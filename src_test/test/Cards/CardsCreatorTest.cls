@isTest
class CardsCreatorTest {

	static testmethod void test() {
		Account acc = new Account(Name = 'Test acc');
		insert acc;
		Card__c card = new Card__c(AccountId__c = acc.Id, StartDate__c = System.today(), EndDate__c = System.today().addDays(1), Type__c = 'Карта', SubType__c = 'Золотая');
		insert card;
		System.assertNotEquals(null, card.Id);
	}

}