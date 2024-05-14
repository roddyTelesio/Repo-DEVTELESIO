public without sharing class AP51_DeleteSigningPool {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Class to delete Requests when Pool Treaty Sections are deleted on Treaty
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 15-DEC-2020  NBI   1.0      Initial version
--------------------------------------------------------------------------------------
**************************************************************************************/

    /**
    * @description
    * @param List<PoolTreatySection__c> lstPoolTreatySections
    * @return void
    */
    public static void deleteSigningRequests(Map<Id, List<Id>> mapTreatyPools){
        Map<String, Id> mapRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectRequest});
        String recordTypeIdSigning= mapRecTypeId.get(AP_Constant.reqRTSigning);
        List<Request__c> lstDeleteReq = new List<Request__c>();

        for(Request__c signingReq : [SELECT Id, Treaty__c, Pool__c from Request__c WHERE Treaty__c IN :mapTreatyPools.keySet() AND RecordTypeId = :recordTypeIdSigning]){
            if(mapTreatyPools.get(signingReq.Treaty__c).contains(signingReq.Pool__c)){
                lstDeleteReq.add(signingReq);
            }
        }

        if(lstDeleteReq.size() > 0){
            delete lstDeleteReq;
        }
    }
}