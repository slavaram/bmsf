public class DailyAttendanceManager {

	public static Set<Id> getUsersByDay(Date day) {
		Set<Id> result = new Set<Id>();
		List<DailyAttendance__c> registers = [SELECT UserId__c
		                                      FROM DailyAttendance__c
		                                      WHERE Day__c = :day];
		for (DailyAttendance__c register : registers) {
			result.add(register.UserId__c);
		}
		return result;
	}

	public static Map<Date, Set<Id>> getUsersInPeriod(Date fromDay, Date byDay) {
		Map<Date, Set<Id>> result = new Map<Date, Set<Id>>();
		List<DailyAttendance__c> registers = [SELECT Day__c, UserId__c
		                                      FROM DailyAttendance__c
		                                      WHERE Day__c >= :fromDay
		                                      AND Day__c <= :byDay];
		for (DailyAttendance__c register : registers) {
			Set<ID> oneDayRegisters = result.get(register.Day__c);
			if (oneDayRegisters == null) {
				Set<Id> newOneDayRegisters = new Set<Id>();
				newOneDayRegisters.add(register.UserId__c);
				result.put(register.Day__c, newOneDayRegisters);
			} else {
				oneDayRegisters.add(register.UserId__c);
				result.put(register.Day__c, oneDayRegisters);
			}
		}
		return result;
	}

}