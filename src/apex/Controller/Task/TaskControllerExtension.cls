public with sharing class TaskControllerExtension {

	public transient String taskCreationErrorMessage {get; private set;}

	private static final String ERROR_NEW_TASK_NOT_ASSIGNED = 'Задача не была назначена, потому что {0}';

	public TaskControllerExtension(ApexPages.StandardController standardController) {
	}

	public PageReference assignNewCallTask() {
		CampaignClientsManager manager = new CampaignClientsManager(UserInfo.getUserId());
		OperationResults results = manager.assignNewCallTask();
		if (results.mIsOperationSuccessful) {
			Task newTask = (Task) results.returnedObjects.get(0);
			PageReference pageReference = new PageReference('/' + newTask.Id);
			pageReference.setRedirect(true);
			return pageReference;
		} else {
			taskCreationErrorMessage = String.format(ERROR_NEW_TASK_NOT_ASSIGNED, new List<String> {results.errorMessages.get(0)});
			return null;
		}
	}

}