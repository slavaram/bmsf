global class CardTasksScheduler implements Schedulable {

	private static final String JOB_NAME = 'CardTasksScheduler.cls';
	private static final String CRON_EXP = '0 0 12 ? * * *';

	public static final String FOLDER_NAME			= 'AlertEmails';
	public static final String BEFORE_14_TEMPLATE	= 'Before14';
	public static final String IN_DATE_TEMPLATE		= 'InDate';
	public static final String AFTER_7_TEMPLATE		= 'After7';

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
		Map<Id, Card__c> lastCards			= new Map<Id, Card__c>();
		List<Card__c> taskCards				= new List<Card__c>();
		List<Card__c> before14cards			= new List<Card__c>();
		List<Card__c> inDateCards			= new List<Card__c>();
		List<Card__c> after7Cards			= new List<Card__c>();
		Map<String, Id> emailTemplates		= new Map<String, Id>();
		List<String> templateNames			= new List<String> {BEFORE_14_TEMPLATE, IN_DATE_TEMPLATE, AFTER_7_TEMPLATE};
		for (EmailTemplate template : [SELECT Id, DeveloperName FROM EmailTemplate WHERE Folder.DeveloperName = :FOLDER_NAME AND DeveloperName IN :templateNames]) {
			emailTemplates.put(template.DeveloperName, template.Id);
		}
		List<Messaging.SingleEmailMessage> emails	= new List<Messaging.SingleEmailMessage>();
		for (Card__c card : [SELECT Id, AccountId__c, AccountId__r.OwnerId, AccountId__r.Owner.ManagerId, OpportunityId__c, AccountId__r.PersonEmail, EndDate__c
		                     FROM Card__c
		                     WHERE Type__c = 'Карта'
		                     AND SubType__c IN ('Зеленая', 'Черная', 'Золотая')
		                     ORDER BY EndDate__c]) {
			if (lastCards.get(card.AccountId__c) == null) {
				lastCards.put(card.AccountId__c, card);
				if (card.EndDate__c == System.today().addDays(-3))	taskCards.add(card);
				if (card.EndDate__c == System.today().addDays(-14))	before14cards.add(card);
				if (card.EndDate__c == System.today())				inDateCards.add(card);
				if (card.EndDate__c == System.today().addDays(7))	after7Cards.add(card);
			}
		}
		assignTasks(taskCards);
		emails.addAll(createEmails(before14cards, emailTemplates.get(BEFORE_14_TEMPLATE)));
		emails.addAll(createEmails(inDateCards, emailTemplates.get(IN_DATE_TEMPLATE)));
		emails.addAll(createEmails(after7Cards, emailTemplates.get(AFTER_7_TEMPLATE)));
		sendEmails(emails);
	}

	private void assignTasks(List<Card__c> cards) {
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
						ActivityDate		= System.today(),
						Goal__c				= '',
						Priority			= '3',
						WhoId				= contactId,
						WhatId				= opportunityId);
	}

	private List<Messaging.SingleEmailMessage> createEmails(List<Card__c> cards, Id templateId) {
		List<Messaging.SingleEmailMessage> result = new List<Messaging.SingleEmailMessage>();
		Map<Id, Id> contactIds = new Map<Id, Id>();
		for (Card__c card : cards) {
			contactIds.put(card.AccountId__c, null);
		}
		for (Contact con : [SELECT Id, AccountId FROM Contact WHERE AccountId IN :contactIds.keySet()]) {
			contactIds.put(con.AccountId, con.Id);
		}
		for (Card__c card : cards) {
			Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
			email.setToAddresses(new List<String> {card.AccountId__r.PersonEmail});
			email.setTemplateId(templateId);
			email.setTargetObjectId(contactIds.get(card.AccountId__c));
			email.setSaveAsActivity(false);
			result.add(email);
		}
		return result;
	}

	private void sendEmails(List<Messaging.SingleEmailMessage> emails) {
		Messaging.sendEmail(emails);
	}

}