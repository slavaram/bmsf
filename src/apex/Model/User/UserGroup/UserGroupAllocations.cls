public class UserGroupAllocations {

	public List<sObject> allocate(List<sObject> objectEntities, UserGroup userGroup) {
		if (objectEntities == null || objectEntities.size() == 0 || userGroup.members.size() == 0) {
			return new List<sObject>();
		}
		return allocateCustom(objectEntities, userGroup.members, userGroup.name);
	}

	// Add or remove conditions in this method if you want to change the allocation logic.
	private List<sObject> allocateCustom(List<sObject> objectEntities, List<Id> members, String groupName) {
		List<List<sObject>> objectBundles = groupObjectsByType(objectEntities);
		for (List<sObject> objectBundle : objectBundles) {
			String objectsType = objectBundle.get(0).getSObjectType().getDescribe().getName();
			if (groupName == 'B2bManagersGroup') { 
				if (objectsType == 'Case') {
					return allocateCasesForB2bManagers(objectBundle, members);
				}
			}
			if (groupName == 'AllManagersGroup') {
				if (objectsType == 'Case') {
					return allocateCasesForAllManagers(objectBundle, members);
				}
			}
			if (groupName == 'PossibleAccountOwners') {
				if (objectsType == 'PossibleAccount__c') {
					return allocatePossibleAccountsForPossibleAccountOwners(objectBundle, members);
				}
			}
			/*
			if (groupName == '<new group>') {
				if (objectsType == 'Account') {
					// Do smth
				}
				// Check other objec type
			}
			// Add other group
			*/
		}
		return new List<sObject>();
	}

	private List<List<sObject>> groupObjectsByType(List<sObject> objectEntities) {
		List<List<sObject>> result		= new List<List<sObject>>();
		List<String> objectNames = new List<String>();
		objectNames.addAll(Schema.getGlobalDescribe().keySet());
		for (String objectName : objectNames) {
			List<sObject> objectBundle = new List<sObject>();
			for (sObject objectEntity : objectEntities) {
				if (objectName == objectEntity.getSObjectType().getDescribe().getName()) {
					objectBundle.add(objectEntity);
				}
			}
			if (objectBundle.size() > 0) result.add(objectBundle);
		}
		return result;
	}

	private List<sObject> allocateCasesForB2bManagers(List<Case> objectEntities, List<Id> members) {
		List<sObject> result = new List<sObject>();
		List<AggregateResult> userCasesCount = [SELECT OwnerId, COUNT(Id)
		                                        FROM Case
		                                        WHERE OwnerId IN :members
		                                        AND CreatedDate >= TODAY
		                                        GROUP BY OwnerId];
		Map<Id, Integer> casesYet = new Map<Id, Integer>();
		for (AggregateResult userCaseCount : userCasesCount) {
			casesYet.put((Id) userCaseCount.get('OwnerId'), (Integer) userCaseCount.get('expr0'));
		}
		Map<Id, Integer> casesCount = new Map<Id, Integer>();
		for (Id member : members) {
			Integer countYet = casesYet.get(member);
			casesCount.put(member, (countYet == null ? 0 : countYet));
		}
		for (Case objectEntity : objectEntities) {
			Integer lowestCount = null;
			Id ownerToAssign = null;
			for (Id ownerId : casesCount.keySet()) {
				Integer currentCount = casesCount.get(ownerId);
				if (lowestCount == null) {
					lowestCount = currentCount;
					ownerToAssign = ownerId;
				} else {
					if (lowestCount > currentCount) {
						lowestCount = currentCount;
						ownerToAssign = ownerId;
					}
				}
			}
			casesCount.put(ownerToAssign, lowestCount + 1);
			objectEntity.OwnerId = ownerToAssign;
			result.add(objectEntity);
		}
		return result;
	}

	private List<sObject> allocateCasesForAllManagers(List<Case> objectEntities, List<Id> members) {
		List<sObject> result		= new List<sObject>();
		Map<Id, Account> toUpdate	= new Map<Id, Account>();
		List<Id> accountIds			= new List<Id>();
		for (Case cas : objectEntities) {
			if (cas.AccountId != null) accountIds.add(cas.AccountId);
		}
		Map<Id, Id> accountAndOwner = new Map<Id, Id>();
		for (Account acc : [SELECT Id, OwnerId FROM Account WHERE Id IN :accountIds AND Owner.Profile.Name = 'Менеджер' AND Owner.IsActive = true]) {
			accountAndOwner.put(acc.Id, acc.OwnerId);
		}
		List<Case> toAllocate = new List<Case>();
		for (Case cas : objectEntities) {
			Id ownerId = accountAndOwner.get(cas.AccountId);
			if (ownerId == null) {
				toAllocate.add(cas);
			} else {
				cas.OwnerId = ownerId;
				result.add(cas);
			}
		}
		if (toAllocate.size() > 0) {
			List<AggregateResult> dailyRate = [SELECT OwnerId caseOwner, COUNT(ID) casesCount
			                                   FROM Case
			                                   WHERE CreatedDate >= TODAY
			                                   AND Owner.Profile.Name = 'Менеджер'
			                                   AND Owner.IsActive = true
			                                   GROUP BY OwnerId];
			Map<Id, Integer> managerCaseNumber = new Map<Id, Integer>();
			for (AggregateResult rate : dailyRate) {
				managerCaseNumber.put((Id) rate.get('caseOwner'), (Integer) rate.get('casesCount'));
			}
			for (Id manager : members) {
				if (managerCaseNumber.get(manager) == null) managerCaseNumber.put(manager, 0);
			}
			Map<Id, Integer> managerCaseNumberShuffled = new Map<Id, Integer>();
			for (Id managerId : ApexUtils.shuffle(new List<Id>(managerCaseNumber.keySet()))) {
				managerCaseNumberShuffled.put(managerId, managerCaseNumber.get(managerId));
			}
			for (Case cas : toAllocate) {
				Integer lowerNumber;
				Id ownerId;
				for (Id manager : managerCaseNumberShuffled.keySet()) {
					if (lowerNumber == null) {
						lowerNumber = managerCaseNumberShuffled.get(manager);
						ownerId = manager;
					} else {
						if (lowerNumber > managerCaseNumberShuffled.get(manager)) {
							lowerNumber = managerCaseNumberShuffled.get(manager);
							ownerId = manager;
						}
					}
				}
				managerCaseNumberShuffled.put(ownerId, lowerNumber + 1);
				if (cas.AccountId != null) {
					Account acc = new Account(Id = cas.AccountId, OwnerId = ownerId);
					toUpdate.put(acc.Id, acc);
				}
				cas.OwnerId = ownerId;
				result.add(cas);
			}
		}
		update toUpdate.values();
		return result;
	}

	private List<sObject> allocatePossibleAccountsForPossibleAccountOwners(List<PossibleAccount__c> objectEntities, List<Id> members) {
		List<sObject> result = new List<sObject>();
		List<Account> toUpdate = new List<Account>();
		Map<Id, Id> accAndOwner = new Map<Id, Id>();
		for (PossibleAccount__c possibleAccount : objectEntities) {
			if (possibleAccount.RecommendedBy__c != null) {
				accAndOwner.put(possibleAccount.RecommendedBy__c, null);
			}
		}
		for (Account acc : [SELECT Id, OwnerId FROM Account WHERE Id IN :accAndOwner.keySet() AND OwnerId != null AND Owner.Profile.Name = 'Менеджер' AND Owner.IsActive = true]) {
			accAndOwner.put(acc.Id, acc.OwnerId);
		}
		Map<Id, List<PossibleAccount__c>> tempMap = new Map<Id, List<PossibleAccount__c>>();
		for (PossibleAccount__c possibleAccount : objectEntities) {
			Id ownerId = accAndOwner.get(possibleAccount.RecommendedBy__c);
			if (ownerId != null) {
				possibleAccount.OwnerId = ownerId;
				result.add(possibleAccount);
			} else {
				List<PossibleAccount__c> thisPossibleAccounts = tempMap.get(possibleAccount.RecommendedBy__c);
				if (thisPossibleAccounts == null) {
					List<PossibleAccount__c> newPossibleAccounts = new List<PossibleAccount__c>();
					newPossibleAccounts.add(possibleAccount);
					tempMap.put(possibleAccount.RecommendedBy__c, newPossibleAccounts);
				} else {
					thisPossibleAccounts.add(possibleAccount);
					tempMap.put(possibleAccount.RecommendedBy__c, thisPossibleAccounts);
				}
			}
		}
		List<List<PossibleAccount__c>> toAllocate = new List<List<PossibleAccount__c>>();
		for (Id keyId : tempMap.keySet()) {
			if (keyId == null) {
				for (PossibleAccount__c possibleAccount : tempMap.get(keyId)) {
					toAllocate.add(new List<PossibleAccount__c> {possibleAccount});
				}
			} else {
				toAllocate.add(tempMap.get(keyId));
			}
		}
		if (toAllocate.size() > 0) {
			List<AggregateResult> userAccountsCount = [SELECT OwnerId, COUNT(Id)
			                                           FROM PossibleAccount__c
			                                           WHERE OwnerId IN :members
			                                           AND CreatedDate >= TODAY
			                                           GROUP BY OwnerId];
			Map<Id, Integer> accountsYet = new Map<Id, Integer>();
			for (AggregateResult agrRes : userAccountsCount) {
				accountsYet.put((Id) agrRes.get('OwnerId'), (Integer) agrRes.get('expr0'));
			}
			Map<Id, Integer> accountsCount = new Map<Id, Integer>();
			for (Id member : members) {
				Integer countYet = accountsYet.get(member);
				accountsCount.put(member, (countYet == null ? 0 : countYet));
			}
			for (List<PossibleAccount__c> bundle : toAllocate) {
				Integer lowestCount = null;
				Id ownerToAssign = null;
				for (Id ownerId : accountsCount.keySet()) {
					Integer currentCount = accountsCount.get(ownerId);
					if (lowestCount == null) {
						lowestCount = currentCount;
						ownerToAssign = ownerId;
					} else {
						if (lowestCount > currentCount) {
							lowestCount = currentCount;
							ownerToAssign = ownerId;
						}
					}
				}
				accountsCount.put(ownerToAssign, lowestCount + 1);
				for (PossibleAccount__c possibleAccount : bundle) {
					possibleAccount.OwnerId = ownerToAssign;
					result.add(possibleAccount);
				}
				if (bundle.get(0).RecommendedBy__c != null) toUpdate.add(new Account(Id = bundle.get(0).RecommendedBy__c, OwnerId = ownerToAssign));
			}
		}
		update toUpdate;
		return result;
	}

}