public class ServicesInfoController {

	public Day__c				fromDate			{get; set;}
	public Day__c				byDate				{get; set;}
	public List<SelectOption>	groups				{get; private set;}
	public String				groupId				{get; set;}
	public String				tableMessage		{get; set;}
	public List<String>			headers				{get; private set;}
	public List<Row>			rows				{get; private set;}
	public List<Integer>		totalRow			{get; private set;}
	public List<SelectOption>	serviceGroups		{get; private set;}
	public String				serviceGroupId		{get; set;}
	public List<SelectOption>	serviceSubgroups	{get; private set;}
	public String				serviceSubgroupId	{get; set;}
	public String				serviceTableMessage {get; set;}
	public List<String>			serviceHeaders		{get; private set;}
	public List<Row>			serviceRows			{get; private set;}
	public List<Integer>		serviceTotalRow		{get; private set;}

	{
		fromDate			= new Day__c(Date__c = System.today().addDays(-7));
		byDate				= new Day__c(Date__c = System.today());
		groups				= new List<SelectOption>();
		serviceGroups		= new List<SelectOption>();
		serviceSubgroups	= new List<SelectOption>();
		tableMessage		= 'Нажмите "Обновить", чтобы загрузить данные';
		serviceTableMessage = 'Нажмите "Обновить", чтобы загрузить данные';
		headers				= new List<String>();
		headers.add('Образовательное мероприятие');
		headers.add('Колличество заявок');
		headers.add('Сервисный продукт');
		headers.add('Колличество заявок');
		headers.add('Доля');
		serviceHeaders		= new List<String>();
		serviceHeaders.add('Сервисный продукт');
		serviceHeaders.add('Колличество заявок');
		serviceHeaders.add('Образовательное мероприятие');
		serviceHeaders.add('Колличество заявок');
		serviceHeaders.add('Доля');
		rows				= new List<Row>();
		serviceRows			= new List<Row>();
		totalRow			= new List<Integer>();
		serviceTotalRow		= new List<Integer>();
	}

	private class Row {
		public List<Cell> cells {get; private set;}
		public Row(List<Cell> cells) {
			this.cells = cells;
		}
	}

	private class Cell {
		public Boolean isRowSpanedOwer {get; private set;}
		public Integer rowSpanedOwer {get; private set;}
		public Boolean isObject {get; private set;}
		public String link {get; private set;}
		public String name {get; private set;}
		public String value {get; private set;}
	}

	public ServicesInfoController() {
		for (ServicesTrackingProductGroup__c productGroup : ServicesTrackingProductGroup__c.getAll().values()) {
			groups.add(new SelectOption(productGroup.Id__c, productGroup.Name));
		}
		if (groups.size() == 0) {
			tableMessage = 'Не найдены образовательные группы продуктов';
		} else {
			groupId = groups.get(0).getValue();
		}
		List<ProductGroup__c> serviceProductGroups = [SELECT Id, Name
		                                              FROM ProductGroup__c
		                                              WHERE ParentProductGroup__c = :ServicesInfo.ROOT_GROUP_ID
													  ORDER BY Name];
		for (ProductGroup__c productGroup : serviceProductGroups) {
			serviceGroups.add(new SelectOption(productGroup.Id, productGroup.Name));
		}
		if (serviceGroups.size() == 0) {
			serviceTableMessage = 'Не найдены сервисные группы продуктов';
		} else {
			serviceGroupId = serviceGroups.get(0).getValue();
			processSubgroups();
		}
	}

	public void processSubgroups() {
		if (serviceTableMessage != 'Нажмите "Обновить", чтобы загрузить данные') serviceTableMessage = null;
		serviceSubgroups.clear();
		List<ProductGroup__c> serviceProductSubgroups = [SELECT Id, Name
		                                                 FROM ProductGroup__c
		                                                 WHERE ParentProductGroup__c = :serviceGroupId
		                                                 ORDER BY Name];
		for (ProductGroup__c productGroup : serviceProductSubgroups) {
			serviceSubgroups.add(new SelectOption(productGroup.Id, productGroup.Name));
		}
		serviceSubgroups.add(new SelectOption('012345678901234567', '-все-'));
		if (serviceSubgroups.size() == 0) {
			serviceTableMessage = 'Не найдены сервисные подгруппы продуктов';
		} else {
			serviceSubgroupId = serviceSubgroups.get(0).getValue();
		}
	}

	public void processEducationTable() {
		tableMessage = null;
		rows.clear();
		List<ServicesInfo.Bean> beans = ServicesInfo.createBeans(fromDate.Date__c, byDate.Date__c, null, groupId);
		if (beans.size() == 0) {
			tableMessage = 'Нет заявок на сервисные продукты после покупки образовательных продуктов выбранной группы за данный период';
			return;
		}
		buildEducationRows(beans);
	}

	private void buildEducationRows(List<ServicesInfo.Bean> beans) {
		rows.clear();
		Map<Id, List<ServicesInfo.Bean>> sortedBeans = sortBeansByAction(beans);
		Boolean isFirstRow = true;
		for (Id educationActionId : sortedBeans.keySet()) {
			Boolean isRowGroup = true;
			List<ServicesInfo.Bean> bundle = sortedBeans.get(educationActionId);
			Map<Id, List<ServicesInfo.Bean>> aggregatedBeans = sortedBeansByServiceProduct(bundle);
			for (Id serviceProductId : aggregatedBeans.keySet()) {
				List<ServicesInfo.Bean> subbundle = aggregatedBeans.get(serviceProductId);
				rows.add(createEducationRow(subbundle.get(0),
											bundle.size(),
											!isRowGroup,
											aggregatedBeans.size(),
											subbundle.size()));
				isRowGroup = false;
			}
		}
		calculateEducationTotals();
	}

	public void processServiceTable() {
		serviceTableMessage = null;
		serviceRows.clear();
		List<ServicesInfo.Bean> beans = new List<ServicesInfo.Bean>();
		if (serviceSubgroupId == '012345678901234567') {
			beans.addAll(ServicesInfo.createBeans(fromDate.Date__c, byDate.Date__c, serviceGroupId, null));
		} else {
			beans.addAll(ServicesInfo.createBeans(fromDate.Date__c, byDate.Date__c, serviceSubgroupId, null));
		}
		if (beans.size() == 0) {
			serviceTableMessage = 'Нет заявок на сервисные продукты после покупки образовательных продуктов выбранной группы за данный период';
			return;
		}
		buildServiceRows(beans);
	}

	private void buildServiceRows(List<ServicesInfo.Bean> beans) {
		serviceRows.clear();
		Map<Id, List<ServicesInfo.Bean>> sortedBeans = sortedBeansByServiceProduct(beans);
		Boolean isFirstRow = true;
		for (Id productId : sortedBeans.keySet()) {
			Boolean isRowGroup = true;
			List<ServicesInfo.Bean> bundle = sortedBeans.get(productId);
			Map<Id, List<ServicesInfo.Bean>> aggregatedBeans = sortBeansByAction(bundle);
			for (Id educationActionId : aggregatedBeans.keySet()) {
				List<ServicesInfo.Bean> subbundle = aggregatedBeans.get(educationActionId);
				serviceRows.add(createServiceRow(subbundle.get(0),
										  bundle.size(),
										  !isRowGroup,
										  aggregatedBeans.size(),
										  subbundle.size()));
				isRowGroup = false;
			}
		}
		calculateServiceTotals();
	}

	private Map<Id, List<ServicesInfo.Bean>> sortBeansByAction(List<ServicesInfo.Bean> beans) {
		Map<Id, List<ServicesInfo.Bean>> result = new  Map<Id, List<ServicesInfo.Bean>>();
		Set<String> educationActionIds = new Set<String>();
		for (ServicesInfo.Bean bean : beans) {
			educationActionIds.add(bean.educationActionId);
		}
		List<String> educationActionIdsSorted = new List<String>();
		educationActionIdsSorted.addAll(educationActionIds);
		educationActionIdsSorted.sort();
		for (String educationActionId : educationActionIdsSorted) {
			List<ServicesInfo.Bean> beansBundle = new List<ServicesInfo.Bean>();
			for (ServicesInfo.Bean bean : beans) {
				if (bean.educationActionId == educationActionId) {
					beansBundle.add(bean);
				}
			}
			result.put(educationActionId, beansBundle);
		}
		return result;
	}

	private Map<Id, List<ServicesInfo.Bean>> sortedBeansByServiceProduct(List<ServicesInfo.Bean> beans) {
		Map<Id, List<ServicesInfo.Bean>> result = new  Map<Id, List<ServicesInfo.Bean>>();
		Set<String> productIds = new Set<String>();
		for (ServicesInfo.Bean bean : beans) {
			productIds.add(bean.serviceProductId);
		}
		List<String> productIdsSorted = new List<String>();
		productIdsSorted.addAll(productIds);
		productIdsSorted.sort();
		for (String productId : productIdsSorted) {
			List<ServicesInfo.Bean> beansBundle = new List<ServicesInfo.Bean>();
			for (ServicesInfo.Bean bean : beans) {
				if (bean.serviceProductId == productId) {
					beansBundle.add(bean);
				}
			}
			result.put(productId, beansBundle);
		}
		return result;
	}

	private Row createEducationRow(ServicesInfo.Bean bean, Integer opportunitiesGroupCount, Boolean isRowSpanedOwer, Integer rowsSpanedOwer, Integer opportunitiesCount) {
		List<Cell> cells = new List<Cell>();
		Cell educationActionCell = new Cell();
		educationActionCell.isRowSpanedOwer = isRowSpanedOwer;
		educationActionCell.rowSpanedOwer = rowsSpanedOwer;
		educationActionCell.isObject = true;
		educationActionCell.link = bean.educationActionId;
		educationActionCell.name = bean.educationActionName;
		cells.add(educationActionCell);
		Cell groupCountCell = new Cell();
		groupCountCell.isRowSpanedOwer = isRowSpanedOwer;
		groupCountCell.rowSpanedOwer = rowsSpanedOwer;
		groupCountCell.isObject = false;
		groupCountCell.value = String.valueOf(opportunitiesGroupCount);
		cells.add(groupCountCell);
		Cell serviceProductCell = new Cell();
		serviceProductCell.isRowSpanedOwer = false;
		serviceProductCell.rowSpanedOwer = 0;
		serviceProductCell.isObject = true;
		serviceProductCell.link = bean.serviceProductId;
		serviceProductCell.name = bean.serviceProductName;
		cells.add(serviceProductCell);
		Cell countCell = new Cell();
		countCell.isRowSpanedOwer = false;
		countCell.rowSpanedOwer = 0;
		countCell.isObject = false;
		countCell.value = String.valueOf(opportunitiesCount);
		cells.add(countCell);
		Cell rate = new Cell();
		rate.isRowSpanedOwer = false;
		rate.rowSpanedOwer = 0;
		rate.isObject = false;
		rate.value = '';
		cells.add(rate);
		return new Row(cells);
	}

	private Row createServiceRow(ServicesInfo.Bean bean, Integer opportunitiesGroupCount, Boolean isRowSpanedOwer, Integer rowsSpanedOwer, Integer opportunitiesCount) {
		List<Cell> cells = new List<Cell>();
		Cell serviceProductCell = new Cell();
		serviceProductCell.isRowSpanedOwer = isRowSpanedOwer;
		serviceProductCell.rowSpanedOwer = rowsSpanedOwer;
		serviceProductCell.isObject = true;
		serviceProductCell.link = bean.serviceProductId;
		serviceProductCell.name = bean.serviceProductName;
		cells.add(serviceProductCell);
		Cell groupCountCell = new Cell();
		groupCountCell.isRowSpanedOwer = isRowSpanedOwer;
		groupCountCell.rowSpanedOwer = rowsSpanedOwer;
		groupCountCell.isObject = false;
		groupCountCell.value = String.valueOf(opportunitiesGroupCount);
		cells.add(groupCountCell);
		Cell educationActionCell = new Cell();
		educationActionCell.isRowSpanedOwer = false;
		educationActionCell.rowSpanedOwer = 0;
		educationActionCell.isObject = true;
		educationActionCell.link = bean.educationActionId;
		educationActionCell.name = bean.educationActionName;
		cells.add(educationActionCell);
		Cell countCell = new Cell();
		countCell.isRowSpanedOwer = false;
		countCell.rowSpanedOwer = 0;
		countCell.isObject = false;
		countCell.value = String.valueOf(opportunitiesCount);
		cells.add(countCell);
		Cell rate = new Cell();
		rate.isRowSpanedOwer = false;
		rate.rowSpanedOwer = 0;
		rate.isObject = false;
		rate.value = '';
		cells.add(rate);
		return new Row(cells);
	}

	private void calculateEducationTotals() {
		Decimal total = 0;
		for (Row row : rows) {
			total += Integer.valueOf(row.cells.get(3).value);
		}
		for (Row row : rows) {
			Decimal rate = Decimal.valueOf(row.cells.get(3).value)*100;
			rate = rate.divide(total, 2, System.RoundingMode.UP);
			row.cells.get(4).value = (String.valueOf(rate)) + ' %';
		}
		totalRow.clear();
		totalRow.add(Integer.valueOf(total));
	}

	private void calculateServiceTotals() {
		Decimal total = 0;
		for (Row row : serviceRows) {
			total += Integer.valueOf(row.cells.get(3).value);
		}
		for (Row row : serviceRows) {
			Decimal rate = Decimal.valueOf(row.cells.get(3).value)*100;
			rate = rate.divide(total, 2, System.RoundingMode.UP);
			row.cells.get(4).value = (String.valueOf(rate)) + ' %';
		}
		serviceTotalRow.clear();
		serviceTotalRow.add(Integer.valueOf(total));
	}

}