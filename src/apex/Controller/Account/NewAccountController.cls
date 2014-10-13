public with sharing class NewAccountController {

    public String selectedRT			{get;set;}
    public boolean isNameWarning        {get;set;}
    public boolean isEmailWarning		{get;set;}
        
    public String lastName				{get;set;}
    public String firstName				{get;set;}

    public Account acc;
    public boolean isFirst						= true;
    public boolean isFound						= false;
    public boolean isRtNotSelected				= false;
    
    private List<Account> matches				= new List<Account>();
    private Set<ID> personalRTs					= new Set<ID>();
    private List<SelectOption> recordTypeList	= getRecordTypeList();
    private List<SelectOption> emptyList		= new List<SelectOption>();  
    
    {
    	acc = new Account();
    }
        
    public NewAccountController(ApexPages.StandardController controller) {
    	isNameWarning = false;
    	isEmailWarning = false;
    	isRtNotSelected = false;
        String accountEmail = ApexPages.currentPage().getParameters().get('Email');
        if (accountEmail != null) {
        	acc.PersonEmail = accountEmail;
        }
        String accountPhone = ApexPages.currentPage().getParameters().get('Phone');
        if (accountPhone != null) {
        	acc.Phone = accountPhone;
        }
    }

    public PageReference somethingWasChanged() {
        this.isFirst = true;
        return null;
    }

    public boolean getNoErrors() {
        return (!(isNameWarning || isEmailWarning || isRTNotSelected));
    }
    
    public boolean getIsFound() {
        return this.isFound;
    }
    
    public boolean getIsPersonal() {
        return personalRTs.contains(id.valueOf(selectedRT));
    }
    
    public boolean getIsRtNotSelected() {
        return isRtNotSelected;
    }     

    public List<SelectOption> getRecordTypeList() {
        try {
	        if ((recordTypeList != null) && (recordTypeList.size() >= 0)) return recordTypeList;
	        recordTypeList = new List<SelectOption>();
	        List<RecordType> recordTypes = [SELECT Id, Name, DeveloperName, IsPersonType
	                                        FROM RecordType
	                                        WHERE SObjectType = 'Account'
	                                        AND IsActive = true];
	        selectedRT = null;              
	       	Id curRoleId = UserInfo.getUserRoleId();
	        UserRole ur = [SELECT Id, DeveloperName
	                       FROM UserRole
	                       WHERE Id = :curRoleId];
	        for (RecordType rt : recordTypes) {
	        	if((ur.DeveloperName == 'Manager') || (ur.DeveloperName == 'SiniorManager')) {
	        		if ((rt.DeveloperName == 'PersonAccount')||(rt.DeveloperName == 'BusinessAccount')) recordTypeList.add(new SelectOption(rt.id, rt.Name));
	            } else {
	            	recordTypeList.add(new SelectOption(rt.id, rt.Name));
	            }
	            if (rt.isPersonType == true) {
	            	personalRTs.add(rt.id);
	            }
	            if (rt.DeveloperName == 'PersonAccount') {
	            	selectedRT = rt.id;
	            }
	        }
	        if (selectedRT == null) {
	        	recordTypeList = emptyList;
	        }
	        return recordTypeList;
	    } catch (Exception ex) {
	    	return NULL;
	    }
    }

    public boolean getisFirst() {
        return isfirst;
    }

    public void setisFirst(Boolean b) {
        this.isFirst = b;
    }

    public void setisFound(Boolean b) {
        this.isFound = b;
    }      
        
    public PageReference CreateNewAcc() { 
    	try {                   
    		if (isFirst) {
    			next();
                if (isFound) {
                	return null;
                }
    		}
	        isRtNotSelected	= false;
	        isEmailWarning	= false;
	        isNameWarning	= false; 
	        if (selectedRT == null) {
                isRtNotSelected = true;
                return null;
	        }
	        if (getIsPersonal() == true) {                  
                if (acc.PersonEmail == null) {
                	isEmailWarning = true;
                	return null;
                }
                if ((this.LastName == null) || (this.LastName == '')) {
                	LastName = '-';
                }       
                acc.LastName = this.LastName;
                acc.FirstName = this.FirstName;
	        } else {
	        	if (acc.name == null) {
	        		isNameWarning = true;
	        		return null;
                }
                if (acc.name == '') {
                	acc.name = '-';
                }
	        }
	        acc.RecordTypeId = (id) selectedRT; 
	        insert acc;
	        String pageProperty = ApexPages.currentPage().getParameters().get('FromTask');
	        if (pageProperty != null) {
	        	return creteTaskAndRedirect(pageProperty);
	        }
	        pageReference pageRef = new pageReference('/'+acc.id);
	        pageref.getparameters().put('retURL', '/'+acc.id);
	        pageRef.setRedirect(true);
	        return pageRef;
    	} catch (Exception ex) {
    		return NULL;
    	}
    }

    private PageReference creteTaskAndRedirect(String taskId) {
    	Task oldTask = [SELECT Id, Status, WhatId FROM Task WHERE Id = :taskId].get(0);
    	oldTask.Status = 'Завершено';
    	update oldTask;
    	update new PossibleAccount__c(Id = oldTask.WhatId, RealAccount__c = acc.Id);
    	Task newTask = new Task(Status = 'Новая', WhatId = acc.Id);
    	insert newTask;
    	return new PageReference('/' + newTask.Id);
    }

    public Account getAcc() {
        if (acc == null) {
        	acc = new Account();
        }
        return acc;
    } 

    public void setAcc(Account a) {
        acc = a;
    }

    public List<Account> getMatches() {
        return matches;
    }

    public PageReference next() {
    	try{
    		if (getIsPersonal() == false) {
    			if (acc.Name == null) {
    				isNameWarning = true;
    				return null;
    			}
    		} else {
    			if (acc.PersonEmail == null) {
    				isEmailWarning = true;
    				return null;
    			}
            }
            isNameWarning = false;
            isEmailWarning = false;
            String searchText;
            if (getIsPersonal() == false) {
                searchText = ' WHERE Name = \'' + acc.Name + '\'';
            } else {
                searchText = ' WHERE PersonEmail = \'' + acc.PersonEmail + '\'';
            }
            isFirst = false;
            matches = Database.query('SELECT Id, Name, PersonEmail, CountryCode__c, CityCode__c, PhoneNumber__c, NoName__c FROM Account' +
            							searchText + ' AND RecordType.IsPersonType = ' + getIsPersonal() + ' LIMIT 200');
            if (matches.size() == 0) {
            	isFound = false;
            } else {
            	isFound = true;
            }
            return null;
        } catch (Exception ex) {
        	return NULL;
        }  
    }

}