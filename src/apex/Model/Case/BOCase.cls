public class BOCase {

	@future
	public static void AssignCase(Set<Id> caseIds ) {
		List<Case> cases = [SELECT Id, AccountId, OwnerId
							FROM Case
							WHERE Id IN :caseIds
							AND Origin = 'Эл. почта'
							AND AccountId != null
							AND Account.Owner.Name != 'Администратор'];
		Set<Id> accountIds = new Set<Id>();
		for (Case cs : cases) {
			accountIds.add(cs.AccountId);
		}
		Map<Id, Account> relatedAccounts = new Map<Id, Account>([SELECT Id, Name, OwnerId
																 FROM Account
																 WHERE Id IN :accountIds]);
		for (Case cas : cases) {
			cas.OwnerId = relatedAccounts.get(cas.AccountId).OwnerId;
		}
		if (!cases.isEmpty()) {
			update cases;
		}
	}

}