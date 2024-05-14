global class BAT002_DeleteSharingBigQuantity implements Database.Batchable<SObject>, Database.Stateful{
    /**************************************************************************************
-- - Author        : Telesio
-- - Description   : batch apex to execute the delete request share more than 10 000 records
--
-- Maintenance History:
--
-- Date          Name  Version  Remarks
-- -----------   ----  -------  -------------------------------------------------------
-- 22-AUG-2022  RRA   1.0      Initial version
--------------------------------------------------------------------------------------
**************************************************************************************/

 public List <Request__Share> lstReqShare = new List<Request__Share>();

 global BAT002_DeleteSharingBigQuantity(List<Request__Share> lstReqShareDelete){
     lstReqShare = lstReqShareDelete;          
     System.debug('BAT001_InsertSharingBigQuantity___lstReqShare= ' + lstReqShare);
 }

 public List<Request__Share> start(Database.BatchableContext BC){
     return lstReqShare;
 }

 global void execute(Database.BatchableContext BC, List<Request__Share> lstScope){
     System.debug('BAT001_InsertSharingBigQuantity___lstScope= ' + lstScope);
        delete lstScope;     
 }

global void finish(Database.BatchableContext BC){
 System.debug('BAT001_InsertSharingBigQuantity___finish__Insertion= ');
 }

}