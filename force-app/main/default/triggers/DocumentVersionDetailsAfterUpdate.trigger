/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 11-07-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
trigger DocumentVersionDetailsAfterUpdate on Apttus__DocumentVersionDetail__c (After update) {

    /**************************************************************************************
    -- - Author        : Telesio
    -- - Description   : Trigger on Apttus__DocumentVersionDetail__c
    --
    -- Maintenance History:
    --
    -- Date         Name  Version  Remarks
    -- -----------  ----  -------  -------------------------------------------------------
    -- 14-AUG-2020  SBH   1.0      Initial version
    --------------------------------------------------------------------------------------
    **************************************************************************************/

    // Bypass des Triggers en mode Batch, future ou queuable (pour gérer la réentrance). 
    if (system.isBatch() || system.isFuture() || system.isQueueable()) {
        System.debug('EventLogAfterInsert: END trigger bypassed (mode)');
        return;
    }

    // notify when datafactory response is received
    if ((DocumentVersionDetails_CST.SETTING.CanAfterUpdate__c && DocumentVersionDetails_CST.DoAfterUpdate) || Test.isRunningTest()){ 
        System.debug('DocumentVersionDetails_CST : can after insert true');
        if(DocumentVersionDetails_CST.SETTING.CanGeneratePdfFile__c || Test.isRunningTest() ){
            System.debug('DocumentVersionDetails_CST : CanGeneratePdfFile__c true');
            DocumentVersionDetails_DMN.generatePdf(Trigger.new, Trigger.oldMap); 
        }
    } 

    
}