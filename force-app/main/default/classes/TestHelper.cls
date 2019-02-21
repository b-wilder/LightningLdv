public class TestHelper {
    public static String MARKETING_LIST = 'Marketing Distribution List';
    public static String SALES_LIST = 'Sales Distribution List';

    public static Global_Trigger_Settings__c commonConfig(){
        Date maintenanceDay = Utilities.getCurrentDate();
        DateTime maintenanceStartDateTime = DateTime.newInstance(maintenanceDay, Time.newInstance(1, 0, 0, 0));
        DateTime maintenanceEndDateTime = DateTime.newInstance(maintenanceDay, Time.newInstance(4, 0, 0, 0));
        
        Date blackoutDay = Utilities.getCurrentDate();
        DateTime blackoutStartDateTime = DateTime.newInstance(blackoutDay, Time.newInstance(13, 0, 0, 0));
        DateTime blackoutEndDateTime = DateTime.newInstance(blackoutDay, Time.newInstance(15, 0, 0, 0));

        return getGlobalTriggerSettings(maintenanceStartDateTime, maintenanceEndDateTime, blackoutStartDateTime, blackoutEndDateTime);
    }


    public static Global_Trigger_Settings__c altMaintenanceConfig(){ //maintnenance period crosses from one day to the next
        Date maintenanceDay = Utilities.getCurrentDate();
        DateTime maintenanceStartDateTime = DateTime.newInstance(maintenanceDay, Time.newInstance(23, 0, 0, 0));
        DateTime maintenanceEndDateTime = DateTime.newInstance(maintenanceDay.addDays(1), Time.newInstance(2, 0, 0, 0));
        
        Date blackoutDay = Utilities.getCurrentDate();
        DateTime blackoutStartDateTime = DateTime.newInstance(blackoutDay, Time.newInstance(13, 0, 0, 0));
        DateTime blackoutEndDateTime = DateTime.newInstance(blackoutDay, Time.newInstance(15, 0, 0, 0));

        return getGlobalTriggerSettings(maintenanceStartDateTime, maintenanceEndDateTime, blackoutStartDateTime, blackoutEndDateTime);
    }
    

    public static Global_Trigger_Settings__c getGlobalTriggerSettings(
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


    public static void commonSetup(Global_Trigger_Settings__c orgDefaults){
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


    public static String getRecipientName(String prefix, Integer i){
        return prefix + ' Recipient ' + String.valueOf(i);
    }


    public static String getRecipientEmail(String name){
        return name.replace(' ','') + '@test.com';
    }


    public static void validateTestSetup(){
        System.debug('Utilities.getCurrentDate(): ' + Utilities.getCurrentDate().format());
        System.debug('Utilities.getCurrentDateTime(): ' + Utilities.getCurrentDateTime().format());
        System.debug('Utilities.getMaintenanceWindowStart(): ' + Utilities.getMaintenanceWindowStart().format());
        System.debug('Utilities.getMaintenanceWindowEnd(): ' + Utilities.getMaintenanceWindowEnd().format());
        System.debug('Utilities.getSoftMaintnanceWindowEnd(): ' + Utilities.getSoftMaintnanceWindowEnd().format());


        Global_Trigger_Settings__c orgDefaults = Global_Trigger_Settings__c.getOrgDefaults();
        System.assert(orgDefaults != NULL, 'Global_Trigger_Settings__c org default should have been inserted');

        Integer edlCount = (Integer)[SELECT count(Id) countVal FROM Email_Distribution_List__c].get(0).get('countVal');
        System.assertEquals(edlCount,2);

        Integer marketingRecipientsCount = (Integer)[SELECT count(Id) countVal FROM Email_Recipient__c WHERE Email_Distribution_List__r.Name = :MARKETING_LIST].get(0).get('countVal');
        System.assertEquals(marketingRecipientsCount,3);

        Integer salesRecipientsCount = (Integer)[SELECT count(Id) countVal FROM Email_Recipient__c WHERE Email_Distribution_List__r.Name = :SALES_LIST].get(0).get('countVal');
        System.assertEquals(salesRecipientsCount,3);
    }


     public static void validateDistributionList(String edlName, set<String> expectedValues){
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