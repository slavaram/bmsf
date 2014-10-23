public class BM_CampaignMemberDAO {

	private static final String FIELDS		= 'Id, CampaignId, Campaign.Priority__c, ContactId, Contact.Name';
	private static final String OBJECT_NAME	= 'CampaignMember';

	public class Filter	{
		public String campaignId						{get; set;}
		public Boolean isCampaignActive					{get; set;}
		public Boolean selectMembersForAccountsOnly		{get; set;}
		public Boolean isAutoTaskCreated				{get; set;}
		public Boolean isSuperGroup						{get; set;}
		public String[] accountOwnersIds				{get; set;}
		public Integer limitOfResultSet					{get; set;}
		public String fieldsForSorting					{get; set;}
		public BM_SoqlUtils.SortingOrder sortingOrder	{get; set;}
	}

	public static List<CampaignMember> getMembersByFilter(Filter filter) {
		String condition = createConditionByFilter(filter);
		if (String.isBlank(condition)) return null;
        BM_SoqlQueryBuilder queryBuilder	= new BM_SoqlQueryBuilder(FIELDS, OBJECT_NAME);
    	queryBuilder.condition				= condition;
    	queryBuilder.limitOfResultSet		= filter.limitOfResultSet;
    	queryBuilder.setOrderByBlock(filter.fieldsForSorting, filter.sortingOrder);
        return BM_SoqlUtils.performQuery(queryBuilder);
	}

	private static String createConditionByFilter(Filter filter) {
		if (filter == null) return null;
		List<String> conditions = new List<String>();
		if (filter.isSuperGroup == true) {
			conditions.add('CampaignId = \'701b0000000DnyR\' or CampaignId = \'701b0000000Du01\' or CampaignId = \'701b0000000DvgY\'');
		} else {
			conditions.add('CampaignId != \'701b0000000DnyR\' and CampaignId != \'701b0000000Du01\' and CampaignId != \'701b0000000DvgY\'');
		}
		if (filter.isCampaignActive != null) conditions.add('Campaign.IsActive = ' + filter.isCampaignActive);
		if (filter.isAutoTaskCreated != null) conditions.add('IsCallTaskCreated__c = ' + filter.isAutoTaskCreated);
		if (filter.selectMembersForAccountsOnly != null && filter.selectMembersForAccountsOnly) conditions.add('ContactId != null AND Contact.AccountId != null');
		String ownerIds = BM_SoqlUtils.joinStringsForINSection(filter.accountOwnersIds);
		if (String.isNotBlank(stringOfAccountOwnersIds)) conditions.add('Contact.Account.OwnerId IN (' + ownerIds + ')');
		return BM_SoqlUtils.joinConditions(conditions, BM_SoqlUtils.LogicOperator.AND_OPERATOR);
	}

}