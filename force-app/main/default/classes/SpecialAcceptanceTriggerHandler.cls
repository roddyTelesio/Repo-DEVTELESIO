public with sharing class SpecialAcceptanceTriggerHandler {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Request Trigger Handler Class
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 24-FEB-2021  MBE    1.0     Initial Version
--------------------------------------------------------------------------------------
**************************************************************************************/

    public SpecialAcceptanceTriggerHandler() {}

    public void handleAfterUpdate(List<SpecialAcceptance__c> lstOldSA, List<SpecialAcceptance__c> lstNewSA){
        List<SpecialAcceptance__c> lstSAToSendMailReminder = new List<SpecialAcceptance__c>();

        for(Integer i = 0; i < lstNewSA.size(); i++) {
            System.debug('### lstNewSA[i].SentAgreFromSpecialAcceptance__c'+ lstNewSA[i].SentAgreFromSpecialAcceptance__c);
            if(PAD.canRun('AP56_SendBindReminder')){
                //if(lstOldSA[i].TECH_BindReminder__c != lstNewSA[i].TECH_BindReminder__c){ //MRA 01/08/2022 W-1229 Mass mail send on declaration Type SA 
                //RRA - ticket 1447 - 14032023
                if(lstOldSA[i].TECH_BindReminder__c != lstNewSA[i].TECH_BindReminder__c && lstNewSA[i].Type__c != '1' && lstNewSA[i].SentAgreFromSpecialAcceptance__c != null && lstNewSA[i].Bound__c != '1'){
                    System.debug('### Miditra ato') ;
                    lstSAToSendMailReminder.add(lstNewSA[i]);
                }
            }
        }

        System.debug('## before AP56_SendBindReminder lstSAToSendMailReminder.size()'+ lstSAToSendMailReminder.size());

        if(PAD.canRun('AP56_SendBindReminder') && lstSAToSendMailReminder.size() > 0){
            System.debug('### Miditra ato') ;
            AP56_SendBindReminder.sendBindReminderToCovCedCon(lstSAToSendMailReminder);
        }
    }

}