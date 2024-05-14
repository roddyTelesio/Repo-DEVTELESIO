public with sharing class ReinstatementTriggerHandler {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Handler for trigger on Reinstatement
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 15-JUN-2020  MBE   1.0      Initial version
--------------------------------------------------------------------------------------
**************************************************************************************/

    public void handleAfterInsert(List<Reinstatement__c> lstNewReinstatements){
        Set<Id> setIdReins = new Set<Id>();
        for (Reinstatement__c reins : lstNewReinstatements){
            setIdReins.add(reins.Id);
        }
        if(PAD.canRun('AP34_UpdateSections') && lstNewReinstatements.size() > 0){
            AP34_UpdateSections.updateSections(setIdReins);
        }
    }

    public void handleAfterUpdate(List<Reinstatement__c> lstOldReinstatements, List<Reinstatement__c> lstNewReinstatements){

        List<Reinstatement__c> lstReinstatements = new List<Reinstatement__c>();
        Set<Id> setIdReins = new Set<Id>();
        for(Integer i = 0; i < lstNewReinstatements.size(); i++) {
            if(PAD.canRun('AP34_UpdateSections')){
                //Condition based on requirement
                if(lstOldReinstatements[i].Order__c != lstNewReinstatements[i].Order__c || lstOldReinstatements[i].Prorata__c != lstNewReinstatements[i].Prorata__c || lstOldReinstatements[i].Percentage__c != lstNewReinstatements[i].Percentage__c || lstOldReinstatements[i].Free__c != lstNewReinstatements[i].Free__c){
                    //lstReinstatements.add(lstNewReinstatements[i]);
                    setIdReins.add(lstNewReinstatements[i].Id);
                }
            }
        }

        if(PAD.canRun('AP34_UpdateSections') && setIdReins.size() > 0){
            //Call class/method for the specific development
            AP34_UpdateSections.updateSections(setIdReins);
        }
    }

    public void handleAfterDelete(List<Reinstatement__c> lstOldReinstatements){
        Set<Id> setIdOldReins = new Set<Id>();
        for (Reinstatement__c reins : lstOldReinstatements){
            setIdOldReins.add(reins.Id);
        }
        if(PAD.canRun('AP34_UpdateSections') && lstOldReinstatements.size() > 0){
            AP34_UpdateSections.updateSections(setIdOldReins);
        }
    }
}