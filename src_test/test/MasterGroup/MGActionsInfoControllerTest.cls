@isTest(seeAllData=true)
class MGActionsInfoControllerTest {

	static testmethod void test() {
		MGActionsInfoController controller = new MGActionsInfoController();
		controller.mActionId = controller.mRowElements.get(0).actionId;
		controller.loadInfo();
		System.assertNotEquals(0, controller.mGroups.size());
	}

}