public with sharing class Update_MG_Members implements Schedulable {

	private static final String JOB_NAME = 'Update_MG_Members.cls';
	private static final String CRON_EXP = '0 0 1 ? * * *';

	public static Boolean run() {
		SavePoint save = Database.setSavepoint();
		try {
			String jobId = System.schedule(Update_MG_Members.JOB_NAME,
										   Update_MG_Members.CRON_EXP,
										   new Update_MG_Members());
			CacheManager.cache(SchedulableManager.JOB_IDS_MAP, new Map<String, String> {Update_MG_Members.JOB_NAME => jobId});
			return true;
		} catch (Exception ex) {
			Database.rollback(save);
			System.debug(LoggingLevel.ERROR, '[Update_MG_Members] Unable to run apex job.');
			return false;
		}
	}

	public static Boolean abort() {
		SavePoint save = Database.setSavepoint();
		try {
			System.abortJob(CacheManager.getMap(SchedulableManager.JOB_IDS_MAP).get(Update_MG_Members.JOB_NAME));
			CacheManager.release(SchedulableManager.JOB_IDS_MAP, new Set<String> {Update_MG_Members.JOB_NAME});
			return true;
		} catch (Exception ex) {
			Database.rollback(save);
			System.debug(LoggingLevel.ERROR, '[Update_MG_Members] Unable to abort apex job.');
			return false;
		}
	}

	public void execute(SchedulableContext sc) {
		Date cdate = Date.today().addDays(-1);
		List<MasterGroupCards__c> cards = [
			select Client__c
			from MasterGroupCards__c
			where StartDate__c <= :cdate
			  and EndDate__c > :cdate
		]; 
		List<Id> accsIds = new List<Id>();
		for (MasterGroupCards__c item : cards) {
			accsIds.add(item.Client__c);
		}
		List<Account> accsToSwitch = [
			select MasterGroup__c
			from Account
			where Id in : accsIds];
		for (Account item : accsToSwitch) {
			item.MasterGroup__c = !item.MasterGroup__c;
		}
		update accsToSwitch;
	}
}