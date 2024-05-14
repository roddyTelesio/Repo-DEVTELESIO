trigger RequestTrigger on Request__c (after update, after insert, after delete, before delete, before update) {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Trigger on Request
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 25-JUN-2020  MBE   1.0      Initial version
-- 04-AUG-2020  MBE   1.1      After Insert
-- 05-JUL-2021  MBE   1.2      W-0973 - Special Acceptance - Problème de maj statut SA suite à une réponse sur le portail BR
--------------------------------------------------------------------------------------
**************************************************************************************/

    RequestTriggerHandler handler = new RequestTriggerHandler();

    if(Trigger.isAfter && Trigger.isUpdate) {
        handler.handleAfterUpdate(Trigger.old, Trigger.new);
    }
    else if(Trigger.isAfter && Trigger.isInsert){
        handler.handleAfterInsert(Trigger.new);
    }
    else if(Trigger.isAfter && Trigger.isDelete){
        handler.handleAfterDelete(Trigger.old);
    }
    else if(Trigger.isBefore && Trigger.isDelete){
        handler.handleBeforeDelete(Trigger.old);
    }
    else if(Trigger.isBefore && Trigger.isUpdate){
        handler.handleBeforeUpdate(Trigger.old, Trigger.new);
    }
}