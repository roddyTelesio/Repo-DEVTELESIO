public with sharing class LWC21_NewLeadRequest {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Controller for Lightning Web Component lwc21NewLeadRequest
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 31-JAN-2020  MBE   1.0      Initial version
-- 14-OCT-2020  NBI   1.1      On creation, each parent request should have a separate list of child requests.
                               Before: same children records were linked to different parent lead requests in Lead Request Selection.
                               This was causing issues when deleting a single record whereby all were deleted since all parents linked to same children.
-- 21-May-2021  MBE   1.2      W-0974 - Bug bloquant Prod - Impossibilité de créer une Lead request - TECH_Actor2Id__c
-- 08-JUL-2021  NBI   1.3      W-0992: Third Party Management
-- 14-JUN-2021  MBE   1.4      W-0894 - ODS - TECH_SentByUser__c seems empty after a modification of a lead request
-- 24-JUL-2021  MBE   1.5      SOQL Injection for getBroker()
-- 27-AUG-2021  MBE   1.6      Remove unused value for mapResult
--------------------------------------------------------------------------------------
**************************************************************************************/

    /**
    * @description Method to Treaty (ies) for Program
    * @param Id programId
    * @return List<OptionWrapper>
    */
    @AuraEnabled
    public static List<OptionWrapper> getTreaties(Id programId ){
        Map<String, Id> mapRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectRequest});
        Map<Id, List<Section__c>> mapLstSectionByTreatyId = new Map<Id, List<Section__c>>();
        String recordTypeLeadId = mapRecTypeId.get(AP_Constant.reqRTLead);
        List<OptionWrapper> lstTreatyForRetainToLead = new List<OptionWrapper>();
        Set<Id> setExistedTreatyForLeadReq = new Set<Id>();

        //MBE 03/09 - Display active treaty/section
        List<Request__c> lstParentLeadRequests = [SELECT Id, Name, Treaty__c FROM Request__c WHERE Program__c = :programId AND RecordTypeId = :recordTypeLeadId AND Reinsurer__c != NULL];

        for(Request__c leadRequest : lstParentLeadRequests){
            setExistedTreatyForLeadReq.add(leadRequest.Treaty__c);
        }
        //RRA - ticket 1524 - 24052023
        List<Treaty__c> lstTreaties = [SELECT Id, Name, Layer__c FROM Treaty__c WHERE Program__c = :programId AND Status__c = :AP_Constant.statusActive ORDER BY Name];

        for(Section__c section : [SELECT Id, Name, Treaty__c
                                  FROM Section__c
                                  WHERE Treaty__c IN :lstTreaties
                                  AND Retained_to_lead__c = TRUE
                                  AND Status__c = :AP_Constant.statusActive]){
            List<Section__c> lstSectionsByTreaty = new List<Section__c>();
            if(mapLstSectionByTreatyId.containsKey(section.Treaty__c)){
                lstSectionsByTreaty = mapLstSectionByTreatyId.get(section.Treaty__c);
                lstSectionsByTreaty.add(section);
                mapLstSectionByTreatyId.put(section.Treaty__c, lstSectionsByTreaty);
            }
            else{
                lstSectionsByTreaty.add(section);
                mapLstSectionByTreatyId.put(section.Treaty__c, lstSectionsByTreaty);
            }
        }

        for(Treaty__c treaty : lstTreaties){
            if(mapLstSectionByTreatyId.containsKey(treaty.Id) && !setExistedTreatyForLeadReq.contains(treaty.Id)){
                lstTreatyForRetainToLead.add(new OptionWrapper(treaty.Name, treaty.Id, treaty.Layer__c));//RRA - ticket 1524 - 24052023
            }
        }
        //RRA - ticket 1524 - 24052023
        lstTreatyForRetainToLead.sort();
        return lstTreatyForRetainToLead;
    }

    //RRA - ticket 1524 - 24052023 - Implement Interface Comparable and Add method compareTo to sort the lstTreaties
    public class OptionWrapper implements Comparable{
        @AuraEnabled
        public String label {get; set;}
        @AuraEnabled
        public String value {get; set;}
        @AuraEnabled
        public Decimal layer {get; set;}

        public OptionWrapper(String label, String value, Decimal layer) {
            this.label = label;
            this.value = value;
            this.layer = layer;
        }
        
        public Integer compareTo(Object o) {
            OptionWrapper that = (OptionWrapper) o;
            if (that.layer > this.layer) {
                return -1;
            } else if (that.layer < this.layer) {
                return 1;
            } else {
                return 0;
            }
        }
    }

    /**
    * @description Method to get Broker for search value
    * @param String ObjectName, String fieldName, String value, List<String> selectedRecI
    * @return List<SObjectResult>
    */
    @AuraEnabled(Cacheable=true)
    public static List<SObjectResult> getBroker(String ObjectName, String fieldName, String value, List<String> selectedRecId) {
        List<SObjectResult> sObjectResultList = new List<SObjectResult>();
        Map<String, Id> mapRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectAcc});
        String recordTypeIdBroker = mapRecTypeId.get(AP_Constant.accRTBroker);

        if(selectedRecId == null) {
            selectedRecId = new List<String>();
        }

        if(String.isNotEmpty(value)) {
            String strValue = '%' + String.escapeSingleQuotes(value.trim()) + '%';
            String query = 'Select Id, Name from Account where Name LIKE :strValue and ID NOT IN: selectedRecId AND IsActive__c = TRUE and RecordTypeId = :recordTypeIdBroker';

            // String query = 'Select Id,'+fieldName+' FROM '+ObjectName+' WHERE '+fieldName+' LIKE \'%' + value.trim() + '%\' and ID NOT IN: selectedRecId AND IsActive__c = TRUE and RecordTypeId = :recordTypeIdBroker';
            
            for(SObject so : Database.query(query)) {
                String fieldvalue = (String)so.get(fieldName);
                sObjectResultList.add(new SObjectResult(fieldvalue, so.Id));
            }
        }

        return sObjectResultList;
    }

    public class SObjectResult {
        @AuraEnabled
        public String recName;
        @AuraEnabled
        public Id recId;

        public SObjectResult(String recNameTemp, Id recIdTemp) {
            recName = recNameTemp;
            recId = recIdTemp;
        }
        public SObjectResult() {

        }
    }

    /**
    * @description Method to get Section details for Lead
    * @param Id treatyId
    * @param List<String> lstLeader
    * @return Map<String, Object>
    */
    @AuraEnabled(Cacheable = true)
    public static Map<String, Object> getSectionRetainToLeadDetails(Id treatyId, List<String> lstLeader){
        Map<String, Object> mapResults = new Map<String, Object>();
        List<String> lstSectionFields = AP_Constant.getCreatableFieldsByObjName(AP_Constant.sObjectSection);
        String strSectionFields = String.join(lstSectionFields , ', ');
        Set<Id> lstSectionId = new Set<Id>();
        String statusActive = AP_Constant.statusActive;
        Map<Id, List<Request__c>> mapLstRequestBySectionId = new Map<Id, List<Request__c>>();
        Map<Id, Request__c> mapLastCreatedRequestBySectionId = new Map<Id, Request__c>();

        String querySection = 'select Id, Program__r.LTA__c, Treaty__c,Treaty__r.Layer__c, '
                            + strSectionFields
                            + ' from Section__c where (Treaty__c = :treatyId AND Retained_to_lead__c = TRUE AND Status__c = :statusActive ) '; // RRA - ticket 1051 - 09112022

        List<Section__c> lstSections = Database.query(querySection);

        for(Section__c section : lstSections){
            lstSectionId.add(section.Id);
        }

        List<String> lstRequestFields = AP_Constant.getCreatableFieldsByObjName(AP_Constant.sObjectRequest);
        String strRequestFields = String.join(lstRequestFields , ', ');
        Map<String, Id> mapRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectRequest});
        String recordTypeIdQuoteReq = mapRecTypeId.get(AP_Constant.reqRTQuote);

        String queryRequest = 'select Id, '
                            + strRequestFields
                            + ' from Request__c where (Section__c IN :lstSectionId AND RecordTypeId = :recordTypeIdQuoteReq AND LastVersionAnswered__c = TRUE AND LastVersionSent__c = TRUE ) ' //TECH_LatestVersion__c = TRUE
                            + ' ORDER BY LastModifiedDate ASC';

        List<Request__c> lstQuoteRequests = Database.query(queryRequest);

        for(Request__c request : lstQuoteRequests){
            List<Request__c> lstRequest = new List<Request__c>();
            if(mapLstRequestBySectionId.containsKey(request.Section__c)){
                lstRequest = mapLstRequestBySectionId.get(request.Section__c);
                lstRequest.add(request);
                mapLstRequestBySectionId.put(request.Section__c, lstRequest);
            }
            else{
                lstRequest.add(request);
                mapLstRequestBySectionId.put(request.Section__c, lstRequest);
            }
        }

        for(Id key : mapLstRequestBySectionId.keySet()){
            List<Request__c> lstRequest = mapLstRequestBySectionId.get(key);
            Request__c requestByLastVersion = new Request__c();

            for(Request__c request : lstRequest){
                //check if each request broker-reinsurer is found in lstLeader(Broker-Reinsurer)
                for(String brokerReinsurerId : lstLeader){
                    String brokerId = brokerReinsurerId.split('-')[0];
                    if(brokerId == 'undefined'){
                        brokerId = null;
                    }
                    String reinsurerId = brokerReinsurerId.split('-')[1];

                    //lstRequest ORDERED ASC By CreatedDate
                    //hence, request will be overwritten until last request with same broker and reinsurer
                    if (!Test.isRunningTest()){
                        if(request.Broker__c == brokerId && request.Reinsurer__c == reinsurerId){
                            requestByLastVersion = request;
                        }
                    }
                }
            }
            mapLastCreatedRequestBySectionId.put(key, requestByLastVersion);
        }

        mapResults.put('lstSections', lstSections);
        mapResults.put('mapLastCreatedRequestBySectionId', mapLastCreatedRequestBySectionId);
        return mapResults;
    }

    /**
    * @description Method to get Reinsurer from Quote Requests
    * @param Id treatyId
    * @return List<Request__c>
    */
    @AuraEnabled
    public static List<Request__c> loadReinsurerFromQuote(Id treatyId) {
        Map<String, Id> mapReqRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectRequest});
        Set<String> setExistingBrokerReinsurer = new Set<String>();
        List<Request__c> lstUniqueRequestQuote =  new List<Request__c>();
        //map of List of Quote Request of Treaty by Broker/Reinsurer
        Map<String, List<Request__c>> mapQuoteRequestByBrokerRein = new Map<String, List<Request__c>>();
        List<Request__c> lstFirstSectionQuoteRequest = new List<Request__c>();
        List<Request__c> lstRequestsLead = new List<Request__c>();
        List<Request__c> lstRequestsQuote = new List<Request__c>();

        for(Request__c leadReq : [SELECT Id, Name, Reinsurer__c, Broker__c, Broker__r.IsActive__c, Reinsurer__r.IsActive__c, FixedRate__c, MinRate__c, QuoteOnBehalf__c, LeadOnBehalf__c, PlacementOnBehalf__c, WrittenShareResponse__c, CommentsResponse__c, ReinsurerExpenses__c, LossCarryingForward__c, OrUnlimited__c, LossCorridorPart__c, LossCorridorMaxLR__c, LossCorridorMinLR__c, NoClaimBonus__c,NoClaimBonusAmount__c, ProfitCommission__c, MaxRate__c, ProvisionalRate__c, FlatPremium__c, MDP__c, FixedCommission__c, MinVarCommission__c, MaxVarCommission__c, ProvisionalCommission__c, PerHeadPremium__c, MinPerHeadAmount__c, MaxPerHeadAmount__c, ProvisionalPerHeadPremium__c, EstimatedReinsurancePremium__c, EstimatedInsurancePremium__c
                                  FROM Request__c
                                  WHERE Treaty__c = :treatyId
                                  AND RecordTypeId = :mapReqRecTypeId.get(AP_Constant.reqRTLead)]){
            if(leadReq.Broker__c != null && (leadReq.Broker__r.IsActive__c == TRUE && leadReq.Reinsurer__r.IsActive__c == TRUE)){
                lstRequestsLead.add(leadReq);
            }
            else if(leadReq.Broker__c == null && leadReq.Reinsurer__r.IsActive__c == TRUE){
               lstRequestsLead.add(leadReq);
            }
        }

        for(Request__c quoteReq :[SELECT Id, Name, Section__r.SectionNumber__c, FixedRate__c , MinRate__c, QuoteOnBehalf__c, LeadOnBehalf__c, PlacementOnBehalf__c, WrittenShareResponse__c, CommentsResponse__c, ReinsurerExpenses__c, LossCarryingForward__c, OrUnlimited__c, LossCorridorPart__c, LossCorridorMaxLR__c, LossCorridorMinLR__c, NoClaimBonus__c,NoClaimBonusAmount__c, ProfitCommission__c, MaxRate__c, ProvisionalRate__c, FlatPremium__c, MDP__c, FixedCommission__c, MinVarCommission__c, MaxVarCommission__c, ProvisionalCommission__c, PerHeadPremium__c, MinPerHeadAmount__c, MaxPerHeadAmount__c, ProvisionalPerHeadPremium__c, EstimatedReinsurancePremium__c, EstimatedInsurancePremium__c, CreatedDate, Reinsurer__c, Broker__c, Treaty__c, TECH_TreatyName__c, TECH_ReinsurerName__c, TECH_BrokerName__c, Broker__r.IsActive__c, Reinsurer__r.IsActive__c, LastVersionAnswered__c, LastVersionSent__c
                                  FROM Request__c
                                  WHERE Treaty__c = :treatyId
                                  AND RecordTypeId = :mapReqRecTypeId.get(AP_Constant.reqRTQuote)]){
            if(quoteReq.Broker__c != null && (quoteReq.Broker__r.IsActive__c == TRUE && quoteReq.Reinsurer__r.IsActive__c == TRUE)){
                lstRequestsQuote.add(quoteReq);
            }
            else if(quoteReq.Broker__c == null && quoteReq.Reinsurer__r.IsActive__c == TRUE){
               lstRequestsQuote.add(quoteReq);
            }
        }

        //Get existed Broker-Reinsurer for Quote Request which is already created in Lead Request
        for(Request__c requestQuote : lstRequestsQuote){
            for(Request__c requestLead :lstRequestsLead){
                if(requestQuote.Broker__c == requestLead.Broker__c && requestQuote.Reinsurer__c == requestLead.Reinsurer__c){
                    setExistingBrokerReinsurer.add(requestQuote.Broker__c + '-' + requestQuote.Reinsurer__c);
                }
            }
        }

        for(Request__c requestQuote : lstRequestsQuote){
            String brokerRein = requestQuote.Broker__c + '-' + requestQuote.Reinsurer__c;
            List<Request__c> lstQuoteRequests = new List<Request__c>();
            if(mapQuoteRequestByBrokerRein.containsKey(brokerRein)){
                lstQuoteRequests = mapQuoteRequestByBrokerRein.get(brokerRein);
                lstQuoteRequests.add(requestQuote);
                mapQuoteRequestByBrokerRein.put(brokerRein, lstQuoteRequests);
            }
            else{
                lstQuoteRequests.add(requestQuote);
                mapQuoteRequestByBrokerRein.put(brokerRein, lstQuoteRequests);
            }
        }

        for(String brokerReinStr : mapQuoteRequestByBrokerRein.keySet()){
            List<Request__c> lstQuoteRequests = mapQuoteRequestByBrokerRein.get(brokerReinStr);
            Request__c quoteRequestOfFirstSection = lstQuoteRequests[0];
            for(Request__c request : lstQuoteRequests){
                if(Decimal.valueOf(request.Section__r.SectionNumber__c) < Decimal.valueOf(quoteRequestOfFirstSection.Section__r.SectionNumber__c)){
                    //quoteRequestOfFirstSection.FixedRate__c = request.FixedRate__c.setscale(6,RoundingMode.DOWN);
                    quoteRequestOfFirstSection = request;
                }
            }
            lstFirstSectionQuoteRequest.add(quoteRequestOfFirstSection);
        }
        for(Request__c requestQuote : lstFirstSectionQuoteRequest){
            if(setExistingBrokerReinsurer.contains(requestQuote.Broker__c + '-' + requestQuote.Reinsurer__c) == false){
                lstUniqueRequestQuote.add(requestQuote);
            }
        }

        return lstUniqueRequestQuote;
    }

    /**
    * @description Method to save Lead Request
    * @param List<Request__c> lstParentLeadRequest, List<Request__c> lstChildLeadRequest
    * @return Map<String, Object>
    */
    @AuraEnabled
    public static Map<String, Object> saveLeadRequestRecord(List<Request__c> lstParentLeadRequest, List<Request__c> lstChildLeadRequest) {
        Map<String, Object> mapResults = new Map<String, Object>();
        Map<String, Id> mapRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectRequest});
        Map<String, List<Request__c>> mapParentChild = new Map<String, List<Request__c>>();
        List<Request__c> lstChildRequestToInsert = new List<Request__c>();
        List<LeadRequestSelection__c> lstLeadRequestSelection = new List<LeadRequestSelection__c>();
        Savepoint sp = Database.setSavepoint();

        try{
            for(Integer i = 0; i < lstParentLeadRequest.size(); i++) {
                lstParentLeadRequest[i].TECH_Actor2Id__c = null;
                lstParentLeadRequest[i].SentBy__c = null;
                Request__c parentRequest = new Request__c();

                parentRequest = lstParentLeadRequest[i];
                parentRequest.RecordTypeId = mapRecTypeId.get(AP_Constant.reqRTLead);
                parentRequest.OriginalRequest__c = null;
                parentRequest.LastVersionSent__c = false;
                parentRequest.LastVersionAnswered__c = false;
                parentRequest.TECH_ParentChildRef__c = String.valueOf(i);
                if(parentRequest.LeadType__c == null){
                    parentRequest.LeadType__c = '1';
                }

                //RRA - ticket 1363 - 05122022 => Definitive
                if (parentRequest.LeadType__c == '2' && parentRequest.ReinsurerStatus__c == 'Setup'){
                    parentRequest.LastVersionSent__c = true;
                    parentRequest.LastVersionAnswered__c = true;
                }

                //RRA - ticket 1363 - 12122022 => Simulated
                if (parentRequest.LeadType__c == '1' && parentRequest.ReinsurerStatus__c == 'Setup'){
                    parentRequest.LastVersionSent__c = false;
                    parentRequest.LastVersionAnswered__c = false;
                }

                for(Integer j = 0; j < lstChildLeadRequest.size(); j++) {
                    lstChildLeadRequest[j].SentBy__c = null;
                    Request__c newChild = new Request__c();
                    newChild = lstChildLeadRequest[j].clone(false, true);
                    newChild.TECH_ParentChildRef__c = String.valueOf(i);
                    newChild.RecordTypeId = mapRecTypeId.get(AP_Constant.reqRTLead);
                    newChild.OriginalRequest__c = null;
                    newChild.LastVersionSent__c = false;
                    newChild.LastVersionAnswered__c = false;
                    newChild.TECH_Actor2Id__c = null;

                    if(mapParentChild.containsKey(String.valueOf(i))){
                        mapParentChild.get(String.valueOf(i)).add(newChild);
                    }
                    else{
                        mapParentChild.put(String.valueOf(i), new List<Request__c>{newChild});
                    }  
                }
            }

            if(mapParentChild.size() > 0){
                for(String key : mapParentChild.keySet()) {
                    lstChildRequestToInsert.addAll(mapParentChild.get(key));
                }
            }

            if(lstParentLeadRequest.size() > 0){
                insert lstParentLeadRequest;
            }

            if(lstChildRequestToInsert.size() > 0){
                insert lstChildRequestToInsert;
            }

            for(Request__c childRequest : lstChildRequestToInsert){
                for(Request__c parentRequest : lstParentLeadRequest){
                    if(childRequest.TECH_ParentChildRef__c == parentRequest.TECH_ParentChildRef__c) {
                        LeadRequestSelection__c leadRequestSelection = new LeadRequestSelection__c();
                        leadRequestSelection.LeadRequestChild__c = childRequest.Id;
                        leadRequestSelection.LeadRequestParent__c = parentRequest.Id;
                        lstLeadRequestSelection.add(leadRequestSelection);
                    }

                    //RRA - ticket 1363 - 05122022 => Definitive
                    if (parentRequest.LeadType__c == '2' && parentRequest.ReinsurerStatus__c == 'Setup'){
                        childRequest.LastVersionAnswered__c = true;
                        childRequest.LastVersionSent__c = true;
                        childRequest.isFirstSending__c = false;//RRA VERSIONING

                    //RRA - ticket 1363 - 05122022 => Simulated
                    }if (parentRequest.LeadType__c == '1' && parentRequest.ReinsurerStatus__c == 'Setup'){
                        childRequest.LastVersionAnswered__c = false;
                        childRequest.LastVersionSent__c = false;
                        childRequest.isFirstSending__c = false;//RRA VERSIONING
                    }
                }
            }

             //RRA - ticket 1363 - 05122022
             if(lstChildRequestToInsert.size() > 0){
                update lstChildRequestToInsert;
            }

            if(lstLeadRequestSelection.size() > 0){
                insert lstLeadRequestSelection;
            }

            mapResults.put('Success', 'Success');
        }
        catch (Exception ex) {
            Database.rollback(sp);
            mapResults.put('Error', ex.getMessage());
        }
        return mapResults;
    }

    /**
    * @description Method to get Broker/Reinsurer of Program
    * @param Id programId
    * @return Map<String, Object>
    */
    @AuraEnabled
    public static Map<String, Object> getBrokersAndReinsurers(Id programId){
        //get all brokers + reinsurer related to the program (from requests)
        Map <String, Object> mapResults = new Map <String, Object>();
        List <Request__c> lstFilteredRequests = new List<Request__c>();
        Set<string> setExistingValues = new Set<string>();

        try{
            List <Request__c> lstAllRequests = [ SELECT Id,
                                                        Name,
                                                        TECH_BrokerName__c, 
                                                        TECH_ReinsurerName__c, Broker__c, Reinsurer__c
                                                 FROM Request__c
                                                 WHERE Program__c =: programId
                                                 AND   TECH_BrokerName__c != null
                                                 AND   TECH_ReinsurerName__c != null
                    AND Broker__r.IsActive__c = TRUE AND Reinsurer__r.IsActive__c = TRUE
                                                ];
            if(lstAllRequests.size() < 1){
                mapResults.put('Error', 'No Request is available for this Treaty.');
            }
            else{
                for(Request__c request : lstAllRequests){
                    String value = request.TECH_BrokerName__c + '_' + request.TECH_ReinsurerName__c;
    
                    if(!setExistingValues.contains(value)){
                        lstFilteredRequests.add(request);
                        setExistingValues.add(value);
                    }
                }
                mapResults.put('Success', lstFilteredRequests);
                mapResults.put('AllRequests', lstAllRequests);
            }
        }
        catch (Exception ex) {
            mapResults.put('Error', ex.getMessage());
        }
        return mapResults;
    }
}