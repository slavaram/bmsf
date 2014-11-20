global class OpportunityEntity {

	global Opportunity thisOpportunity	{get; set;}
	global String actionsMode			{get; set;}
	global String fieldProduct			{get; set;}
	global AutoTask autoTask			{get; set;}
	global List<Action> actions {
		get {return (actions == null ? new List<Action>() : actions);}
		set;
	}
	global Integer countOfActions {
		get {return (actions == null ? 0 : actions.size());}
		set;
	}

	global class Action {
		global String actionId					{get; set;}
		global String parentName				{get; set;}
		global Boolean isDeleted				{get; set;}
		global Map<String, Action__c> actions	{get; set;}
		global Action__c currentAction			{get; set;}
		global List<SelectOption> listActions {
			get {
				ListActions = new List<SelectOption>();
				if (actions.size() == 1) {
					currentAction = actions.values().get(0);
					actionId = currentAction.Id;
					listActions.add(new SelectOption(returnId(CurrentAction), returnCityName(CurrentAction)));
				} else {
					ListActions.add(new SelectOption('', '-- Не выбрано --'));
					Map<String, String> mapForSort = getMapCities(actions.values());
					List<String> sortList = new List<String>();
					sortList.addAll(mapForSort.keySet());
					sortList.sort();
					for (String item : sortList) {
						listActions.add(new SelectOption(mapForSort.get(item), item));
					}
				}
				return listActions;
			}
			set;
		}

		global Action() {
			parentName		= 'Родительское мероприятие не задано';
			actions			= new Map<String, Action__c>();
			currentAction	= new Action__c();
			isDeleted		= false;
		}

		global Action(String parentNameValue, Map<String, Action__c> actionValues) {
			parentName		= (String.isNotBlank(parentNameValue) ? parentNameValue : 'Родительское мероприятие не задано');
			actions			= actionValues;
			currentAction	= new Action__c();
			isDeleted		= false;
		}

		global Action(Action__c currentActionValue, Map<String, Action__c> actionValues) {
			currentAction	= currentActionValue;
			actionId		= (currentAction.Id == null ? '' : CurrentAction.id);
			parentName		= (CurrentAction.ParentId__r.Name == null ? 'Родительское мероприятие не задано' : CurrentAction.ParentId__r.Name);
			actions			= actionValues;
			isDeleted		= false;
		}

		global void remove() {
			isDeleted = true;
		}

		global void refresh() {
			if (actions.containsKey(actionId)) currentAction = actions.get(actionId);
		}

		global Map<String, String> getMapCities(List<Action__c> actionValues) {
			Map<String, String> result = new Map<String, String>();
			for (Action__c item : actionValues) {
				result.put(returnCityName(item), returnId(item));
			}
			return result;
		}

		global String returnCityName(Action__c action) {
			return (action.CityId__r != null ? action.CityId__r.Name : 'Он-лайн');
		}

		global String returnId(Action__c Action ) {
			return (action.Id != null ? String.valueOf(action.Id) : 'empty');
		}
	}

	global OpportunityEntity() {
		init('empty');
	}

	global OpportunityEntity(String opportunityId){
		init(opportunityId);
	}

	global void init(String opportunityId) {
		selectOpportunity(opportunityId);
		getListActionsByActionIds(getActionIds((thisOpportunity.ActionIds__c != null ? thisOpportunity.ActionIds__c : '')));
		actionsMode = 'Мероприятия';
	}

	global List<String> getActionIds(String actionIds) {
    	List<String> result = new List<String>();
    	if (String.isNotBlank(actionIds)) result = actionIds.split(';');
    	return result;
	}

	global void selectOpportunity(String opportunityId) {
        String query = 'SELECT '+ fieldsToString('Opportunity') +' FROM Opportunity WHERE Id = \'' + opportunityId + '\'';
		try {
			thisOpportunity = Database.query(query);
		} catch (Exception ex) {
			thisOpportunity = new Opportunity();
			setDefaultValues();
		}
		autoTask			= (thisOpportunity.Id == null ? new AutoTask() : new AutoTask(thisOpportunity.StageName));
		autoTask.stageName	= thisOpportunity.StageName;
		autoTask.setAutoTask();
	}

    global String fieldsToString(String objectName){
        Map<String, Schema.SObjectField> sObjectFields = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap();
        List<String> listFields = new List<String>(sObjectFields.KeySet());
        return String.join( listFields, ', ');
    }

	global void setDefaultValues() {
		Map<String,String> parameters = ApexPages.currentPage().getParameters();
		if (parameters.containsKey('Account')) {
			thisOpportunity.AccountId = parameters.get('Account');
		} else if (parameters.containsKey('Contact')) {
			String query = 'SELECT Id, AccountId, Account.AccountUl__c FROM Contact WHERE Id = \'' + parameters.get('Contact') + '\'';
			Contact con = (Contact) BM_SoqlUtils.performSingleResultQuery(query);														// BM_SoqlUtils.cls !!!!!!!!
			if (con != null && String.isNotBlank(con.AccountId)) {
				thisOpportunity.AccountId = con.AccountId;
				if(con.Account.AccountUl__c != null) thisOpportunity.Payer__c = con.Account.AccountUl__c;
			}
		}
		if (parameters.containsKey('Campaign'))	thisOpportunity.CampaignId = parameters.get('Campaign');
		Map<String, OpportunityDefaultValues__c> defaultValues	= OpportunityDefaultValues__c.getAll();
		thisOpportunity.StageName								= defaultValues.get('StageName').DefaultValue__c;
		thisOpportunity.Source__c								= defaultValues.get('Source__c').DefaultValue__c;
		thisOpportunity.CloseDate								= Date.today().addDays(Integer.valueOf(defaultValues.get('CloseDate').DefaultValue__c));
	}

    global void getListActionsByActionIds(List<String> actionIds) {
    	createListActionsByActions(selectActionByIds(actionIds, null));
    }

    global void createListActionsByActions(List<Action__c> actionsList) {
    	actions = new List<Action>();
    	for (Action__c action : actionsList) {
    		Map<String, Action__c> allActionsByParent = new Map<String, Action__c>();
    		if (action.ParentId__c == null) {
    			allActionsByParent = new Map<String, Action__c> {action.Id => action};
    		} else {
    			allActionsByParent = new Map<String, Action__c>(selectActionByIds(null, action.ParentId__c));
    		}
    		actions.add(new Action(action, allActionsByParent));
    	}
    }

    global List<Action__c> selectActionByIds(List<String> actionIds, String parentId) {
    	return [SELECT Id, Name, ParentId__c, ParentId__r.Name, CityId__r.Name, StartDate__c, EndDate__c
    	        FROM Action__c
    	        WHERE Id IN :(ActionIds != null ? actionIds : new List<String>())
    	        OR ParentId__c = :(ParentId != null ? parentId : 'empty')];
    }

	global void addNewAction() {
		actions.add(new Action());
	}

	global Product2 selectProductByName(String productName) {
		try {
			return [SELECT Id FROM Product2 WHERE Name = :ProductName];
		} catch (Exception ex) {
			return new Product2();
		}
	}

	global void getListActions() {																											// ЗАГЛУХА НА ПРОДУКТЫ
		Product2 product = selectProductByName(fieldProduct);
		List<AvailableEvents__c> availableEvents = [SELECT ActionID__c, ActionID__r.ParentId__c, Product__c
		                                            FROM AvailableEvents__c
		                                            WHERE Product__c = :(product.Id != null ? String.valueOf(product.Id) : 'empty')
		                                            AND ActionID__r.RecordType.DeveloperName = 'ParentActionRecordType'
		                                            AND ActionID__r.RegistrationStartDate__c <= :DateTime.now()
		                                            AND ActionID__r.RegistrationEndDate__c >= :DateTime.now()];
		List<String> actionIds = new List<String>();
		for (AvailableEvents__c event : availableEvents) {
			actionIds.add(event.ActionID__c);
		}
		createListActions(selectActionByIds(actionIds, null));
	}

	global void CreateListActions(List<Action__c> actionsList) {
		Map<String, Map<String, Action__c>> actionsMap	= new Map<String, Map<String, Action__c>>();
		Map<String, String> parentNames					= new Map<String, String>();
		String indexStr									= '';
		Integer indexInt								= 0;
		for (Action__c action : actionsList) {
			if (action.ParentId__c != null) {
				indexStr = action.ParentId__c;
				parentNames.put(indexStr, action.ParentId__r.Name);
			} else {
				indexInt += 1;
				indexStr = String.valueOf(indexInt);
				parentNames.put(indexStr, '');
			}
			if (actionsMap.containsKey(indexStr)) {
				Map<String, Action__c> childActions = actionsMap.get(action.ParentId__c);
				childActions.put(action.Id, action);
				actionsMap.put(indexStr, childActions);
			} else {
				actionsMap.put(indexStr, new Map<String, Action__c> {action.Id => action});
			}
		}
		actions = new List<Action>();
		for (String action : actionsMap.keySet()) {
			actions.add(new Action(parentNames.get(action), actionsMap.get(action)));
		}
	}

	global pageReference cancel() {
		return goToOpportunity(thisOpportunity.Id);
	}

	global pageReference save() {
		Boolean isError = setActionIds(actions);
		if (isError) addErrors(new List<String>{'Необходимо выбрать все мероприятия'});
		if (!isError) {
			PageReference page;
			if (thisOpportunity.Id == null) {
				page = insertOpportunity(thisOpportunity);
			} else {
				page = updateOpportunity(thisOpportunity);
			}
			if (thisOpportunity.Id != null) autoTask.changeAutoTask(thisOpportunity.StageName, thisOpportunity.Id);
			return page;
		}
		return null;
	}

	global Boolean setActionIds(List<Action> actionsList) {
		Boolean isError = false;
		String actionIds = '';
		for (Action action : actionsList) {
			if (!action.isDeleted) {
				if (String.isNotBlank(action.ActionId)) {
					if (ActionIds != '') actionIds += ';'; 
					actionIds += action.ActionId;
				} else {
					isError = true;
				}
			}
		}
		if (thisOpportunity.ActionIds__c != actionIds) thisOpportunity.ActionIds__c = actionIds;
		return isError;
	}

	global void addErrors(List<String> errors) {
		for (String error : errors) {
			ApexPages.Message message = new ApexPages.Message(ApexPages.Severity.ERROR,Error);
			ApexPages.addMessage(message);
		}
	}

	global PageReference insertOpportunity(Opportunity opp) {
		try {
			insert opp;
			return goToOpportunity(opp.Id);
		} catch (Exception ex) {
			addErrors(new List<String> {'Не удалось сохранить заявку'});
			return null;
		}
	}

	global PageReference updateOpportunity(Opportunity opp){
		try {
			update opp;
			return goToOpportunity(opp.Id);
		} catch (Exception ex) {
			addErrors(new List<String> {'Не удалось обновить заявку'});
			return null;
		}
	}

	global PageReference goToOpportunity(String opportunityId){
		PageReference page = new PageReference('/' + opportunityId);
		page.setRedirect(true);
		return page;
	}

}