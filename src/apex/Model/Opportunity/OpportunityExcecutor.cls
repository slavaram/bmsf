public with sharing class OpportunityExcecutor {

	public void deleteNonActualActivitesBeforeUpdate(Map<Id, Opportunity> newOpps, Map<Id, Opportunity> oldOpps) {
		Map<Id, Opportunity> newOppsC = new Map<Id, Opportunity>();
		Map<Id, Opportunity> oldOppsC = new Map<Id, Opportunity>();
		for (Opportunity opp : newOpps.values()) {
			if (oldOpps.containsKey(opp.Id)) {
				Opportunity oldOpp = oldOpps.get(opp.Id);
				if (oldOpp.ActionIds__c != null && oldOpp.ActionIds__c.trim().length() > 0 && oldOpp.ActionIds__c != opp.ActionIds__c) {
					newOppsC.put(opp.Id, opp);
					oldOppsC.put(oldOpp.Id, oldOpp);
				}
			}
		}
		Map<Id, Set<Id>> mapNewOppToActionIdSet = oppToActionIdSet(newOppsC);
		Map<Id, Set<Id>> mapOldOppToActionIdSet = oppToActionIdSet(oldOppsC);
		List<ApplicationsActivities__c> actionsToDelete = actionToDelete(newOppsC, mapNewOppToActionIdSet, mapOldOppToActionIdSet);
		if (actionsToDelete != null && !actionsToDelete.isEmpty()) delete actionsToDelete;
	}

	public static Map<Id, Set<Id>> oppToActionIdSet(Map<Id, Opportunity> mapOpp) {
		Map<Id, Set<Id>> result = new Map<Id, Set<Id>>();
		if (mapOpp != null) {
			for (Opportunity opp : mapOpp.values()) {
				Set<Id> setActionIds = OpportunityMethods.parceOpportunityActionIds(opp);
				if (!setActionIds.IsEmpty()) result.put(opp.Id, setActionIds);
			}
		}
		return result;
	}

	private List<ApplicationsActivities__c> actionToDelete(Map<Id, Opportunity> newOpps, Map<Id, Set<Id>> mapNewOppToActionIdSet, Map<Id, Set<Id>> mapOldOppToActionIdSet) {
		if (newOpps == null || newOpps.size() < 1 || mapOldOppToActionIdSet == null) return null;
		Set<Id> setOfIdsToDelete = new Set<Id>();
		List<ApplicationsActivities__c> result = new List<ApplicationsActivities__c>();
		for(Opportunity oppItem : newOpps.values()) {
			Set<Id> newOppActionIdSet = mapNewOppToActionIdSet.get(oppItem.Id);
			Set<Id> oldOppActionIdSet = mapOldOppToActionIdSet.get(oppItem.Id);
			if (newOppActionIdSet != null && !newOppActionIdSet.IsEmpty() && oldOppActionIdSet != null)	oldOppActionIdSet.removeAll(newOppActionIdSet);
			if (oldOppActionIdSet != null) {
				mapOldOppToActionIdSet.put(oppItem.Id, oldOppActionIdSet);
				setOfIdsToDelete.addAll(oldOppActionIdSet);
			}
		}

		if (setOfIdsToDelete == null || setOfIdsToDelete.size() < 1) return null;
		for (ApplicationsActivities__c actionToDelete : [SELECT Id, ActionId__c, ApplicationsActivities__c.OpportunityId__c
		                                                 FROM ApplicationsActivities__c
		                                                 WHERE ActionId__c IN :setOfIdsToDelete
		                                                 AND OpportunityId__c IN :newOpps.keySet()]) {
			if (mapOldOppToActionIdSet.containsKey(actionToDelete.OpportunityId__c) 
					&& mapOldOppToActionIdSet.get(actionToDelete.OpportunityId__c).contains(actionToDelete.ActionId__c)) {
				result.add(actionToDelete);
			}
		}
		return result;
	}

}