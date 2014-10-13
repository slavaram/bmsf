public class AutoTask {

	public Boolean isCreateNextTask {
		get {return (isCreateNextTask != null ? isCreateNextTask : true);}
		set;
	}
	public Boolean isFindAutoTask {
		get {return (isFindAutoTask != null ? isFindAutoTask : false);}
		set;
	}
	public Task thisTask {
		get {return (thisTask != null ? thisTask : new Task());}
		set;
	}
	public String oldStageName {
		get {return (oldStageName != null ? oldStageName : '' );}
		set;
	}
	public String stageName {get;set;}

	public AutoTask() {
		OldStageName = '';
	}

	public AutoTask(String stageName) {
		oldStageName = (String.isNotBlank(StageName) ? stageName : '');
	}

	public void setAutoTask() {
		isFindAutoTask = false;
		if (oldStageName != stageName) {
			Map<String, Tasks__c> autoTasks = Tasks__c.getAll();
			if (autoTasks.containsKey(stageName)) {
				isCreateNextTask = true;
				thisTask = new Task();
				thisTask.ReminderDateTime = Datetime.newInstance(Date.today(), Time.newInstance(10, 0, 0, 0)).addDays(Integer.valueOf(AutoTasks.get(StageName).Days__c));
				thisTask.Subject = autoTasks.get(stageName).TaskName__c;
				isFindAutoTask = true;
			}
		}
	}

	public String changeAutoTask(String stageName, String opportunityId) {
		String result = '';
		if (oldStageName != stageName ) {
			Map<String, Tasks__c> autoTasks = Tasks__c.getAll();
			if (autoTasks.containsKey(stageName)) {
				Task nextTask;
				try {
					nextTask = [SELECT Id, ReminderDateTime, ActivityDate
								FROM Task
								WHERE whatId = :opportunityId
								AND subject = :thisTask.Subject
								ORDER BY CreatedDate DESC
								LIMIT 1];
				} catch (Exception ex) {
					nextTask = new Task();
				}
				if (isCreateNextTask == true) {
					nextTask = changeAutoTaskField(nextTask, thisTask);
					try {
						update nextTask;
					} catch (Exception ex) {
						if (nextTask.Id != null ) result = nextTask.Id;
					}
				} else {
					try {
						delete nextTask;
					} catch (Exception ex) {}
				}
			}
		}
		return result;
	}

	public Task changeAutoTaskField(Task nextTask, Task taskObj) {
		if (taskObj.reminderDateTime != null ) {
			nextTask.ReminderDateTime	= taskObj.ReminderDateTime;
			nextTask.ActivityDate		= Date.valueOf(taskObj.ReminderDateTime);
		}
		return nextTask;
	}

}