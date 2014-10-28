trigger OpportunityProcessInsert on Opportunity (before insert, after insert) {

	if (trigger.isBefore) {
		List<Id> listClientsIdAll = new List<Id>();
        Map<Id, Account> clientsMap = new Map<Id, Account>();
        for (Opportunity opp : trigger.new) {
            opp.Name = 'temp';
            listClientsIdAll.add(opp.AccountID);
            opp.OwnerDup__c = opp.OwnerId;
            if (opp.FromSite__c == true) {
                opp.StageName = 'Новая';
                opp.CloseDate = Date.today().addDays(7);
            }
        }
        Id adminId = [SELECT Id FROM User WHERE Name = 'Администратор'].get(0).Id;
        for(Account client : [SELECT Id, PersonEmail, Phone, OwnerId, Owner.IsActive
                            FROM Account 
                            WHERE Id in :listClientsIdAll]) {

            if (client.Owner.IsActive == false) {
                client.OwnerId = adminId;
            }
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
					if (doubleClients.isEmpty() == false) {
						client.OwnerId = doubleClients.get(0).OwnerId;
						toUpdate.put(client.Id, client);
					}
					if (client.OwnerId == adminId) opp.CleanOpp__c = true;
					CustomBMAllocation allocation = new CustomBMAllocation(opp, (String) client.OwnerId, adminId);							//MEGA FAIL !!!!!!!!!!!!!!!
					Id oppOwnerId = allocation.getUserForOpportunity();
					if (oppOwnerId != null) {
						opp.OwnerId = oppOwnerId;
						opp.isAllocated__c = true;
						if (client.OwnerId == adminId
                                || !client.Owner.IsActive) {
                            client.OwnerId = oppOwnerId;
    						toUpdate.put(client.Id, client);
                        }
					}
				}
			} catch (Exception e) {}
		}
		if (!toUpdate.isEmpty()) update toUpdate.values();

		Map<String, String> mapOppNames = OpportunityMethod.generateAppNames(trigger.new);
		for (Opportunity opp : trigger.new) {
			if (mapOppNames.containsKey(opp.ActionIds__c))			opp.ActionNames__c = mapOppNames.get(opp.ActionIds__c);
			if (opp.Debt__c <= 0 && opp.IsPartlyPassed__c == true)	opp.StageName = 'Мероприятие пройдено частично';
			if (opp.Debt__c <= 0 && opp.IsComplete__c == true)		opp.StageName = 'Мероприятие пройдено';
		}
	}

	if (trigger.isAfter) {
	    List<Opportunity> opportunitiesWithChangedProduct	= new List<Opportunity>();
	    List<Id> listProductId								= new List<Id>();
	    for (Opportunity opp : trigger.new) {
	    	if (opp.ProductId__c != null) {
	    		opportunitiesWithChangedProduct.add(opp);
	    		listProductId.add(opp.ProductId__c);
	    	}
	    }
	    if (opportunitiesWithChangedProduct.size() > 0) {
	        List<Product2> productsFromOpportunities = [SELECT Id, ProductIds__c, ProductPercents__c 
	        											FROM Product2 
	        											WHERE Id IN :listProductId];
	        Map<Id, List<String>> packageAndProducts = new Map<Id, List<String>>();
	        Map<Id, List<String>> packageAndPercents = new Map<Id, List<String>>();
	        List<id> allProductIds = listProductId;
	        for (Product2 product : productsFromOpportunities) {
	            if (product.ProductIds__c != null && product.ProductPercents__c != null && 
	                product.ProductIds__c != '' && product.ProductPercents__c != '') {
	                List<String> ids = product.ProductIds__c.split(';', 0);
	                List<String> percents = product.ProductPercents__c.split(';', 0);
	                packageAndProducts.put(product.id, ids);
	                packageAndPercents.put(product.id, percents);
	                for (String idP : ids) {
	                    allProductIds.add(Id.valueOf(idP)); 
	                }
	            }
	        }
	        List<PriceBookEntry> priceBookEntries = [SELECT Id, Product2id, UnitPrice
											         FROM PriceBookEntry 
		                                             WHERE IsActive = true
		           									 AND PriceBook2.IsActive = true
		           									 AND PriceBook2.IsStandard = true
		           									 AND IsDeleted = false
		           									 AND Product2Id IN : allProductIds];
	        Map<Id, PriceBookEntry> productPrices = new Map<Id, PricebookEntry>();
	        for (PriceBookEntry priceBookEntry : priceBookEntries) {
	            productPrices.put(priceBookEntry.Product2Id, priceBookEntry);
	        }
	        List<Discount__c> listDiscount = [SELECT Id, Discount__c, ProductId__c, StartDate__c, EndDate__c 
	        								  FROM Discount__c 
	        								  WHERE ProductId__c IN : listProductId];
	        Map<Id, List<Discount__c>> productDiscounts = new Map<id, list<Discount__c>>();
	        for (Discount__c discount : listDiscount) {
	            List<Discount__c> discs = new List<Discount__c>();
	            if (productDiscounts.keySet().contains(discount.ProductId__c)) discs = productDiscounts.get(discount.ProductId__c);
	            discs.add(discount);
	            productDiscounts.put(discount.ProductId__c, discs);
	        }
	        List<OpportunityLineItem> oliToInsert = new List<OpportunityLineItem>();
	        for (Opportunity opp : opportunitiesWithChangedProduct) {
	            if (!productPrices.containsKey(opp.ProductId__c)) continue;
	            Double price = productPrices.containsKey(opp.ProductId__c) ? productPrices.get(opp.ProductId__c).UnitPrice : 0;
	            if (price == null) price = 0.0;
	            Double summaryDiscount = 0.0;
	            List<Discount__c> thisProductDiscounts = productDiscounts.get(opp.ProductId__c);
	            if (thisProductDiscounts != null && thisProductDiscounts.size() > 0) {
	                for (Discount__c disc : thisProductDiscounts) {
	                    if (disc.StartDate__c >= opp.CreatedDate && disc.EndDate__c <= opp.CreatedDate) {
	                        summaryDiscount += disc.Discount__c;
	                    }
	                }
	            }
	            Double totalPrice = price;
	            List<String> childProducts = packageAndProducts.get(opp.ProductId__c);
	            if (childProducts != null && childProducts.size() != 0) { 
	                List<String> childPercents = packageAndPercents.get(opp.ProductId__c);
	                for (Integer i = 0;  i < childProducts.size(); i++) {
	                    OpportunityLineItem oli = new OpportunityLineItem();
	                    oli.ProductId__c = Id.valueOf(childProducts.get(i));                                                                          
	                    oli.UnitPrice = totalPrice / 100 * Double.valueOf(childPercents.get(i));
						if (oli.UnitPrice == null) oli.UnitPrice = 0.0;
	                    oli.OpportunityId = opp.id;
	                    oli.Discount = summaryDiscount;
	                    oli.Quantity = 1;
	                    if (productPrices.get(Id.valueOf(childProducts.get(i))) != null) {
	                      	oli.PricebookEntryId = productPrices.get(Id.valueOf(childProducts.get(i))).id;
	                    }
	                    oliToInsert.add(oli);
	                }
	                OpportunityLineItem oli = new OpportunityLineItem();
	                oli.ProductId__c = opp.ProductId__c;  
	                oli.UnitPrice = 0;
	                oli.OpportunityId = opp.id;
	                oli.Discount = summaryDiscount;
	                oli.Quantity = 1;
	                oli.PricebookEntryId = productPrices.get(opp.ProductId__c).id;
	                oliToInsert.add(oli);
	            } else {
	                OpportunityLineItem oli = new OpportunityLineItem();
	                oli.ProductId__c = opp.ProductId__c;
	                oli.UnitPrice = totalPrice;
	                oli.OpportunityId = opp.id;
	                oli.Discount = summaryDiscount;
	                oli.Quantity = 1;
	                oli.PricebookEntryId = productPrices.get(opp.ProductId__c).id;
	                oliToInsert.add(oli);
	            }
			}
			insert oliToInsert;																											//ONE MORE MEGA FAIL !!!!!!!!!
			OpportunityMethod.DONE = true;
	    }

		List<Payment__c> newPayments = new List<Payment__c>();
		Date paymentDate;
		Double summPerMonth;
	    List<ApplicationsActivities__c> toInsert = new List<ApplicationsActivities__c>();
	    for (Opportunity opp : trigger.new) {
	        if (opp.ActionIds__c != null) {
	            Set<Id> actionIds = OpportunityMethod.oppToActionIdSet(opp);
	            for (Id actionId : actionIds) {
	                toInsert.add(new ApplicationsActivities__c(ActionID__c = actionId, OpportunityId__c = opp.Id));
	            }
	        }
	    }
		insert toInsert;																												//YEAP, MEGA FAIL AGAIN !!!!!!!!!

	    BMOpportunity bmOpportunity = new BMOpportunity();
	    for(ProductRoles__c par : ProductRoles__c.getAll().values()) {
            bmOpportunity.createAccountRoleForInsert(trigger.new, par.ProductName__c, par.RoleNumber__c);
        }
	}

}