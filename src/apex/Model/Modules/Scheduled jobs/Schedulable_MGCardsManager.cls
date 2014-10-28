global class Schedulable_MGCardsManager implements Schedulable {

	/* Говнокод! Причины:
		1. Некорректное поле ActionIds__c в объекте Opportunity
		2. Архитектура Opportunity - ApplicationsActivities__c
	*/

	public static final Set<String> ACTION_IDS	{get; set;}
	public static final Set<String> PRODUCT_IDS {get; set;}

	private static final String JOB_NAME = 'Schedulable_MGCardsManager.cls';
	private static final String CRON_EXP = '0 0 12 ? * * *';

	static {
		ACTION_IDS = new Set<String>();
		ACTION_IDS.add('a0011000004iRATAA2'); // "МГ. Зеленая карта" [Sandbox]
		ACTION_IDS.add('a0011000004iRAOAA2'); // "МГ. Черная карта" [Sandbox]
		ACTION_IDS.add('a0011000004iRAdAAM'); // "МГ. Золотая карта" [Sandbox]
		ACTION_IDS.add('a00b000000CaOPRAA3'); // "МГ. Зеленая карта" [Production]
		ACTION_IDS.add('a00b000000CaOMMAA3'); // "МГ. Черная карта" [Production]
		ACTION_IDS.add('a00b000000CaOJMAA3'); // "МГ. Золотая карта" [Production]
		PRODUCT_IDS = new Set<String>();
		PRODUCT_IDS.add('01t11000000xPCaAAM'); // "МГ. Зеленая карта" [Sandbox]
		PRODUCT_IDS.add('01tb0000002GWtuAAG'); // "МГ. Черная карта" [Sandbox]
		PRODUCT_IDS.add('01t1100000139JbAAI'); // "МГ. Золотая карта" [Sandbox]
		PRODUCT_IDS.add('01tb0000002GWtpAAG'); // "МГ. Зеленая карта" [Production]
		PRODUCT_IDS.add('01t11000000xPCVAA2'); // "МГ. Черная карта" [Production]
		PRODUCT_IDS.add('01tb0000002GWtVAAW'); // "МГ. Золотая карта" [Production]
	}

	private class Card {
		String opportunityId			{get; set;}
		String productId				{get; set;}
		String productName				{get; set;}
		String[] actionIds				{get; set;}
		String actionId					{get; set;}
		String clientId					{get; set;}
		String clientEmail				{get; set;}
		String cardType					{get; set;}
		String applicationActivityId	{get; set;}
		String cityId					{get; set;}
		Date startDate					{get; set;}
		Date endDate					{get; set;}
	}

	public static Boolean run() {
		SavePoint save = Database.setSavepoint();
		try {
			String jobId = System.schedule(Schedulable_MGCardsManager.JOB_NAME,
										   Schedulable_MGCardsManager.CRON_EXP,
										   new Schedulable_MGCardsManager());
			CacheManager.cache(SchedulableManager.JOB_IDS_MAP, new Map<String, String> {Schedulable_MGCardsManager.JOB_NAME => jobId});
			return true;
		} catch (Exception ex) {
			Database.rollback(save);
			System.debug(LoggingLevel.ERROR, '[Schedulable_MGCardsManager] Unable to run apex job.');
			return false;
		}
	}

	public static Boolean abort() {
		SavePoint save = Database.setSavepoint();
		try {
			System.abortJob(CacheManager.getMap(SchedulableManager.JOB_IDS_MAP).get(Schedulable_MGCardsManager.JOB_NAME));
			CacheManager.release(SchedulableManager.JOB_IDS_MAP, new Set<String> {Schedulable_MGCardsManager.JOB_NAME});
			return true;
		} catch (Exception ex) {
			Database.rollback(save);
			System.debug(LoggingLevel.ERROR, '[Schedulable_MGCardsManager] Unable to abort apex job.');
			return false;
		}
	}

	global void execute(SchedulableContext context) {
		createNewCards(); // 6 soql queries
		processCardsDataValidation(); // 2 soql queries
		attachTasksForManagers(); // 3 soql queries
	}

	private void createNewCards() {
		List<Card> cards = new List<Card>();
		List<Opportunity> opps = [SELECT Id, DateOfPayment__c, ActionIds__c, ProductId__c, AccountId, Account.PersonEmail
								  FROM Opportunity
								  WHERE ProductId__c IN :Schedulable_MGCardsManager.PRODUCT_IDS
								  AND StageName = 'Оплачено'
								  AND LastModifiedDate >= YESTERDAY
								  AND ActionIds__c != NULL];
		for (Opportunity opp : opps) {
			// if ([Sandbox] || [Production])
			if (opp.ProductId__c == '01t11000000xPCaAAM' || opp.ProductId__c == '01tb0000002GWtuAAG') {
				Card card = new Card();
				card.opportunityId = opp.Id;
				card.productId = opp.ProductId__c;
				card.productName = 'МГ. Зеленая карта';
				card.actionIds = opp.ActionIds__c.split(';', 0);
				card.clientId = opp.Account.Id;
				card.startDate = opp.DateOfPayment__c;
				card.clientEmail = opp.Account.PersonEmail;
				cards.add(card);
			} else if (opp.ProductId__c == '01t1100000139JbAAI' || opp.ProductId__c == '01tb0000002GWtpAAG') {
				Card card = new Card();
				card.opportunityId = opp.Id;
				card.productId = opp.ProductId__c;
				card.productName = 'МГ. Черная карта';
				card.actionIds = opp.ActionIds__c.split(';', 0);
				card.clientId = opp.Account.Id;
				card.startDate = opp.DateOfPayment__c;
				card.clientEmail = opp.Account.PersonEmail;
				cards.add(card);
			} else if (opp.ProductId__c == '01t11000000xPCVAA2' || opp.ProductId__c == '01tb0000002GWtVAAW') {
				Card card = new Card();
				card.opportunityId = opp.Id;
				card.productId = opp.ProductId__c;
				card.productName = 'МГ. Золотая карта';
				card.actionIds = opp.ActionIds__c.split(';', 0);
				card.clientId = opp.Account.Id;
				card.startDate = opp.DateOfPayment__c;
				card.clientEmail = opp.Account.PersonEmail;
				cards.add(card);
			}
		}
		List<Action__c> allActionIds = [SELECT Id, ParentId__r.Name
										FROM Action__c
										WHERE ParentId__c IN :Schedulable_MGCardsManager.ACTION_IDS];
		for (Card card : cards) {
			for (String actionId : card.actionIds) {
				String cardType = null;
				if (actionId == 'a0011000004iRATAA2' || actionId == 'a00b000000CaOPRAA3') {
					card.cardType = 'Зеленая';
					card.actionId = actionId;
				} else if (actionId == 'a0011000004iRAOAA2' || actionId == 'a00b000000CaOMMAA3') {
					card.cardType = 'Черная';
					card.actionId = actionId;
				} else if (actionId == 'a0011000004iRAdAAM' || actionId == 'a00b000000CaOJMAA3') {
					card.cardType = 'Золотая';
					card.actionId = actionId;
				}
				if (cardType == null) {
					for (Action__c action : allActionIds) {
						if (actionId == action.Id) {
							card.cardType = action.ParentId__r.Name.substringAfter(' ').substringBefore(' ');
							card.actionId = actionId;
						}
					}
				}
			}
		}
		List<Card> correctCards = new List<Card>();
		List<String> actionIds = new List<String>();
		List<String> opportunityIds = new List<String>();
		List<String> clientIds = new List<String>();
		for (Card card : cards) {
			if (card.cardType != null && card.productName.contains(card.cardType)) {
				correctCards.add(card);
				actionIds.add(card.actionId);
				opportunityIds.add(card.opportunityId);
				clientIds.add(card.clientId);
			}
		}
		List<ApplicationsActivities__c> applicationsActivities = [SELECT Id, ActionID__c, OpportunityId__c
																  FROM ApplicationsActivities__c
																  WHERE ActionID__c = :actionIds
																  AND OpportunityId__c = :opportunityIds];
		List<String> applicationActivitiyIds = new List<String>();
		for (Card card : correctCards) {
			for (ApplicationsActivities__c appAct : applicationsActivities) {
				if (appAct.ActionID__c == card.actionId && appAct.OpportunityId__c == card.opportunityId) {
					card.applicationActivityId = appAct.Id;
					applicationActivitiyIds.add(appAct.Id);
				}
			}
		}
		List<MasterGroupCards__c> doubleCards = [SELECT Id, Client__c, ApplicationsActivitiesId__c, CardType__c
												 FROM MasterGroupCards__c
												 WHERE Client__c IN :clientIds
												 AND ApplicationsActivitiesId__c IN :applicationActivitiyIds
												 ORDER BY StartDate__c];
		for (MasterGroupCards__c doubleCard : doubleCards) {
			for (Integer i = 0; i < correctCards.size(); i++) {
				Card card = correctCards.get(i);
				if (doubleCard.Client__c == card.clientId &&
					doubleCard.ApplicationsActivitiesId__c == card.applicationActivityId &&
					doubleCard.CardType__c == card.cardType) {
					correctCards.remove(i);
					break;
				}
			}
		}
		List<Action__c> actions = [SELECT Id, CityId__c
								   FROM Action__c
								   WHERE Id IN :actionIds];
		for (Card card : correctCards) {
			for (Action__c action : actions) {
				if (card.actionId == action.Id) {
					card.cityId = action.CityId__c;
					break;
				}
			}
		}
		List<MasterGroupCards__c> toInsert = new List<MasterGroupCards__c>();
		for (Card card : correctCards) {
			String cardTypeFull = card.cardType + ' карта';
			Map<String, CardsDueDates__c> castomSetting = CardsDueDates__c.getAll();
			CardsDueDates__c cardSettings = castomSetting.get(cardTypeFull);
			Integer monthes = (Integer) cardSettings.MonthsCount__c;
			card.endDate = card.startDate.addMonths(monthes);
			toInsert.add(new MasterGroupCards__c(CardType__c = card.cardType,
												 Client__c = card.clientId,
												 StartDate__c = card.startDate,
												 EndDate__c = card.endDate,
												 ApplicationsActivitiesId__c = card.applicationActivityId,
												 CitiesId__c = card.cityId,
												 ClientEmail__c = card.clientEmail,
												 IsMasterGroupCard__c = true));
		}
		insert toInsert;
	}


	private void processCardsDataValidation() {
		List<MasterGroupCards__c> cards = [SELECT Id, Client__c, EndDate__c, IsLastCard__c, CardType__c
										   FROM MasterGroupCards__c
										   WHERE LastModifiedDate >= YESTERDAY
										   AND IsMasterGroupCard__c = true];
		Set<String> clientIds = new Set<String>();
		for (MasterGroupCards__c card : cards) {
			clientIds.add(card.Client__c);
		}
		if (clientIds.size() > 0) {
			List<MasterGroupCards__c> toUpdate = new List<MasterGroupCards__c>();
			List<MasterGroupCards__c> allCards = [SELECT Id, IsLastCard__c, Client__c, StartDate__c, EndDate__c
												  FROM MasterGroupCards__c
												  WHERE Client__c IN :clientIds
												  AND IsMasterGroupCard__c = true
												  ORDER BY Client__c];
			String clientId = allCards.get(0).Client__c;
			List<MasterGroupCards__c> clientCards = new List<MasterGroupCards__c>();
			MasterGroupCards__c lastCard;
			for (MasterGroupCards__c card : allCards) {
				if (card.Client__c == clientId) {
					clientCards.add(card);
				} else {
					lastCard = clientCards.get(0);
					for (Integer i = 1; i < clientCards.size(); i++) {
						MasterGroupCards__c newCard = clientCards.get(i);
						if (lastCard.EndDate__c >= newCard.EndDate__c) {
							newCard.IsLastCard__c = false;
							toUpdate.add(newCard);
						} else {
							lastCard.IsLastCard__c = false;
							toUpdate.add(lastCard);
							lastCard = newCard;
						}
					}
					lastCard.IsLastCard__c = true;
					toUpdate.add(lastCard);
					clientId = card.Client__c;
					clientCards.clear();
					clientCards.add(card);
				}
			}
			lastCard = clientCards.get(0);
			for (Integer i = 1; i < clientCards.size(); i++) {
				MasterGroupCards__c newCard = clientCards.get(i);
				if (lastCard.EndDate__c >= newCard.EndDate__c) {
					newCard.IsLastCard__c = false;
					toUpdate.add(newCard);
				} else {
					lastCard.IsLastCard__c = false;
					toUpdate.add(lastCard);
					lastCard = newCard;
				}
			}
			lastCard.IsLastCard__c = true;
			toUpdate.add(lastCard);
			update toUpdate;
		}
	}


	private void attachTasksForManagers() {
		Date threeDaysBefore = System.today().addDays(3);
		List<MasterGroupCards__c> cards = [SELECT Id, Client__c, Client__r.OwnerId, Client__r.Owner.ManagerId, ApplicationsActivitiesId__r.OpportunityId__c
										   FROM MasterGroupCards__c
										   WHERE EndDate__c = :threeDaysBefore
										   AND IsMasterGroupCard__c = true
										   AND IsLastCard__c = true];
		List<User> activeSenjorManagers = [SELECT Id
										   FROM User
										   WHERE IsActive = true
										   AND Profile.Name = :TaskAttachController.SENIOR_MANAGER_TAG];

		List<String> clientIds = new List<String>();
		for (MasterGroupCards__c card : cards) {
			clientIds.add(card.Client__c);
		}
		List<Contact> contacts = [SELECT Id, AccountId
								  FROM Contact
								  WHERE AccountId IN :clientIds];
		Map<String, String> accountWithContact = new Map<String, String>();
		for (String clientId : clientIds) {
			for (Contact contact : contacts) {
				if (contact.AccountId == clientId) {
					accountWithContact.put(clientId, contact.Id);
				}
			}
		}

		List<Task> toInsert = new List<Task>();
		Set<Id> managers = DailyAttendanceManager.getUsersByDay(System.today());
		for (MasterGroupCards__c card : cards) {
			String cardManager = card.Client__r.OwnerId;
			Boolean isSameManager = false;
			if (managers.contains(cardManager)) {
				toInsert.add(getTask(cardManager, accountWithContact.get(card.Client__c), card.ApplicationsActivitiesId__r.OpportunityId__c));
				isSameManager = true;
			}
			if (!isSameManager) {
				Boolean hasSenjorManager = false;
				if (card.Client__r.Owner.ManagerId != NULL) {
					for (User senjorManager : activeSenjorManagers) {
						if (senjorManager.Id == card.Client__r.Owner.ManagerId) {
							toInsert.add(getTask(senjorManager.Id, accountWithContact.get(card.Client__c), card.ApplicationsActivitiesId__r.OpportunityId__c));
							hasSenjorManager = true;
							break;
						}
					}
				}
				if (!hasSenjorManager) {
					Integer randomNumer = (Integer) Math.floor(Math.random() * activeSenjorManagers.size());
					User randomSenjorManager = activeSenjorManagers.get(randomNumer);
					toInsert.add(getTask(randomSenjorManager.Id, accountWithContact.get(card.Client__c), card.ApplicationsActivitiesId__r.OpportunityId__c));
				}
			}
		}
		insert toInsert;
	}


	private Task getTask(String ownerId, String whoId, String whatId) {
		return new Task(OwnerId = ownerId,
						Subject = 'Через 3 дня заканчивается карта МГ. Продать новую.',
						ActivityDate = System.today(),
						Priority = 'Высокий',
						WhoId = whoId,
						WhatId = whatId);
	}


}