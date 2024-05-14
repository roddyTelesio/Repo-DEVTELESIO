trigger DocumentVersionDetailBeforeInsert on Apttus__DocumentVersionDetail__c (before insert) {
/**************************************************************************************
    -- - Author        : Telesio
    -- - Description   : before insert Trigger on Apttus__DocumentVersionDetail__c
    --
    -- Maintenance History:
    --
    -- Date         Name  Version  Remarks
    -- -----------  ----  -------  -------------------------------------------------------
    -- 14-AUG-2020  SBH   1.0      Initial version
    --------------------------------------------------------------------------------------
    **************************************************************************************/

    // Bypass des Triggers en mode Batch, future ou queuable (pour gérer la réentrance). 
    if (system.isBatch() || system.isFuture() || system.isQueueable()) {System.debug('DocumentVersionDetailBeforeInsert: END trigger bypassed (mode)');return;}

    // notify when datafactory response is received

    System.debug('DocumentVersionDetailBeforeInsert : before insert to process');
    DocumentVersionDetails_DMN.beforeInsert(Trigger.new); 


}