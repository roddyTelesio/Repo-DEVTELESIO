public without sharing class LWC29_AnswerRequests {
    /**************************************************************************************
    -- - Author        : Spoon Consulting
    -- - Description   : Controller for Lightning Web Component lwc29AnswerRequest
    -- Maintenance History:
    --
    -- Date         Name  Version  Remarks
    -- -----------  ----  -------  -------------------------------------------------------
    -- 20-MAR-2020  NBI   1.0      Initial version
    -- 29-MAR-2020  MBE   1.1      Update Child Lead Request - ReinsurerStatus + ResponseDate
    -- 30-MAR-2021  MBE   1.2      W-0903 - ODS - RECEIVEDDATE non alimentée pour les placement requests
    -- 02-APR-2021  MBE   1.3      W-0938 - Mettre en CC la BAL de la PCC
    -- 21-APR-2021  MBE   1.4      W-0926 - Portal - Lead - Champ obligatoire
    -- 22-APR-2021  MBE   1.5      W-0929 - Transversal - Respond on behalf et pages de réponses réassureur - affichage champs
    -- 21-May-2021  MBE   1.6      W-0974 - Bug bloquant Prod - Impossibilité de créer une Lead request - TECH_Actor2Id__c
    -- 27-AUG-2021  MBE   1.7      Remove unused value for mapResult
    -- 04-OCT-2021  MBE   1.8      W-1033 - impossibilité de visualisation des documents en cotation par un broker
    --------------------------------------------------------------------------------------
    **************************************************************************************/
    
        /**
        * @description Method to get request details
        * @param String progId, String reinId, String brokId, String requestPhaseType
        * @return Map<String, Object>
        */

        @AuraEnabled
        public static Map<String, Object> getRequestDetails(String progId, String reinId, String brokId, String requestPhaseType){
            List<Request__c> lstRequestAll = new List<Request__c>();
            List<String> lstRequestFields = AP_Constant.getCreatableFieldsByObjName(AP_Constant.sObjectRequest);
            List<OptionWrapper> lstTreaties = new List<OptionWrapper>();
            List<Request__c> lstRequestBrokers = new List<Request__c>();
            List<Request__c> lstParentLeadRequest = new List<Request__c>(); //for lead
            Set<Id> setTreatyId = new Set<Id>();
            Set<Id> setSectionId = new Set<Id>();
            Map<String, Object> mapResults = new Map<String, Object>();
            Map<Id, List<Request__c>> mapSectionRequestByTreatyId = new Map<Id, List<Request__c>>();
            Map<String, Id> mapRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectRequest});
            Map<Id, Request__c> mapParentRequestByTreatyId = new Map<Id, Request__c>(); //for lead
            Map<Id, Request__c> mapParentLeadRequestByTreatyId = new Map<Id, Request__c>(); //for placement
            String reqQuoteRecordTypeId = mapRecTypeId.get(AP_Constant.reqRTQuote);
            String reqLeadRecordTypeId = mapRecTypeId.get(AP_Constant.reqRTLead);
            String reqPlacementRecordTypeId = mapRecTypeId.get(AP_Constant.reqRTPlacement);
            String strRequestFields = String.join(lstRequestFields , ', ');
            String setupReinsurerStatus = AP_Constant.statusSetup;
            Boolean isBroker = false;
            Set<Id> setRelatedBroker = new Set<Id>();
            String reinsName = '' ;//MRA W-0953 8/09/2022 
            String brokerName = '' ;//MRA W-0953 8/09/2022 
            Boolean isDeactivatedProg = false;//RRA - ticket 0585 - 07122022
    
            try {
                User usr = [SELECT Id, ContactId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
                Id contactId = usr.ContactId;

                if (requestPhaseType == 'Quote'){
                    //Program RRA - ticket 0585 07122022'
                    for (Program__c program : [SELECT Id, isBtnActivatedDeactivated__c FROM Program__c WHERE Id = :progId]){
                        if (program.isBtnActivatedDeactivated__c){
                            isDeactivatedProg = true;
                        }
                    }  

                }

                if(contactId != null){
                    Contact connectedContact = [SELECT Id, AccountId, Account.RecordTypeId FROM Contact WHERE Id = :contactId LIMIT 1];
    
                    if(connectedContact != null && connectedContact.AccountId != null){
                        for(AccountContactRelation relatedContactRelationBroker : [SELECT Id, AccountId, Account.RecordTypeId
                                                                                          , Contact.Account.RecordTypeId, Roles
                                                                                          , ContactId, Contact.MacroLoB__c
                                                                                          , Contact.Nature__c, IsDirect
                                                                                    FROM AccountContactRelation
                                                                                    WHERE ContactId = :contactId
                                                                                    AND IsActive = TRUE
                                                                                    AND Contact.MacroLoB__c != NULL
                                                                                    AND Contact.Nature__c != NULL]){
                            if(relatedContactRelationBroker.Roles == 'Broker' || relatedContactRelationBroker.IsDirect == true){
                                setRelatedBroker.add(relatedContactRelationBroker.AccountId);
                            }
                        }
                    }
                }
    
                // SRA - Ticket 928 - update request quote.
                if(requestPhaseType == 'Quote' || requestPhaseType == 'Lead'){
                    String queryQuoteRequest = 'select Id, Treaty__r.Name, Treaty__r.Layer__c, Program__r.PrincipalCedingCompany__c, Program__r.UwYear__c, Program__r.TECH_StageName__c, Section__r.CededPremium__c, Reinsurer__r.Name'
                            + ', Broker__r.Name, TECH_BrokerName__c, TECH_ReinsurerName__c, Program__r.LTA__c, Program__r.Name, toLabel(Program__r.LossDeposit__c), Program__r.InceptionDate__c, Program__r.Expirydate__c, Section__r.TECH_TypeofTreaty__c, Section__r.QuoteType__c, Section__r.SectionNumber__c'
                            + ', Section__r.Cession_Perc__c, Section__r.Name, Section__r.Currency__c, Section__r.Unlimited__c, Treaty__r.Deductions_Perc__c, Treaty__r.PremiumDeposit__c, Treaty__r.TypeofTreaty__c, toLabel(Treaty__r.LossDeposit__c)'
                            + ', Section__r.EventLimit__c, Section__r.RetentionLine__c, Section__r.TAL__c, Section__r.Retention__c, Section__r.CessionAmount__c, Section__r.TECH_Reinstatement__c, Section__r.Reinstatements__c, ExpectedResponseDate__c, LastSentDate__c'
                            + ', Section__r.RetentionAmount__c, Section__r.TotalEPI__c, Section__r.Nature__c, Section__r.LineAmount__c, Section__r.CededLines__c, TECH_LastAnswerDate__c'
                            + ', Section__r.Capacity__c, Section__r.Limit__c, Section__r.Deductible__c, Section__r.AAD__c, Section__r.AAL__c, ReinsurerStatus__c'
                            + ', Section__r.LimitPercent__c, Section__r.DeductiblePercent__c, Section__r.MaxLimitAmount__c, Section__r.MinLimitAmount__c, Section__r.ExpectedMDP__c, Section__r.ExpectedDP__c, Section__r.ExpectedMP__c, Section__r.CommentsReinsurerBroker__c, '//RRA - ticket 1095 - 01082023
                            + strRequestFields
                            + ' from Request__c where (Program__c = :progId AND Reinsurer__c = :reinId AND RecordTypeId = :reqQuoteRecordTypeId AND (OriginalRequest__c = NULL AND ReinsurerStatus__c != :setupReinsurerStatus)) ';
    
                    // SRA - Ticket 928 - update request lead
                    String queryParentLeadReq = 'select Id, Treaty__r.Name, Treaty__r.Layer__c, Program__r.PrincipalCedingCompany__c, Program__r.UwYear__c, Program__r.TECH_StageName__c, Reinsurer__r.Name'
                            + ', Broker__r.Name, TECH_BrokerName__c, TECH_ReinsurerName__c, Program__r.LTA__c, Section__r.TECH_TypeofTreaty__c, Section__r.QuoteType__c, Section__r.TECH_Reinstatement__c, Section__r.Reinstatements__c, Section__r.SectionNumber__c, Treaty__r.PremiumDeposit__c'
                            + ', Section__r.Cession_Perc__c, Section__r.Name, Section__r.Currency__c, Section__r.Unlimited__c, Treaty__r.TypeofTreaty__c, toLabel(Treaty__r.LossDeposit__c), WrittenShare__c, ReinsurerStatus__c, ExpectedResponseDate__c, LastSentDate__c'
                            + ', Section__r.EventLimit__c, Section__r.RetentionLine__c, Section__r.TAL__c, Section__r.Retention__c, Section__r.CessionAmount__c, Program__r.Name, toLabel(Program__r.LossDeposit__c), Program__r.InceptionDate__c, Program__r.Expirydate__c'
                            + ', Section__r.RetentionAmount__c, Section__r.TotalEPI__c, Section__r.Nature__c, Section__r.LineAmount__c, Section__r.CededLines__c, Section__r.CededPremium__c'
                            + ', Section__r.Capacity__c, Section__r.Limit__c, Section__r.Deductible__c, Section__r.AAD__c, Section__r.AAL__c, TECH_LastAnswerDate__c, Treaty__r.Deductions_Perc__c'
                            + ', Section__r.LimitPercent__c, Section__r.DeductiblePercent__c, Section__r.MaxLimitAmount__c, Section__r.MinLimitAmount__c, Section__r.ExpectedMDP__c, Section__r.ExpectedDP__c, Section__r.ExpectedMP__c, Section__r.CommentsReinsurerBroker__c, '//RRA - ticket 1095 - 01082023
                            + strRequestFields
                            + ' from Request__c where (Program__c = :progId AND Reinsurer__c = :reinId AND RecordTypeId = :reqLeadRecordTypeId AND (OriginalRequest__c = NULL AND ReinsurerStatus__c != :setupReinsurerStatus)) ';
    
                    if(brokId != null && brokId != 'null'){
                        queryParentLeadReq = queryParentLeadReq + ' AND Broker__c IN :setRelatedBroker';
                        queryQuoteRequest = queryQuoteRequest + ' AND Broker__c IN :setRelatedBroker';
                    }
                    else{
                        queryParentLeadReq = queryParentLeadReq + ' AND Broker__c = NULL';
                        queryQuoteRequest = queryQuoteRequest + ' AND Broker__c = NULL';
                    }
    
                    lstParentLeadRequest = Database.query(queryParentLeadReq);
                    Set<Id> setParentLeadRequestId = new Set<Id>();
    
                    for(Request__c requestParent : lstParentLeadRequest){
                        mapParentRequestByTreatyId.put(requestParent.Treaty__c, requestParent);
                        setParentLeadRequestId.add(requestParent.Id);
                    }
    
                    Set<Id> setChildRequestId = new Set<Id>();
                    for(LeadRequestSelection__c leadRequestSelection : [SELECT Id, Name, LeadRequestChild__c
                                                                        FROM LeadRequestSelection__c
                                                                        WHERE LeadRequestParent__c IN :setParentLeadRequestId]){
                        setChildRequestId.add(leadRequestSelection.LeadRequestChild__c);
                    }
    
                    String queryChildLeadRequest = 'select Id, Treaty__r.Name, Treaty__r.Layer__c, Program__r.PrincipalCedingCompany__c, Program__r.UwYear__c, Program__r.TECH_StageName__c, Reinsurer__r.Name'
                            + ', Broker__r.Name, TECH_BrokerName__c, TECH_ReinsurerName__c, Program__r.LTA__c, Section__r.TECH_TypeofTreaty__c, Section__r.QuoteType__c, Section__r.TECH_Reinstatement__c, Section__r.Reinstatements__c, Section__r.SectionNumber__c'
                            + ', Section__r.Cession_Perc__c, Section__r.Name, Section__r.Currency__c, Section__r.Unlimited__c, Treaty__r.TypeofTreaty__c, toLabel(Treaty__r.LossDeposit__c), WrittenShare__c, ReinsurerStatus__c'
                            + ', Section__r.EventLimit__c, Section__r.RetentionLine__c, Section__r.TAL__c, Section__r.Retention__c, Section__r.CessionAmount__c, Program__r.Name, toLabel(Program__r.LossDeposit__c), Program__r.InceptionDate__c, Program__r.Expirydate__c, Treaty__r.Deductions_Perc__c, Treaty__r.PremiumDeposit__c'
                            + ', Section__r.RetentionAmount__c, Section__r.TotalEPI__c, Section__r.Nature__c, Section__r.LineAmount__c, Section__r.CededLines__c, Section__r.CededPremium__c, ExpectedResponseDate__c'
                            + ', Section__r.Capacity__c, Section__r.Limit__c, Section__r.Deductible__c, Section__r.AAD__c, Section__r.AAL__c, TECH_LastAnswerDate__c, LastSentDate__c '
                            + ', Section__r.LimitPercent__c, Section__r.DeductiblePercent__c, Section__r.MaxLimitAmount__c, Section__r.MinLimitAmount__c, Section__r.ExpectedMDP__c, Section__r.ExpectedDP__c, Section__r.ExpectedMP__c, Section__r.CommentsReinsurerBroker__c, '//RRA - ticket 1095 - 01082023
                            + strRequestFields
                            + ' from Request__c where (Id IN :setChildRequestId AND Program__c = :progId AND Reinsurer__c = null AND RecordTypeId = :reqLeadRecordTypeId) ';
    
                    if(requestPhaseType == 'Quote'){
                        //phase type = 'Quote'
                        lstRequestAll = Database.query(queryQuoteRequest);
                    }
                    else if(requestPhaseType == 'Lead'){
                        //phase type = 'Lead'
                        if(lstParentLeadRequest.size()>0){
                        reinsName = lstParentLeadRequest[0].TECH_ReinsurerName__c ;//MRA W-0953 8/09/2022 
                        brokerName = lstParentLeadRequest[0].TECH_BrokerName__c!=null?lstParentLeadRequest[0].TECH_BrokerName__c:null ;//MRA W-0953 8/09/2022 
                    }
                        lstRequestAll = Database.query(queryChildLeadRequest);
                    }
                }
    
                else if(requestPhaseType == 'Placement'){
                    Set<Id> setPlacementTreatyId = new Set<Id>();
                    String brokerId = null;
    
                    if(brokId != null && brokId != 'null'){
                        brokerId = brokId;
                    }
    
                    // SRA - Ticket 928 - update request placement.
                    //get all Placement Request for connected user(broker/reinsurer)
                    String queryPlacementReq = 'select Id, Treaty__r.Name, Treaty__r.Layer__c, Program__r.PrincipalCedingCompany__c, Program__r.UwYear__c, Program__r.TECH_StageName__c, Section__r.CededPremium__c, Section__r.TECH_Reinstatement__c, Section__r.Reinstatements__c, Section__r.SectionNumber__c'
                            + ', Broker__r.Name, TECH_BrokerName__c, TECH_ReinsurerName__c, Program__r.LTA__c, Program__r.Name, toLabel(Program__r.LossDeposit__c), Program__r.InceptionDate__c, Program__r.Expirydate__c, Section__r.TECH_TypeofTreaty__c, Section__r.QuoteType__c, Reinsurer__r.Name'
                            + ', Section__r.Cession_Perc__c, Section__r.Name, Section__r.Currency__c, Section__r.Unlimited__c, Treaty__r.Deductions_Perc__c, Treaty__r.PremiumDeposit__c, Treaty__r.TypeofTreaty__c, toLabel(Treaty__r.LossDeposit__c)'
                            + ', Section__r.EventLimit__c, Section__r.RetentionLine__c, Section__r.TAL__c, Section__r.Retention__c, Section__r.CessionAmount__c, WrittenShare__c, ReinsurerStatus__c'
                            + ', Section__r.RetentionAmount__c, Section__r.TotalEPI__c, Section__r.Nature__c, Section__r.LineAmount__c, Section__r.CededLines__c, ExpectedResponseDate__c, LastSentDate__c '
                            + ', Section__r.Capacity__c, Section__r.Limit__c, Section__r.Deductible__c, Section__r.AAD__c, Section__r.AAL__c, TECH_LastAnswerDate__c'
                            + ', Section__r.LimitPercent__c, Section__r.DeductiblePercent__c, Section__r.MaxLimitAmount__c, Section__r.MinLimitAmount__c, Section__r.ExpectedMDP__c, Section__r.ExpectedDP__c, Section__r.ExpectedMP__c, Section__r.CommentsReinsurerBroker__c, '//RRA - ticket 1095 - 01082023
                            + strRequestFields
                            + ' from Request__c where (Program__c = :progId AND RecordTypeId = :reqPlacementRecordTypeId AND Reinsurer__c = :reinId AND (OriginalRequest__c = NULL AND ReinsurerStatus__c != :setupReinsurerStatus)) ';
    
                    if(brokId != null && brokId != 'null'){
                        queryPlacementReq = queryPlacementReq + ' AND Broker__c IN :setRelatedBroker';
                    }
                    else{
                        queryPlacementReq = queryPlacementReq + ' AND Broker__c = NULL';
                    }
    
                    List<Request__c> lstPlacementRequest = Database.query(queryPlacementReq);
                    if(lstPlacementRequest.size()>0){
                        reinsName = lstPlacementRequest[0].TECH_ReinsurerName__c ;//MRA W-0953 8/09/2022 
                        brokerName = lstPlacementRequest[0].TECH_BrokerName__c!=null?lstPlacementRequest[0].TECH_BrokerName__c:null ;//MRA W-0953 8/09/2022 
                    }
                    //get all Treaties for Placement
                    for(Request__c placementRequest : lstPlacementRequest){
                        setPlacementTreatyId.add(placementRequest.Treaty__c);
                        mapParentRequestByTreatyId.put(placementRequest.Treaty__c, placementRequest);
                    }
    
                    //get all Parent Lead Request where it has same treaties as Placemennt
                    List<Request__c> lstParentLeadRequests = [SELECT Id, Name, Treaty__c, Treaty__r.Layer__c, LastModifiedDate, ReinsurerStatus__c, TECH_LastAnswerDate__c, ResponseDate__c, Reinsurer__c, Broker__c, RecordType.Name, Section__r.SectionNumber__c, OriginalRequest__c
                                                            FROM Request__c
                                                            WHERE Treaty__c IN :setPlacementTreatyId AND RecordTypeId = :reqLeadRecordTypeId AND Reinsurer__c != NULL AND OriginalRequest__c = NULL];
    
                    // Map latest Parent Lead Request by Treaty Id
                    Set<Id> setParentLeadRequestId = new Set<Id>();
    
                    for(Request__c parentLeadRequest : lstParentLeadRequests){
                        Request__c latestParentLeadRequest = new Request__c();
                        if(mapParentLeadRequestByTreatyId.containsKey(parentLeadRequest.Treaty__c)){
                            Request__c prevParentLeadRequest = mapParentLeadRequestByTreatyId.get(parentLeadRequest.Treaty__c);
                            if(parentLeadRequest.LastModifiedDate > prevParentLeadRequest.LastModifiedDate){
                                parentLeadRequest.ReinsurerStatus__c = prevParentLeadRequest.ReinsurerStatus__c;
                                latestParentLeadRequest = parentLeadRequest;
                            }
                            else{
                                latestParentLeadRequest = prevParentLeadRequest;
                            }
                            mapParentLeadRequestByTreatyId.put(parentLeadRequest.Treaty__c, latestParentLeadRequest);
                            setParentLeadRequestId.add(latestParentLeadRequest.Id);
                        }
                        else{
                            mapParentLeadRequestByTreatyId.put(parentLeadRequest.Treaty__c, parentLeadRequest);
                            setParentLeadRequestId.add(parentLeadRequest.Id);
                        }
                    }
    
                    //get all child Lead Request from LeadRequestSelection__c
                    Set<Id> setChildLeadRequestId = new Set<Id>();
    
                    for(LeadRequestSelection__c leadRequestSelection : [SELECT Id, Name, LeadRequestChild__c
                                                                        FROM LeadRequestSelection__c
                                                                        WHERE LeadRequestParent__c IN :setParentLeadRequestId]){
                        setChildLeadRequestId.add(leadRequestSelection.LeadRequestChild__c);
                    }
    
                    String queryChildLeadRequestforPlacement = 'select Id, Treaty__r.Name, Treaty__r.Layer__c, Program__r.PrincipalCedingCompany__c, Program__r.UwYear__c, Program__r.TECH_StageName__c, Section__r.TECH_Reinstatement__c, Section__r.Reinstatements__c, Section__r.SectionNumber__c, Reinsurer__r.Name'
                            + ', Broker__r.Name, TECH_BrokerName__c, TECH_ReinsurerName__c, Program__r.LTA__c, Section__r.TECH_TypeofTreaty__c, Section__r.QuoteType__c, Treaty__r.Deductions_Perc__c'
                            + ', Section__r.Cession_Perc__c, Section__r.Name, Section__r.Currency__c, Section__r.Unlimited__c, Treaty__r.TypeofTreaty__c, toLabel(Treaty__r.LossDeposit__c)'
                            + ', Section__r.EventLimit__c, Section__r.RetentionLine__c, Section__r.TAL__c, Section__r.Retention__c, Section__r.CessionAmount__c,  Program__r.Name, toLabel(Program__r.LossDeposit__c), Program__r.InceptionDate__c, Program__r.Expirydate__c, Treaty__r.PremiumDeposit__c'
                            + ', Section__r.RetentionAmount__c, Section__r.TotalEPI__c, Section__r.Nature__c, Section__r.LineAmount__c, Section__r.CededLines__c, Section__r.CededPremium__c'
                            + ', Section__r.Capacity__c, Section__r.Limit__c, Section__r.Deductible__c, Section__r.AAD__c, Section__r.AAL__c, TECH_LastAnswerDate__c, LastSentDate__c'
                            + ', Section__r.LimitPercent__c, Section__r.DeductiblePercent__c, Section__r.MaxLimitAmount__c, Section__r.MinLimitAmount__c, Section__r.ExpectedMDP__c, Section__r.ExpectedDP__c, Section__r.ExpectedMP__c, Section__r.CommentsReinsurerBroker__c, '//RRA - ticket 1095 - 01082023
                            + strRequestFields
                            + ' from Request__c where (Id IN :setChildLeadRequestId AND Program__c = :progId AND Reinsurer__c = null AND RecordTypeId = :reqLeadRecordTypeId) ';
    
                    lstRequestAll = Database.query(queryChildLeadRequestforPlacement);
                }
    
                for(Request__c request : lstRequestAll){
                    lstTreaties.add(new OptionWrapper(request.Treaty__r.Name, request.Treaty__c));
                    lstRequestBrokers.add(request);
                    setTreatyId.add(request.Treaty__c);
                    setSectionId.add(request.Section__c);
                    List<Request__c> lstSectionRequests = new List<Request__c>();
    
                    if(mapSectionRequestByTreatyId.containsKey(request.Treaty__c)){
                        lstSectionRequests = mapSectionRequestByTreatyId.get(request.Treaty__c);
                        lstSectionRequests.add(request);
                    }
                    else{
                        lstSectionRequests.add(request);
                    }
                    mapSectionRequestByTreatyId.put(request.Treaty__c, lstSectionRequests);
                }
    
                mapResults.put('lstTreaties', lstTreaties);
                mapResults.put('mapSectionRequestByTreatyId', mapSectionRequestByTreatyId);
                mapResults.put('lstRequestAll', lstRequestAll);
                mapResults.put('requestPhaseType', requestPhaseType);
                mapResults.put('mapParentRequestByTreatyId', mapParentRequestByTreatyId);
                mapResults.put('lstParentLeadRequest', lstParentLeadRequest);
                mapResults.put('reinsName', reinsName);//MRA W-0953 8/09/2022 
                mapResults.put('brokerName', brokerName);//MRA W-0953 8/09/2022 
                mapResults.put('isDeactivatedProg', isDeactivatedProg); //RRA - ticket 585 - 07032023
            }
            catch (Exception ex) {
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
    
        /**
        * @description Method to save Request
        * @param List<Request__c> lstRequest, String phaseType, List<Request__c> lstParentRequest, String btnName
        * @return Map<String, Object>
        * RRA - 1054
        */
        @AuraEnabled
        public static Map<String, Object> saveRequestRecord(List<Request__c> lstRequest, String phaseType, List<Request__c> lstParentRequest, String btnName, Date quotedeadline, Boolean isChangedDateQuote, Id idRequestSelected, Boolean isPortalAccess) { //RRA - ticket 1541 - 06072023 and RRA - ticket 1574 - 06102023 
            System.debug('idRequestSelected == ' + idRequestSelected);
            System.debug('isChangedDateQuote == ' + isChangedDateQuote);
            Boolean isDateQuoteValChanged = false;
            Map<String, Object> mapResults = new Map<String, Object>();
            Set<Id> setParentLeadId = new Set<Id>();
            Set<Id> setAllAnsweredLeadId = new Set<Id>();
            Set<Id> setAllParentLeadId = new Set<Id>();
            Set<String> setAnsweredParentQuote = new Set<String>();
            Set<String> setAnsweredParentLeadId = new Set<String>();
            Set<String> setAnsweredParentPlacement = new Set<String>();
            Set<String> setAnsweredChildLead = new Set<String>();
            Set<Id> setProgramId = new Set<Id>();
            Set<Id> setReinsurerId = new Set<Id>();
            Set<Id> setBrokerId = new Set<Id>();
            List<Id> setDocumentVisibilityId= new List<Id>();
            List<DocumentVisibility__c> lstDocumentVisibility = new List<DocumentVisibility__c>();
            List<Request__c> lstChildLeadRequest;
            List<DocumentVisibility__c> lstDocVis;
            List<DocumentVisibility__c> lstDocVisBroReins;
            List<DocumentVisibility__c> lstDocVisReins;
            List<Id> lstIdReqOrig = new List<Id>(); //RRA - ticket 1541 - 05072023
            List<Id> lstIdReqLast = new List<Id>(); //RRA - ticket 1541 - 05072023
            List<Request__c> lstRequestUpdatedLastVers = new List <Request__c>(); //RRA - ticket 1541 - 05072023
            List<Request__c> lstRequestUpdatedOrig = new List <Request__c>(); //RRA - ticket 1541 - 05072023
            List<Request__c> lstRequestUpdatedLastVersFromSaveAll = new List <Request__c>(); //RRA - ticket 1541 - 05072023
            String str;
            Date dateQuoteValidity; //RRA - ticket 1574 - 24102023
            List<Request__c> lstReqUpdateFlagReminder = new List<Request__c>();//RRA - ticket 1574 - 24102023
            
            //RRA - 939
            Map<String, Request__c> mapKeyExistRequest = new Map<String, Request__c>();
            Savepoint sp = Database.setSavepoint();
            Boolean isCheck  = false;
            try {
                
                if (isChangedDateQuote == null){
                    isDateQuoteValChanged = false;
                }else if(isChangedDateQuote){
                    isDateQuoteValChanged = true;
                }else if(isChangedDateQuote == false){
                    isDateQuoteValChanged = false;
                }
                
                if(phaseType == 'Quote'){
                    for(Request__c req : lstRequest){
                        setProgramId.add(req.Program__c);
                        setBrokerId.add(req.Broker__c);
                        setReinsurerId.add(req.Reinsurer__c);
                        }
                }else if (phaseType == 'Lead' || phaseType == 'Placement'){
                    for(Request__c req : lstParentRequest){
                        setProgramId.add(req.Program__c);
                        setBrokerId.add(req.Broker__c);
                        setReinsurerId.add(req.Reinsurer__c);
                    }
                }
    
    
                lstDocVis = [SELECT Id, Tech_BrokerId__c, Tech_Request_Status__c, Tech_Phase__c, Tech_LabelPhase__c, Tech_ReinsurerId__c, Program__c, Tech_IsExternal__c FROM DocumentVisibility__c WHERE Program__c IN:setProgramId AND Tech_IsExternal__c = true];
    
                String query = 'SELECT Id, Tech_BrokerId__c, Tech_Request_Status__c, Tech_Phase__c, Tech_LabelPhase__c, Tech_ReinsurerId__c, Program__c, Tech_IsExternal__c FROM DocumentVisibility__c WHERE Program__c =:setProgramId AND Tech_IsExternal__c = true AND Tech_LabelPhase__c =:phaseType';
    
                if (!setBrokerId.contains(null) && !setReinsurerId.contains(null)){
                    query = query + ' AND Tech_BrokerId__c IN:setBrokerId AND Tech_ReinsurerId__c IN: setReinsurerId';
                }else if (setBrokerId.contains(null) && !setReinsurerId.contains(null)){
                    query = query + ' AND Tech_BrokerId__c = null AND Tech_ReinsurerId__c IN: setReinsurerId';
                }
                lstDocVisBroReins = Database.query(query);
                lstDocVisReins = Database.query(query);
    
    
                System.debug('lstDocVisBroReins = ' + lstDocVisBroReins);
                System.debug('lstDocVisReins = ' + lstDocVisReins);
    
                // SAU change status and dates only when send is clicked -- 19/08/2020
                if(btnName == 'Send'){
                    for(Request__c req : lstRequest){
                         //RRA - ticket 1541 - 04072023 - Update lastVersion Req
                        if(phaseType == 'Quote'){
                            req.QuoteDeadline__c = quotedeadline;
                            req.isChk2DaysEmailReminder__c = isDateQuoteValChanged; //RRA - ticket 1574 - 24102023
                            lstIdReqOrig.add(req.OriginalRequest__c);
                            lstRequestUpdatedLastVers.add(req);
                        }
                        if (req.ReinsurerStatus__c != AP_Constant.statusSetup && req.ReinsurerStatus__c != AP_Constant.statusTimeout) {
                                //for(DocumentVisibility__c docVis : lstDocVis){
                                    /* if Phase Type is Quote
                                   if Quote__c == 'Quote' -> Reinsurer Status = 'Answered'
                                   if Quote__c == 'Refusal' -> Reinsurer Status = 'Refused'
                                */
                                if(phaseType == 'Quote'){
                                    req.ResponseDate__c = System.today();
                                    req.TECH_LastAnswerDate__c = System.today();
                                    if (req.Quote__c == '1') {
                                       // req.ReinsurerStatus__c = AP_Constant.statusAnswered;
                                    }
                                    else if (req.Quote__c == '2') {
                                        req.ReinsurerStatus__c = AP_Constant.statusRefused;
                                        
                                        //RRA - ticket 1369 - 22022023 - initialize to null value of Quotation id ReinsurerStatus is refused
                                        req.ReinsurerExpenses__c = null;
                                        req.LossCarryingForward__c = null;
                                        req.OrUnlimited__c = false;
                                        req.LossCorridorPart__c = null;
                                        req.LossCorridorMaxLR__c = null;
                                        req.LossCorridorMinLR__c = null;
                                        req.NoClaimBonus__c =null;
                                        req.NoClaimBonusAmount__c = null; 
                                        req.ProfitCommission__c = null;
                                        req.WrittenShareResponse__c = null;
                                        req.WrittenShare__c = null;
                                        req.FixedCommission__c = null;
                                        req.FixedRate__c = null;
                                        req.MinRate__c = null;
                                        req.MaxRate__c = null;
                                        req.ProvisionalRate__c = null;
                                        req.FlatPremium__c = null;
                                        req.MDP__c = null;
                                        req.MinVarCommission__c = null;
                                        req.MaxVarCommission__c = null;
                                        req.ProvisionalCommission__c = null;
                                        req.PerHeadPremium__c = null;
                                        req.MinPerHeadAmount__c = null;
                                        req.MaxPerHeadAmount__c = null;
                                        req.ProvisionalPerHeadPremium__c = null;
                                        req.EstimatedReinsurancePremium__c = null;
                                        req.EstimatedInsurancePremium__c = null;
                                    }
                                    setAnsweredParentQuote.add(req.ReinsurerStatus__c);
                                    if (String.isNotBlank(req.CommentsResponse__c) || req.CommentsResponse__c != null){
                                        req.Utility_Icon_Comment__c = AP_Constant.iconComment; //RRA - 939
                                        
                                    }
    
                                    if (String.isBlank(req.CommentsResponse__c) || req.CommentsResponse__c == null){
                                        req.Utility_Icon_Comment__c = null; //RRA - 939
                                        
                                    }
                                    
                                    //RRA - ticket 1541 - 05072023
                                    if (req.QuoteDeadline__c != null){
                                        req.UtilityIconDate__c = AP_Constant.iconDate; 
                                        
                                    }else{
                                        req.UtilityIconDate__c = null; 
                                    }
    
                                    mapKeyExistRequest.put(req.Broker__c + '_'+ req.Reinsurer__c + '_'+ req.Program__c, req);
    
                                    // RRA - 939 delete icon attach and comment if document visibility don't exists
                                    if (lstDocVisBroReins.size() == 0){
                                        req.Utility_Icon_Attachment__c= ''; //RRA - 939
                                    }
                                    if (lstDocVisReins.size() == 0){
                                        req.Utility_Icon_Attachment__c= ''; //RRA - 939
                                    }
                                   
                                }
            
                                /* if Phase Type is Lead
                                   if checkbox Accept__c == 'True' -> Reinsurer Status = 'Answered'
                                */
                                if (phaseType == 'Lead') {
                                    if (req.Accept__c == true) {
                                        req.ResponseDate__c = System.today();
                                        req.TECH_LastAnswerDate__c = System.today();
                                        req.ReinsurerStatus__c = AP_Constant.statusAnswered;
                                        setAllAnsweredLeadId.add(req.Id);
                                        setAnsweredParentLeadId.add(req.ReinsurerStatus__c);
                                    }
                                    if (String.isNotBlank(req.CommentsResponse__c) || req.CommentsResponse__c != null){
                                        req.Utility_Icon_Comment__c = AP_Constant.iconComment; //RRA - 939
                                    }
    
                                    if (String.isBlank(req.CommentsResponse__c) || req.CommentsResponse__c == null){
                                        req.Utility_Icon_Comment__c = null; //RRA - 939
                                    }
    
                                    // RRA - 939 delete icon attach and comment if document visibility don't exists
                                    if (lstDocVisBroReins.size() == 0){
                                        req.Utility_Icon_Attachment__c= ''; //RRA - 939
                                    }
                                    if (lstDocVisReins.size() == 0){
                                        req.Utility_Icon_Attachment__c= ''; //RRA - 939
                                    }
    
                                    mapKeyExistRequest.put(req.Broker__c + '_'+ req.Reinsurer__c + '_'+ req.Program__c, req);
                                }
                            //}
                        }
                    }
                    
                                            
                                  
                    //RRA - ticket 1541 - 04072023 - Update Original Req - RRA 1574
                    for (Request__c  request : [SELECT Id, OriginalRequest__c, QuoteDeadline__c FROM Request__c WHERE Id IN:lstIdReqOrig]){
                        if (request.OriginalRequest__c == null){
                            request.QuoteDeadline__c = quotedeadline;
                            request.isChk2DaysEmailReminder__c = isDateQuoteValChanged; //RRA - ticket 1574 - 24102023
                            lstRequestUpdatedOrig.add(request);
                        }
                    }
                    
                    
                    for(Request__c req : lstParentRequest){
                            if(req.ReinsurerStatus__c != AP_Constant.statusSetup && req.ReinsurerStatus__c != AP_Constant.statusTimeout) {
                                    /* if Phase Type is Quote
                                if Quote__c == 'Quote' -> Reinsurer Status = 'Answered'
                                if Quote__c == 'Refusal' -> Reinsurer Status = 'Refused'
                                */
                                if(phaseType == 'Quote'){
                                    req.ResponseDate__c = System.today();
                                    req.TECH_LastAnswerDate__c = System.today();
                                    if (req.Quote__c == '1') {
                                        req.ReinsurerStatus__c = AP_Constant.statusAnswered;
                                    }
                                    else if (req.Quote__c == '2') {
                                        req.ReinsurerStatus__c = AP_Constant.statusRefused;
                                        
                                        //RRA - ticket 1369 - 22022023 - initialize to null value of Quotation id ReinsurerStatus is refused
                                        req.ReinsurerExpenses__c = null;
                                        req.LossCarryingForward__c = null;
                                        req.OrUnlimited__c = false;
                                        req.LossCorridorPart__c = null;
                                        req.LossCorridorMaxLR__c = null;
                                        req.LossCorridorMinLR__c = null;
                                        req.NoClaimBonus__c =null;
                                        req.NoClaimBonusAmount__c = null; 
                                        req.ProfitCommission__c = null;
                                        req.WrittenShareResponse__c = null;
                                        req.WrittenShare__c = null;
                                        req.FixedCommission__c = null;
                                        req.FixedRate__c = null;
                                        req.MinRate__c = null;
                                        req.MaxRate__c = null;
                                        req.ProvisionalRate__c = null;
                                        req.FlatPremium__c = null;
                                        req.MDP__c = null;
                                        req.MinVarCommission__c = null;
                                        req.MaxVarCommission__c = null;
                                        req.ProvisionalCommission__c = null;
                                        req.PerHeadPremium__c = null;
                                        req.MinPerHeadAmount__c = null;
                                        req.MaxPerHeadAmount__c = null;
                                        req.ProvisionalPerHeadPremium__c = null;
                                        req.EstimatedReinsurancePremium__c = null;
                                        req.EstimatedInsurancePremium__c = null;
                                    }
                                    setAnsweredParentQuote.add(req.ReinsurerStatus__c);
    
                                    if (String.isNotBlank(req.CommentsResponse__c) || req.CommentsResponse__c != null){
                                        req.Utility_Icon_Comment__c = AP_Constant.iconComment; //RRA - 939
                                    }
    
                                    if (String.isBlank(req.CommentsResponse__c) || req.CommentsResponse__c == null){
                                        req.Utility_Icon_Comment__c = null; //RRA - 939
                                    }
                                    
                                    //RRA - ticket 1541 - 05072023
                                    if (req.QuoteDeadline__c != null){
                                        req.UtilityIconDate__c = AP_Constant.iconDate; 
                                        
                                    }else{
                                        req.UtilityIconDate__c = null; 
                                    }
    
                                    // RRA - 939 delete icon attach and comment if document visibility don't exists
                                    if (lstDocVisBroReins.size() == 0){
                                        req.Utility_Icon_Attachment__c= ''; //RRA - 939
                                    }
                                    if (lstDocVisReins.size() == 0){
                                        req.Utility_Icon_Attachment__c= ''; //RRA - 939
                                    }
    
                                    mapKeyExistRequest.put(req.Broker__c + '_'+ req.Reinsurer__c + '_'+ req.Program__c, req);
                                }
            
                                /* if Phase Type is Lead
                                if checkbox Accept__c == 'True' -> Reinsurer Status = 'Answered'
                                */
                                if (phaseType == 'Lead') {
                                    if (req.Accept__c == true) {
                                        req.ResponseDate__c = System.today();
                                        req.TECH_LastAnswerDate__c = System.today();
                                        req.ReinsurerStatus__c = AP_Constant.statusAnswered;
                                        setAllAnsweredLeadId.add(req.Id);
                                        setAnsweredParentLeadId.add(req.ReinsurerStatus__c);
    
                                        if (String.isNotBlank(req.CommentsResponse__c) || req.CommentsResponse__c != null){
                                            req.Utility_Icon_Comment__c = AP_Constant.iconComment; //RRA - 939
                                        }
    
                                        if (String.isBlank(req.CommentsResponse__c) || req.CommentsResponse__c == null){
                                            req.Utility_Icon_Comment__c = null; //RRA - 939
                                        }
                                    }
                                    setAllParentLeadId.add(req.Id);
    
                                    // RRA - 939 delete icon attach and comment if document visibility don't exists
                                    if (lstDocVisBroReins.size() == 0){
                                        req.Utility_Icon_Attachment__c= ''; //RRA - 939
                                    }
                                    if (lstDocVisReins.size() == 0){
                                        req.Utility_Icon_Attachment__c= ''; //RRA - 939
                                    }
                                    mapKeyExistRequest.put(req.Broker__c + '_'+ req.Reinsurer__c + '_'+ req.Program__c, req);
                                }
                            
            
                                /* if Phase Type is Placement
                                if PlacementParticipation__c == 'Yes' -> Reinsurer Status = 'Answered'
                                if PlacementParticipation__c == 'No' -> Reinsurer Status = 'Refused'
                                */
                                if(phaseType == 'Placement'){
                                    req.ResponseDate__c = System.today();
                                    req.ReceptionDate__c = System.today();
                                    req.TECH_LastAnswerDate__c = System.today();
                                    if(req.PlacementParticipation__c == '1'){
                                        req.ReinsurerStatus__c = AP_Constant.statusAnswered;
                                    }
                                    else if(req.PlacementParticipation__c == '2'){
                                        req.ReinsurerStatus__c = AP_Constant.statusRefused;
                                        
                                        //RRA - ticket 1369 - 22022023 - initialize to null value of Quotation id ReinsurerStatus is refused
                                        req.ReinsurerExpenses__c = null;
                                        req.LossCarryingForward__c = null;
                                        req.OrUnlimited__c = false;
                                        req.LossCorridorPart__c = null;
                                        req.LossCorridorMaxLR__c = null;
                                        req.LossCorridorMinLR__c = null;
                                        req.NoClaimBonus__c =null;
                                        req.NoClaimBonusAmount__c = null; 
                                        req.ProfitCommission__c = null;
                                        req.WrittenShareResponse__c = null;
                                        req.WrittenShare__c = null;
                                        req.FixedCommission__c = null;
                                        req.FixedRate__c = null;
                                        req.MinRate__c = null;
                                        req.MaxRate__c = null;
                                        req.ProvisionalRate__c = null;
                                        req.FlatPremium__c = null;
                                        req.MDP__c = null;
                                        req.MinVarCommission__c = null;
                                        req.MaxVarCommission__c = null;
                                        req.ProvisionalCommission__c = null;
                                        req.PerHeadPremium__c = null;
                                        req.MinPerHeadAmount__c = null;
                                        req.MaxPerHeadAmount__c = null;
                                        req.ProvisionalPerHeadPremium__c = null;
                                        req.EstimatedReinsurancePremium__c = null;
                                        req.EstimatedInsurancePremium__c = null;
                                    }
                                    setAnsweredParentPlacement.add(req.ReinsurerStatus__c);
    
                                    if (String.isNotBlank(req.CommentsResponse__c) || req.CommentsResponse__c != null){
                                        req.Utility_Icon_Comment__c = AP_Constant.iconComment; //RRA - 939
                                    }
    
                                    if (String.isBlank(req.CommentsResponse__c) || req.CommentsResponse__c == null){
                                        req.Utility_Icon_Comment__c = null; //RRA - 939
                                    }
    
                                    // RRA - 939 delete icon attach and comment if document visibility don't exists
                                    if (lstDocVisBroReins.size() == 0){
                                        req.Utility_Icon_Attachment__c= ''; //RRA - 939
                                    }
                                    if (lstDocVisReins.size() == 0){
                                        req.Utility_Icon_Attachment__c= ''; //RRA - 939
                                    }
                                    mapKeyExistRequest.put(req.Broker__c + '_'+ req.Reinsurer__c + '_'+ req.Program__c, req);
                            }
                        }
                    }
                    // RRA - 939
                    if ((setAnsweredParentLeadId.contains(AP_Constant.statusAnswered) || setAnsweredParentLeadId.contains(AP_Constant.statusRefused)) || 
                        (setAnsweredParentQuote.contains(AP_Constant.statusAnswered) || setAnsweredParentQuote.contains(AP_Constant.statusRefused))  ||                 
                         setAnsweredParentPlacement.contains(AP_Constant.statusAnswered) || setAnsweredParentPlacement.contains(AP_Constant.statusRefused)){
                                Set<String> setPhaseDocVis = new Set<String> ();
    
                                for(DocumentVisibility__c docVis : lstDocVis){
    
                                    // RRA 939 - il file is delete directly, set Utility_Icon_Attachment__c to empty
                                    if(docVis.Tech_LabelPhase__c == 'Quote' || docVis.Tech_LabelPhase__c == 'Lead' || docVis.Tech_LabelPhase__c == 'Placement'){
                                        for(Request__c reqAnswered :lstRequest){
                                            if (String.isBlank(docVis.Tech_BrokerId__c) && String.isBlank(docVis.Tech_ReinsurerId__c) && reqAnswered.Broker__c!=null){
                                                reqAnswered.Utility_Icon_Attachment__c = '';
                                            }else if (docVis.Tech_BrokerId__c == null && reqAnswered.Broker__c==null){
                                                reqAnswered.Utility_Icon_Attachment__c = '';
                                            }
                                        }
                                        for(Request__c reqAnswered :lstParentRequest){
                                            if (String.isBlank(docVis.Tech_BrokerId__c) && String.isBlank(docVis.Tech_ReinsurerId__c) && reqAnswered.Broker__c!=null){
                                                reqAnswered.Utility_Icon_Attachment__c = '';
                                            }else if (String.isBlank(docVis.Tech_BrokerId__c) && reqAnswered.Broker__c==null){
                                                reqAnswered.Utility_Icon_Attachment__c = '';
                                            }
                                        }
                                    }
                                }
    
                                System.debug('lstDocVisBroReins' + lstDocVisBroReins.size());
                                System.debug('lstDocVisReins' + lstDocVisReins.size());
                                if (lstDocVisBroReins.size () > 0){
                                    for(DocumentVisibility__c docVis : lstDocVisBroReins){
                                        for(Request__c reqAnswered :lstRequest){
                                            if (phaseType == 'Quote'){
                                                if (docVis.Tech_BrokerId__c == reqAnswered.Broker__c && docVis.Tech_ReinsurerId__c == reqAnswered.Reinsurer__c){
                                                    reqAnswered.Utility_Icon_Attachment__c = AP_Constant.iconAttach;
                                                    docVis.Tech_Request_Status__c =  AP_Constant.statusVisibleOnPortalDocVis; // RRA - 1054
                                                }else {
                                                    reqAnswered.Utility_Icon_Attachment__c = '';
                                                }
                                                lstDocumentVisibility.add(docVis);
                                            }
    
                                            if (phaseType == 'Lead'){
                                                if (docVis.Tech_BrokerId__c == reqAnswered.Broker__c && docVis.Tech_ReinsurerId__c == reqAnswered.Reinsurer__c ){
                                                    reqAnswered.Utility_Icon_Attachment__c = AP_Constant.iconAttach;
                                                    docVis.Tech_Request_Status__c =  AP_Constant.statusVisibleOnPortalDocVis; // RRA - 1054
                                                }else {
                                                    reqAnswered.Utility_Icon_Attachment__c = '';
                                                }
                                                lstDocumentVisibility.add(docVis);
                                            }
    
                                            if (phaseType == 'Placement'){
                                                if (docVis.Tech_BrokerId__c == reqAnswered.Broker__c && docVis.Tech_ReinsurerId__c == reqAnswered.Reinsurer__c ){
                                                    reqAnswered.Utility_Icon_Attachment__c = AP_Constant.iconAttach;
                                                    docVis.Tech_Request_Status__c =  AP_Constant.statusVisibleOnPortalDocVis; // RRA - 1054
                                                }else {
                                                    reqAnswered.Utility_Icon_Attachment__c = '';
                                                }
                                                lstDocumentVisibility.add(docVis);
                                            }
                                        }
    
                                        for(Request__c reqAnswered :lstParentRequest){
                                            if (phaseType == 'Quote'){
                                                if (docVis.Tech_BrokerId__c == reqAnswered.Broker__c && docVis.Tech_ReinsurerId__c == reqAnswered.Reinsurer__c){
                                                    reqAnswered.Utility_Icon_Attachment__c = AP_Constant.iconAttach;
                                                    docVis.Tech_Request_Status__c =  AP_Constant.statusVisibleOnPortalDocVis; // RRA - 1054
                                                }else {
                                                    reqAnswered.Utility_Icon_Attachment__c = '';
                                                }
                                                lstDocumentVisibility.add(docVis);
                                            }
    
                                            if (phaseType == 'Lead'){
                                                if (docVis.Tech_BrokerId__c == reqAnswered.Broker__c && docVis.Tech_ReinsurerId__c == reqAnswered.Reinsurer__c){
                                                    reqAnswered.Utility_Icon_Attachment__c = AP_Constant.iconAttach;
                                                    docVis.Tech_Request_Status__c =  AP_Constant.statusVisibleOnPortalDocVis; // RRA - 1054
                                                }else {
                                                    reqAnswered.Utility_Icon_Attachment__c = '';
                                                }
                                                lstDocumentVisibility.add(docVis);
                                            }
    
                                            if (phaseType == 'Placement'){
                                                    if (docVis.Tech_BrokerId__c == reqAnswered.Broker__c && docVis.Tech_ReinsurerId__c == reqAnswered.Reinsurer__c){
                                                        reqAnswered.Utility_Icon_Attachment__c = AP_Constant.iconAttach;
                                                        docVis.Tech_Request_Status__c =  AP_Constant.statusVisibleOnPortalDocVis; // RRA - 1054
                                                    }else {
                                                        reqAnswered.Utility_Icon_Attachment__c = '';
                                                    }
                                                lstDocumentVisibility.add(docVis);
                                            }
                                        }
                                    }
                                }
                                
                                if (lstDocVisBroReins.size() == 0){
                                    if (phaseType == 'Quote' || phaseType == 'Lead' || phaseType == 'Placement'){
                                        for(Request__c reqAnswered :lstRequest){
                                            reqAnswered.Utility_Icon_Attachment__c = '';
                                        }
                                    }
                                }
    
                                if (lstDocVisReins.size () > 0){
                                    for(DocumentVisibility__c docVis : lstDocVisReins){
                                        for(Request__c reqAnswered :lstRequest){
                                            if (phaseType == 'Quote'){
                                                if (docVis.Tech_BrokerId__c == reqAnswered.Broker__c && docVis.Tech_ReinsurerId__c == reqAnswered.Reinsurer__c){
                                                    reqAnswered.Utility_Icon_Attachment__c = AP_Constant.iconAttach;
                                                    docVis.Tech_Request_Status__c =  AP_Constant.statusVisibleOnPortalDocVis; // RRA - 1054
                                                }else {
                                                    reqAnswered.Utility_Icon_Attachment__c = '';
                                                }
                                                lstDocumentVisibility.add(docVis);
                                            }
    
                                            if (phaseType == 'Lead'){
                                                if (docVis.Tech_BrokerId__c == reqAnswered.Broker__c && docVis.Tech_ReinsurerId__c == reqAnswered.Reinsurer__c){
                                                    reqAnswered.Utility_Icon_Attachment__c = AP_Constant.iconAttach;
                                                    docVis.Tech_Request_Status__c =  AP_Constant.statusVisibleOnPortalDocVis; // RRA - 1054
                                                }else {
                                                    reqAnswered.Utility_Icon_Attachment__c = '';
                                                }
                                                lstDocumentVisibility.add(docVis);
                                            }
    
                                            if (phaseType == 'Placement'){
                                                if (docVis.Tech_BrokerId__c == reqAnswered.Broker__c && docVis.Tech_ReinsurerId__c == reqAnswered.Reinsurer__c){
                                                    reqAnswered.Utility_Icon_Attachment__c = AP_Constant.iconAttach;
                                                    docVis.Tech_Request_Status__c =  AP_Constant.statusVisibleOnPortalDocVis; // RRA - 1054
                                                }else {
                                                    reqAnswered.Utility_Icon_Attachment__c = '';
                                                }
                                                lstDocumentVisibility.add(docVis);
                                            }
                                        }
    
                                        for(Request__c reqAnswered :lstParentRequest){
                                            if (phaseType == 'Quote'){
                                                if (docVis.Tech_BrokerId__c == reqAnswered.Broker__c && docVis.Tech_ReinsurerId__c == reqAnswered.Reinsurer__c){
                                                    reqAnswered.Utility_Icon_Attachment__c = AP_Constant.iconAttach;
                                                    docVis.Tech_Request_Status__c =  AP_Constant.statusVisibleOnPortalDocVis; // RRA - 1054
                                                }else {
                                                    reqAnswered.Utility_Icon_Attachment__c = '';
                                                }
                                                lstDocumentVisibility.add(docVis);
                                            }
    
                                            if (phaseType == 'Lead'){
                                                if (docVis.Tech_BrokerId__c == reqAnswered.Broker__c && docVis.Tech_ReinsurerId__c == reqAnswered.Reinsurer__c){
                                                    reqAnswered.Utility_Icon_Attachment__c = AP_Constant.iconAttach;
                                                    docVis.Tech_Request_Status__c =  AP_Constant.statusVisibleOnPortalDocVis; // RRA - 1054
                                                }else {
                                                    reqAnswered.Utility_Icon_Attachment__c = '';
                                                }
                                                lstDocumentVisibility.add(docVis);
                                            }
    
                                            if (phaseType == 'Placement'){
                                                if (docVis.Tech_BrokerId__c == reqAnswered.Broker__c && docVis.Tech_ReinsurerId__c == reqAnswered.Reinsurer__c){
                                                    reqAnswered.Utility_Icon_Attachment__c = AP_Constant.iconAttach;
                                                    docVis.Tech_Request_Status__c =  AP_Constant.statusVisibleOnPortalDocVis; // RRA - 1054
                                                }else {
                                                    reqAnswered.Utility_Icon_Attachment__c = '';
                                                }
                                                lstDocumentVisibility.add(docVis);
                                            }
                                        }
                                    }
                                }
                                
                                if (lstDocVisReins.size () == 0) {
                                    if (phaseType == 'Quote' || phaseType == 'Lead' || phaseType == 'Placement'){
                                        for(Request__c reqAnswered :lstRequest){
                                            reqAnswered.Utility_Icon_Attachment__c = '';
                                        }
                                    }
                                }
                            }
 
                }else if (btnName == 'SaveAll' && phaseType == 'Quote'){
                    System.debug('quotedeadline SaveAll == ' + quotedeadline);
                    //RRA - ticket 1541 - 04072023 - Update lastVersion Req
                        for (Request__c  request : lstRequest){
                            request.QuoteDeadline__c = quotedeadline;
                            request.isChk2DaysEmailReminder__c = isDateQuoteValChanged; //RRA - ticket 1574 - 24102023
                            request.UtilityIconDate__c = null; //not complete this field even if button saveAll is clicked
                            lstIdReqOrig.add(request.OriginalRequest__c); 
                            lstIdReqLast.add(request.Id);
                        }
                    
                        //RRA - ticket 1541 - 04072023 - Update Original Req
                        for (Request__c  request : [SELECT Id, OriginalRequest__c, LastVersionAnswered__c, isChk2DaysEmailReminder__c, LastVersionSent__c, UtilityIconDate__c, QuoteDeadline__c FROM Request__c WHERE Id IN:lstIdReqOrig]){
                            if (request.OriginalRequest__c == null){
                                request.QuoteDeadline__c = quotedeadline;
                                request.isChk2DaysEmailReminder__c = isDateQuoteValChanged; //RRA - ticket 1574 - 24102023
                                request.UtilityIconDate__c = null;  //not complete this field even if button saveAll is clicked
                                lstRequestUpdatedOrig.add(request);
                            }
                        }
                        
                        
                        //RRA - ticket 1541 - 04072023 - Last Version Req
                        for (Request__c  request : [SELECT Id, OriginalRequest__c, LastVersionAnswered__c, isChk2DaysEmailReminder__c, LastVersionSent__c, UtilityIconDate__c, QuoteDeadline__c FROM Request__c WHERE OriginalRequest__c IN:lstIdReqLast]){
                            if (request.LastVersionAnswered__c && request.LastVersionSent__c){
                                request.QuoteDeadline__c = quotedeadline;
                                request.isChk2DaysEmailReminder__c = isDateQuoteValChanged; //RRA - ticket 1574 - 24102023
                                request.UtilityIconDate__c = null;  //not complete this field even if button saveAll is clicked
                                lstRequestUpdatedLastVersFromSaveAll.add(request);
                            }
                        }
                        System.debug('lstRequestUpdatedOrig SaveAll == ' + lstRequestUpdatedOrig);
                }else{ // SAU button save is clicked
                    for(Request__c req : lstParentRequest){
                        setAllParentLeadId.add(req.Id);
                    }
                }
    
                System.debug('lstRequest == ' + lstRequest);
                
                List<Id> lstIdReq = new List<Id>();
                map<Id, Request__c> mapIdReqOrigReq = new map <Id,Request__c>();
                map<Id,Request__c> requestMap = new map<Id,Request__c>(); //Avoid System.ListException: Duplicate id in list:
             
                //RRA - VERSIONING - Update Last Version from Original Request if that one has changed
                if(lstRequest.size() > 0 && phaseType != 'Placement' ){
                    //update lstRequest;
                    for (Request__c req : lstRequest){
                        /*if (req.OriginalRequest__c == null){
                            lstIdReq.add(req.Id);
                            mapIdReqOrigReq.put(req.Id, req);
                        }*/
                        
                        //if(req.ReinsurerStatus__c != AP_Constant.statusSetup && req.ReinsurerStatus__c != AP_Constant.statusTimeout) {
                            requestMap.putall(lstRequest);
                        //}
                    }
                    if (requestMap.values().size()>0){
                        update requestMap.values();
                    }
                    //List<Request__c> lstReqLastVersToUpdate = [SELECT Id, OriginalRequest__c, ReinsurerStatus__c, WrittenShareResponse__c, FixedCommission__c, ProfitCommission__c,ReinsurerExpenses__c,LossCarryingForward__c, OrUnlimited__c, LossCorridorPart__c,LossCorridorMinLR__c, LossCorridorMaxLR__c,NoClaimBonus__c,NoClaimBonusAmount__c, Comments__c FROM Request__c WHERE OriginalRequest__c IN:lstIdReq AND LastVersionAnswered__c = true AND LastVersionSent__c = true];
                    
                    /*if (lstReqLastVersToUpdate.size()>0){
                        for (Request__c req : lstReqLastVersToUpdate){
                            if (req.OriginalRequest__c != null){
                               // if(req.ReinsurerStatus__c != AP_Constant.statusSetup && req.ReinsurerStatus__c != AP_Constant.statusTimeout) {
                                    req.WrittenShareResponse__c = mapIdReqOrigReq.get(req.OriginalRequest__c).WrittenShareResponse__c;
                                    req.FixedCommission__c = mapIdReqOrigReq.get(req.OriginalRequest__c).FixedCommission__c;
                                    req.ProfitCommission__c = mapIdReqOrigReq.get(req.OriginalRequest__c).ProfitCommission__c;
                                    req.ReinsurerExpenses__c = mapIdReqOrigReq.get(req.OriginalRequest__c).ReinsurerExpenses__c;
                                    req.LossCarryingForward__c = mapIdReqOrigReq.get(req.OriginalRequest__c).LossCarryingForward__c;
                                    req.OrUnlimited__c = mapIdReqOrigReq.get(req.OriginalRequest__c).OrUnlimited__c;
                                    req.LossCorridorPart__c = mapIdReqOrigReq.get(req.OriginalRequest__c).LossCorridorPart__c;
                                    req.LossCorridorMinLR__c = mapIdReqOrigReq.get(req.OriginalRequest__c).LossCorridorMinLR__c;
                                    req.LossCorridorMaxLR__c = mapIdReqOrigReq.get(req.OriginalRequest__c).LossCorridorMaxLR__c;
                                    req.NoClaimBonus__c = mapIdReqOrigReq.get(req.OriginalRequest__c).NoClaimBonus__c;
                                    req.NoClaimBonusAmount__c = mapIdReqOrigReq.get(req.OriginalRequest__c).NoClaimBonusAmount__c;
                                    req.Comments__c = mapIdReqOrigReq.get(req.OriginalRequest__c).Comments__c;
                               // }
                            }
                        }
                        update lstReqLastVersToUpdate;
                    }*/
                }

                System.debug('update lstRequest == ' + lstRequest);

                if(lstParentRequest.size() > 0){
                    update lstParentRequest;
                }

                System.debug('setAllParentLeadId == ' + setAllParentLeadId);
    
                if(setAllParentLeadId.size() > 0){
                    //update Reinsurer status for Child Lead Request if Accept = True for Parent Lead Request
                    Set<Id> setChildLeadId = new Set<Id>();
                    for(LeadRequestSelection__c  leadRequestSelection: [SELECT Id, LeadRequestChild__r.Section__c, LeadRequestChild__r.Section__r.TECH_TreatyName__c
                                                                                    , LeadRequestChild__r.Section__r.Name, LeadRequestChild__c, LeadRequestParent__r.TECH_ReinsurerName__c
                                                                             FROM LeadRequestSelection__c
                                                                             WHERE LeadRequestParent__c IN :setAllParentLeadId]){
                        setChildLeadId.add(leadRequestSelection.LeadRequestChild__c);
                    }
    
                     lstChildLeadRequest = [SELECT Id, ReinsurerStatus__c, ResponseDate__c, TECH_LastAnswerDate__c, CommentsResponse__c FROM Request__c WHERE Id IN :setChildLeadId];

                     System.debug('lstChildLeadRequestBeforeUpdates == ' + lstChildLeadRequest);
                    
                    if(btnName == 'Send'){
                        for(Request__c childLeadRequest : lstChildLeadRequest){
                                if(setAllAnsweredLeadId.contains(childLeadRequest.Id)){
                                    childLeadRequest.ReinsurerStatus__c = AP_Constant.statusAnswered;
                                    childLeadRequest.ResponseDate__c = System.today();
                                    childLeadRequest.TECH_LastAnswerDate__c = System.today();
                                    setAnsweredChildLead.add(childLeadRequest.Id);
                                    mapKeyExistRequest.put(childLeadRequest.Broker__c + '_'+ childLeadRequest.Reinsurer__c + '_'+ childLeadRequest.Program__c, childLeadRequest);
                                }
    
                                if (String.isNotBlank(childLeadRequest.CommentsResponse__c) || childLeadRequest.CommentsResponse__c != null){
                                    childLeadRequest.Utility_Icon_Comment__c = AP_Constant.iconComment; //RRA - 939
                                    
                                }
    
                                if (String.isBlank(childLeadRequest.CommentsResponse__c) || childLeadRequest.CommentsResponse__c == null){
                                    childLeadRequest.Utility_Icon_Comment__c = null; //RRA - 939
                                    
                                }
    
                                // RRA - 939 delete icon attach and comment if document visibility don't exists
                                if (lstDocVisBroReins.size() == 0){
                                    childLeadRequest.Utility_Icon_Attachment__c= ''; //RRA - 939
                                }
                                if (lstDocVisReins.size() == 0){
                                    childLeadRequest.Utility_Icon_Attachment__c= ''; //RRA - 939
                                }
                                
                        }
                    }
    
    
                    /*if (setAnsweredChildLead.contains(AP_Constant.statusAnswered) || setAnsweredChildLead.contains(AP_Constant.statusRefused)){
                        for(DocumentVisibility__c docVis : lstDocVis){
                            docVis.Tech_Request_Status__c =  AP_Constant.statusVisibleOnPortalDocVis;
                            lstDocumentVisibility.add(docVis);
                        }
                    }*/
    
                    if(lstChildLeadRequest.size() > 0){
                        update lstChildLeadRequest;
                    }

                    System.debug('lstChildLeadRequestAfterUpdate == ' + lstChildLeadRequest);
                }
    
    
                if(lstDocumentVisibility.size() > 0 ){
                  map<Id,DocumentVisibility__c> docVisMap = new map<Id,DocumentVisibility__c>(); //Avoid System.ListException: Duplicate id in list:
                  docVisMap.putall(lstDocumentVisibility);
                    System.debug('lstDocVisibilityToDeleteInitQuote == ' + lstDocumentVisibility);
                    update docVisMap.values();
                }
                
                 //RRA - ticket 1541 - 04072023
                 if (lstRequestUpdatedOrig.size()>0){
                    update lstRequestUpdatedOrig; 
                }
                  //RRA - ticket 1541 - 04072023
                  if (lstRequestUpdatedLastVersFromSaveAll.size()>0){
                    update lstRequestUpdatedLastVersFromSaveAll; 
                }
                
               
                 //RRA - ticket 1574 - 24102023
                if (idRequestSelected != null && btnName == 'Send' && phaseType == 'Quote'){
                    for (Request__c req : [SELECT Id , QuoteDeadline__c FROM Request__c WHERE Id =: idRequestSelected ]){
                        if (req.QuoteDeadline__c != null) { 
                            dateQuoteValidity = req.QuoteDeadline__c;
                        }
                    }
                    if (dateQuoteValidity != null){
                        System.debug('dateQuoteValidity == ' + dateQuoteValidity);
                        Date dateQuoteValidityDaysMinus2 = dateQuoteValidity - 2; 
                        Date dateQuoteValidityDaysMinus1 = dateQuoteValidity - 1;
                        Date dateQuoteValidityDaysCurrent = dateQuoteValidity;
                        Boolean isActionSendEmail = false;
                        System.debug('dateQuoteValidityDaysMinus2== ' + dateQuoteValidityDaysMinus2);
                        System.debug('dateQuoteValidityDaysMinus1 == ' + dateQuoteValidityDaysMinus1);
                        System.debug('dateQuoteValidityDaysCurrent == ' + dateQuoteValidityDaysCurrent);
                        System.debug('isActionSendEmail == ' + isActionSendEmail);
                        if (dateQuoteValidityDaysMinus2 == Date.today() || dateQuoteValidityDaysMinus1 == Date.today() || dateQuoteValidityDaysCurrent  ==  Date.today()){
                            isActionSendEmail = true;
                        }
                        if (isActionSendEmail){
                            apexReminderMailQuotValidity.sendEmail(idRequestSelected, isPortalAccess);
                            System.debug('ok sendEmail from Portal');
                        }
                    }
                }
    
    
                mapResults.put('lstRequest', lstRequest);
                mapResults.put('lstParentRequest', lstParentRequest);
                mapResults.put('Success', 'Success');
            }catch (Exception ex) {
                Database.rollback(sp);
                mapResults.put('Error', ex.getMessage());
            }
            return mapResults;
        }
    
        public static String LabelPhaseRequest (String phase){
            String phaseType;
            Request__c req =[SELECT toLabel(TECH_PhaseType__c) FROM Request__c WHERE TECH_PhaseType__c =: phase LIMIT 1];
            phaseType = req.TECH_PhaseType__c;
            return phaseType;
        }
    
        /**
        * @description Method to send mail for Request
        * @param List<Request__c> lstRequest, String stage, Request__c parentRequest, String reinId, String brokId, List<Request__c> lstParentRequest
        * @return Map<String, Object>
        */
        @AuraEnabled
        public static Map<String, Object> sendMail(List<Request__c> lstRequest, String stage, Request__c parentRequest, String reinId, String brokId, List<Request__c> lstParentRequest){
            Map<String, Object> mapResults = new Map<String, Object>();
            Map<Id, String> mapReinsurerStatusByOriginalReqId = new Map<Id, String>();
            List<String> lstCCEmailsToSend = new List<String>();
            Savepoint sp = Database.setSavepoint();
            String strLstCCEmail = null;
            String strLstCCEmailDisplay = null;
            String brokerReinsurerName; //RRA - ticket 1761 - 14112023
            Map<Id, Request__c> mapRequestNewVersionById = new Map<Id, Request__c>(); //RRA - VERSIONING
            Date valueResponseDate;
    
            try{
                Id requestId;
                Id programId;
                Boolean portalFirstSend = false;
    
                EmailTemplate emailTemplateRequestAnswer = [SELECT Id, Name FROM EmailTemplate WHERE Name = :AP_Constant.emailTemplateRequestAnswer];
                List<Messaging.SingleEmailMessage> lstMails =  new List<Messaging.SingleEmailMessage>();
                //For Sender in subject 
                User user = [SELECT Id, ContactId, Email FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
                
                //RRA - ticket 1761 - 14112023
                //For AXA SA used as sender email address
                User userAXASA = [SELECT Id, Name, Email FROM User WHERE Id =:System.label.AXA_SA_Sender LIMIT 1];
                Contact contact = [SELECT Id, Name, Email FROM Contact WHERE Id = :user.ContactId];
    
                if(stage == 'Quote' || stage == 'Placement'){
                    //08/03/2021
                    //First Sent -> 'sent'
                    //Second or more Sent -> 'changed'
                    if(stage == 'Quote' && lstRequest.size() > 0){
                        requestId = lstRequest[0].Id;
                        programId = lstRequest[0].Program__c;
                    }
                    else if(stage == 'Placement' && parentRequest != null){
                        requestId = parentRequest.Id;
                        programId = parentRequest.Program__c;
                    }
    
                    if(requestId != null){
                        Request__c req = [SELECT Id, Name, TECH_PortalFirstSend__c FROM Request__c WHERE Id = :requestId];
    
                        if(req.TECH_PortalFirstSend__c == true){
                            portalFirstSend = true;
                        }
                        else{
                            portalFirstSend = false;
                        }
                    }
                }
                else{
                    if(parentRequest != null){
                        requestId = parentRequest.Id;
                        programId = parentRequest.Program__c;
                    }
                }
    
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
    
                if(stage == 'Placement'){
                    //MBE - 27/01/2021
                    requestId = lstParentRequest[0].Id;
                }
    
                List<Request__c> lstRequestNewVersion = new List<Request__c>();
                Set<Id> setNewLeadRequestInsertedId = new Set<Id>();
                Decimal valueMinor;
                Boolean isAccept = false;

                if (stage == 'Lead'){
                    for(Request__c request : lstRequest){
                        if (stage == 'Lead') {
                            if (request.Accept__c == true) {
                                isAccept = true;
                            }
                        }
                    }
                }
                


                if(stage == 'Quote' || stage == 'Signing' ){
                    for(Request__c request : lstRequest){
                        //RRA - ticket 1761 - 14112023
                        if (request.Broker__c != null && request.Reinsurer__c != null){
                            brokerReinsurerName = 'by ' + request.TECH_ReinsurerName__c + ' (via ' + request.TECH_BrokerName__c + ') '; 
                        }else if (request.Broker__c == null && request.Reinsurer__c != null){
                            brokerReinsurerName = 'by ' + request.TECH_ReinsurerName__c;
                        }
                        
                        //RRA VERSIONING
                        //request.ResponseDate__c = System.today();
                        request.DateNextSending__c = null;
                        valueResponseDate = request.ResponseDate__c;
                        if (request.ResponseDate__c != null){
                            request.ResponseDate__c = valueResponseDate;
                        }else{
                            request.ResponseDate__c = System.today();
                        }
                        
                        valueMinor = request.VersionMinor__c + 1;
                        if (request.ReinsurerStatus__c != AP_Constant.statusSetup && request.ReinsurerStatus__c != AP_Constant.statusTimeout) { // RRA - 1104
                            request.VersionMinor__c = valueMinor;
                            request.QuoteOnBehalf__c = false; // RRA - remake QuoteOnBehalf to false if it's a response on portal -28/09/2022
                            request.TECH_PortalFirstSend__c = false;
                            mapReinsurerStatusByOriginalReqId.put(request.Id, request.ReinsurerStatus__c);
                            Request__c newVersionRequest = request.clone(false, false, false, false);
                            newVersionRequest.OriginalRequest__c = request.Id;
                            newVersionRequest.LastVersionSent__c = true;
                            newVersionRequest.LastVersionAnswered__c = true;
                            newVersionRequest.TECH_OldRequestId__c = request.Id;
                            newVersionRequest.TECH_PortalFirstSend__c = false;
                            newVersionRequest.TECH_Actor2Id__c = null;
                            newVersionRequest.ResponseDate__c = System.today();//RRA VERSIONING
                            newVersionRequest.ReinsurerStatus__c = AP_Constant.statusAnswered; //RRA VERSIONING
                            lstRequestNewVersion.add(newVersionRequest);
                        }
                    }
                    System.debug('brokerReinsurerName == ' + brokerReinsurerName);
                }
                else if(stage == 'Placement'){
                    for(Request__c parenReq : lstParentRequest){
                        if (parenReq.Broker__c != null && parenReq.Reinsurer__c != null){
                            brokerReinsurerName = 'by ' + parenReq.TECH_ReinsurerName__c + ' (via ' + parenReq.TECH_BrokerName__c + ') '; 
                        }else if (parenReq.Broker__c == null && parenReq.Reinsurer__c != null){
                            brokerReinsurerName = 'by ' + parenReq.TECH_ReinsurerName__c;
                        }
                        //RRA VERSIONINGl){
                        //parenReq.ResponseDate__c = System.today();
                        valueResponseDate = parenReq.ResponseDate__c;
                        if (parenReq.ResponseDate__c != null){
                            parenReq.ResponseDate__c = valueResponseDate;
                        }else{
                            parenReq.ResponseDate__c = System.today();
                        }
                        parenReq.DateNextSending__c = null;
                        valueMinor= parenReq.VersionMinor__c + 1;
                        if (parenReq.ReinsurerStatus__c != AP_Constant.statusSetup && parenReq.ReinsurerStatus__c != AP_Constant.statusTimeout) { // RRA - 1104
                            parenReq.VersionMinor__c = valueMinor;
                            parenReq.PlacementOnBehalf__c = false; // RRA - remake PlacementOnBehalf to false if it's a response on portal -28/09/2022
                            parenReq.TECH_PortalFirstSend__c = false;
                            parenReq.ReceptionDate__c = System.today();
                            mapReinsurerStatusByOriginalReqId.put(parenReq.Id, parenReq.ReinsurerStatus__c);
                            Request__c newParentVersionRequest = parenReq.clone(false, false, false, false);
                            newParentVersionRequest.OriginalRequest__c = parenReq.Id;
                            newParentVersionRequest.LastVersionSent__c = true;
                            newParentVersionRequest.LastVersionAnswered__c = true;
                            newParentVersionRequest.TECH_OldRequestId__c = parenReq.Id;
                            newParentVersionRequest.TECH_PortalFirstSend__c = false;
                            newParentVersionRequest.TECH_Actor2Id__c = null;
                            newParentVersionRequest.ResponseDate__c = System.today();//RRA VERSIONING
                            newParentVersionRequest.ReinsurerStatus__c = AP_Constant.statusAnswered; //RRA VERSIONING
                            lstRequestNewVersion.add(newParentVersionRequest);
                        }
                    }
                }
                else if(stage == 'Lead'){

                    for(Request__c request : lstRequest){
                        if (request.Accept__c == true) {
                            isAccept = true;
                        }
                    }
                    for(Request__c request : lstParentRequest){
                        if (request.Broker__c != null && request.Reinsurer__c != null){
                            brokerReinsurerName = 'by ' + request.TECH_ReinsurerName__c + ' (via ' + request.TECH_BrokerName__c + ') '; 
                        }else if (request.Broker__c == null && request.Reinsurer__c != null){
                            brokerReinsurerName = 'by ' + request.TECH_ReinsurerName__c;
                        }
                            if (request.Accept__c == true) {
                                isAccept = true;
                            }

                    }

                    List<LeadRequestSelection__c> lstLeadRequestSelection = [SELECT Id, LeadRequestChild__r.Section__c, LeadRequestChild__r.Section__r.TECH_TreatyName__c
                                                                                    , LeadRequestChild__r.Section__r.Name, LeadRequestChild__c, LeadRequestParent__r.TECH_ReinsurerName__c
                                                                             FROM LeadRequestSelection__c
                                                                             WHERE LeadRequestParent__c IN :lstParentRequest];
    
                    List<Request__c> lstLeadRequestToInsert = new List<Request__c>();
                    List<LeadRequestSelection__c> lstLeadRequestSelectionNewVersion = new List<LeadRequestSelection__c>();
    
                    for(Request__c parentLeadRequest : lstParentRequest){
                        //if (parentLeadRequest.Accept__c) {
                            if (isAccept == true){
                                //RRA VERSIONING
                               //parentLeadRequest.ResponseDate__c = System.today();
                               valueResponseDate = parentLeadRequest.ResponseDate__c;
                                if (parentLeadRequest.ResponseDate__c != null){
                                    parentLeadRequest.ResponseDate__c = valueResponseDate;
                                }else{
                                    parentLeadRequest.ResponseDate__c = System.today();
                                }
                               parentLeadRequest.DateNextSending__c = null;
                                valueMinor= parentLeadRequest.VersionMinor__c + 1;
                                parentLeadRequest.VersionMinor__c = valueMinor ; //RRA - 1104 (inc VersionMinor if and only if accept field is checked if no equal 0)
                                parentLeadRequest.LeadOnBehalf__c = false; // RRA - remake PlacementOnBehalf to false if it's a response on portal -28/09/2022
                                //parentLeadRequest.VersionMinor__c = parentLeadRequest.VersionMinor__c + 1;
                                mapReinsurerStatusByOriginalReqId.put(parentLeadRequest.Id, parentLeadRequest.ReinsurerStatus__c);
                                Request__c newParentVersionRequest = parentLeadRequest.clone(false, false, false, false);
                                newParentVersionRequest.OriginalRequest__c = parentLeadRequest.Id;
                                newParentVersionRequest.LastVersionSent__c = true;
                                newParentVersionRequest.LastVersionAnswered__c = true;
                                newParentVersionRequest.TECH_OldRequestId__c = parentLeadRequest.Id;
                                newParentVersionRequest.TECH_Actor2Id__c = null;
                                newParentVersionRequest.ReinsurerStatus__c = AP_Constant.statusAnswered; //RRA VERSIONING
                                newParentVersionRequest.ResponseDate__c = System.today(); //RRA VERSIONING
                                lstLeadRequestToInsert.add(newParentVersionRequest);
                        }
                    }
    
                    for(Request__c childRequest : lstRequest){
                        //if(childRequest.Accept__c){
                            if (isAccept == true){
                            //RRA VERSIONING
                                //childRequest.ResponseDate__c = System.today();
                                valueResponseDate = childRequest.ResponseDate__c;
                                if (childRequest.ResponseDate__c != null){
                                    childRequest.ResponseDate__c = valueResponseDate;
                                }else{
                                    childRequest.ResponseDate__c = System.today();
                                }
                                childRequest.DateNextSending__c = null;
                                valueMinor= childRequest.VersionMinor__c + 1;
                                childRequest.VersionMinor__c = valueMinor; //RRA - 1104 (inc VersionMinor if and only if accept field is checked if no equal 0)
                                childRequest.LeadOnBehalf__c = false; // RRA - remake PlacementOnBehalf to false if it's a response on portal -28/09/2022
                                //childRequest.VersionMinor__c = childRequest.VersionMinor__c + 1;
                                mapReinsurerStatusByOriginalReqId.put(childRequest.Id, childRequest.ReinsurerStatus__c);
                                Request__c newChildVersionRequest = childRequest.clone(false, false, false, false);
                                newChildVersionRequest.OriginalRequest__c = childRequest.Id;
                                newChildVersionRequest.LastVersionSent__c = true;
                                newChildVersionRequest.LastVersionAnswered__c = true;
                                newChildVersionRequest.TECH_OldRequestId__c = childRequest.Id;
                                newChildVersionRequest.TECH_Actor2Id__c = null;
                                newChildVersionRequest.ResponseDate__c = System.today(); //RRA VERSIONING
                                newChildVersionRequest.ReinsurerStatus__c = AP_Constant.statusAnswered; //RRA VERSIONING
                                lstLeadRequestToInsert.add(newChildVersionRequest);
                         } 
                        
                    }
    
                    if(lstLeadRequestToInsert.size() > 0) {
                        insert lstLeadRequestToInsert;
                        mapRequestNewVersionById = new Map<Id, Request__c>(lstLeadRequestToInsert);    //RRA - VERSIONING
                    }
    
                    Map<Id, Id> mapNewRequestIdByOldRequestLead = new Map<Id, Id>();
    
                    for(Request__c newLeadRequest : lstLeadRequestToInsert){
                        setNewLeadRequestInsertedId.add(newLeadRequest.Id);
                        mapNewRequestIdByOldRequestLead.put(newLeadRequest.TECH_OldRequestId__c, newLeadRequest.Id);
                    }
    
                    for(LeadRequestSelection__c leadRequestSelection: lstLeadRequestSelection){
                        if(mapNewRequestIdByOldRequestLead.containsKey(leadRequestSelection.LeadRequestParent__c) && mapNewRequestIdByOldRequestLead.containsKey(leadRequestSelection.LeadRequestChild__c)){
                            LeadRequestSelection__c newLeadRequestSelection = leadRequestSelection.clone(false,false,false,false);
                            newLeadRequestSelection.LeadRequestChild__c = mapNewRequestIdByOldRequestLead.get(leadRequestSelection.LeadRequestChild__c);
                            newLeadRequestSelection.LeadRequestParent__c = mapNewRequestIdByOldRequestLead.get(leadRequestSelection.LeadRequestParent__c);
                            lstLeadRequestSelectionNewVersion.add(newLeadRequestSelection);
                        }
                    }
    
                    if(lstLeadRequestSelectionNewVersion.size() > 0){
                        insert lstLeadRequestSelectionNewVersion;
                    }
                }
                 //RRA - VERSIONING
                List<Request__c> lstAllRequestVersion = [SELECT Id, Name, isFirstSending__c, LastVersionSent__c, LastVersionAnswered__c, OriginalRequest__c, ReceptionDate__c FROM Request__c WHERE OriginalRequest__c IN :mapReinsurerStatusByOriginalReqId.keySet()];
                
                //RRA - VERSIONING
                if(stage != 'Lead' && lstRequestNewVersion.size() > 0){
                    insert lstRequestNewVersion;
                    mapRequestNewVersionById = new Map<Id, Request__c>(lstRequestNewVersion);   
                }
                
                System.debug('mapRequestNewVersionById == ' + mapRequestNewVersionById);
                
                 //RRA - VERSIONING
                Request__c  lastVersionReq = new Request__c();
                lastVersionReq = mapRequestNewVersionById.size() > 0 ? mapRequestNewVersionById.values().get(0) : null; //RRA - VERSIONING
                
                System.debug('lastVersionReq == ' + lastVersionReq);
                
                for(Request__c request : lstAllRequestVersion){
                    if(!setNewLeadRequestInsertedId.contains(request.Id)){
                        Id originalReqId;
                        if(request.OriginalRequest__c == null){
                            originalReqId = request.Id;
                        }
                        else{
                            originalReqId = request.OriginalRequest__c;
                        }
    
                        //RRA - VERSIONING
                        if(mapReinsurerStatusByOriginalReqId.containsKey(originalReqId)){
                            //request.ReinsurerStatus__c = mapReinsurerStatusByOriginalReqId.get(originalReqId);
                        }

                        request.LastVersionAnswered__c = false;
                        request.LastVersionSent__c = false;
                        //request.ResponseDate__c = System.today();
                        request.TECH_LastAnswerDate__c = System.today();
    
                        if(stage == 'Quote' || stage == 'Placement'){
                            request.TECH_PortalFirstSend__c = false;
                        }
                        if(stage == 'Placement'){
                            request.ReceptionDate__c = System.today();
                        }
                    }
                }
                
               
                if(lstParentRequest.size() > 0){
                    update lstParentRequest;
                }
    
                if(lstAllRequestVersion.size() > 0){
                    update lstAllRequestVersion;
                    
                    //RRA VERSIONING
                    List<Request__c> lstReqUpdateLastSentDate = new List<Request__c>();
                    for (Request__c req : lstAllRequestVersion){
                        if (req.isFirstSending__c && req.LastVersionSent__c == false){
                            req.isFirstSending__c = false;
                            lstReqUpdateLastSentDate.add(req);
                        }
                    }
                    if (lstReqUpdateLastSentDate.size()>0 && lstReqUpdateLastSentDate != null){
                        update lstReqUpdateLastSentDate;
                    }
                }
                
                if(lstRequest.size() > 0){
                    update lstRequest;
                }
                
                 //RRA - VERSIONING
                List<Request__c> lstAllRequestOriginalVersion = [SELECT Id, Name, LastVersionSent__c, LastVersionAnswered__c, OriginalRequest__c, ReinsurerStatus__c FROM Request__c WHERE Id IN :mapReinsurerStatusByOriginalReqId.keySet()];
                
                System.debug('lstAllRequestOriginalVersion == ' + lstAllRequestOriginalVersion);
                
                for(Request__c request : lstAllRequestOriginalVersion){
                    if(request.OriginalRequest__c == null){
                        System.debug('ok its original request');
                        request.ReinsurerStatus__c = lastVersionReq.ReinsurerStatus__c; //RRA - VERSIONING
                        request.ResponseDate__c = lastVersionReq.ResponseDate__c;//RRA - VERSIONING
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
    
                if(lstCCEmailsToSend.size() > 0){
                    mail.setCcAddresses(lstCCEmailsToSend);
                }
    
                String htmlBody = m.htmlBody;
                String domainURL = URL.getSalesforceBaseUrl().toExternalForm();
                String answerPageLink = '<a href="'+domainURL+'/portal/s/request?c__details='+programId+'-'+reinId+'-'+brokId+'-'+stage+'-'+requestId+'">here.</a>'; //RRA 1045
                String htmlInternetLink = '<a href="'+domainURL+'/portal/s/homepage">ACTOR Page</a>';
    
                htmlBody = htmlBody.replace('[ACTOR link TreatiesReinsurers/QuotationReply page]', answerPageLink);
                htmlBody = htmlBody.replace('{InternetLink}', htmlInternetLink);
    
                if(strLstCCEmailDisplay != null ){
                    htmlBody = htmlBody.replace('[Actor Mail box per instance]', strLstCCEmailDisplay);
                }
                else{
                    htmlBody = htmlBody.replace('[Actor Mail box per instance]', '');
                }
                
                if((stage == 'Quote' || stage == 'Placement') && portalFirstSend == true){
                    htmlBody = htmlBody.replace('{statusSentChanged}', 'sent');
                }
                else if((stage == 'Quote' || stage == 'Placement') && portalFirstSend == false){
                    htmlBody = htmlBody.replace('{statusSentChanged}', 'changed');
                }
                else{
                    htmlBody = htmlBody.replace('{statusSentChanged}', 'sent');
                }
    
                mail.setHtmlBody(htmlBody);
                //mail.setSubject(m.getSubject());
                lstMails.add(mail);
                System.debug('lstMails == ' + lstMails);
                Messaging.sendEmail((List<Messaging.Email>) lstMails);
                mapResults.put('Success', 'Success');
                
                 //RRA - VERSIONING
                if(lstAllRequestOriginalVersion.size() > 0){
                    update lstAllRequestOriginalVersion;
                    System.debug('update ok done');
                
                }
    
                //mapResults.put('answerPageLink', answerPageLink);
            }
            catch (Exception ex) {
                Database.rollback(sp);
                mapResults.put('Error', ex.getMessage());
            }
            return mapResults;
        }
    
        /**
        * @description Method to get RecordTypeId for Placement Request
        * @return String
        */
        //MRA 13/07/22: W-0949 Portal -Quote / Placement - Ajout d'un bouton "refuse all"
        @AuraEnabled
        public static String getPlacementRequestRecordTypeId(String phase){
            Map<String, Id> mapRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectRequest});
            String reqPlacementRecordTypeId = '' ;
            if(phase == 'Placement')
                 reqPlacementRecordTypeId = mapRecTypeId.get(AP_Constant.reqRTPlacement);
            else if(phase == 'Quote')
                 reqPlacementRecordTypeId = mapRecTypeId.get(AP_Constant.reqRTQuote);

            return reqPlacementRecordTypeId;
        }
    }