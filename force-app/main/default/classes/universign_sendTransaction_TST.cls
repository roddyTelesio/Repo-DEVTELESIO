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
public class universign_sendTransaction_TST {

    public static Id acceptationRecordTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Acceptation').getRecordTypeId();

    @TestSetup
    static void makeData(){
        ContentVersion cv1 = TestFactory.createContentVersion('1','1','1','Test CV1',Blob.valueOf('Test Content 1'),'test');
        insert cv1;
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
    static void testSendTransactionSuccess() {
        // Test data setup
        Universign_SendTransaction.ObjectContext objContext = new Universign_SendTransaction.ObjectContext();
        Universign_SendTransaction.Result expectedResult = new Universign_SendTransaction.Result(true, 'http://example.com', '12345');
        
        // Populate objContext with required data for testing
        objContext.contentVersions = [SELECT Id,title,ContentDocumentId FROM ContentVersion LIMIT 1];
        // objContext.signatories = createSignatories();
        objContext.universignTransaction = [SELECT Id,profile__c,mustContactFirstSigner__c,finalDocSent__c,finalDocRequesterSent__c,language__c,chainingMode__c FROM Universign_Transaction__c LIMIT 1];
        
        Test.startTest();
        // Mock the HTTP callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(expectedResult));
        
        // Test the sendTransaction method
        List<Universign_SendTransaction.Result> results = Universign_SendTransaction.sendTransaction(new List<Universign_SendTransaction.ObjectContext>{objContext});
        Test.stopTest();
        // Assert the results
        System.assertEquals(1, results.size());
        Universign_SendTransaction.Result actualResult = results[0];
        // System.assertEquals(expectedResult.isSuccess, actualResult.isSuccess);
        // System.assertEquals(expectedResult.responseBody, actualResult.responseBody);
        // System.assertEquals(expectedResult.transactionId, actualResult.transactionId);
    }

    @IsTest
    static void testGetSigners() {
        Universign_Transaction__c trans = [SELECT id,successURL__c,cancelURL__c,failURL__c,certificateType__c,invitationMessage__c FROM  Universign_Transaction__c LIMIT 1 ];
        List<sObject> testSigners = [SELECT FirstName__c,LastName__c,Email__c,Phone__c,role__c from  Universign_signer__c];
        // Call the method to be tested
        List<Object> result = universign_sendTransaction.getSigners(testSigners, trans);

        System.assertEquals(3, result.size(), 'Expected 3 signers');
    }

    // Mock HTTP response generator for callout testing
    public class MockHttpResponseGenerator implements HttpCalloutMock {
        private Universign_SendTransaction.Result expectedResult;

        public MockHttpResponseGenerator(Universign_SendTransaction.Result expectedResult) {
            this.expectedResult = expectedResult;
        }

        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setBody('{"id": "12345", "url": "http://example.com"}');
            res.setStatusCode(200);
            return res;
        }
    }
    
    @IsTest
    static void testgetSignatureFields() {
		List<sObject> testSigners = [SELECT FirstName__c,LastName__c,Email__c,Phone__c,role__c from  Universign_signer__c];
        // Call the method to be tested
        List<Object> result = universign_sendTransaction.getSignatureFields(testSigners, 'test',5);
    }
}