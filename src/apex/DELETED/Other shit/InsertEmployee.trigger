trigger InsertEmployee on Employee__c (before insert, before update) {
	new BOEmployee().SetEmployeesName( trigger.new );
}