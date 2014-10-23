public class BM_TaskDAO {

	private static final String BASIC_FIELDS	= 'Id, Subject, Status, ActivityDate, OwnerId, WhoId, WhatId';
    public static String OBJECT_NAME			= 'Task';

	public class Filter {
		public Date activityDate		{get; set;}
		public String[] taskStatuses	{get; set;}
		public String[] ownersIds		{get; set;}
	}

	public static Task[] getTasksByFilter(Filter filter) {
		String condition = createConditionByFilter(filter);
        if (String.isBlank(condition)) return null;
        BM_SoqlQueryBuilder queryBuilder = new BM_SoqlQueryBuilder(BASIC_FIELDS, OBJECT_NAME);
    	queryBuilder.condition = condition;
        return BM_SoqlUtils.performQuery(queryBuilder);
	}

	public static Integer getTasksCountByFilter(Filter filter) {
		String condition = createConditionByFilter(filter);
        if (String.isBlank(condition)) return null;
        BM_SoqlQueryBuilder queryBuilder = new BM_SoqlQueryBuilder('count()', OBJECT_NAME);
    	queryBuilder.condition = condition;
        return BM_SoqlUtils.performCountQuery(queryBuilder);
	}

	private static String createConditionByFilter(Filter filter) {
    	if (filter == null) return null;
    	List<String> listOfConditions = new List<String>();
    	if (filter.activityDate != null) listOfConditions.add('ActivityDate = ' + BM_SoqlUtils.formatDate(filter.activityDate));
    	String stringOfTaskStatuses = BM_SoqlUtils.joinStringsForINSection(filter.taskStatuses);
    	if (String.isNotBlank(stringOfTaskStatuses)) listOfConditions.add('Status IN (' + stringOfTaskStatuses + ')');
    	String stringOfOwnersIds = BM_SoqlUtils.joinStringsForINSection(filter.ownersIds);
    	if (String.isNotBlank(stringOfOwnersIds)) listOfConditions.add('OwnerId IN (' + stringOfOwnersIds + ')');
    	return BM_SoqlUtils.joinConditions(listOfConditions, BM_SoqlUtils.LogicOperator.AND_Operator);
	}

}