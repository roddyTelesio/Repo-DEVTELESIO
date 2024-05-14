/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 10-25-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class CLM_CloneAgreementSF {
    public class ObjectContext {     
        @InvocableVariable(required=true label='Initial Agreement record' )
        public sObject agreement;

    }

    public class Result {
        @InvocableVariable(required=false label='Is Success ?')
        public Boolean isSuccess;

        @InvocableVariable(required=false label='Error Message')
        public String errorMsg;

        @InvocableVariable(required=false label='Agreement Generated')
        public Apttus__APTS_Agreement__c agreementGenerated;

        public Result(Boolean isSuccess, String errorMsg){
            this.isSuccess = isSuccess;
            this.errorMsg = errorMsg;
        }


        public Result(Boolean isSuccess, String errorMsg, Apttus__APTS_Agreement__c agreementGenerated){
            this.isSuccess = isSuccess;
            this.errorMsg = errorMsg;
            this.agreementGenerated = agreementGenerated;
        }
    }


    /***
    * @description	Ammend agreement record
    * @param	    obj 
    * @return		List<Slots> 
    * @exception   	None
    ***/   
    @InvocableMethod(label='[CLM] clone record (Salesforce method)' description='Creates a clone of an agreement' callout=true)
    public static List<Result> cloneAgreement(List<ObjectContext> obj) {
        try{
            System.debug('cloneAgreement: Start ');

            Apttus__APTS_Agreement__c initialAgreement = (Apttus__APTS_Agreement__c) obj[0].agreement;
            Apttus__APTS_Agreement__c  clonedAgreement = initialAgreement.clone(false, true, false, false);
            System.debug('cloneAgreement record : ' + clonedAgreement);
            // insert clonedAgreement; 
            System.debug('cloneAgreement: End ');
            return new List<Result>{ new Result(true, null, clonedAgreement)};
            
        }
        catch(Exception e){  
            System.debug('cloneAgreement Exception  : ' + e.getMessage());
            return new List<Result>{ new Result(false, e.getMessage())};
        }
    }
}