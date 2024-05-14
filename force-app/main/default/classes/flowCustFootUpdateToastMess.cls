/**************************************************************************************
-- - Author        : Telesio DEV (RRA)
-- - Description   : Update SuccessErrorToastMessageOnFlow__c field to null => When the screen subSection is displaying after click button generate hazard bassins
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 22-SEPT-2022  RRA   1.0      Initial version
--------------------------------------------------------------------------------------
**************************************************************************************/

public with sharing class flowCustFootUpdateToastMess {
    @AuraEnabled 
    public static String updateToastMessageOnFlow(Id idSection){
        String message = '';
        Section__c sec = [SELECT Id, SuccessErrorToastMessageOnFlow__c FROM Section__c WHERE Id =: idSection];
        if (sec.SuccessErrorToastMessageOnFlow__c != null || sec.SuccessErrorToastMessageOnFlow__c != ''){
            sec.SuccessErrorToastMessageOnFlow__c = null;
            message='Update Done';
        }
        message = 'Update Not Done';
        update sec;
        return message;
    }
    
    //RRA - ticket 1532 - 22062023
    @AuraEnabled
    public static List<Section__c> getInfoWorkingScope(Id idSection) {
    return [SELECT Id, Program__c, Program__r.UwYear__c, Program__r.PrincipalCedingCompany__c, Program__r.TECH_StageName__c FROM Section__c WHERE Id =:idSection];
    }

}