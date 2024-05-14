/**
 * @description       : 
 * @author            : Patrick Randrianarisoa
 * @group             : 
 * @last modified on  : 03-11-2023
 * @last modified by  : Patrick Randrianarisoa
 * Modifications Log
 * Ver   Date         Author                   Modification
 * 1.0   03-11-2023   Patrick Randrianarisoa   Initial Version
**/
@isTest
private class CLM_mergeDocxQueueable_TST {
    public static Id acceptationRecordTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Acceptation').getRecordTypeId();

    @isTest
    static void testMergeDocxQueueableExecution() {
        Apttus__APTS_Agreement__c testAgreement = TestFActory.createAgreement('Test Agreement');
        testAgreement.recordTypeId = acceptationRecordTypeId;
        insert testAgreement;

        Apttus.CustomClass.AttachmentInfo testAttachmentInfo = new Apttus.CustomClass.AttachmentInfo();
        List<Apttus.CustomClass.AttachmentInfo> attachmentInfoList = new List<Apttus.CustomClass.AttachmentInfo>();
        attachmentInfoList.add(testAttachmentInfo);

        String parentId = UserInfo.getUserId();
        String docFileName = 'Test';
        String agreementId = testAgreement.id;
        CLM_mergeDocxQueueable queueable = new CLM_mergeDocxQueueable(parentId, docFileName, attachmentInfoList, agreementId);

        Test.startTest();
        System.enqueueJob(queueable);
        Test.stopTest();
    }
}