@IsTest private class EmailRecipientTriggerTest {
    
    private static testMethod void testInsert(){
        Test.startTest();
            TestHelper.commonSetup(TestHelper.commonConfig());
            TestHelper.validateTestSetup();
        Test.stopTest();

        TestHelper.validateDistributionList(TestHelper.MARKETING_LIST, new set<String>{'MarketingRecipient1@test.com','MarketingRecipient2@test.com','MarketingRecipient3@test.com'});
        TestHelper.validateDistributionList(TestHelper.SALES_LIST, new set<String>{'SalesRecipient1@test.com','SalesRecipient2@test.com','SalesRecipient3@test.com'});
    }


    private static testMethod void testUpdate(){
        Test.startTest();
            TestHelper.commonSetup(TestHelper.commonConfig());
            TestHelper.validateTestSetup();

            Email_Recipient__c er1 = [Select Id FROM Email_Recipient__c WHERE Email__c = 'MarketingRecipient2@test.com'];
            er1.Email__c = 'MarketingLeader2@test.com';

            Email_Recipient__c er2 = [Select Id FROM Email_Recipient__c WHERE Email__c = 'SalesRecipient2@test.com'];
            er2.Email__c = 'SalesLeader2@test.com';

            Email_Recipient__c er3 = [Select Id, Email__c FROM Email_Recipient__c WHERE Email__c = 'SalesRecipient3@test.com'];
            er3.Email_Distribution_List__c = [Select Id FROM Email_Distribution_List__c WHERE Name = :TestHelper.MARKETING_LIST].get(0).Id;
            er3.Email__c = 'Former' + er3.Email__c;

            update new list<Email_Recipient__c>{er1,er2,er3};
        Test.stopTest();

        TestHelper.validateDistributionList(TestHelper.MARKETING_LIST, new set<String>{'MarketingRecipient1@test.com','MarketingLeader2@test.com','MarketingRecipient3@test.com','FormerSalesRecipient3@test.com'});
        TestHelper.validateDistributionList(TestHelper.SALES_LIST, new set<String>{'SalesRecipient1@test.com','SalesLeader2@test.com'});
    }


    private static testMethod void testDelete(){
        Test.startTest();
            TestHelper.commonSetup(TestHelper.commonConfig());
            TestHelper.validateTestSetup();

            list<Email_Recipient__c> ers = [SELECt Id FROM Email_Recipient__c WHERE Email__c like '%2@test.com'];
            delete ers;
        Test.stopTest();

        TestHelper.validateDistributionList(TestHelper.MARKETING_LIST, new set<String>{'MarketingRecipient1@test.com','MarketingRecipient3@test.com'});
        TestHelper.validateDistributionList(TestHelper.SALES_LIST, new set<String>{'SalesRecipient1@test.com','SalesRecipient3@test.com'});
    }


     private static testMethod void testUndelete(){
        Test.startTest();
            TestHelper.commonSetup(TestHelper.commonConfig());
            TestHelper.validateTestSetup();

            list<Email_Recipient__c> ers = [SELECt Id FROM Email_Recipient__c WHERE Email__c like '%2@test.com'];
            delete ers;
            
            Email_Recipient__c er = [SELECT Id FROM EmaiL_Recipient__c WHERE Email__c = 'SalesRecipient2@test.com' AND IsDeleted = true ALL ROWS];
            undelete er;
        Test.stopTest();

        TestHelper.validateDistributionList(TestHelper.MARKETING_LIST, new set<String>{'MarketingRecipient1@test.com','MarketingRecipient3@test.com'});
        TestHelper.validateDistributionList(TestHelper.SALES_LIST, new set<String>{'SalesRecipient1@test.com','SalesRecipient2@test.com','SalesRecipient3@test.com'});
    }


    //Maintenance period is a few consecutive hours within the same day
    //Lightning LDV trigger is fired outside the maintenance period
    private static testMethod void testOutideSingleDayMaintenancePeriod(){
        Test.startTest();
            Utilities.testDateTime = DateTime.newInstance(Utilities.getCurrentDate(), Time.newInstance(9, 0, 0, 0)); //set current time to 9am
            TestHelper.commonSetup(TestHelper.commonConfig()); //set maintenance period to 1am to 4am
            TestHelper.validateTestSetup();

            String cronName = Utilities.SCHEDULED_JOB_PREFIX + 'LightningLdv__Email_Recipient__c';
            list<CronTrigger> scheduledBatch = [SELECT NextFireTime FROM CronTrigger WHERE CronJobDetail.Name = :cronName];
            System.assert(scheduledBatch.size() == 1, 'There should be 1 LightningLdv batch for the LightningLdv__Email_Recipient__c object scheduled');

            DateTime scheduledTime = scheduledBatch.get(0).NextFireTime;
            System.assert(scheduledTime >  Utilities.getCurrentDateTime() && scheduledTime <= Utilities.getCurrentDateTime().addMinutes(15), 
                'The LightningLdv batch should be scheduled some time within the next 15 minutes'
            );
        Test.stopTest();


    }


    //Maintenance period is a few consecutive hours within the same day
    //Lightning LDV trigger is fired inside the maintenance period
    private static testMethod void testInsideSingleDayMaintenancePeriod(){
        Test.startTest();
            Utilities.testDateTime = DateTime.newInstance(Utilities.getCurrentDate(), Time.newInstance(2, 0, 0, 0)); //set current time to 2am
            TestHelper.commonSetup(TestHelper.commonConfig()); //set maintenance period to 1am to 4am
            TestHelper.validateTestSetup();

            String cronName = Utilities.SCHEDULED_JOB_PREFIX + 'LightningLdv__Email_Recipient__c';
            list<CronTrigger> scheduledBatch = [SELECT NextFireTime FROM CronTrigger WHERE CronJobDetail.Name = :cronName];
            System.assert(scheduledBatch.size() == 1, 'There should be 1 LightningLdv batch for the LightningLdv__Email_Recipient__c object scheduled');

            DateTime scheduledTime = scheduledBatch.get(0).NextFireTime;
            System.assert(scheduledTime >= Utilities.getMaintenanceWindowEnd() && scheduledTime <= Utilities.getSoftMaintnanceWindowEnd(), 
                'The LightningLdv batch should be scheduled shortly after the maintnenace window has ended'
            );
        Test.stopTest();
    }

    //Maintenance period is a few consecutive hours that crosses from one day to the next
    //Lightning LDV trigger is fired outside the maintenance period
    private static testMethod void testOutideCrossDayMaintenancePeriod(){
        Test.startTest();
            Utilities.testDateTime = DateTime.newInstance(Utilities.getCurrentDate(), Time.newInstance(9, 0, 0, 0)); //set current time to 9am
            TestHelper.commonSetup(TestHelper.altMaintenanceConfig()); //set maintenance period to 11pm to 2am the next day
            TestHelper.validateTestSetup();

            String cronName = Utilities.SCHEDULED_JOB_PREFIX + 'LightningLdv__Email_Recipient__c';
            list<CronTrigger> scheduledBatch = [SELECT NextFireTime FROM CronTrigger WHERE CronJobDetail.Name = :cronName];
            System.assert(scheduledBatch.size() == 1, 'There should be 1 LightningLdv batch for the LightningLdv__Email_Recipient__c object scheduled');

            DateTime scheduledTime = scheduledBatch.get(0).NextFireTime;
            System.assert(scheduledTime >  Utilities.getCurrentDateTime() && scheduledTime <= Utilities.getCurrentDateTime().addMinutes(15), 
                'The LightningLdv batch should be scheduled some time within the next 15 minutes'
            );
        Test.stopTest();


    }


    //Maintenance period is a few consecutive hours that crosses from one day to the next
    //Lightning LDV trigger is fired inside the maintenance period
    private static testMethod void testInsideCrossDayMaintenancePeriod(){
        Test.startTest();
            Utilities.testDateTime = DateTime.newInstance(Utilities.getCurrentDate(), Time.newInstance(1, 0, 0, 0)); //set current time to 1am
            TestHelper.commonSetup(TestHelper.altMaintenanceConfig()); //set maintenance period to 11pm to 2am the next day
            TestHelper.validateTestSetup();

            String cronName = Utilities.SCHEDULED_JOB_PREFIX + 'LightningLdv__Email_Recipient__c';
            list<CronTrigger> scheduledBatch = [SELECT NextFireTime FROM CronTrigger WHERE CronJobDetail.Name = :cronName];
            System.assert(scheduledBatch.size() == 1, 'There should be 1 LightningLdv batch for the LightningLdv__Email_Recipient__c object scheduled');

            DateTime scheduledTime = scheduledBatch.get(0).NextFireTime;
            System.assert(scheduledTime >= Utilities.getMaintenanceWindowEnd() && scheduledTime <= Utilities.getSoftMaintnanceWindowEnd(), 
                'The LightningLdv batch should be scheduled shortly after the maintnenace window has ended'
            );
        Test.stopTest();
    }
}