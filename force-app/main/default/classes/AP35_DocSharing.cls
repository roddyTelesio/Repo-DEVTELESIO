public with sharing class AP35_DocSharing {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Class for Document Sharing
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 15-JUN-2020  NBI   1.0      Initial Version
--------------------------------------------------------------------------------------
**************************************************************************************/

    /**
    * @description Method to change visibility of documents
    * @param List<DocumentVisibility__c> lstDocVisibility
    * @return void
    */
    public static void shareDocuments(List<DocumentVisibility__c> lstDocVisibility){
        try{
            List<ContentVersion> lstContentVersion = new List<ContentVersion>();
            List<ContentDocumentLink> lstContentDocLink;
            Set<ContentDocumentLink> setLstContentDocLink = new Set<ContentDocumentLink>();
            List<ContentDocumentLink> updateLstContentDocLink = new List<ContentDocumentLink>();
            Set<Id> setConVersionId = new Set<Id>();
            Set<Id> setProgramId = new Set<Id>();
            Map<Id, Id> mapVersionIdVSDocId = new Map<Id, Id>();
            Set<Id> setContentDocId = new Set<Id>();

            for(DocumentVisibility__c docVisibility : lstDocVisibility) {
                if(docVisibility.ContentVersionId__c != null && docVisibility.Program__c != null){
                    setProgramId.add(docVisibility.Program__c);
                    setConVersionId.add(docVisibility.ContentVersionId__c);
                }
            }

            for(ContentVersion contentVersion : [SELECT Id, SharingOption, SharingPrivacy, OwnerId, ContentDocumentId FROM ContentVersion WHERE Id IN :setConVersionId]){
                mapVersionIdVSDocId.put(contentVersion.Id, contentVersion.ContentDocumentId);
                setContentDocId.add(contentVersion.ContentDocumentId);
            }

            lstContentDocLink = [SELECT ContentDocumentId, LinkedEntityId, ShareType, Visibility FROM ContentDocumentLink WHERE LinkedEntityId IN :setProgramId AND Visibility != 'AllUsers'];

            for(DocumentVisibility__c docVisibility : lstDocVisibility){
                if(docVisibility.ContentVersionId__c != null && docVisibility.Program__c != null){
                    for(ContentDocumentLink contentDocLink : lstContentDocLink){
                        if(contentDocLink.LinkedEntityId == docVisibility.Program__c){
                            if(mapVersionIdVSDocId != null && mapVersionIdVSDocId.containsKey(docVisibility.ContentVersionId__c) && mapVersionIdVSDocId.get(docVisibility.ContentVersionId__c) == contentDocLink.ContentDocumentId){
                                contentDocLink.Visibility = 'AllUsers';
                                setLstContentDocLink.add(contentDocLink);
                            }
                        }
                    }
                }
            }

            if(setLstContentDocLink.size() > 0){
                updateLstContentDocLink.addAll(setLstContentDocLink);
            }

            if(updateLstContentDocLink.size() > 0){
                update updateLstContentDocLink;
            }
        }
        catch(Exception e){
        }
    }
}