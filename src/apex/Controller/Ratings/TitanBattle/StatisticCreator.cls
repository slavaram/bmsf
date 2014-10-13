public with sharing class StatisticCreator implements Schedulable {

	private static final String JOB_NAME = 'StatisticCreator.cls';
	private static final String CRON_EXP = '0 0 5 ? * * *';

	public static Boolean run() {
		SavePoint save = Database.setSavepoint();
		try {
			String jobId = System.schedule(StatisticCreator.JOB_NAME,
										   StatisticCreator.CRON_EXP,
										   new StatisticCreator());
			CacheManager.cache(SchedulableManager.JOB_IDS_MAP, new Map<String, String> {StatisticCreator.JOB_NAME => jobId});
			return true;
		} catch (Exception ex) {
			Database.rollback(save);
			System.debug(LoggingLevel.ERROR, '[StatisticCreator] Unable to run apex job.');
			return false;
		}
	}

	public static Boolean abort() {
		SavePoint save = Database.setSavepoint();
		try {
			System.abortJob(CacheManager.getMap(SchedulableManager.JOB_IDS_MAP).get(StatisticCreator.JOB_NAME));
			CacheManager.release(SchedulableManager.JOB_IDS_MAP, new Set<String> {StatisticCreator.JOB_NAME});
			return true;
		} catch (Exception ex) {
			Database.rollback(save);
			System.debug(LoggingLevel.ERROR, '[StatisticCreator] Unable to abort apex job.');
			return false;
		}
	}

	public void execute(SchedulableContext sc) {
		createYesterDayUserStatistic();
		createYesterDayGroupStatistic();
	}

	@future
	public static void createYesterDayUserStatistic() {
		UserStats.createAllManagersStats(date.today().addDays(-1), date.today().addDays(-1));
	}

	@future
	public static void createYesterDayGroupStatistic() {
		GroupStats.createGroupStatsForTitanBattle(date.today().addDays(-1), '');
	}

}