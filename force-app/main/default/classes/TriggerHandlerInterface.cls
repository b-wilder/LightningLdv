global interface TriggerHandlerInterface {
    void onAfterInsert(map<Id,sObject> newMap);
    void onAfterUpdate(map<Id,sObject> newMap);
    void onAfterDelete(map<Id,sObject> oldMap);
    void onAfterUndelete(map<Id,sObject> newMap);
}