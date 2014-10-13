public class ServicesInfo {

	public static final String ROOT_GROUP_ID;
	public static final String TOP_GROUP_ID_0;
	public static final String TOP_GROUP_ID_1;
	public static final String TOP_GROUP_ID_2;
	public static final String TOP_GROUP_ID_3;
	public static final String TOP_GROUP_ID_4;
	public static final String TOP_GROUP_ID_5;

	public class Bean {
		public Id		clientId				{get; private set;}
		public Id		serviceProductId		{get; private set;}
		public String	serviceProductName		{get; private set;}
		public Id		serviceProductGroupId	{get; private set;}
		public Id		educationProductId		{get; private set;}
		public String	educationProductName	{get; private set;}
		public String	educationProductGroupId {get; private set;}
		public Id		educationActionId		{get; private set;}
		public String	educationActionName		{get; private set;}
	}

	static {
		ROOT_GROUP_ID	= TopProductGroup__c.getValues('Сервисы').Id__c;
		TOP_GROUP_ID_0	= TopProductGroup__c.getValues('Интенсив, Коучинг').Id__c;
		TOP_GROUP_ID_1	= TopProductGroup__c.getValues('Карьера').Id__c;
		TOP_GROUP_ID_2	= TopProductGroup__c.getValues('Миллион за сто').Id__c;
		TOP_GROUP_ID_3	= TopProductGroup__c.getValues('Отдел продаж').Id__c;
		TOP_GROUP_ID_4	= TopProductGroup__c.getValues('Распродажа').Id__c;
		TOP_GROUP_ID_5	= TopProductGroup__c.getValues('Самолет. VIP').Id__c;
	}

	public static List<Bean> createBeans(Date fromDate, Date byDate, Id serviceGroupId, Id educationGroupId) {
		List<Bean> result = new List<Bean>();
		String serviceQuery = 'SELECT Id, Name, Account.Id, CreatedDate, ProductId__c, ProductId__r.Name, ProductId__r.ProductGroup__c, RelatedOpportunity__r.ActionIds__c, ' +
							  'RelatedOpportunity__r.ProductId__c, RelatedOpportunity__r.ProductId__r.ProductGroup__c, RelatedOpportunity__r.ProductId__r.Name, RelatedOpportunity__r.ActionNames__c ' +
							  'FROM Opportunity ' +
							  'WHERE ' +
							  'CreatedDate >= ' + SoqlUtils.formatDateTime(fromDate) + ' ' +
							  'AND CreatedDAte <= ' + SoqlUtils.formatDateTime(byDate) + ' ' +
							  'AND ProductId__r.ProductGroup__r.HierachyPath__c LIKE \'%' + (serviceGroupId == null ? ROOT_GROUP_ID : serviceGroupId) + '%\' ' +
							  (educationGroupId == null ? '' : 'AND RelatedOpportunity__r.ProductId__r.ProductGroup__r.HierachyPath__c LIKE \'%' + educationGroupId + '%\' ') +
							  'AND RelatedOpportunity__c != null ' +
							  'ORDER BY CreatedDate';
		List<Opportunity> opportunities = Database.query(serviceQuery);
		for (Opportunity opp : opportunities) {
			result.add(createBean(opp));
		}
		return result;
	}

	private static ServicesInfo.Bean createBean(Opportunity opp) {
		Bean bean					= new Bean();
		bean.clientId				= opp.Account.Id;
		bean.serviceProductId		= opp.ProductId__c;
		bean.serviceProductName		= opp.ProductId__r.Name;
		bean.serviceProductGroupId	= opp.ProductId__r.ProductGroup__c;
		
		bean.educationProductId			= opp.RelatedOpportunity__r.ProductId__c;
		bean.educationProductName		= opp.RelatedOpportunity__r.ProductId__r.Name;
		bean.educationProductGroupId 	= opp.RelatedOpportunity__r.ProductId__r.ProductGroup__c;
		bean.educationActionName		= opp.RelatedOpportunity__r.ActionNames__c;
		try {
		if (opp.RelatedOpportunity__r.ActionIds__c != null) {
			if (String.isBlank(opp.RelatedOpportunity__r.ActionIds__c.substringAfter('\''))) {
				bean.educationActionId = opp.RelatedOpportunity__r.ActionIds__c.substringBefore(';');
			} else {
				String action = opp.RelatedOpportunity__r.ActionIds__c.substringAfter('\'').substringBefore('\'');
				bean.educationActionId = Id.valueOf((String.isBlank(action.substringAfter(';')) ? action : action.substringBefore(';')));
			}
		}
		} catch (Exception ex) {
			System.debug(opp.RelatedOpportunity__r.ActionIds__c);
			System.debug(LoggingLevel.ERROR, ex.getMessage());
		}
		return bean;
	}

}