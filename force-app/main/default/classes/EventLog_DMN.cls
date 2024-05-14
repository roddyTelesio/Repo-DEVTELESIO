/***
* @author      Telesio Dev
* @date        16/09/2019
* @description Class implementing the main business rules for the EventLog object.
* @group       EventLog
* @see         EventLog_CST
*
***/

// @TODO review all Custom Labels to check if to be changed by simple static constants

public with sharing class EventLog_DMN {

    // ###############################################################
    // ######################## STATIC VARIABLES  ####################
    // ###############################################################


    /***
    * @description Notifies LWC components through platform event that a reponse was received by datafactory
    * @param       eventList    List of eventlog records being created.
    * @return      void           Nothing (the fields in accountList are updated)
    * @exception   none special.
    * @author      telesio dev
    * @date        19/05/2022       
    ***/
    public static void onDataFactoryNotify(List<EventLog__c> eventList){
        System.debug('onDataFactoryNotify: Start');


        List<QuoteTableResponse__e> eventsToPublish = new List<QuoteTableResponse__e>();
        for(EventLog__c e : eventList){
            System.debug('onDataFactoryNotify: Processing ' + e);
            if(e.Context__c == EventLog_CST.CONTEXT_DF){

                // retrieve file download URL 
        
                eventsToPublish.add(
                    new QuoteTableResponse__e(
                        classeurId__c=e.RecordId__c
                        ,fileUrl__c = createClasseurs.getFileList(new List<String>{e.RecordId__c})
                        )
                );
            }
        }
        System.debug('onDataFactoryNotify: End');
        if(!eventsToPublish.isEmpty()){
            // Call method to publish events
            List<Database.SaveResult> results = EventBus.publish(eventsToPublish);

            // Inspect publishing result for each event
            for (Database.SaveResult sr : results) {
                if (sr.isSuccess()) {
                    System.debug('Successfully published event.');
                } else {
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('Error returned: ' +
                                    err.getStatusCode() +
                                    ' - ' +
                                    err.getMessage());
                    }
                }       
            }
        }
    }
}