@isTest
class OpportunityMethodsTest {

	static testmethod void test() {
		RecordType singleRecord = [SELECT Id FROM RecordType WHERE DeveloperName = 'SingleRecord'].get(0);
		RecordType paketRecord	= [SELECT Id FROM RecordType WHERE DeveloperName = 'PaketRecord'].get(0);
		Id pricebookId			= Test.getStandardPricebookId();
		Product2 singleProductOne = new Product2(Name = 'Product one', IsActive = true, RecordTypeId = singleRecord.Id);
		Product2 singleProductTwo = new Product2(Name = 'Product two', IsActive = true, RecordTypeId = singleRecord.Id);
		insert singleProductOne;
		insert singleProductTwo;
		PricebookEntry entryOne = new PricebookEntry(IsActive = true, Pricebook2Id = pricebookId, Product2Id = singleProductOne.Id, UnitPrice = 100, UseStandardPrice = false);
		PricebookEntry entryTwo = new PricebookEntry(IsActive = true, Pricebook2Id = pricebookId, Product2Id = singleProductTwo.Id, UnitPrice = 200, UseStandardPrice = false);
		insert entryOne;
		insert entryTwo;
		Product2 paketProduct = new Product2(Name				= 'Product three',
											 IsActive			= true,
											 RecordTypeId		= paketRecord.Id,
											 ProductIds__c		= singleProductOne.Id + ';' + singleProductTwo.Id + ';',
											 ProductPercents__c	= '50.0;50.0;');
		insert paketProduct;
		Account acc = new Account(Name = 'Test');
		insert acc;
		Action__c actionOne = new Action__c(Name = 'Test action one', StartDate__c = System.today().addDays(-7), EndDate__c = System.today());
		Action__c actionTwo = new Action__c(Name = 'Test action two', StartDate__c = System.today().addDays(-7), EndDate__c = System.today());
		insert actionOne;
		insert actionTwo;
		Opportunity opp = new Opportunity(AccountId		= acc.Id,
										  ProductId__c	= paketProduct.Id,
										  ActionIds__c	= actionOne.Id + ';' + actionTwo.Id,
										  StageName		= 'Новая',
										  CloseDate		= System.today());
		insert opp;
		Action__c actionThree = new Action__c(Name = 'Test action three', StartDate__c = System.today().addDays(-7), EndDate__c = System.today());
		insert actionThree;
		OpportunityMethods.DONE = false;
		opp.ActionIds__c = opp.ActionIds__c.substringBefore(';') + ';' + actionThree.Id;
		update opp;
		System.assert(null != opp);
	}

}