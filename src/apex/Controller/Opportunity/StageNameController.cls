public class StageNameController {

    public Integer countOfStatusOptions {
    	get {return (countOfStatusOptions != null ? countOfStatusOptions :0);}
    	set;
    }

    public Boolean isShowAllStageName {
    	get {return (isShowAllStageName!= null ? isShowAllStageName:false);}
    	set;
    }

    public Opportunity opp {
        get;
        set {
            opp = value; 
            getStageNames(opp, getUserRoleName(UserInfo.getUserId()));
        }
    }

    public List<SelectOption> statusOptions {
    	get {return (statusOptions != null ? statusOptions : new List<SelectOption>());}
    	set;
    }

    public StageNameController() {
    }

    public String getUserRoleName(String userId) {
        User user = new User();
        try { 
        	user = [Select UserRole.Name From User Where Id=: userId]; 
        } catch (Exception ex) {}
        return (user.UserRole.Name != null ? user.UserRole.Name : '');
    }

    public void getStageNames(Opportunity opp, String userRoleName) {
        statusOptions													= new List<SelectOption>();
        isShowAllStageName												= false;
        Map<String, RoleWithAllStageNames__c> mapRoleWithAllStageNames	= RoleWithAllStageNames__c.getAll();
        if (mapRoleWithAllStageNames.containsKey(UserRoleName)) isShowAllStageName = true; 
        if (!isShowAllStageName) createStageNames(opp, userRoleName);
    }

    public void createStageNames(Opportunity opp, String userRoleName) {
		String currentStage = (opp != null && opp.StageName != null ? opp.StageName : '');
		Map<String, Statuses__c> mapStatuses = Statuses__c.getAll();
		Map<String, String> availableStatuses = new Map<String, String>();
		for (Statuses__c status : mapStatuses.values()) {
			if (status.Roles__c.contains(UserRoleName)) AvailableStatuses.put(status.Name, status.Name);
		}
		if (availableStatuses.containsKey(currentStage) || currentStage == '') {
			List<String> sortAvailableStatuses = new List<String>();
			sortAvailableStatuses.addAll(availableStatuses.KeySet());
			sortAvailableStatuses.sort();
			for (String item : sortAvailableStatuses) {
				statusOptions.add(new SelectOption(item ,item));
			}
		}
		countOfStatusOptions = statusOptions.size();
    }

}