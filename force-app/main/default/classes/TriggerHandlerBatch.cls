public without sharing class TriggerHandlerBatch implements Database.Batchable<sObject>{

    private Object_Trigger_Settings__mdt objectTriggerSettings;
    private Utilities.TriggerContext triggerContext;
    private TriggerHandlerInterface ldvHandler;
    private String selectx;
    private String fromx;
    private String wherex;
    private DateTime lastRunTime;

    public TriggerHandlerBatch(String objectApiName, Utilities.TriggerContext tc) {
        this.objectTriggerSettings = [  SELECT Update_Field__c, Changed_Fields_API_Name__c,
                                            Queried_Fields__c, Last_Run_Time__c, DeveloperName
                                        FROM Object_Trigger_Settings__mdt
                                        WHERE DeveloperName = 'objectApiName'
        ].get(0);

        String TriggerHandler = objectApiName.replace('__c','').replace('_', '') + '_LdvHandler';
        Type t = Type.forName(TriggerHandler);
        this.ldvHandler = (TriggerHandlerInterface)t.newInstance();

        this.triggerContext = tc;

        this.selectx = buildSelectString();
        this.fromx = 'FROM ' + objectApiName;
        this.wherex = buildWhereString();
    }
    
    private String buildSelectString(){
        set<String> selectValues = new set<String>{'Id','CreatedDate','SystemModStamp','IsDeleted'};

        //Add "Update Field" to query if relevant
        if( !String.isBlank(this.objectTriggerSettings.Update_Field__c) &&
            (   this.triggerContext == Utilities.TriggerContext.AfterUpdate || 
                this.triggerContext == Utilities.TriggerContext.AfterUndelete
            )
        ){
            selectValues.add(this.objectTriggerSettings.Update_Field__c);
        }

        //Add "Changed Fields" to query if relevant
        if( !String.isBlank(this.objectTriggerSettings.Changed_Fields_API_Name__c) &&
            this.triggerContext == Utilities.TriggerContext.AfterUpdate
        ){
            selectValues.addAll(Utilities.getStringListFromCsv(this.objectTriggerSettings.Changed_Fields_API_Name__c));
        }

        //Add other fields needed by trigger logic to the query
        selectValues.addAll(Utilities.getStringListFromCsv(this.objectTriggerSettings.Queried_Fields__c));

        return 'SELECT ' + String.join(new list<String>(selectValues), ',');
    }

    private String buildWhereString(){
        String returnVal = 'WHERE';
        switch on this.triggerContext{
            when AfterInsert {
                returnVal += ' CreatedDate >= ' + this.objectTriggerSettings.Last_Run_Time__c;
            }
            when AfterUpdate {
                returnVal += ' SystemModStamp >= ' + this.objectTriggerSettings.Last_Run_Time__c;
                returnVal += ' AND CreatedDate < ' + this.objectTriggerSettings.Last_Run_Time__c;
                returnVal += ' AND ' + this.objectTriggerSettings.Update_Field__c + ' = true';
            }
            when AfterDelete {
                returnVal += ' SystemModStamp >= ' + this.objectTriggerSettings.Last_Run_Time__c + ' ';
                returnVal += ' AND isDeleted = true ALL ROWS';
            }
            when AfterUndelete {
                returnVal += ' SystemModStamp >= ' + this.objectTriggerSettings.Last_Run_Time__c;
                returnVal += ' AND CreatedDate < ' + this.objectTriggerSettings.Last_Run_Time__c;
                returnVal += ' AND ' + this.objectTriggerSettings.Update_Field__c + ' = false';
            }
            when else {}
        }
        return returnVal;
    }

    public Database.QueryLocator start(Database.BatchableContext BC){
        // Track Last Run Time as of start time of batch, but do not update it until the batch succeeds
        this.lastRunTime = DateTime.now();

        System.debug('SELECT String: ' + this.selectx);
        System.debug('FROM String: ' + this.fromx);
        System.debug('WHERE String: ' + this.wherex);
        String queryString = String.join(new list<String>{selectx,fromx,wherex},' ');
        return Database.getQueryLocator(queryString);
    }

    public void execute(Database.BatchableContext BC, List<sObject> scope){
        map<Id,sObject> scopeMap = new map<Id,sObject>(scope);
        
        //Execute the handler class that implements LightningLdv__TriggerHandlerInterface
        switch on this.triggerContext{
            when AfterInsert {
                this.ldvHandler.onAfterInsert(scopeMap);
            }
            when AfterUpdate {
                this.ldvHandler.onAfterUpdate(scopeMap);
            }
            when AfterDelete {
                this.ldvHandler.onAfterDelete(scopeMap);
            }
            when AfterUndelete {
                this.ldvHandler.onAfterUndelete(scopeMap);
            }
            when else {
                return;
            }
        }
    }

    public void finish(Database.BatchableContext BC){
        //Updates the Last Run Time with the value tracked in the start method now that the batch has succeeded.
        setLastRunDate();
    }

    //Handles deploying the LightningLdv__Object_Trigger_Settings__mdt to update the Last Run Time.
    private void setLastRunDate(){
        Metadata.CustomMetadata customMetadata =  new Metadata.CustomMetadata();
        customMetadata.fullName = 'LightningLdv__Object_Trigger_Settings.LightningLdv__' + objectTriggerSettings.DeveloperName;
        
        //Adding updated Last Run Time to the Object_Trigger_Settings__mdt record
        Metadata.CustomMetadataValue lastRunTimeField = new Metadata.CustomMetadataValue();
        lastRunTimeField.field = 'LightningLdv__Last_Run_Time__c';
        lastRunTimeField.value = this.lastRunTime;
        customMetadata.values.add(lastRunTimeField);

        //Creating deploy container
        Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
        mdContainer.addMetadata(customMetadata);

        // Setting up deploy callback
        Utilities.MetadataCallback callback = new  Utilities.MetadataCallback();

        // Enqueue custom metadata deployment
        // jobId is the deployment ID
        /* this isn't working, and I realized I should use a custom setting anyways, so I'm commenting it out
        Id jobId = Metadata.Operations.enqueueDeployment(mdContainer, callback);
        System.debug('jobId for LightningLdv__Object_Trigger_Settings__mdt deployment: ' + jobId);
        */
    }
}
