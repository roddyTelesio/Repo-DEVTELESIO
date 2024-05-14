trigger SectionTrigger on Section__c (before insert, before update, after update) {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Trigger on Section
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 25-JUN-2020  MBE   1.0      Initial version
--------------------------------------------------------------------------------------
**************************************************************************************/

    SectionTriggerHandler handler = new SectionTriggerHandler();

    if(Trigger.isBefore && Trigger.isUpdate) {
        handler.handleBeforeUpdate(Trigger.new);
    }
    if(Trigger.isBefore && Trigger.isInsert) {
        handler.handleBeforeInsert(Trigger.new);
    }
    //RRA - ticket 1745 - 09112023
    if(Trigger.isAfter && Trigger.isUpdate) {
        handler.handleAfterUpdate(Trigger.old, Trigger.new);
    }
}