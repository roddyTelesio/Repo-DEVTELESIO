/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 06-16-2022
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public without sharing class LWC48_CopySpecialAcceptance {
    /**************************************************************************************
    -- - Author        : Spoon Consulting
    -- - Description   : Controller for Lightning Web Component lwc48CopySpecialAcceptance
    --
    -- Maintenance History:
    --
    -- Date         Name  Version  Remarks
    -- -----------  ----  -------  -------------------------------------------------------
    -- 09-OCT-2020  MBE   1.0      Initial version
    -- 23-APR-2021  MBE   1.1      W-0962 - Special Acceptance - message bloquant au Load Placement table
    -- 08-JUN-2021  MBE   1.2      W-0985 - Special Acceptance - Le SA ID sur de la mêm SA n'est pas unique d'un portail à un autre
    -- 13-JUN-2021  MBE   1.3      W-0894 - ODS - TECH_SentByUser__c seems empty after a modification of a lead request
    -- 05-AUG-2021  MBE   1.4      W-1005 - Special Acceptance - Filtrer les SA sur le portail Cédante afin qu'il ne voit pas les SA des autres cédantes d'un programme régional
    -- 17-AUG-2021  MBE   1.5      W-1013 - Special Acceptance - Bind Response Emails      
    -- 23-AUG-2021  MBE   1.6      W-0977 - Special Acceptance - Bug copie au niveau des infos inform ceding companies
    -- 27-AUG-2021  MBE   1.7      Remove unused value for mapResult
    -- 19-OCT-2021  MBE   1.8      W-1034 - tailles limite de documents envoyés
    -- 09-NOV-2021  MBE   1.9      W-1037 - remove renderedStoredEmailTemplate from Loop
    -- 21-DEC-2021  MBE   2.0      W-0932 - Transversal - Ne pas proposer des utilisateurs inactifs
    --------------------------------------------------------------------------------------
    **************************************************************************************/
    
        /**
        * @description Method to get Special Acceptance Details
        * @param String String specialAcceptanceId, Boolean isCE
        * @return Map<String, Object>
        */
        @AuraEnabled
        public static Map<String, Object> getSADetail(String specialAcceptanceId, Boolean isCE, Boolean isRenew){
            Map<String, Object> mapResults = new Map<String, Object>();
            Map<String, Decimal> mapRateByCurrencyLabel = new Map<String, Decimal>();
            Map<String, Id> mapRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectRequest}); 
            List<String> lstRequestFields = AP_Constant.getCreatableFieldsByObjName(AP_Constant.sObjectRequest);
            List<String> lstSAFields = AP_Constant.getCreatableFieldsByObjName(AP_Constant.sObjectSpecialAcceptance);
            List<ContentVersion> lstContentVersions = new List<ContentVersion>();
            List<ContentVersion> lstContentVersionsBRPortal = new List<ContentVersion>();
            List<Request__c> lstSARequest = new List<Request__c>();
            List<Request__c> lstClosedSigningReq = new List<Request__c>();
            String recordSigningTypeId = mapRecTypeId.get(AP_Constant.reqRTSigning);
            String strSAFields = String.join(lstSAFields , ', ');
            String strRequestFields = String.join(lstRequestFields, ', ');
            String statusSetup = AP_Constant.statusSetup;
            String programId;
            Set<Id> setContentDocumentId = new Set<Id>();
            Program__c renewedProgram = new Program__c();
            Integer uwy;
            String uwYear;
            String strTotalInseredValue;
            Decimal decTotalInseredValue;
            Decimal convertStrToDecTotalInseredValue;
            List<SpecialAcceptance__c> lstSpecSA = new List<SpecialAcceptance__c>();
            
    
            String querySA = 'select Id, Program__r.UwYear__c, Program__r.PrincipalCedingCompany__c, Program__r.Nature__c, SpaDurationDays__c, Program__r.Name, '
                    + strSAFields
                    + ' from SpecialAcceptance__c where (Id = :specialAcceptanceId) ORDER BY SpecialAcceptanceName__c asc ' ;//RRA - 1086
    
            List<SpecialAcceptance__c> lstSpecialAcceptance = Database.query(querySA);
    
            if(lstSpecialAcceptance.size() > 0){
                //RRA - ticket 1996 - 08042024
                if (isRenew){
                    uwy = Integer.valueOf(lstSpecialAcceptance[0].Program__r.UwYear__c) + 1;
                    uwYear = String.valueOf(uwy);
                }else{
                    uwYear = lstSpecialAcceptance[0].Program__r.UwYear__c;
                }
                programId = lstSpecialAcceptance[0].Program__c;
                
                /*for (SpecialAcceptance__c sa : lstSpecialAcceptance){
                    decTotalInseredValue = sa.TotalInsuredValue__c;
                    strTotalInseredValue = LWC20_LeadRequests.separateurMillier(decTotalInseredValue).replace(',',' ');
                    convertStrToDecTotalInseredValue = Decimal.valueOf(strTotalInseredValue);
                    sa.TotalInsuredValue__c = convertStrToDecTotalInseredValue;
                    lstSpecSA.add(sa);
                }
                
                if (lstSpecSA.size()>0){
                    update lstSpecSA;
                }*/
                
                System.debug('specialAcceptanceId == ' + specialAcceptanceId);
                System.debug('uwYear == ' + uwYear);
                System.debug('programId == ' + programId);
    
                for(FXRate__c fxRate : [SELECT Id, toLabel(Currency__c), FX_Rate__c FROM FXRate__c WHERE UW_Year__c = :uwYear]){
                    if(!mapRateByCurrencyLabel.containsKey(fxRate.Currency__c)){
                        mapRateByCurrencyLabel.put(fxRate.Currency__c, fxRate.FX_Rate__c);
                    }
                }
                System.debug('mapRateByCurrencyLabel == ' + mapRateByCurrencyLabel);
                
                for(ContentDocumentLink contentDocLink : [SELECT Id, ContentDocumentId
                                                          FROM ContentDocumentLink
                                                          WHERE LinkedEntityId = :specialAcceptanceId]){
                    setContentDocumentId.add(contentDocLink.ContentDocumentId);
                }
    
                //Remove VersionData, PathOnClient in Query
    
                for(ContentVersion cv : [SELECT Id, VersionData, PathOnClient, Phase__c, Title, IsExternal__c, ContentDocumentId
                                                , Nature__c, FileType, FileExtension, ContentUrl, ContentSize
                                                , FirstPublishLocationId, SpecialAcceptance__c
                                         FROM ContentVersion
                                         WHERE ContentDocumentId IN :setContentDocumentId]){
                    if(cv.IsExternal__c == true){
                        //Broker/Reinsurer Portal
                        lstContentVersionsBRPortal.add(cv);
                    }
                    else{
                        lstContentVersions.add(cv);
                    }
                }
    
                //RRA - ticket 1537 - 31072023
                List<Program__c> lstRenewedProgram = [SELECT Id, Name, UwYear__c, PrincipalCedingCompany__c, RenewedFromProgram__c, InceptionDate__c, Expirydate__c FROM Program__c WHERE RenewedFromProgram__c = :programId LIMIT 1];
    
                if(lstRenewedProgram.size() > 0){
                    renewedProgram = lstRenewedProgram[0];
                }
    
                lstClosedSigningReq = [SELECT Id, Name, SigningStatus__c FROM Request__c WHERE SigningStatus__c = :AP_Constant.statusRequestClosed AND RecordTypeId =:recordSigningTypeId AND Program__c = :programId];
            }
            
            Set<String> setKeySAType = new Set<String>();
            String statusInternal = null;
            List<SpecialAcceptance__c> lstSA = new List<SpecialAcceptance__c>();
              //RRA - ticket 1509 - 17052023
            Map<Id,Request__c> mapKeySATypeGlobal = new Map<Id, Request__c>();
            Map<Id,String> mapIdPoolReinsStrSAType = new Map<Id, String>();
            Boolean isSubmission = false; 
            Boolean isGoTo = false;
            Boolean allRequestIsNotSent = false;
            Boolean allRequestIsNotAgreed = false;
            Boolean isSentOperating = false;
            Boolean isAgreedOperating = false;
            List<String> lstStringStatusRequest = new List<String>();
    
            if(specialAcceptanceId != null){
                String querySaRequest = 'SELECT Id, TECH_TreatyName__c, Treaty__r.PlacementShare_Perc__c, TECH_BrokerName__c, TECH_IsBrokerPresent__c, TECH_ReinsurerName__c, TECH_Layer__c, TECH_UWyear__c,  SigningRegionalManager__r.Email '
                        + ', RiskCarrier__r.Name, FinancialEntity__r.Name, Program__r.LossDepositMode__c, Program__r.LossDeposit__c '
                        + ', Treaty__r.LossDepositMode__c, Treaty__r.LossDeposit__c, Treaty__r.Deductions__c, TreatyReference__c, Treaty__r.TypeofTreaty__c, Program__r.UwYear__c '
                        + ', Treaty__r.PremiumDeposit__c, Program__r.LossDepositLevel__c, Pool__r.Name, Pool__r.AssignedTo__r.Email, Pool__r.AssignedTo__c, Pool__r.SA_Email__c, Program__r.Name, program__r.principalcedingcompany__r.Name, Program__r.PrincipalCedingCompany__c '
                        + ', Special_Acceptance__r.SpecialAcceptanceName__c, Special_Acceptance__r.CoveredCedingCompany__r.Name, '
                        +  strRequestFields
                        + ' from Request__c where (Special_Acceptance__c = :specialAcceptanceId) AND ((LastVersionSent__c = TRUE AND LastVersionAnswered__c = TRUE) OR (SA_Request_Status__c = :statusSetup)) ORDER BY Special_Acceptance__r.SpecialAcceptanceName__c asc'; //RRA - 1086';
    
                lstSARequest = Database.query(querySaRequest);
            }
            
            //RRA - ticket 1509 - 17052023
            //Step 1 : Ordering priority Setup / Refused / Timeout / Sent / Agreed the field SA_Request_Status__c of Request
            for (Request__c request : [SELECT Id, RiskCarrier__c, Pool__c, Special_Acceptance__r.Type__c, SA_Request_Status__c, SA_Type__c, Special_Acceptance__c FROM Request__c WHERE Special_Acceptance__c =:specialAcceptanceId AND (LastVersionSent__c = TRUE AND LastVersionAnswered__c = TRUE) ORDER BY TECH_OrderStatusRequest__c]) {
                if (request.Special_Acceptance__r.Type__c == '2'){ 
                    lstStringStatusRequest.add(request.SA_Request_Status__c);
                }else if (request.Special_Acceptance__r.Type__c == '1'){
                    statusInternal = AP_Constant.statusAgreed;
                    isGoTo = true;
                }
            }
            System.debug('lstStringStatusRequest == ' +lstStringStatusRequest);
            //Step 2: Looping on the string SA_Request_Status__c
            if (lstStringStatusRequest.size() > 0){
                for (String strStatusReq : lstStringStatusRequest){
                    if (strStatusReq != null){
                        System.debug('strStatusReq == ' +strStatusReq);
                        if (strStatusReq.contains(AP_Constant.statusSetup)){
                            statusInternal = AP_Constant.statusPending;
                            isGoTo = true;
                            break;
                        }else if (strStatusReq.contains(AP_Constant.statusRefused)){
                            isGoTo = true;
                            statusInternal = AP_Constant.statusRefused;
                            break;
                        }else if (strStatusReq.contains(AP_Constant.statusTimeout)){
                            isGoTo = true;
                            statusInternal = AP_Constant.statusTimeout;
                            break;
                        }else if (strStatusReq.contains(AP_Constant.statusSent)){
                            isSentOperating = true;
                        }else if (strStatusReq.contains(AP_Constant.statusAgreed)){
                            isAgreedOperating = true;
                        }
                    }
                }
                
                System.debug('isSentOperating == ' +isSentOperating);
                
                //Check if Status contains Sent
                if (isSentOperating){
                    String firstLoopSent = lstStringStatusRequest[0];
                    for(String nextLoopSent: lstStringStatusRequest){
                        if(firstLoopSent != nextLoopSent){
                            allRequestIsNotSent = true;
                        } 
                    }
                    if (allRequestIsNotSent == false){
                        isGoTo = true;
                        statusInternal = AP_Constant.statusSent;
                    }
                }

                System.debug('isAgreedOperating == ' +isAgreedOperating);
                
                //Check if Status contains Agreed
                if (isAgreedOperating){
                    String firstLoopAgreed = lstStringStatusRequest[0];
                    for(String nextLoopAgreed: lstStringStatusRequest){
                        if(firstLoopAgreed != nextLoopAgreed){
                            allRequestIsNotAgreed = true;
                        } 
                    }
                    
                    if (allRequestIsNotAgreed == false){
                        isGoTo = true;
                        statusInternal = AP_Constant.statusAgreed;
                    }
                }
                
                //Check if Status Agreed and Sent are blend => update statusInternal to Sent
                if (allRequestIsNotAgreed && allRequestIsNotSent){
                    isGoTo = true;
                    statusInternal = AP_Constant.statusSent;
                }
            }
            
            System.debug('lstStringStatusRequest == ' +lstStringStatusRequest);
            System.debug('allRequestIsNotSent == ' +allRequestIsNotSent);
            System.debug('allRequestIsNotAgreed == ' +allRequestIsNotAgreed);
            System.debug('statusInternal == ' +statusInternal);
            System.debug('isGoTo == ' +isGoTo);
            
            //RRA - ticket 1509 - 17052023
            if (isGoTo){
                SpecialAcceptance__c spa = [SELECT Id, InternalStatus__c  FROM SpecialAcceptance__c WHERE Id =: specialAcceptanceId];
                if (spa != null  && statusInternal != null){
                    spa.InternalStatus__c = statusInternal;
                    lstSA.add(spa);
                }
                System.debug('lstSA lwc49== ' +lstSA);
                if (lstSA.size()>0){
                    update lstSA;
                }
            }
    
            Profile profileObj = [select Id, Name from Profile where Id =: UserInfo.getProfileId()];
            
            mapResults.put('lstSpecialAcceptance', lstSpecialAcceptance);
            mapResults.put('mapRateByCurrencyLabel', mapRateByCurrencyLabel);
            mapResults.put('lstContentVersions', lstContentVersions);
            mapResults.put('lstContentVersionsBRPortal', lstContentVersionsBRPortal);
            mapResults.put('renewedProgram', renewedProgram);
            mapResults.put('lstSARequest', lstSARequest);
            mapResults.put('lstClosedSigningReq', lstClosedSigningReq);
            mapResults.put('userProfile', profileObj.Name);
            mapResults.put('Success', 'Success');
            return mapResults;
        }
    
        /**
        * @description Method to get Program Details
        * @param String programId
        * @return Map<String, Object>
        */
        @AuraEnabled
        public static Map<String, Object> getProgramDetail(String programId, Boolean isCE){
            Map<String, Object> mapResults = new Map<String, Object>();
            Map<String, Id> mapAccountRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectAcc});
            List<OptionWrapper> lstCedingComp = new List<OptionWrapper>();
            List<Program__c> lstRenewedProgram = new List<Program__c>();
            String lastRefIndex = '';
    
            User usr = [SELECT Id, ContactId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            Id contactId = usr.ContactId;
            Id cedingAcc = null;
    
            List<Id> lstGroupIds = new List<Id>();
            List<String> lstReferentialIds = new List<String>();
            Set<Id> setAccCedingPublicGroup = new Set<Id>();
            Contact cedingContact = new Contact();
    
            if(contactId != null){
                cedingContact = [SELECT Id, AccountId FROM Contact WHERE Id = :contactId LIMIT 1];
    
                if(cedingContact != null && cedingContact.AccountId != null){
                    cedingAcc = cedingContact.AccountId;
                    setAccCedingPublicGroup.add(cedingContact.AccountId);
                }
            }
    
            for(GroupMember groupMemberRecord : [SELECT Id, GroupId FROM GroupMember WHERE UserOrGroupId = :UserInfo.getUserId()]){
                lstGroupIds.add(groupMemberRecord.GroupId);
            }
    
            for(Group groupRecord : [SELECT Id, DeveloperName FROM Group WHERE Id IN :lstGroupIds]){
                lstReferentialIds.add(groupRecord.DeveloperName);
            }
    
            for(Account account : [SELECT Id, Name, IsActive__c FROM Account WHERE TECH_ReferentialId__c IN :lstReferentialIds AND RecordTypeId = :mapAccountRecTypeId.get(AP_Constant.accRTCoveredCedingCompany)]){
                setAccCedingPublicGroup.add(account.Id);    
            }
    
            List<Program__c> lstProgram = [SELECT Id, Name, toLabel(Macro_L_O_B__c), InceptionDate__c, toLabel(Nature__c), PrincipalCedingCompany__r.Name, UwYear__c FROM Program__c WHERE Id = :programId];
    
            lstRenewedProgram = [SELECT Id, Name, InceptionDate__c, RenewedFromProgram__c FROM Program__c WHERE RenewedFromProgram__c = :programId];
    
            for(CoveredCedingCompany__c covCedCom : [SELECT Id, Account__r.Name FROM CoveredCedingCompany__c WHERE Program__c = :programId AND ProgramIsSelected__c = TRUE]){
                if(isCE == true){
                    lstCedingComp.add(new OptionWrapper(covCedCom.Account__r.Name, covCedCom.Account__c));
                }
                else if(setAccCedingPublicGroup.contains(covCedCom.Account__c)){
                    lstCedingComp.add(new OptionWrapper(covCedCom.Account__r.Name, covCedCom.Account__c));
                }
            }
    
            lstCedingComp.sort();
    
            // List<SpecialAcceptance__c> lstLastSpecialAcceptance = [SELECT Id, Name, Reference__c FROM SpecialAcceptance__c WHERE ((RenewedFromSpecialAcceptance__c = NULL) OR (RenewedFromSpecialAcceptance__c != NULL AND SentAgreFromSpecialAcceptance__c != NULL)) AND TECH_LocalSA__c = NULL ORDER BY CreatedDate  DESC LIMIT 1];
            List<SpecialAcceptance__c> lstLastSpecialAcceptance = [SELECT Id, Name, Reference__c, TECH_ReferenceIndex__c FROM SpecialAcceptance__c ORDER BY TECH_ReferenceIndex__c DESC LIMIT 1];
    
            if(lstLastSpecialAcceptance != null && lstLastSpecialAcceptance.size() > 0){
                if(lstLastSpecialAcceptance[0].Reference__c != null){
                    String refIndex = lstLastSpecialAcceptance[0].Reference__c.split('-')[2];
                    Decimal refIndexVal = Decimal.valueOf(refIndex) + 1;
                    lastRefIndex = (('0'.repeat(8))+refIndexVal).right(8);
                }
            }
            else{
                lastRefIndex = System.Label.SAReferenceIndex;
            }
           
            mapResults.put('lstProgram', lstProgram);
            mapResults.put('lastRefIndex', lastRefIndex);
            mapResults.put('lstCedingComp', lstCedingComp);
            mapResults.put('lstRenewedProgram', lstRenewedProgram);
            mapResults.put('Success', 'Success');
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
    
        /**
        * @description Method to get save Copy Special Acceptance
        * @param SpecialAcceptance__c specialAcceptanceObj, String programIdOfSelectedSA, Boolean copyDoc, String selectedSpecAccId, String actionBtnClick
        * @return Map<String, Object>
        */
        @AuraEnabled
        public static Map<String, Object> saveCopySpecialAcceptanceRecord(SpecialAcceptance__c specialAcceptanceObj, String programIdOfSelectedSA, Boolean copyDoc, String selectedSpecAccId, String actionBtnClick) {
            Map<String, Object> mapResults = new Map<String, Object>();
            List<Id> lstContentDocument = new List<Id>();
            List<ContentDocumentLink> lstContentDocumentLinkToInsert = new List<ContentDocumentLink>();
            List<ContentVersion> lstNewContentVersionToInsert = new List<ContentVersion>();
            List<ContentVersion> lstContentVersion = new List<ContentVersion>();
            Savepoint sp = Database.setSavepoint();
            String programId;
            Set<Id> setContentDocumentId = new Set<Id>();
                   
            try {
    
                if(specialAcceptanceObj != null){
                    programId = specialAcceptanceObj.Program__c;
                    specialAcceptanceObj.TECH_LocalSA__c = null;
                    specialAcceptanceObj.Bound__c = 'Pending';
                    specialAcceptanceObj.BindRemainingDays__c = null;
                    specialAcceptanceObj.AdditionalPremium__c = null;
                    specialAcceptanceObj.Rationale__c = null;
                    specialAcceptanceObj.ProposedToFac__c = null;
                    insert specialAcceptanceObj;
                }
    
                if(copyDoc == true){
                    for(ContentDocumentLink contentDocLink : [SELECT Id, ContentDocumentId
                                                              FROM ContentDocumentLink
                                                              WHERE LinkedEntityId = :selectedSpecAccId]){
                        setContentDocumentId.add(contentDocLink.ContentDocumentId);
                    }
    
                    if(setContentDocumentId.size() > 0){
                        lstContentVersion = [SELECT Id, Phase__c, Title, IsExternal__c, ContentDocumentId
                                                    , Nature__c, FileType, FileExtension, ContentUrl, ContentSize
                                                    , PathOnClient, VersionData, FirstPublishLocationId, SpecialAcceptance__c
                                             FROM ContentVersion
                                             WHERE ContentDocumentId IN :setContentDocumentId AND IsExternal__c = FALSE];
    
                        for(ContentVersion contentVersion : lstContentVersion){
                            ContentVersion newContentVersion = new ContentVersion();
                            newContentVersion.Title = contentVersion.Title;
                            newContentVersion.PathOnClient = contentVersion.PathOnClient;
                            newContentVersion.VersionData = contentVersion.VersionData;
                            newContentVersion.FirstPublishLocationId = contentVersion.FirstPublishLocationId;
                            newContentVersion.Nature__c = contentVersion.Nature__c;
                            newContentVersion.SpecialAcceptance__c = specialAcceptanceObj.Id;
                            newContentVersion.IsExternal__c = contentVersion.IsExternal__c;
                            lstNewContentVersionToInsert.add(newContentVersion);
                        }
                    }
    
                    if(lstNewContentVersionToInsert.size() > 0){
                        insert lstNewContentVersionToInsert;
    
                        for(ContentVersion cv : [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN :lstNewContentVersionToInsert]){
                            lstContentDocument.add(cv.ContentDocumentId);
                        }
    
                        for(Id contentDocumentId : lstContentDocument){
                            ContentDocumentLink cd = new ContentDocumentLink();
                            cd.LinkedEntityId = specialAcceptanceObj.Id;
                            cd.ContentDocumentId = contentDocumentId;
                            cd.Visibility = 'AllUsers';
                            cd.ShareType = 'V';
                            lstContentDocumentLinkToInsert.add(cd);
                        }
    
                        if(lstContentDocumentLinkToInsert.size() > 0){
                            insert lstContentDocumentLinkToInsert;
                        }
                    }
    
                    if(actionBtnClick == 'Submit'){
                        submitSpecialAcceptanceRecord(specialAcceptanceObj.Id);
                    }
    
                    mapResults.put('lstContentVersion', lstContentVersion);
                    mapResults.put('lstContentDocumentLinkToInsert', lstContentDocumentLinkToInsert);
                }
    
                mapResults.put('Success', 'Success');
            }catch (Exception ex) {
                Database.rollback(sp);
                mapResults.put('Error', ex.getMessage());
            }
            return mapResults;
        }
    
        /**
        * @description Method to get load placement table
        * @param SpecialAcceptance__c specialAcceptanceObj
        * @return Map<String, Object>
        */
        @AuraEnabled
        public static Map<String, Object> loadPlacementTable(SpecialAcceptance__c specialAcceptanceObj) {
            System.debug('loadPlacementTable START with ' + specialAcceptanceObj);
    
            Map<String, Object> mapResults = new Map<String, Object>();
            Map<String, Id> mapRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectRequest});
            String recordLeadTypeId = mapRecTypeId.get(AP_Constant.reqRTLead);
            String recordPlacementTypeId = mapRecTypeId.get(AP_Constant.reqRTPlacement);
            String recordSigningTypeId = mapRecTypeId.get(AP_Constant.reqRTSigning);
            String recordSATypeId = mapRecTypeId.get(AP_Constant.reqRTSA);
            List<String> lstRequestFields = AP_Constant.getCreatableFieldsByObjName(AP_Constant.sObjectRequest);
            List<Request__c> lstRequest = new List<Request__c>();
            List<Request__c> lstSARequestToInsert = new List<Request__c>();
            String strRequestFields = String.join(lstRequestFields , ', ');
            String programId;
            Set<String> setBrokReinPoolId = new Set<String>();
            Set <String> setIdPccIdUser = new  Set <String>();
            Map<String, Id> mapIdGroupIdSAPcc = new Map<String, Id>();
            List<Request__Share> lstRequestSAShare = new List<Request__Share>();
            List<SpecialAcceptance__Share> lstSAShare = new List<SpecialAcceptance__Share>();
            Map<String, Id> mapKeyIdSA = new  Map<String, Id> ();
            Map<String, Id> mapReqSAKey = new  Map<String, Id> ();
            Map<String, Id> mapIdPccIdSA = new  Map<String, Id> ();
            List<String> lstkeySASplit = new List<String>();
            List<String> lstkeySplitSA = new List<String>();
            String keySASharing;
            String keySAidReq;
            String keySharingSA;
            String keyidReqSA;
            Set<String> setKeySASharing = new Set<String>();
            Set<Id> setKeySAidReq = new Set<Id>();
            Set<String> setKeySharingSA = new Set<String>();
            Set<Id> setKeyidReqSA = new Set<Id>();
            Set <String> setIdSAIdUser = new  Set <String>();
            Set <String> setIdReqIdUserSA = new  Set <String>();
            Map <String, Id> mapPccIdReqId = new Map <String, Id>();
            List<String> lstkeySplitPCC = new List<String>();
            String keyPccSharing;
            String keyidPccReq;
            Set<String> setKeyPccSharing = new Set<String>();
            Set<Id> setKeyidPccReq = new Set<Id>();
            List<AccountShare> lstAccountShareToInsert =  new List<AccountShare>();

            Map<String, String> mapIdBrokerIdReinsurerReq = new  Map<String, String> (); //RRA - ticket 1488 - 12042023
            Map<String, String> mapIdBrokerReinsurerIdPCC = new  Map<String, String> ();//RRA - ticket 1488 - 12042023
            Map<String, String> mapIdUserIdPCC = new  Map<String, String> ();//RRA - ticket 1488 - 12042023 
            Map<String, String> mapIdUserIdSA = new  Map<String, String> ();//RRA - ticket 1488 - 12042023 
            Map<String, String> mapIdReinsurerIntObj = new  Map<String, String> ();
            Set <Id> setReinsurerIdsSigning = new Set<Id>();
            Map<Id,Id> mapReinsIdToParentIdSigning = new Map<Id,Id>();
            Map<Id,Id> mapBrokerReinsurerIdUser = new Map<Id,Id>();
            Map<Id,Id> mapIdSAqIdReq = new Map<Id,Id>();
            Map<String,Id> mapNamePCCSAId = new Map<String,Id>();
            Map<String,Id> mapIdGrpIdSAPcc = new Map<String,Id>();
            Map <Id, List<Id>> mapParentToRiskFinancialId = new Map<Id, List<Id>>();
            List<Id> lstReins = new List<Id>();
            Boolean isSleepingPartners = false;
            List<String> lstNewKeyInSigning = new List<String>();
            Set<String> setNewKeyInSigningReq = new Set<String>();
            Set<String> setKeyInSigning = new Set<String>();
            Set<String> setAccShare = new Set<String>();
            List<AccountShare> lstAccShare =  new List<AccountShare>();
            List<Request__Share> lstRequestShareSleepPart = new List<Request__Share>();

            Savepoint sp = Database.setSavepoint();       
    
            try {
                User connectedUser = [SELECT Id, Name, Email FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
    
                if(specialAcceptanceObj != null){
                    programId = specialAcceptanceObj.Program__c;
                    //RRA - ticket 1301 - 05122022
                    String queryRequest = 'select Id, KeyRequestSharing__c, PrincipalCedingCompany__c, TECH_RelatedLeadPlacementRequest__r.RecordTypeId,Pool__r.PoolTrackNumber__c, TECH_RelatedLeadPlacementRequest__r.Id, Program__r.InceptionDate__c, Program__r.PrincipalCedingCompany__c, '
                            + strRequestFields
                            + ' from Request__c where (Program__c = :programId AND RecordTypeId = :recordSigningTypeId AND ((LastVersionSent__c = TRUE AND LastVersionAnswered__c = TRUE)) AND SignedShare__c > 0) '; //16/06/2022 - AzharNahoor - W-1121 : Do not query request with SignedShare 0    
                            
                    lstRequest = Database.query(queryRequest);
    
                    //Get placement request leaders (or pools) for previous program
                    Map<String, Request__c> previousSAReqLeaders = getPreviousSAReq('Leader', specialAcceptanceObj.Id);
                    System.debug('loadPlacementTable previousSAReqLeaders ' + previousSAReqLeaders);
    
                    //Get placement request followers for previous program
                    Map<String, Request__c> previousSAReqFollowers = getPreviousSAReq('Follower', specialAcceptanceObj.Id);
                    System.debug('loadPlacementTable previousSAReqFollowers ' + previousSAReqFollowers);
    
                    for(Request__c req : lstRequest){
                        Request__c newRequest = req.clone(false, false, false, false);
                        newRequest.Id = null;
                        newRequest.RecordTypeId = recordSATypeId;
                        newRequest.Special_Acceptance__c = specialAcceptanceObj.Id;
                        newRequest.OriginalRequest__c = null;
                        newRequest.TECH_Actor2Id__c = null;
                        newRequest.VersionMajor__c = 0;
                        newRequest.VersionMinor__c = 0;
    
                        if(req.TECH_RelatedLeadPlacementRequest__r != null){
                            if(req.TECH_RelatedLeadPlacementRequest__r.RecordTypeId == recordPlacementTypeId){
                                newRequest.SA_Type__c = 'Follower';
                            }
                            else if(req.TECH_RelatedLeadPlacementRequest__r.RecordTypeId == recordLeadTypeId){
                                newRequest.SA_Type__c = 'Leader';
                            }
                        }
    
                        if(specialAcceptanceObj.Type__c == '1'){
                            //Declaration + Leader/Pool: requests status are set to agreed and all date to today date
                            //Declaration + Follower: requests status are set to setup and all date to null
                            String key = newRequest.Broker__c + '-' + newRequest.Reinsurer__c+ '-' + newRequest.Pool__r.PoolTrackNumber__c;// MRA 1281/1290 Hotfix
                            
                            if(newRequest.SA_Type__c == 'Follower'){ // Follower OR Pool // MRA 1281/1290 Hotfix
                                newRequest.SentBy__c = null;
                                newRequest.SA_Request_Status__c = AP_Constant.statusSetup;
                                //27/04/2022 Azhar Nahoor - W-1122 
                                if(previousSAReqFollowers == null){
                                    newRequest.LastSentDate__c         = null;
                                    newRequest.ExpectedResponseDate__c = null;
                                    newRequest.ResponseDate__c         = null; 
                                }else{
                                    System.debug('loadPlacementTable Follower SA Request "BrokerId-ReinsurerId" key ' + key);
                                    if(previousSAReqFollowers.containskey(key)){
                                        System.debug('loadPlacementTable Follower unchanged Broker: ' + newRequest.Broker__c + '/ Reinsurer: ' + newRequest.Reinsurer__c);
                                        newRequest.LastSentDate__c          = previousSAReqFollowers.get(key).LastSentDate__c;  
                                        newRequest.ExpectedResponseDate__c  = previousSAReqFollowers.get(key).ExpectedResponseDate__c;
                                        newRequest.ResponseDate__c          = previousSAReqFollowers.get(key).ResponseDate__c;
                                        newRequest.SA_Request_Status__c     = AP_Constant.statusNotified;
                                    }else{
                                        System.debug('loadPlacementTable Follower changed Broker: ' + newRequest.Broker__c + '/ Reinsurer: ' + newRequest.Reinsurer__c);
                                        newRequest.LastSentDate__c          = null;
                                        newRequest.ExpectedResponseDate__c  = null;
                                        newRequest.ResponseDate__c          = null;
                                    }
                                }
                            }
                            else{ //SA_Type is leader
                                newRequest.SentBy__c = connectedUser.Id;
                                newRequest.SA_Request_Status__c = AP_Constant.statusAgreed;
                                newRequest.SpecialAcceptanceAnswer__c = AP_Constant.statusAgree;
    
                                //27/04/2022 Azhar Nahoor - W-1081 - - Do not take today's date ; instead prefill with existing dates if leaders unchanged
                                if(previousSAReqLeaders == null){
                                    System.debug('loadPlacementTable Leader(or pool) Not renewal Context, set Inception date');
                                    newRequest.LastSentDate__c         = req.Program__r.InceptionDate__c;
                                    newRequest.ExpectedResponseDate__c = req.Program__r.InceptionDate__c;
                                    newRequest.ResponseDate__c         = req.Program__r.InceptionDate__c;
                                }else{
                                    System.debug('loadPlacementTable Leader(or pool) Renewal Context');
                                    System.debug('loadPlacementTable Leader(or pool) SA Request "BrokerId-ReinsurerId" key ' + key);
                                    System.debug('### MRA = ' + previousSAReqLeaders) ;
                                    if(previousSAReqLeaders.containskey(key)){
                                        System.debug('loadPlacementTable Leader(or pool) unchanged Broker: ' + newRequest.Broker__c + '/ Reinsurer: ' + newRequest.Reinsurer__c);
                                        newRequest.LastSentDate__c          = previousSAReqLeaders.get(key).LastSentDate__c;  
                                        newRequest.ExpectedResponseDate__c  = previousSAReqLeaders.get(key).ExpectedResponseDate__c;
                                        newRequest.ResponseDate__c          = previousSAReqLeaders.get(key).ResponseDate__c;
                                    }else{
                                        System.debug('loadPlacementTable Leader(or pool) changed Broker: ' + newRequest.Broker__c + '/ Reinsurer: ' + newRequest.Reinsurer__c);
                                        newRequest.LastSentDate__c          = req.Program__r.InceptionDate__c;
                                        newRequest.ExpectedResponseDate__c  = req.Program__r.InceptionDate__c;
                                        newRequest.ResponseDate__c          = req.Program__r.InceptionDate__c;
                                    }
                                }
                                System.debug('newRequest.SA_Type__c == '+ newRequest.SA_Type__c);
                            }
                            // MRA 1281/1290 Hotfix
                            if(!setBrokReinPoolId.contains(key)){
                                setBrokReinPoolId.add(key);
                                lstSARequestToInsert.add(newRequest);
                            }
                        }
                        else if(specialAcceptanceObj.Type__c == '2'){
                            //Submission : requests status are set to setup and all date to null
                            newRequest.SentBy__c = null;
                            newRequest.SA_Request_Status__c = AP_Constant.statusSetup;
                            newRequest.LastSentDate__c = null;
                            newRequest.ExpectedResponseDate__c = null;
                            newRequest.ResponseDate__c = null;
                            // MRA 1281/1290 Hotfix : START
                            String brokReinPoolStr = newRequest.Broker__c + '-' + newRequest.Reinsurer__c + '-' + newRequest.Pool__r.PoolTrackNumber__c;
                            if(!setBrokReinPoolId.contains(brokReinPoolStr)){
                                setBrokReinPoolId.add(brokReinPoolStr);
                                lstSARequestToInsert.add(newRequest);
                            }
                        }
                           // MRA 1281/1290 Hotfix : END
                    }
    
                    System.debug('lstSARequestToInsert == ' +lstSARequestToInsert);
                    if(lstSARequestToInsert.size() > 0){
                        insert lstSARequestToInsert;
                    }

                    //Visibility portail Reinsurer/Broker RRA - ticket 1301 - 05122022
                    //Visibility portail Broker RRA - ticket 1488 - 19042023
                    if (specialAcceptanceObj.Type__c == '1'){
                        for (Request__c req : lstSARequestToInsert){
                            if(req.SA_Request_Status__c =='Agreed' && req.Special_Acceptance__c == specialAcceptanceObj.Id){
                                System.debug('Begin visibility');
                                mapReqSAKey.put (req.KeyRequestSharing__c + '-' + req.Special_Acceptance__c, req.Special_Acceptance__c); //to share for SA
                                mapKeyIdSA.put (req.KeyRequestSharing__c + '-' + req.Id, req.Id); // to share for User for account
                                mapIdPccIdSA.put (req.PrincipalCedingCompany__c, req.Id); // to share for group
                                mapPccIdReqId.put (req.KeyRequestSharing__c + '-' +req.Id, req.Program__r.PrincipalCedingCompany__c);

                                if (req.Broker__c != null){
                                    if (req.BrokerStatus__c == '2'){ //financial intermediate
                                        isSleepingPartners  = false;
                                    }else if (req.BrokerStatus__c == '1'){ //sleeping partners
                                        lstReins.add(req.Reinsurer__c); // get reinsurer Attached on Broker
                                        isSleepingPartners = true;
                                    }
                                }
                            }
                        }
                        System.debug('lstReins == '+lstReins);

                        // Get key and Id Req for SA for sharing Request SA
                        for (String keySA : mapKeyIdSA.KeySet()){
                            lstkeySplitSA.add(keySA);
                        }

                        for (String key : mapPccIdReqId.KeySet()){
                            lstkeySplitPCC.add(key);
                        }

                        for (String keySAEllgible : lstkeySplitSA){
                            keySharingSA = keySAEllgible.split('-')[0];
                            keyidReqSA = keySAEllgible.split('-')[1];
                            setKeySharingSA.add(keySharingSA);
                            setKeyidReqSA.add(keyidReqSA);
                        }

                        for (String keyPccEllgible : lstkeySplitPCC){
                            keyPccSharing = keyPccEllgible.split('-')[0];
                            keyidPccReq = keyPccEllgible.split('-')[1];
                            setKeyPccSharing.add(keyPccSharing);
                            setKeyidPccReq.add(keyidPccReq);
                        }

                        System.debug('mapReqSAKey: ' +  mapReqSAKey);
                        System.debug('setKeyidPccReq: ' +  setKeyidPccReq);

                        // Get key and Id SA for sharing SA
                        for (String keySA : mapReqSAKey.KeySet()){
                            lstkeySASplit.add(keySA);
                        }

                        System.debug('lstkeySASplit: ' +  lstkeySASplit);

                        for (String keySAEllgible : lstkeySASplit){
                            keySASharing = keySAEllgible.split('-')[0];
                            keySAidReq = keySAEllgible.split('-')[1];
                            setKeySASharing.add(keySASharing);
                            setKeySAidReq.add(keySAidReq);
                        }

                        // Create map relation => to share PCC for SA 
                        if(mapIdPccIdSA != null ){
                            for(Group objGroup : [SELECT Id, Name FROM Group WHERE Name IN:mapIdPccIdSA.KeySet()]){
                                mapIdGroupIdSAPcc.put(objGroup.Name, objGroup.Id);
                            }
                        }

                        System.debug('isSleepingPartners: ' +  isSleepingPartners);

                        //RRA - ticket 1488 - 12042023  Create new Key attached on Reinsurer from Broker if BrolerStatus = '2' 
                        if (isSleepingPartners){
                            for (String strNewKeySA : setKeySASharing){
                                List<String> lstNewKeySASharing = strNewKeySA.split('_');
                                for (String reinsId : lstReins){
                                    if (reinsId != null){
                                        setNewKeyInSigningReq.add(lstNewKeySASharing.get(0) + '_' + reinsId  + '_' + lstNewKeySASharing.get(2) + '_' + lstNewKeySASharing.get(3));
                                    }                                    
                                }
                            }
                        }
                        System.debug('setNewKeyInSigningReq: ' +  setNewKeyInSigningReq);
                        System.debug('mapIdGroupIdSAPcc: ' +  mapIdGroupIdSAPcc);
                        System.debug('setKeySAidReq: ' +  setKeySAidReq);
                        System.debug('setKeySASharing 11: ' +  setKeySASharing);

                        //Create Set => SAShare to Share for User
                        if (setKeySASharing.size()>0 && setKeySASharing !=null){
                            if (isSleepingPartners){
                                for (IntermediateACRRequest__c keys : [SELECT Id, User__c, User__r.IsActive, SharingKeyFormula__c FROM IntermediateACRRequest__c WHERE SharingKeyFormula__c IN:setNewKeyInSigningReq]){
                                    //RRA - ticket 1488 - 18042023
                                    if (keys.User__r.IsActive){
                                        setIdSAIdUser.add(specialAcceptanceObj.Id  + '_' + keys.User__c);
                                    }
                                }
                                System.debug('ok  isSleepingPartners 11' );
                            }else {
                                for (Id idReqSA : setKeySAidReq){
                                    for (IntermediateACRRequest__c keys : [SELECT Id, User__c, User__r.IsActive, SharingKeyFormula__c FROM IntermediateACRRequest__c WHERE SharingKeyFormula__c IN:setKeySASharing]){
                                        //RRA - ticket 1488 - 18042023
                                        if (keys.User__r.IsActive){
                                            System.debug('mapReqSAKey result: ' +  mapReqSAKey.get(keys.SharingKeyFormula__c + '-' + idReqSA));
                                            if (mapReqSAKey.get(keys.SharingKeyFormula__c + '-' + idReqSA) != null){
                                                setIdSAIdUser.add(mapReqSAKey.get(keys.SharingKeyFormula__c + '-' + idReqSA)  + '_' + keys.User__c);
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    
                        System.debug('setIdSAIdUser: ' +  setIdSAIdUser);
                        System.debug('setKeySharingSA 22: ' +  setKeySharingSA);

                        //Create Set => RequestShare for SA to share for User
                        if (setKeySharingSA.size()>0 && setKeySharingSA !=null){
                            if (isSleepingPartners){
                                for (Id idSAReq : setKeyidReqSA){
                                    for (IntermediateACRRequest__c keys : [SELECT Id, User__c, User__r.IsActive, SharingKeyFormula__c FROM IntermediateACRRequest__c WHERE SharingKeyFormula__c IN:setNewKeyInSigningReq]){
                                        //RRA - ticket 1488 - 18042023
                                        if (keys.User__r.IsActive){
                                            setIdReqIdUserSA.add(idSAReq  + '_' + keys.User__c);
                                        }
                                    }
                                }
                            }else {
                                for (Id idSAReq : setKeyidReqSA){
                                    for (IntermediateACRRequest__c keys : [SELECT Id, User__c, User__r.IsActive, SharingKeyFormula__c FROM IntermediateACRRequest__c WHERE SharingKeyFormula__c IN:setKeySharingSA]){
                                        //RRA - ticket 1488 - 18042023
                                        if (keys.User__r.IsActive){
                                            if (mapKeyIdSA.get(keys.SharingKeyFormula__c + '-' + idSAReq) != null){
                                                setIdReqIdUserSA.add(mapKeyIdSA.get(keys.SharingKeyFormula__c + '-' + idSAReq)  + '_' + keys.User__c);
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Create Set => AccountShare
                        if (setKeyPccSharing.size()>0 && setKeyPccSharing !=null){

                            if (isSleepingPartners){
                                for (Id idReq : setKeyidPccReq){
                                    for (IntermediateACRRequest__c key : [SELECT Id, User__c, User__r.IsActive, SharingKeyFormula__c FROM IntermediateACRRequest__c WHERE SharingKeyFormula__c IN:setNewKeyInSigningReq]){
                                        if (key.User__r.IsActive){
                                                setIdPccIdUser.add(idReq  + '_' + key.User__c);
                                        }
                                    }
                                }
                                System.debug('ok  isSleepingPartners 33' );
                            }else {
                                for (Id idReq : setKeyidPccReq){
                                    for (IntermediateACRRequest__c key : [SELECT Id, User__c, User__r.IsActive, SharingKeyFormula__c FROM IntermediateACRRequest__c WHERE SharingKeyFormula__c IN:setKeyPccSharing]){
                                        //RRA - ticket 1488 - 18042023
                                        if (key.User__r.IsActive){
                                            if (mapPccIdReqId.get(key.SharingKeyFormula__c + '-' + idReq) != null){
                                                setIdPccIdUser.add(mapPccIdReqId.get(key.SharingKeyFormula__c + '-' + idReq)  + '_' + key.User__c);
                                            }
                                        }
                                    }
                                }
                            }
                        }
                   
                 
                        System.debug('setKeyidReqSA: ' +  setKeyidReqSA);
                        System.debug('setIdReqIdUserSA: ' +  setIdReqIdUserSA);
                        System.debug('setIdPccIdUser: ' +  setIdPccIdUser);


                        // Account Share for Pcc   => Treaty placement
                        for(String accString : setIdPccIdUser){
                            String idPcc = accString.split('_')[0];
                            String userIdPcc = accString.split('_')[1];
                            AccountShare accountShare = new AccountShare();
                            accountShare.AccountAccessLevel = 'Read';
                            accountShare.OpportunityAccessLevel = 'Read';
                            accountShare.AccountId = idPcc;
                            accountShare.UserOrGroupId = userIdPcc;
                            lstAccountShareToInsert.add(accountShare);
                        }

                        // Requesthare for SA (PCC)  => SA
                        for(String namePcc : mapIdGroupIdSAPcc.keySet()){
                            Request__Share requestShare = new Request__Share();
                            requestShare.RowCause = 'Manual';
                            requestShare.AccessLevel = 'Edit';
                            requestShare.ParentId = mapIdPccIdSA.get(namePcc);
                            requestShare.UserOrGroupId = mapIdGroupIdSAPcc.get(namePcc);
                            lstRequestSAShare.add(requestShare);
                        }

                        // SA Share 
                        for(String SAShare : setIdSAIdUser){
                            String reqSAId = SAShare.split('_')[0];
                            String userSAIdReq = SAShare.split('_')[1];
                            SpecialAcceptance__Share shareSA = new SpecialAcceptance__Share();
                            shareSA.RowCause = 'Manual';
                            shareSA.AccessLevel = 'Edit';
                            shareSA.ParentId = reqSAId;
                            shareSA.UserOrGroupId = userSAIdReq;
                            lstSAShare.add(shareSA);
                        }

                            // Requesthare for SA  => SA
                        for(String reqSAShare : setIdReqIdUserSA){
                            String reqIdSA = reqSAShare.split('_')[0];
                            String userIdReqSA = reqSAShare.split('_')[1];
                            Request__Share reqShare = new Request__Share();
                            reqShare.RowCause = 'Manual';
                            reqShare.AccessLevel = 'Edit';
                            reqShare.ParentId = reqIdSA;
                            reqShare.UserOrGroupId = userIdReqSA;
                            lstRequestShareSleepPart.add(reqShare);
                        }

                        System.debug('Request SA Share lstAccountShareToInsert ==  ' + lstAccountShareToInsert);

                        if(lstAccountShareToInsert.size() > 0){
                            System.debug('loadPlacementTable__lstAccountShareToInsert ==  ' + lstAccountShareToInsert);
                            System.debug('shareAccoutToUsers: inserting AccountShare List with ' + lstAccountShareToInsert.size() + ' elements');
                            AP38_CreateSharingForRequest.Manage_DataBaseInsertSharing_UTL util = new  AP38_CreateSharingForRequest.Manage_DataBaseInsertSharing_UTL();
                            util.insertAccountShares(lstAccountShareToInsert);
                            System.debug('Account Share  List inserted Successfully for Pcc');
                        }

                        System.debug('Request SA Share lstRequestSAShare ==  ' + lstRequestSAShare);

                        if(lstRequestSAShare.size() > 0){
                            System.debug('shareSARequestToUsers: inserting lstRequestSAShare SA List with ' + lstRequestSAShare.size() + ' elements');
                            AP38_CreateSharingForRequest.Manage_DataBaseInsertSharing_UTL util = new AP38_CreateSharingForRequest.Manage_DataBaseInsertSharing_UTL();
                            util.insertRequestShares(lstRequestSAShare);
                            System.debug('Request SA lstRequestSAShare inserted Successfully ');
                        }
                        System.debug('loadPlacementTable__lstRequestShareSleepPart ==  ' + lstRequestShareSleepPart);

                        if(lstRequestShareSleepPart.size() > 0){
                            System.debug('shareSARequestToUsers: inserting lstRequestShareSleepPart SA List with ' + lstRequestShareSleepPart.size() + ' elements');
                            AP38_CreateSharingForRequest.Manage_DataBaseInsertSharing_UTL util = new AP38_CreateSharingForRequest.Manage_DataBaseInsertSharing_UTL();
                            util.insertRequestShares(lstRequestShareSleepPart);
                            System.debug('Request SA lstRequestShareSleepPart inserted Successfully ');

                        }

                        System.debug('Request SA Share lstSAShare ==  ' + lstSAShare);
                    
                        if(lstSAShare.size() > 0){
                            System.debug('shareSAToUsers: inserting SA_RequestShare List with ' + lstSAShare.size() + ' elements');
                            AP38_CreateSharingForRequest.Manage_DataBaseInsertSharing_UTL util = new AP38_CreateSharingForRequest.Manage_DataBaseInsertSharing_UTL();
                            util.insertSAShares(lstSAShare);
                            System.debug('SA Share  List inserted Successfully ');
                        }

                        if(specialAcceptanceObj.Type__c == '1'){
                        //Declaration : set internal sa to agreed
                        specialAcceptanceObj.InternalStatus__c = AP_Constant.statusAgreed;
                        }
        
                        if(specialAcceptanceObj != null){
                            update specialAcceptanceObj;
                        }
                    }
            }
                
    
                mapResults.put('Success', 'Success');
            }catch(Exception ex) {
                Database.rollback(sp);
                System.debug('loadPlacementTable Exception occured: ' + ex.getMessage());
                mapResults.put('Error', ex.getMessage());
            }
    
    
            System.debug('loadPlacementTable END with ' + mapResults);
    
            return mapResults;
        }
    
        /**
        * @description Method to return list of SA requests (Follower or leader) for previous 
        *              program (if it exist)
        * @param SAId      (Renewed) Special acceptance
        * @param SAReqType Follower or leader
        * @return Map<String, Requests> Key : "BrokerId-ReinsurerId" and Value is SA Request
        */
        public static Map<String, Request__c> getPreviousSAReq(String SAReqType, String SAId){
            System.debug(LoggingLevel.DEBUG, 'getPreviousSAReq START with ' + SAId +' for ' + SAReqType);
            Map<String, Request__c> prevSAReqs = new Map<String, Request__c>();
    
            //Get original SA (RenewedFromSpecialAcceptance__c)
            SpecialAcceptance__c SA = [
                SELECT Id, RenewedFromSpecialAcceptance__c 
                FROM SpecialAcceptance__c 
                WHERE id =: SAId
                LIMIT 1
            ];
    
            if(SA.RenewedFromSpecialAcceptance__c == null){
                System.debug(LoggingLevel.DEBUG, 'getPreviousSAReq Special Acceptance is not a renewal, return empty list');
                return null;
            }
            
            //Get request leaders/followers of original program
            for(Request__c req : [  SELECT Id, Broker__c , Reinsurer__c, LastSentDate__c,Pool__r.PoolTrackNumber__c, ExpectedResponseDate__c, ResponseDate__c, Pool__c,SA_Type__c, SA_Request_Status__c
                                    FROM   Request__c
                                    WHERE  Special_Acceptance__c = :SA.RenewedFromSpecialAcceptance__c 
                                    AND    (SA_Type__c = :SAReqType OR SA_Type__c = Null)]){

                    if(req.SA_Type__c != 'Follower' || (req.SA_Type__c == 'Follower' && req.SA_Request_Status__c == AP_Constant.statusNotified) ){
                        prevSAReqs.put(req.Broker__c + '-' + req.Reinsurer__c + '-' + req.Pool__r.PoolTrackNumber__c, req);
                        System.debug('### MRA = ' + req.Broker__c + '-' + req.Reinsurer__c + '-' + req.Pool__r.PoolTrackNumber__c);
                    }
            }
            System.debug(LoggingLevel.DEBUG, 'getPreviousSAReq END with ' + prevSAReqs);
    
            return prevSAReqs;
        }
    
    
        /**
        * @description Method to get save Renew Special Acceptance
        * @param SpecialAcceptance__c specialAcceptanceObj, String programIdOfSelectedSA, List<ContentVersion> lstDocumentToUpdate, List<Id> lstDeletedDocument, List<ContentVersion> lstDocumentToInsert, String actionBtnClick
        * @return Map<String, Object>
        */
        @AuraEnabled
        public static Map<String, Object> saveRenewSpecialAcceptanceRecord(SpecialAcceptance__c specialAcceptanceObj, String programIdOfSelectedSA, List<ContentVersion> lstDocumentToUpdate, List<Id> lstDeletedDocument, List<ContentVersion> lstDocumentToInsert, String actionBtnClick) {
            Map<String, Object> mapResults = new Map<String, Object>();
            Map<Id, String> mapNatureByContentVersionId = new Map<Id, String>();
            List<ContentVersion> lstNewContentVersionToInsert = new List<ContentVersion>();
            List<ContentDocumentLink> lstContentDocumentLinkToInsert = new List<ContentDocumentLink>();
            List<Id> lstContentDocument = new List<Id>();
            Id renewedProgramId;
            Savepoint sp = Database.setSavepoint();
    
            try {
                List<Program__c> lstRenewedProgram = [SELECT Id, Name, UwYear__c, PrincipalCedingCompany__c, RenewedFromProgram__c FROM Program__c WHERE RenewedFromProgram__c = :programIdOfSelectedSA LIMIT 1];
                
                if(lstRenewedProgram.size() > 0){
                    renewedProgramId = lstRenewedProgram[0].Id;
                }
    
                if(specialAcceptanceObj != null){
                    specialAcceptanceObj.Program__c = renewedProgramId;
                    specialAcceptanceObj.TECH_LocalSA__c = null;
                    specialAcceptanceObj.Bound__c = 'Pending';
                    insert specialAcceptanceObj;
                }
    
                if(lstDocumentToUpdate.size() > 0){
                    for(ContentVersion contentVersion : lstDocumentToUpdate){
                        contentVersion.SpecialAcceptance__c = specialAcceptanceObj.Id;
                        lstContentDocument.add(contentVersion.ContentDocumentId);
                    }
                    update lstDocumentToUpdate;
                }
    
                if(lstDeletedDocument.size() > 0) {
                    Set<Id> setContentDocumentId = new Set<Id>();
    
                    for(ContentVersion contentVersion : [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN :lstDeletedDocument]) {
                        setContentDocumentId.add(contentVersion.ContentDocumentId);
                    }
    
                    if(setContentDocumentId.size() > 0){
                        List<ContentDocument> lstContentDoc = [SELECT Id FROM ContentDocument WHERE Id IN :setContentDocumentId];
    
                        if(lstContentDoc.size() > 0) {
                            delete lstContentDoc;
                        }
                    }
                }
    
                if(lstDocumentToInsert.size() > 0){
                    List<ContentVersion> lstExistingContentVersion = [SELECT Id, Phase__c, Title, IsExternal__c, ContentDocumentId
                                                                            , Nature__c, FileType, FileExtension, ContentUrl, ContentSize
                                                                            , PathOnClient, VersionData, FirstPublishLocationId, SpecialAcceptance__c
                                                                      FROM ContentVersion
                                                                      WHERE Id IN :lstDocumentToInsert AND IsExternal__c = FALSE];
    
                    for(ContentVersion contentVersion : lstDocumentToInsert){
                        if(contentVersion.Nature__c != null){
                            mapNatureByContentVersionId.put(contentVersion.Id, contentVersion.Nature__c);
                        }
                    }
    
                    for(ContentVersion contentVersion : lstExistingContentVersion){
                        ContentVersion newContentVersion = new ContentVersion();
                        newContentVersion.Title = contentVersion.Title;
                        newContentVersion.PathOnClient = contentVersion.PathOnClient;
                        newContentVersion.VersionData = contentVersion.VersionData;
                        newContentVersion.FirstPublishLocationId = contentVersion.FirstPublishLocationId;
                        newContentVersion.SpecialAcceptance__c = specialAcceptanceObj.Id;
                        newContentVersion.IsExternal__c = contentVersion.IsExternal__c;
    
                        if(mapNatureByContentVersionId.containsKey(contentVersion.Id)){
                            newContentVersion.Nature__c = mapNatureByContentVersionId.get(contentVersion.Id);
                        }
                        lstNewContentVersionToInsert.add(newContentVersion);
                    }
    
                    if(lstNewContentVersionToInsert.size() > 0) {
                        insert lstNewContentVersionToInsert;
    
                        for(ContentVersion cv : [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN :lstNewContentVersionToInsert]){
                            lstContentDocument.add(cv.ContentDocumentId);
                        }
                    }
                }
    
                for(Id contentDocumentId : lstContentDocument){
                    ContentDocumentLink cd = new ContentDocumentLink();
                    cd.LinkedEntityId = specialAcceptanceObj.Id;
                    cd.ContentDocumentId = contentDocumentId;
                    cd.Visibility = 'AllUsers';
                    cd.ShareType = 'V';
                    lstContentDocumentLinkToInsert.add(cd);
                }
    
                if(lstContentDocumentLinkToInsert.size() > 0){
                    insert lstContentDocumentLinkToInsert;
                }
    
                if(actionBtnClick == 'Submit'){
                    submitSpecialAcceptanceRecord(specialAcceptanceObj.Id);
                }
    
                mapResults.put('Success', 'Success');
            }catch (Exception ex) {
                Database.rollback(sp);
                mapResults.put('Error', ex.getMessage());
            }
            return mapResults;
        }
    
        /**
       * @description Method to get update Special Acceptance
       * @param SpecialAcceptance__c specialAcceptanceObj, List<ContentVersion> lstDocumentToUpdate, List<Id> lstDeletedDocument, String actionBtnClick
       * @return Map<String, Object>
       */
        @AuraEnabled
        public static Map<String, Object> saveEditSpecialAcceptanceRecord(SpecialAcceptance__c specialAcceptanceObj, List<ContentVersion> lstDocumentToUpdate, List<Id> lstDeletedDocument, String actionBtnClick, List<Request__c> lstRequest, Boolean isCE) {
            Map<String, Object> mapResults = new Map<String, Object>();
            Savepoint sp = Database.setSavepoint();
            List<Id> lstContentDocument = new List<Id>();
            List<ContentVersion> lstContentVersionToUpdate = new List<ContentVersion>();
            List<ContentDocumentLink> lstContentDocumentLinkToInsert = new List<ContentDocumentLink>();
            List<ContentDocumentLink> lstContentDocumentLinkToDelete = new List<ContentDocumentLink>();
            List<SpecialAcceptance__c> lstCedingPortalSa = new List<SpecialAcceptance__c>();
            List<SpecialAcceptance__c> lstCeSa = new List<SpecialAcceptance__c>();
            List<SpecialAcceptance__c> lstGroupCoverSa = new List<SpecialAcceptance__c>();
            List<SpecialAcceptance__c> lstSABeforeSave = new List<SpecialAcceptance__c>();
            List<Request__c> lstAllVersionRequest = new List<Request__c>();
            Map<Id, Request__c> mapRequestDetailById = new Map<Id, Request__c>();
            Boolean isOriginalSABoundYes = false;
            Boolean isSendEmail = false; //RRA - ticket 1447 - 20032023
    
            try {
    
                lstSABeforeSave = [SELECT Id, Name, Bound__c FROM SpecialAcceptance__c WHERE Id = :specialAcceptanceObj.Id];
    
                if(lstSABeforeSave[0].Bound__c == '1'){
                    //Original SA Bound was 'Yes'
                    isOriginalSABoundYes = true;
                }
                else{
                    //Original SA Bound was not 'Yes' -> it was 'No' or 'Pending'
                    isOriginalSABoundYes = false;
                }
    
                if(lstRequest.size() > 0){
                    update lstRequest;
    
                    if(isCE == true){
                        //to find all version for the request and align all changes made
                        // Follower -> Follower as leader : Agree
                        // Follower as leader -> Follower : Setup
    
                        for(Request__c req : lstRequest){
                            if(req.OriginalRequest__c != null){
                                mapRequestDetailById.put(req.OriginalRequest__c, req);
                            }
                            else{
                                mapRequestDetailById.put(req.Id, req);
                            }
                        }
    
                        if(mapRequestDetailById.size() > 0){
                            lstAllVersionRequest = [SELECT Id, OriginalRequest__c, BrokerStatus__c, LastSentDate__c
                                                        ,ExpectedResponseDate__c, ResponseDate__c, SA_Request_Status__c, SpecialAcceptanceAnswer__c
                                                    FROM Request__c
                                                    WHERE Id IN :mapRequestDetailById.keySet() OR OriginalRequest__c IN :mapRequestDetailById.keySet()];
                        }
    
                        for(Request__c reqToUpdate : lstAllVersionRequest){
                            Request__c request = new Request__c();
    
                            if(reqToUpdate.OriginalRequest__c == null && mapRequestDetailById.containsKey(reqToUpdate.Id)){
                                request = mapRequestDetailById.get(reqToUpdate.Id);                    
                            }
                            else if(reqToUpdate.OriginalRequest__c != null && mapRequestDetailById.containsKey(reqToUpdate.OriginalRequest__c)){
                                request = mapRequestDetailById.get(reqToUpdate.Id);
                            }
                            else if(reqToUpdate.OriginalRequest__c != null && mapRequestDetailById.containsKey(reqToUpdate.Id)){
                                request = mapRequestDetailById.get(reqToUpdate.Id);
                            }
    
                            if(request != null){
                                reqToUpdate.LastSentDate__c = request.LastSentDate__c;
                                reqToUpdate.ExpectedResponseDate__c = request.ExpectedResponseDate__c;
                                reqToUpdate.ResponseDate__c = request.ResponseDate__c;
                                reqToUpdate.BrokerStatus__c = request.BrokerStatus__c;
                                reqToUpdate.SA_Request_Status__c = request.SA_Request_Status__c;
                                reqToUpdate.SpecialAcceptanceAnswer__c = request.SpecialAcceptanceAnswer__c;
                            }                  
                        }
    
                        if(lstAllVersionRequest.size() > 0){
                            update lstAllVersionRequest;
                        }
                    }
                }
    
                
                if(isCE == true){
                    //Internal CE
                    //Ceding Portal SA: Query SA which has Id = SentAgreFromSpecialAcceptance__c of specialAcceptanceObj
                    //CE Group Cover SA: Query SA which has TECH_LocalSA__c of specialAcceptanceObj
    
                    SpecialAcceptance__c selectedSa = [SELECT SentAgreFromSpecialAcceptance__c FROM SpecialAcceptance__c WHERE Id = :specialAcceptanceObj.Id];
    
                    if(selectedSa.SentAgreFromSpecialAcceptance__c != null){
                        lstCedingPortalSa = [SELECT Id, Bound__c, SentAgreFromSpecialAcceptance__c 
                                             FROM SpecialAcceptance__c
                                             WHERE Id = :selectedSa.SentAgreFromSpecialAcceptance__c];
    
                        for(SpecialAcceptance__c cedingPortalSa : lstCedingPortalSa){
                            if(specialAcceptanceObj.Bound__c != null){
                                cedingPortalSa.Bound__c = specialAcceptanceObj.Bound__c;
                            }  
                        }
    
                        if(lstCedingPortalSa.size() > 0){
                            update lstCedingPortalSa;
                        }
                    }
    
                    lstGroupCoverSa = [SELECT Id, Bound__c, SentAgreFromSpecialAcceptance__c, TECH_LocalSA__c
                                       FROM SpecialAcceptance__c
                                       WHERE TECH_LocalSA__c = :specialAcceptanceObj.Id];
    
                    for(SpecialAcceptance__c groupCoverSa : lstGroupCoverSa){
                        if(specialAcceptanceObj.Bound__c != null){
                            groupCoverSa.Bound__c = specialAcceptanceObj.Bound__c;
                        }  
                    }
    
                    if(lstGroupCoverSa.size() > 0){
                        update lstGroupCoverSa;
                    }
                }
                else{
                    //Ceding Portal
                    //CE SA: Query SA which has SentAgreFromSpecialAcceptance__c = Id of specialAcceptanceObj
                    //CE Group Cover SA: Query SA which has TECH_LocalSA__c = Id of CE SA
    
                    lstCeSa = [SELECT Id, Bound__c, SentAgreFromSpecialAcceptance__c 
                               FROM SpecialAcceptance__c
                               WHERE SentAgreFromSpecialAcceptance__c = :specialAcceptanceObj.Id];
    
                    for(SpecialAcceptance__c ceSa : lstCeSa){
                        if(specialAcceptanceObj.Bound__c != null){
                            ceSa.Bound__c = specialAcceptanceObj.Bound__c;
                        }  
                    }
    
                    if(lstCeSa.size() > 0){
                        update lstCeSa;
    
                        lstGroupCoverSa = [SELECT Id, Bound__c, SentAgreFromSpecialAcceptance__c, TECH_LocalSA__c
                                       FROM SpecialAcceptance__c
                                       WHERE TECH_LocalSA__c IN :lstCeSa];
    
                        for(SpecialAcceptance__c groupCoverSa : lstGroupCoverSa){
                            if(specialAcceptanceObj.Bound__c != null){
                                groupCoverSa.Bound__c = specialAcceptanceObj.Bound__c;
                            }  
                        }
    
                        if(lstGroupCoverSa.size() > 0){
                            update lstGroupCoverSa;
                        }
                    }
                }

                //RRA - ticket 1453 - 13032023
                if(specialAcceptanceObj != null){
                    update specialAcceptanceObj;
                }            
    
    
                for(ContentVersion contentVersion : lstDocumentToUpdate){
                    ContentVersion contentVersionToUpdate = new ContentVersion();
                    contentVersionToUpdate.Id = contentVersion.Id;
                    contentVersionToUpdate.SpecialAcceptance__c = specialAcceptanceObj.Id;
                    contentVersionToUpdate.Nature__c = contentVersion.Nature__c;
                    lstContentVersionToUpdate.add(contentVersionToUpdate);
                    lstContentDocument.add(contentVersion.ContentDocumentId);
                }
    
                if(lstContentVersionToUpdate.size() > 0){
                    update lstContentVersionToUpdate;
    
                    lstContentDocumentLinkToDelete = [SELECT Id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :specialAcceptanceObj.Id AND ContentDocumentId IN :lstContentDocument];
    
                    if(lstContentDocumentLinkToDelete.size() > 0){
                        delete lstContentDocumentLinkToDelete;
                    }
    
                    for(Id contentDocumentId : lstContentDocument){
                        ContentDocumentLink cd = new ContentDocumentLink();
                        cd.LinkedEntityId = specialAcceptanceObj.Id;
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
    
                if(actionBtnClick == 'Submit'){
                    submitSpecialAcceptanceRecord(specialAcceptanceObj.Id);
                }
    
                if(actionBtnClick == 'send' || actionBtnClick == 'update' || actionBtnClick == 'remind' || actionBtnClick == 'notify'){
                    isSendEmail = true; //RRA - ticket 1447 - 20032023
                }else if (actionBtnClick == 'informCedingCompany'){
                    isSendEmail = false; //RRA - ticket 1447 - 20032023
                }

                //RRA - ticket 1447 - 20032023
                if (isSendEmail){
                    if(isOriginalSABoundYes == false && specialAcceptanceObj.Bound__c == '1'){
                        //to send Bind Email
                        bindSA(specialAcceptanceObj, isCE);
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
        * @description Method to get submit Special Acceptance
        * @param SpecialAcceptance__c specialAcceptanceObj
        * @return Map<String, Object>
        */
        @AuraEnabled
        public static Map<String, Object> submitSpecialAcceptanceRecord(Id specialAcceptanceId){
            Map<String, Object> mapResults = new Map<String, Object>();
            Savepoint sp = Database.setSavepoint();
            SpecialAcceptance__c specialAcceptanceNewClone = new SpecialAcceptance__c();
            SpecialAcceptance__c specialAcceptanceCloneExisted = new SpecialAcceptance__c();
            List<ContentVersion> lstNewContentVersionToInsert = new List<ContentVersion>();
            List<ContentVersion> lstContentVersion = new List<ContentVersion>();
            List<Account> lstPCCAccount = new List<Account>();
            List<SpecialAcceptance__c> lstLastSpecialAcceptance = new List<SpecialAcceptance__c>();
            List<Id> lstContentDocument = new List<Id>();
            List<ContentDocumentLink> lstContentDocumentLinkToInsert = new List<ContentDocumentLink>();
            List<String> lstSaPCCEmailsToSend = new List<String>();
            Set<Id> setContentDocumentId = new Set<Id>();
            String lastRefIndex = '';
            String programId;
            String pccId;
            String strLstSaPCCEmail;
            String strLstSaPCCEmailDisplay;
    
            try {
                //send email to PCC of the program to which the SA is linked
                //change portal status to 'Submitted'
                //to clone record + set portal status = null + set internal status = 'Setup'
                //to clone document
    
                List<String> lstSAFields = AP_Constant.getCreatableFieldsByObjName(AP_Constant.sObjectSpecialAcceptance);
                String strSAFields = String.join(lstSAFields , ', ');
    
                String querySA = 'select Id, Program__r.UwYear__c, Program__r.PrincipalCedingCompany__c, Program__r.Nature__c, SpaDurationDays__c, Program__r.Name, CoveredCedingCompany__r.Name, Program__r.PrincipalCedingCompany__r.Name, '
                        + strSAFields
                        + ' from SpecialAcceptance__c where (Id = :specialAcceptanceId) ' ;
    
                List<SpecialAcceptance__c> lstSpecialAcceptance = Database.query(querySA);

                System.debug('lstSpecialAcceptance == ' + lstSpecialAcceptance);
    
                lstLastSpecialAcceptance = [SELECT Id, Name, Reference__c, TECH_ReferenceIndex__c FROM SpecialAcceptance__c ORDER BY TECH_ReferenceIndex__c DESC LIMIT 1];
    
                if(lstSpecialAcceptance.size() > 0){
                    programId = lstSpecialAcceptance[0].Program__c;
                    pccId = lstSpecialAcceptance[0].Program__r.PrincipalCedingCompany__c;
                    specialAcceptanceCloneExisted = lstSpecialAcceptance[0];
                    specialAcceptanceCloneExisted.PortalStatus__c = AP_Constant.statusSubmittedToAgre;
                    String newReference;
    
                    if(lstSpecialAcceptance[0].Reference__c != null){
                        String[] refOldIndex = lstSpecialAcceptance[0].Reference__c.split('-');
                        newReference = refOldIndex[0] + '-' + refOldIndex[1] + '-' + refOldIndex[2];
                    }
    
                    specialAcceptanceNewClone = specialAcceptanceCloneExisted.clone(false, false, false, false);
                    specialAcceptanceNewClone.Id = null;
                    specialAcceptanceNewClone.TECH_Actor2Id__c = null;
                    specialAcceptanceNewClone.PortalStatus__c = null;
                    specialAcceptanceNewClone.InternalStatus__c = 'Setup';
                    specialAcceptanceNewClone.SentAgreFromSpecialAcceptance__c = specialAcceptanceId;
                    specialAcceptanceNewClone.Reference__c = newReference;
                    specialAcceptanceNewClone.TECH_LocalSA__c = null;
                }
    
                System.debug('specialAcceptanceCloneExisted == ' + specialAcceptanceCloneExisted);

                try{
                    if(specialAcceptanceCloneExisted != null){
                        update specialAcceptanceCloneExisted;
                    }
                }catch (Exception ex) {
                    System.debug('Error Message RRA == ' + ex.getMessage());
                }
                
    
                if(specialAcceptanceNewClone != null){
                    insert specialAcceptanceNewClone;
                }
    
                for(ContentDocumentLink contentDocLink : [SELECT Id, ContentDocumentId
                                                          FROM ContentDocumentLink
                                                          WHERE LinkedEntityId = :specialAcceptanceId]){
                    setContentDocumentId.add(contentDocLink.ContentDocumentId);
                }
    
                if(setContentDocumentId.size() > 0){
                    lstContentVersion = [SELECT Id, Phase__c, Title, IsExternal__c, ContentDocumentId
                                                , Nature__c, FileType, FileExtension, ContentUrl, ContentSize
                                                , PathOnClient, VersionData, FirstPublishLocationId, SpecialAcceptance__c
                                         FROM ContentVersion
                                         WHERE ContentDocumentId IN :setContentDocumentId];
    
    
                    for(ContentVersion contentVersion : lstContentVersion){
                        ContentVersion newContentVersion = new ContentVersion();
                        newContentVersion.Title = contentVersion.Title;
                        newContentVersion.PathOnClient = contentVersion.PathOnClient;
                        newContentVersion.VersionData = contentVersion.VersionData;
                        newContentVersion.FirstPublishLocationId = contentVersion.FirstPublishLocationId;
                        newContentVersion.Nature__c = contentVersion.Nature__c;
                        newContentVersion.SpecialAcceptance__c = specialAcceptanceNewClone.Id;
                        newContentVersion.IsExternal__c = contentVersion.IsExternal__c;
                        lstNewContentVersionToInsert.add(newContentVersion);
                    }
    
                    if(lstNewContentVersionToInsert.size() > 0) {
                        insert lstNewContentVersionToInsert;
    
                        for(ContentVersion cv : [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN :lstNewContentVersionToInsert]){
                            lstContentDocument.add(cv.ContentDocumentId);
                        }
    
                        for(Id contentDocumentId : lstContentDocument){
                            ContentDocumentLink cd = new ContentDocumentLink();
                            cd.LinkedEntityId = specialAcceptanceNewClone.Id;
                            cd.ContentDocumentId = contentDocumentId;
                            cd.Visibility = 'AllUsers';
                            cd.ShareType = 'V';
                            lstContentDocumentLinkToInsert.add(cd);
                        }
    
                        if(lstContentDocumentLinkToInsert.size() > 0){
                            insert lstContentDocumentLinkToInsert;
                        }
                    }
                }
    
                //send email to PCC of the program to which the SA is linked
    
                if(pccId != null){
                    lstPCCAccount = [SELECT Id, Name, EmailSA__c FROM Account WHERE Id = :pccId LIMIT 1];
                    strLstSaPCCEmail = lstPCCAccount[0].EmailSA__c;
    
                    if(strLstSaPCCEmail != null ){
                        if(strLstSaPCCEmail.contains(';')){
                            lstSaPCCEmailsToSend = strLstSaPCCEmail.split(';');
                        }
                        else{
                            lstSaPCCEmailsToSend.add(strLstSaPCCEmail);
                        }
                    }
    
                    for(String pccEmail : lstSaPCCEmailsToSend){
                        if(strLstSaPCCEmailDisplay == null){
                            strLstSaPCCEmailDisplay = pccEmail;
                        }
                        else{
                            strLstSaPCCEmailDisplay = strLstSaPCCEmailDisplay + ' ' + pccEmail;   
                        }
                    }
                }
    
                Id emailTempSASubmitId;
                String emailTempSASubmit = AP_Constant.emailTemplateSpecialAcceptanceSubmitToAGRE;
                List<Messaging.SingleEmailMessage> lstMailsToSend =  new List<Messaging.SingleEmailMessage>();
               
                List<EmailTemplate> lstEmailTempSASubmit= [SELECT Id, Name FROM EmailTemplate WHERE Name = :emailTempSASubmit];
                emailTempSASubmitId = lstEmailTempSASubmit[0].Id;
    
                Messaging.SingleEmailMessage m;
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                List<String> lstEmailsToSend = new List<String>();
                Id userId = UserInfo.getUserId();
    
                if(lstSaPCCEmailsToSend.size() > 0){
                    m = Messaging.renderStoredEmailTemplate(emailTempSASubmitId, userId,null);
                    m.setSaveAsActivity(false);
                    mail.setToAddresses(lstSaPCCEmailsToSend);
    
                    if(lstSaPCCEmailsToSend.size() > 0){
                        mail.setCcAddresses(lstSaPCCEmailsToSend);
                    }
                    
                    mail.setReplyTo(UserInfo.getUserEmail());
                    mail.setSenderDisplayName(UserInfo.getFirstName() + ' ' + UserInfo.getLastName());
    
                    String htmlBody = m.htmlBody;
                    String htmlSubject = m.getSubject();
                    String url = String.valueOf(System.URL.getOrgDomainUrl().toExternalForm());
                    String htmlInternetLink = '<a href="' + url + '/lightning/page/home">ACTOR NewGen Page</a>';
                    String urlLoadSARequest = '/lightning/n/LoadSARequest?s__id='+specialAcceptanceNewClone.Id+'-'+specialAcceptanceNewClone.Program__r.UwYear__c+'-'+pccId+'-'+specialAcceptanceNewClone.Program__c;
                    String urlLoadSARequestLink = '<a href="' + url + urlLoadSARequest + '">Link</a>';
    
                    if(specialAcceptanceCloneExisted != null){
                        htmlBody = htmlBody.replace('{U/W Year}', specialAcceptanceCloneExisted.Program__r.UwYear__c);
                        htmlBody = htmlBody.replace('{Coveredcedingcompany}', specialAcceptanceCloneExisted.CoveredCedingCompany__r.Name);
                        htmlBody = htmlBody.replace('{Programname}', specialAcceptanceCloneExisted.Program__r.Name);
                        htmlBody = htmlBody.replace('{SAname}', specialAcceptanceCloneExisted.SpecialAcceptanceName__c);
                        htmlBody = htmlBody.replace('{pccEmail}',  UserInfo.getUserEmail());  //connected covered ceding user email
                        htmlBody = htmlBody.replace('[URL]', urlLoadSARequestLink);
                        htmlBody = htmlBody.replace('{ActorNewGenURL}', htmlInternetLink);
                        htmlSubject = htmlSubject.replace('{ProgramName}', specialAcceptanceCloneExisted.Program__r.Name);  
                        htmlSubject = htmlSubject.replace('{CedingCompanyName}', specialAcceptanceCloneExisted.CoveredCedingCompany__r.Name);  
                    }
    
                    mail.setHtmlBody(htmlBody);
                    mail.setSubject(htmlSubject);
                    lstMailsToSend.add(mail);
    
                    if(lstMailsToSend.size() > 0){
                        Messaging.sendEmail((List<Messaging.Email>) lstMailsToSend);
                    }
    
                    mapResults.put('Success', 'Success');
                    mapResults.put('url', url); 
                    mapResults.put('specialAcceptanceCloneExisted', specialAcceptanceCloneExisted);
                }
    
            }catch (Exception ex) {
                Database.rollback(sp);
                mapResults.put('Error', ex.getMessage());
            }
            return mapResults;
        }
    
       /**
       * @description Method to Get Content Version for Document
       * @param List<Id> lstContentDocumentId
       * @return List<ContentVersion>
       */
        @AuraEnabled(Cacheable = true)
        public static List<ContentVersion> getContentVersionId(List<Id> lstContentDocumentId) {
            List<ContentVersion> lstContentVersion = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE ContentDocumentId IN :lstContentDocumentId];
            return lstContentVersion;
        }
    
        /**
        * @description Method to Save Documents
        * @param List<ContentVersion> lstContentVersion
        * @return Map<String, Object>
        */
        @AuraEnabled
        public static Map<String, Object> saveDocuments(List<ContentVersion> lstContentVersion) {
            Map<String, Object> mapResults = new Map<String, Object>();
    
            try {
                if(lstContentVersion.size() > 0){
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
        * @description Method to delete Placement table
        * @param Id specialAcceptanceId
        * @return Map<String, Object>
        */
        @AuraEnabled
        public static Map<String, Object> deletePlacementTable(Id specialAcceptanceId) {
            Map<String, Object> mapResults = new Map<String, Object>();
            List<Request__c> lstSaRequest = new List<Request__c>();
            List<SpecialAcceptance__c> lstSaCeInternal = new List<SpecialAcceptance__c>();
            List<SpecialAcceptance__c> lstSaToUpdate = new List<SpecialAcceptance__c>();
            Savepoint sp = Database.setSavepoint();
    
            try {
                lstSaRequest = [SELECT Id, name FROM Request__c WHERE Special_Acceptance__c = :specialAcceptanceId];
    
                if(lstSaRequest.size() > 0){
                    delete lstSaRequest;
                }
                
                //Internal CE - InternalStatus__c = 'Setup'
                //Ceding Portal - PortalStatus__c = 'Submitted To Agre'
    
                lstSaCeInternal = [SELECT Id, InternalStatus__c, PortalStatus__c, SentAgreFromSpecialAcceptance__c FROM SpecialAcceptance__c WHERE Id = :specialAcceptanceId LIMIT 1];
    
                if(lstSaCeInternal.size() > 0){
                    SpecialAcceptance__c saCeInternal = new SpecialAcceptance__c();
                    saCeInternal.Id = lstSaCeInternal[0].Id;
                    saCeInternal.InternalStatus__c = AP_Constant.statusSetup;
                    lstSaToUpdate.add(saCeInternal);
    
                    if(lstSaCeInternal[0].SentAgreFromSpecialAcceptance__c != null){
                        SpecialAcceptance__c saCedingPortal = new SpecialAcceptance__c();
                        saCedingPortal.Id = lstSaCeInternal[0].SentAgreFromSpecialAcceptance__c;
                        saCedingPortal.PortalStatus__c = AP_Constant.statusSubmittedToAgre;
                        lstSaToUpdate.add(saCedingPortal);
                    }
                }
    
                if(lstSaToUpdate.size() > 0){
                    update lstSaToUpdate;
                }
    
                mapResults.put('Success', 'Success');
            }
            catch (Exception ex) {
                Database.rollback(sp);
                mapResults.put('Error', ex.getMessage());
            }
            return mapResults;
        }
    
        /**
        * @description Method to bind selected Special Acceptances
        * @param List<Id> lstSpecialAcceptanceId
        * @return Map<String, Object>
        */
        @AuraEnabled
        public static Map<String, Object> bindSA(SpecialAcceptance__c selectedSpecialAcceptance, Boolean isUserCE){
            Map<String, Object> mapResults = new Map<String, Object>();
            Map<String, Id> mapEmailTempIdByName = new Map<String, Id>();
            Map<Id, Id> mapIntCeSaByCedingPortalSa = new Map<Id, Id>();
            Map<Id, List<Request__c>> mapPoolReqBySaId = new Map<Id, List<Request__c>>();
            List<Messaging.SingleEmailMessage> lstMailsToSend =  new List<Messaging.SingleEmailMessage>();
            List<SpecialAcceptance__c> lstSaPCCEmail = new List<SpecialAcceptance__c>();
            List<SpecialAcceptance__c> lstSaCovCedContactEmail = new List<SpecialAcceptance__c>();
            List<SpecialAcceptance__c> lstSABRPoolEmailToSend = new List<SpecialAcceptance__c>();
            List<SpecialAcceptance__c> lstSelectedSpecialAcceptance = new List<SpecialAcceptance__c>();
            List<String> lstEmailTemplateName = new List<String>();
            List<Request__c> lstAllRequests = new List<Request__c>();
            List<Request__c> lstAllRequestBR = new List<Request__c>();
            String statusSetup = AP_Constant.statusSetup;
            Savepoint sp = Database.setSavepoint();
    
            try{
                Network networkObjPortal = [SELECT Id
                                      FROM Network
                                      WHERE Name =: System.Label.Actor_portal_name];
    
                String urlPortal = Network.getLoginUrl(networkObjPortal.Id);
                List <String> urlArrPortal = urlPortal.split('login');
                Id userId = UserInfo.getUserId();
    
                lstEmailTemplateName = new List<String>{AP_Constant.emailTempSaBindCedComPccSaEmail
                                                       ,AP_Constant.emailTempSaBindCedComBroker
                                                       ,AP_Constant.emailTempSaBindCedComReinsurer
                                                       ,AP_Constant.emailTempSaBindInternalCovCedCon
                                                       ,AP_Constant.emailTempSaBindInternalBroker
                                                       ,AP_Constant.emailTempSaBindInternalReinsurer};
    
                for(EmailTemplate emailTemp: [SELECT Id, Name FROM EmailTemplate WHERE Name IN : lstEmailTemplateName]){
                    mapEmailTempIdByName.put(emailTemp.Name, emailTemp.Id);
                }
    
                Messaging.SingleEmailMessage emailTempSaBindCedComPccSaEmail = new Messaging.SingleEmailMessage();       
                emailTempSaBindCedComPccSaEmail = Messaging.renderStoredEmailTemplate(mapEmailTempIdByName.get(AP_Constant.emailTempSaBindCedComPccSaEmail), userId, null);
    
                Messaging.SingleEmailMessage emailTempSaBindCedComBroker = new Messaging.SingleEmailMessage();       
                emailTempSaBindCedComBroker = Messaging.renderStoredEmailTemplate(mapEmailTempIdByName.get(AP_Constant.emailTempSaBindCedComBroker), userId, null);
    
                Messaging.SingleEmailMessage emailTempSaBindCedComReinsurer = new Messaging.SingleEmailMessage();       
                emailTempSaBindCedComReinsurer = Messaging.renderStoredEmailTemplate(mapEmailTempIdByName.get(AP_Constant.emailTempSaBindCedComReinsurer), userId, null);
    
                Messaging.SingleEmailMessage emailTempSaBindInternalCovCedCon = new Messaging.SingleEmailMessage();       
                emailTempSaBindInternalCovCedCon = Messaging.renderStoredEmailTemplate(mapEmailTempIdByName.get(AP_Constant.emailTempSaBindInternalCovCedCon), userId, null);
    
                Messaging.SingleEmailMessage emailTempSaBindInternalBroker = new Messaging.SingleEmailMessage();       
                emailTempSaBindInternalBroker = Messaging.renderStoredEmailTemplate(mapEmailTempIdByName.get(AP_Constant.emailTempSaBindInternalBroker), userId, null);
    
                Messaging.SingleEmailMessage emailTempSaBindInternalReinsurer = new Messaging.SingleEmailMessage();       
                emailTempSaBindInternalReinsurer = Messaging.renderStoredEmailTemplate(mapEmailTempIdByName.get(AP_Constant.emailTempSaBindInternalReinsurer), userId, null);
    
                lstSelectedSpecialAcceptance = [SELECT Id, SentAgreFromSpecialAcceptance__r.SpecialAcceptanceName__c, Bound__c, Comments__c, SpecialAcceptanceName__c
                                                        , PrincipalCedingCompany__r.EmailSA__c, PrincipalCedingCompany__r.Name, TECH_LocalSA__c
                                                        , Program__r.Name, Program__r.UwYear__c, CoveredCedingCompany__r.Name
                                                FROM SpecialAcceptance__c 
                                                WHERE Id = :selectedSpecialAcceptance.Id];
    
                if(isUserCE == true){
                    //Internal CE
                    //Send email alert to Covered Ceding Contact of Internal Ce + Group Cover
                    //Send email alert to Broker/Reinsurer/Pool of SA Internal Ce + Group Cover Sa
    
                    Map<Id, SpecialAcceptance__c> mapSaCovCedConBySaId = new Map<Id, SpecialAcceptance__c>();
    
                    for(SpecialAcceptance__c internalCeSa : lstSelectedSpecialAcceptance){
                        lstSaCovCedContactEmail.add(internalCeSA); //to send Email to CCC Contact
                        mapSaCovCedConBySaId.put(internalCeSA.Id, internalCeSA);
                        lstSABRPoolEmailToSend.add(internalCeSa); //to send Email to Pool/Broker/Reinsurer
                    }
    
                    List<SpecialAcceptance__c> lstGroupCoverSaInternalCe = new List<SpecialAcceptance__c>();
    
                    if(lstSelectedSpecialAcceptance.size() > 0){                    
                        //Get group cover sa of internal ce sa 
                        lstGroupCoverSaInternalCe = [SELECT Id, SentAgreFromSpecialAcceptance__r.SpecialAcceptanceName__c, Bound__c, Comments__c, SpecialAcceptanceName__c
                                                            , PrincipalCedingCompany__r.EmailSA__c, PrincipalCedingCompany__r.Name, TECH_LocalSA__c
                                                            , Program__r.Name, Program__r.UwYear__c, CoveredCedingCompany__r.Name
                                                     FROM SpecialAcceptance__c 
                                                     WHERE TECH_LocalSA__c IN :lstSelectedSpecialAcceptance];
    
                        for(SpecialAcceptance__c groupCoverSa : lstGroupCoverSaInternalCe){
                            lstSaCovCedContactEmail.add(groupCoverSa);
                            mapSaCovCedConBySaId.put(groupCoverSa.Id, groupCoverSa);
                            lstSABRPoolEmailToSend.add(groupCoverSa);
                        }
                    }
    
                    //Send email alert to Covered Ceding Contact of Internal Ce + Group Cover
                    //Build map of SA, list of covered ceding contact
    
                    Map<Id, List<AccountContactRelation>> mapLstCovCedConBySaId = new Map<Id, List<AccountContactRelation>>();
                    mapLstCovCedConBySaId = getCovCedContact(lstSaCovCedContactEmail);
    
                    Network networkObj = [SELECT Id
                                          FROM Network
                                          WHERE Name =: System.Label.Actor_ceding_portal_name];
    
                    String url = Network.getLoginUrl(networkObj.Id);
                    List<String> urlArr = url.split('login');
                    
                    for(Id saId : mapLstCovCedConBySaId.keySet()) {
                        List<AccountContactRelation> lstCovAccCont = mapLstCovCedConBySaId.get(saId);
                        SpecialAcceptance__c sa = mapSaCovCedConBySaId.get(saId);
    
                        for(AccountContactRelation covCedCon : lstCovAccCont){
                            Messaging.SingleEmailMessage m = new Messaging.SingleEmailMessage();
                            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                            List<String> lstEmailsToSend = new List<String>();
                            Id emailTempSaBindInternalCovCedConEmailId = mapEmailTempIdByName.get(AP_Constant.emailTempSaBindInternalCovCedCon);
                            String pccSaEmail = sa.PrincipalCedingCompany__r.EmailSA__c;
                            String email = covCedCon.Contact.Email;
                            String pccSaEmailDisplay = null;
                            List<String> lstSaPCCEmailsToSend = new List<String>();
                            // m = Messaging.renderStoredEmailTemplate(emailTempSaBindInternalCovCedConEmailId, userId, null);
    
                            m.setTemplateId(emailTempSaBindInternalCovCedConEmailId);
                            m.setTargetObjectId(userId);
                            // m.setWhatId(reqId);
                            m.setSaveAsActivity(false);
                            m.setSubject(emailTempSaBindInternalCovCedCon.getSubject());
                            m.setHtmlBody(emailTempSaBindInternalCovCedCon.htmlBody);
                            m.setSaveAsActivity(false);
    
                            if(pccSaEmail != null ){
                                if(pccSaEmail.contains(';')){
                                    lstSaPCCEmailsToSend = pccSaEmail.split(';');
                                }
                                else{
                                    lstSaPCCEmailsToSend.add(pccSaEmail);
                                }
                            }
    
                            for(String pccEmail : lstSaPCCEmailsToSend){
                                if(pccSaEmailDisplay == null){
                                    pccSaEmailDisplay = pccEmail;
                                }
                                else{
                                    pccSaEmailDisplay = pccSaEmailDisplay + ' ' + pccEmail;   
                                }
                            }
    
                            if(lstSaPCCEmailsToSend.size() > 0){
                                mail.setCcAddresses(lstSaPCCEmailsToSend);
                            }
    
                            lstEmailsToSend.add(email); //contact email
                            mail.setToAddresses(lstEmailsToSend);
                            mail.setReplyTo(UserInfo.getUserEmail());
                            mail.setSenderDisplayName(UserInfo.getFirstName() + ' ' + UserInfo.getLastName());
    
                            String htmlBody = m.htmlBody;
                            String htmlSubject = m.getSubject();
                            String saUrl = urlArr[0] + 'SADetail?s__id=' + sa.Id + '-' + sa.Program__r.UwYear__c + '-' + sa.PrincipalCedingCompany__c + '-' + sa.Program__c;
                            String saLink = '<a href="' + saUrl +'">Link of Special Acceptance</a>';
                            String htmlInternetLink = '<a href="' + urlArr[0] +'">ACTOR Page</a>';
    
                            htmlBody = htmlBody.replace('{U/W Year}', sa.Program__r.UwYear__c);
                            htmlBody = htmlBody.replace('{Programname}', sa.Program__r.Name);
                            htmlBody = htmlBody.replace('{SAname}', sa.SpecialAcceptanceName__c);        
    
                            String strPccSaEmailDisplay = pccSaEmailDisplay != null ? pccSaEmailDisplay : '';
                            htmlBody = htmlBody.replace('{SAEmailPCC}', strPccSaEmailDisplay);
                           
                            htmlBody = htmlBody.replace('[URLofTheSpecialAcceptance]', saLink);
                            htmlBody = htmlBody.replace('{ActorNewGenURL}', htmlInternetLink);
    
                            String strCCC = sa.CoveredCedingCompany__r != null ? sa.CoveredCedingCompany__r.Name : '';
                            htmlBody = htmlBody.replace('{Coveredcedingcompany}', strCCC);
                            htmlSubject = htmlSubject.replace('{CedingCompanyName}', strCCC);  
    
                            String strComment = sa.Comments__c != null ? sa.Comments__c : '';
                            String commentStrDesigned = '<b style="color:blue";><font face="Arial" size="50px">'+ strComment + '</font></b>'; //RRA - ticket 1382 - 1912202
                            htmlBody = htmlBody.replace('{Comments}', commentStrDesigned); //RRA - ticket 1382 - 1912202
                            htmlSubject = htmlSubject.replace('{ProgramName}', sa.Program__r.Name);  
    
                            mail.setHtmlBody(htmlBody);
                            mail.setSubject(htmlSubject);
                            lstMailsToSend.add(mail);
                        }
                    }
                }
                else{
                    //Ceding Portal
                    //Send email alert to SAEmail of PCC of SA Ceding + Group Cover
                    //Send email alert to Broker/Reinsurer/Pool of SA Internal Ce + Group Cover Sa 
    
                    User usr = [SELECT Id, ContactId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
                    Id contactId = usr.ContactId;
                    String covCedConEmail;
    
                    if(contactId != null){
                        Contact covCedContact = [SELECT Id, AccountId, Email FROM Contact WHERE Id = :contactId LIMIT 1];
                        covCedConEmail = covCedContact.Email;
                    }
    
                    for(SpecialAcceptance__c cedingPortalSa : lstSelectedSpecialAcceptance){
                        lstSaPCCEmail.add(cedingPortalSa);
                    }
    
                    //Build a map of Ceding Portal Sa, Internal Ce Sa -> mapIntCeSaByCedingPortalSa
                    //Get all Related Sa From Internal Ce (these sa is created upon 'Submit' button in Ceding Portal or 'New' in Internal Ce)
                    List<SpecialAcceptance__c> lstSaInternalCe = [SELECT Id, SentAgreFromSpecialAcceptance__r.SpecialAcceptanceName__c, Bound__c, Comments__c
                                                                         , PrincipalCedingCompany__r.EmailSA__c, PrincipalCedingCompany__r.Name, TECH_LocalSA__c
                                                                         , Program__r.Name, Program__r.UwYear__c, CoveredCedingCompany__r.Name
                                                                  FROM SpecialAcceptance__c 
                                                                  WHERE SentAgreFromSpecialAcceptance__c IN :lstSelectedSpecialAcceptance];
    
                    for(SpecialAcceptance__c internalCeSA : lstSaInternalCe){
                        mapIntCeSaByCedingPortalSa.put(internalCeSA.SentAgreFromSpecialAcceptance__c, internalCeSA.Id);
                        lstSABRPoolEmailToSend.add(internalCeSA);
                    }
    
                    List<SpecialAcceptance__c> lstGroupCoverSaInternalCe = new List<SpecialAcceptance__c>();
    
                    if(lstSaInternalCe.size() > 0){  
                        //Get group cover sa of internal ce sa 
                        lstGroupCoverSaInternalCe = [SELECT Id, SentAgreFromSpecialAcceptance__r.SpecialAcceptanceName__c, Bound__c, Comments__c, SpecialAcceptanceName__c
                                                            , PrincipalCedingCompany__r.EmailSA__c, PrincipalCedingCompany__r.Name, TECH_LocalSA__c
                                                            , Program__r.Name, Program__r.UwYear__c, CoveredCedingCompany__r.Name
                                                     FROM SpecialAcceptance__c 
                                                     WHERE TECH_LocalSA__c IN :lstSaInternalCe];
    
                        lstSaPCCEmail.addAll(lstGroupCoverSaInternalCe);
                    }
    
                    for(SpecialAcceptance__c groupCoverSa : lstGroupCoverSaInternalCe){
                        lstSABRPoolEmailToSend.add(groupCoverSa);
                    }
    
                    //Send email alert to SA Email of PCC for SA Ceding Portal + Group Cover SA
    
                    for(SpecialAcceptance__c sa : lstSaPCCEmail){
                        Messaging.SingleEmailMessage m = new Messaging.SingleEmailMessage();
                        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                        List<String> lstEmailsToSend = new List<String>();
                        List<String> lstLstPccSaEmail = new List<String>();
                        Id emailTempSaBindCedComPccSaEmailId = mapEmailTempIdByName.get(AP_Constant.emailTempSaBindCedComPccSaEmail);
                        String pccSaEmail = sa.PrincipalCedingCompany__r.EmailSA__c;
                        String pccSaEmailDisplay = null;
                        
                        if(pccSaEmail != null ){
                            if(pccSaEmail.contains(';')){
                                lstLstPccSaEmail = pccSaEmail.split(';');
                            }
                            else{
                                lstLstPccSaEmail.add(pccSaEmail);
                            }
                        }
    
                        for(String pccEmail : lstLstPccSaEmail){
                            if(pccSaEmailDisplay == null){
                                pccSaEmailDisplay = pccEmail;
                            }
                            else{
                                pccSaEmailDisplay = pccSaEmailDisplay + ' ' + pccEmail;   
                            }
                        }
    
                        if(lstLstPccSaEmail.size() > 0){
                            // m = Messaging.renderStoredEmailTemplate(emailTempSaBindCedComPccSaEmailId, userId, null);
                            m.setTemplateId(emailTempSaBindCedComPccSaEmailId);
                            m.setTargetObjectId(userId);
                            // m.setWhatId(reqId);
                            m.setSaveAsActivity(false);
                            m.setSubject(emailTempSaBindCedComPccSaEmail.getSubject());
                            m.setHtmlBody(emailTempSaBindCedComPccSaEmail.htmlBody);
                            
                            mail.setToAddresses(lstLstPccSaEmail);
                            mail.setReplyTo(UserInfo.getUserEmail());
                            mail.setSenderDisplayName(UserInfo.getFirstName() + ' ' + UserInfo.getLastName());
    
                            if(lstLstPccSaEmail.size() > 0){
                                mail.setCcAddresses(lstLstPccSaEmail);
                            }
    
                            String htmlBody = m.htmlBody;
                            String htmlSubject = m.getSubject();
                            String url = String.valueOf(System.URL.getOrgDomainUrl().toExternalForm());
                            String htmlInternetLink = '<a href="' + url + '/lightning/page/home">ACTOR NewGen Page</a>';
                            Id internalCeSaId;
    
                            if(sa.TECH_LocalSA__c == null){
                                //Ceding portal SA
                                internalCeSaId = mapIntCeSaByCedingPortalSa.get(sa.Id); //to display related internal ce sa of ceding portal sa
                            }
                            else{
                                //Group cover SA
                                internalCeSaId = sa.Id; //Group cover - Internal CE SA
                            }
    
                            String urlLoadSARequest = '/lightning/n/LoadSARequest?s__id='+internalCeSaId+'-'+sa.Program__r.UwYear__c+'-'+sa.PrincipalCedingCompany__c+'-'+sa.Program__c;
                            String urlLoadSARequestLink = '<a href="' + url + urlLoadSARequest + '">Link</a>';
    
                            htmlBody = htmlBody.replace('{U/W Year}', sa.Program__r.UwYear__c);
                            htmlBody = htmlBody.replace('{Programname}', sa.Program__r.Name);
                            htmlBody = htmlBody.replace('{SAname}', sa.SpecialAcceptanceName__c);
    
                            String strPccSaEmailDisplay = pccSaEmailDisplay != null ? pccSaEmailDisplay : '';
                            htmlBody = htmlBody.replace('{pccEmail}', strPccSaEmailDisplay);
                            
                            htmlBody = htmlBody.replace('[URLofTheSpecialAcceptance]', urlLoadSARequestLink);
                            htmlBody = htmlBody.replace('{ActorNewGenURL}', htmlInternetLink);
    
                            if(covCedConEmail != null){
                                htmlBody = htmlBody.replace('{covCedContactEmail}', covCedConEmail);
                            }
    
                            String strCovCedCom = sa.CoveredCedingCompany__r != null? sa.CoveredCedingCompany__r.Name : '';
                            htmlBody = htmlBody.replace('{Coveredcedingcompany}', strCovCedCom);
                            htmlSubject = htmlSubject.replace('{CedingCompanyName}', strCovCedCom);
    
                            String strComments = sa.Comments__c != null ? sa.Comments__c : '';
                            String commentStrDesigned = '<b style="color:blue";><font face="Arial" size="50px">' + strComments + '</font></b>'; //RRA - ticket 1382 - 1912202
                            htmlBody = htmlBody.replace('{Comments}', commentStrDesigned); //RRA - ticket 1382 - 1912202
    
                            htmlSubject = htmlSubject.replace('{ProgramName}', sa.Program__r.Name);  
                            mail.setHtmlBody(htmlBody);
                            mail.setSubject(htmlSubject);
                            lstMailsToSend.add(mail);
                        }
                    }
                }
    
                //Send email alert to Pool of Internal Ce + Group Cover SA
                //Build map of sa, list of Pool Request
    
                if(lstSABRPoolEmailToSend.size() > 0){
                    lstAllRequests = [SELECT Id, Name, Special_Acceptance__c, Program__r.Name, PrincipalCedingCompany__c, Program__r.UwYear__c
                                                , Program__r.Macro_L_O_B__c, toLabel(Program__r.Nature__c), Program__r.PrincipalCedingCompany__c
                                                , Pool__r.SA_Email__c, Pool__r.Name, Broker__r.Name, Reinsurer__r.Name, BrokerStatus__c, ExpectedResponseDate__c
                                                , Special_Acceptance__r.SpecialAcceptanceName__c, Special_Acceptance__r.Comments__c, SA_Type__c
                                                , Special_Acceptance__r.CoveredCedingCompany__r.Name, Special_Acceptance__r.PrincipalCedingCompany__r.EmailSA__c
                                      FROM Request__c 
                                      WHERE Special_Acceptance__c IN :lstSABRPoolEmailToSend
                                      AND (LastVersionSent__c = TRUE AND LastVersionAnswered__c = TRUE) AND SA_Request_Status__c <> :statusSetup];
                }
    
                for(Request__c saReq : lstAllRequests){
                    List<Request__c> lstPoolReq = new List<Request__c>();
                    if(mapPoolReqBySaId.containsKey(saReq.Special_Acceptance__c)){
                        lstPoolReq = mapPoolReqBySaId.get(saReq.Special_Acceptance__c);
                    }
    
                    if(saReq.Pool__c != null){
                        lstPoolReq.add(saReq);
                        mapPoolReqBySaId.put(saReq.Special_Acceptance__c, lstPoolReq);
                    }
                    else{
                        lstAllRequestBR.add(saReq);
                    }
                }
    
                for(Id saId : mapPoolReqBySaId.keySet()){
                    List<Request__c> lstPoolRequest = mapPoolReqBySaId.get(saId);
                    for(Request__c poolReq : lstPoolRequest){
                        Messaging.SingleEmailMessage m = new Messaging.SingleEmailMessage();
                        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                        List<String> lstEmailsToSend = new List<String>();
                        List<String> lstSaPCCEmailsToSend = new List<String>();
                        Id emailTempSaBindReinsurerEmailId;
    
                        if(isUserCE == true){
                            emailTempSaBindReinsurerEmailId = mapEmailTempIdByName.get(AP_Constant.emailTempSaBindInternalReinsurer);
                        }
                        else{
                            emailTempSaBindReinsurerEmailId = mapEmailTempIdByName.get(AP_Constant.emailTempSaBindCedComReinsurer);
                        }
    
                        String pccSaEmail = poolReq.Special_Acceptance__r.PrincipalCedingCompany__r.EmailSA__c;
                        String poolSaEmail = poolReq.Pool__r.SA_Email__c;
                        String pccSaEmailDisplay = null;
    
                        //m = Messaging.renderStoredEmailTemplate(emailTempSaBindReinsurerEmailId, userId, null);
                        m.setTemplateId(emailTempSaBindReinsurerEmailId);
                        m.setTargetObjectId(userId);
                        // m.setWhatId(reqId);
    
                        if(isUserCE == true){
                            m.setSubject(emailTempSaBindInternalReinsurer.getSubject());
                            m.setHtmlBody(emailTempSaBindInternalReinsurer.htmlBody);
                        }
                        else{
                            m.setSubject(emailTempSaBindCedComReinsurer.getSubject());
                            m.setHtmlBody(emailTempSaBindCedComReinsurer.htmlBody);
                        }
    
                        m.setSaveAsActivity(false);
                        lstEmailsToSend.add(poolSaEmail); //Send to pool SA Email
                        mail.setToAddresses(lstEmailsToSend);
                        mail.setReplyTo(UserInfo.getUserEmail());
                        mail.setSenderDisplayName(UserInfo.getFirstName() + ' ' + UserInfo.getLastName());
    
                        if(pccSaEmail != null ){
                            if(pccSaEmail.contains(';')){
                                lstSaPCCEmailsToSend = pccSaEmail.split(';');
                            }
                            else{
                                lstSaPCCEmailsToSend.add(pccSaEmail);
                            }
                        }
    
                        for(String pccEmail : lstSaPCCEmailsToSend){
                            if(pccSaEmailDisplay == null){
                                pccSaEmailDisplay = pccEmail;
                            }
                            else{
                                pccSaEmailDisplay = pccSaEmailDisplay + ' ' + pccEmail;   
                            }
                        }
    
                        if(lstSaPCCEmailsToSend.size() > 0){
                            mail.setCcAddresses(lstSaPCCEmailsToSend);
                        }
    
                        String htmlBody = m.htmlBody;
                        String htmlSubject = m.getSubject();
                        String urlDomain = String.valueOf(System.URL.getOrgDomainUrl().toExternalForm());
                        String htmlInternetLink = '<a href="' + urlDomain + '/lightning/page/home">ACTOR NewGen Page</a>';
                        String urlLoadSARequest = '/lightning/n/LoadSARequest?s__id='+saId+'-'+poolReq.Program__r.UwYear__c+'-'+poolReq.PrincipalCedingCompany__c+'-'+poolReq.Program__c+'-All-ugp';
                        String urlLoadSARequestLink = '<a href="' + urlDomain + urlLoadSARequest + '">Link</a>';
    
                        htmlBody = htmlBody.replace('{U/W Year}', poolReq.Program__r.UwYear__c);
                        htmlBody = htmlBody.replace('{Programname}', poolReq.Program__r.Name);
                        htmlBody = htmlBody.replace('{SAname}', poolReq.Special_Acceptance__r.SpecialAcceptanceName__c);
    
                        String strPccSaEmailDisplays = pccSaEmailDisplay != null ? pccSaEmailDisplay : '';
                        htmlBody = htmlBody.replace('{SAEmailPCC}', strPccSaEmailDisplays);
                        
                        htmlBody = htmlBody.replace('[URLofTheSpecialAcceptance]', urlLoadSARequestLink);
                        htmlBody = htmlBody.replace('{ActorNewGenURL}', htmlInternetLink);
    
                        String strCCCName = poolReq.Special_Acceptance__r.CoveredCedingCompany__r != null ? poolReq.Special_Acceptance__r.CoveredCedingCompany__r.Name : '';
                        htmlBody = htmlBody.replace('{Coveredcedingcompany}', strCCCName);
                        htmlSubject = htmlSubject.replace('{CedingCompanyName}', strCCCName);  
    
                        String strCommentPool = poolReq.Special_Acceptance__r.Comments__c != null ? poolReq.Special_Acceptance__r.Comments__c : '';
                        String commentStrDesigned = '<b style="color:blue";><font face="Arial" size="50px">' + strCommentPool + '</font></b>'; //RRA - ticket 1382 - 1912202
                        htmlBody = htmlBody.replace('{Comments}', commentStrDesigned); //RRA - ticket 1382 - 1912202
                        htmlSubject = htmlSubject.replace('{ProgramName}', poolReq.Program__r.Name);  
    
                        mail.setHtmlBody(htmlBody);
                        mail.setSubject(htmlSubject);
                        lstMailsToSend.add(mail);
                    }
                }
    
                //Send email alert to BR of Internal Ce + Group Cover Sa
                //Build map of sa, list of BR Request contact
    
                Map<Request__c, List<AccountContactRelation>> mapAccConRelBySAR = getBRContact(lstAllRequestBR);
    
                for(Request__c saReq : mapAccConRelBySAR.keySet()){
                    List<AccountContactRelation> lstBRContact = mapAccConRelBySAR.get(saReq);
    
                    for(AccountContactRelation contactBR : lstBRContact){
                        Messaging.SingleEmailMessage m = new Messaging.SingleEmailMessage();
                        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                        List<String> lstEmailsToSend = new List<String>();
                        Id emailTempSaBindBREmailId;
                        String pccSaEmail = saReq.Special_Acceptance__r.PrincipalCedingCompany__r.EmailSA__c;
                        String contactEmail = contactBR.Contact.Email;
                        String pccSaEmailDisplay = null;
                        List<String> lstSaPCCEmailsToSend = new List<String>();
    
                        if(saReq.Broker__c != null && saReq.BrokerStatus__c != '1'){
                            //Send mail alert to Broker
                            if(isUserCE == true){
                                emailTempSaBindBREmailId = mapEmailTempIdByName.get(AP_Constant.emailTempSaBindInternalBroker);
                                m.setTemplateId(emailTempSaBindBREmailId);
                                m.setTargetObjectId(userId);
                                m.setSubject(emailTempSaBindInternalBroker.getSubject());
                                m.setHtmlBody(emailTempSaBindInternalBroker.htmlBody);
                            }
                            else{
                                emailTempSaBindBREmailId = mapEmailTempIdByName.get(AP_Constant.emailTempSaBindInternalBroker);
                                m.setTemplateId(emailTempSaBindBREmailId);
                                m.setTargetObjectId(userId);
                                m.setSubject(emailTempSaBindInternalBroker.getSubject());
                                m.setHtmlBody(emailTempSaBindInternalBroker.htmlBody);
                            }
                        }
                        else{
                            //Send mail alert to Reinsurer
                            if(isUserCE == true){
                                emailTempSaBindBREmailId = mapEmailTempIdByName.get(AP_Constant.emailTempSaBindInternalReinsurer);
                                m.setTemplateId(emailTempSaBindBREmailId);
                                m.setTargetObjectId(userId);
                                m.setSubject(emailTempSaBindInternalReinsurer.getSubject());
                                m.setHtmlBody(emailTempSaBindInternalReinsurer.htmlBody);
                            }
                            else{
                                emailTempSaBindBREmailId = mapEmailTempIdByName.get(AP_Constant.emailTempSaBindCedComReinsurer);
                                m.setTemplateId(emailTempSaBindBREmailId);
                                m.setTargetObjectId(userId);
                                m.setSubject(emailTempSaBindCedComReinsurer.getSubject());
                                m.setHtmlBody(emailTempSaBindCedComReinsurer.htmlBody);
                            }
                        }
                        
                        // m = Messaging.renderStoredEmailTemplate(emailTempSaBindBREmailId, userId, null);
                        m.setSaveAsActivity(false);
                        lstEmailsToSend.add(contactEmail);
                        mail.setToAddresses(lstEmailsToSend);
                        mail.setReplyTo(UserInfo.getUserEmail());
                        mail.setSenderDisplayName(UserInfo.getFirstName() + ' ' + UserInfo.getLastName());
    
                        if(pccSaEmail != null ){
                            if(pccSaEmail.contains(';')){
                                lstSaPCCEmailsToSend = pccSaEmail.split(';');
                            }
                            else{
                                lstSaPCCEmailsToSend.add(pccSaEmail);
                            }
                        }
    
                        for(String pccEmail : lstSaPCCEmailsToSend){
                            if(pccSaEmailDisplay == null){
                                pccSaEmailDisplay = pccEmail;
                            }
                            else{
                                pccSaEmailDisplay = pccSaEmailDisplay + ' ' + pccEmail;   
                            }
                        }
    
                        if(lstSaPCCEmailsToSend.size() > 0){
                            mail.setCcAddresses(lstSaPCCEmailsToSend);
                        }
    
                        String urlLoadSARequestBrokerRein = 'SARespondOnBehalf?s__id='+saReq.Special_Acceptance__c+'-'+saReq.Program__r.UwYear__c+'-'+saReq.Program__r.PrincipalCedingCompany__c+'-'+saReq.Program__c+'-'+saReq.Broker__c+'-'+saReq.Reinsurer__c+'-undefined-portalBR-undefined-'+saReq.Id;
                        String urlLoadSARequestLinkBrokerRein = '<a href="' + urlArrPortal[0] + urlLoadSARequestBrokerRein + '">'+saReq.Reinsurer__r.Name+'</a>';
                        String strReinsurerName = '';
    
                        if(strReinsurerName == ''){
                            strReinsurerName = '<li style="text-align: left;">' + urlLoadSARequestLinkBrokerRein + ' {'+ saReq.SA_Type__c +'}</li>';
                        }
                        else{
                            strReinsurerName += '<li style="text-align: left;">' + urlLoadSARequestLinkBrokerRein + ' {'+ saReq.SA_Type__c +'}</li>';
                        }
    
                        String htmlBody = m.htmlBody;
                        String htmlSubject = m.getSubject();
                        String urlDomain = String.valueOf(System.URL.getOrgDomainUrl().toExternalForm());
                        String htmlInternetLink = '<a href="' + urlDomain + '/lightning/page/home">ACTOR NewGen Page</a>';
                        String urlLoadSARequest = '/lightning/n/LoadSARequest?s__id='+saReq.Special_Acceptance__c+'-'+saReq.Program__r.UwYear__c+'-'+saReq.PrincipalCedingCompany__c+'-'+saReq.Program__c;
                        String urlLoadSARequestLink = '<a href="' + urlDomain + urlLoadSARequest + '">Link</a>';
                        
                        htmlBody = htmlBody.replace('{U/W Year}', saReq.Program__r.UwYear__c);
                        htmlBody = htmlBody.replace('{Programname}', saReq.Program__r.Name);
                        htmlBody = htmlBody.replace('{SAname}', saReq.Special_Acceptance__r.SpecialAcceptanceName__c);
    
                        String strPccSaEmailDisplayRein = pccSaEmailDisplay != null ? pccSaEmailDisplay : '';
                        htmlBody = htmlBody.replace('{SAEmailPCC}', strPccSaEmailDisplayRein);  
    
                        htmlBody = htmlBody.replace('[URLofTheSpecialAcceptance]', urlLoadSARequestLink);
                        htmlBody = htmlBody.replace('{ActorNewGenURL}', htmlInternetLink);
                        htmlSubject = htmlSubject.replace('{ProgramName}', saReq.Program__r.Name); 
                        
                        if(strReinsurerName != null){
                            htmlBody = htmlBody.replace('{ListReinsurerLink}', strReinsurerName);
                        }
                        else{
                            htmlBody = htmlBody.replace('{ListReinsurerLink}', '');
                        }
    
                        String strCovCedComName = saReq.Special_Acceptance__r.CoveredCedingCompany__r != null? saReq.Special_Acceptance__r.CoveredCedingCompany__r.Name : '';
                        htmlBody = htmlBody.replace('{Coveredcedingcompany}', strCovCedComName);
                        htmlSubject = htmlSubject.replace('{CedingCompanyName}', strCovCedComName);
    
                        String strCommentRein = saReq.Special_Acceptance__r.Comments__c != null? saReq.Special_Acceptance__r.Comments__c : '';
                        String commentStrDesigned = '<b style="color:blue";><font face="Arial" size="50px">' + strCommentRein + '</font></b>'; //RRA - ticket 1382 - 1912202
                        htmlBody = htmlBody.replace('{Comments}', commentStrDesigned); //RRA - ticket 1382 - 1912202
    
                        String strExpectedResDate = saReq.ExpectedResponseDate__c != null ? String.valueOf(saReq.ExpectedResponseDate__c) : '';
                        htmlBody = htmlBody.replace('{expectedAnswerDate}', strExpectedResDate);
    
                        mail.setHtmlBody(htmlBody);
                        mail.setSubject(htmlSubject);
                        lstMailsToSend.add(mail);
                    }
                }
    
                if(lstMailsToSend.size() > 0){
                    Messaging.sendEmail((List<Messaging.Email>) lstMailsToSend);
                }
    
                mapResults.put('Success', 'Success');
            }catch (Exception ex) {
                Database.rollback(sp);
                mapResults.put('Error', ex.getMessage());
            }
            return mapResults;
        }
    
        /**
        * @description Method to get Contact(s) for Covered Ceding Company
        * @param SpecialAcceptance__c specialAcceptanceObj
        * @return Map<String, Object>
        */
        @AuraEnabled
        public static Map<Id, List<AccountContactRelation>> getCovCedContact(List<SpecialAcceptance__c> lstSpecialAcceptance) {
            Map<Id, Id> mapUserIdByContactId = new Map<Id, Id>();
            Map<Id, List<AccountContactRelation>> mapLstCovCedConBySaId = new Map<Id, List<AccountContactRelation>>();
            Map<Id, List<AccountContactRelation>> mapLstCovCedConBySaIdToDisplay = new Map<Id, List<AccountContactRelation>>();
            Map<Id, SpecialAcceptance__c> mapSaBySaId = new Map<Id, SpecialAcceptance__c>();
            Map<Id, String> mapReferentialIdByPCC = new Map<Id, String>();
            Map<String, Group> mapGroupByReferentialId = new Map<String, Group>();
            Map<Id, List<Id>> mapLstUserOrGroupIdByGroupId = new Map<Id, List<Id>>();
            List<AccountContactRelation> lstAccConRelation = new List<AccountContactRelation>(); 
            Set<String> setReferentialId = new Set<String>();
            Set<Id> setContactId = new Set<Id>();
            Set<Id> setCovCedComId = new Set<Id>();
            Set<Id> setPrinCedComId = new Set<Id>();
    
            try{
                for(SpecialAcceptance__c sa : lstSpecialAcceptance){
                    setPrinCedComId.add(sa.PrincipalCedingCompany__c);
                    mapSaBySaId.put(sa.Id, sa);
                    if(sa.CoveredCedingCompany__c != null){
                        setCovCedComId.add(sa.CoveredCedingCompany__c);
                    }
                }
    
                for(AccountContactRelation accContactRelation : [SELECT Id, AccountId,Account.Name, Account.RecordTypeId, Contact.Account.RecordTypeId, Contact.Email, Roles, ContactId, Contact.MacroLoB__c, Contact.Nature__c, Contact.LastName, Contact.FirstName FROM AccountContactRelation
                                                                WHERE AccountId IN :setCovCedComId
                                                                AND IsActive = TRUE]){
                    if(accContactRelation.Account.RecordTypeId == accContactRelation.Contact.Account.RecordTypeId){
                        lstAccConRelation.add(accContactRelation);
                        setContactId.add(accContactRelation.ContactId);
                    }
                }
    
                for(SpecialAcceptance__c sa : lstSpecialAcceptance){
                    for(AccountContactRelation accContactRelation : lstAccConRelation){
                        List<AccountContactRelation> lstCovAccCon = new List<AccountContactRelation>();
                        if(sa.CoveredCedingCompany__c == accContactRelation.AccountId){
                            if(mapLstCovCedConBySaId.containsKey(sa.Id)){
                                lstCovAccCon = mapLstCovCedConBySaId.get(sa.Id);
                            }
                            lstCovAccCon.add(accContactRelation);
                            mapLstCovCedConBySaId.put(sa.Id, lstCovAccCon);
                        }
                    }
                }
    
                for(User user : [SELECT Id, ContactId, IsActive FROM User WHERE ContactId IN :setContactId AND IsActive = true]){
                    mapUserIdByContactId.put(user.ContactId, user.Id);
                }
    
                List<Account> lstAccount = [SELECT Id, Name, TECH_ReferentialId__c FROM Account WHERE Id IN :setPrinCedComId];
    
                for(Account acc : lstAccount){
                    setReferentialId.add(acc.TECH_ReferentialId__c);
                    mapReferentialIdByPCC.put(acc.Id, acc.TECH_ReferentialId__c);
                }
                
                List<Group> lstGroup = [SELECT Id, DeveloperName FROM Group WHERE DeveloperName IN :setReferentialId];
                
                for(Group gp : lstGroup){
                    mapGroupByReferentialId.put(gp.DeveloperName, gp);
                }
    
                for(GroupMember groupMember : [SELECT Id, GroupId, UserOrGroupId FROM GroupMember WHERE GroupId IN :lstGroup]){
                    List<Id> lstUserOrGroupId = new List<Id>();
                    
                    if(mapLstUserOrGroupIdByGroupId.containsKey(groupMember.GroupId)){
                        lstUserOrGroupId = mapLstUserOrGroupIdByGroupId.get(groupMember.GroupId);
                    }
    
                    lstUserOrGroupId.add(groupMember.UserOrGroupId);
                    mapLstUserOrGroupIdByGroupId.put(groupMember.GroupId, lstUserOrGroupId);
                }
    
                for(Id saId : mapLstCovCedConBySaId.keySet()){
                    SpecialAcceptance__c sa = mapSaBySaId.get(saId);
                    Id pccId = sa.PrincipalCedingCompany__c;
                    List<AccountContactRelation> lstCovCedAccConRelation = mapLstCovCedConBySaId.get(saId);
                    List<AccountContactRelation> lstAccountContactRelationsToDisplay = new List<AccountContactRelation>();
    
                    //Get Referential Id of PCC
                    if(mapReferentialIdByPCC.containsKey(pccId)){
                        String pccReferentialId = mapReferentialIdByPCC.get(pccId);
                        //Get Group of Referential Id 0f PCC
                        if(mapGroupByReferentialId.containsKey(pccReferentialId)){
                            Group gp = mapGroupByReferentialId.get(pccReferentialId);
    
                            //Get list of User or Group Id of group of Referential Id 0f PCC 
                            if(mapLstUserOrGroupIdByGroupId.containsKey(gp.Id)){
                                List<Id> lstUserOrGroupIdOfPCC = mapLstUserOrGroupIdByGroupId.get(gp.Id);
                                Set<Id> setUserOrGroupIdOfPCC = new Set<Id>();
                                setUserOrGroupIdOfPCC.addAll(lstUserOrGroupIdOfPCC);
                                for(AccountContactRelation covCedCon : lstCovCedAccConRelation){
                                    //Get userId for Covered Ceding Contact
                                    if(mapUserIdByContactId.containsKey(covCedCon.ContactId)){
                                        Id userId = mapUserIdByContactId.get(covCedCon.ContactId);
                                        if(setUserOrGroupIdOfPCC.contains(userId)){
                                            lstAccountContactRelationsToDisplay.add(covCedCon);
                                        }
                                    }
                                }
                            }
                        }
                    }
    
                    mapLstCovCedConBySaIdToDisplay.put(saId, lstAccountContactRelationsToDisplay);
                }
            }catch (Exception ex) {
            }
            
            return mapLstCovCedConBySaIdToDisplay;
        }
    
        /**
        * @description Method to get Broker/Reinsurer Contact(s) for Program
        * @param List<Request__c> lstSAR
        * @return Map<Request__c, List<AccountContactRelation>>
        */
        @AuraEnabled
        public static Map<Request__c, List<AccountContactRelation>> getBRContact(List<Request__c> lstSAR) {
            Map<Id, List<AccountContactRelation>> mapContactRel = new Map<Id, List<AccountContactRelation>>();
            Map<Request__c, List<AccountContactRelation>> mapContactRelBySAR = new Map<Request__c, List<AccountContactRelation>>();
            Map<Id, Contact> mapContactsDetails = new Map<Id, Contact>();
            List<Id> lstAllAccountBRId = new List<Id>();
            Set<Id> setContactId = new Set<Id>();
            Set<Id> setActiveContactId = new Set<Id>();
    
            for(Request__c saReq : lstSAR){
                if(saReq.Broker__c != null && saReq.BrokerStatus__c != '1'){
                    lstAllAccountBRId.add(saReq.Broker__c);
                }
                else{
                    lstAllAccountBRId.add(saReq.Reinsurer__c);
                }
            }
    
            for(AccountContactRelation accContactRelation : [SELECT Id, AccountId, Account.RecordTypeId, Contact.Account.RecordTypeId, Roles, ContactId, Contact.MacroLoB__c, Contact.Nature__c  FROM AccountContactRelation
                                                            WHERE AccountId IN :lstAllAccountBRId
                                                            AND IsActive = TRUE
                                                            AND Contact.MacroLoB__c != null
                                                            AND Contact.Nature__c != null]){
    
                if(accContactRelation.Account.RecordTypeId == accContactRelation.Contact.Account.RecordTypeId){
                    setContactId.add(accContactRelation.ContactId);
                }
            }
    
            if(setContactId.size() > 0){
                for(User user: [SELECT Id, name, ContactId, IsActive FROM User WHERE ContactId IN :setContactId AND IsActive = true]){
                    setActiveContactId.add(user.ContactId);
                }
            }
    
            if(setActiveContactId.size() > 0){
                for(Contact con : [SELECT Id, AccountType__c, AccountId, MacroLoB__c, toLabel(Nature__c), Account.Name,
                                          FirstName, LastName, Email FROM Contact WHERE Id IN :setActiveContactId]){
                    mapContactsDetails.put(con.Id, con);
                }
    
                for(AccountContactRelation accContactRelation : [SELECT Id, AccountId, ContactId, IsDirect, Roles, IsActive, Contact.AccountType__c, Contact.AccountId,
                                                                        Contact.MacroLoB__c, toLabel(Contact.Nature__c), Account.Name,
                                                                        Contact.FirstName, Contact.LastName, Contact.Email
                                                                FROM AccountContactRelation
                                                                WHERE ContactId IN :setActiveContactId
                                                                AND IsActive = TRUE]){
    
                    if(mapContactRel.containsKey(accContactRelation.ContactId)){
                        mapContactRel.get(accContactRelation.ContactId).add(accContactRelation);
                    }
                    else{
                        mapContactRel.put(accContactRelation.ContactId, new List<AccountContactRelation>{accContactRelation});
                    }
                }
            }
    
            for(Request__c saReq : lstSAR){
                Id accountId;
                Set<AccountContactRelation> setAccConRel = new Set<AccountContactRelation>();
                List<AccountContactRelation> lstAccountContactRelationsToDisplay = new List<AccountContactRelation>();
    
                if(saReq.Broker__c != null && saReq.BrokerStatus__c != '1'){
                    accountId = saReq.Broker__c;
                }
                else{
                    accountId = saReq.Reinsurer__c;
                }
    
                for(Id key : mapContactsDetails.keySet()){
                    Contact contactExterne = mapContactsDetails.get(key);
                    String[] macroLOBArr = contactExterne.MacroLoB__c.split(';');
                    Boolean checksOK = false;
                    String macroLOBFromProgram = saReq.Program__r.Macro_L_O_B__c;
                    String natureFromProgram = saReq.Program__r.Nature__c;
                    String prinCedComFromProgram = saReq.Program__r.PrincipalCedingCompany__c;
    
                    if(macroLOBArr.contains(macroLOBFromProgram)
                            && (contactExterne.Nature__c == natureFromProgram || (contactExterne.Nature__c.contains(natureFromProgram)))){
                        for(AccountContactRelation relation : mapContactRel.get(key)){
                            if(relation.Roles == 'PrincipalCedingCompany'){
                                if(relation.AccountId == prinCedComFromProgram){
                                    checksOK = true;
                                }
                            }
                        }
                    }
    
                    if(checksOK == true){
                        for(AccountContactRelation relation : mapContactRel.get(key)){
                            if(accountId == relation.AccountId && relation.Contact.Email != null){
                                setAccConRel.add(relation);
                            }
                        }
                    }
                }
                lstAccountContactRelationsToDisplay.addAll(setAccConRel);
                mapContactRelBySAR.put(saReq, lstAccountContactRelationsToDisplay);
            }
    
            return mapContactRelBySAR;
        }
    }