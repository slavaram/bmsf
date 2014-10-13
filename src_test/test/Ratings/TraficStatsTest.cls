@isTest
class TraficStatsTest {

	static testmethod void test() {
		TraficStats controller = new TraficStats();
		Id managerId = [SELECT ManagerId FROM User WHERE Profile.Name = 'Менеджер'].get(0).ManagerId;
		controller.getAllUsersStats(System.today().addDays(-30), System.today(), managerId);
	}
}