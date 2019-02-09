@IsTest private class EmailRecipientTriggerTest {
    private static String MARKETING_LIST = 'Marketing Distribution List';
    private static String SALES_LIST = 'Sales Distribution List';

    private static Global_Trigger_Settings__c commonConfig(){
      Global_Trigger_Settings__c orgDefaults = Global_Trigger_Settings__c.getOrgDefaults();

      Date maintenanceDay = Date.Today();
      DateTime maintenanceStartDateTime = DateTime.newInstance(maintenanceDay, Time.newInstance(1, 0, 0, 0));
      DateTime maintenanceEndDateTime = DateTime.newInstance(maintenanceDay, Time.newInstance(4, 0, 0, 0));
      
      Date blackoutDay = Date.Today().addDays(1);
      DateTime blackoutStartDateTime = DateTime.newInstance(blackoutDay, Time.newInstance(13, 0, 0, 0));
      DateTime blackoutEndDateTime = DateTime.newInstance(blackoutDay, Time.newInstance(15, 0, 0, 0));

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