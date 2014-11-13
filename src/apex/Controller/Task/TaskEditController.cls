public class TaskEditController {

	public Task thisTask		{get; private set;}
	public Account thisAccount	{get; private set;}

	public class TaskEditControllerException extends Exception {}

	public TaskEditController() {
		try {
			thisTask = [SELECT Id, Subject, WhatId, WhoId
			            FROM Task
			            WHERE Id = :ApexPages.currentPage().getParameters().get('id')].get(0);
		} catch (Exception ex) {
			throw new TaskEditControllerException('Задача не найдена');
		}
		// TODO
	}

	public PageReference save() {
		// TODO
		return null;
	}

}