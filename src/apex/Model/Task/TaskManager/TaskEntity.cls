public without sharing class TaskEntity {

	public String result {
		get;
		set {
			if (result != null && value == null) throw new TaskEntityException('Result can not be set to null for this goal');
			result = value;
			updateParameters();
		}
	}
	public Boolean closable					{get; private set;}
	public List<String> results				{get; private set;}
	public String closeComment				{get; set;}
	public Boolean newTaskCreatable			{get; private set;}
	public CloseTaskParameters closeBlock	{get; private set;}
	public CreateTaskParameters createBlock	{get; private set;}

	private Task thisTask;
	private Map<String, TaskResultsMatrix__c> resultMatrix = new Map<String, TaskResultsMatrix__c>();

	public class CloseTaskParameters {
		public Boolean visible {get; private set;}
		public String reason {
			get;
			set {
				if (reason != null && value == null) throw new TaskEntityException('reason can not be set to null for this result');
				reason = value;
			}
		}
		public List<String> reasons {get; private set;}
		public DateTime possiblePaymentDate {
			get;
			set {
				if (possiblePaymentDate != null && value == null) throw new TaskEntityException('PossiblePaymentDate can not be set to null for this result');
				possiblePaymentDate = value;
			}
		}
		private CloseTaskParameters(Boolean visible, String reason, List<String> reasons, DateTime possiblePaymentDate) {
			this.visible				= visible;
			this.reason					= reason;
			this.reasons					= reasons;
			this.possiblePaymentDate	= possiblePaymentDate;
		}
		private CloseTaskParameters() {
			visible = false;
		}
	}

	public class CreateTaskParameters {
		public Boolean visible {get; private set;}
		public DateTime activityDateTime {
			get;
			set {
				if (activityDateTime != null && value == null) throw new TaskEntityException('ActivityDateTime can not be set to null for this result');
				activityDateTime = value;
			}
		}
		public String communicationType {
			get;
			set {
				if (communicationType != null && value == null) throw new TaskEntityException('CommunicationType can not be set to null for this result');
				communicationType = value;
			}
		}
		public List<String> communicationTypes {get; private set;}
		public Id ownerId {
			get;
			set {
				if (ownerId != null && value == null) throw new TaskEntityException('OwnerId can not be set to null for this result');
				ownerId = value;
			}
		}
		public List<Id> ownerIds {get; private set;}
		public String comment {get; set;}
		private CreateTaskParameters(Boolean visible, DateTime activityDateTime, String communicationType,
				List<String> communicationTypes, Id ownerId, List<Id> ownerIds, String comment) {
			this.visible					= visible;
			this.activityDateTime			= activityDateTime;
			this.communicationType			= communicationType;
			this.communicationTypes			= communicationTypes;
			this.ownerId					= ownerId;
			this.ownerIds					= ownerIds;
			this.comment					= comment;
		}
		private CreateTaskParameters() {
			visible = false;
		}
	}

	public class TaskEntityException extends Exception {}

	{
		results = new List<String>();
	}

	public TaskEntity(Id taskId) {
		if (taskId == null) throw new TaskEntityException('Invalid taskId value: \'' + taskId + '\'');
		try {
			thisTask = [SELECT Id, WhatId, WhoId, Goal__c, Description, Status, Priority, Subject FROM Task WHERE Id = :taskId].get(0);
		} catch (Exception ex) {
			throw new TaskEntityException('Task for \'' + taskId + '\' id not found');
		}
		closeComment		= thisTask.Description;
		closable			= true;
		String profileKey	= ApexUtils.getProfileKeyById(UserInfo.getProfileId());
		for (TaskResultsMatrix__c matrixRecord : TaskResultsMatrix__c.getAll().values()) {
			if ((profileKey == 'admin' || matrixRecord.ProfileKey__c == profileKey) &&
					matrixRecord.SourceObjectType__c == thisTask.WhatId.getSObjectType().getDescribe().getName() &&
					matrixRecord.Goal__c == thisTask.Goal__c) {
				resultMatrix.put(matrixRecord.Result__c, matrixRecord);
				results.add(matrixRecord.Result__c);
			}
		}
		if (results == null || results.isEmpty() || thisTask.Status != 'Выполняется') {
			closable			= false;
			newTaskCreatable	= false;
			closeBlock			= new CloseTaskParameters();
			createBlock			= new CreateTaskParameters();
		} else {
			result = results.get(0);
		}
	}

	public void close() {
		if (!closable) throw new TaskEntityException('Не корректная задача. Она не может быть завершена.');
		List<sObject> toUpdate		= new List<sObject>();
		TaskResultsMatrix__c matrix	= resultMatrix.get(result);
		thisTask.Resolution__c		= result;
		thisTask.Description		= closeComment;
		thisTask.Reason__c			= closeBlock.reason;
		thisTask.Status				= 'Завершено';
		toUpdate.add(thisTask);
		Id whoId;
		if (matrix.SourceObjectType__c == 'Opportunity') {
			Opportunity source = [SELECT Id, StageName, ExpectedPayDate__c FROM Opportunity WHERE Id = :thisTask.WhatId].get(0);
			source.StageName = matrix.SourceObjectStatus__c;
			if (matrix.PossiblePaymentDateEditable__c) source.ExpectedPayDate__c = closeBlock.possiblePaymentDate.date();
			if (matrix.IsFullDeligation__c) source.OwnerId = getOwnerId(matrix);
			toUpdate.add(source);
		} else if (matrix.SourceObjectType__c == 'Case') {
			Case source = [SELECT Id FROM Case WHERE Id = :thisTask.WhatId].get(0);
			source.Status = matrix.SourceObjectStatus__c;
			if (matrix.IsFullDeligation__c) source.OwnerId = getOwnerId(matrix);
			toUpdate.add(source);
		} else if (matrix.SourceObjectType__c == 'Account' && matrix.IsFullDeligation__c) {
			Account source = [SELECT Id FROM Account WHERE Id = :thisTask.WhatId].get(0);
			source.OwnerId = getOwnerId(matrix);
			toUpdate.add(source);
		} else if (matrix.SourceObjectType__c == 'PossibleAccount__c' && (matrix.IsFullDeligation__c || result == 'Клиент подтвержден')) {
			PossibleAccount__c source = [SELECT Id, Name__c, Email__c, Phone__c, Description__c, RealAccount__c FROM PossibleAccount__c WHERE Id = :thisTask.WhatId].get(0);
			if (matrix.IsFullDeligation__c) source.OwnerId = getOwnerId(matrix);
			if (result == 'Клиент подтвержден') {
				Account acc = new Account(Name = source.Name__c, PersonEmail = source.Email__c, Phone = source.Phone__c, Description = source.Description__c, OwnerId = UserInfo.getUserId());
				insert acc;
				source.RealAccount__c = acc.Id;
				whoId = acc.Id;
			}
			toUpdate.add(source);
		}
		if (!matrix.IsFinal__c || matrix.IsAutoTask__c) {
			insert new Task(ActivityDateTime__c = createBlock.activityDateTime,
							WhatId = thisTask.WhatId,
							WhoId = (whoId == null ? thisTask.WhoId : whoId),
							Goal__c = thisTask.Goal__c,
							Subject = thisTask.Subject + ' | ',
							Description = createBlock.comment,
							ContactType__c = createBlock.communicationType,
							Contacts__c = 'Исходящий',
							OwnerId = getOwnerId(matrix),
							Priority = (matrix.IsAutoTask__c ? '3': thisTask.Priority));
		}
		if (!toUpdate.isEmpty()) update toUpdate;
	}

	private void updateParameters() {
		TaskResultsMatrix__c matrix				= resultMatrix.get(result);
		List<String> reasons						= (String.isBlank(matrix.Causes__c) ? null : matrix.Causes__c.split(';'));
		closeBlock = new CloseTaskParameters(   (!String.isBlank(matrix.Causes__c) || matrix.PossiblePaymentDateEditable__c),
												(reasons == null || reasons.isEmpty() ? null : reasons.get(0)),
												reasons,
												(matrix.PossiblePaymentDateEditable__c ? System.now() : null));
		List<String> communicationTypes			= SObjectUtils.getObjectPickListFieldLabels('Task', 'ContactType__c');
		List<Id> ownerIds						= getOwnerIds(matrix.NewOwner__c);
		createBlock	= new CreateTaskParameters( !matrix.IsFinal__c,
												System.now(),
												communicationTypes.get(0),
												communicationTypes,
												(ownerIds == null || ownerIds.isEmpty() ? null : ownerIds.get(0)),
												(ownerIds == null || ownerIds.isEmpty() ? null : ownerIds),
												'');
		newTaskCreatable						= matrix.NewTaskCreatable__c;
	}

	private List<Id> getOwnerIds(String key) {
		List<Id> result = new List<Id>();
		if (key == 'to manager in group') {
			for (User use : [SELECT Id FROM User WHERE IsActive = true AND ManagerId = :UserInfo.getUserId()]) {
				result.add(use.Id);
			}
			return result;
		} else if (key == 'to any') {
			for (User use : [SELECT Id FROM User WHERE IsActive = true]) {
				result.add(use.Id);
			}
			return result;
		} else {
			return null;	
		}
	}

	private Id getOwnerId(TaskResultsMatrix__c matrix) {
		if (createBlock.ownerId != null) return createBlock.ownerId;
		if (matrix.NewOwner__c == null) {
			return UserInfo.getUserId();
		} else if (matrix.NewOwner__c == 'to senior manager') {
			return [SELECT Id, ManagerId FROM User WHERE Id = :UserInfo.getUserId()].get(0).ManagerId;
		} else if (matrix.NewOwner__c == 'to account manager' || matrix.NewOwner__c == 'to support manager' || matrix.NewOwner__c == 'to issue manager') {
			String profileKey = matrix.NewOwner__c.substringAfter('to ');
			List<User> users = [SELECT Id FROM User WHERE ProfileId = :ApexUtils.getProfileIdByKey(profileKey)];
			if (users.isEmpty()) throw new TaskEntityException('Нет пользователей с профилем \'' + profileKey + '\' либо профиль не сохранен в OrganizationProfiles.cs');
			return users.get((Integer) Math.roundToLong(Math.random()*users.size())).Id;
		} else {
			throw new TaskEntityException('Cant assign new task owner');
		}
	}

	public String nicePrint() {
		String result = '';
		result += (closable ? 'YES' : 'NO') + ' | ' + (newTaskCreatable ? 'YES\n' : 'NO\n');
		if (closable) {
			result += '  result: ' + this.result + ' ' + results + '\n';
			result += '      CLOSE\n';
			result += '  visible: ' + closeBlock.visible + '\n';
			if (closeBlock.visible) {
				result += '  reason: ' + closeBlock.reason + '\n';
				result += '  reasons: ' + closeBlock.reasons + '\n';
				result += '  possiblePaymentDate: ' + closeBlock.possiblePaymentDate + '\n';
			}
			result += '      CREATE\n';
			result += '  visible: ' + createBlock.visible + '\n';
			if (createBlock.visible) {
				result += '  activityDateTime: ' + createBlock.activityDateTime + '\n';
				result += '  communicationType: ' + createBlock.communicationType + '\n';
				result += '  communicationTypes: ' + createBlock.communicationTypes + '\n';
				result += '  ownerId: ' + createBlock.ownerId + '\n';
				result += '  ownerIds: ' + createBlock.ownerIds + '\n';
			}
		}
		return result + '\n';
	}

}