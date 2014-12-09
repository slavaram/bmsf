public class CertificateCreator {

	private static final String STATUS = 'Оплачено';

	public static void processOpportunities(Map<Id, Opportunity> oldOpportunities, Map<Id, Opportunity> newOpportunities) {
		List<Opportunity> toProcess = new List<Opportunity>();
		for (Opportunity oldOpp : oldOpportunities.values()) {
			Opportunity newOpp = newOpportunities.get(oldOpp.Id);
			if (oldOpp.StageName != STATUS && newOpp.StageName == STATUS) toProcess.add(newOpp);
		}
		if (!toProcess.isEmpty()) createCertificates(toProcess);
	}

	public static void processOpportunities(List<Opportunity> opportunities) {
		List<Opportunity> toProcess = new List<Opportunity>();
		for (Opportunity opp : opportunities) {
			if (opp.StageName == STATUS) toProcess.add(opp);
		}
		if (!toProcess.isEmpty()) createCertificates(toProcess);
	}

	private static void createCertificates(List<Opportunity> opportunities) {
		if (opportunities.isEmpty()) return;
		Map<Id, CertificateProducts__c> settings = new Map<Id, CertificateProducts__c>();
		for (CertificateProducts__c setting : CertificateProducts__c.getAll().values()) {
			settings.put(setting.ProductId__c, setting);
		}
		if (settings.isEmpty()) return;
		List<Certificate__c> toInsert = new List<Certificate__c>();
		for (Opportunity opp : opportunities) {
			CertificateProducts__c setting = settings.get(opp.ProductId__c);
			if (setting != null) {
				Decimal count = (opp.countSeats__c == null ? 1 : opp.countSeats__c);
				while (count > 0) {
					toInsert.add(createCard(opp, setting));
					count--;
				}
			}
		}
		if (!toInsert.isEmpty()) insert toInsert;
    	OpportunityMethods.CERTIFICATES_DONE = true;
	}

	private static Certificate__c createCard(Opportunity opp, CertificateProducts__c setting) {
		Date startDate = (opp.DateOfPayment__c == null ? System.today() : opp.DateOfPayment__c);
		return new Certificate__c(StartDate__c		= startDate,
								  EndDate__c		= startDate.addMonths((Integer) setting.MonthsDuration__c).addDays((Integer) setting.DaysDuration__c),
								  OpportunityId__c	= opp.Id,
								  AccountId__c		= opp.AccountId,
								  Products__c		= setting.Products__c,
								  Type__c			= setting.Name);
	}
}