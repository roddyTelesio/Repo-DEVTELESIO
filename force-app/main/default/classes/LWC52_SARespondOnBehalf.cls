public without sharing class LWC52_SARespondOnBehalf {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Controller for Lightning Web Component lwc52SARespondOnBehalf
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 04-JAN-2021  MBE   1.0      Initial version
-- 07-MAY-2021  MBE   1.1      W-0967 - Special Acceptance - Lien dans les emails SA
-- 11-AUG-2021  MBE   1.2      W-1011 - Special Acceptance - BR Response Emails + Code Optimzation
-- 19-OCT-2021  MBE   1.3      W-1034 - tailles limite de documents envoyés
-- 09-NOV-2021  MBE   1.4      W-1037 - remove renderedStoredEmailTemplate from Loop
--------------------------------------------------------------------------------------
**************************************************************************************/

    /**
    * @description Method to get Request details
    * @param String saId, String reqBrokerId, String reqReinsurerId, String reqPoolId, String reqId, Boolean isUserBR
    * @return Map<String, Object>
    */
    @AuraEnabled
    public static Map<String, Object> getRequestDetails(String saId, String reqBrokerId, String reqReinsurerId, String reqPoolId, String reqId, Boolean isUserBR){
        Map<String, Object> mapResults = new Map<String, Object>();
        List<Request__c> lstSaRequest = new List<Request__c>();
        List<Request__c> lstOriginalSaRequest = new List<Request__c>();
        List<OptionWrapper> lstCedingComp = new List<OptionWrapper>();
        List<SpecialAcceptance__c> lstSpecialAcceptance = new List<SpecialAcceptance__c>();
        List<ContentVersion> lstContentVersionExternal = new List<ContentVersion>();
        List<ContentVersion> lstContentVersionInternal = new List<ContentVersion>();
        List<ContentVersion> lstContentVersion = new List<ContentVersion>();
        List<String> lstSAFields = AP_Constant.getCreatableFieldsByObjName(AP_Constant.sObjectSpecialAcceptance);
        Program__c program = new Program__c();
        String strSAFields = String.join(lstSAFields , ', ');
        String statusSetup = AP_Constant.statusSetup;   
        String naturePublic = 'Public';
        String querySARClone, querySARCloneTest;
        String querySAROriginal;
        Set<Id> setAllContentVersionId = new Set<Id>();
        
        try {
            if(reqBrokerId == 'undefined' || reqBrokerId == 'null'){
                reqBrokerId = null;
            }

            if(reqReinsurerId == 'undefined' || reqReinsurerId == 'null'){
                reqReinsurerId = null;
            }

            if(reqPoolId == 'undefined' || reqPoolId == 'null'){
                reqPoolId = null;
            }

            querySARClone = 'SELECT Id, Name, Broker__c, Reinsurer__c, Pool__c, TECH_BrokerName__c, TECH_ReinsurerName__c, RiskCarrier__r.Name, Pool__r.Name, SA_Type__c, SpecialAcceptanceAnswer__c '
                        +', SA_Request_Status__c, PrincipalCedingCompany__c, toLabel(BrokerStatus__c), LastSentDate__c, ExpectedResponseDate__c, ResponseDate__c, CommentsResponse__c, Special_Acceptance__r.Type__c'
                        +' FROM Request__c  '; //RRA - 1086';


            String querySARCloneForBRByLink = querySARClone;

            querySAROriginal = 'SELECT Id, Name, Broker__c, Reinsurer__c, Pool__c, TECH_BrokerName__c, TECH_ReinsurerName__c, RiskCarrier__r.Name, Pool__r.Name, SA_Type__c, SpecialAcceptanceAnswer__c '
                        +', SA_Request_Status__c, PrincipalCedingCompany__c, toLabel(BrokerStatus__c), LastSentDate__c, ExpectedResponseDate__c, ResponseDate__c, CommentsResponse__c, Special_Acceptance__r.Type__c'
                        +' FROM Request__c WHERE Id = :reqId';

                       
            
            if(isUserBR == true){
                String querySA = 'select Id, Program__r.UwYear__c, Program__r.PrincipalCedingCompany__c, Program__r.Nature__c, SpaDurationDays__c, OriginalPolicyPremiumEuro__c, '
                    + 'Program__r.Name, SpecialAcceptanceName__c, RateExchange__c, TotalInsuredValueEuro__c, LimitEuro__c, TotalExposureAxaShareEuro__c, DeductibleAmountEuro__c, '
                    + 'TreatyExposureEuro__c, TotalSumRiskEuro__c, AverageSumRiskEuro__c, AverageSumRisk__c, '
                    + 'TopLocationPdValues100Euro__c, MaximumPossibleLossMplEuro__c, '
                    + 'LossLimit100Euro__c, ExposureAmount100Euro__c, CededExposureTreatyEuro__c, CededExposureAutofacEuro__c, CededExposureInternalFacultativeEuro__c, '
                    + 'CededExposureExternalFacultativeEuro__c, TotalAxaShareEuro__c, OriginalPremium100Euro__c, NetCededPremiumAutofacEuro__c, '
                    + strSAFields
                    + ' from SpecialAcceptance__c where (Id = :saId) ORDER BY SpecialAcceptanceName__c asc'; //RRA - 1086' ;' ;

                lstSpecialAcceptance = Database.query(querySA);

                String programId = lstSpecialAcceptance[0].Program__c;

                for(CoveredCedingCompany__c covCedCom : [SELECT Id, Account__r.Name FROM CoveredCedingCompany__c WHERE Program__c = :programId AND ProgramIsSelected__c = TRUE]){
                    lstCedingComp.add(new OptionWrapper(covCedCom.Account__r.Name, covCedCom.Account__c));
                }

                lstCedingComp.sort();

                program = [SELECT Id, Name, toLabel(Macro_L_O_B__c), InceptionDate__c, toLabel(Nature__c), PrincipalCedingCompany__r.Name, UwYear__c FROM Program__c WHERE Id = :programId LIMIT 1];
                
                //Declaration 1 -> display SAR - which is on internal ce 
                //Submission 2 -> display original SAR 

                if(lstSpecialAcceptance[0].Type__c == '1'){
                    querySARClone = querySARClone + ' WHERE Id = :reqId ORDER BY Special_Acceptance__r.SpecialAcceptanceName__c asc ';
                }
                else{
                    List<Request__c> lstOriginalReqBRPortal = [SELECT Id, OriginalRequest__c FROM Request__c WHERE Id = :reqId];
                    String originalReq = lstOriginalReqBRPortal[0].OriginalRequest__c;
                    querySARClone = querySARClone + ' WHERE Id = :originalReq ORDER BY Special_Acceptance__r.SpecialAcceptanceName__c asc ';
                }
            }
            else{
                querySARClone = querySARClone + ' WHERE Id = :reqId ORDER BY Special_Acceptance__r.SpecialAcceptanceName__c asc ';
            }

            lstSaRequest = Database.query(querySARClone);

            if(isUserBR == true && lstSaRequest.size() ==  0){
                //BR Portal - Answer Page through link
                //Request Id in url - Request Id of Internal CE
                querySARCloneForBRByLink = querySARCloneForBRByLink + ' WHERE Id = :reqId ORDER BY Special_Acceptance__r.SpecialAcceptanceName__c asc ';
                lstSaRequest = Database.query(querySARCloneForBRByLink);

                querySAROriginal = 'SELECT Id, Name, Broker__c, Reinsurer__c, Pool__c, TECH_BrokerName__c, TECH_ReinsurerName__c, RiskCarrier__r.Name, Pool__r.Name, SA_Type__c, SpecialAcceptanceAnswer__c '
                        +', SA_Request_Status__c, PrincipalCedingCompany__c, toLabel(BrokerStatus__c), LastSentDate__c, ExpectedResponseDate__c, ResponseDate__c, CommentsResponse__c, Special_Acceptance__r.Type__c'
                        +' FROM Request__c WHERE OriginalRequest__c = :reqId';
            }

            //Response editable based on original request(during send)
            lstOriginalSaRequest = Database.query(querySAROriginal);

            for(DocumentVisibility__c docVis : [SELECT Id, ContentVersionId__c, Company__c, Broker__c, Reinsurer__c, SpecialAcceptance__c
                                                FROM DocumentVisibility__c
                                                WHERE SpecialAcceptance__c = :saId
                                                AND Broker__c = :reqBrokerId
                                                AND Reinsurer__c = :reqReinsurerId]){
                setAllContentVersionId.add(docVis.ContentVersionId__c);
            }

            //Remove VersionData, PathOnClient in Query lstContentVersion

            if(setAllContentVersionId.size() > 0){
                lstContentVersion = [SELECT Id, VersionData, PathOnClient, Phase__c, Title, IsExternal__c, ContentDocumentId
                                            , Nature__c, FileType, FileExtension, ContentUrl, ContentSize
                                            , FirstPublishLocationId, SpecialAcceptance__c
                                    FROM ContentVersion
                                    WHERE Id IN :setAllContentVersionId];

                for(ContentVersion cv : lstContentVersion){
                    if(cv.IsExternal__c == true){
                        lstContentVersionExternal.add(cv);
                    }
                    else if(cv.IsExternal__c == false  && cv.Nature__c == naturePublic){
                        lstContentVersionInternal.add(cv);
                    }
                }
            }

            mapResults.put('Success', 'Success');
            mapResults.put('program', program);
            mapResults.put('lstCedingComp', lstCedingComp);
            mapResults.put('lstSaRequest', lstSaRequest);
            mapResults.put('lstOriginalSaRequest', lstOriginalSaRequest);
            mapResults.put('lstSpecialAcceptance', lstSpecialAcceptance);
            mapResults.put('lstContentVersionExternal', lstContentVersionExternal);
            mapResults.put('lstContentVersionInternal', lstContentVersionInternal);
        }
        catch (Exception ex) {
            mapResults.put('Error', ex.getMessage());
        }
        return mapResults;
    }

    /**
    * @description Method to send Respond on behalf
    * @param String commentValue, String responseValue, List<String> lstRequestId, Boolean isExtPortalBR, String saId, List<ContentVersion> lstDocumentToUpdate, List<Id> lstDeletedDocument, Boolean isExtPortalUGP, String reqBrokerId, String reqReinsurerId
    * @return Map<String, Object>
    */
    @AuraEnabled
    public static Map<String, Object> sendRespondOnBehalf(String commentValue, String responseValue, List<String> lstRequestId, Boolean isExtPortalBR, String saId, List<ContentVersion> lstDocumentToUpdate, List<Id> lstDeletedDocument, Boolean isExtPortalUGP, String reqBrokerId, String reqReinsurerId){
        Map<String, Object> mapResults = new Map<String, Object>();
        Map<Id, Request__c> mapRequestSentByOriginalReqId = new Map<Id, Request__c>();
        List<Id> lstOriginalRequestId = new List<Id>();
        List<Request__c> lstSaRequest = new List<Request__c>();
        List<Request__c> lstRequestNewVersion = new List<Request__c>();
        List<Request__c> lstRequestVersionStatus = new List<Request__c>();
        List<Id> lstContentDocument = new List<Id>();
        List<ContentVersion> lstContentVersionToUpdate = new List<ContentVersion>();
        List<ContentDocumentLink> lstContentDocumentLinkToInsert = new List<ContentDocumentLink>();
        List<ContentDocumentLink> lstContentDocumentLinkToDelete = new List<ContentDocumentLink>();
        List<DocumentVisibility__c> lstDocumentVisibilityToInsert = new List<DocumentVisibility__c>();
        List<DocumentVisibility__c> lstAllDocumentVisibilities = new List<DocumentVisibility__c>();  
        List<String> lstRequestFields = AP_Constant.getCreatableFieldsByObjName(AP_Constant.sObjectRequest);
        String strRequestFields = String.join(lstRequestFields, ', ');
        String querySaRequest;
        Set<String> setAllDocumentVisibilities = new Set<String>();  
        Set<Id> setNewVersionReqId = new Set<Id>();
        List<Request__c> lstOriginalRequestToUpdate = new List<Request__c>();  

        //RRA - ticket 1453 - 24022023
        String statusInternal = null;
        List<SpecialAcceptance__c> lstSA = new  List<SpecialAcceptance__c>();

        Savepoint sp = Database.setSavepoint();

        try {
            if(isExtPortalBR == true){
                //if BR Portal -> Query Reinsurer__r.Name, Broker__r.Name, ExpectedResponseDate__c, LastSentDate__c, SA_Type__c

                querySaRequest = 'SELECT Id, TECH_TreatyName__c, Treaty__r.PlacementShare_Perc__c, TECH_BrokerName__c, TECH_IsBrokerPresent__c, TECH_ReinsurerName__c, TECH_Layer__c, TECH_UWyear__c,  SigningRegionalManager__r.Email '
                    + ', RiskCarrier__r.Name, FinancialEntity__r.Name, Program__r.LossDepositMode__c, Program__r.LossDeposit__c, Program__r.UwYear__c, Reinsurer__r.Name, Broker__r.Name, ExpectedResponseDate__c, LastSentDate__c, SA_Type__c '
                    + ', Treaty__r.LossDepositMode__c, Treaty__r.LossDeposit__c, Treaty__r.Deductions__c, TreatyReference__c, Treaty__r.TypeofTreaty__c '
                    + ', Treaty__r.PremiumDeposit__c, Program__r.LossDepositLevel__c, Pool__r.Name, Pool__r.AssignedTo__r.Email, Pool__r.AssignedTo__c,Pool__r.SA_Email__c, Program__r.Name, program__r.principalcedingcompany__r.Name, Program__r.PrincipalCedingCompany__c '
                    + ', Special_Acceptance__r.SpecialAcceptanceName__c, Special_Acceptance__r.CoveredCedingCompany__r.Name, Special_Acceptance__r.PrincipalCedingCompany__r.EmailSA__c, Special_Acceptance__r.PrincipalCedingCompany__r.EmailPCLife__c,'
                    +  strRequestFields
                    + ' from Request__c where Id IN :lstRequestId';
            }
            else{
                querySaRequest = 'SELECT Id, TECH_TreatyName__c, Treaty__r.PlacementShare_Perc__c, TECH_BrokerName__c, TECH_IsBrokerPresent__c, TECH_ReinsurerName__c, TECH_Layer__c, TECH_UWyear__c,  SigningRegionalManager__r.Email '
                    + ', RiskCarrier__r.Name, FinancialEntity__r.Name, Program__r.LossDepositMode__c, Program__r.LossDeposit__c, Program__r.UwYear__c, Reinsurer__r.Name, Broker__r.Name '
                    + ', Treaty__r.LossDepositMode__c, Treaty__r.LossDeposit__c, Treaty__r.Deductions__c, TreatyReference__c, Treaty__r.TypeofTreaty__c '
                    + ', Treaty__r.PremiumDeposit__c, Program__r.LossDepositLevel__c, Pool__r.Name, Pool__r.AssignedTo__r.Email, Pool__r.AssignedTo__c,Pool__r.SA_Email__c, Program__r.Name, program__r.principalcedingcompany__r.Name, Program__r.PrincipalCedingCompany__c '
                    + ', Special_Acceptance__r.SpecialAcceptanceName__c, Special_Acceptance__r.CoveredCedingCompany__r.Name, Special_Acceptance__r.PrincipalCedingCompany__r.EmailSA__c, Special_Acceptance__r.PrincipalCedingCompany__r.EmailPCLife__c,'
                    +  strRequestFields
                    + ' from Request__c where Id IN :lstRequestId';
            }

            lstSaRequest = Database.query(querySaRequest);

            System.debug('lstSaRequest == ' + lstSaRequest);
            System.debug('lstSaRequestSIZE == ' + lstSaRequest.size());

            for(Request__c req : lstSaRequest){
                req.SpecialAcceptanceAnswer__c = responseValue;
                req.CommentsResponse__c = commentValue;
                req.ResponseDate__c = System.today();

                if(responseValue == 'Agree'){
                    req.SA_Request_Status__c = AP_Constant.statusAgreed;
                    statusInternal = AP_Constant.statusAgreed; //RRA - ticket 1453- 24022023
                }
                else if(responseValue == 'Refuse'){
                    req.SA_Request_Status__c = AP_Constant.statusRefused;
                    statusInternal = AP_Constant.statusRefused; //RRA - ticket 1453 - 24022023
                }
                else if(responseValue == 'Need more information/Subjectivities'){
                    req.SA_Request_Status__c = AP_Constant.statusMoreInfoRequired;
                    statusInternal = AP_Constant.statusRefused; //RRA - ticket 1453 - 24022023
                }

                if(req.OriginalRequest__c == null){
                    mapRequestSentByOriginalReqId.put(req.Id, req);
                }
                else{
                    mapRequestSentByOriginalReqId.put(req.OriginalRequest__c, req);
                }

                req.VersionMajor__c = 1;
                req.LastVersionSent__c = false; //RRA - ticket 1488 - 04052023
                req.LastVersionAnswered__c = false; //RRA - ticket 1488 - 04052023
                Request__c newVersionRequest = req.clone(false, false, false, false);
                newVersionRequest.TECH_Actor2Id__c = null;

                if(req.OriginalRequest__c == null){
                    newVersionRequest.OriginalRequest__c = req.Id;
                }
                else{
                    newVersionRequest.OriginalRequest__c = req.OriginalRequest__c;
                    lstOriginalRequestId.add(req.OriginalRequest__c);
                }

                newVersionRequest.LastVersionSent__c = true;
                newVersionRequest.LastVersionAnswered__c = true;
                lstRequestNewVersion.add(newVersionRequest);
            }

            if(lstSaRequest.size() > 0){
                update lstSaRequest;
            }

            if(lstRequestNewVersion.size() > 0){
                //insert lstRequestNewVersion;
            }

             //RRA - ticket 1453 - 24022023
            if(lstOriginalRequestToUpdate.size() > 0){
                update lstOriginalRequestToUpdate;
            }

            for(Request__c newVersionReq : lstRequestNewVersion){
                setNewVersionReqId.add(newVersionReq.Id);
            }

            lstRequestVersionStatus = [SELECT Id, CommentsResponse__c, SpecialAcceptanceAnswer__c, OriginalRequest__c, ExpectedResponseDate__c, ResponseDate__c, TECH_LastSendUpdRemDate__c, LastSentDate__c, SA_Request_Status__c
                                       FROM Request__c 
                                       WHERE Id IN :mapRequestSentByOriginalReqId.keySet() OR OriginalRequest__c IN :mapRequestSentByOriginalReqId.keySet()];

            for(Request__c request : lstRequestVersionStatus){
                Id originalReqId;
                if(request.OriginalRequest__c == null){
                    originalReqId = request.Id;
                }

                else{
                    originalReqId = request.OriginalRequest__c;
                }
                
                Request__c originalRequest = mapRequestSentByOriginalReqId.get(originalReqId);
                request.SA_Request_Status__c = originalRequest.SA_Request_Status__c;
                request.SpecialAcceptanceAnswer__c = originalRequest.SpecialAcceptanceAnswer__c;
                request.CommentsResponse__c = originalRequest.CommentsResponse__c;
                
                request.ResponseDate__c = originalRequest.ResponseDate__c;

                if(!setNewVersionReqId.contains(request.Id)){
                    request.LastVersionSent__c = true; //RRA - ticket 1488 - 04052023
                    request.LastVersionAnswered__c = true; //RRA - ticket 1488 - 04052023
                }
            }

            if(lstRequestVersionStatus.size() > 0){
                update lstRequestVersionStatus;
            }

            if(isExtPortalBR == true){
                lstAllDocumentVisibilities = [SELECT Id, Program__c, Treaty__c, Broker__c, Reinsurer__c, SpecialAcceptance__c, ContentVersionId__c
                                              FROM DocumentVisibility__c
                                              WHERE SpecialAcceptance__c = :saId];

                for(DocumentVisibility__c docVis : lstAllDocumentVisibilities){
                    if(docVis.Broker__c == null){
                        setAllDocumentVisibilities.add(docVis.ContentVersionId__c + '-' + docVis.Treaty__c + '-' + docVis.Reinsurer__c);
                    }
                    else{
                        setAllDocumentVisibilities.add(docVis.ContentVersionId__c + '-' + docVis.Treaty__c + '-' + docVis.Reinsurer__c + '-' + docVis.Broker__c);
                    }
                }

                //save document
                for(ContentVersion contentVersion : lstDocumentToUpdate){
                    ContentVersion contentVersionToUpdate = new ContentVersion();
                    contentVersionToUpdate.Id = contentVersion.Id;
                    contentVersionToUpdate.SpecialAcceptance__c = saId;
                    contentVersionToUpdate.Nature__c = 'Private';
                    lstContentVersionToUpdate.add(contentVersionToUpdate);
                    lstContentDocument.add(contentVersion.ContentDocumentId);

                    String strDocVis;

                    if(reqBrokerId != null && reqBrokerId != 'null'){
                        strDocVis = contentVersion.Id + '-' + lstSaRequest[0].Treaty__c + '-' + reqReinsurerId;
                    }
                    else{
                        strDocVis = contentVersion.Id + '-' + lstSaRequest[0].Treaty__c + '-' + reqReinsurerId + '-' + reqBrokerId;
                    }

                    if(!setAllDocumentVisibilities.contains(strDocVis)){
                        DocumentVisibility__c docVis = new DocumentVisibility__c();
                        docVis.ContentVersionId__c = contentVersion.Id;
                        docVis.Program__c = lstSaRequest[0].Program__c;
                        docVis.Treaty__c = lstSaRequest[0].Treaty__c;
                        docVis.Reinsurer__c = reqReinsurerId;
                        docVis.SpecialAcceptance__c = saId;

                        if(reqBrokerId != null && reqBrokerId != 'null' && reqBrokerId != 'undefined'){
                            docVis.Broker__c = reqBrokerId;
                        }

                        lstDocumentVisibilityToInsert.add(docVis);
                    }       
                }

                if(lstDocumentVisibilityToInsert.size() > 0){
                    insert lstDocumentVisibilityToInsert;
                }

                if(lstContentVersionToUpdate.size() > 0){
                    update lstContentVersionToUpdate;

                    lstContentDocumentLinkToDelete = [SELECT Id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :saId AND ContentDocumentId IN :lstContentDocument];
                    
                    if(lstContentDocumentLinkToDelete.size() > 0){
                        delete lstContentDocumentLinkToDelete;
                    }

                    for(Id contentDocumentId : lstContentDocument){
                        ContentDocumentLink cd = new ContentDocumentLink();
                        cd.LinkedEntityId = saId;
                        cd.ContentDocumentId = contentDocumentId;
                        cd.Visibility = 'AllUsers';
                        cd.ShareType = 'V';
                        lstContentDocumentLinkToInsert.add(cd);
                    }

                    if(lstContentDocumentLinkToInsert.size() > 0){
                        insert lstContentDocumentLinkToInsert;
                    }
                }

                if(lstDeletedDocument.size() > 0){
                    Set<Id> setContentDocumentId = new Set<Id>();

                    for(ContentVersion contentVersion : [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN :lstDeletedDocument]) {
                        setContentDocumentId.add(contentVersion.ContentDocumentId);
                    }

                    List<ContentDocument> lstContentDoc = [SELECT Id FROM ContentDocument WHERE Id IN :setContentDocumentId];

                    if(lstContentDoc.size() > 0){
                        delete lstContentDoc;
                    }
                }      
            }

            if(isExtPortalBR == true || isExtPortalUGP == true){
                Map<String, Object> mapSendMailToCeResult = sendEmailToCe(lstSaRequest);
                mapResults.put('mapSendMailToCeResult', mapSendMailToCeResult);
            }

            //RRA - ticket 1453 - 24022023
            SpecialAcceptance__c sa = [SELECT Id, InternalStatus__c  FROM SpecialAcceptance__c WHERE Id =: saId];
            if (sa != null  && statusInternal != null){
                sa.InternalStatus__c = statusInternal;
                lstSA.add(sa);
            }
            if (lstSA.size()>0){
                update lstSA;
            }

            mapResults.put('lstSaRequest', lstSaRequest);
            mapResults.put('lstSaRequestSize', lstSaRequest.size());
            mapResults.put('Success', 'Success');
        }catch (Exception ex) {
            Database.rollback(sp);
            mapResults.put('Error', ex.getMessage());
        }
        return mapResults;
    }

    /**
    * @description Method to save Respond on behalf
    * @param String commentValue, String responseValue, List<String> lstRequestId, Boolean isExtPortalUGP, String saId, List<ContentVersion> lstDocumentToUpdate, List<Id> lstDeletedDocument, String reqBrokerId, String reqReinsurerId
    * @return Map<String, Object>
    */
    @AuraEnabled
    public static Map<String, Object> saveRespondOnBehalf(String commentValue, String responseValue, List<String> lstRequestId, Boolean isExtPortalUGP, String saId, List<ContentVersion> lstDocumentToUpdate, List<Id> lstDeletedDocument, String reqBrokerId, String reqReinsurerId){
        Map<String, Object> mapResults = new Map<String, Object>();
        List<Request__c> lstSaRequest = new List<Request__c>();
        List<Id> lstContentDocument = new List<Id>();
        List<ContentVersion> lstContentVersionToUpdate = new List<ContentVersion>();
        List<ContentDocumentLink> lstContentDocumentLinkToInsert = new List<ContentDocumentLink>();
        List<ContentDocumentLink> lstContentDocumentLinkToDelete = new List<ContentDocumentLink>();
        List<DocumentVisibility__c> lstDocumentVisibilityToInsert = new List<DocumentVisibility__c>();
        List<DocumentVisibility__c> lstAllDocumentVisibilities = new List<DocumentVisibility__c>();
        List<String> lstRequestFields = AP_Constant.getCreatableFieldsByObjName(AP_Constant.sObjectRequest);
        Set<String> setAllDocumentVisibilities = new Set<String>();  
        String strRequestFields = String.join(lstRequestFields, ', ');
        String querySaRequest;

        //RRA - ticket SA - 24022023
        String statusInternal = null;
        List<SpecialAcceptance__c> lstSA = new  List<SpecialAcceptance__c>();
        Savepoint sp = Database.setSavepoint();

        try{
            querySaRequest = 'SELECT Id, TECH_TreatyName__c, Treaty__r.PlacementShare_Perc__c, TECH_BrokerName__c, TECH_IsBrokerPresent__c, TECH_ReinsurerName__c, TECH_Layer__c, TECH_UWyear__c,  SigningRegionalManager__r.Email '
                    + ', RiskCarrier__r.Name, FinancialEntity__r.Name, Program__r.LossDepositMode__c, Program__r.LossDeposit__c, Program__r.UwYear__c, Reinsurer__r.Name, Broker__r.Name, ExpectedResponseDate__c, LastSentDate__c, SA_Type__c '
                    + ', Treaty__r.LossDepositMode__c, Treaty__r.LossDeposit__c, Treaty__r.Deductions__c, TreatyReference__c, Treaty__r.TypeofTreaty__c '
                    + ', Treaty__r.PremiumDeposit__c, Program__r.LossDepositLevel__c, Pool__r.Name, Pool__r.AssignedTo__r.Email, Pool__r.AssignedTo__c,Pool__r.SA_Email__c, Program__r.Name, program__r.principalcedingcompany__r.Name, Program__r.PrincipalCedingCompany__c '
                    + ', Special_Acceptance__r.SpecialAcceptanceName__c, Special_Acceptance__r.CoveredCedingCompany__r.Name, Special_Acceptance__r.PrincipalCedingCompany__r.EmailSA__c, Special_Acceptance__r.PrincipalCedingCompany__r.EmailPCLife__c,'
                    +  strRequestFields
                    + ' from Request__c where Id IN :lstRequestId';

            lstSaRequest = Database.query(querySaRequest);

            for(Request__c req : lstSaRequest){
                req.SpecialAcceptanceAnswer__c = responseValue;
                req.CommentsResponse__c = commentValue;
                req.ResponseDate__c = System.today();

                if(responseValue == 'Agree'){
                    req.SA_Request_Status__c = AP_Constant.statusAgreed;
                    statusInternal = AP_Constant.statusAgreed; //RRA - ticket 1453- 24022023
                }
                else if(responseValue == 'Refuse'){
                    req.SA_Request_Status__c = AP_Constant.statusRefused;
                    statusInternal = AP_Constant.statusRefused; //RRA - ticket 1453 - 24022023
                }
                else if(responseValue == 'Need more information/Subjectivities'){
                    req.SA_Request_Status__c = AP_Constant.statusMoreInfoRequired;
                    statusInternal = AP_Constant.statusRefused; //RRA - ticket 1453 - 24022023
                }
            }

            if(lstSaRequest.size() > 0){
                update lstSaRequest;
            }

            //RRA - ticket 1453 - 24022023
            SpecialAcceptance__c sa = [SELECT Id, InternalStatus__c  FROM SpecialAcceptance__c WHERE Id =: saId];
            if (sa != null  && statusInternal != null){
                sa.InternalStatus__c = statusInternal;
                lstSA.add(sa);
            }
            if (lstSA.size()>0){
                update lstSA;
            }

            lstAllDocumentVisibilities = [SELECT Id, Program__c, Treaty__c, Broker__c, Reinsurer__c, SpecialAcceptance__c, ContentVersionId__c
                                          FROM DocumentVisibility__c
                                          WHERE SpecialAcceptance__c = :saId];

            for(DocumentVisibility__c docVis : lstAllDocumentVisibilities){
                if(docVis.Broker__c == null){
                    setAllDocumentVisibilities.add(docVis.ContentVersionId__c + '-' + docVis.Treaty__c + '-' + docVis.Reinsurer__c);
                }
                else{
                    setAllDocumentVisibilities.add(docVis.ContentVersionId__c + '-' + docVis.Treaty__c + '-' + docVis.Reinsurer__c + '-' + docVis.Broker__c);
                }
            }

            //save document
            for(ContentVersion contentVersion : lstDocumentToUpdate){
                ContentVersion contentVersionToUpdate = new ContentVersion();
                contentVersionToUpdate.Id = contentVersion.Id;
                contentVersionToUpdate.SpecialAcceptance__c = saId;
                contentVersionToUpdate.Nature__c = 'Private';
                lstContentVersionToUpdate.add(contentVersionToUpdate);
                lstContentDocument.add(contentVersion.ContentDocumentId);

                String strDocVis;

                if(reqBrokerId != null && reqBrokerId != 'null'){
                    strDocVis = contentVersion.Id + '-' + lstSaRequest[0].Treaty__c + '-' + reqReinsurerId;
                }
                else{
                    strDocVis = contentVersion.Id + '-' + lstSaRequest[0].Treaty__c + '-' + reqReinsurerId + '-' + reqBrokerId;
                }

                if(!setAllDocumentVisibilities.contains(strDocVis)){
                    DocumentVisibility__c docVis = new DocumentVisibility__c();
                    docVis.ContentVersionId__c = contentVersion.Id;
                    docVis.Program__c = lstSaRequest[0].Program__c;
                    docVis.Treaty__c = lstSaRequest[0].Treaty__c;
                    docVis.Reinsurer__c = reqReinsurerId;
                    docVis.SpecialAcceptance__c = saId;

                    if(reqBrokerId != null && reqBrokerId != 'null' && reqBrokerId != 'undefined'){
                        docVis.Broker__c = reqBrokerId;
                    }

                    lstDocumentVisibilityToInsert.add(docVis);
                }
            }

            if(lstDocumentVisibilityToInsert.size() > 0){
                insert lstDocumentVisibilityToInsert;
            }

            if(lstContentVersionToUpdate.size() > 0){
                update lstContentVersionToUpdate;

                lstContentDocumentLinkToDelete = [SELECT Id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :saId AND ContentDocumentId IN :lstContentDocument];

                if(lstContentDocumentLinkToDelete.size() > 0){
                    delete lstContentDocumentLinkToDelete;
                }

                for(Id contentDocumentId : lstContentDocument){
                    ContentDocumentLink cd = new ContentDocumentLink();
                    cd.LinkedEntityId = saId;
                    cd.ContentDocumentId = contentDocumentId;
                    cd.Visibility = 'AllUsers';
                    cd.ShareType = 'V';
                    lstContentDocumentLinkToInsert.add(cd);
                }

                if(lstContentDocumentLinkToInsert.size() > 0){
                    insert lstContentDocumentLinkToInsert;
                }
            }

            if(lstDeletedDocument.size() > 0){
                Set<Id> setContentDocumentId = new Set<Id>();

                for(ContentVersion contentVersion : [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN :lstDeletedDocument]) {
                    setContentDocumentId.add(contentVersion.ContentDocumentId);
                }

                List<ContentDocument> lstContentDoc = [SELECT Id FROM ContentDocument WHERE Id IN :setContentDocumentId];

                if(lstContentDoc.size() > 0){
                    delete lstContentDoc;
                }
            }

            mapResults.put('Success', 'Success');
        }catch (Exception ex) {
            Database.rollback(sp);
            mapResults.put('Error', ex.getMessage());
        }
        return mapResults;
    }

    /**
    * @description Method to Save Documents
    * @param List<ContentVersion> lstContentVersion
    * @return Map<String, Object>
    */
    @AuraEnabled
    public static Map<String, Object> saveDocuments(List<ContentVersion> lstContentVersion) {
        Map<String, Object> mapResults = new Map<String, Object>();

        try{
            if(lstContentVersion.size() > 0) {
                update lstContentVersion;
            }
            mapResults.put('Success', 'Success');
        }
        catch (Exception ex) {
            mapResults.put('Error', ex.getMessage());
        }
        return mapResults;
    }

    /**
    * @description Method to Send Email Alert to CE when Answer to SAR 
    * @param List<Request__c> lstSaReq
    * @return Map<String, Object>
    */
    @AuraEnabled
    public static Map<String, Object> sendEmailToCe(List<Request__c> lstSaReq){
        System.debug('Starting sending email');
        Map<String, Object> mapResults = new Map<String, Object>();
        Map<String, Id> mapEmailTempIdByName = new Map<String, Id>();
        List<String> lstEmailTemplateName = new List<String>();
        List<Messaging.SingleEmailMessage> lstMailsToSend =  new List<Messaging.SingleEmailMessage>();
        Savepoint sp = Database.setSavepoint();
        String connectedUserContactEmail;
        String brokerReinsurerName; //RRA - ticket 1761 - 29112023
      
        try{
            lstEmailTemplateName = new List<String>{AP_Constant.emailTempSaReqAnswerAgree
                                                   ,AP_Constant.emailTempSaReqAnswerRefuse
                                                   ,AP_Constant.emailTempSaReqAnswerNeedMoreInfo};

            for(EmailTemplate emailTemp: [SELECT Id, Name FROM EmailTemplate WHERE Name IN : lstEmailTemplateName]){
                mapEmailTempIdByName.put(emailTemp.Name, emailTemp.Id);
            }

            Id userId = UserInfo.getUserId();

            Messaging.SingleEmailMessage emailTempSaReqAnswerAgree = new Messaging.SingleEmailMessage();       
            emailTempSaReqAnswerAgree = Messaging.renderStoredEmailTemplate(mapEmailTempIdByName.get(AP_Constant.emailTempSaReqAnswerAgree), userId, null);

            Messaging.SingleEmailMessage emailTempSaReqAnswerRefuse = new Messaging.SingleEmailMessage();       
            emailTempSaReqAnswerRefuse = Messaging.renderStoredEmailTemplate(mapEmailTempIdByName.get(AP_Constant.emailTempSaReqAnswerRefuse), userId, null);

            Messaging.SingleEmailMessage emailTempSaReqAnswerNeedMoreInfo = new Messaging.SingleEmailMessage();       
            emailTempSaReqAnswerNeedMoreInfo = Messaging.renderStoredEmailTemplate(mapEmailTempIdByName.get(AP_Constant.emailTempSaReqAnswerNeedMoreInfo), userId, null);
            
            System.debug('emailTempSaReqAnswerAgree == ' + emailTempSaReqAnswerAgree);

            User usr = [SELECT Id, ContactId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            Id contactId = usr.ContactId;
            
            //RRA - ticket 1761 - 29112023
            //For AXA SA used as sender email address
            User userAXASA = [SELECT Id, Name, Email FROM User WHERE Id =:System.label.AXA_SA_Sender LIMIT 1];

            if(contactId != null){
                Contact contact = [SELECT Id, AccountId, Email FROM Contact WHERE Id = :contactId LIMIT 1];
                connectedUserContactEmail = contact.Email;
            }

            for(Request__c saReq : lstSaReq){
                Id emailTempSaReqAnswerId;
                
                //RRA - ticket 1761 - 29112023
                if (saReq.Broker__c != null && saReq.Reinsurer__c != null){
                    brokerReinsurerName = 'by ' + saReq.TECH_ReinsurerName__c + ' (via ' + saReq.TECH_BrokerName__c + ') '; 
                }else if (saReq.Broker__c == null && saReq.Reinsurer__c != null){
                    brokerReinsurerName = 'by ' + saReq.TECH_ReinsurerName__c;
                }
                System.debug('brokerReinsurerName == ' + brokerReinsurerName);
                if(saReq.SpecialAcceptanceAnswer__c == 'Agree'){
                    emailTempSaReqAnswerId = mapEmailTempIdByName.get(AP_Constant.emailTempSaReqAnswerAgree);
                }
                else if(saReq.SpecialAcceptanceAnswer__c == 'Refuse'){
                    emailTempSaReqAnswerId = mapEmailTempIdByName.get(AP_Constant.emailTempSaReqAnswerRefuse);
                }
                else if(saReq.SpecialAcceptanceAnswer__c == 'Need more information/Subjectivities'){
                    emailTempSaReqAnswerId = mapEmailTempIdByName.get(AP_Constant.emailTempSaReqAnswerNeedMoreInfo);
                }
                
                System.debug('emailTempSaReqAnswerId == ' + emailTempSaReqAnswerId);

                Messaging.SingleEmailMessage m = new Messaging.SingleEmailMessage();
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                List<String> lstEmailsToSend = new List<String>();
                List<String> lstCCEmailsToSend = new List<String>();
                String pccSaEmail = saReq.Special_Acceptance__r.PrincipalCedingCompany__r.EmailSA__c;
                String pccBalEmail = saReq.Special_Acceptance__r.PrincipalCedingCompany__r.EmailPCLife__c;
                List<String> lstSaPCCEmailsToSend = new List<String>();
                List<String> lstPCCBalEmailsToSend = new List<String>();

                if(pccSaEmail != null ){
                    if(pccSaEmail.contains(';')){
                        lstSaPCCEmailsToSend = pccSaEmail.split(';');
                    }
                    else{
                        lstSaPCCEmailsToSend.add(pccSaEmail);
                    }
                }
                
                System.debug('lstSaPCCEmailsToSend == ' + lstSaPCCEmailsToSend);

                if(pccBalEmail != null ){
                    if(pccBalEmail.contains(';')){
                        lstPCCBalEmailsToSend = pccBalEmail.split(';');
                    }
                    else{
                        lstPCCBalEmailsToSend.add(pccBalEmail);
                    }
                }
                
                System.debug('lstPCCBalEmailsToSend == ' + lstPCCBalEmailsToSend);

                if(saReq.Pool__c == null){
                    //B/R Portal
                    //send to PCC SA Email
                    //CC to BAL Of PCC - EmailPCLife__c + to connected user email
                    lstEmailsToSend = lstSaPCCEmailsToSend;
                    lstPCCBalEmailsToSend.add(connectedUserContactEmail);
                    lstCCEmailsToSend = lstPCCBalEmailsToSend;
                }
                else{
                    //send to Pool SA Email
                    //CC to SA Email of PCC
                    if(saReq.Pool__r.SA_Email__c != null){
                        lstEmailsToSend.add(saReq.Pool__r.SA_Email__c);
                    }
                    
                    lstCCEmailsToSend = lstSaPCCEmailsToSend; 
                }
                
                System.debug('lstEmailsToSend == ' + lstEmailsToSend);
                System.debug('lstCCEmailsToSend == ' + lstCCEmailsToSend);

                if(lstEmailsToSend.size() > 0){
                    m.setTemplateId(emailTempSaReqAnswerId);
                    //m.setTargetObjectId(userId);
                    // m.setWhatId(reqId);
                    m.setSaveAsActivity(false);

                    if(saReq.SpecialAcceptanceAnswer__c == 'Agree'){
                        m.setSubject(emailTempSaReqAnswerAgree.getSubject());
                        m.setHtmlBody(emailTempSaReqAnswerAgree.htmlBody);                   
                    }
                    else if(saReq.SpecialAcceptanceAnswer__c == 'Refuse'){
                        m.setSubject(emailTempSaReqAnswerRefuse.getSubject());
                        m.setHtmlBody(emailTempSaReqAnswerRefuse.htmlBody);          
                    }
                    else if(saReq.SpecialAcceptanceAnswer__c == 'Need more information/Subjectivities'){
                        m.setSubject(emailTempSaReqAnswerNeedMoreInfo.getSubject());
                        m.setHtmlBody(emailTempSaReqAnswerNeedMoreInfo.htmlBody);
                    }
                    
                    // m = Messaging.renderStoredEmailTemplate(emailTempSaReqAnswerId, userId, null);
                    mail.setToAddresses(lstEmailsToSend);
                    //RRA - ticket 1761 - 29112023
                    OrgWideEmailAddress[] owea = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'actor.po@axa.com'];
                    if (owea.size()>0) {
                        mail.setOrgWideEmailAddressId(owea.get(0).Id);
                    }
                    mail.setReplyTo(userAXASA.Email); //RRA - ticket 1761 - 29112023
                    //mail.setReplyTo(UserInfo.getUserEmail());
                    //mail.setSenderDisplayName(UserInfo.getFirstName() + ' ' + UserInfo.getLastName());

                    if(lstCCEmailsToSend.size() > 0){
                        mail.setCcAddresses(lstCCEmailsToSend);
                    }

                    String htmlBody = m.htmlBody;
                    
                    System.debug('htmlBody == ' + htmlBody);
                    
                    String htmlSubject = m.getSubject();
                    
                    System.debug('htmlSubject == ' + htmlSubject);
                    
                    htmlBody = htmlBody.replace('{U/W Year}', saReq.Program__r.UwYear__c);
                    htmlBody = htmlBody.replace('{Programname}', saReq.Program__r.Name);
                    htmlSubject = htmlSubject.replace('{ProgramName}', saReq.Program__r.Name);

                    String strSAName = saReq.Special_Acceptance__r.SpecialAcceptanceName__c != null ? saReq.Special_Acceptance__r.SpecialAcceptanceName__c : '';
                    htmlBody = htmlBody.replace('{SAname}', strSAName);

                    htmlSubject = htmlSubject.replace('{brokerReinsurerName}', brokerReinsurerName); //RRA - ticket 1761 - 29112023
                    
                    String strCovCedCom =  saReq.Special_Acceptance__r.CoveredCedingCompany__r != null ? saReq.Special_Acceptance__r.CoveredCedingCompany__r.Name : '';
                    htmlBody = htmlBody.replace('{Coveredcedingcompany}', strCovCedCom);
                    htmlSubject = htmlSubject.replace('{CedingCompanyName}', strCovCedCom);
                
                    String strCommentResponse = saReq.CommentsResponse__c != null ? saReq.CommentsResponse__c : '';
                    String commentStrDesigned = '<b style="color:blue";><font face="Arial" size="50px">' + strCommentResponse + '</font></b>'; //RRA - ticket 1382 - 1912202
                    htmlBody = htmlBody.replace('{Comments}', commentStrDesigned); //RRA - ticket 1382 - 1912202
                    
                    System.debug('htmlBody == ' + htmlBody);

                    mail.setHtmlBody(htmlBody);
                    mail.setSubject(htmlSubject);
                    lstMailsToSend.add(mail);
                    System.debug('lstMailsToSend == ' + lstMailsToSend);
                }                
            }

            if(lstMailsToSend.size() > 0){
                Messaging.sendEmail((List<Messaging.Email>) lstMailsToSend);
            }

            mapResults.put('Success', 'Success');
            System.debug('mail send successfully');
        }
        catch(Exception ex) {
            Database.rollback(sp);
            mapResults.put('Error', ex.getMessage());
        }
        return mapResults;
    }

    public class OptionWrapper implements Comparable{
        @AuraEnabled
        public String label {get; set;}
        @AuraEnabled
        public String value {get; set;}

        public OptionWrapper(String label, String value){
            this.label = label;
            this.value = value;
        }

        public Integer compareTo(Object compareTo){
            OptionWrapper optWrapper = (OptionWrapper) compareTo;
            if (label == optWrapper.label) return 0;
            if (label > optWrapper.label) return 1;
            return -1;
        }
    }
}