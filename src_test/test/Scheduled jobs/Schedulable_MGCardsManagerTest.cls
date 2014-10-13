@isTest(seeAllData = true)
class Schedulable_MGCardsManagerTest {

 	static testmethod void test() {

		Test.startTest();

		/*List<Opportunity> opps = [SELECT Id, ActionIds__c
								  FROM Opportunity
							 	  WHERE ProductId__c IN :Schedulable_MGCardsManager.PRODUCT_IDS
							  	  AND StageName = 'Оплачено'
								  AND LastModifiedDate >= YESTERDAY
								  AND ActionIds__c != NULL];
		List<Action__c> actions = [SELECT Id
								   FROM Action__c
								   WHERE ParentId__c IN :Schedulable_MGCardsManager.ACTION_IDS];

		Integer opportunitiesCount = 0;
		for (Opportunity opp : opps) {
			for (Action__c action : actions) {
				if (opp.ActionIds__c.contains(action.Id) ||
					opp.ActionIds__c.contains('a0011000004iRATAA2') || opp.ActionIds__c.contains('a00b000000CaOPRAA3') ||
					opp.ActionIds__c.contains('a0011000004iRAOAA2') || opp.ActionIds__c.contains('a00b000000CaOMMAA3') ||
					opp.ActionIds__c.contains('a0011000004iRAdAAM') || opp.ActionIds__c.contains('a00b000000CaOJMAA3')) {
					opportunitiesCount++;
				}
			}
		}*/

		String jobId = System.schedule('Check new opportunities for cards',
										'0 0 12 ? * * *',
										new Schedulable_MGCardsManager());

		Test.stopTest();

		/*Integer cardsCount = [SELECT COUNT()
							  FROM MasterGroupCards__c
							  WHERE CreatedDate >= YESTERDAY];
		System.assertEquals(opportunitiesCount, cardsCount);*/
	}

}