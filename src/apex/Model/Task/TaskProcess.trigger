trigger TaskProcess on Task (before insert,
							 before update) {

	for (Task task: Trigger.new) {
		if (task.WhatId != null) {
			if (task.WhatId.getSObjectType().getDescribe().getName() == 'Case' && task.Status == 'Завершено') {
				Case caseClose = new Case(Id = task.WhatId);
				caseClose.Status = 'Закрыто';
				update caseClose;
			}
		}
	}
	
	if (trigger.isUpdate) {
		BOTask.setWorkTime(trigger.new, trigger.old);
	}

	try {
		new BOTask().setDate(trigger.new);
		new BOTask().setWhoId(trigger.new);
	} catch (Exception ex) {
		System.debug(ex.getMessage());
	}

}