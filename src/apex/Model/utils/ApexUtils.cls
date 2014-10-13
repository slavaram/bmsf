public class ApexUtils {

	public static Type getType(String typeName) {
		Type result;
		try {
			result = Type.forName(typeName);
		} catch (Exception e) {
			result = null;
			System.debug(LoggingLevel.ERROR, 'Exception occurred in ApexUtils.getType: ' + e.getMessage());
		}
		return result;
	}

	public static List<Object> createEmptyListByTypeName(String typeName) {
		String fullNameOfListType = 'List<' + typeName + '>';
		Type listType = BM_ApexTypeUtils.getType(fullNameOfListType);
		List<Object> resultList = null;
		if (listType != null) {
			resultList = (List<Object>) listType.newInstance();
		}
		return resultList;
	}

	public static String getMonthNameRus(Integer month, Boolean isNominative) {
		if (month == null || isNominative == null) return null;
		if (month < 1 || month > 12) return null;
		if (month == 1) {
			return (isNominative ? 'январь' : 'января');
		} else if (month == 2) {
			return (isNominative ? 'февраль' : 'февраля');
		} else if (month == 3) {
			return (isNominative ? 'март' : 'марта');
		} else if (month == 4) {
			return (isNominative ? 'апрель' : 'апреля');
		} else if (month == 5) {
			return (isNominative ? 'май' : 'мая');
		} else if (month == 6) {
			return (isNominative ? 'июнь' : 'июня');
		} else if (month == 7) {
			return (isNominative ? 'июль' : 'июля');
		} else if (month == 8) {
			return (isNominative ? 'август' : 'августа');
		} else if (month == 9) {
			return (isNominative ? 'сентябрь' : 'сентября');
		} else if (month == 10) {
			return (isNominative ? 'октябрь' : 'октября');
		} else if (month == 11) {
			return (isNominative ? 'ноябрь' : 'ноября');
		} else {
			return (isNominative ? 'декабрь' : 'декабря');
		}
	}

	public static Boolean isWeekend(DateTime dateValue) {
		return isWeekend(Date.valueOf(dateValue));
	}

	public static Boolean isWeekend(Date dateValue) {
		if (dateValue == null) return null;
		for (DayTypes__c day : DayTypes__c.getAll().values()) {
			if (day.Day__c == dateValue) {
				return day.IsWeekend__c;
			}
		}
		// 18 may 2014 is saturday
		Date saturday = Date.valueOf('2014-05-17 00:00:00');
		Integer daysBetween = saturday.daysBetween(dateValue);
		if (Math.mod(daysBetween, 7) == 0 || Math.mod(daysBetween, 7) == 1) {
			return true;
		} else {
			return false;
		}
	}

	public static String dateToString(Date dateValue) {
		String result = '';
		if (dateValue == null) return '00.00.0000';
		Integer day = dateValue.day();
		Integer month = dateValue.month();
		Integer year = dateValue.year();
		result += (day < 10 ? '0' + String.valueOf(day) : String.valueOf(day));
		result += '.';
		result += (month < 10 ? '0' + String.valueOf(month) : String.valueOf(month));
		result += '.' + year;
		return result;
	}

	public static List<SelectOption> getObjectPickListFieldValues(SObject obj, String field) {
		List<SelectOption> options = new List<SelectOption>();
		Schema.sObjectType objectType = obj.getSObjectType();
		Schema.DescribeSObjectResult objectDescribe = objectType.getDescribe();
		Map<String, Schema.SObjectField> fieldMap = objectDescribe.fields.getMap();
		List<Schema.PicklistEntry> values = fieldMap.get(field).getDescribe().getPickListValues();
		for (Schema.PicklistEntry a : values) { 
			options.add(new SelectOption(a.getLabel(), a.getValue())); 
		}
		return options;
	}

	public static Boolean isEqualStrings(String str1, String str2) {
		if (str1 == null) {
			if (str2 == null) {
				return true;
			} else {
				return false;
			}
		} else {
			if (str2 == null) {
				return false;
			} else {
				if (str1 == str2) {
					return true;
				} else {
					return false;
				}
			}
		}
	}

	public static Boolean isFirstDateEarlier(String firstDate, String secondDate) {
		if (firstDate == null || secondDate == null) return null;
		Pattern datePattern = Pattern.compile('[\\d][\\d][.][\\d][\\d][.][\\d][\\d][\\d][\\d]');
		Matcher date1Match = datePattern.matcher(firstDate);
		Matcher date2Match = datePattern.matcher(secondDate);
		if (!date1Match.matches() || !date2Match.matches()) {
			return null;
		}
		Integer day1 = Integer.valueOf(firstDate.substringBefore('.'));
		Integer month1 = Integer.valueOf(firstDate.substringAfter('.').substringBefore('.'));
		Integer year1 = Integer.valueOf(firstDate.substringAfterLast('.'));
		Integer day2 = Integer.valueOf(secondDate.substringBefore('.'));
		Integer month2 = Integer.valueOf(secondDate.substringAfter('.').substringBefore('.'));
		Integer year2 = Integer.valueOf(secondDate.substringAfterLast('.'));
		if (day1 < 0 || day1 > 31 ||
			day2 < 0 || day2 > 31 ||
			month1 < 0 || month1 > 12 ||
			month2 < 0 || month2 > 12 ||
			year1 < 1500 || year1 > 2500 ||
			year2 < 1500 || year2 > 2500) {
			return null;
		}
		if (year1 > year2) {
			return false;
		} else if (year1 < year2) {
			return true;
		} else {
			if (month1 > month2) {
				return false;
			} else if (month1 < month2) {
				return true;
			} else {
				if (day1 >= day2) {
					return false;
				} else {
					return true;
				}
			}
		}
	}
	
	public static String getLabel(List<SelectOption> options, String value) {
		if (options == null || value == null || options.size() == 0) return null;
		for (SelectOption option : options) {
			if (option.getValue() == value) return option.getLabel();
		}
		return null;
	}

}