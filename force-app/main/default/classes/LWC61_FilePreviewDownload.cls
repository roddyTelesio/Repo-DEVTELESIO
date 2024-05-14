/**************************************************************************************
-- - Author        : Telesio
-- - Description   : Controller for Lightning Web Component LWC61_PreviewDownloadFile
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 17-OCT-2023  RRA   1.0      Ticket 1675 - Initial version
-- 17-OCT-2023  RRA   1.0      Ticket 1675 - Create public group named Portal public group > select Portal Role and Subordinaltes > add all roles on selected members by grouping 100 items 
 --------------------------------------------------------------------------------------
**************************************************************************************/

public without sharing class LWC61_FilePreviewDownload {
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getRelatedFiles() {
        List<Id> lstFileIDs = new List<Id>();
        Map<String, Object> mapResults = new Map<String, Object>();
        Map<Id, String> mapIdTitle = new Map<Id, String>();
        Map<Id, Integer> mapIdSize = new Map<Id, Integer>();
        Map<Id, String> mapIdColorSize = new Map<Id, String>();
        Map<Id, Id> mapIdContIdConv= new Map<Id, Id>();
        System.debug ('begin LWC61_FilePreviewDownload ');
        //Get Id from ContentWorkspace 
        List<ContentWorkspace > lstContentWrkSpace = [SELECT Id,Name FROM ContentWorkspace WHERE Name LIKE '%Portal General Conditions%' LIMIT 1];
        System.debug ('lstContentWrkSpace ==  ' + lstContentWrkSpace);
        Id contentWorkSpaceForAXA = lstContentWrkSpace[0].Id;
        System.debug ('contentWorkSpaceForAXA == ' + contentWorkSpaceForAXA);
        // Get record file Ids        
        List<ContentDocumentLink> lstContentfiles = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :contentWorkSpaceForAXA];

        for (ContentDocumentLink docLink : lstContentfiles) {
            lstFileIDs.add(docLink.ContentDocumentId);
        }
        System.debug ('lstFileIDs == ' + lstFileIDs);
        List<ContentVersion> lstDocsConv = [SELECT ContentDocumentId, FileExtension, Title, ContentSize FROM ContentVersion WHERE ContentDocumentId IN : lstFileIDs];
        
        for (ContentVersion docLink : lstDocsConv) {
            
            mapIdTitle.put(docLink.ContentDocumentId, docLink.Title);
            mapIdSize.put(docLink.ContentDocumentId, docLink.ContentSize);
            mapIdContIdConv.put(docLink.ContentDocumentId, docLink.Id);
            if (docLink.ContentSize > 25000000){
                mapIdColorSize.put(docLink.ContentDocumentId, 'red-color');
            }else {
                mapIdColorSize.put(docLink.ContentDocumentId, 'green');
            }
        }
        mapResults.put('mapIdTitle', mapIdTitle);
        mapResults.put('mapIdContIdConv', mapIdContIdConv);
        mapResults.put('mapIdSize', mapIdSize);
        mapResults.put('mapIdColorSize', mapIdColorSize);
        
        System.debug ('mapResults == ' + mapResults);
        return mapResults;
    }
}