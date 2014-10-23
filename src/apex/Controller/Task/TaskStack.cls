public class TaskStack {

	private static final String TASK_STAGE_IN_PROGESS	= 'Выполняется';
	private static final String TASK_STAGE_DONE			= 'Завершено';
	private static final Integer TIME_INTERVAL_MINUTES	= 15;

	public static List<Task> getUserTasksInProgres(Id userId) {
		List<Task> result = new List<Task>();
		String query = 'SELECT ' + String.join(getTaskFields(), ', ') +
				' FROM Task WHERE OwnerId = \'' + userId +
				'\' AND Status = \'' + TASK_STAGE_IN_PROGESS + '\' ORDER BY CreatedDate';
		try {
			result = Database.query(query);
		} catch (Exception ex) {}
		return result;
	}

	public static Task getUserTaskToBeDone(Id userId) {
		List<Task> tasks = new List<Task>();
		Task result;
		String query = 'SELECT ' + String.join(getTaskFields(), ', ') +
				' FROM Task WHERE OwnerId = \'' + userId +
				'\' AND Status != \'' + TASK_STAGE_IN_PROGESS +
				'\' AND Status != \'' + TASK_STAGE_DONE +
				'\' AND Delta__c < ' + TIME_INTERVAL_MINUTES +
				' AND Delta__c > ' + -TIME_INTERVAL_MINUTES + ' ORDER BY Delta__c';
		try {
			tasks = Database.query(query);
		} catch (Exception ex) {}
		if (!tasks.isEmpty()) {
			for (Task tas : tasks) {
				if (result == null) {
					result = tas;
				} else {
					if (Math.abs(result.Delta__c) > Math.abs(tas.Delta__c)) result = tas;
				}
			}
			return result;
		}
		query = 'SELECT ' + String.join(getTaskFields(), ', ') +
				' FROM Task WHERE OwnerId = \'' + userId +
				'\' AND Status != \'' + TASK_STAGE_IN_PROGESS +
				'\' AND Status != \'' + TASK_STAGE_DONE +
				'\' AND Delta__c < ' + -TIME_INTERVAL_MINUTES + ' ORDER BY Priority DESC';
		try {
			tasks = Database.query(query);
		} catch (Exception ex) {}
		if (!tasks.isEmpty()) {
			return tasks.get(0);
		}
		// TODO
		return null;
	}

	private static List<String> getTaskFields() {
		return new List<String>(Schema.SObjectType.Task.fields.getMap().keySet());
	}

}