/**
 * @description       : 
 * @author            : Patrick Randrianarisoa
 * @group             : 
 * @last modified on  : 14-09-2023
 * @last modified by  : Patrick Randrianarisoa
 * Modifications Log
 * Ver   Date         Author                   Modification
 * 1.0   07-09-2023   Patrick Randrianarisoa   Initial Version
**/
@isTest
public class ApprovalRecall_SVC_TST {
    @isTest
    static void testRecallApproval() {
        ApprovalRecall_SVC.recallApproval(new List<Id>{'0015E000037awhLQAQ'});
    }
}