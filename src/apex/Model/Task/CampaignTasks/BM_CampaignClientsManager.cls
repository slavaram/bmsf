public class BM_CampaignClientsManager {

	private static final String ERROR_INTERNAL				= 'произошла внутренняя ошибка';
	private static final String ERROR_INCORRECT_USER_ROLE	= 'пользователь с ролью "{0}" не работает с клиентами';
	private static final String ERROR_NO_SUITABLE_TASK		= 'система не может найти подходящую задачу';
	private static final String NEW_TASK_SUBJECT			= 'Холодный звонок';

	private User			thisUser;
	private Date			mDueDateOfNewTask;
	private List<sObject>	mObjectsForInsert;
	private List<sObject>	mObjectsForUpdate;

	{
		mDueDateOfNewTask	= Date.today();
		mObjectsForInsert	= new List<sObject>();
		mObjectsForUpdate	= new List<sObject>()
	}

	public CampaignClientsManager(String userId) {
		thisUser = [SELECT Id, Name, UserRoleId, UserRole.Name, isSuperGroupForCampaign__c FROM User WHERE Id = :userId].get(0);
	}

	public BM_OperationResults assignNewCallTask() {
		if (thisUser != null && String.isNotBlank(thisUser.Id)) {
			BM_OperationResults validationResults = validateAllParameters();
			if (!validationResults.isOperationSuccessful) return validationResults;
			CampaignMember suitableCampaignMember = findSuitableCampaignMember();
			if (suitableCampaignMember == null)	{
				BM_OperationResults results = new BM_OperationResults(false);
				results.errorMessages.add(ERROR_NO_SUITABLE_TASK);
				return results;
			}
			assignNewCallTask(suitableCampaignMember);
			BM_OperationResults assignmentResults = commitDBChanges();
			if (assignmentResults.isOperationSuccessful) assignmentResults.returnedObjects.addAll((Object[])mObjectsForInsert);
			clearTemporaryState();
			return assignmentResults;
		} else {
			BM_OperationResults results = new BM_OperationResults(false);
			results.errorMessages.add(ERROR_INTERNAL);
			return results;
		}
	}

	private BM_OperationResults validateAllParameters() {
		BM_OperationResults validationResults;
		Set<String> roleNamesOfClientOwners = new Set<String>(BM_Settings.getRoleNamesOfClientOwners());
		if (!roleNamesOfClientOwners.contains(thisUser.UserRole.Name)) {
			validationResults = new BM_OperationResults(false);
			validationResults.errorMessages.add(String.format(ERROR_INCORRECT_USER_ROLE, new String[] {thisUser.UserRole.Name}));
			return validationResults;
		}
		return BM_TaskAssignmentUtils.reserveNewTask(thisUser.Id, mDueDateOfNewTask);
	}

	private CampaignMember findSuitableCampaignMember() {
		CampaignMember suitableCampaignMember = findCampaignMemberForOwnClient();
		if (thisUser.isSuperGroupForCampaign__c == true)	suitableCampaignMember = findCampaignMemberForSuperGroup();
		if (suitableCampaignMember == null)					suitableCampaignMember = findCampaignMemberForFreeClient();
		if (suitableCampaignMember == null)					suitableCampaignMember = findCampaignMemberForTakenClient();
		return suitableCampaignMember;
	}

	private CampaignMember findCampaignMemberForOwnClient() {
		BM_CampaignMemberDAO.Filter filter	= createCampaignMembersFilter(thisUser.isSuperGroupForCampaign__c);
		filter.accountOwnersIds				= new String[] {thisUser.Id};
		return findCampaignMemberByFilter(filter);
	}

	private static CampaignMember findCampaignMemberByFilter(BM_CampaignMemberDAO.Filter filter) {
		List<CampaignMember> campaignMembers = BM_CampaignMemberDAO.getMembersByFilter(BM_CampaignMemberDAO.KEY_FIELDS_WITH_CONTACT_INFO, filter);
		return (campaignMembers.isEmpty()) ? null : campaignMembers.get((Integer)(Math.random()*campaignMembers.size())));
	}

	private CampaignMember findCampaignMemberForSuperGroup() {
		BM_CampaignMemberDAO.Filter filter = createCampaignMembersFilter(thisUser.isSuperGroupForCampaign__c);
		List<User> ownersUsers = [SELECT Id FROM User WHERE isActive = true AND ManagerId = :thisUser.Id];
		List<String> ownIds = new List<String>();
		for (User us: ownersUsers) {
			ownIds.add(us.Id);
		}
		filter.accountOwnersIds = ownIds;
		return findCampaignMemberByFilter(filter);
	}

	private CampaignMember findCampaignMemberForFreeClient() {
		String unknownClientOwnerId = BM_Settings.getUnknownClientOwnerId();
		if (String.isBlank(unknownClientOwnerId)) return null;
		BM_CampaignMemberDAO.Filter filter = createCampaignMembersFilter(thisUser.isSuperGroupForCampaign__c);
		List<User> deActiveUsers = [SELECT id from User where isActive = false];
		List<String> unknownClientOwnerIds = new List<String>();
		for (User user: deActiveUsers) {
			unknownClientOwnerIds.add(user.Id);
		}
		unknownClientOwnerIds.add(unknownClientOwnerId);
		filter.accountOwnersIds = unknownClientOwnerIds;
		CampaignMember campaignMemberForFreeClient = findCampaignMemberByFilter(filter);
		if (campaignMemberForFreeClient != null) {
			assignFreeClientToUser(campaignMemberForFreeClient);
		}
		return campaignMemberForFreeClient;
	}

	private CampaignMember findCampaignMemberForTakenClient() {
		if (!BM_Settings.userCanManageClientOfAnotherOwner()) return null;
		BM_CampaignMemberDAO.Filter filter = createCampaignMembersFilter(thisUser.isSuperGroupForCampaign__c);
		return findCampaignMemberByFilter(filter);
	}

	private void assignNewCallTask(CampaignMember campaignMember) {
		Task newTask = new Task();
		newTask.WhatId = campaignMember.CampaignId;
		newTask.WhoId = campaignMember.ContactId;
		newTask.CampaignId__c = campaignMember.CampaignId;
		newTask.Subject = NEW_TASK_SUBJECT;
		newTask.isGetNewTask__c = true;
		if (BM_Priority.TASK_PRIORITIES.contains(campaignMember.Campaign.Priority__c)) newTask.Priority = campaignMember.Campaign.Priority__c;
		newTask.ActivityDate = mDueDateOfNewTask;
		newTask.OwnerId = thisUser.Id;
		mObjectsForInsert.add(newTask);
		campaignMember.IsCallTaskCreated__c = true;
		mObjectsForUpdate.add(campaignMember);
	}

	private static BM_CampaignMemberDAO.Filter createCampaignMembersFilter(Boolean isSuperGroup) {
		BM_CampaignMemberDAO.Filter filter	= new BM_CampaignMemberDAO.Filter();
		filter.isCampaignActive				= true;
		filter.isAutoTaskCreated			= false;
		filter.selectMembersForAccountsOnly = true;
		filter.fieldsForSorting				= 'Campaign.Priority__c';
		filter.sortingOrder					= BM_SoqlUtils.SortingOrder.Ascending;
		filter.limitOfResultSet				= 100;
		filter.isSuperGroup					= isSuperGroup;
	}

	private void assignFreeClientToUser(CampaignMember campaignMemberForFreeClient)	{
		if (thisUser.isSuperGroupForCampaign__c == false) {
			Contact freeClient	= new Contact();
			freeClient.Id		= campaignMemberForFreeClient.ContactId;
			freeClient.OwnerId	= thisUser.Id;
			mObjectsForUpdate.add(freeClient);
		}
	}

	private void clearTemporaryState() {
		mObjectsForInsert.clear();
		mObjectsForUpdate.clear();
	}

	private BM_OperationResults commitDBChanges() {
		SavePoint transactionStart = Database.setSavepoint();
		Boolean isInsertSuccessful = BM_SoqlUtils.tryPerformDmlOperation(BM_SoqlUtils.DmlOperation.Inserting, this.mObjectsForInsert);
		Boolean isUpdateSuccessful = false;
		if (isInsertSuccessful)	isUpdateSuccessful = BM_SoqlUtils.tryPerformDmlOperation(BM_SoqlUtils.DmlOperation.Updating, this.mObjectsForUpdate);
		BM_OperationResults results;
		if (isInsertSuccessful && isUpdateSuccessful) {
			results = new BM_OperationResults(true);
		} else {
			Database.rollback(transactionStart);
			results = new BM_OperationResults(false);
			results.errorMessages.add(ERROR_INTERNAL);
		}
		return results;
	}

}