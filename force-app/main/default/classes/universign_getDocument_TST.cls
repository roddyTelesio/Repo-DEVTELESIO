/**
 * @description       : 
 * @author            : Patrick Randrianarisoa
 * @group             : 
 * @last modified on  : 13-09-2023
 * @last modified by  : Patrick Randrianarisoa
 * Modifications Log
 * Ver   Date         Author                   Modification
 * 1.0   11-09-2023   Patrick Randrianarisoa   Initial Version
**/
@isTest
public class universign_getDocument_TST{
    public static Id acceptationRecordTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Acceptation').getRecordTypeId();

    @testSetup
    static void setupTestData() {
        Apttus__APTS_Agreement__c initialAgreement = TestFActory.createAgreement('Test Agreement');
        initialAgreement.recordTypeId = acceptationRecordTypeId;
        insert initialAgreement;
        Universign_Transaction__c trans = TestFactory.createUniversignTransaction('Test Transaction');
        trans.Agreement__c = initialAgreement.Id;
        insert trans;
    }

    @isTest
    static void testGetTransactionDocSuccess() {
        // Call the getTransactionDoc method
        universign_getDocument.ObjectContext context = new universign_getDocument.ObjectContext();
        context.universignTransaction = [SELECT Id,transactionId__c FROM Universign_Transaction__c LIMIT 1]; // Use the record created in test setup
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        List<universign_getDocument.Result> results = universign_getDocument.getTransactionDoc(new List<universign_getDocument.ObjectContext>{context});
        Test.stopTest();

        // System.assertEquals(true, results[0].isSuccess);
        // System.assertEquals(null, results[0].errorMsg);
        // System.assertNotEquals(null, results[0].contentVersionId);

    }

    @isTest
    static void testCreateContentDocument() {
        Apttus__APTS_Agreement__c agree = [SELECT Id FROM Apttus__APTS_Agreement__c LIMIT 1];
        Test.startTest();
        String contentVersionId = universign_getDocument.createContentDocument(Blob.valueOf('Test Content'), 'Test.pdf', agree.id);
        Test.stopTest();
    }
}