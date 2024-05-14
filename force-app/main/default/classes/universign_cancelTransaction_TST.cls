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
public class universign_cancelTransaction_TST {
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
    static void testCancelTransaction() {
       
        // Create an ObjectContext with the Universign_Transaction__c record
        universign_cancelTransaction.ObjectContext objContext = new universign_cancelTransaction.ObjectContext();
        objContext.universignTransaction = [SELECT Id,transactionId__c FROM Universign_Transaction__c LIMIT 1];
        
        Test.startTest();
        // Call the cancelTransaction method
        List<universign_cancelTransaction.Result> results = universign_cancelTransaction.cancelTransaction(new List<universign_cancelTransaction.ObjectContext>{objContext});

        Test.stopTest();
        // Verify the results
        System.assertEquals(1, results.size());
    }
}