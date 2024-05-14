public with sharing class DocumentVisibilityTriggerHandler {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Document Visibility Trigger Handler Class
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 15-JUN-2020  NBI   1.0      Initial Version
--------------------------------------------------------------------------------------
**************************************************************************************/

    public DocumentVisibilityTriggerHandler(){}

    /**
    * @description Method to share Documents after insert a Document Visibility record
    * @param List<DocumentVisibility__c> lstDocVisibility
    * @return void
    */
    public void handleAfterInsert(List<DocumentVisibility__c> lstDocVisibility) {
        if(PAD.canRun('AP35_DocSharing') && lstDocVisibility.size() > 0){
            AP35_DocSharing.shareDocuments(lstDocVisibility);
        }
    }
}