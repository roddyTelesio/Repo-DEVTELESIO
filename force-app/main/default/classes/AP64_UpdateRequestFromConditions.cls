public with sharing class AP64_UpdateRequestFromConditions {
/**************************************************************************************
-- - Author        : Telesio
-- - Description   : Controller apex to update fields
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 07-JAN-2023  RRA   1.0      Initial version ticket 1420 - 07022023 SIGNING - Loss Deposit in Signing not equal to loss deposit in Conditions 																		   
--------------------------------------------------------------------------------------
**************************************************************************************/

    /**
    * @description Method to update values of Request if conditions change on Program : LossDepositMode__c / LossDeposit__c 
    * @param List<Id> lstIdProgram
    */
    public static void updateRequestFromConditions(List<Id> lstIds, List<SObject> lstNewsObject, String objectName){
        System.debug('begin updateRequestFromConditions');
        Map<Id, SObject> mapProgramLossDepositValues = new Map<Id, SObject> ();

        String query = 'SELECT Id, OriginalRequest__c, Program__c, LossDeposit__c, LossDepositMode__c, Program__r.LossDeposit__c, Program__r.LossDepositMode__c, Deductions__c, Treaty__r.PremiumDeposit__c, Treaty__r.TECH_PremiumDeposit__c, Treaty__r.LossDepositMode__c, Treaty__r.LossDeposit__c, Treaty__r.Deductions_Perc__c FROM Request__c';

        if(objectName == 'Program'){
            System.debug('pass on request from program');
            query = query + ' WHERE Program__c IN: lstIds';
        }else if (objectName == 'Treaty'){
            System.debug('pass on request from treaty');
            query = query + ' WHERE Treaty__c IN: lstIds';
        }else {
            query = null;
        }

        if (lstNewsObject.size() > 0 ){
            for (SObject record : lstNewsObject){
                mapProgramLossDepositValues.put((Id)record.get('Id'), record);
            }
        }
        List<Request__c> lstRequestToUpdate = Database.query(query);
        if (lstRequestToUpdate.size () > 0){
            for (Request__c req : lstRequestToUpdate){
                if(objectName == 'Program'){ 
                    System.debug('pass to update request from program');
                    req.LossDeposit__c = (String)mapProgramLossDepositValues.get(req.Program__c).get('LossDeposit__c');
                }else if (objectName == 'Treaty'){
                    System.debug('pass to update request from treaty');
                    req.PremiumDeposit__c = (String)mapProgramLossDepositValues.get(req.Treaty__c).get('TECH_PremiumDeposit__c');
                    req.LossDeposit__c = (String)mapProgramLossDepositValues.get(req.Treaty__c).get('LossDeposit__c');
                    req.Deductions__c = (Decimal)mapProgramLossDepositValues.get(req.Treaty__c).get('Deductions_Perc__c');
                }   
            }
            update lstRequestToUpdate;
        }
        System.debug('end updateRequestFromConditions lstRequestToUpdate == '  + lstRequestToUpdate);
        System.debug('end updateRequestFromConditions');
    }
}