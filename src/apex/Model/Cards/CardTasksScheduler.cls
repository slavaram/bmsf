global class CardTasksScheduler implements Schedulable {

	private static final String JOB_NAME = 'CardTasksScheduler.cls';
	private static final String CRON_EXP = '0 0 12 ? * * *';

	private static final String FROM_ADDRESS = 'mg@molodost.bz';
	private static final String BEFORE_14_TEMPLATE = '<table style="width:700px; margin-left:auto; margin-right:auto;"><tbody><tr><td>' +
				'<p>Ты не поверишь, но вот уже почти [PLACEHOLDER], как ты состоишь в Мастер Группе БМ! Сейчас пришло время, чтобы определиться:' +
				'хочешь ли ты оставаться в Сообществе? Участвовать в мастер-классах нового уровня и глобальных проектах. Или уйдешь в одиночное плавание?</p>' +
				'<a href="http://molodost.bz/mg/card/" target="_top"><b>Я хочу остаться в Мастер Группе &gt;&gt;</b></a>' +
				'<p>За год география участников стала шире, а уровень – выше.  Мы успели много где побывать, завести полезные знакомства' +
				'и подружиться семьями. Мы стали глобальным международным Сообществом, которому по зубам такие проекты, которое год назад нам и не снились…</p>' +
				'</td></tr><tr><td>' +
				'<img src="https://c.cs18.content.force.com/servlet/servlet.ImageServer?id=01511000000IDAQ&amp;oid=00D110000000b1O&amp;lastMod=1403691935000" style="border:1px solid black" width="700px">' +
				'</td></tr><tr><td><br><a href="http://molodost.bz/mg/card/" target="_top"><b>Я хочу остаться в Сообществе Мастер Группа &gt;&gt;</b></a>' +
				'<br><p>Пришло время хотеть большего…</p><p>Перечислить все проекты Мастер Группы невозможно: они находятся в состоянии постоянного развития, изменения и возникновения. Но мы попробуем!</p>' +
				'<p><b>Сейчас среди реализуемых и планируемых в ближайшем будущем следующие проекты Мастер Группы:</b></p><ol type="number">' +
				'<li>Развитие территорий</li><li>Инвестиционный клуб Мастер Группы</li><li>Ассоциация Экспертов Мастер Группы</li>' +
				'<li>Краудфандинг МГ (ищи партнеров и финансы на свои проекты по всей РФ!)</li><li>Франшизы БМ</li>' +
				'<li>Третейский суд МГ (профессиональное и цивилизованное решение спорных ситуаций между участниками Сообщества)</li>' +
				'<li>Вики-база знаний МГ продвинутого уровня (видео, статьи, маркетинг-киты и многое другое!)</li><li>Дома БМ по всей стране</li>' +
				'<li>Премия ТОП-50 (знаем самых достойных в лицо!)</li><li>Знак качества БМ</li><li>Лаборатория Фабрики Мысли</li><li>Школа развития личности с Михаилом Федоренко</li>' +
				'<li>Благотворительные проекты (работа с детьми, эко-проекты и многие другие)</li></ol><a href="http://molodost.bz/mg/card/" target="_top"><b>Я хочу остаться в Мастер Группе &gt;&gt;</b></a>' +
				'<p>Ты можешь участвовать в уже существующих проектах или создать свой. В Мастер Группе твои возможности увеличиваются в разы, умножаясь на количество участников МГ более чем в 80 городах мира.</p>' +
				'<p>Мастер Группа – это среда, в которой ты с большей легкостью и эффективностью ты можешь создавать великое, а еще продолжать бизнес и личностное развитие и просто отлично отдыхать!</p>' +
				'</td></tr><tr><td>' +
				'<img src="https://c.cs18.content.force.com/servlet/servlet.ImageServer?id=01511000000IG0J&amp;oid=00D110000000b1O&amp;lastMod=1403787194000" style="border:1px solid black" width="700px">' +
				'</td></tr><tr><td><br><a href="http://molodost.bz/mg/card/" target="_top"><b>Продлить доступ в Мастер Группу &gt;&gt;</b></a>' +
				'<p>Мы никого не уговариваем, не заставляем и ничего не доказываем. К нам присоединяются только те, кто согласен с нашей позицией.</p>' +
				'<br><br><p>Верю, что каждый сделает правильный выбор,</p><p>Президент Сообщества БМ,</p><p>Евгения Роньжина</p></td></tr></tbody></table>';
	private static final String IN_DATE_TEMPLATE = '<table style="width:700px; margin-left:auto; margin-right:auto;"><tbody><tr>' +
				'<td><p>Добрый день!</p><p>Напоминаем Вам, что ваша карта участника Мастер Группы заканчивается сегодня.</p>' +
				'<p>Для того чтобы продлить свое участие в Сообществе, пожалуйста, сделайте годовой взнос здесь, выбрав свой уровень дохода:</p>' +
				'<a href="http://molodost.bz/mg/card/" target="_top">Я хочу остаться в Сообществе Мастер Группа &gt;&gt;</a><br><br>' +
				'<p>С наилучшими пожеланиями,</p><p>Команда Мастер Группы</p></td></tr></tbody></table>';
	private static final String AFTER_7_TEMPLATE = '<table style="width:700px; margin-left:auto; margin-right:auto;"><tbody><tr><td><p>Привет!</p>' +
				'<p>Вот уже неделя, как ты не в Мастер Группе… Мы скучаем по тебе!</p>' +
				'<p>На этой неделе у нас, как обычно проходит куча интереснейших событий: мастер-классы от лучших профи в своем деле по бизнесу, дружеские встречи, интересный досуг и, конечно, путешествия!</p>' +
				'<a href="http://molodost.bz/mg/card/" target="_top">Посмотри, что интересненького в Мастер Группе &gt;&gt;</a><p>Будем рады, если ты решишь присоединиться к участию в этих событиях!</p>' +
				'<p>Для этого пройди по ссылке: <a href="http://molodost.bz/mg/card/" target="_top">http://molodost.bz/mg/card/</a> и восстанови свое участие в МГ!</p>' +
				'<br><p>С наилучшими пожеланиями,</p><p>Команда Мастер Группы</p></td></tr></tbody></table>';

	public static Boolean run() {
		SavePoint save = Database.setSavepoint();
		try {
			String jobId = System.schedule(CardTasksScheduler.JOB_NAME,
										   CardTasksScheduler.CRON_EXP,
										   new CardTasksScheduler());
			CacheManager.cache(SchedulableManager.JOB_IDS_MAP, new Map<String, String> {CardTasksScheduler.JOB_NAME => jobId});
			return true;
		} catch (Exception ex) {
			Database.rollback(save);
			System.debug(LoggingLevel.ERROR, '[CardTasksScheduler] Unable to run apex job.');
			return false;
		}
	}

	public static Boolean abort() {
		SavePoint save = Database.setSavepoint();
		try {
			System.abortJob(CacheManager.getMap(SchedulableManager.JOB_IDS_MAP).get(CardTasksScheduler.JOB_NAME));
			CacheManager.release(SchedulableManager.JOB_IDS_MAP, new Set<String> {CardTasksScheduler.JOB_NAME});
			return true;
		} catch (Exception ex) {
			Database.rollback(save);
			System.debug(LoggingLevel.ERROR, '[CardTasksScheduler] Unable to abort apex job.');
			return false;
		}
	}

	global void execute(SchedulableContext context) {
		Map<Id, Card__c> lastCards			= new Map<Id, Card__c>();
		List<Card__c> taskCards				= new List<Card__c>();
		List<Card__c> before14cards			= new List<Card__c>();
		List<Card__c> inDateCards			= new List<Card__c>();
		List<Card__c> after7Cards			= new List<Card__c>();
		List<Messaging.SingleEmailMessage> emails	= new List<Messaging.SingleEmailMessage>();
		Id fromAddress = [SELECT Id FROM OrgWideEmailAddress WHERE Address = :FROM_ADDRESS].get(0).Id;
		for (Card__c card : [SELECT Id, AccountId__c, AccountId__r.OwnerId, AccountId__r.Owner.ManagerId, OpportunityId__c, AccountId__r.PersonEmail, EndDate__c, SubType__c
		                     FROM Card__c
		                     WHERE Type__c = 'Карта'
		                     AND SubType__c IN ('Зеленая', 'Черная', 'Золотая')
		                     ORDER BY EndDate__c]) {
			if (lastCards.get(card.AccountId__c) == null) {
				lastCards.put(card.AccountId__c, card);
				if (card.EndDate__c == System.today().addDays(3))	taskCards.add(card);
				if (card.EndDate__c == System.today().addDays(14))	before14cards.add(card);
				if (card.EndDate__c == System.today())				inDateCards.add(card);
				if (card.EndDate__c == System.today().addDays(-7))	after7Cards.add(card);
			}
		}
		assignTasks(taskCards);
		emails.addAll(createEmails(before14cards, BEFORE_14_TEMPLATE, fromAddress));
		emails.addAll(createEmails(inDateCards, IN_DATE_TEMPLATE, fromAddress));
		emails.addAll(createEmails(after7Cards, AFTER_7_TEMPLATE, fromAddress));
		sendEmails(emails);
	}

	private void assignTasks(List<Card__c> cards) {
		Set<Id> seniorManagers	= new Set<Id>();
		List<Id> accountIds		= new List<Id>();
		Map<Id, Id> accounts	= new Map<Id, Id>();
		for (User seniorManager : [SELECT Id FROM User WHERE IsActive = true AND Profile.Name = 'Старший менеджер']) {
			seniorManagers.add(seniorManager.Id);
		}
		for (Card__c card : cards) {
			accountIds.add(card.AccountId__c);
		}
		for (Contact con : [SELECT Id, AccountId FROM Contact WHERE AccountId IN :accountIds]) {
			accounts.put(con.AccountId, con.Id);
		}
		List<Task> toInsert	= new List<Task>();
		Set<Id> managers	= DailyAttendanceManager.getUsersByDay(System.today());
		for (Card__c card : cards) {
			String managerId		= card.AccountId__r.OwnerId;
			if (managers.contains(managerId)) {
				toInsert.add(createTask(managerId, accounts.get(card.AccountId__c), card.OpportunityId__c));
			} else {
				if (card.AccountId__r.Owner.ManagerId != NULL && seniorManagers.contains(card.AccountId__r.Owner.ManagerId)) {
					toInsert.add(createTask(card.AccountId__r.Owner.ManagerId, accounts.get(card.AccountId__c), card.OpportunityId__c));
				} else {
					Integer index = (Integer) Math.floor(Math.random() * seniorManagers.size());
					List<Id> seniorManagersList = new List<Id>(seniorManagers);
					toInsert.add(createTask(seniorManagersList.get(index), accounts.get(card.AccountId__c), card.OpportunityId__c));
				}
			}
		}
		if (!toInsert.isEmpty()) insert toInsert;
	}

	private Task createTask(Id userId, Id contactId, Id opportunityId) {
		return new Task(OwnerId				= userId,
						Subject				= 'Через 3 дня заканчивается карта МГ. Продать новую.',
						ActivityDateTime__c	= System.now().addMinutes(60),
						ActivityDate		= System.today(),
						Goal__c				= '',
						Priority			= '3',
						WhoId				= contactId,
						WhatId				= opportunityId);
	}

	private List<Messaging.SingleEmailMessage> createEmails(List<Card__c> cards, String template, Id fromAddress) {
		List<Messaging.SingleEmailMessage> result = new List<Messaging.SingleEmailMessage>();
		for (Card__c card : cards) {
			Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
			email.setToAddresses(new List<String> {card.AccountId__r.PersonEmail});
			email.setSaveAsActivity(false);
			email.setHtmlBody(template.replace('[PLACEHOLDER]', (card.SubType__c == 'Зеленая' ? '3 месяца' : 'год')));
			email.setOrgWideEmailAddressId(fromAddress);
			result.add(email);
		}
		return result;
	}

	private void sendEmails(List<Messaging.SingleEmailMessage> emails) {
		Messaging.sendEmail(emails);
	}

}