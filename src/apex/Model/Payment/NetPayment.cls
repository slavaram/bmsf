public class NetPayment {

	public static final Integer DAYS_AFTER_CALL = 60;

	public static void processNetPayments(List<Payment__c> payments) {
		Set<Id> opportunityIds = new Set<Id>();
		for (Payment__c pay : payments) {
			opportunityIds.add(pay.OpportunityID__c);
		}
		Map<Id, Id> accountIds = new Map<Id, Id>();
		for (Opportunity opp : [SELECT AccountId FROM Opportunity WHERE Id IN :opportunityIds]) {
			accountIds.put(Opp.Id, opp.AccountId);
		}
		List<Task> tasks = [SELECT Id, WhatId, ActivityDate
		                    FROM Task
		                    WHERE WhatId IN :accountIds.values()
		                    AND IsCallAccepted__c = true];
		for (Payment__c pay : payments) {
			Boolean hasTask = false;
			for (Task tas : tasks) {
				if (tas.WhatId == accountIds.get(pay.OpportunityID__c)) {
					Date taskDate = tas.ActivityDate;
					Date paymentDate = System.today();
					if (taskDate.daysBetween(paymentDate) <= 0 || taskDate.daysBetween(paymentDate) >= DAYS_AFTER_CALL) {
						hasTask = true;
					}
				}
			}
			pay.IsNetPayment__c = !hasTask;
		}
	}

}