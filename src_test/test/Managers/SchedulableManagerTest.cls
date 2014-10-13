@isTest
class SchedulableManagerTest {

	static testmethod void test() {
		SchedulableManager.runAllJobs();
		SchedulableManager.abortAllJobs();
	}

}