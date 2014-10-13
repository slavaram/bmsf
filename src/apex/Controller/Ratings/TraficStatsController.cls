public with sharing class TraficStatsController {
	static final private String 		MODE_MANAGERS 			= 'byManagers',
										MODE_GROUP 				= 'byGroups',
										MODE_SDM                = 'bySDMs',
										
										PERIOD_TODAY 			= 'today',
										PERIOD_YESTERDAY 		= 'yesterday',
										PERIOD_WEEK 			= 'thisWeek',
										PERIOD_PREVIOUS_WEEK 	= 'prevWeek',
										PERIOD_MONTH 			= 'thisMonth',
										PERIOD_PREVIOUS_MONTH 	= 'prevMonth';
										
	public String 						ratingDate { get; set; }
	public String 						mode { get; set; }
	public String 						managerGroup { get; set; }
	public String                       SDM { get; set; }
	
	public List<SelectOption> 			ratingDates { get; set; }
	public List<SelectOption> 			modes { get; set; }
	public List<SelectOption> 			managerGroups { get; set; }
	public List<SelectOption> 			SDMs { get; set; }

	public List<TraficStats.UserStats> 	usersStats { get; set; }
	public TraficStats.UserStats 		score { get; set; }

	public TraficStatsController (){
		ratingDates = new List<SelectOption>();
		ratingDates.add (new SelectOption (PERIOD_TODAY, 'Сегодня'));
		ratingDates.add (new SelectOption (PERIOD_YESTERDAY, 'Вчера'));
		ratingDates.add (new SelectOption (PERIOD_WEEK,'Текущая неделя'));
		ratingDates.add (new SelectOption (PERIOD_PREVIOUS_WEEK, 'Прошлая неделя'));
		ratingDates.add (new SelectOption (PERIOD_MONTH, 'Текущий месяц'));
		ratingDates.add (new SelectOption (PERIOD_PREVIOUS_MONTH, 'Прошлый месяц'));
		
		modes = new List<SelectOption>();
		modes.add (new SelectOption (MODE_MANAGERS, 'По менеджерам'));
		modes.add (new SelectOption (MODE_GROUP, 'По группам'));
		modes.add (new SelectOption (MODE_SDM, 'По отделам'));
		
		List<User> seniorManagers = [
			select LastName, Id
			from User
			where
			     isActive = true
			 and ProfileId = '00eb0000000QgSJ'
			 and id != '005b0000001Nxzk' // Сагун1
		];
		
		managerGroups = new List<SelectOption>();
		for (User item : seniorManagers) {
			managerGroups.add(new SelectOption(item.Id, item.LastName));
		}
		managerGroups.add(new SelectOption('005b0000000NiKS', 'none'));
				
		// По умолчанию
		ratingDate 		= PERIOD_TODAY;
		mode 			= MODE_MANAGERS;
		managerGroup 	= '005b0000000NiKS';
		SDM             = '005b0000000NiKS';
		
		RefreshRating ();
	}
	
	public void refreshRating (){
		Date startDate, endDate;
		
		if (ratingDate == PERIOD_TODAY){	
			startDate 	= Date.today ();
			endDate 	= Date.today ();
		} else if (ratingDate == PERIOD_YESTERDAY){
			startDate 	= Date.today ().addDays (-1);
			endDate 	= Date.today ().addDays (-1);
		} else if (ratingDate == PERIOD_WEEK){
			startDate 	= Date.today ().toStartOfWeek ();
			endDate 	= Date.today ();
		} else if (ratingDate == PERIOD_PREVIOUS_WEEK){
			startDate 	= Date.today ().toStartOfWeek ().addDays (-7);
			endDate 	= Date.today ().toStartOfWeek ().addDays (-1);
		} else if (ratingDate == PERIOD_MONTH){
			startDate 	= Date.today ().toStartOfMonth ();
			endDate 	= Date.today ();
		} else if (ratingDate == PERIOD_PREVIOUS_MONTH){
			startDate 	= Date.today ().toStartOfMonth ().addMonths (-1);
			endDate 	= Date.today ().toStartOfMonth ().addDays (-1);
		}
		
		if (mode == MODE_MANAGERS){
			usersStats 	= new TraficStats ().getAllusersStats (startDate, endDate, (Id) managerGroup);
			score 		= usersStats.remove (usersStats.size () - 1);
		} else if (mode == MODE_GROUP){
			TraficStats ts = new TraficStats ();
			List<TraficStats.UserStats> tmp = ts.getAllusersStats (startDate, endDate, (Id) managerGroup);
			usersStats 	= ts.getManagerStats (tmp, (Id) managerGroup, startDate, endDate);
			score 		= usersStats.remove (usersStats.size () - 1);
		} else if (mode == MODE_SDM) {
			TraficStats ts = new TraficStats();
			List<TraficStats.UserStats> tmp = ts.getAllusersStats (startDate, endDate, (Id) managerGroup);
			usersStats 	= ts.getSDMStats (tmp, (Id) SDM, startDate, endDate);
			score 		= usersStats.remove (usersStats.size () - 1);
		}
	}
}