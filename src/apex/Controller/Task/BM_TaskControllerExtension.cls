public with sharing class BM_TaskControllerExtension {

	public transient String taskCreationErrorMessage {get; private set;}

	private static final String ERROR_NEW_TASK_NOT_ASSIGNED = 'Задача не была назначена, потому что {0}';

	public BM_TaskControllerExtension(ApexPages.StandardController standardController) {
	}

	public PageReference assignNewCallTask() {
		BM_CampaignClientsManager manager = new BM_CampaignClientsManager(UserInfo.getUserId());
		BM_OperationResults results = manager.assignNewCallTask();
		if (results.IsOperationSuccessful) {
			Task newTask = (Task)results.returnedObjects[0];
			PageReference pageReference = new PageReference('/' + newTask.Id);
			pageReference.setRedirect(true);
			return pageReference;
		} else {
			this.taskCreationErrorMessage = String.format(ERROR_NEW_TASK_NOT_ASSIGNED,
				new String[] {results.errorMessages[0]});
			return null;
		}
	}

}