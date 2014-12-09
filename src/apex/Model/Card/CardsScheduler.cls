global class CardsScheduler implements Schedulable {

	private static final String JOB_NAME = 'CardsScheduler.cls';
	private static final String CRON_EXP = '0 0 1 ? * * *';

	public static Boolean run() {
		SavePoint save = Database.setSavepoint();
		try {
			String jobId = System.schedule(CardsScheduler.JOB_NAME,
										   CardsScheduler.CRON_EXP,
										   new CardsScheduler());
			CacheManager.cache(SchedulableManager.JOB_IDS_MAP, new Map<String, String> {CardsScheduler.JOB_NAME => jobId});
			return true;
		} catch (Exception ex) {
			Database.rollback(save);
			System.debug(LoggingLevel.ERROR, '[CardsScheduler] Unable to run apex job.');
			return false;
		}
	}

	public static Boolean abort() {
		SavePoint save = Database.setSavepoint();
		try {
			System.abortJob(CacheManager.getMap(SchedulableManager.JOB_IDS_MAP).get(CardsScheduler.JOB_NAME));
			CacheManager.release(SchedulableManager.JOB_IDS_MAP, new Set<String> {CardsScheduler.JOB_NAME});
			return true;
		} catch (Exception ex) {
			Database.rollback(save);
			System.debug(LoggingLevel.ERROR, '[CardsScheduler] Unable to abort apex job.');
			return false;
		}
	}

	global void execute(SchedulableContext sc) {
		List<Account> accounts = [SELECT Id, MasterGroup__c
		                          FROM Account
		                          WHERE Id IN (SELECT AccountId__c FROM Card__c WHERE StartDate__c = YESTERDAY OR EndDate__c = YESTERDAY)];
		for (Account acc : accounts) {
			acc.MasterGroup__c = !acc.MasterGroup__c;
		}
		if (!accounts.isEmpty()) update accounts;
	}

}