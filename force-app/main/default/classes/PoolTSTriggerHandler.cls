public with sharing class PoolTSTriggerHandler {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Request Trigger Handler Class
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 15-DEC-2020  NBI   1.0      Initial version
-- 13-OCT-2021  MBE   1.1      W-1035 - Production - Demande d'analyse du comportement des pools de la section suite à un renouvellement																								   
--------------------------------------------------------------------------------------
**************************************************************************************/

    public void handleAfterDelete(List<PoolTreatySection__c> lstPoolTreatySections){
        List<Id> lstPoolId = new List<Id>();
        Map<Id, List<Id>> mapTreatyPools = new Map<Id, List<Id>>();

        for(PoolTreatySection__c pool : lstPoolTreatySections){
            if(PAD.canRun('AP51_DeleteSigningPool')){
                if(pool.TreatyIsSelected__c == true){
                    if(mapTreatyPools.containsKey(pool.Treaty__c)){
                        mapTreatyPools.get(pool.Treaty__c).add(pool.Pool__c);
                    }
                    else{
                        mapTreatyPools.put(pool.Treaty__c, new List<Id>{pool.Pool__c});
                    }
                }
            }
        }

        if(PAD.canRun('AP51_DeleteSigningPool') && mapTreatyPools.keySet().size() > 0){
            AP51_DeleteSigningPool.deleteSigningRequests(mapTreatyPools);
        }
    }
}