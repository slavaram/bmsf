public class TaskAttachController {

	public List<SelectOption>	mGroups				{get; set;}
	public List<SelectOption>	mAllUsers			{get; set;}
	public List<Task>			mTasks				{get; set;}
	public List<SelectOption>	mUsersForPick		{get; set;}
	public List<SelectOption>	mUsersPicked		{get; set;}
	public String				mGroup				{get; set;}
	public List<String>			mUsers				{get; set;}
	public String				mTask				{get; set;}
	public Integer				mTasksCount			{get; set;}
	public Boolean				mIsTricklyShare		{get; set;}
	public Day__c				mToday				{get; set;}
	public Day__c				mActivityDate		{get; set;}
	public Day__c				mNewActivityDate	{get; set;}

	public static final String SENIOR_MANAGER_TAG	= 'Старший менеджер';
	public static final String MANAGER_TAG			= 'Менеджер';
	public static final String EXCEPT_TASK_STATUS	= 'Завершено';

	{
		mGroups				= new List<SelectOption>();
		mAllUsers			= new List<SelectOption>();
		mUsers				= new List<String>();
		mTasks				= new List<Task>();
		mUsersForPick		= new List<SelectOption>();
		mUsersPicked		= new List<SelectOption>();
		mToday				= new Day__c(Date__c = System.today());
		mActivityDate		= new Day__c(Date__c=System.today());
		mNewActivityDate	= new Day__c(Date__c=System.today());
		mIsTricklyShare		= false;
	}

	public TaskAttachController() {
		List<User> groups = [SELECT Id, Name
							 FROM User
							 WHERE Profile.Name =: TaskAttachController.SENIOR_MANAGER_TAG
							 AND IsActive = true
							 ORDER BY Name];
		if (groups.size() > 0) {
			for (User seniorManager : groups) {
				SelectOption option = new SelectOption(seniorManager.Id, seniorManager.Name);
				mGroups.add(option);
			}
			mGroup = mGroups.get(0).getValue();
			processUsers();
		}
	}

	public void processUsers() {
		mAllUsers.clear();
		mUsers.clear();
		List<User> users = [SELECT Id, Name
							FROM User
							WHERE Profile.Name = :TaskAttachController.MANAGER_TAG
							AND IsActive = true
							AND ManagerId = :mGroup
							ORDER BY Name];
		if (users.size() > 0) {
			for (User manager : users) {
				SelectOption option = new SelectOption(manager.Id, manager.Name);
				mAllUsers.add(option);
			}
		}
		processTasks();
	}

	public void processTasks() {
		mTasks.clear();
		mUsersForPick.clear();
		mUsersPicked.clear();
		if (mUsers.size() == 0) {
			mTasksCount = 0;
			return;
		}
		mTasks = getTasks(mUsers);
		mTasksCount = mTasks.size();
		mUsersForPick.addAll(mAllUsers);
		if (mUsers.size() == mAllUsers.size()) {
			mUsersForPick.clear();
		} else {
			for (String userId : mUsers) {
				for (Integer i = 0; i < mUsersForPick.size(); i++) {
					if (mUsersForPick.get(i).getValue().equals(userId)) {
						mUsersForPick.remove(i);
					}
				}
			}
		}
	}

	public void saveTasks() {
		List<Task> uploadedTasks = uploadTasks(mTasks);
		Map<String, Case> cases = caseFromTasks(uploadedTasks);
		List<Case> toUpdate = new List<Case>();
		for (Task tk : uploadedTasks) {
			for (String taskId : cases.keySet()) {
				if (tk.Id == taskId) {
					System.debug('[case found]');
					Case thisCase = cases.get(taskId);
					thisCase.OwnerId = tk.OwnerId;
					toUpdate.add(thisCase);
				}
			}
		}
		update toUpdate;
		update uploadedTasks;
		processTasks();
	}

	public void shareTasks() {
		if (mUsersPicked.size() == 0) {
			resetDateForTasks();
		} else {
			if (mIsTricklyShare) {
				shareTasksTrickly();
			} else {
				shareTasksNormal();
			}
		}
		processTasks();
	}

	private void shareTasksNormal() {
		List<Task> toUpdate = new List<Task>();
		List<Case> toUpdateCase = new List<Case>();

		List<Task> uploadedTasks = uploadTasks(mTasks);
		Map<String, Case> cases = caseFromTasks(uploadedTasks);
		Double tasksPerUser = Math.floor((Double)mTasksCount/(Double)mUsersPicked.size());
		for (SelectOption user : mUsersPicked) {
			for (Integer count = 0; count < tasksPerUser; count++) {
				if (uploadedTasks.size() == 0) {
					break;
				} else {
					Task task = uploadedTasks.get(0);
					task.OwnerId = user.getValue();
					task.ActivityDate = mNewActivityDate.Date__c;
					toUpdate.add(task);
					Case cs = cases.get(task.Id);
					if (cs != null) {
						cs.OwnerId = task.OwnerId;
						toUpdateCase.add(cs);
					}
					uploadedTasks.remove(0);
				}
			}
		}
		while (uploadedTasks.size() > 0) {
			for (SelectOption user : mUsersPicked) {
				if (uploadedTasks.size() == 0) {
					break;
				} else {
					Task task = uploadedTasks.get(0);
					task.OwnerId = user.getValue();
					task.ActivityDate = mNewActivityDate.Date__c;
					toUpdate.add(task);
					Case cs = cases.get(task.Id);
					if (cs != null) {
						cs.OwnerId = task.OwnerId;
						toUpdateCase.add(cs);
					}
					uploadedTasks.remove(0);
				}
			}
		}
		update toUpdate;
		update toUpdateCase;
	}

	private void shareTasksTrickly() {
		List<Task> toUpdate = new List<Task>();
		List<Case> toUpdateCase = new List<Case>();
		List<Task> uploadedTasks = uploadTasks(mTasks);
		Integer usersPickedCount = mUsersPicked.size();
		Map<String, Integer> usersAndTasks = getUserIdAndTasksCount(mUsersPicked);
		Integer maxTasks = 0;
		for (String userId : usersAndTasks.keySet()) {
			if (maxTasks < usersAndTasks.get(userId)) {
				maxTasks = usersAndTasks.get(userId);
			}
		}
		Integer spaceForFill = 0;
		for (SelectOption option : mUsersPicked) {
			spaceForFill = spaceForFill + maxTasks - usersAndTasks.get(option.getValue());
		}
		Map<String, Case> cases = caseFromTasks(uploadedTasks);
		Double tasksLevel;
		if (spaceForFill >= mTasksCount) {
			tasksLevel = Math.ceil(	( (usersPickedCount-1) * (Double)maxTasks - (Double)spaceForFill + (Double)mTasksCount ) / (usersPickedCount-1)	);
		} else {
			tasksLevel = Math.ceil(	( (usersPickedCount) * (Double)maxTasks - (Double)spaceForFill + (Double)mTasksCount ) / usersPickedCount );
		}
		for (SelectOption user : mUsersPicked) {
			while (usersAndTasks.get(user.getValue()) < tasksLevel) {
				if (uploadedTasks.size() == 0) {
					break;
				} else {
					Task task = uploadedTasks.get(0);
					task.OwnerId = user.getValue();
					task.ActivityDate = mNewActivityDate.Date__c;
					toUpdate.add(task);
					Case cs = cases.get(task.Id);
					if (cs != null) {
						cs.OwnerId = task.OwnerId;
						toUpdateCase.add(cs);
					}
					uploadedTasks.remove(0);
					usersAndTasks.put(user.getValue(), usersAndTasks.get(user.getValue()) + 1);
				}
			}
		}
		update toUpdate;
		update toUpdateCase;
		mIsTricklyShare = false;
	}

	private void resetDateForTasks() {
		List<Task> toUpdate = new List<Task>();
		List<Task> uploadedTasks = uploadTasks(mTasks);
		for (Task task : uploadedTasks) {
			task.ActivityDate = mNewActivityDate.Date__c;
			toUpdate.add(task);
		}
		update toUpdate;
	}

	private Map<String, Integer> getUserIdAndTasksCount(List<SelectOption> value) {
		Map<String, Integer> result = new Map<String, Integer>();
		List<String> userIds = new List<String>();
		for (SelectOption option : value) {
			userIds.add(option.getValue());
		}
		List<Task> tasks = getTasks(userIds);

		if (tasks.size() == 0) {
			for (String userId : userIds) {
				result.put(userId, 0);
			}
		} else {
			for (String userId : userIds) {
				Integer tasksCount = 0;
				for (Task thisTask : tasks) {
					if (thisTask.OwnerId.equals(userId)) {
						tasksCount++;
					}
				}
				result.put(userId, tasksCount);
			}
		}
		return result;
	}

	private List<Task> getTasks(List<String> userIds) {
		return [SELECT Id, Subject, CreatedDate, Status, ActivityDate, OwnerId, Owner.Name, Task__c, WhatId
				FROM Task
				WHERE OwnerId IN :userIds
				AND ActivityDate <= :mActivityDate.Date__c
				AND Status != :TaskAttachController.EXCEPT_TASK_STATUS
				ORDER BY ActivityDate DESC];
	}

	private List<Task> uploadTasks(List<Task> tasks) {
		List<Task> realTimeTask = [SELECT Id, Subject, CreatedDate, Status, ActivityDate, OwnerId, Owner.Name, Task__c, WhatId
								   FROM Task
								   WHERE Id IN :tasks
								   AND ActivityDate <= :mActivityDate.Date__c
								   AND Status != :TaskAttachController.EXCEPT_TASK_STATUS
								   ORDER BY ActivityDate DESC];
		List<Task> result = new List<Task>();
		for (Task taskSelected : tasks) {
			for (Task taskReal : realTimeTask) {
				if (taskSelected.Id == taskReal.Id) {
					result.add(taskSelected);
				}
			}
		}
		return result;
	}

	private Map<String, Case> caseFromTasks(List<Task> tasks) {
		Map<String, Case> result = new Map<String, Case>();
		List<Id> caseIds = new List<Id>();
		for (Task tk : tasks) {
			Id whatId = tk.WhatId;
			if (whatId != null) {
				if (whatId.getSobjectType().getDescribe().getName().equals('Case')) {
					caseIds.add(whatId);
				}
			}
		}
		List<Case> cases = [SELECT Id, Owner.Id FROM Case WHERE Id IN :caseIds];
		Set<String> duplicateCaseIds = new Set<String>();
		for (Task tk : tasks) {
			Id whatId = tk.WhatId;
			for (Case cs : cases) {
				if (whatId == cs.Id && !duplicateCaseIds.contains(cs.Id)) {
					duplicateCaseIds.add(cs.Id);
					result.put(tk.Id, cs);
				}
			}
		}
		return result;
	}

}