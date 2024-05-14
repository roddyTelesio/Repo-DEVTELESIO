/**
 * @description       : 
 * @author            : Patrick Randrianarisoa
 * @group             : 
 * @last modified on  : 12-12-2023
 * @last modified by  : Patrick Randrianarisoa
 * Modifications Log
 * Ver   Date         Author                   Modification
 * 1.0   22-11-2023   Patrick Randrianarisoa   Initial Version
**/
@isTest
public class CLM_ReinsuredAdressseConcatenation_TST {

    public static String  requestId = Schema.SObjectType.Apttus__AgreementLineItem__c.getRecordTypeInfosByName().get('Request').getRecordTypeId();
    public static String  sectionId = Schema.SObjectType.Apttus__AgreementLineItem__c.getRecordTypeInfosByName().get('Section').getRecordTypeId();
    public static String  treatyId = Schema.SObjectType.Apttus__AgreementLineItem__c.getRecordTypeInfosByName().get('Treaty').getRecordTypeId();
    public static String  CCCId = Schema.SObjectType.Apttus__AgreementLineItem__c.getRecordTypeInfosByName().get('Covered Ceding Companies').getRecordTypeId();

    @TestSetup
    static void makeData(){
        Apttus__APTS_Agreement__c agr = TestFactory.createAgreement('Test Agreement');
        insert agr;
        List<Apttus__AgreementLineItem__c> listAgl = new List<Apttus__AgreementLineItem__c>();
        Apttus__AgreementLineItem__c aglReq = new Apttus__AgreementLineItem__c();
        aglReq.RecordTypeId = requestId;
        aglReq.BillingStreet__c = '123 Main St';
        aglReq.BillingCity__c = 'City';
        aglReq.BillingState__c = 'State';
        aglReq.BillingPostalCode__c = '12345';
        aglReq.BillingCountry__c = 'Country';
        aglReq.RequestLEICodeRiskCarrier__c = 'LEICode';
        aglReq.Apttus__AgreementId__c = agr.id;
        listAgl.add(aglReq);
        Apttus__AgreementLineItem__c aglSec = new Apttus__AgreementLineItem__c();
        aglSec.RecordTypeId = sectionId;
        aglSec.BillingStreet__c = '123 Main St';
        aglSec.BillingCity__c = 'City';
        aglSec.BillingState__c = 'State';
        aglSec.BillingPostalCode__c = '12345';
        aglSec.BillingCountry__c = 'Country';
        aglSec.CedingAccountName__c = 'test';
        aglSec.Apttus__AgreementId__c = agr.id;
        listAgl.add(aglSec);
        Apttus__AgreementLineItem__c aglTreat = new Apttus__AgreementLineItem__c();
        aglTreat.RecordTypeId = treatyId;
        aglTreat.RequestSignedShare__c = 50.0;
        aglTreat.Layer__c = 'Layer123';
        aglTreat.TreatyRef__c = 'Treaty123';
        aglTreat.Apttus__AgreementId__c = agr.id;
        listAgl.add(aglTreat);

        Apttus__AgreementLineItem__c aglCCC = new Apttus__AgreementLineItem__c();
        aglCCC.RecordTypeId = CCCId;
        aglCCC.BillingStreet__c = '123 Main St';
        aglCCC.BillingCity__c = 'City';
        aglCCC.BillingState__c = 'State';
        aglCCC.BillingPostalCode__c = '12345';
        aglCCC.BillingCountry__c = 'Country';
        aglCCC.CedingAccountName__c = 'test';
        aglCCC.Apttus__AgreementId__c = agr.id;
        listAgl.add(aglCCC);

        insert listAgl;

    }

    @isTest
    public static void testGetConcatenationReinsuredAdresse() {

        CLM_ReinsuredAdressseConcatenation.InputVariables input1 = new CLM_ReinsuredAdressseConcatenation.InputVariables();
        input1.agl = [SELECT RecordTypeId,BillingStreet__c,BillingCity__c,BillingState__c,BillingPostalCode__c,BillingCountry__c,RequestLEICodeRiskCarrier__c,CedingAccountName__c,RequestSignedShare__c,Layer__c,TreatyRef__c FROM Apttus__AgreementLineItem__c WHERE RecordTypeId =:requestId];

        CLM_ReinsuredAdressseConcatenation.InputVariables input2 = new CLM_ReinsuredAdressseConcatenation.InputVariables();
        input2.agl = [SELECT RecordTypeId,BillingStreet__c,BillingCity__c,BillingState__c,BillingPostalCode__c,BillingCountry__c,RequestLEICodeRiskCarrier__c,CedingAccountName__c,RequestSignedShare__c,Layer__c,TreatyRef__c FROM Apttus__AgreementLineItem__c WHERE RecordTypeId =:sectionId];

        CLM_ReinsuredAdressseConcatenation.InputVariables input3 = new CLM_ReinsuredAdressseConcatenation.InputVariables();
        input3.agl = [SELECT RecordTypeId,BillingStreet__c,BillingCity__c,BillingState__c,BillingPostalCode__c,BillingCountry__c,RequestLEICodeRiskCarrier__c,CedingAccountName__c,RequestSignedShare__c,Layer__c,TreatyRef__c FROM Apttus__AgreementLineItem__c WHERE RecordTypeId =:treatyId];

        CLM_ReinsuredAdressseConcatenation.InputVariables input4 = new CLM_ReinsuredAdressseConcatenation.InputVariables();
        input4.agl = [SELECT RecordTypeId,BillingStreet__c,BillingCity__c,BillingState__c,BillingPostalCode__c,BillingCountry__c,RequestLEICodeRiskCarrier__c,CedingAccountName__c,RequestSignedShare__c,Layer__c,TreatyRef__c FROM Apttus__AgreementLineItem__c WHERE RecordTypeId =:CCCId];

        List<CLM_ReinsuredAdressseConcatenation.InputVariables> inputList = new List<CLM_ReinsuredAdressseConcatenation.InputVariables>();
        inputList.add(input1);
        inputList.add(input2);
        inputList.add(input3);
        inputList.add(input4);

        // Test the method
        Test.startTest();
        List<CLM_ReinsuredAdressseConcatenation.Result> result = CLM_ReinsuredAdressseConcatenation.getConcatenationReinsuredAdresse(inputList);
        Test.stopTest();

        // Verify the result
        System.assertEquals(4, result.size(), 'Expected one result');
    }

    @isTest
    public static void testGetConcatenationReinsuredAdresseFail() {

        List<CLM_ReinsuredAdressseConcatenation.InputVariables> inputList = new List<CLM_ReinsuredAdressseConcatenation.InputVariables>();
        inputList.add(null);
    

        // Test the method
        Test.startTest();
        List<CLM_ReinsuredAdressseConcatenation.Result> result = CLM_ReinsuredAdressseConcatenation.getConcatenationReinsuredAdresse(inputList);
        Test.stopTest();
    }
}