@isTest (SeeAllData =  true)
public with sharing class Test_InsertEmployee {
	
	static testMethod void Test_TriggerInsertEmployee(){
		Employee__c Employee = new Employee__c ( FirstName__c = 'FirstName', LastName__c = 'LastName' );
		insert Employee;
		
		Employee = [ select Name from Employee__c where id =: Employee.Id ];
		
		system.assertEquals( Employee.Name, 'FirstName LastName' ); 
	}
}