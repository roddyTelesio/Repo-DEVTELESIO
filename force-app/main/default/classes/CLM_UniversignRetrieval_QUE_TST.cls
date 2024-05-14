/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 01-17-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
public class CLM_UniversignRetrieval_QUE_TST {

    // Test setup to create necessary test data
    @testSetup
    static void setupTestData() {
        // Assuming Universign_Transaction__c and related objects are custom objects in your org
        // Create and insert test data needed for your Queueable class

        Id acceptationRecordTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Acceptation').getRecordTypeId();

        Apttus__APTS_Agreement__c initialAgreement = TestFActory.createAgreement('Test Agreement');
        initialAgreement.recordTypeId = acceptationRecordTypeId;
        insert initialAgreement;


        Universign_Transaction__c transac = new Universign_Transaction__c(
            transactionId__c = 'TestTransactionId',
            Status__c = 'ready', // Ensure this status meets your query criteria in the queueable class
            LastDateCheckedByBatch__c = Date.today().addDays(-1),
            Agreement__c = initialAgreement.Id
            // Include other necessary fields
        );
        insert transac;
    }

    // Test method for the execute method of CLM_UniversignRetrieval_QUE
    @isTest
    static void testExecuteMethod() {
        //Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();

        // Enqueue the job
        Id jobId = System.enqueueJob(new CLM_UniversignRetrieval_QUE());

        Test.stopTest();
    }

    @isTest
    static  void testScheduleAndExecute() {
        Test.startTest();
        String cronExp = '0 0 13 * * ?';  // Example cron expression
        String jobId = System.schedule('TestCLM_UniversignRetrieval_QUE_SCHEDULE', cronExp, new CLM_UniversignRetrieval_QUE_SCHEDULE());

        // Execute scheduled job
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE Id = :jobId];
        System.assertEquals(cronExp, ct.CronExpression);
        System.enqueueJob(new CLM_UniversignRetrieval_QUE());
        Test.stopTest();
    }

}