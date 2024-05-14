/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 09-05-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class CLM_ComplyImportedDocs {
   
    public class ObjectContext {     
        @InvocableVariable(required=true label='agreementId' )
        public String agreementId;
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
    }

    /***
    * @description	Method to prepare & do callout to book a b2g appointment
    * @param	    obj 
    * @exception   	None
    ***/   
    @InvocableMethod(label='[CLM] Comply imported documents on documentVersionDetails' description='Comply imported documents on documentVersionDetails' callout=true)
    public static List<Result> complyImportedDocs(List<ObjectContext> obj) {
        try{
            System.debug('complyImportedDocs: Start ');
            Apttus.ComplyWebService.updateImportedAgreementDocs(obj[0].agreementId);
            System.debug('complyImportedDocs: End ');
            return new List<Result>{ new Result(true, null)};
        }
        catch(Exception e){  
            System.debug('complyImportedDocs Exception  : ' + e.getMessage());
            return new List<Result>{ new Result(false, e.getMessage())};
        }
    }
}