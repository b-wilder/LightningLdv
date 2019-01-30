public without sharing class TriggerHandlerBatch implements Database.Batchable<sObject>{

    private Object_Trigger_Settings__mdt objectTriggerSettings; //Used to track object-based configuration of Lightning LDV trigger
    private Object_Trigger_Data__c objectTriggerData; //Used to track last run time
    private TriggerHandlerInterface ldvHandler;
    private String selectx;
    private String fromx;
    private String wherex;
    private DateTime nextLastRunTime; //Value to be set as the Last Run Time for this object after successful execution

    public TriggerHandlerBatch(String objectApiName) {
        this.objectTriggerSettings = [  SELECT Update_Field__c, Changed_Fields_API_Name__c,
                                            Queried_Fields__c, DeveloperName, Apex_Handler_Name__c,
                                            Run_After_Inserts__c, Run_After_Updates__c,
                                            Run_After_Deletes__c, Run_After_Undeletes__c
                                        FROM Object_Trigger_Settings__mdt
                                        WHERE DeveloperName = :objectApiName
        ].get(0);
        this.objectTriggerData = getObjectTriggerData(objectApiName);

        Type t = Type.forName(objectTriggerSettings.Apex_Handler_Name__c);
        this.ldvHandler = (TriggerHandlerInterface)t.newInstance();

        this.selectx = buildSelectString();
        this.fromx = 'FROM ' + objectApiName;
        this.wherex = buildWhereString();
    }

    private Object_Trigger_Data__c getObjectTriggerData(String objectApiName){
        Object_Trigger_Data__c returnVal = Object_Trigger_Data__c.getInstance(objectApiName);
        if (returnVal == null){
            returnVal = new Object_Trigger_Data__c(Name = objectApiName, Last_Run_Time__c = DateTime.now().addHours(-1));
            insert returnVal;
        }
        return returnVal;
    }
    
    private String buildSelectString(){
        set<String> selectValues = new set<String>{'Id','CreatedDate','SystemModStamp','IsDeleted'};

        //Add "Update Field" to query
        if(!String.isBlank(this.objectTriggerSettings.Update_Field__c)
        ){
            selectValues.add(this.objectTriggerSettings.Update_Field__c);
        }

        //Add "Changed Fields" to query
        if(!String.isBlank(this.objectTriggerSettings.Changed_Fields_API_Name__c)){
            selectValues.addAll(Utilities.getStringListFromCsv(this.objectTriggerSettings.Changed_Fields_API_Name__c));
        }

        //Add other fields needed by trigger logic to the query
        selectValues.addAll(Utilities.getStringListFromCsv(this.objectTriggerSettings.Queried_Fields__c));

        return 'SELECT ' + String.join(new list<String>(selectValues), ',');
    }

    private String buildWhereString(){
        String returnVal = 'WHERE SystemModStamp >= ' + this.objectTriggerData.Last_Run_Time__c;
        if(this.objectTriggerSettings.Run_After_Deletes__c){
            returnVal += ' ALL ROWS';
        }
        return returnVal;
    }

    public Database.QueryLocator start(Database.BatchableContext BC){
        // Track Last Run Time as of start time of batch, but do not update it until the batch succeeds
        this.nextLastRunTime = DateTime.now();

        System.debug('SELECT String: ' + this.selectx);
        System.debug('FROM String: ' + this.fromx);
        System.debug('WHERE String: ' + this.wherex);
        String queryString = String.join(new list<String>{selectx,fromx,wherex},' ');
        return Database.getQueryLocator(queryString);
    }

    public void execute(Database.BatchableContext BC, List<sObject> scope){
        map<Id,sObject> afterInsertMap = new map<Id,sObject>();
        map<Id,sObject> afterUpdateMap = new map<Id,sObject>();
        map<Id,sObject> afterDeleteMap = new map<Id,sObject>();
        map<Id,sObject> afterUndeleteMap = new map<Id,sObject>();
        
        for(sObject recordObj : scope){
            Id recordId = ((Id)recordObj.get('Id'));

            //Retrieve records inserted after last run time if Run After Inserts == true
            if( objectTriggerSettings.Run_After_Inserts__c 
                && ((DateTime)recordObj.get('CreatedDate')) >= objectTriggerData.Last_Run_Time__c
                && (!(Boolean)recordObj.get('IsDeleted'))
            ){
                afterInsertMap.put(recordId, recordObj);
            }
            //Retrieve records updated after last run time if Run After Updates == true
            //The query in the Start method has already ensured SystemModStamp >= Last Run Time
            else if( objectTriggerSettings.Run_After_Updates__c 
                && ((DateTime)recordObj.get('CreatedDate')) < objectTriggerData.Last_Run_Time__c
                && ((Boolean)recordObj.get(objectTriggerSettings.Update_Field__c)) //Checks that record was updated and not undeleted
                && (!(Boolean)recordObj.get('IsDeleted'))
            ){
                afterUpdateMap.put(recordId, recordObj);
            }
            //Retrieve records deleted after last run time if Run After Deletes == true
            else if( objectTriggerSettings.Run_After_Deletes__c
                && ((Boolean)recordObj.get('IsDeleted'))
            ){
                afterDeleteMap.put(recordId, recordObj);
            }
            //Retrieve records undeleted after last run time if Run After Undeletes == true
            else if( objectTriggerSettings.Run_After_Undeletes__c
                && (!(Boolean)recordObj.get(objectTriggerSettings.Update_Field__c)) //Checks that record was undeleted and not updated
                && (!(Boolean)recordObj.get('IsDeleted'))
            ){
                afterUndeleteMap.put(recordId, recordObj);
            }
        } //End of loop through scope

        //Run Lightning LDV trigger handler
        if(!afterInsertMap.isEmpty()){
            this.ldvHandler.onAfterInsert(afterInsertMap);
        }
        if(!afterUpdateMap.isEmpty()){
            this.ldvHandler.onAfterUpdate(afterUpdateMap);
        }
        if(!afterDeleteMap.isEmpty()){
            this.ldvHandler.onAfterDelete(afterDeleteMap);
        }
        if(!afterUndeleteMap.isEmpty()){
            this.ldvHandler.onAfterUndelete(afterUndeleteMap);
        }
    }

    public void finish(Database.BatchableContext BC){
        //Updates the Last Run Time with the value tracked in the start method now that the batch has succeeded.
        this.objectTriggerData.Last_Run_Time__c = this.nextLastRunTime;
        update this.objectTriggerData;
    }
}
