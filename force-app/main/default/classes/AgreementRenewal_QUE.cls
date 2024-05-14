/***
* @description  Queueable class for deletion of document Version Details (files) when an agreement is copied during renewal
* @group        Agreement
* @see          Agreement_DMN
***/
public with sharing class AgreementRenewal_QUE implements Queueable {


    //#########################################
   //########## STATIC CONSTANTS #############
   //#########################################



    /***
    * @description  Current iteration of the Queuable process. Remains at 0 while 
    *               there are still Agreements to process.
    ***/
    private Integer iteration = 0;
    /***
    * @description  Map of document version detail to be processed
    ***/     
    private Map<ID,Apttus__DocumentVersionDetail__c> dvdMap = null;
    /***
    * @description  Maximum process size of the queue (records)
    ***/  
    private INTEGER MAX_PROCESS_SIZE = 1; 
    /***
    * @description  Max. number of times the queuable requeues itself when it has no
    *               Agreement to process.
    ***/
    private final static Integer MAX_ITER_NBR = 10;

    /* 
    * @description map of agreement Ids that need to be updated after the documents are done processing to indicate that the processing is completed.
    */
    private Map<Id, Apttus__APTS_Agreement__c> agreementsToUpdate; 

    private Id currentAgreementId; 




   public AgreementRenewal_QUE() {
       this.iteration = 0;
       this.agreementsToUpdate = new Map<Id, Apttus__APTS_Agreement__c>();
   }


   /***
   * @description  Private Constructor used internally by the Queueable process to
   *               reenqueue itself when there is nothing to process.
   *               The queuable process should stop when reaching
   *               iteration MAX_UPDATE_NBR. 
   ***/
   @TestVisible
   private AgreementRenewal_QUE(integer iter) {
       System.debug('AgreementRenewal_QUE: init for iteration ' + iter);
       this.iteration = iter;
       
   }
   
   @TestVisible
    private AgreementRenewal_QUE(Map<Id, Apttus__APTS_Agreement__c> agreementsMap){
        this.iteration = 0;
        this.agreementsToUpdate = agreementsMap; 
    }


   //##########################################
   //########### EXECUTION LOGIC ##############
   //##########################################
   
   /***
   * @description  Executes the logic of deletion and clearing files that are linked to the document version details
   * @param        context	Standard QueueableContext (not used, but in standard interface)
   * @exception    None special (all catched and logged).
   ***/     
    public void execute(QueueableContext context){
        System.debug(LoggingLevel.INFO, 'execute: START for AgreementRenewal_QUE for iteration ' + this.iteration);
        // Controlling processDocumentVersionDetails to delete
        if (processDocumentVersionDetails()) {

            if(this.agreementsToUpdate != null && !this.agreementsToUpdate.isEmpty()) {
                processAgreementDocumentCleanup(); 
            }

            System.debug('execute: processDocumentVersionDetails deleted for deleted Agreement');
            if(!Test.isRunningTest()){
                System.enqueueJob(new AgreementRenewal_QUE(this.agreementsToUpdate));
            }
            System.debug(LoggingLevel.INFO, 'execute: END / Public Group deleted for deleted BUs');
        }
        else if(this.agreementsToUpdate != null && !this.agreementsToUpdate.isEmpty()){
            updateAgreementStatus();
            // update this.agreementsToUpdate.values(); 
            this.agreementsToUpdate = null; 
            if(!Test.isRunningTest()){
                System.enqueueJob(new AgreementRenewal_QUE(this.iteration + 1));
            }
        }else if(processAgreementsFlagged()){
            System.debug('');
            if(!Test.isRunningTest()){
                System.enqueueJob(new AgreementRenewal_QUE(this.iteration + 1));
            }
        }
        else{
            System.debug('execute: Nothing to do' + this.iteration);
            if (this.iteration >= MAX_ITER_NBR) {
                System.debug(LoggingLevel.INFO, 'execute: Last iteration reached');
            }
            else {
                if(!Test.isRunningTest()){
                    System.enqueueJob(new AgreementRenewal_QUE(this.iteration + 1));
                }
                System.debug(LoggingLevel.INFO, 'execute: END / Triggering new iteration');
            }
        }
    }

    private boolean processAgreementsFlagged(){
        System.debug('processAgreementsFlagged: Start');

        Map<Id, Apttus__APTS_Agreement__c> agreementToUpdate = new Map<Id, Apttus__APTS_Agreement__c>();

        System.debug('processAgreementsFlagged: Current agreement: ' + this.currentAgreementId);

        Map<Id, Apttus__APTS_Agreement__c> agmtsToClean = new Map<Id, Apttus__APTS_Agreement__c>([
            SELECT ID, Renew_Type__c FROM Apttus__APTS_Agreement__c WHERE DeleteRenewedAgreementDocuments__c = true LIMIT 1
        ]); 
        
        
        if(!agmtsToClean.isEmpty()){

            for(ID agmtId : agmtsToClean.keySet()){
                Map<Id, ContentDocument> cntentsToDelete = new Map<Id, ContentDocument>(); 

                Map<Id, ContentDocumentLink> mapAgToContentDocumentLink = new Map<Id, ContentDocumentLink>(); 
                // select content document to clean up

                for(ContentDocumentLink cdl : [SELECT LinkedEntityId,Id, ContentDocumentId, ContentDocument.Title
                                            FROM ContentDocumentLink 
                                            WHERE LinkedEntityId = :agmtId])
                {
                    Apttus__APTS_Agreement__c currentAgmt = agmtsToClean.get(cdl.LinkedEntityId);

                    System.debug('Title : ' + cdl.ContentDocument.Title);
                    System.debug('currentAgmt.Renew_Type__c : ' + currentAgmt.Renew_Type__c);


                    if(currentAgmt.Renew_Type__c != 'Copy Final Version And Signed PDF'){

                        System.debug('processAgreementsFlagged : Adding content to delete');
                        cntentsToDelete.put(
                            cdl.ContentDocumentId, 
                            new ContentDocument(
                                Id = cdl.ContentDocumentId
                            )
                        );
                    }else if(
                        currentAgmt.Renew_Type__c == 'Copy Final Version And Signed PDF'
                        && !cdl.ContentDocument.Title.contains('Signed_')
                    ){
                        System.debug('processAgreementsFlagged : Adding content to delete non signed documents');
                        cntentsToDelete.put(
                            cdl.ContentDocumentId, 
                            new ContentDocument(
                                Id = cdl.ContentDocumentId
                            )
                        );
                    }
                }   


                agreementToUpdate.put(
                        agmtId,
                        new Apttus__APTS_Agreement__c(
                            Id = agmtId
                            ,DeleteRenewedAgreementDocuments__c = false
                        )
                );

                if(!cntentsToDelete.isEmpty()){
                    System.debug('processAgreementsFlagged: Deleting contents: ' + cntentsToDelete);
                    delete cntentsToDelete.values(); 
                }

                if(!agreementToUpdate.isEmpty()){

                    System.debug('processAgreementsFlagged: updating agreements ' + cntentsToDelete);
                    update agreementToUpdate.values(); 
                    
                }

                return true; 

            }
            
        }
        System.debug('processAgreementsFlagged: End');

        return false;
    }

    private void processAgreementDocumentCleanup(){
        System.debug('processAgreementDocumentCleanup: Start');

        System.debug('processAgreementDocumentCleanup: Current agreement: ' + this.currentAgreementId);
        if(this.currentAgreementId != null){
            Map<Id, Apttus__APTS_Agreement__c> agmtsToClean = new Map<Id, Apttus__APTS_Agreement__c>([
                SELECT ID, Renew_Type__c FROM Apttus__APTS_Agreement__c WHERE Id = :this.currentAgreementId
            ]); 

            Map<Id, ContentDocument> cntentsToDelete = new Map<Id, ContentDocument>(); 

            Map<Id, ContentDocumentLink> mapAgToContentDocumentLink = new Map<Id, ContentDocumentLink>(); 
            // select content document to clean up

            for(ContentDocumentLink cdl : [SELECT LinkedEntityId,Id, ContentDocumentId, ContentDocument.Title
                                        FROM ContentDocumentLink 
                                        WHERE LinkedEntityId = :this.currentAgreementId])
            {
                Apttus__APTS_Agreement__c currentAgmt = agmtsToClean.get(cdl.LinkedEntityId);

                System.debug('Title : ' + cdl.ContentDocument.Title);
                System.debug('currentAgmt.Renew_Type__c : ' + currentAgmt.Renew_Type__c);


                if(currentAgmt.Renew_Type__c != 'Copy Final Version And Signed PDF'){

                    System.debug('processAgreementDocumentCleanup : Adding content to delete');
                    cntentsToDelete.put(
                        cdl.ContentDocumentId, 
                        new ContentDocument(
                            Id = cdl.ContentDocumentId
                        )
                    );
                }else if(
                    currentAgmt.Renew_Type__c == 'Copy Final Version And Signed PDF'
                    && !cdl.ContentDocument.Title.contains('Signed_')
                ){
                    System.debug('processAgreementDocumentCleanup : Adding content to delete non signed documents');
                    cntentsToDelete.put(
                        cdl.ContentDocumentId, 
                        new ContentDocument(
                            Id = cdl.ContentDocumentId
                        )
                    );
                }
            }   


            if(!cntentsToDelete.isEmpty()){
                System.debug('processAgreementDocumentCleanup: Deleting contents: ' + cntentsToDelete);
                delete cntentsToDelete.values(); 
            }
            
        }
        
        
        System.debug('processAgreementDocumentCleanup: End');
    }

    private void updateAgreementStatus(){

        System.debug('updateAgreementStatus start ');
        List<Apttus__APTS_Agreement__c> agreementsToUpdate = new List<Apttus__APTS_Agreement__c>(
        [SELECT ID, Renew_Type__c, Program__r.TypeOfRenew__c FROM Apttus__APTS_Agreement__c WHERE Id IN :this.agreementsToUpdate.values()]
        );

        for(Apttus__APTS_Agreement__c agmt : agreementsToUpdate){
            System.debug('updateAgreementStatus iterating ' + agmt);

            if(agmt.Program__r.TypeOfRenew__c == 'LTA/TR Identical Renew'){
                System.debug('updateAgreementStatus iterating setting identical renew');
                agmt.Apttus__Status_Category__c = 'In Effect'; 
                agmt.Apttus__Status__c = 'Activated'; 
                agmt.IsBeingRenewed__c = false;
            }else if(agmt.Program__r.TypeOfRenew__c == 'LTA/TR Renegotiation' || agmt.Program__r.TypeOfRenew__c == 'Standard Renew' ){
                System.debug('updateAgreementStatus iterating setting Renegotations');
                agmt.Apttus__Status__c = 'Other Party Signatures';
                agmt.Apttus__Status_Category__c = 'In Signatures';
                agmt.IsBeingRenewed__c = false;
            }
        }

        if(!agreementsToUpdate.isEmpty()){
            System.debug('updateAgreementStatus updating agreements: ' + agreementsToUpdate);
            update agreementsToUpdate; 
        }

        System.debug('updateAgreementStatus End ');
    }


    private boolean processDocumentVersionDetails(){
        System.debug('processDocumentVersionDetails start');
        this.dvdMap = new Map<ID,Apttus__DocumentVersionDetail__c>([
            SELECT Id, Apttus__DocumentVersionId__r.Apttus__AgreementId__c
            FROM Apttus__DocumentVersionDetail__c
            WHERE ToProcessDelete__c = true
            ORDER BY systemModStamp asc
            LIMIT :this.MAX_PROCESS_SIZE]);

        if (this.dvdMap.size() == 0) {
            System.debug('processDocumentVersionDetails: END - No DocumentVersionDetails to delete');
            return false;
        }

        List<ContentDocument> contentDocumentsToDelete = new List<ContentDocument>();
        //retrieve content document links
        for(ContentDocumentLink cdl : [SELECT ContentDocumentId 
                                        FROM ContentDocumentLink 
                                        WHERE LinkedEntityId IN :this.dvdMap.keySet()])
        {
            System.debug('processDocumentVersionDetails processing cdl: ' + cdl.Id + ' ' + cdl.ContentDocumentId);
            contentDocumentsToDelete.add(new ContentDocument(Id =cdl.ContentDocumentId));
        }

        if(!contentDocumentsToDelete.isEmpty()){
            System.debug('processDocumentVersionDetails: deleting contentDocs' + contentDocumentsToDelete);
            delete contentDocumentsToDelete; 
        }

        if(!this.dvdMap.values().isEmpty()){
            System.debug('processDocumentVersionDetails deleting dvd: ' + this.dvdMap.values());
            for(Apttus__DocumentVersionDetail__c dvd: this.dvdMap.values()){
                if(
                    dvd.Apttus__DocumentVersionId__r.Apttus__AgreementId__c != null &&    
                !this.agreementsToUpdate.containsKey(dvd.Apttus__DocumentVersionId__r.Apttus__AgreementId__c)){
                    this.agreementsToUpdate.put(
                        dvd.Apttus__DocumentVersionId__r.Apttus__AgreementId__c,
                        new Apttus__APTS_Agreement__c(
                            Id= dvd.Apttus__DocumentVersionId__r.Apttus__AgreementId__c
                            ,IsBeingRenewed__c = false
                        )
                    );

                    this.currentAgreementId = dvd.Apttus__DocumentVersionId__r.Apttus__AgreementId__c;
                }
            }
            delete this.dvdMap.values(); 
        }
        System.debug('processDocumentVersionDetails End');   

        return true;
    }
}