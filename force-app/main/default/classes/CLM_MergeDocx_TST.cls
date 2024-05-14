/**
 * @description       : 
 * @author            : Patrick Randrianarisoa
 * @group             : 
 * @last modified on  : 14-09-2023
 * @last modified by  : Patrick Randrianarisoa
 * Modifications Log
 * Ver   Date         Author                   Modification
 * 1.0   08-09-2023   Patrick Randrianarisoa   Initial Version
**/
@isTest
public class CLM_MergeDocx_TST {
    public static Id acceptationRecordTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Acceptation').getRecordTypeId();

    @testSetup
    static void setupTestData() {

        // Create test content versions to merge
        ContentVersion cv1 = TestFactory.createContentVersion('1','1','1','Test Doc 1',Blob.valueOf('Test Content 1'),'test');
        insert cv1;

        ContentVersion cv2 = TestFactory.createContentVersion('1','1','1','Test Doc 2',Blob.valueOf('Test Content 2'),'test');
        insert cv2;

        // Create a test parent record (e.g., Agreement) for the merge
        Apttus__APTS_Agreement__c testAgreement = TestFActory.createAgreement('Test Agreement');
        testAgreement.recordTypeId = acceptationRecordTypeId;
        insert testAgreement;
    }

    @isTest
    static void testMergeDocuments_WithValidData() {
        // Set up test data by calling the setupTestData method.

        // Create an object context for merging DOCX documents
        CLM_MergeDocx.ObjectContext context = new CLM_MergeDocx.ObjectContext();
        context.contentDocsToMerge = new List<sObject>{
            [SELECT Id, Title FROM ContentDocument WHERE Title = 'Test Doc 1'],
            [SELECT Id, Title FROM ContentDocument WHERE Title = 'Test Doc 2']
        };
        Apttus__APTS_Agreement__c agreem = [SELECT Id FROM Apttus__APTS_Agreement__c LIMIT 1];

        context.parentId = agreem.id;
        context.docFileName = 'Merged_Document.docx';

        // Call the mergeDocuments method with the object context
        List<CLM_MergeDocx.Result> results = CLM_MergeDocx.mergeDocuments(new List<CLM_MergeDocx.ObjectContext>{context});

        // Verify the results with assertions
        System.assertEquals(1, results.size(), 'The result does not contain a single element.');
        CLM_MergeDocx.Result result = results[0];
        System.assertEquals(true, result.isSuccess, 'DOCX document merge failed.');
        System.assertEquals(null, result.errorMsg, 'An unexpected error message was returned.');
        System.assertNotEquals(null, result.contentIdGenerated, 'The content record ID is missing.');

    }

    @isTest
    static void testgetMergeDocId() {
        Apttus__APTS_Agreement__c agreem = [SELECT Id FROM Apttus__APTS_Agreement__c LIMIT 1];

        Map<String, Object> results = CLM_MergeDocx.getMergeDocId(agreem.id);

    }
}