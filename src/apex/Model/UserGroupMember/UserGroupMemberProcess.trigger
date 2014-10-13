trigger UserGroupMemberProcess on UserGroupMember__c (after insert,
													  after delete) {

	Set<Id> toInsert = new Set<Id>();
	Set<Id> toDelete = new Set<Id>();
	List<UserGroupMember__c> members = new List<UserGroupMember__c>();
	if (trigger.isInsert) members = trigger.new;
	if (trigger.isDelete) members = trigger.old;
	for (UserGroupMember__c member : members) {
		System.debug(member.UserGroup__r.Name);
		if (member.UserGroup__c == 'a0R11000002lCrEEAU' || member.UserGroup__c == 'a0Rb0000005db32EAA') {
			if (trigger.isInsert) {
				toInsert.add(member.User__c);
			}
			if (trigger.isDelete) {
				toDelete.add(member.User__c);
			}
		}
	}
	UserGroupManager.addGroupMembers('PossibleAccountOwners', toInsert);
	UserGroupManager.removeGroupMembers('PossibleAccountOwners', toDelete);

}