/**
 * @description       : 
 * @author            : Patrick Randrianarisoa
 * @group             : 
 * @last modified on  : 03-11-2023
 * @last modified by  : Patrick Randrianarisoa
 * Modifications Log
 * Ver   Date         Author                   Modification
 * 1.0   12-09-2023   Patrick Randrianarisoa   Initial Version
**/
@isTest
public class LWCDOCVIEWER_SVC_TST {

    @testSetup
    static void setupTestData() {
        // Create test data
        Apttus__APTS_Template__c testTemplate = TestFActory.createTemplate('Test Template');
        testTemplate.Apttus__Type__c = 'Test Type'; 
        testTemplate.Apttus__IsActive__c = false ;

        insert testTemplate;
    
        Attachment testAttachment = TestFActory.createAttachment('Test Attachment',testTemplate.Id,Blob.valueOf('Contenu initial'));
        insert testAttachment;

        User AdmUser = TestFactory.createUser('Adminuser',TestFactory.getProfileAdminId());
        AdmUser.isActive = true;
        insert AdmUser;
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        
        req1.setComments('Submitting request for approval.');
        req1.setObjectId(testTemplate.id);
        req1.setNextApproverIds(new Id[] {UserInfo.getUserId()});
        req1.setSkipEntryCriteria(true);
        System.runAs(AdmUser) {
            // Submit the approval request for the Template
             Approval.ProcessResult result = Approval.process(req1);
        }
    }

    @isTest
    static void testGetDocumentDetails() {

        ProcessInstanceWorkitem piw = [SELECT Id FROM ProcessInstanceWorkitem LIMIT 1];
        Test.startTest();
        // Call the getDocumentDetails method
        Map<String, Object> result = LWCDOCVIEWER_SVC.getDocumentDetails(piw.Id);
        Test.stopTest();

        // Add assertions to verify the result
         System.assertEquals('Apttus__APTS_Template__c', result.get('ObjectName'));
         System.assertEquals('Test Type', result.get('tempType'));

        // Attachment resultAttachment = (Attachment)result.get('attach');
        // System.assertEquals('Test Attachment', resultAttachment.Name);

    }
}