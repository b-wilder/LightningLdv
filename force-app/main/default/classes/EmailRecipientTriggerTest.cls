@IsTest private class EmailRecipientTriggerTest {
    private static String MARKETING_LIST = 'Marketing Distribution List';
    private static String SALES_LIST = 'Sales Distribution List';

    @TestSetup private static void commonSetup(){
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
        Integer edlCount = (Integer)[Select count(Id) countVal FROM Email_Distribution_List__c].get(0).get('countVal');
        System.assertEquals(edlCount,2);

        Integer marketingRecipientsCount = (Integer)[Select count(Id) countVal FROM Email_Recipient__c WHERE Email_Distribution_List__r.Name = :MARKETING_LIST].get(0).get('countVal');
        System.assertEquals(marketingRecipientsCount,3);

        Integer salesRecipientsCount = (Integer)[Select count(Id) countVal FROM Email_Recipient__c WHERE Email_Distribution_List__r.Name = :SALES_LIST].get(0).get('countVal');
        System.assertEquals(salesRecipientsCount,3);
    }

    private static testMethod void testInserts(){
        validateTestSetup();
    }
}