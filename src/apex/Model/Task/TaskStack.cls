public without sharing class TaskStack {

	private static final String TASK_STAGE_IN_PROGESS	= 'Выполняется';
	private static final String TASK_STAGE_DONE			= 'Завершено';
	private static final Integer TIME_INTERVAL_MINUTES	= 15;

	public static List<Task> getTasksInProgres(Id userId) {
		List<Task> result = new List<Task>();
		String query = 'SELECT ' + String.join(getTaskFields(), ', ') +
				' FROM Task WHERE OwnerId = \'' + userId +
				'\' AND Status = \'' + TASK_STAGE_IN_PROGESS + '\' ORDER BY CreatedDate';
		try {
			result = Database.query(query);
		} catch (Exception ex) {}
		return result;
	}

	public static Task getTaskToBeDone(Id userId) {
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

	public static CampaignMember getCampaignMemberForNewTask(Id userId) {
		List<CampaignMember> result = selectCampaignMembers(userId);
		if (result.isEmpty()) result = selectCampaignMembers(null);
		return (result.isEmpty() ? null : result.get(0));
	}

	private static List<String> getTaskFields() {
		return new List<String>(Schema.SObjectType.Task.fields.getMap().keySet());
	}

	private static List<CampaignMember> selectCampaignMembers(Id userId) {
		List<CampaignMember> result = new List<CampaignMember>();
		String query = 'SELECT Id ' +
						'FROM CampaignMember ' +
						'WHERE Campaign.IsActive = true ' +
						'AND IsCallTaskCreated__c = false ' +
						'AND ContactId != null ' +
						'AND Contact.AccountId != null ' +
						(userId == null ?
								'AND (Contact.Account.Owner.IsActive = false OR Contact.Account.Owner.Name = \'Администратор\') ' :
								'AND Contact.Account.OwnerId = \'' + userId + '\' ') +
						'ORDER BY Campaign.Priority__c ' +
						'LIMIT 100';
		try {
			result = Database.query(query);
		} catch (Exception ex) {
			// TODO
		}
		return result;
	}

}