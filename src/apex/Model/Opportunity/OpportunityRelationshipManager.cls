public class OpportunityRelationshipManager implements Schedulable {

	private static final String JOB_NAME = 'OpportunityRelationshipManager.cls';
	private static final String CRON_EXP = '0 0 0 ? * * *';

	public static Boolean run() {
		SavePoint save = Database.setSavepoint();
		try {
			String jobId = System.schedule(OpportunityRelationshipManager.JOB_NAME,
										   OpportunityRelationshipManager.CRON_EXP,
										   new OpportunityRelationshipManager());
			CacheManager.cache(SchedulableManager.JOB_IDS_MAP, new Map<String, String> {OpportunityRelationshipManager.JOB_NAME => jobId});
			return true;
		} catch (Exception ex) {
			Database.rollback(save);
			System.debug(LoggingLevel.ERROR, '[OpportunityRelationshipManager] Unable to run apex job. ' + ex.getMessage());
			return false;
		}
	}

	public static Boolean abort() {
		SavePoint save = Database.setSavepoint();
		try {
			System.abortJob(CacheManager.getMap(SchedulableManager.JOB_IDS_MAP).get(OpportunityRelationshipManager.JOB_NAME));
			CacheManager.release(SchedulableManager.JOB_IDS_MAP, new Set<String> {OpportunityRelationshipManager.JOB_NAME});
			return true;
		} catch (Exception ex) {
			Database.rollback(save);
			System.debug(LoggingLevel.ERROR, '[OpportunityRelationshipManager] Unable to abort apex job. ' + ex.getMessage());
			return false;
		}
	}

	public void execute(SchedulableContext context) {
		String serviceId = '%' + TopProductGroup__c.getInstance('Сервисы').Id__c + '%';
		List<Opportunity> seviceOpps = [SELECT Id, AccountId, CreatedDate, ProductId__c
		                                FROM Opportunity
		                                WHERE ProductId__r.ProductGroup__r.HierachyPath__c LIKE :serviceId
		                                AND CreatedDate >= TODAY];
		List<Opportunity> toUpdate = processRelations(seviceOpps);
		if (toUpdate.size() > 0) update toUpdate;
	}

	private List<Opportunity> processRelations(List<Opportunity> opportunities) {
		List<Opportunity> result = new List<Opportunity>();
		if (opportunities.size() == 0) return result;
		List<Id> accountIds = new List<Id>();
		for (Opportunity opp : opportunities) {
			accountIds.add(opp.AccountId);
		}
		String prGr1 = '%' + TopProductGroup__c.getInstance('Интенсив, Коучинг').Id__c + '%';
		String prGr2 = '%' + TopProductGroup__c.getInstance('Карьера').Id__c + '%';
		String prGr3 = '%' + TopProductGroup__c.getInstance('Самолет. VIP').Id__c + '%';
		String prGr4 = '%' + TopProductGroup__c.getInstance('Миллион за сто').Id__c + '%';
		String prGr5 = '%' + TopProductGroup__c.getInstance('Отдел продаж').Id__c + '%';
		List<ApplicationsActivities__c> activities = [SELECT Id, OpportunityId__c, OpportunityId__r.ProductId__c, OpportunityId__r.CreatedDate,
		                                              		OpportunityId__r.AccountId, ActionID__c, ActionID__r.StartDate__c
					                             	  FROM ApplicationsActivities__c
					                             	  WHERE OpportunityId__r.AccountId IN :accountIds
					                             	  AND OpportunityId__r.StageName = 'Оплачено'
					                             	  AND (OpportunityId__r.ProductId__r.ProductGroup__r.HierachyPath__c LIKE :prGr1
					                             			  OR OpportunityId__r.ProductId__r.ProductGroup__r.HierachyPath__c LIKE :prGr2
					                             			  OR OpportunityId__r.ProductId__r.ProductGroup__r.HierachyPath__c LIKE :prGr3
					                             			  OR OpportunityId__r.ProductId__r.ProductGroup__r.HierachyPath__c LIKE :prGr4
					                             			  OR OpportunityId__r.ProductId__r.ProductGroup__r.HierachyPath__c LIKE :prGr5
					                             		  )];
		Map<Id, List<ApplicationsActivities__c>> accAndAct = new Map<Id, List<ApplicationsActivities__c>>();
		for (ApplicationsActivities__c activity : activities) {
			List<ApplicationsActivities__c> thisActivities = accAndAct.get(activity.OpportunityId__r.AccountId);
			if (thisActivities == null) {
				List<ApplicationsActivities__c> newActivities = new List<ApplicationsActivities__c>();
				newActivities.add(activity);
				accAndAct.put(activity.OpportunityId__r.AccountId, newActivities);
			} else {
				thisActivities.add(activity);
				accAndAct.put(activity.OpportunityId__r.AccountId, thisActivities);
			}
		}
		for (Opportunity opp : opportunities) {
			List<ApplicationsActivities__c> accActivities = accAndAct.get(opp.AccountId);
			if (accActivities != null) {
				ApplicationsActivities__c lastActivity;
				for (ApplicationsActivities__c activity : accActivities) {
					if (activity.ActionID__r.StartDate__c < opp.CreatedDate) {
						if (lastActivity == null) {
							lastActivity = activity;
						} else {
							if (lastActivity.ActionID__r.StartDate__c > activity.ActionID__r.StartDate__c) lastActivity = activity;
						}
					}
				}
				if (lastActivity != null) {
					opp.RelatedOpportunity__c = lastActivity.OpportunityId__c;
					result.add(opp);
				}
			}
		}
		return result;
	}

}