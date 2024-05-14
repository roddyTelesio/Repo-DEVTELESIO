/**
 * @description       : Queue to generate PDF from Final Docs for imported agreements
 * @author            : Azhar Nahoor
 * @group             : CLM
 * @last modified on  : 01-04-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class CLM_CreatePDFForImportedAgreements_QUE implements Queueable, Database.AllowsCallouts {

    private Integer QueueSize = 1;

    //Constructor
    public CLM_CreatePDFForImportedAgreements_QUE() {
        this(1);
    }

    public CLM_CreatePDFForImportedAgreements_QUE(Integer QueueSize) {
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
        System.debug('CLM_CreatePDFForImportedAgreements_QUE START');

        try{
            String apiServerURL = System.Url.getOrgDomainUrl().toExternalForm() + '/services/Soap/u/58.0/' + UserInfo.getOrganizationId();

            //Get Universign transaction
            List<Apttus__DocumentVersionDetail__c> docVersionDetails = [
                SELECT Id, Apttus__Title__c, Apttus__ContentVersionId__c, TECH_AgreementId__c, TECH_GeneratePDFByBatch__c, TECH_GeneratePDF_Error__c
                FROM   Apttus__DocumentVersionDetail__c 
                WHERE  TECH_isFromThemis__c = true
                AND    TECH_GeneratePDFByBatch__c = true
                AND    Apttus__DocumentInfo__c = 'Final'
                AND TECH_GeneratePDF_Error__c = null
                //AND    Name = '1.0.0'
                LIMIT  :QueueSize
            ];
    
            System.debug('Number of docVersionDetails queried: ' + docVersionDetails.size());
            For(Apttus__DocumentVersionDetail__c docVersionDetail : docVersionDetails){ 
                try{
                    //1. Get ContentVersion
                    List<ContentVersion> cv = [SELECT id, ContentDocumentId, Title FROM ContentVersion WHERE ID =: docVersionDetail.Apttus__ContentVersionId__c];
                

                    Id convertedDocId;
                    //2. Call Callout API 
                    if(!Test.isRunningTest()){
                        convertedDocId = Apttus.MergeWebService.convertWordDocToPDF(cv[0].ContentDocumentId, cv[0].Title,
                        false, false, null, null, UserInfo.getSessionId(), apiServerURL);  
                        System.debug('CLM_CreatePDFForImportedAgreements_QUE convertedDocId ' + convertedDocId);
                    }else{
                        convertedDocId = cv[0].contentDocumentId;
                    }


                    
                    //3. Create contentDocumentLink on the agreement if it doesn't exist already
                    List<ContentDocumentLink> cdls = [
                        SELECT id 
                        FROM contentDocumentLink 
                        WHERE LinkedEntityId =  :docVersionDetail.TECH_AgreementId__c 
                        AND ContentDocumentId = :convertedDocId
                    ];
                    if(cdls == null || cdls.isEmpty()){
                        ContentDocumentLink cdl = new ContentDocumentLink();
                        cdl.LinkedEntityId = docVersionDetail.TECH_AgreementId__c;
                        cdl.ContentDocumentId = convertedDocId;
                        insert cdl;
                    }

                    //4. Update TECH_GeneratePDFByBatch__c flag on DocumentVersionDetail
                    docVersionDetail.TECH_GeneratePDFByBatch__c = false;
                    update docVersionDetail;
                }catch(Exception e){
                    system.debug(e.getMessage());
                    docVersionDetail.TECH_GeneratePDF_Error__c = e.getMessage();
                    update docVersionDetail;
                }
            }
            
    
            if(docVersionDetails.size() == QueueSize){
                //Re-initialize Job
                System.debug('CLM_CreatePDFForImportedAgreements_QUE Enqueue New job ');
               Id JobId = System.enqueueJob(new CLM_CreatePDFForImportedAgreements_QUE());
            }else{
                System.debug('CLM_CreatePDFForImportedAgreements_QUE FINISH ');
            }
        }catch(Exception e){
            System.debug('CLM_CreatePDFForImportedAgreements_QUE Exception occured : ' + e.getMessage());
        }
        System.debug('CLM_CreatePDFForImportedAgreements_QUE END');
    }

}