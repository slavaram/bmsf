@isTest
public class PossibleAccountProcessTest {

	public static testmethod void test() {
		RecordType recType = [SELECT Id FROM RecordType WHERE IsActive = true AND SobjectType = 'Account' AND IsPersonType = true].get(0);
		Account accOne = new Account(RecordTypeId = recType.Id, LastName = 'TestAccountOne', PersonEmail = 'test1@gmail.com', Phone = '1234567');
		Account accTwo = new Account(RecordTypeId = recType.Id, LastName = 'TestAccountTwo', PersonEmail = 'test2@gmail.com', Phone = '1234568');
		Account accThree = new Account(RecordTypeId = recType.Id, LastName = 'TestAccountThree', PersonEmail = 'test3@gmail.com', Phone = '1234569');
		insert accOne;
		insert accTwo;
		insert accThree;
		PossibleAccount__c possibleAccount = new PossibleAccount__c(Email__c = accOne.PersonEmail,
																	Phone__c = accTwo.Phone,
																	RecommendedBy__c = accThree.Id);
		insert possibleAccount;
		System.assertNotEquals(null, [SELECT Id, Description FROM Task WHERE WhatId = :possibleAccount.Id].get(0).Description);
	}

}