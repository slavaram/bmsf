public with sharing class WeeklyRating {
	public List<UserRating> UsersRating{get;set;}
public String debug;
	
	public class UserRating {
		public Integer position{get;set;}
		public String userName{get;set;}
		public Id userId{get;set;}
		public String userPhoto{get;set;}
		public Id userManagerId{get;set;}
		public Boolean superGroup{get;set;}
		public Integer payments{get;set;}
		public Integer paysToNext{get;set;}
		
		public UserRating () {
			this.position = 0;
			this.userName = '';
			this.userId = '005b0000000NiKS';
			this.userPhoto = '';
			this.payments = 0;
		}
	}
	
	public WeeklyRating() {
debug = '';
		UsersRating = new List<UserRating>();
	}
	
	public UserRating getUserRating(User u) {
		UserRating uRate;
		
		return uRate;
	}
	
	public List<UserRating> getAllUsersRating(Integer N, Date startDate) {
		List<BonusProdGroups__c> BPG = BonusProdGroups__c.getall().values();
		List<Id> ProdGroupsIds = new List<Id>();
		for (BonusProdGroups__c item : BPG) {
			if (item.Bonus_Type__c == 'Бонус менеджера по продажам') {
				ProdGroupsIds.add((Id) item.ProdGroup_Id__c);
			}
		}
		
		if (N == -1) {
			N = 1000;
		} 
		
		Date endDate = startDate.addDays(7);

		List<AggregateResult> uPays = [
			select OpportunityID__r.Owner.Id, OpportunityID__r.Owner.Name, OpportunityID__r.Owner.ManagerId, 
			       MAX(OpportunityID__r.Owner.SmallPhotoUrl) Photo, SUM(Summ__c) Payments
			from Payment__c
			where
			     OpportunityID__r.Owner.isActive = true
			 and OpportunityID__r.Owner.ProfileID = '00eb0000000Qbbz'
			 and OpportunityID__r.Owner.ManagerId != '005b0000000wndZ'
			 and DateOfPayment__c >= : startDate
			 and DateOfPayment__c < : endDate
			 and TypeOfPayment__c != 'Выплата клиенту (возврат)'
			 and PaymentSource__c != 'Тестовый платеж'
			 and OpportunityID__r.ProductId__r.ProductGroup__c in : ProdGroupsIds
			group by OpportunityID__r.Owner.Id, OpportunityID__r.Owner.Name, OpportunityID__r.Owner.ManagerId
			order by SUM(Summ__c) desc
			limit : N
		];
		Integer prevPay = -1;
		Integer prevPos = -1;
		Integer prevPaysToNext = -1;
		List<UserRating> uRate = new List<UserRating>();
		for (AggregateResult item : uPays) {
			UserRating tmp = new UserRating();
			tmp.payments = Integer.valueOf(item.get('Payments'));
			if (prevPay == -1) {
				tmp.paysToNext = 0;
			} else {
				if (prevPay == tmp.payments) {
					tmp.paysToNext = prevPaysToNext; 
				} else {
					tmp.paysToNext = prevPay - tmp.payments;
				}
			}
			if (tmp.payments == prevPay) {
				tmp.position = prevPos;
			} else {
				tmp.position = uRate.size() + 1;
				prevPay = tmp.payments; 
			}
			tmp.userId = (Id) item.get('Id');
			tmp.userName = String.valueOf(item.get('Name'));
			tmp.userPhoto = String.valueOf(item.get('Photo'));
			tmp.userManagerId = (Id) item.get('ManagerId');
			if ((Id) item.get('ManagerId') == '005b0000000wndZ') {
				tmp.superGroup = true;
			} else {
				tmp.superGroup = false;
			}
			
			uRate.add(tmp);
			prevPos = tmp.position;
			prevPaysToNext = tmp.paysToNext;
		}
		
		return uRate;	
	}
	
	public List<UserRating> getManagerUsersRating(Integer N, Date startDate, Id manager) {
		List<UserRating> result = new List<UserRating>();
		List<UserRating> uR = getAllUsersRating(N, startDate);
		
		if (manager == '005b0000000NiKS') {
			return uR;
		} else {
			//Integer counter = 1;
			for (UserRating item : uR) {
				if (item.userManagerId == manager) {
					//item.position = counter;
					//counter++;
					result.add(item);
				}
			}
		}
		return result;
	}
	
	public List<UserRating> getManagerStats(List<UserRating> usersStats, Id manager) {
		List<User> managers;
		if (manager == '005b0000000NiKS') {
			managers = [
				select Id, Name, SmallPhotoUrl
				from User
				where
				     isActive = true
				 and ProfileId = '00eb0000000QgSJ'
				 and id != '005b0000001Nxzk' //Сагун1
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
		
		Integer pos = 0;
		for (User item : managers) {
			UserRating tmp = new UserRating();
			tmp.userId = item.Id;
			tmp.userName = item.Name;
			tmp.userPhoto = item.SmallPhotoUrl;
			
			for (UserRating item1 : usersStats) {
				if (item1.userManagerId == item.Id) {
					tmp.payments += item1.payments;
				}
			}
			
			pos = 0;
			if (managerStats.size() > 0) {
				for (UserRating item1 : managerStats) {
					if (tmp.payments > item1.payments) {
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
		Integer prevPay = -1;
		for (UserRating item : managerStats) {
			item.position = pos;
			pos++;
			if (prevPay != -1) {
				item.paysToNext = prevPay - item.payments;
			}
			prevPay = item.payments;
		}
		
		return managerStats;
	}
}