public with sharing class ContentVersionTriggerHandler {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Content Version Trigger Handler Class
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 31-MAY-2021  MBE    1.0     Initial Version
--------------------------------------------------------------------------------------
**************************************************************************************/
    public ContentVersionTriggerHandler() {}

    public void handleAfterInsert(List<ContentVersion> lstNewContentVersion){
        List<ContentVersion> lstContentVersion = new List<ContentVersion>();

        for(Integer i = 0; i < lstNewContentVersion.size(); i++) {
            if(PAD.canRun('AP57_DocumentFromThemis')){
                if(lstNewContentVersion[i].FromThemis__c == true){
                    lstContentVersion.add(lstNewContentVersion[i]);
                }
            }
        }

        if(PAD.canRun('AP57_DocumentFromThemis') && lstContentVersion.size() > 0){
            AP57_DocumentFromThemis.createContentDocLink(lstContentVersion);
        }
    }

    public void handleBeforeInsert(List<ContentVersion> lstNewContentVersion){
        List<ContentVersion> lstContentVersion = new List<ContentVersion>();

        for(Integer i = 0; i < lstNewContentVersion.size(); i++) {
            if(PAD.canRun('AP57_DocumentFromThemis')){
                if(lstNewContentVersion[i].FromThemis__c == true){
                    lstContentVersion.add(lstNewContentVersion[i]);
                }
            }
        }

        if(PAD.canRun('AP57_DocumentFromThemis') && lstContentVersion.size() > 0){
            AP57_DocumentFromThemis.incrementContentVersion(lstContentVersion);
        }
    }

}