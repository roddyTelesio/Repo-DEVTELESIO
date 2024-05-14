/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 10-25-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class CLM_AmmendAgreement {
    
    
    public class ObjectContext {     
        @InvocableVariable(required=true label='Initial Agreement record' )
        public String agreementId;

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
    @InvocableMethod(label='[CLM] Ammend an agreement' description='Creates ammendment record for the given agreement' callout=true)
    public static List<Result> createAmmendment(List<ObjectContext> obj) {
        try{
            System.debug('createAmmendment: Start ');
            Apttus__APTS_Agreement__c  ammendedAgreement = Apttus.AgreementWebService.amendAgreement(obj[0].agreementId);
            System.debug('createAmmendment record created: ' + ammendedAgreement);
            insert ammendedAgreement; 
            System.debug('createAmmendment: End ');
            return new List<Result>{ new Result(true, null, ammendedAgreement)};
            
        }
        catch(Exception e){  
            System.debug('createAmmendment Exception  : ' + e.getMessage());
            return new List<Result>{ new Result(false, e.getMessage())};
        }
    }
}