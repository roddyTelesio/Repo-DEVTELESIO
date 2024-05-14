public with sharing class LWC24_NewPlacementRequest {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Controller for Lightning Web Component LWC24_NewPlacementRequest
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 25-FEB-2020  DMO   1.0      Initial version
-- 21-May-2021  MBE   1.1      W-0974 - Bug bloquant Prod - Impossibilité de créer une Lead request - TECH_Actor2Id__c
-- 08-JUL-2021  NBI   1.2      W-0992: Third Party Management
-- 14-JUN-2021  MBE   1.3      W-0894 - ODS - TECH_SentByUser__c seems empty after a modification of a lead request
--------------------------------------------------------------------------------------
**************************************************************************************/
    /**
    * @description Method to get Sections of Treaty
    * @param Id treatyId
    * @param List<Request__c> lstBrokerReinsurers
    * @return Map<String, Object>
    */
    @AuraEnabled
    public static Map<String, Object> getAllSections(Id treatyId, List<Request__c> lstBrokerReinsurers){
        Map<String, Object> mapResults = new Map<String, Object>();
        List<String> lstSectionFields = AP_Constant.getCreatableFieldsByObjName(AP_Constant.sObjectSection);
        String strSectionFields = String.join(lstSectionFields , ', ');
        Set<Id> lstSectionId = new Set<Id>();

        String querySection = 'select Id, Program__r.LTA__c, Treaty__c, '
                            + strSectionFields
                            + ' from Section__c where Treaty__c = :treatyId ';

        List<Section__c> lstSections = Database.query(querySection);

        for(Section__c section : lstSections){
            lstSectionId.add(section.Id);
        }

        List<String> lstRequestFields = AP_Constant.getCreatableFieldsByObjName(AP_Constant.sObjectRequest);
        String strRequestFields = String.join(lstRequestFields , ', ');
        Map<String, Id> mapRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectRequest});
        String recordTypeIdPlacementReq = mapRecTypeId.get(AP_Constant.reqRTPlacement);

        String queryRequest = 'select Id, '
                            + strRequestFields
                            + ' from Request__c where (Section__c IN :lstSectionId AND RecordTypeId = :recordTypeIdPlacementReq AND TECH_LatestVersion__c = TRUE ) '
                            + ' ORDER BY LastModifiedDate ASC';

        List<Request__c> lstPlacementRequests = Database.query(queryRequest);
        Map<Id, List<Request__c>> mapLstRequestBySectionId = new Map<Id, List<Request__c>>();

        for(Request__c request : lstPlacementRequests){
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

        Map<Id, Request__c> mapLastCreatedRequestBySectionId = new Map<Id, Request__c>();

        for(Id key : mapLstRequestBySectionId.keySet()){
            List<Request__c> lstRequest = mapLstRequestBySectionId.get(key);
            Request__c requestByLastVersion = new Request__c();

            for(Request__c request : lstRequest){
                //check if each request broker-reinsurer is found in lstLeader(Broker-Reinsurer)
                for(Request__c item : lstBrokerReinsurers){
                    //lstRequest ORDERED ASC By CreatedDate
                    //hence, request will be overwritten until last request with same broker and reinsurer
                    if(request.Broker__c == item.Broker__c && request.Reinsurer__c == item.Reinsurer__c){
                        requestByLastVersion = request;
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
    * @description Method to save Placement Request
    * @param List<Request__c> lstPlacementLeadRequest
    * @return Map<String, Object>
    */
    @AuraEnabled
    public static Map<String, Object> savePlacementRequestRecord(List<Request__c> lstPlacementLeadRequest) {
        Map<String, Object> mapResults = new Map<String, Object>();
        Map<String, Id> mapRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectRequest});

        try{

            String userId = UserInfo.getUserId();
            User activeUser = [Select Email From User where Id = : userId limit 1];
            String userEmail = activeUser.Email;


            for(Request__c request : lstPlacementLeadRequest){
                request.RecordTypeId = mapRecTypeId.get(AP_Constant.reqRTPlacement);
                request.ReinsurerStatus__c = 'Setup';
                request.TECH_OwnerEmail__c = userEmail;
                request.TECH_Actor2Id__c = null;
                request.SentBy__c = null;
            }

            if(lstPlacementLeadRequest.size() > 0) {
                insert lstPlacementLeadRequest;
            }

            mapResults.put('Success', 'Success');
        }
        catch (Exception ex){
            mapResults.put('Error', ex.getMessage());
        }

        return mapResults;
    }

    /**
    * @description Method to save Load previous year of Program
    * @param Id selectedProgram
    * @param Id selectedTreaty
    * @return List<Request__c>
    */
    @AuraEnabled(Cacheable = true)
    public static List<Request__c> loadPreviousYear(Id selectedProgram){
        System.debug('selectedProgram == '+ selectedProgram);
        Map<String, Id> mapRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectRequest});
        String recordTypePlacementId = mapRecTypeId.get(AP_Constant.reqRTPlacement);
        String recordTypeLeadId = mapRecTypeId.get(AP_Constant.reqRTLead);
        System.debug('recordTypePlacementId == '+ recordTypePlacementId);
        System.debug('recordTypeLeadId == '+ recordTypeLeadId);
        List<Request__c> lstRequestPlacement = new List<Request__c>();
        List<Request__c> lstRequestsLead = new List<Request__c>();
        Program__c renewedProgram = [SELECT Id, RenewedFromProgram__c FROM Program__c WHERE Id = :selectedProgram];
        Id renewedFromProgramId = renewedProgram.RenewedFromProgram__c;
        List<Request__c> lstRequestPlacementUnique = new List<Request__c>();
        List<Request__c> lstRequestPlacementUniqueAll = new List<Request__c>();
        
        map<String, List<Request__c>> mapKeyRelatedPlacementReq = new map<String, List<Request__c>>();
        map<String, List<Request__c>> mapKeyRelatedLeadReq = new map<String, List<Request__c>>();
        Boolean isContain = false;
        
          //Get placement request existing on previous year // RRA -ticket 1571 - 11092023
        if(renewedFromProgramId != null){
            for(Request__c placReq : [SELECT Id, Treaty__c,  TECH_TreatyName__c, TECH_ReinsurerName__c, TECH_BrokerName__c, Broker__c, Reinsurer__c, Program__c, Broker__r.IsActive__c, Reinsurer__r.IsActive__c FROM Request__c WHERE Program__c =:renewedFromProgramId AND RecordTypeId = :recordTypePlacementId]){
                if(placReq.Broker__c != null && (placReq.Broker__r.IsActive__c && placReq.Reinsurer__r.IsActive__c)){
                    if (mapKeyRelatedPlacementReq.containsKey(placReq.Broker__c + '-' + placReq.Reinsurer__c)){
                        mapKeyRelatedPlacementReq.get(placReq.Broker__c + '-' + placReq.Reinsurer__c).add(placReq);
                    }else{
                        mapKeyRelatedPlacementReq.put(placReq.Broker__c + '-' + placReq.Reinsurer__c, new List<Request__c>{placReq});
                    }
                }else if (placReq.Broker__c == null && placReq.Reinsurer__r.IsActive__c){
                    if (mapKeyRelatedPlacementReq.containsKey(placReq.Reinsurer__c)){
                        mapKeyRelatedPlacementReq.get(placReq.Reinsurer__c).add(placReq);
                    }else{
                        mapKeyRelatedPlacementReq.put(placReq.Reinsurer__c, new List<Request__c>{placReq});
                    }
                }            
                
            }
        }
        System.debug('mapKeyRelatedPlacementReq == '+ mapKeyRelatedPlacementReq);
        System.debug('mapKeyRelatedPlacementReq.SIZE == '+ mapKeyRelatedPlacementReq.size());
        //Get lead request existing on current year // RRA -ticket 1571 - 11092023
        for(Request__c leadReq : [SELECT Id, Name, Reinsurer__c, Broker__c, Treaty__c, TECH_TreatyName__c, TECH_ReinsurerName__c, TECH_BrokerName__c, Program__c, Broker__r.IsActive__c, Reinsurer__r.IsActive__c FROM Request__c WHERE Program__c =:selectedProgram AND RecordTypeId =:recordTypeLeadId]){
            if(leadReq.Broker__c != null && (leadReq.Broker__r.IsActive__c && leadReq.Reinsurer__r.IsActive__c)){
                if (mapKeyRelatedLeadReq.containsKey(leadReq.Broker__c + '-' + leadReq.Reinsurer__c)){
                    mapKeyRelatedLeadReq.get(leadReq.Broker__c + '-' + leadReq.Reinsurer__c).add(leadReq);
                }else{
                    mapKeyRelatedLeadReq.put(leadReq.Broker__c + '-' + leadReq.Reinsurer__c, new List<Request__c>{leadReq});
                }
            }else if (leadReq.Broker__c == null && leadReq.Reinsurer__r.IsActive__c){
                if (mapKeyRelatedLeadReq.containsKey(leadReq.Reinsurer__c)){
                    mapKeyRelatedLeadReq.get(leadReq.Reinsurer__c).add(leadReq);
                }else{
                    mapKeyRelatedLeadReq.put(leadReq.Reinsurer__c, new List<Request__c>{leadReq});
                }
            }
        }
        System.debug('mapKeyRelatedLeadReq == '+ mapKeyRelatedLeadReq);
        System.debug('mapKeyRelatedLeadReq.SIZE == '+ mapKeyRelatedLeadReq.size());
        
        //Compare mapPlacement and mapLead to retrieve the key existing in Lead but not contain in Placement Request // RRA -ticket 1571 - 11092023
        for (String keyPlac : mapKeyRelatedPlacementReq.keySet()){
            for (String keyLead : mapKeyRelatedLeadReq.keySet()){
                if (keyLead.equals(keyPlac)){
                    isContain = true;
                }else {
                    isContain =false;
                }
                System.debug('keyPlac == '+ keyPlac + '========= ' + 'keyLead ==' + keyLead);
                System.debug('isContain == '+ isContain);
            }
            if (isContain == false){
                lstRequestPlacementUnique.addAll(mapKeyRelatedPlacementReq.get(keyPlac));
            }
        }
     
        System.debug('lstRequestPlacementUnique == '+ lstRequestPlacementUnique);
        return lstRequestPlacementUnique;
    }

    /**
    * @description Method to get UW year of Program
    * @param Id progId
    * @return Map<String, Object>
    */
    @AuraEnabled
    public static Map<String, Object> getUWYearForOriginalProgram(Id progId){
        Map<String, Object> mapResults = new Map<String, Object>();

        Program__c renewedProgram = [SELECT Id, RenewedFromProgram__c, TypeOfRenew__c FROM Program__c WHERE Id = :progId];
        Id renewedFromProgramId = renewedProgram.RenewedFromProgram__c;
        String uwYearOriginalProgram = null;
        Boolean isProgRenewedStandRene = false;

        if(renewedFromProgramId != null){
            if(renewedProgram.TypeOfRenew__c == 'Standard Renew' || renewedProgram.TypeOfRenew__c == 'LTA/TR Renegotiation'){
                //program is renewed Standard/Renegotiation
                Program__c originalProgram = [SELECT Id, UwYear__c FROM Program__c WHERE Id = :renewedFromProgramId];
                uwYearOriginalProgram = originalProgram.UwYear__c;
                isProgRenewedStandRene = true;
            }
        }

        mapResults.put('uwYearOriginalProgram', uwYearOriginalProgram);
        mapResults.put('isProgRenewedStandRene', isProgRenewedStandRene);
        return mapResults;
    }
    /**
    * @description Method to get Treaties of Program
    * @param Id selectedProgramId
    * @return List<OptionWrapper>
    */
    @AuraEnabled(Cacheable = true)
    public static List<OptionWrapper> getTreaties(Id selectedProgramId ){
        Map<String, Id> mapRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectRequest});
        String recordTypeLeadId = mapRecTypeId.get(AP_Constant.reqRTLead);
        Map<Id, List<Section__c>> mapLstSectionByTreatyId = new Map<Id, List<Section__c>>();
        List<OptionWrapper> lstTreatyForRetainToLead = new List<OptionWrapper>();
        Set<Id> setLeadTreatyIds =  new Set<Id>();

        //MBE 04/09
         //RRA - ticket 1524 - 24052023
        List<Treaty__c> lstTreaties = [SELECT Id, Name, Layer__c FROM Treaty__c WHERE Program__c = :selectedProgramId AND Status__c = :AP_Constant.statusActive ORDER BY Name];

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
        //SAU 23/06
        for(Request__c request : [ SELECT Id, Treaty__c
                                   FROM Request__c
                                   WHERE Program__c =: selectedProgramId
                                   AND RecordTypeId =: recordTypeLeadId
                                   AND TECH_LeadType__c = 'parent']){
            setLeadTreatyIds.add(request.Treaty__c);
        }

        for(Treaty__c treaty : lstTreaties){
            if(mapLstSectionByTreatyId.containsKey(treaty.Id) && setLeadTreatyIds.contains(treaty.Id)){
                lstTreatyForRetainToLead.add(new OptionWrapper(treaty.Name, treaty.Id, treaty.Layer__c)); //RRA - ticket 1524 - 24052023
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
    * @description Method to get Reinsurer of Quote
    * @param List<Id> lstTreatyId
    * @return List<Request__c>
    */
    @AuraEnabled(Cacheable=true)
    public static List<Request__c> loadReinsurerFromQuote(List<Id> lstTreatyId) {
        Map<String, Id> mapReqRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectRequest});
        Set<String> setExistingBrokerReinsurer = new Set<String>();
        List<Request__c> lstUniqueRequestQuote =  new List<Request__c>();
        List<Request__c> lstRequestsLead = new List<Request__c>();
        List<Request__c> lstRequestsQuote = new List<Request__c>();

        for(Request__c leadReq : [SELECT Id, Name, Reinsurer__c, Broker__c, Treaty__c, TECH_TreatyName__c, TECH_ReinsurerName__c, TECH_BrokerName__c, Broker__r.IsActive__c, Reinsurer__r.IsActive__c
                                  FROM Request__c
                                  WHERE Treaty__c IN :lstTreatyId
                                  AND RecordTypeId = :mapReqRecTypeId.get(AP_Constant.reqRTLead)]){
            if(leadReq.Broker__c != null && (leadReq.Broker__r.IsActive__c == TRUE && leadReq.Reinsurer__r.IsActive__c == TRUE)){
                lstRequestsLead.add(leadReq);
            }
            else if(leadReq.Broker__c == null && leadReq.Reinsurer__r.IsActive__c == TRUE){
               lstRequestsLead.add(leadReq);
            }
        }

        for(Request__c quoteReq :[SELECT Id, Name, Section__r.SectionNumber__c, WrittenShareResponse__c, CreatedDate, Reinsurer__c, Broker__c, Treaty__c, TECH_TreatyName__c, TECH_ReinsurerName__c, TECH_BrokerName__c
                                         , Broker__r.IsActive__c, Reinsurer__r.IsActive__c
                                  FROM Request__c
                                  WHERE Treaty__c IN :lstTreatyId
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
                if(requestQuote.Treaty__c == requestLead.Treaty__c && requestQuote.Broker__c == requestLead.Broker__c && requestQuote.Reinsurer__c == requestLead.Reinsurer__c){
                    setExistingBrokerReinsurer.add(requestQuote.Treaty__c + '-' + requestQuote.Broker__c + '-' + requestQuote.Reinsurer__c);
                }
            }
        }
        //map of List of Quote Request of Treaty by Broker/Reinsurer
        Map<String, List<Request__c>> mapQuoteRequestByBrokerRein = new Map<String, List<Request__c>>();

        for(Request__c requestQuote : lstRequestsQuote){
            String brokerRein = requestQuote.Treaty__c + '-' + requestQuote.Broker__c + '-' + requestQuote.Reinsurer__c;
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

        List<Request__c> lstFirstSectionQuoteRequest = new List<Request__c>();

        for(String brokerReinStr : mapQuoteRequestByBrokerRein.keySet()){
            List<Request__c> lstQuoteRequests = mapQuoteRequestByBrokerRein.get(brokerReinStr);
            Request__c quoteRequestOfFirstSection = lstQuoteRequests[0];
            for(Request__c request : lstQuoteRequests){
                if(request.Section__r.SectionNumber__c != null && quoteRequestOfFirstSection.Section__r.SectionNumber__c != null){
                    if(Decimal.valueOf(request.Section__r.SectionNumber__c) < Decimal.valueOf(quoteRequestOfFirstSection.Section__r.SectionNumber__c)){
                        quoteRequestOfFirstSection = request;
                    }
                }
            }
            lstFirstSectionQuoteRequest.add(quoteRequestOfFirstSection);
        }

        for(Request__c requestQuote : lstFirstSectionQuoteRequest){
            if(setExistingBrokerReinsurer.contains(requestQuote.Treaty__c + '-' + requestQuote.Broker__c + '-' + requestQuote.Reinsurer__c) == false){
                lstUniqueRequestQuote.add(requestQuote);
            }
        }

        return lstUniqueRequestQuote;
    }

    /**RRA - ticket 1571 - 11092023
    * @description Method to get Reinsurer/Broker belongs to Program
    * @param List<String> lstIds
    * @param Id programId
    * @return Boolean
    */
    @AuraEnabled
    public static Boolean checkReinsurerBroker(List<String> lstIds, Id programId, String recordTypeName){
        Set<String> setIds = new Set<String>();
        Set<String> lstIdsNew = new Set<String>();
        setIds.addAll(lstIds);
        lstIdsNew.addAll(setIds);
        Boolean result = false;
        String treatySectionBrokerReins = '';
        Map<String, Id> mapRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectRequest});
        String recordTypeIdPlacementReq = mapRecTypeId.get(AP_Constant.reqRTPlacement);
        String recordTypeIdQuoteReq = mapRecTypeId.get(AP_Constant.reqRTQuote);
        String recordTypeIdLeadReq = mapRecTypeId.get(AP_Constant.reqRTLead);
        Boolean isBrokerReins = false;
        List<String> lstTreatyKey = new List<String>();
        String KeyFromRequest;
        String keyFromBeforeInsertion;
        Set<Id> setAllSectionIdFromConditions = new Set<Id>();
        Set<Id> setAllSectionIdFromRequests = new Set<Id>();
        List<Id> lstNewSectionId = new List<Id>();
        Map <Id, List<Id>> mapSectionsByTreatyId = new Map<Id, List<Id>>();
        Map<String, Set<Id>> mapBrokerReinsToSections = new Map<String, Set<Id>>();
        Boolean isQuoteBrokerReins = false;
        
        String query = 'SELECT Id, Treaty__c, Reinsurer__c, Broker__c, Broker__r.IsActive__c, Reinsurer__r.IsActive__c, Section__c FROM Request__c';
        System.debug('setIds == '+setIds);
        System.debug('recordTypeName == '+recordTypeName);
        if (recordTypeName == 'Placement' || recordTypeName == 'Lead'){//RRA - ticket 1571 - 20092023
            query = query + ' WHERE Program__c =: programId AND (RecordTypeId =: recordTypeIdPlacementReq OR RecordTypeId =: recordTypeIdLeadReq) AND TECH_TreatyBrokerReinsurer__c IN:setIds';
        }else if (recordTypeName == 'Quote'){
            query = query + ' WHERE Program__c =: programId AND (RecordTypeId =: recordTypeIdQuoteReq) AND TECH_TreatyBrokerReinsurer__c IN:setIds';//RRA - ticket 1571 - 15092023
        }
        System.debug('query == '+query);
        List<Request__c> lstReqQuotePlacement = Database.query(query);
        System.debug('lstReqQuotePlacement == '+lstReqQuotePlacement);
        
        
        if (setIds.size()>0){
            //Get treaty in the key
            for(String keyT : lstIdsNew){
                lstTreatyKey.add(keyT.split('-')[0]);
                keyFromBeforeInsertion = keyT;
            }
            //Loop on Section to get the list Section active and attached on this treaty / create map to link <TreatyId, List<IdSection>>
            for(Section__c section : [SELECT Id, Treaty__c FROM Section__c WHERE Treaty__c IN: lstTreatyKey AND Status__c = :AP_Constant.statusActive]){
                setAllSectionIdFromConditions.add(section.Id);
            }

        }
        System.debug('lstTreatyKey == '+lstTreatyKey);
        //
        System.debug('keyFromBeforeInsertion == '+keyFromBeforeInsertion);
        System.debug('setAllSectionIdFromConditions == '+setAllSectionIdFromConditions);
        System.debug('setAllSectionIdFromConditions.size == '+setAllSectionIdFromConditions.size());
        //Set <Id> setSectionIdsAll =  new Set <Id>();
        Set<Id> setSecIdFromCondNoExistInReq = new Set<Id>();
        Set<Id> setSecIdFromCondExistInReq = new Set<Id>();
        for( Request__c request : lstReqQuotePlacement){
            keyFromRequest = request.Treaty__c + '-' + request.Broker__c + '-' + request.Reinsurer__c;
           // System.debug('keyFromRequest == '+keyFromRequest + ' : ' + 'keyFromBeforeInsertion == ' + keyFromBeforeInsertion);
            if (request.Broker__c == null && request.Reinsurer__c != null && request.Reinsurer__r.IsActive__c){
                if (recordTypeName == 'Quote'){
                    isQuoteBrokerReins = true;
                    setAllSectionIdFromRequests.add(request.Section__c);
                }else if (recordTypeName == 'Placement' || recordTypeName == 'Lead'){//RRA - ticket 1571 - 20092023
                    result = true;
                }
            }else if(request.Broker__c != null && request.Reinsurer__c != null && request.Broker__r.IsActive__c && request.Reinsurer__r.IsActive__c){
                if (recordTypeName == 'Quote'){
                    isQuoteBrokerReins = true;
                    setAllSectionIdFromRequests.add(request.Section__c);
                }else if (recordTypeName == 'Placement' || recordTypeName == 'Lead'){//RRA - ticket 1571 - 20092023
                    result = true;
                }
            }
           
        }
        
        if (isQuoteBrokerReins){
            if (setAllSectionIdFromConditions.size() != setAllSectionIdFromRequests.size()){
                result = false;
            }else{
                result = true;
            }
        }
    
        System.debug('setSecIdFromCondNoExistInReq == '+setSecIdFromCondNoExistInReq);
        System.debug('setSecIdFromCondExistInReq == '+setSecIdFromCondExistInReq);
        System.debug('setAllSectionIdFromRequests == '+setAllSectionIdFromRequests);
        System.debug('setAllSectionIdFromRequests.size == '+setAllSectionIdFromRequests.size());
        System.debug('result == '+ result);
     
        return result;       
    }
    

    /**
    * @description Method to filter Request by broker and reinsurer which are not present in Placement
    * @param List<String> lstIds
    * @param Id programId
    * @return  List<String>
    */
    @AuraEnabled
    public static List<String> filterBrokerReinsAll(List<String> lstIds, Id programId){
        List<String> lstBrokerReinToDisplay = new List<String>();
        Map<String, Id> mapRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectRequest});
        String recordTypeIdPlacementReq = mapRecTypeId.get(AP_Constant.reqRTPlacement);

        Set<String> setAvailableReqBrokRein = new Set<String>();

        for( Request__c request : [SELECT Id, Treaty__c, Reinsurer__c, Broker__c
                                   FROM Request__c
                                   WHERE Program__c =: programId
                                   AND RecordTypeId =: recordTypeIdPlacementReq
                                   AND Broker__r.IsActive__c = TRUE AND Reinsurer__r.IsActive__c = TRUE]){

            String treatyReinBroker = request.Treaty__c + '-' + request.Broker__c + '-' + request.Reinsurer__c;
            setAvailableReqBrokRein.add(treatyReinBroker);
        }

        for(String brokerReins : lstIds){
            if(!setAvailableReqBrokRein.contains(brokerReins)){
                lstBrokerReinToDisplay.add(brokerReins);
            }
        }

        return lstBrokerReinToDisplay;
    }
}