public class OpportunityMethods {

	public static Boolean DONE			= false;
	public static Boolean CARDS_DONE	= false;

	public class ApplicationsActivitiesManager {												// apex class that divides trigger and class scopes (trick against master-detail)

		public void doCrete(List<Opportunity> opportunities) {
			List<ApplicationsActivities__c> toInsert = new List<ApplicationsActivities__c>();
			for (Opportunity opp : opportunities) {
				if (opp.ActionIds__c != null) {
					for (String actionId : parceOpportunityActionIds(opp.ActionIds__c)) {
						toInsert.add(new ApplicationsActivities__c(ActionID__c = actionId, OpportunityId__c = opp.Id));
					}
				}
			}
			if (!toInsert.isEmpty()) insert toInsert;
		}

		public void doUpdate(Map<Id, Opportunity> oldOpportunities, Map<Id, Opportunity> newOpportunities) {
			List<ApplicationsActivities__c> toInsert	= new List<ApplicationsActivities__c>();
			List<ApplicationsActivities__c> toDelete	= new List<ApplicationsActivities__c>();
			Set<Id> opportunitiesToDelete				= new Set<Id>();
			Set<Id> activitiesToDelete					= new Set<Id>();
			Map<Id, Set<Id>> oppAndActionsToDelete		= new Map<Id, Set<Id>>();
			for (Id oppId : oldOpportunities.keySet()) {
				Set<Id> oldActions = parceOpportunityActionIds(oldOpportunities.get(oppId).ActionIds__c);
				Set<Id> newActions = parceOpportunityActionIds(newOpportunities.get(oppId).ActionIds__c);
				if ((!oldActions.isEmpty() || !newActions.isEmpty()) && oldActions != newActions) {
					Set<Id> thisOppActions	= new Set<Id>();
					Set<Id> toAdd			= new Set<Id>(newActions);
					Set<Id> toRemove		= new Set<Id>(oldActions);
					toAdd.removeAll(oldActions);
					toRemove.removeAll(newActions);
					for (Id actionId : toAdd) {
						toInsert.add(new ApplicationsActivities__c(ActionID__c = actionId, OpportunityId__c = oppId));
					}
					for (Id actionId : toRemove) {
						opportunitiesToDelete.add(oppId);
						activitiesToDelete.add(actionId);
						thisOppActions.add(actionId);
					}
					if (!thisOppActions.isEmpty()) oppAndActionsToDelete.put(oppId, thisOppActions);
				}
			}
			if (!oppAndActionsToDelete.isEmpty()) {
				for (ApplicationsActivities__c activity : [SELECT Id, OpportunityId__c, ActionID__c
				                                           FROM ApplicationsActivities__c
				                                           WHERE OpportunityId__c IN :opportunitiesToDelete
				                                           AND ActionID__c IN :activitiesToDelete]) {
					if (oppAndActionsToDelete.get(activity.OpportunityId__c).contains(activity.ActionID__c)) toDelete.add(activity);
				}
			}
			SavePoint save = Database.setSavepoint();
			try {
				if (!toInsert.isEmpty()) insert toInsert;
				if (!toDelete.isEmpty()) delete toDelete;
			} catch (Exception ex) {
				System.debug(ex.getMessage());
				Database.rollback(save);
			}
		}

	}

	public static Map<String, String> generateAppNames(List<Opportunity> opportunities) {
		Map<String, String> result			= new Map<String, String>();
		Map<String, Set<Id>> oppAndActions	= new Map<String, Set<Id>>();
		Set<Id> actionIds					= new Set<Id>();
		for (Opportunity opp : opportunities) {
			Set<Id> ids = parceOpportunityActionIds(opp.ActionIds__c);
			actionIds.addAll(ids);
			if (!ids.isEmpty()) oppAndActions.put(opp.ActionIds__c, ids);
		}
		Map<Id, Action__c> actions = new Map<Id, Action__c>([SELECT Id, Name FROM Action__c WHERE Id IN :actionIds]);
		for (Opportunity opp : opportunities) {
			if (opp.ActionIds__c != null && opp.ActionIds__c.trim().length() > 0) {
				String actionNames = '';
				for (Id actionId : oppAndActions.get(opp.ActionIds__c)) {
					if (actions.containsKey(actionId)) actionNames += actions.get(actionId).Name + ';';
				}
				result.put(opp.ActionIds__c, actionNames.substringBeforeLast(';'));
			}
		}
		return result;
	}

	public static Set<Id> parceOpportunityActionIds(String actionIds) {
		Set<Id> result = new Set<Id>();
		if (actionIds == null) return result;
		try {
			for (String actionId : actionIds.split(';')) {
				result.add((Id) actionId);
			}
		} catch (Exception ex) {}
		return result;
	}

	public static void setFieldValues(List<Opportunity> opportunities) {
		Map<String, String> actionNames = OpportunityMethods.generateAppNames(opportunities);
		for (Opportunity opp : opportunities) {
			if (actionNames.containsKey(opp.ActionIds__c))			opp.ActionNames__c = actionNames.get(opp.ActionIds__c);
			if (opp.Debt__c <= 0 && opp.IsPartlyPassed__c == true)	opp.StageName = 'Мероприятие пройдено частично';
			if (opp.Debt__c <= 0 && opp.IsComplete__c == true)		opp.StageName = 'Мероприятие пройдено';
		}
	}

	public static void creteApplicationsActivities(List<Opportunity> opportunities) {
		ApplicationsActivitiesManager manager = new ApplicationsActivitiesManager();
		manager.doCrete(opportunities);
	}

	public static void updateApplicationsActivities(Map<Id, Opportunity> oldOpportunities, Map<Id, Opportunity> newOpportunities) {
		ApplicationsActivitiesManager manager = new ApplicationsActivitiesManager();
		manager.doUpdate(oldOpportunities, newOpportunities);
	}

	public static List<OpportunityLineItem> createOpportunityLineItems(List<Opportunity> opportunities, List<Id> productIds) {
		List<OpportunityLineItem> result			= new List<OpportunityLineItem>();
        Map<Id, List<String>> productsInPackage		= new Map<Id, List<String>>();
        Map<Id, List<String>> poductPriceInPackage	= new Map<Id, List<String>>();
        List<Id> allProductIds						= productIds;
        if (opportunities == null || opportunities.isEmpty()) return result;
        for (Product2 pro : [SELECT Id, ProductIds__c, ProductPercents__c FROM Product2 WHERE Id IN :productIds]) {
            if (pro.ProductIds__c != null && pro.ProductPercents__c != null && pro.ProductIds__c != '' && pro.ProductPercents__c != '') {
                List<String> ids = pro.ProductIds__c.split(';', 0);
                List<String> percents = pro.ProductPercents__c.split(';', 0);
                productsInPackage.put(pro.Id, ids);
                poductPriceInPackage.put(pro.Id, percents);
                for (String productId : ids) {
                    allProductIds.add(Id.valueOf(productId));
                }
            }
        }
        Map<Id, PriceBookEntry> priceBookEntries = new Map<Id, PricebookEntry>();
        for (PriceBookEntry priceBookEntry : [SELECT Id, Product2Id, UnitPrice
                                              FROM PriceBookEntry
                                              WHERE IsActive = true
                                              AND PriceBook2.IsActive = true
	           								  AND PriceBook2.IsStandard = true
	           								  AND IsDeleted = false
	           								  AND Product2Id IN :allProductIds]) {
        	priceBookEntries.put(priceBookEntry.Product2Id, priceBookEntry);
        }
        Map<Id, List<Discount__c>> discounts = new Map<id, list<Discount__c>>();
        for (Discount__c discount : [SELECT Id, Discount__c, ProductId__c, StartDate__c, EndDate__c FROM Discount__c WHERE ProductId__c IN :productIds]) {
            List<Discount__c> thisDiscounts = new List<Discount__c>();
            if (discounts.keySet().contains(discount.ProductId__c)) thisDiscounts = discounts.get(discount.ProductId__c);
            thisDiscounts.add(discount);
            discounts.put(discount.ProductId__c, thisDiscounts);
        }
        for (Opportunity opp : opportunities) {
            if (!priceBookEntries.containsKey(opp.ProductId__c)) continue;
            Double price = priceBookEntries.get(opp.ProductId__c).UnitPrice;
            if (price == null) price = 0.0;
            Double summaryDiscount = 0.0;
            if (discounts.keySet().contains(opp.ProductId__c) && !discounts.get(opp.ProductId__c).isEmpty()) {
                for (Discount__c discount : discounts.get(opp.ProductId__c)) {
                    if (discount.StartDate__c >= opp.CreatedDate && discount.EndDate__c <= opp.CreatedDate) summaryDiscount += discount.Discount__c;
                }
            }
            List<String> childProducts = productsInPackage.get(opp.ProductId__c);
            if (childProducts != null && !childProducts.isEmpty()) {
                List<String> childPercents = poductPriceInPackage.get(opp.ProductId__c);
                for (Integer i = 0; i < childProducts.size(); i++) {
                	Double productPrice			= Double.valueOf(childPercents.get(i));
                	PriceBookEntry bookEntry	= priceBookEntries.get((Id) childProducts.get(i));
                	result.add(new OpportunityLineItem(
                    		ProductId__c		= Id.valueOf(childProducts.get(i)),
                    		UnitPrice			= price / 100 * (productPrice == null ? 0.0 : productPrice),
                    		OpportunityId		= opp.Id,
                    		Discount			= summaryDiscount,
                    		Quantity			= 1,
                    		PricebookEntryId	= (bookEntry == null ? null : bookEntry.Id)));
                }
                result.add(new OpportunityLineItem(
                		ProductId__c		= opp.ProductId__c, 
                		UnitPrice			= 0,
                		OpportunityId		= opp.Id,
                		Discount			= summaryDiscount,
                		Quantity			= 1,
                		PricebookEntryId	= priceBookEntries.get(opp.ProductId__c).Id));
            } else {
            	result.add(new OpportunityLineItem(
		                ProductId__c		= opp.ProductId__c,
		                UnitPrice			= price,
		                OpportunityId		= opp.Id,
		                Discount			= summaryDiscount,
		                Quantity			= 1,
		                PricebookEntryId	= priceBookEntries.get(opp.ProductId__c).Id));
            }
		}
		return result;
	}

    public static void createAccountRoleForInsert(List<Opportunity> opps, String actionName, Decimal role) {
        List<StudyMember__c> roles = new List<StudyMember__c>();
        Map<Id, Set<Id>> mapActionsId = new Map<Id, Set<Id>>();
        Set<Id> setActionId = new Set<Id>();
        for (Opportunity opp : opps) {
            if (opp.ActionIds__c != null) {
                Set<Id> actionIds = OpportunityMethods.parceOpportunityActionIds(opp.ActionIds__c);
                if (opp.StageName == 'Оплачено' && opp.ActionNames__c.contains(actionName)) {
                    if (mapActionsId.get(opp.AccountID) == null) {
                        mapActionsId.put(opp.AccountID, actionIds);
                    } else {
                        Set<Id> ids = mapActionsId.get(opp.AccountID);
                        ids.addAll(actionIds);
                        mapActionsId.put(opp.AccountID, ids);
                    }
                    setActionId.addAll(actionIds);
                }
            }
        }
        if (setActionId.isEmpty()) return;
        String actName = '%' + actionName + '%';
        Map<Id, Set<Id>> mapActionsIdAll = new Map<Id, Set<Id>>();
        for (Action__c action : [SELECT ParentId__c FROM Action__c WHERE Name LIKE :actName AND ParentId__c != null AND Id IN :setActionId]) {
            if (mapActionsIdAll.get(action.ParentId__c) == null) {
                Set<Id> ids = new Set<Id>();
                ids.add(action.Id);
                mapActionsIdAll.put(action.ParentId__c, ids);
            } else {
                Set<Id> ids = mapActionsIdAll.get(action.ParentId__c);
                ids.add(action.Id);
                mapActionsIdAll.put(action.ParentId__c, ids);
            }
        }
        for (Id account : mapActionsId.keySet()) {
            for (Id action : mapActionsIdAll.keySet()) {
                Set<Id> actionss = mapActionsId.get(account);
                Set<Id> actionsp = mapActionsIdAll.get(action);
                for (Id act : actionss) {
                    if (actionsp.contains(act)) {
                        roles.add(new StudyMember__c(Client__c = account, Event__c = action, RoleNumber__c = role));
                        break;
                    }
                }
            }
        }
        if (!roles.isEmpty()) upsertRoles(roles, mapActionsId.keySet());
    }

	public static void createAccountRoleForUpdate(List<ApplicationsActivities__c> activities, String actionName, Decimal role) {
        Map<Id, Set<Id>> mapClientId = new Map<Id, Set<Id>>();
        List<StudyMember__c> roles = new List<StudyMember__c>();
        for (ApplicationsActivities__c active : activities) {
            if (active.OpportunityId__r.StageName == 'Оплачено' && active.ActionID__r.Name.contains(actionName) && active.ActionID__r.ParentId__c != null) {
                String actId = active.ActionID__r.ParentId__c;
                if (mapClientId.get(active.OpportunityId__r.AccountID) == null) {
                    Set<Id> ids = new Set<Id>();
                    ids.add(actId);
                    mapClientId.put(active.OpportunityId__r.AccountID, ids);
                } else {
                    Set<Id> ids = mapClientId.get(active.OpportunityId__r.AccountID);
                    ids.add(actId);
                    mapClientId.put(active.OpportunityId__r.AccountID, ids);
                }
            }
        }
        if (mapClientId.isEmpty()) return;
        for (Id clientId : mapClientId.keySet()) {
            for(String act : mapClientId.get(clientId)) {
                roles.add(new StudyMember__c(Client__c = clientId, Event__c = act, RoleNumber__c = role));
            }
        }
        if (!roles.isEmpty()) upsertRoles(roles, mapClientId.keySet());
    }

    private static void upsertRoles(List<StudyMember__c> roles, Set<Id> accounts) {
        List<StudyMember__c> rolesCheck = [SELECT Client__c, Event__c, RoleNumber__c FROM StudyMember__c WHERE Client__c IN :accounts];
        rolesCheck.addAll(roles);
        List<StudyMember__c> rolesInsert = new List<StudyMember__c>(); 
        for (Integer i = 0 ; i < roles.size(); i++) {
            Boolean check = true;
            for (Integer j = i+1; j < roles.size(); j++ ) {
                if (rolesCheck[i].Client__c == rolesCheck[j].Client__c && rolesCheck[i].Event__c == rolesCheck[j].Event__c && rolesCheck[i].RoleNumber__c == rolesCheck[j].RoleNumber__c) {
                    check = false;
                    break;
                }
            }
            if (check) rolesInsert.add(rolesCheck[i]);
        }
        if (!rolesInsert.isEmpty()) upsert rolesInsert;
    }

}