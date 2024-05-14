public with sharing class TreatyTriggerHandler {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : handler for trigger on Treaty
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 07-APR-2020  SAU   1.0      Initial version
-- 25-JUN-2021  MBE   1.1      Update Custom Setting for Treaty Reference
--------------------------------------------------------------------------------------
**************************************************************************************/

    public void handleAfterUpdate(List<Treaty__c> lstOldTreaties, List<Treaty__c> lstNewTreaties){
            List <String> lstValuesRemoved = new List <String>();
            List <String> lstOldTreatyValues = new List <String>();
            List <String> lstNewTreatyValues = new List <String>();
            List <Id> lstTreatiesIds = new List <Id>();
            List<Id> lstTreatiesDeduc = new List<Id>();
            List<Id> lstIdTreaty = new List<Id>();
            List<Treaty__c> lstNewTreaty = new List<Treaty__c>();
            Decimal treatyDeductVal;

            if(PAD.canRun('AP33_updateSigningRequests')){
                for(Integer i = 0; i < lstOldTreaties.size(); i++){
                    Treaty__c oldTreaty = lstOldTreaties[i];
                    Treaty__c newTreaty = lstNewTreaties[i];

                    if(newTreaty.TECH_LossDepoLevel__c == 'Treaty') {
                        if (oldTreaty.LossDepositMode__c != newTreaty.LossDepositMode__c) {
                            lstTreatiesIds.add(newTreaty.Id);
                            if (oldTreaty.LossDepositMode__c != null) {
                                lstOldTreatyValues = oldTreaty.LossDepositMode__c.split(';');
                            }
                            if (newTreaty.LossDepositMode__c != null) {
                                lstNewTreatyValues = newTreaty.LossDepositMode__c.split(';');
                            }

                            for (Integer x = 0; x < lstOldTreatyValues.size(); x++) {
                                if (!lstNewTreatyValues.contains(lstOldTreatyValues[x])) {
                                    lstValuesRemoved.add(lstOldTreatyValues[x]);
                                }
                            }
                        }
                    }

                    // SAU when deduction changes on treaty
                    if(oldTreaty.Deductions_Perc__c != newTreaty.Deductions_Perc__c){
                        treatyDeductVal = newTreaty.Deductions_Perc__c;
                        lstTreatiesDeduc.add(newTreaty.Id);
                    }
                }
                System.debug('lstOldTreatyValues == ' + lstOldTreatyValues);
                System.debug('lstNewTreatyValues == ' + lstNewTreatyValues);
                System.debug('lstValuesRemoved == ' + lstValuesRemoved);

                //RRA - ticket 1420 - 08022023
                for(Integer i = 0; i < lstNewTreaties.size(); i++) {
                    if(lstOldTreaties[i].LossDeposit__c != lstNewTreaties[i].LossDeposit__c){
                        lstIdTreaty.add(lstNewTreaties[i].Id);
                        lstNewTreaty.add(lstNewTreaties[i]);
                    }
                    if(lstOldTreaties[i].PremiumDeposit__c != lstNewTreaties[i].PremiumDeposit__c){
                        lstIdTreaty.add(lstNewTreaties[i].Id);
                        lstNewTreaty.add(lstNewTreaties[i]);
                    }
                    if(lstOldTreaties[i].Deductions_Perc__c != lstNewTreaties[i].Deductions_Perc__c){
                        lstIdTreaty.add(lstNewTreaties[i].Id);
                        lstNewTreaty.add(lstNewTreaties[i]);
                    }
                    
                if(lstValuesRemoved.size()>0){
                AP33_UpdateSigningRequests.updateSigningRequests(lstTreatiesIds, null, lstValuesRemoved);
                }
                if(lstTreatiesDeduc.size() > 0){
                    AP40_UpdateSigningReqDeductions.updateSigningRequests(lstTreatiesDeduc, treatyDeductVal);
                }
                if(lstIdTreaty.size() > 0){
                    AP64_UpdateRequestFromConditions.updateRequestFromConditions(lstIdTreaty, lstNewTreaty, 'Treaty');
                }
            }
        }
    }

    public void handleAfterInsert(List<Treaty__c> lstNewTreaties){
        System.debug('lstNewTreaties old == ' + lstNewTreaties);
        if(PAD.canRun('AP58_UpdateCSTreatyReference') && lstNewTreaties.size() > 0){
            AP58_UpdateCSTreatyReference.updateCSTreatyReference(lstNewTreaties);
        }
    }
}