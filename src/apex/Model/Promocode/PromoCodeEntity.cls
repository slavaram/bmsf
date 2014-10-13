public class PromoCodeEntity {

	public static void reAllocateOpportunities(List<PromoCode__c> promoCodesList) {
		List<Id> accIds = new List<Id>();
		List<Id> oppIds = new List<Id>();
		for (PromoCode__c promoCode : promoCodesList) {
			accIds.add(promoCode.usedByAccount__c);
			oppIds.add(promoCode.OpportunityId__c);
		}
		List<Account> accs = [SELECT Id, OwnerId, Owner.ManagerId, Owner.Manager.IsActive, Owner.Manager.ProfileId
		                  	  FROM Account
		                  	  WHERE Id IN :accIds];
		List<Opportunity> opps = [SELECT Id, OwnerId
		                      	  FROM Opportunity
		                      	  WHERE Id IN :oppIds];
		Map<Id, Account> accsMap = new Map<Id, Account>(accs);
		Map<Id, Opportunity> oppsMap = new Map<Id, Opportunity>(opps);
		List<User> managers = [SELECT Id
		                       FROM User
		                       WHERE ProfileId = '00eb0000000QgSJ'
		                       AND IsActive = true
		                       AND Id != '005b0000001Nxzk'];  //Сагун1
		List<Opportunity> toUpdate = new List<Opportunity>();
		for (PromoCode__c promoCode : promoCodesList) {
			Account acc = accsMap.get(promoCode.usedByAccount__c);
			Opportunity opp = oppsMap.get(promoCode.OpportunityId__c);
			if (opp != null) {
				if (acc != null && acc.OwnerId != null && acc.Owner.ManagerId != null &&
						acc.Owner.Manager.IsActive = true && acc.Owner.Manager.ProfileId == '00eb0000000QgSJ') {
					opp.OwnerId = acc.Owner.ManagerId;
				} else {
					if (managers.size() > 0) opp.OwnerId = managers.get((Integer) (Math.floor(Math.random() * managers.size()))).Id;
				}
				toUpdate.add(opp);
			}
		}
		if (toUpdate.size() > 0) update toUpdate;
	}

}