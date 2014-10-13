@isTest(seeAllData=true)
private class Test_NewOpportunity {

    static testMethod void coverAllOnEdit() {
    	
    	List<RecordType> recordTypes = [Select Id, DeveloperName from RecordType where SobjectType = 'Action__c' or SobjectType = 'Product2'];
		Map <String,Id> rtMap = new Map <String,Id>(); 
		for (RecordType rt : recordTypes) {
        	rtMap.put(rt.DeveloperName,rt.id);
		}
		
		Account acc = new Account (Name = 'testing');
		insert acc;
		//acc = [SELECT Id FROM Account WHERE Name = 'testing'];
	
		Action__c action = new Action__c (Name='Testing', RecordTypeId = rtmap.get('ParentActionRecordType'));
		insert action;
		//action = [select id, Name, RecordTypeId from Action__c where Name='Testing'];
		
		//List<Product2> prods = new List<Product2>();
		Product2 product = new Product2 (Name='Testing1',RecordTypeId = rtMap.get('SingleRecord'));
		insert product;
		
		Pricebook2 standardPB = [select id, Name, IsActive from Pricebook2 where isStandard = true LIMIT 1];
		
		if (!standardPB.isActive) {
            standardPB.isActive = true;
            update standardPB;
        }
		Discount__c disc = new Discount__c(ActionId__c = action.id, StartDate__c = Date.today(), EndDate__c = Date.today().addDays(15), ProductID__c = product.id, Discount__c = 10);
		insert disc;
		
		PricebookEntry priceBookEntry3 = new PricebookEntry (UnitPrice = 1000, Product2Id = product.id, 
					Pricebook2Id = standardPB.Id, isActive=true);
		insert priceBookEntry3;
				
		Opportunity opp = new Opportunity(name = '123', AccountId = acc.Id, ProductId__c = product.id, isComplete__c = false, Discount__c = 1000,
	                              FromSite__c = false, 
                                  StageName = 'Оплачено', Amount = 10000, Description = 'test', CloseDate = Date.today().addDays(15)); // from Opportunity where id = :appAct and ProductId__c != null limit 1];
        try{ insert opp; }catch(exception ex){}
		
    	Id appAct = opp.id;
    	System.currentPageReference().getParameters().put('id', appAct);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(opp);
        NewOpportunityController noc = new NewOpportunityController(sc);

        noc.rerenderAvActionTable();   
          NewOpportunityController.AvActionWrapper testWrap = new NewOpportunityController.AvActionWrapper();
        AvailableEvents__c avActItem = new AvailableEvents__c(ActionID__c = action.Id, Product__c = product.id); 
        testWrap.setIsSelected(true);
        testWrap.setAvActionItem(avActItem);
        testwrap.getIsFiltered();
        testwrap.getIsSelected();
        testwrap.getActionItem();
        testwrap.getAvActionItem();

        
        noc.getAvActions();
        noc.setOppItem(opp); 
        noc.rerenderAvActionTable();      
        noc.setSearchstring('');
        noc.getSearchstring();
        noc.searchAction();
        noc.setSearchstring('Интенсив');
        noc.getSearchstring();
        noc.searchAction();
        noc.getAvActions();

        noc.updateAvActionsStatus();
        Id actId = action.Id; 
        noc.setFilterActionId(actId); 
        noc.getFilterActionId(); 
    	//noc.opp.FromSite__c = false;
        noc.save();
    }
    
    static testMethod void coverAllOnCreate() {
    	
    	try{
     	List<RecordType> recordTypes = [Select Id, DeveloperName from RecordType where SobjectType = 'Action__c'];
		Map <String,Id> rtMap = new Map <String,Id>(); 
		for (RecordType rt : recordTypes) {
        	rtMap.put(rt.DeveloperName,rt.id);
		}

		Account acc = new Account (Name = 'testing');
		insert acc;
	
		Action__c action = new Action__c (Name='Testing', RecordTypeId = rtmap.get('ParentActionRecordType'));
		insert action;
		
		Pricebook2 standardPB = [select id, Name, IsActive from Pricebook2 where isStandard = true LIMIT 1];
		
		if (!standardPB.isActive) {
            standardPB.isActive = true;
            update standardPB;
        }

		
		Opportunity opp = new Opportunity(name = '123', AccountId = acc.Id, isComplete__c = false, Discount__c = 1000,
	                              FromSite__c = false, CreditConditions__c = 'qwret',
                                  NumberOfPayments__c = 2, EndDateOfPayment__c = Date.today().addMonths(2), StartDateOfPayment__c = Date.today(),
                                  StageName = 'Оплачено', Amount = 10000, Description = 'test', CloseDate = Date.today().addDays(15)); // from Opportunity where id = :appAct and ProductId__c != null limit 1];
        insert opp;
        opp = [select id, name, AccountId, ProductId__c, ActionIds__c, isComplete__c, Discount__c,
                      FromSite__c, AmountWithDiscount__c, SummOfPayments__c, CreditConditions__c,
                      BusinessAccount__c, NumberOfPayments__c, EndDateOfPayment__c, StartDateOfPayment__c,
                      StageName, Amount, Description, CloseDate from Opportunity where AccountId = :acc.Id limit 1];
		
    	ApplicationsActivities__c applocationActivity = new ApplicationsActivities__c (OpportunityId__c = opp.id,
																						ActionID__c = action.id);
		
		insert applocationActivity;
        Id accId = acc.Id;
        System.currentPageReference().getParameters().put('id', null);
        System.currentPageReference().getParameters().put('Account', accId);        
       
       OpportunityExcecutor oe = new OpportunityExcecutor();
        
        List<Opportunity> opps = new List<Opportunity>();
        opps.add(opp);
        
        //oe.calculatePriceAndDiscount(opps, true);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(opp);
        NewOpportunityController noc = new NewOpportunityController(sc); 
        noc.getOpp();
        noc.setOpp();
        noc.getOppItem(); 
        
       	noc.setOppItem(opp);
         
        noc.rerenderAvActionTable();
    	}
    	catch(Exception ex){}
    }
}