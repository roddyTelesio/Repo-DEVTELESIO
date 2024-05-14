public without sharing class LWC01_HomePageActions {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Class for Home Page Actions
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 23-OCT-2019  NBI    1.0     Initial Version
-- 24-APR-2020  SAU    1.1     Corrected deleteRecords
-- 31-JUL-2020  SAU    1.2     Delete requests, documents and document visibility
-- 03-AUG-2020  SAU    1.3     Delete requests and sections for deleted treaties
-- 04-AUG-2020  SAU    1.4     Updated delete sections + delete requests
-- 13-AUG-2020  SAU    1.5     delete lead child
-- 03-SEP-2020  SAU    1.6     Delete programs based on user profile
-- 20-NOV-2020  NBI    1.7     W-0802 : Deactivate parent section should not deactivate all other related sections.
-- 15-JUN-2021  MBE    1.8     W-0983 - Bug bloquant Prod sur proramme migré - Des followers supprimés suite à un reopen previous phases apparaissent encore dans le tableau de Signing
--------------------------------------------------------------------------------------
**************************************************************************************/

    /**
    * @description Method to Reactivate/Deactivate Program/Treaty/Section/Request
    * @param List<SObject> lstRecords, String objectName, String status
    * @return Map<String, Object>
    */
    @AuraEnabled
    public static Map<String, Object> reactivateDeactivate(List<SObject> lstRecords, String objectName, String status, Boolean isButtonActDeact){
        Map<String, Object> mapResults = new Map<String, Object>();
        Map<String, Id> mapRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectRequest});
        Set<Id> setProgramIds = new Set<Id>();
        Set<Id> setTreatyIds = new Set<Id>();
        Set<Id> setSectionIds = new Set<Id>();
        Set<Id> setIdSections = new Set<Id>(); 
        Set<Id> setLeadReqIds = new Set<Id>();
        Set<SObject> setUniqueRecords = new Set<SObject>();
        List<SObject> lstUniqueRecords = new List<SObject>();
        List<Id> lstProgramId = new List<Id>();
        List<Id> lstTreatyId = new List<Id>();
        List<Id> lstSectionId = new List<Id>();
        List<Section__c> lstRecordsSection = new List<Section__c>(); //RRA - ticket 14032023
        //List<Section__c> lstRecordsSectionRelated = new List<Section__c>(); //RRA - ticket 14032023
        List<Request__c> lstRecordsReqSection = new List<Request__c>(); //RRA - ticket 14032023
        List<Section__c> lstUpdateRelatedSection = new List<Section__c>(); //RRA - ticket 14032023
        Boolean isSection = false;

        try{
            for(SObject record: lstRecords) {
                if(objectName == 'Request'){
                    String strStatus = (String)record.get('ActiveStatus__c');
                    String strRT = (String)record.get('RecordTypeId');

                    if(strStatus != status){
                        if(mapRecTypeId.containsKey(AP_Constant.reqRTLead) && mapRecTypeId.get(AP_Constant.reqRTLead) == strRT){
                            setLeadReqIds.add((Id)record.get('Id'));
                        }
                        record.put('ActiveStatus__c', status);
                    }
                }
                else{
                    String strStatus = (String) record.get('Status__c');
                    if (strStatus != status) {
                        record.put('Status__c', status);
                    }
                }

                if(objectName == 'Program'){
                    setProgramIds.add((Id)record.get('Id'));
                    lstProgramId.addAll(setProgramIds);
                }
                else if(objectName == 'Treaty'){
                    setTreatyIds.add((Id)record.get('Id'));
                    lstTreatyId.addAll(setTreatyIds);
                 //RRA - ticket 585 - 13032023
                }else if(objectName == 'Section'){
                    setIdSections.add((Id)record.get('Id'));
                    lstSectionId.addAll(setIdSections);
                }
            }

            //Manage deactivation Program
            if(setProgramIds.size() > 0){
                for(Treaty__c treaty : [SELECT Id, Status__c FROM Treaty__c WHERE Program__c IN :setProgramIds]){
                    setTreatyIds.add(treaty.Id);
                    if(treaty.Status__c != status){
                        treaty.Status__c = status;
                    }
                    lstRecords.add(treaty);
                }

                //RRA - ticket 585 06122022 - Activate / Deactivate all button on Request phases (Quote/Lead/Placement/Signing)
                for(Program__c prg : [SELECT Id, isBtnActivatedDeactivated__c FROM Program__c WHERE Id IN :setProgramIds]){
                    prg.isBtnActivatedDeactivated__c = isButtonActDeact;
                    lstUniqueRecords.add(prg);
                }
                //RRA - ticket 585 07122022 : 
                if (lstProgramId != null && !lstProgramId.isEmpty()){
                    if(isButtonActDeact){
                        //Step 1 :  Action Delete Sharing On program deactivated
                        AP63_CreateSharingOrDeleteFromProgram.DeleteSharingRequestFromProgram(lstProgramId, 'Program');
                    }else{
                         //Step 2 :  Action Create Sharing On program Reactivated
                         AP63_CreateSharingOrDeleteFromProgram.createSharingRequestFromProgram(lstProgramId, 'Program');
                    }
                }
            }

            //Manage deactivation Treaty
            if(setTreatyIds.size() > 0){
                for(Section__c section : [SELECT Id, Status__c FROM Section__c WHERE Treaty__c IN :setTreatyIds AND Option__c = '2']){
                    setSectionIds.add(section.Id);
                    if(section.Status__c != status){
                        section.Status__c = status;
                    }
                    lstRecords.add(section);
                }

                for(Treaty__c treaty : [SELECT Id FROM Treaty__c WHERE Id IN :setTreatyIds]){
                    lstUniqueRecords.add(treaty);
                }
                if (lstTreatyId != null && !lstTreatyId.isEmpty()){
                    if(isButtonActDeact){
                        //Step 1 :  Action Delete Sharing On program deactivated
                        AP63_CreateSharingOrDeleteFromProgram.DeleteSharingRequestFromProgram(lstTreatyId, 'Treaty');
                    }else{
                         //Step 2 :  Action Create Sharing On program Reactivated
                         AP63_CreateSharingOrDeleteFromProgram.createSharingRequestFromProgram(lstTreatyId, 'Treaty');
                    }
                }
                if(setSectionIds.size() > 0){
                    for(Section__c childSection : [SELECT Id, Status__c FROM Section__c WHERE RelatedSection__c IN :setSectionIds]){
                        if(childSection.Status__c != status){
                            childSection.Status__c = status;
                        }

                        lstRecords.add(childSection);
                    }
                }
                if(setLeadReqIds.size() > 0){
                    Set<Id> setChildLeadReq = new Set<Id>();
                    for(LeadRequestSelection__c leadReqSelection : [SELECT Id, LeadRequestChild__c FROM LeadRequestSelection__c WHERE LeadRequestParent__c IN :setLeadReqIds]){
                        setChildLeadReq.add(leadReqSelection.LeadRequestChild__c);
                    }
    
                    if(setChildLeadReq.size() > 0){
                        for(Request__c childReq: [SELECT Id, ActiveStatus__c FROM Request__c WHERE Id IN :setChildLeadReq]){
                            if(childReq.ActiveStatus__c != status){
                                childReq.ActiveStatus__c = status;
                            }
                            lstRecords.add(childReq);
                        }
                    }
                }
            }
           

            //Manage deactivation Section
            if(setIdSections.size() > 0){
                isSection = true;
                List<Id> lstRelatedSection = new List<Id>();
                List<Id> lstIdSection = new List<Id>();
                List<Section__c> lstSec = new List<Section__c>();
                String query = null;
                for(Section__c section : [SELECT Id, Status__c, Retained_to_lead__c, RelatedSection__c FROM Section__c WHERE Id IN :setIdSections]){

                    if(section.Status__c != status){
                        section.Status__c = status;
                    }

                    lstRecordsSection.add(section);
                }
        
                if(setLeadReqIds.size() > 0){
                    Set<Id> setChildReqLead= new Set<Id>();
                    for(LeadRequestSelection__c leadReqSelection : [SELECT Id, LeadRequestChild__c FROM LeadRequestSelection__c WHERE LeadRequestParent__c IN :setLeadReqIds]){
                        setChildReqLead.add(leadReqSelection.LeadRequestChild__c);
                    }
    
                    if(setChildReqLead.size() > 0){
                        for(Request__c childReq: [SELECT Id, ActiveStatus__c FROM Request__c WHERE Id IN :setChildReqLead]){
                            if(childReq.ActiveStatus__c != status){
                                childReq.ActiveStatus__c = status;
                            }
                            lstRecordsReqSection.add(childReq);
                        }
                    }
                }
            }
        
            //Step3: Init value of number of Lead /Placement / Signing Requests to display the error message on UI
            //if Reactivation => Status is Activated for Program / Treaty / Section

            //RRA - ticket 585 06122022 - Manage Reactivation / Deactivation on Section 
            if (isSection){
                //Reactivation section
                if (status == '1' && isButtonActDeact == false){
                    if (lstRecordsSection.size()>0){
                        update lstRecordsSection;
                    }

                    /*if (lstRecordsSectionRelated.size()>0 || lstRecordsSectionRelated != null){
                        update lstRecordsSectionRelated;
                    }*/

                    if (lstRecordsReqSection.size()>0 || lstRecordsReqSection != null){
                        update lstRecordsReqSection;
                    }

                    mapResults.put('Success', 'Records successfully Reactivated.');
                }else if (status == '2' && isButtonActDeact){
                    /*if (numbLeadRequest > 0){
                        mapResults.put('numbLeadRequest', numbLeadRequest);
                    }else */
                    //if (numbLeadRequest == 0){
                        //RRA - ticket 585 06122022
                        if (lstRecordsSection.size()>0){
                            update lstRecordsSection;
                        }

                        if (lstRecordsSection.size()>0 || lstRecordsSection != null){
                            for (Section__c sec : lstRecordsSection){
                                if (sec.Retained_to_lead__c){
                                    sec.Retained_to_lead__c = false;
                                    lstUpdateRelatedSection.add(sec);
                                }
                            }
                        }

                        /*if (lstRecordsSectionRelated.size()>0 || lstRecordsSectionRelated != null){
                            update lstRecordsSectionRelated;
                        }*/

                        if (lstRecordsReqSection.size()>0 || lstRecordsReqSection != null){
                            update lstRecordsReqSection;
                        }

                        if (lstUpdateRelatedSection.size()>0 || lstUpdateRelatedSection != null){
                            update lstUpdateRelatedSection;
                        }

                        System.debug('lstRecordsSection == ' + lstRecordsSection);
                        //mapResults.put('numbLeadRequest', numbLeadRequest);
                        mapResults.put('Success', 'Records successfully Deactivated.');
                    //}
                }
            //RRA - ticket 585 06122022 - Manage Reactivation / Deactivation on Program and on Treaty 
            }else{
                //Reactivation
                if (status == '1' && isButtonActDeact == false){
                    if(lstRecords.size() > 0){
                        setUniqueRecords.addAll(lstRecords);
                        update lstRecords;
                    }
                    lstRecords.clear();
                    if(setUniqueRecords.size() > 0){
                        lstRecords.addAll(setUniqueRecords);
                    }
                    //RRA - ticket 585 06122022
                    if (lstUniqueRecords.size()>0){
                        update lstUniqueRecords;
                    }
    
                    if(lstRecords.size() > 0){
                        update lstRecords;
                    }
                    mapResults.put('Success', 'Records successfully Reactivated.');
    
                //Deactivation => Check first if Request on Lead / Placement / Signing exists, if yes bloked if no, update the Data
                }else if (status == '2' && isButtonActDeact){    
                        if(lstRecords.size() > 0){
                            setUniqueRecords.addAll(lstRecords);
                            update lstRecords;
                        }
            
                        lstRecords.clear();
            
                        if(setUniqueRecords.size() > 0){
                            lstRecords.addAll(setUniqueRecords);
                        }
                        //RRA - ticket 585 06122022
                        if (lstUniqueRecords.size()>0){
                            update lstUniqueRecords;
                        }
            
                        if(lstRecords.size() > 0){
                            update lstRecords;
                        }
                        mapResults.put('Success', 'Records successfully Deactivated.');
                }
            }
            
        }
        catch (Exception ex){
            mapResults.put('Error', ex.getMessage());
        }
        return mapResults;
    }

    /**
    * RRA - ticket 585 - 22032023 
    * @description Method to check if lead Request is present on Program/Treaty/Section/
    * @param List<SObject> lstRecords, String objectName, String status
    * @return Map<String, Object>
    */
    @AuraEnabled
    public static Map<String, Object> checkRequestExist(List<SObject> lstRecords, String objectName, String status, Boolean isButtonActDeact){
        Map<String, Object> mapResults = new Map<String, Object>();
        Map<String, Id> mapRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectRequest});
        Set<Id> setProgramIds = new Set<Id>();
        Set<Id> setTreatyIds = new Set<Id>();
        Set<Id> setSectionIds = new Set<Id>();
        Set<Id> setIdSections = new Set<Id>(); 
        Set<Id> setLeadReqIds = new Set<Id>();
        List<Id> lstProgramId = new List<Id>();
        List<Id> lstTreatyId = new List<Id>();//lstSectionId
        List<Id> lstSectionId = new List<Id>();
        Set<String> setRecordTypeName = new Set<String>();
	    String recordTypeQuote;
        String recordTypeLead;
        String recordTypePlacement;
        String recordTypeSigning;
        String queryCountPlacement = null;
        String queryCountSigning =null;
        String queryCountLead = null;
        String queryCountQuote = null;
        Integer numbPlacementRequest = 0;
        Integer numbLeadRequest = 0;
        Integer numbSigningRequest = 0;
        Integer numbQuoteRequest = 0;
        try{
            for(SObject record: lstRecords) {
                if(objectName == 'Program'){
                    setProgramIds.add((Id)record.get('Id'));
                    lstProgramId.addAll(setProgramIds);
                }
                else if(objectName == 'Treaty'){
                    setTreatyIds.add((Id)record.get('Id'));
                    lstTreatyId.addAll(setTreatyIds);
                 //RRA - ticket 585 - 13032023
                }else if(objectName == 'Section'){
                    setIdSections.add((Id)record.get('Id'));
                    lstSectionId.addAll(setIdSections);
                }
            }

                //Manage deactivation Program
                if(setProgramIds.size() > 0){
                    //RRA - ticket 585 01032023 : Check and display error message when requests Quote/ lead/ Plamcent are still existing on program
                    for (Request__c req : [SELECT Id, RecordType.Name  FROM Request__c WHERE Program__c IN:setProgramIds]){
                        setRecordTypeName.add(req.RecordType.Name);
                    }

                    //Step1 : get the recordType attached on program
                    for (String recName : setRecordTypeName){
                        if (recName == 'Quote Request'){
                            recordTypeQuote = recName;
                        }else if (recName == 'Lead Request'){
                            recordTypeLead = recName;
                        }else if (recName == 'Placement Request'){
                            recordTypePlacement = recName;
                        }else if (recName == 'Signing Request'){
                            recordTypeSigning = recName;
                        }
                    }

                    //Step2 : create request to count the number of Quote / Lead / Placement Requests
                    if (recordTypeLead == 'Lead Request'){
                        queryCountLead = 'SELECT Count() FROM Request__c WHERE Program__c IN:setProgramIds AND RecordType.Name =:recordTypeLead AND ReinsurerStatus__c IN (\'Setup\', \'Sent\', \'Answered\', \'Timeout\') AND OriginalRequest__c = null';
                    }else if (recordTypePlacement == 'Placement Request'){
                        queryCountPlacement =  'SELECT Count() FROM Request__c WHERE Program__c IN:setProgramIds AND RecordType.Name = \'Placement Request\'  AND ReinsurerStatus__c IN (\'Setup\', \'Sent\', \'Answered\', \'Timeout\', \'Refused\') AND OriginalRequest__c = null';
                    }else if (recordTypeSigning == 'Signing Request'){
                        queryCountSigning =  'SELECT Count() FROM Request__c WHERE Program__c IN:setProgramIds AND RecordType.Name = \'Signing Request\'  AND ReinsurerStatus__c IN (\'Setup\', \'Sent\', \'Signed\', \'Timeout\', \'Signed By R.M.\') AND OriginalRequest__c = null';
                    }

                    if (queryCountLead != null){
                        numbLeadRequest = Database.countQuery(queryCountLead);
                    }
                    
                    if (queryCountPlacement !=null){
                        numbPlacementRequest = Database.countQuery(queryCountPlacement);
                    }

                    if (queryCountSigning !=null){
                        numbSigningRequest = Database.countQuery(queryCountSigning);
                    }
                    mapResults.put('numbLeadRequest', numbLeadRequest);
                    mapResults.put('numbPlacementRequest', numbPlacementRequest);
                    mapResults.put('numbSigningRequest', numbSigningRequest);
                }

                //Manage deactivation Treaty
                if(setTreatyIds.size() > 0){
                    for (Request__c req : [SELECT Id, RecordType.Name  FROM Request__c WHERE Treaty__c IN:setTreatyIds]){
                        setRecordTypeName.add(req.RecordType.Name);
                    }

                    //Step1 : get the recordType attached on Treaty
                    for (String recName : setRecordTypeName){
                        if (recName == 'Quote Request'){
                            recordTypeQuote = recName;
                        }else if (recName == 'Lead Request'){
                            recordTypeLead = recName;
                        }else if (recName == 'Placement Request'){
                            recordTypePlacement = recName;
                        }else if (recName == 'Signing Request'){
                            recordTypeSigning = recName;
                        }
                    }

                    //Step2 : create request to count the number of Quote / Lead / Placement Requests
                    if (recordTypeLead == 'Lead Request'){
                        queryCountLead = 'SELECT Count() FROM Request__c WHERE Treaty__c IN:setTreatyIds AND RecordType.Name =:recordTypeLead AND ReinsurerStatus__c IN (\'Setup\', \'Sent\', \'Answered\', \'Timeout\') AND OriginalRequest__c = null';
                    }else if (recordTypePlacement == 'Placement Request'){
                        queryCountPlacement =  'SELECT Count() FROM Request__c WHERE Treaty__c IN:setTreatyIds AND RecordType.Name = \'Placement Request\'  AND ReinsurerStatus__c IN (\'Setup\', \'Sent\', \'Answered\', \'Timeout\', \'Refused\') AND OriginalRequest__c = null';
                    }else if (recordTypeSigning == 'Signing Request'){
                        queryCountSigning =  'SELECT Count() FROM Request__c WHERE Treaty__c IN:setTreatyIds AND RecordType.Name = \'Signing Request\'  AND ReinsurerStatus__c IN (\'Setup\', \'Sent\', \'Signed\', \'Timeout\', \'Signed By R.M.\') AND OriginalRequest__c = null';
                    }

                    if (queryCountLead != null){
                        numbLeadRequest = Database.countQuery(queryCountLead);
                    }
                    
                    if (queryCountPlacement !=null){
                        numbPlacementRequest = Database.countQuery(queryCountPlacement);
                    }

                    if (queryCountSigning !=null){
                        numbSigningRequest = Database.countQuery(queryCountSigning);
                    }

                    mapResults.put('numbLeadRequest', numbLeadRequest);
                    mapResults.put('numbPlacementRequest', numbPlacementRequest);
                    mapResults.put('numbSigningRequest', numbSigningRequest);
                }

                //Manage deactivation Section
                if(setIdSections.size() > 0){
                    List<Id> lstIdTreatyAttachedOnSection = new List<Id>();
                    for (Section__c sec : [SELECT Id, Treaty__c FROM Section__c WHERE Id IN:setIdSections]){
                        lstIdTreatyAttachedOnSection.add(sec.Treaty__c);
                    }

                      System.debug('lstIdTreatyAttachedOnSection == ' + lstIdTreatyAttachedOnSection);

                    if (lstIdTreatyAttachedOnSection.size()>0){ 
                        for (Request__c req : [SELECT Id, RecordType.Name  FROM Request__c WHERE Treaty__c IN:lstIdTreatyAttachedOnSection]){
                            setRecordTypeName.add(req.RecordType.Name);
                        }
                    }

                    System.debug('setRecordTypeName == ' + setRecordTypeName);

                    //Step1 : get the recordType attached on Section
                    for (String recName : setRecordTypeName){
                        if (recName == 'Lead Request'){
                            recordTypeLead = recName;
                        }else if (recName == 'Placement Request'){
                            recordTypePlacement = recName;
                        }else if (recName == 'Signing Request'){
                            recordTypeSigning = recName;
                        }
                    }

                    System.debug('recordTypePlacement == ' + recordTypePlacement);

                    //Step2 : create request to count the number of Quote / Lead / Placement Requests
                    if (recordTypeLead == 'Lead Request'){
                        queryCountLead = 'SELECT Count() FROM Request__c WHERE Treaty__c IN:lstIdTreatyAttachedOnSection AND RecordType.Name =:recordTypeLead AND ReinsurerStatus__c IN (\'Setup\', \'Sent\', \'Answered\', \'Timeout\', \'Refused\') AND OriginalRequest__c = null';
                    }else if (recordTypePlacement == 'Placement Request'){
                        queryCountPlacement =  'SELECT Count() FROM Request__c WHERE  Treaty__c IN:lstIdTreatyAttachedOnSection AND RecordType.Name = \'Placement Request\'  AND ReinsurerStatus__c IN (\'Setup\', \'Sent\', \'Answered\', \'Timeout\', \'Refused\') AND OriginalRequest__c = null';
                    }else if (recordTypeSigning == 'Signing Request'){
                        queryCountSigning =  'SELECT Count() FROM Request__c WHERE Treaty__c IN:lstIdTreatyAttachedOnSection AND RecordType.Name = \'Signing Request\'  AND ReinsurerStatus__c IN (\'Setup\', \'Sent\', \'Signed\', \'Timeout\', \'Signed By R.M.\') AND OriginalRequest__c = null';
                    }

                    if (queryCountLead != null){
                        numbLeadRequest = Database.countQuery(queryCountLead);
                    }

                    System.debug('numbLeadRequest == ' + numbLeadRequest);

                    if (queryCountPlacement !=null){
                        numbPlacementRequest = Database.countQuery(queryCountPlacement);
                    }
                    System.debug('numbPlacementRequest == ' +numbPlacementRequest);

                    if (queryCountSigning !=null){
                        numbSigningRequest = Database.countQuery(queryCountSigning);
                    }
                    System.debug('numbSigningRequest == ' +numbSigningRequest);

                    mapResults.put('numbLeadRequest', numbLeadRequest);
                    mapResults.put('numbPlacementRequest', numbPlacementRequest);
                    mapResults.put('numbSigningRequest', numbSigningRequest);
                }
            }
            catch (Exception ex){
                mapResults.put('Error', ex.getMessage());
            }

            return mapResults;
        }

    @AuraEnabled
    public static Map<String, Object> deleteRecords(List<SObject> lstRecords, String objectName){
        Map<String, Object> mapResults = new Map<String, Object>();
        Map<String, Id> mapRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectRequest});
        Set<Id> setIdToDelete = new Set<Id>();
        Set<Id> setIdExcluded = new Set<Id>();
        List<Id> lstAllIds = new List<Id>();
        Set<Id> setSectionId = new Set<Id>();
        List<Reinstatement__c> lstReinstatementsDel = new List<Reinstatement__c>();
        List<CoveredCedingCompany__c> lstCoveredCedComp = new List<CoveredCedingCompany__c>();
        List<PoolTreatySection__c> lstPoolTreatySection = new List<PoolTreatySection__c>();
        List <Treaty__c> lstTreatiesTodelete = new List <Treaty__c>();
        List<Request__c> lstRequestsToDelete = new List<Request__c>();
        List<DocumentVisibility__c> lstDocVisibilityToDelete = new List<DocumentVisibility__c>();
        List<ContentDocument> lstContentDocumentToDelete = new List<ContentDocument>();
        List <Section__c> lstSectionsToDelete = new List<Section__c>();
        List<Request__c> lstSigningRequestToDelete = new List<Request__c>();
        String recordTypeIdQuote = mapRecTypeId.get(AP_Constant.reqRTQuote);
        String recordTypeIdLead = mapRecTypeId.get(AP_Constant.reqRTLead);
        String recordTypeIdPlacement = mapRecTypeId.get(AP_Constant.reqRTPlacement);
        String recordTypeIdSigning = mapRecTypeId.get(AP_Constant.reqRTSigning);

        Set<Id> setLeadReqIds = new Set<Id>();
        Set<Id> setTreatyIds = new Set<Id>();
        Set<Id> setOriginalLeadPlacementId = new Set<Id>();
        Set<Id> setAllVersionLeadPlacementId = new Set<Id>();
        Profile profileObj = [SELECT Id, Name FROM Profile WHERE Id =: UserInfo.getProfileId()]; //RRA - ticket 1360 - 30112022
        try{
            for(SObject record: lstRecords) {
                Id recordId = (Id)record.get('Id');
                setIdToDelete.add(recordId);
            }
            Boolean reinsStatusAnsweredRefused = false;

            if(objectName == 'Request__c'){
                for(SObject record: lstRecords) {
                    String strRT = (String)record.get('RecordTypeId');

                    if (recordTypeIdLead == strRT) {
                        setLeadReqIds.add((Id)record.get('Id'));
                    }

                    if((recordTypeIdQuote == strRT || recordTypeIdLead == strRT || recordTypeIdPlacement == strRT) && ((String)record.get('ReinsurerStatus__c') == AP_Constant.statusAnswered || (String)record.get('ReinsurerStatus__c') == AP_Constant.statusRefused)){ // RRA - ticket 1360 - 30112022
                        reinsStatusAnsweredRefused = true;
                    }

                    if(recordTypeIdPlacement == strRT || recordTypeIdLead == strRT){
                        if((Id)record.get('OriginalRequest__c') != null){
                            setOriginalLeadPlacementId.add((Id)record.get('OriginalRequest__c'));
                        }
                        else{
                            setOriginalLeadPlacementId.add((Id)record.get('Id'));
                        }
                    }
                }

                if(setOriginalLeadPlacementId.size() > 0){
                    for(Request__c placementRequest :  [SELECT Id, OriginalRequest__c
                                                        FROM Request__c
                                                        WHERE (OriginalRequest__c IN :setOriginalLeadPlacementId
                                                        OR Id IN :setOriginalLeadPlacementId)]){
                        setAllVersionLeadPlacementId.add(placementRequest.Id);
                    }

                    if(setAllVersionLeadPlacementId.size() > 0){
                        for( Request__c signingRequest : [SELECT Id, TECH_RelatedLeadPlacementRequest__c
                                                          FROM Request__c
                                                          WHERE RecordTypeId = :recordTypeIdSigning
                                                          AND TECH_RelatedLeadPlacementRequest__c IN :setAllVersionLeadPlacementId]){
                            lstAllIds.add(signingRequest.Id);
                        }
                    }

                }

                if(reinsStatusAnsweredRefused == true && (profileObj.Name != 'System Administrator' && profileObj.Name != 'AGRE_System Admin' && profileObj.Name != 'AGRE_Delegated Admin')){ //RRA - ticket 1360 - 30112022
                        mapResults.put('Error','Selected Request(s) have Reinsurer Status Answered/Refused');
                    }
                    else{
                        if(setLeadReqIds.size() > 0){
                            Map<Id, List<Id>> mapChildParentReq = new Map<Id, List<Id>>();
                            for(LeadRequestSelection__c leadReqSelection : [SELECT Id, LeadRequestChild__c, LeadRequestParent__c FROM LeadRequestSelection__c WHERE LeadRequestParent__c IN :setLeadReqIds]){
                                mapResults.put(leadReqSelection.Id,leadReqSelection);
                                setIdToDelete.add(leadReqSelection.LeadRequestChild__c);
                            }
                        }
        
                        lstAllIds.addAll(setIdToDelete);
                    }  
            }
            
            if(objectName == 'Program__c'){              
                Boolean quoteLeadReqPresent = false;
                List<Request__c> lstRequests = [SELECT Id,
                                                       ReinsurerStatus__c,
                                                       RecordTypeId
                                                FROM Request__c
                                                WHERE Program__c IN :setIdToDelete
                                                AND (RecordTypeId =:recordTypeIdQuote OR RecordTypeId=:recordTypeIdLead OR RecordTypeId=:recordTypeIdPlacement)];

                for(Request__c request : lstRequests){
                    if(request.RecordTypeId == recordTypeIdQuote || request.RecordTypeId == recordTypeIdLead){
                        if(request.ReinsurerStatus__c == AP_Constant.statusAnswered){
                            quoteLeadReqPresent = true;
                        }
                    }
                }
                Profile userProfile = [SELECT Id, Name FROM Profile WHERE Id =: UserInfo.getProfileId()];

                if(quoteLeadReqPresent == true && userProfile.Name != AP_Constant.profileSysAdmin && userProfile.Name != AP_Constant.profileSysAdminAGRe && userProfile.Name != AP_Constant.profileDelagatedAdmin){
                    mapResults.put('Error','Selected Program(s) have Quote/Lead Request(s) with Reinsurer Status Answered');
                }
                else{
                    lstAllIds.addAll(setIdToDelete);
                    lstRequestsToDelete = lstRequests;
                    if(lstAllIds.size() > 0){
                        //get treaties for program
                        for(Treaty__c treaty : [SELECT Id FROM Treaty__c WHERE Program__c IN :setIdToDelete]){
                            lstTreatiesTodelete.add(treaty);
                        }

                        Set <Id> setContentVersionId = new Set<Id>();
                        lstDocVisibilityToDelete = [SELECT Id,
                                                           ContentVersionId__c
                                                    FROM DocumentVisibility__c
                                                    WHERE Program__c IN :setIdToDelete];

                        for(DocumentVisibility__c docVisibility : lstDocVisibilityToDelete){
                            setContentVersionId.add(docVisibility.ContentVersionId__c);
                        }

                        lstContentDocumentToDelete = [SELECT Id
                                                      FROM ContentDocument
                                                      WHERE LatestPublishedVersionId IN: setContentVersionId];
                        
                        for(Section__c sect : [SELECT Id FROM Section__c WHERE Program__c IN :setIdToDelete]){
                            setSectionId.add(sect.Id);
                        }
    
                        if(setSectionId.size() > 0){
                            for(Reinstatement__c reins : [SELECT Id FROM Reinstatement__c WHERE Section__c IN :setSectionId]){
                                lstReinstatementsDel.add(reins);
                            }
                        }
                    }

                }
            }
            if(objectName == 'Treaty__c'){
                List<Request__c> lstRequests = [SELECT Id,
                                                       ReinsurerStatus__c,
                                                       RecordTypeId
                                                FROM Request__c
                                                WHERE Treaty__c IN :setIdToDelete
                                                AND (RecordTypeId =:recordTypeIdQuote OR RecordTypeId=:recordTypeIdLead)];

                Boolean quoteLeadReqPresent = false;
                //RRA - ticket 1413 - 07022023
                
                /*for(Request__c request : lstRequests){
                    if(request.RecordTypeId == recordTypeIdQuote || request.RecordTypeId == recordTypeIdLead){
                        if(request.ReinsurerStatus__c == AP_Constant.statusAnswered){
                            quoteLeadReqPresent = true;
                        }
                    }
                    if(request.RecordTypeId == recordTypeIdQuote && request.ReinsurerStatus__c == AP_Constant.statusRefused){
                        quoteLeadReqPresent = true;
                    }
                }
                if(quoteLeadReqPresent == true){
                    mapResults.put('Error','Selected Treaty(ies) have Quote/Lead Request(s) with Reinsurer Status Answered/Refused');
                }
                else{*/
                    lstAllIds.addAll(setIdToDelete);
                    lstRequestsToDelete = lstRequests;
                    if(lstAllIds.size() > 0){
                        for(Section__c sect : [SELECT Id FROM Section__c WHERE Treaty__c IN :setIdToDelete]){
                            setSectionId.add(sect.Id);
                            lstSectionsToDelete.add(sect);
                        }
    
                        for(CoveredCedingCompany__c coveredCedingCompany : [SELECT Id FROM CoveredCedingCompany__c
                                                                            WHERE Treaty__c IN :setIdToDelete AND TreatyIsSelected__c = true]){
                            lstCoveredCedComp.add(coveredCedingCompany);
                        }
    
                        if(setSectionId.size() > 0){
                            for(Reinstatement__c reins : [SELECT Id FROM Reinstatement__c WHERE Section__c IN :setSectionId]){
                                lstReinstatementsDel.add(reins);
                            }
                        }
                    }
                //}
            }

            if(objectName == 'Section__c'){

                if(setIdToDelete.size() > 0){
                    Boolean quoteReqPresent = false;
                    List<Request__c> lstRequests = [SELECT Id,
                                                        ReinsurerStatus__c,
                                                        RecordTypeId
                                                    FROM Request__c
                                                    WHERE Section__c IN :setIdToDelete
                                                    AND RecordTypeId =:recordTypeIdQuote];
                    /*for(Request__c request : lstRequests){
                        //RRA - ticket 1347 - 02122022
                        if(request.ReinsurerStatus__c == AP_Constant.statusAnswered || request.ReinsurerStatus__c == AP_Constant.statusRefused){
                            quoteReqPresent = true;
                        }
                    }
                   /* if(quoteReqPresent == true){
                        mapResults.put('Error','Selected Section(s) have Quote Request(s) with Reinsurer Status Answered/Refused');
                    }else{*/
                        lstRequestsToDelete = lstRequests;
                        for(Section__c sectn : [SELECT Id, Treaty__c FROM Section__c WHERE (Id IN :setIdToDelete OR RelatedSection__c IN :setIdToDelete)]){
                            setTreatyIds.add(sectn.Treaty__c);
                        }

                        for(Section__c sect : [SELECT Id FROM Section__c WHERE RelatedSection__c IN :setIdToDelete]){
                            setIdToDelete.add(sect.Id);
                        }

                        for(CoveredCedingCompany__c coveredCedingCompany : [SELECT Id FROM CoveredCedingCompany__c
                                                                            WHERE Section__c IN :setIdToDelete AND SectionIsSelected__c = true]){
                            lstCoveredCedComp.add(coveredCedingCompany);
                        }

                        for(PoolTreatySection__c poolTreatySection : [SELECT Id FROM PoolTreatySection__c
                                                                    WHERE Section__c IN :setIdToDelete AND SectionIsSelected__c = true]){
                            lstPoolTreatySection.add(poolTreatySection);
                        }

                        for(Reinstatement__c reins : [SELECT Id FROM Reinstatement__c WHERE Section__c IN :setIdToDelete]){
                            lstReinstatementsDel.add(reins);
                        }
                         lstAllIds.addAll(setIdToDelete);
                    //}
                }
            }
            if(lstReinstatementsDel.size() > 0){
                delete lstReinstatementsDel;
            }
            if(lstTreatiesTodelete.size() > 0){
                delete lstTreatiesTodelete;
            }

            if(lstCoveredCedComp.size() > 0){
                delete lstCoveredCedComp;
            }

            if(lstPoolTreatySection.size() > 0){
                delete lstPoolTreatySection;
            }
            if(lstRequestsToDelete.size() > 0){
                delete lstRequestsToDelete;
            }
            if(lstDocVisibilityToDelete.size() > 0){
                delete lstDocVisibilityToDelete;
            }
            if(lstContentDocumentToDelete.size() > 0){
                delete lstContentDocumentToDelete;
            }
            if(lstSectionsToDelete.size() > 0){
                delete lstSectionsToDelete;
            }

            if(lstAllIds.size() > 0){
                Database.DeleteResult[] deleteResults = Database.delete(lstAllIds, true);
            }

            if(objectName == 'Section__c'){
                if(setTreatyIds.size() > 0){
                    LWC01_HomePageActions.recalculateSectionNumbers(setTreatyIds);
                }
            }

            mapResults.put('Success', 'Records deleted successfully.');
        }
        catch (Exception ex){
            mapResults.put('Error', ex.getMessage());
        }

        return mapResults;
    }


    /**
    * @description Method to recalculate Section numbers
    * @param Set<Id> setTreatyId
    * @return void
    * RRA - 1083
    */
    public static void recalculateSectionNumbers(Set<Id> setTreatyId){
        List<Section__c> lstSections = new List<Section__c>();
        Map<Id, Decimal> mapIdSectNumber = new Map<Id, Decimal>();
        Map<Id, List<Section__c>> mapTreatySections = new Map<Id, List<Section__c>>();
        String strSectionNumber;
        String[] parts;
        Integer beforeComma;
        Integer afterComma;
        String sectionNumberToStringInit;
        String sectionNumberToString;
        Decimal x = 10;
        for(Section__c section : [SELECT Id, Name, ID__c, SectionNumber__c, Treaty__c FROM Section__c WHERE Treaty__c IN :setTreatyId AND RelatedSection__c = null ORDER BY Name, ID__c, SectionNumber__c ASC]){
            if(mapTreatySections.containsKey(section.Treaty__c)){
                List<Section__c> lstSect = (List<Section__c>) mapTreatySections.get(section.Treaty__c);
                lstSect.add(section);
                mapTreatySections.put(section.Treaty__c, lstSect);
            }
            else{
                mapTreatySections.put(section.Treaty__c, new List<Section__c>{section});
            }
        }

        for(Id treatyId : mapTreatySections.keySet()){
            Decimal sectionNumber = 0.1;
            Integer i = 0;
            List<Section__c> lstSect = (List<Section__c>) mapTreatySections.get(treatyId);
            lstSect.sort();
            for(Section__c sect : lstSect){
                sectionNumber += 1.0;
                sect.SectionNumber__c = String.valueOf(sectionNumber);
                lstSections.add(sect);
                mapIdSectNumber.put(sect.Id, sectionNumber);
            }
            System.debug('lstSect== '+ lstSect);
            System.debug('lstSections== '+ lstSections);
        }

        List<Section__c> lstOptions =  [SELECT Id, Name, ID__c, RelatedSection__c, SectionNumber__c  FROM Section__c WHERE Treaty__c IN :setTreatyId AND RelatedSection__c != null ORDER BY Name, ID__c, SectionNumber__c ASC];
        if(lstOptions != null && lstOptions.size() > 0){
            for(Id sectionId : mapIdSectNumber.keySet()){
                Decimal optionNumber = mapIdSectNumber.get(sectionId);
                System.debug('optionNumberInit== ' + optionNumber);
                for(Section__c option : lstOptions){
                    if(option.RelatedSection__c == sectionId){ //RRA - 1083 recalculate the options
                        //optionNumber += 0.1;
                        strSectionNumber = String.valueOf(optionNumber); 
                        parts = strSectionNumber.split('\\.');
                        beforeComma = Integer.valueOf(parts[0]);
                        afterComma =Integer.valueOf(parts[1]);
                        
                        if (afterComma == 0){ // if value decimal is zero
                            sectionNumberToStringInit = String.valueOf(beforeComma - 1 + '.' + (afterComma + x)); 
                            System.debug('sectionNumberToStringAA== ' + sectionNumberToStringInit);
                            optionNumber = Decimal.valueOf(sectionNumberToStringInit);
                        }else if (afterComma >= 1){ // if value decimal is greater than 1
                            sectionNumberToString = String.valueOf(beforeComma + '.' + (afterComma + 1));
                            optionNumber = Decimal.valueOf(sectionNumberToString);
                            System.debug('sectionNumberToStringBB== ' + sectionNumberToString);
                        }

                        System.debug('optionNumber== '+ optionNumber);
                        option.SectionNumber__c = String.valueOf(optionNumber);
                        lstSections.add(option);
                    }

                    System.debug('lstSectionsOptions== '+ lstSections);
                }
            }
        }

        if(lstSections.size() > 0){
            update lstSections;
        }
    }
}