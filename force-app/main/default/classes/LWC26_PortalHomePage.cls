public with sharing class LWC26_PortalHomePage {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Controller for Lightning Web Component lwc26PortalHomePage
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 25-FEB-2019  NBI   1.0      Initial version
-- 27-AUG-2021  MBE   1.1      Remove unused value for mapResult
--------------------------------------------------------------------------------------
**************************************************************************************/

    @future
    @AuraEnabled
    public static void asyncGetRequestsInfo (Id reinsurerId, Boolean isBroker, String uwYear, Id pcc){
        Map<String, Object> mapResults = getRequestsInfo(reinsurerId, isBroker, uwYear, pcc);
    }
    @AuraEnabled
    public static Map<String, Object> getRequestsInfo(Id reinsurerId, Boolean isBroker, String uwYear, Id pcc){
        Map<String, Object> mapResults = new Map<String, Object>();
        List<RequestWrapper> lstRequests = new List<RequestWrapper>();
        List<OptionWrapper> lstReinsurerOptionsAll = new List<OptionWrapper>();
        Id brokerAcc = null;
        Set<Id> setReqIds = new Set<Id>();
        Set<String> setReinsProg = new Set<String>();
        Map<String, List<ReqWrapper>> mapRequests = new Map<String, List<ReqWrapper>>();
        Map<String, String> mapReinsRequests = new Map<String, String>(); //RRA - ticket 1525 - 10072023 
        Map<String, Id> mapRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectRequest}); 
        Map<Id, List<Request__c>> mapProgIdVSRequest = new Map<Id, List<Request__c>>();
        Map<String, List<Request__c>> mapListReqByProgIdReinsurerName = new Map<String, List<Request__c>>();
        Map<Id, Request__c> mapProgLastReq = new Map<Id, Request__c>();
        Map<Id, Request__c> mapProgLastAnsDate = new Map<Id, Request__c>();
        Map<String, String> mapReinNameByReinId = new Map<String, String>();
        Set<Id> setRelatedBroker = new Set<Id>();
        Set<Id> setRelatedReinsurer = new Set<Id>();
        Set<Id> setReinsurerOptionsAllId = new Set<Id>();
        String recordSATypeId = mapRecTypeId.get(AP_Constant.reqRTSA);
        String recordQuoteTypeId = mapRecTypeId.get(AP_Constant.reqRTQuote);
        String recordLeadTypeId = mapRecTypeId.get(AP_Constant.reqRTLead);
        String recordPlacementTypeId = mapRecTypeId.get(AP_Constant.reqRTPlacement);
        String recordSigningTypeId = mapRecTypeId.get(AP_Constant.reqRTSigning);
        List<String> lstIdRecorType = new List <String>{recordQuoteTypeId, recordLeadTypeId, recordPlacementTypeId, recordSigningTypeId};
        Id contactId;
        Contact brokContact;

        if(reinsurerId == null && isBroker == true){
            //broker contact logged in
            //no reinsurer value is selected(picklist) - value = 'All'
            //Nigel => 0052o00000BbcMZAAZ
            // Adeline => 0052o00000BbcM5AAJ
            User usr = [SELECT Id, ContactId FROM User WHERE Id =: UserInfo.getUserId() LIMIT 1];
            contactId = usr.ContactId;
            System.debug('contactId == ' + contactId);
            if(contactId != null){
                brokContact = [SELECT Id, AccountId FROM Contact WHERE Id = :contactId LIMIT 1];

                if(brokContact != null && brokContact.AccountId != null){
                    brokerAcc = brokContact.AccountId;
                    System.debug('brokContact == ' + brokContact);
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
                    System.debug('setRelatedBroker == ' + setRelatedBroker);
                }
            }
            //<> :recordSATypeId
            if (setRelatedBroker != null && !setRelatedBroker.isEmpty()){
                for(Request__c req : [SELECT Id, QuoteType__c,RecordType.DeveloperName, Program__c, Program__r.Name, Reinsurer__r.Name, ReinsurerStatus__c, TECH_ReinsurerName__c, TECH_ProgramName__c, ExpectedResponseDate__c, ResponseDate__c, TECH_LastAnswerDate__c, Program__r.PrincipalCedingCompany__c, Program__r.UwYear__c FROM Request__c WHERE (Broker__c IN :setRelatedBroker OR Reinsurer__c !=NULL) AND Program__r.PrincipalCedingCompany__c = :pcc AND Program__r.UwYear__c = :uwYear AND RecordTypeId IN: lstIdRecorType AND OriginalRequest__c = NULL ORDER BY TECH_ProgramName__c ASC]){ // OR Reinsurer__c !=NULL (to add this condition because a contact can have a reinsurer and also a broker attached with this same reinsurer)
                    setReqIds.add(req.Id);
                    setReinsProg.add(req.TECH_ReinsurerName__c+'---'+req.Program__c+'---'+req.TECH_ProgramName__c+'---'+req.Reinsurer__c+'---'+brokerAcc);// SRA - 1045
    
                    if(req.Reinsurer__c != null){
                        mapReinNameByReinId.put(req.Reinsurer__c, req.TECH_ReinsurerName__c);
                        setReinsurerOptionsAllId.add(req.Reinsurer__c);
                    }
                }
            }

           
            System.debug('setReqIds == ' + setReqIds);
            System.debug('setReinsProg == ' + setReinsProg);

            if(setReqIds.size() > 0){
                for(Request__c req : [SELECT Id, QuoteType__c, RecordType.DeveloperName, Program__c, Program__r.Name, Reinsurer__r.Name, ReinsurerStatus__c, TECH_ReinsurerName__c, TECH_ProgramName__c, ExpectedResponseDate__c, ResponseDate__c, TECH_LastAnswerDate__c FROM Request__c WHERE Id IN :setReqIds AND OriginalRequest__c = NULL ORDER BY TECH_ProgramName__c ASC]){
                        if(mapProgIdVSRequest.containsKey(req.Program__c)){ 
                            List<Request__c> lstReq = (List<Request__c>)mapProgIdVSRequest.get(req.Program__c);
                            lstReq.add(req);
                            mapProgIdVSRequest.put(req.Program__c, lstReq);
                        }
                        else{
                            mapProgIdVSRequest.put(req.Program__c, new List<Request__c>{req});
                        }
    
                        if(mapListReqByProgIdReinsurerName.containsKey(req.Program__c + '-' + req.TECH_ReinsurerName__c)){
                            List<Request__c> lstRequest = (List<Request__c>)mapListReqByProgIdReinsurerName.get(req.Program__c + '-' + req.TECH_ReinsurerName__c);
                            lstRequest.add(req);
                            mapListReqByProgIdReinsurerName.put(req.Program__c + '-' + req.TECH_ReinsurerName__c, lstRequest);
                        }
                        else{
                            mapListReqByProgIdReinsurerName.put(req.Program__c + '-' + req.TECH_ReinsurerName__c, new List<Request__c>{req});
                        }
                }

                System.debug('mapProgIdVSRequest == ' + mapProgIdVSRequest);
                System.debug('mapListReqByProgIdReinsurerName == ' + mapListReqByProgIdReinsurerName);

                for(Request__c req : [SELECT Id, Program__c, TECH_LastSendUpdRemDate__c, ExpectedResponseDate__c , ResponseDate__c, TECH_LastAnswerDate__c, Reinsurer__c FROM Request__c WHERE Id IN :setReqIds AND OriginalRequest__c = NULL ORDER BY TECH_LastSendUpdRemDate__c DESC]){
                    if(!mapProgLastReq.containsKey(req.Program__c)){
                        mapProgLastReq.put(req.Program__c, req);
                    }
                }
                System.debug('mapProgLastReq == ' + mapProgLastReq);
                for(Request__c req : [SELECT Id, Program__c, TECH_LastAnswerDate__c, ResponseDate__c, Reinsurer__c  FROM Request__c WHERE Id IN :setReqIds AND ResponseDate__c <> NULL AND OriginalRequest__c = NULL ORDER BY ResponseDate__c  DESC]){
                    if(!mapProgLastAnsDate.containsKey(req.Program__c)){
                        mapProgLastAnsDate.put(req.Program__c, req);
                    }
                }
                System.debug('mapProgLastAnsDate == ' + mapProgLastAnsDate);
            }
        }
        else if(reinsurerId == null && isBroker == false){
            //reinsurer contact logged in
            //no picklist
            Id reinsAcc;
            User usr = [SELECT Id, ContactId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            contactId = usr.ContactId;

            if(contactId != null){
                Contact reinsContact = [SELECT Id, AccountId FROM Contact WHERE Id = :contactId LIMIT 1];

                if(reinsContact != null && reinsContact.AccountId != null){
                    reinsAcc = reinsContact.AccountId;

                    for(AccountContactRelation relatedContactRelationReinsurer : [SELECT Id, AccountId, Account.RecordTypeId
                                                                                      , Contact.Account.RecordTypeId, Roles
                                                                                      , ContactId, Contact.MacroLoB__c
                                                                                      , Contact.Nature__c, IsDirect
                                                                               FROM AccountContactRelation
                                                                               WHERE ContactId = :contactId
                                                                               AND IsActive = TRUE
                                                                               AND Contact.MacroLoB__c != NULL
                                                                               AND Contact.Nature__c != NULL]){
                        //if(relatedContactRelationReinsurer.Roles == 'RiskCarrier' || relatedContactRelationReinsurer.IsDirect == true){
                            setRelatedReinsurer.add(relatedContactRelationReinsurer.AccountId);
                        //}
                    }

                }
            }
            System.debug('setRelatedReinsurer == '+ setRelatedReinsurer);
            if (setRelatedReinsurer !=null && !setRelatedReinsurer.isEmpty()){
                for(Request__c req : [SELECT Id, QuoteType__c, RecordType.DeveloperName, Program__c, Program__r.Name, Reinsurer__r.Name, ReinsurerStatus__c, TECH_ReinsurerName__c, TECH_ProgramName__c, ExpectedResponseDate__c, ResponseDate__c, TECH_LastAnswerDate__c, Program__r.PrincipalCedingCompany__c, Program__r.UwYear__c, Broker__c FROM Request__c WHERE  Reinsurer__c IN: setRelatedReinsurer AND RecordTypeId IN: lstIdRecorType AND OriginalRequest__c = NULL AND Program__r.PrincipalCedingCompany__c = :pcc AND Program__r.UwYear__c = :uwYear]){ // AND Broker= NULL (to delete because the condition to check isBroker is already verify in line 127)
                    setReqIds.add(req.Id);
                    setReinsProg.add(req.TECH_ReinsurerName__c+'---'+req.Program__c+'---'+req.TECH_ProgramName__c+'---'+req.Reinsurer__c+'---'+brokerAcc); // SRA - 1045
                }
            }
          

            if(setReqIds.size() > 0){
                for(Request__c req : [SELECT Id, QuoteType__c, RecordType.DeveloperName, Program__c, Program__r.Name, Reinsurer__r.Name, ReinsurerStatus__c, TECH_ReinsurerName__c, TECH_ProgramName__c, ExpectedResponseDate__c, ResponseDate__c, TECH_LastAnswerDate__c FROM Request__c WHERE Id IN :setReqIds AND OriginalRequest__c = NULL ORDER BY TECH_ProgramName__c ASC]){
                    if(mapProgIdVSRequest.containsKey(req.Program__c)){
                        List<Request__c> lstReq = (List<Request__c>)mapProgIdVSRequest.get(req.Program__c);
                        lstReq.add(req);
                        mapProgIdVSRequest.put(req.Program__c, lstReq);
                    }
                    else{
                        mapProgIdVSRequest.put(req.Program__c, new List<Request__c>{req});
                    }

                    if(mapListReqByProgIdReinsurerName.containsKey(req.Program__c + '-' + req.TECH_ReinsurerName__c)){
                        List<Request__c> lstRequest = (List<Request__c>)mapListReqByProgIdReinsurerName.get(req.Program__c + '-' + req.TECH_ReinsurerName__c);
                        lstRequest.add(req);
                        mapListReqByProgIdReinsurerName.put(req.Program__c + '-' + req.TECH_ReinsurerName__c, lstRequest);
                    }
                    else{
                        mapListReqByProgIdReinsurerName.put(req.Program__c + '-' + req.TECH_ReinsurerName__c, new List<Request__c>{req});
                    }
                }

                for(Request__c req : [SELECT Id, Program__c, TECH_LastSendUpdRemDate__c, ExpectedResponseDate__c, ResponseDate__c, Reinsurer__c, TECH_LastAnswerDate__c FROM Request__c WHERE Id IN :setReqIds AND OriginalRequest__c = NULL ORDER BY TECH_LastSendUpdRemDate__c DESC]){
                    if(!mapProgLastReq.containsKey(req.Program__c)){
                        mapProgLastReq.put(req.Program__c, req);
                    }
                }

                for(Request__c req : [SELECT Id, Program__c, TECH_LastAnswerDate__c, ResponseDate__c , Reinsurer__c FROM Request__c WHERE Id IN :setReqIds AND ResponseDate__c <> NULL AND OriginalRequest__c = NULL ORDER BY ResponseDate__c DESC]){
                    if(!mapProgLastAnsDate.containsKey(req.Program__c)){
                        mapProgLastAnsDate.put(req.Program__c, req);
                    }
                }
            }
        }
        else if(reinsurerId != null && isBroker == true){
            //broker contact logged in
            //reinsurer value is selected(picklist) - not All
            User usr = [SELECT Id, ContactId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            contactId = usr.ContactId;

            if(contactId != null){
                brokContact = [SELECT Id, AccountId FROM Contact WHERE Id = :contactId LIMIT 1];

                if(brokContact != null && brokContact.AccountId != null){
                    brokerAcc = brokContact.AccountId;

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
                }
            }
            if (setRelatedBroker !=null && !setRelatedBroker.isEmpty()){
                for(Request__c req : [SELECT Id, QuoteType__c, RecordType.DeveloperName, Program__c, Program__r.Name, Reinsurer__r.Name, ReinsurerStatus__c, TECH_ReinsurerName__c, TECH_ProgramName__c, ExpectedResponseDate__c, ResponseDate__c, TECH_LastAnswerDate__c, Program__r.PrincipalCedingCompany__c, Program__r.UwYear__c FROM Request__c WHERE (Broker__c IN :setRelatedBroker OR Reinsurer__c !=NULL) AND Program__r.PrincipalCedingCompany__c = :pcc AND Program__r.UwYear__c = :uwYear AND OriginalRequest__c = NULL AND RecordTypeId IN: lstIdRecorType ORDER BY TECH_ProgramName__c ASC]){ //OR Reinsurer__c !=NULL (to add this condition because a contact can have a reinsurer and also a broker attached with this same reinsurer )
                    if(req.Reinsurer__c == reinsurerId){
                        setReqIds.add(req.Id);
                        setReinsProg.add(req.TECH_ReinsurerName__c+'---'+req.Program__c+'---'+req.TECH_ProgramName__c+'---'+req.Reinsurer__c+'---'+brokerAcc); // SRA - 1045
                    }
    
                    if(req.Reinsurer__c != null){
                        mapReinNameByReinId.put(req.Reinsurer__c, req.TECH_ReinsurerName__c);
                        setReinsurerOptionsAllId.add(req.Reinsurer__c);
                    }
                }
            }
          

            if(setReqIds.size() > 0){

                for(Request__c req : [SELECT Id, QuoteType__c, RecordType.DeveloperName, Program__c, Program__r.Name, Reinsurer__r.Name, ReinsurerStatus__c, TECH_ReinsurerName__c, TECH_ProgramName__c, ExpectedResponseDate__c, ResponseDate__c,TECH_LastAnswerDate__c FROM Request__c WHERE Id IN :setReqIds AND OriginalRequest__c = NULL ORDER BY TECH_ProgramName__c ASC]){
                    if(mapProgIdVSRequest.containsKey(req.Program__c)){
                        List<Request__c> lstReq = (List<Request__c>)mapProgIdVSRequest.get(req.Program__c);
                        lstReq.add(req);
                        mapProgIdVSRequest.put(req.Program__c, lstReq);
                    }
                    else{
                        mapProgIdVSRequest.put(req.Program__c, new List<Request__c>{req});
                    }

                    if(mapListReqByProgIdReinsurerName.containsKey(req.Program__c + '-' + req.TECH_ReinsurerName__c)){
                        List<Request__c> lstRequest = (List<Request__c>)mapListReqByProgIdReinsurerName.get(req.Program__c + '-' + req.TECH_ReinsurerName__c);
                        lstRequest.add(req);
                        mapListReqByProgIdReinsurerName.put(req.Program__c + '-' + req.TECH_ReinsurerName__c, lstRequest);
                    }
                    else{
                        mapListReqByProgIdReinsurerName.put(req.Program__c + '-' + req.TECH_ReinsurerName__c, new List<Request__c>{req});
                    }
                }

                for(Request__c req : [SELECT Id, Program__c, TECH_LastSendUpdRemDate__c, ExpectedResponseDate__c, ResponseDate__c, TECH_LastAnswerDate__c, Reinsurer__c FROM Request__c WHERE Id IN :setReqIds AND OriginalRequest__c = NULL ORDER BY TECH_LastSendUpdRemDate__c DESC]){
                    if(!mapProgLastReq.containsKey(req.Program__c)){
                        mapProgLastReq.put(req.Program__c, req);
                    }
                }

                for(Request__c req : [SELECT Id, Program__c, TECH_LastAnswerDate__c, ResponseDate__c , Reinsurer__c FROM Request__c WHERE Id IN :setReqIds AND ResponseDate__c <> NULL AND OriginalRequest__c = NULL ORDER BY ResponseDate__c DESC]){
                    if(!mapProgLastAnsDate.containsKey(req.Program__c)){
                        mapProgLastAnsDate.put(req.Program__c, req);
                    }
                }
            }
        }

        for(String progId : mapProgIdVSRequest.keySet()){

            for(String name : setReinsProg){
                String[] nameArr = name.split('---');
                mapResults.put(name, nameArr);
                String reinsurerIdString;
                if(isBroker == true){
                    reinsurerIdString = nameArr[3];
                }
                else{
                    reinsurerIdString = null;
                }

                System.debug('reinsurerIdString == '+ reinsurerIdString);

                if(nameArr[1] == progId){
                    System.debug('nameArr[1] == progId == '+ nameArr[1] + '==' + progId);
                    Integer answered = 0;
                    Integer forInfoCount = 0;
                    Integer sumAll = 0;
                    String statusText = '';
                    String statusIcon = '';
                    String classStatusIcon = '';
                    Boolean forInfo = false;
                    Integer reqCount = mapListReqByProgIdReinsurerName.get(progId + '-' + nameArr[0]).size();

                    //RRA -1045 the colors on the round shapes don't display on portal users to check the status of request => add slds-icon  and change the size of icon in _x-small
                    String defaultIcon = 'slds-icon slds-icon-text-default slds-icon_x-small';
                    String errorIcon = 'slds-icon slds-icon-text-error slds-icon_x-small';
                    String successIcon = 'slds-icon slds-icon-text-success slds-icon_x-small';
                    String warningIcon = 'slds-icon slds-icon-text-warning slds-icon_x-small';

                    for(Request__c req : mapListReqByProgIdReinsurerName.get(progId + '-' + nameArr[0])){
                        if(req.RecordType.DeveloperName == 'Quote' && req.QuoteType__c == '2'){
                            forInfo = true;
                            forInfoCount++;
                        }

                        if( (req.ReinsurerStatus__c == 'Answered' || req.ReinsurerStatus__c == 'Refused' || req.ReinsurerStatus__c == 'Signed') && req.ResponseDate__c != null){
                            answered++;
                        }
                    }

                    sumAll = forInfoCount + answered;

                    if(forInfo == true && answered == 0){
                        statusText = 'Not Approached to answer ';
                        statusIcon = defaultIcon;
                        classStatusIcon = defaultIcon;
                    }
                    else if(answered == 0){
                        statusText = 'No requests are answered';
                        statusIcon = errorIcon;
                        classStatusIcon = errorIcon;
                    }
                    else if(answered == reqCount){
                        statusText = 'All requests are answered';
                        statusIcon = successIcon;
                        classStatusIcon = successIcon;
                    }
                    else if(answered > 0 && forInfo == true && sumAll == reqCount){
                        statusText = 'All requests are answered';
                        statusIcon = successIcon;
                        classStatusIcon = successIcon;
                    }
                    else if(answered > 0 && answered < reqCount){
                        statusText = 'Some requests are answered';
                        statusIcon = warningIcon;
                        classStatusIcon = warningIcon;
                    }

                    String expAnswerDate = '';
                    String lastAnswerDate = '';

                    System.debug('mapProgLastReq222 == '+ mapProgLastReq);

                    if(mapProgLastReq.containsKey(progId)){
                        expAnswerDate = String.valueOf(mapProgLastReq.get(progId).ExpectedResponseDate__c);
                    }

                    System.debug('mapProgLastAnsDate222 == '+ mapProgLastAnsDate);

                    if(mapProgLastAnsDate.containsKey(progId)){
                        lastAnswerDate = String.valueOf(mapProgLastAnsDate.get(progId).TECH_LastAnswerDate__c);
                    }

                    System.debug('mapRequests222 == '+ mapRequests);

                    if(mapRequests.containsKey(nameArr[0])){
                        List<ReqWrapper> lstReq = (List<ReqWrapper>)mapRequests.get(nameArr[0]);
                        System.debug('nameArr[0] == '+ nameArr[0]);
                        System.debug('lstReq11 == '+ lstReq);

                        String urll = '/portal/s/summary?c__portal='+ progId+'-'+nameArr[3]+'-'+uwYear+'-'+pcc+'-'+nameArr[4]; // SRA - 1045
                        lstReq.add(new ReqWrapper(nameArr[2], urll, expAnswerDate, lastAnswerDate, statusIcon, classStatusIcon, statusText));

                        System.debug('lstReq22 == '+ lstReq);
                        

                        mapRequests.put(nameArr[0], lstReq);
                        mapReinsRequests.put(nameArr[0], nameArr[3]); //RRA - ticket 1525 - 10072023

                    }
                    else{
                        String urll = '/portal/s/summary?c__portal='+ progId+'-'+nameArr[3]+'-'+uwYear+'-'+pcc+'-'+nameArr[4]; // SRA - 1045
                        mapRequests.put(nameArr[0], new List<ReqWrapper>{new ReqWrapper(nameArr[2], urll, expAnswerDate, lastAnswerDate, statusIcon, classStatusIcon, statusText)}); 
                        mapReinsRequests.put(nameArr[0], nameArr[3]); //RRA - ticket 1525 - 10072023
                        System.debug(' List<ReqWrapper> == '+ new List<ReqWrapper>{new ReqWrapper(nameArr[2], urll, expAnswerDate, lastAnswerDate, statusIcon, classStatusIcon, statusText)});
                    }
                    System.debug('mapRequestsInFOr == '+ mapRequests);
                }
            }
        }
        System.debug('mapRequests == '+ mapRequests);
        if(mapRequests != null){
            for(String key : mapRequests.keySet()){
                lstRequests.add(new RequestWrapper(key, mapRequests.get(key), mapReinsRequests.get(key)));
            }
        }
        System.debug('lstRequests == '+ lstRequests);

        for(Id reinId : setReinsurerOptionsAllId){
            lstReinsurerOptionsAll.add(new OptionWrapper(mapReinNameByReinId.get(reinId), reinId));
        }

        lstReinsurerOptionsAll.sort();
        //setRelatedReinsurer
        mapResults.put('setRelatedReinsurer', setRelatedReinsurer);
        mapResults.put('mapRequests', mapRequests);
        //mapResults.put('mapRequests', mapRequests);
        mapResults.put('setReqIds', setReqIds); 
        mapResults.put('setReinsProg', setReinsProg); 
        //setReinsProg
        mapResults.put('contactId', contactId);
        //mapResults.put('brokContact', brokContact);
        mapResults.put('lstRequests', lstRequests);
        mapResults.put('reinsurerOptionsAll', lstReinsurerOptionsAll); 
        System.debug('mapResults == '+mapResults);

        return mapResults;
    }

    public class OptionWrapper implements Comparable{
        @AuraEnabled public String label {get; set;}
        @AuraEnabled public String value {get; set;}

        public OptionWrapper(String label, String value) {
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

    public class ReqWrapper {
        @AuraEnabled public String programName {get; set;}
        @AuraEnabled public String programUrl {get; set;}
        @AuraEnabled public String expectedAnswerDate {get; set;}
        @AuraEnabled public String lastAnswerDate {get; set;}
        @AuraEnabled public String statusIcon {get; set;}
        @AuraEnabled public String classStatusIcon {get; set;}
        @AuraEnabled public String statusMessage {get; set;}

        public ReqWrapper(String programName, String programUrl, String expectedAnswerDate, String lastAnswerDate, String statusIcon, String classStatusIcon, String statusMessage) {
            this.programName = programName;
            this.programUrl = programUrl;
            this.expectedAnswerDate = expectedAnswerDate;
            this.lastAnswerDate = lastAnswerDate;
            this.statusIcon = statusIcon;
            this.classStatusIcon = classStatusIcon;
            this.statusMessage = statusMessage;
        }
    }

    public class RequestWrapper {
        @AuraEnabled public String reinsurerName {get; set;}
        @AuraEnabled public List<ReqWrapper> lstRequests{get; set;}
        @AuraEnabled public String idReinsurer {get; set;}//RRA - ticket 1525 - 10072023

        public RequestWrapper(String reinsurerName, List<ReqWrapper> lstRequests, String idReinsurer) {//RRA - ticket 1525 - 10072023) {
            this.reinsurerName = reinsurerName;
            this.idReinsurer = idReinsurer;//RRA - ticket 1525 - 10072023
            this.lstRequests = lstRequests;
        }
    }
}