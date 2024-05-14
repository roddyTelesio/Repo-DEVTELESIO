public with sharing class LWC18_SendEmailForQuotePlaceSign implements Queueable{
    /**************************************************************************************
    -- - Author        : Spoon Consulting
    -- - Description   : Controller for Lightning Web Component lwc18SendUpdateRemind - Queueable class to send email for Quote/Placement/Signing
    --
    -- Maintenance History:
    --
    -- Date         Name  Version  Remarks
    -- -----------  ----  -------  -------------------------------------------------------
    -- 08-NOV-2021  MBE   1.0      Initial version
    --------------------------------------------------------------------------------------
    **************************************************************************************/
    
        public List<Request__c> lstRequest;
        public List<Request__c> lstSigningRequestSignedShare0;
        public List<AccountContactRelation> lstAccountContact;
        public String btnNameSendUpdateRemind;
        public String stageType;
        public List<String> lstCCEmailsToSend;
        public String strLstCCEmailDisplay;
        public String programName;
        public String cedingCompanyName;
        public List<ContentVersion> lstContractDoc;
        public List<ContentVersion> lstRenewDoc;
        public Map<Id, Set<String>> mapListOfCompanyByContentVersionId;
        public Set<Id> setSigningRequestSignedShare0Id;
        public Request__c requestCommentExpectedAnsDate;
        
        public LWC18_SendEmailForQuotePlaceSign(List<Request__c> lstRequest, List<Request__c> lstSigningRequestSignedShare0, List<AccountContactRelation> lstAccountContact
        , String btnNameSendUpdateRemind, String stageType, List<String> lstCCEmailsToSend, String strLstCCEmailDisplay
        , String programName, String cedingCompanyName, List<ContentVersion> lstContractDoc, List<ContentVersion> lstRenewDoc
        , Map<Id, Set<String>> mapListOfCompanyByContentVersionId, Set<Id> setSigningRequestSignedShare0Id, Request__c requestCommentExpectedAnsDate){
            
            this.lstRequest = lstRequest; 
            this.lstSigningRequestSignedShare0 = lstSigningRequestSignedShare0;
            this.lstAccountContact = lstAccountContact; 
            this.btnNameSendUpdateRemind = btnNameSendUpdateRemind;  
            this.stageType = stageType; 
            this.lstCCEmailsToSend = lstCCEmailsToSend; 
            this.strLstCCEmailDisplay = strLstCCEmailDisplay; 
            this.programName = programName; 
            this.cedingCompanyName = cedingCompanyName; 
            this.lstContractDoc = lstContractDoc; 
            this.lstRenewDoc = lstRenewDoc; 
            this.mapListOfCompanyByContentVersionId = mapListOfCompanyByContentVersionId; 
            this.setSigningRequestSignedShare0Id = setSigningRequestSignedShare0Id; 
            this.requestCommentExpectedAnsDate = requestCommentExpectedAnsDate; 
        }
    
        public void execute(QueueableContext context) {
            Id userId = UserInfo.getUserId();
            Id emailTemplateUpdateId;
            Id emailTempSendQuoteReqReinsurerForQuoteId;
            Id emailTempSendRQuoteReqReinsurerForInfoId;
            Id emailTempSendQuoteReqBrokerForQuoteId;
            Id emailTempSendQuoteReqBrokerForInfoId;
    
            String emailTempSendQuoteReqBrokerForQuoteName;
            String emailTempSendQuoteReqBrokerForInfoName;
            String emailTempSendQuoteReqReinsurerForQuoteName;
            String emailTempSendQuoteReqReinsurerForInfoName;
    
            Id emailTempSendPlacementReqBroker;
            Id emailTempSendPlacementReqReinsurer;
            Id emailTempSendSigningReqBroker;
            Id emailTempSendSigningReqReinsurer;
            Id emailTempSendSigningBrokerSignedShare;
            Id emailTempSendSigningReinsurerSignedShare;
    
            List<String> lstEmailTemplateName = new List<String>{AP_Constant.emailTemplateUpdateReq
                                                                ,AP_Constant.emailTemplateSendQuoteReqReinsurerForQuote
                                                                ,AP_Constant.emailTemplateSendRQuoteReqReinsurerForInformation
                                                                ,AP_Constant.emailTemplateSendQuoteReqBrokerForQuote
                                                                ,AP_Constant.emailTemplateSendQuoteReqBrokerForInformation
                                                                ,AP_Constant.emailTemplateSendPlacementReqBroker
                                                                ,AP_Constant.emailTemplateSendPlacementReqReinsurer
                                                                ,AP_Constant.emailTemplateSendSigningReqBroker
                                                                ,AP_Constant.emailTemplateSendSigningReqReinsurer
                                                                ,AP_Constant.emailTemplateSendSigningBrokerSignedShare
                                                                ,AP_Constant.emailTemplateSendSigningReinsurerSignedShare};
    
            List<EmailTemplate> lstEmailTemplate = [SELECT Id, Name FROM EmailTemplate WHERE Name IN : lstEmailTemplateName];
    
            for(EmailTemplate emailTemplate : lstEmailTemplate){
                if(emailTemplate.Name == AP_Constant.emailTemplateUpdateReq){
                    emailTemplateUpdateId = emailTemplate.Id;
                }
                else if(emailTemplate.Name == AP_Constant.emailTemplateSendQuoteReqReinsurerForQuote){
                    emailTempSendQuoteReqReinsurerForQuoteId = emailTemplate.Id;
                    emailTempSendQuoteReqReinsurerForQuoteName = emailTemplate.Name;
                }
                else if(emailTemplate.Name == AP_Constant.emailTemplateSendRQuoteReqReinsurerForInformation){
                    emailTempSendRQuoteReqReinsurerForInfoId = emailTemplate.Id;
                    emailTempSendQuoteReqReinsurerForInfoName = emailTemplate.Name;
                }
                else if(emailTemplate.Name == AP_Constant.emailTemplateSendQuoteReqBrokerForQuote){
                    emailTempSendQuoteReqBrokerForQuoteId = emailTemplate.Id;
                    emailTempSendQuoteReqBrokerForQuoteName = emailTemplate.Name;
                }
                else if(emailTemplate.Name == AP_Constant.emailTemplateSendQuoteReqBrokerForInformation){
                    emailTempSendQuoteReqBrokerForInfoId = emailTemplate.Id;
                    emailTempSendQuoteReqBrokerForInfoName = emailTemplate.Name;
                }
                else if(emailTemplate.Name == AP_Constant.emailTemplateSendPlacementReqBroker){
                    emailTempSendPlacementReqBroker = emailTemplate.Id;
                }
                else if(emailTemplate.Name == AP_Constant.emailTemplateSendPlacementReqReinsurer){
                    emailTempSendPlacementReqReinsurer = emailTemplate.Id;
                }
                else if(emailTemplate.Name == AP_Constant.emailTemplateSendSigningReqBroker){
                    emailTempSendSigningReqBroker = emailTemplate.Id;
                }
                else if(emailTemplate.Name == AP_Constant.emailTemplateSendSigningReqReinsurer){
                    emailTempSendSigningReqReinsurer = emailTemplate.Id;
                }
                else if(emailTemplate.Name == AP_Constant.emailTemplateSendSigningBrokerSignedShare){
                    emailTempSendSigningBrokerSignedShare = emailTemplate.Id;
                }
                else if(emailTemplate.Name == AP_Constant.emailTemplateSendSigningReinsurerSignedShare){
                    emailTempSendSigningReinsurerSignedShare = emailTemplate.Id;
                }
            }
    
            Messaging.SingleEmailMessage mUpdate = new Messaging.SingleEmailMessage();       
            mUpdate = Messaging.renderStoredEmailTemplate(emailTemplateUpdateId, userId, lstRequest[0].Id);
    
            Messaging.SingleEmailMessage mSendQuoteReqReinsurerForQuote = new Messaging.SingleEmailMessage();       
            mSendQuoteReqReinsurerForQuote = Messaging.renderStoredEmailTemplate(emailTempSendQuoteReqReinsurerForQuoteId, userId, lstRequest[0].Id);
    
            Messaging.SingleEmailMessage mSendRQuoteReqReinsurerForInfo = new Messaging.SingleEmailMessage();       
            mSendRQuoteReqReinsurerForInfo = Messaging.renderStoredEmailTemplate(emailTempSendRQuoteReqReinsurerForInfoId, userId, lstRequest[0].Id);
    
            Messaging.SingleEmailMessage mSendQuoteReqBrokerForQuote = new Messaging.SingleEmailMessage();       
            mSendQuoteReqBrokerForQuote = Messaging.renderStoredEmailTemplate(emailTempSendQuoteReqBrokerForQuoteId, userId, lstRequest[0].Id);
    
            Messaging.SingleEmailMessage mSendQuoteReqBrokerForInfo = new Messaging.SingleEmailMessage();       
            mSendQuoteReqBrokerForInfo = Messaging.renderStoredEmailTemplate(emailTempSendQuoteReqBrokerForInfoId, userId, lstRequest[0].Id);
    
            Messaging.SingleEmailMessage mSendPlacementReqBroker = new Messaging.SingleEmailMessage();       
            mSendPlacementReqBroker = Messaging.renderStoredEmailTemplate(emailTempSendPlacementReqBroker, userId, lstRequest[0].Id);
    
            Messaging.SingleEmailMessage mSendPlacementReqReinsurer = new Messaging.SingleEmailMessage();       
            mSendPlacementReqReinsurer = Messaging.renderStoredEmailTemplate(emailTempSendPlacementReqReinsurer, userId, lstRequest[0].Id);
    
            Messaging.SingleEmailMessage mSendSigningReqBroker = new Messaging.SingleEmailMessage();       
            mSendSigningReqBroker = Messaging.renderStoredEmailTemplate(emailTempSendSigningReqBroker, userId, lstRequest[0].Id);
    
            Messaging.SingleEmailMessage mSendSigningReqReinsurer = new Messaging.SingleEmailMessage();       
            mSendSigningReqReinsurer = Messaging.renderStoredEmailTemplate(emailTempSendSigningReqReinsurer, userId, lstRequest[0].Id);
    
            Messaging.SingleEmailMessage mSendSigningBrokerSignedShare = new Messaging.SingleEmailMessage();       
            mSendSigningBrokerSignedShare = Messaging.renderStoredEmailTemplate(emailTempSendSigningBrokerSignedShare, userId, lstRequest[0].Id);
    
            Messaging.SingleEmailMessage mSendSigningReinsurerSignedShare = new Messaging.SingleEmailMessage();       
            mSendSigningReinsurerSignedShare = Messaging.renderStoredEmailTemplate(emailTempSendSigningReinsurerSignedShare, userId, lstRequest[0].Id);
    
            Map<Id, List<Request__c>> mapLstRequestByAccID = new Map<Id, List<Request__c>>();
            Map<Id, List<AccountContactRelation>> mapLstAccountContactByAccID = new Map<Id, List<AccountContactRelation>>();
            List<Messaging.SingleEmailMessage> lstMailsForQuote =  new List<Messaging.SingleEmailMessage>();
            List<Messaging.SingleEmailMessage> lstMailsForInfo =  new List<Messaging.SingleEmailMessage>();
            List<Messaging.SingleEmailMessage> lstMails =  new List<Messaging.SingleEmailMessage>();
            List<Messaging.SingleEmailMessage> lstSignedShareMail =  new List<Messaging.SingleEmailMessage>();
            Map<Id, List<Request__c>> mapLstSigningRequestByAccID = new Map<Id, List<Request__c>>();
    
            for(Request__c request : lstRequest){
                List<Request__c> lstUpdRequest = new List<Request__c>();
                if(request.Broker__c != null){
                    if(mapLstRequestByAccID.containsKey(request.Broker__c)){
                        lstUpdRequest = mapLstRequestByAccID.get(request.Broker__c);
                        lstUpdRequest.add(request);
                        mapLstRequestByAccID.put(request.Broker__c, lstUpdRequest);
                    }
                    else{
                        lstUpdRequest.add(request);
                        mapLstRequestByAccID.put(request.Broker__c, lstUpdRequest);
                    }
                }
                else{
                    if(mapLstRequestByAccID.containsKey(request.Reinsurer__c)){
                        lstUpdRequest = mapLstRequestByAccID.get(request.Reinsurer__c);
                        lstUpdRequest.add(request);
                        mapLstRequestByAccID.put(request.Reinsurer__c, lstUpdRequest);
                    }
                    else{
                        lstUpdRequest.add(request);
                        mapLstRequestByAccID.put(request.Reinsurer__c, lstUpdRequest);
                    }
                }
    
                System.debug('lstUpdRequest == ' + lstUpdRequest);
            }
    
            for(Request__c signingRequest : lstSigningRequestSignedShare0){
                List<Request__c> lstUpdRequest = new List<Request__c>();
                if(signingRequest.Broker__c != null){
                    if(mapLstSigningRequestByAccID.containsKey(signingRequest.Broker__c)){
                        lstUpdRequest = mapLstSigningRequestByAccID.get(signingRequest.Broker__c);
                        lstUpdRequest.add(signingRequest);
                        mapLstSigningRequestByAccID.put(signingRequest.Broker__c, lstUpdRequest);
                    }
                    else{
                        lstUpdRequest.add(signingRequest);
                        mapLstSigningRequestByAccID.put(signingRequest.Broker__c, lstUpdRequest);
                    }
                }
                else{
                    if(mapLstSigningRequestByAccID.containsKey(signingRequest.Reinsurer__c)){
                        lstUpdRequest = mapLstSigningRequestByAccID.get(signingRequest.Reinsurer__c);
                        lstUpdRequest.add(signingRequest);
                        mapLstSigningRequestByAccID.put(signingRequest.Reinsurer__c, lstUpdRequest);
                    }
                    else{
                        lstUpdRequest.add(signingRequest);
                        mapLstSigningRequestByAccID.put(signingRequest.Reinsurer__c, lstUpdRequest);
                    }
                }
            }
    
            for(AccountContactRelation accountContact : lstAccountContact){
                List<AccountContactRelation> lstUpdAccountContact = new List<AccountContactRelation>();
                if(mapLstAccountContactByAccID.containsKey(accountContact.AccountId)){
                    lstUpdAccountContact = mapLstAccountContactByAccID.get(accountContact.AccountId);
                    lstUpdAccountContact.add(accountContact);
                    mapLstAccountContactByAccID.put(accountContact.AccountId, lstUpdAccountContact);
                }
                else{
                    lstUpdAccountContact.add(accountContact);
                    mapLstAccountContactByAccID.put(accountContact.AccountId, lstUpdAccountContact);
                }
            }
    
            Network networkObj = [SELECT Id
                                    FROM Network
                                    WHERE Name =: System.Label.Actor_portal_name];
    
            String url = Network.getLoginUrl(networkObj.Id);
            List <String> urlArr = url.split('login');
    
            if(btnNameSendUpdateRemind == 'Send' && stageType == 'Signing'){
                for(Id accountId : mapLstAccountContactByAccID.keySet()){
                    List<AccountContactRelation> lstAccountContactByAccId = mapLstAccountContactByAccID.get(accountId);
                    for(AccountContactRelation accountContact : lstAccountContactByAccId) {
                        List<Request__c> lstSigningRequestByAccId = new List<Request__c>();
    
                        if(mapLstSigningRequestByAccID.containsKey(accountContact.AccountId)){
                            lstSigningRequestByAccId = mapLstSigningRequestByAccID.get(accountContact.AccountId);
                            Boolean isBroker;
    
                            List<String> lstTreatyReinsurer = new List<String>();
                            Map<String, List<String>> mapLstReinsurerByTreaty = new Map<String, List<String>>();
    
                            for(Request__c signingRequest : lstSigningRequestByAccId){
                                List<String> lstReinsurer = new List<String>();
                                if(mapLstReinsurerByTreaty.containsKey(signingRequest.TECH_TreatyName__c)){
                                    lstReinsurer = mapLstReinsurerByTreaty.get(signingRequest.TECH_TreatyName__c);
                                }
    
                                lstReinsurer.add(signingRequest.TECH_ReinsurerName__c);
                                mapLstReinsurerByTreaty.put(signingRequest.TECH_TreatyName__c, lstReinsurer);
    
                                if(signingRequest.Broker__c == null){
                                    lstReinsurer.add(signingRequest.TECH_ReinsurerName__c);
                                    isBroker = false;
                                }
                                else{
                                    isBroker = true;
                                }
                            }
    
                            for(String treatyName : mapLstReinsurerByTreaty.keySet() ){
                                List<String> lstReinsurerName = mapLstReinsurerByTreaty.get(treatyName);
                                String reinsString = '';
    
                                for(String reinsurerName : lstReinsurerName){
                                    if(reinsString == ''){
                                        reinsString = reinsurerName;
                                    }
                                    else{
                                        reinsString = reinsString + ', ' +reinsurerName;
                                    }
                                }
    
                                lstTreatyReinsurer.add('For the treaty '+treatyName+ ' : ' +reinsString);
                            }
    
                            if(lstSigningRequestByAccId.size() > 0){
                                Id reqId = lstSigningRequestSignedShare0[0].Id;
                                List<Messaging.SingleEmailMessage> lstEmailMessageSigning = new List<Messaging.SingleEmailMessage>();
                                Messaging.SingleEmailMessage m = new Messaging.SingleEmailMessage();
    
                                if(isBroker == true){
                                    m.setTemplateId(emailTempSendSigningBrokerSignedShare);
                                    m.setTargetObjectId(userId);
                                    m.setWhatId(reqId);
                                    m.setSaveAsActivity(false);
                                    m.setSubject(mSendSigningBrokerSignedShare.getSubject());
                                    m.setHtmlBody(mSendSigningBrokerSignedShare.htmlBody);
                                    lstEmailMessageSigning.add(m);
                                }
                                else{
                                    m.setTemplateId(emailTempSendSigningReinsurerSignedShare);
                                    m.setTargetObjectId(userId);
                                    m.setWhatId(reqId);
                                    m.setSaveAsActivity(false);
                                    m.setSubject(mSendSigningReinsurerSignedShare.getSubject());
                                    m.setHtmlBody(mSendSigningReinsurerSignedShare.htmlBody);
                                    lstEmailMessageSigning.add(m);
                                }
    
                                for(Messaging.SingleEmailMessage emailMessage : lstEmailMessageSigning) {
                                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                                    List<String> sendTo = new List<String>();
                                    sendTo.add(accountContact.Contact.Email);
                                    mail.setToAddresses(sendTo);
                                    mail.setReplyTo(UserInfo.getUserEmail());
                                    mail.setSenderDisplayName(UserInfo.getFirstName() + ' ' + UserInfo.getLastName());
    
                                    if(lstCCEmailsToSend.size() > 0){
                                        mail.setCcAddresses(lstCCEmailsToSend);
                                    }
    
                                    String htmlBody = emailMessage.htmlBody;
                                    String subject = emailMessage.getSubject();
    
                                    if(htmlBody != null && htmlBody != ''){
                                        htmlBody = htmlBody.replace('{ProgramName}', programName);
                                        htmlBody = htmlBody.replace('{CedingCompanyName}', cedingCompanyName);
                                        subject = subject.replace('{ProgramName}', programName);
                                        subject = subject.replace('{CedingCompanyName}', cedingCompanyName);
                                    }
                                    
                                    mail.setSubject(subject);
    
                                    if(lstTreatyReinsurer.size() > 0){
                                        String listTreatyListReinsurer = '';
    
                                        for(String treatyReinsurer : lstTreatyReinsurer){
                                            if(listTreatyListReinsurer == ''){
                                                listTreatyListReinsurer = '<li style="text-align: left;">' + treatyReinsurer + '</li>';
                                            }
                                            else{
                                                listTreatyListReinsurer += '<li style="text-align: left;">' + treatyReinsurer + '</li>';
                                            }
                                        }
    
                                        if(htmlBody != null && htmlBody != ''){
                                            htmlBody = htmlBody.replace('{ListTreatysListReinsurers}', listTreatyListReinsurer);
                                        }
                                    }
    
                                    if(htmlBody != null && htmlBody != ''){
                                        String strLstCCEmailDisplayInEmail = strLstCCEmailDisplay != null ? strLstCCEmailDisplay : '';
                                        htmlBody = htmlBody.replace('{emailP_C_LIFE}', strLstCCEmailDisplayInEmail);
    
                                        String htmlInternetLink = '<a href="' + urlArr[0] + 'homepage">ACTOR New Gen HomePage</a>';
                                        htmlBody = htmlBody.replace('{InternetLink}', htmlInternetLink);
                                    }
    
                                    mail.setHtmlBody(htmlBody);
                                    lstSignedShareMail.add(mail);
                                }
                            }
                        }
                    }
                }
    
                if(lstSignedShareMail.size() > 0){
                    Messaging.sendEmail((List<Messaging.Email>) lstSignedShareMail);
                }
            }
    
            for(Id accountId : mapLstAccountContactByAccID.keySet()){
                List<AccountContactRelation> lstAccountContactByAccId = mapLstAccountContactByAccID.get(accountId);
    
                for(AccountContactRelation accountContact : lstAccountContactByAccId){
                    List<Request__c> lstRequestByAccId = new List<Request__c>();
                    lstRequestByAccId = mapLstRequestByAccID.get(accountContact.AccountId);
                    List<String> lstTreatysListReinsurers = new List<String>();
                    List<String> lstTreatysListReinsurersForQuote = new List<String>();
                    List<String> lstTreatysListReinsurersForInfo = new List<String>();
                    Map<String, String> mapBrokerReinsIds = new Map<String, String>();
                    Request__c quoteReqForQuote = new Request__c();
                    Request__c quoteReqForInfo = new Request__c();
                    Set<String> setBrokerReinsurerReq = new Set<String>();
                    String reinsurerLinks = '';
                    String reinsurerLinksForQuote = '';
                    String reinsurerLinksForInfo = '';
                    Id requestId;
                    System.debug('lstRequestByAccId == ' + lstRequestByAccId);
                    for(Request__c request : lstRequestByAccId){
                        requestId = request.Id;
                        System.debug('request.QuoteType__c 11 == ' + request.QuoteType__c);
                        if(request.Broker__c == null){
                            setBrokerReinsurerReq.add('undefined-' + request.Reinsurer__c);
                        }
                        else{
                            setBrokerReinsurerReq.add(request.Broker__c + '-' + request.Reinsurer__c);
                        }
    
                        String brokerReinsIsQuote = request.Broker__c + '-' + request.Reinsurer__c;
                        String reinBrokerLinkQuote = urlArr[0] + 'request?c__details=';
                        if(btnNameSendUpdateRemind == 'Send' && stageType == 'Quote'){
                            String treatysListReinsurers = '';
                            treatysListReinsurers = request.TECH_TreatyName__c + ' / ' + request.TECH_SectionName__c + ' : ' + request.TECH_ReinsurerName__c;
    
                            if(request.QuoteType__c == '1'){
                                
                                //for Quote
                                quoteReqForQuote = request;
                                lstTreatysListReinsurersForQuote.add(treatysListReinsurers);
                            }
                            if(request.QuoteType__c == '2'){
                                //for Information
                                quoteReqForInfo = request;
                                lstTreatysListReinsurersForInfo.add(treatysListReinsurers);
                            }
    
                            System.debug('lstTreatysListReinsurersForQuote 11 ' + lstTreatysListReinsurersForQuote);
                            System.debug('lstTreatysListReinsurersForInfo 11' + lstTreatysListReinsurersForInfo);
    
                            if(!mapBrokerReinsIds.containsKey(brokerReinsIsQuote)){
                                if(accountContact.Contact.AccountType__c == AP_Constant.contactBroker) {
                                    reinBrokerLinkQuote += request.Program__c + '-' + request.Reinsurer__c + '-' + request.Broker__c + '-' + request.Program__r.TECH_StageName__c + '-'+request.Id; 
                                }
                                else if(accountContact.Contact.AccountType__c == AP_Constant.contactReinsurer) {
                                    reinBrokerLinkQuote += request.Program__c + '-' + request.Reinsurer__c + '-null-' + request.Program__r.TECH_StageName__c + '-'+request.Id; 
                                }
                            }
                            if (request.QuoteType__c == '1') {
                                //for Quote
                                System.debug('Nandalo 1');
                                reinsurerLinks += '<li style="text-align: left;"><a href="'+ reinBrokerLinkQuote + '">'+ request.Reinsurer__r.Name +'</a> </li>';
                                reinsurerLinksForQuote += '<li style="text-align: left;"><a href="'+ reinBrokerLinkQuote + '">'+ request.Reinsurer__r.Name +'</a> </li>';
                                System.debug('Nandalo 2');
                                System.debug('reinsurerLinksForQuote 00 == ' + reinsurerLinksForQuote);
                            }
                            if (request.QuoteType__c == '2') {
                                //for Information
                                reinsurerLinks += '<li style="text-align: left;"><a href="'+ reinBrokerLinkQuote + '">'+ request.Reinsurer__r.Name +'</a> </li>';
                                reinsurerLinksForInfo += '<li style="text-align: left;"><a href="'+ reinBrokerLinkQuote + '">'+ request.Reinsurer__r.Name +'</a> </li>';
                            }
                        }else{
                            reinsurerLinks += '<li style="text-align: left;"><a href="'+ reinBrokerLinkQuote + '">'+ request.Reinsurer__r.Name +'</a> </li>';
                        }
                        mapBrokerReinsIds.put(brokerReinsIsQuote, brokerReinsIsQuote);
    
                        if(btnNameSendUpdateRemind == 'Update' && stageType == 'Quote'){
                            String treatysListReinsurers = '';
                            treatysListReinsurers = request.TECH_TreatyName__c + ' / ' + request.TECH_SectionName__c + ' : ' + request.TECH_ReinsurerName__c;
    
                            if(request.QuoteType__c == '2'){
                                //for Information
                                quoteReqForInfo = request;
                                lstTreatysListReinsurersForInfo.add(treatysListReinsurers);
                            }
                        }
                        else if(btnNameSendUpdateRemind == 'Send' && stageType == 'Signing'){
                            if(!setSigningRequestSignedShare0Id.contains(requestId)) {
                                String treatysListReinsurers = '';
                                treatysListReinsurers = request.TECH_TreatyName__c + ' : ' + request.TECH_ReinsurerName__c;
                                lstTreatysListReinsurers.add(treatysListReinsurers);
                            }
                        }
                        else{
                            String treatysListReinsurers = '';
                            treatysListReinsurers = request.TECH_TreatyName__c + ' : ' + request.TECH_ReinsurerName__c;
                            lstTreatysListReinsurers.add(treatysListReinsurers);
                        }
    
                        String brokerReinsIs = request.Broker__c + '-' + request.Reinsurer__c;
                        if(!mapBrokerReinsIds.containsKey(brokerReinsIs)){
                            String reinBrokerLink = urlArr[0] + 'request?c__details=';
    
                            if(accountContact.Contact.AccountType__c == AP_Constant.contactBroker) {
                                if(stageType == 'Signing'){
                                    reinBrokerLink += request.Program__c + '-' + request.Id + '-Signing';
                                }
                                /*else{
                                    reinBrokerLink += request.Program__c + '-' + request.Reinsurer__c + '-' + request.Broker__c + '-' + request.Program__r.TECH_StageName__c + '-'+request.Id; //RRA - 1045;
                                }*/
                            }
                            else if(accountContact.Contact.AccountType__c == AP_Constant.contactReinsurer) {
                                if(stageType == 'Signing'){
                                    reinBrokerLink += request.Program__c + '-' + request.Id + '-Signing';
                                }
                                /*else{
                                    reinBrokerLink += request.Program__c + '-' + request.Reinsurer__c + '-null-' + request.Program__r.TECH_StageName__c + '-'+request.Id; //RRA - 1045;
                                }*/
                            }
    
                            /*if(stageType == 'Quote') {
                                System.debug('request.QuoteType__c 22 == ' + request.QuoteType__c);
                                if (request.QuoteType__c == '1') {
                                    //for Quote
                                    System.debug('Nandalo 1');
                                    reinsurerLinks += '<li style="text-align: left;"><a href="'+ reinBrokerLink + '">'+ request.Reinsurer__r.Name +'</a> </li>';
                                    reinsurerLinksForQuote += '<li style="text-align: left;"><a href="'+ reinBrokerLink + '">'+ request.Reinsurer__r.Name +'</a> </li>';
                                    System.debug('Nandalo 2');
                                    System.debug('reinsurerLinksForQuote 00 == ' + reinsurerLinksForQuote);
                                }
                                if (request.QuoteType__c == '2') {
                                    //for Information
                                    reinsurerLinks += '<li style="text-align: left;"><a href="'+ reinBrokerLink + '">'+ request.Reinsurer__r.Name +'</a> </li>';
                                    reinsurerLinksForInfo += '<li style="text-align: left;"><a href="'+ reinBrokerLink + '">'+ request.Reinsurer__r.Name +'</a> </li>';
                                }
    
                                System.debug('reinsurerLinksForQuote 11 == ' + reinsurerLinksForQuote);
                                System.debug('reinsurerLinksForInfo 11 == ' + reinsurerLinksForInfo);
                            }
                            else{
                                reinsurerLinks += '<li style="text-align: left;"><a href="'+ reinBrokerLink + '">'+ request.Reinsurer__r.Name +'</a> </li>';
                            }*/
                            mapBrokerReinsIds.put(brokerReinsIs, brokerReinsIs);
                        }
                    }
    
                    System.debug('reinsurerLinksForQuote 22 == ' + reinsurerLinksForQuote);
                    System.debug('reinsurerLinksForInfo 22 == ' + reinsurerLinksForInfo);
                    //FMU : W-1061
                    lstTreatysListReinsurersForQuote.sort();
                    lstTreatysListReinsurersForInfo.sort();
                    lstTreatysListReinsurers.sort();
    
    
                    List<Messaging.SingleEmailMessage> lstEmailMessage = new List<Messaging.SingleEmailMessage>();
                    List<Id> lstIdTemplateForQuote = new List<Id>();
                    List<Id> lstIdTemplateForInfo = new List<Id>();
                    String htmlBodyForQuotee;
                    String htmlBodyForInfoo;
                    String subjectQuote;
                    String subjectInfo;
                    Boolean isQuote = false;
                    Boolean isInfo = false;
                    Messaging.SingleEmailMessage m = new Messaging.SingleEmailMessage();
    
                    if(btnNameSendUpdateRemind == 'Send'){
                        if(stageType == 'Quote'){
                            if(quoteReqForQuote.QuoteType__c != null){
                                System.debug('Begin quoteReqForQuote');
                                if(accountContact.Contact.AccountType__c == AP_Constant.contactBroker) {
                                    System.debug('Begin quoteReqForQuote Broker emailTempSendQuoteReqBrokerForQuoteId ' + emailTempSendQuoteReqBrokerForQuoteId);
                                    m.setTemplateId(emailTempSendQuoteReqBrokerForQuoteId);
                                    m.setTargetObjectId(userId);
                                    m.setWhatId(requestId);
                                    m.setSaveAsActivity(false);
                                    m.setSubject(mSendQuoteReqBrokerForQuote.getSubject());
                                    m.setHtmlBody(mSendQuoteReqBrokerForQuote.htmlBody);
                                    isQuote = true;
                                    //lstEmailMessage.add(m);
                                    lstIdTemplateForQuote.add(m.getTemplateId());
                                    htmlBodyForQuotee = m.getHtmlBody();
                                    subjectQuote = m.getSubject();
                                    System.debug('Begin quoteReqForQuote Broker getTemplateId ' + m.getTemplateId());
                                    System.debug('Begin quoteReqForQuote Broker getHtmlBody ' + m.getHtmlBody());
                                }
                                else if(accountContact.Contact.AccountType__c == AP_Constant.contactReinsurer) {
                                    System.debug('Begin quoteReqForQuote Reinsurer emailTempSendQuoteReqReinsurerForQuoteId ' + emailTempSendQuoteReqReinsurerForQuoteId);
                                    m.setTemplateId(emailTempSendQuoteReqReinsurerForQuoteId);
                                    m.setTargetObjectId(userId);
                                    m.setWhatId(requestId);
                                    m.setSaveAsActivity(false);
                                    m.setSubject(mSendQuoteReqReinsurerForQuote.getSubject());
                                    m.setHtmlBody(mSendQuoteReqReinsurerForQuote.htmlBody);
                                    isQuote = true;
                                    //lstEmailMessage.add(m);
                                    lstIdTemplateForQuote.add(m.getTemplateId());
                                    htmlBodyForQuotee = m.getHtmlBody();
                                    subjectQuote = m.getSubject();
                                    //System.debug('Begin quoteReqForQuote Reinsurer lstEmailMessage ' + lstEmailMessage);
                                }
                            }
                            if(quoteReqForInfo.QuoteType__c != null){
                                System.debug('Begin quoteReqForInfo');
                                if(accountContact.Contact.AccountType__c == AP_Constant.contactBroker) {
                                    System.debug('Begin quoteReqForInfo Broker emailTempSendQuoteReqBrokerForInfoId ' + emailTempSendQuoteReqBrokerForInfoId);
                                    m.setTemplateId(emailTempSendQuoteReqBrokerForInfoId);
                                    m.setTargetObjectId(userId);
                                    m.setWhatId(requestId);
                                    m.setSaveAsActivity(false);
                                    m.setSubject(mSendQuoteReqBrokerForInfo.getSubject());
                                    m.setHtmlBody(mSendQuoteReqBrokerForInfo.htmlBody);
                                    isInfo = true;
                                    lstIdTemplateForInfo.add(m.getTemplateId());
                                    htmlBodyForInfoo = m.getHtmlBody();
                                    subjectInfo = m.getSubject();
                                    //lstEmailMessage.add(m);
                                    System.debug('Begin quoteReqForInfo Broker getHtmlBody ' + m.getHtmlBody());
                                    //System.debug('Begin quoteReqForInfo Broker lstEmailMessage ' + lstEmailMessage);
                                }
                                else if(accountContact.Contact.AccountType__c == AP_Constant.contactReinsurer) {
                                    System.debug('Begin quoteReqForInfo Reinsurer emailTempSendRQuoteReqReinsurerForInfoId ' + emailTempSendRQuoteReqReinsurerForInfoId);
                                    m.setTemplateId(emailTempSendRQuoteReqReinsurerForInfoId);
                                    m.setTargetObjectId(userId);
                                    m.setWhatId(requestId);
                                    m.setSaveAsActivity(false);
                                    m.setSubject(mSendRQuoteReqReinsurerForInfo.getSubject());
                                    m.setHtmlBody(mSendRQuoteReqReinsurerForInfo.htmlBody);
                                    isInfo = true;
                                    lstIdTemplateForInfo.add(m.getTemplateId());
                                    htmlBodyForInfoo = m.getHtmlBody();
                                    subjectInfo = m.getSubject();
                                    //lstEmailMessage.add(m);
                                    //System.debug('Begin quoteReqForInfo Reinsurer lstEmailMessage ' + lstEmailMessage);
                                }
                            }
                        }
                        else{
                            if(accountContact.Contact.AccountType__c == AP_Constant.contactBroker) {
                                if(stageType == 'Placement'){
                                    m.setTemplateId(emailTempSendPlacementReqBroker);
                                    m.setTargetObjectId(userId);
                                    m.setWhatId(requestId);
                                    m.setSaveAsActivity(false);
                                    m.setSubject(mSendPlacementReqBroker.getSubject());
                                    m.setHtmlBody(mSendPlacementReqBroker.htmlBody);
                                    lstEmailMessage.add(m);
                                }
                                else if(stageType == 'Signing'){
                                    m.setTemplateId(emailTempSendSigningReqBroker);
                                    m.setTargetObjectId(userId);
                                    m.setWhatId(requestId);
                                    m.setSaveAsActivity(false);
                                    m.setSubject(mSendSigningReqBroker.getSubject());
                                    m.setHtmlBody(mSendSigningReqBroker.htmlBody);
                                    lstEmailMessage.add(m);
                                }
    
                            }
                            else if(accountContact.Contact.AccountType__c == AP_Constant.contactReinsurer) {
                                if(stageType == 'Placement'){
                                    System.debug('Nandalo placement');
                                    m.setTemplateId(emailTempSendPlacementReqReinsurer);
                                    m.setTargetObjectId(userId);
                                    m.setWhatId(requestId);
                                    m.setSaveAsActivity(false);
                                    m.setSubject(mSendPlacementReqReinsurer.getSubject());
                                    m.setHtmlBody(mSendPlacementReqReinsurer.htmlBody);
                                    lstEmailMessage.add(m);
                                }
                                else if(stageType == 'Signing'){
                                    System.debug('Nandalo Signing');
                                    m.setTemplateId(emailTempSendSigningReqReinsurer);
                                    m.setTargetObjectId(userId);
                                    m.setWhatId(requestId);
                                    m.setSaveAsActivity(false);
                                    m.setSubject(mSendSigningReqReinsurer.getSubject());
                                    m.setHtmlBody(mSendSigningReqReinsurer.htmlBody);
                                    lstEmailMessage.add(m);
                                }
                            }
                        }
                    }
                    else if(btnNameSendUpdateRemind == 'Update'){
                        m.setTemplateId(emailTemplateUpdateId);
                        m.setTargetObjectId(userId);
                        m.setWhatId(requestId);
                        m.setSaveAsActivity(false);
                        m.setSubject(mUpdate.getSubject());
                        m.setHtmlBody(mUpdate.htmlBody);
                        lstEmailMessage.add(m);
                    }
    
                    System.debug('lstIdTemplateForQuote == ' + lstIdTemplateForQuote);
                    System.debug('lstIdTemplateForInfo == ' + lstIdTemplateForInfo);
    
                    System.debug('htmlBodyForQuotee == ' + htmlBodyForQuotee);
                    System.debug('htmlBodyForInfoo == ' + htmlBodyForInfoo);
    
    
                    // RRA - 1311 TP - Mail au courtier manquant pour les "For Quote" 11/102022
                    //*********************************** */
                    Messaging.SingleEmailMessage mailforQuote = new Messaging.SingleEmailMessage();
                    Messaging.SingleEmailMessage mailforInfo = new Messaging.SingleEmailMessage();
                    List<String> sendTo = new List<String>();
                    sendTo.add(accountContact.Contact.Email);
                    System.debug('sendTo == ' + sendTo);
                    String htmlBodyForQuote;
                    String htmlBodyForInfo;
    
                    if (lstIdTemplateForQuote.size() > 0 && isQuote){
                        mailforQuote.setToAddresses(sendTo);
                        mailforQuote.setReplyTo(UserInfo.getUserEmail());
                        mailforQuote.setSenderDisplayName(UserInfo.getFirstName() + ' ' + UserInfo.getLastName());
                        if(lstCCEmailsToSend.size() > 0){
                            mailforQuote.setCcAddresses(lstCCEmailsToSend);
                        }
                        mailforQuote.setSubject(subjectQuote);
                        htmlBodyForQuote = htmlBodyForQuotee;
                    }
                    if (lstIdTemplateForInfo.size() > 0 && isInfo){
                        mailforInfo.setToAddresses(sendTo);
                        mailforInfo.setReplyTo(UserInfo.getUserEmail());
                        mailforInfo.setSenderDisplayName(UserInfo.getFirstName() + ' ' + UserInfo.getLastName());
                        if(lstCCEmailsToSend.size() > 0){
                            mailforInfo.setCcAddresses(lstCCEmailsToSend);
                        }
                        mailforInfo.setSubject(subjectInfo);
                        htmlBodyForInfo = htmlBodyForInfoo;
                    }
    
                    System.debug('htmlBodyForQuote == ' + htmlBodyForQuote);             
                    System.debug('htmlBodyForInfo == ' + htmlBodyForInfo);
                    
                    String htmlTreatysListReinsurers = '<br/>';
                    String htmlTreatysListReinsurersForQuote = '<br/>';
                    String htmlTreatysListReinsurersForInfo = '<br/>';
    
                    if(btnNameSendUpdateRemind == 'Send' && stageType == 'Quote'){
                        System.debug('lstTreatysListReinsurersForQuote 22 ' + lstTreatysListReinsurersForQuote);
    
                        System.debug('lstTreatysListReinsurersForQuote size ' + lstTreatysListReinsurersForQuote.size());
    
                        if (lstTreatysListReinsurersForQuote.size() > 0){
                            System.debug('OK lstTreatysListReinsurersForQuote ');
                            for(Integer i = 0; i < lstTreatysListReinsurersForQuote.size(); i++){
                                htmlTreatysListReinsurersForQuote += '<li style="text-align: left;">' + lstTreatysListReinsurersForQuote[i] + '</li>';
                            }
                        }
                    
                        System.debug('htmlTreatysListReinsurersForQuote ' + htmlTreatysListReinsurersForQuote);
    
                        if(lstTreatysListReinsurersForInfo.size() > 0){
                            for(Integer i = 0; i < lstTreatysListReinsurersForInfo.size(); i++){
                                htmlTreatysListReinsurersForInfo += '<li style="text-align: left;">' + lstTreatysListReinsurersForInfo[i] + '</li>';
                            }
    
                        }
    
                        System.debug('htmlTreatysListReinsurersForInfo  ' + htmlTreatysListReinsurersForInfo);
    
                        if(htmlBodyForQuote != null && htmlBodyForQuote != ''){
                            if (lstIdTemplateForQuote.size() > 0){
                                if(lstIdTemplateForQuote[0] == emailTempSendQuoteReqBrokerForQuoteId || lstIdTemplateForQuote[0] == emailTempSendQuoteReqReinsurerForQuoteId){
                                    //for quote
                                    System.debug('htmlTreatysListReinsurersForQuote ==  ' + htmlTreatysListReinsurersForQuote);
                                    System.debug('ReinsurerListPageLink reinsurerLinksForQuote ==  ' + reinsurerLinksForQuote);
                                    System.debug('ReinsurerPageLink reinsurerLinksForQuote ==  ' + reinsurerLinksForQuote);
    
                                    //if (htmlTreatysListReinsurersForQuote != '' && reinsurerLinksForQuote != ''){
                                        htmlBodyForQuote = htmlBodyForQuote.replace('{ListTreatySection}', htmlTreatysListReinsurersForQuote);
                                        htmlBodyForQuote = htmlBodyForQuote.replace('{ReinsurerListPageLink}', reinsurerLinksForQuote);
                                        htmlBodyForQuote = htmlBodyForQuote.replace('{ReinsurerPageLink}', reinsurerLinksForQuote);
                                    //}
                                }
                            }
                        }
    
                        if(htmlBodyForInfo != null && htmlBodyForInfo != ''){
                            if (lstIdTemplateForInfo.size() > 0){
                                if(lstIdTemplateForInfo[0] == emailTempSendQuoteReqBrokerForInfoId || lstIdTemplateForInfo[0] == emailTempSendRQuoteReqReinsurerForInfoId){
                                    //for information
                                    System.debug('htmlTreatysListReinsurersForInfo ==  ' + htmlTreatysListReinsurersForInfo);
                                    System.debug('ReinsurerListPageLink reinsurerLinksForInfo ==  ' + reinsurerLinksForInfo);
                                    System.debug('ReinsurerPageLink reinsurerLinksForInfo ==  ' + reinsurerLinksForInfo);
                                    
                                    //if (htmlTreatysListReinsurersForInfo != '' && reinsurerLinksForInfo != ''){
                                        htmlBodyForInfo = htmlBodyForInfo.replace('{ListTreatySection}', htmlTreatysListReinsurersForInfo);
                                        htmlBodyForInfo = htmlBodyForInfo.replace('{ReinsurerListPageLink}', reinsurerLinksForInfo);
                                        htmlBodyForInfo = htmlBodyForInfo.replace('{ReinsurerPageLink}', reinsurerLinksForInfo);
                                    //}
                                }
                            }
                        }
                    }
    
                        if(btnNameSendUpdateRemind == 'Update' && stageType == 'Quote'){
                            for(Integer i = 0; i < lstTreatysListReinsurersForQuote.size(); i++){
                                htmlTreatysListReinsurersForQuote += '<li style="text-align: left;">' + lstTreatysListReinsurersForQuote[i] + '</li>';
                            }
    
                            for(Integer i = 0; i < lstTreatysListReinsurersForInfo.size(); i++){
                                htmlTreatysListReinsurersForInfo += '<li style="text-align: left;">' + lstTreatysListReinsurersForInfo[i] + '</li>';
                            }
    
                            if(htmlBodyForQuote != null && htmlBodyForQuote != ''){
                                htmlBodyForQuote = htmlBodyForQuote.replace('{ListTreatySection}', htmlTreatysListReinsurersForInfo);
                                htmlBodyForQuote = htmlBodyForQuote.replace('{ReinsurerListPageLink}', reinsurerLinks);
                                htmlBodyForQuote = htmlBodyForQuote.replace('{ReinsurerPageLink}', reinsurerLinksForInfo);
                            }
    
                            if(htmlBodyForInfo != null && htmlBodyForInfo != ''){
                                htmlBodyForInfo = htmlBodyForInfo.replace('{ListTreatySection}', htmlTreatysListReinsurersForInfo);
                                htmlBodyForInfo = htmlBodyForInfo.replace('{ReinsurerListPageLink}', reinsurerLinks);
                                htmlBodyForInfo = htmlBodyForInfo.replace('{ReinsurerPageLink}', reinsurerLinksForInfo);
                            }
    
                        }
                        else{
                            for(Integer i = 0; i < lstTreatysListReinsurers.size(); i++){
                                htmlTreatysListReinsurers += '<li style="text-align: left;">' + lstTreatysListReinsurers[i] + '</li>';
                            }
    
                            if(htmlBodyForQuote != null && htmlBodyForQuote != ''){
                                htmlBodyForQuote = htmlBodyForQuote.replace('{ListTreatySection}', htmlTreatysListReinsurers);
                                htmlBodyForQuote = htmlBodyForQuote.replace('{ReinsurerListPageLink}', reinsurerLinks);
                                htmlBodyForQuote = htmlBodyForQuote.replace('{ReinsurerPageLink}', reinsurerLinks);
                            }
    
                            if(htmlBodyForInfo != null && htmlBodyForInfo != ''){
                                htmlBodyForInfo = htmlBodyForInfo.replace('{ListTreatySection}', htmlTreatysListReinsurers);
                                htmlBodyForInfo = htmlBodyForInfo.replace('{ReinsurerListPageLink}', reinsurerLinks);
                                htmlBodyForInfo = htmlBodyForInfo.replace('{ReinsurerPageLink}', reinsurerLinks);
                            } 
                        }
    
                        if(htmlBodyForQuote != null && htmlBodyForQuote != ''){
                            System.debug('RhtmlTreatysListReinsurers ==  ' + htmlTreatysListReinsurers);
    
                            htmlBodyForQuote = htmlBodyForQuote.replace('{ListTreatysListReinsurers}', htmlTreatysListReinsurers);
                            htmlBodyForQuote = htmlBodyForQuote.replace('{ProgramName}', programName);
                            htmlBodyForQuote = htmlBodyForQuote.replace('{CedingCompanyName}', cedingCompanyName);
                            htmlBodyForQuote = htmlBodyForQuote.replace('{phase}', stageType);
                            System.debug('stageType ==  ' + stageType);
                            
    
                            if(requestCommentExpectedAnsDate.ExpectedResponseDate__c != null){
                                htmlBodyForQuote = htmlBodyForQuote.replace('{ExpectedResponseDate}', String.valueOf(requestCommentExpectedAnsDate.ExpectedResponseDate__c));
                            }
    
                            String strComments = requestCommentExpectedAnsDate.Comments__c != null ? requestCommentExpectedAnsDate.Comments__c : '';
                            String commentStrDesigned = '<b style="color:blue";><font face="Arial" size="50px">' + strComments + '</font></b>'; //RRA - ticket 1382 - 16122022
                            htmlBodyForQuote = htmlBodyForQuote.replace('{Comments}', commentStrDesigned); //RRA - ticket 1382 - 16122022
    
                            String strLstCCEmailDisplayInEmails = strLstCCEmailDisplay != null ? strLstCCEmailDisplay : '';
                            htmlBodyForQuote = htmlBodyForQuote.replace('{emailP_C_LIFE}', strLstCCEmailDisplayInEmails);
                        }
    
                        if(htmlBodyForInfo != null && htmlBodyForInfo != ''){
                            System.debug('RhtmlTreatysListReinsurers ==  ' + htmlTreatysListReinsurers);
    
                            htmlBodyForInfo = htmlBodyForInfo.replace('{ListTreatysListReinsurers}', htmlTreatysListReinsurers);
                            htmlBodyForInfo = htmlBodyForInfo.replace('{ProgramName}', programName);
                            htmlBodyForInfo = htmlBodyForInfo.replace('{CedingCompanyName}', cedingCompanyName);
                            htmlBodyForInfo = htmlBodyForInfo.replace('{phase}', stageType);
                            System.debug('stageType ==  ' + stageType);
                            
    
                            if(requestCommentExpectedAnsDate.ExpectedResponseDate__c != null){
                                htmlBodyForInfo = htmlBodyForInfo.replace('{ExpectedResponseDate}', String.valueOf(requestCommentExpectedAnsDate.ExpectedResponseDate__c));
                            }
    
                            String strComments = requestCommentExpectedAnsDate.Comments__c != null ? requestCommentExpectedAnsDate.Comments__c : '';
                            String commentStrDesigned = '<b style="color:blue";><font face="Arial" size="50px">' + strComments + '</font></b>'; //RRA - ticket 1382 - 16122022
                            htmlBodyForInfo = htmlBodyForInfo.replace('{Comments}', commentStrDesigned); //RRA - ticket 1677 - 12102023
                            String strLstCCEmailDisplayInEmails = strLstCCEmailDisplay != null ? strLstCCEmailDisplay : '';
                            htmlBodyForInfo = htmlBodyForInfo.replace('{emailP_C_LIFE}', strLstCCEmailDisplayInEmails);
                        }
    
                        String htmlLstDocument = '';
                        Boolean containNewContractualDoc = false;
                        Boolean containNewRenewDoc = false;
                        Set<Id> setAllDocContentVersion = new Set<Id>();
    
                        if(lstContractDoc.size() > 0){
                            for(ContentVersion contentVersion : lstContractDoc){
                                Set<String> setBrokReinByContentVersionIdContract = new Set<String>();
                                if(mapListOfCompanyByContentVersionId.containsKey(contentVersion.Id)){
                                    setBrokReinByContentVersionIdContract = mapListOfCompanyByContentVersionId.get(contentVersion.Id);
                                }
    
                                for(String brokerReinDoc : setBrokReinByContentVersionIdContract){
                                    if(setBrokerReinsurerReq.contains(brokerReinDoc)){
                                        if(containNewContractualDoc == false){
                                            containNewContractualDoc = true;
                                            htmlLstDocument = '<h4 style="text-align: left;">Contractual Document</h4>';
                                        }   
                                        if(!setAllDocContentVersion.contains(contentVersion.Id)){
                                            setAllDocContentVersion.add(contentVersion.Id);
                                            htmlLstDocument += '<li style="text-align: left;">' + contentVersion.Title + '</li>';
                                        }
                                    }
                                }
                            }
                        }
    
                        if(lstRenewDoc.size() > 0){
                            for(ContentVersion contentVersion : lstRenewDoc){
                                Set<String> setBrokReinByContentVersionIdRenew = new Set<String>();
                                if(mapListOfCompanyByContentVersionId.containsKey(contentVersion.Id)){
                                    setBrokReinByContentVersionIdRenew = mapListOfCompanyByContentVersionId.get(contentVersion.Id);
                                }
    
                                for(String brokerReinDoc : setBrokReinByContentVersionIdRenew){
                                    if(setBrokerReinsurerReq.contains(brokerReinDoc)){
                                        if(containNewRenewDoc == false){
                                            containNewRenewDoc = true;
                                            htmlLstDocument += '<h4 style="text-align: left;">Renewal Document</h4>';
                                        }   
    
                                        if(!setAllDocContentVersion.contains(contentVersion.Id)){
                                            setAllDocContentVersion.add(contentVersion.Id);
                                            htmlLstDocument += '<li style="text-align: left;">' + contentVersion.Title + '</li>';
                                        }  
                                    }
                                }
                            }
                        }
    
                        if(htmlBodyForQuote != null && htmlBodyForQuote != ''){
                            if(containNewContractualDoc == true || containNewRenewDoc == true){
                                htmlBodyForQuote = htmlBodyForQuote.replace('{ListOfDocuments}', htmlLstDocument);
                            }
                            else{
                                htmlBodyForQuote = htmlBodyForQuote.replace('{ListOfDocuments}', '');
                            }
    
                            String htmlInternetLink = '<a href="' + urlArr[0] + 'homepage">ACTOR New Gen HomePage</a>';
                            htmlBodyForQuote = htmlBodyForQuote.replace('{InternetLink}', htmlInternetLink);
                        }
    
                        if(htmlBodyForInfo != null && htmlBodyForInfo != ''){
                            if(containNewContractualDoc == true || containNewRenewDoc == true){
                                htmlBodyForInfo = htmlBodyForInfo.replace('{ListOfDocuments}', htmlLstDocument);
                            }
                            else{
                                htmlBodyForInfo = htmlBodyForInfo.replace('{ListOfDocuments}', '');
                            }
    
                            String htmlInternetLink = '<a href="' + urlArr[0] + 'homepage">ACTOR New Gen HomePage</a>';
                            htmlBodyForInfo = htmlBodyForInfo.replace('{InternetLink}', htmlInternetLink);
                        }
    
                        mailforQuote.setHtmlBody(htmlBodyForQuote);
                        mailforInfo.setHtmlBody(htmlBodyForInfo);
                        if(btnNameSendUpdateRemind == 'Send' && stageType == 'Signing'){
                            if(lstTreatysListReinsurers.size() > 0){
                                lstMailsForQuote.add(mailforQuote);
                                lstMailsForInfo.add(mailforInfo);
                            }
                        }
                        else {
                            lstMailsForQuote.add(mailforQuote);
                            lstMailsForInfo.add(mailforInfo);
                        }
    
    
    
                        // FOR SIGNING - PLACEMENT AND UPDATE QUOTE : // RRA - 1311 TP - Mail au courtier manquant pour les "For Quote" 11/102022
                        //*********************************** */
                        if (lstEmailMessage.size() > 0){
                            for(Messaging.SingleEmailMessage emailMessage : lstEmailMessage){
                                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                                List<String> sendToo = new List<String>();
                                sendToo.add(accountContact.Contact.Email);
                                mail.setToAddresses(sendToo);
                                mail.setReplyTo(UserInfo.getUserEmail());
                                mail.setSenderDisplayName(UserInfo.getFirstName() + ' ' + UserInfo.getLastName());
            
                                if(lstCCEmailsToSend.size() > 0){
                                    mail.setCcAddresses(lstCCEmailsToSend);
                                }
            
                                mail.setSubject(emailMessage.getSubject());
                                String htmlBody = emailMessage.htmlBody;
                                String htmlTreatysListReinsurersx = '<br/>';
                                String htmlTreatysListReinsurersForQuotex = '<br/>';
                                String htmlTreatysListReinsurersForInfox = '<br/>';
            
                                if(btnNameSendUpdateRemind == 'Update' && stageType == 'Quote'){
                                    for(Integer i = 0; i < lstTreatysListReinsurersForQuote.size(); i++){
                                        htmlTreatysListReinsurersForQuotex += '<li style="text-align: left;">' + lstTreatysListReinsurersForQuote[i] + '</li>';
                                    }
            
                                    for(Integer i = 0; i < lstTreatysListReinsurersForInfo.size(); i++){
                                        htmlTreatysListReinsurersForInfox += '<li style="text-align: left;">' + lstTreatysListReinsurersForInfo[i] + '</li>';
                                    }
            
                                    if(htmlBody != null && htmlBody != ''){
                                        htmlBody = htmlBody.replace('{ListTreatySection}', htmlTreatysListReinsurersForInfox);
                                        htmlBody = htmlBody.replace('{ReinsurerListPageLink}', reinsurerLinks);
                                        htmlBody = htmlBody.replace('{ReinsurerPageLink}', reinsurerLinksForInfo);
                                    }
                                }
                                else{
                                    for(Integer i = 0; i < lstTreatysListReinsurers.size(); i++){
                                        htmlTreatysListReinsurersx += '<li style="text-align: left;">' + lstTreatysListReinsurers[i] + '</li>';
                                    }
            
                                    if(htmlBody != null && htmlBody != ''){
                                        htmlBody = htmlBody.replace('{ListTreatySection}', htmlTreatysListReinsurersx);
                                        htmlBody = htmlBody.replace('{ReinsurerListPageLink}', reinsurerLinks);
                                        htmlBody = htmlBody.replace('{ReinsurerPageLink}', reinsurerLinks);
                                    }  
                                }
            
                                if(htmlBody != null && htmlBody != ''){
                                    htmlBody = htmlBody.replace('{ListTreatysListReinsurers}', htmlTreatysListReinsurersx);
                                    htmlBody = htmlBody.replace('{ProgramName}', programName);
                                    htmlBody = htmlBody.replace('{CedingCompanyName}', cedingCompanyName);
                                    htmlBody = htmlBody.replace('{phase}', stageType);
            
                                    if(requestCommentExpectedAnsDate.ExpectedResponseDate__c != null){
                                        htmlBody = htmlBody.replace('{ExpectedResponseDate}', String.valueOf(requestCommentExpectedAnsDate.ExpectedResponseDate__c));
                                    }
            
                                    String strCommentsx = requestCommentExpectedAnsDate.Comments__c != null ? requestCommentExpectedAnsDate.Comments__c : '';
                                    String commentStrDesigned = '<b style="color:blue";><font face="Arial" size="50px">' + strCommentsx + '</font></b>'; //RRA - ticket 1382 - 16122022
                                    htmlBody = htmlBody.replace('{Comments}', commentStrDesigned);//RRA - ticket 1382 - 16122022
            
                                    String strLstCCEmailDisplayInEmailsx = strLstCCEmailDisplay != null ? strLstCCEmailDisplay : '';
                                    htmlBody = htmlBody.replace('{emailP_C_LIFE}', strLstCCEmailDisplayInEmailsx);
                                }
            
                                String htmlLstDocumentx = '';
                                Boolean containNewContractualDocx = false;
                                Boolean containNewRenewDocx = false;
                                Set<Id> setAllDocContentVersionx= new Set<Id>();
            
                                if(lstContractDoc.size() > 0){
                                    for(ContentVersion contentVersion : lstContractDoc){
                                        Set<String> setBrokReinByContentVersionIdContract = new Set<String>();
                                        if(mapListOfCompanyByContentVersionId.containsKey(contentVersion.Id)){
                                            setBrokReinByContentVersionIdContract = mapListOfCompanyByContentVersionId.get(contentVersion.Id);
                                        }
            
                                        for(String brokerReinDoc : setBrokReinByContentVersionIdContract){
                                            if(setBrokerReinsurerReq.contains(brokerReinDoc)){
                                                if(containNewContractualDocx == false){
                                                    containNewContractualDocx = true;
                                                    htmlLstDocumentx = '<h4 style="text-align: left;">Contractual Document</h4>';
                                                }   
                                                if(!setAllDocContentVersionx.contains(contentVersion.Id)){
                                                    setAllDocContentVersionx.add(contentVersion.Id);
                                                    htmlLstDocumentx += '<li style="text-align: left;">' + contentVersion.Title + '</li>';
                                                }
                                            }
                                        }
                                    }
                                }
            
                                if(lstRenewDoc.size() > 0){
                                    for(ContentVersion contentVersion : lstRenewDoc){
                                        Set<String> setBrokReinByContentVersionIdRenew = new Set<String>();
                                        if(mapListOfCompanyByContentVersionId.containsKey(contentVersion.Id)){
                                            setBrokReinByContentVersionIdRenew = mapListOfCompanyByContentVersionId.get(contentVersion.Id);
                                        }
            
                                        for(String brokerReinDoc : setBrokReinByContentVersionIdRenew){
                                            if(setBrokerReinsurerReq.contains(brokerReinDoc)){
                                                if(containNewRenewDocx == false){
                                                    containNewRenewDocx = true;
                                                    htmlLstDocumentx += '<h4 style="text-align: left;">Renewal Document</h4>';
                                                }   
            
                                                if(!setAllDocContentVersionx.contains(contentVersion.Id)){
                                                    setAllDocContentVersionx.add(contentVersion.Id);
                                                    htmlLstDocumentx += '<li style="text-align: left;">' + contentVersion.Title + '</li>';
                                                }  
                                            }
                                        }
                                    }
                                }
            
                                if(htmlBody != null && htmlBody != ''){
                                    if(containNewContractualDocx == true || containNewRenewDocx == true){
                                        htmlBody = htmlBody.replace('{ListOfDocuments}', htmlLstDocumentx);
                                    }
                                    else{
                                        htmlBody = htmlBody.replace('{ListOfDocuments}', '');
                                    }
            
                                    String htmlInternetLinkx = '<a href="' + urlArr[0] + 'homepage">ACTOR New Gen HomePage</a>';
                                    htmlBody = htmlBody.replace('{InternetLink}', htmlInternetLinkx);
                                }
            
                                mail.setHtmlBody(htmlBody);
            
                                if(btnNameSendUpdateRemind == 'Send' && stageType == 'Signing'){
                                    if(lstTreatysListReinsurers.size() > 0){
                                        lstMails.add(mail);
                                    }
                                }
                                else {
                                    lstMails.add(mail);
                                }
                            }
                        }
                        
                    //}
                }
            }
            System.debug('lstMails ==  ' + lstMails);
    
            //System.debug('lstMailsForQuote ==  ' + lstMailsForQuote);
            //System.debug('lstMailsForQuote[0].getToAddresses() ==  ' + lstMailsForQuote[0].getToAddresses());
            //System.debug('lstMailsForInfo ==  ' + lstMailsForInfo);
            //System.debug('lstMailsForInfo[0].getToAddresses() ==  ' + lstMailsForInfo[0].getToAddresses());
    
            List<Messaging.SingleEmailMessage> lstMailElligibleQuote = new List<Messaging.SingleEmailMessage>();
            List<Messaging.SingleEmailMessage> lstMailElligibleInfo = new List<Messaging.SingleEmailMessage>();
    
            for (Messaging.SingleEmailMessage mailQuote : lstMailsForQuote){
                if (mailQuote.getToAddresses() !=null){
                    lstMailElligibleQuote.add(mailQuote);
                }
            }
    
            for (Messaging.SingleEmailMessage mailInfo : lstMailsForInfo){
                if (mailInfo.getToAddresses() !=null){
                    lstMailElligibleInfo.add(mailInfo);
                }
            }
    
            if(lstMailElligibleQuote.size() > 0 ){ //&& lstMailsForQuote[0].getHtmlBody() !=null && lstMailsForQuote[0].getToAddresses()!=null
                Messaging.sendEmail((List<Messaging.Email>) lstMailElligibleQuote);
            }
    
            if(lstMailElligibleInfo.size() > 0 ){ //
                Messaging.sendEmail((List<Messaging.Email>) lstMailElligibleInfo);
            }
    
            if(lstMails.size() > 0){
                Messaging.sendEmail((List<Messaging.Email>) lstMails);
            }
        }
    }