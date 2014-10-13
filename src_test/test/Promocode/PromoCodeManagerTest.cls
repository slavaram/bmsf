@isTest
class PromoCodeManagerTest {

	public static testmethod void assignPromoCodesTest() {
		Test.startTest();
		PromoCode__c promoCode = new PromoCode__c(Code__c = PromoCodeManager.PROMO_CODE_PREFIX + '12345', Status__c = PromoCodeManager.UNUSED_PROMO_CODE_STATUS);
		insert promoCode;
		Account acc = new Account(Name = 'Test acc', BirthDay__c = System.today().addYears(-50));
		insert acc;
		System.schedule('Test Schedule', '0 0 0 ? * * *', new PromoCodeManager());
		Test.stopTest();
		System.assertEquals(acc.Id, [SELECT AccountId__c FROM PromoCode__c WHERE Id = :promoCode.Id].AccountId__c);
	}


	public static testmethod void reassignUnusedPromoCodesTest() {
		Test.startTest();
		PromoCode__c promoCode = new PromoCode__c(Code__c = PromoCodeManager.PROMO_CODE_PREFIX + '12345',
				Status__c = PromoCodeManager.UNUSED_PROMO_CODE_STATUS,
				AccountBirthDay__c = System.today().addDays(-PromoCodeManager.EXPIRE_PERIOD));
		insert promoCode;
		System.schedule('Test Schedule', '0 0 0 ? * * *', new PromoCodeManager());
		Test.stopTest();
		System.assertEquals(null, [SELECT AccountBirthDay__c FROM PromoCode__c WHERE Id = :promoCode.Id].AccountBirthDay__c);
	}

}