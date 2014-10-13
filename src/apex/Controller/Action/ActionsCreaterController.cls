public class ActionsCreaterController {

	/*
		Custom logic!
	*/

	public List<SelectOption> mActivities { get; set; }
	public String mActivity { get; set; }
	public List<SelectOption> mTypes { get; set; }
	public String mStartReg { get; set; }
	public String mStartPay { get; set; }


	public String mName0 { get; set; }
	public String mType { get; set; }
	public Integer mPrice0 { get; set; }

	public String mName1 { get; set; }
	public Boolean mIsIn1 { get; set; }
	public Integer mPrice1 { get; set; }
	public String mCity1 { get; set; }
	public String mStartDate1 { get; set; }
	public String mEndDate1 { get; set; }
	public String mEndReg1 { get; set; }
	public String mEndPay1 { get; set; }

	public String mName2 { get; set; }
	public Boolean mIsIn2 { get; set; }
	public Integer mPrice2 { get; set; }
	public String mCity2 { get; set; }
	public String mStartDate2 { get; set; }
	public String mEndDate2 { get; set; }
	public String mEndReg2 { get; set; }
	public String mEndPay2 { get; set; }


	{
		mActivities = new List<SelectOption>();
		mActivities.add(new SelectOption('0', 'Вебинар'));
		mActivities.add(new SelectOption('1', 'Региональные МК'));
		mActivities.add(new SelectOption('2', 'МГ МК'));
		mTypes = new List<SelectOption>();
		mTypes.add(new SelectOption('0', 'он-лайн'));
		mTypes.add(new SelectOption('1', 'оф-лайн'));
		mTypes.add(new SelectOption('2', 'он-лайн/оф-лайн'));
		mStartReg = ApexUtils.dateToString(System.today());
		mStartPay = ApexUtils.dateToString(System.today());
		mStartReg += ' 08:00';
		mStartPay += ' 08:00';
		mPrice0 = 0;
		mPrice1 = 0;
		mPrice2 = 0;
		mStartDate1 = ApexUtils.dateToString(System.today());
		mEndDate1 = ApexUtils.dateToString(System.today());
		mStartDate1 += ' 08:00';
		mEndDate1 += ' 08:00';
		mEndReg1 = ApexUtils.dateToString(System.today());
		mEndReg1 += ' 08:00';
		mEndPay1 = ApexUtils.dateToString(System.today());
		mEndPay1 += ' 08:00';
		mStartDate2 = mStartDate1;
		mEndDate2 = mEndDate1;
		mEndReg2 = mEndReg1;
		mEndPay2 = mEndPay1;
	}

	public PageReference createAction() {
		if (mActivity == null) {
			return null;
		}
		if (mActivity == '0') {
			if (mTypes == null || mName0 == null || mType == null || mPrice0 == null) {
				return null;
			}
		} else if (mActivity == '1') {
			if (mName1 == null || mIsIn1 == null || mPrice1 == null || mCity1 == null ||
				mStartDate1 == null || mEndDate1 == null || mEndReg1 == null || mEndPay1 == null) {
				return null;
			}
		} else {
			if (mName2 == null || mIsIn2 == null || mPrice2 == null || mCity2 == null ||
				mStartDate2 == null || mEndDate2 == null || mEndReg2 == null || mEndPay2 == null) {
				return null;
			}
		}
		Action__c action = new Action__c(MegaplanLink__c = 'https://molodostbz.megaplan.ru/task/1029044/card/?fromList=1029044',
										 IsActive__c = true,
										 AvailableOnSite__c = true,
										 RegistrationStartDate__c = stringToDatetime(mStartReg),
										 PaymentStartDate__c = stringToDatetime(mStartPay));
		Action__c actionOff;
		action.RecordTypeId = [SELECT Id FROM RecordType WHERE Name = 'Родительское мероприятие'].get(0).Id;
		if (mActivity == '0') {
			action.Name = mName0;
			action.Type__c = (mPrice0 == 0 ? 'Бесплатное' : 'Платное');
			action.CityId__c = getCityId('Москва');
			action.FormOf__c = 'он-лайн';
			action.StartDate__c = Date.valueOf(stringToDatetime('01.01.2014 20:00'));
			action.StartTime__c = '20:00';
			action.EndDate__c = Date.valueOf(stringToDatetime('01.07.2014 24:00'));
			action.EndTime__c = '24:00';
			action.RegistrationStartDate__c = Date.valueOf(stringToDatetime('25.07.2014 12:00'));
			action.PaymentStartDate__c = Date.valueOf(stringToDatetime('25.07.2014 12:00'));
			action.RegistrationEndDate__c = Date.valueOf(stringToDatetime('01.01.2100 23:59'));
			action.PaymentOldDate__c = Date.valueOf(stringToDatetime('01.01.2100 23:59'));
			actionOff = new Action__c(MegaplanLink__c = 'https://molodostbz.megaplan.ru/task/1029044/card/?fromList=1029044',
									  IsActive__c = true,
									  AvailableOnSite__c = true,
									  RecordTypeId = [SELECT Id FROM RecordType WHERE Name = 'Родительское мероприятие'].get(0).Id,
									  Name = action.Name,
									  Type__c = action.Type__c,
									  CityId__c = action.CityId__c,
									  FormOf__c = 'оф-лайн',
									  StartDate__c = action.StartDate__c,
									  StartTime__c = action.StartTime__c,
									  EndDate__c = action.EndDate__c,
									  EndTime__c = action.EndTime__c,
									  RegistrationStartDate__c = action.RegistrationStartDate__c,
									  PaymentStartDate__c = action.PaymentStartDate__c,
									  RegistrationEndDate__c = Date.valueOf(stringToDatetime('01.07.2014 22:00')),
									  PaymentOldDate__c = Date.valueOf(stringToDatetime('01.07.2014 22:00')));
			Id productId = getProductId(mPrice0);
			if (mType == '0' || mType == '2') {
				insert action;
				insert new AvailableEvents__c(ActionId__c = action.Id, Product__c = productId);
				if (mType == '2') {
					insert actionOff;
					insert new AvailableEvents__c(ActionId__c = actionOff.Id, Product__c = productId);
				}
			}
			if (mType == '1') {
				insert actionOff;
				insert new AvailableEvents__c(ActionId__c = action.Id, Product__c = productId);
			}
		}
		if (mActivity == '1') {
			action.Name = mName1;
			action.Type__c = (mPrice1 == 0 ? 'Бесплатное' : 'Платное');
			action.CityId__c = getCityId(mCity1);
			action.FormOf__c = (mIsIn1 ? 'зал' : '');
			action.StartDate__c = Date.valueOf(stringToDatetime(mStartDate1));
			action.StartTime__c = mStartDate1.substringAfter(' ');
			action.EndDate__c = Date.valueOf(stringToDatetime(mEndDate1));
			action.EndTime__c = mEndDate1.substringAfter(' ');
			action.RegistrationEndDate__c = stringToDatetime(mEndReg1);
			action.PaymentOldDate__c = stringToDatetime(mEndPay1);
			insert action;
			Day__c day = new Day__c(Name = 'День 1', Date__c = action.StartDate__c, ActionId__c = action.Id);
			insert day;
			insert new AvailableEvents__c(ActionId__c = action.Id, Product__c = getProductId(mPrice1));
		}
		if (mActivity == '2') {
			action.Name = mName2;
			action.Type__c = (mPrice1 == 0 ? 'Бесплатное' : 'Платное');
			action.CityId__c = getCityId(mCity2);
			action.FormOf__c = (mIsIn2 ? 'зал' : '');
			action.StartDate__c = Date.valueOf(stringToDatetime(mStartDate2));
			action.StartTime__c = mStartDate2.substringAfter(' ');
			action.EndDate__c = Date.valueOf(stringToDatetime(mEndDate2));
			action.EndTime__c = mEndDate2.substringAfter(' ');
			action.RegistrationEndDate__c = stringToDatetime(mEndReg2);
			action.PaymentOldDate__c = stringToDatetime(mEndPay2);
			insert action;
			Day__c day = new Day__c(Name = 'День 1', Date__c = action.StartDate__c, ActionId__c = action.Id);
			insert day;
			insert new AvailableEvents__c(ActionId__c = action.Id, Product__c = getProductId(mPrice2));
		}
		return new PageReference(URL.getSalesforceBaseUrl().toExternalForm() + '/' + action.Id);
	}

	public Id getCityId(String cityName) {
		List<Cities__c> city = [SELECT Id
								FROM Cities__c
								WHERE Name LIKE :cityName];
		if (city.size() > 0) {
			return city.get(0).Id;
		} else {
			Cities__c newCity = new Cities__c(Name = cityName);
			insert newCity;
			return newCity.Id;
		}
	}

	public Id getProductId(Integer productPrice) {
		String name = getProductName(productPrice);
		List<Product2> product = [SELECT Id
								  FROM Product2
								  WHERE Name LIKE :name];
		if (product.size() > 0) {
			return product.get(0).Id;
		} else {
			Product2 newProduct = new Product2(Name = name);
			insert newProduct;
			Pricebook2 priceBook = [SELECT Id FROM Pricebook2 WHERE IsStandard = true].get(0);
			PricebookEntry price = new PricebookEntry(Pricebook2Id = priceBook.Id,
													  Product2Id = newProduct.Id,
													  UnitPrice = productPrice,
													  IsActive = true);
			insert price;
			return newProduct.Id;
		}
	}

	private String getProductName(Integer price) {
		if (mActivity == '0') {
			return (price == 0 ? 'Вебинар (бесплатный)' :  'Вебинар (платный). ' + price);
		} else if (mActivity == '1') {
			return (price == 0 ? 'Мастер-класс (бесплатный)' :  'Мастер-класс. ' + price);
		} else {
			return (price == 0 ? 'МГ. Мастер-класс (бесплатный)' :  'МГ. Мастер-класс. ' + price);
		}
	}

	public Datetime stringToDatetime(String stringValue) {
		String year = stringValue.substringBefore(' ').substringAfterLast('.');
		String month = stringValue.substringAfter('.').substringBeforeLast('.');
		String day = stringValue.substringBefore('.');
		String hours = stringValue.substringAfter(' ').substringBefore(':');
		String minutes = stringValue.substringAfterLast(':');
		String seconds = '00';
		String stringDate = year + '-' + month + '-' + day + ' ' + hours + ':' + minutes +  ':' + seconds;
		return Datetime.valueOf(stringDate);
	}

}