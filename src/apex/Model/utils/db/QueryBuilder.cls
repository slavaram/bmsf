public class QueryBuilder {

	public String	mSelectedFields		{get; set;}
	public String	mObjectName			{get; set;}
	public String	mConditions			{get; set;}
	public String	mGroupByBlockValue	{get; set;}
	public String	mOrderByBlockValue	{get; private set;}
	public String	mHavingBlockValue	{get; set;}
	public Integer	mLimitOfResultSet	{get; set;}
	public Integer	mOffsetOfResult		{get; set;}

	public QueryBuilder(String selectedFields, String objectName) {
		mSelectedFields = selectedFields;
		mObjectName = objectName;
	}

	public QueryBuilder(String selectedFields, String objectName, String conditions) {
		mSelectedFields = selectedFields;
		mObjectName = objectName;
		mConditions = conditions;
	}

	public void setOrderByBlock(String fieldsForSorting, DbUtils.SortingOrder sortingOrder) {
		if (String.isBlank(fieldsForSorting)) {
			orderByBlockValue = null;
			return;
		}
		orderByBlockValue = fieldsForSorting;
		if (sortingOrder != null) {
			if (sortingOrder == DbUtils.SortingOrder.Ascending) {
				orderByBlockValue += ' ASC';
			} else if (sortingOrder == DbUtils.SortingOrder.Descending) {
				orderByBlockValue += ' DESC';
			}
		}
	}

	public String buildQuery() {
		if (String.isBlank(mSelectedFields) || String.isBlank(mObjectName)) {
			return null;
		}
		String result = 'SELECT ' + mSelectedFields + ' FROM ' + mObjectName;
		if (String.isNotBlank(mCondition)) {
			result += ' WHERE ' + mCondition;
		}
		if (String.isNotBlank(mGroupByBlockValue)) {
			result += ' GROUP BY ' + mGroupByBlockValue;
		} else if (String.isNotBlank(mOrderByBlockValue)) {
			result += ' GROUP BY ROLLUP (' + mOrderByBlockValue + ')';
		}
		if (String.isNotBlank(mHavingBlockValue)) {
			result += ' HAVING ' + mHavingBlockValue;
		}
		if (String.isNotBlank(mOrderByBlockValue)) {
			result += ' ORDER BY ' + mOrderByBlockValue;
		}
		if (this.mLimitOfResultSet >= 0) {
			result += ' LIMIT ' + mLimitOfResultSet;
		}
		if (this.mOffsetOfResult >= 0) {
			result += ' OFFSET ' + mOffsetOfResult;
		}        
		return result;
	}

}