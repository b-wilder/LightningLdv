public with sharing class Utilities {
    public static final String SCHEDULED_JOB_PREFIX = 'LightningLdv Sync: ';
    public static DateTime maintenanceWindowStart;
    public static Date maintenanceWindowEndDay;
    public static DateTime maintenanceWindowEnd;
    public static DateTime softMaintenanceWindowEnd;
    public static DateTime softBlackoutPeriodEnd;
    public static boolean isLightningLdvExecution;
    public static set<String> objectsTriggeredInThisContext;
    //!!add booleans for isInMaintenanceWindow and isInBlackoutWindow

    public static DateTime testDateTime;

    public Enum TriggerContext{
        AfterInsert,
        AfterUpdate,
        AfterDelete,
        AfterUndelete
    }

    public static list<String> getStringListFromCsv(String csv){
        return csv.replaceAll(' ','').split(',');
    }

    //Used to enable testing of logic that is dependent on the current dateTime;
    //This will be called in place of DateTime.now() by functional code
    public static DateTime getCurrentDateTime(){
        if(Test.isRunningTest() && testDateTime != NULL){
            return testDateTime;
        } else {
            return DateTime.now();
        }
    }

    //Used to enable testing of logic that is dependent on the current dateTime;
    //This will be called in place of Date.today() by functional code
    public static Date getCurrentDate(){
        if(Test.isRunningTest() && testDateTime != NULL){
            return testDateTime.date();
        } else {
            return Date.today();
        }
    }

    public static DateTime getMaintenanceWindowStart(){
        if(maintenanceWindowStart == NULL){
            Date startDay = getCurrentDate();
            Time startTime = Global_Trigger_Settings__c.getOrgDefaults().Maintenance_Window_Start__c.time();
            maintenanceWindowStart = DateTime.newInstance(startDay, startTime);
        }
        return maintenanceWindowStart;
    }

    public static Date getMaintenanceWindowEndDay(){
        if(maintenanceWindowEndDay == NULL){
            maintenanceWindowEndDay = getCurrentDate();

            Global_Trigger_Settings__c orgDefaults = Global_Trigger_Settings__c.getOrgDefaults();
            Time startTime = orgDefaults.Maintenance_Window_Start__c.time();
            Time endTime = orgDefaults.Maintenance_Window_End__c.time();

            if (endTime < startTime){
                maintenanceWindowEndDay = getCurrentDate().addDays(1);
            }
        }
        return maintenanceWindowEndDay;
    }

    public static DateTime getMaintenanceWindowEnd(){
        if(maintenanceWindowEnd == NULL){
            Date endDay = getMaintenanceWindowEndDay();
            Time endTime = Global_Trigger_Settings__c.getOrgDefaults().Maintenance_Window_End__c.time();
            maintenanceWindowEnd = DateTime.newInstance(endDay, endTime);
        }
        return maintenanceWindowEnd;

    }

    //LightningLdv batches are run every 5 minutes object-by-object after the maintenance window ends
    //The period is referred to as the Soft Maintenance Window
    public static DateTime getSoftMaintnanceWindowEnd(){
        if(softMaintenanceWindowEnd == NULL){
            Integer numberOfLightningLdvTriggers = [SELECT DeveloperName FROM Object_Trigger_Settings__mdt].size();
            Integer batchOffsetMinutes = numberOfLightningLdvTriggers * 5;
            Global_Trigger_Settings__c orgDefaults = Global_Trigger_Settings__c.getOrgDefaults();
            softMaintenanceWindowEnd = getMaintenanceWindowEnd().addMinutes(batchOffsetMinutes);
        }
        return softMaintenanceWindowEnd;
    }

    public static DateTime getSoftBlackoutPeriodEnd(){
        Global_Trigger_Settings__c orgDefaults = Global_Trigger_Settings__c.getOrgDefaults();
        DateTime nowDT = getCurrentDateTime();
        if( softBlackoutPeriodEnd == NULL &&
            orgDefaults.Blackout_Period_Start__c != NULL &&
            orgDefaults.Blackout_Period_End__c != NULL &&
            nowDT >= orgDefaults.Blackout_Period_Start__c &&
            nowDT <= orgDefaults.Blackout_Period_End__c
        ){
            Integer numberOfLightningLdvTriggers = [SELECT DeveloperName FROM Object_Trigger_Settings__mdt].size();
            Integer batchOffsetMinutes = numberOfLightningLdvTriggers * 5;
            softBlackoutPeriodEnd = orgDefaults.Blackout_Period_End__c.addMinutes(batchOffsetMinutes);
        }
        return softBlackoutPeriodEnd;
    }

    public static boolean getIsLightningLdvExecution(){
        if(isLightningLdvExecution == NULL){
            isLightningLdvExecution = false;
        }
        return isLightningLdvExecution;
    }

    public static set<String> getObjectsTriggeredInThisContext(){
        if(objectsTriggeredInThisContext == NULL){
            objectsTriggeredInThisContext = new set<String>();
        }
        return objectsTriggeredInThisContext;
    }

    public static String getCronName(Map<Id,SObject> recordMap){
        String objectType = String.valueOf(recordMap.getSObjectType());
        return SCHEDULED_JOB_PREFIX + objectType;
    }
}
