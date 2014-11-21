public class BMOpportunity {

	public Opportunity data {
		get {
			return (data == null ? new Opportunity() : data);
		}
		set;
	}

	public BMOpportunity() {}

	public BMOpportunity(String opportunityId) {
		data = [SELECT Id, Name, ProductId__c, ProductId__r.RecordTypeId, ActionIds__c, CreatedDate, StageName
		        FROM Opportunity
		        WHERE Id = :opportunityId];
	}

	public BMOpportunity(Opportunity opp) {
		try {
			data = [SELECT Id, Name, ProductId__c, ProductId__r.RecordType.DeveloperName, ActionIds__c, CreatedDate, StageName
			        FROM Opportunity
			        WHERE Id = :opp.Id];
		} catch (Exception ex) {
			data = opp;
		}
	}

	public void calculateDiscount(List<Opportunity> opportunities) {
		for (Opportunity opportunity : opportunities) {
			Date discountDate = (opportunity.CalculateDiscountDate__c == null ? Date.valueOf(opportunity.CreatedDate) : opportunity.CalculateDiscountDate__c);
			opportunity.Discount__c = new BMOpportunity(opportunity).calculateDiscount(discountDate);
			opportunity.CalculateDiscountDate__c = discountDate;
		}
	}

	public Decimal calculateDiscount(DateTime calculationDate) {
		List<String> actionIds = new List<String>();
		if (String.isNotBlank(data.ActionIds__c)) actionIds = Data.ActionIds__c.split(';');
		List<AvailableEvents__c> availableEvents = new List<AvailableEvents__c>();
		if (data.Id != null ) {
			availableEvents = new List<AvailableEvents__c>(
					[SELECT Id, Name, Product__c, Product__r.Id, Product__r.Name, ActionID__c
					 FROM AvailableEvents__c
					 WHERE Product__c  = :data.ProductId__c
					 AND ActionID__c IN :actionIds
					 ORDER BY Product__r.Name]);
		}
		List<String> actionIdsForDiscount = new List<String>();
		if (data.ProductId__r.RecordType.DeveloperName == 'SingleRecord') actionIdsForDiscount.addAll(actionIds);
		List<String> productIds = new List<String>();
		if (data.ProductId__c != null ) productIds.add(Data.ProductId__c);
		List<Discount__c> discountList = new List<Discount__c>();
		if (opportunity.Id != null) {
			discountList = [SELECT Id, AvailableEventId__c, ProductID__c, ActionId__c, name, AbsolutelyDiscount__c, AbsolutelyDiscountLocal__c, StartDate__c, EndDate__c
			                FROM Discount__c
			                WHERE AvailableEventId__c IN :availableEvents
			                OR ProductID__c IN :productIds
			                OR ActionId__c IN :actionIdsForDiscount];
		}
		return calculateDiscountByDate(discountList, calculationDate);
	}

	public List<Opportunity> searchOpportunities(String productId, Date startDate, Date endDate, String stageName) {
		List<Opportunity> opportunities = new List<Opportunity>();
		if (productId == null) {
			opportunities = [SELECT Id, Name, StageName, Amount, ProductId__c, Discount__c, Account.Name, CreatedDateTime__c, CalculateDiscountDate__c
	    	                 FROM Opportunity
	    	                 WHERE CreatedDateTime__c >= :startDate
	    	                 AND CreatedDateTime__c <= :endDate
	    	                 AND StageName = :stageName];
		} else {
			opportunities = [SELECT Id, Name, StageName, Amount, ProductId__c, Discount__c, Account.Name, CreatedDateTime__c, CalculateDiscountDate__c
	 		                 FROM Opportunity
	 		                 WHERE CreatedDateTime__c >= :startDate
	 		                 AND CreatedDateTime__c <= :endDate
	 		                 AND Productid__c = :productId
	 		                 AND StageName = :stageName];
		}
		return opportunities;
	}

	private List<String> getActionIds(List<AvailableEvents__c> availableEvents) {
		List<String> result = new List<String>();
		for (AvailableEvents__c item : AvailableEvents ) {
			Action__c action = new Action__c();
			if (item.ActionID__c != null) {
				action = [SELECT Id, Name, ParentId__c, ParentId__r.Id, ParentId__r.Name FROM Action__c WHERE Id = :item.ActionID__c];
				if (action.Id != null ) result.add(action.Id);
				if (action.ParentId__c != null && action.ParentId__r.Id != null) result.add(Action.ParentId__r.Id);
			}
		}
		return result;
	}

	private Decimal calculateDiscountByDate(List<Discount__c> discounts, DateTime selectedDate) {
		Decimal result = 0;
		for (Discount__c discount : discounts) {
			result += calculateDiscountByDate(discount, selectedDate);
		}
		return result;
	}

	private Decimal calculateDiscountByDate(Discount__c discount, DateTime selectedDate) {
		return (selectedDate >= discount.StartDate__c && selectedDate <= discount.EndDate__c && discount.AbsolutelyDiscount__c != null ? discount.AbsolutelyDiscount__c : 0 );
	}

}