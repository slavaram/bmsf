public with sharing class DayMemberController {

	public Account client			{get; set;}
	public Boolean isSendAllTask	{get; set;}
	public Boolean isLoan			{get; private set;}
	public String loanStatus		{get; private set;}
	public String seatType			{get; private set;}
	public Boolean cardGranted		{get; set;}

	public String countTask			{get; set;}
	public String countProfit		{get; set;}
	public String countBad			{get; set;}
	public String countChecked		{get; set;}
	public String numberPromo		{get; set;}
	public String numberPromo2		{get; set;}

	public PromoCode__c promo1		{get; set;}
	public Boolean doubPromo1		{get; set;}
	public Boolean noFoundPromo1	{get; set;}
	public PromoCode__c promo2		{get; set;}
	public Boolean doubPromo2		{get; set;}
	public Boolean noFoundPromo2	{get; set;}

	public Map<Id, List<BODayMember.DayMember>> dayMembers		{get; set;}
	public List<ApplicationsActivities__c> opportunityEvents	{get; set;}

	private Boolean savable = false;
	private Set<String> profiles = new Set<String> {'00eb0000000QbbzAAC', '00eb0000000QbcJAAS', '00eb0000000QbbzAAC', '00eb0000000QbcJAAS'};

	public Integer dayMembersSize {
		get {return dayMembers.size();} 
		set;
	}

	{
		dayMembers = new Map<Id, List<BODayMember.DayMember>>();
		isLoan = false;
	}

	public DayMemberController(ApexPages.Standardcontroller controller) {
	 	init(controller.getId());
	}

	private void init(String accountId) {
		Client = [SELECT Name, Id, Phone, PersonEmail, Owner__c, isCardGiven__c FROM Account WHERE Id = :accountId].get(0);
		cardGranted					= client.isCardGiven__c;
		BODayMember dayMemberData	= new BODayMember(Date.today(), client.Id);
		opportunityEvents			= dayMemberData.opportunityEvents.values();
		dayMembers					= dayMemberData.getDayMemders();
		seatType					= getSeatType();
		statusSendAllTask();
		/*for (ApplicationsActivities__c activity : opportunityEvents) {
			if (activity.OpportunityId__r.LoanStatus__c == 'Акт по кредиту сформирован') {
				isLoan = true;
				loanStatus = 'Акт по кредиту сформирован';
			} else {*/
				savable = true;
			/*}
		}*/
	}

	private void statusSendAllTask() {
		if (opportunityEvents.size() > 0) {
			List<ReportStatistic__c> hws = [SELECT Id, Checked__c
			                                FROM ReportStatistic__c
			                                WHERE EventId__c = :OpportunityEvents[0].ActionID__r.ParentId__c
			                                AND AccountId__c = :Client.Id];
			Boolean good = True;
			Integer countT = 0;
			Integer countC = 0;
			Integer countB = 0;
			Integer countP = 0;
			countT = hws.size();
			for (ReportStatistic__c hw: hws) {
				if (hw.Checked__c == 'Отклонено') {
					countB++;
					countC++;
				}
				if (hw.Checked__c == 'Принято')	{
					countP++;
					countC++;
				}
			} 
			countChecked	= String.valueOf(countC) + '/10';
			countProfit		= String.valueOf(countP) + '/10';
			countBad		= String.valueOf(countB) + '/10';
			countTask		= String.valueOf(countT) + '/10';
		}
	}

	public PageReference getPromoCode() {
		promo1 = null;
		promo2 = null;
		String qCode = getNumberPromo(numberPromo);
		try{
			promo1 = [SELECT Id, AccountId__c, Name, Code__c, Status__c FROM PromoCode__c WHERE Code__c LIKE :qCode];
			if (promo1.AccountId__c != null) {
				doubPromo1 = true;
			}
		} catch (System.QueryException ex) {}
		qCode = getNumberPromo(numberPromo2);
		try {
			promo2 = [SELECT Id, AccountId__c, Name, Code__c, Status__c FROM PromoCode__c WHERE Code__c LIKE :qCode];
			if (promo2.AccountId__c != null) {
				doubPromo2 = true;
			}
		}
		catch(System.QueryException ex)	{}
		return null;
	}

	public PageReference save() {
		if (!savable && profiles.contains(UserInfo.getProfileId())) return null;
		List<DayMember__c> toDelete = new List<DayMember__c>();
		List<DayMember__c> toInsert = new List<DayMember__c>();
		if (promo1 != null && doubPromo1 != true) {
			promo1.AccountId__c = client.Id;
			promo1.Status__c = 'Новый';
			update promo1;
		}
		if (promo2 != null && doubPromo2 != true) {
			promo2.AccountId__c = client.Id;
			promo2.Status__c = 'Новый';
			update promo2;
		}
		for (List<BODayMember.DayMember> items : dayMembers.values()) {
			for (BODayMember.DayMember item : items) {
				if (item.Member.Id != null ) {
					if (!item.Member.IsPassed__c) toDelete.add(item.Member);
				} else {
					if (item.Member.IsPassed__c) toInsert.add(item.Member);
				}
			}
		}
		if (!ToDelete.isEmpty()) delete toDelete;
		if (!ToInsert.isEmpty()) insert toInsert;
	    update new Account(Id = client.Id, isCardGiven__c = cardGranted);
	    return (toInsert.isEmpty() ? null : (new ApexPages.StandardController(toInsert.get(0))).view());
	}

	private String getNumberPromo(String code) {
		String res = code;
		Integer delta;
		if (res.length() < 4) {
			delta = 4 - res.length();
		}
		String temp = '';
		for (Integer i = 0; i < delta; i++)	{
			temp = temp + '0';
		}
		res = temp + res;
		res = '%ОП02' + res + '%';
		return res;
	}

	// FAIL DELETE AS FAST AS YOU CAN
	private String getSeatType() {
		if (opportunityEvents.isEmpty()) return '-';
		if (opportunityEvents.get(0).OpportunityId__r.ProductId__c == '01tb0000002gZb0') return 'Задние ряды';
		if (opportunityEvents.get(0).OpportunityId__r.ProductId__c == '01tb0000002gZcy') return 'VIP';
		if (opportunityEvents.get(0).OpportunityId__r.ProductId__c == '01tb0000002gZav') return 'Середина зала';
		if (opportunityEvents.get(0).OpportunityId__r.ProductId__c == '01tb0000002gaIF') return 'Для участников коучинга';
		return opportunityEvents.get(0).OpportunityId__r.SeatType__c;
	}

}