global class Schedulable_RefreshOpportunities implements Schedulable {

	private static final String JOB_NAME = 'Schedulable_RefreshOpportunities.cls';
	private static final String CRON_EXP = '0 0 0 ? * * *';
	private static final List<String> EXCEPT_STAGE_NAMES = new List<String> {
			'Оплачено',
			'Условно оплачено',
			'Отмена',
			'Дубль',
			'Отказ',
			'Условный отказ'
		};

	public static Boolean run() {
		SavePoint save = Database.setSavepoint();
		try {
			String jobId = System.schedule(Schedulable_RefreshOpportunities.JOB_NAME,
										   Schedulable_RefreshOpportunities.CRON_EXP,
										   new Schedulable_RefreshOpportunities());
			CacheManager.cache(SchedulableManager.JOB_IDS_MAP, new Map<String, String> {Schedulable_RefreshOpportunities.JOB_NAME => jobId});
			return true;
		} catch (Exception ex) {
			Database.rollback(save);
			System.debug(LoggingLevel.ERROR, '[Schedulable_RefreshOpportunities] Unable to run apex job.');
			return false;
		}
	}

	public static Boolean abort() {
		SavePoint save = Database.setSavepoint();
		try {
			System.abortJob(CacheManager.getMap(SchedulableManager.JOB_IDS_MAP).get(Schedulable_RefreshOpportunities.JOB_NAME));
			CacheManager.release(SchedulableManager.JOB_IDS_MAP, new Set<String> {Schedulable_RefreshOpportunities.JOB_NAME});
			return true;
		} catch (Exception ex) {
			Database.rollback(save);
			System.debug(LoggingLevel.ERROR, '[Schedulable_RefreshOpportunities] Unable to abort apex job.');
			return false;
		}
	}

	global void execute(SchedulableContext context) {
		List<Opportunity> opportunities = [SELECT Id
		                                   FROM Opportunity
		                                   WHERE StageName
		                                   NOT IN : Schedulable_RefreshOpportunities.EXCEPT_STAGE_NAMES];
		update opportunities;
	}

}