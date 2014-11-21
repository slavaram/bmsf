trigger OpportunityProcessUpdate on Opportunity (before update, after update) {

	if (trigger.isBefore) {
		BMOpportunity bmOpportunity = new BMOpportunity();
		bmOpportunity.calculateDiscount(trigger.new);
		OpportunityMethods.setFieldValues(trigger.new);
	}

	if (trigger.isAfter) {
		List<sObject> toInsert = new List<sObject>();
		if (!OpportunityMethods.DONE) {
			OpportunityMethods.DONE = true;
			OpportunityExcecutor oppExcecutor = new OpportunityExcecutor();
			oppExcecutor.deleteNonActualActivitesBeforeUpdate(trigger.newMap, trigger.oldMap);

			for (Opportunity opp : trigger.new) {
				Opportunity oppOld = trigger.oldMap.get(opp.Id);
				if (opp.ActionIds__c != oppOld.ActionIds__c) {
					Set<Id> actionIds = OpportunityMethods.parceOpportunityActionIds(opp.ActionIds__c);
					Set<Id> actionIdsOld = OpportunityMethods.parceOpportunityActionIds(oppOld.ActionIds__c);
					actionIds.removeAll(actionIdsOld);
					for (Id actId : actionIds) {
						toInsert.add(new ApplicationsActivities__c(ActionID__c = actId, OpportunityId__c = opp.Id));							// SELF INVOCATION
					}
				}
			}
		}

		List<id> opportunityIds = new List<id>();
		for (Opportunity opp : trigger.new) {
			if (opp.StageName == 'Оплачено') opportunityIds.add(opp.Id);
		}
		List<Task> tasks = [SELECT Id, OwnerId, Status, Resolution__c
		                    FROM Task
		                    WHERE Subject = 'Консультирование. Создание заявки на мероприятие'
		                    AND Status = 'Новая'
		                    AND WhatId IN :opportunityIds];
		for (Task tas : tasks) {
			tas.OwnerId			= '005b0000000NiKS';
			tas.Status			= 'Завершено';
			tas.Resolution__c	= 'Автомат.Поступление платежа от клиента';
		}
		update tasks;

		List<ApplicationsActivities__c> activities = [SELECT Id, OpportunityId__c, ActionID__c, ActionID__r.Name, ActionID__r.ParentId__c, OpportunityId__r.StageName, OpportunityId__r.AccountID
		                                              FROM ApplicationsActivities__c
		                                              WHERE OpportunityId__c IN :trigger.newMap.keySet()
		                                              AND OpportunityId__r.StageName IN ('Условно оплачена', 'Оплачено', 'Частичная оплата')];
		update activities;																														// SELF INVOCATION
		for (ProductRoles__c par : ProductRoles__c.getAll().values()) {
		    OpportunityMethods.createAccountRoleForUpdate(activities, par.ProductName__c, par.RoleNumber__c);									// ?????
		}

		for (Opportunity oldOpp : trigger.old) {
			Opportunity newOpp = trigger.newMap.get(oldOpp.Id);
			if (oldOpp.StageName != 'Частичная оплата' && oldOpp.StageName != 'Оплачено' && newOpp.StageName == 'Частичная оплата') {
				toInsert.add(new StepPayment__c(OpportunityId__c = newOpp.Id,
												StepPayment__c = 5,
												DateUpdateStepPay__c = DateTime.now()));
			}
			if (oldOpp.StageName != 'Частичная оплата' && oldOpp.StageName != 'Оплачено' && newOpp.StageName == 'Оплачено') {
				toInsert.add(new StepPayment__c(OpportunityId__c = newOpp.Id,
												StepPayment__c = 5,
												DateUpdateStepPay__c = DateTime.now()));
				toInsert.add(new StepPayment__c(OpportunityId__c = newOpp.Id,
												StepPayment__c = 6,
												DateUpdateStepPay__c = DateTime.now()));
			}
			if (oldOpp.StageName == 'Частичная оплата' && newOpp.StageName == 'Оплачено') {
				toInsert.add(new StepPayment__c(OpportunityId__c = newOpp.Id,
												StepPayment__c = 6,
												DateUpdateStepPay__c = DateTime.now()));
			}
		}

	    List<Opportunity> opportunities	= new List<Opportunity>();
	    List<Id> productIds				= new List<Id>();
	    List<Id> opportunityIds2		= new List<Id>();
	    for (Opportunity newOpp : trigger.new) {
	      	Opportunity oldOpp = trigger.oldMap.get(newOpp.Id);
	        if (newOpp.ProductId__c != oldOpp.ProductId__c) {
	        	opportunityIds2.add(newOpp.Id);
	            if (newOpp.ProductId__c != null) {
	            	opportunities.add(newOpp);
	            	productIds.add(newOpp.ProductId__c);
	            }
	        }
	    }
	    delete [SELECT Id FROM OpportunityLineItem WHERE OpportunityId IN :opportunityIds2];
	    insert OpportunityMethods.createOpportunityLineItems(opportunities, productIds);														// SELF INVOCATION

	    if (!toInsert.isEmpty()) insert toInsert;																								// HERE HELL BEGINS
	}

}