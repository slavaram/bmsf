@isTest
class SObjectUtilsTest {

	static testmethod void getFieldNamesTest() {
		System.assertNotEquals(null, SObjectUtils.getFieldNames('Opportunity'));
	}

	static testmethod void getSystemFieldNamesTest() {
		System.assertNotEquals(null, SObjectUtils.getFieldNames('Opportunity', false));
	}

	static testmethod void getObjectPickListFieldValuesTest() {
		System.assertNotEquals(null, SObjectUtils.getObjectPickListFieldValues(new Opportunity(), 'StageName'));
	}

}