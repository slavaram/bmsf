public class CardsCreator {

	private static final String STATUS = 'Оплачено';

	public static void processOpportunities(Map<Id, Opportunity> oldOpportunities, Map<Id, Opportunity> newOpportunities) {
		List<Opportunity> toProcess = new List<Opportunity>();
		for (Opportunity oldOpp : oldOpportunities.values()) {
			Opportunity newOpp = newOpportunities.get(oldOpp.Id);
			if (oldOpp.StageName != STATUS && newOpp.StageName == STATUS) toProcess.add(newOpp);
		}
		if (!toProcess.isEmpty()) createCards(toProcess);
	}

	public static void processOpportunities(List<Opportunity> opportunities) {
		List<Opportunity> toProcess = new List<Opportunity>();
		for (Opportunity opp : opportunities) {
			if (opp.StageName == STATUS) toProcess.add(opp);
		}
		if (!toProcess.isEmpty()) createCards(toProcess);
	}

	private static void createCards(List<Opportunity> opportunities) {
		if (opportunities.isEmpty()) return;
		Map<Id, CardProducts__c> settings = new Map<Id, CardProducts__c>();
		for (CardProducts__c setting : CardProducts__c.getAll().values()) {
			settings.put(setting.ProductId__c, setting);
		}
		if (settings.isEmpty()) return;
		List<Card__c> toInsert		= new List<Card__c>();
		Map<Id, String> actionIds	= new Map<Id, Id>();
		Map<Id, Id> cityIds		= new Map<Id, Id>();
		for (Opportunity opp : opportunities) {
			if (opp.ActionIds__c != null) actionIds.put(opp.Id, (opp.ActionIds__c.contains(';') ? opp.ActionIds__c.substringBefore(';') : opp.ActionIds__c));
		}
		for (Action__c action : [SELECT Id, CityId__c FROM Action__c WHERE Id IN :actionIds.values()]) {
			cityIds.put(action.Id, action.CityId__c);
		}
		for (Opportunity opp : opportunities) {
			CardProducts__c setting = settings.get(opp.ProductId__c);
			if (setting != null) {
				Decimal count = (opp.countSeats__c == null ? 1 : opp.countSeats__c);
				while (count > 0) {
					toInsert.add(createCard(opp, cityIds.get(actionIds.get(opp.Id)), setting));
					count--;
				}
			}
		}
		if (!toInsert.isEmpty()) insert toInsert;
    	OpportunityMethods.CARDS_DONE = true;
	}

	private static Card__c createCard(Opportunity opp, Id cityId, CardProducts__c setting) {
		return new Card__c(Type__c			= setting.Type__c,
						 SubType__c			= setting.SubType__c,
						 StartDate__c		= opp.DateOfPayment__c,
						 EndDate__c			= opp.DateOfPayment__c.addMonths((Integer) setting.MonthsDuration__c).addDays((Integer) setting.DaysDuration__c),
						 OpportunityId__c	= opp.Id,
						 AccountId__c		= opp.AccountId,
						 CityId__c			= cityId,
						 Products__c		= setting.Products__c);
	}

}