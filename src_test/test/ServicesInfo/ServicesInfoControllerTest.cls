@isTest
class ServicesInfoControllerTest {

	static testmethod void test() {
		List<TopProductGroup__c> toInsert = new List<TopProductGroup__c>();
		toInsert.add(new TopProductGroup__c(Name = 'Сервисы',	Id__c = '012345678901234567'));
		toInsert.add(new TopProductGroup__c(Name = 'Интенсив, Коучинг',	Id__c = '012345678901234561'));
		toInsert.add(new TopProductGroup__c(Name = 'Карьера',	Id__c = '012345678901234562'));
		toInsert.add(new TopProductGroup__c(Name = 'Миллион за сто',	Id__c = '012345678901234563'));
		toInsert.add(new TopProductGroup__c(Name = 'Отдел продаж',	Id__c = '012345678901234564'));
		toInsert.add(new TopProductGroup__c(Name = 'Распродажа',	Id__c = '012345678901234565'));
		toInsert.add(new TopProductGroup__c(Name = 'Самолет. VIP',	Id__c = '012345678901234566'));
		insert toInsert;
		ServicesInfoController controller = new ServicesInfoController();
	}
}