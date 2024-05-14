/**
 * @description       : 
 * @author            : Patrick Randrianarisoa
 * @group             : 
 * @last modified on  : 03-11-2023
 * @last modified by  : Patrick Randrianarisoa
 * Modifications Log
 * Ver   Date         Author                   Modification
 * 1.0   12-09-2023   Patrick Randrianarisoa   Initial Version
**/
@isTest
public class XmlRpcGenerator_TST {
    public static Id acceptationRecordTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Acceptation').getRecordTypeId();

    @TestSetup
    static void makeData(){
        List<ContentVersion> contentVersions = new List<ContentVersion>();
        for (Integer i = 5; i > 0; i--) {
            ContentVersion cv = TestFactory.createContentVersion('1','1','1','Test Content ' + i,Blob.valueOf('Test Content 2'),'test');
            cv.TECH_PhaseNumber__c =i;
            contentVersions.add(cv);
        }
        insert contentVersions;

        Apttus__APTS_Agreement__c initialAgreement = TestFActory.createAgreement('Test Agreement');
        initialAgreement.recordTypeId = acceptationRecordTypeId;
        insert initialAgreement;
        Universign_Transaction__c trans = TestFactory.createUniversignTransaction('Test Transaction');
        trans.Agreement__c = initialAgreement.Id;
        trans.successURL__c = 'https://success.com';
        trans.cancelURL__c = 'https://cancel.com';
        trans.failURL__c = 'https://fail.com';
        trans.certificateType__c = 'simple';
        trans.invitationMessage__c = 'Test invitation';
        insert trans;

        List<sObject> testSigners = new List<sObject>();
        for (Integer i = 0; i < 3; i++) {
            Universign_signer__c signer = TestFactory.createUniversignsigner(trans.id);
            signer.put('FirstName__c','First' + i);
            signer.put('LastName__c','Last' + i);
            signer.put('Email__c','test' + i + '@example.com');
            testSigners.add(signer);
        }
        
        insert testSigners; 
    }

    @isTest
    static void testGenerateXmlRpcString() {
        // Test the 'generateXmlRpcString' method.

        // Define test data for the 'generateXmlRpcString' method.
        String methodName = 'TestMethod';
        Map<String, Object> params = new Map<String, Object>{
            'param1' => 'Value1',
            'param2' => 42,
            'param3' => Datetime.newInstance(2023, 10, 26, 12, 0, 0)
        };
        List<sObject> contentVersions = [SELECT id FROM contentVersion];
        List<Object> signers = [SELECT FirstName__c,LastName__c,Email__c,Phone__c,role__c from  Universign_signer__c];
        Integer countTotalPages = 5;

        // Call the 'generateXmlRpcString' method to generate an XML-RPC string.
        String xmlRpcString = XmlRpcGenerator.generateXmlRpcString(methodName, params, contentVersions, signers, countTotalPages);

        // Add assertions to verify the generated XML-RPC string.
        // For example, you can check if the string contains specific XML elements and values.
        System.assert(xmlRpcString.contains('<methodCall>'));
        System.assert(xmlRpcString.contains('<methodName>TestMethod</methodName>'));
        // Add more assertions based on your test case.
    }

    @isTest
    static void testGenerateXMLRPCMethodString() {
        String methodName = 'testMethod';
        String xxx = 'Hello World';
        String xmlString = XmlRpcGenerator.generateXMLRPCMethodString(methodName, xxx);
    }
}