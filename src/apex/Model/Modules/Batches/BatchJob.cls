global class BatchJob implements Database.Batchable<sObject> {

	global String QUERY_BODY;

	global BatchJob(String query) {
		QUERY_BODY = query;
	}

	global Database.QueryLocator start(Database.BatchableContext context) {
		return Database.getQueryLocator(QUERY_BODY);
	}

	global void execute(Database.BatchableContext context, List<Account> accounts) {
		Map<Id, Card__c> cards = new Map<Id, Card__c>();
		for (Card__c card : [SELECT Id, AccountId__c FROM Card__c WHERE Type__c IN ('Зеленая', 'Золотая', 'Черная') AND StartDate__c < TODAY AND EndDate__c >= TODAY]) {
			cards.put(card.AccountId__c, card);
		}
		for (Account acc : accounts) {
			Card__c card = cards.get(acc.Id);
			acc.MasterGroup__c = (card == null ? false : true);
		}
		update accounts;
	}

	global void finish(Database.BatchableContext context) {
		// TODO
	}

}