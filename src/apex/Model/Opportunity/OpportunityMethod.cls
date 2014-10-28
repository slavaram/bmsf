global class OpportunityMethod {

	public static Boolean DONE = false;

	private static Map<Id, Opportunity> alreadyOInBatchComing = new Map<Id, Opportunity>();

	public static Map<String, String> generateAppNames(list<Opportunity> opportunities) {
		Map<String, String> result = new Map<String, String>();
		Map<String, Set<Id>> mapAIds = new Map<String, Set<Id>>();
		Set<Id> actionIds = new Set<Id>();
		for(Opportunity opp : opportunities) {
			if (opp.ActionIds__c != null && opp.ActionIds__c.trim().length() > 0) {
				Set<Id> sids = oppToActionIdSet(opp);
				actionIds.addAll(sids);
				mapAIds.put(opp.ActionIds__c, sids);
			}
		}
		Map<Id, Action__c> mapA = new Map<Id, Action__c>([SELECT Id, Name FROM Action__c WHERE Id IN :actionIds]);
		for(Opportunity opp : opportunities) {
			if (opp.ActionIds__c != null && opp.ActionIds__c.trim().length() > 0) {
				String sTemp = '';
				for(Id aId : mapAIds.get(opp.ActionIds__c)) {
					if (mapA.containsKey(aId)) sTemp += mapA.get(aId).Name + ';';
				}
				result.put(opp.ActionIds__c, sTemp);
			}
		}
		return result;
	}

	public static Set<Id> oppToActionIdSet(Opportunity oppItem)	{
		Set<Id> result = new Set<Id>();
		if (oppItem.ActionIds__c != null && oppItem.ActionIds__c.trim().length() > 0) {
			for (String ids : oppItem.ActionIds__c.split(';')) {
				if (isValidId(ids))	result.add(cut15(ids));
			}
		}
		return result;
	}

	public static String cut15(Id value) {
		return (value != null ? cut15(String.valueOf(value)) : '');
	}

	public static string cut15(String value) {
		return (value != null && value.trim().length() > 15 ? value.trim().substring(0, 15) : value);
	}

	public static boolean isValidId(String idString) {
		return (idString != null && ((idString.length() == 15 || idString.length() == 18) && Pattern.matches('^[a-zA-Z0-9]*$', idString)));
	}

}