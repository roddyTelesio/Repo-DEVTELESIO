/**
 * @description       : 
 * @author            : Patrick Randrianarisoa
 * @group             : 
 * @last modified on  : 12-09-2023
 * @last modified by  : Patrick Randrianarisoa
 * Modifications Log
 * Ver   Date         Author                   Modification
 * 1.0   12-09-2023   Patrick Randrianarisoa   Initial Version
**/
@isTest
public class universign_getTransactionInfo_TST {

    public static Id acceptationRecordTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Acceptation').getRecordTypeId();

    @testSetup
    static void setupTestData() {
        Apttus__APTS_Agreement__c initialAgreement = TestFActory.createAgreement('Test Agreement');
        initialAgreement.recordTypeId = acceptationRecordTypeId;
        insert initialAgreement;
        Universign_Transaction__c trans = TestFactory.createUniversignTransaction('Test Transaction');
        trans.Agreement__c = initialAgreement.Id;
        insert trans;

        Universign_signer__c signer = TestFactory.createUniversignsigner(trans.id);
        insert signer;
    }

    @isTest
    static void testSendTransaction_Success() {
        // Create test ObjectContext
        List<universign_getTransactionInfo.ObjectContext> objContextList = new List<universign_getTransactionInfo.ObjectContext>();
        universign_getTransactionInfo.ObjectContext objContext = new universign_getTransactionInfo.ObjectContext();
        objContext.universignTransaction = [SELECT id,transactionId__c FROM Universign_Transaction__c LIMIT 1];
        objContextList.add(objContext);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        // Call the sendTransaction method
        List<universign_getTransactionInfo.Result> results = universign_getTransactionInfo.sendTransaction(objContextList);

        Test.stopTest();

        // Perform assertions to verify the success scenario
        System.assertEquals(1, results.size());
        universign_getTransactionInfo.Result result = results[0];
        // System.assertEquals(null, result.errorMsg);
    }

    /*@isTest
    static void testSendTransaction_Error() {
        // Create test data and initialize it to simulate an error scenario
        
        // Create test ObjectContext
        List<universign_getTransactionInfo.ObjectContext> objContextList = new List<universign_getTransactionInfo.ObjectContext>();
        universign_getTransactionInfo.ObjectContext objContext = new universign_getTransactionInfo.ObjectContext();
        // Initialize objContext with error-inducing data
        objContext.universignTransaction = null; // Example: Setting it to null to trigger an error
        objContextList.add(objContext);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        // Call the sendTransaction method
        //List<universign_getTransactionInfo.Result> results = universign_getTransactionInfo.sendTransaction(objContextList);

        Test.stopTest();

        // Perform assertions to verify the error scenario
        //System.assertEquals(1, results.size());
        //universign_getTransactionInfo.Result result = results[0];
        //System.assertNotEquals(null, result.errorMsg);
    }*/
}