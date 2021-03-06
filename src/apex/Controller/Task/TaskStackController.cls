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

		public Record(Id taskId, DateTime activityDateTime, Decimal delta, String subject, String status, String priority, Id whatId, String relatedObjectType) {
			this.taskId				= taskId;
			this.subject			= (subject != null && subject.length() > 100 ? subject.substring(0, 98) + '..' : subject);
			this.activityDateTime	= activityDateTime;
			this.delta				= Integer.valueOf(delta);
			this.status				= status;
			this.priority			= priority;
			this.whatId				= whatId;
			this.relatedObjectType	= relatedObjectType;
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
			try {
				Id objectId = Id.valueOf(ApexUtils.decript(EncodingUtil.urlDecode(taskParameter, 'UTF-8').replace(' ', '+')));
				if (objectId != null && objectId.getSObjectType().getDescribe().getName() == 'Task') {
					update new Task(Id = objectId, Status = TASK_STAGE_IN_PROGESS);
					return new PageReference(System.URL.getSalesforceBaseUrl().toExternalForm() + (UserInfo.getUserId() == '0051100000144kpAAA' ? '/apex/TaskView?id=' : '/') + objectId);
				} else if (objectId != null && objectId.getSObjectType().getDescribe().getName() == 'CampaignMember') {
					CampaignMember member = [SELECT Id, CampaignId, ContactId, Contact.AccountId, Campaign.Priority__c, Campaign.Goal__c
					                         FROM CampaignMember
					                         WHERE Id = :objectId].get(0);
					System.debug('member selected');
					Task newTask = new Task(Subject				= CAMPAIGN_TASK_SUBJECT,
											Status				= TASK_STAGE_IN_PROGESS,
											WhatId				= member.CampaignId,
											WhoId				= member.ContactId,
											isGetNewTask__c		= true,
											Priority			= member.Campaign.Priority__c,
											Goal__c				= member.Campaign.Goal__c,
											OwnerId				= UserInfo.getUserId(),
											ActivityDateTime__c	= System.now());
					insert newTask;
					System.debug('task inserted');
					return new PageReference(System.URL.getSalesforceBaseUrl().toExternalForm() + (UserInfo.getUserId() == '0051100000144kpAAA' ? '/apex/TaskView?id=' : '/') + newTask.Id);
				} else {
					refresh();
					return null;
				}
			} catch (Exception ex) {
				System.debug(ex.getMessage());
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
		List<Task> tasks = [SELECT Id, Subject, ActivityDateTime__c, Status, Priority, WhatId, Delta__c
		                    FROM Task
		                    WHERE OwnerId = :UserInfo.getUserId()
		                    AND Status != :TASK_STAGE_CLOSED
		                    ORDER BY ActivityDateTime__c];
		for (Task tas : tasks) {
			String sourceObjectType = (tas.WhatId == null ? null : tas.WhatId.getSObjectType().getDescribe().getName());
			if (type.contains(sourceObjectType)) records.add(new Record(tas.Id, tas.ActivityDateTime__c, tas.Delta__c, tas.Subject, tas.Status, tas.Priority, tas.WhatId, sourceObjectType));
		}
	}

	private void refreshTaskToBeDone() {
		message			= null;
		taskToBeDone	= null;
		taskToBeDoneUrl	= null;
		List<Task> currentTasks = [SELECT Id FROM Task WHERE Status = :TASK_STAGE_IN_PROGESS AND OwnerId = :UserInfo.getUserId()];
		if (currentTasks.isEmpty()) {
			taskToBeDone = TaskMethods.getUserNextTask(UserInfo.getUserId());
			if (taskToBeDone == null) {
				CampaignMember member = getCampaignMemberForNewTask(UserInfo.getUserId());
				if (member == null) {
					message = 'Для тебя нет ни одной задачки, можешь прогуляться.';
				} else {
					taskToBeDoneUrl = getRedirectUrlFor(member.Id);
				}
			} else {
				taskToBeDoneUrl = getRedirectUrlFor(taskToBeDone.Id);
			}
		} else {
			taskToBeDoneUrl = getRedirectUrlFor(currentTasks.get(0).Id);
		}
	}

	private String getRedirectUrlFor(Id objectId) {
		String baseUrl		= System.URL.getSalesforceBaseUrl().toExternalForm();
		String pageUrl		= ApexPages.currentPage().getUrl().substringBefore('?');
		String parameters	= '?' + REQUEST_PARAMETER_TASK + '=' + EncodingUtil.urlEncode(ApexUtils.encript(String.valueOf(objectId)), 'UTF-8');
		return baseUrl + pageUrl + parameters;
	}

	private static CampaignMember getCampaignMemberForNewTask(Id userId) {
		List<CampaignMember> result = selectCampaignMembers(userId);
		if (result.isEmpty()) result = selectCampaignMembers(null);
		return (result.isEmpty() ? null : result.get(0));
	}

	private static List<CampaignMember> selectCampaignMembers(Id userId) {
		List<CampaignMember> result = new List<CampaignMember>();
		String query = 'SELECT Id ' +
						'FROM CampaignMember ' +
						'WHERE Campaign.IsActive = true ' +
						'AND IsCallTaskCreated__c = false ' +
						'AND ContactId != null ' +
						'AND Contact.AccountId != null ' +
						(userId == null ?
								'AND (Contact.Account.Owner.IsActive = false OR Contact.Account.Owner.Name = \'Администратор\') ' :
								'AND Contact.Account.OwnerId = \'' + userId + '\' ') +
						'ORDER BY Campaign.Priority__c ' +
						'LIMIT 100';
		try {
			result = Database.query(query);
		} catch (Exception ex) {
			// TODO
		}
		return result;
	}

}