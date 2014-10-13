global class Schedulable_CheckActiveCampaigns implements Schedulable {

	private static final String STATUS_FINISHED = 'Завершено';
    private static final Decimal ACTIVE_RATIO = 0.95;

	private static final String JOB_NAME = 'Schedulable_CheckActiveCampaigns.cls';
	private static final String CRON_EXP = '0 0 0 ? * * *';

	public static Boolean run() {
		SavePoint save = Database.setSavepoint();
		try {
			String jobId = System.schedule(Schedulable_CheckActiveCampaigns.JOB_NAME,
										   Schedulable_CheckActiveCampaigns.CRON_EXP,
										   new Schedulable_CheckActiveCampaigns());
			CacheManager.cache(SchedulableManager.JOB_IDS_MAP, new Map<String, String> {Schedulable_CheckActiveCampaigns.JOB_NAME => jobId});
			return true;
		} catch (Exception ex) {
			Database.rollback(save);
			System.debug(LoggingLevel.ERROR, '[Schedulable_CheckActiveCampaigns] Unable to run apex job.');
			return false;
		}
	}

	public static Boolean abort() {
		SavePoint save = Database.setSavepoint();
		try {
			System.abortJob(CacheManager.getMap(SchedulableManager.JOB_IDS_MAP).get(Schedulable_CheckActiveCampaigns.JOB_NAME));
			CacheManager.release(SchedulableManager.JOB_IDS_MAP, new Set<String> {Schedulable_CheckActiveCampaigns.JOB_NAME});
			return true;
		} catch (Exception ex) {
			Database.rollback(save);
			System.debug(LoggingLevel.ERROR, '[Schedulable_CheckActiveCampaigns] Unable to abort apex job.');
			return false;
		}
	}

	global void execute(SchedulableContext context) {
		List<Campaign> campaigns = [SELECT NumberOfContacts, TasksSize__c FROM Campaign WHERE IsActive = true];
		List<Campaign> toUpdate = new List<Campaign>();
		for(Campaign cam: campaigns) {
			if (cam.NumberOfContacts == cam.TasksSize__c) {
				cam.isActive = false;
				cam.Status = STATUS_FINISHED;
				toUpdate.add(cam);
			}
		}
		if (toUpdate.size() > 0) update toUpdate;
	}

}