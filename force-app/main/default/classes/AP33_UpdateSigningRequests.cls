public with sharing class AP33_UpdateSigningRequests {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Update signing requests
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 07-APR-2020  SAU   1.0      Initial version
--------------------------------------------------------------------------------------
**************************************************************************************/

    /**
    * @description Update Loss Deposit picklist values on Signing Requests when values are changed on Treaty
    * @param List <Id> lstTreatyIds, List <Id> lstProgramIds, List <String> lstRemovedValues
    * @return void
    */
    public static void updateSigningRequests(List <Id> lstTreatyIds, List <Id> lstProgramIds, List <String> lstRemovedValues){
        String signingRT = AP_Constant.reqRTSigning.split('-')[1];
        List <Request__c> lstRequests = new List <Request__c>();
        List <Request__c> lstUpdatedRequests = new List <Request__c>();
        List <Request__c> lstUpdatedRequestsNonInCondition = new List <Request__c>();
        String query = 'SELECT Id, LossDepositMode__c, Treaty__c, Treaty__r.LossDepositMode__c, TECH_isAdmin__c, RecordType.DeveloperName FROM Request__c WHERE RecordType.DeveloperName =: signingRT ';//RRA - ticket 1421 - 06092023

        if(lstTreatyIds != null){
            query = query + 'AND Treaty__c IN: lstTreatyIds';
        }
        else if(lstProgramIds != null){
            query = query + 'AND Program__c IN: lstProgramIds';
        }

        lstRequests = Database.query(query);

        for(Integer i = 0; i < lstRequests.size(); i++){
            Request__c request = lstRequests[i];
            if (request.TECH_isAdmin__c == false){
             //RRA - ticket 1421 - 06092023 - put LossDepositMode to null if lossDepositMode value in Request not contain in lossDepositMode value in Treaty
                if (request.Treaty__r.LossDepositMode__c != null && request.LossDepositMode__c != null){
                    if (!request.Treaty__r.LossDepositMode__c.contains(request.LossDepositMode__c)){
                        request.LossDepositMode__c = null;
                        lstUpdatedRequestsNonInCondition.add(request);
                    }
                }
                for(Integer x = 0; x < lstRemovedValues.size(); x++){
                    // loss deposit mode on request is not a multi picklist
                    if(request.LossDepositMode__c == lstRemovedValues[x]){
                        request.LossDepositMode__c = null;
                        lstUpdatedRequests.add(request);
                    }
                }
            }
        }

        if(lstUpdatedRequestsNonInCondition.size() > 0){
            update lstUpdatedRequestsNonInCondition;
        }
        
        if(lstUpdatedRequests.size() > 0){
            update lstUpdatedRequests;
        }
        
       
    }
}