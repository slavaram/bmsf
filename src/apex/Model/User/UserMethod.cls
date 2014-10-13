public class UserMethod {

	@future
	public static void createAllocations(List<Id> userIds) {
		List<BonusProdGroups__c> BPG = BonusProdGroups__c.getall().values();
		List<Id> ProdGroupsIds = new List<Id>();
		for (BonusProdGroups__c item : BPG) {
			if (item.Bonus_Type__c == 'Бонус менеджера по продажам') {
				ProdGroupsIds.add((Id) item.ProdGroup_Id__c);
			}
		}
		List<UserAllocation__c> toInsert = new List<UserAllocation__c>();
		for (Id userId : userIds) {
			for (Id productGroupId : ProdGroupsIds) {
				UserAllocation__c allocation = new UserAllocation__c();
				allocation.UserId__c = userId;
				allocation.ProductGroup__c = productGroupId;
				allocation.IsActive__c = false;
				allocation.isAllocationOn__c = false;
				allocation.Penalty__c = false;
				toInsert.add(allocation);
			}
		}
		insert toInsert;
	}

	@future
	public static void deleteAllocations(List<Id> userIds) {
		delete [SELECT Id FROM UserAllocation__c WHERE UserId__c IN :userIds];
	}

}