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
public class CLM_ComplyImportedDocs_TST {
    public static Id acceptationRecordTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Acceptation').getRecordTypeId();
    
    @testSetup
    static void setupTestData() {
        // Create a test agreement record for the test
        Apttus__APTS_Agreement__c initialAgreement = TestFActory.createAgreement('Test Agreement');
        initialAgreement.recordTypeId = acceptationRecordTypeId;
        insert initialAgreement;
    }

    @isTest
    static void testComplyImportedDocs() {
        // Set up test data by calling the setupTestData method.

        // Create an object context for the compliance operation
        CLM_ComplyImportedDocs.ObjectContext context = new CLM_ComplyImportedDocs.ObjectContext();
        Apttus__APTS_Agreement__c agre= [SELECT Id FROM Apttus__APTS_Agreement__c LIMIT 1 ];
        
        context.agreementId = agre.Id;

        // Call the complyImportedDocs method with the object context
        List<CLM_ComplyImportedDocs.Result> results = CLM_ComplyImportedDocs.complyImportedDocs(new List<CLM_ComplyImportedDocs.ObjectContext>{context});

        // Verify the results with assertions
        System.assertEquals(1, results.size(), 'The result does not contain a single element.');
        CLM_ComplyImportedDocs.Result result = results[0];
        System.assertEquals(true, result.isSuccess, 'Compliance operation failed.');
        System.assertEquals(null, result.errorMsg, 'An unexpected error message was returned.');
    }
}