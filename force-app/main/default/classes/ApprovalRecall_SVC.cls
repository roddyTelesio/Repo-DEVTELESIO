/**
 * @description       : 
 * @author            : Patrick Randrianarisoa
 * @group             : 
 * @last modified on  : 14-09-2023
 * @last modified by  : Patrick Randrianarisoa 
 * Modifications Log
 * Ver   Date         Author                   Modification
 * 1.0   14-09-2023   Patrick Randrianarisoa   Initial Version
**/
global class ApprovalRecall_SVC
{
   @InvocableMethod
    public static void recallApproval(List<Id> recId)   
    {       
        List<ProcessInstanceWorkitem> piwi = [SELECT Id, ProcessInstanceId, ProcessInstance.TargetObjectId FROM ProcessInstanceWorkitem WHERE Id IN :recId];
        Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
        req.setAction('Removed');
        if(! Test.isRunningTest()){
            req.setWorkitemId(piwi[0].Id);
        }       
        Approval.process(req,false);
    }
}