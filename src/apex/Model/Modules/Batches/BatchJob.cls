global class BatchJob implements Database.Batchable<sObject> {

	global String QUERY_BODY;

	global BatchJob(String query) {
		QUERY_BODY = query;
	}

	global Database.QueryLocator start(Database.BatchableContext context) {
		return Database.getQueryLocator(QUERY_BODY);
	}

	global void execute(Database.BatchableContext context, List<Account> accounts) {
		// TODO
	}

	global void finish(Database.BatchableContext context) {
		// TODO
	}

}