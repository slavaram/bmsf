@isTest(seeAllData=true)
class CardTasksSchedulerTest {

	static testmethod void test() {
        Test.startTest();
        Contact contactOne = [SELECT Id, AccountId FROM Contact LIMIT 50].get(0);
        Contact contactTwo = [SELECT Id, AccountId FROM Contact LIMIT 50].get(10);
		Card__c cardOne = new Card__c(AccountId__c = contactOne.AccountId, Type__c = 'Карта', SubType__c = 'Зеленая', StartDate__c = System.today(), EndDate__c = System.today());
		Card__c cardTwo = new Card__c(AccountId__c = contactTwo.AccountId, Type__c = 'Карта', SubType__c = 'Золотая', StartDate__c = System.today(), EndDate__c = System.today().addDays(3));
		insert cardOne;
		insert cardTwo;
		System.schedule('Test job', '0 0 12 ? * * *', new CardTasksScheduler());
        Test.stopTest();
        System.assert([SELECT Id FROM Task WHERE Subject = 'Через 3 дня заканчивается карта МГ. Продать новую.'].size() > 0);
	}

}