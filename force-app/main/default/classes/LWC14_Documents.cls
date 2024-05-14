/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 10-11-2023
 * @last modified by  : Patrick Randrianarisoa
**/
public with sharing class LWC14_Documents {
    /**************************************************************************************
    -- - Author        : Spoon Consulting
    -- - Description   : Controller for Lightning Web Component lwc14Documents
    --
    -- Maintenance History:
    --
    -- Date         Name  Version  Remarks
    -- -----------  ----  -------  -------------------------------------------------------
    -- 10-DEC-2019  MBE   1.0      Initial version
    -- 06-JUL-2020  SAU   1.1      Retrieve external documents
    -- 12-APR-2021  MBE   1.2      W-0838 - Tri des documents dans toutes les phases
    -- 03-JUN-2021  MBE   1.3      Themis - Point 4: I need to see the last version of the each Themis document
    -- 11-JUN-2021  NBI   1.4      New section to display THEMIS documents - backlog point 5
    -- 13-JUL-2021  NBI   1.5      W-1008 : Documents - Incrémentation des versions de documents Thémis par phase
    -- 19-OCT-2021  MBE   1.6      W-1034 - tailles limite de documents envoyés
    -- 05-JUL-2022  AMI   1.7      W-0944 - Changer les caractéristiques de documents qu'on a pas ajouté
    -- 10-JUL-2023  ANA   1.8      AGRE-CLM Get Conga documents 
    --------------------------------------------------------------------------------------
    **************************************************************************************/
    
        /**
        * @description Method to save Documents for a Program
        * @param List<ContentVersion> lstContentVersion, Id programId, List<Id> lstDeletedDocument
        * @return Map<String, Object>
        */
        @AuraEnabled
        public static Map<String, Object> saveDocuments(List<ContentVersion> lstContentVersion, Id programId, List<Id> lstDeletedDocument) {
            Map<String, Object> mapResults = new Map<String, Object>();
    
            try {
                if (lstDeletedDocument.size() > 0) {
                    Set<Id> setContentDocumentId = new Set<Id>();
    
                    for (ContentVersion contentVersion : [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN :lstDeletedDocument AND SpecialAcceptance__c = NULL]) {
                        setContentDocumentId.add(contentVersion.ContentDocumentId);
                    }
    
                    List<ContentDocument> lstContentDoc = [SELECT Id FROM ContentDocument WHERE Id IN :setContentDocumentId];
                    delete lstContentDoc;
                }
    
                //AMI 05/07/22 W-0944 - Changer les caractéristiques de documents qu'on a pas ajouté
                //added admin rights on cv update
                if (lstContentVersion.size() > 0) {
                    performAdminRequest utils = new performAdminRequest();
                    map <string,object> status = utils.updateContentVersionProperties(lstContentVersion);

                    if(status.get('status') == 'OK'){
                        mapResults.put('Success', 'Success');
                    }else{
                        mapResults.put('Error', (string)status.get('message'));
                    }
                }
            }
            catch (Exception ex) {
                mapResults.put('Error', ex.getMessage());
            }
            return mapResults;
        }
    
        /**
        * @description Method to get Portal Documents for a Program
        * @param Id programId
        * @return List<ContentVersion>
        */
       /* @AuraEnabled 
        public static List<contentVersionWrapper> getExternalDocuments(Id programId) {
            Set<Id> setContentDocumentId = new Set<Id>();
            Map<Id, ContentVersion> mapContentVersionByDocumentId = new Map<Id, ContentVersion>();
            List<contentVersionWrapper> lstcvWrp = new List<contentVersionWrapper> ();
            //Map<String, Id> mapRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectAcc});
     
            for (ContentDocumentLink contentDocLink : [SELECT Id, ContentDocumentId
                                                        FROM ContentDocumentLink
                                                        WHERE LinkedEntityId = :programId AND Visibility = 'AllUsers']){
                setContentDocumentId.add(contentDocLink.ContentDocumentId);
            }
            
            System.debug('setContentDocumentId=='+ setContentDocumentId);
            List<ContentVersion> lstContentVersion = [
                    SELECT Id, 
                           ToLabel(Phase__c), 
                           Title,
                           IsExternal__c,
                           ContentDocumentId,
                           VersionData,
                           Tech_BrokerId__c,
                           Tech_BrokerName__c,
                           Tech_ReinsurerId__c,
                           Tech_ReinsurerName__c,
                           CreatedDate,
                           Tech_NumberPhase__c
                    FROM ContentVersion
                    WHERE ContentDocumentId IN :setContentDocumentId
                    AND IsExternal__c = TRUE ORDER BY Tech_NumberPhase__c DESC
            ];
    
            System.debug('lstContentVersion=='+ lstContentVersion);
    
            for(ContentVersion contentVersion : lstContentVersion){
                contentVersionWrapper cvWrap = new contentVersionWrapper ();
                cvWrap.Id = contentVersion.Id;
                cvWrap.phase = contentVersion.Phase__c;
                cvWrap.title = contentVersion.Title;
                cvWrap.isExt = contentVersion.IsExternal__c;
                cvWrap.contentDocId = contentVersion.ContentDocumentId;
                cvWrap.versData = contentVersion.VersionData;
                cvWrap.broker = contentVersion.Tech_BrokerName__c ;
                cvWrap.reinsurer = contentVersion.Tech_ReinsurerName__c;
                cvWrap.dateConv = contentVersion.CreatedDate.format('d/M/YYYY HH:mm:ss'); 
                cvWrap.phaseNumber = contentVersion.Tech_NumberPhase__c;
               /* if(contentVersion.CreatedBy.Account.RecordTypeId == mapRecTypeId.get(AP_Constant.accRTBroker)){    
                    cvWrap.broker = contentVersion.CreatedBy.Contact.Account.Name;
                }
                if(contentVersion.CreatedBy.Account.RecordTypeId == mapRecTypeId.get(AP_Constant.accRTReinsurer)){
                    cvWrap.reinsurer = contentVersion.CreatedBy.Contact.Account.Name;
                }
                lstcvWrp.add(cvWrap);
            }
            return lstcvWrp;
        }*/
        // RRA 1045
        @AuraEnabled 
        public static List<DocumentVisibility__c> getExternalDocumentVisibility(Id programId) {
            Set<Id> setContentDocumentId = new Set<Id>(); 
            for (ContentDocumentLink contentDocLink : [SELECT Id, ContentDocumentId
                                                        FROM ContentDocumentLink
                                                        WHERE LinkedEntityId = :programId]){
                setContentDocumentId.add(contentDocLink.ContentDocumentId);
            }
            
            System.debug('setContentDocumentId=='+ setContentDocumentId);
            List<DocumentVisibility__c> lstDocVis= [
                    SELECT Id, 
                           Tech_Phase__c, 
                           Tech_Title__c,
                           Tech_IsExternal__c,
                           Tech_ContentDocumentId__c,
                           Tech_BrokerId__c,
                           Tech_BrokerName__c,
                           Tech_ReinsurerId__c,
                           Tech_ReinsurerName__c,
                           Tech_Date__c,
                           Tech_NumberPhase__c,
                           Tech_LabelPhase__c,
                           Tech_Request_Status__c
                    FROM DocumentVisibility__c
                    WHERE Tech_ContentDocumentId__c IN :setContentDocumentId
                    AND Tech_IsExternal__c = TRUE AND Tech_Request_Status__c =: AP_Constant.statusVisibleOnPortalDocVis ORDER BY Tech_NumberPhase__c DESC // RRA - 1054 Add Tech_Request_Status__c
            ];
    
            System.debug('lstDocVis=='+ lstDocVis);
    
            return lstDocVis;
        }

        /**
        * @description Method to get CONGA Documents for a Program
        * @param Id programId
        * @return List<ContentVersion>
        * @author AzharNahoor
        */
        @AuraEnabled
        public static Map<String,Object> viewOrCreateAgreement(Id programId, Id recordTypeId) {
            System.debug(LoggingLevel.DEBUG, 'viewOrCreateAgreement START with : ' + programId);
            try{
                List<Apttus__APTS_Agreement__c> agreement  = [
                    SELECT Id 
                    FROM Apttus__APTS_Agreement__c 
                    WHERE Program__c =: programId 
                    AND Reinsurer__c = NULL
                    AND (Recordtype.developername = 'Acceptation'
                    OR Recordtype.developername = 'GroupCover'
                    OR RecordType.developername = 'GlobalBroker')
                    ORDER BY CREATEDDATE DESC
                    LIMIT 1
                ];
                System.debug(LoggingLevel.DEBUG, 'viewOrCreateAgreement agreement : ' + agreement);

    
                if(!agreement.isEmpty()){
                    return new Map<String,Object>{'isSuccess' => true, 'value'=> agreement[0].Id};
                }else{

                    if(recordTypeId != null){
                        System.debug(LoggingLevel.DEBUG, 'viewOrCreateAgreement creating a new agreeement');
                        Apttus__APTS_Agreement__c newAgreement = new Apttus__APTS_Agreement__c(
                            Program__c = programId ,
                            RecordtypeId = recordTypeId
                        );
                        insert newAgreement;
                        return new Map<String,Object>{'isSuccess' => true, 'value'=> newAgreement.Id};
                    }
                    return new Map<String,Object>{'isSuccess' => true, 'value'=> 'createNew'};
                           
                }
            }catch(Exception e){
                System.debug(LoggingLevel.DEBUG, 'viewOrCreateAgreement exception e : ' + e.getMessage());
                return new Map<String,Object>{'isSuccess' => false, 'value'=>  e.getMessage()};       
            }

        }

        /**
        * @description Method to get CONGA Documents version details for each latest created stage
        * @param String programId
        * @return List<String> of document version detail Ids
        * @author AzharNahoor 
        */
        public static List<String> getLatestDocVersionDetailsByStage(String programId, String stage){
            List<String> latestDocVersionDetailsByStage = new List<String>();

            List<AggregateResult> latestRecords = [
                SELECT Stage__c, MAX(CreatedDate) maxCreatedDate, Apttus__DocumentVersionId__r.Apttus__AgreementId__c
                FROM   Apttus__DocumentVersionDetail__c
                WHERE  TECH_Program__c = :programId
                AND    NAME LIKE '%-pdf'
                GROUP BY Stage__c,  Apttus__DocumentVersionId__r.Apttus__AgreementId__c
            ];
            
            System.debug('latestRecords: ' + latestRecords);
            
            for (AggregateResult ar : latestRecords) {
                String recordStage = (String) ar.get('Stage__c');
                Datetime maxCreatedDate = (Datetime) ar.get('maxCreatedDate');
                // String agreement = (String) ar.get('Apttus__DocumentVersionId__r.Apttus__AgreementId__c');

                if(stage != null){
                    if(recordStage != stage){
                        continue;
                    }
                }
            
                System.debug('Processing Stage: ' + recordStage + ', Max Created Date: ' + maxCreatedDate);
                //🥶 Don't worry query for latest records will never return more than 200 records (to cause DML Error)
                List<Apttus__DocumentVersionDetail__c> stageRecords = [
                    SELECT Id
                    FROM   Apttus__DocumentVersionDetail__c
                    WHERE  Stage__c        = :recordStage 
                    AND    CreatedDate     = :maxCreatedDate
                    AND    TECH_program__c = :programId
                    LIMIT 1
                ];
            
                System.debug('Stage Records: ' + stageRecords);
            
                if (!stageRecords.isEmpty()) {
                    latestDocVersionDetailsByStage.add(stageRecords[0].Id);
                }
            }    
            System.debug('latestDocVersionDetailsByStage: ' + latestDocVersionDetailsByStage);

            return latestDocVersionDetailsByStage;
        }


        /**
        * @description Method to get CONGA Documents for a Program
        * @param Id programId
        * @return List<ContentVersion>
        * @author AzharNahoor            System.debug(LoggingLevel.DEBUG, 'documentVersionDetails START with : ' + programId);
        */
        @AuraEnabled
        public static List<ContentVersion> getCongaDocuments(Id programId) {
            System.debug(LoggingLevel.DEBUG, '@AuraEnabled getCongaDocuments : ' + programId);
            return getCongaDocuments(programId, null);
        }

        /**
        * @description Method to get CONGA Documents for a Program
        * @param Id programId
        * @param String stage --> Specific stage for which to retrieve documents
        * @return List<ContentVersion>
        * @author AzharNahoor            System.debug(LoggingLevel.DEBUG, 'documentVersionDetails START with : ' + programId);
        */
        public static List<ContentVersion> getCongaDocuments(Id programId, String stage){
            Set<Id> contentVersionIds = new Set<Id>();
            List<ContentVersion> lstContentVersion = new List<ContentVersion>();
            Map<String,String> stageToDocumentVersion = new Map<String,String>();
            Map<String, String> versionToDocumentVersion = new Map<String,String>();
            Map<String, String> nameToDocumentVersion = new Map<String,String>();

            List<Apttus__DocumentVersionDetail__c> documentVersionDetails = [
                SELECT Id, Apttus__ContentVersionId__c, Stage__c, Name, Apttus__DocumentVersionId__r.Apttus__AgreementId__r.Name, Apttus__Title__c
                FROM Apttus__DocumentVersionDetail__c
                WHERE ID  IN :getLatestDocVersionDetailsByStage(programId, stage)
                AND Name LIKE '%-pdf'
                AND Apttus__ContentVersionId__c != null
            ];

            Map<String, Integer> mappingPhase = new Map<String, Integer> {
                'Conditions' => 1,
                'Quote' => 2,
                'Lead' => 3,
                'Placement' => 4,
                'Signing' => 5
            };

            System.debug(LoggingLevel.DEBUG, 'documentVersionDetails : ' + documentVersionDetails);

            if(!documentVersionDetails.isEmpty()){
                for(Apttus__DocumentVersionDetail__c docVersionDetail : documentVersionDetails){
                    contentVersionIds.add(docVersionDetail.Apttus__ContentVersionId__c);
                    stageToDocumentVersion.put(docVersionDetail.Apttus__ContentVersionId__c, docVersionDetail.Stage__c);
                    versionToDocumentVersion.put(docVersionDetail.Apttus__ContentVersionId__c, docVersionDetail.Name);
                    //AzharNahoor - 19/10/2023 - Display title of document instead
                    //nameToDocumentVersion.put(docVersionDetail.Apttus__ContentVersionId__c, docVersionDetail.Apttus__DocumentVersionId__r.Apttus__AgreementId__r.Name );
                    nameToDocumentVersion.put(docVersionDetail.Apttus__ContentVersionId__c, docVersionDetail.Apttus__Title__c );
                }
                System.debug(LoggingLevel.DEBUG, 'contentVersionIds : ' + contentVersionIds);

                // PRA W-1612 8/11/2023
                List<String> lstContentDocumentId = new List<String>();
                for (contentDocumentLink cdl : [Select ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :programId]){
                    System.debug('cdl added : ' + cdl);
                    lstContentDocumentId.add(cdl.ContentDocumentId);
                } 
                for( ContentVersion cv :  [SELECT Id, ToLabel(Phase__c), Title, GroupType__c, ToLabel(DocumentType__c), DocumentID__c, IsExternal__c, ContentDocumentId,
                        VersionData, FromThemis__c, Version__c, TECH_OldVersionNumber__c, FileType, TECH_SelectedBrokerRein__c, VersionNumber
                        FROM ContentVersion 
                        WHERE ID IN :contentVersionIds
                        AND FileType = 'PDF'
                        AND ContentDocumentId in :lstContentDocumentId
                        ORDER BY CreatedDate ASC]){

                            System.debug('contentVersion looping : ' + cv.Title);

                            cv.TECH_OldVersionNumber__c = versionToDocumentVersion.get(cv.Id);
                            cv.Phase__c = stageToDocumentVersion.get(cv.Id);
                            cv.TECH_PhaseNumber__c = mappingPhase.containsKey(cv.Phase__c) ? mappingPhase.get(cv.Phase__c): null;
                            cv.DocumentType__c = 'Acceptance - Special conditions';
                            // cv.Title = nameToDocumentVersion.get(cv.Id);
                            cv.grouptype__c = '1';
                            lstContentVersion.add(cv);
                }
                System.debug(LoggingLevel.DEBUG, 'contentVersions : ' + lstContentVersion);

                List<contentVersion> sortedList; 
                sortedList = ContentVersionSorter.sortByPhase(lstContentVersion);
                return sortedList;


            }

            return null;
        }


    
        /**
        * @description Method to get THEMIS Documents for a Program
        * @param Id programId
        * @return List<ContentVersion>
        */
        @AuraEnabled
        public static List<ContentVersion> getTHEMISDocuments(Id programId) {
            Set<Id> setContentDocumentId = new Set<Id>();
            Map<String, ContentVersion> mapThemisConVersionByDocumentId = new Map<String, ContentVersion>();
            List<ContentVersion> lstContentVersion = new List<ContentVersion>();
    
            for(ContentDocumentLink contentDocLink : [SELECT Id, ContentDocumentId
                                                        FROM ContentDocumentLink
                                                        WHERE LinkedEntityId = :programId]){
                setContentDocumentId.add(contentDocLink.ContentDocumentId);
            }
    
    //        List<ContentVersion> lstContentVersion = [
    //                SELECT Id, ToLabel(Phase__c), Title, ToLabel(GroupType__c), ToLabel(DocumentType__c), DocumentID__c, IsExternal__c, ContentDocumentId,
    //                        VersionData
    //                FROM ContentVersion
    //                WHERE ContentDocumentId IN :setContentDocumentId
    //                AND IsExternal__c = FALSE
    //                AND FromThemis__c = TRUE
    //        ];
    
            if(setContentDocumentId.size() > 0) {
                for(ContentVersion version : [
                        SELECT Id, ToLabel(Phase__c), Title, ToLabel(GroupType__c), ToLabel(DocumentType__c), DocumentID__c, IsExternal__c, ContentDocumentId,
                            VersionData, FromThemis__c, Version__c
                        FROM ContentVersion
                        WHERE ContentDocumentId IN :setContentDocumentId
                        AND IsExternal__c = FALSE
                        AND FromThemis__c = TRUE]){
                    if(version.FromThemis__c == true){
                        String docIdPhase = version.DocumentID__c + '-' + version.Phase__c;
    
                        if(mapThemisConVersionByDocumentId.containsKey(docIdPhase)){
                            ContentVersion lastContentVersion = mapThemisConVersionByDocumentId.get(docIdPhase);
                            if(version.Version__c > lastContentVersion.Version__c){
                                mapThemisConVersionByDocumentId.put(docIdPhase, version);
                            }
                        }
                        else{
                            mapThemisConVersionByDocumentId.put(docIdPhase, version);
                        }
                    }
                }
            }
    
            for(String documentId : mapThemisConVersionByDocumentId.keySet()){
                lstContentVersion.add(mapThemisConVersionByDocumentId.get(documentId));
            }
    
            return lstContentVersion;
        }
    
        /**
        * @description Method to get Documents for a Program
        * @param Id programId
        * @return List<ContentVersion>
        */
    //    @AuraEnabled
    //    public static List<ContentVersion> getDocuments(Id programId) {
    //        Set<Id> setContentDocumentId = new Set<Id>();
    //        Map<String, ContentVersion> mapThemisContentVersionByDocumentId = new Map<String, ContentVersion>();
    //        List<ContentVersion> lstContentVersionAll = new List<ContentVersion>();
    //
    //        for (ContentDocumentLink contentDocLink : [SELECT Id, ContentDocumentId
    //                                                    FROM ContentDocumentLink
    //                                                    WHERE LinkedEntityId = :programId]){
    //            setContentDocumentId.add(contentDocLink.ContentDocumentId);
    //        }
    //
    //        if(setContentDocumentId.size() > 0) {
    //
    //            for(ContentVersion version : [
    //                        SELECT Id, DocumentType__c, GroupType__c, Phase__c, Title, Version__c, FromThemis__c
    //                                , PathOnClient, VersionData, ContentDocumentId, VersionNumber, DocumentID__c
    //                        FROM ContentVersion
    //                        WHERE ContentDocumentId IN :setContentDocumentId
    //                        AND IsExternal__c = FALSE
    //                        AND SpecialAcceptance__c = NULL]){
    //                if(version.FromThemis__c == true){
    //                    if(mapThemisContentVersionByDocumentId.containsKey(version.DocumentID__c)){
    //                        ContentVersion lastContentVersion = mapThemisContentVersionByDocumentId.get(version.DocumentID__c);
    //                        if(version.Version__c > lastContentVersion.Version__c){
    //                            mapThemisContentVersionByDocumentId.put(version.DocumentID__c, version);
    //                        }
    //                    }
    //                    else{
    //                        mapThemisContentVersionByDocumentId.put(version.DocumentID__c, version);
    //                    }
    //                }
    //                else{
    //                    lstContentVersionAll.add(version);
    //                }
    //            }
    //        }
    //
    //        for(String documentId : mapThemisContentVersionByDocumentId.keySet()){
    //            lstContentVersionAll.add(mapThemisContentVersionByDocumentId.get(documentId));
    //        }
    //
    //        return lstContentVersionAll;
    //    }
        @AuraEnabled
        public static List<ContentVersion> getDocuments(Id programId) {
            Set<Id> setContentDocumentId = new Set<Id>();
            Map<Id, ContentVersion> mapContentVersionByDocumentId = new Map<Id, ContentVersion>();
            List<ContentVersion> lstContentVersionAll = new List<ContentVersion>();
    
            for (ContentDocumentLink contentDocLink : [SELECT Id, ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :programId]){
                setContentDocumentId.add(contentDocLink.ContentDocumentId);
            }
    
            if(setContentDocumentId.size() > 0) {
                //Remove VersionData, PathOnClient in Query lstContentVersion  
    
                for(ContentVersion version : [
                        SELECT Id, DocumentType__c, GroupType__c, Phase__c, Title
                                , ContentDocumentId, VersionNumber
                        FROM ContentVersion
                        WHERE ContentDocumentId IN :setContentDocumentId
                        AND IsExternal__c = FALSE
                        AND SpecialAcceptance__c = NULL
                        AND FromThemis__c = FALSE
                        AND CLM_Name__c = NULL // The document is not from conga 
                ]){
                    lstContentVersionAll.add(version);
                }
            }
    
            return lstContentVersionAll;
        }
    
        /**
        * @description Method to get Content Version
        * @param Id contentDocumentId
        * @return ContentVersion
        */
        @AuraEnabled(Cacheable = true)
        public static ContentVersion getContentVersionId(Id contentDocumentId) {
            ContentVersion contentVersion = [SELECT Id, Title FROM ContentVersion WHERE ContentDocumentId = :contentDocumentId AND SpecialAcceptance__c = NULL];
            return contentVersion;
        }
    
        /**
        * @description Method to get delete a Document
        * @param List<Id> lstDocumentId
        * @return Map<String, Object>
        */
        @AuraEnabled
        public static Map<String, Object> deleteContentDocument(List<Id> lstDocumentId) {
            Map<String, Object> mapResults = new Map<String, Object>();
    
            try{
                List<ContentDocument> lstContentDocument = [SELECT Id FROM ContentDocument WHERE Id IN :lstDocumentId];
    
                if (lstContentDocument.size() > 0) {
                    delete lstContentDocument;
                }
    
                mapResults.put('Success', 'Success');
            }
            catch (Exception ex) {
                mapResults.put('Error', ex.getMessage());
            }
            return mapResults;
        }
    
        /**
        * @description Method to replace a Document
        * @param Id documentIdReplace, Id selectedRowContentVersionId, String selectedDocPicklist
        * @return Map<String, Object>
        */
        @AuraEnabled
        public static Map<String, Object> saveReplaceDocument(Id documentIdReplace, Id selectedRowContentVersionId, String selectedDocPicklist){
            Map<String, Object> mapResults = new Map<String, Object>();
    
            try {
                ContentVersion contentVersionNew = [SELECT Id, PathOnClient, VersionData, ContentDocumentId, Title, DocumentType__c, GroupType__c, Phase__c FROM ContentVersion WHERE ContentDocumentId = :documentIdReplace AND SpecialAcceptance__c = NULL];
                ContentDocument contentDocument = [SELECT Id FROM ContentDocument WHERE Id = :documentIdReplace];
                List<String> lstPicklist = new List<String>();
    
                if(contentDocument != null){
                    delete contentDocument;
                }
    
                if(selectedDocPicklist.contains('//')){
                    lstPicklist = selectedDocPicklist.split('//');
                }
    
    
                ContentVersion contentVersionOld = [SELECT Id, ContentDocumentId, VersionData, DocumentType__c, GroupType__c, Phase__c FROM ContentVersion WHERE Id = :selectedRowContentVersionId AND SpecialAcceptance__c = NULL];
    
                ContentVersion contentVersionReplace = new ContentVersion();
                contentVersionReplace.ContentDocumentId = contentVersionOld.ContentDocumentId;
                contentVersionReplace.VersionData = contentVersionNew.VersionData;
                contentVersionReplace.PathOnClient = contentVersionNew.PathOnClient;
                contentVersionReplace.Title = contentVersionNew.Title;
    
                if(lstPicklist[0] != 'undefined'){
                    contentVersionReplace.GroupType__c = lstPicklist[0];
                }
                if(lstPicklist[1] != 'undefined'){
                    contentVersionReplace.DocumentType__c = lstPicklist[1];
                }
                if(lstPicklist[2] != 'undefined') {
                    contentVersionReplace.Phase__c = lstPicklist[2];
                }
    
                insert contentVersionReplace;
    
                mapResults.put('ContentVersionReplace', contentVersionReplace);
                mapResults.put('Success', 'Success');
            }
            catch (Exception ex) {
                mapResults.put('Error', ex.getMessage());
            }
            return mapResults;
        }
    
        /**
        * @description Method to delete a Document when using the Replace function
        * @param List<ContentVersion> lstReplaceContentVersion
        * @return Map<String, Object>
        */
        @AuraEnabled
        public static Map<String, Object> deleteReplaceDocument(List<ContentVersion> lstReplaceContentVersion){
            Map<String, Object> mapResults = new Map<String, Object>();
    
            try{
                Map<Id, List<String>> mapVersionNumberByDocumentId = new  Map<Id, List<String>>();
    
                for(ContentVersion contentVersion : lstReplaceContentVersion){
                    List<String> lstVersionNumber = new List<String>();
    
                    if(mapVersionNumberByDocumentId.containsKey(contentVersion.ContentDocumentId)){
                        lstVersionNumber = mapVersionNumberByDocumentId.get(contentVersion.ContentDocumentId);
                        lstVersionNumber.add(contentVersion.VersionNumber);
                        mapVersionNumberByDocumentId.put(contentVersion.ContentDocumentId, lstVersionNumber);
                    }
                    else{
                        lstVersionNumber.add(contentVersion.VersionNumber);
                        mapVersionNumberByDocumentId.put(contentVersion.ContentDocumentId, lstVersionNumber);
                    }
                }
    
                Set<Id> contentDocumentId = mapVersionNumberByDocumentId.keySet();
                List<ContentVersion> lstAllContentVersion = [SELECT Id, ContentDocumentId, VersionNumber FROM ContentVersion WHERE ContentDocumentId IN :contentDocumentId AND SpecialAcceptance__c = NULL];
                Map<Id, List<ContentVersion>> mapContentVersionsByDocumentIds = new Map<Id, List<ContentVersion>>();
    
                for(ContentVersion version : lstAllContentVersion){
                    List<String> lstContentVersionNumber = mapVersionNumberByDocumentId.get(version.ContentDocumentId);
    
                    if(!lstContentVersionNumber.contains(version.VersionNumber)){
                        List<ContentVersion> lstContentVersionToInsert = new List<ContentVersion>();
    
                        if(mapContentVersionsByDocumentIds.containsKey(version.ContentDocumentId)){
                            lstContentVersionToInsert = mapContentVersionsByDocumentIds.get(version.ContentDocumentId);
                            lstContentVersionToInsert.add(version);
                            mapContentVersionsByDocumentIds.put(version.ContentDocumentId, lstContentVersionToInsert);
                        }
                        else{
                            lstContentVersionToInsert.add(version);
                            mapContentVersionsByDocumentIds.put(version.ContentDocumentId, lstContentVersionToInsert);
                        }
                    }
                }
    
                mapResults.put('mapContentVersionsByDocumentIds', mapContentVersionsByDocumentIds);
                mapResults.put('Success', 'Success');
            }
            catch (Exception ex) {
                mapResults.put('Error', ex.getMessage());
            }
            return mapResults;
        }
    
        /**
        * @description Method to retrieve initial Documents
        * @param Id programId
        * @return Map<Id, List<String>>
        */
        @AuraEnabled(Cacheable = true)
        public static Map<Id, List<String>> getInitialDocuments(Id programId) {
            Set<Id> setContentDocumentId = new Set<Id>();
            Map<Id, List<String>> mapDocumentVersion = new Map<Id, List<String>>();
    
            for(ContentDocumentLink contentDocLink : [SELECT Id, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :programId]){
                setContentDocumentId.add(contentDocLink.ContentDocumentId);
            }
            
            //Remove VersionData, PathOnClient in Query
    
            for(ContentVersion contentVersion : [SELECT Id, DocumentType__c, GroupType__c, Phase__c, Title, ContentDocumentId, VersionNumber
                                                  FROM ContentVersion
                                                  WHERE ContentDocumentId IN :setContentDocumentId AND IsExternal__c = FALSE
                                                  AND SpecialAcceptance__c = NULL]){
                if(mapDocumentVersion.containsKey(contentVersion.ContentDocumentId)){
                      mapDocumentVersion.get(contentVersion.ContentDocumentId).add(contentVersion.VersionNumber);
                }
                else{
                    mapDocumentVersion.put(contentVersion.ContentDocumentId, new List<String>{contentVersion.VersionNumber});
                }
    
            }
    
            return mapDocumentVersion;
        }
    
        /**
        * @description Method to replace Document
        * @param Map<Id, List<String>> mapOldDocumentVersion, Id programId
        * @return Map<String, Object>
        */
        @AuraEnabled
        public static Map<String, Object> replaceDocuments(Map<Id, List<String>> mapOldDocumentVersion, Id programId) {
            Set<Id> setContentDocumentId = new Set<Id>();
            Map<Id, List<String>> mapNewDocumentVersion = LWC14_Documents.getInitialDocuments(programId);
            Map<String, Object> mapResults = new Map<String, Object>();
    
            for(Id key : mapOldDocumentVersion.keySet()){
                if(mapNewDocumentVersion.containsKey(key)){
                    if(mapOldDocumentVersion.get(key).equals(mapNewDocumentVersion.get(key)) == false){
                        //new version was created, hence old version list and new version list are not same
                        setContentDocumentId.add(key);
                    }
                }
            }
    
            if(setContentDocumentId.size() > 0) {
                List<String> lstContentVersionFields = AP_Constant.getCreatableFieldsByObjName('ContentVersion');
                String strCVFields = String.join(lstContentVersionFields, ', ');
                List<ContentVersion> lstPrimaryVersionCV = new List<ContentVersion>();
                List<ContentVersion> lstOtherVersionsCV = new List<ContentVersion>();
                Set<Id> setNewCVIds = new Set<Id>();
                List<Id> lstOldIds = new List<Id>();
    
                String queryCV = 'select Id, VersionNumber, ContentDocumentId, PathOnClient, FirstPublishLocationId, '
                        + strCVFields
                        + ' from ContentVersion where (ContentDocumentId IN :setContentDocumentId) order by VersionNumber ASC ' ;
    
                List<ContentVersion> lstCV = Database.query(queryCV);
    
                for(ContentVersion contentVersion : lstCV) {
                    if(mapOldDocumentVersion.get(contentVersion.ContentDocumentId).contains(contentVersion.VersionNumber)){
                        ContentVersion newcont = new ContentVersion();
                        newcont.Title  = contentVersion.Title;
                        newcont.PathOnClient  = contentVersion.PathOnClient;
                        newcont.VersionData = contentVersion.VersionData;
                        newcont.FirstPublishLocationId = contentVersion.FirstPublishLocationId;
                        newcont.TECH_OldDocumentId__c  = contentVersion.ContentDocumentId;
                        newcont.TECH_OldVersionNumber__c = contentVersion.VersionNumber;
                        newcont.OwnerId = contentVersion.OwnerId;
                        newcont.Phase__c = contentVersion.Phase__c;
                        newcont.DocumentType__c = contentVersion.DocumentType__c;
                        newcont.GroupType__c = contentVersion.GroupType__c;
    
                        if(newcont.FirstPublishLocationId != null){
                            lstPrimaryVersionCV.add(newcont);
                        }
                        else{
                            lstOtherVersionsCV.add(newcont);
                        }
                    }
                }
    
                if(lstPrimaryVersionCV.size() > 0){
                    insert lstPrimaryVersionCV;
                }
    
                for(ContentVersion cv : lstPrimaryVersionCV){
                    setNewCVIds.add(cv.Id);
                }
    
                for(ContentVersion newCV : [SELECT TECH_OldDocumentId__c, TECH_OldVersionNumber__c, ContentDocumentId from ContentVersion WHERE Id IN :setNewCVIds AND SpecialAcceptance__c = NULL]){
                    lstOldIds.add(newCV.TECH_OldDocumentId__c);
                    for(ContentVersion otherVersionCV : lstOtherVersionsCV){
                        if(otherVersionCV.TECH_OldDocumentId__c == newCV.TECH_OldDocumentId__c){
                            otherVersionCV.ContentDocumentId = newCV.ContentDocumentId;
                        }
                    }
                }
    
                if(lstOtherVersionsCV.size() > 0){
                    insert lstOtherVersionsCV;
                }
    
                if(lstOldIds.size() > 0){
                    Database.DeleteResult[] deleteResults = Database.delete(lstOldIds, true);
                }
            }
    
            mapResults.put('Success', 'Success');
            return mapResults;
        }
    
        public class contentVersionWrapper {
            public String Id {get; set;}
            @AuraEnabled public String phase {get; set;}
            @AuraEnabled public String title {get; set;}
            @AuraEnabled public Boolean isExt {get; set;}
            @AuraEnabled public String contentDocId {get; set;}
            @AuraEnabled public Blob versData {get; set;}
            @AuraEnabled public String broker {get; set;}
            @AuraEnabled public String reinsurer {get; set;}
            @AuraEnabled public String dateConv {get; set;}
            @AuraEnabled public Decimal phaseNumber {get; set;}
        }

        /***
        * @description Private method to execute query/dml with admin rights - W-0944
        * @param       none special
        * @return      void           
        * @exception   none special.
        * @author      AMI
        * @date        05/07/2022         
        ***/
        @TestVisible
        private without sharing class performAdminRequest {
            /***
            * @description Private method to update content version properties regardless of who uploaded it
            * @param       list <ContentVersion> cvToUdate - new content version instances to update properties of
            * @return      map <string,object>           
            * @exception   none special.
            * @author      AMI
            * @date        05/07/2022         
            ***/
            public map <string,object> updateContentVersionProperties (list <ContentVersion> cvToUdate) {
                system.debug(LoggingLevel.DEBUG, 'START LWC14_Documents - performAdminRequest - updateContentVersionProperties');

                //method return object
                map <string,object> results = new map <string,object>();

                try{
                    update cvToUdate;
                    results.put('status','OK');
                }catch(DmlException d){
                    results.put('status','KO');
                    results.put('message',d.getMessage());
                }

                system.debug(LoggingLevel.DEBUG, 'END LWC14_Documents - performAdminRequest - updateContentVersionProperties');
                return results;
            }
        }   

        /**
     * Returns the Value__c field of the specified field developer name from the given Custom Metadata type.
     * @param metadataType The Custom Metadata type to query.
     * @param fieldDeveloperName The developer name of the field to retrieve.
     * @return The Value__c field of the specified field, or null if not found.
     */
    @AuraEnabled(cacheable=true)
    public static String getMetadataFieldValue(String metadataType, String fieldDeveloperName) {
        System.debug('getMetadataFieldValue: Start');
        String query = 'SELECT Value__c FROM ' + metadataType + ' WHERE DeveloperName = \'' + fieldDeveloperName + '\' LIMIT 1';
        System.debug('getMetadataFieldValue: query ' + query);
        CLMSettings__mdt result = (CLMSettings__mdt)Database.query(query);
        
        if (result != null) {
            System.debug('getMetadataFieldValue: result ' + result);
            return result.Value__c;
        } else {
            System.debug('getMetadataFieldValue: null');
            return null;
        }
    }

    @AuraEnabled
    public static Map<String,Object> checkAgreementGenerationStatus(Id programId) {
        try{
            List<Apttus__APTS_Agreement__c> agreement  = [
                SELECT Id 
                FROM Apttus__APTS_Agreement__c 
                WHERE Program__c =: programId 
                AND Reinsurer__c = NULL
                AND (Recordtype.developername = 'Acceptation'
                OR Recordtype.developername = 'GroupCover'
                OR RecordType.developername = 'GlobalBroker')
                ORDER BY CREATEDDATE DESC
                LIMIT 1
            ];
            System.debug(LoggingLevel.DEBUG, 'checkAgreementGenerationStatus agreement : ' + agreement);


            if(!agreement.isEmpty()){
                return new Map<String,Object>{'agreementGenerated' => true};
            }else{
                // check if agreement is eligible for renewal
                List<Program__c> currentProgram = [SELECT ID, RenewedFromProgram__c FROM Program__c WHERE Id = :programId AND RenewedFromProgram__c != null]; 
                
                if(!currentProgram.isEmpty()){
                    List<Apttus__APTS_Agreement__c> agreementInitial  = [
                        SELECT Id 
                        FROM Apttus__APTS_Agreement__c 
                        WHERE Program__c =: currentProgram[0].RenewedFromProgram__c
                        AND isAmended__c = false
                        AND Reinsurer__c = NULL
                        AND (Recordtype.developername = 'Acceptation'
                        OR Recordtype.developername = 'GroupCover'
                        OR RecordType.developername = 'GlobalBroker')
                        ORDER BY CREATEDDATE DESC
                        LIMIT 1
                    ];

                    if(!agreementInitial.isEmpty()){
                        return new Map<String,Object>{'canRenew' => true};
                    }else{
                        return new Map<String,Object>{'generateNew' => true};
                    }
                }else{
                    return new Map<String,Object>{'generateNew' => true};
                }
            }
        }catch(Exception e){
            System.debug(LoggingLevel.DEBUG, 'checkAgreementGenerationStatus exception e : ' + e.getMessage());
            return new Map<String,Object>{'isSuccess' => false, 'value'=>  e.getMessage()};       
        }
    }


    /**
    * @description Method to get CONGA Documents for a Program
    * @param Id programId
    * @return List<ContentVersion>
    * @author AzharNahoor
    */
    @AuraEnabled
    public static Map<String,Object> renewAgreement(Id programId) {
        System.debug(LoggingLevel.DEBUG, 'renewAgreement START with : ' + programId);
        try{

            List<Program__c> currentProgram = [SELECT ID, RenewedFromProgram__c FROM Program__c WHERE Id = :programId AND RenewedFromProgram__c != null]; 
            
            if(!currentProgram.isEmpty()){
                List<Apttus__APTS_Agreement__c> agreement  = [
                    SELECT Id 
                    FROM Apttus__APTS_Agreement__c 
                    WHERE Program__c =: currentProgram[0].RenewedFromProgram__c
                    AND isAmended__c = false
                    AND Reinsurer__c = NULL
                    AND (Recordtype.developername = 'Acceptation'
                    OR Recordtype.developername = 'GroupCover'
                    OR RecordType.developername = 'GlobalBroker')
                    ORDER BY CREATEDDATE DESC
                    LIMIT 1
                ];
                System.debug(LoggingLevel.DEBUG, 'renewAgreement agreement : ' + agreement);


                if(!agreement.isEmpty()){


                    String instanceUrl = URL.getSalesforceBaseUrl().toExternalForm(); 
                    String fullUrl = instanceUrl +'/one/one.app#'; 

                    String ToEncodedPartStr = '{"componentDef":"one:alohaPage","attributes":{"address":"'+instanceUrl+'/apex/apttus__lightningagreementrenew?id='+agreement[0].Id+'"},"state":{}}';
                    String encodedString = EncodingUtil.urlEncode(EncodingUtil.base64Encode(Blob.valueOf(ToEncodedPartStr)), 'UTF-8'); 

                    fullUrl = fullUrl + encodedString; 

                    System.debug(fullUrl);
                    return new Map<String,Object>{'isSuccess' => true, 'value'=> fullUrl};
                }else{
                    return new Map<String,Object>{'isSuccess' => true, 'value'=> 'NoAgreement'};
                            
                }
            }

            return new Map<String,Object>{'isSuccess' => true, 'value'=> 'NoAgreement'};
        }catch(Exception e){
            System.debug(LoggingLevel.DEBUG, 'renewAgreement exception e : ' + e.getMessage());
            return new Map<String,Object>{'isSuccess' => false, 'value'=>  e.getMessage()};       
        }

    }
    
    /*@AuraEnabled(cacheable=true) 
        public static filesExtensions__c getCustomSettingsExtension(){
            return filesExtensions__c.getOrgDefaults();
        }*/

          //RRA - ticket 1780 - 19122023
          @AuraEnabled
          public static String getProfiles(){
              Boolean isVisible = false;
              String profileName = null;
              Id userId = UserInfo.getProfileId();
              Profile profile = [SELECT Name  FROM Profile  WHERE Id =: userId];
              //isVisible = (profile.Name == Label.Super_user || profile.Name == AP_Constant.profileSysAdmin || profile.Name == AP_Constant.profileSysAdminAGRe || profile.Name == AP_Constant.profileDelagatedAdmin ) ? true : false;
              if (profile.Name == Label.Super_user || profile.Name == AP_Constant.profileSysAdmin || profile.Name == AP_Constant.profileDelagatedAdmin){
                 profileName = 'Admin';
              }else if (profile.Name == AP_Constant.profileSysAdminAGRe){
                 profileName = 'Admin_AGRE';
              }else if (profile.Name == 'AGRE_Actor C.E'){
                 profileName = 'Actor_CE';
              }else if (profile.Name == 'AGRE_C.E_AXA XL'){
                 profileName = 'Agre_AXAXL';
              }else if (profile.Name == 'AGRE_Actor Basic Salesforce Access'){
                 profileName = 'AgreActor_BasicSalesforce';
              }else if (profile.Name == 'AGRE_Actor Basic SF Platform Access'){
                 profileName = 'AgreActor_BasicSFPlatform';
              }else if (profile.Name == 'AGRE_Community External User'){
                 profileName = 'Agre_CommunityExternal';
              }else if (profile.Name == 'AGRE_Community Internal User'){
                 profileName = 'Agre_CommunityInternal';
              }else if (profile.Name == 'Salesforce Platform_read only'){
                 profileName = 'SF_PlatformReadOnly';
              }
              return profileName;
          }

}