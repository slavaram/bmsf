public with sharing class TaskViewController {

	public Task thisTask			{get; private set;}
	public Account thisAccount		{get; private set;}
	public sObject source			{get; private set;}
	public TaskEntity entity		{get; private set;}
	public Boolean deletable		{get; private set;}
	public String sourceTypeName	{get; private set;}
	public List<Task> relatedTasks	{get; private set;}

	public String errorMessage		{get; private set;}
	public Boolean closeFormVisible	{get; private set;}
	public String baseUrl			{get; private set;}

	public List<SelectOption> results	{get; private set;}

	private String sourceType;

	private static final Map<String, String> TYPES_ALLOWED = new Map<String, String> {'Account' => 'Кампания менеджера',
																					  'Campaign' => 'Кампания',
																					  'Case' => 'Запрос',
																					  'Opportunity' => 'Заявка',
																					  'PossibleAccount__c' => 'Рекомендация'};

	{
		baseUrl = System.URL.getSalesforceBaseUrl().toExternalForm();
		deletable = (ApexUtils.getProfileKeyById(UserInfo.getProfileId()) == 'manager' ? false : true);
		closeFormVisible = false;
		errorMessage = null;
		results = new List<SelectOption>();
	}

	public TaskViewController() {
		errorMessage = init();
	}

	public void close() {
		closeFormVisible = true;
	}

	public PageReference deleteTask() {
		delete thisTask;
		return new PageReference('/home/home.jsp');
	}

	public PageReference closeTask() {
		try {
			entity.close();
		} catch (Exception ex) {
			errorMessage = ex.getMessage();
			closeFormVisible = false;
			return null;
		}
		return new PageReference('/home/home.jsp');
	}

	public PageReference closeAndCreateTask() {
		try {
			entity.close();
		} catch (Exception ex) {
			errorMessage = ex.getMessage();
			closeFormVisible = false;
			return null;
		}
		return new PageReference('/00T/e');
	}

	public void cancel() {
		closeFormVisible = false;
	}

	private String init() {
		try {
			String taskId = ApexPages.currentPage().getParameters().get('id');
			thisTask = [SELECT Id, Subject, WhatId, WhoId, Goal__c, ActivityDateTime__c, Status, Priority__c,
			            	Description, ContactType__c, Contacts__c, CreatedDate, CreatedBy.Name
			            FROM Task
			            WHERE Id = :taskId].get(0);
			entity = new TaskEntity(taskId);
		} catch (Exception ex) {
			return 'Задача не найдена';
		}
		try {
			sourceType = thisTask.WhatId.getSObjectType().getDescribe().getName();
		} catch (Exception ex) {
			return 'У задачи должен быть источник';
		}
		if (!TYPES_ALLOWED.keySet().contains(sourceType)) return 'Данный тип источника не допустим';
		if (thisTask.WhoId == null) return 'Задача должна быть связана с клиентом';
		try {
			thisAccount = [SELECT Id, FirstName, LastName, Phone, PersonEmail, isCallAccepted__c, patronymic__c, MassEmailValid__c, Status__c, smsValid__c, Description
			               FROM Account
			               WHERE Id IN (SELECT AccountId FROM Contact WHERE Id = :thisTask.WhoId)].get(0);
		} catch (Exception ex) {
			return 'Не найден клиент по данной задаче' ;
		}

		relatedTasks = [SELECT Id, Subject, Status, What.Name, Goal__c, Priority
		                FROM Task
		                WHERE WhoId = :thisTask.WhoId
		                AND Status != 'Завершено'
		                AND Id != :thisTask.Id];
		sourceTypeName	= TYPES_ALLOWED.get(sourceType);
		if (entity.closable) {
			for (String result : entity.results) {
				results.add(new SelectOption(result, result));
			}
		}
		return null;
	}

	public Boolean isAccount() {
		return (sourceType == 'Account' ? true : false);
	}

	public Boolean isCampaign() {
		return (sourceType == 'Campaign' ? true : false);
	}

	public Boolean isCase() {
		return (sourceType == 'Case' ? true : false);
	}

	public Boolean isOpportunity() {
		return (sourceType == 'Opportunity' ? true : false);
	}

	public Boolean isPossibleAccount() {
		return (sourceType == 'PossibleAccount__c' ? true : false);
	}

}