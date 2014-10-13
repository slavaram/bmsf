public class UserGroup {

	public final String name				{get; private set;}
	public List<Id> members					{get; private set;}
	private	List<FilterCriteria> filters	{get; set;}

	{
		members = new List<Id>();
		filters = new List<FilterCriteria>();
	}

	private class FilterCriteria {
		String objectName				{get; set;}
		Boolean isAllObjects			{get; set;}
		Map<String, String> pConditions	{get; set;}
		Map<String, String> nConditions	{get; set;}
		{
			isAllObjects = false;
		}
	}

	public UserGroup(String groupName, Set<Id> groupMembers) {
		name = groupName;
		Map<String, UserGroupFilters__c> settings = UserGroupFilters__c.getAll();
		for (String setting : settings.keySet()) {
			if (settings.get(setting).GroupName__c == groupName) {
				String criteria = String.valueOf(settings.get(setting).Condition__c);
				try {
					FilterCriteria filter = new FilterCriteria();
					filter.objectName = settings.get(setting).ObjectName__c;
					Map<String, String> pConditions = new Map<String, String>();
					Map<String, String> nConditions = new Map<String, String>();
					if (criteria == '*') {
						filter.isAllObjects = true;
					} else {
						filter.isAllObjects = false;
						for (String condition : criteria.split(',')) {
							if (condition.contains('!=')) {
								nConditions.put(condition.substringBefore('!='), condition.substringAfter('!='));
							} else {
								pConditions.put(condition.substringBefore('='), condition.substringAfter('='));
							}
						}
						filter.pConditions = pConditions;
						filter.nConditions = nConditions;
					}
					filters.add(filter);
				} catch (Exception ex) {}
			}
		}
		members.addAll(groupMembers);
	}

	public Boolean isOwner(sObject objectEntity) {
		if (objectEntity == null) {
			return false;
		}
		if (filters.size() == 0) {
			return false;
		}
		String objectType = objectEntity.getSObjectType().getDescribe().getName();
		for (FilterCriteria filter : filters) {
			if (filter.objectName == objectType) {
				Boolean passed = true;
				if (!filter.isAllObjects) {
					for (String fieldName : filter.pConditions.keySet()) {
						if (objectEntity.get(fieldName) != filter.pConditions.get(fieldName)) passed = false;
					}
					for (String fieldName : filter.nConditions.keySet()) {
						if (objectEntity.get(fieldName) == filter.nConditions.get(fieldName)) passed = false;
					}
				}
				if (passed) return passed;
			}
		}
		return false;
	}

}