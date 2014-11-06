trigger TaskProcess on Task (before insert,
							 before update) {

	try {
		TaskMethods.setWhoId(trigger.new);
	} catch (Exception ex) {
		System.debug(LoggingLevel.ERROR, ex.getMessage());
	}

	if (trigger.isBefore) {
		for (Task tas : trigger.new) {
			if (tas.ActivityDate == null && tas.ActivityDateTime__c != null) tas.ActivityDate = (Date) tas.ActivityDateTime__c;
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