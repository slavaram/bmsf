@isTest
public class OpportunityProcessTest {

	public testmethod static void test() {
		Account acc = new Account(Name = 'Test acc');
		insert acc;
		Action__c action = new Action__c(Name = 'Test action');
		Opportunity opp = new Opportunity(Name = 'Tets opp', Account = acc, StageName = 'Test', CloseDate = System.today(), ActionIds__c = action.Id);
		insert opp;
		opp.Description = 'Test description';
		update opp;
		delete opp;
	}

}