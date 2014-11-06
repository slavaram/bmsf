public class SObjectUtils {

	public static List<String> getFieldNames(String sObjectType) {
		return getFieldNames(sObjectType, true);
	}

	public static List<String> getFieldNames(String sObjectType, Boolean withSystemFields) {
		List<String> result = new List<String>();
		if (sObjectType == null || withSystemFields == null) return result;
		Map<String, Schema.SObjectField> fieldsMap = Schema.getGlobalDescribe().get(sObjectType).getDescribe().fields.getMap();
		List<String> fieldNames = new List<String>(fieldsMap.keySet());
		if (withSystemFields) {
			for (String fieldName : fieldsMap.keySet()) {
				if (fieldsMap.get(fieldName).getDescribe().isAccessible()) result.add(fieldName);
			}
		} else {
			for (String fieldName : fieldsMap.keySet()) {
				if (fieldsMap.get(fieldName).getDescribe().isAccessible() && fieldName.endsWithIgnoreCase('__c')) result.add(fieldName);
			}
		}
		return result;
	}

	public static List<SelectOption> getObjectPickListFieldValues(SObject obj, String field) {
		List<SelectOption> options = new List<SelectOption>();
		Schema.sObjectType objectType = obj.getSObjectType();
		Schema.DescribeSObjectResult objectDescribe = objectType.getDescribe();
		Map<String, Schema.SObjectField> fieldMap = objectDescribe.fields.getMap();
		List<Schema.PicklistEntry> values = fieldMap.get(field).getDescribe().getPickListValues();
		for (Schema.PicklistEntry a : values) { 
			options.add(new SelectOption(a.getLabel(), a.getValue())); 
		}
		return options;
	}

}