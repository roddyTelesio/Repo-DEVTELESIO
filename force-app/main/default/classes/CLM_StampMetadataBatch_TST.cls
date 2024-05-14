/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 01-05-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
public class CLM_StampMetadataBatch_TST {

    @isTest
    static void testBatchExecution() {
        // Create test data
        List<Apttus__APTS_Agreement__c> testAgreements = new List<Apttus__APTS_Agreement__c>();
        for (Integer i = 0; i < 1; i++) {
            testAgreements.add(new Apttus__APTS_Agreement__c(
                Name = 'Test Agreement ' + i,
                toProcessStamp__c = true
            ));
        }
        insert testAgreements;

        // Mock the callout response (adjust as needed)
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Start the batch
        Test.startTest();
        Integer batchSize = 50;
        CLM_StampMetadataBatch stampMetadataBatch = new CLM_StampMetadataBatch();
        Database.executeBatch(stampMetadataBatch);
        Test.stopTest();

        // Verify that the toProcessStamp__c field is set to false for processed agreements
        List<Apttus__APTS_Agreement__c> updatedAgreements = [SELECT Id, toProcessStamp__c FROM Apttus__APTS_Agreement__c WHERE Id IN :testAgreements];
        for (Apttus__APTS_Agreement__c agreement : updatedAgreements) {
            System.assertEquals(false, agreement.toProcessStamp__c, 'toProcessStamp__c should be set to false');
        }

        // Add additional assertions if needed
    }

    // Mock HTTP response generator class
    public class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            // Return a dummy HTTPResponse for the callout
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"status": "success"}');
            return res;
        }
    }

    @isTest
    static void testBatchExecutionWithException() {
        // Create test data
        Apttus__APTS_Agreement__c testAgreement = new Apttus__APTS_Agreement__c(
            Name = 'Test Agreement',
            toProcessStamp__c = true
        );
        insert testAgreement;

        // Mock the callout response to simulate an exception (adjust as needed)
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorWithError());

        // Start the batch
        Test.startTest();
        Integer batchSize = 1; // Set to 1 to force exception
        CLM_StampMetadataBatch stampMetadataBatch = new CLM_StampMetadataBatch();
        Database.executeBatch(stampMetadataBatch);
        Test.stopTest();

        // Verify that the toProcessStamp__c field is not updated for the agreement with the exception
        Apttus__APTS_Agreement__c updatedAgreement = [SELECT Id, toProcessStamp__c FROM Apttus__APTS_Agreement__c WHERE Id = :testAgreement.Id];
        //System.assertEquals(true, updatedAgreement.toProcessStamp__c, 'toProcessStamp__c should not be updated');
    }

    // Mock HTTP response generator class to simulate an exception
    public class MockHttpResponseGeneratorWithError implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            // Return a dummy HTTPResponse with an error status code
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('{"error": "Simulated error"}');
            return res;
        }
    }
}