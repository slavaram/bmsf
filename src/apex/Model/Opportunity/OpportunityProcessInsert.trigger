trigger OpportunityProcessInsert on Opportunity (before insert, after insert) {

	if (trigger.isBefore) {
		List<Id> listClientsIdAll = new List<Id>();
        Map<Id, Account> clientsMap = new Map<Id, Account>();
        for (Opportunity opp : trigger.new) {
            opp.Name = 'temp';
            listClientsIdAll.add(opp.AccountID);
            if (opp.FromSite__c == true) {
                opp.StageName = 'Новая';
                opp.CloseDate = Date.today().addDays(7);
            }
        }
        Id adminId = [SELECT Id FROM User WHERE Name = 'Администратор'].get(0).Id;
        for (Account client : [SELECT Id, PersonEmail, Phone, OwnerId, Owner.IsActive FROM Account WHERE Id in :listClientsIdAll]) {
            if (!client.Owner.IsActive) client.OwnerId = adminId;
            clientsMap.put(client.Id, client);
        }

		Map<Id, Account> toUpdate = new Map<Id, Account>();
		for (Opportunity opp : trigger.new)	{
			if (opp.IsAllocated__c == true) continue;
			try {
				Account client = clientsMap.get(opp.AccountId);
				if (client != null) {
					List<Account> doubleClients;
					if (client.Phone != null && client.Phone.length() > 5 && !String.isEmpty(client.PersonEmail)) {
						doubleClients = [SELECT Id, PersonEmail, Phone, OwnerId, Owner.IsActive
						                 FROM Account
						                 WHERE OwnerId != :adminId
						                 AND (PersonEmail = :client.PersonEmail OR Phone = :client.Phone)
						                 AND Owner.IsActive = true
						                 AND Owner.isNoAllocation__c = false
						                 LIMIT 1];
					}
					if (!doubleClients.isEmpty()) {
						client.OwnerId = doubleClients.get(0).OwnerId;
						toUpdate.put(client.Id, client);
					} else {
						opp.CleanOpp__c = true;
						CustomBMAllocation allocation = new CustomBMAllocation(opp, (String) client.OwnerId, adminId);					// MEGA FAIL !!!!!!!!!!!!!!!
						Id oppOwnerId = allocation.getUserForOpportunity();
						if (oppOwnerId != null) {
							opp.OwnerId = oppOwnerId;
							opp.isAllocated__c = true;
							if (client.OwnerId == adminId || !client.Owner.IsActive) {
	                            client.OwnerId = oppOwnerId;
	    						toUpdate.put(client.Id, client);
	                        }
						}
					}
				}
			} catch (Exception e) {}
		}
		if (!toUpdate.isEmpty()) update toUpdate.values();

		OpportunityMethods.setFieldValues(trigger.new);
	}

	if (trigger.isAfter) {
	    List<sObject> toInsert			= new List<sObject>();
	    List<Opportunity> opportunities	= new List<Opportunity>();
	    List<Id> productIds				= new List<Id>();
	    for (Opportunity opp : trigger.new) {
	    	if (opp.ProductId__c != null) {
	    		opportunities.add(opp);
	    		productIds.add(opp.ProductId__c);
	    	}
	    }
	    insert OpportunityMethods.createOpportunityLineItems(opportunities, productIds);											// ONE MORE MEGA FAIL !!!!!!!!!

	    for (Opportunity opp : trigger.new) {
	        if (opp.ActionIds__c != null) {
	            Set<Id> actionIds = OpportunityMethods.parceOpportunityActionIds(opp.ActionIds__c);
	            for (Id actionId : actionIds) {
	            	toInsert.add(new ApplicationsActivities__c(ActionID__c = actionId, OpportunityId__c = opp.Id));
	            }
	        }
	    }
		if (!toInsert.isEmpty()) insert toInsert;																						// YEAP, MEGA FAIL AGAIN !!!!!!!!!

		try {																															// ??????
		    for (ProductRoles__c par : ProductRoles__c.getAll().values()) {
	            OpportunityMethods.createAccountRoleForInsert(trigger.new, par.ProductName__c, par.RoleNumber__c);
	        }
		} catch (Exception ex) {}
	}

}