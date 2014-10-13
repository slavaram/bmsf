trigger UserProcess on User (before insert, after insert,
							 before update,
							 before delete) {

	if (trigger.isAfter && trigger.isInsert) {
		List<Id> userIds = new List<Id>();
		for (User use : trigger.new) {
			try {
				if (use.ProfileId != null && use.ProfileId == '00eb0000000QbbzAAC') {
					userIds.add(use.Id);
				}
			} catch (Exception ex) {}
		}
		UserMethod.createAllocations(userIds);
	}

	if (trigger.isAfter && trigger.isInsert) {
		Set<Id> newGroupMembers = new Set<Id>();
		for (User use : trigger.new) {
			if (use.Profile.Name == 'Менеджер' && use.IsActive == true) {
				newGroupMembers.add(use.Id);
			}
		}
		UserGroupManager.addGroupMembersFuture('AllManagersGroup', newGroupMembers);
	}

	if (trigger.isUpdate) {
		List<Id> userIdsToCreate = new List<Id>();
		List<Id> userIdsToDelete = new List<Id>();
		for (User newUser : trigger.new) {
			for (User oldUser : trigger.old) {
				if (newUser.Id == oldUser.Id) {
					if ((newUser.ProfileId == '00eb0000000Qbbz') && (oldUser.ProfileId != '00eb0000000Qbbz') && (newUser.isActive = true)) {
						userIdsToCreate.add(newUser.Id);
					}
					if ((newUser.IsActive == true && oldUser.IsActive == false)) {
						userIdsToCreate.add(newUser.Id);
					}
					if ((newUser.IsActive == false && oldUser.IsActive == true) || ((newUser.ProfileId != '00eb0000000Qbbz') && (oldUser.ProfileId == '00eb0000000Qbbz'))) {
						userIdsToDelete.add(newUser.Id);
					}
					break;
				}
			}
		}
		if (userIdsToCreate.size() > 0) UserMethod.createAllocations(userIdsToCreate);
	 	if (userIdsToDelete.size() > 0) UserMethod.deleteAllocations(userIdsToDelete);
	}

	if (trigger.isBefore && trigger.isUpdate) {
		Id managerProfileId = [SELECT Id FROM Profile WHERE Name = 'Менеджер'].get(0).Id;
		Set<Id> addGroupMembers = new Set<Id>();
		Set<Id> removeGroupMembers = new Set<Id>();
		for (User newUser : trigger.new) {
			for (User oldUser : trigger.old) {
				if (newUser.Id == oldUser.Id) {
					if ((oldUser.ProfileId != managerProfileId || oldUser.IsActive == false) && newUser.ProfileId == managerProfileId && newUser.IsActive == true) {
						addGroupMembers.add(newUser.Id);
					}
					if (oldUser.ProfileId == managerProfileId && oldUser.IsActive == true && (newUser.ProfileId != managerProfileId || newUser.IsActive == false)) {
						removeGroupMembers.add(newUser.Id);
					}
					break;
				}
			}
		}
		UserGroupManager.addGroupMembersFuture('AllManagersGroup', addGroupMembers);
		UserGroupManager.removeGroupMembersFuture('AllManagersGroup', removeGroupMembers);
	}

}