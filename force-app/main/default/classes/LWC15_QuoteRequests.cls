public with sharing class LWC15_QuoteRequests {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Controller for Lightning Web Component lwc15QuoteRequests
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 20-DEC-2019  MBE   1.0      Initial version
-- 06-MAY-2020  SAU   1.1      Filter reinsurer
-- 03-AUG-2020  SAU   1.2      Create request only for new section for same broker/reinsurer
-- 21-May-2021  MBE   1.3      W-0974 - Bug bloquant Prod - Impossibilité de créer une Lead request - TECH_Actor2Id__c
-- 08-JUL-2021  NBI   1.4      W-0992: Third Party Management
-- 15-JUN-2021  MBE   1.5      W-0894 - ODS - TECH_SentByUser__c seems empty after a modification of a lead request
-- 24-JUL-2021  MBE   1.6      SOQL Injection for getReinsurer() + getBroker()
-- 27-AUG-2021  MBE   1.7      Remove unused value for mapResult
--------------------------------------------------------------------------------------
**************************************************************************************/

    /**
    * @description Method to retreieve Quote Requests from a Program
    * @param Id programId, Id treatyId, Id reinsurerId, Id brokerId, String reinsurerStatus
    * @return List<Request__c>
     * RRA - ticket 585 - 06032023
    */
    @AuraEnabled
    public static  Map<String, Object> getQuoteRequests(Id programId, Id treatyId, Id reinsurerId, Id brokerId, String reinsurerStatus){ //, List<Id> lstSelectedIdTreaty, List<Id> lstSelectedIdSection
        Map<String, Object> mapResults = new Map<String, Object>();
        Map<String, Id> mapRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectRequest});
        List<Request__c> lstQuoteRequests = new List<Request__c>();
        List<Program__c> lstProgram = new List<Program__c>();
        String recordTypeId = mapRecTypeId.get(AP_Constant.reqRTQuote);
        List<Request__c> lstQuoteRequestsToDisplay = new List<Request__c>();
        Boolean isDeactivatedProg = false;   //RRA - ticket 585 - 07032023
        //List<String> lstStatusQuoteSecTreaty = new List<String>();//RRA - ticket 585 - 15032023
        //RRA - ticket 1421 - 01092023
        String query = 'SELECT Id, Name, Layer__c, TECH_BrokerReinsurer__c, Section__r.QuoteType__c, Section__r.SectionNumber__c, Section__r.TECH_TypeofTreaty__c, TECH_Layer__c, TreatyReference__c, Treaty__c, Section__c, TECH_TreatyName__c, TECH_SectionName__c, Broker__c, Reinsurer__c, toLabel(QuoteType__c), TECH_LatestVersion__c, Program__r.isBtnActivatedDeactivated__c, Program__c, Treaty__r.Status__c, Section__r.Status__c ' //RRA - ticket 585 16032023
                    + ', toLabel(Quote__c), WrittenShareResponse__c, ReinsurerStatus__c, ResponseDate__c, LastSentDate__c, ExpectedResponseDate__c, TECH_BrokerName__c, TECH_ReinsurerName__c '
                    + ', FixedRate__c, MinRate__c, MaxRate__c, ProvisionalRate__c, FlatPremium__c, MDP__c, FixedCommission__c, MinVarCommission__c, VersionMajor__c, LastVersionSent__c, LastVersionAnswered__c, OriginalRequest__c '
                    + ', MaxVarCommission__c, ProvisionalCommission__c, PerHeadPremium__c, MinPerHeadAmount__c, MaxPerHeadAmount__c, ProvisionalPerHeadPremium__c, Program__r.TECH_ShowClosePreviousPhaseBtn__c'
                    + ', EstimatedReinsurancePremium__c, EstimatedInsurancePremium__c, RecordTypeId, Utility_Icon_Attachment__c, Utility_Icon_Comment__c, UtilityIconDate__c, Section__r.Sort_SectionNumber__c ' // RRA - tickets 939 and 1541 - 05072023
                    + ' FROM Request__c '
                    + ' WHERE Program__c = :programId'
                    + ' AND RecordTypeId = :recordTypeId'
                    + ' AND Program__c != NULL';

        if (treatyId!=null)
            query = query + ' AND Treaty__c = :treatyId ';
        if (reinsurerId!=null)
            query = query + ' AND Reinsurer__c = :reinsurerId';
        if (brokerId!=null)
            query = query + ' AND Broker__c = :brokerId';
        if (reinsurerStatus!=null)
            query = query + ' AND ReinsurerStatus__c = :reinsurerStatus ';
        
        query = query + ' ORDER BY TECH_Layer__c, TECH_TreatyName__c, Section__r.Sort_SectionNumber__c, TECH_ReinsurerName__c, TECH_BrokerName__c'; //RRA - ticket 1571 - 09102023

        lstQuoteRequests = Database.query(query);

        for(Request__c quoteRequest : lstQuoteRequests){
            if(quoteRequest.ReinsurerStatus__c == 'Setup'
                    || (quoteRequest.ReinsurerStatus__c != 'Setup' && quoteRequest.LastVersionSent__c == true && quoteRequest.LastVersionAnswered__c == true)){
                lstQuoteRequestsToDisplay.add(quoteRequest);
            }
        }

        //RRA - ticket 585 - 07032023
        for (Program__c prog : [SELECT Id, isBtnActivatedDeactivated__c FROM Program__c WHERE Id=:programId]){
            if (prog.isBtnActivatedDeactivated__c){
                isDeactivatedProg = true;
            }
        }

        mapResults.put('isDeactivatedProg', isDeactivatedProg);//RRA - ticket 585 - 07032023
        mapResults.put('lstQuoteRequestsToDisplay', lstQuoteRequestsToDisplay);
        return mapResults;
    }

    /**
    * @description Method to retrieve Treaty(ies) from a Program
    * @param Id programId
    * @return List<OptionWrapper>
    */
    @AuraEnabled(Cacheable = true)
    public static List<OptionWrapper> getTreaties(Id programId ){
        List<OptionWrapper> lstTreaties = new List<OptionWrapper>();
        Set<Id> setTreatyId = new Set<Id>();
        Set<Id> setAvailableTreatyIdInSection = new Set<Id>();

        for(Treaty__c treaty : [SELECT Id, Name FROM Treaty__c
                                WHERE Program__c = :programId
                                AND Status__c = :AP_Constant.statusActive
                                ORDER BY Name]){
            setTreatyId.add(treaty.Id);
        }

        //RRA - 1524 - 24052023
        for(Section__c section : [SELECT Id, Name, Treaty__c, Treaty__r.Layer__c, TECH_TreatyName__c FROM Section__c WHERE Treaty__c IN :setTreatyId AND Status__c = :AP_Constant.statusActive]){
            if(!setAvailableTreatyIdInSection.contains(section.Treaty__c)){
                setAvailableTreatyIdInSection.add(section.Treaty__c);
                lstTreaties.add(new OptionWrapper(section.TECH_TreatyName__c, section.Treaty__c, section.Treaty__r.Layer__c, section.Id));//RRA - ticket 1524 - 24052023 and RRA - ticket 1571 - 15092023
            }
        }
        //RRA - ticket 1524 - 24052023
        lstTreaties.sort();

        return lstTreaties;
    }

    /**
    * @description Method to retrieve Brokers
    * @param null
    * @return List<OptionWrapper>
    */
    @AuraEnabled(Cacheable = true)
    public static List<OptionWrapper> getAccountBroker(){
        Map<String, Id> mapRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectAcc});
        List<OptionWrapper> lstAccountBroker = new List<OptionWrapper>();

        for(Account account : [SELECT Id, Name FROM Account WHERE RecordTypeId = :mapRecTypeId.get(AP_Constant.accRTBroker) AND IsActive__c= TRUE]){
            lstAccountBroker.add(new OptionWrapper(account.Name, account.Id, null, null));   //RRA - ticket 1524 - 24052023
        }

        return lstAccountBroker;
    }

    /**
    * @description Method to retrieve Reinsurer(s)
    * @param String ObjectName, String fieldName, String value, List<String> selectedRecId
    * @return List<SObjectResult>
    */
    @AuraEnabled(Cacheable=true)
    public static List<SObjectResult> getReinsurer(String ObjectName, String fieldName, String value, List<String> selectedRecId) {
        List<SObjectResult> sObjectResultList = new List<SObjectResult>();
        Map<String, Id> mapRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectAcc});
        String recordTypeIdReinsurer = mapRecTypeId.get(AP_Constant.accRTReinsurer);

        if(selectedRecId == null) {
            selectedRecId = new List<String>();
        }

        if(String.isNotEmpty(value)) {
            String strValue = '%' + value.trim() + '%';
            String query = 'Select Id, Name from Account where Name LIKE :strValue and ID NOT IN: selectedRecId and RecordTypeId = :recordTypeIdReinsurer AND IsActive__c = TRUE AND IsRiskCarrier__c = true';

            // String query = 'Select Id,'+fieldName+' FROM '+ObjectName+' WHERE '+fieldName+' LIKE \'%' + value.trim() + '%\' and ID NOT IN: selectedRecId and RecordTypeId = :recordTypeIdReinsurer AND IsActive__c = TRUE AND IsRiskCarrier__c = true';
            for(SObject so : Database.query(query)) {
                String fieldvalue = (String)so.get(fieldName);
                sObjectResultList.add(new SObjectResult(fieldvalue, so.Id));
            }
        }

        return sObjectResultList;
    }

    /**
    * @description Method to retrieve Broker(s) in lookup field
    * @param String ObjectName, String fieldName, String value, List<String> selectedRecId
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
            String strValue = '%' + value.trim() + '%';
            String query = 'Select Id, Name from Account where Name LIKE :strValue and ID NOT IN: selectedRecId AND IsActive__c = TRUE and RecordTypeId = :recordTypeIdBroker';

            // String query = 'Select Id,'+fieldName+' FROM '+ObjectName+' WHERE '+fieldName+' LIKE \'%' + value.trim() + '%\' and ID NOT IN: selectedRecId AND IsActive__c = TRUE and RecordTypeId = :recordTypeIdBroker';
            for(SObject so : Database.query(query)) {
                String fieldvalue = (String)so.get(fieldName);
                sObjectResultList.add(new SObjectResult(fieldvalue, so.Id));
            }
        }

        return sObjectResultList;
    }

    /**
    * @description Method to save Reinsurer
    * @param List<Request__c> lstRequest, List<Id> lstTreaty
    * @return Map<String, Object> 
    */
    @AuraEnabled
    public static Map<String, Object> saveReinsurer(List<Request__c> lstRequest, List<Id> lstTreaty) {
        Map<String, Object> mapResults = new Map<String, Object>();
        Map<String, Id> mapRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectRequest});
        Map<Id, List<Id>> mapSectionsByTreatyId = new Map<Id, List<Id>>();
        Set<Id> lstRequestId = new Set<Id>();
        Set<Id> lstAllSectionId = new Set<Id>();

        try {
            for(Section__c section : [SELECT Id, Treaty__c FROM Section__c WHERE Treaty__c IN :lstTreaty AND Status__c = :AP_Constant.statusActive]){
                lstAllSectionId.add(section.Id);
                List<Id> lstNewSectionId = new List<Id>();
                if(mapSectionsByTreatyId.containsKey(section.Treaty__c)){
                    lstNewSectionId = mapSectionsByTreatyId.get(section.Treaty__c);
                    lstNewSectionId.add(section.Id);
                    mapSectionsByTreatyId.put(section.Treaty__c, lstNewSectionId);
                }
                else{
                    lstNewSectionId.add(section.Id);
                    mapSectionsByTreatyId.put(section.Treaty__c, lstNewSectionId);
                }
            }

            List<Request__c> lstExistingRequestForSection = [SELECT Id, TECH_LatestVersion__c, Treaty__c, Broker__c, Reinsurer__c FROM Request__c WHERE Section__c IN :lstAllSectionId AND TECH_LatestVersion__c = TRUE];
            for(Request__c reqExisting : lstExistingRequestForSection){
                for(Request__c reqNewToInsert : lstRequest){
                    if(reqExisting.Treaty__c == reqNewToInsert.Treaty__c && reqExisting.Broker__c == reqNewToInsert.Broker__c && reqExisting.Reinsurer__c == reqNewToInsert.Reinsurer__c){
                        reqExisting.TECH_LatestVersion__c = false;
                    }
                }
            }

            if(lstExistingRequestForSection.size() > 0){
                update lstExistingRequestForSection;
            }


            String userId = UserInfo.getUserId();
            User activeUser = [Select Email From User where Id = : userId limit 1];
            String userEmail = activeUser.Email;

            Map<String, Set<Id>> mapBrokerReinsToSections = new Map<String, Set<Id>>();
            for(Request__c quoteRequest : [SELECT Id
                                                  ,Section__c
                                                  ,Broker__c
                                                  ,Reinsurer__c
                                           FROM Request__c
                                           WHERE Program__c = :lstRequest[0].Program__c
                                           AND RecordTypeId =:mapRecTypeId.get(AP_Constant.reqRTQuote)]){

                String key = quoteRequest.Broker__c + '-' + quoteRequest.Reinsurer__c;
                Set <Id> setSectionIds = new Set<Id>();
                if(mapBrokerReinsToSections.containsKey(key)){
                    setSectionIds = mapBrokerReinsToSections.get(key);
                    setSectionIds.add(quoteRequest.Section__c);
                    mapBrokerReinsToSections.put(key, setSectionIds);
                }
                else{
                    setSectionIds.add(quoteRequest.Section__c);
                    mapBrokerReinsToSections.put(key, setSectionIds);
                }
            }

            List<Request__c> lstRequestsToInsert = new List<Request__c>();
            for(Request__c request : lstRequest){
                if(mapSectionsByTreatyId.containsKey(request.Treaty__c)){
                    for(Id sectionId : mapSectionsByTreatyId.get(request.Treaty__c)){
                        String key = request.Broker__c + '-' + request.Reinsurer__c;
                        if(mapBrokerReinsToSections.containsKey(key)){
                            Set <Id> setSectionIds = mapBrokerReinsToSections.get(key);
                            if(!setSectionIds.contains(sectionId)){
                                Request__c newRequest = new Request__c();
                                newRequest.QuoteType__c = request.QuoteType__c;
                                newRequest.TECH_PhaseType__c = request.TECH_PhaseType__c;
                                newRequest.Reinsurer__c = request.Reinsurer__c;
                                newRequest.Broker__c = request.Broker__c;
                                newRequest.Treaty__c = request.Treaty__c;
                                newRequest.Program__c = request.Program__c;
                                newRequest.RecordTypeId = mapRecTypeId.get(AP_Constant.reqRTQuote);
                                newRequest.Section__c = sectionId;
                                newRequest.TECH_LatestVersion__c = true;
                                newRequest.ReinsurerStatus__c = AP_Constant.statusSetup;
                                newRequest.TECH_OwnerEmail__c = userEmail;
                                newRequest.TECH_Actor2Id__c = null;                         
                                lstRequestsToInsert.add(newRequest);
                            }
                        }
                        else{
                            Request__c newRequest = new Request__c();
                            newRequest.QuoteType__c = request.QuoteType__c;
                            newRequest.TECH_PhaseType__c = request.TECH_PhaseType__c;
                            newRequest.Reinsurer__c = request.Reinsurer__c;
                            newRequest.Broker__c = request.Broker__c;
                            newRequest.Treaty__c = request.Treaty__c;
                            newRequest.Program__c = request.Program__c;
                            newRequest.RecordTypeId = mapRecTypeId.get(AP_Constant.reqRTQuote);
                            newRequest.Section__c = sectionId;
                            newRequest.TECH_LatestVersion__c = true;
                            newRequest.ReinsurerStatus__c = AP_Constant.statusSetup;
                            newRequest.TECH_OwnerEmail__c = userEmail;
                            newRequest.TECH_Actor2Id__c = null;
                            lstRequestsToInsert.add(newRequest);
                        }
                    }
                }
            }
            if (lstRequestsToInsert.size() > 0) {
                insert lstRequestsToInsert;
            }

            for(Request__c requestInsert : lstRequestsToInsert){
                lstRequestId.add(requestInsert.Id);
            }

            List<Request__c> lstRequestDetails = [SELECT Id, Name, Layer__c, TECH_Layer__c,TreatyReference__c, Treaty__c, Section__c
                                                        , TECH_TreatyName__c, TECH_SectionName__c, Broker__c, Reinsurer__c, toLabel(QuoteType__c)
                                                        , toLabel(Quote__c), WrittenShare__c, ReinsurerStatus__c, ResponseDate__c, LastSentDate__c
                                                        , ExpectedResponseDate__c, TECH_BrokerName__c, TECH_ReinsurerName__c
                                                        , Section__r.SectionNumber__c
                                                  FROM Request__c
                                                  WHERE Id IN :lstRequestId
            ];

            mapResults.put('Success', 'Success');
            mapResults.put('lstRequestDetails', lstRequestDetails);
        }
        catch (Exception ex) {
            mapResults.put('Error', ex.getMessage());
        }
        return mapResults;
    }
    
    /**
     * RRA - ticket 1371 01082023
    * @description Method to load previous year Requests
    * @param Id programId, Id pcc, String uwy
    * @return Map<String, Object> 
    */
    @AuraEnabled (Cacheable=true)
    public static Map<String, Object> loadCurrentYearQuoteRequest(Id programId){
        Map<String, Id> mapRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectRequest});
        Map<String, Object> mapResults = new Map<String, Object>();
        String recordTypeQuoteId = mapRecTypeId.get(AP_Constant.reqRTQuote);
        List<Request__c> lstRequest = new List<Request__c>();
        List<Request__c> lstActiveQuoteRequest = new List<Request__c>();
        String pcc;
        String uwy;
        
        //RRA - ticket 1571 - Add Section__c on SOQL 18092023
        String query = 'SELECT Id, Name, Program__r.PrincipalCedingCompany__c, Program__r.UwYear__c, Treaty__c, Section__c, TECH_TreatyName__c, Broker__c, Reinsurer__c, QuoteType__c, TECH_BrokerName__c, TECH_ReinsurerName__c, Program__c '
                    + ', Broker__r.IsActive__c, Reinsurer__r.IsActive__c '
                    + ' FROM Request__c '
                    + ' WHERE Program__c = :programId'
                    + ' AND RecordTypeId = :recordTypeQuoteId';
                    
        lstRequest = Database.query(query);

        for(Request__c request : lstRequest){
            if(request.Broker__c != null && (request.Broker__r.IsActive__c == TRUE && request.Reinsurer__r.IsActive__c == TRUE)){
                lstActiveQuoteRequest.add(request);
            }
            else if(request.Broker__c == null && request.Reinsurer__r.IsActive__c == TRUE){
                lstActiveQuoteRequest.add(request);
            }
            pcc = request.Program__r.PrincipalCedingCompany__c;
            uwy = request.Program__r.UwYear__c; 
        }

        System.debug('lstActiveQuoteRequest == ' + lstActiveQuoteRequest);
        mapResults.put('lstRequest', lstActiveQuoteRequest);
        mapResults.put('pcc', pcc);
        mapResults.put('uwy', uwy);
        return mapResults;
    }

    /**
    * @description Method to load previous year Requests
    * @param Id programId, String selectedTreaty
    * @return Map<String, Object> 
    */
    @AuraEnabled(Cacheable = true)
    public static Map<String, Object> loadPreviousYearQuoteRequest(Id programId, String selectedTreaty){ // RRAà voir pour les nouveaux ickets
        Map<String, Id> mapRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectRequest});
        Map<Id, Treaty__c> mapNewTreatyByOldTreatyId = new Map<Id, Treaty__c>();
        Map<String, Object> mapResults = new Map<String, Object>();
        Set<Id> setOldTreatyId = new Set<Id>();
        String recordTypeQuoteId = mapRecTypeId.get(AP_Constant.reqRTQuote);
        List<Request__c> lstRequest = new List<Request__c>();
        List<Request__c> lstActiveQuoteRequest = new List<Request__c>();

        Program__c renewedProgram = [SELECT Id, RenewedFromProgram__c FROM Program__c WHERE Id = :programId];
        Id renewedFromProgramId = renewedProgram.RenewedFromProgram__c;

        //RRA - ticket 1571 - 15092023 add Section__c field on soql
        String query = 'SELECT Id, Name, Treaty__c, TECH_TreatyName__c, Broker__c, Reinsurer__c, Section__c, QuoteType__c, TECH_BrokerName__c, TECH_ReinsurerName__c, Program__c '
                    + ', Broker__r.IsActive__c, Reinsurer__r.IsActive__c '
                    + ' FROM Request__c '
                    + ' WHERE Program__c = :renewedFromProgramId'
                    + ' AND RecordTypeId = :recordTypeQuoteId';
                    
        lstRequest = Database.query(query);

        for(Request__c request : lstRequest){
            if(request.Broker__c != null && (request.Broker__r.IsActive__c == TRUE && request.Reinsurer__r.IsActive__c == TRUE)){
                lstActiveQuoteRequest.add(request);
            }
            else if(request.Broker__c == null && request.Reinsurer__r.IsActive__c == TRUE){
                lstActiveQuoteRequest.add(request);
            }
        }

        for(Request__c quoteReq : lstActiveQuoteRequest){
            setOldTreatyId.add(quoteReq.Treaty__c);
        }

        for(Treaty__c treaty : [SELECT Id, Name, TECH_OldTreatyId__c FROM Treaty__c WHERE TECH_OldTreatyId__c IN :setOldTreatyId]){
            if(!mapNewTreatyByOldTreatyId.containsKey(treaty.TECH_OldTreatyId__c)){
                mapNewTreatyByOldTreatyId.put(treaty.TECH_OldTreatyId__c, treaty);
            }
        }

        mapResults.put('lstRequest', lstActiveQuoteRequest);
        return mapResults;
    }

    /**
    * @description Method to check if Program is Renewed
    * @param Id programId
    * @return Boolean
    */
    @AuraEnabled(Cacheable = true)
    public static Boolean isProgramRenewed(Id programId){
        Program__c renewedProgram = [SELECT Id, RenewedFromProgram__c, TypeOfRenew__c FROM Program__c WHERE Id = :programId];
        Id renewedFromProgramId = renewedProgram.RenewedFromProgram__c;
        Boolean isProgramRenewed = false;

        if(renewedFromProgramId != null){
            if(renewedProgram.TypeOfRenew__c == 'Standard Renew' || renewedProgram.TypeOfRenew__c == 'LTA/TR Renegotiation') {
                //program is renewed Standard/Renegotiation
                isProgramRenewed = true;
            }
        }

        return isProgramRenewed;
    }

    /**
    * @description Method to change Request Type
    * @param List<SObject> lstRecords
    * @return Map<String, Object>
    */
    @AuraEnabled
    public static Map<String, Object> toggleRequestType(List<SObject> lstRecords){
        Map<String, Object> mapResults = new Map<String, Object>();
        try{
            Map<Id, String> mapQuoteTypeByOriginalRequestId = new Map<Id, String>();

            for(SObject record: lstRecords) {
                String strReqType = (String) record.get('QuoteType__c');
                if(strReqType == '1'){
                    record.put('QuoteType__c', '2');
                }
                else if(strReqType == '2'){
                    record.put('QuoteType__c', '1');
                }

                if(record.get('OriginalRequest__c') == null){
                    mapQuoteTypeByOriginalRequestId.put((Id) record.get('Id'), (String) record.get('QuoteType__c'));
                }
                else{
                    mapQuoteTypeByOriginalRequestId.put((Id) record.get('OriginalRequest__c'), (String) record.get('QuoteType__c'));
                }
            }

            List<Request__c> lstAllRequestVersion = [SELECT Id, Name, OriginalRequest__c, QuoteType__c FROM Request__c WHERE Id IN :mapQuoteTypeByOriginalRequestId.keySet() OR OriginalRequest__c IN :mapQuoteTypeByOriginalRequestId.keySet()];

            for(Request__c request : lstAllRequestVersion){
                if(request.OriginalRequest__c == null){
                    request.QuoteType__c = mapQuoteTypeByOriginalRequestId.get(request.Id);
                }
                else{
                    request.QuoteType__c = mapQuoteTypeByOriginalRequestId.get(request.OriginalRequest__c);
                }
            }

            if(lstRecords.size() > 0){
                update lstRecords;
            }

            if(lstAllRequestVersion.size() > 0){
                update lstAllRequestVersion;
            }

            mapResults.put('Success', 'Records successfully Updated.');
        }
        catch(Exception ex){
            mapResults.put('Error', ex.getMessage());
        }
        return mapResults;
    }

    /**
    * @description Method to get UW year of original Program in case of Renew
    * @param Id programId
    * @return String
    */
    @AuraEnabled
    public static String getUWYearForOriginalProgram(Id programId){
        Program__c renewedProgram = [SELECT Id, RenewedFromProgram__c, TypeOfRenew__c FROM Program__c WHERE Id = :programId];
        Id renewedFromProgramId = renewedProgram.RenewedFromProgram__c;
        String uwYearOriginalProgram = null;

        if(renewedFromProgramId != null){
            //program is renewed
            Program__c originalProgram = [SELECT Id, UwYear__c FROM Program__c WHERE Id = :renewedFromProgramId];
            uwYearOriginalProgram = originalProgram.UwYear__c;
        }
        return uwYearOriginalProgram;
    }

     //RRA - ticket 1524 - 24052023 - Implement Interface Comparable and Add method compareTo to sort the lstTreaties
     public class OptionWrapper implements Comparable{
        @AuraEnabled
        public String label {get; set;}
        @AuraEnabled
        public String value {get; set;}
        @AuraEnabled
        public Decimal layer {get; set;}
        @AuraEnabled
        public Id idSec {get; set;}//RRA - ticket 1571 - 15092023

        public OptionWrapper(String label, String value, Decimal layer, Id idSec) {//RRA - ticket 1571 - 15092023
            this.label = label;
            this.value = value;
            this.layer = layer;
            this.idSec = idSec;//RRA - ticket 1571 - 15092023
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

    public class SObjectResult{
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
}