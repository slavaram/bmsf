public class BODayMember {

	public Map<String, Day__c> days									{get; set;}
	public Map<String, List<Day__c>> actionDays						{get; set;}
	public Map<String, ApplicationsActivities__c> opportunityEvents	{get; set;}
	public Map<String, DayMember__c> existingDayMembers				{get; set;}
	public Map<Id, Boolean> markedOpportunityEvents					{get; set;}

	public Class DayMember {
		public DayMember__c member							{get; set;}
		public ApplicationsActivities__c opportunityEvent	{get; set;}
		public Day__c day									{get; set;}
		public Boolean readOnly								{get; set;}
		public Boolean wasMarked							{get; set;}

		public DayMember(DayMember__c dayMember, ApplicationsActivities__c applicationActivity, Day__c theDay, Boolean isReadOnly) {
			member				= dayMember;
			opportunityEvent	= applicationActivity;
			day					= theDay;
			readOnly			= isReadOnly;
		}

		public DayMember(DayMember__c dayMember, Boolean isReadOnly) {
			member		= dayMember;
			readOnly	= isReadOnly;
			try {
				opportunityEvent = [SELECT Id, OpportunityId__c, ActionID__c, ActionID__r.Name, ActionID__r.CityId__c,
				                    	OpportunityId__r.StageName, OpportunityId__r.Debt__c
				                    FROM ApplicationsActivities__c
				                    WHERE  Id = :member.OpportunityEvent__c];
			} catch (Exception ex) {
				opportunityEvent = new ApplicationsActivities__c();
			}
			try {
				day = [SELECT Id, Name, Date__c
				       FROM Day__c
				       WHERE Id = :member.Day__c];
			} catch (Exception ex) {
				day = new Day__c();
			}
		}
	}

	public BODayMember() {
	}

	public BODayMember(Date theDate, String accountId) {
		days					= getDays(theDate);
		actionDays				= getActionDays(days.values());
		opportunityEvents		= getOpportunityEvents(actionDays.keySet(), accountId);
		existingDayMembers		= getExistingDayMembers();
	}

	// GETTER
	public Map<String, Day__c> getDays(Date thisDate) {
		try {
			return new Map<String, Day__c>([SELECT Id, Name, Date__c, ActionId__c FROM Day__c WHERE Date__c = :thisDate]);
		} catch (Exception ex) {
			return new Map<String, Day__c>();
		}
	}

	// GETTER
	public Map<String, List<Day__c>> getActionDays(List<Day__c>  days) {
		List<String> eventIds = new List<String>();
		for (Day__c item : days) {
			if (item.ActionId__c != null ) {
				eventIds.add(item.ActionId__c);
			}
		}
		List<Day__c> allDays;
		try {
			allDays = [SELECT Id, Name, Date__c, ActionId__c
			           FROM Day__c
			           WHERE ActionId__c IN :eventIds
			           ORDER BY ActionId__c, Date__c];
		} catch (Exception ex) {
			allDays = new List<Day__c>();
		} 
		return setMapActionDays(allDays);
	}

	// GETTER
	public Map<String, ApplicationsActivities__c> getOpportunityEvents(Set<String> eventIds, String accountId) {
		try {
			return new Map<String, ApplicationsActivities__c>(
					[SELECT Id, Name, OpportunityId__c, ActionID__c, ActionID__r.Name, ActionID__r.ParentId__c,
					 	ActionID__r.CityId__c, OpportunityId__r.StageName, OpportunityId__r.Debt__c, OpportunityId__r.SeatType__c
					 FROM ApplicationsActivities__c
					 WHERE ActionID__r.ParentId__c IN :eventIds
					 AND OpportunityId__r.AccountId = :accountId
					 AND OpportunityId__r.StageName != 'Дубль'
					 ORDER BY OpportunityId__r.SummOfPayments__c DESC]);
		} catch (exception ex) {
			return new Map<String, ApplicationsActivities__c>();
		}
	}

	// GETTER
	public Map<String, DayMember__c> getExistingDayMembers () {
		Map<String, DayMember__c> result = new Map<String, DayMember__c>();
		markedOpportunityEvents = new Map<Id, Boolean>();
		for (DayMember__c dayMember : getExistingListDayMembers(opportunityEvents.keySet())) {
			result.put(String.valueOf(dayMember.OpportunityEvent__c) + String.valueOf(dayMember.Day__c), dayMember);
			markedOpportunityEvents.put(dayMember.OpportunityEvent__c, true);
		}
		return result;
	}

	public Map<Id, List<DayMember>> getDayMemders() {
		return setDayMembers();
	}

	public Map<Id, List<DayMember>> setDayMembers(){
		Map<Id, List<DayMember>> result = new Map<Id, List<DayMember>>();
		for (ApplicationsActivities__c opportunityEvent : opportunityEvents.values()) {
			List<DayMember> dayMembers = getDayMembersByOpportunityEvent(opportunityEvent, actionDays.get(opportunityEvent.ActionID__r.ParentId__c));
			result.put(opportunityEvent.Id, dayMembers);
		}
		return result;
	}

	public Map<String, List<Day__c>> setMapActionDays(List<Day__c> allDays) {
		Map<String, List<Day__c>> result = new Map<String, List<Day__c>>();
		for (Day__c day : allDays) {
			String actionId = (day.ActionId__c != null ? String.valueOf(day.ActionId__c) : '-empty-');
			List<Day__c> listDays = new List<Day__c>();
			if (result.containsKey(actionId)) listDays = result.get(actionId);
			ListDays.add(day);
			result.put(actionId, listDays);
		}
		return result;
	}	

	public List<DayMember__c> getExistingListDayMembers(Set<String> opportunityEventIds) {
		return [SELECT IsPassed__c, Day__c, OpportunityEvent__c, Comment__c, Reason__c, City__c, ArmletKey__c
		        FROM DayMember__c
		        WHERE OpportunityEvent__c IN :opportunityEventIds
		        ORDER BY Day__r.Date__c];
	}

	public List<DayMember> getDayMembersByOpportunityEvent(ApplicationsActivities__c opportunityEvent, List<Day__c> opportunityEventDays) {
		List<DayMember> result = new List<DayMember>(); 
		for (Day__c day : opportunityEventDays) {
			DayMember mDay;
			if (isCurrentDay(Day)) {
				if (isExistingDayMember(opportunityEvent.Id, day.Id)) {
					mDay = new DayMember(getExistingDayMember(opportunityEvent.Id, day.Id), false);
				} else {
					mDay = new DayMember(
							new DayMember__c(OpportunityEvent__c = opportunityEvent.Id, City__c = opportunityEvent.ActionId__r.CityId__c, Day__c = day.Id, IsPassed__c = false),
							opportunityEvent,
							day,
							false);
				}
			}
			if (!isCurrentDay(day)) {
				if (isExistingDayMember(opportunityEvent.Id, day.Id)) {
					mDay = new DayMember(getExistingDayMember(opportunityEvent.Id, day.Id), true);
				} else {
					mDay = new DayMember(
							new DayMember__c(OpportunityEvent__c = opportunityEvent.Id, Day__c = day.Id, IsPassed__c = false),
							opportunityEvent,
							day,
							true);
				}
			}
			mDay.wasMarked = wasMarked(opportunityEvent.Id);
			result.add(mDay);
		}
		return result;
	}

	private Boolean isCurrentDay(Day__c day) {
		return (day.Id != null ? days.containsKey(day.Id) : false);
	}

	private Boolean isExistingDayMember(Id opportunityEventId, Id dayId) {
		return (opportunityEventId != null && dayId != null ? existingDayMembers.containsKey(String.valueOf(opportunityEventId) + String.valueOf(dayId)) : false);
	}

	private DayMember__c getExistingDayMember(Id opportunityEventId, Id dayId) {
		return (opportunityEventId != null && dayId != null ? existingDayMembers.get(String.valueOf(OpportunityEventId) + String.valueOf(dayId)) : new DayMember__c());
	}

	private Boolean wasMarked(Id opportunityEventId) {
		return (opportunityEventId != null ? markedOpportunityEvents.containsKey(OpportunityEventId) : false);
	}

}