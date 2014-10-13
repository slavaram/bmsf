trigger PromoCodeProcess on PromoCode__c (after insert) {

	List<PromoCode__c> toUpdate = new List<PromoCode__c>();
	for (PromoCode__c promoCode : trigger.new) {
		if (promoCode.Status__c == 'Использован' && promoCode.PartnerName__c == '36' &&
				(promoCode.Discount__c == 3000 || promoCode.Discount__c == 5000) && promoCode.DiscountType__c == 'Абсолютная') {
			codesToUpdate.add(promoCode);
		}
	}
	PromoCodeEntity.reAllocateOpportunities(codesToUpdate);

}