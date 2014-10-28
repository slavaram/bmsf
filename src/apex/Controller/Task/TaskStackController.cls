public with sharing class TaskStackController {

	public String noTaskMessage		{get; private set;}
	public List<Record> records		{get; set;}
	public String type				{get; set;}
	public List<SelectOption> types	{get; set;}
	public Boolean noRecords		{get {return records.isEmpty();} set;}
	public Task taskToBeDone		{get; private set;}
	public String taskToBeDoneUrl	{get; private set;}
	public String message			{get; private set;}

	private List<Task> tasksInProgress = new List<Task>();

	private static final Set<String> TASK_STAGES_TO_AVOID			= new Set<String>();
	private static final String REQUEST_PARAMETER_TASK				= 'r';
	private static final String TASK_STAGE_CLOSED					= 'Завершено';
	private static final String TASK_STAGE_IN_PROGESS				= 'Выполняется';
	private static final String CAMPAIGN_TASK_SUBJECT				= 'Холодный звонок';
	private static final String INIT_TYPE							= 'Все';
	private static final Map<String, String> RELATED_OBJECT_TYPES	= new Map<String, String>();

	public class Record {
		public Id taskid					{get; private set;}
		public String subject				{get; private set;}
		public DateTime activityDateTime	{get; private set;}
		public String status				{get; private set;}
		public String priority				{get; private set;}
		public String whatId				{get; private set;}
		public Integer delta				{get; private set;}
		public String deadline				{get; private set;}
		public String relatedObjectType		{get; private set;}
		public String relatedObjectName		{get; private set;}

		public Record(Id taskId, DateTime activityDateTime, Decimal delta, String subject, String status, String priority, Id whatId, String relatedObjectType, String relatedObjectName) {
			this.taskId				= taskId;
			this.subject			= (subject != null && subject.length() > 50 ? subject.substring(0, 48) + '..' : subject);
			this.activityDateTime	= activityDateTime;
			this.delta				= Integer.valueOf(delta);
			this.status				= status;
			this.priority			= priority;
			this.whatId				= whatId;
			this.relatedObjectType	= relatedObjectType;
			this.relatedObjectName	= (relatedObjectName != null && relatedObjectName.length() > 30 ? relatedObjectName.substring(0, 28) + '..' : relatedObjectName);
			deadline = String.valueOf(activityDateTime).substring(11, 16);
			if (activityDateTime.day() != System.today().day()) {
				deadline += ' (' + activityDateTime.day() + ' ' + ApexUtils.getMonthNameRus(activityDateTime.month(), false);
				if (activityDateTime.year() != System.today().year()) deadline += ' ' + activityDateTime.year();
				deadline += ')';
			}
		}
	}

	static {
		TASK_STAGES_TO_AVOID.add(TASK_STAGE_IN_PROGESS);
		TASK_STAGES_TO_AVOID.add(TASK_STAGE_CLOSED);
		RELATED_OBJECT_TYPES.put('Campaign', 'Кампания');
		RELATED_OBJECT_TYPES.put('Case', 'Обращение');
		RELATED_OBJECT_TYPES.put('Opportunity', 'Заявка');
		RELATED_OBJECT_TYPES.put('Task', 'Задача');
		RELATED_OBJECT_TYPES.put('PossibleAccount__c', 'Рекомендация');
	}

	{
		noTaskMessage	= 'У вас нет задач! Быть не может.. О_о';
		records			= new List<Record>();
		types			= new List<SelectOption>();
	}

	public TaskStackController() {
		type = String.join(new List<String>(RELATED_OBJECT_TYPES.keySet()), ',');
		types.add(new SelectOption(type, INIT_TYPE));
		for (String typeName : RELATED_OBJECT_TYPES.keySet()) {
			types.add(new SelectOption(typeName, RELATED_OBJECT_TYPES.get(typeName)));
		}
	}

	public PageReference redirection() {
		String taskParameter	= ApexPages.currentPage().getParameters().get(REQUEST_PARAMETER_TASK);
		if (taskParameter == null) {
			refresh();
			return null;
		} else {
			SavePoint save = Database.setSavepoint();
			try {
				Id objectId = Id.valueOf(ApexUtils.decript(EncodingUtil.urlDecode(taskParameter, 'UTF-8')));
				if (objectId != null && objectId.getSObjectType().getDescribe().getName() == 'Task') {
					return new PageReference(System.URL.getSalesforceBaseUrl().toExternalForm() + '/' + objectId);
				} else if (objectId != null && objectId.getSObjectType().getDescribe().getName() == 'CampaignMember') {
					CampaignMember member = [SELECT Id, CampaignId, Campaign.Priority__c, ContactId, Contact.AccountId FROM CampaignMember WHERE Id =:objectId].get(0);
					Task tas = new  Task(
							Subject				= CAMPAIGN_TASK_SUBJECT,
							Status				= TASK_STAGE_IN_PROGESS,
							WhatId				= member.CampaignId,
							WhoId				= member.ContactId,
							isGetNewTask__c		= true,
							Priority			= member.Campaign.Priority__c,
							ActivityDate		= System.today(),
							OwnerId				= UserInfo.getUserId(),
							ActivityDateTime__c	= System.now());
					insert tas;
					update new CampaignMember(Id = objectId, IsCallTaskCreated__c = true);
					AccountMethods.assignAccountOwner(member.Contact.AccountId, UserInfo.getUserId());
					return new PageReference(System.URL.getSalesforceBaseUrl().toExternalForm() + '/' + tas.Id);
				} else {
					refresh();
					return null;
				}
			} catch (Exception ex) {
				Database.rollback(save);
				return null;
			}
		}
	}

	public void refresh() {
		refreshTable();
		refreshTaskToBeDone();
	}

	public void refreshWithTask() {
		if (taskToBeDone != null) {
			taskToBeDone.Status = TASK_STAGE_IN_PROGESS;
			update taskToBeDone;
		}
		refreshTable();
		refreshTaskToBeDone();
	}

	private void refreshTable() {
		records.clear();
		List<Task> tasks = [SELECT Id, Subject, ActivityDateTime__c, Status, Priority, WhatId, What.Name, TaskTrack__c, Delta__c
		                    FROM Task
		                    WHERE OwnerId = :UserInfo.getUserId()
		                    AND Status != :TASK_STAGE_CLOSED
		                    ORDER BY ActivityDateTime__c];
		Map<Id, String> taskAndName = new Map<Id, String>();
		for (Task tas : tasks) {
			if (!String.isEmpty(tas.TaskTrack__c)) taskAndName.put(tas.TaskTrack__c.substringAfterLast(','), null);
		}
		for (Task tas : [SELECT Id, Subject FROM Task WHERE Id IN :taskAndName.keySet()]) {
			taskAndName.put(tas.Id, tas.Subject);
		}
		for (Task tas : tasks) {
			String relatedObjectType = '';
			String relatedObjectName = '';
			if (String.isEmpty(tas.TaskTrack__c)) {
				if (!String.isEmpty(tas.WhatId)) {
					relatedObjectType = tas.WhatId.getSObjectType().getDescribe().getName();
					relatedObjectName = tas.What.Name;
				}
			} else {
				relatedObjectType = 'Task';
				relatedObjectName = taskAndName.get(tas.TaskTrack__c.substringAfterLast(','));
			}
			if (type.contains(relatedObjectType)) records.add(new Record(tas.Id, tas.ActivityDateTime__c, tas.Delta__c, tas.Subject, tas.Status, tas.Priority, tas.WhatId, relatedObjectType, relatedObjectName));
		}
	}

	private void refreshTaskToBeDone() {
		message			= null;
		taskToBeDone	= null;
		taskToBeDoneUrl	= null;
		if (TaskStack.getTasksInProgres(UserInfo.getUserId()).isEmpty()) {
			taskToBeDone = TaskStack.getTaskToBeDone(UserInfo.getUserId());
			if (taskToBeDone == null) {
				CampaignMember member = TaskStack.getCampaignMemberForNewTask(UserInfo.getUserId());
				if (member == null) {
					message = 'Для тебя нет ни одной задачки, можешь прогуляться.';
				} else {
					taskToBeDoneUrl = getRedirectUrlFor(member.Id);
				}
			} else {
				taskToBeDoneUrl = getRedirectUrlFor(taskToBeDone.Id);
			}
		} else {
			message = 'У тебя есть текущие незавершенные задачи.';
		}
	}

	private String getRedirectUrlFor(Id objectId) {
		String baseUrl		= System.URL.getSalesforceBaseUrl().toExternalForm();
		String pageUrl		= ApexPages.currentPage().getUrl().substringBefore('?');
		String parameters	= '?' + REQUEST_PARAMETER_TASK + '=' + EncodingUtil.urlEncode(ApexUtils.encript(String.valueOf(objectId)), 'UTF-8');
		return baseUrl + pageUrl + parameters;
	}

}