public class SchedulableManager {

	public static final String JOB_IDS_MAP = 'ApexJobs';

	public static void runAllJobs() {
		SavePoint save = Database.setSavepoint();
		if (!Schedulable_MGCardsManager.run() ||
				!Schedulable_CheckActiveCampaigns.run() ||
				!OppOwnerAutoChanger.run() ||
				!Schedulable_RefreshOpportunities.run() ||
				!StatisticCreator.run() ||
				!Update_MG_Members.run() ||
				!DeactivateUser.run() ||
				!OpportunityRelationshipManager.run() ||
				!PromoCodeManager.run()) {
			System.debug(LoggingLevel.ERROR, '[SchedulableManager] Unable to run all apex jobs.');
			Database.rollback(save);
		}
	}

	public static void abortAllJobs() {
		SavePoint save = Database.setSavepoint();
		if (!Schedulable_MGCardsManager.abort() ||
				!Schedulable_CheckActiveCampaigns.abort() ||
				!OppOwnerAutoChanger.abort() ||
				!Schedulable_RefreshOpportunities.abort() ||
				!StatisticCreator.abort() ||
				!Update_MG_Members.abort() ||
				!DeactivateUser.abort() ||
				!OpportunityRelationshipManager.abort() ||
				!PromoCodeManager.abort()) {
			System.debug(LoggingLevel.ERROR, '[SchedulableManager] Unable to abort all apex jobs.');
			Database.rollback(save);
		}
	}

}