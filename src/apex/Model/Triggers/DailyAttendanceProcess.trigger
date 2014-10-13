trigger DailyAttendanceProcess on DailyAttendance__c (before insert, before update) {

	if (trigger.isInsert && trigger.isBefore) {
		List<String> uniqKeys = new List<String>();
		for (DailyAttendance__c attend : trigger.new) {
			uniqKeys.add(attend.UniqKey__c);
		}
		List<DailyAttendance__c> duplicates = [SELECT Id FROM DailyAttendance__c WHERE UniqKey__c IN :uniqKeys];
		delete duplicates;
	}

}