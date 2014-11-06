public without sharing class TaskMethods {

	private static final String TASK_STAGE_IN_PROGESS	= 'Выполняется';
	private static final String TASK_STAGE_DONE			= 'Завершено';
	private static final String CAMPAIGN_TASK_SUBJECT	= 'Холодный звонок';
	private static final Integer TIME_INTERVAL_MINUTES	= 15;

	public class InvalidParameterException extends Exception {}
	public class TaskNotDefinedException extends Exception {}

	private class Counter {
		private List<Id> batch	= new List<Id>();
		private Integer index	= 0;
		public Counter(List<Id> batch) {
			this.batch = batch;
		}
		public Id getNext() {
			index = (index == batch.size() - 1 ? 0 : ++index);
			return batch.get(index);
		}
	}

	private class TaskEntity {
		TasksMatrix__c matrix;
		public TaskEntity(TasksMatrix__c matrix) {
			this.matrix = matrix;
		}
		public Boolean matches(Task tas) {
			Map<String, String> inputs = new Map<String, String>();
			for (String condition : matrix.Input__c.split(',')) {
				inputs.put(condition.substringBefore(':'), condition.substringAfter(':'));
			}
			sObject obj = (sObject) tas;
			for (String fieldName : inputs.keySet()) {
				String fieldValue = (String) obj.get(fieldName);
				if (fieldValue == null || fieldValue != inputs.get(fieldName)) return false;
			}
			return true;
		}
		public Task getTask() {
			sObject obj = (sObject) new Task();
			for (String condition : matrix.Output__c.split(',')) {
				obj.put(condition.substringBefore(':'), condition.substringAfter(':'));
			}
			return (Task) obj;
		}
	}

	public static Task getUserNextTask(Id userId) {
		if (userId == null) throw new InvalidParameterException('Invalid user Id: \'null\'');
		List<Task> tasks	= new List<Task>();
		String taskFields	= String.join(new List<String>(SObjectUtils.getFieldNames('Task')), ', ');
		String query = 'SELECT ' + taskFields +
				' FROM Task WHERE OwnerId = \'' + userId +
				'\' AND Status != \'' + TASK_STAGE_IN_PROGESS +
				'\' AND Status != \'' + TASK_STAGE_DONE +
				'\' AND Delta__c < ' + TIME_INTERVAL_MINUTES +
				' AND Delta__c > ' + -TIME_INTERVAL_MINUTES + ' ORDER BY Delta__c';
		try {
			tasks = Database.query(query);
		} catch (Exception ex) {
			System.debug(LoggingLevel.ERROR, ex.getMessage());
		}
		if (!tasks.isEmpty()) {
			Task result;
			for (Task tas : tasks) {
				if (result == null) {
					result = tas;
				} else {
					if (Math.abs(result.Delta__c) > Math.abs(tas.Delta__c)) result = tas;
				}
			}
			return result;
		}
		query = 'SELECT ' + taskFields +
				' FROM Task WHERE OwnerId = \'' + userId +
				'\' AND Status != \'' + TASK_STAGE_IN_PROGESS +
				'\' AND Status != \'' + TASK_STAGE_DONE +
				'\' AND Delta__c < ' + -TIME_INTERVAL_MINUTES + ' ORDER BY Priority';
		try {
			tasks = Database.query(query);
		} catch (Exception ex) {
			System.debug(LoggingLevel.ERROR, ex.getMessage());
		}
		return (tasks.isEmpty() ? null : tasks.get(0));
	}

	public static Id createTask(CampaignMember member, Id ownerId) {
		if (member == null) throw new InvalidParameterException('Invalid CampaignMember: \'null\'');
		if (ownerId == null) throw new InvalidParameterException('Invalid owner Id: \'null\'');
		return createTask(new List<CampaignMember> {member}, new List<Id> {ownerId}).get(0);
	}

	public static List<Id> createTask(List<CampaignMember> members, List<Id> ownerIds) {
		if (members == null) throw new InvalidParameterException('Invalid CampaignMembers: \'null\'');
		if (ownerIds == null) throw new InvalidParameterException('Invalid owner Ids: \'null\'');
		List<Id> result			= new List<Id>();
		List<Task> tasks		= new List<Task>();
		List<sObject> toUpdate	= new List<sObject>();
		Counter counter			= new Counter(ownerIds);
		for (CampaignMember member : members) {
			Id ownerId				= counter.getNext();
			sObject obj				= (sObject) member;
			String objId			= (Id) obj.get('Id');
			String campaignId		= (Id) obj.get('CampaignId');
			String contactId		= (Id) obj.get('ContactId');
			String accountId		= (Id) obj.get('Contact.AccountId');
			String priority			= (String) obj.get('Campaign.Priority__c');
			String goal				= (String) obj.get('Campaign.Goal__c');
			if (objId == null)		throw new InvalidParameterException('CampaignMember.Id field is missing');
			if (campaignId == null)	throw new InvalidParameterException('CampaignMember.CampaignId field is missing');
			if (contactId == null)	throw new InvalidParameterException('CampaignMember.ContactId field is missing');
			if (accountId == null)	throw new InvalidParameterException('CampaignMember.Contact.AccountId field is missing');
			if (priority == null)	throw new InvalidParameterException('CampaignMember.Campaign.Priority__c field is missing');
			if (goal == null)		throw new InvalidParameterException('CampaignMember.Campaign.Goal__c field is missing');
			tasks.add(new Task( Subject				= CAMPAIGN_TASK_SUBJECT,
								Status				= TASK_STAGE_IN_PROGESS,
								WhatId				= campaignId,
								WhoId				= contactId,
								isGetNewTask__c		= true,
								Priority			= priority,
								ActivityDate		= System.today(),
								Goal__c				= goal,
								OwnerId				= ownerId,
								ActivityDateTime__c	= System.now()));
			toUpdate.add(new CampaignMember(Id = objId, IsCallTaskCreated__c = true));
			toUpdate.add(new Account(Id = accountId, OwnerId = ownerId));
		}
		SavePoint save = Database.setSavepoint();
		try {
			update toUpdate;
			insert tasks;
			for (Task tas : tasks) {
				result.add(tas.Id);
			}
			return result;
		} catch (Exception ex) {
			Database.rollback(save);
			throw ex;
		}
	}

	public static void createTask(List<PossibleAccount__c> possibleAccounts) {
		List<Task> tasks	= new List<Task>();
		for (PossibleAccount__c possibleAccount : possibleAccounts) {
			sObject obj				= (sObject) possibleAccount;
			String objId			= (Id) obj.get('Id');
			String accountId		= (Id) obj.get('RecommendedBy__c');
			String ownerId			= (Id) obj.get('OwnerId');
			String priority			= (String) obj.get('Priority__c');
			String goal				= (String) obj.get('Goal__c');
			String source			= (String) possibleAccount.get('Source__c');
			if (objId == null)		throw new InvalidParameterException('PossibleAccount__c.Id field is missing');
			if (ownerId == null)	throw new InvalidParameterException('PossibleAccount__c.OwnerId field is missing');
			if (priority == null)	throw new InvalidParameterException('PossibleAccount__c.Priority__c field is missing');
			if (goal == null)		throw new InvalidParameterException('PossibleAccount__c.Goal__c field is missing');
			tasks.add(new Task(	Subject				= 'Рекомендация. ' + (source != null && source.length() > 80 ? source.substring(78) + '..' :	source),
								WhatId				= objId,
								WhoId				= accountId,
								ActivityDate		= System.today().addDays(1),
								ActivityDateTime__c	= DateTime.newInstance(System.today().addDays(1), Time.newInstance(10, 0, 0, 0)),
								Status				= 'Новая',
								Priority			= priority,
								Goal__c				= goal,
								OwnerId				= ownerId));
		}
		insert tasks;
	}

	public static void createTask(List<Case> cases) {
		List<Task> tasks	= new List<Task>();
		// TODO
		insert tasks;
	}

	public static void createTask(List<Opportunity> opportunities)  {
		List<Task> tasks	= new List<Task>();
		// TODO
		insert tasks;
	}

	public static Task createTask(Task sourceTask) {
		if (sourceTask == null) throw new InvalidParameterException('Invalid Task: \'null\'');
		List<TaskEntity> taskMatrix = new List<TaskEntity>();
		for (TasksMatrix__c matrix : TasksMatrix__c.getAll().values()) {
			taskMatrix.add(new TaskEntity(matrix));
		}
		for (TaskEntity entity : taskMatrix) {
			if (entity.matches(sourceTask)) return entity.getTask();
		}
		throw new TaskNotDefinedException('Task does not match any entity in TasksMatrix__c setting');
	}

	public static void setWhoId(List<Task> tasks) {
		Set<Id> whatIds = new Set<Id>();
		for (Task item : tasks) {
			if (item.WhoId == null && item.WhatId != null) whatIds.add(item.WhatId);
		}
		Map<Id,Id> contactIds = getContact(whatIds);
		for (Task item : tasks) {
			if (contactIds.containsKey(item.WhatId)) {
				item.WhoId = contactIds.get(item.WhatId);
			}
		}
	}

	private static Map<Id,Id> getContact(Set<Id> whatIds) {
		Map<Id,Id> contactIds = new Map<Id,Id> ();
		contactIds.putAll(getContactByCase(whatIds));
		contactIds.putAll(getContactByOpportunity(whatIds));
		contactIds.putAll(getContactByAccount(whatIds));
		return contactIds;
	}

	private static Map<Id,Id> getContactByCase(Set<Id> whatIds) {
		List<Case> cases;
		try {
			cases = [SELECT Id, AccountId FROM Case WHERE Id IN :whatIds];
		} catch (Exception ex) {
			cases = new List<Case>();
		}
		Set<Id> accountIds = new Set<Id>();
		for (Case item : Cases) {
			accountIds.add(item.AccountId);
		}
		Map<Id, Id> mapAccountContact = setContactIds(AccountIds);
		Map<Id,Id> contactIds = new Map<Id,Id>();
		for (Case item : cases) {
			if (mapAccountContact.containsKey(item.AccountId)) {
				contactIds.put(item.Id, mapAccountContact.get(item.AccountId));
			}
		}
		return contactIds;
	}

	private static Map<Id,Id> getContactByOpportunity(Set<Id> whatIds) {
		List<Opportunity> Opportunities;
		try {
			Opportunities = [SELECT Id, AccountId FROM Opportunity WHERE Id IN :whatIds];
		} catch (Exception ex) {
			Opportunities = new List<Opportunity>();
		}
		Set<Id> accountIds = new Set<Id>();
		for (Opportunity item : opportunities){
			accountIds.add(item.AccountId);
		}
		Map<Id, Id> mapAccountContact = setContactIds(AccountIds);
		Map<Id,Id> contactIds = new Map<Id,Id>();
		for (Opportunity item : opportunities) {
			if (mapAccountContact.containsKey(item.AccountId)) {
				contactIds.put(item.Id, mapAccountContact.get(item.AccountId));
			}
		}
		return ContactIds;
	}

	private static Map<Id,Id> getContactByAccount(Set<Id> whatIds) {
		Map<Id, Account> Accounts;
		try {
			accounts = new Map<Id, Account>([SELECT Id FROM Account WHERE Id IN :whatIds]);
		} catch (Exception ex) {
			accounts = new Map<Id, Account>();
		}
		return setContactIds(accounts.KeySet());
	}

	private static Map<Id,Id> setContactIds(Set<Id> accountIds) {
		List<Contact> contacts = [SELECT Id, AccountId FROM Contact WHERE AccountId IN :accountIds];
		Map<Id, Id> mapAccountContact = new Map<Id, Id>();
		for (Contact item : contacts) {
			mapAccountContact.put(item.AccountId, item.Id);
		}
		return mapAccountContact;
	}

}