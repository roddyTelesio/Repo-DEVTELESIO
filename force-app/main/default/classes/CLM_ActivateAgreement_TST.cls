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
public class CLM_ActivateAgreement_TST {
    
    @isTest
    static void testActivateDocumentsSuccess() {
        // Test the 'activateDocuments' method when it succeeds.
        List<CLM_ActivateAgreement.ObjectContext> testObjects = new List<CLM_ActivateAgreement.ObjectContext>();

        // Populate testObjects with test data for a successful scenario.
        CLM_ActivateAgreement.ObjectContext context = new CLM_ActivateAgreement.ObjectContext();
        context.agreementId = 'TestAgreementId';
        context.activateDocIds = new List<String>{'DocId1', 'DocId2'};
        context.remDocIds = null;
        testObjects.add(context);

        Test.startTest();
        List<CLM_ActivateAgreement.Result> results = CLM_ActivateAgreement.activateDocuments(testObjects);
        Test.stopTest();
    }

    @isTest
    static void testActivateDocumentsFailure() {
        // Test the 'activateDocuments' method when it fails.
        List<CLM_ActivateAgreement.ObjectContext> testObjects = new List<CLM_ActivateAgreement.ObjectContext>();

        // Populate testObjects with test data for a failure scenario.
        CLM_ActivateAgreement.ObjectContext context = new CLM_ActivateAgreement.ObjectContext();
        context.agreementId = 'NonExistentAgreementId'; // Simulate a non-existent agreement.
        context.activateDocIds = new List<String>{'DocId1', 'DocId2'};
        context.remDocIds = null;
        testObjects.add(context);

        Test.startTest();
        List<CLM_ActivateAgreement.Result> results = CLM_ActivateAgreement.activateDocuments(testObjects);
        Test.stopTest();
    }
}