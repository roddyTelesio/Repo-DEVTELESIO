public without sharing class LWC33_MarketSubmission {
    /**************************************************************************************
    -- - Author        : Spoon Consulting
    -- - Description   : Class for lwc33MarketSubmission
    --
    -- Maintenance History:
    --
    -- Date         Name  Version  Remarks
    -- -----------  ----  -------  -------------------------------------------------------
    -- 01-JUL-2020  SAU    1.0     Initial Version
    -- 13-AUG-2020  MBE    1.1     Get Request Details/Save Requests Updated - to take consideration for versions
    -- 27-JAN-2021  NBI    1.2     Email template review
    -- 04-FEB-2021  NBI    1.3     W-0861: LA - MARKET SUB - Champs collatéraux vides côté CE
    -- 02-APR-2021  MBE    1.4     W-0938 - Mettre en CC la BAL de la PCC
    -- 21-May-2021  MBE    1.5     W-0974 - Bug bloquant Prod - Impossibilité de créer une Lead request - TECH_Actor2Id__c
    -- 08-JUL-2021  NBI    1.6     W-0992: Third Party Management
    -- 02-AUG-2021  MBE    1.7     W-1000 - Signing - Impossibilité de modifier les champs modifiables du signing sur des programmes migrés ou renouvelés à l'identique à partir de données migrées
    -- 11-AUG-2021  MBE    1.8     Code Optimization - Use Ternary Operator
    -- 26-AUG-2021  MBE    1.9     SOQL Injection for getLookupAccountField()
    -- 27-AUG-2021  MBE    2.0     Remove unused value for mapResult
    -- 29-SEP-2021  MBE    2.1     W-1012 - Signing - Filtre à enlever sur les champs risk carrier et financial entity pour un user avec le profil AGRe Admin user  
    -- 04-OCT-2021  MBE    2.2     W-1033 - impossibilité de visualisation des documents en cotation par un broker
    -- 02-DEC-2021  MBE    2.3     W-1062 - UAT - Non mise à jour du statut de la requête de signing - Method: getRequestLists
    --------------------------------------------------------------------------------------
    **************************************************************************************/
    
        /**
        * @description Method to get details of selected Request
        * @param Id requestId
        * @return Boolean
        */
        @AuraEnabled
        public static Request__c getRequestDetails(Id requestId){
            Request__c request = new Request__c();
    
            try{
                 request = [SELECT Id,
                                   ReinsurerStatus__c,
                                   ExpectedResponseDate__c,
                                   LastSentDate__c,
                                   ResponseDate__c,
                                   Program__r.Name,
                                   Program__r.UwYear__c,
                                   Program__r.PrincipalCedingCompany__r.Name,
                                   Program__r.PrincipalCedingCompany__r.IsActive__c,
                                   Broker__c,
                                   Broker__r.Name,
                                   Broker__r.IsActive__c,
                                   BrokerStatus__c,
                                   Reinsurer__c,
                                   Reinsurer__r.Name,
                                   Reinsurer__r.IsActive__c,
                                   RiskCarrier__c,
                                   RiskCarrier__r.Name,
                                   FinancialEntity__c,
                                   FinancialEntity__r.Name,
                                   Collateral_Provider_City__c,
                                   Collateral_provider_Code__c,
                                   Collateral_provider_Name__c,
                                   Type_of_Code__c,
                                   Claims_contact__c,
                                   DescriptionReinsurerLimitColl__c,
                                   Accept__c,
                                   WrittenShare__c,
                                   TECH_RelatedLeadPlacementRequest__c,
                                   Reinsurer_s_Ref__c, 
                                   Broker_s_Ref__c
                            FROM Request__c
                            WHERE Id =: requestId];
    
                return request;
            }
            catch(Exception ex){
                return request;
            }
        }
    
        /**
        * @description Method to get request with same Reinsurer as selected Request
        * @param Id programId, Id reinsurerId, Boolean portalAccess
        * @return Map<String, Object>
        */
        @AuraEnabled
        public static Map<String, Object> getRequestLists(Id programId, Id reinsurerId, Boolean portalAccess){
            Map<String, Object> mapResults = new Map<String, Object>();
            Map<String, Id> mapRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectRequest});
            List<Request__c> lstRequests = new List <Request__c>();
            List<String> lstRequestFields = AP_Constant.getCreatableFieldsByObjName(AP_Constant.sObjectRequest);
            String strRequestFields = String.join(lstRequestFields , ', ');
            String statusSetup = AP_Constant.statusSetup;
            String recordTypeIdSigning = mapRecTypeId.get(AP_Constant.reqRTSigning);
            Boolean isDeactivatedProg = false; //RRA - ticket 0585 07122022

            //Program RRA - ticket 0585 07122022'
            Program__c program = [SELECT Id, isBtnActivatedDeactivated__c FROM Program__c WHERE Id = :programId];  
            if (program.isBtnActivatedDeactivated__c){
                isDeactivatedProg = true;
            }
            
            try{
                if(portalAccess == true){
                    List<User> connectedUser = [SELECT Id, ContactId FROM User WHERE Id =: UserInfo.getUserId()];
    
                    List<Contact> contact = [SELECT Id, AccountType__c, AccountId FROM Contact WHERE Id =: connectedUser[0].ContactId];
    
                    if(contact[0].AccountType__c == 'Broker'){
                        Id brokerId = contact[0].AccountId;
                        Id contactId = connectedUser[0].ContactId;
                        Set<Id> setRelatedBroker = new Set<Id>();
    
                        for(AccountContactRelation relatedContactRelationBroker : [SELECT Id, AccountId, Account.RecordTypeId
                                                                                          , Contact.Account.RecordTypeId, Roles
                                                                                          , ContactId, Contact.MacroLoB__c
                                                                                          , Contact.Nature__c, IsDirect
                                                                                    FROM AccountContactRelation
                                                                                    WHERE ContactId = :contactId
                                                                                    AND IsActive = TRUE
                                                                                    AND Contact.MacroLoB__c != NULL
                                                                                    AND Contact.Nature__c != NULL]){
                            //if(relatedContactRelationBroker.Roles == 'Broker' || relatedContactRelationBroker.IsDirect == true){
                                setRelatedBroker.add(relatedContactRelationBroker.AccountId);
                            //}
                        }
    
                        String querySigning = 'SELECT Id, TECH_TreatyName__c, Treaty__r.PlacementShare_Perc__c, TECH_BrokerName__c, TECH_IsBrokerPresent__c, TECH_ReinsurerName__c, TECH_Layer__c, TECH_UWyear__c,  SigningRegionalManager__r.Email, TECH_RelatedLeadPlacementRequest__c '
                                + ', RiskCarrier__r.Name, FinancialEntity__r.Name, Program__r.LossDepositMode__c, Program__r.LossDeposit__c, Broker__r.Name, Reinsurer__r.Name, ExpectedResponseDate__c, LastSentDate__c,WrittenShare__c '
                                + ', Treaty__r.LossDepositMode__c, Treaty__r.LossDeposit__c, TreatyReference__c, Treaty__r.Deductions__c '
                                + ', Treaty__r.TypeofTreaty__c, Treaty__r.PremiumDeposit__c, Program__r.LossDepositLevel__c, Pool__r.Name, Pool__r.AssignedTo__r.Email, Program__r.Name, program__r.principalcedingcompany__r.Name, Reinsurer_s_Ref__c, Broker_s_Ref__c, '
                                +  strRequestFields
                                + ' from Request__c where (Program__c = \''+programId+ '\' AND Broker__c IN :setRelatedBroker AND Reinsurer__c = \''+reinsurerId+ '\' AND RecordTypeId = :recordTypeIdSigning AND OriginalRequest__c = NULL AND ReinsurerStatus__c != :AP_Constant.statusSetup ) ';
                        lstRequests = Database.query(querySigning);
                    }
                    else if(contact[0].AccountType__c == 'Reinsurer'){
                        Id reinsId = contact[0].AccountId;
    
                        String querySigning = 'SELECT Id, TECH_TreatyName__c, Treaty__r.PlacementShare_Perc__c, TECH_BrokerName__c, TECH_IsBrokerPresent__c, TECH_ReinsurerName__c, TECH_Layer__c, TECH_UWyear__c,  SigningRegionalManager__r.Email, TECH_RelatedLeadPlacementRequest__c '
                                + ', RiskCarrier__r.Name, FinancialEntity__r.Name, Program__r.LossDepositMode__c, Program__r.LossDeposit__c, Broker__r.Name, Reinsurer__r.Name, ExpectedResponseDate__c, LastSentDate__c, WrittenShare__c '
                                + ', Treaty__r.LossDepositMode__c, Treaty__r.LossDeposit__c, TreatyReference__c, Treaty__r.Deductions__c '
                                + ', Treaty__r.TypeofTreaty__c, Treaty__r.PremiumDeposit__c, Program__r.LossDepositLevel__c, Pool__r.Name, Pool__r.AssignedTo__r.Email, Program__r.Name, program__r.principalcedingcompany__r.Name, Reinsurer_s_Ref__c, Broker_s_Ref__c, '
                                +  strRequestFields
                                + ' from Request__c where (Program__c = \''+programId+ '\' AND Reinsurer__c = \''+reinsurerId+ '\' AND Broker__c = null AND RecordTypeId = :recordTypeIdSigning AND OriginalRequest__c = NULL AND ReinsurerStatus__c != :AP_Constant.statusSetup ) ';
                        lstRequests = Database.query(querySigning);
                    }
                }
                else{
                    String querySigning = 'SELECT Id, TECH_TreatyName__c, Treaty__r.PlacementShare_Perc__c, TECH_BrokerName__c, TECH_IsBrokerPresent__c, TECH_ReinsurerName__c, TECH_Layer__c, TECH_UWyear__c,  SigningRegionalManager__r.Email '
                            + ', RiskCarrier__r.Name, FinancialEntity__r.Name, Program__r.LossDepositMode__c, Program__r.LossDeposit__c, Broker__r.Name, Reinsurer__r.Name '
                            + ', Treaty__r.LossDepositMode__c, Treaty__r.LossDeposit__c, TreatyReference__c, Treaty__r.Deductions__c '
                            + ', Treaty__r.TypeofTreaty__c, Treaty__r.PremiumDeposit__c, Program__r.LossDepositLevel__c, Pool__r.Name, Pool__r.AssignedTo__r.Email, Program__r.Name, program__r.principalcedingcompany__r.Name, '
                            +  strRequestFields
                            + ' from Request__c where (Program__c = \''+programId+ '\' AND Reinsurer__c = \''+reinsurerId+ '\' AND RecordTypeId = :recordTypeIdSigning) AND ((LastVersionSent__c = TRUE AND LastVersionAnswered__c = TRUE) OR (ReinsurerStatus__c = :statusSetup)) ';
    
                    lstRequests = Database.query(querySigning);
                }
                mapResults.put('isDeactivatedProg', isDeactivatedProg); //RRA - ticket 585 - 07032023
                mapResults.put('Success',lstRequests);
                return mapResults;
            }
            catch(Exception ex){
                mapResults.put('Error',ex.getMessage());
                return mapResults;
            }
        }
        //MRA 19/05/23 - Contact Signatory Rebuild - START
        @AuraEnabled
        public static Map<String, Object> saveSignatories(List<ContactReinsurerProgramRelation__c> lstContacts,Id reinsurerId,Id idProgram){
            Map<String, Object> mapResults = new Map<String, Object>();
            List<String> lstNewContactIds = new List<Id>();
                List <ContactReinsurerProgramRelation__c> lstContactToDelete = new List<ContactReinsurerProgramRelation__c>();
                List <ContactReinsurerProgramRelation__c> lstContactToInsert = new List<ContactReinsurerProgramRelation__c>();
                List <ContactReinsurerProgramRelation__c> lstContactToUpdate = new List<ContactReinsurerProgramRelation__c>(); //MRA 1103 07/07/2022
    
                for(ContactReinsurerProgramRelation__c contact : lstContacts){
                    String Id = contact.Id;
                    //new contacts
                    if(Id == null){
                        lstContactToInsert.add(contact);
                    }
                    else{
                        //salesforce contacts
                        lstContactToUpdate.add(contact) ; //MRA 1103 07/07/2022
                        lstNewContactIds.add(Id);
                    }
                }
    
                for(ContactReinsurerProgramRelation__c existingContact : [SELECT Id,Name, ContactId__r.Salutation,ContactId__r.LastName,ContactId__r.FirstName,ContactId__r.Email,ContactId__r.MobilePhone,ProgramId__r.Name,ReinsurerId__r.Name,OrderOfSignatory__c
                                               FROM ContactReinsurerProgramRelation__c 
                                               WHERE ReinsurerId__c =: reinsurerId
                                               AND ProgramId__c =: idProgram
                                               ORDER BY OrderOfSignatory__c]){
                    if(lstNewContactIds.indexOf(existingContact.Id) == -1){
                        lstContactToDelete.add(existingContact);
                    }
                }
                //MRA 1103 07/07/2022 START
                if(lstContactToUpdate.size() > 0){
                    update lstContactToUpdate;
                }
                //MRA 1103 07/07/2022 END
                if(lstContactToDelete.size() > 0){
                    delete lstContactToDelete;
                }
                if(lstContactToInsert.size() > 0){
                    insert lstContactToInsert;
                }

                mapResults.put('Success','Success');
                return mapResults;
        }
        //MRA 19/05/23 - Contact Signatory Rebuild - END
        /**
        * @description Method to save updated Requests
        * @param List<Request__c> lstRequests, String buttonName, Id reinsurerId, List<Contact> lstContacts, Boolean isPortal
        * @return Map<String, Object>
        * RRA - 1054
        */
        @AuraEnabled
        public static Map<String, Object> saveRequests(List<Request__c> lstRequests, String buttonName, Id reinsurerId, Boolean isPortal,Id idProgram){
            Schema.DescribeSObjectResult contactObj = Contact.SObjectType.getDescribe();
            Map<String, Object> mapResults = new Map<String, Object>();
            List<Request__c> lstNewVersionRequest = new List<Request__c>();
            List<Request__c> lstOriginalRequestToUpdate = new List<Request__c>();
            Set<Id> setOriginalRequestId = new Set<Id>();
            Set<String> setAnsweredSigned = new Set<String>();
            Set<String> setAllAnsweredSigned = new Set<String>();
            List<DocumentVisibility__c> lstDocumentVisibility = new List<DocumentVisibility__c>();
            //List<DocumentVisibility__c> lstDocVis;
            List<DocumentVisibility__c> lstDocVisBroReins;
            List<DocumentVisibility__c> lstDocVisReins;
            Set<Id> setProgramId = new Set<Id>();
            Set<Id> setReinsurerId = new Set<Id>();
            Set<Id> setBrokerId = new Set<Id>();
            //Id recordTypeId;
            Decimal valueMinor;
            String nandalo;
            Savepoint sp = Database.setSavepoint();
    
            //try{
                /*for(Schema.RecordTypeInfo contactRT : contactObj.getRecordTypeInfos()){
                    if(contactRT.getDeveloperName() == AP_Constant.contactSignatory){
                       recordTypeId = contactRT.getRecordTypeId();
                    }
                }*/

                for(Request__c req : lstRequests){
                    setProgramId.add(req.Program__c);
                    setBrokerId.add(req.Broker__c);
                    setReinsurerId.add(req.Reinsurer__c);
                }

                //lstDocVis = [SELECT Id, Tech_BrokerId__c, Tech_Request_Status__c, Tech_Phase__c, Tech_ReinsurerId__c, Program__c, Tech_IsExternal__c FROM DocumentVisibility__c WHERE Program__c IN:setProgramId AND Tech_IsExternal__c = true ];

                //RRA - 939
                String query = 'SELECT Id, Tech_BrokerId__c, Tech_Request_Status__c, Tech_Phase__c, Tech_LabelPhase__c, Tech_ReinsurerId__c, Program__c, Tech_IsExternal__c FROM DocumentVisibility__c WHERE Program__c =:setProgramId AND Tech_IsExternal__c = true';

                if (!setBrokerId.contains(null) && !setReinsurerId.contains(null)){
                    query = query + ' AND Tech_BrokerId__c IN:setBrokerId AND Tech_ReinsurerId__c IN: setReinsurerId';
                }else if (setBrokerId.contains(null) && !setReinsurerId.contains(null)){
                    query = query + ' AND Tech_BrokerId__c = null AND Tech_ReinsurerId__c IN: setReinsurerId';
                }

                lstDocVisBroReins = Database.query(query);
                lstDocVisReins = Database.query(query);
    
                if(buttonName == 'Send'){
                    List<Request__c> lstUpdatedRequests = new List<Request__c>();
                    System.debug('valueMinor 111 == ' + valueMinor);
                    for(Request__c request : lstRequests){
                         //RRA - 1104 23/05/2022
                         valueMinor = request.VersionMinor__c + 1; 
                        if(request.VersionMinor__c == 0){
                            request.VersionMinor__c = 1;
                        } 

                         //RRA - 1104 03/06/2022
                        if (request.OriginalRequest__c == null){
                            request.VersionMinor__c = valueMinor;
                            request.TECH_isAdmin__c = false; //RRA - ticket 1421 - 11092023
                        }

                        request.ReinsurerStatus__c = AP_Constant.statusRequestSigned;
                        request.ResponseDate__c = System.today();
                        request.TECH_LastAnswerDate__c = System.today();
                        lstUpdatedRequests.add(request);
                        setOriginalRequestId.add(request.Id);
                        setAnsweredSigned.add(request.ReinsurerStatus__c);
    
                        Request__c newVersionRequest = request.clone(false, false, false, false);
                         //RRA - 1104 23/05/2022
                        newVersionRequest.VersionMinor__c = valueMinor;

                        newVersionRequest.OriginalRequest__c = request.Id;
                        newVersionRequest.LastVersionSent__c = true;
                        newVersionRequest.LastVersionAnswered__c = true;
                        newVersionRequest.TECH_Actor2Id__c = null;
                        newVersionRequest.TECH_isAdmin__c = false;  //RRA - ticket 1421 - 11092023
                        lstNewVersionRequest.add(newVersionRequest);
                    }
    
                    List<Request__c> lstAllRequestVersion = [SELECT Id, Name, LastVersionSent__c, LossDepositMode__c, LossDeposit__c, TECH_isAdmin__c, LastVersionAnswered__c, ResponseDate__c, ReinsurerStatus__c, OriginalRequest__c FROM Request__c WHERE OriginalRequest__c IN :setOriginalRequestId];                     
    
                    for(Request__c request : lstAllRequestVersion){

                        request.LastVersionAnswered__c = false;
                        request.LastVersionSent__c = false;
                        request.ResponseDate__c = System.today();
                        request.TECH_LastAnswerDate__c = System.today();
                        request.ReinsurerStatus__c = AP_Constant.statusRequestSigned;
                        setAllAnsweredSigned.add(request.ReinsurerStatus__c);
                    }
                    //RRA - 1054
                    if (setAnsweredSigned.contains(AP_Constant.statusRequestSigned) || setAllAnsweredSigned.contains(AP_Constant.statusRequestSigned)) {

                        if (lstDocVisBroReins.size () > 0){
                            for(DocumentVisibility__c docVis : lstDocVisBroReins){
                                for(Request__c reqSigned :lstRequests){
                                    if (docVis.Tech_BrokerId__c == reqSigned.Broker__c && docVis.Tech_ReinsurerId__c == reqSigned.Reinsurer__c){
                                        docVis.Tech_Request_Status__c =  AP_Constant.statusVisibleOnPortalDocVis; // RRA - 1054
                                        lstDocumentVisibility.add(docVis);
                                    }
                                }
                            }
                        }

                        if (lstDocVisReins.size () > 0){
                            for(DocumentVisibility__c docVis : lstDocVisReins){
                                for(Request__c reqSigned :lstRequests){
                                    if (docVis.Tech_BrokerId__c == reqSigned.Broker__c && docVis.Tech_ReinsurerId__c == reqSigned.Reinsurer__c){
                                        docVis.Tech_Request_Status__c =  AP_Constant.statusVisibleOnPortalDocVis; // RRA - 1054
                                        lstDocumentVisibility.add(docVis);
                                    }
                                }
                            }
                        }
                    }

                    if(lstDocumentVisibility.size() > 0 ){
                        map<Id,DocumentVisibility__c> docVisMap = new map<Id,DocumentVisibility__c>(); 
                        docVisMap.putall(lstDocumentVisibility);
                        update docVisMap.values();
                      }
    
                    if(lstAllRequestVersion.size() > 0){
                        update lstAllRequestVersion;
                    }
                    
                    if(lstNewVersionRequest.size() > 0){
                        insert lstNewVersionRequest;
                    }
                    
                    if(lstUpdatedRequests.size() > 0){
                        update lstUpdatedRequests;
                    }
                    
                    //RRA - Ticket 1866 - 15012024
                    updateRequestForLossDeposit (lstAllRequestVersion);
                    updateRequestForLossDeposit (lstNewVersionRequest);
                    updateRequestForLossDeposit (lstUpdatedRequests);
                }
                else{
                    if(isPortal == false || isPortal == true ){ //RRA - ticket 1343 -14112022
                        Set<Id> setOriginalReqId = new Set<Id>();
                        Set<Id> setOriginalIdReq = new Set<Id>();
                        Set<Id> setOriginalIdReq2 = new Set<Id>();
                        List<Request__c> lstReqUpdateOrigReqTechIsAdmin = new List<Request__c>();
                        String claimContact = '';
                        Map<Id, Request__c> mapOriginalReqs = new Map<Id, Request__c>();
                        Map<Id, Request__c> mapLastVersReqs = new Map<Id, Request__c>();
                        List<Request__c> lstLastVersionRequest = new List<Request__c>();
                        //Button Save in Internal
                        for(Request__c originalReq : lstRequests) {
                            //RRA - ticket 1421 - 11092023
                            if (originalReq.OriginalRequest__c == null){
                                if (originalReq.TECH_isAdmin__c){
                                    originalReq.TECH_isAdmin__c = false;
                                }
                            }
                            if(originalReq.ReinsurerStatus__c != AP_Constant.statusSetup) {
                                // RRA - ticket 1392 - 11012023 
                                setOriginalReqId.add(originalReq.Id);
                                setOriginalIdReq.add(originalReq.OriginalRequest__c);
                                claimContact = originalReq.Claims_contact__c;
                                mapOriginalReqs.put(originalReq.Id, originalReq);
                                mapLastVersReqs.put(originalReq.OriginalRequest__c, originalReq);
                               
                                if(setOriginalReqId.size() > 0){
                                    lstLastVersionRequest = [SELECT Id, Name, PremiumDepositMode__c,LossDeposit__c, TECH_isAdmin__c, Claims_contact__c, OriginalRequest__c,SignedShare__c, WrittenShare__c, WrittenShareResponse__c, PremiumDeposit__c, RetrocessionBrokerage__c, Deductions__c,Collateral_Provider_City__c, Collateral_provider_Code__c, Collateral_provider_Name__c,
                                                            Type_of_Code__c, DescriptionReinsurerLimitColl__c, Broker_s_Ref__c, Reinsurer_s_Ref__c, LossDepositMode__c
                                                             FROM Request__c
                                                             WHERE OriginalRequest__c IN :setOriginalReqId
                                                             AND LastVersionSent__c = TRUE
                                                             AND LastVersionAnswered__c = TRUE];
            
                                    for(Request__c lastVersionReq : lstLastVersionRequest){
                                        lastVersionReq.Claims_contact__c = claimContact;
                                        lastVersionReq.SignedShare__c = mapOriginalReqs.get(lastVersionReq.OriginalRequest__c).SignedShare__c;
                                        lastVersionReq.WrittenShare__c = mapOriginalReqs.get(lastVersionReq.OriginalRequest__c).WrittenShare__c;
                                        lastVersionReq.WrittenShareResponse__c = mapOriginalReqs.get(lastVersionReq.OriginalRequest__c).WrittenShareResponse__c;
                                        lastVersionReq.PremiumDeposit__c = mapOriginalReqs.get(lastVersionReq.OriginalRequest__c).PremiumDeposit__c;
                                        lastVersionReq.RetrocessionBrokerage__c = mapOriginalReqs.get(lastVersionReq.OriginalRequest__c).RetrocessionBrokerage__c;
                                        lastVersionReq.Deductions__c = mapOriginalReqs.get(lastVersionReq.OriginalRequest__c).Deductions__c;

                                        lastVersionReq.Collateral_Provider_City__c = mapOriginalReqs.get(lastVersionReq.OriginalRequest__c).Collateral_Provider_City__c;
                                        lastVersionReq.Collateral_provider_Code__c = mapOriginalReqs.get(lastVersionReq.OriginalRequest__c).Collateral_provider_Code__c;
                                        lastVersionReq.Collateral_provider_Name__c = mapOriginalReqs.get(lastVersionReq.OriginalRequest__c).Collateral_provider_Name__c;
                                        lastVersionReq.Type_of_Code__c = mapOriginalReqs.get(lastVersionReq.OriginalRequest__c).Type_of_Code__c;
                                        lastVersionReq.DescriptionReinsurerLimitColl__c = mapOriginalReqs.get(lastVersionReq.OriginalRequest__c).DescriptionReinsurerLimitColl__c;
                                        lastVersionReq.Broker_s_Ref__c = mapOriginalReqs.get(lastVersionReq.OriginalRequest__c).Broker_s_Ref__c;
                                        lastVersionReq.Reinsurer_s_Ref__c = mapOriginalReqs.get(lastVersionReq.OriginalRequest__c).Reinsurer_s_Ref__c;
                                        lastVersionReq.LossDepositMode__c = mapOriginalReqs.get(lastVersionReq.OriginalRequest__c).LossDepositMode__c;
                                        lastVersionReq.BrokerStatus__c = mapOriginalReqs.get(lastVersionReq.OriginalRequest__c).BrokerStatus__c;
                                        lastVersionReq.RiskCarrier__c = mapOriginalReqs.get(lastVersionReq.OriginalRequest__c).RiskCarrier__c;
                                        lastVersionReq.FinancialEntity__c = mapOriginalReqs.get(lastVersionReq.OriginalRequest__c).FinancialEntity__c;
                                        lastVersionReq.TECH_isAdmin__c = false;//RRA - ticket 1421 - 11092023
                                        
                                        //RRA - ticket 1632 - 04102023
                                        if (lastVersionReq.PremiumDeposit__c == '2'){
                                            lastVersionReq.PremiumDepositMode__c = null;
                                        }else if (lastVersionReq.PremiumDeposit__c == '1'){
                                            lastVersionReq.PremiumDepositMode__c = mapOriginalReqs.get(lastVersionReq.OriginalRequest__c).PremiumDepositMode__c;
                                        }
                                    }
                                }

                                System.debug('mapOriginalReqs == ' + mapOriginalReqs);
                                System.debug('mapLastVersReqs == ' + mapLastVersReqs);
                                System.debug('setOriginalReqId == ' + setOriginalReqId);


                                // RRA - tickets (1103 et 1401) - 11012023 - Update line original Request 
                                List<Request__c> lstReqUpdateOrigReq = [SELECT Id, TECH_isAdmin__c, OriginalRequest__c, Claims_contact__c,SignedShare__c, PremiumDepositMode__c, WrittenShare__c, WrittenShareResponse__c, PremiumDeposit__c, RetrocessionBrokerage__c, Deductions__c,Collateral_Provider_City__c, Collateral_provider_Code__c, Collateral_provider_Name__c,Type_of_Code__c, DescriptionReinsurerLimitColl__c, Broker_s_Ref__c, Reinsurer_s_Ref__c, LossDepositMode__c FROM Request__c WHERE  Id IN: setOriginalIdReq];//RRA - ticket 1421 - 11092023 and  RRA - ticket 1632 - 02102023

                                System.debug('lstReqUpdateOrigReq == ' + lstReqUpdateOrigReq);

                                for (Request__c reqOrig : lstReqUpdateOrigReq){
                                    if (reqOrig.OriginalRequest__c == null){
                                        reqOrig.Claims_contact__c = claimContact;
                                        reqOrig.SignedShare__c = mapLastVersReqs.get(reqOrig.Id).SignedShare__c;
                                        reqOrig.WrittenShare__c = mapLastVersReqs.get(reqOrig.Id).WrittenShare__c;
                                        reqOrig.WrittenShareResponse__c = mapLastVersReqs.get(reqOrig.Id).WrittenShareResponse__c;
                                        reqOrig.PremiumDeposit__c = mapLastVersReqs.get(reqOrig.Id).PremiumDeposit__c;
                                        reqOrig.RetrocessionBrokerage__c = mapLastVersReqs.get(reqOrig.Id).RetrocessionBrokerage__c;
                                        reqOrig.Deductions__c = mapLastVersReqs.get(reqOrig.Id).Deductions__c;

                                        reqOrig.Collateral_Provider_City__c = mapLastVersReqs.get(reqOrig.Id).Collateral_Provider_City__c ;
                                        reqOrig.Collateral_provider_Code__c = mapLastVersReqs.get(reqOrig.Id).Collateral_provider_Code__c ;
                                        reqOrig.Collateral_provider_Name__c = mapLastVersReqs.get(reqOrig.Id).Collateral_provider_Name__c;
                                        reqOrig.Type_of_Code__c = mapLastVersReqs.get(reqOrig.Id).Type_of_Code__c;
                                        reqOrig.DescriptionReinsurerLimitColl__c = mapLastVersReqs.get(reqOrig.Id).DescriptionReinsurerLimitColl__c;
                                        reqOrig.Broker_s_Ref__c = mapLastVersReqs.get(reqOrig.Id).Broker_s_Ref__c;
                                        reqOrig.Reinsurer_s_Ref__c = mapLastVersReqs.get(reqOrig.Id).Reinsurer_s_Ref__c;
                                        reqOrig.LossDepositMode__c = mapLastVersReqs.get(reqOrig.Id).LossDepositMode__c;
                                        
                                        //RRA - ticket 1632 - 04102023
                                        if (reqOrig.PremiumDeposit__c == '2'){
                                            reqOrig.PremiumDepositMode__c = null;
                                        }else if (reqOrig.PremiumDeposit__c == '1'){
                                            reqOrig.PremiumDepositMode__c = mapLastVersReqs.get(reqOrig.Id).PremiumDepositMode__c; 
                                        }
                                        reqOrig.BrokerStatus__c = mapLastVersReqs.get(reqOrig.Id).BrokerStatus__c;
                                        reqOrig.RiskCarrier__c = mapLastVersReqs.get(reqOrig.Id).RiskCarrier__c;
                                        reqOrig.FinancialEntity__c = mapLastVersReqs.get(reqOrig.Id).FinancialEntity__c;
                                    }
                                }
                                if (lstReqUpdateOrigReq.size()>0){
                                    update lstReqUpdateOrigReq;
                                }
                            }
                        }
                        
                        if(lstRequests.size() > 0){
                            update lstRequests;
                        }
    
                        if(lstLastVersionRequest.size() > 0){
                            update lstLastVersionRequest;
                        }
                        //RRA - ticket 1866 - 16012023
                        updateRequestForLossDeposit (lstRequests);
                        updateRequestForLossDeposit (lstLastVersionRequest);
                    }
                    /*else{
                        Set<Id> setOriginalReqId = new Set<Id>();
                        String claimContact = '';
                        Map<Id, Request__c> mapOriginalReqs = new Map<Id, Request__c>();
    
    
                        for(Request__c originalReq : lstRequests){
                            setOriginalReqId.add(originalReq.Id);
                            claimContact = originalReq.Claims_contact__c;
                            mapOriginalReqs.put(originalReq.Id, originalReq);
                        }
    
                        List<Request__c> lstLastVersionRequest = new List<Request__c>();
    
                        if(setOriginalReqId.size() > 0){
                            lstLastVersionRequest = [SELECT Id, Name, Claims_contact__c, OriginalRequest__c,
                                                    Collateral_Provider_City__c, Collateral_provider_Code__c, Collateral_provider_Name__c,
                                                    Type_of_Code__c, DescriptionReinsurerLimitColl__c, Broker_s_Ref__c, Reinsurer_s_Ref__c, LossDepositMode__c
                                                     FROM Request__c
                                                     WHERE OriginalRequest__c IN :setOriginalReqId
                                                     AND LastVersionSent__c = TRUE
                                                     AND LastVersionAnswered__c = TRUE];
    
                            for(Request__c lastVersionReq : lstLastVersionRequest){
                                lastVersionReq.Claims_contact__c = claimContact;
                                lastVersionReq.Collateral_Provider_City__c = mapOriginalReqs.get(lastVersionReq.OriginalRequest__c).Collateral_Provider_City__c;
                                lastVersionReq.Collateral_provider_Code__c = mapOriginalReqs.get(lastVersionReq.OriginalRequest__c).Collateral_provider_Code__c;
                                lastVersionReq.Collateral_provider_Name__c = mapOriginalReqs.get(lastVersionReq.OriginalRequest__c).Collateral_provider_Name__c;
                                lastVersionReq.Type_of_Code__c = mapOriginalReqs.get(lastVersionReq.OriginalRequest__c).Type_of_Code__c;
                                lastVersionReq.DescriptionReinsurerLimitColl__c = mapOriginalReqs.get(lastVersionReq.OriginalRequest__c).DescriptionReinsurerLimitColl__c;
                                lastVersionReq.Broker_s_Ref__c = mapOriginalReqs.get(lastVersionReq.OriginalRequest__c).Broker_s_Ref__c;
                                lastVersionReq.Reinsurer_s_Ref__c = mapOriginalReqs.get(lastVersionReq.OriginalRequest__c).Reinsurer_s_Ref__c;
                                lastVersionReq.LossDepositMode__c = mapOriginalReqs.get(lastVersionReq.OriginalRequest__c).LossDepositMode__c;
                                lastVersionReq.BrokerStatus__c = mapOriginalReqs.get(lastVersionReq.OriginalRequest__c).BrokerStatus__c;
                                lastVersionReq.RiskCarrier__c = mapOriginalReqs.get(lastVersionReq.OriginalRequest__c).RiskCarrier__c;
                                lastVersionReq.FinancialEntity__c = mapOriginalReqs.get(lastVersionReq.OriginalRequest__c).FinancialEntity__c;
                            }
                        }
    
                        if(lstRequests.size() > 0){
                            update lstRequests;
                        }
    
                        if(lstLastVersionRequest.size() > 0){
                            update lstLastVersionRequest;
                        }
                    }*/
                }
                mapResults.put('Success','Success');
                mapResults.put('valueMinor', valueMinor);
                mapResults.put('nandalo', nandalo);
                return mapResults;
            /*}
            catch(Exception ex){
                Database.rollback(sp);
                mapResults.put('Error', ex.getMessage());
                return mapResults;
            }*/
        }
    
        /** RRA - ticket 1866 - 16012023
        * @description Method to update LossDeposit and Tech_isAdmin flag for objects Requests
        * @param List<Request__c> lstRequestToUpdated
        */
        public static void updateRequestForLossDeposit (List<Request__c> lstRequestToUpdated){
            List<Request__c> lstRequestUpdated = new List<Request__c> ();
            for (Request__c request : lstRequestToUpdated){
                if (request.LossDepositMode__c != null && request.LossDeposit__c == '2'){
                    request.LossDeposit__c = '1';
                }
                if (request.LossDepositMode__c != null && request.LossDeposit__c == '1' && request.TECH_isAdmin__c == false){
                    request.TECH_isAdmin__c = true; 
                }
                lstRequestUpdated.add(request);
            }
            if (lstRequestUpdated.size()>0){
                update lstRequestUpdated;
            }
        }
        /**
        * @description Method to get Accounts of the searched value
        * @param String value, Id requestId, String lookupName
        * @return List<SObjectResult>
        */
        @AuraEnabled(Cacheable=true)
        public static List<SObjectResult> getLookupAccountField(String value, Id requestId, String lookupName) {
            List<SObjectResult> sObjectResultList = new List<SObjectResult>();
            Map<String, Id> mapRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectAcc});
            String recordTypeIdReinsurer = mapRecTypeId.get(AP_Constant.accRTReinsurer);
            String query = '';
            List<AccountContactRelation> lstAccountContactRelation = new List<AccountContactRelation>();
            Id parentId;
    
            Request__c request = [SELECT Id, Name, RiskCarrier__c, FinancialEntity__c, Reinsurer__c, Reinsurer__r.ParentId FROM Request__c WHERE Id = :requestId];
    
            if(request != null){
                parentId = request.Reinsurer__r.ParentId;
            }
            // SRA - ticket 1012
            Profile userProfile = [SELECT Id, Name FROM Profile WHERE Id =: UserInfo.getProfileId()];
    
            if(String.isNotEmpty(value)) {
                String strValue = '%' + String.escapeSingleQuotes(value.trim()) + '%';
    
               // if(lookupName == 'RiskCarrier'){
                    //query = 'SELECT Id,Name FROM Account WHERE Name LIKE :strValue and RecordTypeId = :recordTypeIdReinsurer and IsActive__c = TRUE and IsRiskCarrier__c = TRUE AND ParentId = :parentId';
                    // query = 'SELECT Id,Name FROM Account WHERE Name LIKE \'%' + value.trim() + '%\' and RecordTypeId = :recordTypeIdReinsurer and IsActive__c = TRUE and IsRiskCarrier__c = TRUE AND ParentId = :parentId';
                //}
                //else if(lookupName == 'FinancialEntity'){
                   // query = 'SELECT Id,Name FROM Account WHERE Name LIKE :strValue and RecordTypeId = :recordTypeIdReinsurer and IsActive__c = TRUE and IsFinancialEntity__c = TRUE AND ParentId = :parentId';
                    // query = 'SELECT Id,Name FROM Account WHERE Name LIKE \'%' + value.trim() + '%\' and RecordTypeId = :recordTypeIdReinsurer and IsActive__c = TRUE and IsFinancialEntity__c = TRUE AND ParentId = :parentId';
                //}
    
                // SRA - ticket 1012 - Modify filter according the profile.
                if(lookupName == 'RiskCarrier'){
                     query = 'SELECT Id, Name FROM Account WHERE Name LIKE :strValue and IsActive__c = TRUE and RecordTypeId = :recordTypeIdReinsurer and IsRiskCarrier__c = TRUE ';
                }
                else if(lookupName == 'FinancialEntity'){
                    query = 'SELECT Id, Name FROM Account WHERE Name LIKE :strValue and IsActive__c = TRUE and RecordTypeId = :recordTypeIdReinsurer and IsFinancialEntity__c = TRUE ';             
                }
    
                if(userProfile.Name != AP_Constant.profileSysAdminAGRe){
                    query += ' AND ParentId = :parentId ';
                }
    
                for(SObject so : Database.query(query)) {
                    String fieldvalue = (String)so.get('Name');
                    sObjectResultList.add(new SObjectResult(fieldvalue, so.Id));
                }
            }
            return sObjectResultList;
        }
    
        /**
        * @description Method to send mail for Signed Requests
        * @param Request__c parentRequest, List<Request__c> lstRelatedRequests
        * @return List<SObjectResult>
        */
        @AuraEnabled
        public static Map<String, Object> sendMail(Request__c parentRequest, List<Request__c> lstRelatedRequests){
            Map<String, Object> mapResults = new Map<String, Object>();
            List<String> lstCCEmailsToSend = new List<String>();
            String strLstCCEmail = null;
            String strLstCCEmailDisplay = null;
            String brokerReinsurerName; //RRA - ticket 1761 - 14112023
            Savepoint sp = Database.setSavepoint();
            
    
            try {
                
                for (Request__c request : lstRelatedRequests){
                    if (request.Broker__c != null && request.Reinsurer__c != null){
                        brokerReinsurerName = 'by ' + request.TECH_ReinsurerName__c + ' (via ' + request.TECH_BrokerName__c + ') ';  
                    }else if (request.Broker__c == null && request.Reinsurer__c != null){
                        brokerReinsurerName = 'by ' + request.TECH_ReinsurerName__c;
                    }
                }
                Id requestId = parentRequest.Id;
                Id programId = parentRequest.Program__c;
                //RRA - ticket 1761 - 14112023
                
                EmailTemplate emailTemplateRequestAnswer = [SELECT Id, Name FROM EmailTemplate WHERE Name = :AP_Constant.emailTemplateRequestAnswer];
                List<Messaging.SingleEmailMessage> lstMails =  new List<Messaging.SingleEmailMessage>();
    
                User user = [SELECT Id, ContactId, Email FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
                //RRA - ticket 1761 - 14112023
                //For AXA SA used as sender email address
                User userAXASA = [SELECT Id, Name, Email FROM User WHERE Id =:System.label.AXA_SA_Sender LIMIT 1];
                Contact contact = [SELECT Id, Name, Email FROM Contact WHERE Id = :user.ContactId AND Account.IsActive__c = TRUE ];
    
                if(programId != null){
                    Program__c program = [SELECT Id, Macro_L_O_B__c, Name, PrincipalCedingCompany__r.Name, PrincipalCedingCompany__r.EmailPCLife__c
                                          FROM Program__c 
                                          WHERE Id = :programId];
    
                    strLstCCEmail = program.PrincipalCedingCompany__r.EmailPCLife__c;
    
                    if(strLstCCEmail != null ){
                        if(strLstCCEmail.contains(';')){
                            lstCCEmailsToSend = strLstCCEmail.split(';');
                        }
                        else{
                            lstCCEmailsToSend.add(strLstCCEmail);
                        }
                    }
    
                    for(String pccEmail : lstCCEmailsToSend){
                        if(strLstCCEmailDisplay == null){
                            strLstCCEmailDisplay = pccEmail;
                        }
                        else{
                            strLstCCEmailDisplay = strLstCCEmailDisplay + ' ' + pccEmail;   
                        }
                    }
                }
    
                Messaging.SingleEmailMessage m;
                m = Messaging.renderStoredEmailTemplate(emailTemplateRequestAnswer.Id, UserInfo.getUserId(), requestId);
                m.setSaveAsActivity(false);
    
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                List<String> sendTo = new List<String>();
                sendTo.add(contact.Email);
                mail.setToAddresses(sendTo);
                //RRA - ticket 1761 - 14112023
                OrgWideEmailAddress[] owea = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'actor.po@axa.com'];
                if (owea.size()>0) {
                    mail.setOrgWideEmailAddressId(owea.get(0).Id);
                }
                mail.setReplyTo(userAXASA.Email); //RRA - ticket 1761 - 14112023
                String subject = m.getSubject(); //RRA - ticket 1761 - 14112023
                subject = subject.replace('{brokerReinsurerName}', brokerReinsurerName); //RRA - ticket 1761 - 14112023
                mail.setSubject(subject); //RRA - ticket 1761 - 14112023
                //mail.setReplyTo(UserInfo.getUserEmail());
                //mail.setSenderDisplayName(UserInfo.getFirstName() + ' ' + UserInfo.getLastName());
    
                if(lstCCEmailsToSend.size() > 0){
                    mail.setCcAddresses(lstCCEmailsToSend);
                }
    
                String htmlBody = m.htmlBody;
                String domainURL = URL.getSalesforceBaseUrl().toExternalForm();
                String answerPageLink = '<a href="'+domainURL+'/portal/s/request?c__details='+programId+'-'+requestId+'-Signing">here.</a>';
                String htmlInternetLink = '<a href="'+domainURL+'/portal/s/homepage">ACTOR Page</a>';
    
                htmlBody = htmlBody.replace('[ACTOR link TreatiesReinsurers/QuotationReply page]', answerPageLink);
                htmlBody = htmlBody.replace('{InternetLink}', htmlInternetLink);
                htmlBody = htmlBody.replace('{statusSentChanged}', 'sent');
    
                String strLstCCEmailDisplayInEmail = strLstCCEmailDisplay != null ? strLstCCEmailDisplay : '';
                htmlBody = htmlBody.replace('[Actor Mail box per instance]', strLstCCEmailDisplayInEmail);
    
                mail.setHtmlBody(htmlBody);
                //mail.setSubject(m.getSubject());
                lstMails.add(mail);
                Messaging.sendEmail((List<Messaging.Email>) lstMails);
                mapResults.put('Success', 'Success');
            }
            catch (Exception ex) {
                Database.rollback(sp);
                mapResults.put('Error', ex.getMessage());
            }
            return mapResults;
        }
    
        /**
        * @description Method to get Signatories contact for selected reinsurer
        * @param Id reinsurerId, Id programId
        * @return Map<String, Object>
        */
        @AuraEnabled
        public static Map<String, Object> getSignatories(Id reinsurerId, Id programId){
            Map<String,Object> mapResult = new Map<String,Object>();
    
            try{
                /*List<Contact> lstSignatories = [SELECT Id,
                                                       AccountId,
                                                       Salutation,
                                                       FirstName,
                                                       LastName,
                                                       Email,
                                                       MobilePhone,
                                                       TECH_ProgramId__c,
                                                       Order_of_signatories__c, //MRA 1103 07/07/2022
                                                       RecordTypeId
                                                FROM Contact
                                                WHERE AccountId =: reinsurerId
                                                AND RecordType.DeveloperName =: AP_Constant.contactSignatory
                                                AND TECH_ProgramId__c =: programId
                                                ORDER BY Order_of_signatories__c //MRA 1103 07/07/2022
                                                ];*/
                List<ContactReinsurerProgramRelation__c> lstSignatories = [SELECT Id,Name, ContactId__r.Salutation,ContactId__r.LastName,ContactId__r.FirstName,ContactId__r.Email,ContactId__r.MobilePhone,ProgramId__r.Name,ReinsurerId__r.Name,OrderOfSignatory__c
                                                FROM ContactReinsurerProgramRelation__c 
                                                WHERE ReinsurerId__c =: reinsurerId
                                                AND ProgramId__c =: programId
                                                AND ContactId__c != null //RRA - ticket 1855 - HotFix 28122023
                                                ORDER BY OrderOfSignatory__c
                                                ] ;//MRA 19/05/23 - Contact Signatory Rebuild 
                mapResult.put('Success', lstSignatories);
                System.debug('mapResult == ' + mapResult);
            }
            catch(Exception ex){
                mapResult.put('Error', ex.getMessage());
            }
            return mapResult;
        }
    
        public class SObjectResult {
            @AuraEnabled public String recName;
            @AuraEnabled public Id recId;
    
            public SObjectResult(String recNameTemp, Id recIdTemp) {
                recName = recNameTemp;
                recId = recIdTemp;
            }
            public SObjectResult(){ }
        }
    }