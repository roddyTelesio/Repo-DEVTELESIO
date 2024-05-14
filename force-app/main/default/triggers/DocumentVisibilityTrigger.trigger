trigger DocumentVisibilityTrigger on DocumentVisibility__c (after insert) {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Document Visibility Trigger
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 15-JUN-2020  NBI   1.0      Initial Version
--------------------------------------------------------------------------------------
**************************************************************************************/

    DocumentVisibilityTriggerHandler handler = new DocumentVisibilityTriggerHandler();

    if(Trigger.isAfter && Trigger.isInsert) {
        handler.handleAfterInsert(Trigger.new);
    }
}