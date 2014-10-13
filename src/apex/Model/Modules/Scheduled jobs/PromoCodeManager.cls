global class PromoCodeManager implements Schedulable {

	public static final String PROMO_CODE_PREFIX		= 'DRBM';
	public static final String UNUSED_PROMO_CODE_STATUS	= 'Новый';
	public static final Integer EXPIRE_PERIOD			= 7;

	private static final String JOB_NAME = 'PromoCodeManager.cls';
	private static final String CRON_EXP = '0 0 0 ? * * *';

	public static Boolean run() {
		SavePoint save = Database.setSavepoint();
		try {
			String jobId = System.schedule(PromoCodeManager.JOB_NAME,
										   PromoCodeManager.CRON_EXP,
										   new PromoCodeManager());
			CacheManager.cache(SchedulableManager.JOB_IDS_MAP, new Map<String, String> {PromoCodeManager.JOB_NAME => jobId});
			return true;
		} catch (Exception ex) {
			Database.rollback(save);
			System.debug(LoggingLevel.ERROR, '[PromoCodeManager] Unable to run apex job.');
			return false;
		}
	}

	public static Boolean abort() {
		SavePoint save = Database.setSavepoint();
		try {
			System.abortJob(CacheManager.getMap(SchedulableManager.JOB_IDS_MAP).get(PromoCodeManager.JOB_NAME));
			CacheManager.release(SchedulableManager.JOB_IDS_MAP, new Set<String> {PromoCodeManager.JOB_NAME});
			return true;
		} catch (Exception ex) {
			Database.rollback(save);
			System.debug(LoggingLevel.ERROR, '[PromoCodeManager] Unable to abort apex job.');
			return false;
		}
	}

	global void execute(SchedulableContext context) {
		reassignUnusedPromoCodes();
		assignPromoCodes();
	}

	global void assignPromoCodes() {
		Integer monthNow = System.today().month();
		Integer dayNow = System.today().day();
		String codePrefix = PROMO_CODE_PREFIX + '%';
		List<Account> accounts			= [SELECT Id, BirthDay__c
		                      			   FROM Account
		                      			   WHERE CALENDAR_MONTH(BirthDay__c) = :monthNow
		                      			   AND DAY_IN_MONTH(BirthDay__c) = :dayNow];
		List<PromoCode__c> promoCodes	= [SELECT Id, AccountId__c, AccountBirthDay__c
		                             	   FROM PromoCode__c
		                             	   WHERE Code__c LIKE :codePrefix
		                             	   AND Status__c = :UNUSED_PROMO_CODE_STATUS
		                             	   AND AccountId__c = null
		                             	   LIMIT :accounts.size()];
		for (Integer i = 0; i < accounts.size(); i++) {
			promoCodes.get(i).AccountId__c = accounts.get(i).Id;
			promoCodes.get(i).AccountBirthDay__c = System.today();
		}
		update promoCodes;
	}

	global void reassignUnusedPromoCodes() {
		String codePrefix = PROMO_CODE_PREFIX + '%';
		List<PromoCode__c> promoCodes	= [SELECT Id, AccountId__c, AccountBirthDay__c
		                             	   FROM PromoCode__c
		                             	   WHERE AccountBirthDay__c = :System.today().addDays(-EXPIRE_PERIOD)
		                             	   AND Status__c = :UNUSED_PROMO_CODE_STATUS
		                             	   AND Code__c LIKE :codePrefix];
		for (PromoCode__c promoCode : promoCodes) {
			promoCode.AccountId__c = null;
			promoCode.AccountBirthDay__c = null;
		}
		update promoCodes;
	}

}