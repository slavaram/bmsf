public class DataManager {

	public static void initOrgSettings() {
		insert new OrganizationProfiles__c(Name = 'manager', Id__c = [SELECT Id FROM Profile WHERE Name = 'Менеджер'].get(0).Id);
	}

}