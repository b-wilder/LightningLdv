@IsTest private class BatchSchedulingTest {

    //Maintenance period is a few consecutive hours within the same day
    //Lightning LDV trigger is fired outside the maintenance period
    private static testMethod void testOutideSingleDayMaintenancePeriod(){
        Test.startTest();
            System.debug('testOutideSingleDayMaintenancePeriod');
            Utilities.testDateTime = DateTime.newInstance(Date.Today(), Time.newInstance(9, 0, 0, 0)); //set current time to 9am
            TestHelper.commonSetup(TestHelper.commonConfig()); //set maintenance period to 1am to 4am
            TestHelper.validateTestSetup();

            DateTime expectedMaintenanceStart = DateTime.newInstance(Date.Today(), Time.newInstance(1, 0, 0, 0));
            System.assertEquals(expectedMaintenanceStart, Utilities.getMaintenanceWindowStart(), 'Maintenance window should start at 1AM today');

            DateTime expectedMaintenanceEnd = DateTime.newInstance(Date.Today(), Time.newInstance(4, 0, 0, 0));
            System.assertEquals(expectedMaintenanceEnd, Utilities.getMaintenanceWindowEnd(), 'Maintenance window should end at 4AM today');

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
            System.debug('testInsideSingleDayMaintenancePeriod');
            Utilities.testDateTime = DateTime.newInstance(Date.Today(), Time.newInstance(2, 0, 0, 0)); //set current time to 2am
            TestHelper.commonSetup(TestHelper.commonConfig()); //set maintenance period to 1am to 4am
            TestHelper.validateTestSetup();

            DateTime expectedMaintenanceStart = DateTime.newInstance(Date.Today(), Time.newInstance(1, 0, 0, 0));
            System.assertEquals(expectedMaintenanceStart, Utilities.getMaintenanceWindowStart(), 'Maintenance window should start at 1AM today');

            DateTime expectedMaintenanceEnd = DateTime.newInstance(Date.Today(), Time.newInstance(4, 0, 0, 0));
            System.assertEquals(expectedMaintenanceEnd, Utilities.getMaintenanceWindowEnd(), 'Maintenance window should end at 4AM today');

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
            System.debug('testOutideCrossDayMaintenancePeriod');
            Utilities.testDateTime = DateTime.newInstance(Date.Today(), Time.newInstance(9, 0, 0, 0)); //set current time to 9am
            TestHelper.commonSetup(TestHelper.altMaintenanceConfig()); //set maintenance period to 11pm to 2am the next day
            TestHelper.validateTestSetup();

            DateTime expectedMaintenanceStart = DateTime.newInstance(Date.Today(), Time.newInstance(23, 0, 0, 0));
            System.assertEquals(expectedMaintenanceStart, Utilities.getMaintenanceWindowStart(), 'Maintenance window should start at 11PM today');

            DateTime expectedMaintenanceEnd = DateTime.newInstance(Date.Today().addDays(1), Time.newInstance(2, 0, 0, 0));
            System.assertEquals(expectedMaintenanceEnd, Utilities.getMaintenanceWindowEnd(), 'Maintenance window should end at 2AM tomorrow');

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
            System.debug('testInsideCrossDayMaintenancePeriod');
            Utilities.testDateTime = DateTime.newInstance(Date.Today(), Time.newInstance(1, 0, 0, 0)); //set current time to 1am
            TestHelper.commonSetup(TestHelper.altMaintenanceConfig()); //set maintenance period to 11pm to 2am the next day
            TestHelper.validateTestSetup();

            DateTime expectedMaintenanceStart = DateTime.newInstance(Date.Today(), Time.newInstance(23, 0, 0, 0));
            System.assertEquals(expectedMaintenanceStart, Utilities.getMaintenanceWindowStart(), 'Maintenance window should start at 11PM today');

            DateTime expectedMaintenanceEnd = DateTime.newInstance(Date.Today().addDays(1), Time.newInstance(2, 0, 0, 0));
            System.assertEquals(expectedMaintenanceEnd, Utilities.getMaintenanceWindowEnd(), 'Maintenance window should end at 2AM tomorrow');

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