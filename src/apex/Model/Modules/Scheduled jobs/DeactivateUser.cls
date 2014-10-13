global class DeactivateUser implements Schedulable {

	private static final String JOB_NAME = 'DeactivateUser.cls';
	private static final String CRON_EXP = '0 0 10 ? * * *';

	public static Boolean run() {
		SavePoint save = Database.setSavepoint();
		try {
			String jobId = System.schedule(DeactivateUser.JOB_NAME,
										   DeactivateUser.CRON_EXP,
										   new DeactivateUser());
			CacheManager.cache(SchedulableManager.JOB_IDS_MAP, new Map<String, String> {DeactivateUser.JOB_NAME => jobId});
			return true;
		} catch (Exception ex) {
			Database.rollback(save);
			System.debug(LoggingLevel.ERROR, '[DeactivateUser] Unable to run apex job.');
			return false;
		}
	}

	public static Boolean abort() {
		SavePoint save = Database.setSavepoint();
		try {
			System.abortJob(CacheManager.getMap(SchedulableManager.JOB_IDS_MAP).get(DeactivateUser.JOB_NAME));
			CacheManager.release(SchedulableManager.JOB_IDS_MAP, new Set<String> {DeactivateUser.JOB_NAME});
			return true;
		} catch (Exception ex) {
			Database.rollback(save);
			System.debug(LoggingLevel.ERROR, '[DeactivateUser] Unable to abort apex job.');
			return false;
		}
	}

	global void execute(SchedulableContext sc) {
		List<User> users = [SELECT id, isActive from User Where isActive = true and isDeActive__c = true];
		for(User user: users) {
			user.isActive = false;
		}
		update users;
	}

}