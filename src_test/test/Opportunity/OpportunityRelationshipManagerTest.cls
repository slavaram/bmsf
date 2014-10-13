@isTest
class OpportunityRelationshipManagerTest {

 	static testmethod void executeTest() {
		Test.startTest();
		ProductGroup__c parentProductGroupA = new ProductGroup__c(Name = 'Parent product group A');
		ProductGroup__c parentProductGroupB = new ProductGroup__c(Name = 'Parent product group B');
		insert parentProductGroupA;
		insert parentProductGroupB;
		ProductGroup__c childProductGroupA = new ProductGroup__c(Name = 'Child product group A', ParentProductGroup__c = parentProductGroupA.Id);
		ProductGroup__c childProductGroupB = new ProductGroup__c(Name = 'Child product group B', ParentProductGroup__c = parentProductGroupB.Id);
		insert childProductGroupA;
		insert childProductGroupB;
		Product2 productA = new Product2(Name = 'Test product A', ProductGroup__c = childProductGroupA.Id);
		Product2 productB = new Product2(Name = 'Test product B', ProductGroup__c = childProductGroupB.Id);
		insert productA;
		insert productB;
		Account acc = new Account(Name = 'Test account');
		insert acc;
		Opportunity oppA = new Opportunity(AccountId = acc.Id, ProductId__c = productA.Id, StageName = 'Test', CloseDate = System.today().addDays(1));
		Opportunity oppB = new Opportunity(AccountId = acc.Id, ProductId__c = productB.Id, StageName = 'Оплачено', CloseDate = System.today());
		insert oppA;
		Opportunity opp = [SELECT Id, ProductId__r.ProductGroup__r.HierachyPath__c FROM Opportunity WHERE ID = :oppA.Id];
		insert oppB;
		insert new TopProductGroup__c(Name = 'Сервисы', Id__c = parentProductGroupA.Id);
		insert new TopProductGroup__c(Name = 'Интенсив, Коучинг', Id__c = parentProductGroupB.Id);
		insert new TopProductGroup__c(Name = 'Карьера', Id__c = childProductGroupA.Id);
		insert new TopProductGroup__c(Name = 'Самолет. VIP', Id__c = childProductGroupB.Id);
		insert new TopProductGroup__c(Name = 'Миллион за сто', Id__c = productA.Id);
		insert new TopProductGroup__c(Name = 'Отдел продаж', Id__c = productB.Id);
		Action__c actionA = new Action__c(Name = 'Action A', StartDate__c = System.today());
		Action__c actionB = new Action__c(Name = 'Action B', StartDate__c = System.today().addDays(-1));
		insert actionA;
		insert actionB;
		ApplicationsActivities__c apActA = new ApplicationsActivities__c(OpportunityId__c = oppA.Id, ActionID__c = actionA.Id);
		ApplicationsActivities__c apActB = new ApplicationsActivities__c(OpportunityId__c = oppB.Id, ActionID__c = actionB.Id);
		insert apActA;
		insert apActB;
		System.schedule('TEST', '0 0 0 ? * * *',  new OpportunityRelationshipManager());
		Test.stopTest();
		Opportunity newOppA = [SELECT Id, RelatedOpportunity__c FROM Opportunity WHERE Id = :oppA.Id].get(0);
		System.assertEquals(oppB.Id, newOppA.RelatedOpportunity__c);
 	}

}