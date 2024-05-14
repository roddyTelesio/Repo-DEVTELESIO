/**
 * @description       : 
 * @author            : Patrick Randrianarisoa
 * @group             : 
 * @last modified on  : 13-09-2023
 * @last modified by  : Patrick Randrianarisoa
 * Modifications Log
 * Ver   Date         Author                   Modification
 * 1.0   08-09-2023   Patrick Randrianarisoa   Initial Version
**/
@isTest
public class CLM_mergeDocs_TST {
    public static Id acceptationRecordTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Acceptation').getRecordTypeId();
    
    @testSetup
    static void setupTestData() {
        // Create test content versions to merge
        ContentVersion cv1 = TestFactory.createContentVersion('1','1','1','Test CV1',Blob.valueOf('Test Content 1'),'test');
        insert cv1;

        ContentVersion cv2 = TestFactory.createContentVersion('1','1','1','Test CV2',Blob.valueOf('Test Content 2'),'test');
        insert cv2;

        // Create a test parent record (e.g., Agreement) for the merge
        Apttus__APTS_Agreement__c testAgreement = TestFActory.createAgreement('Test Agreement');
        testAgreement.recordTypeId = acceptationRecordTypeId;
        insert testAgreement;
    }

    @isTest
    static void testMergeDocs_WithValidData() {
        // Set up test data by calling the setupTestData method.

        // Create an object context for merging PDF documents
        CLM_mergeDocs.ObjectContext context = new CLM_mergeDocs.ObjectContext();
        context.contentVersionsToMerge = new List<sObject>{
            [SELECT Id FROM ContentVersion WHERE Title = 'Test CV1'],
            [SELECT Id FROM ContentVersion WHERE Title = 'Test CV2']
        };
        Apttus__APTS_Agreement__c agreem = [SELECT Id FROM Apttus__APTS_Agreement__c LIMIT 1];

        context.parentId = agreem.id;
        context.docFileName = 'Merged_Document.pdf';

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        // Call the mergeDocs method with the object context
        List<CLM_mergeDocs.Result> results = CLM_mergeDocs.mergeDocs(new List<CLM_mergeDocs.ObjectContext>{context});

        // Verify the results with assertions
        System.assertEquals(1, results.size(), 'The result does not contain a single element.');
        CLM_mergeDocs.Result result = results[0];
        // System.assertEquals(true, result.isSuccess, 'PDF document merge failed.');
        // System.assertEquals(null, result.errMsg, 'An unexpected error message was returned.');
        // System.assertNotEquals(null, result.mergedDocId, 'The merged document ID is missing.');
    }

    @isTest
    static void testMergeDocs_WithNoContentVersions() {
        // Set up test data by calling the setupTestData method.

        // Create an object context for merging PDF documents with no content versions
        CLM_mergeDocs.ObjectContext context = new CLM_mergeDocs.ObjectContext();
        context.contentVersionsToMerge = new List<sObject>(); // Empty list
        Apttus__APTS_Agreement__c agreem = [SELECT Id FROM Apttus__APTS_Agreement__c LIMIT 1];

        context.parentId = agreem.id;
        context.docFileName = 'Merged_Document.pdf';

        // Call the mergeDocs method with the object context
        List<CLM_mergeDocs.Result> results = CLM_mergeDocs.mergeDocs(new List<CLM_mergeDocs.ObjectContext>{context});

        // Verify the results with assertions
        System.assertEquals(1, results.size(), 'The result does not contain a single element.');
        CLM_mergeDocs.Result result = results[0];
        // System.assertEquals(false, result.isSuccess, 'PDF document merge succeeded unexpectedly.');
        // System.assertNotEquals(null, result.errMsg, 'An expected error message is missing.');
        // System.assertEquals('No content versions parsed in parameter', result.errMsg);
    }
}