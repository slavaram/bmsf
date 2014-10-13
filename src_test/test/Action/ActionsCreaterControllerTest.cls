@isTest(seeAllData=true)
class ActionsCreaterControllerTest {

	static testmethod void test() {
		ActionsCreaterController controller = new ActionsCreaterController();

		controller.mActivity = '0';
		controller.mName0 = 'test activity with strange name';
		controller.mType = '2';
		controller.mPrice0 = 1000;
		controller.createAction();
		List<Action__c> actions1 = [SELECT Id
									FROM Action__c
									WHERE Name = 'test activity with strange name'];
		System.assertEquals(2, actions1.size());

		controller.mActivity = '1';
		controller.mName1 = 'test activity with strange name 2';
		controller.mIsIn1 = false;
		controller.mPrice1 = 1000;
		controller.mCity1 = 'Test City';
		controller.mStartDate1 = '01.01.2001 10:00';
		controller.mEndDate1 = '01.01.2001 10:00';
		controller.mEndReg1 = '01.01.2001 10:00';
		controller.mEndPay1 = '01.01.2001 10:00';
		controller.createAction();
		List<Action__c> actions2 = [SELECT Id
									FROM Action__c
									WHERE Name = 'test activity with strange name 2'];
		System.assertEquals(1, actions2.size());

		controller.mActivity = '2';
		controller.mName2 = 'test activity with strange name 3';
		controller.mIsIn2 = true;
		controller.mPrice2 = 1000;
		controller.mCity2 = 'Test City';
		controller.mStartDate2 = '01.01.2001 10:00';
		controller.mEndDate2 = '01.01.2001 10:00';
		controller.mEndReg2 = '01.01.2001 10:00';
		controller.mEndPay2 = '01.01.2001 10:00';
		controller.createAction();
		List<Action__c> actions3 = [SELECT Id
									FROM Action__c
									WHERE Name = 'test activity with strange name 3'];
		System.assertEquals(1, actions3.size());
	}

}