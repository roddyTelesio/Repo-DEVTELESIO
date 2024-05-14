public with sharing class LWC01_Sections {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Controller for Lightning Web Component lwc01Sections
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 16-OCT-2019  MBE   1.0      Initial version
-- 21-DEC-2020  NBI   1.1      W-0806: Sections retenues et rajout de sections retenues
-- 08-JUL-2021  NBI   1.2      W-0992: Third Party Management
--------------------------------------------------------------------------------------
**************************************************************************************/

      /**
    * @description Method to get retrieve Sections for selected Treaty(ies)
    * @param List<Id> lstSelectedTreaties
    * @return List<Section__c>
    */
    @AuraEnabled
    public static List<Section__c> getSections(List<Id> lstSelectedTreaties){
        List<String> lstSectionFields = AP_Constant.getCreatableFieldsByObjName(AP_Constant.sObjectSection);

        for(Integer j = 0; j < lstSectionFields.size(); j++){
            if(lstSectionFields[j] == 'Status__c'){
                lstSectionFields.remove(j);
            }
            if(lstSectionFields[j] == 'Currency__c'){
                lstSectionFields.remove(j);
            }
        }
        String strSectionFields = String.join(lstSectionFields , ', ');
        //RRA - ticket 1275 add formulas fields fieldLimit__c and  fieldRetention__c in soql
        //RRA - ticket 1533 - 12062023
        String querySection = 'select Id, fieldLimit__c, fieldRetention__c, Treaty__c, ID__c, Treaty__r.Layer__c, Treaty__r.IsPooled__c, TECH_ProgramName__c, TECH_TreatyName__c, TECH_RelatedSectionNumber__c, Left_Section_Number__c, Sort_SectionNumber__c, toLabel(Status__c), toLabel(Currency__c), RelatedSection__r.SectionNumber__c, Program__r.UwYear__c, Program__r.Macro_L_O_B__c, ' 
                + strSectionFields
                + ' from Section__c where (Treaty__c IN :lstSelectedTreaties) '
                + ' order by Treaty__r.Layer__c, Sort_SectionNumber__c, Name' ;  // RRA - ticket 1540 - 09062023
        List<Section__c> lstSections = Database.query(querySection);

        return lstSections;
    }

    /**
    * @description Method to get retrieve Treaties from Lead Request
    * @param List<Id> lstProgramId
    * @return List<Id>
    */
    @AuraEnabled
    public static List<Id> getTreatiesForExistedLeadRequest(List<Id> lstProgramId){
        Map<String, Id> mapRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectRequest});
        String recordTypeId = mapRecTypeId.get(AP_Constant.reqRTLead);
        Set<Id> setTreatiesId = new Set<Id>();

        for(Request__c leadRequest:  [SELECT Id, Treaty__c, Treaty__r.Name
                                            FROM Request__c
                                            WHERE Program__c IN :lstProgramId
                                            AND RecordTypeId = :recordTypeId
                                            AND Program__c != NULL
                                            AND Reinsurer__c != NULL]){
            setTreatiesId.add(leadRequest.Treaty__c);
        }

        List<Id> lstTreatiesId = new List<Id>(setTreatiesId);

        return lstTreatiesId;
    }

    /**
    * @description Method to get Covered Ceding Companies for Section
    * @param String selectedSectionId
    * @return List<CoveredCedingCompany__c>
    */
    @AuraEnabled(Cacheable = true)
    public static List<CoveredCedingCompany__c> getCoveredCedingCompanies(String selectedSectionId) {
        return [
                SELECT Id, Name, Account__r.Name, EPI__c, AllocationKey__c
                FROM CoveredCedingCompany__c
                WHERE Section__c = :selectedSectionId
                AND SectionIsSelected__c = TRUE
        ];
    }

    /**
    * @description Method to get Section Number
    * @param null
    * @return String
    */
    @AuraEnabled(Cacheable = true)
    public static String getSectionNumber() {
        Decimal sectionNumber;
        List<Decimal> lstSectionNumber = new List<Decimal>();

        for (Section__c section : [SELECT Id, SectionNumber__c FROM Section__c ORDER BY SectionNumber__c DESC]) {
            lstSectionNumber.add(Decimal.valueOf(section.SectionNumber__c));
        }
        lstSectionNumber.sort();

        if(lstSectionNumber.size() > 0) {
            Integer sectionNumInt = (Integer) lstSectionNumber[lstSectionNumber.size() - 1];
            sectionNumber = (Decimal) sectionNumInt + 1.1;
        }
        else {
            sectionNumber = 1.1;
        }

        String sectionNumberToString = String.valueOf(sectionNumber);
        return sectionNumberToString;
    }

    /**
    * @description Method to retain Section to Lead
    * @param List<Id> lstSectionId, List<Id> lstSelectedTreaties
    * @return Map<String, Object>
    */
    @AuraEnabled
    public static Map<String, Object> saveRetainedToLeadSection(List<Id> lstSectionId, List<Id> lstSelectedTreaties){
        Map<String, Object> mapResults = new Map<String, Object>();
        
        try{
            List<Section__c> lstSections = [SELECT Id, Retained_to_lead__c, fieldLimit__c, fieldRetention__c, Status__c, Program__c, Program__r.TECH_StageName__c, Treaty__c FROM Section__c WHERE Id IN :lstSectionId];
            List<Program__c> lstPrograms = new List<Program__c>();
            Set<Id> setProgramId = new Set<Id>();
            Set<Id> setTreatyId = new Set<Id>();

            for(Section__c section : lstSections){
                section.Status__c = '1';
                setTreatyId.add(section.Treaty__c);
            }

            for(Section__c section : lstSections){
                section.Retained_to_lead__c = true;
                if(!setProgramId.contains(section.Program__c)){
                    setProgramId.add(section.Program__c);
                    Program__c program = new Program__c();
                    program.Id = section.Program__c;
                    program.TECH_StageName__c = 'Lead';
                    lstPrograms.add(program);
                }
            }

            Set<Id> setSections = new Set<Id>();
            Set<Id> setParentSections = new Set<Id>();

            // Il faut que les sections qui ne sont pas retenues au sein de ma famille de section soit mis en statut "cancelled".
            // Par exemple si je retiens ma 1.1 alors ma 1.2, 1.3 et 1.4 doivent être en statut "cancelled" lorsque je fais save et que je ferme ma pop-up.
            for(Section__c sectionOption : [SELECT Id, Option__c, RelatedSection__c FROM Section__c WHERE Id IN :lstSectionId]){
                //1 = is an option
                if(sectionOption.Option__c == '1'){
                    setParentSections.add(sectionOption.RelatedSection__c);
                }
                else if(sectionOption.Option__c == '2'){
                //2 = is a section
                    setSections.add(sectionOption.Id);
                }
            }

            //get list of related to update to Cancelled
            List<Section__c> lstRelatedSectOpt = [SELECT Id, Status__c, fieldLimit__c, fieldRetention__c FROM Section__c WHERE Id NOT IN :lstSectionId AND (Id IN :setParentSections OR RelatedSection__c IN :setParentSections OR RelatedSection__c IN :setSections)];
            for(Section__c relatedSectOpt : lstRelatedSectOpt){
                relatedSectOpt.Retained_to_lead__c = false;
                relatedSectOpt.Status__c = '2';
            }

            if(lstRelatedSectOpt.size() > 0){
                update lstRelatedSectOpt;
            }

            if(lstPrograms.size() > 0){
                update lstPrograms;
            }

            if(lstSections.size() > 0){
                update lstSections;
            }

            List<Section__c> lstUpdSections = getSections(lstSelectedTreaties);

            mapResults.put('lstSections', lstUpdSections);
            mapResults.put('Success', 'Success');
        }
        catch (Exception ex) {
            mapResults.put('Error', ex.getMessage());
        }
        return mapResults;
    }

    /**
    * @description Method to get Treaty details
    * @param Id treatyId
    * @return Treaty__c
    */
    @AuraEnabled
    public static Treaty__c getSelectedTreatyDetail(Id treatyId){
        Treaty__c treaty = [SELECT Id, Name, Program__r.TypeOfRenew__c, Program__r.RenewedFromProgram__c FROM Treaty__c WHERE Id = :treatyId];
        return treaty;
    }

    /**
    * @description Method to check Active PCC
    * @param Id sectionId
    * @return Boolean
    */
    @AuraEnabled
    public static Boolean checkPCC(Id sectionId){
        Boolean pccActive = false;

        Section__c sect = [SELECT Id, Name, Program__r.PrincipalCedingCompany__r.IsActive__c FROM Section__c
        WHERE Id = :sectionId];

        if(sect != null) {
            pccActive = sect.Program__r.PrincipalCedingCompany__r.IsActive__c;
        }
        return pccActive;
    }

    /**
    * @description Method to check Active PCC
    * @param Id TreatyId
    * @return Boolean
    */
    @AuraEnabled
    public static Boolean checkCCC(Id sectionId){
        Boolean cccActive = true;
        Set<Boolean> setIsActive = new Set<Boolean>();

        for(CoveredCedingCompany__c ccc : [SELECT Id, Name, Account__r.IsActive__c FROM CoveredCedingCompany__c
        WHERE Section__c = :sectionId AND TreatyIsSelected__c = FALSE AND SectionIsSelected__c = TRUE]){
            setIsActive.add(ccc.Account__r.IsActive__c);
        }

        if(setIsActive.size() > 0){
            if(!setIsActive.contains(true)){
                cccActive = false;
            }
        }

        return cccActive;
    }

     /**
    * @description Method to check existing Quote or Lead Requests
    * @param Id sectionId
    * @return Boolean
    * RRA - ticket - 1347 24112022 => update from ticket - 1413 27012023
    */
    @AuraEnabled(cacheable=true)
    public static  Map<String, Object> checkStatusRequestQuoteLead(List<Id> lstSectionId, List<Id> lstTreatyId){
        Boolean isExist = false;
        Map<String, Object> mapResults = new Map<String, Object>();
        Map<String, Id> mapRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectRequest});
        String recordTypeLeadId = mapRecTypeId.get(AP_Constant.reqRTLead);
        String recordTypeQuoteId = mapRecTypeId.get(AP_Constant.reqRTQuote);
        Boolean isDeleteSection = false;
        Set<String> setKeyQuoteLead = new Set<String>();

        Set<String> setCombSetup = new Set<String>();
        Set<String> setCombSent = new Set<String>();
        Set<String> setCombSetupSent = new Set<String>();
        Set<String> setCombSetupAnswered = new Set<String>();
        Set<String> setCombSetupTimeout = new Set<String>();
        Set<String> setCombSentSetup = new Set<String>();
        Set<String> setCombAnsweredQuoteOnly = new Set<String>();
        Set<String> setCombAnsweredLeadOnly = new Set<String>();
        Set<String> setCombTimeout = new Set<String>();
        Set<String> setCombQuoteOnlyTimeout = new Set<String>();
        Set<String> setCombLeadOnlyTimeout = new Set<String>();
        Set<String> setCombLeadTimeout = new Set<String>();

        Set<String> setCombSentAnswered = new Set<String>();
        Set<String> setCombQuoteRefused = new Set<String>();
        Set<String> setCombSentTimeout = new Set<String>();
        Set<String> setCombAnsweredSetup = new Set<String>();
        Set<String> setCombAnsweredSent = new Set<String>();
        Set<String> setCombAnsweredAnswered = new Set<String>();
        Set<String> setCombAnsweredTimeout = new Set<String>();
        Set<String> setCombRefusedSetup = new Set<String>();
        Set<String> setCombRefusedSent = new Set<String>();
        Set<String> setCombRefusedAnswered = new Set<String>();
        Set<String> setCombRefusedTimeout = new Set<String>();
        Set<String> setQuoteRefused = new Set<String>();
        Set<String> setCombLeadRefused = new Set<String>();

        Set<String> setCombAnswered = new Set<String>();
        Set<String> setCombTimeoutSetup = new Set<String>();
        Set<String> setCombTimeoutSent = new Set<String>();
        Set<String> setCombTimeoutAnswered = new Set<String>();
        Set<String> setCombTimeoutTimeout = new Set<String>();
        map<Id, String> mapIdReqChildReinsStatusOrigNull = new map<Id, String> ();
        map<Id, String> mapIdReqChildReinsStatusOrigNotNull = new map<Id, String> ();

        Set<String> setCombQuoteSetup = new Set<String>();
        Set<String> setCombQuoteSent = new Set<String>();
        Set<String> setCombLeadSetup = new Set<String>();
        Set<String> setCombLeadSent = new Set<String>();

        Set<String> setQuoteLeadSetupSetup = new Set<string>{'Lead_Setup', 'Quote_Setup'};
        Set<String> setQuoteLeadSentSent = new Set<string>{'Lead_Sent', 'Quote_Sent'};
        Set<String> setQuoteLeadAnsweredAnswered = new Set<string>{'Lead_Answered', 'Quote_Answered'};
        Set<String> setQuoteLeadTimeoutTimeout = new Set<string>{'Lead_Timeout', 'Quote_Timout'};

        Set<String> setQuoteLeadSetupSent = new Set<string>{'Lead_Sent', 'Quote_Setup'};
        Set<String> setQuoteLeadSetupAnswered = new Set<string>{'Lead_Answered', 'Quote_Setup'};
        Set<String> setQuoteLeadSetupTimeout = new Set<string>{'Lead_Timeout', 'Quote_Setup'};
        Set<String> setQuoteLeadSentSetup= new Set<string>{'Lead_Setup', 'Quote_Sent'};
        Set<String> setQuoteLeadSentAnswered = new Set<string>{'Lead_Answered', 'Quote_Sent'};
        Set<String> setQuoteLeadSentTimeout = new Set<string>{'Lead_Timeout', 'Quote_Sent'};
        Set<String> setQuoteLeadAnsweredSetup = new Set<string>{'Lead_Setup', 'Quote_Answered'};
        Set<String> setQuoteLeadAnsweredSent = new Set<string>{'Lead_Sent','Quote_Answered'};
        Set<String> setQuoteLeadAnsweredTimeout = new Set<string>{'Lead_Timeout', 'Quote_Answered'};
        Set<String> setQuoteLeadAnswered = new Set<string>{'Quote_Answered'};
        Set<String> setQuoteLeadRefusedSetup = new Set<string>{'Lead_Setup','Quote_Refused'};
        Set<String> setQuoteLeadRefusedSent = new Set<string>{'Lead_Sent', 'Quote_Refused'};
        Set<String> setQuoteLeadRefusedAnswered = new Set<string>{'Lead_Answered', 'Quote_Refused'};
        Set<String> setQuoteLeadRefusedTimeout = new Set<string>{'Lead_Timeout', 'Quote_Refused'};
        Set<String> setQuoteLeadRefused = new Set<string>{'Quote_Refused'};
        Set<String> setQuoteLeadTimeoutSetup = new Set<string>{'Lead_Setup', 'Quote_Timeout'};
        Set<String> setQuoteLeadTimeoutSent = new Set<string>{'Lead_Sent', 'Quote_Timeout'};
        Set<String> setQuoteLeadTimeoutAnswered = new Set<string>{'Lead_Answered', 'Quote_Timeout'};
        Set<String> setQuoteLeadTimeout = new Set<string>{'Quote_Timeout'};
        Set<String> setQuoteLeadSetup = new Set<string>{'Quote_Setup'};
        Set<String> setQuoteLeadSent = new Set<string>{'Quote_Sent'};
        Set<String> setLeadAnswered = new Set<string>{'Lead_Answered'};
        Set<String> setLeadRefused = new Set<string>{'Lead_Refused'};
        Set<String> setLeadTimeout = new Set<string>{'Lead_Timeout'};
        Set<String> setLeadSetup = new Set<string>{'Lead_Setup'};
        Set<String> setLeadSent = new Set<string>{'Lead_Sent'};
        Set<string> setIdSectionOption = new Set<string>();
        String queryLeadRequestSelection = null;
        String queryRequest = null;
        List<LeadRequestSelection__c> lstLeadReqSelect = new List<LeadRequestSelection__c> ();
        List<Request__c> lstReq = new List<Request__c> ();
        
        try{

            System.debug('lstSectionId == ' + lstSectionId);
            System.debug('lstTreatyId == ' + lstTreatyId);

            if(lstSectionId != null && lstTreatyId == null){
                //Get Id's Section Option From related Section 
                for (Section__c sec : [SELECT Id, RelatedSection__c FROM Section__c WHERE RelatedSection__c IN:lstSectionId]){
                    if (sec.RelatedSection__c != null){
                        setIdSectionOption.add(sec.Id);
                    }
                }
            }
            queryLeadRequestSelection = 'SELECT Id, LeadRequestChild__c, LeadRequestParent__r.OriginalRequest__c, LeadRequestParent__r.ReinsurerStatus__c, LeadRequestParent__r.RecordType.Name, LeadRequestParent__r.RecordTypeId, LeadRequestChild__r.Section__c, LeadRequestChild__r.Treaty__c, LeadRequestParent__r.LastVersionSent__c, LeadRequestParent__r.LastVersionAnswered__c  FROM LeadRequestSelection__c ';

            queryRequest = 'SELECT Id, RecordTypeId, OriginalRequest__c, LastVersionSent__c, LastVersionAnswered__c, RecordType.Name, ReinsurerStatus__c, TECH_LeadType__c FROM Request__c';

            if ((lstSectionId != null || !lstSectionId.isEmpty()) && (lstTreatyId == null || lstTreatyId.isEmpty())){
                System.debug('ok section ');
                queryLeadRequestSelection = queryLeadRequestSelection + ' WHERE (LeadRequestChild__r.Section__c IN: lstSectionId OR LeadRequestChild__r.Section__c IN:setIdSectionOption)';
                queryRequest = queryRequest + ' WHERE (Section__c IN :lstSectionId OR Section__c IN:setIdSectionOption)';
                
            }else if ((lstTreatyId != null || !lstTreatyId.isEmpty()) && (lstSectionId == null || lstSectionId.isEmpty())){
                System.debug('ok treaty ');
                queryLeadRequestSelection = queryLeadRequestSelection + ' WHERE LeadRequestChild__r.Treaty__c IN: lstTreatyId';
                queryRequest = queryRequest + ' WHERE Treaty__c IN :lstTreatyId';
            }

            System.debug('queryLeadRequestSelection == ' + queryLeadRequestSelection);
            System.debug('queryRequest == ' + queryRequest);

            if (queryLeadRequestSelection != null){
                lstLeadReqSelect = Database.query(queryLeadRequestSelection);
            }

            if (queryRequest != null){
                lstReq = Database.query(queryRequest);
            }

            System.debug('lstLeadReqSelect == ' + lstLeadReqSelect);
            System.debug('lstReq == ' + lstReq);

            if (lstLeadReqSelect.size() > 0){
                for (LeadRequestSelection__c leadRequest : lstLeadReqSelect){

                    if (leadRequest.LeadRequestParent__r.OriginalRequest__c == null) {
                        mapIdReqChildReinsStatusOrigNull.put(leadRequest.LeadRequestChild__c, leadRequest.LeadRequestParent__r.ReinsurerStatus__c);
                    }else if (leadRequest.LeadRequestParent__r.OriginalRequest__c != null)
                    mapIdReqChildReinsStatusOrigNotNull.put(leadRequest.LeadRequestChild__c, leadRequest.LeadRequestParent__r.ReinsurerStatus__c);
                }
            }
            System.debug('mapIdReqChildReinsStatusOrigNull == ' + mapIdReqChildReinsStatusOrigNull);
            System.debug('mapIdReqChildReinsStatusOrigNotNull == ' + mapIdReqChildReinsStatusOrigNotNull);

            for(Request__c req : lstReq){

                if (req.OriginalRequest__c == null){
                    //  for Lead
                    if (req.RecordTypeId == recordTypeLeadId && mapIdReqChildReinsStatusOrigNull.get(req.Id) != null){
                        setKeyQuoteLead.add(req.RecordType.Name.replaceAll(' Request', '') + '_'+ mapIdReqChildReinsStatusOrigNull.get(req.Id));
                    //  for Quote
                    }else if (req.RecordTypeId == recordTypeQuoteId && req.ReinsurerStatus__c != null){
                        setKeyQuoteLead.add(req.RecordType.Name.replaceAll(' Request', '') + '_'+ req.ReinsurerStatus__c);
                    }
                }else if (req.OriginalRequest__c != null){
                    //  for Lead
                    if (req.RecordTypeId == recordTypeLeadId && mapIdReqChildReinsStatusOrigNotNull.get(req.Id)!= null ){
                        setKeyQuoteLead.add(req.RecordType.Name.replaceAll(' Request', '') + '_'+ mapIdReqChildReinsStatusOrigNotNull.get(req.Id));
                    //  for Quote
                    }else if (req.RecordTypeId == recordTypeQuoteId && req.ReinsurerStatus__c != null){
                        setKeyQuoteLead.add(req.RecordType.Name.replaceAll(' Request', '') + '_'+ req.ReinsurerStatus__c);
                    }
                }

                   /*//  for Lead
                    if (req.RecordTypeId == recordTypeLeadId){
                        setKeyQuoteLead.add(req.RecordType.Name.replaceAll(' Request', '') + '_'+ mapIdReqChildReinsStatus.get(req.Id));
                    //  for Quote
                    }else if (req.RecordTypeId == recordTypeQuoteId){
                        setKeyQuoteLead.add(req.RecordType.Name.replaceAll(' Request', '') + '_'+ req.ReinsurerStatus__c);
                    }*/

                    if (setKeyQuoteLead.equals(setQuoteLeadSetupSetup)){
                        setCombSetup = setQuoteLeadSetupSetup;
                    }else if (setKeyQuoteLead.equals(setQuoteLeadSentSent)){
                        setCombSent = setQuoteLeadSentSent;
                    }else if (setKeyQuoteLead.equals(setQuoteLeadAnsweredAnswered)){
                        setCombAnswered = setQuoteLeadAnsweredAnswered;
                    }else if (setKeyQuoteLead.equals(setQuoteLeadTimeoutTimeout)){
                        setCombTimeout = setQuoteLeadTimeoutTimeout;
                    }/*else if (setKeyQuoteLead.equals('Quote_Refused')){
                        setQuoteRefused.add('Quote_Refused');
                    
                    //Quote Setup
                    }*/else if (setKeyQuoteLead.equals(setQuoteLeadSetupSent)){
                        setCombSetupSent = setQuoteLeadSetupSent;
                    }else if (setKeyQuoteLead.equals(setQuoteLeadSetupAnswered)){
                        setCombSetupAnswered = setQuoteLeadSetupAnswered;
                    }else if (setKeyQuoteLead.equals(setQuoteLeadSetupTimeout)){
                        setCombSetupTimeout = setQuoteLeadSetupTimeout;
                    }else if (setKeyQuoteLead.equals(setQuoteLeadSetup)){
                        setCombQuoteSetup = setQuoteLeadSetup;
                    }else if (setKeyQuoteLead.equals(setLeadSetup)){
                        setCombLeadSetup = setLeadSetup;
                    }
                    
                    //Quote Sent
                    else if (setKeyQuoteLead.equals(setQuoteLeadSentSetup)){
                        setCombSentSetup = setQuoteLeadSentSetup;
                    }else if (setKeyQuoteLead.equals(setQuoteLeadSentAnswered)){
                        setCombSentAnswered = setQuoteLeadSentAnswered;
                    }else if (setKeyQuoteLead.equals(setQuoteLeadSentTimeout)){
                        setCombSentTimeout = setQuoteLeadSentTimeout;
                    }else if (setKeyQuoteLead.equals(setQuoteLeadSent)){
                        setCombQuoteSent = setQuoteLeadSent;
                    }else if (setKeyQuoteLead.equals(setLeadSent)){
                        setCombLeadSent = setLeadSent;
                    }

                    //Quote Answered
                    else if (setKeyQuoteLead.equals(setQuoteLeadAnsweredSetup)){
                        setCombAnsweredSetup = setQuoteLeadAnsweredSetup;
                    }else if (setKeyQuoteLead.equals(setQuoteLeadAnsweredSent)){
                        setCombAnsweredSent = setQuoteLeadAnsweredSent;
                    }else if (setKeyQuoteLead.equals(setQuoteLeadAnsweredAnswered)){
                        setCombAnsweredAnswered = setQuoteLeadAnsweredAnswered;
                    }else if (setKeyQuoteLead.equals(setQuoteLeadAnsweredTimeout)){
                        setCombAnsweredTimeout = setQuoteLeadAnsweredTimeout;
                    }else if (setKeyQuoteLead.equals(setQuoteLeadAnswered)){
                        setCombAnsweredQuoteOnly = setQuoteLeadAnswered;
                    }else if (setKeyQuoteLead.equals(setLeadAnswered)){
                        setCombAnsweredLeadOnly = setLeadAnswered;
                    }

                    //Quote Refused
                    else if (setKeyQuoteLead.equals(setQuoteLeadRefusedSetup)){
                        setCombRefusedSetup = setQuoteLeadRefusedSetup;
                    }else if (setKeyQuoteLead.equals(setQuoteLeadRefusedSent)){
                        setCombRefusedSent = setQuoteLeadRefusedSent;
                    }else if (setKeyQuoteLead.equals(setQuoteLeadRefusedAnswered)){
                        setCombRefusedAnswered = setQuoteLeadRefusedAnswered;
                    }else if (setKeyQuoteLead.equals(setQuoteLeadRefusedTimeout)){
                        setCombRefusedTimeout = setQuoteLeadRefusedTimeout;
                    }else if (setKeyQuoteLead.equals(setQuoteLeadRefused)){
                        setCombQuoteRefused = setQuoteLeadRefused;
                    }/*else if (setKeyQuoteLead.equals(leadRefused)){
                        combLeadRefused = leadRefused;
                    }*/

                    //Quote Timeout
                    else if (setKeyQuoteLead.equals(setQuoteLeadTimeoutSetup)){
                        setCombTimeoutSetup = setQuoteLeadTimeoutSetup;
                    }else if (setKeyQuoteLead.equals(setQuoteLeadTimeoutSent)){
                        setCombTimeoutSent = setQuoteLeadTimeoutSent;
                    }else if (setKeyQuoteLead.equals(setQuoteLeadTimeoutAnswered)){
                        setCombTimeoutAnswered = setQuoteLeadTimeoutAnswered;
                    }else if (setKeyQuoteLead.equals(setQuoteLeadTimeoutTimeout)){
                        setCombTimeoutTimeout = setQuoteLeadTimeoutTimeout;
                    }else if (setKeyQuoteLead.equals(setQuoteLeadTimeout)){
                        setCombQuoteOnlyTimeout = setQuoteLeadTimeout;
                    }else if (setKeyQuoteLead.equals(setLeadTimeout)){
                        setCombLeadOnlyTimeout = setLeadTimeout;
                    }
            }
      
                    System.debug('setKeyQuoteLead == ' + setKeyQuoteLead);
                    System.debug('setCombSetup == ' + setCombSetup);
                    System.debug('setCombSent == ' + setCombSent);
                    System.debug('setCombSetupSent == ' + setCombSetupSent);
                    System.debug('setCombSetupAnswered == ' + setCombSetupAnswered);
                    System.debug('setCombSetupTimeout == ' + setCombSetupTimeout);
                    System.debug('setCombSentSetup == ' + setCombSentSetup);
                    System.debug('setCombAnswered == ' + setCombAnswered);
                    System.debug('setCombTimeout == ' + setCombTimeout);
                    System.debug('setCombQuoteOnlyTimeout == ' + setCombQuoteOnlyTimeout);
                    System.debug('setCombSentAnswered == ' + setCombSentAnswered);
                    System.debug('setCombQuoteRefused == ' + setCombQuoteRefused);
                    System.debug('setCombSentTimeout == ' + setCombSentTimeout);
                    System.debug('setCombAnsweredSetup == ' + setCombAnsweredSetup);
                    System.debug('setCombAnsweredSent == ' + setCombAnsweredSent);
                    System.debug('setCombAnsweredAnswered == ' + setCombAnsweredAnswered);
                    System.debug('setCombAnsweredTimeout == ' + setCombAnsweredTimeout);
                    System.debug('setQuoteRefused == ' + setQuoteRefused);
                    System.debug('setCombRefusedSetup == ' + setCombRefusedSetup);
                    System.debug('setCombRefusedSent == ' + setCombRefusedSent);
                    System.debug('setCombRefusedAnswered == ' + setCombRefusedAnswered);
                    System.debug('setCombRefusedTimeout == ' + setCombRefusedTimeout);
                    System.debug('setCombTimeoutSetup == ' + setCombTimeoutSetup);
                    System.debug('setCombTimeoutSent == ' + setCombTimeoutSent);
                     System.debug('setCombTimeoutAnswered == ' + setCombTimeoutAnswered);
                     System.debug('setCombTimeoutTimeout == ' + setCombTimeoutTimeout);
                     System.debug('setCombAnsweredQuoteOnly == ' + setCombAnsweredQuoteOnly);
                     System.debug('setCombLeadSetup == ' + setCombLeadSetup);
                     System.debug('setCombLeadSent == ' + setCombLeadSent);
                     System.debug('setCombLeadAnswered == ' + setCombAnsweredLeadOnly);
                     System.debug('setCombLeadOnlyTimeout == ' + setCombLeadOnlyTimeout);
                     System.debug('setCombLeadRefused == ' + setCombLeadRefused);
                     System.debug('setCombQuoteSetup == ' + setCombQuoteSetup);
                     System.debug('setCombQuoteSent == ' + setCombQuoteSent);
                     System.debug('setCombQuoteRefused == ' + setCombQuoteRefused);
                    System.debug('setCombSentAnswered == ' + setCombSentAnswered);

                    mapResults.put('setCombSetup', setCombSetup);
                    mapResults.put('setCombSent', setCombSent);
                    mapResults.put('setCombSetupSent', setCombSetupSent);
                    mapResults.put('setCombSetupAnswered', setCombSetupAnswered);
                    mapResults.put('setCombSetupTimeout', setCombSetupTimeout);
                    mapResults.put('setCombSentSetup', setCombSentSetup);
                    mapResults.put('setCombAnswered', setCombAnswered);
                    mapResults.put('setCombTimeout', setCombTimeout);
                    mapResults.put('setCombQuoteOnlyTimeout', setCombQuoteOnlyTimeout);
                    mapResults.put('setCombSentAnswered', setCombSentAnswered);
                    mapResults.put('setCombQuoteRefused', setCombQuoteRefused);
                    mapResults.put('setCombSentTimeout', setCombSentTimeout);
                    mapResults.put('setCombAnsweredSetup', setCombAnsweredSetup);
                    mapResults.put('setCombAnsweredSent', setCombAnsweredSent);
                    mapResults.put('setCombAnsweredAnswered', setCombAnsweredAnswered);
                    mapResults.put('setCombAnsweredTimeout', setCombAnsweredTimeout); 
                    mapResults.put('setQuoteRefused', setQuoteRefused);
                    mapResults.put('setCombRefusedSetup', setCombRefusedSetup);
                    mapResults.put('setCombRefusedSent', setCombRefusedSent);
                    mapResults.put('setCombRefusedAnswered', setCombRefusedAnswered);
                    mapResults.put('setCombRefusedTimeout', setCombRefusedTimeout);
                    mapResults.put('setCombTimeoutSetup', setCombTimeoutSetup);
                    mapResults.put('setCombTimeoutSent', setCombTimeoutSent);
                    mapResults.put('setCombTimeoutAnswered', setCombTimeoutAnswered);
                    mapResults.put('setCombTimeoutTimeout', setCombTimeoutTimeout);
                    mapResults.put('setCombAnsweredQuoteOnly', setCombAnsweredQuoteOnly);
                    mapResults.put('setCombLeadSetup', setCombLeadSetup);
                    mapResults.put('setCombLeadSent', setCombLeadSent);
                    mapResults.put('setCombLeadAnswered', setCombAnsweredLeadOnly);
                    mapResults.put('setCombLeadOnlyTimeout', setCombLeadOnlyTimeout);
                    mapResults.put('setCombLeadRefused', setCombLeadRefused);
                    mapResults.put('setCombQuoteSetup', setCombQuoteSetup);
                    mapResults.put('setCombQuoteSent', setCombQuoteSent);
                    mapResults.put('setCombQuoteOnlyTimeout', setCombQuoteOnlyTimeout);
                    mapResults.put('setCombQuoteRefused', setCombQuoteRefused);
        }
        catch (Exception ex) {
            mapResults.put('Error', ex.getMessage());
        }

        return mapResults;
    }

    /**
     * RRA - ticket 585 - 22032023
    * @description Method to update retain to lead field on sections selected
    * @param List<Id> lstSelectedSections
    * @return List<Section__c>
    */
    @AuraEnabled
    public static String updateRetainToLeadDeactivation(List<Id> lstIds, String objectName){
        System.debug('lstIds == ' + lstIds);
        System.debug('objectName == ' + objectName);
        String message = null;
        List<Section__c> lstUpdateSecRetainToLead = new List<Section__c>();
        List<Section__c> lstSelectSecRetainToLead = new List<Section__c>();
        String query;
        if (objectName == 'Program'){
            query = 'SELECT Id, Retained_to_lead__c FROM Section__c WHERE Program__c IN:lstIds';
        }else  if (objectName == 'Treaty'){
            query = 'SELECT Id, Retained_to_lead__c FROM Section__c WHERE Treaty__c IN:lstIds';
        }else if (objectName == 'Section'){
            query = 'SELECT Id, Retained_to_lead__c FROM Section__c WHERE Id IN:lstIds';
        }
        lstSelectSecRetainToLead = Database.query(query);
        System.debug('lstSelectSecRetainToLead == ' + lstSelectSecRetainToLead);
        for (Section__c sec :lstSelectSecRetainToLead){
            if (sec.Retained_to_lead__c){
                sec.Retained_to_lead__c = false;
                lstUpdateSecRetainToLead.add(sec);
            }
        }

        System.debug('lstUpdateSecRetainToLead 22== ' + lstUpdateSecRetainToLead);
        try{
            if (lstUpdateSecRetainToLead.size()>0){
                update lstUpdateSecRetainToLead;
                message = 'Updated successfully';
            }
        }
        catch (Exception ex) {
                message = ex.getMessage();
        }
        System.debug('message == ' + message);
        return message;
    }


}