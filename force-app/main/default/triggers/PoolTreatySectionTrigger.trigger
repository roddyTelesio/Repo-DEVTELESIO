trigger PoolTreatySectionTrigger on PoolTreatySection__c (after delete) {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Trigger on PoolTreatySection__c
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 15-DEC-2020  NBI   1.0      Initial version
--------------------------------------------------------------------------------------
**************************************************************************************/

    PoolTSTriggerHandler handler = new PoolTSTriggerHandler();

    if(Trigger.isAfter && Trigger.isDelete){
        handler.handleAfterDelete(Trigger.old);
    }
}