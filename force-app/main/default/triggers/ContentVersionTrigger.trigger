trigger ContentVersionTrigger on ContentVersion (before insert, after insert) {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Content Version Trigger
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 31-MAY-2020  MBE   1.0      Initial Version
--------------------------------------------------------------------------------------
**************************************************************************************/

    ContentVersionTriggerHandler handler = new ContentVersionTriggerHandler();

    if(Trigger.isAfter && Trigger.isInsert){
        handler.handleAfterInsert(Trigger.new);
    }

    if(Trigger.isBefore && Trigger.isInsert){
        handler.handleBeforeInsert(Trigger.new);
    }
}