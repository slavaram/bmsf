public without sharing class AccountMethods {

	public static void assignAccountOwner(Id accountId, Id ownerId) {
		update new Account(Id = accountId, OwnerId = ownerId);
	}

}