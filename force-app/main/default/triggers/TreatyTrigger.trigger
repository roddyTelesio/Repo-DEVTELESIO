trigger TreatyTrigger on Treaty__c (after update, after insert) {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Trigger on Treaty
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 07-APR-2020  SAU   1.0      Initial version
-- 25-JUN-2021  MBE   1.1      Update Custom Setting for Treaty Reference
--------------------------------------------------------------------------------------
**************************************************************************************/
    TreatyTriggerHandler handler = new TreatyTriggerHandler();

    if(Trigger.isAfter && Trigger.isUpdate) {
        handler.handleAfterUpdate(Trigger.old, Trigger.new);
    }
    else if(Trigger.isAfter && Trigger.isInsert) {
        handler.handleAfterInsert(Trigger.new);
    }
}