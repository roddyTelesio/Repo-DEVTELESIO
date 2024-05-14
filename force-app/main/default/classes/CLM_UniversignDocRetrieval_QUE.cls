/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 01-04-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class CLM_UniversignDocRetrieval_QUE implements Queueable, Database.AllowsCallouts{
    private Integer QueueSize = 1;

    //Constructor
    public CLM_UniversignDocRetrieval_QUE() {
        this(1);
    }

    public CLM_UniversignDocRetrieval_QUE(Integer QueueSize) {
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
        System.debug('CLM_UniversignDocRetrieval_QUE START');

        // Calculate the timestamp for one hour ago
        DateTime oneHourAgo = DateTime.now().addHours(-1);

        //Get Universign transaction
        List<Universign_Transaction__c> transactions = [
            SELECT Id, transactionId__c, Status__c, LastDateCheckedByBatch__c, SignedDocContentVersion__c, DocumentsFetched__c , Agreement__c
            FROM   Universign_Transaction__c
            WHERE  (LastDateCheckedByDocRetBatch__c < :oneHourAgo OR LastDateCheckedByDocRetBatch__c = null)
            AND    DocumentsFetched__c = NULL
            AND    Status__c  IN ('completed')
            AND    SignedDocContentVersion__c = NULL 
            AND    transactionId__c != null 
            LIMIT 1
        ];

        String errorMessage;
        
        System.debug('Number of transactions queried: ' + transactions.size());
        For(Universign_Transaction__c transac : transactions){
            try{
                System.debug('universignTransaction.status__c completed.. getting document');

                //4. Create an instance of ObjectContext and set necessary values
                universign_getDocument.ObjectContext contextGetDoc = new universign_getDocument.ObjectContext();
                contextGetDoc.universignTransaction = transac;

                // Call the getTransactionDoc method
                List<universign_getDocument.Result> resultsGetDocs = callGetTransactionDoc(contextGetDoc);

                if (resultsGetDocs != null && !resultsGetDocs.isEmpty()) {
                    universign_getDocument.Result resultsGetDoc = resultsGetDocs[0];
                    if (resultsGetDoc.isSuccess) {
                        // Handle successful response with contentVersionId
                        String contentVersionId = resultsGetDoc.contentVersionId;
                        // Do something with contentVersionId
                        System.debug('Received contentVersionId: ' + contentVersionId);

                        transac.status__c = 'completed'; transac.DocumentsFetched__c = true; transac.SignedDocContentVersion__c = contentVersionId; transac.LastDateCheckedByBatch__c = datetime.now();
                    } else { errorMessage = resultsGetDoc.errorMsg; System.debug('Error occurred: ' + errorMessage);}
                } else {System.debug('CallGetTransactionDoc : No results returned');}
            }catch(Exception e){
                transac.LastDateCheckedByDocRetBatch__c = datetime.now(); update transac;
                universign_sendTransaction.createUniversignEventLog(String.valueOf(transac.Id), 'CLM_UniversignRetrieval_QUE', null,(e.getMessage()).left(250), 'NOT_SET', e.getStackTraceString());
            }

            transac.LastDateCheckedByDocRetBatch__c = datetime.now();
            update transac;
        }

        if(transactions.size() == QueueSize && !(Test.isRunningTest())){
            //Re-initialize Job
            System.debug('CLM_UniversignDocRetrieval_QUE Enqueue New job ');
           Id JobId = System.enqueueJob(new CLM_UniversignDocRetrieval_QUE());
        }else{System.debug('CLM_UniversignDocRetrieval_QUE FINISH ');}

        System.debug('CLM_UniversignDocRetrieval_QUE END');
    }

    // Method to call getTransactionDoc from universign_getDocument class
    public static List<universign_getDocument.Result> callGetTransactionDoc(universign_getDocument.ObjectContext obj) {
        universign_getDocument.ObjectContext context = new universign_getDocument.ObjectContext();
        context.universignTransaction = obj.universignTransaction;
        
        // universign_getDocument universignDoc = new universign_getDocument();
        return universign_getDocument.getTransactionDoc(new List<universign_getDocument.ObjectContext>{ context });
    }
}