public with sharing class OppOwnerAutoChanger implements Schedulable {

	private static final String JOB_NAME = 'OppOwnerAutoChanger.cls';
	private static final String CRON_EXP = '0 ' + System.now().addMinutes(1).minute() + ' * ? * * *';

	public static Boolean run() {
		SavePoint save = Database.setSavepoint();
		try {
			String jobId = System.schedule(OppOwnerAutoChanger.JOB_NAME,
										   OppOwnerAutoChanger.CRON_EXP,
										   new OppOwnerAutoChanger());
			CacheManager.cache(SchedulableManager.JOB_IDS_MAP, new Map<String, String> {OppOwnerAutoChanger.JOB_NAME => jobId});
			return true;
		} catch (Exception ex) {
			Database.rollback(save);
			System.debug(LoggingLevel.ERROR, '[OppOwnerAutoChanger] Unable to run apex job.');
			return false;
		}
	}

	public static Boolean abort() {
		SavePoint save = Database.setSavepoint();
		try {
			System.abortJob(CacheManager.getMap(SchedulableManager.JOB_IDS_MAP).get(OppOwnerAutoChanger.JOB_NAME));
			CacheManager.release(SchedulableManager.JOB_IDS_MAP, new Set<String> {OppOwnerAutoChanger.JOB_NAME});
			return true;
		} catch (Exception ex) {
			Database.rollback(save);
			System.debug(LoggingLevel.ERROR, '[OppOwnerAutoChanger] Unable to abort apex job.');
			return false;
		}
	}

	private void runNextJob() {
		SavePoint save = Database.setSavepoint();
		try {
			System.abortJob(CacheManager.getMap(SchedulableManager.JOB_IDS_MAP).get(OppOwnerAutoChanger.JOB_NAME));
			CacheManager.release(SchedulableManager.JOB_IDS_MAP, new Set<String> {OppOwnerAutoChanger.JOB_NAME});
			String jobId = System.schedule(OppOwnerAutoChanger.JOB_NAME,
										   '0 ' + System.now().addMinutes(10).minute() + ' * ? * * *',
										   new OppOwnerAutoChanger());
			CacheManager.cache(SchedulableManager.JOB_IDS_MAP, new Map<String, String> {OppOwnerAutoChanger.JOB_NAME => jobId});
		} catch (Exception ex) {
			Database.rollback(save);
			System.debug(LoggingLevel.ERROR, '[Schedulable_MGCardsManager] Unable to rerun cercled apex job.');
		}
	}

	public void execute(SchedulableContext sc) {
		String adminUserId = '';
		String descr = '';
		List<User> qAdminUsers = [SELECT Id FROM User WHERE Name = 'Администратор'];
		if(!qAdminUsers.isEmpty())	{
			adminUserId = qAdminUsers[0].Id;
		}
		DateTime now = DateTime.now();
		DateTime LastWeek = now.addDays(-6);
		
descr += 'now = ' + now + '\nLast Week = ' + LastWeek + '\n';		
		
		//надеюсь, что у нас не будет групп выходного дня, которые будут действовать больше одного дня
		List<UserGroup__c> userGroups = [
			select EndDate__c
			from UserGroup__c
			where 
				 EndDate__c >= : LastWeek
			 and EndDate__c < tomorrow
		];
descr += 'userGroups.size() = ' + userGroups.size() + '\n';
		if (userGroups.size() == 7) {
			return;
		}
		
		List<Boolean> holidayDays = new List<Boolean>();
		Integer i = 0;
		for (; i < 7; ++i) {
			holidayDays.add(false);
		}
		
		Boolean isHolidayToday = false;
		for (UserGroup__c item : userGroups) {
			Integer k = item.EndDate__c.date().daysBetween(now.date());
			if (k == 0) {
				isHolidayToday = true;
			}
			holidayDays.set(k, true);
		}
		
		Datetime lastValidCreatedTime;
		Integer lastWorkDay = -1;
		for (i = 1; i < 7; ++i) {
			if (holidayDays.get(i) == false) {
				lastWorkDay = i;
				break;
			}
		}
descr += 'lastWorkDay = ' + lastWorkDay + '\nisHolidayToday = ' + isHolidayToday + '\n';
		if (lastWorkDay == -1 && isHolidayToday) {
			return;
		}
		
		if (isHolidayToday) {
			if (now.hour() >= 12 && now.hour() < 19) {
				lastValidCreatedTime = now.addMinutes(-15);
			} else if (now.hour() < 11) {
				if (lastWorkDay != -1) {
					lastValidCreatedTime = DateTime.newInstance(now.addDays(-lastWorkDay).year(), now.addDays(-lastWorkDay).month(), now.addDays(-lastWorkDay).day(), 18, 45, 1);
				} else {
					return;
				}
			} else if (now.hour() >= 19) {
				lastValidCreatedTime = DateTime.newInstance(now.year(), now.month(), now.day(), 18, 45, 1);
			} else if (now.hour() >= 11 && now.hour() < 12) {
				lastValidCreatedTime = DateTime.newInstance(now.addDays(-lastWorkDay).year(), now.addDays(-lastWorkDay).month(), now.addDays(-lastWorkDay).day(), 18, now.minute(), now.second() + 1);
			}
		} else {
			if (now.hour() >= 11 && now.hour() < 19) {
				lastValidCreatedTime = now.addMinutes(-15);
			} else if (now.hour() < 10) {
				if (lastWorkDay != -1) {
					lastValidCreatedTime = DateTime.newInstance(now.addDays(-lastWorkDay).year(), now.addDays(-lastWorkDay).month(), now.addDays(-lastWorkDay).day(), 18, 45, 1);
				} else {
					return;
				}
			} else if (now.hour() >= 19) {
				lastValidCreatedTime = DateTime.newInstance(now.year(), now.month(), now.day(), 18, 45, 1);
			} else if (now.hour() >= 10 && now.hour() < 11) {
				lastValidCreatedTime = DateTime.newInstance(now.addDays(-lastWorkDay).year(), now.addDays(-lastWorkDay).month(), now.addDays(-lastWorkDay).day(), 18, now.minute(), now.second() + 1);
			}
		}
		
		//заявки за последнюю неделю в статусе назначено
		List<Opportunity> newOpps = [
			select Id, OwnerId, CreatedDate, LastModifiedDate, Account.OwnerId, ProductId__r.ProductGroup__c,
					       RefererCode__c, Amount, AccountId, ProductGroup__c, Description, owner.managerId
			from Opportunity
			where
				 StageName = 'Назначена'
			 and LastModifiedDate > : LastWeek
			 and ProductId__r.ProductGroup__c = 'a0Lb0000002Wa7b'
			 and Owner.ProfileId = '00eb0000000Qbbz'
			 and Owner.Id != '005b0000000wKke'
			 and RefererCode__c = ''
		]; 
		
system.debug('newOpps.size() = ' + newOpps.size());		
		
		List<Id> allOppsIds = new List<Id>();
		for (Opportunity item : newOpps) {
			allOppsIds.add(item.Id);
		}

		//задачи по этим заявкам
		List<Task> oppTasks = [
			select Id, Subject, OwnerId, what.Id, status, LastModifiedDate
			from Task
			where
			     whatId in : allOppsIds
			 and Subject = 'Поступила новая заявка'
		];
		
system.debug('oppTasks.size() = ' + oppTasks.size());
		
		Map<Id, List<Task>> opps_tasks = new Map<Id, List<Task>>();

		for (Opportunity item1 : newOpps) {
			opps_tasks.put(item1.Id, new List<Task>());
			for (Task item2 : oppTasks) {
				if (item1.Id == item2.what.Id) {
					opps_tasks.get(item1.Id).add(item2);
				}
			}
		}

		Boolean flag = false;
		List<Opportunity> oppsForUpdate = new List<Opportunity>();
		for (Opportunity item : newOpps) {
			flag = false;
			List<Task> opp_tasks = opps_tasks.get(item.Id);
			DateTime tmp1, tmp2;
			for (Task item2 : opp_tasks) {
				if (item2.status == 'Выполняется') {
					flag = true;
					break;
				}
				tmp1 = item2.LastModifiedDate.addMinutes(5);
				if (item2.status == 'Завершено' && tmp1 > now) {
					flag = true;
					break;
				}
			}
			tmp2 = item.LastModifiedDate.addMinutes(30);
			if (item.CreatedDate < lastValidCreatedTime && tmp2 < now && flag == false) {
				Id newOwner;
system.debug('Opp to update: ' + item.Id);
				String accOwnerId;
				if (isHolidayToday) {
					accOwnerId = item.Account.OwnerId;
				} else {
					accOwnerId = adminUserId;	
				}
				CustomBMAllocation allocation = new CustomBMAllocation(item, accOwnerId);
				newOwner = allocation.getUserForOpportunity();
				
				Id oldOwner = item.OwnerId;
				item.OwnerId = newOwner;
	
				String descr1 = 'Заявка перераспределена в ' + now + '.\nСтарый ответственный за заявку:' + oldOwner + '.\nНовый ответственный за заявку: ' + newOwner + '.\n';
				descr1 += 'Дата создания заявки: ' + item.CreatedDate + '.\n' + 'lastValidCreatedTime: ' + lastValidCreatedTime + '.\n';
				item.debugInfo__c = descr + '\n' + descr1;
				
				if (
				    (
				        (now.hour() > 19 && item.LastModifiedDate.date() == now.date())
				     || (now.hour() < 10 && item.LastModifiedDate.date() == now.date().addDays(-1))
				    ) 
				    && item.LastModifiedDate.hour() > 19
				   ) {
					
				} else {
					oppsForUpdate.add(item);
				}
				
				if (oppsForUpdate.size() >= 5) {
					break;
				}
			}
		}

system.debug('oppsForUpdate.size = ' + oppsForUpdate.size());

		List<Task> tasksForUpdate = new List<Task>();
		List<Task> tasksForInsert = new List<Task>();
		for (Opportunity item : oppsForUpdate) {
			List<Task> opp_tasks = opps_tasks.get(item.Id);
			
			Boolean flag1 = true;
			for (Task item1 : opp_tasks) {
				if (item1.status != 'Завершено') {
					flag1 = false;
					break;
				}
			}
			
			if (opp_tasks.size() == 0 || flag1) {
				Task tmp = new Task();
				tmp.Subject = 'Поступила новая заявка';
				tmp.whatId = item.Id;
				tmp.Status = 'Новая';
				tmp.OwnerId = item.OwnerId;
				tasksForInsert.add(tmp);
			} else {
				for (Task item1 : opp_tasks) {
					if (item1.status != 'Завершено') {
						item1.OwnerId = item.OwnerId;
						tasksForUpdate.add(item1);
					}
				}
			}
		}

system.debug('tasksForUpdate.size = ' + tasksForUpdate.size());
system.debug('tasksForInsert.size = ' + tasksForInsert.size());

		update oppsForUpdate;
		update tasksForUpdate;
		insert tasksForInsert;
		runNextJob();
	}

}