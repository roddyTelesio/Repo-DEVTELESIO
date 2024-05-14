trigger EventLogAfterInsert on EventLog__c (after insert) {
    /**************************************************************************************
    -- - Author        : Telesio
    -- - Description   : Trigger on EventLog__c
    --
    -- Maintenance History:
    --
    -- Date         Name  Version  Remarks
    -- -----------  ----  -------  -------------------------------------------------------
    -- 15-DEC-2020  NBI   1.0      Initial version
    --------------------------------------------------------------------------------------
    **************************************************************************************/

    // Bypass des Triggers en mode Batch, future ou queuable (pour gérer la réentrance). 
    if (system.isBatch() || system.isFuture() || system.isQueueable()) {
        System.debug('EventLogAfterInsert: END trigger bypassed (mode)');
        return;
    }

    // notify when datafactory response is received
    if ((EventLog_CST.SETTING.CanAfterInsert__c) && (EventLog_CST.DoAfterInsert)){ 
        System.debug('EventLog_CST : can after insert true');
        if(EventLog_CST.SETTING.DataFactoryNotify__c){
            System.debug('EventLog_CST : DataFactoryNotify__c true');
            EventLog_DMN.onDataFactoryNotify(Trigger.new); 
        }
    }  
}