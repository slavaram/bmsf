trigger ApplicationsActivitiesProcess on ApplicationsActivities__c (before insert) {

	if (trigger.isBefore) {
		List<Id> opportunityIds	= new List<Id>();
		List<Id> actionIds		= new List<Id>();
		for (ApplicationsActivities__c activity : trigger.new) {
			opportunityIds.add(activity.OpportunityId__c);
			actionIds.add(activity.ActionID__c);
		}
		delete [SELECT Id FROM ApplicationsActivities__c WHERE OpportunityId__c IN :opportunityIds AND ActionID__c IN :actionIds];
	}

}