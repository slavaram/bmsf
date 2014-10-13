public class MGCardsInfoController {

	public List<RowElement> mRows { get; set; }
	public Integer mTotalClients { get; set; }
	public Integer mTotalCards { get; set; }

	{
		mRows = new List<RowElement>();
	}

	public class RowElement {
		public String clientName { get; set; }
		public String clientEmail { get; set; }
		public String clientPhone { get; set; }
		public String clientPhotoUrl { get; set; }
		public String clientId { get; set; }
		public String actionName { get; set; }
		public String actionId { get; set; }
		public List<MasterGroupCards__c> cards { get; set; }
	}
	public MGCardsInfoController() {
		List<MasterGroupCards__c> cards = [SELECT Id, StartDate__c, Client__c, ClientEmail__c, CardType__c,
												Client__r.Phone, Client__r.Name, Client__r.PhotoLink__c
										   FROM MasterGroupCards__c
										   ORDER BY StartDate__c];
		Map<String, List<MasterGroupCards__c>> clientAndCards = new Map<String, List<MasterGroupCards__c>>();
		for (MasterGroupCards__c card : cards) {
			List<MasterGroupCards__c> thisCards = clientAndCards.get(card.Client__c);
			if (thisCards == null) {
				List<MasterGroupCards__c> newCards = new List<MasterGroupCards__c>();
				newCards.add(card);
				clientAndCards.put(card.Client__c, newCards);
			} else {
				thisCards.add(card);
				clientAndCards.put(card.Client__c, thisCards);
			}
		}

		mTotalClients = clientAndCards.keySet().size();
		mTotalCards = cards.size();

		List<Action__c> parentActions = [SELECT Id
										 FROM Action__c
										 WHERE RecordType.Name = 'Группирующее мероприятие'
										 AND (
										 	Name LIKE '%МЗС%' OR
										 	Name LIKE '%Коучинг%' OR
										 	Name LIKE '%Отдел продаж%'
										 	)
										];
		List<Action__c> actions = [SELECT Id, Name, CreatedDate
								   FROM Action__c
								   WHERE ParentId__c IN :parentActions];
		Map<String, Action__c> actionIds = new Map<String, Action__c>();
		for (Action__c action : actions) {
			actionIds.put(action.Id, action);

		}
		List<Opportunity> opps = [SELECT Id, ActionIds__c, AccountId
								  FROM Opportunity
								  WHERE AccountId IN :clientAndCards.keySet()
								  AND ActionIds__c IN :actionIds.keySet()];
		Map<String, List<Action__c>> clientAndActions = new Map<String, List<Action__c>>();
		for (Opportunity opp : opps) {
			List<Action__c> thisActions = clientAndActions.get(opp.AccountId);
			if (thisActions == null) {
				List<Action__c> newActions = new List<Action__c>();
				newActions.add(actionIds.get(opp.ActionIds__c));
				clientAndActions.put(opp.AccountId, newActions);
			} else {
				thisActions.add(actionIds.get(opp.ActionIds__c));
				clientAndActions.put(opp.AccountId, thisActions);
			}
		}

		for (String clientId : clientAndCards.keySet()) {
			RowElement row = new RowElement();
			row.cards = clientAndCards.get(clientId);
			Action__c lastAction = getLastActionBefore(clientAndCards.get(clientId).get(0), clientAndActions);
			if (lastAction != null) {
				row.actionId = lastAction.Id;
				row.actionName = lastAction.Name;
			}
			for (MasterGroupCards__c card : clientAndCards.get(clientId)) {
				row.clientId = (row.clientId == null ? card.Client__c : row.clientId);
				row.clientEmail = (row.clientEmail == null ? card.ClientEmail__c : row.clientEmail);
				row.clientName = (row.clientName == null ? card.Client__r.Name : row.clientName);
				row.clientPhone = (row.clientPhone == null ? card.Client__r.Phone : row.clientPhone);
				row.clientPhotoUrl = (row.clientPhotoUrl == null ? card.Client__r.PhotoLink__c : row.clientPhotoUrl);
			}
			mRows.add(row);
		}
	}

	private Action__c getLastActionBefore(MasterGroupCards__c card, Map<String, List<Action__c>> clientAndActions) {
		String clientId = card.Client__c;
		Date dateBefore = card.StartDate__c;
		List<Action__c> actions = clientAndActions.get(clientId);
		Action__c result;
		if (actions != null) {
			for (Action__c action : actions) {
				if (action.CreatedDate <= dateBefore) {
					if (result == null) {
						result = action;
					} else {
						if (action.CreatedDate > result.CreatedDate) {
							result = action;
						}
					}
				}
			}
		}
		return result;
	}

}