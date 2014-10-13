@isTest
class RegisterBookControllerTest {

	private static final Date YESTERDAY = System.today().addDays(-1);
	private static final String REGISTER_YESTERDAY = (ApexUtils.isWeekend(YESTERDAY) ? RegisterBookController.RECORD_REASON_WEEKEND : RegisterBookController.RECORD_VALUE_NO);
	private static final Date TODAY = System.today();
	private static final String REGISTER_TODAY = (ApexUtils.isWeekend(TODAY) ? RegisterBookController.RECORD_REASON_WEEKEND : RegisterBookController.RECORD_VALUE_NO);
	private static final Date TOMORROW = System.today().addDays(1);
	private static final String REGISTER_TOMORROW = (ApexUtils.isWeekend(TOMORROW) ? RegisterBookController.RECORD_REASON_WEEKEND : RegisterBookController.RECORD_VALUE_NO);

	private static User SeniorManager;
	private static Integer managerCount;
	private static User ManagerOne;
	private static User ManagerTwo;

	private static RegisterBookController controller = new RegisterBookController();

	private static void prepareData() {
		List<User> seniorManagers = [SELECT Id, SmallPhotoUrl
		                             FROM User
		                             WHERE Profile.Name = :RegisterBookController.SENIOR_MANAGER_TAG
		                             AND IsActive = true
		                             LIMIT 10];
		SeniorManager = seniorManagers.get(0);
		List<User> managers = [SELECT Id, Name, SmallPhotoUrl
		                       FROM User
		                       WHERE Profile.Name = :RegisterBookController.MANAGER_TAG
		                       AND ManagerId = :SeniorManager.Id
		                       AND IsActive = true
		                       ORDER BY Name];
		managerCount = managers.size();
		ManagerOne = managers.get(0);
		ManagerTwo = managers.get(1);
	}

	static testmethod void test() {
		prepareData();
		User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
		System.runAs (thisUser) {
			controller.mGroup = SeniorManager.Id;
			controller.processGroup();

			System.assertEquals(managerCount, controller.mUsers.size());

			controller.mFromDate.Date__c = TODAY;
			controller.mByDate.Date__c = YESTERDAY;
			controller.processDates();

			controller.mRegisters.get(0).Register__c = RegisterBookController.RECORD_VALUE_MAYBE;
			controller.mRegisters.get(0).Reason__c = RegisterBookController.RECORD_VALUE_MAYBE;
			controller.saveRegisters();

			System.assertEquals(managerCount, [SELECT Id FROM DailyAttendance__c].size());
			System.assertEquals(1, [SELECT Id FROM DailyAttendance__c WHERE Register__c = :RegisterBookController.RECORD_VALUE_MAYBE].size());

			controller.mFromLeaveDate.Date__c = TOMORROW;
			controller.mToLeaveDate.Date__c = YESTERDAY;
			controller.mUser = ManagerTwo.Id;
			controller.saveLeaveRegister();

			System.assertEquals(managerCount, [SELECT Id FROM DailyAttendance__c].size());

			controller.mFromLeaveDate.Date__c = TODAY;
			controller.mToLeaveDate.Date__c = TOMORROW;
			controller.mUser = ManagerTwo.Id;
			controller.saveLeaveRegister();

			System.assertEquals(managerCount + 1, [SELECT Id FROM DailyAttendance__c].size());
			System.assertNotEquals(null, controller.downloadCalendar());
		}
	}

}