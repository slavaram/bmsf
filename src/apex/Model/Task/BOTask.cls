public with sharing class BOTask {

	public void setDate(list<Task> Tasks) {
		for (Task item : Tasks) {
			item.Date__c = (Date.today() == item.ActivityDate && item.ReminderDateTime < DateTime.now() && !item.IsClosed ? DateTime.now() : item.ReminderDateTime);
			item.HotDateTime__c = item.Date__c.addMinutes(15);
		}
	}

	public void setWorkTime(List<Task> tasksNew, List<Task> tasksOld) {
		for (Task itemNew: tasksNew) {
			for (Task itemOld: tasksOld)	{
				if (itemNew.Id == itemOld.Id && itemOld.Status != 'Завершено' && itemNew.Status == 'Завершено') {
					itemNew.TimeWork__c = (DateTime.now().getTime() - itemNew.CreatedDate.getTime()) / 1000;
				}
			}
		}
	}

	public void setWhoId(List<Task> tasks) {
		Set<Id> whatIds = getWhatIds(tasks);
		Map<Id,Id> contactIds = getContact(whatIds);
		for (Task item : tasks) {
			if (contactIds.containsKey(item.WhatId)) {
				item.WhoId = contactIds.get(item.WhatId);
			}
		}
	}

	public set<Id> getWhatIds(List<Task> tasks) {
		Set<Id> whatIds = new Set<Id>();
		for (Task item : tasks) {
			if (item.WhoId == null && item.WhatId != null) {
				whatIds.add(item.WhatId);
			}
		}
		return whatIds;
	}

	public Map<Id,Id> getContact(Set<Id> whatIds) {
		Map<Id,Id> contactIds = new Map<Id,Id> ();
		contactIds.putAll(getContactByCase(whatIds));
		contactIds.putAll(getContactByOpportunity(whatIds));
		contactIds.putAll(getContactByAccount(whatIds));
		return contactIds;
	}

	public Map<Id,Id> getContactByCase(Set<Id> whatIds) {
		List<Case> cases;
		try {
			cases = [SELECT Id, AccountId FROM Case WHERE Id IN :whatIds];
		} catch (Exception ex) {
			cases = new List<Case>();
		}
		Set<Id> accountIds = new Set<Id>();
		for (Case item : Cases) {
			accountIds.add(item.AccountId);
		}
		Map<Id, Id> mapAccountContact = setContactIds(AccountIds);
		Map<Id,Id> contactIds = new Map<Id,Id>();
		for (Case item : cases) {
			if (mapAccountContact.containsKey(item.AccountId)) {
				contactIds.put(item.Id, mapAccountContact.get(item.AccountId));
			}
		}
		return contactIds;
	}

	public Map<Id,Id> getContactByOpportunity(Set<Id> whatIds) {
		List<Opportunity> Opportunities;
		try {
			Opportunities = [SELECT Id, AccountId FROM Opportunity WHERE Id IN :whatIds];
		} catch (Exception ex) {
			Opportunities = new List<Opportunity>();
		}
		Set<Id> accountIds = new Set<Id>();
		for (Opportunity item : opportunities){
			accountIds.add(item.AccountId);
		}
		Map<Id, Id> mapAccountContact = setContactIds(AccountIds);
		Map<Id,Id> contactIds = new Map<Id,Id>();
		for (Opportunity item : opportunities) {
			if (mapAccountContact.containsKey(item.AccountId)) {
				contactIds.put(item.Id, mapAccountContact.get(item.AccountId));
			}
		}
		return ContactIds;
	}

	public Map<Id,Id> getContactByAccount(Set<Id> whatIds) {
		Map<Id, Account> Accounts;
		try {
			accounts = new Map<Id, Account>([SELECT Id FROM Account WHERE Id IN :whatIds]);
		} catch (Exception ex) {
			accounts = new Map<Id, Account>();
		}
		return setContactIds(accounts.KeySet());
	}

	public Map<Id,Id> setContactIds(Set<Id> accountIds) {
		List<Contact> contacts = [SELECT Id, AccountId FROM Contact WHERE AccountId IN :accountIds];
		Map<Id, Id> mapAccountContact = new Map<Id, Id>();
		for (Contact item : contacts) {
			mapAccountContact.put(item.AccountId, item.Id);
		}
		return mapAccountContact;
	}

}