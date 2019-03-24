public with sharing class GenericTriggerHandler {

    //Track changed fields on update
    public void onBeforeUpdate(map<Id,sObject> oldMap, map<Id,sObject> newMap){

    }

    //Schedule batch methods
    public void onAfterDML(map<Id,sObject> recordMap){
        //Gather required information
        Global_Trigger_Settings__c orgDefaults = Global_Trigger_Settings__c.getOrgDefaults();
        String objectType = String.valueOf(recordMap.getSObjectType());
        String cronName = Utilities.getCronName(objectType);
        Object_Trigger_Settings__mdt thisObjectsTriggerSettings;
        list<Object_Trigger_Settings__mdt> objectTriggerSettings = [   
            SELECT Run_After_Inserts__c, Run_After_Updates__c, Run_After_Deletes__c, Run_After_Undeletes__c
            FROM Object_Trigger_Settings__mdt
            WHERE DeveloperName = :objectType
        ];
        if(objectTriggerSettings != null && objectTriggerSettings.size() == 1){
            thisObjectsTriggerSettings = objectTriggerSettings[0];
        }
        
        //Execute or schedule trigger logic if context is valid
        if(isValidExecution(orgDefaults, objectType, thisObjectsTriggerSettings)){
            if( Utilities.isLightningLdvExecution || orgDefaults.Trigger_Delay__c <= 0 ){ //!!run synchronously because this is already a lightning ldv batch execution or because trigger delay was set to 0

            } else { //!!schedule lightningLdv batch
                TriggerHandlerBatch nextBatch = new TriggerHandlerBatch(objectType);
                if(false) { //currently in blackout period
                    //schedule after softblackoutend
                    //!! Documentation needs to indicate maintenance and blackout period should not overlap so that case doesn't need to be handled here.
                } else if(false) { //currently in maintenance window
                    //schedule after softmaintenanceend
                    //!! Documentation needs to indicate maintenance and blackout period should not overlap so that case doesn't need to be handled here.
                } else{
                    //schedule after configured delay (orgDefaults.Trigger_Delay__c)
                }
            }

        }

        Utilities.objectsTriggeredInThisContext.add(objectType);
        Utilities.isLightningLdvExecution = true;
    }

    private boolean isValidExecution(Global_Trigger_Settings__c orgDefaults, String objectType, Object_Trigger_Settings__mdt thisObjectsTriggerSettings){
        String cronName = Utilities.getCronName(objectType);
        DateTime nowDT = Utilities.getCurrentDateTime();
        list<CronTrigger> scheduledBatch = [SELECT NextFireTime FROM CronTrigger WHERE CronJobDetail.Name = :cronName AND NextFireTime >= :nowDT];
        

        return  (
            ( !Utilities.objectsTriggeredInThisContext.contains(objectType) ) && //Prevent trigger from running more than once per objecct in a single context
            ( scheduledBatch == null || scheduledBatch.size() <= 0 ) && //Prevent trigger from running if it is scheduled in the future
            ( System.Trigger.isAfter ) && //onAfterDML method should only run in an After context
            ( thisObjectsTriggerSettings != null ) && //Trigger should only run if there is exactly 1 config record for this object
            (  
                ( System.Trigger.isInsert && thisObjectsTriggerSettings.Run_After_Inserts__c ) || //Trigger should only run after insert if configured to do so
                ( System.Trigger.isUpdate && thisObjectsTriggerSettings.Run_After_Updates__c ) || //Trigger should only run after insert if configured to do so
                ( System.Trigger.isDelete && thisObjectsTriggerSettings.Run_After_Deletes__c ) || //Trigger should only run after insert if configured to do so
                ( System.Trigger.isUndelete && thisObjectsTriggerSettings.Run_After_Undeletes__c ) //Trigger should only run after insert if configured to do so
            )
        );
    }
}
