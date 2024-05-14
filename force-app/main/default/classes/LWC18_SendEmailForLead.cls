public with sharing class LWC18_SendEmailForLead implements Queueable{
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Controller for Lightning Web Component lwc18SendUpdateRemind - Queueable class to send email for Lead
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 05-NOV-2021  MBE   1.0      Initial version
--------------------------------------------------------------------------------------
**************************************************************************************/

    public List<Request__c> lstLeadRequestParent;
    public List<AccountContactRelation> lstAccountContact;
    public String programId;
    public String btnNameSendUpdateRemind;
    public List<String> lstCCEmailsToSend;
    public String strLstCCEmailDisplay;
    public List<ContentVersion> lstContractDoc;
    public List<ContentVersion> lstRenewDoc;
    public Map<Id, Set<String>> mapListOfCompanyByContentVersionId;
    public String programName;
    public String cedingCompanyName;
    public Date expectedAnsDate;
    public String comment;

    public LWC18_SendEmailForLead(List<Request__c> lstLeadRequestParent, List<AccountContactRelation> lstAccountContact, String programId, String btnNameSendUpdateRemind
    , List<String> lstCCEmailsToSend, String strLstCCEmailDisplay, List<ContentVersion> lstContractDoc, List<ContentVersion> lstRenewDoc, Map<Id, Set<String>> mapListOfCompanyByContentVersionId
    , String programName, String cedingCompanyName, Date expectedAnsDate, String comment){

        this.lstLeadRequestParent = lstLeadRequestParent; 
        this.lstAccountContact = lstAccountContact;  
        this.programId = programId;  
        this.btnNameSendUpdateRemind = btnNameSendUpdateRemind;  
        this.lstCCEmailsToSend = lstCCEmailsToSend;  
        this.strLstCCEmailDisplay = strLstCCEmailDisplay;  
        this.lstContractDoc = lstContractDoc;  
        this.lstRenewDoc = lstRenewDoc;  
        this.mapListOfCompanyByContentVersionId = mapListOfCompanyByContentVersionId;  
        this.programName = programName; 
        this.cedingCompanyName = cedingCompanyName;  
        this.expectedAnsDate = expectedAnsDate;  
        this.comment = comment;  
    }

    public void execute(QueueableContext context) {
        Id emailTemplateUpdateId;
        List<String> lstEmailTemplateName = new List<String>();
        Id emailTempRetainedBrokerId;
        Id emailTempRetainedReinsurerId;
        Id emailTempNonRetainedBrokerId;
        Id emailTempNonRetainedReinsurerId;

        lstEmailTemplateName.add(AP_Constant.emailTemplateSendRetainedBroker);
        lstEmailTemplateName.add(AP_Constant.emailTemplateSendRetainedReinsurer);
        lstEmailTemplateName.add(AP_Constant.emailTemplateSendNonRetainedBroker);
        lstEmailTemplateName.add(AP_Constant.emailTemplateSendNonRetainedReinsurer);
        lstEmailTemplateName.add(AP_Constant.emailTemplateUpdateReq);

        List<EmailTemplate> lstEmailTemplate = [SELECT Id, Name FROM EmailTemplate WHERE Name IN : lstEmailTemplateName];

        for(EmailTemplate emailTemplate : lstEmailTemplate){
            if(emailTemplate.Name == AP_Constant.emailTemplateSendRetainedBroker){
                emailTempRetainedBrokerId = emailTemplate.Id;
            }
            else if(emailTemplate.Name == AP_Constant.emailTemplateSendRetainedReinsurer){
                emailTempRetainedReinsurerId = emailTemplate.Id;
            }
            else if(emailTemplate.Name == AP_Constant.emailTemplateSendNonRetainedBroker){
                emailTempNonRetainedBrokerId = emailTemplate.Id;
            }
            else if(emailTemplate.Name == AP_Constant.emailTemplateSendNonRetainedReinsurer){
                emailTempNonRetainedReinsurerId = emailTemplate.Id;
            }
            else if(emailTemplate.Name == AP_Constant.emailTemplateUpdateReq){
                emailTemplateUpdateId = emailTemplate.Id;
            }
        }

        Network networkObj = [SELECT Id FROM Network WHERE Name =: System.Label.Actor_portal_name];

        String url = Network.getLoginUrl(networkObj.Id);
        String userId = UserInfo.getUserId();

        List<String> urlArr = url.split('login');
        String htmlInternetLink = '<a href="' + urlArr[0] + 'homepage">ACTOR New Gen HomePage</a>';

        Messaging.SingleEmailMessage mRetainedBroker = new Messaging.SingleEmailMessage();       
        mRetainedBroker = Messaging.renderStoredEmailTemplate(emailTempRetainedBrokerId, userId, lstLeadRequestParent[0].Id);

        Messaging.SingleEmailMessage mRetainedReinsurer = new Messaging.SingleEmailMessage();       
        mRetainedReinsurer = Messaging.renderStoredEmailTemplate(emailTempRetainedReinsurerId, userId, lstLeadRequestParent[0].Id);

        Messaging.SingleEmailMessage mNonRetainedBroker = new Messaging.SingleEmailMessage();       
        mNonRetainedBroker = Messaging.renderStoredEmailTemplate(emailTempNonRetainedBrokerId, userId, lstLeadRequestParent[0].Id);

        Messaging.SingleEmailMessage mNonRetainedReinsurer = new Messaging.SingleEmailMessage();       
        mNonRetainedReinsurer = Messaging.renderStoredEmailTemplate(emailTempNonRetainedReinsurerId, userId, lstLeadRequestParent[0].Id);

        Messaging.SingleEmailMessage mUpdateReq = new Messaging.SingleEmailMessage();       
        mUpdateReq = Messaging.renderStoredEmailTemplate(emailTemplateUpdateId, userId, lstLeadRequestParent[0].Id);

        Map<Id, List<Request__c>> mapLstParentLeadRequestByAccID = new Map<Id, List<Request__c>>();
        Map<Id, List<AccountContactRelation>> mapLstAccountContactByAccID = new Map<Id, List<AccountContactRelation>>();
        List<Messaging.SingleEmailMessage> lstMails =  new List<Messaging.SingleEmailMessage>();
        Set<Id> setTreatys = new Set<Id>();
        Set<Id> setParentLeadReq = new Set<Id>();

        for(Request__c request : lstLeadRequestParent){
            List<Request__c> lstUpdRequest = new List<Request__c>();
            setTreatys.add(request.Treaty__c);
            setParentLeadReq.add(request.Id);
            if(request.Broker__c != null){
                if(mapLstParentLeadRequestByAccID.containsKey(request.Broker__c)){
                    lstUpdRequest = mapLstParentLeadRequestByAccID.get(request.Broker__c);
                    lstUpdRequest.add(request);
                    mapLstParentLeadRequestByAccID.put(request.Broker__c, lstUpdRequest);
                }
                else{
                    lstUpdRequest.add(request);
                    mapLstParentLeadRequestByAccID.put(request.Broker__c, lstUpdRequest);
                }
            }
            else{
                if(mapLstParentLeadRequestByAccID.containsKey(request.Reinsurer__c)){
                    lstUpdRequest = mapLstParentLeadRequestByAccID.get(request.Reinsurer__c);
                    lstUpdRequest.add(request);
                    mapLstParentLeadRequestByAccID.put(request.Reinsurer__c, lstUpdRequest);
                }
                else{
                    lstUpdRequest.add(request);
                    mapLstParentLeadRequestByAccID.put(request.Reinsurer__c, lstUpdRequest);
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

        Map<Id, List<Request__c>> mapAccountIdToListRequests = new Map <Id, List<Request__c>>();
        Map<Id, List<String>> mapAccIdToTreatySectionList = new Map <Id, List<String>>();
        List<String> lstQuoteRecordType = AP_Constant.reqRTQuote.split('-');
        List<String> lstLeadRecordType = AP_Constant.reqRTLead.split('-');

        List<Request__c> lstQuoteRequests = [SELECT ReinsurerStatus__c
                                                    ,Broker__c
                                                    ,Reinsurer__c
                                                    ,TECH_TreatyName__c
                                                    ,TECH_ReinsurerName__c
                                                    ,TECH_SectionName__c
                                                    ,OriginalRequest__c
                                                    ,LastVersionSent__c
                                                    ,LastVersionAnswered__c
                                              FROM Request__c
                                              WHERE (Broker__c IN: mapLstAccountContactByAccID.keySet()
                                              OR Reinsurer__c IN: mapLstAccountContactByAccID.keySet())
                                              AND Program__c =: programId
                                              AND ((ReinsurerStatus__c = :AP_Constant.statusSetup) OR (LastVersionSent__c = TRUE AND LastVersionAnswered__c = TRUE))
                                              AND RecordType.DeveloperName =: lstQuoteRecordType[1]];

        //create a map - parent lead request id, list of child lead request
        Map<Id, List<Request__c>> mapLstChildReqByParentLeadReq = new Map<Id, List<Request__c>>();

        if(setParentLeadReq.size() > 0){
            for(LeadRequestSelection__c leadReqSelection : [SELECT Id, LeadRequestParent__c, LeadRequestChild__r.TECH_TreatyName__c, LeadRequestChild__r.TECH_SectionName__c
                                                            FROM LeadRequestSelection__c
                                                            WHERE LeadRequestParent__c IN :setParentLeadReq]){
                List<Request__c> lstChildRequest = new List<Request__c>();

                if(mapLstChildReqByParentLeadReq.containsKey(leadReqSelection.LeadRequestParent__c)){
                    lstChildRequest = mapLstChildReqByParentLeadReq.get(leadReqSelection.LeadRequestParent__c);
                }

                lstChildRequest.add(leadReqSelection.LeadRequestChild__r);
                mapLstChildReqByParentLeadReq.put(leadReqSelection.LeadRequestParent__c, lstChildRequest);
            }
        }

        if(lstLeadRequestParent.size() > 0) {
            for (Request__c request : lstLeadRequestParent) {
                //MBE : 27/01/2021
                //Get corresponding child request of parent lead request
                String treatysListReinsurers = '';
                List<Request__c> lstChildLeadRequest = new List<Request__c>();

                if(mapLstChildReqByParentLeadReq.containsKey(request.Id)){
                    lstChildLeadRequest = mapLstChildReqByParentLeadReq.get(request.Id);
                }

                for(Request__c childReq : lstChildLeadRequest){
                // treatysListReinsurers = childReq.TECH_TreatyName__c + ' / ' + childReq.TECH_SectionName__c + ' : ' + request.TECH_ReinsurerName__c;
                    treatysListReinsurers = childReq.TECH_TreatyName__c + ' : ' + request.TECH_ReinsurerName__c;
                }

                if(request.Broker__c != null){
                    if(mapAccountIdToListRequests.containsKey(request.Broker__c)){
                        List<Request__c> lstReqs = mapAccountIdToListRequests.get(request.Broker__c);
                        lstReqs.add(request);
                        mapAccountIdToListRequests.put(request.Broker__c, lstReqs);
                    }
                    else{
                        List<Request__c> lstReqs = new List <Request__c>();
                        lstReqs.add(request);
                        mapAccountIdToListRequests.put(request.Broker__c, lstReqs);
                    }

                    if(mapAccIdToTreatySectionList.containsKey(request.Broker__c)){
                        List<String> lstValues = mapAccIdToTreatySectionList.get(request.Broker__c);
                        lstValues.add(treatysListReinsurers);
                        mapAccIdToTreatySectionList.put(request.Broker__c, lstValues);
                    }
                    else{
                        List<String> lstValues = new List<String>();
                        lstValues.add(treatysListReinsurers);
                        mapAccIdToTreatySectionList.put(request.Broker__c, lstValues);
                    }
                }
                else{
                    if(mapAccountIdToListRequests.containsKey(request.Reinsurer__c)){
                        List<Request__c> lstReqs = mapAccountIdToListRequests.get(request.Reinsurer__c);
                        lstReqs.add(request);
                        mapAccountIdToListRequests.put(request.Reinsurer__c, lstReqs);
                    }
                    else{
                        List<Request__c> lstReqs = new List <Request__c>();
                        lstReqs.add(request);
                        mapAccountIdToListRequests.put(request.Reinsurer__c, lstReqs);
                    }

                    if(mapAccIdToTreatySectionList.containsKey(request.Reinsurer__c)){
                        List<String> lstValues = mapAccIdToTreatySectionList.get(request.Reinsurer__c);
                        lstValues.add(treatysListReinsurers);
                        mapAccIdToTreatySectionList.put(request.Reinsurer__c, lstValues);
                    }
                    else{
                        List<String> lstValues = new List<String>();
                        lstValues.add(treatysListReinsurers);
                        mapAccIdToTreatySectionList.put(request.Reinsurer__c, lstValues);
                    }
                }
            }
        }

        List<Id> lstContactSent = new List<Id>();
        List<Id> lstContactSentQuote = new List<Id>();
        Map<Id, Set<String>> mapRetained = new Map<Id, Set<String>>();

        for(Id accountId : mapLstAccountContactByAccID.keySet()){
            List<AccountContactRelation> lstAccountContactByAccId = mapLstAccountContactByAccID.get(accountId); //  here
            for(AccountContactRelation accountContact : lstAccountContactByAccId){
                List<Id> lstChildLeadRequestId = new List<Id>();
                Boolean test = mapLstParentLeadRequestByAccID.containsKey(accountContact.AccountId);
                List<Request__c> lstParentLeadRequestByAccId = mapLstParentLeadRequestByAccID.get(accountContact.AccountId);
                String reinsurerLinks = '';
                Set<String> setBrokerReinsurerReq = new Set<String>();

                for(Request__c request : lstParentLeadRequestByAccId){
                    if(request.Broker__c == null){
                        setBrokerReinsurerReq.add('undefined-' + request.Reinsurer__c);
                    }
                    else{
                        setBrokerReinsurerReq.add(request.Broker__c + '-' + request.Reinsurer__c);
                    }
                }

                for(Request__c parentRequest : lstParentLeadRequestByAccId){
                    Messaging.SingleEmailMessage m = new Messaging.SingleEmailMessage();
                    Id parentRequestId = parentRequest.Id;

                    if(btnNameSendUpdateRemind == 'Send'){
                        if(accountContact.Contact.AccountType__c == AP_Constant.contactBroker) {
                            m.setTemplateId(emailTempRetainedBrokerId);
                            m.setTargetObjectId(userId);
                            m.setWhatId(parentRequestId);
                            m.setSaveAsActivity(false);

                            if(mapRetained.containsKey(parentRequest.Treaty__c)){
                                String br = parentRequest.Broker__c + '-' + parentRequest.Reinsurer__c;
                                mapRetained.get(parentRequest.Treaty__c).add(br);
                            }
                            else{
                                String br = parentRequest.Broker__c + '-' + parentRequest.Reinsurer__c;
                                mapRetained.put(parentRequest.Treaty__c, new Set<String>{br});
                            }
                        }
                        else if(accountContact.Contact.AccountType__c == AP_Constant.contactReinsurer) {
                            m.setTemplateId(emailTempRetainedReinsurerId);
                            m.setTargetObjectId(userId);
                            m.setWhatId(parentRequestId);
                            m.setSaveAsActivity(false);

                            if(mapRetained.containsKey(parentRequest.Treaty__c)){
                                String br = 'NoBroker-' + parentRequest.Reinsurer__c;
                                mapRetained.get(parentRequest.Treaty__c).add(br);
                            }
                            else{
                                String br = 'NoBroker-' + parentRequest.Reinsurer__c;
                                mapRetained.put(parentRequest.Treaty__c, new Set<String>{br});
                            }
                        }
                    }
                    else if(btnNameSendUpdateRemind == 'Update'){
                        m.setTemplateId(emailTemplateUpdateId);
                        m.setTargetObjectId(userId);
                        m.setWhatId(parentRequestId);
                        m.setSaveAsActivity(false);
                    }

                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    List<String> sendTo = new List<String>();
                    String htmlBody = '';

                    sendTo.add(accountContact.Contact.Email);
                    mail.setToAddresses(sendTo);
                    mail.setReplyTo(UserInfo.getUserEmail());
                    mail.setSenderDisplayName(UserInfo.getFirstName() + ' ' + UserInfo.getLastName());

                    if(lstCCEmailsToSend.size() > 0){
                        mail.setCcAddresses(lstCCEmailsToSend);
                    }

                    if(btnNameSendUpdateRemind == 'Send'){
                        if(accountContact.Contact.AccountType__c == AP_Constant.contactBroker) {
                            mail.setSubject(mRetainedBroker.getSubject());
                            htmlBody = mRetainedBroker.htmlBody;      
                        }
                        else if(accountContact.Contact.AccountType__c == AP_Constant.contactReinsurer) {
                            mail.setSubject(mRetainedReinsurer.getSubject());
                            htmlBody = mRetainedReinsurer.htmlBody;
                        }
                    }
                    else if(btnNameSendUpdateRemind == 'Update'){
                        mail.setSubject(mUpdateReq.getSubject());
                        htmlBody = mUpdateReq.htmlBody;
                    }

                    String strLstCCEmailDisplayss = strLstCCEmailDisplay != null ? strLstCCEmailDisplay : '';
                    
                    if(htmlBody != null && htmlBody != ''){
                        htmlBody = htmlBody.replace('{emailP_C_LIFE}', strLstCCEmailDisplayss);
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
                            Set<String> setBrokReinByContentVersionIdContract = new Set<String>();
                            if(mapListOfCompanyByContentVersionId.containsKey(contentVersion.Id)){
                                setBrokReinByContentVersionIdContract = mapListOfCompanyByContentVersionId.get(contentVersion.Id);
                            }

                            for(String brokerReinDoc : setBrokReinByContentVersionIdContract){
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

                    if(htmlBody != null && htmlBody != ''){
                        if(containNewContractualDoc == true || containNewRenewDoc == true){
                            htmlBody = htmlBody.replace('{ListOfDocuments}', htmlLstDocument);
                        }else{
                            htmlBody = htmlBody.replace('{ListOfDocuments}', '');
                        }
                    }
                    
                    if(mapAccIdToTreatySectionList.containsKey(accountContact.AccountId)){
                        String listTreatySection = '';

                        for(String value : mapAccIdToTreatySectionList.get(accountContact.AccountId)){
                            listTreatySection += '<li style="text-align: left;">' + value + '</li>';
                        }

                        if(htmlBody != null && htmlBody != ''){
                            htmlBody = htmlBody.replace('{ListTreatySection}', listTreatySection);
                            htmlBody = htmlBody.replace('{ListTreatysListReinsurers}', listTreatySection);
                        } 
                    }
                    else{
                        if(htmlBody != null && htmlBody != ''){
                            htmlBody = htmlBody.replace('{ListTreatySection}', '');
                            htmlBody = htmlBody.replace('{ListTreatysListReinsurers}', '');
                        } 
                    }

                    List <String> urlArr2 = url.split('login');
    
                    for(Request__c parentLeadRequest : lstParentLeadRequestByAccId){
                        String reinBrokerLink = urlArr2[0] + 'request?c__details=';
                        if(accountContact.Contact.AccountType__c == AP_Constant.contactBroker) {
                            reinBrokerLink += parentLeadRequest.Program__c + '-' + parentLeadRequest.Reinsurer__c + '-' + parentLeadRequest.Broker__c + '-' + parentLeadRequest.Program__r.TECH_StageName__c + '-'+parentLeadRequest.Id; //RRA - 1045
                        }
                        else if(accountContact.Contact.AccountType__c == AP_Constant.contactReinsurer) {
                            reinBrokerLink += parentLeadRequest.Program__c + '-' + parentLeadRequest.Reinsurer__c + '-null-' + parentLeadRequest.Program__r.TECH_StageName__c + '-'+parentLeadRequest.Id; //RRA - 1045
                        }

                        reinsurerLinks += '<li style="text-align: left;"><a href="'+ reinBrokerLink + '">'+ parentLeadRequest.Reinsurer__r.Name +'</a> </li>';
                    }

                    if(htmlBody != null && htmlBody != ''){
                        htmlBody = htmlBody.replace('{InternetLink}', htmlInternetLink);
                        htmlBody = htmlBody.replace('{ProgramName}', programName);
                        htmlBody = htmlBody.replace('{CedingCompanyName}', cedingCompanyName);
                        htmlBody = htmlBody.replace('{ExpectedResponseDate}', String.valueOf(expectedAnsDate));
                        String commentStrDesigned = '<b style="color:blue";><font face="Arial" size="50px">' + comment + '</font></b>'; //RRA - ticket 1382 - 19122022
                        htmlBody = htmlBody.replace('{Comments}', commentStrDesigned); //RRA - ticket 1382 - 19122022
                        htmlBody = htmlBody.replace('{ReinsurerListPageLink}', reinsurerLinks);
                        htmlBody = htmlBody.replace('{ReinsurerPageLink}', reinsurerLinks);
                    }

                    mail.setHtmlBody(htmlBody);

                    if(!lstContactSent.contains(accountContact.ContactId)){
                        lstContactSent.add(accountContact.ContactId);
                        lstMails.add(mail);
                    }
                }
            }
        }

        Map<Id, List<Request__c>> mapAccListQuote = new Map<Id, List<Request__c>>();
        Map<Id, List<String>> mapAccListTreatySect = new Map<Id, List<String>>();
        Set<String> setBRLead = new Set<String>();

        for(Request__c leadReq : [SELECT Id, Treaty__c, Section__c, Reinsurer__c, Broker__c
                                FROM Request__c
                                WHERE Program__c = :programId
                                AND (ReinsurerStatus__c = :AP_Constant.statusSetup OR (LastVersionSent__c = TRUE AND LastVersionAnswered__c = TRUE))
                                AND RecordType.DeveloperName = :lstLeadRecordType[1]]){

            String strBR = null;
            if(leadReq.Broker__c == null){
                strBR = 'NoBroker-' + leadReq.Reinsurer__c;
            }
            else{
                strBR = leadReq.Broker__c + '-' + leadReq.Reinsurer__c;
            }

            setBRLead.add(strBR);
        }

        if(setTreatys.size() > 0 && mapRetained.size() > 0){
            for(Request__c quoteReq : [SELECT Id, Treaty__c, Section__c, Reinsurer__c, Broker__c, ReinsurerStatus__c, TECH_ReinsurerName__c,TECH_TreatyName__c, TECH_SectionName__c
                                    FROM Request__c
                                    WHERE Treaty__c IN :setTreatys
                                    AND Program__c = :programId
                                    AND ( (LastVersionSent__c = TRUE AND LastVersionAnswered__c = TRUE AND ReinsurerStatus__c = :AP_Constant.statusAnswered)
                                    OR (ReinsurerStatus__c = :AP_Constant.statusSetup OR (LastVersionSent__c = TRUE AND LastVersionAnswered__c = TRUE)) )
                                    AND RecordType.DeveloperName = :lstQuoteRecordType[1]]){

                //String valueTreatyList = quoteReq.TECH_TreatyName__c + ' / ' + quoteReq.TECH_SectionName__c + ' : ' + quoteReq.TECH_ReinsurerName__c;

                String valueTreatyList = quoteReq.TECH_TreatyName__c + ' : ' + quoteReq.TECH_ReinsurerName__c;

                if(quoteReq.ReinsurerStatus__c == AP_Constant.statusAnswered) {
                    if (quoteReq.Broker__c == null) {
                        String br = 'NoBroker-' + quoteReq.Reinsurer__c;

                        if (!mapRetained.get(quoteReq.Treaty__c).contains(br)) {
                            if (mapAccListQuote.containsKey(quoteReq.Reinsurer__c)) {
                                mapAccListQuote.get(quoteReq.Reinsurer__c).add(quoteReq);
                            } else {
                                mapAccListQuote.put(quoteReq.Reinsurer__c, new List<Request__c>{
                                    quoteReq
                                });
                            }

                            if (!setBRLead.contains(br)) {
                                if (mapAccListTreatySect.containsKey(quoteReq.Reinsurer__c)) {
                                    mapAccListTreatySect.get(quoteReq.Reinsurer__c).add(valueTreatyList);
                                } else {
                                    mapAccListTreatySect.put(quoteReq.Reinsurer__c, new List<String>{
                                        valueTreatyList
                                    });
                                }
                            }
                        }
                    } else if (quoteReq.Broker__c != null) {
                        String br = quoteReq.Broker__c + '-' + quoteReq.Reinsurer__c;

                        if (!mapRetained.get(quoteReq.Treaty__c).contains(br)) {
                            if (mapAccListQuote.containsKey(quoteReq.Broker__c)) {
                                mapAccListQuote.get(quoteReq.Broker__c).add(quoteReq);
                            } else {
                                mapAccListQuote.put(quoteReq.Broker__c, new List<Request__c>{
                                    quoteReq
                                });
                            }

                            if (!setBRLead.contains(br)) {
                                if (mapAccListTreatySect.containsKey(quoteReq.Broker__c)) {
                                    mapAccListTreatySect.get(quoteReq.Broker__c).add(valueTreatyList);
                                } else {
                                    mapAccListTreatySect.put(quoteReq.Broker__c, new List<String>{
                                        valueTreatyList
                                    });
                                }
                            }
                        }
                    }
                }
            }
        }

        Map<Id, List<AccountContactRelation>> mapAccVSContactRel = new Map<Id, List<AccountContactRelation>>();

            if(mapAccListQuote != null){
                List<Id> lstAccId = new List<Id>();
                lstAccId.addAll(mapAccListQuote.keySet());
    
                String macroLOBFromProgram;
                String natureFromProgram;
                String prinCedComFromProgram;
                List<AccountContactRelation> lstAccConRel;
               
                System.debug('lstAccId== ' + lstAccId);
                Program__c prog = [SELECT Macro_L_O_B__c, toLabel(Nature__c), PrincipalCedingCompany__c FROM Program__c WHERE Id =:programId];
                macroLOBFromProgram = prog.Macro_L_O_B__c;
                natureFromProgram = prog.Nature__c;
                prinCedComFromProgram = prog.PrincipalCedingCompany__c;
               
                if (!Test.isRunningTest()){
                    lstAccConRel = LWC18_SendUpdateRemind.getContact(lstAccId, macroLOBFromProgram, natureFromProgram, prinCedComFromProgram);
                }else{
                    lstAccConRel = LWC18_SendUpdateRemind.getContactFakeTestMethod(lstAccId, macroLOBFromProgram, natureFromProgram, prinCedComFromProgram);
                }
               
                
                System.debug('lstAccConRel== ' + lstAccConRel);
                
                for(AccountContactRelation accountContact : lstAccConRel){
                    List<AccountContactRelation> lstUpdAccountContact = new List<AccountContactRelation>();
                    if(mapAccVSContactRel.containsKey(accountContact.AccountId)){
                        lstUpdAccountContact = mapAccVSContactRel.get(accountContact.AccountId);
                        lstUpdAccountContact.add(accountContact);
                        mapAccVSContactRel.put(accountContact.AccountId, lstUpdAccountContact);
                    }
                    else{
                        lstUpdAccountContact.add(accountContact);
                        mapAccVSContactRel.put(accountContact.AccountId, lstUpdAccountContact);
                    }
                }
            }
            
            //quote - non retained emails
        for(Id accountId : mapAccVSContactRel.keySet()){
            List<AccountContactRelation> lstAccountContactByAccId = mapAccVSContactRel.get(accountId);

            for(AccountContactRelation accountContact : lstAccountContactByAccId){
                List<Request__c> lstQuoteReqs = mapAccListQuote.get(accountContact.AccountId);

                if(accountContact.Contact.Email != null) {
                    for(Request__c quoteReq : lstQuoteReqs) {

                        Boolean sendEmail = false;
                        Messaging.SingleEmailMessage m = new Messaging.SingleEmailMessage();       
                        Id quoteReqId = quoteReq.Id;

                        if(accountContact.Contact.AccountType__c == AP_Constant.contactBroker) {
                            String strBR = quoteReq.Broker__c + '-' + quoteReq.Reinsurer__c;

                            if (!setBRLead.contains(strBR)) {
                                m.setTemplateId(emailTempNonRetainedBrokerId);
                                m.setTargetObjectId(userId);
                                m.setWhatId(quoteReqId);
                                m.setSaveAsActivity(false);
                                sendEmail = true;
                            }
                        }
                        else if (accountContact.Contact.AccountType__c == AP_Constant.contactReinsurer) {
                            String strBR = 'NoBroker-' + quoteReq.Reinsurer__c;

                            if (!setBRLead.contains(strBR)) {
                                m.setTemplateId(emailTempNonRetainedReinsurerId);
                                m.setTargetObjectId(userId);
                                m.setWhatId(quoteReqId);
                                m.setSaveAsActivity(false);
                                sendEmail = true;
                            }
                        }

                        if(sendEmail == true){
                            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                            List<String> sendTo = new List<String>();
                            String htmlBody = '';

                            sendTo.add(accountContact.Contact.Email);
                            mail.setToAddresses(sendTo);
                            mail.setReplyTo(UserInfo.getUserEmail());
                            mail.setSenderDisplayName(UserInfo.getFirstName() + ' ' + UserInfo.getLastName());

                            if(lstCCEmailsToSend.size() > 0){
                                mail.setCcAddresses(lstCCEmailsToSend);
                            }

                            if(accountContact.Contact.AccountType__c == AP_Constant.contactBroker) {
                                mail.setSubject(mNonRetainedBroker.getSubject());
                                htmlBody = mNonRetainedBroker.htmlBody;
                            }
                            else if(accountContact.Contact.AccountType__c == AP_Constant.contactReinsurer) {
                                mail.setSubject(mNonRetainedReinsurer.getSubject());
                                htmlBody = mNonRetainedReinsurer.htmlBody;
                            }

                            String strLstCCEmailDisplayInEmailss = strLstCCEmailDisplay != null ? strLstCCEmailDisplay : '';
                            
                            if(htmlBody != null && htmlBody != ''){
                                htmlBody = htmlBody.replace('{emailP_C_LIFE}', strLstCCEmailDisplayInEmailss);

                                if(mapAccListTreatySect.containsKey(accountContact.AccountId)) {
                                    String listTreatySection = '';

                                    for (String value : mapAccListTreatySect.get(accountContact.AccountId)) {
                                        listTreatySection += '<li style="text-align: left;">' + value + '</li>';
                                    }

                                    htmlBody = htmlBody.replace('{ListTreatysListReinsurers}', listTreatySection);
                                }else{
                                    htmlBody = htmlBody.replace('{ListTreatysListReinsurers}', '');
                                }

                                htmlBody = htmlBody.replace('{InternetLink}', htmlInternetLink);
                                htmlBody = htmlBody.replace('{ProgramName}', programName);
                                htmlBody = htmlBody.replace('{CedingCompanyName}', cedingCompanyName);

                                if(String.valueOf(expectedAnsDate) != null){
                                    htmlBody = htmlBody.replace('{ExpectedResponseDate}',String.valueOf(expectedAnsDate));
                                }

                                String strCommentss = comment != null ? comment : '';
                                String commentStrDesigned = '<b style="color:blue";><font face="Arial" size="50px">' + strCommentss + '</font></b>'; //RRA - ticket 1382 - 1912202
                                htmlBody = htmlBody.replace('{Comments}', commentStrDesigned); //RRA - ticket 1382 - 1912202                  
                            }
                           
                            mail.setHtmlBody(htmlBody);

                            if (!lstContactSentQuote.contains(accountContact.ContactId)) {
                                lstContactSentQuote.add(accountContact.ContactId);
                                lstMails.add(mail);
                            }
                        }
                    }
                }
            }
        }

        if(lstMails.size() > 0){
            Messaging.sendEmail((List<Messaging.Email>) lstMails);
        }
            
        
    }
}