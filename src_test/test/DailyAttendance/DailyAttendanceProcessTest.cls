@isTest
class DailyAttendanceProcessTest {

	static testmethod void test() {
		User testUser = [SELECT Id FROM User LIMIT 1].get(0);
		DailyAttendance__c registerOne = new DailyAttendance__c(UserId__c = testUser.Id, Day__c = System.today(), Register__c = 'Test');
		insert registerOne;
		DailyAttendance__c registerTwo = new DailyAttendance__c(UserId__c = testUser.Id, Day__c = System.today(), Register__c = 'Test');
		insert registerTwo;
		System.assertEquals(1, [SELECT Id FROM DailyAttendance__c].size());
	}

}