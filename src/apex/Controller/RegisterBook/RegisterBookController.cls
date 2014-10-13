public class RegisterBookController {

	public List<SelectOption> mGroups			{get; set;}
	public Id mGroup							{get; set;}
	public List<SelectOption> mUsers			{get; set;}
	public String mUser							{get; set;}
	public List<DailyAttendance__c> mRegisters	{get; set;}
	public String mToday						{get; set;}
	public List<SelectOption> mRegisterValues	{get; set;}
	public List<SelectOption> mReasonValues		{get; set;}
	public List<SelectOption> mRegistrationDates {get; set;}
	public String mRegistrationDate				{get; set;}
	public List<RowElement> mRows				{get; set;}
	public List<HeaderElement> mHeaders				{get; set;}
	public String mTableBody					{get; set;}
	private PageReference mPageRef;

	public Day__c mFromDate						{get; set;}
	public Day__c mByDate						{get; set;}
	public Day__c mFromLeaveDate				{get; set;}
	public Day__c mToLeaveDate					{get; set;}

	public Boolean mIsEditMode					{get; set;}

	public final static String SENIOR_MANAGER_TAG = 'Старший менеджер';
	public final static String MANAGER_TAG = 'Менеджер';
	public final static String NO_RECORD_VALUE			{get; set;}
	public final static String RECORD_VALUE_YES			{get; set;}
	public final static String RECORD_VALUE_NO			{get; set;}
	public final static String RECORD_VALUE_MAYBE		{get; set;}
	public final static String RECORD_REASON_WEEKEND	{get; set;}
	public final static Integer DAYS_FORWARD			{get; set;}
	public final static String CSS_HEADER_CLASS			{get; set;}

	public class RowElement {
		public List<CellElement> cells {get; set;}
		public RowElement(List<CellElement> cells) {
			this.cells = cells;
		}
	}

	public class HeaderElement {
		public String headerValue	{get; set;}
		public String cssClassName	{get; set;}
		public HeaderElement(String headerValue, String cssClassName) {
			this.headerValue = headerValue;
			this.cssClassName = cssClassName;
		}
	}

	public class CellElement {
		public Boolean isUser	{get; set;}
		public String name		{get; set;}
		public String imgUrl	{get; set;}
		public String textUrl	{get; set;}
		public String register	{get; set;}
		public String reason	{get; set;}
	}
	
	static {
		NO_RECORD_VALUE = '';
		RECORD_VALUE_YES = 'Явка';
		RECORD_VALUE_NO = 'Неявка';
		RECORD_VALUE_MAYBE = 'Явка (без учета задач)';
		RECORD_REASON_WEEKEND = 'Выходной';
		DAYS_FORWARD = 6;
		CSS_HEADER_CLASS = 'Weekend';
	}

	{
		mGroups = new List<SelectOption>();
		mUsers = new List<SelectOption>();
		mRegisters = new List<DailyAttendance__c>();
		mToday = System.now().day() + ' ' + ApexUtils.getMonthNameRus(System.now().month(), false) + ' ' + System.now().year();
		mRegisterValues = ApexUtils.getObjectPickListFieldValues(new DailyAttendance__c(), 'Register__c');
		mReasonValues = ApexUtils.getObjectPickListFieldValues(new DailyAttendance__c(), 'Reason__c');
		mRegistrationDates = new List<SelectOption>();
		mRows = new List<RowElement>();
		mHeaders = new List<HeaderElement>();

		mPageRef = new PageReference('/apex/RegisterBook');
		mPageRef.setRedirect(true);

		mFromDate = new Day__c(Date__c = System.today().addDays(-DAYS_FORWARD));
		mByDate = new Day__c(Date__c = System.today());
		mFromLeaveDate = new Day__c(Date__c = System.today());
		mToLeaveDate = new Day__c(Date__c = System.today().addDays(DAYS_FORWARD));
	}

	public RegisterBookController() {
		setMode();
		List<User> groups = [SELECT Id, Name
							 FROM User
							 WHERE Profile.Name = :TaskAttachController.SENIOR_MANAGER_TAG
							 AND IsActive = true
							 ORDER BY Name];
		if (groups.size() > 0) {
			for (User seniorManager : groups) {
				SelectOption option = new SelectOption(seniorManager.Id, seniorManager.Name);
				mGroups.add(option);
			}
			mGroups.add(new SelectOption('012345678901234567', '--- Все ---' ));
			mGroup = mGroups.get(0).getValue();
		}
		Date dateValue = System.today();
		while (dateValue <= System.today().addDays(DAYS_FORWARD)) {
			mRegistrationDates.add(new SelectOption(String.valueOf(dateValue), ApexUtils.dateToString(dateValue).substringBeforeLast('.')));
			dateValue = dateValue.addDays(1);
		}
		mRegistrationDate = String.valueOf(System.today());
		processGroup();
	}

	public void processGroup() {
		mUsers.clear();
		List<User> users = getUsersInGroup(mGroup);
		for (User use : users) {
			mUsers.add(new SelectOption(use.Id, use.Name));
		}
		mRegisters.clear();
		mRegisters = getRegistersElements(users);
		processDates(users);
	}

	public void processDates() {
		List<User> users = getUsersInGroup(mGroup);
		processDates(users);
	}

	private void processDates(List<User> users) {
		if (mFromDate.Date__c > mByDate.Date__c) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Неверные форматы дат'));
			return;
		}
		mHeaders.clear();
		mHeaders.add(new HeaderElement('Менеджеры (' + mUsers.size()  + ')', ''));
		Integer daysCount = mFromDate.Date__c.daysBetween(mByDate.Date__c);
		for (Integer i = 0; i <= daysCount; i++) {
			Date day = mFromDate.Date__c.addDays(i);
			if (ApexUtils.isWeekend(day)) {
				mHeaders.add(new HeaderElement(ApexUtils.dateToString(day).substringBeforeLast('.'), CSS_HEADER_CLASS));
			} else {
				mHeaders.add(new HeaderElement(ApexUtils.dateToString(day).substringBeforeLast('.'), ''));
			}
		}
		mRows.clear();
		List<List<CellElement>>  calendarStructure = getCalendarElements(users, mFromDate.Date__c, mByDate.Date__c);
		for (List<CellElement> row : calendarStructure) {
			mRows.add(new RowElement(row));
		}
	}

	public PageReference downloadCalendar() {
		String tableBody = '<body><table>';
		tableBody += '<tr><td>ФИО</td><td>Дата отсутствия</td><td>Причина невыхода</td><td>Старший менеджер</td></tr>';
		List<DailyAttendance__c> registers = [SELECT UserId__r.FirstName, UserId__r.LastName, UserId__r.fatherName__c, Day__c, Reason__c,
		                                      		UserId__r.Manager.FirstName, UserId__r.Manager.LastName, UserId__r.Manager.fatherName__c
		                                      FROM DailyAttendance__c
		                                      WHERE Register__c = :RECORD_VALUE_NO
		                                      AND Day__c >= :mFromDate.Date__c
		                                      AND Day__c <= :mByDate.Date__c
		                                      AND UserId__c IN :getUsersInGroup(mGroup)
		                                      ORDER BY Day__c, UserId__r.Manager.Name, UserId__r.Name];
		for (DailyAttendance__c register : registers) {
			tableBody += '<tr><td>' + register.UserId__r.LastName + ' ' + register.UserId__r.FirstName + ' ' + register.UserId__r.fatherName__c + '</td><td>' +
					String.valueOf(register.Day__c).substringBefore(' ') + '</td><td>' +
					register.Reason__c + '</td><td>' +
					register.UserId__r.Manager.LastName + ' ' + register.UserId__r.Manager.FirstName + ' ' + register.UserId__r.Manager.fatherName__c + '</td></tr>';
		}
		tableBody += '</table></body>';
		PageReference pageRef = new PageReference('/apex/RegisterBookDownload?tableBody=' + tableBody);
		return pageRef;
	}

	public void processRegisters() {
		mRegisters.clear();
		List<User> users = getUsersInGroup(mGroup);
		mRegisters = getRegistersElements(users);
	}

	public PageReference saveRegisters() {
		insert mRegisters;
		return mPageRef;
	}

	public PageReference saveLeaveRegister() {
		if (mFromLeaveDate.Date__c > mToLeaveDate.Date__c) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Неверные форматы дат'));
			return null;
		}
		if (mFromLeaveDate.Date__c < System.today()) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Нельзя отмечать за прошедшие даты'));
			return null;
		}
		Integer daysBetween = mFromLeaveDate.Date__c.daysBetween(mToLeaveDate.Date__c);
		List<DailyAttendance__c> toInsert = new List<DailyAttendance__c>();
		for (Integer i = 0; i <= daysBetween; i++) {
			DailyAttendance__c record = new DailyAttendance__c(Day__c = mFromLeaveDate.Date__c.addDays(i),
															   UserId__c = mUser,
															   Register__c = RECORD_VALUE_NO,
															   Reason__c = 'Отпуск');
			toInsert.add(record);
		}
		insert toInsert;
		return mPageRef;
	}

	private void setMode() {
		User currentUser = [SELECT Profile.Id
							FROM User
							WHERE Id = :UserInfo.getUserId()];
		String currentProfile = (String) currentUser.Profile.Id;
		Map<String, RegistringProfiles__c> profiles = RegistringProfiles__c.getAll();
		Set<String> profileIds = new Set<String>();
		for (String profileName : profiles.keySet()) {
			profileIds.add(profiles.get(profileName).ProfileId__c);
		}
		if (profileIds.contains(currentProfile)) {
			mIsEditMode = true;
		} else {
			mIsEditMode = false;
		}
	}

	private List<User> getUsersInGroup(String groupId) {
		if (groupId == '012345678901234567') {
			return [SELECT Id, Name, SmallPhotoUrl
			        FROM User
			        WHERE Profile.Name = :TaskAttachController.MANAGER_TAG
			        AND IsActive = true
			        ORDER BY Name];
		} else {
			return [SELECT Id, Name, SmallPhotoUrl
			        FROM User
			        WHERE Profile.Name = :TaskAttachController.MANAGER_TAG
			        AND IsActive = true
			        AND ManagerId = :groupId
			        ORDER BY Name];
		}
	}

	private List<DailyAttendance__c> getRegistersElements(List<User> users) {
		List<DailyAttendance__c> result = new List<DailyAttendance__c>();
		List<DailyAttendance__c> records = [SELECT Day__c, UserId__c, Register__c, Reason__c
											FROM DailyAttendance__c
											WHERE Day__c = :Date.valueOf(mRegistrationDate)
											AND UserId__c IN :users];
		for (User use : users) {
			DailyAttendance__c userRecord;
			for (DailyAttendance__c record : records) {
				if (use.Id == record.UserId__c) {
					userRecord = new DailyAttendance__c(Day__c = record.Day__c, 
														UserId__c = record.UserId__c, 
														Register__c = record.Register__c,
														Reason__c = record.Reason__c);
					result.add(userRecord);
				}
			}
			if (userRecord == null) {
				if (ApexUtils.isWeekend(Date.valueOf(mRegistrationDate))) {
					userRecord = new DailyAttendance__c(Day__c = Date.valueOf(mRegistrationDate),
													    UserId__c = use.Id,
													    Register__c = RECORD_VALUE_NO,
													    Reason__c = RECORD_REASON_WEEKEND);
				} else {
					userRecord = new DailyAttendance__c(Day__c = Date.valueOf(mRegistrationDate),
													    UserId__c = use.Id,
													    Register__c = RECORD_VALUE_YES);
				}
				result.add(userRecord);
			}
		}
		return result;
	}

	private List<List<CellElement>> getCalendarElements(List<User> users, Date fromDate, Date toDate) {
		List<DailyAttendance__c> records = [SELECT Day__c, UserId__c, Register__c, Reason__c
											FROM DailyAttendance__c
											WHERE UserId__c IN :users
											AND Day__c >= :fromDate
											AND Day__c <= :toDate];
		Map<Id, Map<Date, DailyAttendance__c>> userAndRecords = new Map<Id, Map<Date, DailyAttendance__c>>();
		for (DailyAttendance__c record : records) {
			Map<Date, DailyAttendance__c> userRecords = userAndRecords.get(record.UserId__c);
			if (userRecords == null) {
				Map<Date, DailyAttendance__c> newUserRecords = new Map<Date, DailyAttendance__c>();
				newUserRecords.put(record.Day__c, record);
				userAndRecords.put(record.UserId__c, newUserRecords);
			} else {
				userRecords.put(record.Day__c, record);
				userAndRecords.put(record.UserId__c, userRecords);
			}
		}
		List<List<CellElement>> result = new List<List<CellElement>>();
		for (User use : users) {
			List<CellElement> row = new List<CellElement>();
			CellElement userCell = new CellElement();
			userCell.isUser = true;
			userCell.name = use.Name;
			userCell.textUrl = use.Id;
			userCell.imgUrl = use.SmallPhotoUrl;
			row.add(userCell);
			Map<Date, DailyAttendance__c> userRecords = userAndRecords.get(use.Id);
			Date dateValue = mFromDate.Date__c;
			while (dateValue <= mByDate.Date__c) {
				if (userRecords == null) {
					CellElement recordCell = new CellElement();
					recordCell.isUser = false;
					recordCell.register = NO_RECORD_VALUE;
					row.add(recordCell);
				} else {
					DailyAttendance__c record = userRecords.get(dateValue);
					CellElement recordCell = new CellElement();
					if (record == null) {
						recordCell.isUser = false;
						recordCell.register = NO_RECORD_VALUE;
					} else {
						recordCell.isUser = false;
						recordCell.register = record.Register__c;
						recordCell.reason = record.Reason__c;
					}
					row.add(recordCell);
				}
				dateValue = dateValue.addDays(1);
			}
			result.add(row);
		}
		return result;
	}

}