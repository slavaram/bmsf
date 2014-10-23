public class BMOpportunity {

	public Opportunity data {
		get {
			return (data == null ? new Opportunity() : data);
		}
		set;
	}

	public BMOpportunity() {}

	public BMOpportunity(String opportunityId) {
		data = [SELECT Id, Name, ProductId__c, ProductId__r.RecordTypeId, ActionIds__c, CreatedDate, StageName
		        FROM Opportunity
		        WHERE Id = :opportunityId];
	}

	public BMOpportunity(Opportunity opp) {
		try {
			data = [SELECT Id, Name, ProductId__c, ProductId__r.RecordType.DeveloperName, ActionIds__c, CreatedDate, StageName
			        FROM Opportunity
			        WHERE Id = :opp.Id];
		} catch (Exception ex) {
			data = opp;
		}
	}

	public void createAccountRoleForUpdate(List<ApplicationsActivities__c> activities, String actionName, Decimal role) {
        Map<Id, Set<Id>> mapClientId = new Map<Id, Set<Id>>();
        List<StudyMember__c> roles = new List<StudyMember__c>();
        for (ApplicationsActivities__c active : activities) {
            if (active.OpportunityId__r.StageName == 'Оплачено'
                    && active.ActionID__r.Name.contains(actionName)
                    && active.ActionID__r.ParentId__c != null) {
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
        if(mapClientId.isEmpty()) return;
        for (Id clientId : mapClientId.keySet()) {
            for(String act : mapClientId.get(clientId)) {
                roles.add(new StudyMember__c(Client__c = clientId,
                                             Event__c = act,
                                             RoleNumber__c = role));
            }
        }
        if (roles.isEmpty() == false) upsertRoles(roles, mapClientId.keySet());
    }

    public void createAccountRoleForInsert(List<Opportunity> opps, String actionName, Decimal role) {
        List<StudyMember__c> roles = new List<StudyMember__c>();
        Map<Id, Set<Id>> mapActionsId = new Map<Id, Set<Id>>();
        Set<Id> setActionId = new Set<Id>();
        for (Opportunity opp : opps) {
            if (opp.ActionIds__c != null) {
                Set<Id> actionIds = OpportunityMethod.oppToActionIdSet(opp);
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
        if(setActionId.isEmpty()) return;
        String actName = '%' + actionName + '%';
        List<Action__c> actions = [SELECT ParentId__c 
                                   FROM Action__c 
                                   WHERE Name like :actName
                                     AND ParentId__c != null
                                     AND Id in :setActionId];
        Map<Id, Set<Id>> mapActionsIdAll = new Map<Id, Set<Id>>();
        for (Action__c action : actions) {
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
                for(Id act : actionss) {
                    if (actionsp.contains(act)) {
                        roles.add(new StudyMember__c(Client__c = account,
                                                     Event__c = action,
                                                     RoleNumber__c = role));
                        break;
                    }
                }
            }
        }
        System.debug('Roles '+ roles);
        if (roles.isEmpty() == false) upsertRoles(roles, mapActionsId.keySet());
    }

    private void upsertRoles(List<StudyMember__c> roles, Set<Id> accounts) {
        List<StudyMember__c> rolesCheck = [SELECT Client__c, Event__c, RoleNumber__c FROM StudyMember__c WHERE Client__c IN :accounts];
        rolesCheck.addAll(roles);
        List<StudyMember__c> rolesInsert = new List<StudyMember__c>(); 
        for (Integer i = 0 ; i < roles.size(); i++) {
            Boolean check = true;
            for (Integer j = i+1; j < roles.size(); j++ ) {
                if (rolesCheck[i].Client__c == rolesCheck[j].Client__c
                        && rolesCheck[i].Event__c == rolesCheck[j].Event__c
                        && rolesCheck[i].RoleNumber__c == rolesCheck[j].RoleNumber__c) {
                    check = false;
                    break;
                }
            }
            if (check) rolesInsert.add(rolesCheck[i]);
        }
        if (rolesInsert.isEmpty() == false) upsert rolesInsert;
    }

	public void calculateDiscount(List<Opportunity> opportunities) {
		List<Opportunity> toUpdate = new List<Opportunity>();
		for (Opportunity opportunity : opportunities) {
			Date discountDate = (opportunity.CalculateDiscountDate__c == null ? Date.valueOf(opportunity.CreatedDate) : opportunity.CalculateDiscountDate__c);
			opportunity.Discount__c = new BMOpportunity(opportunity).calculateDiscount(discountDate);
			opportunity.CalculateDiscountDate__c = discountDate;
		}
	}

	public Decimal calculateDiscount(DateTime calculationDate) {
		List<String> actionIds = new List<String>();
		if (String.isNotBlank(data.ActionIds__c)) actionIds = Data.ActionIds__c.split(';');
		List<AvailableEvents__c> availableEvents = new List<AvailableEvents__c>();
		if (data.Id != null ) {
			availableEvents = new List<AvailableEvents__c>(
					[SELECT Id, Name, Product__c, Product__r.Id, Product__r.Name, ActionID__c
					 FROM AvailableEvents__c
					 WHERE Product__c  = :data.ProductId__c
					 AND ActionID__c IN :actionIds
					 ORDER BY Product__r.Name]);
		}
		List<String> actionIdsForDiscount = new List<String>();
		if (data.ProductId__r.RecordType.DeveloperName == 'SingleRecord') actionIdsForDiscount.addAll(actionIds);
		List<String> productIds = new List<String>();
		if (data.ProductId__c != null ) productIds.add(Data.ProductId__c);
		List<Discount__c> discountList = new List<Discount__c>();
		if (opportunity.Id != null) {
			discountList = [SELECT Id, AvailableEventId__c, ProductID__c, ActionId__c, name, AbsolutelyDiscount__c, AbsolutelyDiscountLocal__c, StartDate__c, EndDate__c
			                FROM Discount__c
			                WHERE AvailableEventId__c IN :availableEvents
			                OR ProductID__c IN :productIds
			                OR ActionId__c IN :actionIdsForDiscount];
		}
		return calculateDiscountByDate(discountList, calculationDate);
	}

	public List<Opportunity> searchOpportunities(String productId, Date startDate, Date endDate, String stageName) {
		List<Opportunity> opportunities = new List<Opportunity>();
		if (productId == null) {
			opportunities = [SELECT Id, Name, StageName, Amount, ProductId__c, Discount__c, Account.Name, CreatedDateTime__c, CalculateDiscountDate__c
	    	                 FROM Opportunity
	    	                 WHERE CreatedDateTime__c >= :startDate
	    	                 AND CreatedDateTime__c <= :endDate
	    	                 AND StageName = :stageName];
		} else {
			opportunities = [SELECT Id, Name, StageName, Amount, ProductId__c, Discount__c, Account.Name, CreatedDateTime__c, CalculateDiscountDate__c
	 		                 FROM Opportunity
	 		                 WHERE CreatedDateTime__c >= :startDate
	 		                 AND CreatedDateTime__c <= :endDate
	 		                 AND Productid__c = :productId
	 		                 AND StageName = :stageName];
		}
		return opportunities;
	}

	private List<String> getActionIds(List<AvailableEvents__c> availableEvents) {
		List<String> result = new List<String>();
		for (AvailableEvents__c item : AvailableEvents ) {
			Action__c action = new Action__c();
			if (item.ActionID__c != null) {
				action = [SELECT Id, Name, ParentId__c, ParentId__r.Id, ParentId__r.Name FROM Action__c WHERE Id = :item.ActionID__c];
				if (action.Id != null ) result.add(action.Id);
				if (action.ParentId__c != null && action.ParentId__r.Id != null) result.add(Action.ParentId__r.Id);
			}
		}
		return result;
	}

	private Decimal calculateDiscountByDate(List<Discount__c> discounts, DateTime selectedDate) {
		Decimal result = 0;
		for (Discount__c discount : discounts) {
			result += calculateDiscountByDate(discount, selectedDate);
		}
		return result;
	}

	private Decimal calculateDiscountByDate(Discount__c discount, DateTime selectedDate) {
		return (selectedDate >= discount.StartDate__c && selectedDate <= discount.EndDate__c && discount.AbsolutelyDiscount__c != null ? discount.AbsolutelyDiscount__c : 0 );
	}

}