trigger ReinstatementTrigger on Reinstatement__c (after insert, after update, after delete) {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Trigger on Reinstatement
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 15-JUN-2020  MBE   1.0      Initial version
--------------------------------------------------------------------------------------
**************************************************************************************/
    ReinstatementTriggerHandler handler = new ReinstatementTriggerHandler();

    if((Trigger.isAfter && Trigger.isInsert)) {
        handler.handleAfterInsert(Trigger.new);
    }

    if(Trigger.isAfter && Trigger.isUpdate){
        handler.handleAfterUpdate(Trigger.old, Trigger.new);
    }

    if(Trigger.isAfter && Trigger.isDelete){
        handler.handleAfterDelete(Trigger.old);
    }
}