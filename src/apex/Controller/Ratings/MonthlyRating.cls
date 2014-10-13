public with sharing class MonthlyRating {
	public List<UserRating> UsersRating{get;set;}
	
	public class UserRating {
		public Integer position{get;set;}
		//public Integer progress{get;set;}
		public Id userId{get;set;}
		public String userName{get;set;}
		public String userPhoto{get;set;}
		public DateTime userCreatedDate{get;set;}
		public Id userManagerId{get;set;}
		public Id userSDMId{get;set;}
		public Integer allPaysAmount{get;set;}
		public Integer allPaysCount{get;set;}
		public Integer paysToNext{get;set;}
		public Double siteConversion{get;set;}
		public Double averageBill{get;set;}
		public Integer paysFromSiteAmount{get;set;}
		public Integer paysFromSiteCount{get;set;}
		public Integer oppsFromSiteCount{get;set;}
		public Boolean doneMillion{get;set;}
		
		public UserRating() {
			this.position = 0;
			this.userId = '005b0000000NiKS';
			this.userName = '';
			this.userPhoto = '';
			this.userCreatedDate = date.today();
			this.allPaysAmount = 0;
			this.allPaysCount = 0;
			this.paysToNext = 0;
			this.siteConversion = 0.0;
			this.averageBill = 0.0;
			this.oppsFromSiteCount = 0;
			this.paysFromSiteAmount = 0;
			this.paysFromSiteCount = 0;
			this.doneMillion = false;
		}
	}
	
	public MonthlyRating() {
		UsersRating = new List<UserRating>();
	}
	
	public UserRating getUserRating(Id userId) {
		UserRating uRate = new UserRating();
		
		List<BonusProdGroups__c> BPG = BonusProdGroups__c.getall().values();
		List<Id> ProdGroupsIds = new List<Id>();
		for (BonusProdGroups__c item : BPG) {
			if (item.Bonus_Type__c == 'Бонус менеджера по продажам') {
				ProdGroupsIds.add((Id) item.ProdGroup_Id__c);
			}
		}
		
		User u = [
			select Id, Name, SmallPhotoUrl, CreatedDate
			from User
			where
			     Id = : userId
		];
		
		Integer curMonth = date.today().month();
		
		List<AggregateResult> uPays = [
			select OpportunityID__r.Owner.Id, SUM(Summ__c) Payments, COUNT_DISTINCT(OpportunityID__c) CountOfPayments
			from Payment__c
			where
			     OpportunityID__r.Owner.Id = : userId
			 and Month__c = : curMonth
			 and (OpportunityId__r.ProductId__c = '01tb00000008bYQ' or OpportunityId__r.ProductId__c = '01tb00000008prg' or OpportunityId__r.ProductId__c = '01tb00000008x4I')
			 and OpportunityID__r.From__c = 'Сайт'
			 and PaymentSource__c != 'Тестовый платеж'
			 //and OpportunityID__r.StageName = 'Оплачено'
			 //and TypeOfPayment__c != 'Выплата клиенту (возврат)'
			group by OpportunityID__r.Owner.Id
			order by SUM(Summ__c) desc
		];
		List<AggregateResult> allOpps = [
			select Owner.Id, count(Id) ids
			from Opportunity
			where 
			     Month__c = : curMonth
			 and (ProductId__c = '01tb00000008bYQ' or ProductId__c = '01tb00000008prg' or ProductId__c = '01tb00000008x4I')
			 and From__c = 'Сайт'
			 and ReasonRefusal__c != 'Не было контакта с клиентом'
			 and ReasonRefusal__c != 'Некорректные данные'
			 and ReasonRefusal__c != 'Дубль'
			 and ReasonRefusal__c != 'Тестовая'
			 and StageName != 'Дубль'
			 and StageName != 'Тестовая'
			 and Owner.Id = : userId
			group by Owner.Id
		];
		
		if (uPays.size() == 0) {
			uRate.averageBill = 0;
		} else {
			uRate.averageBill = Double.valueOf(uPays[0].get('Payments')) / Double.valueOf(uPays[0].get('CountOfPayments'));
		}
		
		if (allOpps.size() == 0 || uPays.size() == 0) {
			uRate.siteConversion = 0;
		} else {
			uRate.siteConversion = Double.valueOf(uPays[0].get('CountOfPayments')) / Double.valueOf(allOpps[0].get('ids')) * 100.0;
		}
		
		return uRate;
	}
	
	public List<UserRating> getLosers(Integer N, Date cdate) {
		List<UserRating> uRate = getAllUsersRating(-1, cdate, date.today(), '');
		List<UserRating> Losers = new List<UserRating>();
		
		DateTime growUpDate = datetime.newInstance(date.today().addMonths(-1).toStartOfMonth().addDays(10), time.newInstance(0,0,0,0));
		
		Integer i = uRate.size() - 1;
		Integer counter = 0;
		for (; i >= 0; --i) {
			if (uRate.get(i).userCreatedDate < growUpDate) {
				Losers.add(uRate.get(i));
				counter++;
				if (counter == N) {
					break;
				}
			}
		}
		return Losers;
 	}
	
	public List<UserRating> getAllUsersRating(Integer N, Date cdate, Date edate, String ProdGroup) {
		List<Id> ProdGroupsIds = new List<Id>();
		List<String> UsersNoMil = new List<String>();
		List<Id> ProdGroupsVipIds = new List<Id>();
		if (ProdGroup == '' || ProdGroup == '-') {
			List<BonusProdGroups__c> BPG = BonusProdGroups__c.getall().values();
			for (BonusProdGroups__c item : BPG) {
				if (item.Bonus_Type__c == 'Бонус менеджера по продажам') {
					ProdGroupsIds.add((Id) item.ProdGroup_Id__c);
				}
			}
		} else {
			ProdGroupsIds.add((Id) ProdGroup);
		}

		List<User> users = [
			select Id, Name, SmallPhotoUrl, CreatedDate, ManagerId, Manager.ManagerId
			from User
			where
			     isActive = true
			 and ProfileId = '00eb0000000Qbbz'
			 and ManagerId != '005b0000000wndZ'
and Id != '005b0000001PWFA' // Волчек
		];
		List<Id> usersIds = new List<Id>();
		for (User item : users) {
			usersIds.add(item.Id);
		}

		if (N == -1) {
			N = users.size();
		}
		
		Date startOfMonth = cdate;
		Date endOfMonth = edate;
		
		//Платежи менеджера по оплаченным заявкам с сайта по указанным группам продуктов
		//без возвратов за указанный период
		List<AggregateResult> uPays = [
			select OpportunityID__r.Owner.Id, SUM(Summ__c) Payments, COUNT_DISTINCT(OpportunityID__c) CountOfPayments
			from Payment__c
			where
			 	 DateOfPayment__c >= : startOfMonth
			 and DateOfPayment__c <= : endOfMonth
			
			 and OpportunityID__r.From__c = 'Сайт'
			 and OpportunityID__r.StageName = 'Оплачено'
			 and PaymentSource__c != 'Тестовый платеж'
			 and TypeOfPayment__c != 'Выплата клиенту (возврат)'
			 and OpportunityID__r.Owner.Id in : usersIds
			 and OpportunityID__r.ProductId__r.ProductGroup__c in : ProdGroupsIds
			group by OpportunityID__r.Owner.Id
			order by SUM(Summ__c) desc
		];
	
		//все платежи менеджера по данным группам продуктов c возвратами
		//за указанный период
		List<AggregateResult> uPays2 = [
			select OpportunityID__r.Owner.Id, SUM(Summ__c) Payments, COUNT_DISTINCT(OpportunityID__c) CountOfPayments
			from Payment__c
			where 
				 DateOfPayment__c >= : startOfMonth
			 and DateOfPayment__c <= : endOfMonth
			 and OpportunityID__r.Owner.Id in : usersIds
			 and OpportunityID__r.ProductId__r.ProductGroup__c in : ProdGroupsIds
			 //and TypeOfPayment__c != 'Выплата клиенту (возврат)'
			 and PaymentSource__c != 'Тестовый платеж'
			group by OpportunityID__r.Owner.Id
			order by SUM(Summ__c) desc
		];
		
		//Заявки менеджера созданные за указанный период, пришедшие с сайта
		//исключая заявки с указанными причинами и статусами по указанным группам продуктов
		List<AggregateResult> oppsFromSite = [
			select Owner.Id, count(Id) ids
			from Opportunity
			where 
			     CreatedDate >= : startOfMonth
			 and CreatedDate <= : endOfMonth
			 and ProductId__r.ProductGroup__c in : ProdGroupsIds
			 and From__c = 'Сайт'
			 and ReasonRefusal__c != 'Не было контакта с клиентом'
			 and ReasonRefusal__c != 'Некорректные данные'
			 and ReasonRefusal__c != 'Дубль'
			 and ReasonRefusal__c != 'Тестовая'
			 and StageName != 'Дубль'
			 and StageName != 'Тестовая'
			 and Owner.Id in : usersIds
			group by Owner.Id
		];
		
		//все возвраты менеджера по данным группам продуктов
		//за указанный период
		List<AggregateResult> backPays = [
			select OpportunityID__r.Owner.Id, SUM(Summ__c) Payments, COUNT_DISTINCT(OpportunityID__c) CountOfPayments
			from Payment__c
			where 
				 DateOfPayment__c >= : startOfMonth
			 and DateOfPayment__c <= : endOfMonth
			 and OpportunityID__r.Owner.Id in : usersIds
			 and OpportunityID__r.ProductId__r.ProductGroup__c in : ProdGroupsIds
			 and TypeOfPayment__c = 'Выплата клиенту (возврат)'
			 and PaymentSource__c != 'Тестовый платеж'
			group by OpportunityID__r.Owner.Id
			order by SUM(Summ__c) desc
		];
		
		List<NoMilRule__c> noMilUsers = NoMilRule__c.getall().values();
		Set<Id> noMilUsersIds = new Set<Id>();
		for(NoMilRule__c item: noMilUsers)
		{
			noMilUsersIds.add((Id) item.UserId__c);
		}
		
		List<UserRating> uRate = new List<UserRating>();
		Integer prevPay = -1;
		Integer prevPos = -1;
		Integer prevPaysToNext = -1;
		Integer counter = 1;
		for (AggregateResult item : uPays2) {
			UserRating tmp = new UserRating();
			tmp.userId = (Id) item.get('Id');			
			
			//вносим платежи менеджера по указанным группам продуктов без возвратов
			tmp.allPaysAmount = Integer.valueOf(item.get('Payments'));
			tmp.allPaysCount = Integer.valueOf(item.get('CountOfPayments'));

			for (AggregateResult item1 : backPays) {
				if ((Id) item1.get('Id') == tmp.userId) {
					tmp.allPaysCount -= Integer.valueOf(item1.get('CountOfPayments'));
					break;
				}
			}

			if(noMilUsersIds.contains((Id) item.get('Id'))) {
				tmp.doneMillion = true;
			}
			
			if (tmp.allPaysAmount >= 1000000) {
				tmp.doneMillion = true;
			}
			
			if (prevPay == -1) {
				tmp.paysToNext = 0;
			} else {
				if (prevPay == tmp.allPaysAmount) {
					tmp.paysToNext = prevPaysToNext;
				} else {
					tmp.paysToNext = prevPay - tmp.allPaysAmount;
				}
			}
			if (prevPay == tmp.allPaysAmount) {
				tmp.position = prevPos;
			} else {
				tmp.position = uRate.size() + 1;
			}
				
			for (User item1 : users) {
				if (item1.Id == tmp.userId) {
					tmp.userName = item1.Name;
					tmp.userPhoto = item1.SmallPhotoUrl;
					tmp.userCreatedDate = item1.CreatedDate;
					tmp.userManagerId = item1.ManagerId;
					tmp.userSDMId = item1.Manager.ManagerId;
					break;
				}
			}				
			
			for (AggregateResult item1 : uPays) {
				if ((Id) item1.get('Id') == tmp.userId) {
					tmp.paysFromSiteCount = Integer.valueOf(item1.get('CountOfPayments'));
					tmp.paysFromSiteAmount = Integer.valueOf(item1.get('Payments'));
					tmp.averageBill = Double.valueOf(tmp.paysFromSiteAmount) / Double.valueOf(tmp.paysFromSiteCount);
					break;
				}
			}
			
			for (AggregateResult item1 : oppsFromSite) {
				if (tmp.userId == (Id) item1.get('Id')) {
					tmp.oppsFromSiteCount = Integer.valueOf(item1.get('ids'));
					tmp.siteConversion = Double.valueOf(tmp.paysFromSiteCount) / Double.valueOf(tmp.oppsFromSiteCount) * 100.0;
					break;
				}
			}
			
			uRate.add(tmp);
			prevPay = tmp.allPaysAmount;
			prevPos = tmp.position;
			prevPaysToNext = tmp.paysToNext;
		}
		
		Boolean flag = false;
		Integer pos = uRate.size() + 1;
		for (User item : users) {
			flag = true;
			for (UserRating item1 : uRate) {
				if (item1.userId == item.Id) {
					flag = false;
					break;
				}
			}
			if (flag) {
				UserRating tmp = new UserRating();
				tmp.userId = item.Id;
				tmp.userName = item.Name;
				tmp.userPhoto = item.SmallPhotoUrl;
				tmp.userManagerId = item.ManagerId;
				tmp.userCreatedDate = item.CreatedDate;
				tmp.position = pos;
				uRate.add(tmp);
			}
		}
		
		return uRate;	
	}
	
	public List<UserRating> getManagerRating(List<UserRating> uR, Id manager) {
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
	
	public List<UserRating> getManagerStats(List<UserRating> usersStats, Id manager, Date cdate, Date edate) {
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
		
		List<UserRating> managerStats = new List<UserRating>();
		
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
			  or OpportunityID__r.Owner.Id in : managers
		     )   
		     and DateOfPayment__c >= : cdate
		     and DateOfPayment__c <= : edate
			 and PaymentSource__c != 'Тестовый платеж'
			group by OpportunityID__r.Owner.Id
		];
		
		Integer pos = 0;
		for (User item : managers) {
			UserRating tmp = new UserRating();
			tmp.userId = item.Id;
			tmp.userName = item.Name;
			tmp.userPhoto = item.SmallPhotoUrl;
			
			for (UserRating item1 : usersStats) {
				if (item1.userManagerId == item.Id) {
					tmp.allPaysAmount += item1.allPaysAmount;
					tmp.allPaysCount += item1.allPaysCount;
					tmp.paysFromSiteCount += item1.paysFromSiteCount;
					tmp.oppsFromSiteCount += item1.oppsFromSiteCount;
					tmp.paysFromSiteAmount += item1.paysFromSiteAmount;
					
					for (AggregateResult item2 : VIP_Pays) {
						if ((Id) item2.get('Id') == item1.userId && item1.doneMillion) {
							tmp.allPaysAmount += Integer.valueOf(item2.get('Payments'));
							tmp.allPaysCount += Integer.valueOf(item2.get('CountOfPayments'));
							break;
						}
					}
				}
			}
			
			for (AggregateResult item1 : VIP_Pays) {
				if ((Id) item1.get('Id') == item.Id) {
					tmp.allPaysAmount += Integer.valueOf(item1.get('Payments'));
					tmp.allPaysCount += Integer.valueOf(item1.get('CountOfPayments'));
				}
			}
			
			if (tmp.oppsFromSiteCount == 0) {
				tmp.siteConversion = 0;
			} else {
				tmp.siteConversion = Double.valueOf(tmp.paysFromSiteCount) / Double.valueOf(tmp.oppsFromSiteCount) * 100.0;
			}
			if (tmp.paysFromSiteCount == 0) {
				tmp.averageBill = 0;
			} else {
				tmp.averageBill = Double.valueOf(tmp.paysFromSiteAmount) / Double.valueOf(tmp.paysFromSiteCount);
			}
			
			pos = 0;
			if (managerStats.size() > 0) {
				for (UserRating item1 : managerStats) {
					if (tmp.allPaysAmount > item1.allPaysAmount) {
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
		}
		
		return managerStats;
	}
	public List<UserRating> getSDMStats(List<UserRating> usersStats, Id SDM, Date cdate, Date edate) {
		List<User> SDMs;
		if (SDM == '005b0000000NiKS') {
			SDMs = [
				select Id, Name, SmallPhotoUrl
				from User
				where
				     isActive = true
				 and (id = '005b0000000wndZ' or id = '005b0000001OHLi') //Каримова и Рыжако
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
		
		List<UserRating> SDMStats = new List<UserRating>();
		
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
			  or OpportunityID__r.Owner.Id in : managers
			  or OpportunityID__r.Owner.Id in : SDMs   
		     )   
		     and DateOfPayment__c >= : cdate
		     and DateOfPayment__c <= : edate
			 and PaymentSource__c != 'Тестовый платеж'
			group by OpportunityID__r.Owner.Id
		];
		
		Integer pos = 0;
		AggregateResult corpPays = getCorpPays(cdate, edate);
		for (User item : SDMs) {
			UserRating tmp = new UserRating();
			tmp.userId = item.Id;
			tmp.userName = item.Name;
			tmp.userPhoto = item.SmallPhotoUrl;
			
			if (item.Id == '005b0000001OHLi' /*Рыжако*/ && corpPays.get('Payments') != null) {
				tmp.allPaysAmount += Integer.valueOf(corpPays.get('Payments'));
				tmp.allPaysCount += Integer.valueOf(corpPays.get('CountOfPayments'));
			}
			
			for (UserRating item1 : usersStats) {
				if (item1.userSDMId == item.Id) {
					tmp.allPaysAmount += item1.allPaysAmount;
					tmp.allPaysCount += item1.allPaysCount;
					tmp.oppsFromSiteCount += item1.oppsFromSiteCount;
					tmp.paysFromSiteAmount += item1.paysFromSiteAmount;
					tmp.paysFromSiteCount += item1.paysFromSiteCount;
					
					for (AggregateResult item2 : VIP_Pays) {
						if ((Id) item2.get('Id') == item1.userId && item1.doneMillion) {
							tmp.allPaysAmount += Integer.valueOf(item2.get('Payments'));
							tmp.allPaysCount += Integer.valueOf(item2.get('CountOfPayments'));
							break;
						}
					}
				}
			}
			
			for (AggregateResult item1 : VIP_Pays) {
				if ((Id) item1.get('ManagerId') == item.Id || (Id) item1.get('Id') == item.Id) {
					tmp.allPaysAmount += Integer.valueOf(item1.get('Payments'));
					tmp.allPaysCount += Integer.valueOf(item1.get('CountOfPayments'));
				}
			}
			
			if (tmp.oppsFromSiteCount == 0) {
				tmp.siteConversion = 0;
			} else {
				tmp.siteConversion = Double.valueOf(tmp.paysFromSiteCount) / Double.valueOf(tmp.oppsFromSiteCount) * 100.0;
			}
			if (tmp.paysFromSiteCount == 0) {
				tmp.averageBill = 0;
			} else {
				tmp.averageBill = Double.valueOf(tmp.paysFromSiteAmount) / Double.valueOf(tmp.paysFromSiteCount);
			}
			
			pos = 0;
			if (SDMStats.size() > 0) {
				for (UserRating item1 : SDMStats) {
					if (tmp.allPaysAmount > item1.allPaysAmount) {
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
		}
		
		return SDMStats;
	}
	
	public List<UserRating> getAllUsersRating_IK(Integer N, Date cdate, Date edate) {
		List<BonusProdGroups__c> BPG = BonusProdGroups__c.getall().values();
		List<Id> ProdGroupsIds = new List<Id>();
		for (BonusProdGroups__c item : BPG) {
			if (item.Bonus_Type__c == 'Бонус менеджера по продажам') {
				ProdGroupsIds.add((Id) item.ProdGroup_Id__c);
			}
		}
		
		List<User> users = [
			select Id, Name, SmallPhotoUrl, CreatedDate, ManagerId
			from User
			where
			     isActive = true
			 and ProfileId = '00eb0000000Qbbz'
			 and ManagerId != '005b0000000wndZ'
		];
		if (N == -1) {
			N = users.size();
		}
		List<Id> usersIds = new List<Id>();
		for (User item : users) {
			usersIds.add(item.Id);
		}
	
		Date startOfMonth = cdate;
		Date endOfMonth = edate;
		
		List<AggregateResult> uPays2 = [
			select OpportunityID__r.Owner.Id, SUM(Summ__c) Payments, COUNT_DISTINCT(OpportunityID__c) CountOfPayments
			from Payment__c
			where 
				 DateOfPayment__c >= : startOfMonth
			 and DateOfPayment__c <= : endOfMonth
			 //and TypeOfPayment__c != 'Выплата клиенту (возврат)'
			 and OpportunityID__r.Owner.Id in : usersIds
			 and PaymentSource__c != 'Тестовый платеж'
			 and OpportunityID__r.ProductId__r.ProductGroup__c in : ProdGroupsIds
			group by OpportunityID__r.Owner.Id
			order by SUM(Summ__c) desc
		];
		
		List<AggregateResult> uPays = [
			select OpportunityID__r.Owner.Id, SUM(Summ__c) Payments, COUNT_DISTINCT(OpportunityID__c) CountOfPayments
			from Payment__c
			where
			     OpportunityID__r.Owner.Id in : usersIds
			 and DateOfPayment__c >= : startOfMonth
			 and DateOfPayment__c <= : endOfMonth
			 and (OpportunityId__r.ProductId__c = '01tb00000008bYQ' or OpportunityId__r.ProductId__c = '01tb00000008prg' or OpportunityId__r.ProductId__c = '01tb00000008x4I')
			 and OpportunityID__r.ProductId__r.ProductGroup__c in : ProdGroupsIds
			 and OpportunityID__r.From__c = 'Сайт'
			 and PaymentSource__c != 'Тестовый платеж'
			 //and TypeOfPayment__c != 'Выплата клиенту (возврат)'
			 //and OpportunityID__r.StageName = 'Оплачено'
			group by OpportunityID__r.Owner.Id
			order by SUM(Summ__c) desc
		];
		List<AggregateResult> allOpps = [
			select Owner.Id, count(Id) ids
			from Opportunity
			where 
			     CreatedDate >= : startOfMonth
			 and CreatedDate <= : endOfMonth
			 and (ProductId__c = '01tb00000008bYQ' or ProductId__c = '01tb00000008prg' or ProductId__c = '01tb00000008x4I')
			 and ProductId__r.ProductGroup__c in : ProdGroupsIds
			 and From__c = 'Сайт'
			 and ReasonRefusal__c != 'Не было контакта с клиентом'
			 and ReasonRefusal__c != 'Некорректные данные'
			 and ReasonRefusal__c != 'Дубль'
			 and ReasonRefusal__c != 'Тестовая'
			 and StageName != 'Дубль'
			 and StageName != 'Тестовая'
			 and Owner.Id in : usersIds
			group by Owner.Id
		];
		
		List<UserRating> uRate = new List<UserRating>();
		Integer prevPay = -1;
		Integer prevPos = -1;
		Integer prevPaysToNext = -1;
		Integer counter = 1;
		for (AggregateResult item : uPays2) {
			UserRating tmp = new UserRating();
			tmp.allPaysAmount = Integer.valueOf(item.get('Payments'));
			if (prevPay == -1) {
				tmp.paysToNext = 0;
			} else {
				if (prevPay == tmp.allPaysAmount) {
					tmp.paysToNext = prevPaysToNext;
				} else {
					tmp.paysToNext = prevPay - tmp.allPaysAmount;
				}
			}
			if (prevPay == tmp.allPaysAmount) {
				tmp.position = prevPos;
			} else {
				tmp.position = uRate.size() + 1;
			}
			
			tmp.userId = (Id) item.get('Id');
			tmp.paysFromSiteCount = Integer.valueOf(item.get('CountOfPayments'));	
			for (User item1 : users) {
				if (item1.Id == tmp.userId) {
					tmp.userName = item1.Name;
					tmp.userPhoto = item1.SmallPhotoUrl;
					tmp.userCreatedDate = item1.CreatedDate;
					tmp.userManagerId = item1.ManagerId;
				}
			}	
			
			for (AggregateResult item1 : uPays) {
				if ((Id) item1.get('Id') == tmp.userId) {
					tmp.allPaysCount = Integer.valueOf(item1.get('CountOfPayments'));
					tmp.averageBill = Double.valueOf(item1.get('Payments')) / (Double) tmp.allPaysCount;
				}
			}
			
			for (AggregateResult item1 : allOpps) {
				if (tmp.userId == (Id) item1.get('Id')) {
					tmp.siteConversion = Double.valueOf(tmp.allPaysCount) / Double.valueOf(item1.get('ids')) * 100.0;
					break;
				}
			}
			
			uRate.add(tmp);
			prevPay = tmp.allPaysAmount;
			prevPos = tmp.position;
			prevPaysToNext = tmp.paysToNext;
		}
		
		Boolean flag = false;
		Integer pos = uRate.size() + 1;
		for (User item : users) {
			flag = true;
			for (UserRating item1 : uRate) {
				if (item1.userId == item.Id) {
					flag = false;
					break;
				}
			}
			if (flag) {
				UserRating tmp = new UserRating();
				tmp.userId = item.Id;
				tmp.userName = item.Name;
				tmp.userPhoto = item.SmallPhotoUrl;
				tmp.userManagerId = item.ManagerId;
				tmp.userCreatedDate = item.CreatedDate;
				tmp.position = pos;
				uRate.add(tmp);
			}
		}
		
		return uRate;	
	}
	
	public AggregateResult getCorpPays(Date cdate, Date edate) { // <SDM_Id, Pays Amount>
		AggregateResult pays = [
			select SUM(Summ__c) Payments, COUNT_DISTINCT(OpportunityID__c) CountOfPayments
			from Payment__c
			where
			     (
			         OpportunityID__r.Owner.ProfileId = '00eb0000000RGAo'
			      or OpportunityID__r.Owner.ProfileId = '00eb0000000RGZl'
			     ) 
			 and DateOfPayment__c >= : cdate
			 and DateOfPayment__c <= : edate
			 and TypeOfPayment__c != 'Выплата клиенту (возврат)'
			 and PaymentSource__c != 'Тестовый платеж'
		];
		
		return pays;
	}
}