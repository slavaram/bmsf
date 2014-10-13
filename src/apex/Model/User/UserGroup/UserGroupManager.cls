public class UserGroupManager {

	private static List<UserGroup> userGroups {get; private set;}
	private static Boolean isInitialised = false;
	private static Integer userGroupMembersIndex;

	private static final String START_INDEX = '00000000';

	static {
		userGroups = new List<UserGroup>();
	}

	public static List<sObject> allocateAmongOwnerGroupMembers(sObject objectEntity) {
		if (objectEntity == null) {
			return new List<sObject>();
		}
		return allocateAmongOwnerGroupMembers(new List<sObject> {objectEntity});
	}

	public static List<sObject> allocateAmongOwnerGroupMembers(List<sObject> objectEntities) {
		if (!isInitialised) initUserGroups();
		if (objectEntities == null || objectEntities.size() == 0) {
			return new List<sObject>();
		}
		List<sObject> objectAndOwner = new List<sObject>();
		UserGroupAllocations allocations = new UserGroupAllocations();
		for (UserGroup userGroup : userGroups) {
			List<sObject> objectsBundle = new List<sObject>();
			for (sObject objectEntity : objectEntities) {
				if (userGroup.isOwner(objectEntity)) {
					objectsBundle.add(objectEntity);
				}
			}
			objectAndOwner.addAll(allocations.allocate(objectsBundle, userGroup));
		}
		return objectAndOwner;
	}

	private static void initUserGroups() {
		Map<String, Set<Id>> groupMembers = new Map<String, Set<Id>>();
		for (UserGroupMembers__c groupMember : UserGroupMembers__c.getAll().values()) {
			try {
				Set<Id> thisMembers = groupMembers.get(groupMember.GroupName__c);
				if (thisMembers == null) {
					Set<Id> newMembers = new Set<Id>();
					newMembers.add(Id.valueOf(groupMember.MemberId__c));
					groupMembers.put(groupMember.GroupName__c, newMembers);
				} else {
					thisMembers.add(Id.valueOf(groupMember.MemberId__c));
					groupMembers.put(groupMember.GroupName__c, thisMembers);
				}
			} catch (Exception ex) {} // Throws when setting MemberId__c is not Id
		}
		for (String groupName : groupMembers.keySet()) {
			userGroups.add(new UserGroup(groupName, groupMembers.get(groupName)));
		}
		isInitialised = true;
	}

	public static void addGroupMembers(String groupName, Set<Id> memberIds) {
		if (groupName == null || memberIds == null || memberIds.size() == 0) return;
		SavePoint save = Database.setSavepoint();
		try {
			if (userGroupMembersIndex == null) initUserGroupMembersIndex();
			List<UserGroupMembers__c> toInsert = new List<UserGroupMembers__c>();
			for (Id memberId : memberIds) {
				toInsert.add(new UserGroupMembers__c(Name = indexAsString(++userGroupMembersIndex), GroupName__c = groupName, MemberId__c = memberId));
			}
			insert toInsert;
			setUserGroupMembersIndex(userGroupMembersIndex);
		} catch (Exception ex) {
			Database.rollback(save);
			System.debug(LoggingLevel.ERROR, ex.getMessage());
		}
	}

	public static void removeGroupMembers(String groupName, Set<Id> memberIds) {
		if (groupName == null || memberIds == null || memberIds.size() == 0) return;
		try {
			List<UserGroupMembers__c> toDelete = new List<UserGroupMembers__c>();
			for (UserGroupMembers__c member : UserGroupMembers__c.getAll().values()) {
				if (member.GroupName__c == groupName && memberIds.contains(Id.valueOf(member.MemberId__c))) toDelete.add(member);
			}
			delete toDelete;
		} catch (Exception ex) {
			System.debug(LoggingLevel.ERROR, ex.getMessage());
		}
	}

	@future
	public static void addGroupMembersFuture(String groupName, Set<Id> memberIds) {
		if (groupName == null || memberIds == null || memberIds.size() == 0) return;
		SavePoint save = Database.setSavepoint();
		try {
			if (userGroupMembersIndex == null) initUserGroupMembersIndex();
			List<UserGroupMembers__c> toInsert = new List<UserGroupMembers__c>();
			for (Id memberId : memberIds) {
				toInsert.add(new UserGroupMembers__c(Name = indexAsString(++userGroupMembersIndex), GroupName__c = groupName, MemberId__c = memberId));
			}
			insert toInsert;
			setUserGroupMembersIndex(userGroupMembersIndex);
		} catch (Exception ex) {
			Database.rollback(save);
			System.debug(LoggingLevel.ERROR, ex.getMessage());
		}
	}

	@future
	public static void removeGroupMembersFuture(String groupName, Set<Id> memberIds) {
		if (groupName == null || memberIds == null || memberIds.size() == 0) return;
		try {
			List<UserGroupMembers__c> toDelete = new List<UserGroupMembers__c>();
			for (UserGroupMembers__c member : UserGroupMembers__c.getAll().values()) {
				if (member.GroupName__c == groupName && memberIds.contains(Id.valueOf(member.MemberId__c))) toDelete.add(member);
			}
			delete toDelete;
		} catch (Exception ex) {
			System.debug(LoggingLevel.ERROR, ex.getMessage());
		}
	}

	private static void initUserGroupMembersIndex() {
		UserGroupMembers__c member = UserGroupMembers__c.getInstance(START_INDEX);
		userGroupMembersIndex = Integer.valueOf(member.MemberId__c);
	}

	private static void setUserGroupMembersIndex(Integer index) {
		UserGroupMembers__c member = UserGroupMembers__c.getInstance(START_INDEX);
		member.MemberId__c = String.valueOf(index);
		update member;
	}

	private static String indexAsString(Integer index) {
		String stringIndex = '0000000000' + String.valueOf(index);
		return stringIndex.substring(stringIndex.length() - 8, stringIndex.length());
	}

}