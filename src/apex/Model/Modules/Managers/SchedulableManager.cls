public class SchedulableManager {

	public static final String JOB_IDS_MAP = 'ApexJobs';

	public static void runAllJobs() {
		SavePoint save = Database.setSavepoint();
		if (!Schedulable_CheckActiveCampaigns.run() ||
				!CardTasksScheduler.run() ||
				!OppOwnerAutoChanger.run() ||
				!Schedulable_RefreshOpportunities.run() ||
				!StatisticCreator.run() ||
				!CardsScheduler.run() ||
				!DeactivateUser.run() ||
				!OpportunityRelationshipManager.run() ||
				!PromoCodeManager.run()) {
			System.debug(LoggingLevel.ERROR, '[SchedulableManager] Unable to run all apex jobs.');
			Database.rollback(save);
		}
	}

	public static void abortAllJobs() {
		SavePoint save = Database.setSavepoint();
		if (!Schedulable_CheckActiveCampaigns.abort() ||
				!CardTasksScheduler.abort() ||
				!OppOwnerAutoChanger.abort() ||
				!Schedulable_RefreshOpportunities.abort() ||
				!StatisticCreator.abort() ||
				!CardsScheduler.abort() ||
				!DeactivateUser.abort() ||
				!OpportunityRelationshipManager.abort() ||
				!PromoCodeManager.abort()) {
			System.debug(LoggingLevel.ERROR, '[SchedulableManager] Unable to abort all apex jobs.');
			Database.rollback(save);
		}
	}

}