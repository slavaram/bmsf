public with sharing class DailyRating {
	public List<UserRating> UsersRating{get;set;}
	
	Integer SUC_CALLS_PLAN = 50;
	Integer BUT_TASKS_PLAN = 50;
	Integer CREATED_OPPS_PLAN = 3;
	Integer PAYS_AMOUNT_PLAN = 1000000;							

	public class UserRating {
		public Integer position{get;set;}
		public Id userId{get;set;}
		public String userName{get;set;}
		public String userPhoto{get;set;}
		public Id userManagerId{get;set;}
		public Id userSDMId{get;set;}
		public Integer managersCount{get;set;}
		
		public Integer openTasksCount{get;set;}
		public Integer closeTasksCount{get;set;}
		public Decimal completedTasksPercantage{get;set;}
		
		public Integer payments{get;set;}
		public Integer sucCallsCount{get;set;}
		public Integer butTasksCount{get;set;}
		public Integer createdOppsCount{get;set;}
		
		public Integer paymentsPlan{get;set;}
		public Integer sucCallsPlan{get;set;}
		public Integer butTasksPlan{get;set;}
		public Integer createdOppsPlan{get;set;}
		
		public UserRating () {
			this.position = 0;
			this.payments = 0;
			this.openTasksCount = 0;
			this.closeTasksCount = 0;
			this.completedTasksPercantage = 0;
			this.sucCallsCount = 0;
			this.butTasksCOunt = 0;
			this.createdOppsCount = 0;
			this.managersCount = 0;
			this.paymentsPlan = 0;
			this.sucCallsPlan = 0;
			this.butTasksPlan = 0;
			this.createdOppsPlan = 0;
		}
	}
	
	public DailyRating() {
		UsersRating = new List<UserRating>();
	}
	
	public UserRating getUserRating(User u) {
		UserRating uRate;
		
		return uRate;
	}
	
	public List<UserRating> getAllUsersRating(Integer N, Date cdate) {
		List<BonusProdGroups__c> BPG = BonusProdGroups__c.getall().values();
		List<Id> ProdGroupsIds = new List<Id>();
		for (BonusProdGroups__c item : BPG) {
			if (item.Bonus_Type__c == 'Бонус менеджера по продажам') {
				ProdGroupsIds.add((Id) item.ProdGroup_Id__c);
			}
		}
		
		List<User> users = [
			select Id, Name, SmallPhotoUrl, ManagerId, Manager.ManagerId
			from User
			where
			     isActive = true
			 and ProfileId = '00eb0000000Qbbz'
		];
		
		if (N == -1) {
			N = users.size();
		}
		List<Id> usersIds = new List<Id>();
		for (User item : users) {
			usersIds.add(item.Id);
		}
	
		List<AggregateResult> uPays = [
			select OpportunityID__r.Owner.Id, SUM(Summ__c) Payments
			from Payment__c
			where
			     OpportunityID__r.Owner.Id in : usersIds
			 and DateOfPayment__c = : cdate
			 and OpportunityID__r.ProductId__r.ProductGroup__c in : ProdGroupsIds
			 and PaymentSource__c != 'Тестовый платеж'
			group by OpportunityID__r.Owner.Id
			order by SUM(Summ__c) desc
		];
		
		List<UserRating> uRate = new List<UserRating>();
		for (User item : users) {
			UserRating tmp = new UserRating();
			tmp.userId = item.Id;
			tmp.userName = item.Name;
			tmp.userPhoto = item.SmallPhotoUrl;
			tmp.userManagerId = item.ManagerId;
			tmp.userSDMId = item.Manager.ManagerId;
			
			tmp.sucCallsPlan = SUC_CALLS_PLAN;
			tmp.butTasksPlan = BUT_TASKS_PLAN;
			tmp.createdOppsPlan = CREATED_OPPS_PLAN;
			
			for (AggregateResult item1 : uPays) {
				if (item.Id == (Id)item1.get('Id')) {
					tmp.payments = Integer.valueOf(item1.get('Payments'));
					break;
				}
			}
			if (tmp.payments == 0) {
				tmp.position = uPays.size() + 1;
			}
			uRate.add(tmp);
		}
		
		Datetime cDateTimeB = DateTime.newInstance(cdate.year(), cdate.month(), cdate.day(), 0, 0, 0);
		Datetime cDateTimeE = DateTime.newInstance(cdate.year(), cdate.month(), cdate.day(), 23, 59, 59);
		
		List<AggregateResult> usersClosedTasks = [
			select Owner.Id, count(Id) tasks_count
			from Task
			where
			     Owner.Id in : usersIds
			 and status = 'Завершено'
			 and ClosedDateTime__c >= : cDateTimeB
			 and ClosedDateTime__c <= : cDateTimeE
			 and LastModifiedById in : usersIds
			 and isCall__c = 0
			 and isEmail__c = 0
			group by Owner.Id
		];
		
		Datetime nineteen_oclock = Datetime.newInstance(cdate.year(), cdate.month(), cdate.day(), 19, 0, 0);
		List<AggregateResult> usersOpenTasks = [
			select owner.Id, count(Id) tasks_count
			from Task
			where
			     ActivityDate <= : cdate
			 and CreatedDate < : nineteen_oclock
			 and owner.id in : usersIds
			 and status != 'Завершено'
			group by owner.Id
		];
		
		List<AggregateResult> usersSucCalls = [
			select owner.Id, count(Id) tasks_count
			from Task
			where
			     ActivityDate = : cdate
			 and owner.id in : usersIds
			 and Subject like '%Исходящий вызов%'
			 and successfulCall__c = 1
			group by owner.Id
		];
		
		List<AggregateResult> usersButTasks = [
			select owner.Id, count(Id) tasks_count
			from Task
			where
			     CreatedDate >= : cDateTimeB
			 and CreatedDate <= : cDateTimeE
			 and owner.id in : usersIds
			 and isGetNewTask__c = true
			group by owner.Id
		];
		
		List<AggregateResult> usersCreatedOpps = [
			select CreatedById, count(Id) opps_count
			from Opportunity
			where
			     CreatedDate >= : cDateTimeB
			 and CreatedDate <= : cDateTimeE
			 and CreatedById in : usersIds
			group by CreatedById
		];
		
		//Временное решение, для того, чтобы считать только тех менеджеров,
		//которые сегодня работают.
		//Когда появится функционал, отслеживающий посещаемость менеджеров
		//использовать его.
		List<Integer> indexesToRemove = new List<Integer>();		
		Integer indexCounter = 0;
		
		for (UserRating item : uRate) {
			for (AggregateResult item1 : usersClosedTasks) {
				if (item.userId == (Id) item1.get('Id')) {
					item.closeTasksCount = (Integer) item1.get('tasks_count');
					break;
				}
			}
			for (AggregateResult item1 : usersOpenTasks) {
				if (item.userId == (Id) item1.get('Id')) {
					item.openTasksCount = (Integer) item1.get('tasks_count');
					break;
				}
			}
			for (AggregateResult item1 : usersSucCalls) {
				if (item.userId == (Id) item1.get('Id')) {
					item.sucCallsCount = (Integer) item1.get('tasks_count');
					break;
				}
			}
			for (AggregateResult item1 : usersButTasks) {
				if (item.userId == (Id) item1.get('Id')) {
					item.butTasksCount = (Integer) item1.get('tasks_count');
					break;
				}
			}
			for (AggregateResult item1 : usersCreatedOpps) {
				if (item.userId == (Id) item1.get('CreatedById')) {
					item.createdOppsCount = (Integer) item1.get('opps_count');
					break;
				}
			}
			
			if (item.sucCallsCount == 0 && item.butTasksCount == 0 && item.createdOppsCount == 0) {
				if (indexesToRemove.size() == 0) {
					indexesToRemove.add(indexCounter);
				} else {
					indexesToRemove.add(0, indexCounter);
				}
			}
			indexCounter++;
			
			if ((item.openTasksCount + item.closeTasksCount) != 0) {
				item.completedTasksPercantage = (Decimal) item.closeTasksCount / ((Decimal) item.openTasksCount + (Decimal) item.closeTasksCount) * 100.0;
			}
		}
		
		for (Integer i : indexesToRemove) {
			uRate.remove(i);
		} 
		
		Integer counter = 1;
		List<UserRating> orderRate = new List<UserRating>();
		UserRating score = new UserRating();
		for (AggregateResult item : uPays) {
			for (UserRating item1 : uRate) {
				if (item1.userId == (Id) item.get('Id')) {
					item1.position = counter;
					orderRate.add(item1);
					
					score.payments += item1.payments;
					score.openTasksCount += item1.openTasksCount;
					score.closeTasksCount += item1.closeTasksCount;
					score.sucCallsCount += item1.sucCallsCount;
					score.butTasksCOunt += item1.butTasksCOunt;
					score.createdOppsCount += item1.createdOppsCount;
					score.paymentsPlan += item1.paymentsPlan;
					score.sucCallsPlan += item1.sucCallsPlan;
					score.butTasksPlan += item1.butTasksPlan;
					score.createdOppsPlan += item1.createdOppsPlan;

					counter++;
					break;
				}
			}
		}
		for (UserRating item : uRate) {
			if (item.position == (uPays.size() + 1)) {
				orderRate.add(item);
				
				score.payments += item.payments;
				score.openTasksCount += item.openTasksCount;
				score.closeTasksCount += item.closeTasksCount;
				score.sucCallsCount += item.sucCallsCount;
				score.butTasksCOunt += item.butTasksCOunt;
				score.createdOppsCount += item.createdOppsCount;
				score.paymentsPlan += item.paymentsPlan;
				score.sucCallsPlan += item.sucCallsPlan;
				score.butTasksPlan += item.butTasksPlan;
				score.createdOppsPlan += item.createdOppsPlan;
			}
		}
		
		if (score.openTasksCount == 0 && score.closeTasksCount == 0) {
			score.completedTasksPercantage = 0;
		} else {
			score.completedTasksPercantage = Double.valueOf(score.closeTasksCount) / Double.valueOf(score.openTasksCount + score.closeTasksCount) * 100.0;
		}
		
		//orderRate.add(score);
		
		return orderRate;	
	}
	
	public List<UserRating> getManagerGroupRating(Integer N, Date cdate, Id manager) {
		List<UserRating> uR = getAllUsersRating(N, cdate);
		List<UserRating> result = new List<UserRating>();
		
		if (manager == '005b0000000NiKS') {
			return uR;
		} else {
			for (UserRating item : uR) {
				if (item.userManagerId == manager) {
					result.add(item);
				}
			}
		}	
		return result;
	}
	
	public List<UserRating> getManagersRating(Id manager, Date cdate) {
		List<User> managers;
		if (manager == '005b0000000NiKS') {
			managers = [
				select Id, Name, SmallPhotoUrl
				from User
				where
				     isActive = true
				 and ProfileId = '00eb0000000QgSJ'
				 and id != '005b0000001Nxzk' // Сагун1
			];
		} else {
			managers = [
				select Id, Name, SmallPhotoUrl
				from User
				where
				     isActive = true
				 and ProfileId = '00eb0000000QgSJ'
				 and Id = : manager
			];
		}
		
		List<UserRating> usersStats = getAllUsersRating(-1, cdate);
		List<UserRating> managerStats = new List<UserRating>();
		
		List<ProdGroupsForUnusualAlloc__c> BPG = ProdGroupsForUnusualAlloc__c.getall().values();
		List<Id> ProdGroupsIds = new List<Id>();
		for (ProdGroupsForUnusualAlloc__c item : BPG) {
			ProdGroupsIds.add((Id) item.ProdGroup_Id__c);
		}
		
		Integer pos = 0;
		for (User item : managers) {
			UserRating tmp = new UserRating();
			tmp.userId = item.Id;
			tmp.userName = item.Name;
			tmp.userPhoto = item.SmallPhotoUrl;
			
			for (UserRating item1 : usersStats) {
				if (item1.userManagerId == item.Id) {
					tmp.payments += item1.payments;
					tmp.openTasksCount += item1.openTasksCount;
					tmp.closeTasksCount += item1.closeTasksCount;
					tmp.sucCallsCount += item1.sucCallsCount;
					tmp.butTasksCount += item1.butTasksCount;
					tmp.createdOppsCount += item1.createdOppsCount;
					tmp.managersCount++;
				}
			}
			
			if (tmp.openTasksCount == 0 && tmp.closeTasksCount == 0) {
				tmp.completedTasksPercantage = 0;
			} else {
				tmp.completedTasksPercantage = Double.valueOf(tmp.closeTasksCount) / Double.valueOf(tmp.openTasksCount + tmp.closeTasksCount) * 100.0;
			}
			
			pos = 0;
			if (managerStats.size() > 0) {
				for (UserRating item1 : managerStats) {
					if (tmp.sucCallsCount > item1.sucCallsCount) {
						managerStats.add(pos, tmp);
						break;
					} else if ((pos + 1) == managerStats.size()) {
						managerStats.add(tmp);
						break;
					}
					pos++;
				}
			} else {
				managerStats.add(tmp);
			}
		}
		
		pos = 1;
		for (UserRating item : managerStats) {
			item.position = pos;
			pos++;
			
			item.sucCallsPlan = SUC_CALLS_PLAN * item.managersCount;
			item.butTasksPlan = BUT_TASKS_PLAN * item.managersCount;
			item.createdOppsPlan = CREATED_OPPS_PLAN * item.managersCount;
			item.paymentsPlan = PAYS_AMOUNT_PLAN;
		}
		
		return managerStats;
	}
	
	public List<UserRating> getSDMRating(Id SDM, Date cdate) { // SDM - Sales Department Manager
		List<User> SDMs;
		if (SDM == '005b0000000NiKS') {
			SDMs = [
				select Id, Name, SmallPhotoUrl
				from User
				where
				     isActive = true
				 and (id = '005b0000000wndZ' or id = '005b0000001OHLi') // КОСТЫЛЬНЫЙ ХАРДКОД!! А ВСЕ ПОТОМУ ЧТО У НАС НЕТ ПРОФИЛЕЙ НОРМАЛЬНЫХ
			];
		} else {
			SDMs = [
				select Id, Name, SmallPhotoUrl
				from User
				where
				     isActive = true
				 and Id = : SDM
			];
		}
		
		List<UserRating> usersStats = getAllUsersRating(-1, cdate);
		List<UserRating> SDMStats = new List<UserRating>();
		
		List<ProdGroupsForUnusualAlloc__c> BPG = ProdGroupsForUnusualAlloc__c.getall().values();
		List<Id> ProdGroupsIds = new List<Id>();
		for (ProdGroupsForUnusualAlloc__c item : BPG) {
			ProdGroupsIds.add((Id) item.ProdGroup_Id__c);
		}
		
		Integer pos = 0;
		for (User item : SDMs) {
			UserRating tmp = new UserRating();
			tmp.userId = item.Id;
			tmp.userName = item.Name;
			tmp.userPhoto = item.SmallPhotoUrl;
			
			for (UserRating item1 : usersStats) {
				if (item1.userSDMId == item.Id) {
					tmp.payments += item1.payments;
					tmp.openTasksCount += item1.openTasksCount;
					tmp.closeTasksCount += item1.closeTasksCount;
					tmp.sucCallsCount += item1.sucCallsCount;
					tmp.butTasksCount += item1.butTasksCount;
					tmp.createdOppsCount += item1.createdOppsCount;
					tmp.managersCount++;
				}
			}
			
			if (tmp.openTasksCount == 0 && tmp.closeTasksCount == 0) {
				tmp.completedTasksPercantage = 0;
			} else {
				tmp.completedTasksPercantage = Double.valueOf(tmp.closeTasksCount) / Double.valueOf(tmp.openTasksCount + tmp.closeTasksCount) * 100.0;
			}
			
			pos = 0;
			if (SDMStats.size() > 0) {
				for (UserRating item1 : SDMStats) {
					if (tmp.sucCallsCount > item1.sucCallsCount) {
						SDMStats.add(pos, tmp);
						break;
					} else if ((pos + 1) == SDMStats.size()) {
						SDMStats.add(tmp);
						break;
					}
					pos++;
				}
			} else {
				SDMStats.add(tmp);
			}
		}
		
		pos = 1;
		for (UserRating item : SDMStats) {
			item.position = pos;
			pos++;
			
			item.sucCallsPlan = SUC_CALLS_PLAN * item.managersCount;
			item.butTasksPlan = BUT_TASKS_PLAN * item.managersCount;
			item.createdOppsPlan = CREATED_OPPS_PLAN * item.managersCount;
			item.paymentsPlan = PAYS_AMOUNT_PLAN;
		}
		
		return SDMStats;
	}
}