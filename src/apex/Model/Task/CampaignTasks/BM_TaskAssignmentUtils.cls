public class BM_TaskAssignmentUtils {

	private static final String ERROR_TASKS_COUNT_NOT_FOUND = 'система не может вычислить количество активных задач для пользователя';
	private static final String ERROR_TOO_MANY_ACTIVE_TASKS = 'количество активных задач слишком велико для пользователя';

	public static BM_OperationResults reserveNewTask(String ownerId, Date dueDateOfNewTask) {
		if (String.isBlank(ownerId)) return null;
		BM_TaskDAO.Filter tasksFilter = new BM_TaskDAO.Filter();
		tasksFilter.ownersIds = new String[] {ownerId};
		tasksFilter.activityDate = dueDateOfNewTask;
		tasksFilter.taskStatuses = new List<String> {'Новая', 'Выполняется', 'Переоткрыто'};
		Integer numberOfExistingTasks = BM_TaskDAO.getTasksCountByFilter(tasksFilter);
		BM_OperationResults validationResults;
		if (numberOfExistingTasks == null) {
			validationResults = new BM_OperationResults(false);
			validationResults.errorMessages.add(ERROR_TASKS_COUNT_NOT_FOUND);
		} else {
			if (numberOfExistingTasks < BM_Settings.getMaxNumberOfActiveTasksPerDay()) {
				validationResults = new BM_OperationResults(true);
			} else {
				validationResults = new BM_OperationResults(false);
				validationResults.errorMessages.add(ERROR_TOO_MANY_ACTIVE_TASKS); 
			}
		}
		return validationResults;
	}

}