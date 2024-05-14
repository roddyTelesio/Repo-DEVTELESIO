/**
 * @description       : 
 * @author            : Patrick Randrianarisoa
 * @group             : 
 * @last modified on  : 30-11-2023
 * @last modified by  : Patrick Randrianarisoa
 * Modifications Log
 * Ver   Date         Author                   Modification
 * 1.0   14-11-2023   Patrick Randrianarisoa   Initial Version
**/
public with sharing class CLM_ReinsuredAdressseConcatenation {
    public class InputVariables{
        @InvocableVariable(required=true label='Agreement Line item record' )
        public Apttus__AgreementLineItem__c agl;
    }

    public class Result {
        @InvocableVariable(required=false label='Is Success ?')
        public Boolean isSuccess;

        @InvocableVariable(required=false label='Error Message')
        public String errorMsg;

        @InvocableVariable(required=false label='Reinsured and Adresse concatenation')
        public String textValue;

        public Result(Boolean isSuccess, String errorMsg, String textValue){
            this.isSuccess = isSuccess;
            this.errorMsg = errorMsg;
            this.textValue = textValue;
        }
    }

    @InvocableMethod(label='[CLM] Get concatenation reinsured and adresses' description='Get concatenation reinsured and adresses of AGL record')
    public static List<Result> getConcatenationReinsuredAdresse(List<InputVariables> lstInputVariables) {
        try{
            List<Result> resultlist = new List<Result>();
            for (InputVariables inputVar : lstInputVariables) {
                Apttus__AgreementLineItem__c agl = inputVar.agl;
                String text ='';
                String nameRtAGL = Schema.getGlobalDescribe().get('Apttus__AgreementLineItem__c').getDescribe().getRecordTypeInfosById().get(agl.RecordTypeId).getName();

                if(nameRtAGL == 'Request'){
                    // text = agl.RiskCarrierName__c;
                    text ='Whose head office is at, \r\n';text += agl.BillingStreet__c != null ? agl.BillingStreet__c + ', ' : '';text += agl.BillingCity__c != null ? agl.BillingCity__c + ', ' : '';text += agl.BillingState__c != null ? agl.BillingState__c + ', ' : '';text += agl.BillingPostalCode__c != null ? agl.BillingPostalCode__c + ', ' : '';text += agl.BillingCountry__c != null ? agl.BillingCountry__c :'';
                    // text += '\r\nLEI code: '+agl.RequestLEICodeRiskCarrier__c;

                }else if(nameRtAGL == 'Covered Ceding Companies'){
                    text = '-'+ agl.CedingAccountName__c;
                    text +='\r\n Whose head office is at, \r\n';
                    // text +='';
                    text += agl.BillingStreet__c != null ? agl.BillingStreet__c + ', ' : '';
                    text += agl.BillingCity__c != null ? agl.BillingCity__c + ', ' : '';
                    text += agl.BillingState__c != null ? agl.BillingState__c + ', ' : '';
                    text += agl.BillingPostalCode__c != null ? agl.BillingPostalCode__c + ', ' : '';
                    text += agl.BillingCountry__c != null ? agl.BillingCountry__c : '';
                    text += '\r\n \r\n \r\n' ;

                }else if(nameRtAGL == 'Treaty'){
                    text = agl.RequestSignedShare__c + '% of layer '+agl.Layer__c+' Underlying Reinsurance Agreement n° '+agl.TreatyRef__c;
                }    
                resultlist.Add(new Result(true, null, text));
            }
            return resultlist;
        }
        catch(Exception e){  System.debug('getPicklistLabelByApiName Exception  : ' + e.getMessage());return new List<Result>{ new Result(false, e.getMessage(), null)};}
    }
}