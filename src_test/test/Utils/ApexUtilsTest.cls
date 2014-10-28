@isTest
class ApexUtilsTest {

	static testmethod void getMonthNameRusTest() {
		System.assertEquals(null, ApexUtils.getMonthNameRus(null, true));
		System.assertEquals(null, ApexUtils.getMonthNameRus(200, true));
		System.assertEquals('январь', ApexUtils.getMonthNameRus(1, true));
		System.assertEquals('февраль', ApexUtils.getMonthNameRus(2, true));
		System.assertEquals('март', ApexUtils.getMonthNameRus(3, true));
		System.assertEquals('апрель', ApexUtils.getMonthNameRus(4, true));
		System.assertEquals('май', ApexUtils.getMonthNameRus(5, true));
		System.assertEquals('июнь', ApexUtils.getMonthNameRus(6, true));
		System.assertEquals('июль', ApexUtils.getMonthNameRus(7, true));
		System.assertEquals('август', ApexUtils.getMonthNameRus(8, true));
		System.assertEquals('сентябрь', ApexUtils.getMonthNameRus(9, true));
		System.assertEquals('октябрь', ApexUtils.getMonthNameRus(10, true));
		System.assertEquals('ноябрь', ApexUtils.getMonthNameRus(11, true));
		System.assertEquals('декабрь', ApexUtils.getMonthNameRus(12, true));
	}

	static testmethod void isWeekendTest() {
		System.assertEquals(false, ApexUtils.isWeekend(Date.valueOf('2014-08-21')));
		insert new DayTypes__c(Name = 'test', Day__c = Date.valueOf('2014-08-21'), IsWeekend__c = true);
		System.assertEquals(true, ApexUtils.isWeekend(Date.valueOf('2014-08-21')));
		System.assertEquals(true, ApexUtils.isWeekend(Date.valueOf('2014-08-23')));
		System.assertEquals(true, ApexUtils.isWeekend(DateTime.valueOf('2014-08-23 12:00:00')));
	}

	static testmethod void dateToStringTest() {
		System.assertEquals('21.08.2014', ApexUtils.dateToString(Date.valueOf('2014-08-21')));
	}

	static testmethod void isEqualStringsTest() {
		System.assertEquals(false, ApexUtils.isEqualStrings('string', null));
		System.assertEquals(false, ApexUtils.isEqualStrings(null, 'string'));
		System.assertEquals(true, ApexUtils.isEqualStrings(null, null));
		System.assertEquals(true, ApexUtils.isEqualStrings('string', 'string'));
		System.assertEquals(false, ApexUtils.isEqualStrings('string', 'string2'));
	}

	static testmethod void isFirstDateEarlierTest() {
		System.assertEquals(false, ApexUtils.isFirstDateEarlier('01.01.2014', '01.01.2013'));
		System.assertEquals(false, ApexUtils.isFirstDateEarlier('01.02.2014', '01.01.2014'));
		System.assertEquals(false, ApexUtils.isFirstDateEarlier('02.01.2014', '01.01.2014'));
		System.assertEquals(true, ApexUtils.isFirstDateEarlier('01.01.2013', '01.01.2014'));
		System.assertEquals(true, ApexUtils.isFirstDateEarlier('01.01.2014', '01.02.2014'));
		System.assertEquals(true, ApexUtils.isFirstDateEarlier('01.01.2014', '02.01.2014'));
		System.assertEquals(null, ApexUtils.isFirstDateEarlier('01.01.20144', '02.01.2014'));
		System.assertEquals(null, ApexUtils.isFirstDateEarlier('51.01.2014', '52.01.2014'));
	}

	static testmethod void getLabelTest() {
		List<SelectOption> options = new List<SelectOption>();
		options.add(new SelectOption('valueOne', 'labelOne'));
		options.add(new SelectOption('valueTwo', 'labelTwo'));
		System.assertEquals('labelTwo', ApexUtils.getLabel(options, 'valueTwo'));
		System.assertEquals(null, ApexUtils.getLabel(options, 'valueThree'));
	}

	static testmethod void shuffleTest() {
		List<Case> objectsToShuffle = new List<Case>();
		objectsToShuffle.add(new Case(Subject = 'TestCase0'));
		objectsToShuffle.add(new Case(Subject = 'TestCase1'));
		objectsToShuffle.add(new Case(Subject = 'TestCase2'));
		objectsToShuffle.add(new Case(Subject = 'TestCase3'));
		objectsToShuffle.add(new Case(Subject = 'TestCase4'));
		List<Case> shuffledObjects = (List<Case>) ApexUtils.shuffle(objectsToShuffle);
		System.assert(!(objectsToShuffle.get(0).Subject == shuffledObjects.get(0).Subject
				&& objectsToShuffle.get(1).Subject == shuffledObjects.get(1).Subject
				&& objectsToShuffle.get(2).Subject == shuffledObjects.get(2).Subject
				&& objectsToShuffle.get(3).Subject == shuffledObjects.get(3).Subject
				&& objectsToShuffle.get(4).Subject == shuffledObjects.get(4).Subject));
		insert objectsToShuffle;
		List<Id> idsToShuffle = new List<Id>();
		for (Case cas : objectsToShuffle) {
			idsToShuffle.add(cas.Id);
		}
		List<Id> shuffledIds = ApexUtils.shuffle(idsToShuffle);
		System.assert(!(idsToShuffle.get(0) == shuffledIds.get(0)
				&& idsToShuffle.get(1) == shuffledIds.get(1)
				&& idsToShuffle.get(2) == shuffledIds.get(2)
				&& idsToShuffle.get(3) == shuffledIds.get(3)
				&& idsToShuffle.get(4) == shuffledIds.get(4)));
	}

	static testmethod void criptoTest() {
		String secret = 'I love Madonna';
		System.assertEquals(secret, ApexUtils.decript(ApexUtils.encript(secret)));
	}

}