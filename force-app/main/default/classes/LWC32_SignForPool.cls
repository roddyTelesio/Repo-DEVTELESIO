public with sharing class LWC32_SignForPool {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Class for lwc32SignForPool
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 08-JUN-2020  SAU    1.0     Initial Version
-- 18-AUG-2020  SAU    1.2     Retrieve Written share
-- 01-DEC-2020  NBI    1.3     Allow signature to Deputy CEO
-- 02-APR-2021  MBE    1.4     W-0938 - Mettre en CC la BAL de la PCC
-- 22-APR-2021  MBE    1.5     W-0929 - Transversal - Respond on behalf et pages de réponses réassureur - affichage champs
--------------------------------------------------------------------------------------
**************************************************************************************/

    /**
    * @description Method to send Email for validation to Users
    * @param List <Request__c> lstRequests
    * @param List <User> lstSelectedValidators
    * @param String comment
    * @param String requestLink
    * @return Map<String, Object>
    */
    @AuraEnabled
    public static string getProgramName(Id programId){
        Program__c program = [SELECT Name FROM Program__c WHERE Id =: programId];
        return program.Name;
    }

    @AuraEnabled
    public static Map<String, Object> getDocuments(Id programId) {
        Set<Id> setContentDocumentId = new Set<Id>();
        Map<Id, String> mapDocThemisDateByContentVersionId = new Map<Id, String>();// RRA - ticket 1089 - 0802023
        Map<Id, ContentVersion> mapContentVersionByDocumentId = new Map<Id, ContentVersion>();
        Map<String, Object> mapResults = new Map<String, Object>();

        for (ContentDocumentLink contentDocLink : [SELECT Id, ContentDocumentId
                                                    FROM ContentDocumentLink
                                                    WHERE LinkedEntityId = :programId]){
            setContentDocumentId.add(contentDocLink.ContentDocumentId);
        }
        System.debug('setContentDocumentId =='+ setContentDocumentId);
        
        // RRA - ticket 1089 - 0802023
        List<ContentVersion> lstContentVersion = [
                SELECT Id, ToLabel(Phase__c), Title, ToLabel(GroupType__c), ToLabel(DocumentType__c), DocumentID__c, IsExternal__c, ContentDocumentId, LastModifiedDate, Tech_NumberPhase__c, VersionData, FromThemis__c, Version__c
                FROM ContentVersion
                WHERE ContentDocumentId IN :setContentDocumentId
                AND GroupType__c = '1'
                ORDER BY Tech_NumberPhase__c, LastModifiedDate DESC
        ];

        for(ContentVersion version : lstContentVersion){
            ContentVersion contentVersionMap = new ContentVersion();
            if(mapContentVersionByDocumentId.containsKey(version.ContentDocumentId)){
                contentVersionMap = mapContentVersionByDocumentId.get(version.ContentDocumentId);
                if(Integer.valueOf(version.VersionNumber) > Integer.valueOf(contentVersionMap.VersionNumber)){
                    mapContentVersionByDocumentId.put(version.ContentDocumentId, version);
                }
            }
            else{
                mapContentVersionByDocumentId.put(version.ContentDocumentId, version);
            }
            // RRA - ticket 1089 - 0802023
            if(!mapDocThemisDateByContentVersionId.containsKey(version.Id)){ 
                mapDocThemisDateByContentVersionId.put(version.Id, version.LastModifiedDate.format('YYYY-MM-dd hh:mm:ss'));
                mapDocThemisDateByContentVersionId.put(version.Id, version.LastModifiedDate.format('M/d/YYYY h:mm:ss'));
          }
        }
        
        System.debug('mapContentVersionByDocumentId =='+ mapContentVersionByDocumentId);
        System.debug('mapDocThemisDateByContentVersionId =='+ mapDocThemisDateByContentVersionId);

        List<ContentVersion> lstContentVersions = mapContentVersionByDocumentId.values();
        mapResults.put('mapDocThemisDateByContentVersionId', mapDocThemisDateByContentVersionId);// RRA - ticket 1089 - 0802023
        mapResults.put('lstContentVersion', lstContentVersion);// RRA - ticket 1089 - 0802023
        System.debug('mapResults =='+ mapResults);
        
        return mapResults;
    }

    /**
    * @description Method to get details of Lead requests of Program and Pool
    * @param Id programId
    * @param Id poolId
    * @return Map<String, Object>
    */
    @AuraEnabled
    public static   Map<String, Object> getLeadRequestDetails(Id programId, Id poolId){
        Map<Id, Map<String,Object>> mapResults = new Map<Id, Map<String,Object>>();
        String recordTypeNameLead = AP_Constant.reqRTLead;
        List <String> lstRecordTypeNameLead = recordTypeNameLead.split('-');
        String recordTypeNameSigning = AP_Constant.reqRTSigning;
        List <String> lstRecordTypeNameSigning = recordTypeNameSigning.split('-');
        List<Id> lstTreatyIds = new List <Id>();
        List<Request__c> lstLeadReqs = new List<Request__c>();
        Map<Id, Request__c> mapTreatyIdToSigningReq = new Map<Id, Request__c>();
        Set<Id> setChildRequestId = new Set<Id>();
        List<Request__c> lstRequestAll = new List<Request__c>();

        List<OptionWrapper> lstTreaties = new List<OptionWrapper>();
        List<Request__c> lstRequestBrokers = new List<Request__c>();
        Map<String, Object> mapRequestData = new Map<String, Object>();
        Set<Id> setTreatyId = new Set<Id>();
        Set<Id> setSectionId = new Set<Id>();
        Map<Id, List<Request__c>> mapSectionRequestByTreatyId = new Map<Id, List<Request__c>>();
        Map<String, Id> mapRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectRequest});
        String reqQuoteRecordTypeId = mapRecTypeId.get(AP_Constant.reqRTQuote);
        String reqLeadRecordTypeId = mapRecTypeId.get(AP_Constant.reqRTLead);
        String reqPlacementRecordTypeId = mapRecTypeId.get(AP_Constant.reqRTPlacement);
        List<String> lstRequestFields = AP_Constant.getCreatableFieldsByObjName(AP_Constant.sObjectRequest);
        String strRequestFields = String.join(lstRequestFields , ', ');
        
        Map<Id, Request__c> mapParentRequestByTreatyId = new Map<Id, Request__c>(); //for lead
        List<Request__c> lstParentRequest = new List<Request__c>(); //for lead
        Map<Id, Request__c> mapParentLeadRequestByTreatyId = new Map<Id, Request__c>(); //for placement
        Map<Id,Decimal> mapChildRequestIdToWrittenShare = new Map <Id, Decimal>();

        //get all treaties for pool
        for(PoolTreatySection__c treaty : [ SELECT Treaty__c
                                            FROM PoolTreatySection__c
                                            WHERE Treaty__r.Program__c =: programId
                                            AND Pool__c =: poolId
                                            AND TreatyIsSelected__c = TRUE]){
            lstTreatyIds.add(treaty.Treaty__c );
        }

        //get all lead request of pool
        for(Request__c req : [ SELECT  Id,
                                        Name,
                                        Treaty__c,
                                        Treaty__r.Name,
                                        WrittenShare__c,
                                        SignedShare__c,
                                        ExpectedResponseDate__c,
                                        Accept__c,
                                        Program__c,
                                        Reinsurer__c,
                                        Reinsurer__r.Name,
                                        Broker__c,
                                        Broker__r.Name,
                                        TECH_PhaseType__c,
                                        Program__r.PrincipalCedingCompany__c,
                                        Program__r.UwYear__c,
                                        Program__r.TECH_StageName__c,
                                        Pool__c,
                                        RecordType.DeveloperName, TECH_BrokerName__c, TECH_ReinsurerName__c
                                FROM Request__c
                                WHERE Program__c =: programId
                                AND Treaty__c IN: lstTreatyIds
                                AND LastVersionSent__c = TRUE 
                                AND LastVersionAnswered__c = TRUE
                                AND ( RecordType.DeveloperName =: lstRecordTypeNameLead[1]
                                     OR RecordType.DeveloperName =: lstRecordTypeNameSigning[1] )]){

            if(req.RecordType.DeveloperName ==  lstRecordTypeNameLead[1]){
                lstLeadReqs.add(req);
            }
            else if(req.RecordType.DeveloperName ==  lstRecordTypeNameSigning[1] && req.Pool__c == poolId){ // SR for selected pools
                mapTreatyIdToSigningReq.put(req.Treaty__c, req);
            }
        }

        System.debug('lstLeadReqs = ' + lstLeadReqs);
        System.debug('mapTreatyIdToSigningReq = ' + mapTreatyIdToSigningReq);
                                            
        // for each lead request
        for(Request__c requestById : lstLeadReqs){
            Id reinsurerId = requestById.Reinsurer__c;
            Id brokerId = requestById.Broker__c;
            String requestPhaseType = requestById.TECH_PhaseType__c;
            Id treatyId = requestById.Treaty__c;

            if(requestPhaseType == '3' || requestPhaseType == '4'){

                for(Request__c requestParent : lstLeadReqs){
                    if(requestParent.Reinsurer__c == reinsurerId && requestParent.Broker__c == brokerId ){
                        mapParentRequestByTreatyId.put(requestParent.Treaty__c, requestParent);
                    }
                }
                
                for(LeadRequestSelection__c leadRequestSelection : [SELECT Id, Name, LeadRequestChild__c,LeadRequestParent__r.WrittenShare__c
                                                                FROM LeadRequestSelection__c
                                                                WHERE LeadRequestParent__c IN :lstLeadReqs]){
                    setChildRequestId.add(leadRequestSelection.LeadRequestChild__c);
                    mapChildRequestIdToWrittenShare.put(leadRequestSelection.LeadRequestChild__c,leadRequestSelection.LeadRequestParent__r.WrittenShare__c);
                }
            }
        }
        // RRA - 1074
        String queryLeadRequest = 'select Id, Treaty__r.Name,Treaty__r.Layer__c, Program__r.PrincipalCedingCompany__c, Program__r.UwYear__c, Program__r.TECH_StageName__c'
                    + ', Broker__r.Name, TECH_BrokerName__c, TECH_ReinsurerName__c, Program__r.LTA__c, Section__r.TECH_TypeofTreaty__c, Section__r.QuoteType__c, Section__r.SectionNumber__c'
                    + ', Section__r.Cession_Perc__c, Section__r.Name, Section__r.Currency__c, Section__r.Unlimited__c, Treaty__r.TypeofTreaty__c, Treaty__r.LossDeposit__c,Treaty__r.PlacementShare_Perc__c'
                    + ', Section__r.EventLimit__c, Section__r.RetentionLine__c, Section__r.TAL__c, Section__r.Retention__c, Section__r.CessionAmount__c, Program__r.Name, Program__r.LossDeposit__c, Program__r.InceptionDate__c, Program__r.Expirydate__c'
                    + ', Section__r.RetentionAmount__c, Section__r.TotalEPI__c, Section__r.Nature__c, Section__r.LineAmount__c, Section__r.CededLines__c, Section__r.CededPremium__c'
                    + ', Section__r.Capacity__c, Section__r.Limit__c, Section__r.Deductible__c, Section__r.AAD__c, Section__r.AAL__c, TECH_SectionName__c'
                    + ', Section__r.LimitPercent__c, Section__r.DeductiblePercent__c, Section__r.MaxLimitAmount__c, Section__r.MinLimitAmount__c, Section__r.ExpectedMDP__c, Section__r.ExpectedDP__c, Section__r.ExpectedMP__c, '
                    + strRequestFields
                    + ' from Request__c where (Id IN :setChildRequestId AND Program__c = :programId AND Reinsurer__c = null AND RecordTypeId = :reqLeadRecordTypeId AND (LastVersionSent__c = TRUE AND LastVersionAnswered__c = TRUE) ) ORDER BY Treaty__r.Name';

        lstRequestAll = Database.query(queryLeadRequest);

        Set<Id> setAvailableSectionId = new Set<Id>();

        for(Request__c request : lstRequestAll){
            lstTreaties.add(new OptionWrapper(request.Treaty__r.Name, request.Treaty__c));
            lstRequestBrokers.add(request);
            setTreatyId.add(request.Treaty__c);
            setSectionId.add(request.Section__c);

            List<Request__c> lstSectionRequests = new List<Request__c>();

            if(!setAvailableSectionId.contains(request.Section__c)){
                setAvailableSectionId.add(request.Section__c);
                if(mapSectionRequestByTreatyId.containsKey(request.Treaty__c)){
                    lstSectionRequests = mapSectionRequestByTreatyId.get(request.Treaty__c);
                    lstSectionRequests.add(request);
                }
                else{
                    lstSectionRequests.add(request);
                }
                mapSectionRequestByTreatyId.put(request.Treaty__c, lstSectionRequests);

            }
        }

        Map<Id, String> mapReinstatementBySectionId = new Map<Id, String>();
        List<Reinstatement__c> lstReinstatements = [SELECT Id, Order__c, Percentage__c, toLabel(Prorata__c), Section__c
                                                    FROM Reinstatement__c
                                                    WHERE Section__c IN :setSectionId];

        for(Reinstatement__c reinstatement : lstReinstatements){
            String reinstatementStr = null;
            Decimal percentage = 0;
            String prorata = '';
            if(reinstatement.Percentage__c != null){
                percentage = reinstatement.Percentage__c;
            }
            else{
                percentage = 0;
            }
            if(reinstatement.Prorata__c != null){
                prorata = reinstatement.Prorata__c;
            }
            else{
                prorata = '';
            }
            if(mapReinstatementBySectionId.containsKey(reinstatement.Section__c)){
                reinstatementStr = mapReinstatementBySectionId.get(reinstatement.Section__c);
                reinstatementStr += ' / 1 @ ' + percentage + '% - ' + prorata;
            }
            else{
                reinstatementStr = '1 @ ' + percentage + '% - ' + prorata;
            }
            mapReinstatementBySectionId.put(reinstatement.Section__c, reinstatementStr);
        }

        List<Request__c> lstRequestById = new  List<Request__c> ();
        List<Request__c> lstRequestByDataSigning = new  List<Request__c> ();
        List<String> lstRequestPhaseType = new  List<String> ();
        List<String> lstRequestId = new  List<String> ();

        // RRA - 1074 et 1076
        List<AggregateResult> lstTreatyNonDuplicate = [SELECT Id, Treaty__c treaty, Treaty__r.Name, max(SignedShare__c) signeShare, max (WrittenShare__c)  writtenShare FROM Request__c WHERE program__c=: programId AND LastVersionSent__c = TRUE AND LastVersionAnswered__c = TRUE   AND SignedShare__c!=null AND Pool__c=: poolId AND ( RecordType.DeveloperName =: lstRecordTypeNameLead[1] OR RecordType.DeveloperName =: lstRecordTypeNameSigning[1] ) GROUP BY Id, Treaty__c, Pool__c, Treaty__r.Name ORDER By  Treaty__r.Name ];
        
        for(Request__c requestById : lstLeadReqs){
           // Id treatyID = requestById.Treaty__c;
            //System.debug('treatyID = ' + treatyID);
            //lstRequestId.add(requestById.Id);
            String requestPhaseType = requestById.TECH_PhaseType__c;
            lstRequestPhaseType.add(requestPhaseType);
           // if(mapTreatyIdToSigningReq.containsKey(treatyID)){
                //mapRequestData.put('SigningRequest', mapTreatyIdToSigningReq.get(treatyID));
               // lstRequestByDataSigning.add(mapTreatyIdToSigningReq.get(treatyID));
            //}
        }
       

        for(AggregateResult requestById : lstTreatyNonDuplicate){
            Id treatyID = (String)(requestById.get('treaty'));
            if(mapTreatyIdToSigningReq.containsKey(treatyID)){
                //mapRequestData.put('SigningRequest', mapTreatyIdToSigningReq.get(treatyID));
                lstRequestByDataSigning.add(mapTreatyIdToSigningReq.get(treatyID));
            }
        }
             // RRA - 1074
            mapRequestData.put('SigningRequest', lstRequestByDataSigning);
            mapRequestData.put('requestPhaseType', lstRequestPhaseType); 
            mapRequestData.put('selectedRequestDetail', lstRequestById);
            mapRequestData.put('lstTreaties', lstTreaties);
            mapRequestData.put('mapSectionRequestByTreatyId', mapSectionRequestByTreatyId);
            mapRequestData.put('mapReinstatementBySectionId', mapReinstatementBySectionId);
            mapRequestData.put('lstRequestBrokers', lstRequestBrokers);
            mapRequestData.put('lstRequestAll', lstRequestAll);
            mapRequestData.put('mapParentRequestByTreatyId', mapParentRequestByTreatyId);
            mapRequestData.put('lstParentLeadRequest', lstLeadReqs);
            mapRequestData.put('mapParentLeadRequestByTreatyIdPlacement', mapParentLeadRequestByTreatyId);
            mapRequestData.put('mapChildRequestIdToWrittenShare',mapChildRequestIdToWrittenShare);
            //mapResults.put(requestById.Id, mapRequestData);
            //lstRequestByDataSigning.add(mapResults);
        //}

        //System.debug(' mapResults= ' + mapResults);
       return mapRequestData; 
    }

    /**
    * @description Method to get Signing requests of Program and Pool
    * @param Id programId
    * @param Id poolId
    * @return List <Request__c>
    */
    @AuraEnabled
    public static List <Request__c> getSigningReqDetails(Id poolId, Id programId){
        String recordTypeNameSigning = AP_Constant.reqRTSigning;
        List <String> lstRecordTypeNameSigning = recordTypeNameSigning.split('-');
        //RRA - ticket 1761 - 15112023
        List <Request__c> lstReqDetails = [ SELECT Id,
                                                   ReinsurerStatus__c,
                                                   Broker__c,
                                                   Reinsurer__c,
                                                   TECH_ReinsurerName__c,
                                                   TECH_BrokerName__c,
                                                   ResponseDate__c,
                                                   SigningRegionalManager__c,
                                                   SigningRegionalManager__r.Name,
                                                   TECH_DateSigned__c,
                                                   Pool__r.Name
                                            FROM Request__c
                                            WHERE Pool__c =: poolId
                                            AND Program__c =: programId
                                            AND RecordType.DeveloperName =: lstRecordTypeNameSigning[1]];
        return lstReqDetails;
    }

    /**
    * @description Method to get check if button SFP is visible to User
    * @param List <Request__c> lstSigningReqs
    * @return Boolean
    */
    @AuraEnabled
    public static Boolean getButtonVisibility(List <Request__c> lstSigningReqs){
        Boolean btnVisible = true;
        for(Request__c request : lstSigningReqs){
            if(request.ReinsurerStatus__c == AP_Constant.statusSigned){
                btnVisible = false;
            }
        }
        if(UserInfo.getUserRoleId() != null){
            List <UserRole> userRole = [SELECT DeveloperName
                                    FROM UserRole
                                    WHERE Id =: UserInfo.getUserRoleId()];

            if(userRole[0].DeveloperName != AP_Constant.HeadUGP && userRole[0].DeveloperName != AP_Constant.DeputyCEO){
                btnVisible = false;
            }
        }
        else{
            btnVisible = false;
        }

        return btnVisible;
    }

    /**
    * @description Method to sign Pool and change status for Requests
    * @param List <Request__c> lstSigningReqs
    * @return Map<String, Object>
    */
    @AuraEnabled
    public static Map<String, Object> signPools(List <Request__c> lstSigningReqs){
        Map<String, Object> mapResults = new Map<String, Object>();
        List<String> lstCCEmailsToSend = new List<String>();
        String strLstCCEmail = null;
        String strLstCCEmailDisplay = null;
        List<Id> lstIdRequest = new List<Id>();

        try{
            for(Request__c request : lstSigningReqs){
                request.ReinsurerStatus__c = AP_Constant.statusSigned;
                request.TECH_DateSigned__c = System.today();
                request.ResponseDate__c = System.today();
                request.SigningRegionalManager__c = UserInfo.getUserId();
            }

            update lstSigningReqs;
            String label = 'Signed by ' + UserInfo.getName() + ' on ' + System.today().format();

            //27-01
            EmailTemplate emailTemplateRequestAnswer = [SELECT Id, Name FROM EmailTemplate WHERE Name = :AP_Constant.emailTemplatePoolAnswer];
            List<Messaging.SingleEmailMessage> lstMails = new List<Messaging.SingleEmailMessage>();

            User user = [SELECT Id, ContactId, Email FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            
            //RRA - ticket 1761 - 14112023
            //For AXA SA used as sender email address
            User userAXASA = [SELECT Id, Name, Email FROM User WHERE Id =:System.label.AXA_SA_Sender LIMIT 1];

            Messaging.SingleEmailMessage message;
            message = Messaging.renderStoredEmailTemplate(emailTemplateRequestAnswer.Id, UserInfo.getUserId(), lstSigningReqs[0].Id);
            message.setSaveAsActivity(false);

            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            List<String> sendTo = new List<String>();
            sendTo.add(user.Email);
            mail.setToAddresses(sendTo);
            //RRA - ticket 1761 - 14112023
            OrgWideEmailAddress[] owea = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'actor.po@axa.com'];
            if (owea.size()>0) {
                mail.setOrgWideEmailAddressId(owea.get(0).Id);
            }
            mail.setReplyTo(userAXASA.Email); //RRA - ticket 1761 - 14112023
            String subject = message.getSubject(); //RRA - ticket 1761 - 14112023
            subject = subject.replace('{brokerReinsurerName}', ' '); //RRA - ticket 1761 - 14112023
            mail.setSubject(subject); //RRA - ticket 1761 - 14112023
            //mail.setReplyTo(UserInfo.getUserEmail());
            //mail.setSenderDisplayName(UserInfo.getFirstName() + ' ' + UserInfo.getLastName());

            Id programId = lstSigningReqs[0].Program__c;

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

            if(lstCCEmailsToSend.size() > 0){
                mail.setCcAddresses(lstCCEmailsToSend);
            }

            String htmlBody = message.htmlBody;
            String domainURL = URL.getSalesforceBaseUrl().toExternalForm();
            String htmlInternetLink = '<a href="' + domainURL + '/lightning/page/home">ACTOR NewGen Page</a>';

            htmlBody = htmlBody.replace('{InternetLink}', htmlInternetLink);
            htmlBody = htmlBody.replace('{statusSentChanged}', 'sent');

            if(strLstCCEmailDisplay != null ){
                htmlBody = htmlBody.replace('[Actor Mail box per instance]', strLstCCEmailDisplay);
            }
            else{
                htmlBody = htmlBody.replace('[Actor Mail box per instance]', '');
            }

            mail.setHtmlBody(htmlBody);
            //mail.setSubject(message.getSubject());
            lstMails.add(mail);
            Messaging.sendEmail((List<Messaging.Email>) lstMails);


            mapResults.put('Success', label);
        }
        catch(Exception ex){
            mapResults.put('Error', ex.getMessage());
        }
        return mapResults;
    }

    public class OptionWrapper {
        @AuraEnabled
        public String label {get; set;}
        @AuraEnabled
        public String value {get; set;}

        public OptionWrapper(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }
}