/**
 * @description       : 
 * @author            : Patrick Randrianarisoa
 * @group             : 
 * @last modified on  : 02-11-2023
 * @last modified by  : Patrick Randrianarisoa
 * Modifications Log
 * Ver   Date         Author                   Modification
 * 1.0   08-09-2023   Patrick Randrianarisoa   Initial Version
**/
@isTest
public class CLM_generateDoc_TST {
    public static Id acceptationRecordTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Acceptation').getRecordTypeId();

    @testSetup
    static void setupTestData() {
        // Create a test agreement record for the test
        Apttus__APTS_Agreement__c initialAgreement = TestFActory.createAgreement('Test Agreement');
        initialAgreement.recordTypeId = acceptationRecordTypeId;
        insert initialAgreement;

        // Create a test template record for the test
        Apttus__APTS_Template__c testTemplate = TestFActory.createTemplate('test');
        insert testTemplate;
    }

    @isTest
    static void testGenerateDoc_WithValidTemplateName() {
        // Set up test data by calling the setupTestData method.

        // Create an object context for generating the document
        CLM_generateDoc.ObjectContext context = new CLM_generateDoc.ObjectContext();
        Apttus__APTS_Agreement__c agre= [SELECT Id FROM Apttus__APTS_Agreement__c LIMIT 1 ];

        context.templateName = 'test';
        context.agreementId = agre.Id;

        // Call the generateDoc method with the object context
        List<CLM_generateDoc.Result> results = CLM_generateDoc.generateDoc(new List<CLM_generateDoc.ObjectContext>{context});

        // Verify the results with assertions
        System.assertEquals(1, results.size(), 'The result does not contain a single element.');
        CLM_generateDoc.Result result = results[0];
        // System.assertNotEquals(null, result.docId, 'The generated document ID is missing.');
    }

    @isTest
    static void testGenerateDoc_WithInvalidTemplateName() {
        // Set up test data by calling the setupTestData method.

        // Create an object context for generating the document with an invalid template name
        CLM_generateDoc.ObjectContext context = new CLM_generateDoc.ObjectContext();
        context.templateName = 'Nonexistent Template'; // Use a template name that doesn't exist

        // Call the generateDoc method with the object context
        List<CLM_generateDoc.Result> results = CLM_generateDoc.generateDoc(new List<CLM_generateDoc.ObjectContext>{context});

        // Verify the results with assertions
        System.assertEquals(1, results.size(), 'The result does not contain a single element.');
        CLM_generateDoc.Result result = results[0];
        System.assertEquals(false, result.isSuccess, 'Document generation succeeded unexpectedly.');
        System.assertNotEquals(null, result.errMsg, 'An expected error message is missing.');
        System.assertEquals('No templates found for name: Nonexistent Template to generate signature page', result.errMsg);
    }

     @isTest
     static void testgetRetroDocId1() {
         Apttus__APTS_Agreement__c agre= [SELECT Id FROM Apttus__APTS_Agreement__c LIMIT 1 ];
         Map<String, Object> result = CLM_generateDoc.getRetroDocId(agre.id);
    }
}