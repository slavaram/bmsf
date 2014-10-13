public with sharing class TraficStats {	
	public List<UserStats> UsersStats{get;set;}

	public class UserStats {
		public Id userId{get;set;} //задаем прямо
		public String userName{get;set;} //задаем прямо
		public String userPhoto{get;set;} //задаем прямо
		public Id userManagerId{get;set;} //задаем прямо
		public Id userSDMId{get;set;} //задаем прямо
		public String userManagerName{get;set;} //задаем прямо 
		public String userManagerPhoto{get;set;} //задаем прямо
		public Integer callsCount{get;set;} //суммируем
		public Integer sucCallsCount{get;set;} //суммируем
		public Double averageCallDuration{get;set;} //вычисляем
		public Double callEffect{get;set;} //вычисляем
		public Double averageBill{get;set;} //вычисляем
		public Double siteConversion{get;set;} //вычисляем
		public Double averageDailyTrafic{get;set;} //вычисляем
		public Integer countOfPays{get;set;} //суммируем - кол-во платежей по ОПЛАЧЕННЫМ заявкам с сайта
		public Integer countOfPays2{get;set;} //суммируем - кол-во платежей по ВСЕМ заявкам с сайта
		public Integer allOppsCount{get;set;} //суммируем
		public Integer allCallsDuration{get;set;} //суммируем
		public Integer timeSegment{get;set;} //задаем прямо
		public Integer paysForBill{get;set;} //суммируем - сумма платежей по ОПЛАЧЕННЫМ заявкам с сайта
		public Integer paysForBill2{get;set;} //суммируем - сумма платежей по ВСЕМ заявкам с сайта
		public Integer allPays{get;set;} //суммируем
		public Integer allPaysCount{get;set;} //суммируем
		public Boolean doneMillion{get;set;} //задаем прямо

		public UserStats () {
			callsCount = 0;
			sucCallsCount = 0;
			averageCallDuration = 0.0;
			callEffect = 0.0;
			averageBill = 0.0;
			siteConversion = 0.0;
			averageDailyTrafic = 0.0;
			countOfPays = 0;
			countOfPays2 = 0;
			allOppsCount = 0;
			allCallsDuration = 0;
			timeSegment = 0;
			paysForBill = 0;
			paysForBill2 = 0;
			allPays = 0;
			allPaysCount = 0;
			doneMillion = false;
		}
	}
	
	public TraficStats() {
		UsersStats = new List<UserStats>();
	}
	
	public UserStats getUserStats(User u) {
		UserStats uStats;
		
		return uStats;
	}
	
	public List<UserStats> getAllUsersStats(Date startDate, Date endDate, Id manager) {
		List<UserStats> uStats = new List<UserStats>();
		UserStats score = new UserStats();
		score.userId = '005b0000000NiKS';
		score.userName = 'Итого';
		
		List<User> users;
		if (manager == '005b0000000NiKS') {
			users = [
				select Id, Name, SmallPhotoUrl, Manager.Id, Manager.Name, Manager.SmallPhotoUrl, Manager.ManagerId
				from User
				where
				     isActive = true
				 and ProfileId = '00eb0000000Qbbz'
			];
		} else {
			users = [
				select Id, Name, SmallPhotoUrl, Manager.Id, Manager.Name, Manager.SmallPhotoUrl, Manager.ManagerId
				from User
				where
				     isActive = true
				 and ProfileId = '00eb0000000Qbbz'
				 and managerId = : manager
			];
		}
		
		List<AggregateResult> all_unsuc_calls = new List<AggregateResult>();
		List<AggregateResult> all_suc_calls = new List<AggregateResult>();
		//-----today calls-------------------
		if (endDate >= date.today()) {
			all_unsuc_calls = [
				select OwnerId, count(Id) idCount
				from Task
				where
				     Subject like '%Исходящий%'
				 and Status = 'Завершено'
				 and successfulCall__c = 0
				 and ActivityDate >= today
				 and ActivityDate <= today
				 and OwnerId in : users
				group by OwnerId
			];
			all_suc_calls = [
				select OwnerId, count(Id) idCount, SUM(CallDurationInSeconds) callDuration
				from Task
				where
				     Subject like '%Исходящий%'
				 and Status = 'Завершено'
				 and successfulCall__c = 1
				 and ActivityDate >= today
				 and ActivityDate <= today
				 and OwnerId in : users
				group by OwnerId
			];
		}
		//-------------------------------------
		
		List<AggregateResult> usersStats = [
			select UserId__c, SUM(allCallsCount__c) aCC, SUM(sucCallsCount__c) sCC, SUM(allCallsDur__c) aCD, Count(Id) tS
			from UserStats__c
			where
			     StartDate__c >= : startDate
			 and EndDate__c <= : endDate
			 and UserId__c in : users
			group by UserId__c
		];
		
		
		Integer sumCallDuration;
		for (User item: users) {
			
			UserStats tmp = new UserStats();
			
			tmp.userId = item.Id;
			tmp.userName = item.Name;
			tmp.userPhoto = item.SmallPhotoUrl;
			tmp.userManagerId = item.Manager.Id;
			tmp.userManagerName = item.Manager.Name;
			tmp.userManagerPhoto = item.Manager.SmallPhotoUrl;
			tmp.userSDMId = item.Manager.ManagerId;
			
			for (AggregateResult item1 : usersStats) {
				if ((Id) item1.get('UserId__c') == item.Id) {
					tmp.callsCount = Integer.valueOf(item1.get('aCC'));
					tmp.sucCallsCount = Integer.valueOf(item1.get('sCC'));
					tmp.allCallsDuration = Integer.valueOf(item1.get('aCD'));
					tmp.timeSegment = Integer.valueOf(item1.get('tS'));
					break;
				}
			}
			for (AggregateResult item1 : all_suc_calls) {
				if ((Id) item1.get('OwnerId') == item.Id) {
					tmp.callsCount += Integer.valueOf(item1.get('idCount'));
					tmp.sucCallsCount += Integer.valueOf(item1.get('idCount'));
					tmp.allCallsDuration += Integer.valueOf(item1.get('callDuration'));
					break;
				}
			}
			for (AggregateResult item1 : all_unsuc_calls) {
				if ((Id) item1.get('OwnerId') == item.Id) {
					tmp.callsCount += Integer.valueOf(item1.get('idCount'));
					break;
				}
			}
			
			score.callsCount += tmp.callsCount;
			score.sucCallsCount += tmp.sucCallsCount;
			score.allCallsDuration += tmp.allCallsDuration;
			
system.debug('startDate = ' + startDate + '; endDate = ' + endDate);
			tmp.timeSegment = startDate.daysBetween(endDate) + 1;
			if (tmp.sucCallsCount == 0) {
				tmp.averageCallDuration = 0;
			} else {
				tmp.averageCallDuration = (Double) tmp.allCallsDuration / (Double) tmp.sucCallsCount;
			}
			tmp.averageDailyTrafic = (Double) tmp.allCallsDuration / (Double) tmp.timeSegment;
			
			uStats.add(tmp);
		}
		
		if (score.sucCallsCount == 0) {
			score.averageCallDuration = 0;
		} else {
			score.averageCallDuration = (Double) score.allCallsDuration / (Double) score.sucCallsCount;
		}
		score.timeSegment = startDate.daysBetween(endDate) + 1;
		score.averageDailyTrafic = (Double) score.allCallsDuration / (Double) score.timeSegment;
		
		List<BonusProdGroups__c> BPG = BonusProdGroups__c.getall().values();
		List<Id> ProdGroupsIds = new List<Id>();
		for (BonusProdGroups__c item : BPG) {
			if (item.Bonus_Type__c == 'Бонус менеджера по продажам') {
				ProdGroupsIds.add((Id) item.ProdGroup_Id__c);
			}
		}
		List<AggregateResult> uPays = [
			select OpportunityID__r.Owner.Id, SUM(Summ__c) Payments, COUNT_DISTINCT(OpportunityID__c) CountOfPayments
			from Payment__c
			where
			     OpportunityID__r.Owner.Id in : users
			 and DateOfPayment__c >= : startDate
			 and DateOfPayment__c <= : endDate
			 and OpportunityID__r.ProductId__r.ProductGroup__c in : ProdGroupsIds
			 and OpportunityID__r.From__c = 'Сайт'
			 and OpportunityID__r.StageName = 'Оплачено'
			 and TypeOfPayment__c != 'Выплата клиенту (возврат)'
			 and PaymentSource__c != 'Тестовый платеж'
			group by OpportunityID__r.Owner.Id
			order by SUM(Summ__c) desc
		];
		List<AggregateResult> uPays2 = [
			select OpportunityID__r.Owner.Id, SUM(Summ__c) Payments, COUNT_DISTINCT(OpportunityID__c) CountOfPayments
			from Payment__c
			where 
				 DateOfPayment__c >= : startDate
			 and DateOfPayment__c <= : endDate
			 and TypeOfPayment__c != 'Выплата клиенту (возврат)'
			 and PaymentSource__c != 'Тестовый платеж'
			 and OpportunityID__r.Owner.Id in : users
			 and OpportunityID__r.ProductId__r.ProductGroup__c in : ProdGroupsIds
			group by OpportunityID__r.Owner.Id
			order by SUM(Summ__c) desc
		];
		List<AggregateResult> uPays3 = [
			select OpportunityID__r.Owner.Id, SUM(Summ__c) Payments, COUNT_DISTINCT(OpportunityID__c) CountOfPayments
			from Payment__c
			where
			     OpportunityID__r.Owner.Id in : users
			 and DateOfPayment__c >= : startDate
			 and DateOfPayment__c <= : endDate
			 and OpportunityID__r.ProductId__r.ProductGroup__c in : ProdGroupsIds
			 and OpportunityID__r.StageName = 'Оплачено'
			 and TypeOfPayment__c != 'Выплата клиенту (возврат)'
			 and PaymentSource__c != 'Тестовый платеж'
			group by OpportunityID__r.Owner.Id
			order by SUM(Summ__c) desc
		];
		
		for (UserStats item1 : uStats) {
			for (AggregateResult item : uPays) {
				if (item1.userId == (Id) item.get('Id')) {
					item1.countOfPays = Integer.valueOf(item.get('CountOfPayments'));
					item1.paysForBill = Integer.valueOf(item.get('Payments'));
					//item1.averageBill = Double.valueOf(item.get('Payments')) / Double.valueOf(item.get('CountOfPayments'));
					
					score.countOfPays += item1.countOfPays;
					score.paysForBill += item1.paysForBill;
					break;
				}
			}
			for (AggregateResult item2 : uPays3) {
				if (item1.userId == (Id) item2.get('Id')) {
					item1.countOfPays2 = Integer.valueOf(item2.get('CountOfPayments'));
					item1.paysForBill2 = Integer.valueOf(item2.get('Payments'));
					item1.averageBill = Double.valueOf(item2.get('Payments')) / Double.valueOf(item2.get('CountOfPayments'));
					if (item1.sucCallsCount == 0) {
						item1.CallEffect = 0;
					} else {
						item1.callEffect = Double.valueOf(item2.get('Payments')) / (Double) item1.sucCallsCount;
					}
					score.countOfPays2 += item1.countOfPays2;
					score.paysForBill2 += item1.paysForBill2;
					break;
				}
			}
		}
		
		
		for (AggregateResult item : uPays2) {
			for (UserStats item1 : uStats) {
				if (item1.userId == (Id) item.get('Id')) {
					item1.allPays = Integer.valueOf(item.get('Payments'));
					
					if (item1.allPays >= 1000000) {
						item1.doneMillion = true;
					}
					
					item1.allPaysCount = Integer.valueOf(item.get('CountOfPayments'));
					score.allPays += item1.allPays;
					score.allPaysCount += item1.allPaysCount;
					break;
				}
			}
		}
		
		if (score.sucCallsCount == 0) {
			score.CallEffect = 0;
		} else {
			score.callEffect = (Double) score.paysForBill / (Double) score.sucCallsCount;
		}
		if (score.countOfPays == 0) {
			score.averageBill = 0;
		} else {
			score.averageBill = (Double) score.paysForBill / (Double) score.countOfPays;
		}
		
		List<AggregateResult> allOpps = [
			select Owner.Id, count(Id) ids
			from Opportunity
			where 
			     CreatedDate >= : startDate
			 and CreatedDate <= : endDate
			 and ProductId__r.ProductGroup__c in : ProdGroupsIds
			 and From__c = 'Сайт'
			 and ReasonRefusal__c != 'Некорректные данные'
			 and ReasonRefusal__c != 'Не было контакта с клиентом'
			 and ReasonRefusal__c != 'Дубль'
			 and ReasonRefusal__c != 'Тестовая'
			 and StageName != 'Дубль'
			 and StageName != 'Тестовая'
			 and Owner.Id in : users
			group by Owner.Id
		];
		
		for (AggregateResult item : allOpps) {
			for (UserStats item1 : uStats) {
				if (item1.userId == (Id) item.get('Id')) {
					item1.allOppsCount = Integer.valueOf(item.get('ids'));
					item1.siteConversion = (Double) item1.countOfPays / Double.valueOf(item.get('ids')) * 100.0;
					score.allOppsCount += item1.allOppsCount;
					break;
				}
			}
		}
		
		if (score.allOppsCount == 0) {
			score.siteConversion = 0;
		} else {
			score.siteConversion = (Double) score.countOfPays / (Double) score.allOppsCount;
		}
		
		uStats.add(score);
		return uStats;
	}
	
	public List<UserStats> getManagerStats(List<UserStats> usersStats, Id manager, Date cdate, Date edate) {
		List<User> managers;
		if (manager == '005b0000000NiKS') {
			managers = [
				select Id, Name, SmallPhotoUrl
				from User
				where
				     isActive = true
				 and ProfileId = '00eb0000000QgSJ'
				 and id != '005b0000001NxzkAAC' //Сагун1
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
		
		List<UserStats> managerStats = new List<UserStats>();
		
		List<Id> ProdGroupsIds = new List<Id>();
		List<ProdGroupsForUnusualAlloc__c> BPG = ProdGroupsForUnusualAlloc__c.getall().values();
		for (ProdGroupsForUnusualAlloc__c item : BPG) {
			ProdGroupsIds.add((Id) item.ProdGroup_Id__c);
		}
		
		//платежи по миллионам и платежи, висящие на старших менеджерах
		List<AggregateResult> VIP_Pays = [
			select OpportunityID__r.Owner.Id, SUM(Summ__c) Payments,
			       COUNT_DISTINCT(OpportunityID__c) CountOfPayments, MAX(OpportunityID__r.Owner.ManagerId) ManagerId
			from Payment__c
			where
			 (
				 (
					  OpportunityID__r.Owner.ManagerId in : managers
			      and OpportunityID__r.ProductId__r.ProductGroup__c in : ProdGroupsIds
			     )
			  or (
			      OpportunityID__r.Owner.Id in : managers
			     )
		     )   
		     and DateOfPayment__c >= : cdate
		     and DateOfPayment__c <= : edate
			 and TypeOfPayment__c != 'Выплата клиенту (возврат)'
			 and PaymentSource__c != 'Тестовый платеж'
			group by OpportunityID__r.Owner.Id
		];
		
		for (User item : managers) {
			UserStats tmp = new UserStats();
			tmp.userId = item.Id;
			tmp.userName = item.Name;
			tmp.userPhoto = item.SmallPhotoUrl;
			
			for (UserStats item1 : usersStats) {
				if (item1.userManagerId == item.Id) {
					tmp.callsCount += item1.callsCount;
					tmp.sucCallsCount += item1.sucCallsCount;
					tmp.allCallsDuration += item1.allCallsDuration;
					tmp.countOfPays += item1.countOfPays;
					tmp.countOfPays2 += item1.countOfPays2;
					tmp.allOppsCount += item1.allOppsCount;
					tmp.paysForBill += item1.paysForBill;
					tmp.paysForBill2 += item1.paysForBill2;
					tmp.allPays += item1.allPays;
					tmp.allPaysCount += item1.allPaysCount;
					if (tmp.timeSegment == 0) {
						tmp.timeSegment = item1.timeSegment;
					}
					
					for (AggregateResult item2 : VIP_Pays) {
						if ((Id) item2.get('Id') == item1.userId && item1.doneMillion) {
							tmp.allPays += Integer.valueOf(item2.get('Payments'));
							tmp.allPaysCount += Integer.valueOf(item2.get('CountOfPayments'));
							break;
						}
					}
				}
			}
			
			for (AggregateResult item1 : VIP_Pays) {
				if ((Id) item1.get('Id') == item.Id) {
					tmp.allPays += Integer.valueOf(item1.get('Payments'));
					tmp.allPaysCount += Integer.valueOf(item1.get('CountOfPayments'));
				}
			}
			
			if (tmp.sucCallsCount == 0) {
				tmp.averageCallDuration = 0;
				tmp.callEffect = 0;
			} else {
				tmp.averageCallDuration = (Double) tmp.allCallsDuration / (Double) tmp.sucCallsCount;
				tmp.callEffect = (Double) tmp.paysForBill2 / (Double) tmp.sucCallsCount;
			}
			if (tmp.countOfPays == 0) {
				tmp.averageBill = 0;
			} else {
				tmp.averageBill = (Double) tmp.paysForBill2 / (Double) tmp.countOfPays2;
			}
			if (tmp.allOppsCount == 0) {
				tmp.siteConversion = 0;
			} else {
				tmp.siteConversion = (Double) tmp.countOfPays / (Double) tmp.allOppsCount * 100.0;
			}
			if (tmp.timeSegment == 0) {
				tmp.averageDailyTrafic = 0;
			} else {
				tmp.averageDailyTrafic = (Double) tmp.allCallsDuration / (Double) tmp.timeSegment;
			}
			
			managerStats.add(tmp);
		}
		
		managerStats.add(usersStats.get(usersStats.size() - 1));
		
		return managerStats;
	}
	
	public List<UserStats> getSDMStats(List<UserStats> usersStats, Id SDM, Date cdate, Date edate) {
		List<User> SDMs;
		if (SDM == '005b0000000NiKS') {
			SDMs = [
				select Id, Name, SmallPhotoUrl
				from User
				where
				     isActive = true
				 and (id = '005b0000000wndZ' or id = '005b0000001OHLi') // ХАРДКОДНЫЙ КОСТЫЛЬ ИЗ-ЗА ТОГО, ЧТО НЕТ НОРМАЛЬНЫХ ПРОФИЛЕЙ
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
		
		List<User> managers = [
			select Id, Name, SmallPhotoUrl, ManagerId
			from User
			where
			     isActive = true
			 and ProfileId = '00eb0000000QgSJ'
			 and id != '005b0000001Nxzk' // Сагун1
		];
		
		List<UserStats> SDMStats = new List<UserStats>();
		
		List<Id> ProdGroupsIds = new List<Id>();
		List<ProdGroupsForUnusualAlloc__c> BPG = ProdGroupsForUnusualAlloc__c.getall().values();
		for (ProdGroupsForUnusualAlloc__c item : BPG) {
			ProdGroupsIds.add((Id) item.ProdGroup_Id__c);
		}
		
		//платежи по миллионам и платежи, висящие на старших менеджерах
		List<AggregateResult> VIP_Pays = [
			select OpportunityID__r.Owner.Id, SUM(Summ__c) Payments,
			       COUNT_DISTINCT(OpportunityID__c) CountOfPayments, MAX(OpportunityID__r.Owner.ManagerId) ManagerId
			from Payment__c
			where
			 (
				 (
					  OpportunityID__r.Owner.ManagerId in : managers
			      and OpportunityID__r.ProductId__r.ProductGroup__c in : ProdGroupsIds
			     )
			  or (
			      OpportunityID__r.Owner.Id in : managers
			     )
		     )   
		     and DateOfPayment__c >= : cdate
		     and DateOfPayment__c <= : edate
			 and TypeOfPayment__c != 'Выплата клиенту (возврат)'
			 and PaymentSource__c != 'Тестовый платеж'
			group by OpportunityID__r.Owner.Id
		];
		
		for (User item : SDMs) {
			UserStats tmp = new UserStats();
			tmp.userId = item.Id;
			tmp.userName = item.Name;
			tmp.userPhoto = item.SmallPhotoUrl;
			
			for (UserStats item1 : usersStats) {
				if (item1.userSDMId == item.Id) {
					tmp.callsCount += item1.callsCount;
					tmp.sucCallsCount += item1.sucCallsCount;
					tmp.allCallsDuration += item1.allCallsDuration;
					tmp.countOfPays += item1.countOfPays;
					tmp.countOfPays2 += item1.countOfPays2;
					tmp.allOppsCount += item1.allOppsCount;
					tmp.paysForBill += item1.paysForBill;
					tmp.paysForBill2 += item1.paysForBill2;
					tmp.allPays += item1.allPays;
					tmp.allPaysCount += item1.allPaysCount;
					if (tmp.timeSegment == 0) {
						tmp.timeSegment = item1.timeSegment;
					}
					
					for (AggregateResult item2 : VIP_Pays) {
						if ((Id) item2.get('Id') == item1.userId && item1.doneMillion) {
							tmp.allPays += Integer.valueOf(item2.get('Payments'));
							tmp.allPaysCount += Integer.valueOf(item2.get('CountOfPayments'));
							break;
						}
					}
				}
			}
			
			for (AggregateResult item1 : VIP_Pays) {
				if ((Id) item1.get('ManagerId') == item.Id) {
					tmp.allPays += Integer.valueOf(item1.get('Payments'));
					tmp.allPaysCount += Integer.valueOf(item1.get('CountOfPayments'));
				}
			}
			
			if (tmp.sucCallsCount == 0) {
				tmp.averageCallDuration = 0;
				tmp.callEffect = 0;
			} else {
				tmp.averageCallDuration = (Double) tmp.allCallsDuration / (Double) tmp.sucCallsCount;
				tmp.callEffect = (Double) tmp.paysForBill2 / (Double) tmp.sucCallsCount;
			}
			if (tmp.countOfPays == 0) {
				tmp.averageBill = 0;
			} else {
				tmp.averageBill = (Double) tmp.paysForBill2 / (Double) tmp.countOfPays2;
			}
			if (tmp.allOppsCount == 0) {
				tmp.siteConversion = 0;
			} else {
				tmp.siteConversion = (Double) tmp.countOfPays / (Double) tmp.allOppsCount * 100.0;
			}
			if (tmp.timeSegment == 0) {
				tmp.averageDailyTrafic = 0;
			} else {
				tmp.averageDailyTrafic = (Double) tmp.allCallsDuration / (Double) tmp.timeSegment;
			}
			
			SDMStats.add(tmp);
		}
		
		SDMStats.add(usersStats.get(usersStats.size() - 1));
		
		return SDMStats;
	}	
}