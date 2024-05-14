/**
 * @description       : 
 * @author            : Patrick Randrianarisoa
 * @group             : 
 * @last modified on  : 05-01-2024
 * @last modified by  : Patrick Randrianarisoa 
 * Modifications Log
 * Ver   Date         Author                   Modification
 * 1.0   05-01-2024   Patrick Randrianarisoa   Initial Version
**/
public with sharing class CLM_ActivateAgreement {
    public class ObjectContext {     

        @InvocableVariable(required=true label='agreementId' )
        public String agreementId;

        @InvocableVariable(required=true label='activateDocIds' )
        public List<String> activateDocIds;

        @InvocableVariable(required=true label='remDocIds' )
        public List<String> remDocIds;
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
    @InvocableMethod(label='[CLM] activate agreement' description='Merges multiple documents' callout=true)
    public static List<Result> activateDocuments(List<ObjectContext> obj) {
        List<Apttus.CustomClass.AttachmentInfo> attachmentsInfoList = new List<Apttus.CustomClass.AttachmentInfo>();
        
        System.debug(LoggingLevel.DEBUG, 'activateDocuments START with : ' + obj);

        // String agreementId = obj[0].agreementId;
        // List<String> activateDocIds = obj[0].activateDocIds;
        // List<String> remDocIds = null;
        String agreementId;
        List<String> activateDocIds;
        List<String> remDocIds = null;
        List<Result> lsrRes = new List<Result>(); 
        for(ObjectContext eachObj : obj){
            agreementId = eachObj.agreementId;
            activateDocIds = eachObj.activateDocIds;
            try {
                Apttus.AgreementWebService.activateAgreement(AgreementId, activateDocIds, remDocIds);
                lsrRes.add(new Result(true, null, null));
            } catch (Exception e) {
                System.debug('activateDocuments exception : '+ e.getMessage());
                lsrRes.add(new Result(false, e.getMessage(), null));
            }
        }

        return lsrRes;

    }
}