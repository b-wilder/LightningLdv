@IsTest private class EmailRecipientTriggerTest {
    private static String MARKETING_LIST = 'Marketing Distribution List';
    private static String SALES_LIST = 'Sales Distribution List';

    private static Global_Trigger_Settings__c commonConfig(){
        Date maintenanceDay = Utilities.getCurrentDate();
        DateTime maintenanceStartDateTime = DateTime.newInstance(maintenanceDay, Time.newInstance(1, 0, 0, 0));
        DateTime maintenanceEndDateTime = DateTime.newInstance(maintenanceDay, Time.newInstance(4, 0, 0, 0));
        
        Date blackoutDay = Utilities.getCurrentDate();
        DateTime blackoutStartDateTime = DateTime.newInstance(blackoutDay, Time.newInstance(13, 0, 0, 0));
        DateTime blackoutEndDateTime = DateTime.newInstance(blackoutDay, Time.newInstance(15, 0, 0, 0));

        return getGlobalTriggerSettings(maintenanceStartDateTime, maintenanceEndDateTime, blackoutStartDateTime, blackoutEndDateTime);
    }


    private static Global_Trigger_Settings__c altMaintenanceConfig(){ //maintnenance period crosses from one day to the next
        Date maintenanceDay = Utilities.getCurrentDate();
        DateTime maintenanceStartDateTime = DateTime.newInstance(maintenanceDay, Time.newInstance(23, 0, 0, 0));
        DateTime maintenanceEndDateTime = DateTime.newInstance(maintenanceDay.addDays(1), Time.newInstance(2, 0, 0, 0));
        
        Date blackoutDay = Utilities.getCurrentDate();
        DateTime blackoutStartDateTime = DateTime.newInstance(blackoutDay, Time.newInstance(13, 0, 0, 0));
        DateTime blackoutEndDateTime = DateTime.newInstance(blackoutDay, Time.newInstance(15, 0, 0, 0));

        return getGlobalTriggerSettings(maintenanceStartDateTime, maintenanceEndDateTime, blackoutStartDateTime, blackoutEndDateTime);
    }
    

    private static Global_Trigger_Settings__c getGlobalTriggerSettings(
        DateTime maintenanceStartDateTime, DateTime maintenanceEndDateTime,
        DateTime blackoutStartDateTime, DateTime blackoutEndDateTime
    ) {
        Global_Trigger_Settings__c orgDefaults = Global_Trigger_Settings__c.getOrgDefaults();
        orgDefaults.Maintenance_Window_Start__c = maintenanceStartDateTime;
        orgDefaults.Maintenance_Window_End__c = maintenanceEndDateTime;
        orgDefaults.Blackout_Period_Start__c = blackoutStartDateTime;
        orgDefaults.Blackout_Period_End__c = blackoutEndDateTime;
        return orgDefaults;
    }


    private static void commonSetup(Global_Trigger_Settings__c orgDefaults){
        insert orgDefaults;

        Email_Distribution_List__c ed1 = new Email_Distribution_List__c(name=MARKETING_LIST);
        Email_Distribution_List__c ed2 = new Email_Distribution_List__c(name=SALES_LIST);
        list<Email_Distribution_List__c> emailDistributionLists = new list<Email_Distribution_List__c>{ed1,ed2};
        insert emailDistributionLists;

        list<Email_Recipient__c> emailRecipients = new list<Email_Recipient__c>();
        for(integer i = 1; i <= 3; i++){
            String marketingRecipientName = getRecipientName('Marketing',i);
            String salesRecipientName = getRecipientName('Sales',i);
            
            Email_Recipient__c er1 = new Email_Recipient__c (
                name=marketingRecipientName,
                Email_Distribution_List__c = ed1.Id,
                Email__c=getRecipientEmail(marketingRecipientName)
            );
            emailRecipients.add(er1);

            Email_Recipient__c er2 = new Email_Recipient__c (
                name=salesRecipientName,
                Email_Distribution_List__c = ed2.Id,
                Email__c=getRecipientEmail(salesRecipientName)
            );
            emailRecipients.add(er2);
        }
        insert emailRecipients;
    }


    private static String getRecipientName(String prefix, Integer i){
        return prefix + ' Recipient ' + String.valueOf(i);
    }


    private static String getRecipientEmail(String name){
        return name.replace(' ','') + '@test.com';
    }


    private static void validateTestSetup(){
        Global_Trigger_Settings__c orgDefaults = Global_Trigger_Settings__c.getOrgDefaults();
        System.assert(orgDefaults != NULL, 'Global_Trigger_Settings__c org default should have been inserted');

        Integer edlCount = (Integer)[SELECT count(Id) countVal FROM Email_Distribution_List__c].get(0).get('countVal');
        System.assertEquals(edlCount,2);

        Integer marketingRecipientsCount = (Integer)[SELECT count(Id) countVal FROM Email_Recipient__c WHERE Email_Distribution_List__r.Name = :MARKETING_LIST].get(0).get('countVal');
        System.assertEquals(marketingRecipientsCount,3);

        Integer salesRecipientsCount = (Integer)[SELECT count(Id) countVal FROM Email_Recipient__c WHERE Email_Distribution_List__r.Name = :SALES_LIST].get(0).get('countVal');
        System.assertEquals(salesRecipientsCount,3);
    }


    private static testMethod void testInsert(){
        Test.startTest();
            commonSetup(commonConfig());
            validateTestSetup();
        Test.stopTest();

        validateDistributionList(MARKETING_LIST, new set<String>{'MarketingRecipient1@test.com','MarketingRecipient2@test.com','MarketingRecipient3@test.com'});
        validateDistributionList(SALES_LIST, new set<String>{'SalesRecipient1@test.com','SalesRecipient2@test.com','SalesRecipient3@test.com'});
    }


    private static testMethod void testUpdate(){
        Test.startTest();
            commonSetup(commonConfig());
            validateTestSetup();

            Email_Recipient__c er1 = [Select Id FROM Email_Recipient__c WHERE Email__c = 'MarketingRecipient2@test.com'];
            er1.Email__c = 'MarketingLeader2@test.com';

            Email_Recipient__c er2 = [Select Id FROM Email_Recipient__c WHERE Email__c = 'SalesRecipient2@test.com'];
            er2.Email__c = 'SalesLeader2@test.com';

            Email_Recipient__c er3 = [Select Id, Email__c FROM Email_Recipient__c WHERE Email__c = 'SalesRecipient3@test.com'];
            er3.Email_Distribution_List__c = [Select Id FROM Email_Distribution_List__c WHERE Name = :MARKETING_LIST].get(0).Id;
            er3.Email__c = 'Former' + er3.Email__c;

            update new list<Email_Recipient__c>{er1,er2,er3};
        Test.stopTest();

        validateDistributionList(MARKETING_LIST, new set<String>{'MarketingRecipient1@test.com','MarketingLeader2@test.com','MarketingRecipient3@test.com','FormerSalesRecipient3@test.com'});
        validateDistributionList(SALES_LIST, new set<String>{'SalesRecipient1@test.com','SalesLeader2@test.com'});
    }


    private static testMethod void testDelete(){
        Test.startTest();
            commonSetup(commonConfig());
            validateTestSetup();

            list<Email_Recipient__c> ers = [SELECt Id FROM Email_Recipient__c WHERE Email__c like '%2@test.com'];
            delete ers;
        Test.stopTest();

        validateDistributionList(MARKETING_LIST, new set<String>{'MarketingRecipient1@test.com','MarketingRecipient3@test.com'});
        validateDistributionList(SALES_LIST, new set<String>{'SalesRecipient1@test.com','SalesRecipient3@test.com'});
    }


     private static testMethod void testUndelete(){
        Test.startTest();
            commonSetup(commonConfig());
            validateTestSetup();

            list<Email_Recipient__c> ers = [SELECt Id FROM Email_Recipient__c WHERE Email__c like '%2@test.com'];
            delete ers;
            
            Email_Recipient__c er = [SELECT Id FROM EmaiL_Recipient__c WHERE Email__c = 'SalesRecipient2@test.com' AND IsDeleted = true ALL ROWS];
            undelete er;
        Test.stopTest();

        validateDistributionList(MARKETING_LIST, new set<String>{'MarketingRecipient1@test.com','MarketingRecipient3@test.com'});
        validateDistributionList(SALES_LIST, new set<String>{'SalesRecipient1@test.com','SalesRecipient2@test.com','SalesRecipient3@test.com'});
    }


    //Maintenance period is a few consecutive hours within the same day
    //Lightning LDV trigger is fired outside the maintenance period
    private static testMethod void testOutideSingleDayMaintenancePeriod(){
        Test.startTest();
            Utilities.testDateTime = DateTime.newInstance(Utilities.getCurrentDate(), Time.newInstance(9, 0, 0, 0)); //set current time to 9am
            commonSetup(commonConfig()); //set maintenance period to 1am to 4am
            validateTestSetup();

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
            commonSetup(commonConfig()); //set maintenance period to 1am to 4am
            validateTestSetup();

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
            commonSetup(altMaintenanceConfig()); //set maintenance period to 11pm to 2am the next day
            validateTestSetup();

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
            commonSetup(altMaintenanceConfig()); //set maintenance period to 11pm to 2am the next day
            validateTestSetup();

            String cronName = Utilities.SCHEDULED_JOB_PREFIX + 'LightningLdv__Email_Recipient__c';
            list<CronTrigger> scheduledBatch = [SELECT NextFireTime FROM CronTrigger WHERE CronJobDetail.Name = :cronName];
            System.assert(scheduledBatch.size() == 1, 'There should be 1 LightningLdv batch for the LightningLdv__Email_Recipient__c object scheduled');

            DateTime scheduledTime = scheduledBatch.get(0).NextFireTime;
            System.assert(scheduledTime >= Utilities.getMaintenanceWindowEnd() && scheduledTime <= Utilities.getSoftMaintnanceWindowEnd(), 
                'The LightningLdv batch should be scheduled shortly after the maintnenace window has ended'
            );
        Test.stopTest();
    }


     private static void validateDistributionList(String edlName, set<String> expectedValues){
        Email_Distribution_List__c edl = [SELECT Recipients__c FROM Email_Distribution_List__c WHERE Name = :edlName].get(0);
        set<String> actualValues = new set<String>();
        if(edl.Recipients__c != null){
            actualValues.addAll(edl.Recipients__c.split(','));
        }
        String errorMsg = 'Unexpected Recipients__c value for ' + edlName + ': \"' + edl.Recipients__c + '\".';
        errorMsg += ' Expected value was \"' + String.join(new list<String>(expectedValues), ',') + '\".';
        System.assert(expectedValues.equals(actualValues), errorMsg);
    }
}