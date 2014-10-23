public class TaskController {

	public TaskObj CurrentTask		{get; set;}
	public Boolean isPopupVisible	{get; private set;}

	public class TaskObj {
		public OpportunityEntity controller	{get; set;}

		public Task task					{get; set;}
		public Opportunity opportunity		{get; set;}
		public Campaign campaign			{get; set;}
		public Account account				{get; set;}
		public Case clientCase				{get; set;}
		public PossibleAccount__c possibleAccount {get; set;}
		public String Mode					{get; set;}

		public String OldStageName			{get; set;}

		public Boolean noSaydCity			{get; set;}
		public Boolean noSaydHaveBisnes		{get; set;}
		public Boolean noSaydIncome			{get; set;}
		public Boolean noSaydCountEmp		{get; set;}
		public Boolean noSaydBisnesP		{get; set;}
		public Boolean noSaydWhereKnow		{get; set;}
		public Boolean noSaydWhereKnowOther	{get; set;}
		public Boolean noSaydWhereKnow2		{get; set;}
		public Boolean noSaydMale			{get; set;}
		public Boolean noSaydAge			{get; set;}

		public Boolean doNotCallFlag		{get; set;}

		public Boolean isAccount			{get; set;} // признак связана ли задача с клиентом
		public Boolean isOpportunity		{get; set;} // признак связана ли задача с возможностью
		public Boolean isCampaign			{get; set;}
		public Boolean isCase				{get; set;} // признак связана ли задача с обращением
		public Boolean isPossibleAccount	{get; set;} // признак связана ли задача с обращением
		public Boolean isClone				{get; set;}
		public Boolean isAuto				{get; set;} // создана ли автоматически
		public Boolean FindInAutoTask		{get; set;} // создавать ли новую задачу
		public Boolean isCreateNextTask		{get; set;} // создавать ли новую задачу
		public Task NewTask					{get; set;} // новая задача, для ввода крайнего срока
		public List<Account> likeAccounts	{get; set;}
		public Account accountLookup		{get; set;}
		public String textField				{get; set;}
		public String textField2			{get; set;}

		{
			Mode = 'view';
			accountLookup = new Account();
			textField = 'клиенте';
			textField2 = 'клиенту';
		}

		public TaskObj(Task task, Map<String, String> Parameters) {
			if (task != null) {
				this.task = task;
			} else {
				this.task = new Task();
			}
			if (this.task.ActivityDate == null)	{
				this.task.ActivityDate = date.today();
			}
			if (Parameters.get('isEdit') != null && Parameters.get('isEdit') == '1') Mode = 'edit';
			if (Parameters.containsKey('isClose')) {
				if (Parameters.get('isClose') == '1') {
					Mode = 'edit';
					this.task.Status = 'Завершено';
					isClone = true;
				}
			}
			if (Parameters.get('isAuto') != null && Parameters.get('isAuto') == '1') isAuto = true;
			// пробуем запросить клиента
			try {
				account = [SELECT isPersonAccount ,Phone, id, PhoneNumber__c, BirthDay__c,
				           		SiteRegistrationDate__c, CountryCode__c, CityCode__c, PersonEmail,
				               	ShippingCity ,patronymic__c, NoName__c, NoLastName__c,
				               	PersonMobilePhone, AccountLink__c, PersonBirthDate,	CountryTelCode__c,
				               	HasBusiness__c , FirstName , Name, LastName, Description,
				               	Industry, WhereKnow__c, WhereKnowOther__c, WhereKnowDetail__c,
				               	PersonalIncome__c, NumberOfEmployees, Sex__c
				           FROM Account
				           WHERE Id = :task.AccountId];
			} catch(Exception ex) {
				account = new Account();
			}
			// пробуем запросить возможность
			try {
				opportunity = [SELECT Id__c, JQ__c, id, ActionNames__c, Debt__c, SummNDS__c , CloseDate,
				               		AmountWithDiscount__c, EndDateOfPayment__c, StartDateOfPayment__c,
				               		PrintPayments__c, ProductId__r.Name,NumberOfPayments__c,SummOfPayments__c,
				               		CreatedDate, PaymentRobokassa__c, ReasonRefusal__c, Name, OpportunityLink__c,
				                    Discount__c, StageName, Freezing__c, FreezingToAction__c, Description,
				                    ProductGroup__c, IsMillion__c, Source__c, From__c, Sertifikat__c   
				               FROM Opportunity
				               WHERE Id = :task.WhatId];
			} catch (Exception ex) {
				opportunity = new Opportunity();
			}
			// пробуем запросить кампанию
			try {
				campaign = [SELECT Id, Name FROM Campaign WHERE Id = :task.WhatId];
			} catch (Exception ex) {
				campaign = new Campaign();
			}
			if (opportunity.StageName != null) {
				OldStageName = opportunity.StageName;
			} else {
				OldStageName = '';
			}
			// пробуем запросить обращение
			try {
				clientCase = [SELECT Id, Subject, Status, Description, CaseNumber, OwnerId , Type, PhoneToCall__c, TimeToCall__c, AccountId
				              FROM Case
				              WHERE Id = :task.WhatId];
			} catch (Exception ex) {
				clientCase = new Case();
			}
			// пробуем запросить PossibleAccount__c
			try {
				possibleAccount = [SELECT Id, Name__c, Email__c, Phone__c, Description__c, RecommendedBy__c, RealAccount__c,
				                   		RecommendedBy__r.Name, RealAccount__r.Name, RecommendedBy__r.AccountLink__c, RealAccount__r.AccountLink__c
				                   FROM PossibleAccount__c
				                   WHERE Id = :task.WhatId];
				likeAccounts = [SELECT Id, Name, AccountLink__c
				                FROM Account
				                WHERE (PersonEmail = :possibleAccount.Email__c
				                OR Phone = :possibleAccount.Phone__c)
								AND PersonEmail != null
								AND Phone != null
				                AND AccountLink__c != null
				                AND FirstName != null
				                AND LastName != null
				                AND Name != null
				                LIMIT 10];
				textField = 'рекомендующем';
				textField2 = 'рекомендующему';
			} catch (Exception ex) {
				clientCase = new Case();
			}
			// если не указан код старны, ставим по умолчанию +7
			if (account.CountryTelCode__c == null) account.CountryTelCode__c = '+7';
			isAccount			= (account != null && account.Id != null ?					true : false);
			isOpportunity		= (opportunity != null && opportunity.Id != null ?			true : false);
			isCase				= (clientCase != null && clientCase.Id != null ?			true : false);
			isCampaign			= (campaign != null && campaign.Id != null ?				true : false);
			isPossibleAccount	= (possibleAccount != null && possibleAccount.Id != null ?	true : false);
			controller			= new OpportunityEntity(opportunity.Id);
		}

		public PageReference setStatusInProcess() {
			task.Status = 'Выполняется';
			try {
				update task;
			} catch (exception ex) {}
			Map<String, String> parameters = new Map<String, String> {
								'id' => (task.Id != null ? String.valueOf(task.Id) : ''),
								'isClose' => '1'
							};
			return ReturntoTask(parameters);
		}

		public void close() {
			Mode = 'edit';
			task.Status = 'Завершено';
		}

		public void edit() {
			Mode = 'edit';
		}

		public PageReference remove() {
			try{
				delete task;
			} catch (Exception ex) {}
			PageReference page = new PageReference('/apex/HomePage?sfdc.tabName=01rb00000004pAZ');
			page.setRedirect(true);
			return page;
		}

		public PageReference doNotCall() {
			if (doNotCallFlag)	{
				if (account.ShippingCity == null)		noSaydCity=true;
				if (account.HasBusiness__c == null)		noSaydHaveBisnes=true;
				if (account.PersonalIncome__c == null)	noSaydIncome=true;
				if (account.NumberOfEmployees == null)	noSaydCountEmp=true;
				if (account.Industry == null)			noSaydBisnesP=true;
				if (account.WhereKnow__c == null )		noSaydWhereKnow=true;
				if (account.WhereKnowOther__c == null)	noSaydWhereKnowOther=true;
				if (account.WhereKnowDetail__c == null) noSaydWhereKnow2=true;
				if (account.Sex__c == null)				noSaydMale=true;
				if (account.BirthDay__c == null)		noSaydAge=true;
			} else {
				if (account.ShippingCity == null)		noSaydCity=false;
				if (account.HasBusiness__c == null)		noSaydHaveBisnes=false;
				if (account.PersonalIncome__c == null)	noSaydIncome=false;
				if (account.NumberOfEmployees == null)	noSaydCountEmp=false;
				if (account.Industry == null)			noSaydBisnesP=false;
				if (account.WhereKnow__c == null )		noSaydWhereKnow=false;
				if (account.WhereKnowOther__c == null)	noSaydWhereKnowOther=false;
				if (account.WhereKnowDetail__c == null) noSaydWhereKnow2=false;
				if (account.Sex__c == null)				noSaydMale=false;
				if (account.BirthDay__c == null)		noSaydAge=false;
			}
			return null;
		}
		
		public PageReference Save() {
			Boolean CanSave = true;
			Map<String, String> parameters = new Map<String, String>();
			parameters.put('id', (this.task.Id != null ? string.valueOf(this.task.Id) : '' ));
			try {
				if (this.task.Description.length() < 50 && !this.doNotCallFlag)	{
					ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Комментарий должен быть длиннее 50 символов'));
	    			return null;
				}
			} catch (exception ex) {
				System.debug('Error');
			}
			try { 
				update this.task; 
			} catch (exception ex) {
				System.debug(logginglevel.ERROR, 'Не удалось обновить задачу: ' + (this.task.Id != null ? String.valueOf(this.task.Id) : 'empty'));
			}
			// если задача связана с клиентом - обновляем
			if (this.isAccount) {
				try { 
					update this.account; 
				} catch (exception ex) {
					System.debug(logginglevel.ERROR, 'Не удалось обновить клиента: ' + (this.account.Id != null ? String.valueOf(this.account.Id) : 'empty'));
				}
			}
			// если связана с возможностью - обновляем
			if (this.isOpportunity && !controller.thisOpportunity.Locked__c ) {
				Opportunity temp_opp = [SELECT Id, StageName FROM Opportunity WHERE Id = :controller.thisOpportunity.Id];
				if (temp_opp.StageName == 'Оплачено' || temp_opp.StageName == 'Частичная оплата') {
					controller.thisOpportunity.StageName = temp_opp.StageName;
				}
				if (controller.Save() == null ) CanSave = false;
			}
			// если задача связана с обращением - обновляем
			if (this.isCase) {
				try{
					update this.clientCase; 
				} catch (exception ex) {
					System.debug(logginglevel.ERROR, 'Не удалось обновить обращение: ' + (this.clientCase.Id != null ? String.valueOf(this.clientCase.Id) : 'empty'));
				}
			}
			// переходим на страницу задачи
			if (CanSave) {
				return ReturntoTask(parameters);
			} else {
				return null;
			}
		}

		public PageReference SaveAndCreateOpp() {
			Boolean CanSave = true;
			Map<String, String> parameters = new Map<String, String>();
			parameters.put('id', (this.task.id != null ? string.valueOf(this.task.id) : ''));
			try {
				if (this.task.Description.length() < 50 && !this.doNotCallFlag)	{
					ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Комментарий должен быть длиннее 50 символов'));
	    			CanSave = false;
				}
			} catch (exception ex) {
				System.debug('Error');
			}
			try { 
				update this.task; 
			} catch (exception ex) {
				System.debug(LoggingLevel.ERROR, 'Не удалось обновить задачу: ' + (this.task.Id != null ? String.valueOf(this.task.Id) : 'empty'));
			}
			// если задача связана с клиентом - обновляем
			if (this.isAccount) {
				try{ 
					update this.account; 
				} catch (exception ex) {
					System.debug(LoggingLevel.ERROR, 'Не удалось обновить клиента: ' + (this.account.Id != null ? String.valueOf(this.account.Id) : 'empty'));
				}
			}
			// если связана с возможностью - обновляем
			if (this.isOpportunity && !controller.thisOpportunity.Locked__c ) {
				Opportunity temp_opp = [SELECT Id, StageName FROM Opportunity WHERE Id = :controller.thisOpportunity.Id];
				if (temp_opp.StageName == 'Оплачено' || temp_opp.StageName == 'Частичная оплата') {
					controller.thisOpportunity.StageName = temp_opp.StageName;
				}
				if (controller.Save() == null) CanSave = false;
			}
			// если задача связана с обращением - обновляем
			if (this.isCase) { 
				try {
					update this.clientCase; 
				} catch (Exception ex) {
					System.debug(LoggingLevel.ERROR, 'Не удалось обновить обращение: ' + (this.clientCase.Id != null ? String.valueOf(this.clientCase.Id) : 'empty'));
				}
			}
			// переходим на страницу задачи
			if (CanSave) {	
				PageReference page = new PageReference('/apex/Opportunity');
				Map<String, String> param = new Map<String, String>();
				page.getParameters().put('Campaign', task.CampaignId__c);
				page.getParameters().put('Account', task.account.Id);
				page.setRedirect(true);
				return page;
			} else {
				return null;
			}
		}

		// клонирования
		public PageReference SaveAndCreate() {
			return SaveAndCreate(null);
		}

		private PageReference SaveAndCreate(Id whatId) {
			Save();
			Task CloneTask = new Task();
			if (whatId == null) {
				if (this.clientCase != null && this.clientCase.AccountId != null) {
					CloneTask.WhatId = this.clientCase.AccountId;
				} else {
					if (this.possibleAccount == null) CloneTask.WhatId = this.task.WhatId;
				}
			} else {
				CloneTask.WhatId = whatId;
			}
			CloneTask.WhoId				= (whatId == null ? this.task.WhoId : null);
			CloneTask.TaskType__c		= this.task.TaskType__c;
			CloneTask.Status			= 'Новая';
			CloneTask.OwnerId			= this.task.OwnerId;
			CloneTask.TaskTypes__c		= this.task.TaskTypes__c;
			CloneTask.Contacts__c		= this.task.Contacts__c;
			CloneTask.ContactType__c	= this.task.ContactType__c;
			CloneTask.SubTypeTask__c	= this.task.SubTypeTask__c;
			CloneTask.IsReminderSet		= this.task.IsReminderSet;
			CloneTask.Subject			= this.task.Subject;
			CloneTask.ActivityDate		= Date.today();
			CloneTask.StageName__c		= this.task.StageName__c;
			CloneTask.Resolution__c		= null;
			CloneTask.ReminderDateTime	= DateTime.now().addHours(4);
			CloneTask.Priority			= this.task.Priority;
			CloneTask.Description		= this.task.Description;
			CloneTask.CloseDate__c		= this.task.CloseDate__c;
			CloneTask.CampaignId__c 	= this.task.CampaignId__c;
			// пробуем создать клон
			try { 
				insert CloneTask; 
			} catch (Exception ex) {
				System.debug(LoggingLevel.ERROR, 'Не создать клон задачи ' + (this.task.Id != null ? String.valueOf(this.task.Id) : 'empty'));
			}
			Map<String, String> parameters = new Map<String, String>{ 
								'id' => (CloneTask.Id != null ? String.valueOf(CloneTask.Id) : ''),
								'isClone' => '1',
								'isEdit' => '1' 
							};
			return ReturntoTask(parameters);
		}

		public PageReference Cancel() {
			Map<String, String> parameters = new Map<String, String>{ 
								'id' => (this.task.Id != null ? string.valueOf(this.task.Id) : '')
							};
			return ReturntoTask(parameters);
		}
	
		public PageReference ReturntoTask(Map<String, String> parameters){
			PageReference page = new PageReference ('/apex/Task');
			for (String parameterName : parameters.KeySet()) {
				page.getParameters().put(parameterName, parameters.get(parameterName));
			}
			page.setRedirect(true);
			return page;
		}
	}

	{
		isPopupVisible = false;
	}

	public TaskController(ApexPages.StandardController standardController) {
		String TaskId = standardController.getId();
		Task task;
		try {
			task = [SELECT AccountId, WhatId, WhoId, TaskType__c, Owner.Name, OwnerId, LastModifiedById,
			        	TaskTypes__c, Contacts__c, ContactType__c, SubTypeTask__c, id, IsReminderSet,
			        	Subject, ActivityDate, StageName__c, Resolution__c, ReminderDateTime, Priority,
			        	Description, CloseDate__c, Account.NoLastName__c, Account.NoName__c, Status,
			        	Account.BillingCity, Account.id,Product__c, CreatedBy.Name , CreatedBy.UserRole.Name,
			        	Account.PhoneNumber__c, Account.patronymic__c, Account.BirthDay__c,
			        	Account.SiteRegistrationDate__c, Account.HasBusiness__c, Account.IsPersonAccount,
			        	Account.PersonEmail, LastModifiedBy.Name, LastModifiedDate, CreatedDate,
			        	Account.FirstName, Account.LastName, Account.Name, Account.IsDeleted, CampaignId__c,
			        	doNotCallFlag__c, doRecall__c
			        FROM Task 
			        WHERE Id = :TaskId AND Account.IsDeleted = false];
		} catch (Exception ex) {
			task = new Task();
		}
		Map<String, String> parameters = ApexPages.currentPage().getParameters();
		CurrentTask = new TaskObj(task, parameters);
	}

	public PageReference createAccountAndTask() {
		PageReference pageRef = new PageReference('/apex/NewAccount');
		pageRef.getParameters().put('FromTask', CurrentTask.task.Id);
		if (CurrentTask.possibleAccount.Email__c != null) pageRef.getParameters().put('Email', CurrentTask.possibleAccount.Email__c);
		if (CurrentTask.possibleAccount.Phone__c != null) pageRef.getParameters().put('Phone', CurrentTask.possibleAccount.Phone__c);
		return pageRef;
	}

	public void showPopupForm() {
		isPopupVisible = true;
	}

	public void hidePopupForm() {
		isPopupVisible = false;
	}

	public PageReference assignAccountAndCreateTask() {
		if (CurrentTask.accountLookup.AccountUl__c == null) return null;
		update new PossibleAccount__c(Id = CurrentTask.possibleAccount.Id, RealAccount__c = CurrentTask.accountLookup.AccountUl__c);
		return CurrentTask.SaveAndCreate(CurrentTask.accountLookup.AccountUl__c);
	}

}