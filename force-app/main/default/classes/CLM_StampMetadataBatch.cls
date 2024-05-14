/**
 * Batch class for processing Apttus__APTS_Agreement__c records and updating metadata.
 */
public class CLM_StampMetadataBatch implements Database.Batchable<sObject>, Database.AllowsCallouts {

    private Integer batchSize;

    /**
     * Constructor to initialize the batch size.
     * @param dynamicBatchSize The number of records to be processed in each batch.
     */
    public CLM_StampMetadataBatch() {
        //this.batchSize = dynamicBatchSize;
    }

    /**
     * Start method to provide the query locator for the batch.
     * @param context The batchable context.
     * @return QueryLocator for the batch.
     */
    public Database.QueryLocator start(Database.BatchableContext context) {
        System.debug('Start method: Querying agreements to process.');
        return Database.getQueryLocator([
            SELECT Id, name
            FROM Apttus__APTS_Agreement__c
            WHERE toProcessStamp__c = true
        ]);
    }

    /**
     * Execute method to process each batch of records.
     * @param context The batchable context.
     * @param scope The list of records in the current batch.
     */
    public void execute(Database.BatchableContext context, List<sObject> scope) {
        System.debug('Execute method: Processing batch of agreements.');
        List<EventLog__c> eventLogs = new List<EventLog__c>();
        List<Apttus__APTS_Agreement__c> agreementsToUpdate = new List<Apttus__APTS_Agreement__c>();

        for (sObject record : scope) {
            Apttus__APTS_Agreement__c currentAgreement = (Apttus__APTS_Agreement__c) record;
            System.debug('Processing Agreement: ' + currentAgreement.Name);

            EventLog__c eventLog = new EventLog__c();
            eventLog.RecordId__c = currentAgreement.Id;
            eventLog.Context__c = 'CLM';
            eventLog.ClassName__c = 'CLM_StampMetadata';

            try {
                boolean completed = makeCalloutAndUpdateAgreement(currentAgreement);

                eventLog.StatusCode__c = completed ? '200' : '500';
                eventLog.Message__c = completed ? 'Stamp Successful' : 'Error during stamp';

                if (completed) {
                    agreementsToUpdate.add(new Apttus__APTS_Agreement__c(Id = currentAgreement.Id, toProcessStamp__c = false));
                }
            } catch (Exception e) {
                System.debug('Exception during processing: ' + e.getMessage());
                eventLog.StatusCode__c = '500';
                eventLog.Message__c = e.getMessage();
            }

            eventLogs.add(eventLog);
        }

        System.debug('Inserting Event Logs.');
        insert eventLogs;

        if (!agreementsToUpdate.isEmpty()) {
            System.debug('Updating agreements to set toProcessStamp__c to false.');
            Database.update(agreementsToUpdate, false);
        }
    }

    /**
     * Helper method for making callouts and updating agreements.
     * @param agreement The agreement to be processed.
     * @return True if the processing is successful, false otherwise.
     */
    private boolean makeCalloutAndUpdateAgreement(Apttus__APTS_Agreement__c agreement) {
        System.debug('Making callout for Agreement: ' + agreement.Name);
        boolean completed = Apttus.ComplyWebService.updateImportedAgreementDocs(agreement.Id);
        // Additional logic here if needed
        return completed;
    }

    /**
     * Finish method to perform any additional logic after batch execution.
     * @param context The batchable context.
     */
    public void finish(Database.BatchableContext context) {
        System.debug('Finish method: Batch execution completed.');
        // Additional logic after batch execution...
    }
}