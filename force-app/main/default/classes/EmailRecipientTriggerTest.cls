@IsTest private class EmailRecipientTriggerTest {

    @TestSetup private static void commonSetup(){
        Email_Distribution_List__c ed1 = new Email_Distribution_List__c(name='Marketing Distribution List');
        Email_Distribution_List__c ed2 = new Email_Distribution_List__c(name='Sales Distribution List');
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

        Integer edlCount = (Integer)[Select count(Id) countVal FROM Email_Distribution_List__c].get(0).get('countVal');
        System.assertEquals(edlCount,2);

        Integer marketingRecipientsCount = (Integer)[Select count(Id) countVal FROM Email_Recipient__c WHERE Email_Distribution_List__c = :ed1.Id].get(0).get('countVal');
        System.assertEquals(marketingRecipientsCount,3);

        Integer salesRecipientsCount = (Integer)[Select count(Id) countVal FROM Email_Recipient__c WHERE Email_Distribution_List__c = :ed2.Id].get(0).get('countVal');
        System.assertEquals(salesRecipientsCount,3);
    }

    private static String getRecipientName(String prefix, Integer i){
        return prefix + ' Recipient ' + String.valueOf(i);
    }

    private static String getRecipientEmail(String name){
        return name.replace(' ','') + '@test.com';
    }

    private static testMethod void testInserts(){
        System.assert(true); //stub for test method
    }
}