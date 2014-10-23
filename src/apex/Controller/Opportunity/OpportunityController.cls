public class OpportunityController {

	public Account thisAccount			{get; set;}
	public OpportunityEntity controller	{get; set;}
	public String profileId				{get; set;}

	public OpportunityController(ApexPages.StandardController standardController) {
		String opportunityId = standardController.getId();
		if (opportunityId == null) {
			controller = new OpportunityEntity();
		} else {
			controller = new OpportunityEntity(opportunityId);
		}
		try {
			thisAccount = [SELECT Id, Industry
			               FROM Account
			               WHERE Id = :controller.thisOpportunity.AccountId];
		} catch(Exception ex) {
			thisAccount = new Account();
		}
	}

	public PageReference save() {
		if (thisAccount.Id != null ) {
			try { 
				update thisAccount;
			} catch(Exception ex) {}
		}
		return controller.save();
	}

	public PageReference cancel() {
		return controller.cancel();
	}

}