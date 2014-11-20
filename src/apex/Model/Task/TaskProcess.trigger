trigger TaskProcess on Task (before insert,
							 before update) {

	if (trigger.isBefore) {
		for (Task tas : trigger.new) {
			if (tas.ActivityDate == null && tas.ActivityDateTime__c != null) tas.ActivityDate = tas.ActivityDateTime__c.date();
		}
	}

	if (trigger.isUpdate && trigger.isBefore) {
		for (Task tas: Trigger.new) {
			if (tas.WhatId != null) {
				if (tas.WhatId.getSObjectType().getDescribe().getName() == 'Case' && tas.Status == 'Завершено') {
					Case caseClose = new Case(Id = tas.WhatId, Status = 'Закрыто');
					update caseClose;
				}
			}
		}
	}

}