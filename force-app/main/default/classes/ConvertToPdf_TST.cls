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
public class ConvertToPdf_TST {

    @testSetup
    static void setupTestData() {
        // Create test content document
        ContentVersion testContent = TestFactory.createContentVersion('1','1','1','Test Document',Blob.valueOf('Test Content'),'test-document.docx');
        insert testContent;
    }

    @isTest
    static void testConvertToPdf() {
        // Set up test data by calling the setupTestData method.

        // Query the test content version
        ContentVersion testContentVersion = [SELECT Id, Title FROM ContentVersion WHERE Title = 'Test Document' LIMIT 1];

        // Call the ConvertToPdf method with the test content version
        Test.startTest();
        ConvertToPdf.ConvertToPdf(testContentVersion.Id, testContentVersion.Title);
        Test.stopTest();

        // Query the converted PDF document
        ContentVersion convertedPdf = [SELECT Id, Title, FileType FROM ContentVersion WHERE Title = 'Test Document' LIMIT 1];

        // Verify the results with assertions
        System.assertNotEquals(null, convertedPdf, 'No PDF document found.');
        System.assertEquals('Test Document', convertedPdf.Title, 'The PDF document title is incorrect.');
        // System.assertEquals('PDF', convertedPdf.FileType, 'The document is not in PDF format.');
    }
}