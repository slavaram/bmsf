global class CardTasksScheduler implements Schedulable {

	private static final String JOB_NAME = 'CardTasksScheduler.cls';
	private static final String CRON_EXP = '0 0 12 ? * * *';

	public static Boolean run() {
		SavePoint save = Database.setSavepoint();
		try {
			String jobId = System.schedule(CardTasksScheduler.JOB_NAME,
										   CardTasksScheduler.CRON_EXP,
										   new CardTasksScheduler());
			CacheManager.cache(SchedulableManager.JOB_IDS_MAP, new Map<String, String> {CardTasksScheduler.JOB_NAME => jobId});
			return true;
		} catch (Exception ex) {
			Database.rollback(save);
			System.debug(LoggingLevel.ERROR, '[CardTasksScheduler] Unable to run apex job.');
			return false;
		}
	}

	public static Boolean abort() {
		SavePoint save = Database.setSavepoint();
		try {
			System.abortJob(CacheManager.getMap(SchedulableManager.JOB_IDS_MAP).get(CardTasksScheduler.JOB_NAME));
			CacheManager.release(SchedulableManager.JOB_IDS_MAP, new Set<String> {CardTasksScheduler.JOB_NAME});
			return true;
		} catch (Exception ex) {
			Database.rollback(save);
			System.debug(LoggingLevel.ERROR, '[CardTasksScheduler] Unable to abort apex job.');
			return false;
		}
	}

	global void execute(SchedulableContext context) {
		List<Card__c> cards = [SELECT Id, AccountId__c, AccountId__r.OwnerId, AccountId__r.Owner.ManagerId, OpportunityId__c
		                       FROM Card__c
		                       WHERE EndDate__c = :System.today().addDays(3)
		                       AND Type__c = 'Карта'
		                       AND SubType__c IN ('Зеленая', 'Черная', 'Золотая')];
		Set<Id> seniorManagers	= new Set<Id>();
		List<Id> accountIds		= new List<Id>();
		Map<Id, Id> accounts	= new Map<Id, Id>();
		for (User seniorManager : [SELECT Id FROM User WHERE IsActive = true AND ProfileId = :ApexUtils.getProfileIdByKey('senior manager')]) {
			seniorManagers.add(seniorManager.Id);
		}
		for (Card__c card : cards) {
			accountIds.add(card.AccountId__c);
		}
		for (Contact con : [SELECT Id, AccountId FROM Contact WHERE AccountId IN :accountIds]) {
			accounts.put(con.AccountId, con.Id);
		}
		List<Task> toInsert	= new List<Task>();
		Set<Id> managers	= DailyAttendanceManager.getUsersByDay(System.today());
		for (Card__c card : cards) {
			String managerId		= card.AccountId__r.OwnerId;
			if (managers.contains(managerId)) {
				toInsert.add(createTask(managerId, accounts.get(card.AccountId__c), card.OpportunityId__c));
			} else {
				if (card.AccountId__r.Owner.ManagerId != NULL && seniorManagers.contains(card.AccountId__r.Owner.ManagerId)) {
					toInsert.add(createTask(card.AccountId__r.Owner.ManagerId, accounts.get(card.AccountId__c), card.OpportunityId__c));
				} else {
					Integer index = (Integer) Math.floor(Math.random() * seniorManagers.size());
					List<Id> seniorManagersList = new List<Id>(seniorManagers);
					toInsert.add(createTask(seniorManagersList.get(index), accounts.get(card.AccountId__c), card.OpportunityId__c));
				}
			}
		}
		if (!toInsert.isEmpty()) insert toInsert;
	}

	private Task createTask(Id userId, Id contactId, Id opportunityId) {
		return new Task(OwnerId				= userId,
						Subject				= 'Через 3 дня заканчивается карта МГ. Продать новую.',
						ActivityDateTime__c	= System.now().addMinutes(60),
						Goal__c				= '',
						Priority			= '3',
						WhoId				= contactId,
						WhatId				= opportunityId);
	}

}