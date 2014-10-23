public class BM_UserUtils {

	public static Boolean isClientOwnerRole(String userRoleName) {
		Set<String> roleNamesOfClientOwners = new Set<String>(BM_Settings.getRoleNamesOfClientOwners());
		return roleNamesOfClientOwners.contains(userRoleName);
	}

}