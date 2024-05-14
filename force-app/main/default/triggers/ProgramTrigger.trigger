/**************************************************************************************
-- - Author        : Telesio
-- - Description   : Trigger on Program
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 11-AUG-2022  RRA   1.0      Initial version
--------------------------------------------------------------------------------------
**************************************************************************************/
trigger ProgramTrigger on Program__c (after update) {
    ProgramTriggerHandler handler = new ProgramTriggerHandler();

    if(Trigger.isAfter && Trigger.isUpdate) {
        handler.handleAfterUpdate(Trigger.old, Trigger.new);
    }
    
}