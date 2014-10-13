public class DbUtils {

	public static final String[] SPECIAL_CHARS_FOR_LIKE_OPERATOR = new String[] {'%', '_', '\''};

	private static final String DB_DATETIME_FORMAT = 'yyyy-MM-dd\'T\'HH:mm:ss\'Z\'';
	private static final String DB_DATE_FORMAT = 'yyyy-MM-dd';

	public enum LogicOperator {AND_Operator, OR_Operator}
	public enum SortingOrder {Ascending, Descending}
    public enum DmlOperation {Deleting, Inserting, Updating, Undeleting, Upserting}

	public static List<sObject> performQuery(String query) {
		if (String.isBlank(query)) return null;
		List<sObject> result;
		try {
			result = Database.query(query);
		} catch (System.QueryException e) {
			System.debug(Logginglevel.ERROR, e);
			result = null;
		}
		return result;
	}

	public static List<sObject> performQuery(QueryBuilder queryBuilder) {       
		if (queryBuilder == null) return null;
		return performQuery(queryBuilder.buildQuery());
	}

	public static sObject performSingleResultQuery(String query) {
		sObject resultObject = null;
		List<sObject> listOfsObjects = performQuery(query);
		if (listOfsObjects != null && listOfsObjects.size() > 0) resultObject = listOfsObjects[0];
		return resultObject;
	}

	public static sObject performSingleResultQuery(QueryBuilder queryBuilder) {
		if (queryBuilder == null) return null;
		return performSingleResultQuery(queryBuilder.buildQuery());
	}

	public static Integer performCountQuery(String countQuery) {
		if (String.isBlank(countQuery)) return null;
		Integer result;
		try {
			result = Database.countQuery(countQuery);
		} catch (System.QueryException e) {
			System.debug(Logginglevel.ERROR, e);
			result = null;
		}
		return result;
	}

	public static Integer performCountQuery(QueryBuilder queryBuilder) {
		if (queryBuilder == null) return null;
		return performCountQuery(queryBuilder.buildQuery());
	}

	public static Database.QueryLocator createQueryLocator(String queryString) {
		if (String.isBlank(queryString)) return null;
		Database.QueryLocator queryLocator;
		try {
			queryLocator = Database.getQueryLocator(queryString);
		} catch (System.QueryException e) {
			System.debug(Logginglevel.ERROR, e);
			queryLocator = null;
		}
		return queryLocator;
	}

	public static String escapeSpecialCharsForLikeOperator(String sourceString) {
		if (String.isBlank(sourceString)) return sourceString;
		String result = sourceString;
		for (String specialChar : SPECIAL_CHARS_FOR_LIKE_OPERATOR) {
			result = result.replace(specialChar, '\\' + specialChar);
		}
		return resultString;
	}

	public static String escapeSpecialCharsForSimpleCondition(String sourceString) {
		if (String.isBlank(sourceString)) return sourceString;
		return String.escapeSingleQuotes(sourceString);
	}

	public static String joinConditions(List<String> listOfConditions, LogicOperator logicOperator) {
		if (listOfConditions == null || logicOperator == null) return null;
		Set<String> setOfConditions = new Set<String>(listOfConditions);
		setOfConditions.remove(null);
		setOfConditions.remove('');
		String fullCondition = null;
		if (setOfConditions.size() > 0) {
			String separatorForConditions = ') ' + getSoqlRepresentation(logicOperator) + ' (';
			fullCondition = String.join(new List<String>(setOfConditions), separatorForConditions);
			if (String.isNotBlank(fullCondition)) {
				fullCondition = '(' + fullCondition + ')';
			}
		}
		return fullCondition;
	}

	public static String joinStringsForINSection(List<String> listOfStrings) {
		if (listOfStrings == null) return null;
		Set<String> setOfStrings = new Set<String>(listOfStrings);
		setOfStrings.remove(null);
		setOfStrings.remove('');
		String result = null;
		if (setOfStrings.size() > 0) {
			result = String.join(new List<String>(setOfStrings), '\',\'');
			if (String.isNotBlank(resultString)) {
				result = '(\'' + result + '\')';
			}
		}
		return result;
	}

	public static String formatDateTime(Date sourceDate) {
		if (sourceDate == null) return null;
		Datetime sourceDateTime = DateTime.newInstanceGmt(sourceDate.year(), sourceDate.month(), sourceDate.day(), 0, 0, 0);
		return formatDateTime(sourceDateTime);
	}

	public static String formatDateTime(DateTime sourceDateTime) {
		if (sourceDateTime == null) return null;
		return sourceDateTime.formatGmt(DB_DATETIME_FORMAT);
	}

	public static String formatDate(Date sourceDate) {
		if (sourceDate == null) return null;
		Datetime sourceDateTime = DateTime.newInstance(sourceDate.year(), sourceDate.month(), sourceDate.day(), 0, 0, 0);
		return formatDate(sourceDateTime);
	}

	public static String formatDate(DateTime sourceDateTime) {
		if (sourceDateTime == null) return null;
		return sourceDateTime.format(DB_DATE_FORMAT);
	}

	private static String getSoqlRepresentation(LogicOperator logicOperator) {
		if (logicOperator == DbUtils.LogicOperator.AND_Operator) {
			return 'AND';
		} else if (logicOperator == DbUtils.LogicOperator.OR_Operator) {
			return 'OR';
		} else {
			throw new BM_Exception('DbUtils.getSoqlRepresentation: unknown logic operator: ' + logicOperator);
		}
	}

	public static Boolean tryPerformDmlOperation(DmlOperation dmlOperation, sObject objectForOperation) {
		if (dmlOperation == null || objectForOperation == null) return false;
		List<sObject> sObjects = (List<sObject>) ApexUtils.createEmptyListByTypeName(String.valueOf(objectForOperation.getSObjectType()));
		sObjects.add(objectForOperation);
		return tryPerformDmlOperation(dmlOperation, sObjects);
	}

	public static Boolean tryPerformDmlOperation(DmlOperation dmlOperation, List<sObject> objects) {
		if (dmlOperation == null || objects == null) return false;
		Boolean isOperationSuccessful = true;
		try {
			callDmlOperation(dmlOperation, objects);
		} catch (System.Exception e) {
			System.debug(LoggingLevel.ERROR, e);
			isOperationSuccessful = false;
		}
		return isOperationSuccessful;
	}

	private static void callDmlOperation(DmlOperation dmlOperation, List<sObject> objects) {
		if (dmlOperation == DbUtils.DmlOperation.Updating) {
			update objects;
		} else if (dmlOperation == DbUtils.DmlOperation.Inserting) {
			insert objects;
		} else if (dmlOperation == DbUtils.DmlOperation.Deleting) {
			delete objects;
		} else if (dmlOperation == DbUtils.DmlOperation.Upserting) {
			upsert objects;
		} else if (dmlOperation == DbUtils.DmlOperation.Undeleting) {
			undelete objects;
		} else {
			throw new NullPointerException();
		}
	}

}