public class BM_UserDAO {

	private static String BASIC_FIELDS	= 'Id, Name, UserRoleId, UserRole.Name, isSuperGroupForCampaign__c';
    private static String OBJECT_NAME	= 'User';

	public class Filter {
		public List<String> userRoleNames	{get; set;}
		public Boolean ignoreInactiveUsers	{get; set;}
	}

	private static String createConditionByFilter(Filter filter) {
    	if (filter == null) return null;
    	List<String> listOfConditions = new List<String>();
    	String stringOfUserRoleNames = BM_SoqlUtils.joinStringsForINSection(filter.userRoleNames);
    	if (String.isNotBlank(stringOfUserRoleNames)) listOfConditions.add('UserRole.Name IN (' + stringOfUserRoleNames + ')');
    	if (filter.ignoreInactiveUsers != null && filter.ignoreInactiveUsers) listOfConditions.add('IsActive = true');
    	return BM_SoqlUtils.joinConditions(listOfConditions, BM_SoqlUtils.LogicOperator.AND_Operator);
	}

	public static User getUsersById(String userId) {
        if (String.isBlank(userId))	return null;
        BM_SoqlQueryBuilder queryBuilder = new BM_SoqlQueryBuilder(BASIC_FIELDS, OBJECT_NAME);
    	queryBuilder.condition = 'Id = \'' + userId + '\'';
        return (User) BM_SoqlUtils.performSingleResultQuery(queryBuilder);
	}
	
	public static User[] getUsersByFilter(Filter filter) {
		String condition = createConditionByFilter(filter);
        if (String.isBlank(condition)) return null;
        BM_SoqlQueryBuilder queryBuilder = new BM_SoqlQueryBuilder(BASIC_FIELDS, OBJECT_NAME);
    	queryBuilder.condition = condition;
    	queryBuilder.setOrderByBlock('Name', BM_SoqlUtils.SortingOrder.Ascending);
        return BM_SoqlUtils.performQuery(queryBuilder);
	}

}