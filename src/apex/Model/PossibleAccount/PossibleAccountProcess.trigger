trigger PossibleAccountProcess on PossibleAccount__c (before insert, after insert) {

	if (trigger.isBefore && trigger.isInsert) {
		UserGroupManager.allocateAmongOwnerGroupMembers(trigger.new);
	}

	if (trigger.isAfter && trigger.isInsert) {
		List<Task> toInsert = new List<Task>();
		List<String> emails = new List<String>();
		List<String> phones = new List<String>();
		List<Id> accountIds = new List<Id>();
		for (PossibleAccount__c possibleAccount : trigger.new) {
			if (possibleAccount.Email__c != null)										emails.add(possibleAccount.Email__c);
			if (possibleAccount.Phone__c != null && possibleAccount.Phone__c != '+7')	phones.add(possibleAccount.Phone__c);
			if (possibleAccount.RecommendedBy__c != null)								accountIds.add(possibleAccount.RecommendedBy__c);
		}
		List<Account> likeAccounts = [SELECT Id, FirstName, LastName, PersonEmail, Phone
		                              FROM Account
		                              WHERE PersonEmail IN :emails
		                              OR Phone IN :phones
		                              LIMIT 100];
		Date deadline = System.today().addDays(1);
		while (ApexUtils.isWeekend(deadline)) {
			deadline = deadline.addDays(1);
		}
		Map<Id, Id> accountAndContact = new Map<Id, Id>();
		for (Contact con : [SELECT Id, AccountId FROM Contact WHERE AccountId IN :accountIds]) {
			accountAndContact.put(con.AccountId, con.Id);
		}
		for (PossibleAccount__c possibleAccount : trigger.new) {
			String descriptionBody = 'Возможно это этот клиент: ';
			Boolean likeAccountsFound = false;
			for (Account acc : likeAccounts) {
				if (possibleAccount.Phone__c == acc.Phone || possibleAccount.Email__c == acc.PersonEmail) {
					likeAccountsFound = true;
					descriptionBody += acc.LastName + ' ' + acc.FirstName + ' ' + System.URL.getSalesforceBaseUrl().toExternalForm() + '/' + acc.Id;
					if (possibleAccount.Phone__c == acc.Phone) {
						descriptionBody += ' (совпадение по номеру телефона)';
					} else {
						descriptionBody += ' (совпадение по адресу электронной почты)';
					}
					break;
				}
			}
			if (!likeAccountsFound) descriptionBody = '';
		}
		
		TaskMethods.createTask(trigger.new);
	}

}