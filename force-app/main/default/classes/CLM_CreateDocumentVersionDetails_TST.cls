/**
 * @description       : 
 * @author            : Patrick Randrianarisoa
 * @group             : 
 * @last modified on  : 08-09-2023
 * @last modified by  : Patrick Randrianarisoa
 * Modifications Log
 * Ver   Date         Author                   Modification
 * 1.0   08-09-2023   Patrick Randrianarisoa   Initial Version
**/
@isTest
public class CLM_CreateDocumentVersionDetails_TST {
    public static Id acceptationRecordTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Acceptation').getRecordTypeId();
    
    @testSetup
    static void setupTestData() {
        // Create a test agreement record for the test
        Apttus__APTS_Agreement__c testAgreement = TestFActory.createAgreement('Test Agreement');
        testAgreement.recordTypeId = acceptationRecordTypeId;
        insert testAgreement;
        
        // Create a test template record for the test
        Apttus__APTS_Template__c testTemplate = TestFActory.createTemplate('test');
        insert testTemplate;
    }

    @isTest
    static void testCreateDocVerDetails_WithValidData() {
        // Set up test data by calling the setupTestData method.

        // Create an object context for creating document version details
        CLM_CreateDocumentVersionDetails.ObjectContext context = new CLM_CreateDocumentVersionDetails.ObjectContext();
        Apttus__APTS_Agreement__c agreem = [SELECT id FROM Apttus__APTS_Agreement__c LIMIT 1];
        Apttus__APTS_Template__c tmp = [SELECT id FROM Apttus__APTS_Template__c LIMIT 1];

        context.agreementId = agreem.id;
        context.templateId = tmp.id;
        context.comment = 'Test Comment';
        
        // Call the createDocVerDetails method with the object context
        List<CLM_CreateDocumentVersionDetails.Result> results = CLM_CreateDocumentVersionDetails.createDocVerDetails(new List<CLM_CreateDocumentVersionDetails.ObjectContext>{context});

        // Verify the results with assertions
        System.assertEquals(1, results.size(), 'The result does not contain a single element.');
        CLM_CreateDocumentVersionDetails.Result result = results[0];
        System.assertEquals(true, result.isSuccess, 'Document version details creation failed.');
        System.assertEquals(null, result.errorMsg, 'An unexpected error message was returned.');
        System.assertNotEquals(null, result.contentDocumentVersionDetail, 'The content document version detail is missing.');
    }
    
    @isTest
    static void testCreateDocVerDetails_WithValidDataBlankTemplate() {
        // Set up test data by calling the setupTestData method.

        // Create an object context for creating document version details
        CLM_CreateDocumentVersionDetails.ObjectContext context = new CLM_CreateDocumentVersionDetails.ObjectContext();
        Apttus__APTS_Agreement__c agreem = [SELECT id FROM Apttus__APTS_Agreement__c LIMIT 1];

        context.agreementId = agreem.id;
        context.templateId = '';
        context.comment = 'Test Comment';
        
        // Call the createDocVerDetails method with the object context
        List<CLM_CreateDocumentVersionDetails.Result> results = CLM_CreateDocumentVersionDetails.createDocVerDetails(new List<CLM_CreateDocumentVersionDetails.ObjectContext>{context});

        // Verify the results with assertions
        System.assertEquals(1, results.size(), 'The result does not contain a single element.');
        CLM_CreateDocumentVersionDetails.Result result = results[0];
        System.assertEquals(true, result.isSuccess, 'Document version details creation failed.');
        System.assertEquals(null, result.errorMsg, 'An unexpected error message was returned.');
        System.assertNotEquals(null, result.contentDocumentVersionDetail, 'The content document version detail is missing.');
    }

    @isTest
    static void testCreateDocVerDetails_WithInvalidTemplateId() {
        // Set up test data by calling the setupTestData method.

        // Create an object context for creating document version details with an invalid template ID
        CLM_CreateDocumentVersionDetails.ObjectContext context = new CLM_CreateDocumentVersionDetails.ObjectContext();
        Apttus__APTS_Agreement__c agreem = [SELECT id FROM Apttus__APTS_Agreement__c LIMIT 1];

        context.agreementId = agreem.id;
        context.templateId = 'Invalid_Template_ID'; // Use an ID that does not exist
        context.comment = 'Test Comment';

        // Call the createDocVerDetails method with the object context
        List<CLM_CreateDocumentVersionDetails.Result> results = CLM_CreateDocumentVersionDetails.createDocVerDetails(new List<CLM_CreateDocumentVersionDetails.ObjectContext>{context});

        // Verify the results with assertions
        System.assertEquals(1, results.size(), 'The result does not contain a single element.');
        CLM_CreateDocumentVersionDetails.Result result = results[0];
        System.assertEquals(false, result.isSuccess, 'Document version details creation succeeded unexpectedly.');
        System.assertNotEquals(null, result.errorMsg, 'An expected error message is missing.');
    }
}