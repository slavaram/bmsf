public without sharing class TaskManager {

	public static Task getNextTasksToBeDone(Id userId) {
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
		} catch (Exception ex) {
			// TODO
		}
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
		} catch (Exception ex) {
			// TODO
		}
		return (tasks.isEmpty() ? null : tasks.get(0));
	}

	public static Id createTask(Id relatedObjectId) {
		// TODO
		return null;
	}

	public static Id createTask(sObject relatedObject) {
		// TODO
		return null;
	}

}