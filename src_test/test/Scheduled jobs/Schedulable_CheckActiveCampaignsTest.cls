@isTest
class Schedulable_CheckActiveCampaignsTest {

	static testmethod void test() {

        Test.startTest();

        Campaign campaignToClose = new Campaign(Name = 'test_campaignToClose', IsActive = true, Status = 'test');
        insert campaignToClose;
        Campaign campaignToSwitch = new Campaign(Name = 'test_campaignToSwitch', IsActive = true, Status = 'test');
        insert campaignToSwitch;
        Campaign campaignToCloseId = [SELECT Id FROM Campaign WHERE Name = 'test_campaignToClose'];
        Campaign campaignToSwitchId = [SELECT Id FROM Campaign WHERE Name = 'test_campaignToSwitch'];
        List<CampaignMember> toInsert = new List<CampaignMember>();
        for (Integer i = 0; i < 19; i++) {
            String name = 'test_contactToGetId' + i;
            Contact contact1 = new Contact(FirstName = name, LastName = name);
            insert contact1;
            Contact contactId1 = [SELECT Id FROM Contact WHERE FirstName =: name];
            CampaignMember member1 = new CampaignMember(CampaignId = campaignToCloseId.Id, IsCallTaskCreated__c = true, ContactId = contactId1.Id);
            toInsert.add(member1);
        }
        Contact contact2 = new Contact(FirstName = 'test_contactToGetId20', LastName = 'test_contactToGetId20');
        insert contact2;
        Contact contactId2 = [SELECT Id FROM Contact WHERE FirstName = 'test_contactToGetId20'];
        CampaignMember member2 = new CampaignMember(CampaignId = campaignToCloseId.Id, IsCallTaskCreated__c = false, ContactId = contactId2.Id);
        toInsert.add(member2);
        Contact contact3 = new Contact(FirstName = 'test_contactToGetId21', LastName = 'test_contactToGetId21');
        insert contact3;
        Contact contactId3 = [SELECT Id FROM Contact WHERE FirstName = 'test_contactToGetId20'];
        CampaignMember member3 = new CampaignMember(CampaignId = campaignToSwitchId.Id, IsCallTaskCreated__c = true, ContactId = contactId3.Id);
        toInsert.add(member3);
        insert toInsert;

	    String jobId = System.schedule('Check active campaigns',
        								Schedulable_CheckActiveCampaigns.CRON_EXP,
        								new Schedulable_CheckActiveCampaigns());

        CronTrigger cronTriggerBefore = [SELECT Id, CronExpression, TimesTriggered
                                   FROM CronTrigger
                                   WHERE id = :jobId];

        System.assertEquals(Schedulable_CheckActiveCampaigns.CRON_EXP, cronTriggerBefore.CronExpression);
        System.assertEquals(0, cronTriggerBefore.TimesTriggered);


        Campaign campaignToCloseBefore = [SELECT Id, IsActive, Status, NumberOfContacts, TasksSize__c
                                          FROM Campaign
                                          WHERE Id =: campaignToCloseId.Id];
        Campaign campaignToSwitchBefore = [SELECT Id, IsActive, Status, NumberOfContacts, TasksSize__c
                                          FROM Campaign
                                          WHERE Id =: campaignToSwitchId.Id];

        System.assertEquals(campaignToCloseBefore.isActive, true);
        System.assertEquals(campaignToSwitchBefore.isActive, true);
        System.assertEquals(campaignToCloseBefore.Status, 'test');
        System.assertEquals(campaignToSwitchBefore.Status, 'test');
        System.assertEquals(campaignToCloseBefore.NumberOfContacts, 20);
        System.assertEquals(campaignToSwitchBefore.NumberOfContacts, 1);
        System.assertEquals(campaignToCloseBefore.TasksSize__c, 19);
        System.assertEquals(campaignToSwitchBefore.TasksSize__c, 1);

        Test.stopTest();

        Campaign campaignToCloseAfter = [SELECT Id, IsActive, Status, NumberOfContacts, TasksSize__c
                                          FROM Campaign
                                          WHERE Id =: campaignToCloseId.Id];
        Campaign campaignToSwitchAfter = [SELECT Id, IsActive, Status, NumberOfContacts, TasksSize__c
                                          FROM Campaign
                                          WHERE Id =: campaignToSwitchId.Id];

        System.assertEquals(campaignToCloseAfter.isActive, false);
        System.assertEquals(campaignToSwitchAfter.isActive, false);
        System.assertEquals(campaignToCloseAfter.Status, 'test');
        System.assertEquals(campaignToSwitchAfter.Status, 'Завершено');
        System.assertEquals(campaignToCloseAfter.NumberOfContacts, 20);
        System.assertEquals(campaignToSwitchAfter.NumberOfContacts, 1);
        System.assertEquals(campaignToCloseAfter.TasksSize__c, 19);
        System.assertEquals(campaignToSwitchAfter.TasksSize__c, 1);
	}

}