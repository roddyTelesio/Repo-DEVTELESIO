/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 01-17-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
public class CLM_UniversignDocRetrieval_QUE_TST {

    // Test setup to create necessary test data
    @testSetup
    static void setupTestData() {
        Id acceptationRecordTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Acceptation').getRecordTypeId();

        Apttus__APTS_Agreement__c initialAgreement = TestFActory.createAgreement('Test Agreement');
        initialAgreement.recordTypeId = acceptationRecordTypeId;
        insert initialAgreement;


        Universign_Transaction__c transac = new Universign_Transaction__c(
            transactionId__c = 'TestTransactionId',
            Status__c = 'completed', // Ensure this status meets your query criteria in the queueable class
            LastDateCheckedByBatch__c = Date.today().addDays(-1),
            Agreement__c = initialAgreement.Id
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
        Id jobId = System.enqueueJob(new CLM_UniversignDocRetrieval_QUE());
        Test.stopTest();
    }

    @isTest
    static void testScheduleAndExecute() {
        // Act: Schedule the job
        Test.startTest();
        String cronExp = '0 0 12 * * ?';  // Example cron expression
        String jobId = System.schedule('TestCLM_UniversignDocRetrieval_QUE_SCHEDULE', cronExp, new CLM_UniversignDocRetrieval_QUE_SCHEDULE());

        // Execute scheduled job
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE Id = :jobId];
        System.assertEquals(cronExp, ct.CronExpression);
        System.enqueueJob(new CLM_UniversignDocRetrieval_QUE());
        Test.stopTest();
    }
}