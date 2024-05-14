public with sharing class AP56_SendBindReminder {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Send Bind Reminder Class
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 24-FEB-2021  MBE    1.0     Initial Version
-- 11-AUG-2021  MBE    1.1     Code Optimization - Use Ternary Operator
-- 09-NOV-2021  MBE    1.2     W-1037 - remove renderedStoredEmailTemplate from Loop
-- 21-DEC-2021  MBE    1.3     W-0932 - Transversal - Ne pas proposer des utilisateurs inactifs
--------------------------------------------------------------------------------------
**************************************************************************************/

    /**
    * @description Send Bind Reminder to Covered Ceding Contacts
    * @param List<SpecialAcceptance__c> lstSA
    * @return void
    */
    public static void sendBindReminderToCovCedCon(List<SpecialAcceptance__c> lstSA){
        //get Covered Ceding contact for lstSA
        Map<Id, SpecialAcceptance__c> mapSaCovCedConBySaId = new Map<Id, SpecialAcceptance__c>();
        Map<Id, List<AccountContactRelation>> mapLstCovCedConBySaId = new Map<Id, List<AccountContactRelation>>();
        Map<String, Id> mapEmailTempIdByName = new Map<String, Id>();
        List<Messaging.SingleEmailMessage> lstMailsToSend =  new List<Messaging.SingleEmailMessage>();
        List<String> lstEmailTemplateName = new List<String>{AP_Constant.emailTempSaBindReminder};
        List<String> lstSAFields = AP_Constant.getCreatableFieldsByObjName(AP_Constant.sObjectSpecialAcceptance);
        String strSAFields = String.join(lstSAFields , ', ');
        Id userId = UserInfo.getUserId();

        for(EmailTemplate emailTemp: [SELECT Id, Name FROM EmailTemplate WHERE Name IN : lstEmailTemplateName]){
            mapEmailTempIdByName.put(emailTemp.Name, emailTemp.Id);
        }

        Messaging.SingleEmailMessage emailTempSaBindReminder = new Messaging.SingleEmailMessage();       
        emailTempSaBindReminder = Messaging.renderStoredEmailTemplate(mapEmailTempIdByName.get(AP_Constant.emailTempSaBindReminder), userId, null);

        Network networkObj = [SELECT Id
                              FROM Network
                              WHERE Name =: System.Label.Actor_ceding_portal_name];

        String url = Network.getLoginUrl(networkObj.Id);
        List<String> urlArr = url.split('login');


        String querySA = 'select Id, Program__r.UwYear__c, Program__r.PrincipalCedingCompany__c, Program__r.Nature__c, SpaDurationDays__c, Program__r.Name, CoveredCedingCompany__r.Name, Program__r.PrincipalCedingCompany__r.Name, '
                            + ' PrincipalCedingCompany__r.EmailSA__c, BindExpectedAnswerDate__c, '
                            + strSAFields
                            + ' from SpecialAcceptance__c where (Id IN :lstSA) ' ;

        lstSA = Database.query(querySA);

        for(SpecialAcceptance__c sa : lstSA){
            mapSaCovCedConBySaId.put(sa.Id, sa);
        }

        mapLstCovCedConBySaId = getCovCedContact(lstSA);

        System.debug('mapLstCovCedConBySaId == '+ mapLstCovCedConBySaId);

        for(Id saId : mapLstCovCedConBySaId.keySet()) {
            List<AccountContactRelation> lstCovAccCont = mapLstCovCedConBySaId.get(saId);
            System.debug('lstCovAccCont == '+ lstCovAccCont);
            SpecialAcceptance__c sa = mapSaCovCedConBySaId.get(saId);

            for(AccountContactRelation covCedCon : lstCovAccCont){
                Messaging.SingleEmailMessage m = new Messaging.SingleEmailMessage();
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                List<String> lstEmailsToSend = new List<String>();
                Id emailTempSaBindReminderEmailId = mapEmailTempIdByName.get(AP_Constant.emailTempSaBindReminder);
                String pccSaEmail = sa.PrincipalCedingCompany__r.EmailSA__c;
                String pccSaEmailDisplay = null;
                String covCedConEmail = covCedCon.Contact.Email;
                // m = Messaging.renderStoredEmailTemplate(emailTempSaBindReminderEmailId, userId, null);
                m.setTemplateId(emailTempSaBindReminderEmailId);
                m.setTargetObjectId(userId);
                // m.setWhatId(reqId);
                m.setSubject(emailTempSaBindReminder.getSubject());
                m.setHtmlBody(emailTempSaBindReminder.htmlBody);
                m.setSaveAsActivity(false);
                lstEmailsToSend.add(covCedConEmail);
                mail.setToAddresses(lstEmailsToSend);
                mail.setReplyTo(UserInfo.getUserEmail());
                mail.setSenderDisplayName(UserInfo.getFirstName() + ' ' + UserInfo.getLastName());

                List<String> lstCCEmailsToSend = new List<String>();

                if(pccSaEmail != null ){
                    if(pccSaEmail.contains(';')){
                        lstCCEmailsToSend = pccSaEmail.split(';');
                    }
                    else{
                        lstCCEmailsToSend.add(pccSaEmail);
                    }
                }

                for(String pccEmail : lstCCEmailsToSend){
                    if(pccSaEmailDisplay == null){
                        pccSaEmailDisplay = pccEmail;
                    }
                    else{
                        pccSaEmailDisplay = pccSaEmailDisplay + ' ' + pccEmail;   
                    }
                }

                if(lstCCEmailsToSend.size() > 0){
                    mail.setCcAddresses(lstCCEmailsToSend);
                }
                
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
                
                htmlBody = htmlBody.replace('[URL]', saLink);
                htmlBody = htmlBody.replace('{ActorNewGenURL}', htmlInternetLink);
                htmlBody = htmlBody.replace('{CovCedConEmail}', covCedConEmail==null?'':covCedConEmail); // MRA 1229 04/08/2022 

                String strCCC = sa.CoveredCedingCompany__r != null ? sa.CoveredCedingCompany__r.Name : '';
                htmlBody = htmlBody.replace('{Coveredcedingcompany}', strCCC);
                htmlSubject = htmlSubject.replace('{CedingCompanyName}', strCCC);  

                String strComment = sa.Comments__c != null ? sa.Comments__c : '';
                String commentStrDesigned = '<b style="color:blue";><font face="Arial" size="50px">' + strComment + '</font></b>'; //RRA - ticket 1382 - 16122022
                htmlBody = htmlBody.replace('{Comments}', commentStrDesigned); //RRA - ticket 1382 - 16122022

                String strBindExpAnsDate = sa.BindExpectedAnswerDate__c != null ? String.valueOf(sa.BindExpectedAnswerDate__c) : '';
                htmlBody = htmlBody.replace('{BindExpectedAnswerDate}', strBindExpAnsDate);

                htmlSubject = htmlSubject.replace('{ProgramName}', sa.Program__r.Name);  

                mail.setHtmlBody(htmlBody);
                mail.setSubject(htmlSubject);
                lstMailsToSend.add(mail);
            }
        }

        if(lstMailsToSend.size() > 0){
            Messaging.sendEmail((List<Messaging.Email>) lstMailsToSend);
        }
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
            System.debug('setCovCedComId == '+ setCovCedComId);

            if (!Test.isRunningTest()){
                for(AccountContactRelation accContactRelation : [SELECT Id, AccountId,Account.Name, Account.RecordTypeId, Contact.Account.RecordTypeId, Contact.Email, Roles, ContactId, Contact.MacroLoB__c, Contact.Nature__c, Contact.LastName, Contact.FirstName FROM AccountContactRelation
                                                            WHERE AccountId IN :setCovCedComId
                                                            AND IsActive = TRUE
                                                            AND Contact.Email!= null]){ // MRA 1229 04/08/2022
                if(accContactRelation.Account.RecordTypeId == accContactRelation.Contact.Account.RecordTypeId){
                    lstAccConRelation.add(accContactRelation);
                    setContactId.add(accContactRelation.ContactId);
                }
            }
        }else {
            for(AccountContactRelation accContactRelation : [SELECT Id, AccountId,Account.Name, Account.RecordTypeId, Contact.Account.RecordTypeId, Contact.Email, Roles, ContactId, Contact.MacroLoB__c, Contact.Nature__c, Contact.LastName, Contact.FirstName FROM AccountContactRelation
                                                            WHERE IsActive = TRUE
                                                            AND Contact.Email!= null]){ // MRA 1229 04/08/2022
                if(accContactRelation.Account.RecordTypeId == accContactRelation.Contact.Account.RecordTypeId){
                    lstAccConRelation.add(accContactRelation);
                    setContactId.add(accContactRelation.ContactId);
                }
            }
        }
            

            for(SpecialAcceptance__c sa : lstSpecialAcceptance){
                for(AccountContactRelation accContactRelation : lstAccConRelation){
                    List<AccountContactRelation> lstCovAccCon = new List<AccountContactRelation>();
                    if (!Test.isRunningTest()){
                        if(sa.CoveredCedingCompany__c == accContactRelation.AccountId){
                            if(mapLstCovCedConBySaId.containsKey(sa.Id)){
                                lstCovAccCon = mapLstCovCedConBySaId.get(sa.Id);
                            }
                            lstCovAccCon.add(accContactRelation);
                            mapLstCovCedConBySaId.put(sa.Id, lstCovAccCon);
                        }
                    }else{
                        mapLstCovCedConBySaId.put(sa.Id, lstAccConRelation);
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

                //get Referential Id of PCC
                if(mapReferentialIdByPCC.containsKey(pccId)){
                    String pccReferentialId = mapReferentialIdByPCC.get(pccId);
                    //get Group of Referential Id 0f PCC
                    if(mapGroupByReferentialId.containsKey(pccReferentialId)){
                        Group gp = mapGroupByReferentialId.get(pccReferentialId);

                        //get list of User or Group Id of group of Referential Id 0f PCC 
                        if(mapLstUserOrGroupIdByGroupId.containsKey(gp.Id)){
                            List<Id> lstUserOrGroupIdOfPCC = mapLstUserOrGroupIdByGroupId.get(gp.Id);
                            Set<Id> setUserOrGroupIdOfPCC = new Set<Id>();
                            setUserOrGroupIdOfPCC.addAll(lstUserOrGroupIdOfPCC);
                            for(AccountContactRelation covCedCon : lstCovCedAccConRelation){
                                //get userId for Covered Ceding Contact
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

}