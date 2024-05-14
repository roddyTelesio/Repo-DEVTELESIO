/**
 * @description       : 
 * @author            : Patrick Randrianarisoa
 * @group             : 
 * @last modified on  : 25-04-2024
 * @last modified by  : Patrick Randrianarisoa
 * Modifications Log
 * Ver   Date         Author                   Modification
 * 1.0   31-10-2023   Patrick Randrianarisoa   Initial Version
**/
public without sharing class LWC28_PortalDocuments {
    /**************************************************************************************
    -- - Author        : Spoon Consulting
    -- - Description   : Controller for Lightning Web Component LWC28_PortalDocuments
    --
    -- Maintenance History:
    --
    -- Date         Name  Version  Remarks
    -- -----------  ----  -------  -------------------------------------------------------
    -- 12-APR-2019  NBI   1.0      Initial version
    -- 09-APR-2021  MBE   1.1      W-0923 - Portal - Tri et date des documents
    -- 13-JUL-2021  NBI   1.2      W-1008 : Documents - Incrémentation des versions de documents Thémis par phase
    -- 06-OCT-2021  MBE   1.3      W-1033 - impossibilité de visualisation des documents en cotation par un broker	
    -- 19-OCT-2021  MBE   1.4      W-1034 - tailles limite de documents envoyés
    -- 15-NOV-2021  SRA   1.5      W-1046 : Nom du réassureur qui n'apparait pas sur les documen
    --------------------------------------------------------------------------------------
    **************************************************************************************/
    
        private static final String  BASE_URL = Url.getSalesforceBaseUrl().toExternalForm();
    
        @AuraEnabled
        public static Map<String, Object> saveDocuments(List<ContentVersion> lstContentVersion, Id programId) { //, Id programId, Id idBroker, Id IdReinsurer
            Map<String, Object> mapResults = new Map<String, Object>();
            List<Id>  lstContentDocId = new List<Id>();
            Id userId;
            List<ContentDocumentLink>  lstCDL = new List<ContentDocumentLink>();
            List<DocumentVisibility__c> lstDocVisibiltyUpdate =  new List<DocumentVisibility__c> ();
            try { 
                
                if (lstContentVersion.size() > 0 ) {
                    update lstContentVersion;
                }
    
                for (ContentVersion cvDoc : lstContentVersion){
                    lstContentDocId.add(cvDoc.ContentDocumentId);
                    userId = cvDoc.OwnerId;
                }
    
                DateTime getDateCV = getDateContentVersionId(lstContentDocId);
    
              //  for (DateTime dateCV : lstGetDateCV){
                    for (ContentVersion cvDoc : lstContentVersion){
                        String cvDate = getDateCV.format('d/M/YYYY HH:mm:ss');
                        lstDocVisibiltyUpdate.add(new DocumentVisibility__c(Tech_Title__c=cvDoc.Title,Tech_BrokerId__c=(cvDoc.Tech_BrokerId__c!=null) ? cvDoc.Tech_BrokerId__c:null, Tech_ReinsurerId__c=(cvDoc.Tech_ReinsurerId__c!=null) ? cvDoc.Tech_ReinsurerId__c : null,Tech_BrokerName__c=(cvDoc.Tech_BrokerName__c !=null) ? cvDoc.Tech_BrokerName__c :null , Tech_ReinsurerName__c=(cvDoc.Tech_ReinsurerName__c != null) ? cvDoc.Tech_ReinsurerName__c: null, Program__c=programId, Tech_Phase__c=cvDoc.Phase__c, ContentVersionId__c=cvDoc.Id, Tech_IsExternal__c=true, Tech_Date__c=cvDate, Tech_ContentDocumentId__c=cvDoc.ContentDocumentId, Tech_Request_Status__c = ''));  // Add new field to manage ticket 1054
                        }
               // }
                if (lstDocVisibiltyUpdate.size() > 0 ) {
                    insert lstDocVisibiltyUpdate;
                }
                System.debug('lstDocVisibiltyUpdate==' + lstDocVisibiltyUpdate);
                System.debug(' lstContentVersion' + lstContentVersion);
    
                mapResults.put('lstDocVisibility', lstDocVisibiltyUpdate);
                mapResults.put('Success', 'Success');
                mapResults.put('lstContentVersion', lstContentVersion);
                
            }
            catch (Exception ex) {
                mapResults.put('Error', ex.getMessage());
            }
    
            return mapResults;
        }
    
    
        
        @AuraEnabled
        public static Map<String, Object> retrieveNameBrokerReinsurer(Id idRequest) { //, Id programId, Id idBroker, Id IdReinsurer
            Map<String, Object> mapResults = new Map<String, Object>();
            Request__c  request = new Request__c();
            try { 
                request = [SELECT Id, Broker__c, Broker__r.Name, Reinsurer__c, Reinsurer__r.Name FROM Request__c WHERE Id =:idRequest];
                System.debug(' request' + request);
                mapResults.put('Success', 'Success');
                mapResults.put('request', request);
                mapResults.put('nameBro', request.Broker__r.Name);
                mapResults.put('nameReins', request.Reinsurer__r.Name);
                mapResults.put('nameBroId', request.Broker__c);
                mapResults.put('nameReinsId', request.Reinsurer__c);
            }
            catch (Exception ex) {
                mapResults.put('Error', ex.getMessage());
            }
            return mapResults;
        }
    
        //SRA - 1046
        /*@AuraEnabled
        public static Map<String, Object> updateIdNameBrokerReinsurer(List<Id> lstContenVersonId, Id programId, Id idBroker, Id IdReinsurer) {
            Map<String, Object> mapResults = new Map<String, Object>();
            List<ContentVersion> lstConvUpdate =  new List<ContentVersion> ();
            //List<DocumentVisibility__c> lstDocVisibiltyUpdate =  new List<DocumentVisibility__c> ();
            //Set<Id> setContentDocumentId = new Set<Id>();
            /*for(ContentDocumentLink contentDocLink : [SELECT Id, ContentDocumentId
                                                      FROM ContentDocumentLink
                                                      WHERE LinkedEntityId = :programId AND Visibility = 'AllUsers']){
                setContentDocumentId.add(contentDocLink.ContentDocumentId);
            }*/
    
            /*List<ContentVersion> lstContentVersion = [SELECT Id, DocumentType__c, GroupType__c, Phase__c, Title, FileExtension
                                                             , PathOnClient, VersionData, ContentDocumentId, VersionNumber, IsExternal__c, CreatedDate, Tech_BrokerId__c, CreatedById, Tech_BrokerName__c, Tech_ReinsurerId__c, Tech_ReinsurerName__c, isMajorVersion
                                                      FROM ContentVersion
                                                      WHERE Id IN :lstContenVersonId AND SpecialAcceptance__c = NULL AND isMajorVersion = true];
    
                                              
            List<nameAccWrapper> lstNameBrokerReinsurer = getNameBrokerReinsurer(programId, idBroker, IdReinsurer);
            System.debug('lstnameAccWrapperAAAA ==='+  lstNameBrokerReinsurer);
            System.debug('lstnameAccWrapper[0].broker ==='+  lstNameBrokerReinsurer[0].broker);
            System.debug('lstnameAccWrapper[0].reinsurer ==='+  lstNameBrokerReinsurer[0].reinsurer);
    
            if (lstContentVersion.size() > 0){
                for (ContentVersion conv: lstContentVersion){
                        if(conv.VersionData != null && conv.IsExternal__c == true /*&& conv.CreatedById == UserInfo.getUserId()){
                            /*lstConvUpdate.add(new ContentVersion(Id=conv.Id, Title=conv.Title,Tech_BrokerId__c=idBroker, Tech_ReinsurerId__c=IdReinsurer,Tech_BrokerName__c=lstNameBrokerReinsurer[0].broker, Tech_ReinsurerName__c=lstNameBrokerReinsurer[0].reinsurer, Phase__c=conv.Phase__c, CreatedDate=conv.CreatedDate, ContentDocumentId=conv.ContentDocumentId));
                    }
                }
                try{
                    update lstConvUpdate;
                    mapResults.put('lstConv', lstConvUpdate);
                    System.debug('lstConvUpdate==' + lstConvUpdate);       
                }catch(Exception ex) {
                    mapResults.put('Error', ex.getMessage());
                }
       
                /*for (ContentVersion cvDoc : lstConvUpdate){
                         DateTime dateCV = cvDoc.CreatedDate; //Tech_Date__c=dateCV format('d/M/YYYY HH:mm:ss')
                         String cvDate = dateCV.format('d/M/YYYY HH:mm:ss');
                         lstDocVisibiltyUpdate.add(new DocumentVisibility__c(Tech_Title__c=cvDoc.Title,Tech_BrokerId__c=idBroker, Tech_ReinsurerId__c=IdReinsurer,Tech_BrokerName__c=lstNameBrokerReinsurer[0].broker, Tech_ReinsurerName__c=lstNameBrokerReinsurer[0].reinsurer, Program__c=programId, Tech_Phase__c=cvDoc.Phase__c, ContentVersionId__c=cvDoc.Id, Tech_IsExternal__c=true, Tech_Date__c=cvDate, Tech_ContentDocumentId__c=cvDoc.ContentDocumentId)); 
                 }
                try{
                    upsert lstDocVisibiltyUpdate;
                    mapResults.put('lstDocVisibility', lstDocVisibiltyUpdate);
    
                    System.debug('lstDocVisibiltyUpdate==' + lstDocVisibiltyUpdate);
                }catch(Exception ex) {
                    mapResults.put('Error', ex.getMessage());
                }*/
            /*}
        return mapResults;
        }
    
        //SRA - 1046
        @AuraEnabled
        public static List<nameAccWrapper> getNameBrokerReinsurer(Id programId, Id idBroker, Id IdReinsurer) {
            List<nameAccWrapper> lstNameAcc = new List<nameAccWrapper>();
            nameAccWrapper nameAcc = new nameAccWrapper();
            Set<Id> setRelatedBroker = new Set<Id>();
            String queryReq;
    
            if (String.isNotBlank(idBroker) && String.isNotBlank(IdReinsurer)){
                    queryReq = 'SELECT Id, Broker__c, Reinsurer__c, Broker__r.Name, Reinsurer__r.Name  FROM Request__c WHERE Program__c =: programId AND Reinsurer__c =: IdReinsurer AND Broker__c !=null';  
            }else if (String.isNotBlank(idBroker)  && (String.isBlank(IdReinsurer) || IdReinsurer == null)){
                queryReq = 'SELECT Id, Broker__c, Reinsurer__c, Broker__r.Name, Reinsurer__r.Name  FROM Request__c WHERE Program__c =: programId AND Reinsurer__c =: IdReinsurer';
            }else if ((String.isBlank(idBroker) || idBroker == null)  && String.isNotBlank(IdReinsurer)){
                queryReq = 'SELECT Id, Broker__c, Reinsurer__c, Broker__r.Name, Reinsurer__r.Name  FROM Request__c WHERE Program__c =: programId AND Reinsurer__c =: IdReinsurer AND Broker__c=null';
            }else if ((String.isBlank(idBroker) || idBroker == null)  &&(String.isBlank(IdReinsurer) || IdReinsurer == null)){
                queryReq = 'SELECT Id, Broker__c, Reinsurer__c, Broker__r.Name, Reinsurer__r.Name  FROM Request__c WHERE Program__c =: programId AND Reinsurer__c=null AND Broker__c=null';
            }
            System.debug('queryReq' +  queryReq);
            List<Request__c> lstRequest = Database.query(queryReq);
            System.debug('lstRequest' +  lstRequest.size());
                for (Request__c rr : lstRequest){
                    nameAcc.broker = rr.Broker__r.Name;
                    nameAcc.reinsurer = rr.Reinsurer__r.Name;
                    nameAcc.brokerId = rr.Broker__c;
                    lstNameAcc.add(nameAcc);
                }
            System.debug('lstNameAcc' +  lstNameAcc);
        return lstNameAcc;
        }*/
    
        //SRA - 1046
        @AuraEnabled
        public static Map<String, Object> getDocuments(Id programId, Id reinsurerId, Id idBroker, Id IdReinsurer) { 
            Map<String, ContentVersion> mapContentVersionByPhaseCLM = new Map<String, ContentVersion>();
            Map<Id, ContentVersion> mapContentVersionByDocumentId = new Map<Id, ContentVersion>();
            Map<Id, ContentVersion> mapContentVersionByDocumentIdOld = new Map<Id, ContentVersion>();
            Map<Id, DocumentVisibility__c> mapDocumentVisibilityByDocumentId = new Map<Id, DocumentVisibility__c>();
            Map<Id, DocumentVisibility__c> mapDocumentVisibilityByDocumentIdOld = new Map<Id, DocumentVisibility__c>();
            Map<String, Object> mapResults = new Map<String, Object>();
            Map<Id, String> mapDocumentDateByContentVersionId = new Map<Id, String>();
            Map<Id, String> mapCreatedDateContentVersionId = new Map<Id, String>();
           // Map<Id, String> mapCreatedDateContentVersionOldId = new Map<Id, String>();
            Map<Id, String> mapCreatedDateDocVisId = new Map<Id, String>();
            List<ContentVersion> lstContentVersion = new List<ContentVersion>();
            List<DocumentVisibility__c> lstDocumentVisibility = new List<DocumentVisibility__c>();
            List<DocumentVisibility__c> lstDocumentVisibilityOld = new List<DocumentVisibility__c>();
            Set<Id> setReinsurerAttached = new Set<Id>();
            Set<Id> setBrokerAttached = new Set<Id>();
            List<Id> lstBrokerAttached = new List<Id>();
            Set<Id> setRelatedBroker = new Set<Id>();
            List<ContentVersion> lstConvOldDoc= new List<ContentVersion>();
            List<ContentVersion> lstConvNewDoc= new List<ContentVersion>();
            Set<Id> setContentDocumentId = new Set<Id>();
            Set<Id> setLinkEntityIdId = new Set<Id>();
            Id brokerId = null;
            Map<String, ContentVersion> mapThemisConVersionByDocumentId = new Map<String, ContentVersion>();          
            User usr = [SELECT Id, ContactId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            Id contactId = usr.ContactId;
            Id userId = usr.Id;
    
    
            // Check if it's a Broker
           /* if(LWC25_PortalFilters.checkBrokerContact() == true){
                if(contactId != null){
                    Contact brokContact = [SELECT Id, AccountId, Account.RecordTypeId FROM Contact WHERE Id = :contactId LIMIT 1];
                    brokerId = brokContact.AccountId;
                }
            }*/
            for(ContentDocumentLink contentDocLink : [SELECT Id, ContentDocumentId, LinkedEntityId
            FROM ContentDocumentLink
                                                      WHERE LinkedEntityId = :programId ]){
                setContentDocumentId.add(contentDocLink.ContentDocumentId);
                setLinkEntityIdId.add(contentDocLink.LinkedEntityId);
            }
            
            System.debug('setContentDocumentId=='+ setContentDocumentId);
            //************************ *********************/
            // Part visibilty to display the files uploading 
            //************************ ********************/
            //String queryConv='';
            //String queryDocVisibility='';
    
            String queryDoc = 'SELECT Id, DocumentType__c, GroupType__c, Phase__c, Title, FileExtension , PathOnClient, ContentDocumentId, VersionNumber, IsExternal__c, CreatedDate, Tech_BrokerId__c, Tech_BrokerName__c, Tech_ReinsurerId__c, Tech_ReinsurerName__c, IsOldDocument__c FROM ContentVersion WHERE ContentDocumentId IN :setContentDocumentId AND SpecialAcceptance__c = NULL';// MRA 951 Remove VersionData Field causing LOB heap size error
            // The document is not from conga (conga document wouldn't be retrieve here CLM_Name__c = NULL)

            String queryNewDoc = 'SELECT Id, DocumentType__c, GroupType__c, Phase__c, Title, FileExtension , PathOnClient, ContentDocumentId, VersionNumber, IsExternal__c, CreatedDate, Tech_BrokerId__c, Tech_ReinsurerId__c, IsOldDocument__c, Tech_BrokerName__c, Tech_ReinsurerName__c FROM ContentVersion WHERE ContentDocumentId IN :setContentDocumentId AND SpecialAcceptance__c = NULL';// MRA 951 Remove VersionData Field causing LOB heap size error
    
            //String queryOldDoc = 'SELECT Id, DocumentType__c, GroupType__c, Phase__c, Title, FileExtension , PathOnClient, VersionData, ContentDocumentId, VersionNumber, IsExternal__c, CreatedDate, Tech_BrokerId__c, Tech_ReinsurerId__c, IsOldDocument__c, Tech_BrokerName__c, Tech_ReinsurerName__c FROM ContentVersion WHERE ContentDocumentId IN :setContentDocumentId AND Tech_BrokerId__c = null AND Tech_ReinsurerId__c = null AND IsExternal__c= true';
    
            lstContentVersion = Database.query(queryDoc);
    
            System.debug('lstContentVersion=='+ lstContentVersion);
     
            String queryDocVisibility = 'SELECT Id, ContentVersionId__c, Tech_BrokerId__c, Tech_BrokerName__c, Tech_Date__c, Tech_Phase__c, Tech_ReinsurerId__c, Tech_ReinsurerName__c, Tech_Title__c, Program__c, Tech_IsExternal__c, Tech_ContentDocumentId__c FROM DocumentVisibility__c WHERE Program__c=:programId AND Tech_IsExternal__c = true';

            String queryDocVisibilityOld = 'SELECT Id, ContentVersionId__c, Tech_isFileMigrated__c, Tech_FileOwnerId__c, Tech_BrokerId__c, Tech_BrokerName__c, Tech_Date__c, Tech_Phase__c, Tech_ReinsurerId__c, Tech_ReinsurerName__c, Tech_Title__c, Program__c, Tech_IsExternal__c, Tech_ContentDocumentId__c FROM DocumentVisibility__c WHERE Program__c=:programId AND Tech_IsExternal__c = true AND Tech_isFileMigrated__c = true AND Tech_FileOwnerId__c =: userId' ;
    
        if(LWC25_PortalFilters.checkBrokerContact() == true){
                if(contactId != null){
                    Contact brokContact = [SELECT Id, AccountId, Account.RecordTypeId FROM Contact WHERE Id = :contactId LIMIT 1];
                    brokerId = brokContact.AccountId;
                    if(brokContact != null && brokContact.AccountId != null){
                        for(AccountContactRelation relatedContactRelationBroker : [SELECT Id, AccountId, Account.RecordTypeId
                                                                                        , Contact.Account.RecordTypeId, Roles
                                                                                        , ContactId, Contact.MacroLoB__c
                                                                                        , Contact.Nature__c, IsDirect
                                                                                    FROM AccountContactRelation
                                                                                    WHERE ContactId = :contactId
                                                                                    AND IsActive = TRUE
                                                                                    AND Contact.MacroLoB__c != NULL
                                                                                    AND Contact.Nature__c != NULL]){
                            if(relatedContactRelationBroker.Roles == 'Broker' || relatedContactRelationBroker.IsDirect == true){
                                setRelatedBroker.add(relatedContactRelationBroker.AccountId);
                            }
                        }
                    }
    
                    //queryConv = queryConv + ' AND Tech_BrokerId__c IN: setRelatedBroker';
                }
    
                //for (ContentVersion cvDoc: lstContentVersion){
                    // Retrieve the doc file created recently or in progress with broker and reinsurer updated - 1046
                    //if (!cvDoc.IsOldDocument__c){
                        System.debug('### idBroker=' + idBroker) ;
                        System.debug('### IdReinsurer=' + IdReinsurer) ;

                        // I have connected as Broker and Reinsurer exists => files are visible only for each Reinsurer concerned (Reisurer A don't see the file uploaded by Reinsurer B for one Broker and one program)
                        if (String.isNotBlank(idBroker) && String.isNotBlank(IdReinsurer)){
                            //queryDoc = queryDoc + ' AND Tech_BrokerId__c IN: setRelatedBroker AND Tech_ReinsurerId__c =: IdReinsurer';
                            //queryOldDoc = queryOldDoc;
                            queryDocVisibilityOld = queryDocVisibilityOld;
                            queryDocVisibility = queryDocVisibility + ' AND Tech_BrokerId__c IN: setRelatedBroker AND Tech_ReinsurerId__c =: IdReinsurer';
                                            
                        //  I have connected as Broker and Reinsurer don't exists => Files are visible for only broker (Broker A don't see the files on broker B because their Id are unique)
                        }else if (String.isNotBlank(idBroker)  && (String.isBlank(IdReinsurer) || IdReinsurer == null)){
                            //queryDoc = queryDoc + ' AND Tech_BrokerId__c =: idBroker';
                            //queryOldDoc = queryOldDoc;
                            queryDocVisibilityOld = queryDocVisibilityOld;
                            queryDocVisibility =  queryDocVisibility + ' AND Tech_BrokerId__c =: idBroker';
    
    
                        // I have connected as Reinsurer only => files visible for all Reinsurer attached and broker is null for one program
                        }else if ((String.isBlank(idBroker) || idBroker == null)  && String.isNotBlank(IdReinsurer)){
                            queryNewDoc = queryNewDoc + ' AND Tech_BrokerId__c = null AND Tech_ReinsurerId__c =: IdReinsurer';
                            //queryOldDoc = queryOldDoc;
                            queryDocVisibilityOld = queryDocVisibilityOld;
                            queryDocVisibility =  queryDocVisibility + ' AND Tech_BrokerId__c = null AND Tech_ReinsurerId__c =: IdReinsurer';
    
    
                        }else if ((String.isBlank(idBroker) || idBroker == null)  &&(String.isBlank(IdReinsurer) || IdReinsurer == null)){
                            //queryDoc = queryDoc;
                            //queryOldDoc = queryOldDoc;
                            queryDocVisibilityOld = queryDocVisibilityOld;
                            queryDocVisibility = null;
    
                        }
                    //}
                //}
        // RRA - 1045  Manage visibility of Reinsurer     
        }else if (LWC25_PortalFilters.checkBrokerContact() == false){
            /*for (Request__c req : [SELECT Id, Broker__c, Reinsurer__c FROM Request__c WHERE Program__c =:programId]){
               if (req.Broker__c != null && req.Reinsurer__c !=null){
                    setBrokerAttached.add(req.Broker__c);
                }else if (req.Reinsurer__c !=null){
                    setReinsurerAttached.add(req.Reinsurer__c);
                }
            }*/
    
            //for (ContentVersion cvDoc: lstContentVersion){
                // Retrieve the doc file created recently or in progress with broker and reinsurer updated - 1046
               // if (!cvDoc.IsOldDocument__c){
                    if (String.isNotBlank(IdReinsurer)){
                        //queryDoc = queryDoc +  ' AND (Tech_ReinsurerId__c =: IdReinsurer OR Tech_ReinsurerId__c IN:setReinsurerAttached)';
                        //queryOldDoc = queryOldDoc;
                        queryDocVisibilityOld = queryDocVisibilityOld;
                        queryDocVisibility =  queryDocVisibility + ' AND Tech_BrokerId__c = null AND Tech_ReinsurerId__c =: IdReinsurer';
    
            
                    }else if (String.isNotBlank(idBroker)){
                        //queryDoc = queryDoc +  ' AND (Tech_BrokerId__c =: idBroker OR Tech_BrokerId__c IN:setBrokerAttached)';
                        //queryOldDoc = queryOldDoc;
                        queryDocVisibilityOld = queryDocVisibilityOld;
                        queryDocVisibility =  queryDocVisibility + ' AND Tech_BrokerId__c =: idBroker';
                    }
                //}
            //}
        }
    
        // Retrieve the doc file existing already in databese without broker and reinsurer updated - 1046
        //if (String.isNotBlank(queryDoc) || queryDoc != null){
            //lstConvNewDoc = Database.query(queryDoc); // To Comment because ContentVersion and DocumentVisibility Objects realize the same operation to store the information of documents 
        //}
    
        /*if (String.isNotBlank(queryOldDoc) || queryOldDoc != null){
            lstConvOldDoc = Database.query(queryOldDoc);
        }*/
        
        if (String.isNotBlank(queryDocVisibility) || queryDocVisibility != null){
            lstDocumentVisibility = Database.query(queryDocVisibility);
        }

          
        if (String.isNotBlank(queryDocVisibilityOld) || queryDocVisibilityOld != null){
            lstDocumentVisibilityOld = Database.query(queryDocVisibilityOld);
        }
    
    
    
    
            ///System.debug('lstConvNewDoc=='+ lstConvNewDoc);
            //System.debug('lstConvOldDoc=='+ lstConvOldDoc);
            System.debug('lstDocumentVisibility===' + lstDocumentVisibility);
            System.debug('lstDocumentVisibilityOld===' + lstDocumentVisibilityOld);
    
            /*for (ContentVersion cv  : lstConvOldDoc){
                if(!mapCreatedDateContentVersionOldId.containsKey(cv.Id)){                                                        
                    mapCreatedDateContentVersionOldId.put(cv.Id, cv.CreatedDate.format('d/M/YYYY HH:mm:ss'));
                }
            }*/
    
            Set<Id> setContentVersionIdInternal = new Set<Id>();
            Set<Id> setContentVersionIdFilter = new Set<Id>();
            //Set<Id> setContentVersionIdFilterOld = new Set<Id>();
            Set<Id> setCDocVisIdFilter = new Set<Id>();
            Set<Id> setdocVisIdFilterOld = new Set<Id>();
    
    
            for(ContentVersion contentVersion : lstContentVersion){
                if(contentVersion.IsExternal__c == false){
                    setContentVersionIdInternal.add(contentVersion.Id);
    
                }
            }
    
            System.debug('setContentVersionIdInternal=='+ setContentVersionIdInternal);
    
            /*for(ContentVersion contentVersionOld : lstConvOldDoc){
                    if(contentVersionOld.IsExternal__c == true){ 
                        setContentVersionIdFilterOld.add(contentVersionOld.Id);;
                }
            }*/

            for(DocumentVisibility__c docVisOld : lstDocumentVisibilityOld){
                if(docVisOld.Tech_IsExternal__c == true){ 
                    setdocVisIdFilterOld.add(docVisOld.Id);
            }
        }
    
            for(DocumentVisibility__c docVis : lstDocumentVisibility){
                if(docVis.Tech_IsExternal__c == true){
                    setCDocVisIdFilter.add(docVis.ContentVersionId__c);
                } else if (docVis.Tech_IsExternal__c == false){
                    setCDocVisIdFilter.add(docVis.ContentVersionId__c);
                }
            }
    
            //Broker user - brokerId + reinsurerId
            //Reinsurer user - brokerId = null + reinsurerId
            if(LWC25_PortalFilters.checkBrokerContact() == true){
                for(DocumentVisibility__c docVis : [SELECT Id, ContentVersionId__c, Company__c, Broker__c, Reinsurer__c, DocumentUpdateDate__c
                FROM DocumentVisibility__c
                WHERE Program__c = :programId
                AND ContentVersionId__c IN :setContentVersionIdInternal
                AND Broker__c IN :setRelatedBroker
                AND Tech_IsExternal__c= false
                AND Reinsurer__c = :IdReinsurer ORDER BY DocumentUpdateDate__c DESC]){
                    setContentVersionIdFilter.add(docVis.ContentVersionId__c);
                    if(!mapDocumentDateByContentVersionId.containsKey(docVis.ContentVersionId__c)){                                                        mapDocumentDateByContentVersionId.put(docVis.ContentVersionId__c, docVis.DocumentUpdateDate__c.format('YYYY-MM-dd hh:mm:ss'));
                    mapDocumentDateByContentVersionId.put(docVis.ContentVersionId__c, docVis.DocumentUpdateDate__c.format('M/d/YYYY h:mm:ss'));
                    // mapDocumentDateByContentVersionId.put(docVis.ContentVersionId__c, docVis.DocumentUpdateDate__c.format('YYYY-MM-dd hh:mm:ss'));
                    }
                }   
            }else{
                for(DocumentVisibility__c docVis : [SELECT Id, ContentVersionId__c, Company__c, Broker__c,  Broker__r.Name, Reinsurer__c, Reinsurer__r.Name, DocumentUpdateDate__c
                FROM DocumentVisibility__c
                WHERE Program__c = :programId
                AND ContentVersionId__c IN :setContentVersionIdInternal
                //AND Broker__c = :brokerId
                AND Tech_IsExternal__c= false
                AND Reinsurer__c = :IdReinsurer ORDER BY DocumentUpdateDate__c DESC]){
                    setContentVersionIdFilter.add(docVis.ContentVersionId__c);
    
                    if(!mapDocumentDateByContentVersionId.containsKey(docVis.ContentVersionId__c)){                                         mapDocumentDateByContentVersionId.put(docVis.ContentVersionId__c, docVis.DocumentUpdateDate__c.format('YYYY-MM-dd hh:mm:ss'));
                        mapDocumentDateByContentVersionId.put(docVis.ContentVersionId__c, docVis.DocumentUpdateDate__c.format('M/d/YYYY h:mm:ss'));
                        // mapDocumentDateByContentVersionId.put(docVis.ContentVersionId__c, docVis.DocumentUpdateDate__c.format('YYYY-MM-dd hh:mm:ss'));
                    }
                }
            }
           
            System.debug('mapDocumentDateByContentVersionId=='+ mapDocumentDateByContentVersionId);
            System.debug('setContentVersionIdFilter=='+ setContentVersionIdFilter);
            List<ContentVersion> lstContentVersionAllFilter = [SELECT Id, DocumentType__c, GroupType__c, Phase__c, Title, CLM_Name__c, FileExtension, CreatedById, CreatedDate, Tech_BrokerId__c, Tech_BrokerName__c, Tech_ReinsurerName__c, Tech_ReinsurerId__c , ContentDocumentId, VersionNumber, IsExternal__c, FromThemis__c, Version__c, DocumentID__c FROM ContentVersion WHERE Id IN :setContentVersionIdFilter AND SpecialAcceptance__c = NULL ORDER BY Tech_NumberPhase__c DESC];

            //List<ContentVersion> lstContentVersionAllFilterOld = [SELECT Id, DocumentType__c, GroupType__c, Phase__c, Title, FileExtension, CreatedById, CreatedDate, Tech_BrokerId__c, Tech_BrokerName__c, Tech_ReinsurerName__c, Tech_ReinsurerId__c , ContentDocumentId, VersionNumber, IsExternal__c, FromThemis__c, Version__c, DocumentID__c FROM ContentVersion WHERE Id IN :setContentVersionIdFilterOld AND SpecialAcceptance__c = NULL ORDER BY Tech_NumberPhase__c DESC];

            List<DocumentVisibility__c> lstDocVisAllFilter = [SELECT Id ,ContentVersionId__c, Tech_BrokerId__c, Tech_BrokerName__c, Tech_Date__c, Tech_Phase__c,Tech_ReinsurerId__c, Tech_ReinsurerName__c, Tech_Title__c,Tech_IsExternal__c, Tech_ContentDocumentId__c FROM DocumentVisibility__c WHERE ContentVersionId__c IN :setCDocVisIdFilter ORDER BY Tech_NumberPhase__c DESC];
    
            List<DocumentVisibility__c> lstCDocVisAllFilterOld = [SELECT Id ,ContentVersionId__c, Tech_BrokerId__c, Tech_BrokerName__c, Tech_Date__c, Tech_Phase__c,Tech_ReinsurerId__c, Tech_ReinsurerName__c, Tech_Title__c,Tech_IsExternal__c, Tech_ContentDocumentId__c FROM DocumentVisibility__c WHERE Id IN :setdocVisIdFilterOld ORDER BY Tech_NumberPhase__c DESC];
    
    
            for(DocumentVisibility__c visDoc : lstDocVisAllFilter){
                mapDocumentVisibilityByDocumentId.put(visDoc.ContentVersionId__c, visDoc);
            }
    
            System.debug('lstContentVersionAllFilter=='+ lstContentVersionAllFilter);
    
            for(ContentVersion version : lstContentVersionAllFilter){
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
                }else if(version.CLM_Name__c <> null){
                    ContentVersion contentVersionMap = new ContentVersion();
                    if(mapContentVersionByPhaseCLM.containsKey(version.Phase__c)){
                        contentVersionMap = mapContentVersionByPhaseCLM.get(version.Phase__c);
                        if(version.CreatedDate > contentVersionMap.CreatedDate){
                            mapContentVersionByPhaseCLM.put(version.Phase__c, version);
                        }
                    }else{
                        mapContentVersionByPhaseCLM.put(version.Phase__c, version);
                    }
                }else{
                    ContentVersion contentVersionMap = new ContentVersion();
                    if(mapContentVersionByDocumentId.containsKey(version.ContentDocumentId)){
                        contentVersionMap = mapContentVersionByDocumentId.get(version.ContentDocumentId);
                        if(Integer.valueOf(version.VersionNumber) > Integer.valueOf(contentVersionMap.VersionNumber)){
                            mapContentVersionByDocumentId.put(version.ContentDocumentId, version);
                        }
                    }
                    else{
                        mapContentVersionByDocumentId.put(version.ContentDocumentId, version);
                    }
                }
            }

            for(DocumentVisibility__c visDocOld : lstCDocVisAllFilterOld){
                mapDocumentVisibilityByDocumentIdOld.put(visDocOld.ContentVersionId__c, visDocOld);
            }
            /*for(ContentVersion versionOld : lstContentVersionAllFilterOld){
                    ContentVersion contentVersionMapOld = new ContentVersion();
                    if(mapContentVersionByDocumentIdOld.containsKey(versionOld.ContentDocumentId)){
                        contentVersionMapOld = mapContentVersionByDocumentIdOld.get(versionOld.ContentDocumentId);
                        if(Integer.valueOf(versionOld.VersionNumber) > Integer.valueOf(contentVersionMapOld.VersionNumber)){
                            mapContentVersionByDocumentIdOld.put(versionOld.ContentDocumentId, versionOld);
                        }
                    }
                    else{
                        mapContentVersionByDocumentIdOld.put(versionOld.ContentDocumentId, versionOld);
                }
            }*/
    
    
            
            List<ContentVersion> lstContentVersions = mapContentVersionByDocumentId.values();
            if(mapContentVersionByPhaseCLM.size() > 0 && mapContentVersionByPhaseCLM.values().size()>0){
                lstContentVersions.addAll(mapContentVersionByPhaseCLM.values());
            }
            //List<ContentVersion> lstContentVersionsOld = mapContentVersionByDocumentIdOld.values();
            List<DocumentVisibility__c> lstVisibilityDocument = mapDocumentVisibilityByDocumentId.values();
            List<DocumentVisibility__c> lstVisibilityDocumentOld = mapDocumentVisibilityByDocumentIdOld.values();
    
    
            System.debug('lstContentVersions=='+ lstContentVersions);
    
            //System.debug('lstContentVersionsOld=='+ lstContentVersionsOld);
    
            System.debug('lstVisibilityDocument=='+ lstVisibilityDocument);
            System.debug('lstVisibilityDocumentOld=='+ lstVisibilityDocumentOld);
    
            List<ContentVersion> lstContentVersionExternal = new List<ContentVersion>();
    
            //List<ContentVersion> lstContentVersionExternalOld = new List<ContentVersion>();
    
            List<DocumentVisibility__c> lstDocumentVisibilityExternal = new List<DocumentVisibility__c>();
            List<DocumentVisibility__c> lstDocumentVisibilityExternalOld = new List<DocumentVisibility__c>();
    
            //List<nameAccWrapper> lstnameAccWrapper = getNameBrokerReinsurer(programId, idBroker, IdReinsurer);
    
            //System.debug('lstnameAccWrapperAAAA ==='+  lstnameAccWrapper);
            //System.debug('lstnameAccWrapper[0].broker ==='+  lstnameAccWrapper[0].broker);
            //System.debug('lstnameAccWrapper[0].reinsurer ==='+  lstnameAccWrapper[0].reinsurer);
    
            List<ContentVersion> lstContentVersionInternal = new List<ContentVersion>();
    
            for(String documentId : mapThemisConVersionByDocumentId.keySet()) {
                lstContentVersionInternal.add(mapThemisConVersionByDocumentId.get(documentId));
            }
    
            for(ContentVersion version : lstContentVersions){
                    if(version.IsExternal__c == true && version.CreatedById == UserInfo.getUserId()){
                            lstContentVersionExternal.add(version);
                    }
                            
                    else if(version.IsExternal__c == false){
                        lstContentVersionInternal.add(version);
                    }
            }
    
            System.debug('lstContentVersionInternal222222=='+ lstContentVersionInternal);
    
            /*for(ContentVersion versionOld : lstContentVersionsOld){
                if(versionOld.IsExternal__c == true && versionOld.CreatedById == UserInfo.getUserId()){
                    lstContentVersionExternalOld.add(versionOld);
                }
            }*/
            
    
            for(DocumentVisibility__c visibility : lstVisibilityDocument){
                if(visibility.Tech_IsExternal__c == true){
                    lstDocumentVisibilityExternal.add(visibility);
                }
            }

            for(DocumentVisibility__c visibilityOld : lstVisibilityDocumentOld){
                if(visibilityOld.Tech_IsExternal__c == true){
                    lstDocumentVisibilityExternalOld.add(visibilityOld);
                }
            }
           
            System.debug('lstContentVersionExternal=='+ lstContentVersionExternal);
            //System.debug('lstContentVersionExternalOld=='+ lstContentVersionExternalOld);
            System.debug('lstContentVersionInternal=='+ lstContentVersionInternal);
            System.debug('lstDocumentVisibilityExternal=='+ lstDocumentVisibilityExternal);
            System.debug('lstDocumentVisibilityExternalOld=='+ lstDocumentVisibilityExternalOld);
    
            mapResults.put('lstConvInternal', lstContentVersionInternal);
            //mapResults.put('lstContentVersionExternalOld', lstContentVersionExternalOld);
            mapResults.put('lstContentVersionExternal', lstContentVersionExternal);
            //mapResults.put('lstnameAccWrapper', lstnameAccWrapper);
            //mapResults.put('lstnameAccBroker', lstnameAccWrapper[0].broker);
            //mapResults.put('lstnameAccReinsurer', lstnameAccWrapper[0].reinsurer);
            mapResults.put('lstContentVersions', lstContentVersions);
            mapResults.put('mapDocumentDateByContentVersionId', mapDocumentDateByContentVersionId);
            mapResults.put('mapCreatedDateContentVersionId', mapCreatedDateContentVersionId);
            //mapResults.put('mapCreatedDateContentVersionOldId', mapCreatedDateContentVersionOldId);
            mapResults.put('setRelatedBroker', setRelatedBroker);
            mapResults.put('setReinsurerAttached', setReinsurerAttached);
            mapResults.put('lstVisibilityDocument', lstDocumentVisibilityExternal);
            mapResults.put('lstVisibilityDocumentOld', lstDocumentVisibilityExternalOld);
            mapResults.put('lstDocumentVisibility', lstDocumentVisibility);
            mapResults.put('lstDocumentVisibilityOld', lstDocumentVisibilityOld);
            mapResults.put('OwnerId', usr);
            //mapResults.put('lstCtCV', lstCtCV);
    
            return mapResults;
        }
    
        //SRA 1046 
        @AuraEnabled
        public static List<ContentVersion> getContentVersionId(List<Id> lstContentDocumentId) {
            List<ContentVersion> lstContentVersion = [SELECT Id, Title, ContentDocumentId, CreatedDate, Tech_BrokerId__c, Tech_ReinsurerId__c, DocumentType__c, GroupType__c  FROM ContentVersion WHERE ContentDocumentId IN :lstContentDocumentId AND SpecialAcceptance__c = NULL];
            return lstContentVersion;
        }
    
        //SRA 1045 
        @AuraEnabled
        public static DateTime getDateContentVersionId (List<Id> lstContentDocumentId) {
            List<DateTime> lstDateCV = new List<DateTime>();
            for (ContentVersion cv : [SELECT CreatedDate FROM ContentVersion WHERE ContentDocumentId IN :lstContentDocumentId AND SpecialAcceptance__c = NULL]){
                lstDateCV.add(cv.CreatedDate);
            }
            return lstDateCV[0];
        }
    
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
    
        // SRA - ticket 1045
        @AuraEnabled
        public static Map<String, Object> deleteContentVersionDocument(List<Id> lstDeletedDocument) {
            Map<String, Object> mapResults = new Map<String, Object>();
    
            try{
                if (lstDeletedDocument.size() > 0) {
                    Set<Id> setContentDocumentId = new Set<Id>();
    
                    for (ContentVersion contentVersion : [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN :lstDeletedDocument AND SpecialAcceptance__c = NULL]) {
                        setContentDocumentId.add(contentVersion.ContentDocumentId);
                    }
    
                    List<ContentDocument> lstContentDoc = [SELECT Id FROM ContentDocument WHERE Id IN :setContentDocumentId];
                    delete lstContentDoc;
                }
    
                mapResults.put('Success', 'Success');
            }
            catch (Exception ex) {
                mapResults.put('Error', ex.getMessage());
            }
            return mapResults;
        }
        // Delete Old Documents- 1046
        /*@AuraEnabled
        public static Map<String, Object> deleteContentVersionDocumentOld(List<Id> lstDeletedDocumentOld) {
            Map<String, Object> mapResults = new Map<String, Object>();
    
            try{
                if (lstDeletedDocumentOld.size() > 0) {
                    Set<Id> setContentDocumentIdOld = new Set<Id>();
    
                    for (ContentVersion contentVersionOld : [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN :lstDeletedDocumentOld AND SpecialAcceptance__c = NULL]) {
                        setContentDocumentIdOld.add(contentVersionOld.ContentDocumentId);
                    }
    
                    List<ContentDocument> lstContentDocOld = [SELECT Id FROM ContentDocument WHERE Id IN :setContentDocumentIdOld];
                    delete lstContentDocOld;
                }
    
                mapResults.put('Success', 'Success');
            }
            catch (Exception ex) {
                mapResults.put('Error', ex.getMessage());
            }
            return mapResults;
        }*/
    
        @AuraEnabled
        public static Map<String, Object> deleteDocVisibilityDocument(List<Id> lstDeletedDocument, Id ProgramId) {
            Map<String, Object> mapResults = new Map<String, Object>();
            Set<Id> setContentDocumentId = new Set<Id>();
            Set<Id> setProgContentDocumentId = new Set<Id>();
            List <DocumentVisibility__c> lstDocVisibility = new List<DocumentVisibility__c>();
            List <ContentDocument> lstContentDocumentTodelete = new List<ContentDocument>();
            try{
                if (lstDeletedDocument.size() > 0) {
    
                    List<DocumentVisibility__c> lstContentDocumentVisibility = [SELECT Id, Tech_ContentDocumentId__c FROM DocumentVisibility__c WHERE Id IN :lstDeletedDocument];              
                    for (DocumentVisibility__c docVis : lstContentDocumentVisibility){
                        setContentDocumentId.add(docVis.Tech_ContentDocumentId__c);
                    }

                    for(ContentDocumentLink contentDocLink : [SELECT Id, ContentDocumentId
                                                              FROM ContentDocumentLink
                                                              WHERE LinkedEntityId =: ProgramId]){
                        setProgContentDocumentId.add(contentDocLink.ContentDocumentId);
                    }

                    for(ContentDocument doc : [SELECT Id, LatestPublishedVersionId FROM ContentDocument WHERE Id IN: setProgContentDocumentId AND Id IN:setContentDocumentId]){
                        lstContentDocumentTodelete.add(doc);
                    }

                    if (lstContentDocumentVisibility.size()>0){
                        delete lstContentDocumentVisibility;
                    }

                    if (lstContentDocumentTodelete.size()>0){
                        delete lstContentDocumentTodelete;
                    }
                }
    
                mapResults.put('Success', 'Success');
            }
            catch (Exception ex) {
                mapResults.put('Error', ex.getMessage());
            }
            return mapResults;
        }


        @AuraEnabled
        public static Map<String, Object> deleteDocVisibilityDocumentOld(List<Id> lstDeletedDocumentOld, Id ProgramId) {
            Map<String, Object> mapResults = new Map<String, Object>();
            Set<Id> setContentDocumentIdOld = new Set<Id>();
            Set<Id> setProgContentDocumentIdOld = new Set<Id>();
            List <DocumentVisibility__c> lstDocVisibility = new List<DocumentVisibility__c>();
            List <ContentDocument> lstContentDocumentTodeleteOld = new List<ContentDocument>();
            try{
                if (lstDeletedDocumentOld.size() > 0) {
    
                    List<DocumentVisibility__c> lstContentDocumentVisibilityOld = [SELECT Id, Tech_ContentDocumentId__c FROM DocumentVisibility__c WHERE Id IN :lstDeletedDocumentOld];              
                    for (DocumentVisibility__c docVisOld : lstContentDocumentVisibilityOld){
                        setContentDocumentIdOld.add(docVisOld.Tech_ContentDocumentId__c);
                    }

                    for(ContentDocumentLink contentDocLinkOld : [SELECT Id, ContentDocumentId
                                                              FROM ContentDocumentLink
                                                              WHERE LinkedEntityId =: ProgramId]){
                        setProgContentDocumentIdOld.add(contentDocLinkOld.ContentDocumentId);
                    }

                    for(ContentDocument docOld : [SELECT Id, LatestPublishedVersionId FROM ContentDocument WHERE Id IN: setProgContentDocumentIdOld AND Id IN:setContentDocumentIdOld]){
                        lstContentDocumentTodeleteOld.add(docOld);
                    }

                    if (lstContentDocumentVisibilityOld.size()>0){
                        delete lstContentDocumentVisibilityOld;
                    }

                    if (lstContentDocumentTodeleteOld.size()>0){
                        delete lstContentDocumentTodeleteOld;
                    }
                }
    
                mapResults.put('Success', 'Success');
            }
            catch (Exception ex) {
                mapResults.put('Error', ex.getMessage());
            }
            return mapResults;
        }
    
    
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
    
        @AuraEnabled(Cacheable = true)
        public static Map<Id, List<String>> getInitialDocuments(Id programId) {
            Set<Id> setContentDocumentId = new Set<Id>();
            Map<Id, List<String>> mapDocumentVersion = new Map<Id, List<String>>();
    
            for(ContentDocumentLink contentDocLink : [SELECT Id, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :programId AND Visibility = 'AllUsers']){
                setContentDocumentId.add(contentDocLink.ContentDocumentId);
            }
    
            for(ContentVersion contentVersion : [SELECT Id, DocumentType__c, GroupType__c, Phase__c, Tech_BrokerId__c, Tech_ReinsurerId__c, Tech_BrokerName__c, Tech_ReinsurerName__c, Title, PathOnClient, VersionData, ContentDocumentId, VersionNumber
            FROM ContentVersion
            WHERE ContentDocumentId IN :setContentDocumentId AND SpecialAcceptance__c = NULL]){
                if(mapDocumentVersion.containsKey(contentVersion.ContentDocumentId)){
                    mapDocumentVersion.get(contentVersion.ContentDocumentId).add(contentVersion.VersionNumber);
                }
                else{
                    mapDocumentVersion.put(contentVersion.ContentDocumentId, new List<String>{contentVersion.VersionNumber});
                }
            }
    
            return mapDocumentVersion;
        }
    
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
    
                for(ContentVersion newCV : [SELECT TECH_OldDocumentId__c, TECH_OldVersionNumber__c, ContentDocumentId from ContentVersion WHERE Id IN :setNewCVIds]){
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
        //SRA - 1046
        /*public class nameAccWrapper {
            @AuraEnabled public String broker {get; set;}
            @AuraEnabled public String reinsurer {get; set;}
            @AuraEnabled public String brokerId {get; set;}
        }*/
    }