@isTest
class NetPaymentTest {

	private static Id accountId;
	private static Id opportunityId;

	private static void prepareData() {
		Account acc = new Account(Name = 'TestAccount');
		insert acc;
		accountId = acc.Id;
		Product2 pro = new Product2(Name = 'TestProduct');
		insert pro;
		Opportunity opp = new Opportunity(AccountId = accountId, StageName = 'Новая', CloseDate = System.today(), ProductId__c = pro.Id);
		insert opp;
		opportunityId = opp.Id;
	}

	public static testmethod void processNetPaymentsTest() {
		prepareData();
		Payment__c pay = new Payment__c(OpportunityID__c = opportunityId, Summ__c = 1000);
		insert pay;
		System.assertEquals(true, [SELECT IsNetPayment__c FROM Payment__c WHERE Id = :pay.Id].get(0).IsNetPayment__c);
	}

	public static testmethod void processNetPaymentsInCallPeriodTest() {
		prepareData();
		Task tas = new Task(ActivityDate = System.today(), IsCallAccepted__c = true, WhatId = accountId); 
		insert tas;
		Payment__c pay = new Payment__c(OpportunityID__c = opportunityId, Summ__c = 1000);
		insert pay;
		System.assertEquals(false, [SELECT IsNetPayment__c FROM Payment__c WHERE Id = :pay.Id].get(0).IsNetPayment__c);
	}

}