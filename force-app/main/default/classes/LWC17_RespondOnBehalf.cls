public with sharing class LWC17_RespondOnBehalf {
    /**************************************************************************************
    -- - Author        : Spoon Consulting
    -- - Description   : Controller for Lightning Web Component lwc17RespondOnBehalf
    --
    -- Maintenance History:
    --
    -- Date         Name  Version  Remarks
    -- -----------  ----  -------  -------------------------------------------------------
    -- 09-JAN-2020  MBE   1.0      Initial version
    -- 29-MAR-2021  MBE   1.1      Update Child Lead Request - ReinsurerStatus + ResponseDate
    -- 30-MAR-2021  MBE   1.2      W-0891 - ODS - Respond (Quote/Leads/Placement) OnBehalf are false in database
    -- 30-MAR-2021  MBE   1.3      W-0903 - ODS - RECEIVEDDATE non alimentée pour les placement requests
    -- 21-APR-2021  MBE   1.4      W-0926 - Portal - Lead - Champ obligatoire
    -- 22-APR-2021  MBE   1.5      W-0929 - Transversal - Respond on behalf et pages de réponses réassureur - affichage champs
    -- 21-May-2021  MBE   1.6      W-0974 - Bug bloquant Prod - Impossibilité de créer une Lead request - TECH_Actor2Id__c
    -- 08-JUL-2021  NBI   1.7      W-0992: Third Party Management
    -- 27-AUG-2021  MBE   1.8      Remove unused value for mapResult
    --------------------------------------------------------------------------------------
    **************************************************************************************/
        
        /**
        * @description Method to get Requests for selected Program and Reinsurer
        * @param Id programId
        * @param Id reinsurerId
        * @return List<Request__c>
        */
        @AuraEnabled(Cacheable = true)
        public static List<Request__c> getRequests(Id programId, Id reinsurerId){
            return [
                    SELECT Id, Name, Treaty__c, Treaty__r.Name, Section__c, TECH_TreatyName__c, TECH_SectionName__c, Reinsurer__c,TECH_ReinsurerName__c
                    FROM Request__c
                    WHERE Program__c = :programId AND Reinsurer__c = :reinsurerId
            ];
        }

        /**
        * @description Method to get Request details
        * @param Id requestId
        * @return Map<String, Object>
        */
        @AuraEnabled
        public static Map<String, Object> getRequestDetails(Id requestId){
            // RRA - 1104 - Add FixedRate__c, MinRate__c, MaxRate__c, ProvisionalRate__c, FlatPremium__c, MDP__c, FixedCommission__c, MinVarCommission__c, MaxVarCommission__c, ProvisionalCommission__c, PerHeadPremium__c, MinPerHeadAmount__c, MaxPerHeadAmount__c, ProvisionalPerHeadPremium__c, EstimatedReinsurancePremium__c, EstimatedInsurancePremium__c in sooql
    
            Request__c requestById = [SELECT Id, Program__c, FixedRate__c, MinRate__c, MaxRate__c, ProvisionalRate__c, FlatPremium__c, MDP__c, FixedCommission__c, MinVarCommission__c, MaxVarCommission__c, ProvisionalCommission__c, PerHeadPremium__c, MinPerHeadAmount__c, MaxPerHeadAmount__c, ProvisionalPerHeadPremium__c, EstimatedReinsurancePremium__c, EstimatedInsurancePremium__c, Program__r.RenewedFromProgram__c, Program__r.TypeOfRenew__c, Reinsurer__c, Broker__c, ReinsurerStatus__c, Treaty__c, TECH_PhaseType__c, Program__r.PrincipalCedingCompany__c, Program__r.UwYear__c, Program__r.TECH_StageName__c, Program__r.isBtnActivatedDeactivated__c FROM Request__c WHERE Id =:requestId]; //RRA - ticket 585 - 06032023
            Id programId = requestById.Program__c;
            Boolean isActivatedDeactivatedProg = requestById.Program__r.isBtnActivatedDeactivated__c ; //RRA - ticket 585 - 06032023
            Id reinsurerId = requestById.Reinsurer__c;
            Id brokerId = requestById.Broker__c;
            Id pccId = requestById.Program__r.PrincipalCedingCompany__c;
            String requestPhaseType = requestById.TECH_PhaseType__c;
            Boolean isProgRenewedAndIdentical = false;
            Boolean accActive = true;
            Boolean pccActive = true;
            String reinsName = '' ;//MRA W-0953 8/09/2022 
            String brokerName = '' ;//MRA W-0953 8/09/2022 
    
            if(requestById.Program__r.RenewedFromProgram__c != null && requestById.Program__r.TypeOfRenew__c == 'LTA/TR Identical Renew'){
                isProgRenewedAndIdentical = true;
            }
    
            List<OptionWrapper> lstTreaties = new List<OptionWrapper>();
            List<Request__c> lstRequestBrokers = new List<Request__c>();
            Map<String, Object> mapResults = new Map<String, Object>();
            Set<Id> setTreatyId = new Set<Id>();
            Set<Id> setSectionId = new Set<Id>();
            Map<Id, List<Request__c>> mapSectionRequestByTreatyId = new Map<Id, List<Request__c>>();
            Map<String, Id> mapRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectRequest});
            String reqQuoteRecordTypeId = mapRecTypeId.get(AP_Constant.reqRTQuote);
            String reqLeadRecordTypeId = mapRecTypeId.get(AP_Constant.reqRTLead);
            String reqPlacementRecordTypeId = mapRecTypeId.get(AP_Constant.reqRTPlacement);
            List<String> lstRequestFields = AP_Constant.getCreatableFieldsByObjName(AP_Constant.sObjectRequest);
            String strRequestFields = String.join(lstRequestFields , ', ');
            List<Request__c> lstRequestAll = new List<Request__c>();
            Map<Id, Request__c> mapParentRequestByTreatyId = new Map<Id, Request__c>(); //for lead
            List<Request__c> lstParentRequest = new List<Request__c>(); //for lead
            Map<Id, Request__c> mapParentLeadRequestByTreatyId = new Map<Id, Request__c>(); //for placement
            String statusSetup = AP_Constant.statusSetup;
            
            Set<Id> setParentLeadRequestId = new Set<Id>();
            Set<Id> setPlacementChildRequestId = new Set<Id>();
    
            Set<Boolean> setIsActive = new Set<Boolean>();
    
            for(Account acc : [SELECT Id, Name, IsActive__c FROM Account WHERE (Id = :reinsurerId OR Id = :brokerId)]){
                setIsActive.add(acc.IsActive__c);
            }
    
            if(setIsActive.size() > 0){
                if(setIsActive.contains(false)){
                    accActive = false;
                }
            }
    
            Account pcc = [SELECT Id, Name, IsActive__c FROM Account WHERE Id = :pccId];
            pccActive = pcc.IsActive__c;
    
            // SRA - 928
            if(requestPhaseType == '3' || requestPhaseType == '4'){
                String queryQuoteRequest = 'select Id, Treaty__r.Name, Treaty__r.Layer__c, Program__r.PrincipalCedingCompany__c, Program__r.UwYear__c, Program__r.TECH_StageName__c, Section__r.CededPremium__c'
                        + ', Broker__r.Name, TECH_BrokerName__c, TECH_ReinsurerName__c, Program__r.LTA__c, Program__r.Name, toLabel(Program__r.LossDeposit__c), Program__r.InceptionDate__c, Program__r.Expirydate__c, Section__r.TECH_TypeofTreaty__c, Section__r.QuoteType__c, Section__r.SectionNumber__c'
                        + ', Section__r.Cession_Perc__c, Section__r.Name, Section__r.Currency__c, Section__r.Unlimited__c, Treaty__r.Deductions_Perc__c, ToLabel(Treaty__r.PremiumDeposit__c), Treaty__r.TypeofTreaty__c, toLabel(Treaty__r.LossDeposit__c)'
                        + ', Section__r.EventLimit__c, Section__r.RetentionLine__c, Section__r.TAL__c, Section__r.Retention__c, Section__r.CessionAmount__c, Section__r.TECH_Reinstatement__c'
                        + ', Section__r.RetentionAmount__c,Section__r.Reinstatements__c, Section__r.TotalEPI__c, Section__r.Nature__c, Section__r.LineAmount__c, Section__r.CededLines__c'
                        + ', Section__r.Capacity__c, Section__r.Limit__c, Section__r.Deductible__c, Section__r.AAD__c, Section__r.AAL__c, TECH_SectionName__c,LastModifiedBy.Email, CreatedBy.Email '
                        + ', Section__r.LimitPercent__c, Section__r.DeductiblePercent__c, Section__r.MaxLimitAmount__c, Section__r.MinLimitAmount__c, Section__r.ExpectedMDP__c, Section__r.ExpectedDP__c, Section__r.ExpectedMP__c, Section__r.CommentsReinsurerBroker__c, '//RRA - ticket 1095 - 01082023
                        + strRequestFields
                        + ' from Request__c where (Program__c = :programId AND Reinsurer__c = :reinsurerId AND RecordTypeId = :reqQuoteRecordTypeId AND ((LastVersionSent__c = TRUE AND LastVersionAnswered__c = TRUE) OR (ReinsurerStatus__c = :statusSetup))) '; 

    
                String queryLeadParentRequest = 'select Id, Treaty__r.Name, Treaty__r.Layer__c, Program__r.PrincipalCedingCompany__c, Program__r.UwYear__c, Program__r.TECH_StageName__c, Section__r.CededPremium__c'
                        + ', Broker__r.Name, TECH_BrokerName__c, TECH_ReinsurerName__c, Program__r.LTA__c, Program__r.Name, Program__r.LossDeposit__c, Program__r.InceptionDate__c, Program__r.Expirydate__c, Section__r.TECH_TypeofTreaty__c, Section__r.QuoteType__c, Section__r.SectionNumber__c'
                        + ', Section__r.Cession_Perc__c, Section__r.Name, Section__r.Currency__c, Section__r.Unlimited__c, Treaty__r.Deductions_Perc__c, ToLabel(Treaty__r.PremiumDeposit__c), Treaty__r.TypeofTreaty__c, toLabel(Treaty__r.LossDeposit__c)'
                        + ', Section__r.EventLimit__c, Section__r.RetentionLine__c, Section__r.TAL__c, Section__r.Retention__c, Section__r.CessionAmount__c, Section__r.TECH_Reinstatement__c'
                        + ', Section__r.RetentionAmount__c,Section__r.Reinstatements__c, Section__r.TotalEPI__c, Section__r.Nature__c, Section__r.LineAmount__c, Section__r.CededLines__c'
                        + ', Section__r.Capacity__c, Section__r.Limit__c, Section__r.Deductible__c, Section__r.AAD__c, Section__r.AAL__c, TECH_SectionName__c,LastModifiedBy.Email, CreatedBy.Email '
                        + ', Section__r.LimitPercent__c, Section__r.DeductiblePercent__c, Section__r.MaxLimitAmount__c, Section__r.MinLimitAmount__c, Section__r.ExpectedMDP__c, Section__r.ExpectedDP__c, Section__r.ExpectedMP__c, Section__r.CommentsReinsurerBroker__c, '//RRA - ticket 1095 - 01082023
                        + strRequestFields
                        + ' from Request__c where (Program__c = :programId AND Reinsurer__c = :reinsurerId AND Broker__c = :brokerId AND RecordTypeId = :reqLeadRecordTypeId  AND ((LastVersionSent__c = TRUE AND LastVersionAnswered__c = TRUE) OR (ReinsurerStatus__c = :statusSetup))) '; 
    
    
                lstParentRequest = Database.query(queryLeadParentRequest);
    
                for(Request__c requestParent : lstParentRequest){
                    mapParentRequestByTreatyId.put(requestParent.Treaty__c, requestParent);
                }
    
                Set<Id> setChildRequestId = new Set<Id>();
    
                for(LeadRequestSelection__c leadRequestSelection : [SELECT Id, Name, LeadRequestChild__c
                                                                    FROM LeadRequestSelection__c
                                                                    WHERE LeadRequestParent__c IN :lstParentRequest]){
                    setChildRequestId.add(leadRequestSelection.LeadRequestChild__c);
                }
    
               // SRA - 928
               String queryLeadRequest = 'select Id, Treaty__r.Name, Treaty__r.Layer__c, Program__r.PrincipalCedingCompany__c, Program__r.UwYear__c, Program__r.TECH_StageName__c'
               + ', Broker__r.Name, TECH_BrokerName__c, TECH_ReinsurerName__c, Program__r.LTA__c, Section__r.TECH_TypeofTreaty__c, Section__r.QuoteType__c, Section__r.SectionNumber__c, Treaty__r.PremiumDeposit__c'
               + ', Section__r.Cession_Perc__c, Section__r.Name, Section__r.Currency__c, Section__r.Unlimited__c, Treaty__r.TypeofTreaty__c, ToLabel(Treaty__r.LossDeposit__c)'
               + ', Section__r.EventLimit__c, Section__r.RetentionLine__c, Section__r.TAL__c, Section__r.Retention__c, Section__r.CessionAmount__c, Treaty__r.Deductions_Perc__c, Program__r.Name, toLabel(Program__r.LossDeposit__c), Program__r.InceptionDate__c, Program__r.Expirydate__c'
               + ', Section__r.RetentionAmount__c, Section__r.Reinstatements__c, Section__r.TotalEPI__c, Section__r.Nature__c, Section__r.LineAmount__c, Section__r.CededLines__c, Section__r.CededPremium__c'
               + ', Section__r.Capacity__c, Section__r.Limit__c, Section__r.Deductible__c, Section__r.AAD__c, Section__r.AAL__c, TECH_SectionName__c, Section__r.TECH_Reinstatement__c, LastModifiedBy.Email, CreatedBy.Email '
               + ', Section__r.LimitPercent__c, Section__r.DeductiblePercent__c, Section__r.MaxLimitAmount__c, Section__r.MinLimitAmount__c, Section__r.ExpectedMDP__c, Section__r.ExpectedDP__c, Section__r.ExpectedMP__c, Section__r.CommentsReinsurerBroker__c, '//RRA - ticket 1095 - 01082023
               + strRequestFields
               + ' from Request__c where (Id IN :setChildRequestId) ';
    
                if(requestPhaseType == '3'){
                    //phase type = 'Quote'
                    lstRequestAll = Database.query(queryQuoteRequest);
                }
                else if(requestPhaseType == '4'){
                    reinsName = lstParentRequest[0].TECH_ReinsurerName__c ;//MRA W-0953 8/09/2022 
                    brokerName = lstParentRequest[0].TECH_BrokerName__c!=null?lstParentRequest[0].TECH_BrokerName__c:null ;//MRA W-0953 8/09/2022 
                    //phase type = 'Lead'
                    lstRequestAll = Database.query(queryLeadRequest);
                }
            }
            else if(requestPhaseType == '5'){
                //phase type = 'Placement'
                Set<Id> setPlacementTreatyId = new Set<Id>();
    
                // SRA - 928
                String queryPlacementRequest = 'select Id, Treaty__r.Name, Treaty__r.Layer__c, Program__r.PrincipalCedingCompany__c, Program__r.UwYear__c, Program__r.TECH_StageName__c, Section__r.CededPremium__c'
                        + ', Broker__r.Name, TECH_BrokerName__c, TECH_ReinsurerName__c, Program__r.LTA__c, Program__r.Name, toLabel(Program__r.LossDeposit__c), Program__r.InceptionDate__c, Program__r.Expirydate__c, Section__r.TECH_TypeofTreaty__c, Section__r.QuoteType__c, Section__r.SectionNumber__c'
                        + ', Section__r.Cession_Perc__c, Section__r.Name, Section__r.Currency__c, Section__r.Unlimited__c, Treaty__r.Deductions_Perc__c, ToLabel(Treaty__r.PremiumDeposit__c), Treaty__r.TypeofTreaty__c, toLabel(Treaty__r.LossDeposit__c)'
                        + ', Section__r.EventLimit__c, Section__r.RetentionLine__c, Section__r.TAL__c, Section__r.Retention__c, Section__r.CessionAmount__c, Section__r.TECH_Reinstatement__c'
                        + ', Section__r.RetentionAmount__c,Section__r.Reinstatements__c, Section__r.TotalEPI__c, Section__r.Nature__c, Section__r.LineAmount__c, Section__r.CededLines__c'
                        + ', Section__r.Capacity__c, Section__r.Limit__c, Section__r.Deductible__c, Section__r.AAD__c, Section__r.AAL__c, TECH_SectionName__c, LastModifiedBy.Email, CreatedBy.Email '
                        + ', Section__r.LimitPercent__c, Section__r.DeductiblePercent__c, Section__r.MaxLimitAmount__c, Section__r.MinLimitAmount__c, Section__r.ExpectedMDP__c, Section__r.ExpectedDP__c, Section__r.ExpectedMP__c, Section__r.CommentsReinsurerBroker__c, '//RRA - ticket 1095 - 01082023
                        + strRequestFields
                        + ' from Request__c where (Program__c = :programId AND Reinsurer__c = :reinsurerId AND RecordTypeId = :reqPlacementRecordTypeId AND ((LastVersionSent__c = TRUE AND LastVersionAnswered__c = TRUE) OR (ReinsurerStatus__c = :statusSetup))) '; 
    
                queryPlacementRequest += ' AND Broker__c = :brokerId ';
    
                List<Request__c> lstPlacementRequest = Database.query(queryPlacementRequest);
    
                reinsName = lstPlacementRequest[0].TECH_ReinsurerName__c ;//MRA W-0953 8/09/2022 
                brokerName = lstPlacementRequest[0].TECH_BrokerName__c!=null?lstPlacementRequest[0].TECH_BrokerName__c:null ;//MRA W-0953 8/09/2022 
                for(Request__c placementRequest : lstPlacementRequest){
                    setPlacementTreatyId.add(placementRequest.Treaty__c);
                    mapParentRequestByTreatyId.put(placementRequest.Treaty__c, placementRequest);
                }
    
                mapResults.put('mapParentRequestByTreatyId', mapParentRequestByTreatyId);
    
                List<Request__c> lstParentLeadRequests = [SELECT Id, Name, Treaty__c, LastModifiedDate, ReinsurerStatus__c, TECH_LastAnswerDate__c, ResponseDate__c, Reinsurer__c, Broker__c, RecordType.Name
                                                            FROM Request__c
                                                            WHERE Treaty__c IN :setPlacementTreatyId 
                                                            AND RecordTypeId = :reqLeadRecordTypeId 
                                                            AND Reinsurer__c != NULL
                                                            AND ((LastVersionSent__c = TRUE AND LastVersionAnswered__c = TRUE) OR (ReinsurerStatus__c = :statusSetup))];
    
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
    
                
                for(LeadRequestSelection__c leadRequestSelection : [SELECT Id, Name, LeadRequestChild__c
                                                                    FROM LeadRequestSelection__c
                                                                    WHERE LeadRequestParent__c IN :setParentLeadRequestId]){
                    setPlacementChildRequestId.add(leadRequestSelection.LeadRequestChild__c);
                }
    
                // SRA - 928
                String queryLeadRequestforPlacement = 'select Id, Treaty__r.Name, Treaty__r.Layer__c, Program__r.PrincipalCedingCompany__c, Program__r.UwYear__c, Program__r.TECH_StageName__c, Section__r.TECH_Reinstatement__c'
                        + ', Broker__r.Name, TECH_BrokerName__c, TECH_ReinsurerName__c, Program__r.LTA__c, Section__r.TECH_TypeofTreaty__c, Section__r.QuoteType__c, Section__r.SectionNumber__c, Treaty__r.Deductions_Perc__c, Treaty__r.PremiumDeposit__c'
                        + ', Section__r.Cession_Perc__c, Section__r.Name, Section__r.Currency__c, Section__r.Unlimited__c, Treaty__r.TypeofTreaty__c, ToLabel(Treaty__r.LossDeposit__c)'
                        + ', Section__r.EventLimit__c, Section__r.RetentionLine__c, Section__r.TAL__c, Section__r.Retention__c, Section__r.CessionAmount__c,  Program__r.Name, ToLabel(Program__r.LossDeposit__c), Program__r.InceptionDate__c, Program__r.Expirydate__c'
                        + ', Section__r.RetentionAmount__c, Section__r.TotalEPI__c, Section__r.Nature__c, Section__r.LineAmount__c, Section__r.CededLines__c, Section__r.CededPremium__c'
                        + ', Section__r.Capacity__c, Section__r.Reinstatements__c, Section__r.Limit__c, Section__r.Deductible__c, Section__r.AAD__c, Section__r.AAL__c, TECH_SectionName__c'
                        + ', Section__r.LimitPercent__c, Section__r.DeductiblePercent__c, Section__r.MaxLimitAmount__c, Section__r.MinLimitAmount__c, Section__r.ExpectedMDP__c, Section__r.ExpectedDP__c, Section__r.ExpectedMP__c, Section__r.CommentsReinsurerBroker__c, '//RRA - ticket 1095 - 01082023
                        + strRequestFields
                        + ' from Request__c where (Id IN :setPlacementChildRequestId AND ((LastVersionSent__c = TRUE AND LastVersionAnswered__c = TRUE) OR (ReinsurerStatus__c = :statusSetup)) AND Program__c = :programId AND Reinsurer__c = null AND RecordTypeId = :reqLeadRecordTypeId) ';
    
    
                lstRequestAll = Database.query(queryLeadRequestforPlacement);
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
            mapResults.put('accActive', accActive);
            mapResults.put('pccActive', pccActive);
            mapResults.put('lstTreaties', lstTreaties);
            mapResults.put('mapSectionRequestByTreatyId', mapSectionRequestByTreatyId);
            mapResults.put('lstRequestAll', lstRequestAll);
            mapResults.put('requestPhaseType', requestPhaseType);
            mapResults.put('mapParentRequestByTreatyId', mapParentRequestByTreatyId);
            mapResults.put('lstParentLeadRequest', lstParentRequest);
            mapResults.put('selectedRequestDetail', requestById);
            mapResults.put('setParentLeadRequestId', setParentLeadRequestId);
            mapResults.put('setPlacementChildRequestId', setPlacementChildRequestId);
            mapResults.put('isProgRenewedAndIdentical', isProgRenewedAndIdentical);
            mapResults.put('reinsName', reinsName);//MRA W-0953 8/09/2022 
            mapResults.put('brokerName', brokerName);//MRA W-0953 8/09/2022 
            mapResults.put('isActivatedDeactivatedProg', isActivatedDeactivatedProg); //RRA - ticket 585 - 060320233
    
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
        * @description Method to get save Request
        * @param List<Request__c> lstRequest
        * @param String phaseType
        * @param List<Request__c> lstParentRequest
        * @return Map<String, Object>
        */
        @AuraEnabled
        public static Map<String, Object> saveRequestRecord(List<Request__c> lstRequest, String phaseType, List<Request__c> lstParentRequest, Id selectIdRequest, Date quotedeadline, Boolean isChangedDateQuote) { //RRA - ticket 1574 - 06102023
            System.debug('begin saveRequestRecord');
            System.debug('selectIdRequest == ' + selectIdRequest);
            System.debug('quotedeadline == ' + quotedeadline);
            System.debug('lstRequest == ' + lstRequest);
            Map<String, Object> mapResults = new Map<String, Object>();
            Savepoint sp = Database.setSavepoint();
            Boolean isAccept = false;
            Boolean isDateQuoteValChanged = false;
            Decimal valueFixedCom;
            map<Id, Request__c> mapReqOld = new map<Id, Request__c>();
            map<Id, Request__c> mapReqOldParent = new map<Id, Request__c>();
            List<Request__c> lstRequestUpdatedLastVers = new List <Request__c>(); //RRA - ticket 1541 - 05072023
            List<Request__c> lstRequestUpdatedOrig = new List <Request__c>(); //RRA - ticket 1541 - 05072023 
            List<Request__c> lstReqUpdateIconTimeout = new List <Request__c>(); //RRA - ticket 1541 - 05072023
            String valueReinsurerStatus; //RRA VERSIONING
            Date valueResponseDate; //RRA VERSIONING
            
            if (isChangedDateQuote == null){
                isDateQuoteValChanged = false;
            }else if(isChangedDateQuote){
                isDateQuoteValChanged = true;
            }else if(isChangedDateQuote == false){
                isDateQuoteValChanged = false;
            }

            for (Request__c req : [SELECT Id, ReinsurerStatus__c, FixedRate__c, MinRate__c, QuoteOnBehalf__c, LeadOnBehalf__c, PlacementOnBehalf__c,  WrittenShare__c, WrittenShareResponse__c, CommentsResponse__c, ReinsurerExpenses__c, LossCarryingForward__c, OrUnlimited__c, LossCorridorPart__c, LossCorridorMaxLR__c, LossCorridorMinLR__c, NoClaimBonus__c,NoClaimBonusAmount__c, ProfitCommission__c, MaxRate__c, ProvisionalRate__c, FlatPremium__c, MDP__c, FixedCommission__c, MinVarCommission__c, MaxVarCommission__c, ProvisionalCommission__c, PerHeadPremium__c, MinPerHeadAmount__c, MaxPerHeadAmount__c, ProvisionalPerHeadPremium__c, EstimatedReinsurancePremium__c, EstimatedInsurancePremium__c FROM Request__c WHERE Id In:lstRequest]){
                mapReqOld.put(req.Id, req);
            }
    
    
            for (Request__c req : [SELECT Id, FixedRate__c,PlacementParticipation__c,ReasonRefusal__c, WrittenShare__c,MinRate__c, WrittenShareResponse__c, QuoteOnBehalf__c, LeadOnBehalf__c, PlacementOnBehalf__c,CommentsResponse__c, ReinsurerExpenses__c, LossCarryingForward__c, OrUnlimited__c, LossCorridorPart__c, LossCorridorMaxLR__c, LossCorridorMinLR__c, NoClaimBonus__c,NoClaimBonusAmount__c, ProfitCommission__c, MaxRate__c, ProvisionalRate__c, FlatPremium__c, MDP__c, FixedCommission__c, MinVarCommission__c, MaxVarCommission__c, ProvisionalCommission__c, PerHeadPremium__c, MinPerHeadAmount__c, MaxPerHeadAmount__c, ProvisionalPerHeadPremium__c, EstimatedReinsurancePremium__c, EstimatedInsurancePremium__c FROM Request__c WHERE Id In:lstParentRequest]){// MRA 1104 5/10/2022
                mapReqOldParent.put(req.Id, req);
            }
    
            try {
                List<Request__c> lstNewVersionRequest = new List<Request__c>();
                List<Request__c> lstOriginalRequestToUpdate = new List<Request__c>();
                Map<Id, String> mapReinsurerStatusByOriginalReqId = new Map<Id, String>();
                Set<Id> setAllAnsweredLeadId = new Set<Id>();
                Set<Id> setAllParentLeadId = new Set<Id>();
                Map<Id, Request__c> mapRequestNewVersionById = new Map<Id, Request__c>();
                List<Id> lstIdReqOrig = new List<Id>(); //RRA - ticket 1541 - 05072023
    
                for(Request__c req : lstRequest){
                    //RRA - ticket 1541 - 17072023 - Update lastVersion Req
                    if(phaseType == 'Quote'){
                        System.debug('req.Id == ' + req.Id +'====> ' +'selectIdRequest == ' + selectIdRequest);
                        //if (req.Id == selectIdRequest){
                            req.QuoteDeadline__c = quotedeadline;
                            req.isChk2DaysEmailReminder__c = isDateQuoteValChanged; //RRA - ticket 1574 - 06102023
                            req.UtilityIconDate__c = AP_Constant.iconDate;
                            lstIdReqOrig.add(req.OriginalRequest__c);
                            lstRequestUpdatedLastVers.add(req);
                        //}
                        //RRA - ticket 1541 - 177072023 - Update Original Req
                        for (Request__c  request : [SELECT Id, OriginalRequest__c, QuoteDeadline__c, isChk2DaysEmailReminder__c FROM Request__c WHERE Id IN:lstIdReqOrig]){
                            if (request.OriginalRequest__c == null){
                                request.QuoteDeadline__c = quotedeadline;
                                req.isChk2DaysEmailReminder__c = isDateQuoteValChanged; //RRA - ticket 1574 - 06102023
                                request.UtilityIconDate__c = AP_Constant.iconDate;
                                lstRequestUpdatedOrig.add(request);
                            }
                        }
                    }
                    if (req.ReinsurerStatus__c != AP_Constant.statusSetup && req.ReinsurerStatus__c != AP_Constant.statusTimeout) {
    
                        /* if Phase Type is Quote
                            if Quote__c == 'Quote' -> Reinsurer Status = 'Answered'
                            if Quote__c == 'Refusal' -> Reinsurer Status = 'Refused'
                        */
                        req.Key_Upsert_Request__c = req.Id + '_' + req.OriginalRequest__c;
                        if(phaseType == 'Quote'){
                            System.debug('Phase is Quote');
                            //req.ResponseDate__c = System.today();
                            //RRA VERSIONING
                            valueResponseDate = req.ResponseDate__c;
                            if (req.ResponseDate__c != null){
                                req.ResponseDate__c = valueResponseDate;
                            }else{
                                req.ResponseDate__c = System.today();
                            }
                            if (req.Quote__c == '1') {
                                valueReinsurerStatus = AP_Constant.statusAnswered; //RRA VERSIONING
                            }else if (req.Quote__c == '2') {
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
    
                            //Create new Version Request + Update Original Request
                            // req.VersionMajor__c = 1;
    
                            Decimal valueMinor = req.VersionMinor__c + 1;
                            valueFixedCom = req.FixedCommission__c;
                            System.debug('valueFixedCom 11 == ' + valueFixedCom);
                            Decimal valueFixedRate = req.FixedRate__c;
                            Boolean isQuoteOnBehalf = req.QuoteOnBehalf__c;
                            Boolean isPlacementOnBehalf = req.PlacementOnBehalf__c;
                            Boolean isLeadOnBehalf = req.LeadOnBehalf__c;
                            Decimal valueWrittenShareResponse = req.WrittenShareResponse__c;
                            Decimal valueWrittenShare = req.WrittenShare__c;
                            String valueCommentResponse = req.CommentsResponse__c;
                            Decimal valueProfitCommission = req.ProfitCommission__c;
                            Decimal valueMinRate = req.MinRate__c;
                            Decimal valueMaxRate = req.MaxRate__c;
                            Decimal valueProvisionalRate = req.ProvisionalRate__c;
                            Decimal valueFlatPremium = req.FlatPremium__c ;
                            Decimal valueMDP = req.MDP__c ;
                            Decimal valueMinVarCommission = req.MinVarCommission__c;
                            Decimal valueMaxVarCommission = req.MaxVarCommission__c;
                            Decimal valueProvisionalCommission= req.ProvisionalCommission__c;
                            Decimal valuePerHeadPremium = req.PerHeadPremium__c ;
                            Decimal valueMinPerHeadAmount = req.MinPerHeadAmount__c ;
                            Decimal valueMaxPerHeadAmount = req.MaxPerHeadAmount__c  ;
                            Decimal valueProvisionalPerHeadPremium = req.ProvisionalPerHeadPremium__c ;
                            Decimal valueEstimatedReinsurancePremium = req.EstimatedReinsurancePremium__c  ;
                            Decimal valueEstimatedInsurancePremium = req.EstimatedInsurancePremium__c  ;

                            Decimal valueReinsurerExpenses = req.ReinsurerExpenses__c  ;
                            Decimal valueLossCarryingForward = req.LossCarryingForward__c  ;
                            Boolean isOrUnlimited = req.OrUnlimited__c  ;
                            Decimal valueLossCorridorPart = req.LossCorridorPart__c  ;
                            Decimal valueLossCorridorMaxLR = req.LossCorridorMaxLR__c  ;
                            Decimal valueLossCorridorMinLR = req.LossCorridorMinLR__c  ;
                            Decimal valueNoClaimBonus = req.NoClaimBonus__c  ;
                            Decimal valueNoClaimBonusAmount = req.NoClaimBonus__c  ;
    
                            System.debug('valueMinor == ' + valueMinor);
                            req.LastVersionSent__c = false;
                            req.LastVersionAnswered__c = false;
                            //req.VersionMinor__c = req.VersionMinor__c + 1;
    
                            System.debug('req.VersionMinor__c == ' + req.VersionMinor__c);
                            System.debug('req.FixedCommission__c == ' + req.FixedCommission__c);
                        
                            if(req.OriginalRequest__c != null){
                                Request__c originalRequest = req.clone(false, false, false, false);
                                originalRequest.Id = req.OriginalRequest__c;
                                originalRequest.OriginalRequest__c = null;
                                lstOriginalRequestToUpdate.add(originalRequest);
                            }
    
                            //RRA - 1104 - keep old values Decimal after clone - 27/09/2022
                            if (req.ProfitCommission__c != null || req.fixedCommission__c != null || req.FixedRate__c != null  || req.MinRate__c != null  || req.MaxRate__c != null  || req.ProvisionalRate__c != null  || req.FlatPremium__c != null  || req.MDP__c != null  || req.MinVarCommission__c != null  || req.MaxVarCommission__c != null  || req.ProvisionalCommission__c != null  || req.PerHeadPremium__c != null  || req.MinPerHeadAmount__c != null  || req.MaxPerHeadAmount__c != null  || req.ProvisionalPerHeadPremium__c != null  || req.EstimatedReinsurancePremium__c != null  || req.EstimatedInsurancePremium__c != null || req.WrittenShareResponse__c != null || req.WrittenShare__c != null || req.CommentsResponse__c != null || req.ReinsurerExpenses__c != null || req.LossCarryingForward__c != null || req.LossCorridorPart__c != null || req.LossCorridorMaxLR__c != null || req.LossCorridorMinLR__c != null || req.NoClaimBonus__c != null || req.NoClaimBonusAmount__c != null)  {
                                req.ReinsurerExpenses__c = mapReqOld.get(req.Id).ReinsurerExpenses__c != null ?  mapReqOld.get(req.Id).ReinsurerExpenses__c  : null;
                                req.LossCarryingForward__c = mapReqOld.get(req.Id).LossCarryingForward__c != null ?  mapReqOld.get(req.Id).LossCarryingForward__c  : null;
                                req.OrUnlimited__c = mapReqOld.get(req.Id).OrUnlimited__c;
                                req.LossCorridorPart__c = mapReqOld.get(req.Id).LossCorridorPart__c != null ?  mapReqOld.get(req.Id).LossCorridorPart__c  : null;
                                req.LossCorridorMaxLR__c = mapReqOld.get(req.Id).LossCorridorMaxLR__c != null ?  mapReqOld.get(req.Id).LossCorridorMaxLR__c  : null;
                                req.LossCorridorMinLR__c = mapReqOld.get(req.Id).LossCorridorMinLR__c != null ?  mapReqOld.get(req.Id).LossCorridorMinLR__c  : null;
                                req.NoClaimBonus__c = mapReqOld.get(req.Id).NoClaimBonus__c != null ?  mapReqOld.get(req.Id).NoClaimBonus__c  : null;
                                req.NoClaimBonusAmount__c = mapReqOld.get(req.Id).NoClaimBonusAmount__c != null ?  mapReqOld.get(req.Id).NoClaimBonusAmount__c  : null;
                                req.QuoteOnBehalf__c = mapReqOld.get(req.Id).QuoteOnBehalf__c;
                                req.LeadOnBehalf__c = mapReqOld.get(req.Id).LeadOnBehalf__c;
                                req.PlacementOnBehalf__c = mapReqOld.get(req.Id).PlacementOnBehalf__c;
                                req.ProfitCommission__c = mapReqOld.get(req.Id).ProfitCommission__c != null ?  mapReqOld.get(req.Id).ProfitCommission__c  : null;
                                req.WrittenShareResponse__c = mapReqOld.get(req.Id).WrittenShareResponse__c != null ?  mapReqOld.get(req.Id).WrittenShareResponse__c  : null;
                                req.WrittenShare__c = mapReqOld.get(req.Id).WrittenShare__c != null ?  mapReqOld.get(req.Id).WrittenShare__c  : null;
                                req.CommentsResponse__c = mapReqOld.get(req.Id).CommentsResponse__c != null ?  mapReqOld.get(req.Id).CommentsResponse__c  : null;
                                req.fixedCommission__c = mapReqOld.get(req.Id).fixedCommission__c != null ?  mapReqOld.get(req.Id).fixedCommission__c  : null;
                                req.FixedRate__c = mapReqOld.get(req.Id).FixedRate__c != null ?  mapReqOld.get(req.Id).FixedRate__c  : null;
                                req.MinRate__c = mapReqOld.get(req.Id).MinRate__c != null ?  mapReqOld.get(req.Id).MinRate__c  : null;
                                req.MaxRate__c = mapReqOld.get(req.Id).MaxRate__c != null ?  mapReqOld.get(req.Id).MaxRate__c  : null;
                                req.ProvisionalRate__c = mapReqOld.get(req.Id).ProvisionalRate__c != null ?  mapReqOld.get(req.Id).ProvisionalRate__c  : null;
                                req.FlatPremium__c = mapReqOld.get(req.Id).FlatPremium__c != null ?  mapReqOld.get(req.Id).FlatPremium__c  : null;
                                req.MDP__c = mapReqOld.get(req.Id).MDP__c != null ?  mapReqOld.get(req.Id).MDP__c  : null;
                                req.MinVarCommission__c = mapReqOld.get(req.Id).MinVarCommission__c != null ?  mapReqOld.get(req.Id).MinVarCommission__c  : null;
                                req.MaxVarCommission__c = mapReqOld.get(req.Id).MaxVarCommission__c != null ?  mapReqOld.get(req.Id).MaxVarCommission__c  : null;
                                req.ProvisionalCommission__c = mapReqOld.get(req.Id).ProvisionalCommission__c != null ?  mapReqOld.get(req.Id).ProvisionalCommission__c  : null;
                                req.PerHeadPremium__c = mapReqOld.get(req.Id).PerHeadPremium__c != null ?  mapReqOld.get(req.Id).PerHeadPremium__c  : null;
                                req.MinPerHeadAmount__c = mapReqOld.get(req.Id).MinPerHeadAmount__c != null ?  mapReqOld.get(req.Id).MinPerHeadAmount__c  : null;
                                req.MaxPerHeadAmount__c = mapReqOld.get(req.Id).MaxPerHeadAmount__c != null ?  mapReqOld.get(req.Id).MaxPerHeadAmount__c  : null;
                                req.ProvisionalPerHeadPremium__c = mapReqOld.get(req.Id).ProvisionalPerHeadPremium__c != null ?  mapReqOld.get(req.Id).ProvisionalPerHeadPremium__c  : null;
                                req.EstimatedReinsurancePremium__c = mapReqOld.get(req.Id).EstimatedReinsurancePremium__c != null ?  mapReqOld.get(req.Id).EstimatedReinsurancePremium__c  : null;
                                req.EstimatedInsurancePremium__c = mapReqOld.get(req.Id).EstimatedInsurancePremium__c != null ?  mapReqOld.get(req.Id).EstimatedInsurancePremium__c  : null;
                            }
                            //req.ReinsurerStatus__c =  mapReqOld.get(req.Id).ReinsurerStatus__c;
                            Request__c newVersionRequest = req.clone(false, false, false, false);
                                // RRA - 1104
                            newVersionRequest.VersionMinor__c = valueMinor;
                            newVersionRequest.FixedCommission__c = valueFixedCom != null ? valueFixedCom : null;
    
                            //RRA - 1104 - keep values Decimal after clone - 27/09/2022
                            newVersionRequest.WrittenShareResponse__c = valueWrittenShareResponse != null ?  valueWrittenShareResponse : null;
                            newVersionRequest.WrittenShare__c = valueWrittenShare != null ?  valueWrittenShare : null;
                            newVersionRequest.CommentsResponse__c = valueCommentResponse != null ?  valueCommentResponse : null;
                            newVersionRequest.QuoteOnBehalf__c = true;
                            newVersionRequest.LeadOnBehalf__c = isLeadOnBehalf;
                            newVersionRequest.PlacementOnBehalf__c = isPlacementOnBehalf;
                            newVersionRequest.ReinsurerExpenses__c = valueReinsurerExpenses != null ?  valueReinsurerExpenses : null;
                            newVersionRequest.LossCarryingForward__c = valueLossCarryingForward != null ?  valueLossCarryingForward : null;
                            newVersionRequest.OrUnlimited__c = isOrUnlimited;
                            newVersionRequest.LossCorridorPart__c = valueLossCorridorPart != null ?  valueLossCorridorPart : null;
                            newVersionRequest.LossCorridorMaxLR__c = valueLossCorridorMaxLR != null ?  valueLossCorridorMaxLR : null;
                            newVersionRequest.LossCorridorMinLR__c = valueLossCorridorMinLR != null ?  valueLossCorridorMinLR : null;
                            newVersionRequest.NoClaimBonus__c = valueNoClaimBonus != null ?  valueNoClaimBonus : null;
                            newVersionRequest.NoClaimBonusAmount__c = valueNoClaimBonusAmount != null ?  valueNoClaimBonusAmount : null;
                            newVersionRequest.ProfitCommission__c = valueProfitCommission != null ?  valueProfitCommission : null;
                            newVersionRequest.FixedRate__c = valueFixedRate != null ?  valueFixedRate : null;
                            newVersionRequest.MinRate__c = valueMinRate != null ?  valueMinRate : null;
                            newVersionRequest.MaxRate__c = valueMaxRate != null ?  valueMaxRate : null;
                            newVersionRequest.ProvisionalRate__c = valueProvisionalRate != null ?  valueProvisionalRate : null;
                            newVersionRequest.FlatPremium__c = valueFlatPremium != null ?  valueFlatPremium : null;
                            newVersionRequest.MDP__c = valueMDP != null ?  valueMDP : null;
                            newVersionRequest.MinVarCommission__c = valueMinVarCommission != null ?  valueMinVarCommission : null;
                            newVersionRequest.MaxVarCommission__c = valueMaxVarCommission != null ?  valueMaxVarCommission : null;
                            newVersionRequest.ProvisionalCommission__c = valueProvisionalCommission != null ?  valueProvisionalCommission : null;
                            newVersionRequest.PerHeadPremium__c = valuePerHeadPremium != null ?  valuePerHeadPremium : null;
                            newVersionRequest.MinPerHeadAmount__c = valueMinPerHeadAmount != null ?  valueMinPerHeadAmount : null;
                            newVersionRequest.MaxPerHeadAmount__c = valueMaxPerHeadAmount != null ?  valueMaxPerHeadAmount : null;
                            newVersionRequest.ProvisionalPerHeadPremium__c = valueProvisionalPerHeadPremium != null ?  valueProvisionalPerHeadPremium : null;
                            newVersionRequest.EstimatedReinsurancePremium__c = valueEstimatedReinsurancePremium != null ?  valueEstimatedReinsurancePremium : null;
                            newVersionRequest.EstimatedInsurancePremium__c = valueEstimatedInsurancePremium != null ?  valueEstimatedInsurancePremium : null;
                            newVersionRequest.ReinsurerStatus__c = valueReinsurerStatus; //RRA VERSIONING
    
                            System.debug('newVersionRequest.VersionMinor__c == ' + newVersionRequest.VersionMinor__c);
                                                    
                            if(req.OriginalRequest__c == null){
                                newVersionRequest.OriginalRequest__c = req.Id;
                            }
                            else{
                                newVersionRequest.OriginalRequest__c = req.OriginalRequest__c;
                            }
    
                            newVersionRequest.LastVersionSent__c = true;
                            newVersionRequest.LastVersionAnswered__c = true;
                            newVersionRequest.TECH_Actor2Id__c = null;
                            lstNewVersionRequest.add(newVersionRequest);
                        }
    
                        /* if Phase Type is Lead
                            if checkbox Accept__c == 'True' -> Reinsurer Status = 'Answered'
                        */
    
                        if (phaseType == 'Lead') {
                            if (req.Accept__c == true) {
                                isAccept = true;
                                //req.ResponseDate__c = System.today();
                                //RRA VERSIONING
                                valueResponseDate = req.ResponseDate__c;
                                if (req.ResponseDate__c != null){
                                    req.ResponseDate__c = valueResponseDate;
                                }else{
                                    req.ResponseDate__c = System.today();
                                }
                                req.ReinsurerStatus__c = AP_Constant.statusAnswered;
                                setAllAnsweredLeadId.add(req.Id);
                            }
                            if (String.isNotBlank(req.CommentsResponse__c) || req.CommentsResponse__c != null){
                                req.Utility_Icon_Comment__c = AP_Constant.iconComment; //RRA - 939
                            }
                            if (String.isBlank(req.CommentsResponse__c) || req.CommentsResponse__c == null){
                                req.Utility_Icon_Comment__c = null; //RRA - 939
                            }
                        }
    
                        if(req.OriginalRequest__c == null){
                            mapReinsurerStatusByOriginalReqId.put(req.Id, req.ReinsurerStatus__c);
                        }
                        else{
                            mapReinsurerStatusByOriginalReqId.put(req.OriginalRequest__c, req.ReinsurerStatus__c);
                        }
                    }
                }
                System.debug('lstRequestUpdatedLastVers == ' + lstRequestUpdatedLastVers);
                System.debug('lstRequestUpdatedOrig == ' + lstRequestUpdatedOrig);
                System.debug('lstParentRequest 22 == ' + lstParentRequest);
                System.debug('phaseType 22 == ' + phaseType);
                for(Request__c req : lstParentRequest){
                    if(req.ReinsurerStatus__c != AP_Constant.statusSetup && req.ReinsurerStatus__c != AP_Constant.statusTimeout) {
    
                        /* if Phase Type is Quote
                            if Quote__c == 'Quote' -> Reinsurer Status = 'Answered'
                            if Quote__c == 'Refusal' -> Reinsurer Status = 'Refused'
                        */
    
                        if(phaseType == 'Quote'){
                            //req.ResponseDate__c = System.today();
                            //RRA VERSIONING
                            valueResponseDate = req.ResponseDate__c;
                            if (req.ResponseDate__c != null){
                                req.ResponseDate__c = valueResponseDate;
                            }else{
                                req.ResponseDate__c = System.today();
                            }
                            if (req.Quote__c == '1') {
                                valueReinsurerStatus = AP_Constant.statusAnswered;//RRA VERSIONING
                            }else if (req.Quote__c == '2') {
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
                        }
    
                        /* if Phase Type is Lead
                            if checkbox Accept__c == 'True' -> Reinsurer Status = 'Answered'
                        */
    
                        if (phaseType == 'Lead') {
                            if (req.Accept__c == true) {
                                isAccept = true;
                                //req.ResponseDate__c = System.today();
                                //RRA VERSIONING
                                valueResponseDate = req.ResponseDate__c;
                                if (req.ResponseDate__c != null){
                                    req.ResponseDate__c = valueResponseDate;
                                }else{
                                    req.ResponseDate__c = System.today();
                                }
                                req.ReinsurerStatus__c = AP_Constant.statusAnswered;
                                setAllAnsweredLeadId.add(req.Id);
                            }
                            if (String.isNotBlank(req.CommentsResponse__c) || req.CommentsResponse__c != null){
                                req.Utility_Icon_Comment__c = AP_Constant.iconComment; //RRA - 939
                            }
                            if (String.isBlank(req.CommentsResponse__c) || req.CommentsResponse__c == null){
                                req.Utility_Icon_Comment__c = null; //RRA - 939
                            }
                            setAllParentLeadId.add(req.Id);
                        }
    
                        /* if Phase Type is Placement
                            if PlacementParticipation__c == 'Yes' -> Reinsurer Status = 'Answered'
                            if PlacementParticipation__c == 'No' -> Reinsurer Status = 'Refused'
                        */
    
                        if(phaseType == 'Placement'){
                            //req.ResponseDate__c = System.today();
                            
                             //RRA VERSIONING
                             valueResponseDate = req.ResponseDate__c;
                             if (req.ResponseDate__c != null){
                                 req.ResponseDate__c = valueResponseDate;
                             }else{
                                 req.ResponseDate__c = System.today();
                             }
                             
                            req.ReceptionDate__c = System.today();
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
                                req.fixedCommission__c = null;
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
                            if (String.isNotBlank(req.CommentsResponse__c) || req.CommentsResponse__c != null){
                                req.Utility_Icon_Comment__c = AP_Constant.iconComment; //RRA - 939
                            }
                            if (String.isBlank(req.CommentsResponse__c) || req.CommentsResponse__c == null){
                                req.Utility_Icon_Comment__c = null; //RRA - 939
                            }
                        }
    
                        /* if Phase Type is Quote/Placement
                            Create new Version Request
                        */
                        if(phaseType == 'Quote' || phaseType == 'Placement'){
                            //RRA - 1104
                            Decimal valueMinor = req.VersionMinor__c + 1;
                            valueFixedCom = req.FixedCommission__c;
                            Decimal valueFixedRate = req.FixedRate__c;
                            Boolean isPlacementOnBehalf = req.PlacementOnBehalf__c;
                            Decimal valueProfitCommission = req.ProfitCommission__c;
                            Decimal valueMinRate = req.MinRate__c;
                            Decimal valueMaxRate = req.MaxRate__c;
                            Decimal valueProvisionalRate = req.ProvisionalRate__c;
                            Decimal valueFlatPremium = req.FlatPremium__c ;
                            Decimal valueMDP = req.MDP__c ;
                            Decimal valueMinVarCommission = req.MinVarCommission__c;
                            Decimal valueMaxVarCommission = req.MaxVarCommission__c;
                            Decimal valueProvisionalCommission= req.ProvisionalCommission__c;
                            Decimal valuePerHeadPremium = req.PerHeadPremium__c ;
                            Decimal valueMinPerHeadAmount = req.MinPerHeadAmount__c ;
                            Decimal valueMaxPerHeadAmount = req.MaxPerHeadAmount__c  ;
                            Decimal valueProvisionalPerHeadPremium = req.ProvisionalPerHeadPremium__c ;
                            Decimal valueEstimatedReinsurancePremium = req.EstimatedReinsurancePremium__c  ;
                            Decimal valueEstimatedInsurancePremium = req.EstimatedInsurancePremium__c  ;
                            Decimal valueWrittenShareResponse = req.WrittenShareResponse__c;
                            Decimal valueWrittenShare = req.WrittenShare__c;
                            String valueCommentResponse = req.CommentsResponse__c;

                            Decimal valueReinsurerExpenses = req.ReinsurerExpenses__c  ;
                            Decimal valueLossCarryingForward = req.LossCarryingForward__c  ;
                            Boolean isOrUnlimited = req.OrUnlimited__c  ;
                            Decimal valueLossCorridorPart = req.LossCorridorPart__c  ;
                            Decimal valueLossCorridorMaxLR = req.LossCorridorMaxLR__c  ;
                            Decimal valueLossCorridorMinLR = req.LossCorridorMinLR__c  ;
                            Decimal valueNoClaimBonus = req.NoClaimBonus__c  ;
                            Decimal valueNoClaimBonusAmount = req.NoClaimBonus__c  ;
                            System.debug('valueFixedCom 22 == ' + valueFixedCom);
                           
    
                            req.LastVersionSent__c = false;
                            req.LastVersionAnswered__c = false;
    
                            if(req.OriginalRequest__c != null){
                                Request__c originalRequest = req.clone(false, false, false, false);
                                originalRequest.Id = req.OriginalRequest__c;
                                originalRequest.OriginalRequest__c = null;
    
                                if(phaseType == 'Placement'){
                                    originalRequest.ReceptionDate__c = System.today();
                                }
                                
                                lstOriginalRequestToUpdate.add(originalRequest);
                            }
                            if (mapReqOld.get(req.Id)!=null && mapReqOldParent.get(req.Id)!=null && (req.ProfitCommission__c != null || req.fixedCommission__c != null || req.FixedRate__c != null  || req.MinRate__c != null  || req.MaxRate__c != null  || req.ProvisionalRate__c != null  || req.FlatPremium__c != null  || req.MDP__c != null  || req.MinVarCommission__c != null  || req.MaxVarCommission__c != null  || req.ProvisionalCommission__c != null  || req.PerHeadPremium__c != null  || req.MinPerHeadAmount__c != null  || req.MaxPerHeadAmount__c != null  || req.ProvisionalPerHeadPremium__c != null  || req.EstimatedReinsurancePremium__c != null  || req.EstimatedInsurancePremium__c != null || req.WrittenShareResponse__c != null || req.WrittenShare__c != null || req.CommentsResponse__c != null || req.ReinsurerExpenses__c != null || req.LossCarryingForward__c != null || req.LossCorridorPart__c != null || req.LossCorridorMaxLR__c != null || req.LossCorridorMinLR__c != null || req.NoClaimBonus__c != null || req.NoClaimBonusAmount__c != null)) {// MRA 1104 5/10/2022

                                //RRA - 1104 - keep old values Decimal after clone - 28/09/2022
                                req.ReinsurerExpenses__c = mapReqOld.get(req.Id).ReinsurerExpenses__c != null ?  mapReqOld.get(req.Id).ReinsurerExpenses__c  : null;
                                req.LossCarryingForward__c = mapReqOld.get(req.Id).LossCarryingForward__c != null ?  mapReqOld.get(req.Id).LossCarryingForward__c  : null;
                                req.OrUnlimited__c = mapReqOld.get(req.Id).OrUnlimited__c;
                                req.LossCorridorPart__c = mapReqOld.get(req.Id).LossCorridorPart__c != null ?  mapReqOld.get(req.Id).LossCorridorPart__c  : null;
                                req.LossCorridorMaxLR__c = mapReqOld.get(req.Id).LossCorridorMaxLR__c != null ?  mapReqOld.get(req.Id).LossCorridorMaxLR__c  : null;
                                req.LossCorridorMinLR__c = mapReqOld.get(req.Id).LossCorridorMinLR__c != null ?  mapReqOld.get(req.Id).LossCorridorMinLR__c  : null;
                                req.NoClaimBonus__c = mapReqOld.get(req.Id).NoClaimBonus__c != null ?  mapReqOld.get(req.Id).NoClaimBonus__c  : null;
                                req.NoClaimBonusAmount__c = mapReqOld.get(req.Id).NoClaimBonusAmount__c != null ?  mapReqOld.get(req.Id).NoClaimBonusAmount__c  : null;
                                req.PlacementOnBehalf__c = mapReqOld.get(req.Id).PlacementOnBehalf__c;
                                req.CommentsResponse__c = mapReqOld.get(req.Id).CommentsResponse__c != null ?  mapReqOld.get(req.Id).CommentsResponse__c  : null;
                                req.WrittenShareResponse__c = mapReqOld.get(req.Id).WrittenShareResponse__c != null ?  mapReqOld.get(req.Id).WrittenShareResponse__c  : null;
                                req.WrittenShare__c = mapReqOld.get(req.Id).WrittenShare__c != null ?  mapReqOld.get(req.Id).WrittenShare__c  : null;
                                req.ProfitCommission__c = mapReqOldParent.get(req.Id).ProfitCommission__c != null ?  mapReqOldParent.get(req.Id).ProfitCommission__c  : null;
                                req.fixedCommission__c = mapReqOldParent.get(req.Id).fixedCommission__c != null ?  mapReqOldParent.get(req.Id).fixedCommission__c  : null;
                                req.FixedRate__c = mapReqOldParent.get(req.Id).FixedRate__c != null ?  mapReqOldParent.get(req.Id).FixedRate__c  : null;
                                req.MinRate__c = mapReqOldParent.get(req.Id).MinRate__c != null ?  mapReqOldParent.get(req.Id).MinRate__c  : null;
                                req.MaxRate__c = mapReqOldParent.get(req.Id).MaxRate__c != null ?  mapReqOldParent.get(req.Id).MaxRate__c  : null;
                                req.ProvisionalRate__c = mapReqOldParent.get(req.Id).ProvisionalRate__c != null ?  mapReqOldParent.get(req.Id).ProvisionalRate__c  : null;
                                req.FlatPremium__c = mapReqOldParent.get(req.Id).FlatPremium__c != null ?  mapReqOldParent.get(req.Id).FlatPremium__c  : null;
                                req.MDP__c = mapReqOldParent.get(req.Id).MDP__c != null ?  mapReqOldParent.get(req.Id).MDP__c  : null;
                                req.MinVarCommission__c = mapReqOldParent.get(req.Id).MinVarCommission__c != null ?  mapReqOldParent.get(req.Id).MinVarCommission__c  : null;
                                req.MaxVarCommission__c = mapReqOldParent.get(req.Id).MaxVarCommission__c != null ?  mapReqOldParent.get(req.Id).MaxVarCommission__c  : null;
                                req.ProvisionalCommission__c = mapReqOldParent.get(req.Id).ProvisionalCommission__c != null ?  mapReqOldParent.get(req.Id).ProvisionalCommission__c  : null;
                                req.PerHeadPremium__c = mapReqOldParent.get(req.Id).PerHeadPremium__c != null ?  mapReqOldParent.get(req.Id).PerHeadPremium__c  : null;
                                req.MinPerHeadAmount__c = mapReqOldParent.get(req.Id).MinPerHeadAmount__c != null ?  mapReqOldParent.get(req.Id).MinPerHeadAmount__c  : null;
                                req.MaxPerHeadAmount__c = mapReqOldParent.get(req.Id).MaxPerHeadAmount__c != null ?  mapReqOldParent.get(req.Id).MaxPerHeadAmount__c  : null;
                                req.ProvisionalPerHeadPremium__c = mapReqOldParent.get(req.Id).ProvisionalPerHeadPremium__c != null ?  mapReqOldParent.get(req.Id).ProvisionalPerHeadPremium__c  : null;
                                req.EstimatedReinsurancePremium__c = mapReqOldParent.get(req.Id).EstimatedReinsurancePremium__c != null ?  mapReqOldParent.get(req.Id).EstimatedReinsurancePremium__c  : null;
                                req.EstimatedInsurancePremium__c = mapReqOldParent.get(req.Id).EstimatedInsurancePremium__c != null ?  mapReqOldParent.get(req.Id).EstimatedInsurancePremium__c  : null;
                            }
                            //req.ReinsurerStatus__c = mapReqOld.get(req.Id).ReinsurerStatus__c;
                            
    
                            Request__c newVersionRequest = req.clone(false, false, false, false);
                            if(phaseType == 'Placement'){// MRA 1104 5/10/2022
                                newVersionRequest.CommentsResponse__c = req.CommentsResponse__c ;
                                newVersionRequest.PlacementParticipation__c = req.PlacementParticipation__c ;
                                newVersionRequest.ReasonRefusal__c = req.ReasonRefusal__c ;
                                newVersionRequest.WrittenShare__c = req.WrittenShare__c  ;

                                if(mapReqOldParent.get(req.Id) != null){
                                    req.CommentsResponse__c = mapReqOldParent.get(req.Id).CommentsResponse__c ;
                                    req.PlacementParticipation__c = mapReqOldParent.get(req.Id).PlacementParticipation__c ;
                                    req.ReasonRefusal__c = mapReqOldParent.get(req.Id).ReasonRefusal__c ;
                                    req.WrittenShare__c = mapReqOldParent.get(req.Id).WrittenShare__c ;
                                }
                            }
                            //RRA - 1104
                            newVersionRequest.VersionMinor__c = valueMinor;
                            newVersionRequest.ReinsurerStatus__c = valueReinsurerStatus; //RRA VERSIONING
                            newVersionRequest.FixedCommission__c = valueFixedCom != null ? valueFixedCom : null;
    
                            //RRA - 1104 - keep values Decimal after clone - 28/09/2022
                            newVersionRequest.ReinsurerExpenses__c = valueReinsurerExpenses != null ?  valueReinsurerExpenses : null;
                            newVersionRequest.LossCarryingForward__c = valueLossCarryingForward != null ?  valueLossCarryingForward : null;
                            newVersionRequest.OrUnlimited__c = isOrUnlimited;
                            newVersionRequest.LossCorridorPart__c = valueLossCorridorPart != null ?  valueLossCorridorPart : null;
                            newVersionRequest.LossCorridorMaxLR__c = valueLossCorridorMaxLR != null ?  valueLossCorridorMaxLR : null;
                            newVersionRequest.LossCorridorMinLR__c = valueLossCorridorMaxLR != null ?  valueLossCorridorMaxLR : null;
                            newVersionRequest.NoClaimBonus__c = valueNoClaimBonus != null ?  valueNoClaimBonus : null;
                            newVersionRequest.NoClaimBonusAmount__c = valueNoClaimBonusAmount != null ?  valueNoClaimBonusAmount : null;
                            newVersionRequest.PlacementOnBehalf__c = true;
                            newVersionRequest.WrittenShareResponse__c = valueWrittenShareResponse != null ?  valueWrittenShareResponse : null;
                            newVersionRequest.WrittenShare__c = valueWrittenShare != null ?  valueWrittenShare : null;
                            newVersionRequest.CommentsResponse__c = valueCommentResponse != null ?  valueCommentResponse : null;
                            newVersionRequest.ProfitCommission__c = valueProfitCommission != null ?  valueProfitCommission : null;
                            newVersionRequest.FixedRate__c = valueFixedRate != null ?  valueFixedRate : null;
                            newVersionRequest.MinRate__c = valueMinRate != null ?  valueMinRate : null;
                            newVersionRequest.MaxRate__c = valueMaxRate != null ?  valueMaxRate : null;
                            newVersionRequest.ProvisionalRate__c = valueProvisionalRate != null ?  valueProvisionalRate : null;
                            newVersionRequest.FlatPremium__c = valueFlatPremium != null ?  valueFlatPremium : null;
                            newVersionRequest.MDP__c = valueMDP != null ?  valueMDP : null;
                            newVersionRequest.MinVarCommission__c = valueMinVarCommission != null ?  valueMinVarCommission : null;
                            newVersionRequest.MaxVarCommission__c = valueMaxVarCommission != null ?  valueMaxVarCommission : null;
                            newVersionRequest.ProvisionalCommission__c = valueProvisionalCommission != null ?  valueProvisionalCommission : null;
                            newVersionRequest.PerHeadPremium__c = valuePerHeadPremium != null ?  valuePerHeadPremium : null;
                            newVersionRequest.MinPerHeadAmount__c = valueMinPerHeadAmount != null ?  valueMinPerHeadAmount : null;
                            newVersionRequest.MaxPerHeadAmount__c = valueMaxPerHeadAmount != null ?  valueMaxPerHeadAmount : null;
                            newVersionRequest.ProvisionalPerHeadPremium__c = valueProvisionalPerHeadPremium != null ?  valueProvisionalPerHeadPremium : null;
                            newVersionRequest.EstimatedReinsurancePremium__c = valueEstimatedReinsurancePremium != null ?  valueEstimatedReinsurancePremium : null;
                            newVersionRequest.EstimatedInsurancePremium__c = valueEstimatedInsurancePremium != null ?  valueEstimatedInsurancePremium : null;
    
                            if(req.OriginalRequest__c == null){
                                newVersionRequest.OriginalRequest__c = req.Id;
                            }
                            else{
                                newVersionRequest.OriginalRequest__c = req.OriginalRequest__c;
                            }
                            if (String.isNotBlank(req.CommentsResponse__c) || req.CommentsResponse__c != null){
                                req.Utility_Icon_Comment__c = AP_Constant.iconComment; //RRA - 939
                            }
                            if (String.isBlank(req.CommentsResponse__c) || req.CommentsResponse__c == null){
                                req.Utility_Icon_Comment__c = null; //RRA - 939
                            }
    
                            newVersionRequest.LastVersionSent__c = true;
                            newVersionRequest.LastVersionAnswered__c = true;
                            newVersionRequest.TECH_Actor2Id__c = null;
    
                            System.debug('newVersionRequest.VersionMinor__c == ' + newVersionRequest.VersionMinor__c);
    
                            lstNewVersionRequest.add(newVersionRequest);
                        }
                    }
                    
    
                    if(req.OriginalRequest__c == null){
                        mapReinsurerStatusByOriginalReqId.put(req.Id, req.ReinsurerStatus__c);
                    }
                    else{
                        mapReinsurerStatusByOriginalReqId.put(req.OriginalRequest__c, req.ReinsurerStatus__c);
                    }
                }
    
                /* if Phase Type is Lead
                    if checkbox Accept__c == 'True' -> Reinsurer Status = 'Answered'
                */
    
                System.debug('setAllParentLeadId = ' + setAllParentLeadId);
                List<Request__c> lstLeadRequestToUpdate = new List<Request__c>();

                if (phaseType == 'Lead' && setAllParentLeadId.size() > 0) {
                    List<LeadRequestSelection__c> lstLeadRequestSelection = [SELECT Id, LeadRequestChild__r.Section__c, LeadRequestChild__r.Section__r.TECH_TreatyName__c
                                                                                    , LeadRequestChild__r.Section__r.Name, LeadRequestChild__c, LeadRequestParent__r.TECH_ReinsurerName__c
                                                                                FROM LeadRequestSelection__c
                                                                                WHERE LeadRequestParent__c IN :setAllParentLeadId];
                    //update Reinsurer status for Child Lead Request if Accept = True for Parent Lead Request
                    Set<Id> setChildLeadId = new Set<Id>();
    
                    System.debug('lstLeadRequestSelection__Origine = ' + lstLeadRequestSelection);
    
                    for(LeadRequestSelection__c leadRequestSelection: lstLeadRequestSelection){
                        setChildLeadId.add(leadRequestSelection.LeadRequestChild__c);
                    }
    
                    List<Request__c> lstChildLeadRequest = [SELECT Id, DateNextSending__c, OriginalRequest__c, ReinsurerStatus__c, ResponseDate__c, LeadOnBehalf__c, LastVersionAnswered__c, LastVersionSent__c FROM Request__c WHERE Id IN :setChildLeadId];
    
                    for(Request__c childLeadRequest : lstChildLeadRequest){
                        if(setAllAnsweredLeadId.contains(childLeadRequest.Id)){
                            childLeadRequest.ReinsurerStatus__c = AP_Constant.statusAnswered;
                            //childLeadRequest.ResponseDate__c = System.today();
                            
                             //RRA VERSIONING
                             valueResponseDate = childLeadRequest.ResponseDate__c;
                             if (childLeadRequest.ResponseDate__c != null){
                                childLeadRequest.ResponseDate__c = valueResponseDate;
                             }else{
                                childLeadRequest.ResponseDate__c = System.today();
                             }
                             
                            childLeadRequest.LeadOnBehalf__c = true;
    
                            if(childLeadRequest.OriginalRequest__c == null){
                            mapReinsurerStatusByOriginalReqId.put(childLeadRequest.Id, childLeadRequest.ReinsurerStatus__c);
                            }
                            else{
                                mapReinsurerStatusByOriginalReqId.put(childLeadRequest.OriginalRequest__c, childLeadRequest.ReinsurerStatus__c);
                            }
                        }
                    }
    
                    if(lstChildLeadRequest.size() > 0){
                        update lstChildLeadRequest;
                        
                        //RRA VERSIONING
                        List<Request__c> lstReqToUpdateChild = new  List<Request__c>();
                        for (Request__c child : lstChildLeadRequest){
                            if (child.ReinsurerStatus__c == 'Sent' && child.ResponseDate__c != null){
                                child.ResponseDate__c = null;
                            }else if (child.ReinsurerStatus__c == 'Sent' && child.DateNextSending__c != null){
                                child.DateNextSending__c =  child.DateNextSending__c;
                            }else if ((child.ReinsurerStatus__c == 'Answered' || child.ReinsurerStatus__c == 'Refused') && child.DateNextSending__c != null){
                                child.DateNextSending__c = null;
                            }
                            lstReqToUpdateChild.add(child);
                        }
                        if (lstReqToUpdateChild.size()>0){
                            update lstReqToUpdateChild;
                        }
                    }
    
                    List<Request__c> lstLeadRequestToInsert = new List<Request__c>();
                    List<Request__c> lstLeadRequestToUpdateNew = new List<Request__c>();

                    

                    List<LeadRequestSelection__c> lstLeadRequestSelectionNewVersion = new List<LeadRequestSelection__c>();
                    List<Id> lstOriginalRequestId = new List<Id>();
                    Map<Id, Request__c> mapLastVersReqs = new Map<Id, Request__c>();
    
                    for(Request__c parentRequest : lstParentRequest){
                            if(parentRequest.ReinsurerStatus__c != AP_Constant.statusSetup){ 
                                // if(setAllAnsweredLeadId.contains(parentRequest.Id)){ // RRA - 1104
                                if (isAccept == true){
                                        //RRA - 1104
                                        Decimal valueMinor = parentRequest.VersionMinor__c + 1;
                                        Decimal valueWrittenShare = parentRequest.WrittenShare__c;
                                        parentRequest.LeadOnBehalf__c = mapReqOldParent.get(parentRequest.Id).LeadOnBehalf__c;
                                        parentRequest.WrittenShare__c = mapReqOldParent.get(parentRequest.Id).WrittenShare__c;
                                        parentRequest.LastVersionSent__c = false;
                                        parentRequest.LastVersionAnswered__c = false;
                
                                        if(parentRequest.OriginalRequest__c != null){
                                            Request__c originalRequest = parentRequest.clone(false, false, false, false);
                                            originalRequest.Id = parentRequest.OriginalRequest__c;
                                            originalRequest.OriginalRequest__c = null;
                                            originalRequest.LastVersionSent__c = false;
                                            originalRequest.LastVersionAnswered__c = false;
                                            lstOriginalRequestToUpdate.add(originalRequest);
                                        }
                
                                        if (String.isNotBlank(parentRequest.CommentsResponse__c) || parentRequest.CommentsResponse__c != null){
                                            parentRequest.Utility_Icon_Comment__c = AP_Constant.iconComment; //RRA - 939
                                        }
                                        if (String.isBlank(parentRequest.CommentsResponse__c) || parentRequest.CommentsResponse__c == null){
                                            parentRequest.Utility_Icon_Comment__c = null; //RRA - 939
                                        }
                
                                        Request__c newParentVersionRequest = parentRequest.clone(false, false, false, false);
                                        //RRA - 1104
                                        newParentVersionRequest.VersionMinor__c = valueMinor;
                                        if(parentRequest.OriginalRequest__c == null){
                                            newParentVersionRequest.OriginalRequest__c = parentRequest.Id;
                                        }
                                        else{
                                            newParentVersionRequest.OriginalRequest__c = parentRequest.OriginalRequest__c;
                                            lstOriginalRequestId.add(parentRequest.OriginalRequest__c);
                                        }
                
                                        if (String.isNotBlank(newParentVersionRequest.CommentsResponse__c) || newParentVersionRequest.CommentsResponse__c != null){
                                            newParentVersionRequest.Utility_Icon_Comment__c = AP_Constant.iconComment; //RRA - 939
                                        }
                                        if (String.isBlank(newParentVersionRequest.CommentsResponse__c) || newParentVersionRequest.CommentsResponse__c == null){
                                            newParentVersionRequest.Utility_Icon_Comment__c = null; //RRA - 939
                                        }
                
                                        newParentVersionRequest.LastVersionSent__c = true;
                                        newParentVersionRequest.LastVersionAnswered__c = true;
                                        newParentVersionRequest.TECH_OldRequestId__c = parentRequest.Id;
                                        newParentVersionRequest.TECH_Actor2Id__c = null;
                                        newParentVersionRequest.LeadOnBehalf__c = true;
                                        newParentVersionRequest.WrittenShare__c = valueWrittenShare != null ?  valueWrittenShare : null;
                                        lstLeadRequestToInsert.add(newParentVersionRequest);
                                        
                                    //}
                            
                                }else{  
                                    //RRA 1104 - allow the modification after update 05/10/2022         
                                    if(parentRequest.OriginalRequest__c != null){
                                        Request__c originalRequest = parentRequest.clone(false, false, false, false);
                                        originalRequest.Id = parentRequest.OriginalRequest__c;
                                        originalRequest.OriginalRequest__c = null;
                                        originalRequest.LastVersionSent__c = false;
                                        originalRequest.LastVersionAnswered__c = false;
                                        lstOriginalRequestToUpdate.add(originalRequest);
                                    }
            
                                    if (String.isNotBlank(parentRequest.CommentsResponse__c) || parentRequest.CommentsResponse__c != null){
                                        parentRequest.Utility_Icon_Comment__c = AP_Constant.iconComment; //RRA - 939
                                    }
                                    if (String.isBlank(parentRequest.CommentsResponse__c) || parentRequest.CommentsResponse__c == null){
                                        parentRequest.Utility_Icon_Comment__c = null; //RRA - 939
                                    }
                                }
                            }
                                
                    }
                    Request__c newChildVersionRequest = new Request__c();
                    for(Request__c childRequest : lstRequest){
                        if(childRequest.ReinsurerStatus__c != AP_Constant.statusSetup){ 
                            //if(setAllAnsweredLeadId.contains(childRequest.Id)){ 
                                if (isAccept == true){
                                    //RRA - 1104
                                    Decimal valueMinor = childRequest.VersionMinor__c + 1;
                                    valueFixedCom = childRequest.FixedCommission__c;
                                    Boolean isLeadOnBehalf = childRequest.LeadOnBehalf__c;

                                    Decimal valueWrittenShareResponse = childRequest.WrittenShareResponse__c;
                                    Decimal valueWrittenShare = childRequest.WrittenShare__c;
                                    String valueCommentResponse = childRequest.CommentsResponse__c;
                                    Decimal valueProfitCommission = childRequest.ProfitCommission__c;
                                    Decimal valueFixedRate = childRequest.FixedRate__c;
                                    Decimal valueMinRate = childRequest.MinRate__c;
                                    Decimal valueMaxRate = childRequest.MaxRate__c;
                                    Decimal valueProvisionalRate = childRequest.ProvisionalRate__c;
                                    Decimal valueFlatPremium = childRequest.FlatPremium__c ;
                                    Decimal valueMDP = childRequest.MDP__c ;
                                    Decimal valueMinVarCommission = childRequest.MinVarCommission__c;
                                    Decimal valueMaxVarCommission = childRequest.MaxVarCommission__c;
                                    Decimal valueProvisionalCommission= childRequest.ProvisionalCommission__c;
                                    Decimal valuePerHeadPremium = childRequest.PerHeadPremium__c ;
                                    Decimal valueMinPerHeadAmount = childRequest.MinPerHeadAmount__c ;
                                    Decimal valueMaxPerHeadAmount = childRequest.MaxPerHeadAmount__c  ;
                                    Decimal valueProvisionalPerHeadPremium = childRequest.ProvisionalPerHeadPremium__c ;
                                    Decimal valueEstimatedReinsurancePremium = childRequest.EstimatedReinsurancePremium__c  ;
                                    Decimal valueEstimatedInsurancePremium = childRequest.EstimatedInsurancePremium__c  ;
                                    Decimal valueReinsurerExpenses = childRequest.ReinsurerExpenses__c  ;
                                    Decimal valueLossCarryingForward = childRequest.LossCarryingForward__c  ;
                                    Boolean isOrUnlimited = childRequest.OrUnlimited__c  ;
                                    Decimal valueLossCorridorPart = childRequest.LossCorridorPart__c  ;
                                    Decimal valueLossCorridorMaxLR = childRequest.LossCorridorMaxLR__c  ;
                                    Decimal valueLossCorridorMinLR = childRequest.LossCorridorMinLR__c  ;
                                    Decimal valueNoClaimBonus = childRequest.NoClaimBonus__c  ;
                                    Decimal valueNoClaimBonusAmount = childRequest.NoClaimBonusAmount__c  ;
    
                                    childRequest.LastVersionSent__c = false;
                                    childRequest.LastVersionAnswered__c = false;
                                    childRequest.LeadOnBehalf__c = true;
            
                                    if(childRequest.OriginalRequest__c != null){
                                        Request__c originalRequest = childRequest.clone(false, false, false, false);
                                        originalRequest.Id = childRequest.OriginalRequest__c;
                                        originalRequest.OriginalRequest__c = null;
                                        originalRequest.LastVersionSent__c = false;
                                        originalRequest.LastVersionAnswered__c = false;
                                        lstOriginalRequestToUpdate.add(originalRequest);
                                    }
    
                                    //RRA - 1104 - keep old values Decimal after clone - 27/09/2022
                                    if (childRequest.ProfitCommission__c != null || childRequest.fixedCommission__c != null || childRequest.FixedRate__c != null  || childRequest.MinRate__c != null  || childRequest.MaxRate__c != null  || childRequest.ProvisionalRate__c != null  || childRequest.FlatPremium__c != null  || childRequest.MDP__c != null  || childRequest.MinVarCommission__c != null  || childRequest.MaxVarCommission__c != null  || childRequest.ProvisionalCommission__c != null  || childRequest.PerHeadPremium__c != null  || childRequest.MinPerHeadAmount__c != null  || childRequest.MaxPerHeadAmount__c != null  || childRequest.ProvisionalPerHeadPremium__c != null  || childRequest.EstimatedReinsurancePremium__c != null  || childRequest.EstimatedInsurancePremium__c != null || childRequest.WrittenShareResponse__c != null || childRequest.WrittenShare__c != null || childRequest.CommentsResponse__c != null || childRequest.ReinsurerExpenses__c != null || childRequest.LossCarryingForward__c != null || childRequest.LossCorridorPart__c != null || childRequest.LossCorridorMaxLR__c != null || childRequest.LossCorridorMinLR__c != null || childRequest.NoClaimBonus__c != null || childRequest.NoClaimBonusAmount__c != null) {

                                        childRequest.ReinsurerExpenses__c = mapReqOld.get(childRequest.Id).ReinsurerExpenses__c != null ?  mapReqOld.get(childRequest.Id).ReinsurerExpenses__c  : null;
                                        childRequest.LossCarryingForward__c = mapReqOld.get(childRequest.Id).LossCarryingForward__c != null ?  mapReqOld.get(childRequest.Id).LossCarryingForward__c  : null;
                                        childRequest.OrUnlimited__c = mapReqOld.get(childRequest.Id).OrUnlimited__c;
                                        childRequest.LossCorridorPart__c = mapReqOld.get(childRequest.Id).LossCorridorPart__c != null ?  mapReqOld.get(childRequest.Id).LossCorridorPart__c  : null;
                                        childRequest.LossCorridorMaxLR__c = mapReqOld.get(childRequest.Id).LossCorridorMaxLR__c != null ?  mapReqOld.get(childRequest.Id).LossCorridorMaxLR__c  : null;
                                        childRequest.LossCorridorMinLR__c = mapReqOld.get(childRequest.Id).LossCorridorMinLR__c != null ?  mapReqOld.get(childRequest.Id).LossCorridorMinLR__c  : null;
                                        childRequest.NoClaimBonus__c = mapReqOld.get(childRequest.Id).NoClaimBonus__c != null ?  mapReqOld.get(childRequest.Id).NoClaimBonus__c  : null;
                                        childRequest.NoClaimBonusAmount__c = mapReqOld.get(childRequest.Id).NoClaimBonusAmount__c != null ?  mapReqOld.get(childRequest.Id).NoClaimBonusAmount__c  : null;
                                        childRequest.LeadOnBehalf__c = mapReqOld.get(childRequest.Id).LeadOnBehalf__c;
                                        childRequest.ProfitCommission__c = mapReqOld.get(childRequest.Id).ProfitCommission__c != null ?  mapReqOld.get(childRequest.Id).ProfitCommission__c  : null;
                                        childRequest.CommentsResponse__c = mapReqOld.get(childRequest.Id).CommentsResponse__c != null ?  mapReqOld.get(childRequest.Id).CommentsResponse__c  : null;
                                        childRequest.WrittenShareResponse__c = mapReqOld.get(childRequest.Id).WrittenShareResponse__c != null ?  mapReqOld.get(childRequest.Id).WrittenShareResponse__c  : null;
                                        childRequest.WrittenShare__c = mapReqOld.get(childRequest.Id).WrittenShare__c != null ?  mapReqOld.get(childRequest.Id).WrittenShare__c  : null;
                                        childRequest.fixedCommission__c = mapReqOld.get(childRequest.Id).fixedCommission__c != null ?  mapReqOld.get(childRequest.Id).fixedCommission__c  : null;
                                        childRequest.FixedRate__c = mapReqOld.get(childRequest.Id).FixedRate__c != null ?  mapReqOld.get(childRequest.Id).FixedRate__c  : null;
                                        childRequest.MinRate__c = mapReqOld.get(childRequest.Id).MinRate__c != null ?  mapReqOld.get(childRequest.Id).MinRate__c  : null;
                                        childRequest.MaxRate__c = mapReqOld.get(childRequest.Id).MaxRate__c != null ?  mapReqOld.get(childRequest.Id).MaxRate__c  : null;
                                        childRequest.ProvisionalRate__c = mapReqOld.get(childRequest.Id).ProvisionalRate__c != null ?  mapReqOld.get(childRequest.Id).ProvisionalRate__c  : null;
                                        childRequest.FlatPremium__c = mapReqOld.get(childRequest.Id).FlatPremium__c != null ?  mapReqOld.get(childRequest.Id).FlatPremium__c  : null;
                                        childRequest.MDP__c = mapReqOld.get(childRequest.Id).MDP__c != null ?  mapReqOld.get(childRequest.Id).MDP__c  : null;
                                        childRequest.MinVarCommission__c = mapReqOld.get(childRequest.Id).MinVarCommission__c != null ?  mapReqOld.get(childRequest.Id).MinVarCommission__c  : null;
                                        childRequest.MaxVarCommission__c = mapReqOld.get(childRequest.Id).MaxVarCommission__c != null ?  mapReqOld.get(childRequest.Id).MaxVarCommission__c  : null;
                                        childRequest.ProvisionalCommission__c = mapReqOld.get(childRequest.Id).ProvisionalCommission__c != null ?  mapReqOld.get(childRequest.Id).ProvisionalCommission__c  : null;
                                        childRequest.PerHeadPremium__c = mapReqOld.get(childRequest.Id).PerHeadPremium__c != null ?  mapReqOld.get(childRequest.Id).PerHeadPremium__c  : null;
                                        childRequest.MinPerHeadAmount__c = mapReqOld.get(childRequest.Id).MinPerHeadAmount__c != null ?  mapReqOld.get(childRequest.Id).MinPerHeadAmount__c  : null;
                                        childRequest.MaxPerHeadAmount__c = mapReqOld.get(childRequest.Id).MaxPerHeadAmount__c != null ?  mapReqOld.get(childRequest.Id).MaxPerHeadAmount__c  : null;
                                        childRequest.ProvisionalPerHeadPremium__c = mapReqOld.get(childRequest.Id).ProvisionalPerHeadPremium__c != null ?  mapReqOld.get(childRequest.Id).ProvisionalPerHeadPremium__c  : null;
                                        childRequest.EstimatedReinsurancePremium__c = mapReqOld.get(childRequest.Id).EstimatedReinsurancePremium__c != null ?  mapReqOld.get(childRequest.Id).EstimatedReinsurancePremium__c  : null;
                                        childRequest.EstimatedInsurancePremium__c = mapReqOld.get(childRequest.Id).EstimatedInsurancePremium__c != null ?  mapReqOld.get(childRequest.Id).EstimatedInsurancePremium__c  : null;
                                    }
            
                                    newChildVersionRequest = childRequest.clone(false, false, false, false);
                                    newChildVersionRequest.VersionMinor__c = valueMinor;
    
                                    //RRA - 1104 - keep values Decimal after clone - 27/09/2022
                                    newChildVersionRequest.ReinsurerExpenses__c = valueReinsurerExpenses != null ?  valueReinsurerExpenses : null;
                                    newChildVersionRequest.LossCarryingForward__c = valueLossCarryingForward != null ?  valueLossCarryingForward : null;
                                    newChildVersionRequest.OrUnlimited__c = isOrUnlimited;
                                    newChildVersionRequest.LossCorridorPart__c = valueLossCorridorPart != null ?  valueLossCorridorPart : null;
                                    newChildVersionRequest.LossCorridorMaxLR__c = valueLossCorridorMaxLR != null ?  valueLossCorridorMaxLR : null;
                                    newChildVersionRequest.LossCorridorMinLR__c = valueLossCorridorMinLR != null ?  valueLossCorridorMinLR : null;
                                    newChildVersionRequest.NoClaimBonus__c = valueNoClaimBonus != null ?  valueNoClaimBonus : null;
                                    newChildVersionRequest.NoClaimBonusAmount__c = valueNoClaimBonusAmount != null ?  valueNoClaimBonusAmount : null;
                                    newChildVersionRequest.LeadOnBehalf__c = true;
                                    newChildVersionRequest.WrittenShareResponse__c = valueWrittenShareResponse != null ?  valueWrittenShareResponse : null;
                                    newChildVersionRequest.WrittenShare__c = valueWrittenShare != null ?  valueWrittenShare : null;
                                    newChildVersionRequest.CommentsResponse__c = valueCommentResponse != null ?  valueCommentResponse : null;
                                    newChildVersionRequest.ProfitCommission__c = valueProfitCommission != null ?  valueProfitCommission : null;
                                    newChildVersionRequest.FixedCommission__c = valueFixedCom != null ?  valueFixedCom : null;
                                    newChildVersionRequest.FixedRate__c = valueFixedRate != null ?  valueFixedRate : null;
                                    newChildVersionRequest.MinRate__c = valueMinRate != null ?  valueMinRate : null;
                                    newChildVersionRequest.MaxRate__c = valueMaxRate != null ?  valueMaxRate : null;
                                    newChildVersionRequest.ProvisionalRate__c = valueProvisionalRate != null ?  valueProvisionalRate : null;
                                    newChildVersionRequest.FlatPremium__c = valueFlatPremium != null ?  valueFlatPremium : null;
                                    newChildVersionRequest.MDP__c = valueMDP != null ?  valueMDP : null;
                                    newChildVersionRequest.MinVarCommission__c = valueMinVarCommission != null ?  valueMinVarCommission : null;
                                    newChildVersionRequest.MaxVarCommission__c = valueMaxVarCommission != null ?  valueMaxVarCommission : null;
                                    newChildVersionRequest.ProvisionalCommission__c = valueProvisionalCommission != null ?  valueProvisionalCommission : null;
                                    newChildVersionRequest.PerHeadPremium__c = valuePerHeadPremium != null ?  valuePerHeadPremium : null;
                                    newChildVersionRequest.MinPerHeadAmount__c = valueMinPerHeadAmount != null ?  valueMinPerHeadAmount : null;
                                    newChildVersionRequest.MaxPerHeadAmount__c = valueMaxPerHeadAmount != null ?  valueMaxPerHeadAmount : null;
                                    newChildVersionRequest.ProvisionalPerHeadPremium__c = valueProvisionalPerHeadPremium != null ?  valueProvisionalPerHeadPremium : null;
                                    newChildVersionRequest.EstimatedReinsurancePremium__c = valueEstimatedReinsurancePremium != null ?  valueEstimatedReinsurancePremium : null;
                                    newChildVersionRequest.EstimatedInsurancePremium__c = valueEstimatedInsurancePremium != null ?  valueEstimatedInsurancePremium : null;
    
                                    //need to set Original Parent Request Id
                                    //hence create a map of parentId by childId
                                    if(childRequest.OriginalRequest__c == null){
                                        newChildVersionRequest.OriginalRequest__c = childRequest.Id;
                                    }
                                    else{
                                        newChildVersionRequest.OriginalRequest__c = childRequest.OriginalRequest__c;
                                        lstOriginalRequestId.add(childRequest.OriginalRequest__c);
                                    }
            
                                    newChildVersionRequest.LastVersionSent__c = true;
                                    newChildVersionRequest.LastVersionAnswered__c = true;
                                    newChildVersionRequest.TECH_OldRequestId__c = childRequest.Id;
                                    newChildVersionRequest.TECH_Actor2Id__c = null;
                                    lstLeadRequestToInsert.add(newChildVersionRequest);
                            }
                            else{
                                //RRA 1104 - allow the modification after update 05/10/2022      
                                if(childRequest.OriginalRequest__c != null){
                                        Request__c originalRequest = childRequest.clone(false, false, false, false);
                                        originalRequest.Id = childRequest.OriginalRequest__c;
                                        originalRequest.OriginalRequest__c = null;
                                        originalRequest.LastVersionSent__c = false;
                                        originalRequest.LastVersionAnswered__c = false;
                                        lstOriginalRequestToUpdate.add(originalRequest);
                                    }
                                if(childRequest.OriginalRequest__c == null){
                                    newChildVersionRequest.OriginalRequest__c = childRequest.Id;
                                }
                                else{
                                    newChildVersionRequest.OriginalRequest__c = childRequest.OriginalRequest__c;
                                }
                            }
                        }
                    }
    
                    if(lstLeadRequestToInsert.size() > 0) {
                        insert lstLeadRequestToInsert;
                        mapRequestNewVersionById = new Map<Id, Request__c>(lstLeadRequestToInsert);
                    }

                    if(lstLeadRequestToUpdate.size() > 0) {
                        map<Id,Request__c> mapLstRequest = new map<Id,Request__c>(); //Avoid System.ListException: Duplicate id in list:
                        mapLstRequest.putall(lstLeadRequestToUpdate);
                        update mapLstRequest.values();
                    }
    
                    Map<Id, Id> mapNewRequestIdByOldRequestLead = new Map<Id, Id>();
    
                    for(Request__c newLeadRequest : lstLeadRequestToInsert){
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
                    System.debug('lstLeadRequestSelection = ' + lstLeadRequestSelection);
                    System.debug('lstLeadRequestSelectionNewVersion is inserted = ' + lstLeadRequestSelectionNewVersion.size());
                }
                List<Request__c> lstAllReq = new List<Request__c>();
    
               
                if(lstNewVersionRequest.size() > 0){
                    System.debug('Insert New List ');
                    insert lstNewVersionRequest;
                    mapRequestNewVersionById = new Map<Id, Request__c>(lstNewVersionRequest);
                }
                
                 //RRA - ticket 1541 - 04072023
                 if (lstRequestUpdatedLastVers.size()>0){
                    map<Id,Request__c> mapLstUpLastRequest = new map<Id,Request__c>(); //Avoid System.ListException: Duplicate id in list:
                    mapLstUpLastRequest.putall(lstRequestUpdatedLastVers);
                    update mapLstUpLastRequest.values();
                }
                
                 //RRA - ticket 1541 - 04072023
                 if (lstRequestUpdatedOrig.size()>0){
                    map<Id,Request__c> mapLstUpOrigRequest = new map<Id,Request__c>(); //Avoid System.ListException: Duplicate id in list:
                    mapLstUpOrigRequest.putall(lstRequestUpdatedOrig);
                    update mapLstUpOrigRequest.values();
                }
                 
                 //RRA - ticket 1541 - 05072023
                for (Request__c request : lstRequestUpdatedLastVers){
                    if (request.ReinsurerStatus__c == 'Timeout'){
                        if (request.QuoteDeadline__c != null){
                            request.UtilityIconDate__c = AP_Constant.iconDate; 
                        }else{
                            request.UtilityIconDate__c = null; 
                        }
                        lstReqUpdateIconTimeout.add(request);
                    }
                }
                
                //RRA - ticket 1541 - 04072023
                if (lstReqUpdateIconTimeout.size()>0){
                    update lstReqUpdateIconTimeout;
                }
    
                //Request__c  lastVersionReqq = new Request__c();
                //lastVersionReqq = mapRequestNewVersionById.size() > 0 ? mapRequestNewVersionById.values().get(0) : null;
    
                if(lstRequest.size() > 0 && phaseType != 'Placement'){
                    System.debug('Update Old List ');
                    update lstRequest;
                    
                }
    
    
                if(lstParentRequest.size() > 0){
                    update lstParentRequest;
                    
                    //RRA VERSIONING
                    List<Request__c> lstReqToUpdateParent = new  List<Request__c>();
                    for (Request__c parent : lstParentRequest){
                        if (parent.ReinsurerStatus__c == 'Sent' && parent.ResponseDate__c != null){
                            parent.ResponseDate__c = null;
                        }else if (parent.ReinsurerStatus__c == 'Sent' && parent.DateNextSending__c != null){
                            parent.DateNextSending__c =  parent.DateNextSending__c;
                        }else if ((parent.ReinsurerStatus__c == 'Answered' || parent.ReinsurerStatus__c == 'Refused') && parent.DateNextSending__c != null){
                            parent.DateNextSending__c =  null;
                        }
                        lstReqToUpdateParent.add(parent);
                    }
                    if (lstReqToUpdateParent.size()>0){
                        update lstReqToUpdateParent;
                    }
                }
    
                if(lstOriginalRequestToUpdate.size() > 0){
                    update lstOriginalRequestToUpdate;
                }
    
                List<Request__c> lstRequestVersionReinsurerStatus = [SELECT Id, DateNextSending__c, TECH_LeadType__c, LastVersionAnswered__c, LastVersionSent__c, ReinsurerStatus__c, SignedShare__c, WrittenShareResponse__c, OriginalRequest__c, ResponseDate__c, RecordType.DeveloperName
                                                                            , QuoteOnBehalf__c, LeadOnBehalf__c, PlacementOnBehalf__c, ReceptionDate__c, VersionMinor__c, FixedRate__c, WrittenShare__c
                                                                        FROM Request__c 
                                                                        WHERE Id IN :mapReinsurerStatusByOriginalReqId.keySet() 
                                                                        OR OriginalRequest__c IN :mapReinsurerStatusByOriginalReqId.keySet()];
                
                //RRA - ticket 1404 - 08022023 => update the original Request on Lead Request if writtenShare has changed
                Set<Id> setOriginalReq = new Set<Id> ();
                Set<Id> setReinsReq = new Set<Id> ();
                Set<String> setUWYReq = new Set<String> ();
                Set<Id> setPCCReq = new Set<Id> ();
                Set<Id> setProgramReq = new Set<Id> ();
                Set<Id> setIdReqLastversion = new Set<Id> ();
                String typeRecordTypeName;
                List<Request__c>  lstLastVersionRequestReq = new List<Request__c>();
                Map <Id, Request__c> mapOrigReqIdReq = new  Map <Id, Request__c>();
                List<Request__c> lstRequestOrigineToUpdate = new List<Request__c>();
                //DateTime dateTimeQuoteValidity;
                Date dateQuoteValidity;
                if (selectIdRequest != null){
                    //Step 0 RRA - ticket 1404 : 
                    //0.1- get Reinsurer attached on same section or Treaty 
                    //0.2- Limit the perimeter of reinsurer from pcc, uwy, program
                    //0.3- Add if condition to delimite the current recordType when user clicked on respond on behalf
                    for (Request__c req : [SELECT Id, Reinsurer__c, QuoteDeadline__c, Program__r.UwYear__c,Program__r.PrincipalCedingCompany__c, Program__c  FROM Request__c WHERE Id =: selectIdRequest ]){
                        setReinsReq.add(req.Reinsurer__c);
                        setUWYReq.add(req.Program__r.UwYear__c);
                        setPCCReq.add(req.Program__r.PrincipalCedingCompany__c);
                        setProgramReq.add(req.Program__c);
                        if (phaseType == 'Quote') { 
                            typeRecordTypeName = 'Quote Request';
                            dateQuoteValidity = req.QuoteDeadline__c;//RRA - ticket 1574 - 14102023
                        }else if (phaseType == 'Lead'){
                            typeRecordTypeName = 'Lead Request';
                        }else if (phaseType == 'Placement'){
                            typeRecordTypeName = 'Placement Request';
                        }
                    }
    
                    System.debug('setReinsReq == ' + setReinsReq);
                    System.debug('setUWYReq == ' + setUWYReq);
                    System.debug('setPCCReq == ' + setPCCReq);
                    System.debug('setProgramReq == ' + setProgramReq);
                    System.debug('typeRecordTypeName == ' + typeRecordTypeName);
    
                    //Step 1 RRA - ticket 1404 : get the OriginalRequest__c not null for all current records requests 
                    for (Request__c req : [SELECT Id, OriginalRequest__c, Reinsurer__c, Program__r.UwYear__c,Program__r.PrincipalCedingCompany__c, Program__c FROM Request__c WHERE Reinsurer__c IN: setReinsReq AND Program__r.UwYear__c IN: setUWYReq AND Program__r.PrincipalCedingCompany__c IN:setPCCReq AND Program__c IN:setProgramReq AND RecordType.Name =: typeRecordTypeName]){
                        if (req.OriginalRequest__c != null){
                            setOriginalReq.add(req.OriginalRequest__c);
                        }
                    }
    
                    System.debug('setOriginalReq == ' + setOriginalReq);
    
    
                    //Step 2 RRA - ticket 1404 : get the Ids of  currents requests from OriginalRequest__c and the last status version (LastVersionAnswered__c and LastVersionSent__c)
                    for (Request__c req : [SELECT Id, OriginalRequest__c, LastVersionAnswered__c, LastVersionSent__c  FROM Request__c WHERE OriginalRequest__c IN: setOriginalReq ]){
                        if (req.LastVersionAnswered__c == true && req.LastVersionSent__c == true){
                            setIdReqLastversion.add(req.Id);
                        }
                    }
    
                    System.debug('setIdReqLastversion == ' + setIdReqLastversion);
    
                    //Step 3 RRA - ticket 1404 : get the last requests versions
                    List<Request__c> lstLastParentLeadRequest = [SELECT Id, SignedShare__c, WrittenShareResponse__c, OriginalRequest__c, WrittenShare__c, LastVersionAnswered__c, LastVersionSent__c  FROM Request__c WHERE Id IN: setIdReqLastversion];
    
                    for (Request__c reqLast: lstLastParentLeadRequest){
                        mapOrigReqIdReq.put(reqLast.OriginalRequest__c, reqLast);
                    }
    
                    System.debug('mapOrigReqIdReq == ' + mapOrigReqIdReq);
    
                    //Step 4 RRA - ticket 1404 : get records original request to update
                    lstRequestOrigineToUpdate = [SELECT Id, OriginalRequest__c, WrittenShare__c, WrittenShareResponse__c FROM Request__c WHERE Id IN: setOriginalReq];
    
                    System.debug('lstRequestOrigineToUpdate == ' + lstRequestOrigineToUpdate);
    
                    // Step 5 RRA - ticket 1404 : get record original request and update the writtenShare on signing if written share in lead Request has changed
                    for (Request__c req : lstRequestOrigineToUpdate){
                        if (req.OriginalRequest__c == null){
                            //req.WrittenShare__c =  lastVersionRequestReq != null ?  lastVersionRequestReq.WrittenShare__c : req.WrittenShare__c;
                            req.WrittenShare__c =  mapOrigReqIdReq.get(req.Id).WrittenShare__c != null ?  mapOrigReqIdReq.get(req.Id).WrittenShare__c : req.WrittenShare__c;
                        }
                    }
                    
                     //RRA - ticket 1574 - 13102023
                     //System.debug('dateTimeQuoteValidity == ' + dateTimeQuoteValidity);
                     System.debug('dateQuoteValidity == ' + dateQuoteValidity);
                     System.debug('Date.today == ' + Date.today());
                     System.debug('selectIdRequest == ' + selectIdRequest);
                     
                     if (typeRecordTypeName == 'Quote Request' && dateQuoteValidity != null){
                          //RRA - ticket 1574 - 14102023
                        Date dateQuoteValidityDaysMinus2 = dateQuoteValidity - 2; 
                        Date dateQuoteValidityDaysMinus1 = dateQuoteValidity - 1;
                        Date dateQuoteValidityDaysCurrent = dateQuoteValidity;
                        Boolean isActionSendEmail = false;
                        
                        System.debug('dateQuoteValidityDaysMinus2== ' + dateQuoteValidityDaysMinus2);
                        System.debug('dateQuoteValidityDaysMinus1 == ' + dateQuoteValidityDaysMinus1);
                        System.debug('dateQuoteValidityDaysCurrent == ' + dateQuoteValidityDaysCurrent);
                        
                        if (dateQuoteValidityDaysMinus2 == Date.today() || dateQuoteValidityDaysMinus1 == Date.today() || dateQuoteValidityDaysCurrent  ==  Date.today()){
                            isActionSendEmail = true;
                        }
                        
                        if (isActionSendEmail){
                            apexReminderMailQuotValidity.sendEmail(selectIdRequest, false);
                            System.debug('ok sendEmail from CE');
                        }
                     }
                }

                // RRA - 1104 - Get value request for lastVersion
                Request__c  lastVersionReq = new Request__c();
                lastVersionReq = mapRequestNewVersionById.size() > 0 ? mapRequestNewVersionById.values().get(0) : null;
                
                for(Request__c request : lstRequestVersionReinsurerStatus){
                    Id originalReqId;
                    if(request.OriginalRequest__c == null){
                        originalReqId = request.Id;
                    }
                    else{
                        originalReqId = request.OriginalRequest__c;
                    }

                    // RRA - 1104
                    if(request.OriginalRequest__c == null){
                        request.VersionMinor__c =   lastVersionReq != null ?  lastVersionReq.VersionMinor__c : request.VersionMinor__c;
                        request.ReinsurerStatus__c = lastVersionReq != null ?  lastVersionReq.ReinsurerStatus__c : request.ReinsurerStatus__c; //RRA - VERSIONING
                        //request.FixedRate__c = lastVersionReq != null ?  lastVersionReq.FixedRate__c : request.FixedRate__c; //RRA - 1104 - version fxRate - 11/08/2022 (RRA - ticket 1339 - 09112022)
                    }else if (request.LastVersionAnswered__c && request.LastVersionSent__c && request.ReinsurerStatus__c == 'Sent' && request.TECH_LeadType__c == 'child'){//RRA VERSIONING
                        request.ReinsurerStatus__c = 'Answered';
                    }
                
                    if(mapReinsurerStatusByOriginalReqId.containsKey(originalReqId)){
                        //request.ReinsurerStatus__c = mapReinsurerStatusByOriginalReqId.get(originalReqId); //RRA - VERSIONING
                        if(request.ReinsurerStatus__c == AP_Constant.statusAnswered || request.ReinsurerStatus__c == AP_Constant.statusRefused){
                            //request.ResponseDate__c = System.today();
                            //RRA VERSIONING
                            valueResponseDate = request.ResponseDate__c;
                            if (request.ResponseDate__c != null){
                                request.ResponseDate__c = valueResponseDate;
                            }else{
                                request.ResponseDate__c = System.today();
                            }
                            if(request.RecordType.DeveloperName == AP_Constant.stageQuote){
                                //request.QuoteOnBehalf__c = true;
                            }
                            else if(request.RecordType.DeveloperName == AP_Constant.stageLead){
                                //request.LeadOnBehalf__c = true;
                            }
                            else if(request.RecordType.DeveloperName == AP_Constant.stagePlacement){
                                //request.PlacementOnBehalf__c = true;
                                request.ReceptionDate__c = System.today();
                            }
                        }
                    }
                }
    
                if(lstRequestVersionReinsurerStatus.size() > 0){
                    update lstRequestVersionReinsurerStatus;
                }

                if(lstLeadRequestToUpdate.size() > 0){
                    update lstLeadRequestToUpdate;
                }

                if(lstRequestOrigineToUpdate.size() > 0){
                    update lstRequestOrigineToUpdate;
                }
    
    
                //RRA VERSIONING
                List<Request__c> lstReqToUpdate = new  List<Request__c>();
                for (Request__c req : lstRequestVersionReinsurerStatus){
                    if (req.ReinsurerStatus__c	== 'Sent' && req.ResponseDate__c != null){
                        req.ResponseDate__c = null;
                    }else if (req.ReinsurerStatus__c == 'Sent' && req.DateNextSending__c != null){
                        req.DateNextSending__c =  req.DateNextSending__c;
                    }else if ((req.ReinsurerStatus__c == 'Answered' || req.ReinsurerStatus__c == 'Refused') && req.DateNextSending__c != null){
                        req.DateNextSending__c =  null;
                    }
                    lstReqToUpdate.add(req);
                }
                if (lstReqToUpdate.size()>0){
                    update lstReqToUpdate;
                }
                mapResults.put('Success', 'Success');
            }catch (Exception ex) {
                    Database.rollback(sp);
                mapResults.put('Error', ex.getMessage());
            }
            return mapResults;
        }
    
        /**
        * @description Method to check if LeadPlacementInfo need to be disabled
        * @param Id programId
        * @return Boolean
        */
        @AuraEnabled
        public static Boolean disableLeadPlacementInfo(Id programId){
            Program__c program = [SELECT Id, Name, TECH_ShowClosePreviousPhaseBtn__c FROM Program__c WHERE Id = :programId];
            //if close previous phase button is enabled in signing ---> should display respond on behalf information for lead and placement --- not disable
            //if close previous phase button is disabled in signing ----> should not display respond on behalf information for lead and placement(must click on Reopen Previous Phase to display information) --- disable
            String showPreviousPhaseBtn = program.TECH_ShowClosePreviousPhaseBtn__c;
            Boolean disableLeadPlacementInfo = false;
    
            if(showPreviousPhaseBtn == '1'){
                disableLeadPlacementInfo = false;
            }
            else if(showPreviousPhaseBtn == '2'){
                disableLeadPlacementInfo = true;
            }
    
            return disableLeadPlacementInfo;
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