public without sharing class LWC49_SendSARequest {
    /**************************************************************************************
    -- - Author        : Spoon Consulting
    -- - Description   : Controller for Lightning Web Component lwc49SendSaRequest
    -- Maintenance History:
    --
    -- Date         Name  Version  Remarks
    -- -----------  ----  -------  -------------------------------------------------------
    -- 27-NOV-2020  MBE   1.0      Initial version
    -- 08-JUN-2021  MBE   1.1      W-0985 - Special Acceptance - Le SA ID sur de la mêm SA n'est pas unique d'un portail à un autre
    -- 30-JUN-2021  MBE   1.2      W-0998 - Special Acceptance - Contact cédante à retrouver pour le inform ceding company
    -- 05-JUL-2021  MBE   1.3      W-0973 - Special Acceptance - Problème de maj statut SA suite à une réponse sur le portail BR
    -- 13-JUL-2021  MBE   1.4      W-0894 - ODS - TECH_SentByUser__c seems empty after a modification of a lead request
    -- 11-AUG-2021  MBE   1.5      Code Optimization - Use Ternary Operator
    -- 09-NOV-2021  MBE   1.6      W-1037 - remove renderedStoredEmailTemplate from Loop
    -- 21-DEC-2021  MBE   1.7      W-0932 - Transversal - Ne pas proposer des utilisateurs inactifs
    --------------------------------------------------------------------------------------
    **************************************************************************************/
    
        /**
        * @description Method to get Program details
        * @param String programId
        * @return Map<String, Object>
        */
        @AuraEnabled(Cacheable = true)
        public static Map<String, Object> getProgramDetails(String programId){
            Map<String, Object> mapResults = new Map<String, Object>();
    
            List<Program__c> lstProgram = [SELECT Id, Name, toLabel(Nature__c), Macro_L_O_B__c, PrincipalCedingCompany__r.Name, UwYear__c
                                           FROM Program__c
                                           WHERE Id = :programId LIMIT 1];
    
            mapResults.put('lstProgram', lstProgram);
            return mapResults;
        }
    
        /**
        * @description Method to get document status
        * @param List<Request__c> lstSaRequests, List<ContentVersion> lstDocument
        * @return Map<String, Object>
        */
        @AuraEnabled
        public static Map<String, Object> getDocumentStatus(List<Request__c> lstSaRequests, List<ContentVersion> lstDocument){
            Map<String, Object> mapResults = new Map<String, Object>();
            Map<Id, String> mapContentVersionStatus = new Map<Id, String>();
            List<DocumentVisibility__c> lstDocumentVisibilities = new List<DocumentVisibility__c>();
            Set<Id> setSentContentVersionId = new Set<Id>();
            Request__c saRequest = new Request__c();
    
            //get the first request - Program|Treaty|Broker|Reinsurer|SpecialAcceptance
    
            for(Request__c req : lstSaRequests){
                if(req.Pool__c == null){
                    saRequest = req;
                }
            }
    
            if(saRequest != null){
                //select all document visibility for Program|Treaty|Broker|Reinsurer|SpecialAcceptance -> lstDocumentVisibilities
    
                lstDocumentVisibilities = [SELECT Id, ContentVersionId__c, Treaty__c, Broker__c, Reinsurer__c, SpecialAcceptance__c
                                           FROM DocumentVisibility__c
                                           WHERE Treaty__c = :saRequest.Treaty__c
                                           AND Broker__c = :saRequest.Broker__c
                                           AND Reinsurer__c = :saRequest.Reinsurer__c
                                           AND SpecialAcceptance__c = :saRequest.Special_Acceptance__c];
    
                for(DocumentVisibility__c docVis : lstDocumentVisibilities){
                    setSentContentVersionId.add(docVis.ContentVersionId__c);
                }
    
                //loop over lstDocument to  check if content version id found in setContentVersionAlreadySent
                //if found -> Sent
                //else -> Not Sent
    
                for(ContentVersion contentVersion : lstDocument){
                    if(setSentContentVersionId.contains(contentVersion.Id)){
                        mapContentVersionStatus.put(contentVersion.Id, 'Sent');
                    }
                    else{
                        mapContentVersionStatus.put(contentVersion.Id, 'Not Sent');
                    }
                }
            }
    
            mapResults.put('mapContentVersionStatus', mapContentVersionStatus);
            return mapResults;
        }
    
        /**
       * @description Method to get send/update Special Acceptance Request
       * @param List<Request__c> lstSaRequests, List<AccountContactRelation> lstAccountContact, List<String> lstPoolIdToEmail, List<ContentVersion> lstDocument, String buttonAction
       * @return Map<String, Object>
       */
        @AuraEnabled
        public static Map<String, Object> sendUpdateSaRequest(List<Request__c> lstSaRequests, List<AccountContactRelation> lstAccountContact, List<String> lstPoolIdToEmail, List<ContentVersion> lstDocument, String buttonAction){
            Savepoint sp = Database.setSavepoint();
            Map<String, Object> mapResults = new Map<String, Object>();
            Map<Id, Request__c> mapRequestSentByOriginalReqId = new Map<Id, Request__c>();
            Map<Id, List<Request__c>> mapLstRequestByAccID = new Map<Id, List<Request__c>>();
            Map<Id, List<AccountContactRelation>> mapLstAccountContactByAccID = new Map<Id, List<AccountContactRelation>>(); 
            Map<Id, String> mapPoolIdToEmail = new Map<Id,String>();      
            Id emailTempSendSaReqBrokerId;
            Id emailTempSendSaReqReinsurerId;
            Id emailTempSendSaReqPoolId;
            Id emailTempUpdateSaReqBrokerId;
            Id emailTempUpdateSaReqReinsurerId;
            Id emailTempUpdateSaReqPoolId;
            Id emailTempRemindSaReqBrokerId;
            Id emailTempRemindSaReqReinsurerId;
            Id emailTempRemindSaReqPoolId;
            Id emailTempNotifySaReqBrokerId;
            Id emailTempNotifySaReqReinsurerId;
            String strDocumentName = '';
            List<String> lstEmailTemplateName = new List<String>();
            List<EmailTemplate> lstEmailTemplate = new List<EmailTemplate>();
            List<Request__c> lstAllRequests = new List<Request__c>();
            List<Request__c> lstRequestNewVersion = new List<Request__c>();
            List<DocumentVisibility__c> lstDocumentVisibilityToInsert = new List<DocumentVisibility__c>();
            List<DocumentVisibility__c> lstAllDocumentVisibilities = new List<DocumentVisibility__c>();  
            List<Messaging.SingleEmailMessage> lstMails = new List<Messaging.SingleEmailMessage>();
            List<Id> lstOriginalRequestId = new List<Id>();
            List<String> lstSaPCCEmailsToSend = new List<String>();
            List<String> lstRequestFields = AP_Constant.getCreatableFieldsByObjName(AP_Constant.sObjectRequest);
            String strRequestFields = String.join(lstRequestFields, ', ');
            String strSetup = AP_Constant.statusSetup;
            String pccId;
            String saEmailOfPCC;
            String saEmailOfPCCDisplay;
            Set<String> setAllDocumentVisibilities = new Set<String>();
            Id specialAcceptanceId;

            List<Request__c> lstSarPoolLeader = new List<Request__c>();
            
            //List<Request__c> lstRequestToUpdateFinal = new  List<Request__c> (); // RRA 1102
            // List<Id> lstIdReqSA = new  List<Id> ();  // RRA 1102
            
            try {
                User connectedUser = [SELECT Id, Name, Email FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
    
                Network networkObj = [SELECT Id
                                      FROM Network
                                      WHERE Name =: System.Label.Actor_portal_name];
    
                String url = Network.getLoginUrl(networkObj.Id);
                List <String> urlArr = url.split('login');
                String htmlInternetLink = '<a href="' + urlArr[0] + 'homepage">ACTOR New Gen HomePage</a>';
                Id userId = UserInfo.getUserId();
                String saId = lstSaRequests[0].Special_Acceptance__c;
    
                // RRA - 1102
                /*for (Request__c reqSA : lstSaRequests){
                    lstIdReqSA.add(reqSA.Id);
                }*/
    
                String querySaRequest = 'SELECT Id, TECH_TreatyName__c, Treaty__r.PlacementShare_Perc__c, TECH_BrokerName__c, TECH_IsBrokerPresent__c, TECH_ReinsurerName__c, TECH_Layer__c, TECH_UWyear__c,  SigningRegionalManager__r.Email '
                        + ', RiskCarrier__r.Name, FinancialEntity__r.Name, Program__r.LossDepositMode__c, Program__r.LossDeposit__c, Program__r.UwYear__c '
                        + ', Treaty__r.LossDepositMode__c, Treaty__r.LossDeposit__c, Treaty__r.Deductions__c, TreatyReference__c, Treaty__r.TypeofTreaty__c '
                        + ', Treaty__r.PremiumDeposit__c, Program__r.LossDepositLevel__c, Pool__r.Name, Pool__r.AssignedTo__r.Email, Pool__r.AssignedTo__c, Program__r.Name, Program__r.Principalcedingcompany__r.Name, Program__r.PrincipalCedingCompany__c '
                        + ', Special_Acceptance__r.SpecialAcceptanceName__c, Special_Acceptance__r.CoveredCedingCompany__r.Name, Special_Acceptance__r.Type__c, '
                        +  strRequestFields
                        + ' from Request__c where Id IN :lstSaRequests ORDER BY Special_Acceptance__r.SpecialAcceptanceName__c asc'; //RRA - 1086'; ===> Replace lstSaRequests by lstIdReqSA ( RRA 1102 )
    
                List<Request__c> lstRequestToUpdate = Database.query(querySaRequest);
    
                if(lstRequestToUpdate.size() > 0){
                    pccId = lstRequestToUpdate[0].Program__r.PrincipalCedingCompany__c;   
    
                    if(pccId != null){
                        List<Account> lstPCCAccount = [SELECT Id, EmailSA__c FROM Account WHERE Id = :pccId LIMIT 1];
                        if(lstPCCAccount.size() > 0){
                            saEmailOfPCC = lstPCCAccount[0].EmailSA__c;
    
                            if(saEmailOfPCC != null ){
                                if(saEmailOfPCC.contains(';')){
                                    lstSaPCCEmailsToSend = saEmailOfPCC.split(';');
                                }
                                else{
                                    lstSaPCCEmailsToSend.add(saEmailOfPCC);
                                }
                            }
    
                            for(String pccEmail : lstSaPCCEmailsToSend){
                                if(saEmailOfPCCDisplay == null){
                                    saEmailOfPCCDisplay = pccEmail;
                                }
                                else{
                                    saEmailOfPCCDisplay = saEmailOfPCCDisplay + ' ' + pccEmail;   
                                }
                            }
                        }
                    }             
                }
    
                for(Request__c req : lstRequestToUpdate){
                    String saStatusForNotiyBtn = req.SA_Request_Status__c;
                    if(buttonAction == 'send' || buttonAction == 'update'){
                        req.SA_Request_Status__c = AP_Constant.statusSent;
                        req.LastVersionAnswered__c = true;
                        req.LastVersionSent__c = true;
                        
                        req.LastSentDate__c = System.today();
                    }
                    else if(buttonAction == 'notify'){
                        req.SA_Request_Status__c = AP_Constant.statusNotified;
                        req.LastSentDate__c = System.today();
                        req.ExpectedResponseDate__c = System.today();
                        req.ResponseDate__c = System.today();
                    }
    
                    if(buttonAction == 'send' || buttonAction == 'update' || buttonAction == 'remind' || buttonAction == 'notify' ){
                        req.SentBy__c = connectedUser.Id;
                    }
                    
                    if(lstSaRequests[0].ExpectedResponseDate__c != null){
                        req.ExpectedResponseDate__c = lstSaRequests[0].ExpectedResponseDate__c;
                    }
    
                    if(lstSaRequests[0].Comments__c != null){
                        req.Comments__c = lstSaRequests[0].Comments__c;
                    }
    
                    if(req.OriginalRequest__c == null){
                        mapRequestSentByOriginalReqId.put(req.Id, req);
                    }
                    else{
                        mapRequestSentByOriginalReqId.put(req.OriginalRequest__c, req);
                    }
    
                    // if(buttonAction == 'send' || (buttonAction == 'notify' && saStatusForNotiyBtn == 'Agreed')){
                    if(buttonAction == 'send' || (buttonAction == 'notify' && req.Special_Acceptance__r.Type__c == '2')){
                        //to do later: button notify (sa type : declarative) - to create new version + request sharing - visible in broker/reinsurer 
                        //to create version + share request with broker/reinsurer for all leader/pool/follower as leader
                        //SA de type declaration: attente du Notify pour partager mais du coup partage à tous les intervenants en read only pool, leader, follower. pas d'envoi d'email aux leaders/pool.
                        //05/03:  Create new version for notify only if SA type = 'Submission'
                        req.VersionMajor__c = 1;
                        req.LastVersionSent__c = true; //RRA - ticket 1488 - 04052023
                        req.LastVersionAnswered__c = true; //RRA - ticket 1488 - 04052023
    
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
    
                        if(buttonAction == 'send'){
                            if(newVersionRequest.ExpectedResponseDate__c < Date.today()){
                                newVersionRequest.SA_Request_Status__c = AP_Constant.statusTimeout;
                            }
                        }
                        else if(buttonAction == 'notify'){
                            newVersionRequest.SA_Request_Status__c = AP_Constant.statusNotified;
                        }
                        lstRequestNewVersion.add(newVersionRequest);
                    }
                    // lstRequestToUpdateFinal.add(req); // RRA - 1102
                }
    
                if(lstRequestToUpdate.size() > 0){
                    update lstRequestToUpdate;
                }
    
                if(lstRequestNewVersion.size() > 0){
                    //insert lstRequestNewVersion; //RRA - ticket 1488 - 04052023
                }
    
                // RRA - 1102 Order Executive insert before update  => https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_triggers_order_of_execution.htm
    
                /*if(lstRequestToUpdateFinal.size() > 0){
                    update lstRequestToUpdateFinal;
                }*/
                if (lstRequestToUpdate[0].Special_Acceptance__c != null){
                    specialAcceptanceId = lstRequestToUpdate[0].Special_Acceptance__c; //RRA - 1488 - 04052023
                }
    
                lstAllRequests = [SELECT Id, Program__c, Treaty__c, Reinsurer__c, Broker__c, Pool__c, Special_Acceptance__c, SentBy__c FROM Request__c WHERE Special_Acceptance__c = :saId AND SA_Request_Status__c <> :strSetup AND Pool__c = NULL];
    
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
    
                //create document visibility for selected requests
                for(ContentVersion publicDoc : lstDocument){
                    for(Request__c selectedReq : lstAllRequests){
                        String strDocVis;
                        if(selectedReq.Broker__c == null){
                            strDocVis = publicDoc.Id + '-' + selectedReq.Treaty__c + '-' + selectedReq.Reinsurer__c;
                        }
                        else{
                            strDocVis = publicDoc.Id + '-' + selectedReq.Treaty__c + '-' + selectedReq.Reinsurer__c + '-' + selectedReq.Broker__c;
                        }
    
                        if(!setAllDocumentVisibilities.contains(strDocVis)){
                            DocumentVisibility__c docVis = new DocumentVisibility__c();
                            docVis.ContentVersionId__c = publicDoc.Id;
                            docVis.Program__c = selectedReq.Program__c;
                            docVis.Treaty__c = selectedReq.Treaty__c;
                            docVis.Reinsurer__c = selectedReq.Reinsurer__c;
                            docVis.SpecialAcceptance__c = selectedReq.Special_Acceptance__c;
    
                            if(selectedReq.Broker__c != null){
                                docVis.Broker__c = selectedReq.Broker__c;
                            }
    
                            lstDocumentVisibilityToInsert.add(docVis);
                        }
                    }
    
                    if(strDocumentName == ''){
                        strDocumentName = '<li style="text-align: left;">' + publicDoc.Title + '</li>';
                    }
                    else{
                        strDocumentName += '<li style="text-align: left;">' + publicDoc.Title + '</li>';
                    }
                }
    
                if(lstDocumentVisibilityToInsert.size() > 0){
                    insert lstDocumentVisibilityToInsert;
                }
    
                lstEmailTemplateName.add(AP_Constant.emailTempSendSaReqBroker);
                lstEmailTemplateName.add(AP_Constant.emailTempSendSaReqReinsurer);
                lstEmailTemplateName.add(AP_Constant.emailTempSendSaReqPool);
                lstEmailTemplateName.add(AP_Constant.emailTempUpdateSaReqBroker);
                lstEmailTemplateName.add(AP_Constant.emailTempUpdateSaReqReinsurer);
                lstEmailTemplateName.add(AP_Constant.emailTempUpdateSaReqPool);
                lstEmailTemplateName.add(AP_Constant.emailTempRemindSaReqBroker);
                lstEmailTemplateName.add(AP_Constant.emailTempRemindSaReqReinsurer);
                lstEmailTemplateName.add(AP_Constant.emailTempRemindSaReqPool);
                lstEmailTemplateName.add(AP_Constant.emailTempNotifySaReqBroker);
                lstEmailTemplateName.add(AP_Constant.emailTempNotifySaReqReinsurer);
    
                lstEmailTemplate = [SELECT Id, Name FROM EmailTemplate WHERE Name IN : lstEmailTemplateName];
    
                for(EmailTemplate emailTemplate : lstEmailTemplate){
                    if(emailTemplate.Name == AP_Constant.emailTempSendSaReqBroker){
                        emailTempSendSaReqBrokerId = emailTemplate.Id;
                    }
                    else if(emailTemplate.Name == AP_Constant.emailTempSendSaReqReinsurer){
                        emailTempSendSaReqReinsurerId = emailTemplate.Id;
                    }
                    else if(emailTemplate.Name == AP_Constant.emailTempSendSaReqPool){
                        emailTempSendSaReqPoolId = emailTemplate.Id;
                    }
                    else if(emailTemplate.Name == AP_Constant.emailTempUpdateSaReqBroker){
                        emailTempUpdateSaReqBrokerId = emailTemplate.Id;
                    }
                    else if(emailTemplate.Name == AP_Constant.emailTempUpdateSaReqReinsurer){
                        emailTempUpdateSaReqReinsurerId = emailTemplate.Id;
                    }
                    else if(emailTemplate.Name == AP_Constant.emailTempUpdateSaReqPool) {
                        emailTempUpdateSaReqPoolId = emailTemplate.Id;
                    }
                    else if(emailTemplate.Name == AP_Constant.emailTempRemindSaReqBroker){
                        emailTempRemindSaReqBrokerId = emailTemplate.Id;
                    }
                    else if(emailTemplate.Name == AP_Constant.emailTempRemindSaReqReinsurer){
                        emailTempRemindSaReqReinsurerId = emailTemplate.Id;
                    }
                    else if(emailTemplate.Name == AP_Constant.emailTempRemindSaReqPool){
                        emailTempRemindSaReqPoolId = emailTemplate.Id;
                    }
                    else if(emailTemplate.Name == AP_Constant.emailTempNotifySaReqBroker){
                        emailTempNotifySaReqBrokerId = emailTemplate.Id;
                    }
                    else if(emailTemplate.Name == AP_Constant.emailTempNotifySaReqReinsurer){
                        emailTempNotifySaReqReinsurerId = emailTemplate.Id;
                    }
                }
    
                Messaging.SingleEmailMessage emailTempSendSaReqBroker = new Messaging.SingleEmailMessage();       
                emailTempSendSaReqBroker = Messaging.renderStoredEmailTemplate(emailTempSendSaReqBrokerId, userId, lstSaRequests[0].Id);
    
                Messaging.SingleEmailMessage emailTempSendSaReqReinsurer = new Messaging.SingleEmailMessage();       
                emailTempSendSaReqReinsurer = Messaging.renderStoredEmailTemplate(emailTempSendSaReqReinsurerId, userId, lstSaRequests[0].Id);
    
                Messaging.SingleEmailMessage emailTempSendSaReqPool = new Messaging.SingleEmailMessage();       
                emailTempSendSaReqPool = Messaging.renderStoredEmailTemplate(emailTempSendSaReqPoolId, userId, lstSaRequests[0].Id);
    
                Messaging.SingleEmailMessage emailTempUpdateSaReqBroker = new Messaging.SingleEmailMessage();       
                emailTempUpdateSaReqBroker = Messaging.renderStoredEmailTemplate(emailTempUpdateSaReqBrokerId, userId, lstSaRequests[0].Id);
    
                Messaging.SingleEmailMessage emailTempUpdateSaReqReinsurer = new Messaging.SingleEmailMessage();       
                emailTempUpdateSaReqReinsurer = Messaging.renderStoredEmailTemplate(emailTempUpdateSaReqReinsurerId, userId, lstSaRequests[0].Id);
    
                Messaging.SingleEmailMessage emailTempUpdateSaReqPool = new Messaging.SingleEmailMessage();       
                emailTempUpdateSaReqPool = Messaging.renderStoredEmailTemplate(emailTempUpdateSaReqPoolId, userId, lstSaRequests[0].Id);
    
                Messaging.SingleEmailMessage emailTempRemindSaReqBroker = new Messaging.SingleEmailMessage();       
                emailTempRemindSaReqBroker = Messaging.renderStoredEmailTemplate(emailTempRemindSaReqBrokerId, userId, lstSaRequests[0].Id);
    
                Messaging.SingleEmailMessage emailTempRemindSaReqReinsurer = new Messaging.SingleEmailMessage();       
                emailTempRemindSaReqReinsurer = Messaging.renderStoredEmailTemplate(emailTempRemindSaReqReinsurerId, userId, lstSaRequests[0].Id);
    
                Messaging.SingleEmailMessage emailTempRemindSaReqPool = new Messaging.SingleEmailMessage();       
                emailTempRemindSaReqPool = Messaging.renderStoredEmailTemplate(emailTempRemindSaReqPoolId, userId, lstSaRequests[0].Id);
    
                Messaging.SingleEmailMessage emailTempNotifySaReqBroker = new Messaging.SingleEmailMessage();       
                emailTempNotifySaReqBroker = Messaging.renderStoredEmailTemplate(emailTempNotifySaReqBrokerId, userId, lstSaRequests[0].Id);
    
                Messaging.SingleEmailMessage emailTempNotifySaReqReinsurer = new Messaging.SingleEmailMessage();       
                emailTempNotifySaReqReinsurer = Messaging.renderStoredEmailTemplate(emailTempNotifySaReqReinsurerId, userId, lstSaRequests[0].Id);
    
    
                for(Request__c request : lstSaRequests){
                    List<Request__c> lstUpdRequest = new List<Request__c>();
                    String accountId;
    
                    if(request.Broker__c != null && request.BrokerStatus__c != '1'){ //&& request.BrokerStatus__c != '1' MRA 1618 22/10/2023 :Fix mail not sent to Reinsurer (Broker status 'Sleeping Partner')
                        accountId = request.Broker__c;
                    }
                    else{
                        accountId = request.Reinsurer__c;
                    }
    
                    if(mapLstRequestByAccID.containsKey(accountId)){
                        lstUpdRequest = mapLstRequestByAccID.get(accountId);
                    }
    
                    lstUpdRequest.add(request);
                    mapLstRequestByAccID.put(accountId, lstUpdRequest);
                }
    
                for(AccountContactRelation accountContact : lstAccountContact){
                    List<AccountContactRelation> lstUpdAccountContact = new List<AccountContactRelation>();
    
                    if(mapLstAccountContactByAccID.containsKey(accountContact.AccountId)){
                        lstUpdAccountContact = mapLstAccountContactByAccID.get(accountContact.AccountId);
                    }
        
                    lstUpdAccountContact.add(accountContact);
                    mapLstAccountContactByAccID.put(accountContact.AccountId, lstUpdAccountContact);
                }
    
                for(Id accountId : mapLstAccountContactByAccID.keySet()){
                    List<AccountContactRelation> lstAccountContactByAccId = mapLstAccountContactByAccID.get(accountId);
                    
                    for(AccountContactRelation accountContact : lstAccountContactByAccId) {
                        List<Request__c> lstRequestByAccId = new List<Request__c>();
    
                        if(mapLstRequestByAccID.containsKey(accountContact.AccountId)){
                            lstRequestByAccId = mapLstRequestByAccID.get(accountContact.AccountId);
                            Map<String, Request__c> mapReinsurerNameById = new Map<String, Request__c>();
    
                            for(Request__c req : lstRequestByAccId){
                                if(req.Reinsurer__c != null){
                                    if(!mapReinsurerNameById.containsKey(req.Reinsurer__c)){
                                        mapReinsurerNameById.put(req.Reinsurer__c, req);
                                    }
                                }
                            }
    
                            if(lstRequestByAccId.size() > 0){
                                Request__c req = lstRequestByAccId[0];
                                List<Messaging.SingleEmailMessage> lstEmailMessage = new List<Messaging.SingleEmailMessage>();
                                Messaging.SingleEmailMessage m = new Messaging.SingleEmailMessage();
                                Boolean isBroker = false;
    
                                m.setTargetObjectId(userId);
                                m.setWhatId(req.Id);
                                m.setSaveAsActivity(false);
    
                                if(req.Broker__c != null && req.BrokerStatus__c != '1'){
                                    isBroker = true;
    
                                    if(buttonAction == 'send'){
                                        // m = Messaging.renderStoredEmailTemplate(emailTempSendSaReqBrokerId, userId, req.Id);
                                        m.setTemplateId(emailTempSendSaReqBrokerId);
                                        m.setSubject(emailTempSendSaReqBroker.getSubject());
                                        m.setHtmlBody(emailTempSendSaReqBroker.htmlBody);
                                    }
                                    else if(buttonAction == 'update'){
                                        // m = Messaging.renderStoredEmailTemplate(emailTempUpdateSaReqBrokerId, userId, req.Id);
                                        m.setTemplateId(emailTempUpdateSaReqBrokerId);
                                        m.setSubject(emailTempUpdateSaReqBroker.getSubject());
                                        m.setHtmlBody(emailTempUpdateSaReqBroker.htmlBody);
                                    }
                                    else if(buttonAction == 'remind'){
                                        // m = Messaging.renderStoredEmailTemplate(emailTempRemindSaReqBrokerId, userId, req.Id);
                                        m.setTemplateId(emailTempRemindSaReqBrokerId);
                                        m.setSubject(emailTempRemindSaReqBroker.getSubject());
                                        m.setHtmlBody(emailTempRemindSaReqBroker.htmlBody);
                                    }
                                    else if(buttonAction == 'notify'){
                                        // m = Messaging.renderStoredEmailTemplate(emailTempNotifySaReqBrokerId, userId, req.Id);
                                        m.setTemplateId(emailTempNotifySaReqBrokerId);
                                        m.setSubject(emailTempNotifySaReqBroker.getSubject());
                                        m.setHtmlBody(emailTempNotifySaReqBroker.htmlBody);
                                    }
    
                                    m.setSaveAsActivity(false);
                                    lstEmailMessage.add(m);
                                }
                                else{
                                    isBroker = false;
    
                                    if(buttonAction == 'send'){
                                        // m = Messaging.renderStoredEmailTemplate(emailTempSendSaReqReinsurerId, userId, req.Id);
                                        m.setTemplateId(emailTempSendSaReqReinsurerId);
                                        m.setSubject(emailTempSendSaReqReinsurer.getSubject());
                                        m.setHtmlBody(emailTempSendSaReqReinsurer.htmlBody);
                                    }
                                    else if(buttonAction == 'update'){
                                        // m = Messaging.renderStoredEmailTemplate(emailTempUpdateSaReqReinsurerId, userId, req.Id);
                                        m.setTemplateId(emailTempUpdateSaReqReinsurerId);
                                        m.setSubject(emailTempUpdateSaReqReinsurer.getSubject());
                                        m.setHtmlBody(emailTempUpdateSaReqReinsurer.htmlBody);
                                    }
                                    else if(buttonAction == 'remind'){
                                        // m = Messaging.renderStoredEmailTemplate(emailTempRemindSaReqReinsurerId, userId, req.Id);
                                        m.setTemplateId(emailTempRemindSaReqReinsurerId);
                                        m.setSubject(emailTempRemindSaReqReinsurer.getSubject());
                                        m.setHtmlBody(emailTempRemindSaReqReinsurer.htmlBody);
                                    }
                                    else if(buttonAction == 'notify'){
                                        // m = Messaging.renderStoredEmailTemplate(emailTempNotifySaReqReinsurerId, userId, req.Id);
                                        m.setTemplateId(emailTempNotifySaReqReinsurerId);
                                        m.setSubject(emailTempNotifySaReqReinsurer.getSubject());
                                        m.setHtmlBody(emailTempNotifySaReqReinsurer.htmlBody);
                                    }
    
                                    m.setSaveAsActivity(false);
                                    lstEmailMessage.add(m);
                                }
    
                                for(Messaging.SingleEmailMessage emailMessage : lstEmailMessage) {
                                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                                    List<String> sendTo = new List<String>();
                                    sendTo.add(accountContact.Contact.Email);
                                    mail.setToAddresses(sendTo);
                                    System.debug('#### 1 = ' + sendTo) ;
                                    mail.setReplyTo(UserInfo.getUserEmail());
                                    mail.setSenderDisplayName(UserInfo.getFirstName() + ' ' + UserInfo.getLastName());
                                    String htmlBody = emailMessage.htmlBody;
                                    String htmlSubject = emailMessage.getSubject();
    
                                    if(lstSaPCCEmailsToSend.size() > 0){
                                        mail.setCcAddresses(lstSaPCCEmailsToSend);
                                    }
    
                                    String urlLoadSARequest = 'SARespondOnBehalf?s__id='+req.Special_Acceptance__c+'-'+req.Program__r.UwYear__c+'-'+req.Program__r.PrincipalCedingCompany__c+'-'+req.Program__c+'-'+req.Broker__c+'-'+req.Reinsurer__c+'-undefined-portalBR-undefined-'+req.Id;
                                    String urlLoadSARequestLink = '<a href="' + urlArr[0] + urlLoadSARequest + '">Link</a>';
                                    htmlBody = htmlBody.replace('[URL]', urlLoadSARequestLink);
    
                                    String strReinsurerName = '';
    
                                    htmlBody = htmlBody.replace('{Programname}', req.Program__r.Name);
                                    htmlBody = htmlBody.replace('{Coveredcedingcompany}', req.Special_Acceptance__r.CoveredCedingCompany__r.Name);
                                    htmlBody = htmlBody.replace('{SAname}', req.Special_Acceptance__r.SpecialAcceptanceName__c);
                                    htmlBody = htmlBody.replace('{U/W Year}', req.Program__r.UwYear__c);
                                    htmlBody = htmlBody.replace('{ActorNewGenURL}', htmlInternetLink);
    
                                    String strExpectedResDate = lstSaRequests[0].ExpectedResponseDate__c != null ? String.valueOf(lstSaRequests[0].ExpectedResponseDate__c) : '';
                                    htmlBody = htmlBody.replace('{expectedAnswerDate}', strExpectedResDate);
    
                                    String strSaEmailOfPCCDisplay = saEmailOfPCCDisplay != null ? saEmailOfPCCDisplay : '';
                                    htmlBody = htmlBody.replace('{SAEmailPCC}', strSaEmailOfPCCDisplay);
    
                                    for(String reinsurerId : mapReinsurerNameById.keySet()){
                                        Request__c reqReins = mapReinsurerNameById.get(reinsurerId);
                                        String reinsurerName = reqReins.TECH_ReinsurerName__c;
    
                                        String urlLoadSARequestRein = 'SARespondOnBehalf?s__id='+reqReins.Special_Acceptance__c+'-'+reqReins.Program__r.UwYear__c+'-'+reqReins.Program__r.PrincipalCedingCompany__c+'-'+reqReins.Program__c+'-'+reqReins.Broker__c+'-'+reinsurerId+'-undefined-portalBR-undefined-'+reqReins.Id;
                                        String urlLoadSARequestLinkRein = '<a href="' + urlArr[0] + urlLoadSARequestRein + '">'+reinsurerName+'</a>';
    
                                        if(strReinsurerName == ''){
                                            strReinsurerName = '<li style="text-align: left;">' + urlLoadSARequestLinkRein + '</li>';
                                        }
                                        else{
                                            strReinsurerName += '<li style="text-align: left;">' + urlLoadSARequestLinkRein + '</li>';
                                        }
                                    }
     
                                    htmlSubject = htmlSubject.replace('{ProgramName}', req.Program__r.Name);  
                                    htmlSubject = htmlSubject.replace('{CedingCompanyName}', req.Special_Acceptance__r.CoveredCedingCompany__r.Name);  
                                    htmlBody = htmlBody.replace('{ListReinsurerLink}', strReinsurerName);
    
                                    String strComment = req.Comments__c != null ? req.Comments__c : '';
                                    String commentStrDesigned = '<b style="color:blue";><font face="Arial" size="50px">' + strComment + '</font></b>'; //RRA - ticket 1382 - 1912202
                                    htmlBody = htmlBody.replace('{Comments}', commentStrDesigned); //RRA - ticket 1382 - 1912202
    
                                    if(buttonAction == 'update'){
                                        htmlBody = htmlBody.replace('{ListOfDocuments}', strDocumentName);
                                    }
    
                                    mail.setHtmlBody(htmlBody);
                                    mail.setSubject(htmlSubject);
                                    lstMails.add(mail);
                                }
                            }
                        }
                    }
                }
    
                //Send Email Alert for Pool
                for(Integer i = 0; i < lstPoolIdToEmail.size(); i++){
                    List<String> poolArr = lstPoolIdToEmail[i].split('\\|');
                    mapPoolIdToEmail.put(poolArr[0], poolArr[1]);
                }

                System.debug('buttonAction ==' + buttonAction);
                System.debug('specialAcceptanceId ==' + specialAcceptanceId);
                System.debug('lstRequestToUpdate[0].Special_Acceptance__r.Type__c ==' + lstRequestToUpdate[0].Special_Acceptance__r.Type__c);

                //RRA - ticket 1488 - 04052023
                if((buttonAction == 'send') && lstRequestToUpdate[0].Special_Acceptance__r.Type__c == '2'){
                    List<String> lstSAStatusRein = new List<String> {'Sent','Agreed'};
                    manageSharingVisibilityForSA (specialAcceptanceId, lstSaRequests, lstSAStatusRein, lstAccountContact);
                }

                 //RRA - ticket 1488 - 04052023
                if((buttonAction == 'notify') && (lstRequestToUpdate[0].Special_Acceptance__r.Type__c == '2')){
                    List<String> lstSAStatusRein = new List<String> {'Notified','Agreed'};
                    manageSharingVisibilityForSA (specialAcceptanceId, lstSaRequests, lstSAStatusRein, lstAccountContact);
                }
    
                if(buttonAction != 'notify'){
                    for(Request__c request : lstSaRequests){
                        if(request.Pool__r != null){
                            Pool__c pool = request.Pool__r;
                            Id reqId = request.Id;
                            Messaging.SingleEmailMessage m = new Messaging.SingleEmailMessage();
                            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                            List<String> lstEmailsToSend = new List<String>();
    
                            m.setTargetObjectId(userId);
                            m.setWhatId(reqId);
                            m.setSaveAsActivity(false);
        
                            if(buttonAction == 'send'){
                                // m = Messaging.renderStoredEmailTemplate(emailTempSendSaReqPoolId, userId, reqId);
                                m.setTemplateId(emailTempSendSaReqPoolId);
                                m.setSubject(emailTempSendSaReqPool.getSubject());
                                m.setHtmlBody(emailTempSendSaReqPool.htmlBody);
                            }
                            else if(buttonAction == 'update'){
                                // m = Messaging.renderStoredEmailTemplate(emailTempUpdateSaReqPoolId, userId, reqId);
                                m.setTemplateId(emailTempUpdateSaReqPoolId);
                                m.setSubject(emailTempUpdateSaReqPool.getSubject());
                                m.setHtmlBody(emailTempUpdateSaReqPool.htmlBody);
                            }
                            else if(buttonAction == 'remind'){
                                // m = Messaging.renderStoredEmailTemplate(emailTempRemindSaReqPoolId, userId, reqId);
                                m.setTemplateId(emailTempRemindSaReqPoolId);
                                m.setSubject(emailTempRemindSaReqPool.getSubject());
                                m.setHtmlBody(emailTempRemindSaReqPool.htmlBody);
                            }
        
                            m.setSaveAsActivity(false);
                            lstEmailsToSend.add(mapPoolIdToEmail.get(pool.Id));
                            mail.setToAddresses(lstEmailsToSend);
                            mail.setReplyTo(UserInfo.getUserEmail());
                            mail.setSenderDisplayName(UserInfo.getFirstName() + ' ' + UserInfo.getLastName());
                            String htmlBody = m.htmlBody;
                            String htmlSubject = m.getSubject();
    
                            if(lstSaPCCEmailsToSend.size() > 0){
                                mail.setCcAddresses(lstSaPCCEmailsToSend);
                            }
    
                            htmlBody = htmlBody.replace('{Programname}', request.Program__r.Name);
                            htmlBody = htmlBody.replace('{Coveredcedingcompany}', request.Special_Acceptance__r.CoveredCedingCompany__r.Name);
                            htmlBody = htmlBody.replace('{SAname}', request.Special_Acceptance__r.SpecialAcceptanceName__c);
                            htmlBody = htmlBody.replace('{U/W Year}', request.Program__r.UwYear__c);
                            htmlBody = htmlBody.replace('{ActorNewGenURL}', htmlInternetLink);
    
                            String urlDomain = String.valueOf(System.URL.getOrgDomainUrl().toExternalForm());
                            String urlLoadSARequest = '/lightning/n/LoadSARequest?s__id='+request.Special_Acceptance__c+'-'+request.Program__r.UwYear__c+'-'+request.PrincipalCedingCompany__c+'-'+request.Program__c+'-All-ugp';
                            String urlLoadSARequestLink = '<a href="' + urlDomain + urlLoadSARequest + '">Link</a>';
    
                            htmlBody = htmlBody.replace('[URL]', urlLoadSARequestLink);
    
                            if(request.ExpectedResponseDate__c != null){
                                htmlBody = htmlBody.replace('{expectedAnswerDate}', String.valueOf(request.ExpectedResponseDate__c));
                            }
    
                            String strSaEmailOfPCCDisplays = saEmailOfPCCDisplay != null ? saEmailOfPCCDisplay : '';
                            htmlBody = htmlBody.replace('{SAEmailPCC}', strSaEmailOfPCCDisplays);
    
                            if(buttonAction == 'update'){ 
                                htmlBody = htmlBody.replace('{ListOfDocuments}', strDocumentName);
                            }
    
                            String strComments = request.Comments__c != null ? request.Comments__c : '';
                            String commentStrDesigned = '<b style="color:blue";><font face="Arial" size="50px">' + strComments + '</font></b>'; //RRA - ticket 1382 - 1912202
                            htmlBody = htmlBody.replace('{Comments}', commentStrDesigned); //RRA - ticket 1382 - 1912202
    
                            htmlSubject = htmlSubject.replace('{ProgramName}', request.Program__r.Name);  
                            htmlSubject = htmlSubject.replace('{CedingCompanyName}', request.Special_Acceptance__r.CoveredCedingCompany__r.Name);  
                            mail.setHtmlBody(htmlBody);
                            mail.setSubject(htmlSubject);
                            lstMails.add(mail);
                        }
                    }  
                }
                 //Update status Bound to Yes - RRA - ticket 1301 - 22112022
                 else if(buttonAction == 'send' && lstRequestToUpdate[0].Special_Acceptance__r.Type__c == '1'){
                    List<SpecialAcceptance__c> lstUpdateStatusBound = new List <SpecialAcceptance__c>();
                    if (specialAcceptanceId != null){
                        for (SpecialAcceptance__c sa : [SELECT Id, Bound__c, InternalStatus__c FROM SpecialAcceptance__c WHERE Id =:specialAcceptanceId AND (InternalStatus__c = 'Agreed' OR PortalStatus__c = 'Agreed') AND IsInformCedCom__c = TRUE]){
                            sa.Bound__c = '1';
                            lstUpdateStatusBound.add(sa);
                        }
                    }
                    if (lstUpdateStatusBound.size() > 0){
                        update lstUpdateStatusBound;
                    }
                }
                else if((buttonAction == 'notify') && lstRequestToUpdate[0].Special_Acceptance__r.Type__c == '1'){
                    List<String> lstSAReinsStatus = new List<String> {'Agreed', 'Sent', 'Notified'};
                    //check if Sa Type is Declaration
                    //Share Pool/Leader/Follower as Leader Request
                    if(specialAcceptanceId != null){
                        String querySarPoolLeader = 'SELECT Id, TECH_TreatyName__c, Treaty__r.PlacementShare_Perc__c, TECH_BrokerName__c, TECH_IsBrokerPresent__c, TECH_ReinsurerName__c, TECH_Layer__c, TECH_UWyear__c,  SigningRegionalManager__r.Email '
                                + ', RiskCarrier__r.Name, FinancialEntity__r.Name, Program__r.LossDepositMode__c, Program__r.LossDeposit__c '
                                + ', Treaty__r.LossDepositMode__c, Treaty__r.LossDeposit__c, Treaty__r.Deductions__c, TreatyReference__c, Treaty__r.TypeofTreaty__c, Program__r.UwYear__c '
                                + ', Treaty__r.PremiumDeposit__c, Program__r.LossDepositLevel__c, Pool__r.Name, Pool__r.AssignedTo__r.Email, Pool__r.AssignedTo__c, Pool__r.SA_Email__c, Program__r.Name, program__r.principalcedingcompany__r.Name, Program__r.PrincipalCedingCompany__c '
                                + ', Special_Acceptance__r.SpecialAcceptanceName__c, Special_Acceptance__r.CoveredCedingCompany__r.Name, '
                                +  strRequestFields
                                + ' from Request__c where (Special_Acceptance__c = :specialAcceptanceId) AND ((LastVersionSent__c = TRUE AND LastVersionAnswered__c = TRUE) AND (SA_Request_Status__c <> :strSetup)) ';
    
                        lstSarPoolLeader = Database.query(querySarPoolLeader);
    
                        for(Request__c req : lstSarPoolLeader){
                            // FMU : correction ticket W-1052
                            /* Decimal lastNotify = req.TECH_NotifyBtnClick__c;
                            req.TECH_NotifyBtnClick__c = lastNotify + 1; */
                            decimal lastNotify;
                            if (req.TECH_NotifyBtnClick__c!= null) lastNotify = req.TECH_NotifyBtnClick__c; else lastNotify = 0; 
                            req.TECH_NotifyBtnClick__c = lastNotify + 1;
                        }
    
                        if(lstSarPoolLeader.size() > 0){
                            update lstSarPoolLeader;
                        }
                        mapResults.put('lstSarPoolLeader',lstSarPoolLeader);
                         //RRA - ticket 1488 - 04052023
                        manageSharingVisibilityForSA (specialAcceptanceId, lstSaRequests, lstSAReinsStatus, lstAccountContact);
                   }
                }
                if(lstMails.size() > 0){
                    Messaging.sendEmail((List<Messaging.Email>) lstMails);
                }
    
                List<Request__c> lstRequestVersionSaStatus = [SELECT Id, ReinsurerStatus__c,SA_Request_Status__c, OriginalRequest__c, ExpectedResponseDate__c, TECH_LastSendUpdRemDate__c, LastSentDate__c, SentBy__c FROM Request__c WHERE Id IN :mapRequestSentByOriginalReqId.keySet() OR OriginalRequest__c IN :mapRequestSentByOriginalReqId.keySet()];
    
                for(Request__c request : lstRequestVersionSaStatus){
                    Id originalReqId;
                    if(request.OriginalRequest__c == null){
                        originalReqId = request.Id;
                    }
                    else{
                        originalReqId = request.OriginalRequest__c;
                    }
    
                    Request__c originalRequest = mapRequestSentByOriginalReqId.get(originalReqId);

                    request.SA_Request_Status__c = originalRequest.SA_Request_Status__c;
                    request.ExpectedResponseDate__c = originalRequest.ExpectedResponseDate__c;
                    request.LastSentDate__c = originalRequest.LastSentDate__c;
                    request.SentBy__c = connectedUser.Id;
                }
    
                if(lstRequestVersionSaStatus.size() > 0){
                    update lstRequestVersionSaStatus;
                }
    
                mapResults.put('Success','Success');
            }
            catch(Exception ex) {
                mapResults.put('Error',ex.getMessage());
                Database.rollback(sp);
            }  
            return mapResults;
        }

        //RRA - ticket 1488 - 04052023
        public static void manageSharingVisibilityForSA (Id idSA, List<Request__c> lstSAReq, List<String> lstReinsurerStatusSA, List<AccountContactRelation> lstAccountContact){
            //************************************************************ */
            // Operation Sharing for Follower and Leader
            //************************************************************ */
            System.debug('Begin Sharing');
            Set<Id> setIdCon = new Set<Id>();
            Map<String, Id> mapIdPccIdSA = new  Map<String, Id> ();
            Map<String, Id> mapIdGroupIdSAPcc = new Map<String, Id>();
            List<Request__Share> lstRequestSAShare = new List<Request__Share>();
            Map <String, Id> mapPccIdReqId = new Map <String, Id>();
            List<SpecialAcceptance__Share> lstSAShare = new List<SpecialAcceptance__Share>();
            List<Id> lstReins = new List<Id>();
            List<Id> lstReinsFin = new List<Id>();
            List<Id> lstIdReqFin = new List<Id>();
            List<AccountShare> lstAccountShareToInsert =  new List<AccountShare>();
            Set<String> setNewKeyReinsSigningReq = new Set<String>();
            List<Request__Share> lstRequestShareSA2 = new List<Request__Share>();
            Set<String> setNewKeyConcatBrokeReinsSigningReq = new Set<String>();
            Set<String> keySharingReq = new Set<String>();
            Set<String> setReins = new Set<String>();
            List<Request__c> lstRequestUpdateRecordReins = new List<Request__c>();
            Map<String, List<Id>> mapIdReqIdBroker = new  Map<String, List<Id>> ();
            Map<String, Id> mapIdReqIdReins = new  Map<String, Id> ();
            Map<String, Id> mapIdReqIdReinsFin = new  Map<String, Id> ();
            Map<Id, Id> mapIdUserIdSA = new  Map<Id, Id> ();
            Map<Id, Id> mapIdUserIdReqFromReins = new  Map<Id, Id> ();
            Map<Id, List<List<Id>>> mapIdUserIdReqFromBroker = new  Map<Id, List<List<Id>>> ();
            Map<Id, Id> mapIdUserIdPCC = new  Map<Id, Id> ();
            
            System.debug('lstSaRequests == '+lstSAReq);

            for ( Request__c req :[SELECT Id, Name, LastVersionSent__c, Special_Acceptance__r.Bound__c, LastVersionAnswered__c, OriginalRequest__c, Program__r.Nature__c, Program__r.PrincipalCedingCompany__c, Program__r.Macro_L_O_B__c, RecordTypeId, PrincipalCedingCompany__c,Broker__c, Reinsurer__c, BrokerStatus__c, Special_Acceptance__c, ReinsurerStatus__c, KeyRequestSharing__c FROM Request__c WHERE RecordType.name = 'Special Acceptance Request' AND SA_Request_Status__c IN: lstReinsurerStatusSA AND Special_Acceptance__c  =: idSA AND ReinsurerStatus__c = 'Signed' AND Id IN :lstSAReq]){
                mapIdPccIdSA.put (req.PrincipalCedingCompany__c, req.Id); // to share for group
                keySharingReq.add(req.KeyRequestSharing__c);
                //mapIdReqIdReins.put(req.KeyRequestSharing__c + '_' + req.Reinsurer__c, req.Id);
                if (req.Broker__c != null){
                    if (req.BrokerStatus__c == '1'){ //sleeping partners
                        lstReins.add(req.Reinsurer__c); // get reinsurer Attached on Broker
                        mapIdReqIdReins.put(req.Reinsurer__c, req.Id);
                    }else if (req.BrokerStatus__c == '2'){ //sleeping partners
                        lstReinsFin.add(req.Reinsurer__c); // get reinsurer Attached on Broker
                        lstIdReqFin.add(req.Id);
                        mapIdReqIdReinsFin.put(req.Reinsurer__c, req.Id);
                    }
                }else{
                    lstReins.add(req.Reinsurer__c);
                    lstIdReqFin.add(req.Id);
                    mapIdReqIdReins.put(req.Reinsurer__c, req.Id);
                }
            }
            System.debug('lstReins == '+lstReins);
            System.debug('lstReinsFin == '+lstReinsFin);
            System.debug('lstIdReqFin == '+lstIdReqFin);
            System.debug('mapIdReqIdReins == '+mapIdReqIdReins);
            System.debug('mapIdReqIdReinsFin == '+mapIdReqIdReinsFin);

            if (lstReins.size()>0){
                for (String strNewKeySA : keySharingReq){
                    List<String> lstNewKeySASharing = strNewKeySA.split('_');
                    for (String reinsId : lstReins){
                        if (reinsId != null){
                            setNewKeyReinsSigningReq.add(lstNewKeySASharing.get(0) + '_' + reinsId  + '_' + lstNewKeySASharing.get(2) + '_' + lstNewKeySASharing.get(3));
                        }                                    
                    }
                }
                setNewKeyConcatBrokeReinsSigningReq.addAll(setNewKeyReinsSigningReq);
                setNewKeyConcatBrokeReinsSigningReq.addAll(keySharingReq);
            }
            if (lstReinsFin.size()>0){
                setNewKeyConcatBrokeReinsSigningReq.addAll(keySharingReq);
            }

            System.debug('setNewKeyConcatBrokeReinsSigningReq == '+setNewKeyConcatBrokeReinsSigningReq);

            // Create map => to share PCC for SA 
            if(mapIdPccIdSA != null ){
                for(Group objGroup : [SELECT Id, Name FROM Group WHERE Name IN:mapIdPccIdSA.KeySet()]){
                    mapIdGroupIdSAPcc.put(objGroup.Name, objGroup.Id);
                }
            }

            System.debug('mapIdGroupIdSAPcc == '+mapIdGroupIdSAPcc);

            //Get list Contact Selected on step action Notify
            if (lstAccountContact != null && !lstAccountContact.isEmpty()){
                for (AccountContactRelation accCon : lstAccountContact){
                    setIdCon.add(accCon.ContactId);
                }
            }

            System.debug('setIdCon == '+setIdCon);

            //Create map => to share SA for User
            if (setIdCon.size()>0){
                for (User usr : [SELECT Id, IsActive FROM User WHERE ContactId IN: setIdCon]){
                    if (usr.IsActive){
                        mapIdUserIdSA.put(usr.Id, idSA);
                    }
                }
            }

            System.debug('mapIdUserIdSA == '+mapIdUserIdSA);

            // Create map => to share Account PCC and to Share Request for only Reins
            for (IntermediateACRRequest__c intObj : [SELECT Id, User__c, User__r.IsActive, SharingKeyFormula__c, Reinsurer__c, Broker__c, PCC__c FROM IntermediateACRRequest__c WHERE SharingKeyFormula__c IN:setNewKeyConcatBrokeReinsSigningReq AND Contact__c IN:setIdCon]){
                if (intObj.User__r.IsActive){
                    mapIdUserIdPCC.put(intObj.User__c, intObj.PCC__c);
                    if (intObj.Broker__c == null){
                        mapIdUserIdReqFromReins.put(intObj.User__c, mapIdReqIdReins.get(intObj.Reinsurer__c)); 
                        setReins.add(intObj.Reinsurer__c);
                    }
                }
            }

            System.debug('mapIdUserIdReqFromReins == '+mapIdUserIdReqFromReins);
            System.debug('setReins == '+setReins);

            //Update isUpdateRecordReins__c field to mark that the record corresponding on reinsurer is done
            if (mapIdUserIdReqFromReins.size()>0){
                for (Request__c req : [SELECT Id, isUpdateRecordReins__c, KeyRequestSharing__c, Reinsurer__c FROM Request__c WHERE Id IN:lstSAReq AND Reinsurer__c IN: setReins]){
                    if (req.isUpdateRecordReins__c == false){
                        req.isUpdateRecordReins__c = true;
                        lstRequestUpdateRecordReins.add(req);
                    }
                }
            }

            if (lstRequestUpdateRecordReins.size()>0){
                update lstRequestUpdateRecordReins;
            }

            System.debug('lstRequestUpdateRecordReins == '+lstRequestUpdateRecordReins);

            // Make map relation between keySharing + Broker as Key and list Id request as values
            for (Request__c req : [SELECT Id, isUpdateRecordReins__c, Special_acceptance__c, KeyRequestSharing__c, Broker__c, reinsurer__c FROM Request__c WHERE Reinsurer__c IN: lstReinsFin AND Special_Acceptance__c  =: idSA]){
                mapIdReqIdBroker.put(req.KeyRequestSharing__c + '_' + req.Broker__c, lstIdReqFin);
            }

            System.debug('mapIdReqIdBroker == '+mapIdReqIdBroker);

            if (mapIdReqIdBroker != null){
                for (IntermediateACRRequest__c intObj : [SELECT Id, User__c, User__r.IsActive, SharingKeyFormula__c, Reinsurer__c, Broker__c, PCC__c FROM IntermediateACRRequest__c WHERE SharingKeyFormula__c IN:setNewKeyConcatBrokeReinsSigningReq AND Contact__c IN:setIdCon]){
                    if (intObj.User__r.IsActive){
                        mapIdUserIdPCC.put(intObj.User__c, intObj.PCC__c);
                        if (intObj.Broker__c != null){
                            //mapIdUserIdReqFromBroker.put(intObj.User__c , mapIdReqIdBroker.get(intObj.SharingKeyFormula__c + '_' + intObj.Broker__c)); 

                             // Create map => to share Request for only Broker
                             // Make map relation between user's Broker (fin intermediate) and list of list Id request from reinsurers attached on same broker
                            if (mapIdUserIdReqFromBroker.containsKey(intObj.User__c)){
                                mapIdUserIdReqFromBroker.get(intObj.User__c).add(mapIdReqIdBroker.get(intObj.SharingKeyFormula__c + '_' + intObj.Broker__c));
                            }else{
                                mapIdUserIdReqFromBroker.put(intObj.User__c , new List<List<Id>> {mapIdReqIdBroker.get(intObj.SharingKeyFormula__c + '_' + intObj.Broker__c)}); 
                            }
                        }
                       
                    }
                }
            }
            System.debug('mapIdUserIdReqFromBroker == '+mapIdUserIdReqFromBroker);

            // Account Share for Pcc   => Treaty placement
            for(Id usr : mapIdUserIdPCC.keySet()){
                AccountShare accountShare = new AccountShare();
                accountShare.AccountAccessLevel = 'Read';
                accountShare.OpportunityAccessLevel = 'Read';
                accountShare.AccountId = mapIdUserIdPCC.get(usr);
                accountShare.UserOrGroupId = usr;
                lstAccountShareToInsert.add(accountShare);
            }

            System.debug('lstAccountShareToInsert == '+lstAccountShareToInsert);

            // Requesthare for SA (PCC)  => SA
            for(String namePcc : mapIdGroupIdSAPcc.keySet()){
                Request__Share requestShare = new Request__Share();
                requestShare.RowCause = 'Manual';
                requestShare.AccessLevel = 'Edit';
                requestShare.ParentId = mapIdPccIdSA.get(namePcc);
                requestShare.UserOrGroupId = mapIdGroupIdSAPcc.get(namePcc);
                lstRequestSAShare.add(requestShare);
            }

            System.debug('lstRequestSAShare for SA (PCC)  == '+lstRequestSAShare);


            // SA Share 
            for(Id usr : mapIdUserIdSA.keySet()){
                SpecialAcceptance__Share shareSA = new SpecialAcceptance__Share();
                shareSA.RowCause = 'Manual';
                shareSA.AccessLevel = 'Edit';
                shareSA.ParentId = mapIdUserIdSA.get(usr);
                shareSA.UserOrGroupId = usr;
                lstSAShare.add(shareSA);
            }

            System.debug('lstSAShare == '+lstSAShare);

            // Requesthare for SA from Reins
            for(Id usr : mapIdUserIdReqFromReins.keySet()){
                Request__Share reqShare = new Request__Share();
                reqShare.RowCause = 'Manual';
                reqShare.AccessLevel = 'Edit';
                reqShare.ParentId = mapIdUserIdReqFromReins.get(usr);
                reqShare.UserOrGroupId = usr;
                lstRequestShareSA2.add(reqShare);
            }


                // Requesthare for SA from Broker
                for(Id usr : mapIdUserIdReqFromBroker.keySet()){
                    List<List<Id>> totalMpRecords = mapIdUserIdReqFromBroker.get(usr);
                    for(List<Id> lstIdReq : totalMpRecords){
                        for (Id idFinalReq :lstIdReq){
                            Request__Share reqShare = new Request__Share();
                            reqShare.RowCause = 'Manual';
                            reqShare.AccessLevel = 'Edit';
                            reqShare.ParentId = idFinalReq;
                            reqShare.UserOrGroupId = usr;
                            lstRequestShareSA2.add(reqShare);
                        }
                    }
            }

            System.debug('lstRequestShareSA2 == '+lstRequestShareSA2);

            if(lstAccountShareToInsert.size() > 0){
                System.debug('loadPlacementTable__lstAccountShareToInsert ==  ' + lstAccountShareToInsert);
                System.debug('shareAccoutToUsers: inserting AccountShare List with ' + lstAccountShareToInsert.size() + ' elements');
                AP38_CreateSharingForRequest.Manage_DataBaseInsertSharing_UTL util = new  AP38_CreateSharingForRequest.Manage_DataBaseInsertSharing_UTL();
                util.insertAccountShares(lstAccountShareToInsert);
                System.debug('Account Share  List inserted Successfully for Pcc');
            }
            if(lstRequestSAShare.size() > 0){
                System.debug('shareSARequestToUsers: inserting Request__Share SA List with ' + lstRequestSAShare.size() + ' elements');
                AP38_CreateSharingForRequest.Manage_DataBaseInsertSharing_UTL util = new AP38_CreateSharingForRequest.Manage_DataBaseInsertSharing_UTL();
                util.insertRequestShares(lstRequestSAShare);
                System.debug('Request SA Share List inserted Successfully ');
            }

            if(lstRequestShareSA2.size() > 0){
                System.debug('shareSARequestToUsers: inserting lstRequestShareSA2 SA List with ' + lstRequestShareSA2.size() + ' elements');
                AP38_CreateSharingForRequest.Manage_DataBaseInsertSharing_UTL util = new AP38_CreateSharingForRequest.Manage_DataBaseInsertSharing_UTL();
                util.insertRequestShares(lstRequestShareSA2);
                System.debug('Request SA lstRequestShareSA2 inserted Successfully ');
            }
        
            if(lstSAShare.size() > 0){
                System.debug('shareSAToUsers: inserting SA_RequestShare List with ' + lstSAShare.size() + ' elements');
                AP38_CreateSharingForRequest.Manage_DataBaseInsertSharing_UTL util = new AP38_CreateSharingForRequest.Manage_DataBaseInsertSharing_UTL();
                util.insertSAShares(lstSAShare);
                System.debug('SA Share  List inserted Successfully ');
            }
        }
    
        @AuraEnabled
        public static Map<String, Object> informCedingCompany(SpecialAcceptance__c specialAcceptanceObj, List<AccountContactRelation> lstAccountContact, String requestId,  List<AccountContactRelation> lstAccConForSharingSA){ //RRA - ticket 1445 - 27032023
            Map<String, Object> mapResults = new Map<String, Object>();
            List<SpecialAcceptance__c> lstCedingSa = new List<SpecialAcceptance__c>();
            List<SpecialAcceptance__c> lstCedingSaToUpdate = new List<SpecialAcceptance__c>();
            List<String> lstEmailTemplateName = new List<String>();
            List<EmailTemplate> lstEmailTemplate = new List<EmailTemplate>();
            List<Messaging.SingleEmailMessage> lstMails = new List<Messaging.SingleEmailMessage>();
            List<ContentVersion> lstCloneCEContentVersion = new List<ContentVersion>();
            List<ContentVersion> lstNewCloneCEContentVersionToInsert = new List<ContentVersion>();
            List<ContentDocumentLink> lstContentDocumentLinkCloneToInsert = new List<ContentDocumentLink>();
            List<Id> lstCloneCEContentDocument = new List<Id>();
            List<String> lstSaPCCEmailsToSend = new List<String>();
            Id emailTempSaReqInformCedComAgreedId;
            Id emailTempSaReqInformCedComRefusedId;
            Set<Id> setCloneCEContentDocumentId = new Set<Id>();
            Set<Id> setContentDocumentIdCeding = new Set<Id>();
            String saEmailOfPCC;
            String saEmailOfPCCDisplay;
            String pccId;
    
            //RRA - ticket 1445 - 23032023 : variable for Sharing SA from send button on informCedingCompany
            Set<Id> setIdCon = new Set<Id>();
            Map<Id, Id> mapIdSAIdAcc = new  Map<Id, Id> ();
            Map<Id, Id> mapIdConIdUser = new  Map<Id, Id> ();
            Map<Id, Id> mapIdUserIdAcc = new  Map<Id, Id> ();
            Map<Id, Id> mapIdUserIdSA = new  Map<Id, Id> ();
            //Id idSASentAgre;
            List<SpecialAcceptance__Share> lstSAShare = new List<SpecialAcceptance__Share>();
            Savepoint sp = Database.setSavepoint();
        
            try{
                if(specialAcceptanceObj != null){
                    specialAcceptanceObj.IsInformCedCom__c = true;
                    update specialAcceptanceObj;
                } 
    
                /*if (specialAcceptanceObj.SentAgreFromSpecialAcceptance__c != null){
                    idSASentAgre = specialAcceptanceObj.SentAgreFromSpecialAcceptance__c;
                }*/
    
                List<SpecialAcceptance__c> lstSA = [SELECT Id, Bound__c, CoveredCedingCompany__r.Name,Type__c FROM SpecialAcceptance__c WHERE Id = :specialAcceptanceObj.Id];// MRA W-1229 - 12/08/2022 - SA Declaration Type another email template
    
                String sendFromSaId = specialAcceptanceObj.SentAgreFromSpecialAcceptance__c;
                if(sendFromSaId != null){
                    lstCedingSa = [SELECT Id, BindRemainingDays__c, BindExpectedAnswerDate__c, AdditionalPremium__c, IsInformCedCom__c, Bound__c, TECH_Actor2Id__c, Rationale__c, ProposedToFac__c, InternalStatus__c, PortalStatus__c, Reference__c, RenewedFromSpecialAcceptance__c
                    FROM SpecialAcceptance__c WHERE Id = :sendFromSaId LIMIT 1];
    
                    if(lstCedingSa.size() > 0){
                        SpecialAcceptance__c cedingSa = specialAcceptanceObj.clone(false, false, false, false);
                        cedingSa.TECH_Actor2Id__c = null;
                        cedingSa.Id = lstCedingSa[0].Id;
                        cedingSa.SentAgreFromSpecialAcceptance__c = null;   
                        cedingSa.IsInformCedCom__c = true;
    
                        if(specialAcceptanceObj.InternalStatus__c == AP_Constant.statusAgreed){
                            cedingSa.PortalStatus__c = AP_Constant.statusAgreed;
                        }
                        else if(specialAcceptanceObj.InternalStatus__c == AP_Constant.statusRefused){
                            cedingSa.PortalStatus__c = AP_Constant.statusRefused;
                        }
    
                        cedingSa.InternalStatus__c = null;
                        cedingSa.Reference__c = lstCedingSa[0].Reference__c;
                        cedingSa.RenewedFromSpecialAcceptance__c = lstCedingSa[0].RenewedFromSpecialAcceptance__c;
                        lstCedingSaToUpdate.add(cedingSa); 
    
                        //to delete all document
                        String cedingSaId = cedingSa.Id;
    
                        for(ContentDocumentLink contentDocLink : [SELECT Id, ContentDocumentId
                                                                    FROM ContentDocumentLink
                                                                    WHERE LinkedEntityId = :cedingSaId]){
                            setContentDocumentIdCeding.add(contentDocLink.ContentDocumentId);
                        }
    
                        if(setContentDocumentIdCeding.size() > 0){
                            List<ContentDocument> lstContentDocCedingToDelete = [SELECT Id FROM ContentDocument WHERE Id IN :setContentDocumentIdCeding];
    
                            if(lstContentDocCedingToDelete.size() > 0) {
                                delete lstContentDocCedingToDelete;
                            }
                        }
    
                        //to insert all documents
                        String saId = specialAcceptanceObj.Id;
    
                        for(ContentDocumentLink contentDocLink : [SELECT Id, ContentDocumentId
                                                                    FROM ContentDocumentLink
                                                                    WHERE LinkedEntityId = :saId]){
                            setCloneCEContentDocumentId.add(contentDocLink.ContentDocumentId);
                        }
    
                        if(setCloneCEContentDocumentId.size() > 0){
                            lstCloneCEContentVersion = [SELECT Id, Phase__c, Title, IsExternal__c, ContentDocumentId
                                                            , Nature__c, FileType, FileExtension, ContentUrl, ContentSize
                                                            , PathOnClient, VersionData, FirstPublishLocationId, SpecialAcceptance__c
                                                        FROM ContentVersion
                                                        WHERE ContentDocumentId IN :setCloneCEContentDocumentId];
    
                            for(ContentVersion contentVersion : lstCloneCEContentVersion){
                                ContentVersion newContentVersion = new ContentVersion();
                                newContentVersion.Title = contentVersion.Title;
                                newContentVersion.PathOnClient = contentVersion.PathOnClient;
                                newContentVersion.VersionData = contentVersion.VersionData;
                                newContentVersion.FirstPublishLocationId = contentVersion.FirstPublishLocationId;
                                newContentVersion.Nature__c = contentVersion.Nature__c;
                                newContentVersion.SpecialAcceptance__c = cedingSaId;
                                newContentVersion.IsExternal__c = contentVersion.IsExternal__c;
                                lstNewCloneCEContentVersionToInsert.add(newContentVersion);
                            }
                        }
    
                        if(lstNewCloneCEContentVersionToInsert.size() > 0) {
                            insert lstNewCloneCEContentVersionToInsert;  
    
                            for(ContentVersion cv : [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN :lstNewCloneCEContentVersionToInsert]){
                                lstCloneCEContentDocument.add(cv.ContentDocumentId);
                            }
                            
                            for(Id contentDocumentId : lstCloneCEContentDocument){
                                ContentDocumentLink cd = new ContentDocumentLink();
                                cd.LinkedEntityId = cedingSaId;
                                cd.ContentDocumentId = contentDocumentId;
                                cd.Visibility = 'AllUsers';
                                cd.ShareType = 'V';
                                lstContentDocumentLinkCloneToInsert.add(cd);
                            }
    
                            if(lstContentDocumentLinkCloneToInsert.size() > 0){
                                insert lstContentDocumentLinkCloneToInsert;
                            }
                        } 
                    } 
    
                    //RRA - ticket 1445 - 27032023
                    createSharingSAFromInformCedingCompany (sendFromSaId, lstAccConForSharingSA);
    
                }
                else{
                    cloneCESpecialAcceptanceToCedingPortal(specialAcceptanceObj.Id, lstAccConForSharingSA);
                }
    
                if(lstCedingSaToUpdate.size() > 0){
                    update lstCedingSaToUpdate;
                }
    
                mapResults.put('lstCedingSaToUpdate', lstCedingSaToUpdate);
    
                Network networkObj = [SELECT Id
                                        FROM Network
                                        WHERE Name =: System.Label.Actor_ceding_portal_name];
    
                String url = Network.getLoginUrl(networkObj.Id);
                List <String> urlArr = url.split('login');
    
                lstEmailTemplateName.add(AP_Constant.emailTempSaReqInformCedComAgreedDeclaratrion);// MRA W-1229 - 12/08/2022 - SA Declaration Type another email template
                lstEmailTemplateName.add(AP_Constant.emailTempSaReqInformCedComAgreed);
                lstEmailTemplateName.add(AP_Constant.emailTempSaReqInformCedComRefused);
    
                lstEmailTemplate = [SELECT Id, Name FROM EmailTemplate WHERE Name IN : lstEmailTemplateName];
    
                for(EmailTemplate emailTemplate : lstEmailTemplate){
                    if(emailTemplate.Name == AP_Constant.emailTempSaReqInformCedComAgreed){
                        emailTempSaReqInformCedComAgreedId = emailTemplate.Id;
                    }
                    else if(emailTemplate.Name == AP_Constant.emailTempSaReqInformCedComRefused){
                        emailTempSaReqInformCedComRefusedId = emailTemplate.Id;
                    }
                    // MRA W-1229 - 12/08/2022 - SA Declaration Type another email template
                    else if(lstSA[0].Type__c == '1' && emailTemplate.Name == AP_Constant.emailTempSaReqInformCedComAgreedDeclaratrion){
                            emailTempSaReqInformCedComAgreedId = emailTemplate.Id;
                    }else if (lstSA[0].Type__c == '2'){//RRA - ticket 1447 - 15032023
                        if ((lstSA[0].Bound__c == '1' || lstSA[0].Bound__c == '2' ) && emailTemplate.Name == AP_Constant.emailTempSaReqInformCedComAgreedDeclaratrion){
                            emailTempSaReqInformCedComAgreedId = emailTemplate.Id;
                        }
    
                        //RRA - ticket 1447 - 15032023
                        if (lstSA[0].Bound__c == 'Pending' && emailTemplate.Name == AP_Constant.emailTempSaReqInformCedComAgreed){
                            emailTempSaReqInformCedComAgreedId = emailTemplate.Id;
                        }
                    }
                }
    
                Id userId = UserInfo.getUserId();
                Id programId = specialAcceptanceObj.Program__c;
    
                Messaging.SingleEmailMessage emailTempSaReqInformCedComAgreed = new Messaging.SingleEmailMessage();       
                emailTempSaReqInformCedComAgreed = Messaging.renderStoredEmailTemplate(emailTempSaReqInformCedComAgreedId, userId, requestId);
    
                Messaging.SingleEmailMessage emailTempSaReqInformCedComRefused = new Messaging.SingleEmailMessage();       
                emailTempSaReqInformCedComRefused = Messaging.renderStoredEmailTemplate(emailTempSaReqInformCedComRefusedId, userId, requestId);
    
                List<SpecialAcceptance__c> lstSpecialAcceptance = [SELECT Id, Comments__c, SpecialAcceptanceName__c, BindExpectedAnswerDate__c, PrincipalCedingCompany__c, Program__c, Program__r.Name, Program__r.UwYear__c FROM SpecialAcceptance__c WHERE Id = :specialAcceptanceObj.Id LIMIT 1];
    
                if(lstSpecialAcceptance.size() > 0){
                    pccId = lstSpecialAcceptance[0].PrincipalCedingCompany__c;   
    
                    if(pccId != null){
                        List<Account> lstPCCAccount = [SELECT Id, EmailSA__c FROM Account WHERE Id = :pccId LIMIT 1];
                        if(lstPCCAccount.size() > 0){
                            saEmailOfPCC = lstPCCAccount[0].EmailSA__c;
                            
                            if(saEmailOfPCC != null ){
                                if(saEmailOfPCC.contains(';')){
                                    lstSaPCCEmailsToSend = saEmailOfPCC.split(';');
                                }
                                else{
                                    lstSaPCCEmailsToSend.add(saEmailOfPCC);
                                }
                            }
    
                            for(String pccEmail : lstSaPCCEmailsToSend){
                                if(saEmailOfPCCDisplay == null){
                                    saEmailOfPCCDisplay = pccEmail;
                                }
                                else{
                                    saEmailOfPCCDisplay = saEmailOfPCCDisplay + ' ' + pccEmail;   
                                }
                            }
                        }
                    }             
                }
    
                for(AccountContactRelation accConRelation : lstAccountContact){
                    Messaging.SingleEmailMessage m = new Messaging.SingleEmailMessage();
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    List<String> lstEmailsToSend = new List<String>();
                    
                    m.setTargetObjectId(userId);
                    m.setWhatId(requestId);
                    m.setSaveAsActivity(false);
                    
                    if(specialAcceptanceObj.InternalStatus__c == 'Agreed'){
                        // m = Messaging.renderStoredEmailTemplate(emailTempSaReqInformCedComAgreedId, userId, requestId);
                        m.setTemplateId(emailTempSaReqInformCedComAgreedId);
                        m.setSubject(emailTempSaReqInformCedComAgreed.getSubject());
                        m.setHtmlBody(emailTempSaReqInformCedComAgreed.htmlBody);
                    }
                    else if(specialAcceptanceObj.InternalStatus__c == 'Refused'){
                        // m = Messaging.renderStoredEmailTemplate(emailTempSaReqInformCedComRefusedId, userId, requestId);
                        m.setTemplateId(emailTempSaReqInformCedComRefusedId);
                        m.setSubject(emailTempSaReqInformCedComRefused.getSubject());
                        m.setHtmlBody(emailTempSaReqInformCedComRefused.htmlBody);
                    }
    
                    m.setSaveAsActivity(false);
                    String email = accConRelation.Contact.Email;
                    lstEmailsToSend.add(email);
                    mail.setToAddresses(lstEmailsToSend);
                    mail.setReplyTo(UserInfo.getUserEmail());
                    mail.setSenderDisplayName(UserInfo.getFirstName() + ' ' + UserInfo.getLastName());
                    String htmlBody = m.htmlBody;
                    String htmlSubject = m.getSubject();
    
                    if(lstSaPCCEmailsToSend.size() > 0){
                        mail.setCcAddresses(lstSaPCCEmailsToSend);
                    }
    
                    if(lstSpecialAcceptance.size() > 0){
                        htmlBody = htmlBody.replace('{U/W Year}', lstSpecialAcceptance[0].Program__r.UwYear__c);
                        htmlBody = htmlBody.replace('{Programname}', lstSpecialAcceptance[0].Program__r.Name);
                        htmlBody = htmlBody.replace('{SAname}', lstSpecialAcceptance[0].SpecialAcceptanceName__c);
                        String saUrl = urlArr[0] + 'SADetail?s__id=' + lstSpecialAcceptance[0].Id + '-' + lstSpecialAcceptance[0].Program__r.UwYear__c + '-' + lstSpecialAcceptance[0].PrincipalCedingCompany__c + '-' + lstSpecialAcceptance[0].Program__c;
                        String saLink = '<a href="' + saUrl +'">Link of Special Acceptance</a>';
                        htmlBody = htmlBody.replace('[URLofTheSpecialAcceptance]', saLink);
                        htmlSubject = htmlSubject.replace('{ProgramName}', lstSpecialAcceptance[0].Program__r.Name);  
    
                        String strSaEmailOfPCCDisplay = saEmailOfPCCDisplay != null ? saEmailOfPCCDisplay : '';
                        htmlBody = htmlBody.replace('{SAEmailPCC}', strSaEmailOfPCCDisplay);
    
                        if(lstSpecialAcceptance[0].BindExpectedAnswerDate__c != null){
                            htmlBody = htmlBody.replace('{BindexpectedAnswerDate}', String.valueOf(lstSpecialAcceptance[0].BindExpectedAnswerDate__c));
                        }
    
                        String strComments = lstSpecialAcceptance[0].Comments__c != null ? lstSpecialAcceptance[0].Comments__c : '';
                        String commentStrDesigned = '<b style="color:blue";><font face="Arial" size="50px">' + strComments + '</font></b>'; //RRA - ticket 1382 - 1912202
                        htmlBody = htmlBody.replace('{Comments}', commentStrDesigned); //RRA - ticket 1382 - 1912202
                    }
    
                    String htmlInternetLink = '<a href="' + urlArr[0] +'">ACTOR Page</a>';
                    htmlBody = htmlBody.replace('{ActorNewGenURL}', htmlInternetLink);
                    htmlBody = htmlBody.replace('{Coveredcedingcompany}', lstSA[0].CoveredCedingCompany__r.Name); 
                    // htmlSubject = htmlSubject.replace('{CedingCompanyName}', accConRelation.Account.Name);  
                    htmlSubject = htmlSubject.replace('{CedingCompanyName}', lstSA[0].CoveredCedingCompany__r.Name);  
    
                    mail.setHtmlBody(htmlBody);
                    mail.setSubject(htmlSubject);
                    lstMails.add(mail);
                }
    
                if(lstMails.size() > 0){
                    Messaging.sendEmail((List<Messaging.Email>) lstMails);
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
        * @description Method to clone CE Special Acceptance To Ceding Portal
        * @param String saId
        * @return Map<String, Object>
        */
        @AuraEnabled
        public static Map<String, Object> cloneCESpecialAcceptanceToCedingPortal(String saId, List<AccountContactRelation> lstAccConForSharingSA) {
            Map<String, Object> mapResults = new Map<String, Object>();
            List<ContentVersion> lstCloneCEContentVersion = new List<ContentVersion>();
            List<ContentVersion> lstNewCloneCEContentVersionToInsert = new List<ContentVersion>();
            List<ContentDocumentLink> lstContentDocumentLinkCloneToInsert = new List<ContentDocumentLink>();
            List<Id> lstCloneCEContentDocument = new List<Id>();
            List<String> lstSAFields = AP_Constant.getCreatableFieldsByObjName(AP_Constant.sObjectSpecialAcceptance);
            SpecialAcceptance__c specialAcceptanceNewClone = new SpecialAcceptance__c(); 
            String strSAFields = String.join(lstSAFields , ', ');
            String lastRefIndex = '';
            Set<Id> setCloneCEContentDocumentId = new Set<Id>();
            Savepoint sp = Database.setSavepoint();
    
            try {
                String querySA = 'select Id, Program__r.UwYear__c, Program__r.PrincipalCedingCompany__c, Program__r.Nature__c, SpaDurationDays__c, Program__r.Name, CoveredCedingCompany__r.Name, Program__r.PrincipalCedingCompany__r.Name, '
                        + strSAFields
                        + ' from SpecialAcceptance__c where (Id = :saId) ' ;
    
                List<SpecialAcceptance__c> lstSpecialAcceptance = Database.query(querySA);
    
                List<SpecialAcceptance__c> lstLastSpecialAcceptance = [SELECT Id, Name, Reference__c, TECH_ReferenceIndex__c FROM SpecialAcceptance__c ORDER BY TECH_ReferenceIndex__c DESC LIMIT 1];
    
                if(lstSpecialAcceptance.size() > 0){
                    SpecialAcceptance__c specialAcceptanceCloneExisted = lstSpecialAcceptance[0];
                    String newReference;
    
                    if(lstSpecialAcceptance[0].Reference__c != null){
                        String[] refOldIndex = lstSpecialAcceptance[0].Reference__c.split('-');
                        newReference = refOldIndex[0] + '-' + refOldIndex[1] + '-' + refOldIndex[2];
                    }
    
                    specialAcceptanceNewClone = specialAcceptanceCloneExisted.clone(false, false, false, false);
                    specialAcceptanceNewClone.Id = null;
                    specialAcceptanceNewClone.TECH_Actor2Id__c = null;
                    
                    if(specialAcceptanceCloneExisted.InternalStatus__c == AP_Constant.statusAgreed){
                        specialAcceptanceNewClone.PortalStatus__c = AP_Constant.statusAgreed;
                    }
                    else if(specialAcceptanceCloneExisted.InternalStatus__c == AP_Constant.statusRefused){
                        specialAcceptanceNewClone.PortalStatus__c = AP_Constant.statusRefused;
                    }
    
                    specialAcceptanceNewClone.InternalStatus__c = null;
                    specialAcceptanceNewClone.SentAgreFromSpecialAcceptance__c = null;     
                    specialAcceptanceNewClone.Reference__c = newReference;
                    specialAcceptanceNewClone.TECH_LocalSA__c = null;
                    specialAcceptanceNewClone.IsInformCedCom__c = true;
                }
    
                if(specialAcceptanceNewClone != null){
                    insert specialAcceptanceNewClone;
    
                    for(SpecialAcceptance__c ceSa : lstSpecialAcceptance){
                        //to update ce special acceptance - SentAgreFromSpecialAcceptance__c = specialAcceptanceNewClone.Id
                        ceSa.SentAgreFromSpecialAcceptance__c = specialAcceptanceNewClone.Id;
                    }
              
                    if(lstSpecialAcceptance.size() > 0){
                        update lstSpecialAcceptance;
                    }
    
                    /*if (specialAcceptanceNewClone.SentAgreFromSpecialAcceptance__c != null){
                        idSASentAgre = specialAcceptanceNewClone.SentAgreFromSpecialAcceptance__c;
                    }*/
        
                    //RRA - ticket 1445 - 27032023
                    createSharingSAFromInformCedingCompany (lstSpecialAcceptance[0].SentAgreFromSpecialAcceptance__c, lstAccConForSharingSA);
                }
    
                for(ContentDocumentLink contentDocLink : [SELECT Id, ContentDocumentId
                                                          FROM ContentDocumentLink
                                                          WHERE LinkedEntityId = :saId]){
                    setCloneCEContentDocumentId.add(contentDocLink.ContentDocumentId);
                }
    
                if(setCloneCEContentDocumentId.size() > 0){
                    lstCloneCEContentVersion = [SELECT Id, Phase__c, Title, IsExternal__c, ContentDocumentId
                                                       , Nature__c, FileType, FileExtension, ContentUrl, ContentSize
                                                       , PathOnClient, VersionData, FirstPublishLocationId, SpecialAcceptance__c
                                                FROM ContentVersion
                                                WHERE ContentDocumentId IN :setCloneCEContentDocumentId AND IsExternal__c = FALSE];
    
                    for(ContentVersion contentVersion : lstCloneCEContentVersion){
                        ContentVersion newContentVersion = new ContentVersion();
                        newContentVersion.Title = contentVersion.Title;
                        newContentVersion.PathOnClient = contentVersion.PathOnClient;
                        newContentVersion.VersionData = contentVersion.VersionData;
                        newContentVersion.FirstPublishLocationId = contentVersion.FirstPublishLocationId;
                        newContentVersion.Nature__c = contentVersion.Nature__c;
                        newContentVersion.SpecialAcceptance__c = specialAcceptanceNewClone.Id;
                        newContentVersion.IsExternal__c = contentVersion.IsExternal__c;
                        lstNewCloneCEContentVersionToInsert.add(newContentVersion);
                    }
                }
    
                if(lstNewCloneCEContentVersionToInsert.size() > 0) {
                    insert lstNewCloneCEContentVersionToInsert;  
    
                    for(ContentVersion cv : [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN :lstNewCloneCEContentVersionToInsert]){
                        lstCloneCEContentDocument.add(cv.ContentDocumentId);
                    }
                    
                    for(Id contentDocumentId : lstCloneCEContentDocument){
                        ContentDocumentLink cd = new ContentDocumentLink();
                        cd.LinkedEntityId = specialAcceptanceNewClone.Id;
                        cd.ContentDocumentId = contentDocumentId;
                        cd.Visibility = 'AllUsers';
                        cd.ShareType = 'V';
                        lstContentDocumentLinkCloneToInsert.add(cd);
                    }
    
                    if(lstContentDocumentLinkCloneToInsert.size() > 0){
                        insert lstContentDocumentLinkCloneToInsert;
                    }
                }
    
                mapResults.put('Success', 'Success');
            }
            catch (Exception ex) {
                mapResults.put('Error', ex.getMessage());
                Database.rollback(sp);
            }
            return mapResults;
        }
    
        /**
        *  RRA - ticket 1445 - 23032023
        * @description Method to create sharing SA for Covered Ceding Company
        * @param String saId, List<AccountContactRelation> lstAccConAttachedOnSA
        * @return 0
        */
    
        public static void createSharingSAFromInformCedingCompany (String saId, List<AccountContactRelation> lstAccConAttachedOnSA){
            Set<Id> setIdCon = new Set<Id>();
            Map<Id, Id> mapIdSAIdAcc = new  Map<Id, Id> ();
            Map<Id, Id> mapIdConIdUser = new  Map<Id, Id> ();
            Map<Id, Id> mapIdUserIdAcc = new  Map<Id, Id> ();
            Map<Id, Id> mapIdUserIdSA = new  Map<Id, Id> ();
            List<SpecialAcceptance__Share> lstSAShare = new List<SpecialAcceptance__Share>();
    
            //***********************************************************************/
            // Operation Sharing SA for clone CE SpecialAcceptance to CedingPortal 
            //************************************************************************
    
            for (SpecialAcceptance__c sa : [SELECT Id, CoveredCedingCompany__c, PrincipalCedingCompany__c, SentAgreFromSpecialAcceptance__c, Program__c FROM SpecialAcceptance__c WHERE Id =:saId]){
                mapIdSAIdAcc.put(sa.CoveredCedingCompany__c, sa.Id);
            }
            System.debug('mapIdSAIdAcc cloneCESpecialAcceptanceToCedingPortal == ' + mapIdSAIdAcc);
    
            //Get list Contact Selected on step action Notify
            if (lstAccConAttachedOnSA != null && !lstAccConAttachedOnSA.isEmpty()){
                //Get ContactId From AccountContactRelation
                for (AccountContactRelation accCon : lstAccConAttachedOnSA){
                    setIdCon.add(accCon.ContactId);
                }
    
                //Get UserId From ContactId
                for (User usr : [SELECT Id, ContactId FROM User WHERE ContactId IN:setIdCon]){
                    mapIdConIdUser.put(usr.ContactId, usr.Id);
                }
    
                //Create map between UserId and AccountId
                for (AccountContactRelation accCon : lstAccConAttachedOnSA){
                    mapIdUserIdAcc.put(mapIdConIdUser.get(accCon.ContactId), accCon.AccountId);
                }
            }
    
            System.debug('mapIdConIdUser cloneCESpecialAcceptanceToCedingPortal == ' + mapIdConIdUser);
    
            //Create map between idUser and idSA
            if (mapIdUserIdAcc!= null){
                    for (Id user : mapIdUserIdAcc.keySet()){
                        mapIdUserIdSA.put(user, mapIdSAIdAcc.get(mapIdUserIdAcc.get(user)));
                    }
            }
    
            System.debug('mapIdUserIdSA cloneCESpecialAcceptanceToCedingPortal == ' + mapIdUserIdSA);
    
            if(mapIdUserIdSA != null && mapIdUserIdSA.size()>0){
                for(Id usr : mapIdUserIdSA.keySet()){
                    SpecialAcceptance__Share shareSA = new SpecialAcceptance__Share();
                    shareSA.RowCause = 'Manual';
                    shareSA.AccessLevel = 'Edit';
                    shareSA.ParentId = mapIdUserIdSA.get(usr);
                    shareSA.UserOrGroupId = usr;
                    lstSAShare.add(shareSA);
                }
            }
    
            System.debug('lstSAShare cloneCESpecialAcceptanceToCedingPortal == ' + lstSAShare);
    
            if(lstSAShare.size() > 0){
                System.debug('shareSAToUsers: inserting SA_RequestShare from cloneCESpecialAcceptanceToCedingPortal ' + lstSAShare.size() + ' elements');
                AP38_CreateSharingForRequest.Manage_DataBaseInsertSharing_UTL util = new AP38_CreateSharingForRequest.Manage_DataBaseInsertSharing_UTL();
                util.insertSAShares(lstSAShare);
                System.debug('SA Share  from informCedingCompany inserted Successfully ');
            }
            //## End Sharing ## / 
        }
    
        /**
        * @description Method to get Contact(s) for Covered Ceding Company
        * @param SpecialAcceptance__c specialAcceptanceObj
        * @return Map<String, Object>
        */
        @AuraEnabled
        public static Map<String, Object> getCovCedContact(SpecialAcceptance__c specialAcceptanceObj) {
            Map<String, Object> mapResults = new Map<String, Object>();
            List<Account> lstAccount = new List<Account>();
            List<Group> lstGroup = new List<Group>();
            List<AccountContactRelation> lstAccountContactRelationsToDisplay = new List<AccountContactRelation>();
            Map<Id, Id> mapUserIdByContactId = new Map<Id, Id>();
            Map<String, Id> mapAccountRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectAcc});
            Set<Id> setUserOrGroupId = new Set<Id>();
            Set<Id> setContactId = new Set<Id>();
            Set<Id> setAccConRelId = new Set<Id>();
            String referentialId;
            String groupId;
    
            Id covCedComId = specialAcceptanceObj.CoveredCedingCompany__c;
            Id pccId = specialAcceptanceObj.PrincipalCedingCompany__c;
    
            // Get Contact in same public group as CCC
    
            lstAccount = [SELECT Id, Name, TECH_ReferentialId__c FROM Account WHERE Id = :covCedComId LIMIT 1];
    
            if(lstAccount.size() > 0){
                referentialId = lstAccount[0].TECH_ReferentialId__c;
            }
    
            lstGroup = [SELECT Id, DeveloperName FROM Group WHERE DeveloperName = :referentialId LIMIT 1];
    
            if(lstGroup.size() > 0){
                groupId = lstGroup[0].Id;
            }
            
            for(GroupMember groupMember : [SELECT Id, GroupId, UserOrGroupId FROM GroupMember WHERE GroupId = :groupId]){
                setUserOrGroupId.add(groupMember.UserOrGroupId);
            }
    
            for(User user : [SELECT Id, ContactId, IsActive FROM User WHERE Id IN :setUserOrGroupId AND IsActive = true]){
                mapUserIdByContactId.put(user.ContactId, user.Id);
                setContactId.add(user.ContactId);
            }
    
            if(setContactId.size() > 0){
                for(AccountContactRelation accContactRelation : [SELECT Id, AccountId,Account.Name, Account.RecordTypeId, Contact.Account.RecordTypeId, Contact.Email, Roles, ContactId, Contact.MacroLoB__c, Contact.Nature__c, Contact.LastName, Contact.FirstName FROM AccountContactRelation
                                                             WHERE ContactId IN :setContactId
                                                             AND IsActive = TRUE 
                                                             AND Account.IsActive__c = TRUE]){
                    if(accContactRelation.Account.RecordTypeId == mapAccountRecTypeId.get(AP_Constant.accRTCoveredCedingCompany) && accContactRelation.Contact.Email != null){
                        lstAccountContactRelationsToDisplay.add(accContactRelation);
                        setAccConRelId.add(accContactRelation.Id);
                    }
                }   
            }
    
            //Get Contact in same public group as PCC
            Map<Id, AccountContactRelation> mapAccConRelationByContactIdPCC = new Map<Id, AccountContactRelation>();
            Map<Id, Id> mapUserIdByContactIdPCC = new Map<Id, Id>();
            Set<Id> setContactIdPCC = new Set<Id>();
            Set<Id> setUserOrGroupIdPCC = new Set<Id>();    
    
            for(AccountContactRelation accContactRelation : [SELECT Id, AccountId,Account.Name, Account.RecordTypeId, Contact.Account.RecordTypeId, Contact.Email, Roles, ContactId, Contact.MacroLoB__c, Contact.Nature__c, Contact.LastName, Contact.FirstName FROM AccountContactRelation
                                                             WHERE AccountId = :covCedComId
                                                             AND IsActive = TRUE
                                                             AND Account.IsActive__c = TRUE]){
                if(accContactRelation.Account.RecordTypeId == accContactRelation.Contact.Account.RecordTypeId){
                    setContactIdPCC.add(accContactRelation.ContactId);
                    mapAccConRelationByContactIdPCC.put(accContactRelation.ContactId, accContactRelation);
                }
            }
    
            for(User user : [SELECT Id, ContactId, IsActive FROM User WHERE ContactId IN :setContactIdPCC AND IsActive = true]){
                mapUserIdByContactIdPCC.put(user.ContactId, user.Id);
            }
    
            List<Account> lstAccountPCC = [SELECT Id, Name, TECH_ReferentialId__c FROM Account WHERE Id = :pccId LIMIT 1];
    
            String referentialIdPCC = lstAccountPCC[0].TECH_ReferentialId__c;
    
            List<Group> lstGroupPCC = [SELECT Id, DeveloperName FROM Group WHERE DeveloperName = :referentialIdPCC LIMIT 1];
    
            String groupIdPCC = lstGroupPCC[0].Id;
            
            for(GroupMember groupMember : [SELECT Id, GroupId, UserOrGroupId FROM GroupMember WHERE GroupId = :groupIdPCC]){
                setUserOrGroupIdPCC.add(groupMember.UserOrGroupId);
            }
    
            for(Id contactId : mapUserIdByContactIdPCC.keySet()){
                Id userIdPCC = mapUserIdByContactIdPCC.get(contactId);
    
                if(setUserOrGroupIdPCC.contains(userIdPCC)){
                    if(mapAccConRelationByContactIdPCC.containsKey(contactId)){
                        if(!setAccConRelId.contains(mapAccConRelationByContactIdPCC.get(contactId).Id)){
                            lstAccountContactRelationsToDisplay.add(mapAccConRelationByContactIdPCC.get(contactId));
                        }
                    }
                }
            }
            
            mapResults.put('lstAccountContactRelationsToDisplay', lstAccountContactRelationsToDisplay);
            return mapResults;
        }
    
        /**
        * @description Method to get Email Template for Broker and Reinsurer
        * @param String buttonName, String saReqId, List<ContentVersion> lstDocument
        * @return Map<String, Object>
        */
        @AuraEnabled
        public static Map<String, Object> getEmailTemplate(String buttonName, String saReqId, List<ContentVersion> lstDocument){
            Map<String, Object> mapResults = new Map<String, Object>();
            Map<String, String> mapBodyByEmailTemplateName= new Map<String, String>();
            List<String> lstEmailTemplateName = new List<String>();
            List<EmailTemplate> lstEmailTemplate = new List<EmailTemplate>();
            List<Request__c> lstSaRequest = new List<Request__c>();
            String brokerEmailTemplate;
            String brokerEmailTemplateYes;
            String brokerEmailTemplatePending;
            String reinsurerEmailTemplate;
            String poolEmailTemplate;
            String saEmailOfPCC;
            String saEmailOfPCCDisplay;
            String pccId;
            String strDocumentName = '';
    
            try{
                lstEmailTemplateName.add(AP_Constant.emailTempSendSaReqBroker);
                lstEmailTemplateName.add(AP_Constant.emailTempSendSaReqReinsurer);
                lstEmailTemplateName.add(AP_Constant.emailTempSendSaReqPool);
                lstEmailTemplateName.add(AP_Constant.emailTempUpdateSaReqBroker);
                lstEmailTemplateName.add(AP_Constant.emailTempUpdateSaReqReinsurer);
                lstEmailTemplateName.add(AP_Constant.emailTempUpdateSaReqPool);
                lstEmailTemplateName.add(AP_Constant.emailTempRemindSaReqBroker);
                lstEmailTemplateName.add(AP_Constant.emailTempRemindSaReqReinsurer);
                lstEmailTemplateName.add(AP_Constant.emailTempRemindSaReqPool);
                lstEmailTemplateName.add(AP_Constant.emailTempNotifySaReqBroker);
                lstEmailTemplateName.add(AP_Constant.emailTempNotifySaReqReinsurer);
                lstEmailTemplateName.add(AP_Constant.emailTempSaReqInformCedComAgreed);
                lstEmailTemplateName.add(AP_Constant.emailTempSaReqInformCedComRefused);
                lstEmailTemplateName.add(AP_Constant.emailTempSaReqInformCedComAgreedDeclaratrion); // MRA W-1229 - 12/08/2022 - SA Declaration Type another email template
    
                lstSaRequest = [SELECT Id, Name, TECH_ProgramName__c, Special_Acceptance__r.CoveredCedingCompany__r.Name, Special_Acceptance__r.SpecialAcceptanceName__c,Special_Acceptance__r.Type__c, Special_Acceptance__r.Bound__c, Program__r.UwYear__c, Program__r.PrincipalCedingCompany__r.Name FROM Request__c WHERE Id = : saReqId LIMIT 1];// MRA W-1229 - 12/08/2022 - SA Declaration Type another email template / RRA - ticket 1453 - 13032023
    
                if(lstSaRequest.size() > 0){
                    pccId = lstSaRequest[0].Program__r.PrincipalCedingCompany__c;   
    
                    if(pccId != null){
                        List<Account> lstPCCAccount = [SELECT Id, EmailSA__c FROM Account WHERE Id = :pccId LIMIT 1];
                        if(lstPCCAccount.size() > 0){
                            saEmailOfPCC = lstPCCAccount[0].EmailSA__c;
                            List<String> lstCCEmailsToSend = new List<String>();
    
                            if(saEmailOfPCC != null ){
                                if(saEmailOfPCC.contains(';')){
                                    lstCCEmailsToSend = saEmailOfPCC.split(';');
                                }
                                else{
                                    lstCCEmailsToSend.add(saEmailOfPCC);
                                }
                            }
    
                            for(String pccEmail : lstCCEmailsToSend){
                                if(saEmailOfPCCDisplay == null){
                                    saEmailOfPCCDisplay = pccEmail;
                                }
                                else{
                                    saEmailOfPCCDisplay = saEmailOfPCCDisplay + ' ' + pccEmail;   
                                }
                            }
                        }
                    }             
                }
    
                lstEmailTemplate = [SELECT Id, Name FROM EmailTemplate WHERE Name IN : lstEmailTemplateName];
    
                Network networkObj = [SELECT Id FROM Network WHERE Name = :System.Label.Actor_portal_name];
                String url = Network.getLoginUrl(networkObj.Id);
                List<String> urlArr = url.split('login');
    
                Network networkCedingPortalObj = [SELECT Id FROM Network WHERE Name = :System.Label.Actor_ceding_portal_name];
                String urlCedingPortal = Network.getLoginUrl(networkCedingPortalObj.Id);
                List <String> urlArrCedingPortal = urlCedingPortal.split('login');
                String htmlInternetLink;
    
                for(ContentVersion publicDoc : lstDocument){
                    if(strDocumentName == ''){
                        strDocumentName = '<li style="text-align: left;">' + publicDoc.Title + '</li>';
                    }
                    else{
                        strDocumentName += '<li style="text-align: left;">' + publicDoc.Title + '</li>';
                    }
                }
    
                for(EmailTemplate emailTemplate : lstEmailTemplate){
                    //to build map emailTemplateName - emailBody
                    Messaging.SingleEmailMessage m = Messaging.renderStoredEmailTemplate(emailTemplate.Id, UserInfo.getUserId(), saReqId);
                    m.setSaveAsActivity(false);
                    String body = m.htmlBody;
    
                    if(lstSaRequest.size() > 0){
                        body = body.replace('{Programname}', lstSaRequest[0].TECH_ProgramName__c);
                        body = body.replace('{Coveredcedingcompany}', lstSaRequest[0].Special_Acceptance__r.CoveredCedingCompany__r.Name);
                        body = body.replace('{SAname}', lstSaRequest[0].Special_Acceptance__r.SpecialAcceptanceName__c);
                        body = body.replace('{U/W Year}', lstSaRequest[0].Program__r.UwYear__c);
                        
                        if(buttonName == 'InformCedingCompany'){
                            htmlInternetLink = '<a href="' + urlArrCedingPortal[0] +'">ACTOR Page</a>';
                        }
                        else{
                            htmlInternetLink = '<a href="' + urlArr[0] + 'homepage">ACTOR New Gen HomePage</a>';
                        }
    
                        body = body.replace('{ActorNewGenURL}', htmlInternetLink);           
    
                        String strSaEmailOfPCCDisplay = saEmailOfPCCDisplay != null ? saEmailOfPCCDisplay : '';
                        body = body.replace('{SAEmailPCC}', strSaEmailOfPCCDisplay);
    
                        if(buttonName == 'Update'){
                            body = body.replace('{ListOfDocuments}', strDocumentName);
                        }
    
                        String saUrl = urlArrCedingPortal[0] + 'SADetail?s__id=' + lstSaRequest[0].Special_Acceptance__c + '-' + lstSaRequest[0].Program__r.UwYear__c + '-' + lstSaRequest[0].Program__r.PrincipalCedingCompany__c + '-' + lstSaRequest[0].Program__c;
                        String saLink = '<a href="' + saUrl +'">Link of Special Acceptance</a>';
                        body = body.replace('[URLofTheSpecialAcceptance]', saLink);
                        // body = body.replace('[URL]', saLink);
                    }
                    
                    mapBodyByEmailTemplateName.put(emailTemplate.Name, body);
                }
    
                if(buttonName == 'Send'){
                    //to get the 3 email template - broker/reinsurer/pool for send
                    brokerEmailTemplate = mapBodyByEmailTemplateName.get(AP_Constant.emailTempSendSaReqBroker);
                    reinsurerEmailTemplate = mapBodyByEmailTemplateName.get(AP_Constant.emailTempSendSaReqReinsurer);
                    poolEmailTemplate = mapBodyByEmailTemplateName.get(AP_Constant.emailTempSendSaReqPool);
                }
                else if(buttonName == 'Update'){
                    //to get the 3 email template - broker/reinsurer/pool for update
                    brokerEmailTemplate = mapBodyByEmailTemplateName.get(AP_Constant.emailTempUpdateSaReqBroker);
                    reinsurerEmailTemplate = mapBodyByEmailTemplateName.get(AP_Constant.emailTempUpdateSaReqReinsurer);
                    poolEmailTemplate = mapBodyByEmailTemplateName.get(AP_Constant.emailTempUpdateSaReqPool);
                }
                else if(buttonName == 'Remind'){
                    //to get the 3 email template - broker/reinsurer/pool for remind
                    brokerEmailTemplate = mapBodyByEmailTemplateName.get(AP_Constant.emailTempRemindSaReqBroker);
                    reinsurerEmailTemplate = mapBodyByEmailTemplateName.get(AP_Constant.emailTempRemindSaReqReinsurer);
                    poolEmailTemplate = mapBodyByEmailTemplateName.get(AP_Constant.emailTempRemindSaReqPool);
                }
                else if(buttonName == 'Notify'){
                    //to get the 2 email template - broker/reinsurer for notify
                    brokerEmailTemplate = mapBodyByEmailTemplateName.get(AP_Constant.emailTempNotifySaReqBroker);
                    reinsurerEmailTemplate = mapBodyByEmailTemplateName.get(AP_Constant.emailTempNotifySaReqReinsurer);
                }
                else if(buttonName == 'InformCedingCompany'){
                    //to get the 2 email template - agreed/refused for inform Ceding Company
                    // MRA W-1229 - 12/08/2022 - SA Declaration Type another email template START
                    if(lstSaRequest[0].Special_Acceptance__r.Type__c == '1' || lstSaRequest[0].Special_Acceptance__r.Type__c == '2'){
                        brokerEmailTemplateYes = mapBodyByEmailTemplateName.get(AP_Constant.emailTempSaReqInformCedComAgreedDeclaratrion);
                        brokerEmailTemplatePending = mapBodyByEmailTemplateName.get(AP_Constant.emailTempSaReqInformCedComAgreed);// RRA - ticket 1447 - 15032023
                    }
                    brokerEmailTemplate = mapBodyByEmailTemplateName.get(AP_Constant.emailTempSaReqInformCedComAgreed);  
                    /*else
                       */
                    // MRA W-1229 - 12/08/2022 - SA Declaration Type another email template END
                    reinsurerEmailTemplate = mapBodyByEmailTemplateName.get(AP_Constant.emailTempSaReqInformCedComRefused);
                }
    
                mapResults.put('brokerEmailTemplate', brokerEmailTemplate);
                mapResults.put('brokerEmailTemplateYes', brokerEmailTemplateYes);
                mapResults.put('brokerEmailTemplatePending', brokerEmailTemplatePending);
                mapResults.put('reinsurerEmailTemplate', reinsurerEmailTemplate);
                mapResults.put('poolEmailTemplate', poolEmailTemplate);
                mapResults.put('lstSaRequest', lstSaRequest);
                mapResults.put('Success', 'Success');
    
            } catch (Exception ex) {
                mapResults.put('Error', ex.getMessage());
            }
            return mapResults;
        }
    
        /**
        * @description Method to check if all B/R are active
        * @param List<Id> lstAccountId
        * @return Boolean
        */
        @AuraEnabled(Cacheable = true)
        public static Boolean checkActiveAccounts(List<Id> lstAccountId){
            Boolean accActive = true;
            Set<Boolean> setIsActive = new Set<Boolean>();
    
            for(Account acc : [SELECT Id, Name, IsActive__c FROM Account WHERE Id IN :lstAccountId]){
                setIsActive.add(acc.IsActive__c);
            }
    
            if(setIsActive.size() > 0){
                if(setIsActive.contains(false)){
                    accActive = false;
                }
            }
    
            return accActive;
        }
    
        
        /**
        * @description Method to retrieve Bound and Type of SA
        * @param Id idSA
        * @return SA object
        */
        @AuraEnabled(Cacheable = true)
        public static SpecialAcceptance__c getInfoSA (Id idSA){
            return [SELECT Id, Bound__c, Type__c FROM SpecialAcceptance__c WHERE Id =:idSA];
        }
    }