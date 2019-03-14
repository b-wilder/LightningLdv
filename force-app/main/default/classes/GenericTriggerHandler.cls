public with sharing class GenericTriggerHandler {

    //Track changed fields on update
    public void onBeforeUpdate(map<Id,sObject> oldMap, map<Id,sObject> newMap){

    }

    //Schedule batch methods
    public void onAfterDML(map<Id,sObject> recordMap){
        DateTime nowDT = Utilities.getCurrentDateTime();
        Global_Trigger_Settings__c orgDefaults = Global_Trigger_Settings__c.getOrgDefaults();
        String objectType = String.valueOf(recordMap.getSObjectType());
        String cronName = Utilities.getCronName(recordMap);
        
        if(Utilities.objectsTriggeredInThisContext.contains(objectType)){
            return; //do not run because current object trigger has already been run in this context
        } else {
            cronName = Utilities.SCHEDULED_JOB_PREFIX + objectType;
            list<CronTrigger> scheduledBatch = [SELECT NextFireTime FROM CronTrigger WHERE CronJobDetail.Name = :cronName AND NextFireTime >= :nowDT];
            if(scheduledBatch != NULL && scheduledBatch.size() > 0){
                return;
            } else if( Utilities.isLightningLdvExecution ){ //!!run synchronously because this is already a lightning ldv batch execution

            } else { //!!schedule lightningLdv batch
                TriggerHandlerBatch nextBatch = new TriggerHandlerBatch(objectType);
                if(false) { //currently in blackout period
                    //schedule after softblackoutend
                    //handle case where blackout and maintenance overlap
                } else if(false) { //currently in maintenance window
                    //schedule after softmaintenanceend
                    //handle case where blackout and maintenance overlap
                } else{
                    //schedule in 15 minutes
                }
            }
        }

        Utilities.objectsTriggeredInThisContext.add(objectType);
        Utilities.isLightningLdvExecution = true;
    }
}
