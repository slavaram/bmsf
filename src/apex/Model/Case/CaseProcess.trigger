trigger CaseProcess on Case (before insert, after insert,
							 before update, after update) {

	if (Trigger.isBefore && Trigger.isInsert) {
		for (Case cas : trigger.new) {
			if (cas.CreatedBy__c != null && cas.CreatedBy__c  == 'Оператор Call Center') {
				if (cas.Question__c != null) {
						if (cas.Question__c != 'Другое') {
							cas.Subject = cas.Question__c + (cas.Qualification__c != null ? '. '+ cas.Qualification__c : '');
						} else {
							if (cas.Other__c != null) cas.Subject = cas.Other__c;
						}
				} else {
					if (cas.Reason != null) cas.Subject = cas.Reason;
				}
			}
		}
		UserGroupManager.allocateAmongOwnerGroupMembers(trigger.new);
	}

	if (Trigger.isAfter && Trigger.isInsert) {
		BOCase.AssignCase(trigger.newMap.KeySet());
		List<Task> toInsert = new List<Task>();
		for (Case cas: Trigger.new) {
			if ((cas.OwnerId == '005b0000000PAuN' || cas.OwnerId == '005b0000000v9gM' || cas.OwnerId == '005b0000000v0dm' || cas.OwnerId == '005b0000000w1dB')
					&& (cas.Origin == 'Телефонный звонок' || cas.Origin == 'Эл. почта')) {
				Task task = new Task();
				task.WhatId = cas.Id;
				task.Subject = 'Задача по входящему обращению';
				task.ActivityDate = Date.today();
				task.OwnerId = cas.OwnerId;
				toInsert.add(task);
			}
			if(cas.Subject == 'Заказ обратного звонка с сайта') {
				Task task = new Task();
				task.WhatId = cas.Id;
				task.Subject = 'Заказ обратного звонка';
				task.Priority = 'Высокий';
				task.ActivityDate = Date.today();
				task.OwnerId = cas.OwnerId;
				toInsert.add(task);   
			}
		}
		insert toInsert;
	}

	if (Trigger.isAfter && Trigger.isUpdate) {
		List<Task> toInsert = new List<Task>();
		for (Case casOld: Trigger.old) {
			for (Case casNew: Trigger.new) {
				if (casOld.OwnerId != casNew.OwnerId) {
					if ((casNew.OwnerId == '005b0000000PAuN' || casNew.OwnerId == '005b0000000v9gM' || casNew.OwnerId == '005b0000000v0dm' || casNew.OwnerId == '005b0000000w1dB')
							&& (casNew.Origin == 'Телефонный звонок' || casNew.Origin == 'Эл. почта')) {
						Task task = new Task();
						task.WhatId = casNew.Id;
						task.Subject = 'Задача по входящему обращению';
						task.ActivityDate = Date.today();
						task.OwnerId = casNew.OwnerId;
						toInsert.add(task);
					}
				}
			}
		}
		insert toInsert;
	}

}