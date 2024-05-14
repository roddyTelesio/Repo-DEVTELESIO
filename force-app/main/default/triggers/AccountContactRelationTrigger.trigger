trigger AccountContactRelationTrigger on AccountContactRelation (after insert, after update, after delete, before delete) {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Trigger on AccountContactRelation
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 02-SEP-2020  MBE   1.0      Initial version
-- 13-JUL-2021  AMI   2.0      CRM360 Lot1 - Prevent ACR relationship removal
--                             for Client Executive
--------------------------------------------------------------------------------------
**************************************************************************************/

    AccountContactRelationTriggerHandler handler = new AccountContactRelationTriggerHandler();

    if(Trigger.isAfter && Trigger.isInsert){
        handler.handleAfterInsert(Trigger.new);
        //handler.handleAfterInsertOld(Trigger.old);
    }
    else if(Trigger.isAfter && Trigger.isUpdate) {
        handler.handleAfterUpdate(Trigger.old, Trigger.new);
    }else if (Trigger.isAfter && Trigger.isDelete){
        handler.handleAfterDelete(Trigger.old);
    }
    //AMI 13/07/22: Prevent ACR relationship removal for Client Executive
    //            : Added new trigger context 
    else if (Trigger.isBefore && Trigger.isDelete){
        handler.handleBeforeDelete(Trigger.old);
    }
}