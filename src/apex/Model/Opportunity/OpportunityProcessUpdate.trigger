trigger OpportunityProcessUpdate on Opportunity (before update, after update) {

<<<<<<< HEAD
=======
	if (trigger.isBefore) {
		new BMOpportunity().calculateDiscount(trigger.new);

		Map<String, String> mapOppNames = OpportunityMethod.generateAppNames(trigger.new);
		for (Opportunity opp : trigger.new) {
			if (mapOppNames.containsKey(opp.ActionIds__c))			opp.ActionNames__c = mapOppNames.get(opp.ActionIds__c);
			if (opp.Debt__c <= 0 && opp.IsPartlyPassed__c == true)	opp.StageName = 'Мероприятие пройдено частично';
			if (opp.Debt__c <= 0 && opp.IsComplete__c == true)		opp.StageName = 'Мероприятие пройдено';
		}
		Map<Id, List<Opportunity>> mapProductOpp = new Map<Id, List<Opportunity>>();
		for (Opportunity opp : trigger.new) {
			if (opp.ProductId__c != null) {
				List<Opportunity> listO = (mapProductOpp.containsKey(opp.ProductId__c) ? mapProductOpp.get(opp.ProductId__c) : new List<Opportunity>());
				ListO.add(opp);
				mapProductOpp.put(opp.ProductId__c, listO);
			}
		}
		for (Product2 product : [SELECT Id, AccountId__c FROM Product2 WHERE Id IN :mapProductOpp.keySet()]) {
			for (Opportunity opp : mapProductOpp.get(product.Id)) {
				opp.BusinessAccount__c = product.AccountId__c;
			}
		}
	}

	if (trigger.isAfter) {
		OpportunityExcecutor oppExcecutor = new OpportunityExcecutor();
		oppExcecutor.deleteNonActualActivitesBeforeUpdate(trigger.newMap, trigger.oldMap);

		List<ApplicationsActivities__c> toInsert = new List<ApplicationsActivities__c>();
		for (Opportunity opp : trigger.new) {
			Opportunity oppOld = trigger.oldMap.get(opp.Id);
			if (opp.ActionIds__c != oppOld.ActionIds__c) {
				Set<Id> actionIds = OpportunityMethod.oppToActionIdSet(opp);
				Set<Id> actionIdsOld = OpportunityMethod.oppToActionIdSet(oppOld);
				actionIds.removeAll(actionIdsOld);
				for (Id actId : actionIds) {
					toInsert.add(new ApplicationsActivities__c(ActionID__c = actId, OpportunityId__c = opp.Id));
				}
			}
		}
		insert toInsert;

		List<id> listOpportunityId = new List<id>();
		for (Opportunity opp : trigger.new) {
			if (opp.StageName == 'Оплачено') {
				listOpportunityId.add(opp.Id);
			}
		}
		List<Task> tasks = [SELECT Id, OwnerId, Status, Resolution__c
		                    FROM Task
		                    WHERE Subject = 'Консультирование. Создание заявки на мероприятие'
		                    AND Status = 'Новая'
		                    AND WhatId IN :listOpportunityId];
		for (Task tas : tasks) {
			tas.OwnerId = '005b0000000NiKS';
			tas.Status = 'Завершено';
			tas.Resolution__c = 'Автомат.Поступление платежа от клиента';
		}
		update tasks;

		update [SELECT Id, OpportunityId__c, ActionID__c
		        FROM ApplicationsActivities__c
		        WHERE OpportunityId__c IN :trigger.newMap.keySet()
		        AND (OpportunityId__r.StageName = 'Условно оплачена'
		        		OR OpportunityId__r.StageName = 'Оплачено'
		        		OR OpportunityId__r.StageName = 'Частичная оплата')
		        ];

		List<StepPayment__c> paymentSteps = new List<StepPayment__c>();
		for (Opportunity oldOpp : trigger.old) {
			Opportunity newOpp = trigger.newMap.get(oldOpp.Id);
			if (oldOpp.StageName != 'Частичная оплата' && oldOpp.StageName != 'Оплачено' && newOpp.StageName == 'Частичная оплата') {
				paymentSteps.add(new StepPayment__c(OpportunityId__c = newOpp.Id,
												StepPayment__c = 5,
												DateUpdateStepPay__c = DateTime.now()));
			}
			if (oldOpp.StageName != 'Частичная оплата' && oldOpp.StageName != 'Оплачено' && newOpp.StageName == 'Оплачено') {
				paymentSteps.add(new StepPayment__c(OpportunityId__c = newOpp.Id,
												StepPayment__c = 5,
												DateUpdateStepPay__c = DateTime.now()));
				paymentSteps.add(new StepPayment__c(OpportunityId__c = newOpp.Id,
												StepPayment__c = 6,
												DateUpdateStepPay__c = DateTime.now()));
			}
			if (oldOpp.StageName == 'Частичная оплата' && newOpp.StageName == 'Оплачено') {
				paymentSteps.add(new StepPayment__c(OpportunityId__c = newOpp.Id,
												StepPayment__c = 6,
												DateUpdateStepPay__c = DateTime.now()));
			}
		}
		if (!paymentSteps.isEmpty()) insert paymentSteps;

	    List<Opportunity> opportunitiesWithChangedProduct = new List<Opportunity>();
	    List<id> listProductId = new List<id>();
	    List<Id> opportIds = new List<Id>();
	    for (Opportunity oppNew : trigger.new) {
	      	Opportunity oppOld = trigger.oldMap.get(oppNew.Id);
	        if (oppNew.ProductId__c != oppOld.ProductId__c) {
	          	opportIds.add(oppNew.id);
	            if (oppNew.ProductId__c != null) {
	                opportunitiesWithChangedProduct.add(oppNew);
	                listProductId.add(oppNew.ProductId__c);
	            }
	        }
	    }
	    if (opportunitiesWithChangedProduct.size() > 0) {
	    	delete [SELECT Id FROM OpportunityLineItem WHERE OpportunityId IN : opportIds];
	        List<Product2> productsFromOpportunities = [SELECT Id, ProductIds__c, ProductPercents__c
	        											FROM Product2
	        											WHERE Id IN : listProductId];
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
	        Map<Id, list<Discount__c>> productDiscounts = new Map<id, list<Discount__c>>();
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
	                    if (productPrices.get(Id.valueOf(childProducts.get(i))) != null) oli.PricebookEntryId = productPrices.get(Id.valueOf(childProducts.get(i))).id;
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
			insert oliToInsert;
	    }
	}

>>>>>>> opp_issue
}