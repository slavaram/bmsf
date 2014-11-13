public with sharing class TaskViewController {

	public Task thisTask			{get; private set;}
	public Account thisAccount		{get; private set;}
	public sObject source			{get; private set;}
	public TaskEntity entity		{get; private set;}
	public Boolean deletable		{get; private set;}
	public String sourceTypeName	{get; private set;}

	public String baseUrl			{get; private set;}

	private String sourceType;

	private static final Map<String, String> TYPES_ALLOWED = new Map<String, String> {'Account' => 'Кампания менеджера',
																					  'Campaign' => 'Кампания',
																					  'Case' => 'Запрос',
																					  'Opportunity' => 'Заявка',
																					  'PossibleAccount__c' => 'Рекомендация'};

	public class TaskViewControllerException extends Exception {}

	{
		baseUrl = System.URL.getSalesforceBaseUrl().toExternalForm();
		deletable = false;
	}

	public TaskViewController() {
		try {
			String taskId = ApexPages.currentPage().getParameters().get('id');
			thisTask = [SELECT Id, Subject, WhatId, WhoId, Goal__c, ActivityDateTime__c, Status, Priority__c,
			            	Description, ContactType__c, Contacts__c, CreatedDate, CreatedBy.Name
			            FROM Task
			            WHERE Id = :taskId].get(0);
			entity = new TaskEntity(taskId);
		} catch (Exception ex) {
			throw new TaskViewControllerException('Задача не найдена');
		}
		try {
			sourceType = thisTask.WhatId.getSObjectType().getDescribe().getName();
		} catch (Exception ex) {
			throw new TaskViewControllerException('У задачи должен быть источник');
		}
		if (!TYPES_ALLOWED.keySet().contains(sourceType)) throw new TaskViewControllerException('Данный тип источника не допустим');
		if (thisTask.WhoId == null) throw new TaskViewControllerException('Задача должна быть связана с клиентом');
		try {
			thisAccount = [SELECT Id, FirstName, LastName, Phone, PersonEmail, isCallAccepted__c, patronymic__c, MassEmailValid__c, Status__c, smsValid__c, Description
			               FROM Account
			               WHERE Id IN (SELECT AccountId FROM Contact WHERE Id = :thisTask.WhoId)].get(0);
		} catch (Exception ex) {
			throw new TaskViewControllerException('Не найден клиент по данной задаче');
		}
		
		sourceTypeName	= TYPES_ALLOWED.get(sourceType);
		deletable		= (ApexUtils.getProfileKeyById(UserInfo.getProfileId()) == 'manager' ? false : true);
	}

	public PageReference close() {
		// TODO
		return null;
	}

	public PageReference deleteTask() {
		// TODO
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