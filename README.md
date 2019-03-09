# SFDX  App

## Purpose
1. Enable the development of triggers that can easily be executed in batch to enable maintenance and blackout periods during which integrations and data migrations can occur
2. Take advantage of the increased governer limits of asynchronous apex to execute trigger logic for objects that have to deal with large data volume considerations

## Design
1. Avoid running batch apex more often than is needed. When data is modified, we'll query scheduled jobs to see if a "trigger" job is running within the next 15 minutes for the object in question, and if not we'll schedule one using the System.schedule batch method.
2. Avoid processing during maintenance and blackout periods. If a record is modified during such a period, we'll schedule the next batch to run after it ends
3. Build a single batch class that can work for all objects, and a single trigger handler that can call it. The generic trigger handler will schedule the batch, passing the object context to the batch constructor. The batch class looks up a custom metadata type record to determine which apex class should act as the handler. Because the handler is an interface, the batch class can use the apex Type class to execute some pre-defined methods from the handler (onAfterInsert, onAfterUpdate, onAfterDelete, and onAfterUndelete)
4. Make it easy to implement the trigger handler interface.

## What implementing a "trigger" will look like
1. Create a custom metadata type record that indicates the object api name and the apex class that will act as it's "trigger handler"
2. Write a handler class that implements the LightningLDV__TriggerHandlerInterface interface. It will have the following methods, though it does not need to have logic for all of them.
    * void onAfterInsert(map<Id,sObject> newMap);
    * void onAfterUpdate(map<Id,sObject> newMap);
    * void onAfterDelete(map<Id,sObject> oldMap);
    * void onAfterUndelete(map<Id,sObject> newMap);
3. Create a trigger on the object in question that calls the LightningLDV__GenericTriggerHandler in the appropriate contexts (I'm thinking after insert, after update, after delete, and after undelete, as well as before update if after update is implemented)


## What the generic trigger will do
1. LightningLDV__GenericTriggerHandler determines the object context
2. LightningLDV__GenericTriggerHandler schedules the batch execution, passing the object context to the batch constructor and keeping the following rules in mind
    * If we're in a blackout or maintenance period, schedule after it's over
    * If a batch is already scheduled in the future for this object, do not schedule again
    * If we are being called from another LightningLdv batch context, execute the LightningLDV__TriggerHandlerInterface implementation immediately and synchronously instead of scheduling the batch
3. LightningLDV__GenericTriggerHandler also checks if certain fields (which are configured to be tracked in the custom metadata record) have changed if it is being run from a before update context. It will then write to a long text field indicating which tracked fields have had their values changed


## What the batch will do
1. Lookup a custom metadata record based on the object context
2. Construct a query based on the custom metadata record
3. Execute the LightningLDV__TriggerHandlerInterface implementation

## Dev, Build and Test
* Unlocked package with LightningLDV namespace
* Source-driven package
* Built using sfdx (metadata format and scratch orgs)

## Resources


## Description of Files and Directories


## Issues


