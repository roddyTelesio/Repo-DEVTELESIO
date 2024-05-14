trigger UserTrigger on User (after insert, after update) {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Trigger on User
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 08-SEP-2020  MBE   1.0      Initial version
-- 12-NOV-2021  MBE   1.1      W-1038 - réassureurs qui ne voient pas l'historique des années précédantes - Add handleAfterUpdate
--------------------------------------------------------------------------------------
**************************************************************************************/
    UserTriggerHandler handler = new UserTriggerHandler();

    if(Trigger.isAfter && Trigger.isInsert) {
        handler.handleAfterInsert(Trigger.new);
    }
    else if(Trigger.isAfter && Trigger.isUpdate) {
        handler.handleAfterUpdate(Trigger.old, Trigger.new);
    }
}