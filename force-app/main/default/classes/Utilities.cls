public with sharing class Utilities {
    public static final String SCHEDULED_JOB_PREFIX = 'LightningLdv Sync: ';

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
}
