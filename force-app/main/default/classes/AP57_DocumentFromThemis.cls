public with sharing class AP57_DocumentFromThemis {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Document Themis Class
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 31-MAY-2021  MBE    1.0     Initial Version
-- 13-JUL-2021  NBI    1.1      W-1008 : Documents - Incrémentation des versions de documents Thémis par phase
--------------------------------------------------------------------------------------
**************************************************************************************/

    /**
    * @description Method to create Content Document Link for Themis
    * @param List<ContentVersion> lstNewContentVersion
    * @return void
    */
    public static void createContentDocLink(List<ContentVersion> lstNewContentVersion){
        List<ContentDocumentLink> lstContentDocumentLinkToInsert = new List<ContentDocumentLink>();
        Savepoint sp = Database.setSavepoint();

        try {
            for(ContentVersion contentVersion : lstNewContentVersion){
                ContentDocumentLink cd = new ContentDocumentLink();
                cd.LinkedEntityId = contentVersion.ProgramID__c;
                cd.ContentDocumentId = contentVersion.ContentDocumentId;
                cd.Visibility = 'AllUsers';
                cd.ShareType = 'V';
                lstContentDocumentLinkToInsert.add(cd);
            }

            if(lstContentDocumentLinkToInsert.size() > 0){
                insert lstContentDocumentLinkToInsert;
            }
        }
        catch (Exception ex) {
            Database.rollback(sp);
        }  
    }

    /**
    * @description Method to increment Version in Content Version for Themis
    * @param List<ContentVersion> lstNewContentVersion
    * @return void
    */
    public static void incrementContentVersion(List<ContentVersion> lstNewContentVersion){
        List<String> lstDocumentId = new List<String>();
        Map<String, List<Decimal>> mapListDocVersions = new Map<String, List<Decimal>>();
        Savepoint sp = Database.setSavepoint();

        try{
            for(ContentVersion contentVersion : lstNewContentVersion){
               if(contentVersion.DocumentID__c != null){
                   lstDocumentId.add(contentVersion.DocumentID__c);
               }
            }

            for(ContentVersion cv : [SELECT Id, Version__c, DocumentID__c, Phase__c FROM ContentVersion WHERE FromThemis__c = true AND DocumentID__c = :lstDocumentId]){
                String docIdPhase = cv.DocumentID__c + '-' + cv.Phase__c;
                if(mapListDocVersions.containsKey(docIdPhase)){
                    mapListDocVersions.get(docIdPhase).add(cv.Version__c);
                }
                else{
                    mapListDocVersions.put(docIdPhase, new List<Decimal>{cv.Version__c});
                }
            }

            for(ContentVersion cv : lstNewContentVersion){
                String docIdPhase = cv.DocumentID__c + '-' + cv.Phase__c;
                if(cv.DocumentID__c != null && mapListDocVersions.containsKey(docIdPhase)){
                    List<Decimal> lstVersions = (List<Decimal>) mapListDocVersions.get(docIdPhase);
                    lstVersions.sort();

                    cv.Version__c = (Decimal) lstVersions[lstVersions.size() - 1] + 1;
                }
                else{
                    cv.Version__c = 1;
                }
            }
        }
        catch(Exception ex) {
            Database.rollback(sp);
        }  
    }
}