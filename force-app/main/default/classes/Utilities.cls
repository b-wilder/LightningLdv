public with sharing class Utilities {
    public static Enum TriggerContext{
        AfterInsert,
        AfterUpdate,
        AfterDelete,
        AfterUndelete
    }

    public static list<String> getStringListFromCsv(String csv){
        return csv.replaceAll(' ','').split(',');
    }

    public class MetadataCallback implements Metadata.Metadata.DeployCallback{
        public void handleResult(   Metadata.DeployResult result,
                                    Metadata.DeployCallbackContext context) {
            if (result.status == Metadata.DeployStatus.Succeeded) {
                System.debug('MetaData deployment of LightningLdv__Object_Trigger_Settings__mdt succeeded. Last Run Time was updated.');
                System.debug('result: ' + result);
            } else { // Deployment was not successful
                System.debug(LoggingLevel.ERROR, 'MetaData deployment of LightningLdv__Object_Trigger_Settings__mdt failed. Last Run Time was not updated.');
                System.debug(LoggingLevel.ERROR, 'result: ' + result);
            }
        }
    }
}
