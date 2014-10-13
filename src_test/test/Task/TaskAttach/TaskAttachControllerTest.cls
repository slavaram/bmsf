@isTest
public class TaskAttachControllerTest {

    public static testmethod void test() {
		List<User> seniorManagers = [SELECT Id FROM User WHERE Profile.Name = :TaskAttachController.SENIOR_MANAGER_TAG AND IsActive = true];
		User seniorManager1 = seniorManagers.get(0);
		List<User> managers = [SELECT Id FROM User WHERE Profile.Name = :TaskAttachController.MANAGER_TAG AND IsActive = true AND ManagerId = :seniorManager1.Id];
		User manager1 = managers.get(0);
		User manager2 = managers.get(1);
		User manager3 = managers.get(2);
		List<Task> tasks = new List<Task>();
		tasks.add(new Task(OwnerId = manager2.Id, ActivityDate = System.today()));
		tasks.add(new Task(OwnerId = manager2.Id, ActivityDate = System.today()));
		tasks.add(new Task(OwnerId = manager3.Id, ActivityDate = System.today()));
		tasks.add(new Task(OwnerId = manager3.Id, ActivityDate = System.today()));
		tasks.add(new Task(OwnerId = manager3.Id, ActivityDate = System.today()));
		insert tasks;

		TaskAttachController controller = new TaskAttachController();
		controller.mGroup = seniorManager1.Id;
		controller.processUsers();

		System.assertEquals(seniorManager1.Id, controller.mGroup);
		System.assertNotEquals(0, controller.mAllUsers.size());
		System.assertEquals(0, controller.mUsers.size());
		System.assertEquals(0, controller.mTasksCount);

		controller.mUsers.add(manager1.Id);
		controller.processTasks();

		System.assertEquals(seniorManager1.Id, controller.mGroup);
		System.assertEquals(1, controller.mUsers.size());
		System.assertEquals(0, controller.mTasksCount);

		controller.mUsers.clear();
		controller.mUsers.add(manager2.Id);
		controller.processTasks();

		System.assertEquals(seniorManager1.Id, controller.mGroup);
		System.assertEquals(2, controller.mTasksCount);

		controller.mUsersPicked.add(controller.mUsersForPick.get(0));
		controller.mIsTricklyShare = true;
		controller.shareTasks();

		System.assertEquals(seniorManager1.Id, controller.mGroup);
		System.assertEquals(0, controller.mTasksCount);

		controller.mUsers.clear();
		controller.mUsers.add(manager2.Id);
		controller.processTasks();
		controller.mUsersPicked.add(controller.mUsersForPick.get(0));
		controller.mUsersPicked.add(controller.mUsersForPick.get(1));
		controller.mIsTricklyShare = true;
		controller.shareTasks();

		System.assertEquals(0, controller.mTasksCount);

		tasks.clear();
		tasks.add(new Task(OwnerId = manager1.Id, ActivityDate = System.today()));
		tasks.add(new Task(OwnerId = manager1.Id, ActivityDate = System.today()));
		tasks.add(new Task(OwnerId = manager1.Id, ActivityDate = System.today()));
		insert tasks;

		controller = new TaskAttachController();
		controller.mGroup = seniorManager1.Id;
		controller.processUsers();
		controller.mUsers.add(manager1.Id);
		controller.processTasks();
		controller.mUsersPicked.add(controller.mUsersForPick.get(0));
		controller.mUsersPicked.add(controller.mUsersForPick.get(1));
		controller.mIsTricklyShare = false;
		controller.shareTasks();

		System.assertEquals(0, controller.mTasksCount);

	}

}