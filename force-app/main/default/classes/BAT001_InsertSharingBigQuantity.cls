global class BAT001_InsertSharingBigQuantity implements Database.Batchable<SObject>, Database.Stateful{
/**************************************************************************************
-- - Author        : Telesio
-- - Description   : batch apex to execute the insertion request share more than 10 000 records
--
-- Maintenance History:
--
-- Date          Name  Version  Remarks
-- -----------   ----  -------  -------------------------------------------------------
-- 21-MAY-2022  RRA   1.0      Initial version
--------------------------------------------------------------------------------------
**************************************************************************************/

    public List <Request__Share> lstReqShare = new List<Request__Share>();

    global BAT001_InsertSharingBigQuantity(List<Request__Share> lstReqShareInsert){
        lstReqShare = lstReqShareInsert;          
        System.debug('BAT001_InsertSharingBigQuantity___lstReqShare= ' + lstReqShare);
    }

    public List<Request__Share> start(Database.BatchableContext BC){
        return lstReqShare;
    }

    global void execute(Database.BatchableContext BC, List<Request__Share> lstScope){
        System.debug('BAT001_InsertSharingBigQuantity___lstScope= ' + lstScope);
           insert lstScope;     
    }

   global void finish(Database.BatchableContext BC){
    System.debug('BAT001_InsertSharingBigQuantity___finish__Insertion= ');
    }

}