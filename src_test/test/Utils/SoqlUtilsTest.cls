@isTest
class SoqlUtilsTest {

	static testmethod void formatDateTimeTest() {
		System.assertEquals('2014-01-01T00:00:00Z', SoqlUtils.formatDateTime(Date.valueOf('2014-01-01 00:00:00')));
	}

	static testmethod void formatDateTest() {
		System.assertEquals('2014-01-01', SoqlUtils.formatDate(Date.valueOf('2014-01-01 00:00:00')));
	}

}