/**
 * @description       : 
 * @author            : Patrick Randrianarisoa
 * @group             : 
 * @last modified on  : 02-11-2023
 * @last modified by  : Patrick Randrianarisoa
 * Modifications Log
 * Ver   Date         Author                   Modification
 * 1.0   02-11-2023   Patrick Randrianarisoa   Initial Version
**/
@isTest
private class CLM_CloneAgreement_TST {

    @testSetup
    static void setupTestData() {
        // Create any required test data here.
        Apttus__APTS_Agreement__c initialAgreement = new Apttus__APTS_Agreement__c(Name = 'Test Agreement');
        insert initialAgreement;

        // You can create other necessary records or data as needed.
    }

    @isTest
    static void testCloneAgreementSuccess() {
        // Test the 'cloneAgreement' method when it succeeds.
        List<CLM_CloneAgreement.ObjectContext> testObjects = new List<CLM_CloneAgreement.ObjectContext>();

        // Populate testObjects with test data for a successful scenario.
        CLM_CloneAgreement.ObjectContext context = new CLM_CloneAgreement.ObjectContext();
        context.agreementId = 'Initial Agreement Id'; // Replace with the actual Agreement Id.
        testObjects.add(context);

        Test.startTest();
        List<CLM_CloneAgreement.Result> results = CLM_CloneAgreement.cloneAgreement(testObjects);
        CLM_CloneAgreement.Result res = new CLM_CloneAgreement.Result(true, null, [Select id from Apttus__APTS_Agreement__c LIMIT 1]);
        Test.stopTest();
    }

    @isTest
    static void testCloneAgreementFailure() {
        // Test the 'cloneAgreement' method when it fails.
        List<CLM_CloneAgreement.ObjectContext> testObjects = new List<CLM_CloneAgreement.ObjectContext>();

        // Populate testObjects with test data for a failure scenario, e.g., provide a non-existent Agreement Id.
        CLM_CloneAgreement.ObjectContext context = new CLM_CloneAgreement.ObjectContext();
        context.agreementId = 'NonExistentAgreementId'; // Replace with a non-existent Agreement Id.
        testObjects.add(context);

        Test.startTest();
        List<CLM_CloneAgreement.Result> results = CLM_CloneAgreement.cloneAgreement(testObjects);
        Test.stopTest();
    }
}