@isTest(seeAllData=true)
class MGCardsInfoControllerTest {

	static testmethod void test() {
		MGCardsInfoController controller = new MGCardsInfoController ();
		System.assertNotEquals(0, controller.mRows.size());
	}

}