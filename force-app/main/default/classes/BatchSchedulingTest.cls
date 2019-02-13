@IsTest private class BatchSchedulingTest {

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