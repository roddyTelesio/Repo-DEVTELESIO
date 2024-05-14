public with sharing class LWC23_PlacementRequests {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Controller for Lightning Web Component lwc23PlacementRequests
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 17-FEB-2020  DMO   1.0      Initial version
-- 27-APR-2021  MBE   1.1      W-0871 - Placement - Pas de redescente du Pool dans la pop-up View Placement Table
--------------------------------------------------------------------------------------
**************************************************************************************/
    /**
    * @description Method to get Placement Requests for a Program
    * @param null
    * @return List<OptionWrapper>
    */
    @AuraEnabled(Cacheable = true)
    public static Map<String, Object> getPlacementRequests(Id programId, Id treatyId, Id reinsurerId, Id brokerId, String reinsurerStatus){
        Map<String, Id> mapRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectRequest});
         //RRA - ticket 585 - 07032023
         Map<String, Object> mapResults = new Map<String, Object>();
        String recordTypeId = mapRecTypeId.get(AP_Constant.reqRTPlacement);
        List<Request__c> lstPlacementRequestsToDisplay = new List<Request__c>();
        Boolean isDeactivatedProg = false; //RRA - ticket 0585 - 13032023         
        
          //RRA - ticket 1564 - 31082023 Add TECH_BrokerReinsurer__c in soql
        String query = 'SELECT Id, TECH_Layer__c, Layer__c, TECH_BrokerReinsurer__c, TreatyReference__c, Treaty__c, Broker__c, TECH_TreatyName__c, Section__c, TECH_SectionName__c'
                    + ', TECH_BrokerName__c, WrittenShare__c, ReinsurerStatus__c, LastSentDate__c, TECH_LatestVersion__c, VersionMajor__c, LastVersionSent__c, LastVersionAnswered__c, OriginalRequest__c, Program__r.isBtnActivatedDeactivated__c, Program__c, Section__r.Status__c, Treaty__r.Status__c ' //RRA -ticket 585 - 16032023
                    + ', ExpectedResponseDate__c, ResponseDate__c, toLabel(LeadType__c), Reinsurer__c, TECH_ReinsurerName__c, Version__c, RecordTypeId, Utility_Icon_Attachment__c, Utility_Icon_Comment__c  ' // RRA - 939'
                    + ' FROM Request__c'
                    + ' WHERE Program__c = :programId'
                    + ' AND RecordTypeId = :recordTypeId'
                    + ' AND Program__c != NULL';
        
        if (treatyId!=null)
            query = query + ' AND Treaty__c = :treatyId';
        if (reinsurerId!=null)
            query = query + ' AND Reinsurer__c = :reinsurerId';
        if (brokerId!=null)
            query = query + ' AND Broker__c = :brokerId';
        if (reinsurerStatus!=null)
            query = query + ' AND ReinsurerStatus__c = :reinsurerStatus';
            
        query = query + ' ORDER BY TECH_Layer__c, TECH_TreatyName__c, TECH_ReinsurerName__c, TECH_BrokerName__c'; //RRA - ticket 1571 - 09102023

        List<Request__c> lstPlacementRequest = Database.query(query);

        for(Request__c placementRequest : lstPlacementRequest){
            if(placementRequest.ReinsurerStatus__c == 'Setup'
                    || (placementRequest.ReinsurerStatus__c != 'Setup' && placementRequest.LastVersionSent__c == true && placementRequest.LastVersionAnswered__c == true)){
                lstPlacementRequestsToDisplay.add(placementRequest);
            }
        }

        //Program - RRA - ticket 585 - 07032023
        for (Program__c prog : [SELECT Id, isBtnActivatedDeactivated__c FROM Program__c WHERE Id=:programId]){
            if (prog.isBtnActivatedDeactivated__c){
                isDeactivatedProg = true;
            }
        }

        //RRA - ticket 585 - 07032023
        mapResults.put('isDeactivatedProg', isDeactivatedProg); 
        mapResults.put('lstPlacementRequestsToDisplay', lstPlacementRequestsToDisplay);
        return mapResults;
    }
    /**
    * @description Method to get data for Placement Table
    * @param Id programId
    * @return List<PlacementWrapper>
    */
    @AuraEnabled
    public static List<PlacementWrapper> viewPlacementTable(Id programId){
        List<PlacementWrapper> lstResults = new List<PlacementWrapper>();
        Map<String, List<PlacementWrapper>> mapResults = new Map<String, List<PlacementWrapper>>();
        Map<String, Id> mapRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectRequest});
        Set<String> reqRT = new Set<String>{mapRecTypeId.get(AP_Constant.reqRTLead), mapRecTypeId.get(AP_Constant.reqRTPlacement)};
        Map<Id, Decimal> mapPlacementShareByTreaty = new Map<Id, Decimal>();
        Map<Id, Integer> mapCheckIfTreatyHasLead = new Map<Id, Integer>();

        for(Treaty__c treaty : [SELECT Id, Name, PlacementShare_Perc__c FROM Treaty__c WHERE Program__c = :programId]){
            if(!mapPlacementShareByTreaty.containsKey(treaty.Id)){
                mapPlacementShareByTreaty.put(treaty.Id, treaty.PlacementShare_Perc__c);
            }
        }

        for(Request__c req : [SELECT Id, TECH_Layer__c, RecordType.DeveloperName, TreatyReference__c, Treaty__c, TECH_TreatyName__c, Broker__r.Name, Reinsurer__r.Name, WrittenShare__c, ReinsurerStatus__c,
                            LastSentDate__c, ExpectedResponseDate__c, ResponseDate__c, LastVersionSent__c, LastVersionAnswered__c FROM Request__c WHERE Program__c = :programId
                            AND RecordTypeId IN :reqRT AND Reinsurer__c != NULL]){
            if(req.ReinsurerStatus__c == 'Setup'
                    || (req.ReinsurerStatus__c != 'Setup' && req.LastVersionSent__c == true && req.LastVersionAnswered__c == true)){
                String type = req.RecordType.DeveloperName;
                String key = req.Treaty__c+'---'+req.TECH_Layer__c+'---'+req.TreatyReference__c+'---'+req.TECH_TreatyName__c;
                if(mapResults.containsKey(key)){
                    mapResults.get(key).add(new PlacementWrapper(req.Id, null, type, req.TECH_Layer__c, req.TreatyReference__c, req.TECH_TreatyName__c,
                            req.Broker__r.Name, req.Reinsurer__r.Name, req.WrittenShare__c,
                            req.ReinsurerStatus__c, req.LastSentDate__c, req.ExpectedResponseDate__c,
                            req.ResponseDate__c, null, null));
                }
                else{
                    mapResults.put(key, new List<PlacementWrapper>{new PlacementWrapper(req.Id, null, type, req.TECH_Layer__c, req.TreatyReference__c, req.TECH_TreatyName__c,
                            req.Broker__r.Name, req.Reinsurer__r.Name, req.WrittenShare__c,
                            req.ReinsurerStatus__c, req.LastSentDate__c, req.ExpectedResponseDate__c,
                            req.ResponseDate__c, null, null)});
                }

                if(req.RecordTypeId == mapRecTypeId.get(AP_Constant.reqRTLead)){
                    Integer numLeadReq = 0;
                    if(mapCheckIfTreatyHasLead.containsKey(req.Treaty__c)){
                        numLeadReq = mapCheckIfTreatyHasLead.get(req.Treaty__c);
                    }
                    numLeadReq = numLeadReq + 1;
                    mapCheckIfTreatyHasLead.put(req.Treaty__c, numLeadReq);
                }
            }
        }

        for(PoolTreatySection__c pool : [SELECT Id, Treaty__c, Treaty__r.Layer__c, Treaty__r.WebXLReference__c, Treaty__r.Name, TreatyShareRate__c, Pool__r.name FROM PoolTreatySection__c WHERE TreatyIsSelected__c = true AND SectionIsSelected__c = false
                                        AND Treaty__r.Program__c = :programId]){
            
            if(mapCheckIfTreatyHasLead.containsKey(pool.Treaty__c)){
                if(mapCheckIfTreatyHasLead.get(pool.Treaty__c) > 0){
                    String key = pool.Treaty__c+'---'+pool.Treaty__r.Layer__c+'---'+pool.Treaty__r.WebXLReference__c+'---'+pool.Treaty__r.Name;
                    if(mapResults.containsKey(key)){
                        mapResults.get(key).add(new PlacementWrapper(pool.Id, null, 'pool', String.valueOf(pool.Treaty__r.Layer__c), pool.Treaty__r.WebXLReference__c, pool.Treaty__r.Name,
                                null, pool.Pool__r.name, pool.TreatyShareRate__c,
                                null, null, null,
                                null, null, null));
                    }
                    else{
                        mapResults.put(key, new List<PlacementWrapper>{new PlacementWrapper(pool.Id, null, 'pool', String.valueOf(pool.Treaty__r.Layer__c), pool.Treaty__r.WebXLReference__c, pool.Treaty__r.Name,
                                null, pool.Pool__r.name, pool.TreatyShareRate__c,
                                null, null, null,
                                null, null, null)});
                    }
                }
            }
        }

        for(String key : mapResults.keySet()){
            String[] arrKey = key.split('---');
            String layer = arrKey[1];
            String treatyRef = arrKey[2];
            String treatyName = arrKey[3];
            Decimal totalShare = 0;
            Id treatyId = arrKey[0];

            for(PlacementWrapper placement : mapResults.get(key)){
                if(placement.writtenShare != null){
                    totalShare += placement.writtenShare;
                }
            }

            List<PlacementWrapper> lstChildren = (List<PlacementWrapper>) mapResults.get(key);

            Decimal treatyPlacementShare = mapPlacementShareByTreaty.get(treatyId);

            lstChildren.add(new PlacementWrapper('total'+key, null, 'total', layer, treatyRef, treatyName + ' (' +treatyPlacementShare+ '%)', null, null, totalShare,
                    null, null, null,
                    null, null, treatyPlacementShare ));

            PlacementWrapper newParent = new PlacementWrapper('parent'+key, 'parent'+key, 'parent', layer, treatyRef, treatyName, null, null, null,
                    null, null, null,
                    null, lstChildren, treatyPlacementShare );

            lstResults.add(newParent);
        }

        return lstResults;
    }

    public class PlacementWrapper{
        @AuraEnabled public String id {get; set;}
        @AuraEnabled public String parentId {get; set;}
        @AuraEnabled public String type {get; set;}
        @AuraEnabled public String layer {get; set;}
        @AuraEnabled public String treatyRef {get; set;}
        @AuraEnabled public String treatyName {get; set;}
        @AuraEnabled public String broker {get; set;}
        @AuraEnabled public String reinsurerPool {get; set;}
        @AuraEnabled public Decimal writtenShare {get; set;}
        @AuraEnabled public String reinsurerStatus {get; set;}
        @AuraEnabled public Date lastSentDate {get; set;}
        @AuraEnabled public Date expectedAnswerDate {get; set;}
        @AuraEnabled public Date responseDate {get; set;}
        @AuraEnabled public Decimal treatyPlacementShare {get; set;}
        @AuraEnabled public List<PlacementWrapper> sub {get; set;}

        public PlacementWrapper(String id, String parentId, String type, String layer, String treatyRef, String treatyName, String broker, String reinsurerPool, Decimal writtenShare,
                                String reinsurerStatus, Date lastSentDate, Date expectedAnswerDate, Date responseDate,List<PlacementWrapper> sub, Decimal treatyPlacementShare ) {
            this.id = id;
            this.parentId = parentId;
            this.type = type;
            this.layer = layer;
            this.treatyRef = treatyRef;
            this.treatyName = treatyName;
            this.broker = broker;
            this.reinsurerPool = reinsurerPool;
            this.writtenShare = writtenShare;
            this.reinsurerStatus = reinsurerStatus;
            this.lastSentDate = lastSentDate;
            this.expectedAnswerDate = expectedAnswerDate;
            this.responseDate = responseDate;
            this.sub = sub;
            this.treatyPlacementShare = treatyPlacementShare;
        }
    }
    /**
    * @description Method to check if Placement info need to be disabled
    * @param Id programId
    * @return Boolean
    */
    @AuraEnabled
    public static Boolean disablePlacementInfo(Id programId){
        Program__c program = [SELECT Id, Name, TECH_ShowClosePreviousPhaseBtn__c FROM Program__c WHERE Id = :programId];
        //if close previous phase button is enabled in signing ---> should display information for placement ---not disable
        //if close previous phase button is disabled in signing ----> should not display information for placement(must click on Reopen Previous Phase to display information) -------disable

        String showPreviousPhaseBtn = program.TECH_ShowClosePreviousPhaseBtn__c;
        Boolean disablePlacementInfo = false;

        if(showPreviousPhaseBtn == '1'){
            disablePlacementInfo = false;
        }
        else if(showPreviousPhaseBtn == '2'){
            disablePlacementInfo = true;
        }

        return disablePlacementInfo;
    }
    /**
    * @description Method to check if Lead Request is present before creating Placemnt Request
    * @param Id programId
    * @return Boolean
    */
    @AuraEnabled
    public static Boolean checkIfLeadRequestPresent(Id programId){
        Boolean result = false;
        Map<String, Id> mapRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectRequest});
        String recordTypeLeadId = mapRecTypeId.get(AP_Constant.reqRTLead);
        try{
            List<Request__c> lstLeadRequests =[ SELECT Id, 
                                                       Treaty__c
                                                FROM Request__c
                                                WHERE Program__c =: programId
                                                AND RecordTypeId =: recordTypeLeadId
                                                AND TECH_LeadType__c = 'parent'];
            if(lstLeadRequests != null){
                if(lstLeadRequests.size() > 0){
                    result = true;
                }
            }
            return result;
        }
        catch (Exception ex){
            return false;
        }
    }
    /**
    * @description Method to get Program details
    * @param Id programId
    * @return Program__c
    */
    @AuraEnabled
    public static Program__c getSelectedProgramDetail(Id programId){
        Program__c program = [SELECT Id, Name, RenewedFromProgram__c, TypeOfRenew__c FROM Program__c WHERE Id = :programId];
        return program;
    }
    /**
    * @description Method to get UW year of Program
    * @param Id programId
    * @return String
    */
    @AuraEnabled
    public static String getUWYearForOriginalProgram(Id programId){
        Program__c renewedProgram = [SELECT Id, RenewedFromProgram__c FROM Program__c WHERE Id = :programId];
        Id renewedFromProgramId = renewedProgram.RenewedFromProgram__c;
        String uwYearOriginalProgram = null;

        if(renewedFromProgramId != null){
            //program is renewed
            Program__c originalProgram = [SELECT Id, UwYear__c FROM Program__c WHERE Id = :renewedFromProgramId];
            uwYearOriginalProgram = originalProgram.UwYear__c;
        }
        return uwYearOriginalProgram;
    }
}