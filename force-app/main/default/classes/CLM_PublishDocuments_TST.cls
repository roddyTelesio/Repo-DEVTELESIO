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
private class CLM_PublishDocuments_TST {

    @testSetup
    static void setupTestData() {
        // Create any required test data here, including Agreement and Attachment records.
        Apttus__APTS_Agreement__c testAgreement = new Apttus__APTS_Agreement__c(Name = 'Test Agreement');
        insert testAgreement;

        Attachment testAttachment = new Attachment(
            Name = 'Test Attachment',
            ParentId = testAgreement.Id,
            Body = Blob.valueOf('Test Attachment Content')
        );
        insert testAttachment;
    }

    @isTest
    static void testPublishDocumentsSuccess() {
        // Test the 'publishDocuments' method when it succeeds.
        List<CLM_PublishDocuments.ObjectContext> testObjects = new List<CLM_PublishDocuments.ObjectContext>();

        // Populate testObjects with test data for a successful scenario.
        CLM_PublishDocuments.ObjectContext context = new CLM_PublishDocuments.ObjectContext();
        context.agreementId = 'Test Agreement Id'; // Replace with the actual Agreement Id.
        context.attachmentId = 'Test Attachment Id'; // Replace with the actual Attachment Id.
        testObjects.add(context);

        Test.startTest();
        List<CLM_PublishDocuments.Result> results = CLM_PublishDocuments.publishDocuments(testObjects);
        CLM_PublishDocuments.Result res = new CLM_PublishDocuments.Result(true,null); 
        Test.stopTest();
    }

    @isTest
    static void testPublishDocumentsFailure() {
        // Test the 'publishDocuments' method when it fails.
        List<CLM_PublishDocuments.ObjectContext> testObjects = new List<CLM_PublishDocuments.ObjectContext>();

        // Populate testObjects with test data for a failure scenario, e.g., provide an invalid Agreement Id.
        CLM_PublishDocuments.ObjectContext context = new CLM_PublishDocuments.ObjectContext();
        context.agreementId = 'NonExistentAgreementId'; // Replace with a non-existent Agreement Id.
        context.attachmentId = 'Test Attachment Id'; // Replace with a valid Attachment Id.
        testObjects.add(context);

        Test.startTest();
        List<CLM_PublishDocuments.Result> results = CLM_PublishDocuments.publishDocuments(testObjects);
        Test.stopTest();
    }
}