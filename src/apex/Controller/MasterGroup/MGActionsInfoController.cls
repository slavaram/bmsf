public class MGActionsInfoController {

	/* WARNING!
		Говнокод.
		1) Action__c.Name contains types, dates and groups of actions <-- epic fail
	*/

	public List<SelectOption> mGroups { get; set; }
	public String mGroup { get; set; }
	public List<RowElement> mRowElements { get; set; }
	public List<RowElement> mTotalRow { get; set; }
	public Integer mRowsCount { get; set; }
	public String mActionId { get; set; }
	public String mActionName { get; set; }
	public Boolean isOnlineActions { get; set; }

	public List<String> mHeaders { get; set; }
	public List<RowInfoElement> mInfoRows { get; set; }
	public List<String> mTotalInfoRow { get; set; }
	public Integer mInfoRowsCount { get; set; }

	public List<Integer> mVFPageList { get; set; }
	public Integer mCPULimit1 { get; set; }
	public Integer mCPULimit2 { get; set; }

	private String mParentAction;
	private Map<String, String> mActionAndProduct = new Map<String, String>();
	private Map<String, String> mActionAndDay = new Map<String, String>();
	private Map<String, Set<String>> mActionAndMembers = new Map<String, Set<String>>();

	public class RowElement {
		public String actionId { get; set; }
		public String city { get; set; }
		public Integer registred { get; set; }
		public Integer bought { get; set; }
		public Integer attended { get; set; }
		public String rate { get; set; }
	}

	public class RowInfoElement {
		public List<CellElement> cells { get; set; }

		public RowInfoElement(List<CellElement> cells) {
			this.cells = cells;
		}
	}

	public class CellElement {
		public Boolean isTextCell { get; set; }
		public Boolean isTrue { get; set; }
		public String linkValue { get; set; }
		public String textValue { get; set; }
	}

	{
		mGroups = new List<SelectOption>();
		mRowElements = new List<RowElement>();
		mTotalRow = new List<RowElement>();
		mRowsCount = 0;
		mHeaders = new List<String>();
		mInfoRows = new List<RowInfoElement>();
		mTotalInfoRow = new List<String>();
		mInfoRowsCount = 0;
		isOnlineActions = false;

		mVFPageList = new List<Integer>();
		mVFPageList.add(0);
	}

	public MGActionsInfoController() {
		List<Action__c> actions = [SELECT Id, Name
								   FROM Action__c
								   WHERE Name LIKE '%Кураторство%'
								   AND RecordType.Name = 'Группирующее мероприятие'
								   ORDER BY Name];
		for (Action__c action : actions) {
			mGroups.add(new SelectOption(action.Id, action.Name));
		}
		mParentAction = mGroups.get(0).getValue();
		createRowElements();
	}


	public void processActions() {
		mParentAction = mGroup;
		mActionId = null;
		createRowElements();
	}

	private void createRowElements() {
		mRowElements.clear();
		mTotalRow.clear();
		mActionAndMembers.clear();
		List<Action__c> actions = new List<Action__c>();
		if (isOnlineActions) {
			actions = [SELECT Id, Name
					   FROM Action__c
					   WHERE ParentId__c = :mParentAction
					   AND Name LIKE '%Онлайн%'];
		} else  {
			actions = [SELECT Id, Name
					   FROM Action__c
					   WHERE ParentId__c = :mParentAction
					   AND (NOT Name LIKE '%Онлайн%')];
		}
		List<String> actionIds = new List<String>();
		for (Action__c action : actions) {
			actionIds.add(action.Id);
			RowElement rowElement = new RowElement();
			rowElement.actionId = action.Id;
			rowElement.city = action.Name.substringAfterLast('.').trim();
			mRowElements.add(rowElement);
		}
		List<Opportunity> opps = [SELECT Id, StageName, ActionIds__c, AccountId
								  FROM Opportunity
								  WHERE ActionIds__c IN :actionIds];

		Set<String> allMembers = new Set<String>();
		for (RowElement row : mRowElements) {
			Set<String> acountIds = new Set<String>();
			Integer registred = 0;
			Integer bought = 0;
			for (Opportunity opp : opps) {
				if (opp.ActionIds__c == row.actionId) {
					acountIds.add(opp.AccountId);
					registred++;
					if (opp.StageName == 'Оплачено') {
						bought++;
					}
				}
			}
			mActionAndMembers.put(row.actionId, acountIds);
			allMembers.addAll(acountIds);
			row.registred = registred;
			row.bought = bought;
		}

		List<Day__c> days = [SELECT Id, ActionId__c
							 FROM Day__c
							 WHERE ActionId__c IN :actionIds];
		Map<String, Set<String>> actionAndDays = new Map<String, Set<String>>();
		for (RowElement row : mRowElements) {
			Set<String> thisDays = new Set<String>();
			for (Day__c day : days) {
				if (row.actionId == day.ActionId__c) {
					thisDays.add(day.Id);
				}
			}
			actionAndDays.put(row.actionId, thisDays);
		}

		List<DayMember__c> members = [SELECT Id, Day__c, AccountId__c
									  FROM DayMember__c
									  WHERE Day__c IN :days
									  AND IsPassed__c = true];
		Map<String, Set<String>> daysAndMembers = new Map<String, Set<String>>();
		for (Day__c day : days) {
			Set<String> thisMembers = new Set<String>();
			for (DayMember__c member : members) {
				if (day.Id == member.Day__c) {
					thisMembers.add(member.AccountId__c);
				}
			}
			daysAndMembers.put(day.Id, thisMembers);
		}

		for (RowElement row : mRowElements) {
			Set<String> memberIds = new Set<String>();
			for (String dayId : actionAndDays.get(row.actionId)) {
				memberIds.addAll(daysAndMembers.get(dayId));
			}
			row.attended = memberIds.size();
		}

		List<Certification__c> certificates = [SELECT Id, Client__c, DeltaProfit__c
											   FROM Certification__c
											   WHERE Client__c IN :allMembers
											   AND Passed__c = 'Да'
											   AND DeltaProfit__c != null
											   ORDER BY CertificationDate__c DESC];

		Map<String, Set<Certification__c>> actionAndCertificates = new Map<String, Set<Certification__c>>();
		for (RowElement row : mRowElements) {
			Set<Certification__c> thisCertificates = new Set<Certification__c>();
			Set<String> ownerIds = new Set<String>();
			for (Certification__c certificate : certificates) {
				if (mActionAndMembers.get(row.actionId).contains(certificate.Client__c)) {
					if (!ownerIds.contains(certificate.Client__c)) {
						thisCertificates.add(certificate);
					}
					ownerIds.add(certificate.Client__c);
				}
			}
			actionAndCertificates.put(row.actionId, thisCertificates);
		}

		for (RowElement row : mRowElements) {
			Integer totalCertified = 0;
			Decimal profitSumm = 0;
			for (String actionId : actionAndCertificates.keySet()) {
				if (row.actionId == actionId) {
					for (Certification__c certificate : actionAndCertificates.get(actionId)) {
						totalCertified++;
						profitSumm += certificate.DeltaProfit__c;
					}
				}
			}
			Decimal rate = (totalCertified == 0 ? 0 : profitSumm / totalCertified);
			String rateString = String.valueOf(rate);
			rateString = rateString.substring(0, (rateString.length() < 8 ? rateString.length() : 8));
			row.rate = (totalCertified == row.attended ?
						rateString + '' :
						rateString + ' (' + totalCertified + '/' + row.attended + ')');
		}

		Integer totalRegistred = 0;
		Integer totalBought = 0;
		Integer totalAttended = 0;
		for (RowElement row : mRowElements) {
			totalRegistred += row.registred;
			totalBought += row.bought;
			totalAttended = row.attended;
		}
		RowElement totalRow = new RowElement();
		totalRow.registred = totalRegistred;
		totalRow.bought = totalBought;
		totalRow.attended = totalAttended;
		mTotalRow.add(totalRow);

		mRowsCount =  mRowElements.size();
		mCPULimit1 = Limits.getCpuTime();
		mCPULimit2 = Limits.getLimitCpuTime();
	}

	public void loadInfo() {
		mHeaders.clear();
		mInfoRows.clear();
		mTotalInfoRow.clear();
		mActionName = [SELECT Id, Name FROM Action__c WHERE Id = :mActionId].get(0).Name;
		List<Opportunity> opps = [SELECT Id, Name, StageName, Account.Id, Account.Name
								  FROM Opportunity
								  WHERE ActionIds__c = :mActionId
								  ORDER BY ClientAccount__r.Name];
		if (opps.size() == 0) {
			mInfoRowsCount = 0;
			return;
		}
		mHeaders.add('Заявка');
		mHeaders.add('Оплачена');
		mHeaders.add('Клиент');
		List<CellElement> oppCells = new List<CellElement>();
		List<CellElement> isBoughtCells = new List<CellElement>();
		List<CellElement> clientCells = new List<CellElement>();
		for (Opportunity opp : opps) {
			CellElement cell1 = new CellElement();
			CellElement cell2 = new CellElement();
			CellElement cell3 = new CellElement();
			cell1.isTextCell = true;
			cell1.textValue = opp.Name;
			cell1.linkValue = opp.Id;
			oppCells.add(cell1);
			cell2.isTextCell = false;
			if (opp.StageName == 'Оплачено') {
				cell2.isTrue = true;
			} else {
				cell2.isTrue = false;
			}
			isBoughtCells.add(cell2);
			cell3.isTextCell = true;
			cell3.textValue = opp.Account.Name;
			cell3.linkValue = opp.Account.Id;
			clientCells.add(cell3);
		}
		List<Day__c> days = [SELECT Id, ActionId__c, Date__c
							 FROM Day__c
							 WHERE ActionId__c = :mActionId
							 ORDER BY Date__c];
		for (Day__c day : days) {
			mHeaders.add(ApexUtils.dateToString(day.Date__c).substringBeforeLast('.'));
		}
		List<DayMember__c> members = [SELECT AccountId__c, IsPassed__c, Day__c, Day__r.Date__c
									  FROM DayMember__c
									  WHERE OpportunityEvent__r.ActionID__c = :mActionId];

		List<CellElement> isAttendedCells = new List<CellElement>();
		for (Day__c day : days) {
			List<CellElement> dayCell = new List<CellElement>();
			for (CellElement client : clientCells) {
				Boolean isAttended = false;
				CellElement cell = new CellElement();
				cell.isTextCell = false;
				cell.linkValue = client.linkValue;
				for (DayMember__c member : members) {
					if (member.AccountId__c != null && client.linkValue != null) {
						if (member.Day__r.Date__c == day.Date__c && client.linkValue.contains(member.AccountId__c)) {
							cell.isTrue = member.IsPassed__c;
							isAttended = true;
						}
					}
				}
				if (!isAttended) {
					cell.isTrue = false;
				}
				isAttendedCells.add(cell);
			}
		}


		List<Certification__c> certificates = [SELECT Id, Client__c, DeltaProfit__c
											   FROM Certification__c
											   WHERE Client__c IN :mActionAndMembers.get(mActionId)
											   AND Passed__c = 'Да'
											   AND DeltaProfit__c != null
											   ORDER BY CertificationDate__c DESC];
		mHeaders.add('Дельта');
		List<CellElement> rateCells = new List<CellElement>();
		Map<String, String> certificateAndClient = new Map<String, String>();
		Set<String> ownerIds = new Set<String>();
		for (Certification__c certificate : certificates) {
			if (!ownerIds.contains(certificate.Client__c)) {
				CellElement cell = new CellElement();
				cell.isTextCell = true;
				cell.textValue = String.valueOf(certificate.DeltaProfit__c);
				cell.linkValue = certificate.Id;
				rateCells.add(cell);
				certificateAndClient.put(certificate.Id, certificate.Client__c);
			}
			ownerIds.add(certificate.Client__c);
		}

		Integer rowsNumber = oppCells.size();
		Integer daysNumber = mHeaders.size() - 4;
		for (Integer i = 0; i < rowsNumber; i++) {
			List<CellElement> cells = new List<CellElement>();
			cells.add(oppCells.get(i));
			cells.add(isBoughtCells.get(i));
			cells.add(clientCells.get(i));
			for (CellElement cell : isAttendedCells) {
				if (cell.linkValue == clientCells.get(i).linkValue) {
					cells.add(cell);
				}
			}
			Boolean notCertificated = true;
			for (CellElement cell : rateCells) {
				if (certificateAndClient.get(cell.linkValue) == clientCells.get(i).linkValue) {
					cells.add(cell);
					notCertificated = false;
				}
			}
			if (notCertificated) {
				CellElement cell = new CellElement();
				cell.isTextCell = true;
				cell.textValue = '';
				cells.add(cell);
			}
			mInfoRows.add(new RowInfoElement(cells));
		}

		Integer totalInfoNumber = 0;
		Integer totalBought = 0;
		Map<String, Integer> totalAttendedNDay = new Map<String, Integer>();
		for (Integer i = 3; i < mHeaders.size() - 1; i++) {
			totalAttendedNDay.put(mHeaders.get(i), 0);
		}
		for (RowInfoElement infoRow : mInfoRows) {
			totalInfoNumber++;
			if (infoRow.cells.get(1).isTrue) {
				totalBought++;
			}
			for (Integer i = 3; i < mHeaders.size() -1; i++) {
				String dayName = mHeaders.get(i);
				Integer attendedNumber = totalAttendedNDay.get(dayName);
				if (infoRow.cells.get(i).isTrue) {
					attendedNumber++;
				}
				totalAttendedNDay.put(dayName, attendedNumber);
			}
		}

		mTotalInfoRow.add('Итого');
		mTotalInfoRow.add(String.valueOf(totalBought) + ' / ' + String.valueOf(totalInfoNumber));
		mTotalInfoRow.add(' ');
		for (Integer i = 3; i < mHeaders.size() - 1; i++) {
			mTotalInfoRow.add(String.valueOf(totalAttendedNDay.get(mHeaders.get(i))));
		}
		mTotalInfoRow.add(' ');

		mInfoRowsCount = mInfoRows.size();
		mCPULimit1 = Limits.getCpuTime();
		mCPULimit2 = Limits.getLimitCpuTime();
	}

}