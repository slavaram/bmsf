@isTest
class ApplicationsActivitiesProcessTest {

	static testmethod void test() {
		Opportunity opp	= new Opportunity(StageName = 'Новая', CloseDate = System.today());
		Action__c act	= new Action__c(Name = 'Action!');
		insert opp;
		insert act;
		ApplicationsActivities__c activity = new ApplicationsActivities__c(OpportunityId__c = opp.Id, ActionID__c = act.Id);
		insert activity;
		System.assertNotEquals(null, activity.Id);
	}

}