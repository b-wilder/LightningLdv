public with sharing class Utilities {
    public Enum TriggerContext{
        AfterInsert,
        AfterUpdate,
        AfterDelete,
        AfterUndelete
    }

    public static list<String> getStringListFromCsv(String csv){
        return csv.replaceAll(' ','').split(',');
    }
}
