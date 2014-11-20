public without sharing class TaskMethods {

	private static final String TASK_STAGE_IN_PROGESS	= 'Выполняется';
	private static final String TASK_STAGE_DONE			= 'Завершено';
	private static final String CAMPAIGN_TASK_SUBJECT	= 'Холодный звонок';
	private static final Integer TIME_INTERVAL_MINUTES	= 15;

	public class InvalidParameterException extends Exception {}
	public class TaskNotDefinedException extends Exception {}

	private class Counter {
		private List<Id> batch	= new List<Id>();
		private Integer index	= 0;
		public Counter(List<Id> batch) {
			this.batch = batch;
		}
		public Id getNext() {
			index = (index == batch.size() - 1 ? 0 : ++index);
			return batch.get(index);
		}
	}

	public static Task getUserNextTask(Id userId) {
		if (userId == null) throw new InvalidParameterException('Invalid user Id: \'null\'');
		List<Task> tasks	= new List<Task>();
		String taskFields	= String.join(new List<String>(SObjectUtils.getFieldNames('Task')), ', ');
		String query = 'SELECT ' + taskFields +
				' FROM Task WHERE OwnerId = \'' + userId +
				'\' AND Status != \'' + TASK_STAGE_IN_PROGESS +
				'\' AND Status != \'' + TASK_STAGE_DONE +
				'\' AND Delta__c < ' + TIME_INTERVAL_MINUTES +
				' AND Delta__c > ' + -TIME_INTERVAL_MINUTES + ' ORDER BY Delta__c';
		try {
			tasks = Database.query(query);
		} catch (Exception ex) {
			System.debug(LoggingLevel.ERROR, ex.getMessage());
		}
		if (!tasks.isEmpty()) {
			Task result;
			for (Task tas : tasks) {
				if (result == null) {
					result = tas;
				} else {
					if (Math.abs(result.Delta__c) > Math.abs(tas.Delta__c)) result = tas;
				}
			}
			return result;
		}
		query = 'SELECT ' + taskFields +
				' FROM Task WHERE OwnerId = \'' + userId +
				'\' AND Status != \'' + TASK_STAGE_IN_PROGESS +
				'\' AND Status != \'' + TASK_STAGE_DONE +
				'\' AND Delta__c < ' + -TIME_INTERVAL_MINUTES + ' ORDER BY Priority';
		try {
			tasks = Database.query(query);
		} catch (Exception ex) {
			System.debug(LoggingLevel.ERROR, ex.getMessage());
		}
		return (tasks.isEmpty() ? null : tasks.get(0));
	}

}