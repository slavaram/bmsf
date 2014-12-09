@isTest
class CardTasksSchedulerTest {

	static testmethod void test() {
        Test.startTest();
        RecordType record	= [SELECT Id FROM RecordType WHERE DeveloperName = 'PersonAccount'].get(0);
		Account accOne		= new Account(LastName = 'Test acc one', PersonEmail = 'test@email.ru', RecordTypeId = record.Id);
		Account accTwo		= new Account(LastName = 'Test acc two', PersonEmail = 'test@email.ru', RecordTypeId = record.Id);
		Account accThree	= new Account(LastName = 'Test acc three', PersonEmail = 'test@email.ru', RecordTypeId = record.Id);
		Account accFour		= new Account(LastName = 'Test acc four', PersonEmail = 'test@email.ru', RecordTypeId = record.Id);
		insert accOne;
		insert accTwo;
		insert accThree;
		insert accFour;
		Card__c cardOne		= new Card__c(AccountId__c = accOne.Id, Type__c = 'Зеленая', StartDate__c = System.today().addDays(-30), EndDate__c = System.today());
		Card__c cardTwo		= new Card__c(AccountId__c = accTwo.Id, Type__c = 'Зеленая', StartDate__c = System.today().addDays(-30), EndDate__c = System.today().addDays(14));
		Card__c cardThree	= new Card__c(AccountId__c = accThree.Id, Type__c = 'Черная', StartDate__c = System.today().addDays(-30), EndDate__c = System.today().addDays(-7));
		Card__c cardFour	= new Card__c(AccountId__c = accFour.Id, Type__c = 'Черная', StartDate__c = System.today().addDays(-30), EndDate__c = System.today().addDays(3));
		insert cardOne;
		insert cardTwo;
		insert cardThree;
		insert cardFour;
		System.schedule('Test job', '0 0 12 ? * * *', new CardTasksScheduler());
        Test.stopTest();
        System.assert([SELECT Id FROM Task WHERE Subject = 'Через 3 дня заканчивается карта МГ. Продать новую.'].size() == 1);
	}

}