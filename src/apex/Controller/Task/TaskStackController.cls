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

	private static final Set<String> TASK_STAGES_TO_AVOID	= new Set<String>();
	private static final String REQUEST_PARAMETER_TASK		= 'r';
	private static final String TASK_STAGE_CLOSED			= 'Завершено';
	private static final String TASK_STAGE_IN_PROGESS		= 'Выполняется';

	public class Record {
		public Id id						{get; private set;}
		public String subject				{get; private set;}
		public DateTime activityDateTime	{get; private set;}
		public String status				{get; private set;}
		public String priority				{get; private set;}
		public String whatId				{get; private set;}
		public Integer delta				{get; private set;}
		public String deadline				{get; private set;}
		public String relatedObjectType		{get; private set;}
		public String relatedObjectName		{get; private set;}

		public Record(Id id, DateTime activityDateTime, Decimal delta, String subject, String status, String priority, Id whatId, String relatedObjectType, String relatedObjectName) {
			this.id					= id;
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
	}

	{
		noTaskMessage	= 'У вас нет задач! Быть не может.. О_о';
		records			= new List<Record>();
		type			= 'Campaign,Case,Opportunity,Task';
		types			= new List<SelectOption>();
		types.add(new SelectOption(type, 'Все'));
		types.add(new SelectOption('Campaign', 'Кампания'));
		types.add(new SelectOption('Case', 'Обращение'));
		types.add(new SelectOption('Opportunity', 'Заявка'));
		types.add(new SelectOption('Task', 'Задача'));
	}

	public PageReference redirection() {
		String taskParameter	= ApexPages.currentPage().getParameters().get(REQUEST_PARAMETER_TASK);
		if (taskParameter == null) {
			refresh();
			return null;
		} else {
			Id taskId;
			try {
				taskId = Id.valueOf(EncodingUtil.urlDecode(ApexUtils.decript(taskParameter), 'UTF-8'));
			} catch (Exception ex) {}
			if (taskId != null && taskId.getSObjectType().getDescribe().getName() == 'Task') {
				return new PageReference(System.URL.getSalesforceBaseUrl().toExternalForm() + '/' + taskId);
			} else {
				refresh();
				return null;
			}
		}
	}

	public void refresh() {
		refreshTable();
		refreshTaskToBeDone();
	}

	public void refreshWithTask() {
		taskToBeDone.Status = TASK_STAGE_IN_PROGESS;
		update taskToBeDone;
		refresh();
	}

	private void refreshTable() {
		records.clear();
		List<Task> tasks = [SELECT Id, Subject, ActivityDateTime__c, Status, Priority, WhatId, TaskTrack__c, Delta__c
		                    FROM Task
		                    WHERE OwnerId = :UserInfo.getUserId()
		                    AND Status != :TASK_STAGE_CLOSED
		                    ORDER BY ActivityDateTime__c];
		Map<Id, Campaign> campaignMap		= new Map<Id, Campaign>();
		Map<Id, Case> caseMap				= new Map<Id, Case>();
		Map<Id, Opportunity> opportunityMap	= new Map<Id, Opportunity>();
		Map<Id, Task> taskMap				= new Map<Id, Task>();
		for (Task tas : tasks) {
			if (String.isEmpty(tas.TaskTrack__c)) {
				if (!String.isEmpty(tas.WhatId)) {
					String objectType = tas.WhatId.getSObjectType().getDescribe().getName();
					if (objectType == 'Campaign') {
						campaignMap.put(tas.WhatId, null);
					} else if(objectType == 'Case') {
						caseMap.put(tas.WhatId, null);
					} else if (objectType == 'Opportunity') {
						opportunityMap.put(tas.WhatId, null);
					}
				}
			} else {
				taskMap.put(Id.valueOf(tas.TaskTrack__c.substringAfterLast(',')), null);
			}
		}
		if (!campaignMap.isEmpty()) {
			for (Campaign cam : [SELECT Id, Name FROM Campaign WHERE Id IN :campaignMap.keySet()]) {
				campaignMap.put(cam.Id, cam);
			}
		}
		if (!caseMap.isEmpty()) {
			for (Case cas : [SELECT Id, Subject FROM Case WHERE Id IN :caseMap.keySet()]) {
				caseMap.put(cas.Id, cas);
			}
		}
		if (!opportunityMap.isEmpty()) {
			for (Opportunity opp : [SELECT Id, Name FROM Opportunity WHERE Id IN :opportunityMap.keySet()]) {
				opportunityMap.put(opp.Id, opp);
			}
		}
		if (!taskMap.isEmpty()) {
			for (Task tas : [SELECT Id, Subject FROM Task WHERE Id IN :taskMap.keySet()]) {
				taskMap.put(tas.Id, tas);
			}
		}
		for (Task tas : tasks) {
			String relatedObjectType = '';
			String relatedObjectName = '';
			if (campaignMap.get(tas.WhatId) != null) {
				relatedObjectType = 'Campaign';
				relatedObjectName = campaignMap.get(tas.WhatId).Name;
			} else if (caseMap.get(tas.WhatId) != null) {
				relatedObjectType = 'Case';
				relatedObjectName = caseMap.get(tas.WhatId).Subject;
			} else if (opportunityMap.get(tas.WhatId) != null) {
				relatedObjectType = 'Opportunity';
				relatedObjectName = opportunityMap.get(tas.WhatId).Name;
			} else if (taskMap.get(tas.WhatId) != null) {
				relatedObjectType = 'Task';
				relatedObjectName = taskMap.get(tas.WhatId).Subject;
			} else {
				relatedObjectType = null;
				relatedObjectName = null;
			}
			if (relatedObjectType == null || type.contains(relatedObjectType)) {
				records.add(new Record(tas.Id, tas.ActivityDateTime__c, tas.Delta__c, tas.Subject, tas.Status, tas.Priority, tas.WhatId, relatedObjectType, relatedObjectName));
			}
		}
	}

	private void refreshTaskToBeDone() {
		message			= null;
		taskToBeDone	= null;
		taskToBeDoneUrl	= null;
		if (TaskStack.getUserTasksInProgres(UserInfo.getUserId()).isEmpty()) {
			taskToBeDone = TaskStack.getUserTaskToBeDone(UserInfo.getUserId());
			if (taskToBeDone == null) {
				message = 'Для тебя нет ни одной задачки, можешь прогуляться.';
			} else {
				String baseUrl		= System.URL.getSalesforceBaseUrl().toExternalForm();
				String pageUrl		= ApexPages.currentPage().getUrl().substringBefore('?');
				String parameters	= '?' + REQUEST_PARAMETER_TASK + '=' + EncodingUtil.urlEncode(ApexUtils.encript(String.valueOf(taskToBeDone.Id)), 'UTF-8');
				taskToBeDoneUrl = baseUrl + pageUrl + parameters;
				System.debug(taskToBeDoneUrl);
			}
		} else {
			message = 'У тебя есть текущие незавершенные задачи.';
		}
	}

}