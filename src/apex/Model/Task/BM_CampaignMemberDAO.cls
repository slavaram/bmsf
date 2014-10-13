public class BM_CampaignMemberDAO {

	public static final Integer KEY_BASIC_FIELDS = 1;
	public static final Integer KEY_FIELDS_WITH_CONTACT_INFO = 2;

	private static final String BASIC_FIELDS = 'Id, CampaignId';
	private static final String FIELDS_WITH_CONTACT_INFO = BASIC_FIELDS	+ ', Campaign.Priority__c, ContactId, Contact.Name';
    private static final Map<Integer, String> MAP_OF_FIELDS_LISTS;
	private static String OBJECT_NAME = 'CampaignMember';

    static {
    	MAP_OF_FIELDS_LISTS = new Map<Integer, String>();
    	MAP_OF_FIELDS_LISTS.put(KEY_BASIC_FIELDS, BASIC_FIELDS);
    	MAP_OF_FIELDS_LISTS.put(KEY_FIELDS_WITH_CONTACT_INFO, FIELDS_WITH_CONTACT_INFO);
    }

	public class Filter	{
		public String campaignId {get; set;}
		public Boolean isCampaignActive {get; set;}
		public Boolean selectMembersForAccountsOnly {get; set;}
		public Boolean isAutoTaskCreated {get; set;}
		public Boolean isSuperGroup {get; set;}
        public Boolean groupToCampaign {get; set;}
		public String[] accountOwnersIds {get; set;}

		public Integer limitOfResultSet {get; set;}
		public String fieldsForSorting {get; set;}
		public BM_SoqlUtils.SortingOrder sortingOrder {get; set;}
	}

	private static String createConditionByFilter(Filter filter) {
		if (filter == null) {
			return null;
		}
		List<String> listOfConditions = new List<String>();
		if (filter.isSuperGroup == true) {
			listOfConditions.add('CampaignId = \'701b0000000DnyR\' or CampaignId = \'701b0000000Du01\' or CampaignId = \'701b0000000DvgY\'');
		} else {
			listOfConditions.add('CampaignId != \'701b0000000DnyR\' and CampaignId != \'701b0000000Du01\' and CampaignId != \'701b0000000DvgY\'');
		}
		if (filter.groupToCampaign == false) {
			listOfConditions.add('CampaignId != \'701b0000000DoWZ\' and CampaignId != \'701b0000000DqBe\' and CampaignId != \'701b0000000DrUD\'');
		}
		if (filter.isCampaignActive != null) {
			listOfConditions.add('Campaign.IsActive = ' + filter.isCampaignActive);
		}    	
		if (filter.isAutoTaskCreated != null) {
			listOfConditions.add('IsCallTaskCreated__c = ' + filter.isAutoTaskCreated);
		}
		if (filter.selectMembersForAccountsOnly != null && filter.selectMembersForAccountsOnly)	{
			listOfConditions.add('ContactId != null AND Contact.AccountId != null');
		}
		String stringOfAccountOwnersIds = BM_SoqlUtils.joinStringsForINSection(filter.accountOwnersIds);
		if (String.isNotBlank(stringOfAccountOwnersIds)) {
			listOfConditions.add('Contact.Account.OwnerId IN (' + stringOfAccountOwnersIds + ')');
		}
		return BM_SoqlUtils.joinConditions(listOfConditions, BM_SoqlUtils.LogicOperator.AND_Operator);
	}

	public static List<CampaignMember> getMembersByFilter(Integer fieldsListKey, Filter filter) {
		String fieldsList = MAP_OF_FIELDS_LISTS.get(fieldsListKey);
		String condition = createConditionByFilter(filter);
		if (String.isBlank(fieldsList) || String.isBlank(condition)) {
        	return null;
        }
        BM_SoqlQueryBuilder queryBuilder = new BM_SoqlQueryBuilder(fieldsList, OBJECT_NAME);
    	queryBuilder.condition = condition;
    	queryBuilder.setOrderByBlock(filter.fieldsForSorting, filter.sortingOrder);
    	queryBuilder.limitOfResultSet = filter.limitOfResultSet;
        return BM_SoqlUtils.performQuery(queryBuilder);
	}

}