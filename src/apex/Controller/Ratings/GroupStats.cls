public with sharing class GroupStats {

	//"Titan Battle" - game project of Sales Department BM Company. Start 18.08.2014
	//author - Gleb Puzrov
	public static List<GroupStats__c> getDailyStatsForTitanBattle(Date d) {
		List<GroupStats__c> grStats = new List<GroupStats__c>();
		
		Integer SUC_CALLS_COUNT = 40;
		Integer CREATED_OPPS_COUNT = 3;
		Integer BUT_TASKS_COUNT = 50;

		List<DailyAttendance__c> dailyAtt = [
		        select UserId__c
		        from DailyAttendance__c
		        where
		        	Day__c = : d
		        and Reason__c != 'Отпуск'
		        and Reason__c != 'Выходной'];

		Set<Id> attUsersIds = new Set<Id>();
		for (DailyAttendance__c item : dailyAtt) {
			attUsersIds.add(item.UserId__c);
		}
		
		List<UserGroupMember__c> userGroupMembers = [
			select User__c, UserGroup__c
			from UserGroupMember__c
			where
			     UserGroup__r.Type__c = 'Группа для Битвы Титанов'
		];
		List<UserGroup__c> userGroups = [
			select id, Name
			from UserGroup__c
			where
			     Type__c = 'Группа для Битвы Титанов'
		];
		
		Map<Id, Set<Id>> group_users = new Map<Id, Set<Id>>();
		Map<Id, Integer> group_activeUsers = new Map<Id, Integer>();
		for (UserGroup__c item : userGroups) {
			group_users.put(item.Id, new Set<Id>());
			group_activeUsers.put(item.Id, 0);
		}
		
		List<Id> userIds = new List<Id>();
		for (UserGroupMember__c item : userGroupMembers) {
			userIds.add(item.User__c);
			
			Set<Id> tmpSet = group_users.get(item.UserGroup__c);
			
			if (tmpSet != null) {
				tmpSet.add(item.User__c);
				group_users.put(item.UserGroup__c, tmpSet);
			}
			
			if (attUsersIds.contains(item.User__c)) {
				if (group_activeUsers.get(item.UserGroup__c) != null) {
					Integer tmpInt = group_activeUsers.get(item.UserGroup__c);
					tmpInt++;
					group_activeUsers.put(item.UserGroup__c, tmpInt);
				}
			}
		}
		
		DateTime sDateTime = DateTime.newInstance(d, Time.newInstance(0, 0, 0, 0));
		DateTime eDateTime = DateTime.newInstance(d, Time.newInstance(23, 59, 59, 999));
		
		List<AggregateResult> butCreatedTasks = [
			select OwnerId, Count(Id) idsCount
			from Task
			where
				 CreatedById in : userIds
			 and OwnerId in : userIds
			 and CreatedDate >= : sDateTime
			 and CreatedDate <= : eDateTime
			 and isGetNewTask__c = true
			group by OwnerId
		];
		
		List<AggregateResult> fromSiteOpps = [
			select OwnerId, Count(Id) idsCount
			from Opportunity
			where
			     From__c = 'Сайт'
			 and CreatedDate >= : sDateTime
			 and CreatedDate <= : eDateTime
			 and OwnerId in : userIds
			group by OwnerId
		];
		
		List<AggregateResult> createdOpps = [
			select CreatedById, Count(Id) idsCount
			from Opportunity
			where
			     CreatedById in : userIds
			 and CreatedDate >= : sDateTime
			 and CreatedDate <= : eDateTime
			group by CreatedById
		];
		
		List<AggregateResult> sucCalls = [
			select OwnerId, Count(Id) idsCount
			from Task
			where
			     successfulCall__c = 1
			 and ActivityDate = : d
			 and OwnerId in : userIds
			group by OwnerId
		];
		
		List<BonusProdGroups__c> BPG = BonusProdGroups__c.getall().values();
		List<Id> ProdGroupsIds = new List<Id>();
		for (BonusProdGroups__c item : BPG) {
			if (item.Bonus_Type__c == 'Бонус менеджера по продажам') {
				ProdGroupsIds.add((Id) item.ProdGroup_Id__c);
			}
		}
		
		List<AggregateResult> createdPays = [
			select OpportunityID__r.OwnerId, SUM(Summ__c) Payments
			from Payment__c
			where
			     OpportunityID__r.Owner.Id in : userIds
			 and CreatedDate >= : sDateTime
			 and CreatedDate <= : eDateTime
			 and OpportunityID__r.ProductId__r.ProductGroup__c in : ProdGroupsIds
			 and PaymentSource__c != 'Тестовый платеж'
			group by OpportunityID__r.OwnerId
		];
		
		Integer pos = 0;
		for (UserGroup__c item1 : userGroups) {
			GroupStats__c stats = new GroupStats__c();
			stats.UserGroupId__c = item1.Id;
			stats.StartDate__c = d;
			stats.EndDate__c = d;
			stats.UsingFieldsAPI__c = 'targetPoints__c;'
			                  + 'bonusPoints__c;'
			                  + 'formulaValue__c;'
			                  + 'butCreatedTasksCount__c;'
			                  + 'fromSiteOppsCount__c;'
			                  + 'createdOppsCount__c;'
			                  + 'sucCallsCount__c;'
			                  + 'ratingPlace__c;'
			                  + 'pointsSumm__c;'
			                  + 'createdPaysAmount__c;';
			stats.Description__c = 'Данные показатели используются для проекта Отдела продаж - Битва Титанов.\nПроект запущен 18.08.14.';
			
			stats.butCreatedTasksCount__c = 0;
			for (AggregateResult item2 : butCreatedTasks) {
				if (group_users.get(item1.id).contains((Id) item2.get('OwnerId'))) {
					stats.butCreatedTasksCount__c += Integer.valueOf(item2.get('idsCount'));
				}
			}
			
			stats.fromSiteOppsCount__c = 0;
			for (AggregateResult item2 : fromSiteOpps) {
				if (group_users.get(item1.id).contains((Id) item2.get('OwnerId'))) {
					stats.fromSiteOppsCount__c += Integer.valueOf(item2.get('idsCount'));
				}
			}
			
			stats.createdOppsCount__c = 0;
			for (AggregateResult item2 : createdOpps) {
				if (group_users.get(item1.id).contains((Id) item2.get('CreatedById'))) {
					stats.createdOppsCount__c += Integer.valueOf(item2.get('idsCount'));
				}
			}
			
			stats.sucCallsCount__c = 0;
			for (AggregateResult item2 : sucCalls) {
				if (group_users.get(item1.id).contains((Id) item2.get('OwnerId'))) {
					stats.sucCallsCount__c += Integer.valueOf(item2.get('idsCount'));
				}
			}
			
			stats.createdPaysAmount__c = 0;
			for (AggregateResult item2 : createdPays) {
				if (group_users.get(item1.id).contains((Id) item2.get('OwnerId'))) {
					stats.createdPaysAmount__c += Integer.valueOf(item2.get('Payments'));
				}
			}
			
			stats.activeUsersCount__c = group_activeUsers.get(item1.Id);
			stats.bonusPoints__c = 0;
			
			if (stats.activeUsersCount__c != 0) {
				Double k1 = double.valueOf(stats.butCreatedTasksCount__c) / double.valueOf(BUT_TASKS_COUNT * stats.activeUsersCount__c);
				Double k2 = double.valueOf(stats.createdOppsCount__c) / double.valueOf(CREATED_OPPS_COUNT * stats.activeUsersCount__c);
				Double k3 = double.valueOf(stats.sucCallsCount__c) / double.valueOf(SUC_CALLS_COUNT * stats.activeUsersCount__c);
				stats.formulaValue__c = k1 * k2 * k3 * double.valueOf(stats.createdPaysAmount__c); 
			} else {
				stats.formulaValue__c = 0;
			}
			
			pos = 0;
			if (grStats.size() > 0) {
				for (GroupStats__c item2 : grStats) {
					if (stats.formulaValue__c > item2.formulaValue__c) {
						grStats.add(pos, stats);
						break;
					} else if ((pos + 1) == grStats.size()) {
						grStats.add(stats);
						break;
					}
					pos++;
				}
			} else {
				grStats.add(stats);
			}
		}
		
		pos = 1;
		for (GroupStats__c item : grStats) {
			if (item.formulaValue__c == 0) {
				item.ratingPosition__c = grStats.size();
				item.targetPoints__c = 1;
			} else {
				item.ratingPosition__c = pos;
				item.targetPoints__c = grStats.size() - pos + 1;
			}
			pos++;
			
		}
		
		return grStats;
	}
	
	public static void createGroupStatsForTitanBattle(Date d, String mod) {
		List<GroupStats__c> toInsert = GroupStats.getDailyStatsForTitanBattle(d);
		if (mod != 'UnitTest') {
			insert toInsert;
		}
	}
}