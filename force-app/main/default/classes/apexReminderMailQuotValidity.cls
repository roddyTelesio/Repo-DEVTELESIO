/**
 * @description       : 
 * @author            : Telesio
 * @group             : 
 * @ticket            : 1574
 * @last modified on  : 16-10-2023
 * @last modified by  : Telesio (RRA)
 * Note: - if isChk2DaysEmailReminder__c = true and dateTimeQuotevalidity = today, Email is sending
 *       - if isChk2DaysEmailReminder__c = false and dateTimeQuotevalidity != today, Email is not sending 
**/

public without sharing class apexReminderMailQuotValidity {
    public static void sendEmail (Id idRequest, Boolean isPortalAccess){
        System.debug(LoggingLevel.DEBUG, 'start sendEmail');
        System.debug(LoggingLevel.DEBUG, ' idRequest == '+ idRequest);
        Savepoint sp = Database.setSavepoint();
        String message;
        Messaging.SingleEmailMessage m = new Messaging.SingleEmailMessage();
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        List<Messaging.SingleEmailMessage> lstMailsToSend =  new List<Messaging.SingleEmailMessage>();
        String lstTreatiesSectionsNames = '';
        List<String> lstNamesTreatiesSections = new List<String>();
        String brokerReinsurerName;
        String reinsurerName;
        List<String> lstEmailsToSend = new List<String>();
        String emailTempReminderQuote = 'AGRE - Quote Reminder email 2 days before Quote Validity';
        Id idBroker = null;
        Id idReinsurer = null;
        Id idProgram;
        String namePCC;
        String htmlInternetLink;
        Id emailTempReminderQuoteId;
        List<Request__c> lstReqUpdateFlagReminder = new List<Request__c>();
        String query = 'SELECT  Id, Program__c, OriginalRequest__c, PrincipalCedingCompany__c, isChk2DaysEmailReminder__c, ReinsurerStatus__c, TECH_TreatyName__c,TECH_SectionName__c, TECH_SectionNumber__c, TECH_BrokerName__c, TECH_ReinsurerName__c, Broker__c, Reinsurer__c, QuoteDeadline__c FROM Request__c';
        try{
            Messaging.SingleEmailMessage mReqRemindQuoteVal = new Messaging.SingleEmailMessage(); 
            String emailPcc;
            Id requestId;
            DateTime dateToday = Date.today();    
            map<String, String> mapIdPCCEmailPCC = new map <String, String>();
            List<Request__c> lstReqUpdateDateTime = new List<Request__c>();
            Id userId = UserInfo.getUserId();
            //Boolean is2DaysEmailReminderSet; 
            Boolean isChk2DaysEmailReminder;
            Date dateQuoteValidity;
            List<EmailTemplate> lstEmailTempReminderQuote= [SELECT Id, Name FROM EmailTemplate WHERE Name = :emailTempReminderQuote];
            if (lstEmailTempReminderQuote.size()>0){
                emailTempReminderQuoteId = lstEmailTempReminderQuote[0].Id;
            }
           
            System.debug(LoggingLevel.DEBUG, 'emailTempReminderQuoteId: ' + emailTempReminderQuoteId);
            System.debug(LoggingLevel.DEBUG, 'userId: ' + userId);

            System.debug(LoggingLevel.DEBUG, 'UserInfo.getUserEmail(): ' + UserInfo.getUserEmail());
            System.debug(LoggingLevel.DEBUG, 'UserInfo.getLastName(): ' + UserInfo.getLastName());
            
                //Step 1 : Get Request in current triggered
                for (Request__c reqTriggered: [SELECT Id, Program__c, isChk2DaysEmailReminder__c, QuoteDeadline__c, DateTimeSendEmailQuoteValidity__c, Treaty__c, Broker__c, PrincipalCedingCompany__c, Reinsurer__c FROM Request__c WHERE Id =:idRequest]){
                    if (reqTriggered.Broker__c !=null && reqTriggered.Reinsurer__c != null){
                        idBroker = reqTriggered.Broker__c;
                        idReinsurer = reqTriggered.Reinsurer__c;
                        dateQuoteValidity = reqTriggered.QuoteDeadline__c;
                        
                    }else if (reqTriggered.Broker__c ==null && reqTriggered.Reinsurer__c != null){
                        idReinsurer = reqTriggered.Reinsurer__c;
                        dateQuoteValidity = reqTriggered.QuoteDeadline__c;
                    }
                    idProgram = reqTriggered.Program__c;
                    namePCC = reqTriggered.PrincipalCedingCompany__c;
                   
                }
                System.debug(LoggingLevel.DEBUG, 'dateQuoteValidity: ' + dateQuoteValidity);
                System.debug(LoggingLevel.DEBUG, 'dateToday: ' + dateToday);
                System.debug(LoggingLevel.DEBUG, 'idBroker: ' + idBroker);
                System.debug(LoggingLevel.DEBUG, 'idReinsurer: ' + idReinsurer);
                System.debug(LoggingLevel.DEBUG, 'programId: ' + idProgram);
                System.debug(LoggingLevel.DEBUG, 'namePCC: ' + namePCC);
                
                if (isPortalAccess){
                    //Step 2 : Get all request with the same quoteDateValidity / same broker or Reinsurer / same program
                    if (idBroker != null && idReinsurer != null){
                        query = query + ' WHERE OriginalRequest__c = null AND RecordType.Name = \'Quote Request\' AND Broker__c =:idBroker AND Reinsurer__c =:idReinsurer AND Program__c =:idProgram AND ReinsurerStatus__c IN (\'Answered\', \'Sent\', \'Refused\')';
                    }else if (idBroker == null && idReinsurer != null){
                        query = query + ' WHERE OriginalRequest__c = null  AND RecordType.Name = \'Quote Request\' AND (Broker__c = null AND Reinsurer__c =:idReinsurer) AND Program__c =:idProgram AND ReinsurerStatus__c IN (\'Answered\', \'Sent\', \'Refused\')';
                    }
                }else{
                    if (idBroker != null && idReinsurer != null){
                        query = query + ' WHERE LastVersionAnswered__c = true AND LastVersionSent__c = true AND RecordType.Name = \'Quote Request\' AND Broker__c =:idBroker AND Reinsurer__c =:idReinsurer AND Program__c =:idProgram AND ReinsurerStatus__c IN (\'Answered\', \'Sent\', \'Refused\')';
                    }else if (idBroker == null && idReinsurer != null){
                        query = query + ' WHERE LastVersionAnswered__c = true AND LastVersionSent__c = true  AND RecordType.Name = \'Quote Request\' AND (Broker__c = null AND Reinsurer__c =:idReinsurer) AND Program__c =:idProgram AND ReinsurerStatus__c IN (\'Answered\', \'Sent\', \'Refused\')';
                    }
                }
                
                System.debug(LoggingLevel.DEBUG, 'query: ' + query);
                
                // Step 3 : create map between Name and Email of Account (PCC)
                if (namePCC != null){
                    for (Account acc : [SELECT Id, Name, EmailPCLife__c FROM Account WHERE Name=:namePCC]){
                        mapIdPCCEmailPCC.put(acc.Name, acc.EmailPCLife__c);
                    }
                }
                System.debug(LoggingLevel.DEBUG, 'mapIdPCCEmailPCC: ' + mapIdPCCEmailPCC);
                
                //Step 4: Get Request from Step 2 an loop on it
                 List<Request__c> lstRequestQuote = Database.query(query);
                 if (lstRequestQuote.size()>0 && lstRequestQuote != null){
                    System.debug(LoggingLevel.DEBUG, 'lstRequestQuote: ' + lstRequestQuote);
                    System.debug(LoggingLevel.DEBUG, 'lstRequestQuotesize: ' + lstRequestQuote.size());
                    if (emailTempReminderQuoteId != null){
                        mReqRemindQuoteVal = Messaging.renderStoredEmailTemplate(emailTempReminderQuoteId, userId, lstRequestQuote[0].Id);
                    }
                    for(Request__c request : lstRequestQuote){
                        requestId = request.Id;
                        if (mapIdPCCEmailPCC.get(request.PrincipalCedingCompany__c) != null){
                            lstEmailsToSend.add(mapIdPCCEmailPCC.get(request.PrincipalCedingCompany__c));
                        }else {
                            System.debug(LoggingLevel.DEBUG, 'PCC has no email please check it and add an email');
                        }
                        String htmlTreatysListReinsurers = '<br/>';
                        lstTreatiesSectionsNames += '<li style="text-align: left;">'+request.TECH_TreatyName__c +' - '+ request.TECH_SectionName__c +' - Section Number : ' + request.TECH_SectionNumber__c + '</li>';
                        lstNamesTreatiesSections.add(lstTreatiesSectionsNames);
                        if (request.Broker__c != null && request.Reinsurer__c != null){
                            brokerReinsurerName = request.TECH_ReinsurerName__c + ' (via ' + request.TECH_BrokerName__c + ') ';  
                            isChk2DaysEmailReminder = request.isChk2DaysEmailReminder__c;
                        }else if (request.Broker__c == null && request.Reinsurer__c != null){
                            brokerReinsurerName = request.TECH_ReinsurerName__c;
                            isChk2DaysEmailReminder = request.isChk2DaysEmailReminder__c;
                        }
                        String domainURL = URL.getOrgDomainUrl().toExternalForm();
                        htmlInternetLink = '<a href="' + domainURL + '/lightning/page/home">ACTOR NewGen Page</a>';
                    }
                 }

                 if (lstTreatiesSectionsNames != null && brokerReinsurerName != null && htmlInternetLink != null){
                    //Step 5 : create and prepare configuration on Messaging.SingleEmailMessage object to send Email
                    m.setSaveAsActivity(false);
                    m.setTemplateId(emailTempReminderQuoteId);
                    //m.setTargetObjectId(userId);
                    m.setWhatId(requestId);
                    String htmlBody = mReqRemindQuoteVal.htmlBody;
                    mail.setToAddresses(lstEmailsToSend);
                    //mail.setReplyTo(UserInfo.getUserEmail());
                    mail.setSenderDisplayName(UserInfo.getFirstName() + ' ' + UserInfo.getLastName());
                    mail.setSubject(mReqRemindQuoteVal.getSubject());
                    mail.emailPriority = 'Highest';
                    htmlBody = htmlBody.replace('{listTreatySectionsNames}', lstTreatiesSectionsNames);
                    htmlBody = htmlBody.replace('{BrokerReinsurerName}', brokerReinsurerName);
                    htmlBody = htmlBody.replace('{DateQuoteDeadline}', String.ValueOf(dateQuoteValidity));
                    htmlBody = htmlBody.replace('{HomePageLink}', htmlInternetLink);
                    mail.setHtmlBody(htmlBody);
                    lstMailsToSend.add(mail);
                    System.debug(LoggingLevel.DEBUG, 'lstMailsToSend: ' + lstMailsToSend);
                    System.debug(LoggingLevel.DEBUG, 'lstTreatiesSectionsNames : ' + lstTreatiesSectionsNames);
                    //System.debug(LoggingLevel.DEBUG, 'is2DaysEmailReminderSet : ' + is2DaysEmailReminderSet);
                    System.debug(LoggingLevel.DEBUG, 'isChk2DaysEmailReminder : ' + isChk2DaysEmailReminder);
                    if(lstMailsToSend.size() > 0 && isChk2DaysEmailReminder){  //RRA - ticket 1574 - 12102023
                        Messaging.SendEmailResult[] results = Messaging.sendEmail((List<Messaging.Email>) lstMailsToSend);
                        System.debug(LoggingLevel.DEBUG, 'results : ' + results);
                        if(results[0].success) {
                            message = 'Email Send Successfully';
                        }
                        else {
                            message = results[0].errors[0].message;
                        }
                    }
                    
                    if (message == 'Email Send Successfully'){
                        for(Request__c request : lstRequestQuote){
                            if (request.isChk2DaysEmailReminder__c){
                                request.isChk2DaysEmailReminder__c = false;
                                lstReqUpdateFlagReminder.add(request); 
                            }                   
                        }
                        if (lstReqUpdateFlagReminder.size()>0){
                            update lstReqUpdateFlagReminder;
                        }
                    }
                    
                    
                    System.debug(LoggingLevel.DEBUG, 'lstReqUpdateFlagReminder : ' + lstReqUpdateFlagReminder);
                 } 
            System.debug(LoggingLevel.DEBUG, 'lstEmailsToSend: ' + lstEmailsToSend);
            System.debug(LoggingLevel.DEBUG, 'lstMailsToSend.size: ' + lstMailsToSend.size());
            System.debug(LoggingLevel.DEBUG, 'brokerReinsurerName: ' + brokerReinsurerName);
            System.debug(LoggingLevel.DEBUG, 'message: ' + message);
        }catch(Exception e){
            Database.rollback( sp );
            System.debug(LoggingLevel.DEBUG, 'creationBodyHtml Exception occured: ' + e.getMessage());
        }
    }
}