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
}