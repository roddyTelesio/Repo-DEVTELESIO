public with sharing class CLM_PublishDocuments {
    public class ObjectContext {     

        @InvocableVariable(required=true label='agreementId' )
        public String agreementId;

        @InvocableVariable(required=true label='attachmentId' )
        public String attachmentId;
    }

    public class Result {
        @InvocableVariable(required=false label='Is Success ?')
        public Boolean isSuccess;

        @InvocableVariable(required=false label='Error Message')
        public String errorMsg;

        public Result(Boolean isSuccess, String errorMsg){
            this.isSuccess = isSuccess;
            this.errorMsg = errorMsg;
        }


        public Result(Boolean isSuccess, String errorMsg, String docId){
            this.isSuccess = isSuccess;
            this.errorMsg = errorMsg;
        }
    }

    /***
    * @description	Merge CLM documents in docX format through API 
    * @param	    obj 
    * @return		List<Slots> 
    * @exception   	None
    ***/   
    @InvocableMethod(label='[CLM] publish document' description='Publishes documents conga to repository' callout=true)
    public static List<Result> publishDocuments(List<ObjectContext> obj) {
        List<Apttus.CustomClass.AttachmentInfo> attachmentsInfoList = new List<Apttus.CustomClass.AttachmentInfo>();
        
        System.debug(LoggingLevel.DEBUG, 'publishDocuments START with : ' + obj);

        String agreementId = obj[0].agreementId;
        String attachmentId = obj[0].attachmentId;

        try {
            Apttus.AgreementWebService.publishToDocumentRepository(AgreementId, attachmentId);
            return new List<Result>{new Result(true, null, null)};
        } catch (Exception e) {
            System.debug('publishDocuments exception : '+ e.getMessage());
            return new List<Result>{new Result(false, e.getMessage(), null)};
        }
    }
}