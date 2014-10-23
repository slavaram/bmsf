public class EventsInfoController {

	public Action__c mCityLookUp { get; set; }
	public List<SelectOption> mProductGroups { get; set; }
	public String mProductGroup { get; set; }
	public List<RowElement> mEvents { get; set; }
	public List<RowElement> mMasterGroupEvents { get; set; }
	public Day__c mToday { get; set; }
	public String mProductId { get; set; }
	public String mActionId { get; set; }
	public Boolean mAllProductGroupsMode { get; set; }
	public static final List<String> MASTER_PRODUCT_GROUP_IDS = new List<String>();
	public static final List<String> ALL_PRODUCT_GROUP_IDS = new List<String>();
	public static final String NEW_OPPORTUNITY_STAGE_NAME = 'Назначена';

	public class RowElement {
		public String productName { get; set; }
		public String productGroupName { get; set; }
		public String actionName { get; set; }
		public Date actionStartDate { get; set; }
		public String actionStartTime { get; set; }
		public Date actionEndDate { get; set; }
		public Decimal productPrice { get; set; }
		public Decimal productPriceTomorrow { get; set; }
		public String productId { get; set; }
		public String productGroupId { get; set; }
		public String actionId { get; set; }

		public Boolean isRowSpanedOwer { get; set; }
		public Integer rowSpanedOwer { get; set; }
	}

	{
		mProductGroups = new List<SelectOption>();
		mEvents = new List<RowElement>();
		mMasterGroupEvents = new List<RowElement>();
		mToday = new Day__c(Date__c = System.today());
		mAllProductGroupsMode = true;
		mCityLookUp = new Action__c(CityId__c = 'a05b0000001cdpeAAA');
	}

	static {
		MASTER_PRODUCT_GROUP_IDS.add('a0Lb0000005DP5ZEAW'); // Региональный мастер-класс
		ALL_PRODUCT_GROUP_IDS.add('a0Lb0000002ZByQEAW'); // Игра
		ALL_PRODUCT_GROUP_IDS.add('a0Lb0000006B7obEAC'); // Игра. ИК
		ALL_PRODUCT_GROUP_IDS.add('a0Lb0000006A4YtEAK'); // ИК для женищин
		ALL_PRODUCT_GROUP_IDS.add('a0Lb0000002Wa7bEAC'); // Интенсив, Коучинг
		ALL_PRODUCT_GROUP_IDS.add('a0Lb0000006A9akEAC'); // Карта UNLIM
		ALL_PRODUCT_GROUP_IDS.add('a0Lb0000003jxsKEAQ'); // Карты
		ALL_PRODUCT_GROUP_IDS.add('a0Lb0000005Ga6NEAS'); // Кураторство
		ALL_PRODUCT_GROUP_IDS.add('a0Lb0000007OgMMEA0'); // Маркетинг
		ALL_PRODUCT_GROUP_IDS.add('a0Lb0000002Wa80EAC'); // Миллион за сто
		ALL_PRODUCT_GROUP_IDS.add('a0Lb0000003muUxEAI'); // Миллион за сто. Vip вебинар
		ALL_PRODUCT_GROUP_IDS.add('a0Lb0000005EKEeEAO'); // Отдел продаж
		ALL_PRODUCT_GROUP_IDS.add('a0Lb0000005ETzeEAG'); // Отдел продаж. VIP
		ALL_PRODUCT_GROUP_IDS.add('a0Lb0000006ArZ8EAK'); // Самолет. VIP
		ALL_PRODUCT_GROUP_IDS.add('a0Lb0000002YD8iEAG'); // Самолет. ИК

		MASTER_PRODUCT_GROUP_IDS.add('a0L11000000fgMJEAY'); // SANDBOX
		ALL_PRODUCT_GROUP_IDS.add('a0L110000006aZcEAI'); // SANDBOX
		ALL_PRODUCT_GROUP_IDS.add('a0L110000006cfCEAQ'); // SANDBOX
		ALL_PRODUCT_GROUP_IDS.add('a0L11000000fgMJEAY'); // SANDBOX
	}

	public EventsInfoController() {
		mProductGroups = processProductGroups(EventsInfoController.ALL_PRODUCT_GROUP_IDS);
		mProductGroup = mProductGroups.get(0).getValue();
		processProducts();
	}

	public void processProducts() {
		mMasterGroupEvents.clear();
		mEvents.clear();
		List<AvailableEvents__c> events = getEvents(EventsInfoController.MASTER_PRODUCT_GROUP_IDS);
		mMasterGroupEvents  = getRowElements(events);
		events.clear();
		List<String> productGroupIds = new List<String>();
		if (mProductGroup == '0') {
			productGroupIds.addAll(EventsInfoController.ALL_PRODUCT_GROUP_IDS);
			mAllProductGroupsMode = true;
		} else {
			productGroupIds.add(mProductGroup);
			mAllProductGroupsMode = false;
		}
		events = getEvents(productGroupIds);
		mEvents = getRowElements(events);
	}

	public PageReference createOpportunity() {
		Opportunity opp = new Opportunity(ProductId__c = mProductId, ActionIds__c = mActionId,
										  StageName = EventsInfoController.NEW_OPPORTUNITY_STAGE_NAME,
										  CloseDate = System.today().addDays(7));
		insert opp;
		PageReference redirect = new PageReference('/apex/Opportunity?retURL=%2F' + opp.Id +
												   '&scontrolCaching=1&sfdc.override=1&id=' + opp.Id);
		return redirect;
	}


	private List<RowElement> getRowElements(List<AvailableEvents__c> events) {
		List<RowElement> result = new List<RowElement>();
		Map<String, Decimal> productPrices = getProductPrices(events);
		Map<String, Decimal> productDiscounts = getProductDiscounts(events, System.today());
		Map<String, Decimal> productDiscountsTomorrow = getProductDiscounts(events, System.today().addDays(1));
		for (AvailableEvents__c event : events) {
			Decimal productPrice = (productPrices.get(event.Product__c) == null ? 0 : productPrices.get(event.Product__c));
			Decimal productDiscount = productDiscounts.get(event.Id);
			Decimal productDiscountTomorrow = productDiscountsTomorrow.get(event.Id);
			RowElement element = new RowElement();
			element.productName = event.Product__r.Name;
			element.productGroupName = event.Product__r.ProductGroup__r.Name;
			element.actionName = event.ActionID__r.Name;
			element.actionStartDate = event.ActionID__r.StartDate__c;
			element.actionStartTime = event.ActionID__r.StartTime__c;
			element.actionEndDate = event.ActionID__r.EndDate__c;
			element.productPrice = productPrice - productDiscount;
			element.productPriceTomorrow = productPrice - productDiscountTomorrow;
			element.productId = String.valueOf(event.Product__c);
			element.productGroupId = String.valueOf(event.Product__r.ProductGroup__c);
			element.actionId = String.valueOf(event.ActionID__c);
			result.add(element);
		}
		String productGroupId;
		for (RowElement rowElement : result) {
			rowElement.isRowSpanedOwer = true;
			if (productGroupId == null || productGroupId != rowElement.productGroupId) {
				productGroupId = rowElement.productGroupId;
			} else {
				rowElement.isRowSpanedOwer = false;
			}
		}
		RowElement lastRowElement;
		for (RowElement rowElement : result) {
			if (lastRowElement == null || rowElement.isRowSpanedOwer == true) {
				lastRowElement = rowElement;
				lastRowElement.rowSpanedOwer = 1;
			} else {
				lastRowElement.rowSpanedOwer += 1;
			}
		}
		return result;
	}


	private List<SelectOption> processProductGroups(List<String> productGroupIds) {
		List<SelectOption> result = new List<SelectOption>();
		List<ProductGroup__c> productGroups = [SELECT Id, Name FROM ProductGroup__c WHERE Id IN :productGroupIds ORDER BY Name];
		for (ProductGroup__c productGroup : productGroups) {
			result.add(new SelectOption(productGroup.Id, productGroup.Name));
		}
		result.add(new SelectOption('0', '-все-'));
		result.sort();
		return result;
	}

	private Map<String, Decimal> getProductPrices(List<AvailableEvents__c> events) {
		Map<String, Decimal> result = new Map<String, Decimal>();
		List<String> productIds = new List<String>();
		for (AvailableEvents__c event : events) {
			productIds.add(event.Product__c);
		}
		String pricebookId = [SELECT Id FROM Pricebook2 WHERE IsActive = true AND IsStandard = true].get(0).Id;
		List<PricebookEntry> pricebookEntries = [SELECT Id, Product2Id, UnitPrice 
												 FROM PricebookEntry 
												 WHERE Pricebook2Id = :pricebookId
												 AND Product2Id IN :productIds];
		for (PricebookEntry price : pricebookEntries) {
			result.put(price.Product2Id, price.UnitPrice);
		}
		return result;
	}

	private Map<String, Decimal> getProductDiscounts(List<AvailableEvents__c> events, Date dateTo) {
		Map<String, Decimal> result = new Map<String, Decimal>();
		List<String> eventIds = new List<String>();
		List<String> actionIds = new List<String>();
		List<String> productIds = new List<String>();
		for (AvailableEvents__c event : events) {
			eventIds.add(event.Id);
			actionIds.add(event.ActionID__c);
			productIds.add(event.Product__c);
		}
		List<Discount__c> discounts = [SELECT AbsolutelyDiscount__c, AvailableEventId__c, ActionId__c, ProductID__c
									   FROM Discount__c
									   WHERE ((StartDate__c != NULL AND StartDate__c <= :dateTo) OR StartDate__c = NULL)
									   AND ((EndDate__c != NULL AND EndDate__c >= :dateTo) OR EndDate__c = NULL)
									   AND (
											AvailableEventId__c IN :eventIds
											OR ActionId__c IN :actionIds
											OR ProductID__c IN :productIds
									   )];
		Decimal totalDiscount = 0;
		for (AvailableEvents__c event : events) {
			totalDiscount = 0;
			for (Discount__c discount : discounts) {
				if (ApexUtils.isEqualStrings(event.Id, discount.AvailableEventId__c)  ||
					ApexUtils.isEqualStrings(event.ActionId__c, discount.ActionId__c) ||
					ApexUtils.isEqualStrings(event.Product__c, discount.ProductID__c)) {
					totalDiscount += discount.AbsolutelyDiscount__c;
				}
			}
			result.put(event.Id, totalDiscount);
		}
		return result;
	}

	private List<AvailableEvents__c> getEvents(List<String> productGroups){
		Datetime now = Datetime.now().addHours(4);
		List<AvailableEvents__c> result = new List<AvailableEvents__c>();
		List<AvailableEvents__c> actions = [SELECT Id, Product__c, Product__r.Name, Product__r.ProductGroup__c,
												Product__r.ProductGroup__r.Name, Product__r.ProductIds__c,
												ActionID__c, ActionID__r.Name, ActionID__r.StartDate__c,
												ActionID__r.EndDate__c, ActionID__r.StartTime__c
											FROM AvailableEvents__c
											WHERE ActionID__r.CityId__c = :mCityLookUp.CityId__c
											AND Product__r.ProductGroup__c IN :productGroups
											AND (ActionID__r.RegistrationStartDate__c != NULL AND ActionID__r.RegistrationStartDate__c < :now)
											AND (ActionID__r.RegistrationEndDate__c != NULL AND ActionID__r.RegistrationEndDate__c > :now)
											AND (ActionID__r.EndDate__c != NULL AND ActionID__r.EndDate__c > TODAY)
											AND ActionID__r.StartDate__c != NULL
											ORDER BY Product__r.ProductGroup__r.Name DESC];
		for (AvailableEvents__c action : actions) {
			if (action.Product__r.ProductIds__c == null) {
				result.add(action);
			}
		}
		return result;
	}

}