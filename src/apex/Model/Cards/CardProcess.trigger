trigger CardProcess on Card__c (before insert) {

	if (trigger.isBefore) {
		List<Id> opportunityIds = new List<Id>();
		for (Card__c card : trigger.new) {
			if (card.OpportunityId__c != null) opportunityIds.add(card.OpportunityId__c);
		}
		delete [SELECT Id FROM Card__c WHERE OpportunityId__c IN :opportunityIds];
	}

}