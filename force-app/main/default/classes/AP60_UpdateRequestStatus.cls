public with sharing class AP60_UpdateRequestStatus {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Update Request Status
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 23-NOV-2021  MBE   1.0      Initial version
--------------------------------------------------------------------------------------
**************************************************************************************/

    /**
    * @description Update Reinsurer and SA Status for Request
    * @param List<Request__c> lstOldRequests, List<Request__c> lstNewRequests
    * @return void
    */
    public static void updateRequestStatus(List<Request__c> lstOldRequests, List<Request__c> lstNewRequests){
        Map<Id, Request__c> mapOldReq = new Map<Id, Request__c>(lstOldRequests);
        Map<String, Id> mapRecTypeIdRequest = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectRequest});

        for(Request__c newReq : lstNewRequests){
            if(newReq.RecordTypeId == mapRecTypeIdRequest.get(AP_Constant.reqRTSA)){
                if(newReq.SA_Request_Status__c == 'Sent' && newReq.ExpectedResponseDate__c < date.today()
                    && (mapOldReq.get(newReq.Id).SA_Request_Status__c != newReq.SA_Request_Status__c || mapOldReq.get(newReq.Id).ExpectedResponseDate__c != newReq.ExpectedResponseDate__c)){
                        newReq.SA_Request_Status__c = 'Timeout';
                }
                if(newReq.SA_Request_Status__c == 'Timeout' && newReq.ExpectedResponseDate__c >= date.today()
                    && (mapOldReq.get(newReq.Id).ExpectedResponseDate__c != newReq.ExpectedResponseDate__c)){
                        newReq.SA_Request_Status__c = 'Sent';
                }
            }
            else{
                if(newReq.ReinsurerStatus__c == 'Sent' && newReq.ExpectedResponseDate__c < date.today()
                    && (mapOldReq.get(newReq.Id).ReinsurerStatus__c != newReq.ReinsurerStatus__c || mapOldReq.get(newReq.Id).ExpectedResponseDate__c != newReq.ExpectedResponseDate__c)){
                        newReq.ReinsurerStatus__c = 'Timeout';
                }
                else if(newReq.ReinsurerStatus__c == 'Timeout' && newReq.ExpectedResponseDate__c >= date.today()
                    && (mapOldReq.get(newReq.Id).ExpectedResponseDate__c != newReq.ExpectedResponseDate__c)){
                        newReq.ReinsurerStatus__c = 'Sent';
                }
            }
        }
    }
}