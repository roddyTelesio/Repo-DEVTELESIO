public with sharing class CLM_CreateDocumentVersionDetails {
   
    public class ObjectContext {     
        @InvocableVariable(required=true label='agreementId' )
        public String agreementId;

        @InvocableVariable(required=false label='templateId' )
        public String templateId;

        @InvocableVariable(required=true label='comment' )
        public String comment;
    }

    public class Result {
        @InvocableVariable(required=false label='Is Success ?')
        public Boolean isSuccess;

        @InvocableVariable(required=false label='Error Message')
        public String errorMsg;

        @InvocableVariable(required=false label='Content Document Version Detail')
        public Apttus__DocumentVersionDetail__c contentDocumentVersionDetail;

        public Result(Boolean isSuccess, String errorMsg){
            this.isSuccess = isSuccess;
            this.errorMsg = errorMsg;
        }


        public Result(Boolean isSuccess, String errorMsg, Apttus__DocumentVersionDetail__c contentDocumentVersionDetail){
            this.isSuccess = isSuccess;
            this.errorMsg = errorMsg;
            this.contentDocumentVersionDetail = contentDocumentVersionDetail;
        }
    }

    /***
    * @description	Method to prepare & do callout to book a b2g appointment
    * @param	    obj 
    * @return		List<Slots> 
    * @exception   	None
    ***/   
    @InvocableMethod(label='[CLM] create document version details' description='Creates document version detail records' callout=true)
    public static List<Result> createDocVerDetails(List<ObjectContext> obj) {
        try{
            System.debug('createDocVerDetails: Start tempId' + obj[0].templateId);
            if(String.isNotBlank(obj[0].templateId)){
                Apttus__DocumentVersionDetail__c  documentVersionDetail = Apttus.AgreementGenerateController.createDocVersionSO(obj[0].agreementId,  obj[0].templateId,  Apttus.AgreementGenerateController.ACTION_GENERATE,  'DOCX',  obj[0].comment);
                System.debug('createDocVerDetails: End ');
                return new List<Result>{ new Result(true, null, documentVersionDetail)};
            }else{
                Apttus__APTS_Template__c temp = [SELECT ID, NAME FROM Apttus__APTS_Template__c LIMIT 1];
                Apttus__DocumentVersionDetail__c  documentVersionDetail = Apttus.AgreementGenerateController.createDocVersionSO(obj[0].agreementId,  temp.Id,  Apttus.AgreementGenerateController.ACTION_GENERATE,  'DOCX',  obj[0].comment);
                
                Apttus__DocumentVersionDetail__c  documentVersionDetailRetrieved = [SELECT Id, Apttus__DocumentVersionId__c FROM Apttus__DocumentVersionDetail__c WHERE Id = :documentVersionDetail.Id];
                documentVersionDetailRetrieved.Apttus__Action2__c = 'Import Offline Agreement';
                documentVersionDetailRetrieved.Apttus__Comment__c = 'Import Offline Agreement';
                update documentVersionDetailRetrieved; 

                Apttus__DocumentVersion__c  documentVersionDetRetrieved = [SELECT Id FROM Apttus__DocumentVersion__c WHERE Id = :documentVersionDetailRetrieved.Apttus__DocumentVersionId__c];
                documentVersionDetRetrieved.Apttus__TemplateId__c = null; 
                documentVersionDetRetrieved.Name = 'Import Offline Agreement';
                update documentVersionDetRetrieved;
                return new List<Result>{ new Result(true, null, documentVersionDetail)};
            }
        }
        catch(Exception e){  
            // Catching the exception and getting the line number
            Integer errorLine = e.getLineNumber();
            String errorMessage = 'createDocVerDetails: An error occurred on line ' + errorLine + ': ' + e.getMessage();
            // Log the error or show it on the user interface
            System.debug(errorMessage);
            System.debug('createDocVerDetails Exception  : ' + e.getMessage());
            return new List<Result>{ new Result(false, e.getMessage())};
        }
    }
}