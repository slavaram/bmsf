@isTest
public class UserGroupManagerTest {

	static testmethod void emptyAllocationWithoutGroupsTest() {
		User user = [SELECT Id FROM User WHERE IsActive = true LIMIT 10].get(0);
		insert new UserGroupMembers__c(Name = '00000000', GroupName__c = 'Index', MemberId__c = '0');
		UserGroupManager.addGroupMembers('TestGroup', new Set<Id> {user.Id});
		UserGroupManager.removeGroupMembers('TestGroup', new Set<Id> {user.Id});
		UserGroupManager.addGroupMembersFuture('TestGroup', new Set<Id> {user.Id});
		UserGroupManager.removeGroupMembersFuture('TestGroup', new Set<Id> {user.Id});
		Account acc = new Account(Name = 'Test Account');
		UserGroupManager.allocateAmongOwnerGroupMembers(acc);
		System.assertEquals(null, acc.OwnerId);
	}

	static testmethod void emptyAllocationWithGroupsTest() {
		User user = [SELECT Id FROM User WHERE IsActive = true LIMIT 10].get(0);
		insert new UserGroupMembers__c(Name = '00000000', GroupName__c = 'Index', MemberId__c = '0');
		UserGroupManager.addGroupMembers('TestGroup', new Set<Id> {user.Id});
		insert new UserGroupFilters__c(Name = 'TestGroup Account.Name',
				GroupName__c = 'TestGroup',
				ObjectName__c = 'Account',
				Condition__c = 'Name=Abdula Cumar');
		Account acc = new Account(Name = 'Abdula Cumar');
		UserGroupManager.allocateAmongOwnerGroupMembers(acc);
		System.assertEquals(null, acc.OwnerId);
	}

	static testmethod void b2BManagersGroupCasesAllocationTest() {
		User user = [SELECT Id FROM User WHERE IsActive = true LIMIT 10].get(0);
		insert new UserGroupMembers__c(Name = '00000000', GroupName__c = 'Index', MemberId__c = '0');
		UserGroupManager.addGroupMembers('B2bManagersGroup', new Set<Id> {user.Id});
		insert new UserGroupFilters__c(Name = 'B2bManagersGroup Case.Subject',
				GroupName__c = 'B2bManagersGroup',
				ObjectName__c = 'Case',
				Condition__c = 'Subject=testSubject');
		Case cas = new Case(Subject = 'testSubject');
		UserGroupManager.allocateAmongOwnerGroupMembers(cas);
		System.assertEquals(user.Id, cas.OwnerId);
	}

	static testmethod void allManagersGroupCasesAllocationTest() {
		User userOne = [SELECT Id FROM User WHERE IsActive = true LIMIT 10].get(0);
		User userTwo = [SELECT Id FROM User WHERE IsActive = true AND Profile.Name = 'Менеджер' LIMIT 10].get(1);
		insert new UserGroupMembers__c(Name = '00000000', GroupName__c = 'Index', MemberId__c = '0');
		UserGroupManager.addGroupMembers('AllManagersGroup', new Set<Id> {userOne.Id});
		insert new UserGroupFilters__c(Name = 'AllManagersGroup Case.Subject',
				GroupName__c = 'AllManagersGroup',
				ObjectName__c = 'Case',
				Condition__c = 'Subject=testSubject');
		Account acc = new Account(Name = 'TestAccount', OwnerId = userTwo.Id);
		insert acc;
		Case casOne = new Case(Subject = 'testSubject', AccountId = acc.Id);
		UserGroupManager.allocateAmongOwnerGroupMembers(casOne);
		Case casTwo = new Case(Subject = 'testSubject');
		UserGroupManager.allocateAmongOwnerGroupMembers(casTwo);
		System.assertEquals(userOne.Id, casTwo.OwnerId);
		System.assertEquals(userTwo.Id, casOne.OwnerId);
	}

	static testmethod void possibleAccountOwnersGroupCasesAllocationTest() {
		User userOne = [SELECT Id FROM User WHERE IsActive = true LIMIT 10].get(0);
		User userTwo = [SELECT Id FROM User WHERE IsActive = true AND Profile.Name = 'Менеджер' LIMIT 10].get(1);
		insert new UserGroupMembers__c(Name = '00000000', GroupName__c = 'Index', MemberId__c = '0');
		UserGroupManager.addGroupMembers('PossibleAccountOwners', new Set<Id> {userOne.Id});
		insert new UserGroupFilters__c(Name = 'PossibleAccountOwners PossibleAccount',
				GroupName__c = 'PossibleAccountOwners',
				ObjectName__c = 'PossibleAccount__c',
				Condition__c = '*');
		Account acc = new Account(Name = 'TestAccount', OwnerId = userTwo.Id);
		insert acc;
		PossibleAccount__c posAccA = new PossibleAccount__c();
		UserGroupManager.allocateAmongOwnerGroupMembers(posAccA);
		PossibleAccount__c posAccB = new PossibleAccount__c(RecommendedBy__c = acc.Id);
		UserGroupManager.allocateAmongOwnerGroupMembers(posAccB);
		System.assertEquals(userOne.Id, posAccA.OwnerId);
		System.assertEquals(userTwo.Id, posAccB.OwnerId);
	}

}