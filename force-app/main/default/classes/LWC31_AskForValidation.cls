public without sharing class LWC31_AskForValidation {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Class for lwc31AskForValidation
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 10-APR-2020  SAU    1.0      Initial Version
-- 02-APR-2021  MBE    1.1      W-0938 - Mettre en CC la BAL de la PCC
-- 20-DEC-2021  MBE    1.2      W-0932 - Transversal - Ne pas proposer des utilisateurs inactifs
-- 30-MAY-2022  AMI    1.3      W-0936 - Signing - Ask for validation impossible si on a pas créé le programme
--------------------------------------------------------------------------------------
**************************************************************************************/
    /**
    * @description Method to retrieve name of Program
    * @param Id programId
    * @return Map<String, Object>
    */
    @AuraEnabled
    public static  Map<String, Object> getProgramName(Id programId){
      Map<String, Object> mapResults = new Map<String, Object>();
      List <Program__c> lstProg = [SELECT Id, 
                                          Name
                                   FROM Program__c 
                                   WHERE Id =: programId];
      mapResults.put('Id', lstProg[0].Id);
      mapResults.put('programName', lstProg[0].Name);

      return mapResults;
    }
    /**
    * @description Method to retrieve Users for ask for validation
    * @param Integer premium
    * @param String PrincipleCedingCompany
    * @return Map<String, Object>
    */
    @AuraEnabled
    public static Map<String, Object> getAskToUsers(String premium, String PrincipleCedingCompany){
        Map <String,Object> mapResult = new Map<String,Object>();
        Set<String> setRoles = new Set<String> ();
        List <User> lstSelectedUsers = new List<User>();
        
        try {

            Long premiumInt = Long.valueOf(premium);

            // using Custom Metadata Types
            List<CM_RoleRange__mdt> lstCMRoleRange = [SELECT MasterLabel, Premium_Limit__c FROM CM_RoleRange__mdt];

            for(CM_RoleRange__mdt CMRoleRange : lstCMRoleRange){
                if(CMRoleRange.Premium_Limit__c == 0 || (premiumInt <= CMRoleRange.Premium_Limit__c)){
                    setRoles.add(CMRoleRange.MasterLabel);
                }
            }

            List <User> lstAllUsers = [SELECT Id, Name, Email, IsActive
                                       FROM User
                                       WHERE UserRole.DeveloperName IN: setRoles
                                       AND IsActive = true];

            Account account = [SELECT TECH_ReferentialId__c
                               FROM Account
                               WHERE Id =: PrincipleCedingCompany];

            Group groupOfPrincipleCompany = [SELECT Id, Name
                                             FROM Group
                                             WHERE DeveloperName =: account.TECH_ReferentialId__c];

            List <GroupMember> lstGroupMembers = [SELECT UserOrGroupId
                                                  FROM GroupMember
                                                  WHERE GroupId =: groupOfPrincipleCompany.Id];

            for(GroupMember member : lstGroupMembers){
                for(User user : lstAllUsers){
                    if(member.UserOrGroupId == user.Id){
                        lstSelectedUsers.add(user);
                    }
                }
            }

            mapResult.put('Success', lstSelectedUsers);
            mapResult.put('setRoles', setRoles);

        }    
         catch (Exception error) {
             mapResult.put('Error', error.getMessage());
        }

        return mapResult;
    }

    /**
    * @description Method to send Email for validation to Users
    * @param List <Request__c> lstRequests
    * @param List <User> lstSelectedValidators
    * @param String comment
    * @param String requestLink
    * @return Map<String, Object>
    */
    @AuraEnabled
    public static Map<String, Object> validateRequests(List <Request__c> lstRequests, List <User> lstSelectedValidators, String comment, String requestLink){
        Map<String,Object> mapResult = new Map<String,Object>();
        List <Id> lstIds = new List<Id>();
        List<String> lstCCEmailsToSend = new List<String>();
        String strLstCCEmail = null;
        List<Request__c> lstRequestToUpdated = new List<Request__c>(); //RRA - ticket 01411 - 03042023
        
        try {

             //RRA - ticket 01411 - 03042023
             if(lstRequests.size() > 0){
                for (Request__c req : lstRequests){
                    if (req.isAskValidation__c == false){
                        req.isAskValidation__c = true;
                        lstRequestToUpdated.add(req);
                    }
                }
            }
            if (lstRequestToUpdated.size()>0){
                update lstRequestToUpdated;
            }
            
            //SAU share requests and principle ceding company of program with  list of selected validators
            shareRequestAccounts(lstRequests, lstSelectedValidators);
            Id emailTempValidateId;
            String emailTempValidateName = AP_Constant.emailTemplateValidateReq;
            List <String> lstEmailsToSend = new List<String>();
            List<Messaging.SingleEmailMessage> lstMailsToSend =  new List<Messaging.SingleEmailMessage>();
            List<EmailTemplate> lstEmailTemplateValidate= [SELECT Id, Name FROM EmailTemplate WHERE Name = :emailTempValidateName];
            emailTempValidateId = lstEmailTemplateValidate[0].Id;

            for(User validator : lstSelectedValidators){
                if(!String.isBlank(validator.Email)){
                    lstEmailsToSend.add(validator.Email);
                }
            }
            if(lstEmailsToSend.isEmpty()){
                mapResult.put('Error', 'No email address(es) found for the selected validator(s)');
            }
            else{
                if(lstRequests.size() > 0){
                    Request__c request = lstRequests[0];
                    Id requestId = request.Id;
                    Messaging.SingleEmailMessage m;
                    m = Messaging.renderStoredEmailTemplate(emailTempValidateId, UserInfo.getUserId(), requestId);
                    m.setSaveAsActivity(false);
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    mail.setToAddresses(lstEmailsToSend);
                    mail.setReplyTo(UserInfo.getUserEmail());
                    mail.setSenderDisplayName(UserInfo.getFirstName() + ' ' + UserInfo.getLastName());

                    Id programId = request.Program__c;

                    if(programId != null){
                        Program__c program = [SELECT Id, Macro_L_O_B__c, Name, PrincipalCedingCompany__r.Name, PrincipalCedingCompany__r.EmailPCLife__c
                                              FROM Program__c 
                                              WHERE Id = :programId];

                        strLstCCEmail = program.PrincipalCedingCompany__r.EmailPCLife__c;

                        String strLstCCEmailDisplay = null;

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

                    if(lstCCEmailsToSend.size() > 0){
                        mail.setCcAddresses(lstCCEmailsToSend);
                    }

                    mail.setSubject(m.getSubject());
                    String htmlBody = m.htmlBody;
                    String htmlTreatysListReinsurers = '<br/>';
                    String programName = '';
                    String cedingName = '';
                    if(request.Program__r.Name != null){
                        programName = request.Program__r.Name;
                    }
                    if(request.Program__r.PrincipalCedingCompany__r.Name != null){
                        cedingName = request.Program__r.PrincipalCedingCompany__r.Name;
                    }
                    if(comment == null){
                        comment = '';
                    }

                    String domainURL = URL.getSalesforceBaseUrl().toExternalForm();
                    String htmlInternetLink = '<a href="'+domainURL+'/lightning/page/home">ACTOR New Gen HomePage</a>';
                    String requestLinkStr = '<a href="'+requestLink+'">this link</a>';
                    htmlBody = htmlBody.replace('{InternetLink}', htmlInternetLink);
                    htmlBody = htmlBody.replace('{Request__c.Program__c}', programName);
                    htmlBody = htmlBody.replace('{Request__c.PrincipalCedingCompany__c}', cedingName);
                    htmlBody = htmlBody.replace('{UserName}', UserInfo.getName());
                    htmlBody = htmlBody.replace('{RequestLink}', requestLinkStr);
                    htmlBody = htmlBody.replace('{Comment}', comment);
                    mail.setHtmlBody(htmlBody);
                    lstMailsToSend.add(mail);
                }

                if(lstMailsToSend.size() > 0){
                    Messaging.SendEmailResult[] results = Messaging.sendEmail((List<Messaging.Email>) lstMailsToSend);
                    if (results[0].success) {
                        mapResult.put('Success','Success');
                    } else {
                        mapResult.put('Error', results[0].errors[0].message);
                    }
                }
            }
        }
        catch (Exception ex) {
            mapResult.put('Error',ex.getMessage());
        }       
        return mapResult;
    }

    /**
    * @description Method to share Request with Validators
    * @param List <Request__c> lstRequests
    * @param List <User> lstSelectedValidators
    * @return void
    */
    public static void shareRequestAccounts(List<Request__c> lstRequests, List<User> lstUsers){
        List<Request__Share> lstRequestShare = new List<Request__Share>();
        List<AccountShare> lstAccShare =  new List<AccountShare>();
        Set <Id> setProgramIds = new Set<Id>(); // cater for bulk

        //AMI 31/05/22 : W-0936
        //set users to exclude from sharing of requests
        map <string,set <string>> mapUsersWithAccessToReq = new map <string, set <string>>();

        //AMI 31/05/22 : W-0936
        //query existing request share to exclude new sharing from being if validator already have access
        for(Request__Share reqShare : [select id,ParentId,UserOrGroupId,RowCause,AccessLevel
                                        from Request__Share
                                        where UserOrGroupId IN :lstUsers
                                        and ParentId IN :lstRequests
                                        and (AccessLevel != 'All'
                                        or AccessLevel != 'Edit')]){
                if(mapUsersWithAccessToReq.containsKey(reqShare.UserOrGroupId)){
                    mapUsersWithAccessToReq.get(reqShare.UserOrGroupId).add(reqShare.ParentId);
                }else{
                    mapUsersWithAccessToReq.put(reqShare.UserOrGroupId, new set <string>{reqShare.ParentId});
                }                       
        }
        system.debug('##LWC31_AskForValidation - shareRequestAccounts - mapUsersWithAccessToReq ' + mapUsersWithAccessToReq);

        for(Request__c request : lstRequests){
            setProgramIds.add(request.Program__c);
            for(User user : lstUsers){
                //AMI 31/05/22 : W-0936
                //exclude validators who already have access
                if(!mapUsersWithAccessToReq.containsKey(user.Id) ||
                (
                    mapUsersWithAccessToReq.containsKey(user.Id) &&
                    !mapUsersWithAccessToReq.get(user.Id).contains(request.Id)
                )){
                        Request__Share requestShare = new Request__Share();
                        requestShare.RowCause = 'Manual';
                        requestShare.AccessLevel = 'Edit';
                        requestShare.ParentId = request.Id;
                        requestShare.UserOrGroupId = user.Id;
                        lstRequestShare.add(requestShare);
                }
            }
        }

        for(Program__c program : [SELECT PrincipalCedingCompany__c
                                  FROM Program__c
                                  WHERE Id IN : setProgramIds
                                         ]){
            for(User user : lstUsers){
                //AMI 31/05/22 : W-0936
                //exclude validators who already have access to request from account share
                if(!mapUsersWithAccessToReq.containsKey(user.Id)){
                    AccountShare accountShare = new AccountShare();
                    accountShare.UserOrGroupId = user.Id;
                    accountShare.AccountId = program.PrincipalCedingCompany__c;
                    accountShare.AccountAccessLevel = 'Edit';
                    accountShare.OpportunityAccessLevel = 'Edit';
                    lstAccShare.add(accountShare);
                 }
            }
        }

        if(lstRequestShare.size() > 0){
            insert lstRequestShare;
        }
         if(lstAccShare.size() > 0){
             insert lstAccShare;
         }
    }
}