@isTest
class CertificateCreatorTest {

	static testmethod void createCertificatesTest() {
		Account acc = new Account(Name = 'Test acc');
		insert acc;
		RecordType singleRecord	= [SELECT Id FROM RecordType WHERE DeveloperName = 'SingleRecord'].get(0);
		Id pricebookId			= Test.getStandardPricebookId();
		Product2 product		= new Product2(Name = 'Product one', IsActive = true, RecordTypeId = singleRecord.Id);
		insert product;
		PricebookEntry entry = new PricebookEntry(IsActive = true, Pricebook2Id = pricebookId, Product2Id = product.Id, UnitPrice = 1000, UseStandardPrice = false);
		insert entry;
		Action__c action = new Action__c(Name = 'Test action two', StartDate__c = System.today().addDays(-7), EndDate__c = System.today());
		insert action;
		CertificateProducts__c cardProduct = new CertificateProducts__c(Name				= 'Light',
																	    MonthsDuration__c	= 1,
																	    DaysDuration__c		= 1,
																	    ProductId__c		= product.Id,
																	    Products__c			= 'test');
		insert cardProduct;
		Opportunity opp = new Opportunity(AccountId		= acc.Id,
										  ProductId__c	= product.Id,
										  ActionIds__c	= action.Id,
										  StageName		= 'Новая',
										  CloseDate		= System.today());
		insert opp;
		Payment__c pay = new Payment__c(DateOfPayment__c	= System.today(),
										Summ__c				= 1000,
										PaymentSource__c	= 'test',
										TypeOfPayment__c	= 'testetse',
										OpportunityID__c	= opp.Id);
		insert pay;
		OpportunityMethods.DONE 				= false;
		OpportunityMethods.CERTIFICATES_DONE	= false;
		opp.StageName							= 'Оплачено';
		update opp;
		System.assert(0 != [SELECT Id FROM Certificate__c].size());
	}

}