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
		validationResults = BM_TaskAssignmentUtils.reserveNewTask(thisUser.Id, mDueDateOfNewTask);
		return validationResults;
	}

	private CampaignMember findSuitableCampaignMember() {
		CampaignMember suitableCampaignMember = findCampaignMemberForOwnClient();
		if (thisUser.isSuperGroupForCampaign__c == true)		suitableCampaignMember = findCampaignMemberForSuperGroup();
		if (suitableCampaignMember == null)						suitableCampaignMember = findCampaignMemberForFreeClient();
		if (suitableCampaignMember == null)						suitableCampaignMember = findCampaignMemberForTakenClient();
		return suitableCampaignMember;
	}

	private CampaignMember findCampaignMemberForOwnClient() {
		BM_CampaignMemberDAO.Filter filter	= createCampaignMembersFilter(thisUser.isSuperGroupForCampaign__c);
		filter.accountOwnersIds				= new String[] {thisUser.Id};
		return findCampaignMemberByFilter(filter);
	}

	private static CampaignMember findCampaignMemberByFilter(BM_CampaignMemberDAO.Filter filter) {
		List<CampaignMember> campaignMembers = BM_CampaignMemberDAO.getMembersByFilter(BM_CampaignMemberDAO.KEY_FIELDS_WITH_CONTACT_INFO, filter);
		if (!campaignMembers.isEmpty()) return campaignMembers.get((Integer)(Math.random()*campaignMembers.size()));
		return null;
	}

	private void clearTemporaryState() {
		mObjectsForInsert.clear();
		mObjectsForUpdate.clear();
	}
	
	private void assignFreeClientToUser(CampaignMember campaignMemberForFreeClient)
	{
		//update an owner of the contact who is related with campaign member
		if(this.thisUser.isSuperGroupForCampaign__c == false)
		{
			Contact freeClient = new Contact();
			freeClient.Id = campaignMemberForFreeClient.ContactId;
			freeClient.OwnerId = this.thisUser.Id;
			this.mObjectsForUpdate.add(freeClient);
		}
	}

	private CampaignMember findCampaignMemberForSuperGroup()
	{
		BM_CampaignMemberDAO.Filter filter = createCampaignMembersFilter(thisUser.isSuperGroupForCampaign__c);
		List<User> ownersUsers = [SELECT Id from User where isActive = true and ManagerId = :this.thisUser.Id];
		String[] ownIds = new List<String>();

		for(User us: ownersUsers)
		{
			ownIds.add(us.Id);
		}

		filter.accountOwnersIds = ownIds;

		return findCampaignMemberByFilter(filter);
	}

	private CampaignMember findCampaignMemberForFreeClient()
	{
		//STEP #1: read parameters from custom settings and check them
		//read Id of an unknown user from custom settings
		String unknownClientOwnerId = BM_Settings.getUnknownClientOwnerId();
		//if the value can't be read then the method should be stopped
		if (String.isBlank(unknownClientOwnerId))
		{
			return null;
		}
		
		//STEP #2: initialize the filter to find suitable campaign member
		BM_CampaignMemberDAO.Filter filter = createCampaignMembersFilter(thisUser.isSuperGroupForCampaign__c);
		//accounts should be managed by the user which is considered as unknown owner
		List<User> deActiveUsers = [SELECT id from User where isActive = false];
		List<String> unknownClientOwnerIds = new List<String>();
		for(User user: deActiveUsers)
		{
			unknownClientOwnerIds.add(user.Id);
		}
		unknownClientOwnerIds.add(unknownClientOwnerId);
		filter.accountOwnersIds = unknownClientOwnerIds;
		
		//STEP #3: get campaign members by the filter
		CampaignMember campaignMemberForFreeClient = findCampaignMemberByFilter(filter);
		if (campaignMemberForFreeClient != null)
		{
			//if a free client has been found then we assign him to the processed user
			this.assignFreeClientToUser(campaignMemberForFreeClient);
		}
		return campaignMemberForFreeClient;
	}
	
	//'taken client' means 'a client who belongs to another owner' 
	private CampaignMember findCampaignMemberForTakenClient()
	{
		//STEP #1: this feature can be disabled in custom settings
		if (!BM_Settings.userCanManageClientOfAnotherOwner())
		{
			return null;
		}
		
		//STEP #2: initialize the filter to find suitable campaign member (we don't need to
		//set any other specific subfilters)
		BM_CampaignMemberDAO.Filter filter = createCampaignMembersFilter(this.thisUser.isSuperGroupForCampaign__c);
		
		//STEP #3: get campaign members by the filter
		return findCampaignMemberByFilter(filter);
	}

	private void assignNewCallTask(CampaignMember campaignMember)
	{
		//STEP #1: create a new task
		Task newTask = new Task();
		//set references to connect the task with the campaign and the client
		newTask.WhatId = campaignMember.CampaignId;
		newTask.WhoId = campaignMember.ContactId;
		newTask.CampaignId__c = campaignMember.CampaignId;
		//set a name for the task
		newTask.Subject = NEW_TASK_SUBJECT;
		newTask.isGetNewTask__c = true;
		//synchronize priorities of the campaign and the task if it's possible
		if (BM_Priority.TASK_PRIORITIES.contains(campaignMember.Campaign.Priority__c))
		{
			newTask.Priority = campaignMember.Campaign.Priority__c;
		}
		
		//set parameters which depend on the current state of this class
		newTask.ActivityDate = this.mDueDateOfNewTask;
		newTask.OwnerId = this.thisUser.Id;
		
		//add a new created task into the list of objects for insert
		this.mObjectsForInsert.add(newTask);
		
		//STEP #2: modify the campaign member
		campaignMember.IsCallTaskCreated__c = true;
		this.mObjectsForUpdate.add(campaignMember);
	}
	
	private BM_OperationResults commitDBChanges()
	{
		//all DML operations will be performed as a single logical transaction
		//1) start the transaction
		SavePoint transactionStart = Database.setSavepoint();
		
		//2) insert new objects
		Boolean isInsertSuccessful = BM_SoqlUtils.tryPerformDmlOperation(
			BM_SoqlUtils.DmlOperation.Inserting, this.mObjectsForInsert);
		
		//3) update existing objects
		Boolean isUpdateSuccessful = false;
		if (isInsertSuccessful)
		{
			isUpdateSuccessful = BM_SoqlUtils.tryPerformDmlOperation(
				BM_SoqlUtils.DmlOperation.Updating, this.mObjectsForUpdate);
		}
		
		//4) generate final results
		BM_OperationResults results;
		if (isInsertSuccessful && isUpdateSuccessful)
		{
			//generate positive results
			results = new BM_OperationResults(true);
		}
		else
		{
			//roll back the transaction if at least one operation failed
			Database.rollback(transactionStart);
			//generate negative results
			results = new BM_OperationResults(false);
			results.errorMessages.add(ERROR_INTERNAL);
		}
		
		return results;
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

}