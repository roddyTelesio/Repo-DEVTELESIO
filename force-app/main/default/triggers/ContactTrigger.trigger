trigger ContactTrigger on Contact (after insert, after update) {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Trigger on Contact
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 16-JUN-2020  MBE   1.0      Initial version
--------------------------------------------------------------------------------------
**************************************************************************************/
    ContactTriggerHandler handler = new ContactTriggerHandler();

//    if(Trigger.isAfter && Trigger.isInsert) {
//        handler.handleAfterInsert(Trigger.new);
//    }
    if(Trigger.isAfter && Trigger.isUpdate) {
        handler.handleAfterUpdate(Trigger.old, Trigger.new);
    }
}