public class ApexUtils {

	private static final String ENCRYPT_KEY = 'lui0D7PX/YoN8Lm4OA1i6w=='; // DO NOT CHANGE! REFRESH USING Crypto.generateAesKey(128).

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
		if (dateValue == null) return '01 января 1000';
		Integer day = dateValue.day();
		Integer month = dateValue.month();
		Integer year = dateValue.year();
		result += (day < 10 ? '0' + String.valueOf(day) : String.valueOf(day));
		result += '.';
		result += (month < 10 ? '0' + String.valueOf(month) : String.valueOf(month));
		result += '.' + year;
		return result;
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

	public static String encript(String secret) {
		if (String.isBlank(secret)) return null;
		Blob key		= EncodingUtil.base64Decode(ENCRYPT_KEY);
		Blob blobSecret	= Blob.valueOf(secret);
		Blob encrypted	= Crypto.encrypt('AES128', key, key, blobSecret);
		return EncodingUtil.base64Encode(encrypted);
	}

	public static String decript(String encriptedSecret) {
		if (String.isBlank(encriptedSecret)) return null;
		Blob key		= EncodingUtil.base64Decode(ENCRYPT_KEY);
		Blob encripted	= EncodingUtil.base64Decode(encriptedSecret);
		Blob decrypted	= Crypto.decrypt('AES128', key, key, encripted);
		return decrypted.toString();
	}

	public static List<sObject> shuffle(List<sObject> toShuffle) {
		if (toShuffle == null || toShuffle.isEmpty()) return null;
		List<sObject> result	= new List<sObject>();
		List<sObject> temp		= new List<sObject>(toShuffle);
		for (Integer lim = temp.size(); lim > 0; lim--) {
			Integer index = Integer.valueOf(Math.floor(Math.random()*lim));
			result.add(temp.get(index));
			temp.remove(index);
		}
		return result;
	}

	public static List<Id> shuffle(List<Id> toShuffle) {
		if (toShuffle == null || toShuffle.isEmpty()) return null;
		List<Id> result	= new List<Id>();
		List<Id> temp	= new List<Id>(toShuffle);
		for (Integer lim = temp.size(); lim > 0; lim--) {
			Integer index = Integer.valueOf(Math.floor(Math.random()*lim));
			result.add(temp.get(index));
			temp.remove(index);
		}
		return result;
	}

	public static String getProfileKeyById(Id profileId) {
		if (profileId == null) return null;
		for (OrganizationProfiles__c profileKey : OrganizationProfiles__c.getAll().values()) {
			if (String.valueOf(profileId) == profileKey.Id__c) return profileKey.Name;
		}
		return null;
	}

	public static String getProfileIdByKey(String key) {
		if (key == null) return null;
		for (OrganizationProfiles__c profileKey : OrganizationProfiles__c.getAll().values()) {
			if (key == profileKey.Name) return profileKey.Id__c;
		}
		return null;
	}

}