@isTest
public class DataManagerTest {

	static testmethod void initOrgSettingsTest() {
		DataManager.initOrgSettings();
		System.assertNotEquals(null, [SELECT Id FROM OrganizationProfiles__c]);
	}

}