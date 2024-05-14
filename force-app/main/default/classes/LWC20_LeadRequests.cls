public with sharing class LWC20_LeadRequests {
    /**************************************************************************************
    -- - Author        : Spoon Consulting
    -- - Description   : Controller for Lightning Web Component lwc20LeadRequest
    --
    -- Maintenance History:
    --
    -- Date         Name  Version  Remarks
    -- -----------  ----  -------  -------------------------------------------------------
    -- 30-JAN-2020  MBE   1.0      Initial version
    --------------------------------------------------------------------------------------
    **************************************************************************************/
        /**
        * @description Method to Section details for a Program
        * @param Id programId
        * @param Id treatyId
        * @param Id reinsurerId
        * @param Id brokerId
        * @param Id reinsurerStatus
        * @return Map<String, Object>
        */
        @AuraEnabled(cacheable=true)
        public static Map<String, Object> getSectionDetail(Id programId, Id treatyId, Id reinsurerId, Id brokerId, String reinsurerStatus){

            Map<String, Object> mapResult = new Map<String, Object>();
            List<Request__c>  lstChildLeadRequestsToDisplay = new List<Request__c>();
            Map<Id,LeadRequestSelection__c> mapChildRequestLeadRequest = new Map<Id,LeadRequestSelection__c>() ;
            Map<String, Id> mapRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectRequest});
            Boolean isProgramHasSectionsRetainToLead = false;
            List<Request__c> lstLeadRequestsToDisplay = new List<Request__c>();
            Boolean isDeactivatedProg = false; //RRA - ticket 0585 - 13032023      
    
            List<Section__c> lstSectionRetainToLead = [SELECT Id, Name, Retained_to_lead__c
                                                       FROM Section__c
                                                       WHERE Program__c = :programId AND Retained_to_lead__c = TRUE];
            //RRA - ticket 0585 - 06032023 - Program                                        
            for (Program__c prog : [SELECT Id, isBtnActivatedDeactivated__c FROM Program__c WHERE Id=:programId]){
                if (prog.isBtnActivatedDeactivated__c){
                    isDeactivatedProg = true;
                }
            }
            
            if(lstSectionRetainToLead.size() > 0){
                isProgramHasSectionsRetainToLead = true;
            }
            else{
                isProgramHasSectionsRetainToLead = false;
            }
            String recordTypeId = mapRecTypeId.get(AP_Constant.reqRTLead);
            
            //RRA - ticket 1966 - 18032024
            String query = 'SELECT Id, TECH_Layer__c, Layer__c, TreatyReference__c, Treaty__c, Broker__c, Treaty__r.CessionShare__c, Section__r.TECH_CessionShare__c, TECH_TreatyName__c, Section__c, TECH_SectionName__c'
                        + ', TECH_BrokerName__c, WrittenShare__c, ReinsurerStatus__c, LastSentDate__c, TECH_LatestVersion__c, VersionMajor__c, LastVersionSent__c, LastVersionAnswered__c, OriginalRequest__c, Program__r.isBtnActivatedDeactivated__c, Program__c, Treaty__r.Status__c, Section__r.Status__c ' //RRA - ticket 585 16032023'
                        + ', ExpectedResponseDate__c, ResponseDate__c, toLabel(LeadType__c), Reinsurer__c, TECH_ReinsurerName__c, RecordTypeId, Utility_Icon_Attachment__c, Utility_Icon_Comment__c,TECH_ParentLeadRequestQuoteValue__c,TECH_MDP_LeadParent__c  ' // RRA - 939' //MRA W-0935 : 28/07/2022
                        + ' FROM Request__c '
                        + ' WHERE Program__c = :programId'
                        + ' AND RecordTypeId = :recordTypeId'
                        + ' AND Program__c != NULL'
                        + ' AND Reinsurer__c != NULL';
            
            if (treatyId!=null)
                query = query + ' AND Treaty__c = :treatyId';
            if (reinsurerId!=null)
                query = query + ' AND Reinsurer__c = :reinsurerId';
            if (brokerId!=null)
                query = query + ' AND Broker__c = :brokerId';
            if (reinsurerStatus!=null)
                query = query + ' AND ReinsurerStatus__c = :reinsurerStatus ';

            Map<Id,Request__c> mapLeadRequestParent = new Map<Id,Request__c>((List<Request__c>)Database.query(query));
        //************
        // -BEGIN-
        // MRA - 25/07/2022 - 935 add columns Quote and MDP on Lead phase
        // **********/


        for(LeadRequestSelection__c leadRequestSelection : [SELECT Id, Name, LeadRequestChild__c,LeadRequestParent__c
                                                            FROM LeadRequestSelection__c
                                                            WHERE LeadRequestParent__c IN :mapLeadRequestParent.keySet()]){
            mapChildRequestLeadRequest.put(leadRequestSelection.LeadRequestChild__c,leadRequestSelection);
        }

        Set<Id> setReqChildId = new Set<Id>(mapChildRequestLeadRequest.keySet()) ;
        //RRA - ticket 585 16022023
        String queryRequest = ' SELECT Id, MDP__c, Program__r.isBtnActivatedDeactivated__c, Program__c, Treaty__r.CessionShare__c, Section__r.TECH_CessionShare__c, Treaty__r.Status__c, Section__r.Status__c, Treaty__c, Reinsurer__c, Broker__c, ReinsurerStatus__c, Section__r.QuoteType__c, TECH_QuoteType__c, FixedRate__c, MinRate__c, MaxRate__c, ProvisionalRate__c, FlatPremium__c, FixedCommission__c, MinVarCommission__c, toLabel(Quote__c), MaxVarCommission__c, ProvisionalCommission__c, PerHeadPremium__c, MinPerHeadAmount__c, MaxPerHeadAmount__c, ProvisionalPerHeadPremium__c, EstimatedReinsurancePremium__c, EstimatedInsurancePremium__c,Section__r.SectionNumber__c,TECH_TypeofTreaty__c FROM Request__c WHERE Program__c = :programId '
        + ' AND Id IN :setReqChildId'
        + ' AND RecordTypeId = :recordTypeId '; //RRA - ticket 1966 - 18032024
        //+ ' AND Program__c != NULL'
        //+ ' AND Reinsurer__c != NULL';
        List<Request__c> lstLeadRequestChild = Database.query(queryRequest);
        for (Request__c leadRequestChild : lstLeadRequestChild) { 
            Request__c reqParent = mapLeadRequestParent.get(mapChildRequestLeadRequest.get(leadRequestChild.Id).LeadRequestParent__c) ;
            if(reqParent != null){
                mapLeadRequestParent.get(mapChildRequestLeadRequest.get(leadRequestChild.Id).LeadRequestParent__c).TECH_ParentLeadRequestQuoteValue__c = '' ;        
                mapLeadRequestParent.get(mapChildRequestLeadRequest.get(leadRequestChild.Id).LeadRequestParent__c).TECH_MDP_LeadParent__c = '' ;                
            }
        }

        for (Request__c leadRequestChild : lstLeadRequestChild) { 
            Request__c reqParent = mapLeadRequestParent.get(mapChildRequestLeadRequest.get(leadRequestChild.Id).LeadRequestParent__c) ; 
            String quoteValue = '' ;
            System.debug('### MRA eadRequestChild.TECH_QuoteType__c== ' +leadRequestChild.TECH_QuoteType__c + '********' + leadRequestChild.TECH_TypeofTreaty__c) ;
            if(leadRequestChild.TECH_QuoteType__c != null){ 
                if(leadRequestChild.TECH_QuoteType__c == '1'){
                    System.debug('1');
                    if(leadRequestChild.FixedRate__c != null){
                       quoteValue = String.valueOf(leadRequestChild.FixedRate__c.setScale(6)) + '%';
                    }
                    else{
                        quoteValue = '';
                    }
                    if(leadRequestChild.MDP__c != null){
                        String lastMDP = reqParent.TECH_MDP_LeadParent__c ;
                        reqParent.TECH_MDP_LeadParent__c = (lastMDP ==null?'':lastMDP)+'(' + String.valueOf(leadRequestChild.Section__r.SectionNumber__c) + ') ' +(String.valueOf(separateurMillier(leadRequestChild.MDP__c)) == null?'':String.valueOf(separateurMillier(leadRequestChild.MDP__c)))+'**' ;
                    }
                }
                else if(leadRequestChild.TECH_QuoteType__c == '2'){
                    System.debug('2');
                    if(leadRequestChild.MinRate__c != null && leadRequestChild.MaxRate__c != null && leadRequestChild.ProvisionalRate__c != null){
                        quoteValue = String.valueOf(leadRequestChild.MinRate__c.setScale(6)) + '%/' + String.valueOf(leadRequestChild.MaxRate__c.setScale(6)) + '%/' + String.valueOf(leadRequestChild.ProvisionalRate__c.setScale(6))+'%';
                    }
                    else{
                        quoteValue = '';
                    }
                    if(leadRequestChild.MDP__c != null){
                        String lastMDP = reqParent.TECH_MDP_LeadParent__c ;
                        reqParent.TECH_MDP_LeadParent__c = (lastMDP ==null?'':lastMDP)+'(' + String.valueOf(leadRequestChild.Section__r.SectionNumber__c) + ') ' +(String.valueOf(separateurMillier(leadRequestChild.MDP__c)) == null?'':String.valueOf(separateurMillier(leadRequestChild.MDP__c)))+'**' ;
                    }
                }
                else if(leadRequestChild.TECH_QuoteType__c == '3'){
                    System.debug('3');
                    if(leadRequestChild.FlatPremium__c != null  ){
                        quoteValue = String.valueOf(separateurMillier(leadRequestChild.FlatPremium__c.setScale(0)));
                    }
                    else{
                        quoteValue = '';
                    }
                }
                else if(leadRequestChild.TECH_QuoteType__c == '4'){
                    if(leadRequestChild.MDP__c != null){
                        quoteValue = String.valueOf(separateurMillier(leadRequestChild.MDP__c.setScale(0)));
                    }
                    else{
                        quoteValue = '';
                    }
                }
                else if(leadRequestChild.TECH_QuoteType__c == '5'){
                    System.debug('5');
                    if(leadRequestChild.FixedCommission__c != null){
                        quoteValue = String.valueOf(leadRequestChild.FixedCommission__c.setScale(6)) + '%';
                    }
                    else{
                        quoteValue = '';
                    }
                }
                else if(leadRequestChild.TECH_QuoteType__c == '6'){
                    System.debug('6');
                    if(leadRequestChild.MinVarCommission__c != null && leadRequestChild.MaxVarCommission__c != null && leadRequestChild.ProvisionalCommission__c != null){
                        quoteValue = String.valueOf(leadRequestChild.MinVarCommission__c.setScale(6)) + '%/' + String.valueOf(leadRequestChild.MaxVarCommission__c.setScale(6)) + '%/' + String.valueOf(leadRequestChild.ProvisionalCommission__c.setScale(6))+'%';
                    }
                    else{
                        quoteValue = '';
                    }
                }
                else if(leadRequestChild.TECH_QuoteType__c == '8'){
                    System.debug('8');
                    if(leadRequestChild.MinPerHeadAmount__c != null && leadRequestChild.MaxPerHeadAmount__c != null && leadRequestChild.ProvisionalPerHeadPremium__c != null){
                        quoteValue = String.valueOf(separateurMillier(leadRequestChild.MinPerHeadAmount__c.setScale(0)))  + '/' + String.valueOf(separateurMillier(leadRequestChild.MaxPerHeadAmount__c.setScale(0)))  + '/' + String.valueOf(separateurMillier(leadRequestChild.ProvisionalPerHeadPremium__c.setScale(0)));
                    }
                    else{
                        quoteValue = '';
                    }
                    if(leadRequestChild.MDP__c != null){
                        String lastMDP = reqParent.TECH_MDP_LeadParent__c ;
                        reqParent.TECH_MDP_LeadParent__c = (lastMDP ==null?'':lastMDP)+'(' + String.valueOf(leadRequestChild.Section__r.SectionNumber__c) + ') ' +(String.valueOf(separateurMillier(leadRequestChild.MDP__c)) == null?'':String.valueOf(separateurMillier(leadRequestChild.MDP__c)))+'**' ;
                    }
                }
                else if(leadRequestChild.TECH_QuoteType__c == '9' && (leadRequestChild.TECH_TypeofTreaty__c == '3' || leadRequestChild.TECH_TypeofTreaty__c == '5')){ //RRA - ticket 1966 - 18032024
                    System.debug('9');
                    if(leadRequestChild.EstimatedInsurancePremium__c != null){
                        quoteValue = String.valueOf(separateurMillier(leadRequestChild.EstimatedInsurancePremium__c.setScale(0)));
                    }
                    else{
                        quoteValue = '';
                    }
                }
                else if(leadRequestChild.TECH_QuoteType__c == '9' && leadRequestChild.TECH_TypeofTreaty__c == '4'){
                    System.debug('10');
                    if(leadRequestChild.EstimatedReinsurancePremium__c != null){
                        quoteValue = String.valueOf(separateurMillier(leadRequestChild.EstimatedReinsurancePremium__c.setScale(0)));
                    }
                    else{
                        quoteValue = '';
                    }
                }
                else if(leadRequestChild.TECH_QuoteType__c == '10' || leadRequestChild.TECH_QuoteType__c == '7'){
                    System.debug('11S');
                    if(leadRequestChild.PerHeadPremium__c != null){
                        quoteValue = String.valueOf(separateurMillier(leadRequestChild.PerHeadPremium__c.setScale(0)));
                    }
                    else{
                        quoteValue = '';
                    }
                    if(leadRequestChild.MDP__c != null){
                        String lastMDP = reqParent.TECH_MDP_LeadParent__c ;
                        reqParent.TECH_MDP_LeadParent__c = (lastMDP ==null?'':lastMDP)+'(' + String.valueOf(leadRequestChild.Section__r.SectionNumber__c) + ') ' +(String.valueOf(separateurMillier(leadRequestChild.MDP__c)) == null?'':String.valueOf(separateurMillier(leadRequestChild.MDP__c)))+'**' ;
                    }
                }
            }
            String lastQuoteValue = reqParent.TECH_ParentLeadRequestQuoteValue__c;
            System.debug('### quoteValue =' +quoteValue) ;
            System.debug('### lastQuoteValue =' +lastQuoteValue) ;
            reqParent.TECH_ParentLeadRequestQuoteValue__c = (lastQuoteValue==null?'':lastQuoteValue)+'(' + String.valueOf(leadRequestChild.Section__r.SectionNumber__c) + ') ' + (quoteValue ==''?'Vide':quoteValue)+'**'  ;
            System.debug('### Quote =' + reqParent.TECH_ParentLeadRequestQuoteValue__c) ;
        }
        //lstLeadRequestsToDisplay.addAll(setLeadParentTodisplay) ;
        //************
        // MRA W-0935 - 25/07/2022 -END-
        // **********/

        for(Request__c leadRequest : mapLeadRequestParent.values()){
            if(leadRequest.ReinsurerStatus__c == 'Setup' || (leadRequest.ReinsurerStatus__c != 'Setup' && leadRequest.LastVersionSent__c == true && leadRequest.LastVersionAnswered__c == true)){
                lstLeadRequestsToDisplay.add(leadRequest);
            }
        }
        System.debug('### lstLeadRequestsToDisplay =' + lstLeadRequestsToDisplay.size()) ;
        mapResult.put('isDeactivatedProg', isDeactivatedProg); //RRA - ticket 585 - 06032023
        mapResult.put('isProgramHasSectionsRetainToLead', isProgramHasSectionsRetainToLead);
        mapResult.put('lstLeadRequest', lstLeadRequestsToDisplay);


        return mapResult;
        }
        // MRA W-0935 - 25/07/2022 -START Extra method for display -
        public static String separateurMillier(Decimal m){
            String ch = ',' ;
            //Integer n = Integer.valueOf(m) ; //Integer A 32-bit number that does not include a decimal point. Integers have a minimum value of -2,147,483,648 and a maximum value of 2,147,483,647.
            Long n = m.longValue(); // RRA ticket 1405 - 16012023
            if(n != null){
                     // Counting number of digits
                    Integer l = Integer.valueOf(Math.floor(Math.log10(n))) + 1;
                    String str = '';
                    Integer count = 0;
                    Long r = 0; // RRA ticket 1405 - 16012023
            
                    // Checking if number of digits is greater than 3
                    if (l > 3) {
            
                        for (Integer i = l - 1; i >= 0; i--) {
            
                            r = Math.mod(n,10);
                            n = n / 10;
                            count++;
                            if (((Math.mod(count,3)) == 0) && (i != 0)) {
            
                                // Parsing String value of Integer
                                str += String.valueOf(r);
            
                                // Appending the separator
                                str+=ch;
                            }
                            else
                                str += String.valueOf(r);
                        }
                        str = str.reverse() ;
                    }
            
                    // If digits less than equal to 3, directly print n
                    else
                        str += String.valueOf(n);

                    System.debug('#### = ' + str) ;
                    return String.valueOf(str) ;
            }
           return '' ;
        }
        // MRA W-0935 - 25/07/2022 -END-
   
    
        /**
        * @description Method to change Request Type
        * @param List<SObject> lstRecords
        * @return Map<String, Object>
        */
        @AuraEnabled
        public static Map<String, Object> toggleRequestType(List<SObject> lstRecords){
            Map<String, Object> mapResults = new Map<String, Object>();
            Set<Id> setLeadReqIds = new Set<Id>();
            Map<Id, String> mapLeadTypeByOriginalRequestId = new Map<Id, String>();
            List<Request__c> lstChildReq = new List<Request__c>();
            map<Id, Request__c> mapIdChildRequestParent = new map<Id, Request__c>();
            map<Id, Request__c> mapIdReqParentRequest = new map<Id, Request__c>();
    
            try{
                for(SObject record: lstRecords) {
                    String strReqType = (String) record.get('LeadType__c');
                    if(strReqType == '1'){
                        record.put('LeadType__c', '2');
                    }
                    else if(strReqType == '2'){
                        record.put('LeadType__c', '1');
                    }
    
                    setLeadReqIds.add((Id)record.get('Id'));
    
                    if(record.get('OriginalRequest__c') == null){
                        mapLeadTypeByOriginalRequestId.put((Id) record.get('Id'), (String) record.get('LeadType__c'));
                    }
                    else{
                        mapLeadTypeByOriginalRequestId.put((Id) record.get('OriginalRequest__c'), (String) record.get('LeadType__c'));
                    }
                    // RRA - ticket 1363 - 20122022 => Update Parent line
                    if (record.get('LeadType__c') == '2'){
                        record.put('LastVersionAnswered__c', true);
                        record.put('LastVersionSent__c', true);
                    }else if (record.get('LeadType__c') == '1'){
                        record.put('LastVersionAnswered__c', false);
                        record.put('LastVersionSent__c', false);
                    }
                }
    
                 // RRA - ticket 1363 - 20122022 => Create relation between Id Parent and his Resquest
                 List<Request__c> lstParentReq = [SELECT Id, LastVersionAnswered__c, LastVersionSent__c, ReinsurerStatus__c, LeadType__c FROM Request__c WHERE Id IN :setLeadReqIds];
                 for (Request__c reqParent : lstParentReq){
                     mapIdReqParentRequest.put(reqParent.Id, reqParent);
                 }

                Set<Id> setChildLeadReq = new Set<Id>();
                for(LeadRequestSelection__c leadReqSelection : [SELECT Id, LeadRequestChild__c, LeadRequestParent__c FROM LeadRequestSelection__c WHERE LeadRequestParent__c IN :setLeadReqIds]){
                    setChildLeadReq.add(leadReqSelection.LeadRequestChild__c);
                    // RRA - ticket 1363 - 20122022 => Create relation between Id Child and Request Parent
                    mapIdChildRequestParent.put(leadReqSelection.LeadRequestChild__c, mapIdReqParentRequest.get(leadReqSelection.LeadRequestParent__c));
                }
    
                if(setChildLeadReq.size() > 0){
                    for(Request__c childReq: [SELECT Id, LeadType__c, OriginalRequest__c,TECH_ParentLeadRequestQuoteValue__c,TECH_MDP_LeadParent__c FROM Request__c WHERE Id IN :setChildLeadReq]){ //MRA W-935 22/08/2022
                        if(childReq.LeadType__c == '1'){
                            childReq.LeadType__c = '2';
                        }
                        else if(childReq.LeadType__c == '2'){
                            childReq.LeadType__c = '1';
                        }

                        // RRA - ticket 1363 - 20122022 => Update value LastVersionSent__c and LastVersionAnswered__c of Child Request id LeadType is Simulated Or Definitif
                        if (mapIdChildRequestParent.get(childReq.Id).LeadType__c == '2' && mapIdChildRequestParent.get(childReq.Id).ReinsurerStatus__c == 'Setup'){
                            childReq.LastVersionAnswered__c = false;
                            childReq.LastVersionSent__c = false;
                        }else if (mapIdChildRequestParent.get(childReq.Id).LeadType__c == '1' && mapIdChildRequestParent.get(childReq.Id).ReinsurerStatus__c == 'Setup'){
                            childReq.LastVersionAnswered__c = true;
                            childReq.LastVersionSent__c = true;
                        }

                        //MRA W-935 22/08/2022 : START
                        if(childReq.TECH_ParentLeadRequestQuoteValue__c != '' || childReq.TECH_MDP_LeadParent__c != '' ){
                            childReq.TECH_ParentLeadRequestQuoteValue__c = '' ;
                            childReq.TECH_MDP_LeadParent__c = '' ;
                        }
                        //MRA W-935 22/08/2022 : END
                        lstRecords.add(childReq);
    
                        if(childReq.OriginalRequest__c == null){
                            mapLeadTypeByOriginalRequestId.put(childReq.Id, childReq.LeadType__c);
                        }
                        else{
                            mapLeadTypeByOriginalRequestId.put(childReq.Id, childReq.LeadType__c);
                        }
                    }
                }
    
                List<Request__c> lstAllRequestVersion = [SELECT Id, Name,TECH_ParentLeadRequestQuoteValue__c,OriginalRequest__c, QuoteType__c FROM Request__c WHERE Id IN :mapLeadTypeByOriginalRequestId.keySet() OR OriginalRequest__c IN :mapLeadTypeByOriginalRequestId.keySet()]; ////MRA W-935 22/08/2022 
    
                for(Request__c request : lstAllRequestVersion){
                    if(request.OriginalRequest__c == null){
                        request.LeadType__c = mapLeadTypeByOriginalRequestId.get(request.Id);
                    }
                    else{
                        request.LeadType__c = mapLeadTypeByOriginalRequestId.get(request.OriginalRequest__c);
                    }
                    ////MRA W-935 22/08/2022 : START
                    if(request.TECH_ParentLeadRequestQuoteValue__c != '' || request.TECH_MDP_LeadParent__c != ''){
                        request.TECH_ParentLeadRequestQuoteValue__c = '' ;
                        request.TECH_MDP_LeadParent__c = '' ;
                    }
                    //MRA W-935 22/08/2022 : END
                }
    
                if(lstAllRequestVersion.size() > 0){
                    update lstAllRequestVersion;
                }
    
                if(lstRecords.size() > 0){
                    update lstRecords;
                }
                  if(lstChildReq.size() > 0){
                    update lstChildReq;
                }
    
                mapResults.put('Success', 'Records successfully Updated.');
            }
            catch(Exception ex){
                mapResults.put('Error', ex.getMessage());
            }
            return mapResults;
        }
    
        /**
        * @description Method to check if lead info is disabled
        * @param Id programId
        * @return Boolean
        */
        @AuraEnabled
        public static Boolean disableLeadInfo(Id programId){
            Program__c program = [SELECT Id, Name, TECH_ShowClosePreviousPhaseBtn__c FROM Program__c WHERE Id = :programId];
            //if close previous phase button is enabled in signing ---> should display information for lead --- not disable
            //if close previous phase button is disabled in signing ----> should not display information for lead(must click on Reopen Previous Phase to display information) --- disable
            String showPreviousPhaseBtn = program.TECH_ShowClosePreviousPhaseBtn__c;
            Boolean disableLeadInfo = false;
    
            if(showPreviousPhaseBtn == '1'){
                disableLeadInfo = false;
            }
            else if(showPreviousPhaseBtn == '2'){
                disableLeadInfo = true;
            }
    
            return disableLeadInfo;
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
        * RRA - Ticket 585 - 16032023 
        * @description Method to get Program details
        * @param Id programId
        * @return Program__c
        */
        /*@AuraEnabled
        public static Boolean checkErrorMessage(List<Id> lstTreatyIds){
            List<String> lstStatusSection = new List<String>();
            Boolean isErrorMessage = false;
            for (Section__c sec : [SELECT Id, Name, Treaty__r.Status__c, Status__c FROM Section__c WHERE Treaty__c =:lstTreatyIds]){
                lstStatusSection.add(sec.Treaty__r.Status__c + '_' + sec.Status__c);
            }
            if (lstStatusSection.contains('1_2') || lstStatusSection.contains('2_1') || lstStatusSection.contains('2_2')){
                isErrorMessage = true;
            }
            return isErrorMessage;
        }*/
    }