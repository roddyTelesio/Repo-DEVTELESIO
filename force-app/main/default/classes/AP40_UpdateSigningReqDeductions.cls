public with sharing class AP40_UpdateSigningReqDeductions {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Update deduction on Signing when deduction on Treaty is updated
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
--09-JUL-2020  MBE   1.0      Initial version
--------------------------------------------------------------------------------------
**************************************************************************************/

    /**
    * @description Method to update Deduction on Signing Requests when Treaty is updated
    * @param List<Id> lstTreaties, Decimal newDeductValue
    * @return void
    */
    public static void updateSigningRequests (List<Id> lstTreaties, Decimal newDeductValue){
        Map<String, Id> mapRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectRequest});
        String recordTypeIdSigning = mapRecTypeId.get(AP_Constant.reqRTSigning);
        List<Request__c> lstUpdatedRequests = new List<Request__c>();

        for(Request__c request : [SELECT Id,
                                         Deductions__c
                                  FROM Request__c
                                  WHERE Treaty__c IN: lstTreaties
                                  AND RecordTypeId =: recordTypeIdSigning]){
            request.Deductions__c = newDeductValue;
            lstUpdatedRequests.add(request);
        }
        if(lstUpdatedRequests.size() > 0){
            update lstUpdatedRequests;
        }
    }
}