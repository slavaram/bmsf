public class SoqlUtils {

	private static final String DB_DATETIME_FORMAT = 'yyyy-MM-dd\'T\'HH:mm:ss\'Z\'';
	private static final String DB_DATE_FORMAT = 'yyyy-MM-dd';

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

}