public with sharing class AllocationAutoSwitcher implements Schedulable {

	public void execute(SchedulableContext sc) {
		allocAutoSwitcher();
	}
	
	@future
	public static void allocAutoSwitcher() {
		Datetime nineteen_oclock = Datetime.newInstance(date.today().year(), date.today().month(), date.today().day(), 19, 0, 0);
		
		Set<Id> managerIds = DailyAttendanceManager.getUsersByDay(System.today());
		
		List<AggregateResult> tasksByManagers = [
			select owner.Id, MAX(SeniorManager__c) manager, Count(Id) tasks_count
			from Task
			where
			     ActivityDate <= today
			 and CreatedDate < : nineteen_oclock
			 and Owner.Id in : managerIds
			 and status != 'Завершено'
			 group by owner.Id
		];
		List<User> seniorManagers = [
			select Id, Name, isNoAllocation__c
			from User
			where 
			     ProfileId = '00eb0000000QgSJ'
			 and isActive = true
			 and id != '005b0000001Nxzk'//Сагун1     
		];
		
		Map<String, Boolean> managerStatus = new Map<String, Boolean>();
		for (User item : seniorManagers) {
			managerStatus.put(item.Name, false);
		}
		
		Integer n = 3; // максимальное кол-во незакрытых задач на менеджера
		for (AggregateResult item : tasksByManagers) {
			if (Integer.valueOf(item.get('tasks_count')) > n) {
				managerStatus.put(String.valueOf(item.get('manager')), true);
			}
		}
		
		for (User item : seniorManagers) {
			item.isNoAllocation__c = managerStatus.get(item.Name);
		}
		
		update seniorManagers;
	}
}