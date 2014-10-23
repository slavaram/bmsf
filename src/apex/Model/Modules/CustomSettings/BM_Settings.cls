public class BM_Settings {

	private static final Boolean DEFAULT_ALLOW_MANAGE_CLIENT_OF_ANOTHER_OWNER = false;
	private static final Integer DEFAULT_MAX_NUMBER_OF_ACTIVE_TASKS_PER_DAY = 50;
	
	private static final String SEPARATOR_OF_ROLES = ',';
	
	public static final String ROLES_OF_CLIENT_OWNERS = 'ROLES_OF_CLIENT_OWNERS';
	public static final String MAX_NUMBER_OF_ACTIVE_TASKS_PER_DAY = 'MAX_NUMBER_OF_ACTIVE_TASKS_PER_DAY';
	public static final String UNKNOWN_CLIENT_OWNER_ID = 'UNKNOWN_CLIENT_OWNER_ID';
	public static final String ALLOW_MANAGE_CLIENT_OF_ANOTHER_OWNER = 'ALLOW_MANAGE_CLIENT_OF_ANOTHER_OWNER';

    private static String getStringValueByName(String settingName) {
        try {
            BM_Settings__c setting = BM_Settings__c.getValues(settingName);
            if (setting != null) return setting.Value__c;
        } catch (Exception ex) {
            System.debug(LoggingLevel.WARN, ex);
        }
        return null;
    }

    private static Integer getIntegerValueByName(String settingName) {
        try {
            String settingValue = getStringValueByName(settingName);
            return Integer.valueOf(settingValue);
        } catch (Exception ex) {
            System.debug(LoggingLevel.WARN, ex);
        }
        return null;
    }

    private static Boolean getBooleanValueByName(String settingName) {
        try {
            String settingValue = getStringValueByName(settingName);
            return Boolean.valueOf(settingValue);
        } catch (Exception ex) {
            System.debug(LoggingLevel.WARN, ex);
        }
        return null;
    }

	public static String[] getRoleNamesOfClientOwners() {
		List<String> roleNamesOfClientOwners = new List<String>();
        String valueFromSetting = getStringValueByName(ROLES_OF_CLIENT_OWNERS);
        if (!String.isBlank(valueFromSetting)) {
            String[] settingParts = valueFromSetting.split(SEPARATOR_OF_ROLES);
            for (String settingPart : settingParts) {
            	settingPart = settingPart.trim();
            	if (String.isNotBlank(settingPart)) roleNamesOfClientOwners.add(settingPart);
            }
        }
        return roleNamesOfClientOwners;
	}

	public static Integer getMaxNumberOfActiveTasksPerDay() {
		Integer maxNumberOfActiveTasks = getIntegerValueByName(MAX_NUMBER_OF_ACTIVE_TASKS_PER_DAY);
		return (maxNumberOfActiveTasks != null ? maxNumberOfActiveTasks : DEFAULT_MAX_NUMBER_OF_ACTIVE_TASKS_PER_DAY); 
	}

	public static String getUnknownClientOwnerId() {
		return getStringValueByName(UNKNOWN_CLIENT_OWNER_ID);
	}

	public static Boolean userCanManageClientOfAnotherOwner() {
		Boolean userCanManageClientOfAnotherOwner = getBooleanValueByName(ALLOW_MANAGE_CLIENT_OF_ANOTHER_OWNER);
		return (userCanManageClientOfAnotherOwner != null ? userCanManageClientOfAnotherOwner : DEFAULT_ALLOW_MANAGE_CLIENT_OF_ANOTHER_OWNER);
	}

}