@isTest (SeeAllData=true)
class RatingRotatorTest {

	private static RatingRotator rotator = new RatingRotator();

	static testMethod void refreshPage0Test() {
		rotator.counter = 0;
		System.assertEquals(null, rotator.refreshPage());
	}

	static testMethod void refreshPage1Test() {
		rotator.counter = 1;
		System.assertEquals(null, rotator.refreshPage());
	}

	static testMethod void refreshPage2Test() {
		rotator.counter = 2;
		System.assertEquals(null, rotator.refreshPage());
	}

	static testMethod void refreshPage3Test() {
		rotator.counter = 3;
		System.assertEquals(null, rotator.refreshPage());
	}

	static testMethod void refreshPage4Test() {
		rotator.counter = 4;
		System.assertEquals(null, rotator.refreshPage());
	}

	static testMethod void refreshPage5Test() {
		rotator.counter = 5;
		System.assertEquals(null, rotator.refreshPage());
	}

	static testMethod void refreshPage6Test() {
		rotator.counter = 6;
		System.assertEquals(null, rotator.refreshPage());
	}

	static testMethod void refreshPage7Test() {
		rotator.counter = 7;
		System.assertEquals(null, rotator.refreshPage());
	}

}