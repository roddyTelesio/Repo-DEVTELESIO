/**
 * @description       : Queue to check-in imported clauses
 * @author            : Azhar Nahoor
 * @group             : CLM
 * @last modified on  : 01-04-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class CLM_UniversignRetrieval_QUE implements Queueable, Database.AllowsCallouts {

    private Integer QueueSize = 1;

    //Constructor
    public CLM_UniversignRetrieval_QUE() {
        this(1);
    }

    public CLM_UniversignRetrieval_QUE(Integer QueueSize) {
        this.QueueSize = QueueSize;
    }

    /***
    * @description EXECUTE method of Queue
    * @param       QueueableContext context
    * @return      void 
    * @exception   none special.
    * @author      Telesio Consultant
    * @date        24/11/2023
    ***/ 
    public void execute(QueueableContext context){
        System.debug('CLM_templateCheckIn_QUE START');


        // Calculate the timestamp for one hour ago
        DateTime oneHourAgo = DateTime.now().addHours(-1);
        System.debug('oneHourAgo'+ oneHourAgo);

        //Get Universign transaction
        List<Universign_Transaction__c> transactions = [
            SELECT Id, transactionId__c, Status__c, LastDateCheckedByBatch__c, SignedDocContentVersion__c, DocumentsFetched__c 
            FROM   Universign_Transaction__c
            WHERE  (LastDateCheckedByBatch__c < :oneHourAgo OR LastDateCheckedByBatch__c = NULL)
            AND    DocumentsFetched__c = NULL
            AND    Status__c NOT IN ('expired', 'canceled', 'failed', 'completed')
            AND    transactionId__c != null 
            LIMIT 1
        ];

        String errorMessage;
        
        System.debug('Number of transactions queried: ' + transactions.size());
        For(Universign_Transaction__c transac : transactions){

            try{
                // 1. Create an instance of ObjectContext and set necessary values
                universign_getTransactionInfo.ObjectContext contextgetTransaction = new universign_getTransactionInfo.ObjectContext();
                contextgetTransaction.universignTransaction = transac;

                // 2. Call the sendTransaction method
                List<universign_getTransactionInfo.Result> results = callSendTransaction(contextgetTransaction);

                // 3. Handle the response
                if (results != null && !results.isEmpty()) {
                    universign_getTransactionInfo.Result result_getTransaction = results[0];
                    if (result_getTransaction.isSuccess) {
                        // Handle successful response
                        List<Universign_signer__c> signers = result_getTransaction.signers;
                        Universign_signer__c currentSigner = result_getTransaction.currentSigner;
                        Universign_Transaction__c universignTransaction = result_getTransaction.universignTransaction;
                        // Perform actions with the retrieved data
                        System.debug('Received signers: ' + signers);
                        System.debug('Current signer: ' + currentSigner);
                        System.debug('Universign transac: ' + universignTransaction);

                    } else {
                        // Handle failure with error message
                        errorMessage = result_getTransaction.errorMsg;
                        universign_sendTransaction.createUniversignEventLog(String.valueOf(transac.Id), 'CLM_UniversignRetrieval_QUE', null,(errorMessage).left(250), 'NOT_SET', null);
                        // transac.
                        // Handle error message
                        System.debug('Error occurred: ' + errorMessage);
                    }
                } else {
                    // Handle scenario where no results were returned
                    System.debug('No results returned');
                }

                // Set flag to not enter batch again today
                transac.LastDateCheckedByBatch__c = datetime.now();
                update transac;

            }catch(Exception e){
                // Set flag to not enter batch again today
                transac.LastDateCheckedByBatch__c = datetime.now();update transac;
                universign_sendTransaction.createUniversignEventLog(String.valueOf(transac.Id), 'CLM_UniversignRetrieval_QUE', null,(e.getMessage()).left(250), 'NOT_SET', e.getStackTraceString());
                return;
            }
        }
        

        if(transactions.size() == QueueSize && !(Test.isRunningTest())){
            //Re-initialize Job
            System.debug('CLM_UniversignRetrieval_QUE Enqueue New job ');
           Id JobId = System.enqueueJob(new CLM_UniversignRetrieval_QUE());
        }else{
            System.debug('CLM_UniversignRetrieval_QUE FINISH ');
        }

        System.debug('CLM_UniversignRetrieval_QUE END');
    }

    // Method to call sendTransaction from universign_getTransactionInfo class
    public static List<universign_getTransactionInfo.Result> callSendTransaction(universign_getTransactionInfo.ObjectContext obj) {
        universign_getTransactionInfo.ObjectContext context = new universign_getTransactionInfo.ObjectContext();
        context.universignTransaction = obj.universignTransaction;
        
        // universign_getTransactionInfo transactionInfo = new universign_getTransactionInfo();
        return universign_getTransactionInfo.sendTransaction(new List<universign_getTransactionInfo.ObjectContext>{ context });
    }

    // Method to handle the response
    // public static void handleTransactionResponse(List<universign_getTransactionInfo.Result> results) {
    //     if (results != null && !results.isEmpty()) {
    //         universign_getTransactionInfo.Result result = results[0];
    //         if (result.isSuccess) {
    //             // Handle successful response
    //             List<Universign_signer__c> signers = result.signers;
    //             Universign_signer__c currentSigner = result.currentSigner;
    //             Universign_Transaction__c universignTransaction = result.universignTransaction;
    //             // Perform actions with the retrieved data
    //             System.debug('Received signers: ' + signers);
    //             System.debug('Current signer: ' + currentSigner);
    //             System.debug('Universign transaction: ' + universignTransaction);
    //         } else {
    //             // Handle failure with error message
    //             String errorMessage = result.errorMsg;
    //             // Handle error message
    //             System.debug('Error occurred: ' + errorMessage);
    //         }
    //     } else {
    //         // Handle scenario where no results were returned
    //         System.debug('No results returned');
    //     }
    // }

    // // Method to handle the response
    // public static void handleResponse(List<universign_getDocument.Result> results) {
    //     if (results != null && !results.isEmpty()) {
    //         universign_getDocument.Result result = results[0];
    //         if (result.isSuccess) {
    //             // Handle successful response with contentVersionId
    //             String contentVersionId = result.contentVersionId;
    //             // Do something with contentVersionId
    //             System.debug('Received contentVersionId: ' + contentVersionId);
    //         } else {
    //             // Handle failure with error message
    //             String errorMessage = result.errorMsg;
    //             // Handle error message
    //             System.debug('Error occurred: ' + errorMessage);
    //         }
    //     } else {
    //         // Handle scenario where no results were returned
    //         System.debug('No results returned');
    //     }
    // }
}