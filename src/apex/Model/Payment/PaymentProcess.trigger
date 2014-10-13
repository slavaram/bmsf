trigger PaymentProcess on Payment__c (before insert) {

	NetPayment.processNetPayments(trigger.new);

}