public with sharing class NewOpportunityController {

    public class AvActionWrapper {
    
        public AvActionWrapper(){
            this.setIsFiltered(true);
        }
    
        private Boolean isFiltered;
        
        public Boolean getIsFiltered(){
            return this.isFiltered;
        }
        
        public void setIsFiltered(Boolean isFiltered){
            this.isFiltered = isFiltered;
        }
    
        private Boolean isSelected = false;
        
        public void setIsSelected(Boolean isSelected){
            this.isSelected = isSelected;
        }
        
        public Boolean getIsSelected(){
            
            return this.isSelected;
        }
        
        AvailableEvents__c avActionItem;
        Action__c actionItem;
        
        public AvailableEvents__c getAvActionItem(){

            return this.avActionItem;
        }
        
        public Action__c getActionItem() {

            return actionItem;
        }
        
        public void setAvActionItem(AvailableEvents__c avActionItem){
            this.avActionItem = avActionItem;
        }
        
        public void setActionItem(Action__c actionItem) {
            this.actionItem = actionItem;
        }
    
    }

    public Boolean isRenderAvActionTable {get; set;}

    private Opportunity opp;
    
    private ID oppId = ApexPages.currentPage().getParameters().get('id');
    
    public Opportunity getOpp()
    {
        if(this.opp == null) {
            setOpp();
            if(oppId != null) {
                this.opp = [select  id, name, AccountId, Amount__c, SendEmail__c, ProductId__c, ActionIds__c, Source__c, isComplete__c, Discount__c,
                                    FromSite__c, AmountWithDiscount__c, SummOfPayments__c, CreditConditions__c,
                                    BusinessAccount__c, NumberOfPayments__c, EndDateOfPayment__c, StartDateOfPayment__c,
                                    StageName, ReasonRefusal__c,  Amount, Description, CloseDate
                                    from Opportunity
                                    where id = :oppId];
                
            } else {
                if(ApexPages.currentPage().getParameters().get('Account') != null){
                    this.opp.AccountId = ApexPages.currentPage().getParameters().get('Account');
                }
                this.opp.Name = 'Новая запись';
                this.opp.StageName = 'Клиент думает';
                this.opp.CloseDate = Date.today()+7;
                //this.opp.Probability = 10;
            }
            return this.opp;
        } else { 
        
        return this.opp;
        }
    }
    
    public void setOpp()
    {
		this.opp = new Opportunity();
    }

    public NewOpportunityController(ApexPages.StandardController controller)
    {
        this.isRenderAvActionTable = false;
        if (oppId != null)
        {
            getOpp();
            getOppItem();
            rerenderAvActionTable();
        }
    }
    
    private String searchstring;

    public void setSearchstring(String searchstring)
	{
        this.searchstring = searchstring;
    }
    
    public String getSearchstring(){
        return this.searchstring;
    }

    public void searchAction()
    {
        rerenderAvActionTable();
        
        if(this.searchstring == null || this.searchstring.length() < 1)
        {
            for(AvActionWrapper avActWrapper:this.avActions)
            {
                avActWrapper.setIsFiltered(true);
            }
        }
        else
        {
            for(AvActionWrapper AvActionWrapper : this.avActions)
            {
                Action__c act = AvActionWrapper.getActionItem();
                String actName = act.Name;
                Boolean isContains = isTheSecondContainsTheFirst(actName,this.searchstring);
                AvActionWrapper.setIsFiltered(isContains);
            }
        }
    }

    private Boolean isTheSecondContainsTheFirst(String secondS, String firstS)
    {
        if (firstS == null || firstS.length() < 1)
            return false;

        if(secondS == null || secondS.length()<firstS.length())
            return false;

        return secondS.contains(firstS);
    }

    private String filterActionId;
    
    public String getFilterActionId(){
        return this.filterActionId;
    }
    
    public void setFilterActionId(String filterActionId){
        this.filterActionId = filterActionId;
    }


    public void updateAvActionsStatus()
    {
        List<AvailableEvents__c> avActs4Update = new List<AvailableEvents__c>();
        
        for(AvActionWrapper avActWrap : this.avActions)
        {
            System.debug('participantWrapper.getIsSelected()='+avActWrap.getIsSelected());
            
            if (avActWrap.getIsSelected())
            {
                avActWrap.setIsSelected(false);
                AvailableEvents__c avActItem = avActWrap.getAvActionItem();
            }
        }
        System.debug('participant4Update.size()='+avActs4Update.size());
        update avActs4Update;
    }

    private Opportunity oppItem;
    
    Boolean isDoneFirstRenderOnEdit = false;
    
    public Opportunity getOppItem()
    {
        if (this.oppId != null)
        {
            if (this.opp != null)
                this.oppItem = this.opp;
            else
                getOpp();
        }
        else if (this.oppItem == null)
			this.oppItem = new Opportunity();
        
        return this.oppItem;
    }
    
    public void setOppItem(Opportunity oppItem)
    {
        this.oppItem = oppItem;
    }
    
    private list<AvActionWrapper> AvActions;
    
    public list<AvActionWrapper> getAvActions()
    {
        list<AvActionWrapper> toShowList = new list<AvActionWrapper>();
        
        if (this.avActions == null)
        	return toShowList;
        
        for (AvActionWrapper avActWrapper : this.avActions)
            if (avActWrapper.getIsFiltered())
                toShowList.add(avActWrapper);

        return toShowList;
    }
    
    list<ApplicationsActivities__c> appActsExt = [select id
												    , OpportunityId__c
												    , ActionId__c 
												from ApplicationsActivities__c
												where OpportunityId__c = :this.oppId];
    
    public void rerenderAvActionTable()
    {
        this.avActions = new List<AvActionWrapper>();
        List<AvailableEvents__c> avActionList = [SELECT Id, Name, Product__c, ActionId__c
		                                            FROM AvailableEvents__c
												WHERE Product__c =: this.getOppItem().ProductId__c];
        List<ID> actIds = new List<ID>();
		
		for (AvailableEvents__c avActionItem : avActionList)
            actIds.add(avActionItem.ActionId__c);
        
        List<Action__c> actionsList = [select id, name, StartDate__c,RegistrationEndDate__c, EndDate__c, RecordType.DeveloperName from Action__c 
                                        where id in :actIds and RegistrationEndDate__c >= :Date.today()
                                        and RecordType.DeveloperName = 'ParentActionRecordType'];   
        
        
        if(actionsList != null)
        {
            this.isRenderAvActionTable = true;
            for(Action__c actionItem : actionsList)
            {
                AvActionWrapper avActionWrapper = new AvActionWrapper();
                avActionWrapper.setActionItem(actionItem);
                if (this.oppId != null)
                {
                    for (ApplicationsActivities__c appActExt : appActsExt)
                        if (appActExt.ActionID__c == actionItem.Id)
                             avActionWrapper.setIsSelected(true);
                }
                else
                {
                    avActionWrapper.setIsSelected(false);
                }
                this.avActions.add(avActionWrapper);
            }
        }
        else
        {
            this.isRenderAvActionTable = false;
        }
    }
    
    public PageReference save()
    {
        try
        {
        	list<ID> curActIds = new list<ID>();
        	boolean isSelectid = false;
        	
			opp.ProductId__c = this.getOppItem().ProductId__c;
			opp.ActionIds__c = '';

            if (this.avActions != null)
            { 
                for(AvActionWrapper avActWrapper : this.avActions)
                    if (avActWrapper.getIsSelected())
                    {
                    	Action__c a = avActWrapper.getActionItem();
                    	if (a != null)
                    	{
	                        opp.ActionIds__c += a.Id + ';';
	                        curActIds.add(a.Id);
	                        isSelectid = true;
                    	}
                    } 
            }
            else
             	isSelectid = true;
            
            system.debug(LoggingLevel.Error, opp);
	        upsert opp;
	        
	        set<Id> exCurActsIds = new set<ID>();
	        for (ApplicationsActivities__c exAppAct : appActsExt)
	            exCurActsIds.add(exAppAct.ActionId__c);
	       
	        opp.ActionIds__c = '';
	        
	        if (this.avActions != null)
	            for(AvActionWrapper avActWrapper : this.avActions)
	                if (avActWrapper.getIsSelected() && !exCurActsIds.contains(avActWrapper.getActionItem().Id))
						avActWrapper.setIsSelected(false);
	        
	        pageReference pageRef = new pageReference('/' + opp.id);
	        pageref.getparameters().put('retURL', '/' + opp.id);
	        pageRef.setRedirect(true);
	        return pageRef;
        }
        catch (exception e)
        {
        	system.debug(LoggingLevel.Error, e);
        	return null;
        }
    }
}