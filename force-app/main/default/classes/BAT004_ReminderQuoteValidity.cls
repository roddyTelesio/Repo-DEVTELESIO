/**
 * @description       : 
 * @author            : Telesio
 * @group             : 
 * @ticket            : 1574
 * @last modified on  : 16-10-2023
 * @last modified by  : Telesio (RRA)
 * Note: - Batch scheduled every day for sending email 2 days before quoteDealine (due date of quote validity)
**/

global class BAT004_ReminderQuoteValidity implements Database.Batchable<SObject> {
    
    /*global Id idRequest;
    
    global BAT004_ReminderQuoteValidity(Id reqId){
        System.debug('Begin BAT004_ReminderQuoteValidity');
        this.idRequest = reqId;   
    }*/
    
    global Database.QueryLocator start(Database.BatchableContext BC) {  
        system.debug('## Start BAT004_ReminderQuoteValidity - QueryLocator run by ' + UserInfo.getName());
        string query = 'SELECT  Program__c, TECH_RecordType__c, TECH_DateTimeEmailSendQuoteValidity__c, PrincipalCedingCompany__c, isChk2DaysEmailReminder__c, TECH_TreatyName__c,TECH_SectionName__c, TECH_SectionNumber__c, TECH_BrokerName__c, Program__r.Name, Program__r.PrincipalCedingCompany__r.Name, TECH_ReinsurerName__c, Program__r.PrincipalCedingCompany__c, Broker__c, Reinsurer__c, QuoteDeadline__c, Program__r.PrincipalCedingCompany__r.EmailPCLife__c FROM Request__c ';
        query = query + ' WHERE LastVersionAnswered__c = true AND LastVersionSent__c = true AND RecordType.Name = \'Quote Request\'';
        query = query + ' AND ReinsurerStatus__c IN (\'Answered\', \'Sent\', \'Refused\')';
        query = query + ' AND TECH_DateTimeEmailSendQuoteValidity__c = TODAY' ;
        query = query + ' AND isChk2DaysEmailReminder__c = true ' ;
        system.debug('## query ' + query);
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Request__c> scope) {
        system.debug('## Start BAT004_ReminderQuoteValidity - execute run by ' + UserInfo.getName());
        system.debug('## Start BAT004_ReminderQuoteValidity - scope ' + scope);
        system.debug('## Start BAT004_ReminderQuoteValidity - scope ' + scope.size());
        String message;
        Messaging.SingleEmailMessage m = new Messaging.SingleEmailMessage();
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        List<Messaging.SingleEmailMessage> lstMailsToSend =  new List<Messaging.SingleEmailMessage>();
        String lstTreatiesSectionsNames = '';
        List<String> lstEmailsToSend = new List<String>();
        String email;
        String emailTempReminderQuote = 'AGRE BATCH- Quote Reminder email 2 days before Quote Validity';
        String htmlInternetLink;
        List<Request__c> lstReqUpdateFlagReminder = new List<Request__c>();
        Messaging.SingleEmailMessage mReqRemindQuoteVal = new Messaging.SingleEmailMessage(); 
        Id requestId;
        map<String, String> mapIdPCCEmailPCC = new map <String, String>();
        map<String, String> mapIdPCCNamePCC = new map <String, String>();
        List<Request__c> lstReqUpdateDateTime = new List<Request__c>();
        Id emailTempReminderQuoteId;
        Id userId = UserInfo.getUserId();
        List<EmailTemplate> lstEmailTempReminderQuote= [SELECT Id, Name FROM EmailTemplate WHERE Name = :emailTempReminderQuote];
        if (lstEmailTempReminderQuote.size()>0){
            emailTempReminderQuoteId = lstEmailTempReminderQuote[0].Id;
        }
        List<Date> lstDateQuoteValidity;
        Boolean isActionSendEmail = false;
        String brokerReinsurerName;
        String program;
        String pcc;
        String rtQuote;
        Set<String> setBrokerReinsurerName = new Set<String>();
        Boolean isSameEmail = false;
        if (emailTempReminderQuoteId != null){
            mReqRemindQuoteVal = Messaging.renderStoredEmailTemplate(emailTempReminderQuoteId, userId, scope[0].Id);
        }
        List<Id> lstIdPcc = new List<Id>();
        List<String> lstEmailPcc = new List<String>();
        map<String, List<Request__c>> mapKeysDetailsRequest = new  map<String, List<Request__c>>();
        Date dateQuoteValidity;
        
        for(Request__c request : scope){
            lstIdPcc.add(request.Program__r.PrincipalCedingCompany__c);
            //Step 1 : get list values Request with keys Program__c + '-' + Reinsurer__c + '-' + Broker__c
            if (mapKeysDetailsRequest.containsKey(request.Program__c + '-' + request.Reinsurer__c + '-' + request.Broker__c)){
                mapKeysDetailsRequest.get(request.Program__c + '-' + request.Reinsurer__c + '-' + request.Broker__c).add(request);
            }else{
                mapKeysDetailsRequest.put(request.Program__c + '-' + request.Reinsurer__c + '-' + request.Broker__c, new List<Request__c>{request});
            }
        }
        
        system.debug('mapKeysDetailsRequest == '+ mapKeysDetailsRequest);
        
        //Step 2 : create map to get email on PCC
        if (lstIdPcc.size()>0 &&  lstIdPcc != null){
            for (Account acc : [SELECT Id, Name, EmailPCLife__c FROM Account WHERE Id IN:lstIdPcc]){
                mapIdPCCEmailPCC.put(acc.Id, acc.EmailPCLife__c);
                mapIdPCCNamePCC.put(acc.Id, acc.Name);
            }
        }
        
        system.debug('mapIdPCCEmailPCC == '+ mapIdPCCEmailPCC);
        
        //Step 3 : 
        // Loop on List request of mapKeysDetailsRequest for specify if it's broker or it's reinsurer 
        // Initialize list treatySectionsNames Info according the case broker or case reinsurer
        for (String key : mapKeysDetailsRequest.keySet()){
            List<Request__c> lstReq = mapKeysDetailsRequest.get(key);
            system.debug('lstReq == '+ lstReq);
            system.debug('lstReqsize == '+ lstReq.size());
            for (Request__c request : lstReq){
                rtQuote = request.TECH_RecordType__c;
                if (request.Program__r.PrincipalCedingCompany__r.EmailPCLife__c == mapIdPCCEmailPCC.get(request.Program__r.PrincipalCedingCompany__c) && request.Program__r.PrincipalCedingCompany__r.Name ==  mapIdPCCNamePCC.get(request.Program__r.PrincipalCedingCompany__c)){
                    isSameEmail = true;
                    email = mapIdPCCEmailPCC.get(request.Program__r.PrincipalCedingCompany__c);
                    String treatyName = String.isNotBlank(request.TECH_TreatyName__c) ? request.TECH_TreatyName__c : '';
                    String SectionName = String.isNotBlank(request.TECH_SectionName__c) ? request.TECH_SectionName__c : '';
                    String SectionNumber = String.isNotBlank(request.TECH_SectionNumber__c) ? request.TECH_SectionNumber__c : '';
                        
                    if (request.Broker__c != null && request.Reinsurer__c != null){
                        dateQuoteValidity = request.QuoteDeadline__c;
                        brokerReinsurerName = request.TECH_ReinsurerName__c + ' (via ' + request.TECH_BrokerName__c + ') ';
                        program = request.Program__r.Name;
                        pcc = mapIdPCCNamePCC.get(request.Program__r.PrincipalCedingCompany__c);
                        lstTreatiesSectionsNames += '<li style="text-align: left;">'+ treatyName +' - '+ SectionName  +' - Section Number : ' + SectionNumber  + '</li>';
                    }else if (request.Broker__c == null && request.Reinsurer__c != null){
                        dateQuoteValidity = request.QuoteDeadline__c;
                        brokerReinsurerName = request.TECH_ReinsurerName__c;
                        program = request.Program__r.Name;
                        pcc = mapIdPCCNamePCC.get(request.Program__r.PrincipalCedingCompany__c);
                        lstTreatiesSectionsNames += '<li style="text-align: left;">'+ treatyName +' - '+ SectionName +' - Section Number : ' + SectionNumber  + '</li>';
                    }
                    
                }
            }
            
            String domainURL = URL.getOrgDomainUrl().toExternalForm();
            htmlInternetLink = '<a href="' + domainURL + '/lightning/page/home">ACTOR NewGen Page</a>';
            
            //Step 4 : if mail pcc on request match with mail in account
            // Sending Email
            if (isSameEmail){
                String htmlTreatysListReinsurers = '<br/>';
                m.setSaveAsActivity(false);
                m.setTemplateId(emailTempReminderQuoteId);
                //m.setTargetObjectId(userId);
                //m.setWhatId(requestId);
                String htmlBody = mReqRemindQuoteVal.htmlBody;
                lstEmailsToSend.add(email);
                mail.setToAddresses(lstEmailsToSend);
                mail.setSenderDisplayName(UserInfo.getFirstName() + ' ' + UserInfo.getLastName());
                mail.setSubject('ACTOR : ' + rtQuote + 'Request Reminder 02 Days before Quote Validity for program ' + program + ' for ' + pcc );
                mail.emailPriority = 'Highest';
                System.debug(LoggingLevel.DEBUG, 'lstTreatiesSectionsNames : ' + lstTreatiesSectionsNames);  
                if (!Test.isRunningTest()){
                    htmlBody = htmlBody.replace('{listTreatySectionsNames}', lstTreatiesSectionsNames);
                    htmlBody = htmlBody.replace('{BrokerReinsurerName}', brokerReinsurerName);
                    htmlBody = htmlBody.replace('{DateQuoteDeadline}', String.valueOf(dateQuoteValidity));
                    htmlBody = htmlBody.replace('{programName}', program);
                    htmlBody = htmlBody.replace('{pccName}', pcc);
                    htmlBody = htmlBody.replace('{HomePageLink}', htmlInternetLink);
                    mail.setHtmlBody(htmlBody);
                    lstMailsToSend.add(mail);
                    system.debug('## program ' +program);
                    system.debug('## pcc ' +pcc);
                    System.debug(LoggingLevel.DEBUG, 'lstMailsToSend 11: ' + lstMailsToSend);
                    System.debug(LoggingLevel.DEBUG, 'lstMailsToSend.size 11: ' + lstMailsToSend.size());
                }
                if(lstMailsToSend.size() > 0){  
                    Messaging.SendEmailResult[] results = Messaging.sendEmail((List<Messaging.Email>) lstMailsToSend);
                    System.debug(LoggingLevel.DEBUG, 'results : ' + results);
                    if(results[0].success) {
                        message = 'Email Send Successfully';
                    }
                    else {
                        message = results[0].errors[0].message;
                    }
                }
                
                if (!Test.isRunningTest()){
                    if (message == 'Email Send Successfully'){
                        for(Request__c request : scope){
                            if (request.isChk2DaysEmailReminder__c){
                                request.isChk2DaysEmailReminder__c = false;
                                lstReqUpdateFlagReminder.add(request); 
                            }                   
                        }
                        if (lstReqUpdateFlagReminder.size()>0){
                            update lstReqUpdateFlagReminder;
                        }
                    }
                }
               
            }
            system.debug('lstEmailsToSend == '+ lstEmailsToSend);
            system.debug('lstTreatiesSectionsNames == '+ lstTreatiesSectionsNames);
            
            lstEmailsToSend = new List<String>(); // init lstEmailsToSend to avoid cumulative emails
            lstMailsToSend =  new List<Messaging.SingleEmailMessage>(); //init lstMailsToSend to avoid cumulative sending of emails
            lstTreatiesSectionsNames = ''; // init lstTreatiesSectionsNames to avoid cumulative list of treaty and sections
        }
        system.debug('## message ' +message);
        system.debug('## End BAT004_ReminderQuoteValidity - execute run by ' + UserInfo.getName());
    }
    
    global void finish(Database.BatchableContext BC) {
        system.debug('## finish BAT004_ReminderQuoteValidity - finish run by ' + UserInfo.getName());
    }
}