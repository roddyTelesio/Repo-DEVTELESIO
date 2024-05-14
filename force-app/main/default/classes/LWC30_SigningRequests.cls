public with sharing class LWC30_SigningRequests {
    /**************************************************************************************
    -- - Author        : Spoon Consulting
    -- - Description   : Class for lwc30SigningRequests
    --
    -- Maintenance History:
    -- Date         Name  Version  Remarks
    -- -----------  ----  -------  -------------------------------------------------------
    -- 17-MAR-2020  MBE    1.0     Initial Version
    -- 08-APR-2020  SAU    1.1     Ask for validation
    -- 31-JUL-2020  MBE    1.2     Check if Program has Lead Requests Not Answered
    -- 05-AUG-2020  SAU    1.3     Add related Lead/Placement request to signing request
    -- 12-AUG-2020  MBE    1.4     Close Previous Phase - To copy Original Request only
    -- 01-SEP-2020  SAU    1.5     Save updates on last version of request
    -- 01-SEP-2020  SAU    1.5     Conditions for Close & Notify Web XL
    -- 03-SEP-2020  SAU    1.6     Lead status / Placement status set to closed/ setup
    -- 25-SEP-2020  SAU    1.7     checkIfLeadReqAreAnswered - check if no Lead present
    -- 11-NOV-2020  NBI    1.8     Signed Share not updating
    -- 11-DEC-2020  NBI    1.9     Changes for Pool W-0762/W-0831
    -- 16-DEC-2020  NBI    2.0     Placement and Lead changes in Written Share W-0833
    -- 23-DEC-2020  NBI    2.1     W-0829 : IDENTICAL RENEW - tarification Lead non modifiable
    -- 23-FEB-2021  NBI    2.2     W-0888 : Signing Premium - le calcul de conversion n'est pas le bon
    -- 09-MAR-2021  NBI    2.3     W-0892 : Les requêtes de Pool pour les traités non leadés ne devraient pas apparaitre au sein du tableau de signing
    -- 30-MAR-2021  MBE    2.4     W-0891 - ODS - Respond (Quote/Leads/Placement) OnBehalf are false in database - To set these fields to false when close previous phase
    -- 21-APR-2021  MBE    2.5     W-0927 - Signing - Comportement anormal du au filtrage
    -- 21-May-2021  MBE    2.6     W-0974 - Bug bloquant Prod - Impossibilité de créer une Lead request - TECH_Actor2Id__c
    -- 08-JUL-2021  NBI    2.7     W-0992: Third Party Management
    -- 13-JUN-2021  MBE    2.8     W-0894 - ODS - TECH_SentByUser__c seems empty after a modification of a lead request
    -- 02-AUG-2021  MBE    2.9     W-1000 - Signing - Impossibilité de modifier les champs modifiables du signing sur des programmes migrés ou renouvelés à l'identique à partir de données migrées
    -- 26-AUG-2021  MBE    3.0     SOQL Injection for getLookupAccountField()
    -- 27-AUG-2021  MBE    3.1     Remove unused value for mapResult
    -- 31-AUG-2021  MBE    3.2     W-1000 - Signing - Impossibilité de modifier les champs modifiables du signing sur des programmes migrés ou renouvelés à l'identique à partir de données migrées
    -- 23-SEP-2021  MBE    3.3     W-1012 - Signing - Filtre à enlever sur les champs risk carrier et financial entity pour un user avec le profil AGRe Admin user	
    -- 19-OCT-2021  MBE    3.4     W-1034 - tailles limite de documents envoyés
    -- 19-NOV-2021  MBE    3.5     W-1037 - message d'erreur à l'envoie des quotes
    -- 29-DEC-2021  RRA    3.6     W-1072 - Hotfix - Premium du signing doublé en cas de co-leaders
    -- 25-MAY-2022  AMI    3.7     W-1105 - Signing - Champ Premium Currency du programme vide
    -- 27-MAY-2022  AMI    3.8     W-1103 - Signing - Reprise des valeurs par défaut des champs collateral, signatories et claim contacts dans un programme renouevelé
    --------------------------------------------------------------------------------------
    **************************************************************************************/
        /**
        * @description Method to close phase of signing
        * @param Id programId
        * @return Map<String, Object>
        */
        @AuraEnabled
        public static Map<String, Object> closePreviousPhase(Id programId) {
        
            system.debug('##LWC30_SigningRequests - closePreviousPhase - programId ' + programId);
            Map<String, Object> mapResults = new Map<String, Object>();
            Map<String, Id> mapRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectRequest});
            String recordTypeIdLead = mapRecTypeId.get(AP_Constant.reqRTLead);
            String recordTypeIdPlacement = mapRecTypeId.get(AP_Constant.reqRTPlacement);
            String recordTypeIdSigning = mapRecTypeId.get(AP_Constant.reqRTSigning);
            List<Request__c> lstSigningRequests = new List<Request__c>();
            Set<Id> setSelectedTreatyId = new Set<Id>();
            Set<String> setExistedSigningReqId = new Set<String>();
            Set<Id> setPoolRequestIdAlreadyExisted = new Set<Id>();
            List<Request__c> lstSigningRequestsToInsert = new List<Request__c>();
            List<Request__c> lstRequestToUpdate = new List<Request__c>();
            Map<Id, Request__c> mapRelatedLeadPlacement = new Map<Id, Request__c>();
            List<Request__c> lstExistedSigningRequest = new List<Request__c>();
            List<Request__c> lstExistedSigningRequestToDelete = new List<Request__c>();

            //AMI 27/05/22 : W-1103
            //string to determine if program has been renewed and is of type "standard" or "negociation"
            string eligibleRenewedProgId = '';

            //map that holds info for previous underwriting year for signed requests of a reinsurer
            map <string,Request__c> previousReinsurerInfo = new  map <string,Request__c>();

            //list "signatories to recreate from signing from preceding year
            //MRA 19/05/23 - Contact Signatory Rebuild - START
            Map <Id,List<ContactReinsurerProgramRelation__c>> mapListToInsert = new Map<Id,List<ContactReinsurerProgramRelation__c>>();

            //RRA - ticket 1103 - 27122022 - avoid duplication of creation signatory's contact 
            List<String> lstReinsurerId = new List<String>();
            try{
                Program__c program = new Program__c();
                program.Id = programId;
                program.TECH_ShowClosePreviousPhaseBtn__c = '2';
                update program;

                //AMI 27/05/22 : W-1103
                //Check if program has been renewed and check if type if of "standard" or "negociation"
                for(Program__c prog : [select id,RenewedFromProgram__c, TypeOfRenew__c 
                                        from Program__c 
                                        where Id = :programId]){
                    if(string.isNotBlank(prog.RenewedFromProgram__c) && (prog.TypeOfRenew__c == 'Standard Renew' || prog.TypeOfRenew__c == 'LTA/TR Renegotiation')){
                        eligibleRenewedProgId = prog.RenewedFromProgram__c;
                    }
                }

                for(Request__c existedSigningReq : [SELECT Id, Name, Reinsurer__c, Broker__c, Treaty__c, Pool__c, Broker__r.IsActive__c, Reinsurer__r.IsActive__c, Treaty__r.PremiumDeposit__c, Treaty__r.Deductions__c, Program__r.LossDepositLevel__c, PremiumDeposit__c, LossDeposit__c
                                                    FROM Request__c
                                                    WHERE Program__c = :programId
                                                    AND RecordTypeId = :recordTypeIdSigning
                                                    AND Program__c != NULL]){
                    Boolean activeReq = false;
    
                    if(existedSigningReq.Pool__c != null){
                        activeReq = true;
                    }
                    else if(existedSigningReq.Broker__c != null && (existedSigningReq.Broker__r.IsActive__c == TRUE && existedSigningReq.Reinsurer__r.IsActive__c == TRUE)){
                        activeReq = true;
                    }
                    else if(existedSigningReq.Broker__c == null && existedSigningReq.Reinsurer__r.IsActive__c == TRUE){
                        activeReq = true;
                    }
    
                    if(activeReq == true){
                        lstExistedSigningRequest.add(existedSigningReq);
                    }
                    else{
                        lstExistedSigningRequestToDelete.add(existedSigningReq);
                    }
                }
    
                Map<String, Id> mapSigningIdByTreatyPool = new Map<String, Id>();
    
                for(Request__c signingRequest : lstExistedSigningRequest){
                    if(signingRequest.Broker__c != null && signingRequest.Reinsurer__c != null) {
                        setExistedSigningReqId.add(signingRequest.Treaty__c + '-' + signingRequest.Broker__c + '-' + signingRequest.Reinsurer__c);
                    }
                    else if(signingRequest.Reinsurer__c != null){
                        setExistedSigningReqId.add(signingRequest.Treaty__c + '-'  + signingRequest.Reinsurer__c);
                    }
                    else if(signingRequest.Pool__c != null){
                        setExistedSigningReqId.add(signingRequest.Treaty__c + '-' + signingRequest.Pool__c);
                        String strTreatyPool = signingRequest.Treaty__c + '-' + signingRequest.Pool__c;
                        mapSigningIdByTreatyPool.put(strTreatyPool, signingRequest.Id);
                    }
                }
                System.debug('setExistedSigningReqId == ' + setExistedSigningReqId);
                List<String> lstRequestFields = AP_Constant.getCreatableFieldsByObjName(AP_Constant.sObjectRequest);
                String strRequestFields = String.join(lstRequestFields , ', ');
    
                //Get parent Lead Request for selected program
                String queryLeadRequest = 'select Id, TECH_Layer__c, TECH_TreatyName__c, TECH_SectionName__c, '
                        + 'TECH_BrokerName__c, TECH_ProgramName__c, TECH_ReinsurerName__c, TECH_UWyear__c, SigningRegionalManager__r.Email,'
                        + 'Program__r.LossDepositMode__c, Program__r.LossDeposit__c, Treaty__r.LossDepositMode__c, Treaty__r.LossDeposit__c,'
                        + 'Treaty__r.TypeofTreaty__c, Treaty__r.PremiumDeposit__c, Program__r.LossDepositLevel__c, '
                        + 'Broker__r.IsActive__c, Reinsurer__r.IsActive__c,Treaty__r.Deductions__c, Treaty__r.Status__c, Section__r.Status__c, ' 
                        +  strRequestFields
                        + ' from Request__c where (Program__c = :programId AND RecordTypeId = :recordTypeIdLead AND Program__c != NULL AND Reinsurer__c != NULL AND OriginalRequest__c = NULL) ';
    
                List<Request__c> lstLeadRequest = Database.query(queryLeadRequest);
    
                System.debug('lstLeadRequest == '+ lstLeadRequest);
                System.debug('lstLeadRequest.size == '+ lstLeadRequest.size());

                for(Request__c leadRequest : lstLeadRequest){
                    Boolean brokerReinActive = false;
    
                    if(leadRequest.Broker__c != null && (leadRequest.Broker__r.IsActive__c == TRUE && leadRequest.Reinsurer__r.IsActive__c == TRUE)){
                        brokerReinActive = true;
                    }
                    else if(leadRequest.Broker__c == null && leadRequest.Reinsurer__r.IsActive__c == TRUE){
                        brokerReinActive = true;
                    }
    
                    if(brokerReinActive == true){
                        setSelectedTreatyId.add(leadRequest.Treaty__c);
                        if(leadRequest.Reinsurer__c != null){
                            Request__c signingRequest = leadRequest.clone(false,true, false,false);
                            signingRequest.RecordTypeId = recordTypeIdSigning;
                            signingRequest.TECH_PhaseType__c = '6';
                            signingRequest.ReinsurerStatus__c = 'Setup';
                            signingRequest.QuoteOnBehalf__c = false;
                            signingRequest.LeadOnBehalf__c = false;
                            signingRequest.PlacementOnBehalf__c = false;
                            signingRequest.TECH_RelatedLeadPlacementRequest__c = leadRequest.Id;
                            lstSigningRequests.add(signingRequest);
                            mapRelatedLeadPlacement.put(leadRequest.Id, leadRequest);
                        }
                    }
                }
                System.debug('lstSigningRequests from lead == '+ lstSigningRequests.size());
                System.debug('lstSigningRequests from lead size== '+ lstSigningRequests.size());
                //update status
                String queryAllLeadRequest = 'select Id, TECH_Layer__c, TECH_TreatyName__c, TECH_SectionName__c, '
                        + 'TECH_BrokerName__c, TECH_ProgramName__c, TECH_ReinsurerName__c, TECH_UWyear__c, SigningRegionalManager__r.Email,'
                        + 'Program__r.LossDepositMode__c, Program__r.LossDeposit__c, Treaty__r.LossDepositMode__c, Treaty__r.LossDeposit__c, Treaty__r.TypeofTreaty__c, Treaty__r.PremiumDeposit__c, Program__r.LossDepositLevel__c, '
                        + 'Broker__r.IsActive__c, Reinsurer__r.IsActive__c,Treaty__r.Deductions__c, Treaty__r.Status__c, Section__r.Status__c,' 
                        +  strRequestFields
                        + ' from Request__c where (Program__c = :programId AND RecordTypeId = :recordTypeIdLead AND Program__c != NULL) ';
                List<Request__c> lstAllActiveInactiveLeadRequest = Database.query(queryAllLeadRequest);
    
                List<Request__c> lstAllLeadRequest = new List<Request__c>();
    
                for(Request__c leadRequest : lstAllActiveInactiveLeadRequest){
                    Boolean brokerReinActive = false;
    
                    if(leadRequest.Broker__c != null && (leadRequest.Broker__r.IsActive__c == TRUE && leadRequest.Reinsurer__r.IsActive__c == TRUE)){
                        brokerReinActive = true;
                    }
                    else if(leadRequest.Broker__c == null && leadRequest.Reinsurer__r.IsActive__c == TRUE){
                        brokerReinActive = true;
                    }
    
                    if(brokerReinActive == true){
                        leadRequest.LeadStatus__c = '6';
                        lstAllLeadRequest.add(leadRequest);
                        lstRequestToUpdate.add(leadRequest);
                    }
                }
    
                //Get parent Placement Request for selected program
                String queryPlacementRequest = 'select Id, TECH_Layer__c, TECH_TreatyName__c, TECH_SectionName__c, ' 
                        + 'TECH_BrokerName__c, TECH_ProgramName__c, TECH_ReinsurerName__c, TECH_UWyear__c, SigningRegionalManager__r.Email,'
                        + 'Program__r.LossDepositMode__c, Program__r.LossDeposit__c, Treaty__r.LossDepositMode__c, Treaty__r.LossDeposit__c, Treaty__r.TypeofTreaty__c, Treaty__r.PremiumDeposit__c, Program__r.LossDepositLevel__c, Treaty__r.Status__c, Section__r.Status__c, '
                        + 'Broker__r.IsActive__c, Reinsurer__r.IsActive__c,Treaty__r.Deductions__c, '
                        +  strRequestFields
                        + ' from Request__c where (Program__c = :programId AND RecordTypeId = :recordTypeIdPlacement AND Program__c != NULL) ';
    
                List<Request__c> lstPlacementRequest = Database.query(queryPlacementRequest);

                System.debug('lstPlacementRequest == '+ lstPlacementRequest);
                System.debug('lstPlacementRequest size== ' + lstPlacementRequest.size());
    
                for(Request__c placementRequest : lstPlacementRequest){
                    Boolean brokerReinActive = false;
    
                    if(placementRequest.Broker__c != null && (placementRequest.Broker__r.IsActive__c == TRUE && placementRequest.Reinsurer__r.IsActive__c == TRUE)){
                        brokerReinActive = true;
                    }
                    else if(placementRequest.Broker__c == null && placementRequest.Reinsurer__r.IsActive__c == TRUE){
                        brokerReinActive = true;
                    }
    
                    if(brokerReinActive == true){
                        //added by SAU
                        placementRequest.PlacementStatus__c = '6';
                        lstRequestToUpdate.add(placementRequest);
                        if(placementRequest.ReinsurerStatus__c == 'Answered' && placementRequest.OriginalRequest__c == null){
                            Request__c signingRequest = placementRequest.clone(false,true, false,false);
                            signingRequest.RecordTypeId = recordTypeIdSigning;
                            signingRequest.TECH_PhaseType__c = '6';
                            signingRequest.ReinsurerStatus__c = 'Setup';
                            signingRequest.QuoteOnBehalf__c = false;
                            signingRequest.LeadOnBehalf__c = false;
                            signingRequest.PlacementOnBehalf__c = false;
                            signingRequest.VersionMajor__c = 0; // RRA - 02/06/2022 - 1104
                            signingRequest.VersionMinor__c = 0; // RRA - 02/06/2022 - 1104
                            signingRequest.CommentsResponse__c = null; // RRA - 02/06/2022 - 1104
                            signingRequest.TECH_RelatedLeadPlacementRequest__c = placementRequest.Id;
                            lstSigningRequests.add(signingRequest);
                            mapRelatedLeadPlacement.put(placementRequest.Id, placementRequest);
                        }
                    }
                }

                System.debug('lstSigningRequests from placement== ' + lstSigningRequests);
                System.debug('lstSigningRequests from placement size == ' + lstSigningRequests.size());
    
                Map<Id,Treaty__c> mapTreatyIdToTreatyType = new Map<Id,Treaty__c>();
    
                for(Treaty__c treaty :  [SELECT Id, Name, Deductions_Perc__c FROM Treaty__c WHERE Program__c = :programId]){
                    mapTreatyIdToTreatyType.put(treaty.Id, treaty);
                }
    
                List<PoolTreatySection__c> lstPoolTreatySections = [SELECT Id, Pool__r.ShareRate__c, Pool__c, Pool__r.Name, TreatyShareRate__c, Treaty__c, TreatyIsSelected__c
                                                                    FROM PoolTreatySection__c
                                                                    WHERE Treaty__c IN :setSelectedTreatyId
                                                                    AND TreatyIsSelected__c = TRUE];
    
                Map<String, Decimal> mapTreatyShareRateByPool = new Map<String, Decimal>();
                System.debug('lstPoolTreatySections.size == ' + lstPoolTreatySections.size());
                System.debug('lstPoolTreatySections == ' + lstPoolTreatySections);
                for(PoolTreatySection__c poolTreatySection: lstPoolTreatySections){
                    Request__c signingPoolRequest = new Request__c();
                    signingPoolRequest.Program__c = programId;
                    signingPoolRequest.Treaty__c = poolTreatySection.Treaty__c;
                    signingPoolRequest.WrittenShare__c = poolTreatySection.TreatyShareRate__c;
                    signingPoolRequest.SignedShare__c = poolTreatySection.TreatyShareRate__c;
                    signingPoolRequest.TECH_PhaseType__c = '6';
                    signingPoolRequest.RecordTypeId = recordTypeIdSigning;
                    signingPoolRequest.Pool__c = poolTreatySection.Pool__c;
                    lstSigningRequests.add(signingPoolRequest);
    
                    String strTreatyPool = poolTreatySection.Treaty__c + '-' + poolTreatySection.Pool__c;
                    mapTreatyShareRateByPool.put(strTreatyPool, poolTreatySection.TreatyShareRate__c);
                }
                List<Request__c> lstOriginalReqToUpdate = new List<Request__c>();
                //MBE - 10/12/2020 - W-0831 - Suppression pool ou modification de pool share traité --> tableau signing non MàJ

                System.debug('lstSigningRequests ok passe=='+ lstSigningRequests);
                for(Request__c newSigningReq : lstSigningRequests){
                    newSigningReq.Accept__c = false;
                    Treaty__c treatyObj = mapTreatyIdToTreatyType.get(newSigningReq.Treaty__c);
                    Request__c reqLeadPlacement = mapRelatedLeadPlacement.get(newSigningReq.Id);
                    
                    if(newSigningReq.Pool__c == null){
                        if(newSigningReq.PremiumDeposit__c == null && newSigningReq.Treaty__r.PremiumDeposit__c != null){
                            if(newSigningReq.Treaty__r.PremiumDeposit__c == 'No'){
                                newSigningReq.PremiumDeposit__c = '2';
                            }
                            else if(newSigningReq.Treaty__r.PremiumDeposit__c == 'Yes'){
                                newSigningReq.PremiumDeposit__c = '1';
                            }
                        }
    
                        newSigningReq.LossDeposit__c = newSigningReq.Program__r.LossDeposit__c;
    
                        if(newSigningReq.Program__r.LossDepositLevel__c != null && newSigningReq.Program__r.LossDepositLevel__c == 'Treaty'){
                            newSigningReq.LossDeposit__c = newSigningReq.Treaty__r.LossDeposit__c;
                        }
    
                        if(newSigningReq.Treaty__r.Deductions__c == '2'){
                            newSigningReq.Deductions__c = 0;
                        }
                    }

                    System.debug('Reinsurer__c ==' + newSigningReq.Reinsurer__c);
                    
                    if(newSigningReq.Broker__c != null && newSigningReq.Reinsurer__c != null){
                        //for Lead Request and Placement Request - broker and reinsurer pair
                        if(!setExistedSigningReqId.contains(newSigningReq.Treaty__c + '-' + newSigningReq.Broker__c + '-' + newSigningReq.Reinsurer__c)){
                            newSigningReq.LastSentDate__c = null;
                            newSigningReq.ExpectedResponseDate__c = null;
                            newSigningReq.ResponseDate__c = null;
                            newSigningReq.VersionMajor__c = 0; // RRA - 02/06/2022 - 1104
                            newSigningReq.VersionMinor__c = 0; // RRA - 02/06/2022 - 1104
                            newSigningReq.CommentsResponse__c = null; // RRA - 02/06/2022 - 1104
                            newSigningReq.RiskCarrier__c = newSigningReq.Reinsurer__c;
                            newSigningReq.Deductions__c = treatyObj.Deductions_Perc__c;
                            newSigningReq.TECH_Actor2Id__c = null;
                            newSigningReq.RetrocessionBrokerage__c = 0; //RRA - 1090
                            newSigningReq.SentBy__c = null;
                            lstSigningRequestsToInsert.add(newSigningReq);
                        }
                        System.debug('setExistedSigningReqId==' + setExistedSigningReqId);
                    } 
                    else if(newSigningReq.Reinsurer__c != null){
                        System.debug('mandalo reins' );
                        System.debug('setExistedSigningReqId mandalo== ' + setExistedSigningReqId);
                        System.debug('newSigningReq.Treaty__c mandalo== ' + newSigningReq.Treaty__c);
                        System.debug('newSigningReq.Reinsurer__c mandalo== ' + newSigningReq.Reinsurer__c);
                        //for Lead Request and Placement Request - only reinsurer
                        if(!setExistedSigningReqId.contains(newSigningReq.Treaty__c + '-' + newSigningReq.Reinsurer__c)) {
                            newSigningReq.LastSentDate__c = null;
                            newSigningReq.ExpectedResponseDate__c = null;
                            newSigningReq.ResponseDate__c = null;
                            newSigningReq.VersionMajor__c = 0; // RRA - 02/06/2022 - 1104
                            newSigningReq.VersionMinor__c = 0; // RRA - 02/06/2022 - 1104
                            newSigningReq.CommentsResponse__c = null; // RRA - 02/06/2022 - 1104
                            newSigningReq.RiskCarrier__c = newSigningReq.Reinsurer__c;
                            newSigningReq.Deductions__c = treatyObj.Deductions_Perc__c;
                            newSigningReq.RetrocessionBrokerage__c = 0; //RRA - 1090
                            newSigningReq.TECH_Actor2Id__c = null;
                            newSigningReq.SentBy__c = null;
                            lstSigningRequestsToInsert.add(newSigningReq);
                        }
                        System.debug('lstSigningRequestsToInsert mandalo 11== ' + lstSigningRequestsToInsert);
                    }else if(newSigningReq.Pool__c != null){
                        //for Pool - contain unique Treaty and Pool
                        if(!setExistedSigningReqId.contains(newSigningReq.Treaty__c + '-' + newSigningReq.Pool__c)){
                            newSigningReq.LastSentDate__c = null;
                            newSigningReq.ExpectedResponseDate__c = null;
                            newSigningReq.ResponseDate__c = null;
                            newSigningReq.VersionMajor__c = 0; // RRA - 02/06/2022 - 1104
                            newSigningReq.VersionMinor__c = 0; // RRA - 02/06/2022 - 1104
                            // newSigningReq.Deductions__c = treatyObj.Deductions_Perc__c;
                            newSigningReq.RetrocessionBrokerage__c = 0; //RRA - 1090
                            newSigningReq.LossDepositMode__c = '';
                            newSigningReq.ReinsurerStatus__c = 'Setup';
                            newSigningReq.TECH_Actor2Id__c = null;
                            newSigningReq.SentBy__c = null;
                            lstSigningRequestsToInsert.add(newSigningReq);
                        }else{
                            //update Signing Request with new value TreatyShareRate__c
                            String strTreatyPool = newSigningReq.Treaty__c + '-' + newSigningReq.Pool__c;
                            if(mapTreatyShareRateByPool.containsKey(strTreatyPool) && mapSigningIdByTreatyPool.containsKey(strTreatyPool)){
                                newSigningReq.Id = mapSigningIdByTreatyPool.get(strTreatyPool);
                                newSigningReq.WrittenShare__c = mapTreatyShareRateByPool.get(strTreatyPool);
                                newSigningReq.SignedShare__c = mapTreatyShareRateByPool.get(strTreatyPool);
                                setPoolRequestIdAlreadyExisted.add(mapSigningIdByTreatyPool.get(strTreatyPool));
                                lstRequestToUpdate.add(newSigningReq);
                                
                                system.debug('##LWC30_SigningRequests - closePreviousPhase - lstRequestToUpdate  11 ' + lstRequestToUpdate );
                            }
                        }
                    }
                }

                system.debug('##LWC30_SigningRequests - closePreviousPhase - lstSigningRequestsToInsert 11 ' + lstSigningRequestsToInsert);
                try{
                    insert lstSigningRequestsToInsert;
                    System.debug('lstSigningRequestsToInsert mandalo 33== ' + lstSigningRequestsToInsert);
                }catch (Exception ex) {
                    System.debug('Error = ' + ex.getMessage());
                }
                
                //RRA - ticket 1554 - 18082023 - keep data selected on signing Request for LossDepositMode
                List <Request__c> lstReq = [SELECT Id, OriginalRequest__c,  LossDepositMode__c, Program__r.LossDepositMode__c, Treaty__r.LossDepositMode__c, Reinsurer__r.name from Request__c WHERE Program__c =:programId AND OriginalRequest__c = null AND RecordType.Name = 'Signing Request'];
                List<Request__c> lstReqUpdateLossDeposite = new List<Request__c>();
                System.debug('lstReq = ' + lstReq);
                System.debug('lstReqSIze = ' + lstReq.size());
                for(Request__c req : lstReq){
                    if (req.LossDepositMode__c != null){
                        if (req.Program__r.LossDepositMode__c.contains(req.LossDepositMode__c)){
                            req.LossDepositMode__c = req.Program__r.LossDepositMode__c;
                        }else{
                            req.LossDepositMode__c = req.LossDepositMode__c;
                        }
                        lstReqUpdateLossDeposite.add(req);
                    }
                }
                if (lstReqUpdateLossDeposite.size()>0){
                    update lstReqUpdateLossDeposite;
                }

               system.debug('##LWC30_SigningRequests - closePreviousPhase - lstSigningRequestsToInsert 22' + lstSigningRequestsToInsert);
               system.debug('##LWC30_SigningRequests - closePreviousPhase - lstSigningRequests  22 ' + lstSigningRequests );
                if(mapRelatedLeadPlacement.keySet().size() > 0){
                    for(Request__c existingRequest : [SELECT Id, WrittenShare__c, TECH_RelatedLeadPlacementRequest__c FROM Request__c WHERE TECH_RelatedLeadPlacementRequest__c IN :mapRelatedLeadPlacement.keySet()]){
                        if(existingRequest.WrittenShare__c != mapRelatedLeadPlacement.get(existingRequest.TECH_RelatedLeadPlacementRequest__c).WrittenShare__c){
                            existingRequest.WrittenShare__c =  mapRelatedLeadPlacement.get(existingRequest.TECH_RelatedLeadPlacementRequest__c).WrittenShare__c;
                            lstRequestToUpdate.add(existingRequest);
                        }
                    }
                }
                //RRA - ticket 1590 - 29092023
                if(lstRequestToUpdate.size() > 0){
                    update lstRequestToUpdate;
                }
                
    
                system.debug('##LWC30_SigningRequests - closePreviousPhase - mapRelatedLeadPlacement ' + mapRelatedLeadPlacement);

                    //RRA - ticket 1103 - 27122022 - Get only the list of Reinsurer(s) created in previous year 
                if(string.isNotBlank(programId)){
                    system.debug('##LWC30_SigningRequests - closePreviousPhase - ok programId ');
                    for(Request__c req : [SELECT id,Reinsurer__c, Reinsurer__r.IsActive__c,Collateral_Provider_City__c, Collateral_provider_Code__c,Collateral_provider_Name__c,DescriptionReinsurerLimitColl__c, Type_of_Code__c,Claims_contact__c 
                                            FROM Request__c 
                                            WHERE Program__c =:programId 
                                            AND OriginalRequest__c = null 
                                            AND Reinsurer__c != null 
                                            AND Reinsurer__r.IsActive__c = true 
                                            AND RecordTypeId =: recordTypeIdSigning]){ 
                            lstReinsurerId.add(req.Reinsurer__c);
                    }
                }
                system.debug('##LWC30_SigningRequests - closePreviousPhase -  programId ' + programId);
                system.debug('##LWC30_SigningRequests - closePreviousPhase - lstReinsurerId ' + lstReinsurerId);

                //AMI 27/05/22 : W-1103
                //if program has been renewed, get all previous info from signing from preceding year
                if(string.isNotBlank(eligibleRenewedProgId) && lstReinsurerId != null && !lstReinsurerId.isEmpty()){
                    for(Request__c req : [select id,Reinsurer__c,Reinsurer__r.IsActive__c,Collateral_Provider_City__c,
                                            Collateral_provider_Code__c,Collateral_provider_Name__c,DescriptionReinsurerLimitColl__c,
                                            Type_of_Code__c,Claims_contact__c
                                            from Request__c
                                            where Program__c = :eligibleRenewedProgId
                                            and RecordTypeId = :recordTypeIdSigning
                                            and OriginalRequest__c = null
                                            and Reinsurer__c IN:lstReinsurerId //RRA - ticket 1103 - 27122023
                                            and Reinsurer__c !=null
                                            and Reinsurer__r.IsActive__c = true]){
                        previousReinsurerInfo.put(req.Reinsurer__c,req);
                    }
                }//end if eligibleRenewedProgId
                system.debug('##LWC30_SigningRequests - closePreviousPhase - previousReinsurerInfo ' + previousReinsurerInfo);

                List<Request__c> lstInfoReqToUpdate = [SELECT id,Reinsurer__c,Reinsurer__r.IsActive__c,Collateral_Provider_City__c,Collateral_provider_Code__c,Collateral_provider_Name__c,DescriptionReinsurerLimitColl__c,Type_of_Code__c,Claims_contact__c
                FROM Request__c WHERE Program__c =:programId AND RecordTypeId = :recordTypeIdSigning AND Reinsurer__c IN:lstReinsurerId AND Reinsurer__r.IsActive__c = true];

                //RRA - ticket 1103 - 30122022
                //update new signing requests with info from previous underwriting year
                system.debug('##LWC30_SigningRequests - closePreviousPhase - lstInfoReqToUpdate == ' + lstInfoReqToUpdate);

                if(lstInfoReqToUpdate.size() > 0){
                    for(Request__c reqToInsert : lstInfoReqToUpdate){
                        if(string.isNotBlank(reqToInsert.Reinsurer__c) && previousReinsurerInfo.containsKey(reqToInsert.Reinsurer__c)){
                            reqToInsert.Collateral_Provider_City__c = previousReinsurerInfo.get(reqToInsert.Reinsurer__c).Collateral_Provider_City__c;
                            reqToInsert.Collateral_provider_Code__c = previousReinsurerInfo.get(reqToInsert.Reinsurer__c).Collateral_provider_Code__c;
                            reqToInsert.Collateral_provider_Name__c = previousReinsurerInfo.get(reqToInsert.Reinsurer__c).Collateral_provider_Name__c;
                            reqToInsert.DescriptionReinsurerLimitColl__c = previousReinsurerInfo.get(reqToInsert.Reinsurer__c).DescriptionReinsurerLimitColl__c;
                            reqToInsert.Type_of_Code__c = previousReinsurerInfo.get(reqToInsert.Reinsurer__c).Type_of_Code__c;
                            reqToInsert.Claims_contact__c = previousReinsurerInfo.get(reqToInsert.Reinsurer__c).Claims_contact__c;
                        }
                    }
                }

                if (lstInforeqToUpdate.size()>0){
                    update lstInforeqToUpdate;
                }
                //MRA 19/05/23 - Contact Signatory Rebuild - START
                system.debug('##LWC30_SigningRequests - closePreviousPhase - lstInfoReqToUpdate 222 == ' + lstInfoReqToUpdate);
                system.debug('##LWC30_SigningRequests - closePreviousPhase - eligibleRenewedProgId == ' + eligibleRenewedProgId);
                Set<Id> previousContactsIdSet = new Set<Id>() ;
                if(string.isNotBlank(eligibleRenewedProgId)){
                    for(ContactReinsurerProgramRelation__c con : [SELECT Id,Name, ContactId__r.Salutation,ContactId__r.LastName,ContactId__r.FirstName,ContactId__r.Email,ContactId__r.MobilePhone,ProgramId__r.Name,ReinsurerId__r.Name,OrderOfSignatory__c,ContactId__r.ApprovalRole__c
                                                                  FROM ContactReinsurerProgramRelation__c 
                                                                  WHERE ReinsurerId__c IN :previousReinsurerInfo.keySet()
                                                                  AND ProgramId__c =: eligibleRenewedProgId
                                                                  AND ContactId__r.ApprovalRole__c INCLUDES ('Signatory')
                                                                  ORDER BY OrderOfSignatory__c]){
                        if (!mapListToInsert.keySet().contains(con.ReinsurerId__c)) {
                            mapListToInsert.put(con.ReinsurerId__c,new List<ContactReinsurerProgramRelation__c>()) ;
                        }
                        if(mapListToInsert.get(con.ReinsurerId__c) != null){
                            mapListToInsert.get(con.ReinsurerId__c).add(new ContactReinsurerProgramRelation__c(Name = con.Name,
                                                                                                                ReinsurerId__c = con.ReinsurerId__c,
                                                                                                                ProgramId__c = programId,
                                                                                                                ContactId__c = con.ContactId__c));
                        }
                        previousContactsIdSet.add(con.ContactId__c) ;
                    }
                }
                List<ContactReinsurerProgramRelation__c> conListToInsert = new List<ContactReinsurerProgramRelation__c>() ;
                for (Id IdReins : mapListToInsert.keySet()) {
                    // Reorder the remaining rows
                    for(Integer i = 0; i < mapListToInsert.get(IdReins).size(); i++) {
                        mapListToInsert.get(IdReins)[i].OrderOfSignatory__c = i + 1;
                    }
                    conListToInsert.addAll(mapListToInsert.get(IdReins)) ;
                }
                // Reorder the remaining rows
                /*for(Integer i = 0; i < conListToInsert.size(); i++) {
                    conListToInsert[i].OrderOfSignatory__c = i + 1;
                }*/
                List<ContactReinsurerProgramRelation__c> lstExistingSignatory = [SELECT Id
                                                                                FROM ContactReinsurerProgramRelation__c 
                                                                                WHERE ReinsurerId__c IN :previousReinsurerInfo.keySet()
                                                                                AND ProgramId__c =: programId
                                                                                AND ContactId__r.ApprovalRole__c INCLUDES ('Signatory')
                                                                                AND ContactId__c IN :previousContactsIdSet] ;

                system.debug('##LWC30_SigningRequests - closePreviousPhase - lstExistingSignatory ' + lstExistingSignatory);
                system.debug('##LWC30_SigningRequests - closePreviousPhase - conListToInsert.size() > 0 && lstExistingSignatory.isEmpty() ' + (conListToInsert.size() > 0 && lstExistingSignatory.isEmpty()));

                if(conListToInsert.size() > 0 && lstExistingSignatory.isEmpty()){
                    insert conListToInsert ;
                }
                
                ///RRA - ticket 1632 - 04102023
                List<Request__c> lstReqSigning = [SELECT Id, PremiumDepositMode__c, PremiumDeposit__c FROM Request__c WHERE Program__c =:programId AND RecordType.Name ='Signing Request' AND PremiumDeposit__c ='2'];
               if (lstReqSigning.size()>0){
                   for (Request__c reqSign :lstReqSigning){
                        reqSign.PremiumDepositMode__c = null; 
                   }
                   update lstReqSigning;
               } 
                
                //MRA 19/05/23 - Contact Signatory Rebuild - END
                system.debug('##LWC30_SigningRequests - closePreviousPhase - end ');
                system.debug('##LWC30_SigningRequests - lstSigningRequests== ' + lstSigningRequests);
                mapResults.put('lstPoolTreatySections', lstPoolTreatySections);//lstSigningRequests	
                mapResults.put('lstSigningRequests', lstSigningRequests);
                mapResults.put('Success', 'Updated successfully');
            }
            catch (Exception exp){
                mapResults.put('Error', exp.getMessage());
            }
    
            return mapResults;
        }
    
        // RRA 1072 - Convert nameAPI for Currency to Value 
        public static String getValueForCurrency (String nameAPI){
            String currencyValue;
            if (String.IsNotBlank(nameAPI)){
                for (Request__c req : [SELECT Id, toLabel(Section__r.Currency__c) FROM Request__c WHERE Section__r.Currency__c =:  nameAPI LIMIT 1]){
                    currencyValue = req.Section__r.Currency__c;
                }
            }
            return currencyValue;
        }
    
           /**
        * @description Method lis request 
        * @param d requestId, Id programI
        * @return List<Request__c>
        */
        //RRA - 863 Signing - Broker status unique pour un couple B/R
        @AuraEnabled
            public static List<Request__c> lstRequestResult (Id requestId, Id programId){
                Map<String, Id> mapRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectRequest});
                String recordTypeIdSigning = mapRecTypeId.get(AP_Constant.reqRTSigning);
                List<Request__c> lstReq = [SELECT Id, Broker__c, Broker__r.Name, Reinsurer__c, Reinsurer__r.Name FROM Request__c WHERE Id=:requestId AND Program__c =: programId AND RecordTypeId = :recordTypeIdSigning];
                System.debug('lstReq= ' + lstReq);
                return lstReq;
            }
    
        /**
        * @description Method signing request details
        * @param Id programId, Id treatyId, Id reinsurerId, Id brokerId, String reinsurerStatus
        * @return Map<String, Object>
        */
        @AuraEnabled
        public static Map<String, Object> getSigningDetails(Id programId, Id treatyId, Id reinsurerId, Id brokerId, String reinsurerStatus, Boolean isClosePreviousBtnClick) {
            Map<String, Object> mapResults = new Map<String, Object>();
            Boolean showClosePreviousPhaseBtn = false;
            List<Request__c> lstAllSigningRequest = new List<Request__c>();
            List<Request__c> lstSigningRequest = new List<Request__c>();
            List<Request__c> lstFilteredSigningRequest = new List<Request__c>();
            Map<String, Id> mapRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectRequest});
            String recordTypeIdLead = mapRecTypeId.get(AP_Constant.reqRTLead);
            String recordTypeIdSigning = mapRecTypeId.get(AP_Constant.reqRTSigning);
            String statusSetup = AP_Constant.statusSetup;
            String renewStatus = 'none';
            Decimal cededPremiumCalculate;
            List<Decimal> lstCededPremiumCalculate = new List<Decimal>();
            List<Decimal> lstTest = new List<Decimal>();
            Boolean isDeactivatedProg = false; //RRA - ticket 0585 - 13032023      
    
            Program__c program = [SELECT Id, TECH_StageName__c, UwYear__c, SigningPremiumCurrency__c, isBtnActivatedDeactivated__c, TECH_PremiumEUR__c, TypeOfRenew__c, TECH_PremiumOther__c, TECH_ShowClosePreviousPhaseBtn__c, SigningPremium__c FROM Program__c WHERE Id = :programId];  //RRA - ticket 0585 - 13032023  

            if (program.isBtnActivatedDeactivated__c){
                isDeactivatedProg = true;  //RRA - ticket 0585 - 13032023  
            }
            //****Ticket 1072 - RRA ***
            /***************************/
    
            // Search list Section and avoid duplication on request by program
            Set<String> lstSection = new Set<String>();
            List<String> lstCededPremiumEUR = new List<String>();
            List<Decimal> lstGetCededPremiumEUR = new List<Decimal>();
            List<Id> lstIdChildLeadReq = new List<Id>();
            List<Decimal> lstGetSectionEPI = new List<Decimal>();
            List<Decimal> lstGetCessionPerc = new List<Decimal>();
            List<Request__c> leadRequestCededPremium = new List<Request__c>();
            //map<String, Decimal> mapCededPlacementShare = new map<String, Decimal>();
    
            // Retrieve the list CededPremium__c without duplication 
            List<AggregateResult> lstRequestCededPremium = [SELECT Section__c, Treaty__c, Treaty__r.WebXLReference__c, Section__r.SectionNumber__c , max(CededPremium__c) countCededPremium, max(Section__r.TotalEPI__c) sectionEPI, max(Section__r.Cession_Perc__c) cessionPerc, max(Section__r.TECH_CessionShare__c) cessionShare, max(FixedRate__c) fixeRate, max(FlatPremium__c) flatPremium, max(MDP__c) MDP, max(MinRate__c) minRate, max(PerHeadPremium__c) perHeadPremium, min (MinPerHeadAmount__c) minPerHeadAmount, Treaty__r.TypeofTreaty__c typeTreaty, Section__r.QuoteType__c quoteType, Section__r.Currency__c currency  FROM Request__c Where program__c=: programId AND  RecordTypeId =:recordTypeIdLead  AND ((LastVersionSent__c = TRUE AND LastVersionAnswered__c = TRUE) OR (ReinsurerStatus__c =: statusSetup)) AND CededPremium__c!=null GROUP BY Section__c, Treaty__c, Treaty__r.WebXLReference__c, Section__r.SectionNumber__c, Treaty__r.TypeofTreaty__c, Section__r.QuoteType__c,Section__r.Currency__c ];//RRA - 1513 - 02062023 and RRA - 1966 - 18032024
    
            System.debug('lstRequestCededPremium==' + lstRequestCededPremium);
    
            //if duplication exists n cededpremium
            if (lstRequestCededPremium.size() > 0){
                for (AggregateResult rqCededPre : lstRequestCededPremium){
                    lstGetCededPremiumEUR.add((Decimal)(rqCededPre.get('countCededPremium')));
                    
                }
                System.debug('lstGetCededPremiumEUR==' + lstGetCededPremiumEUR);
            }
            
            if(program.TypeOfRenew__c != null && program.TypeOfRenew__c == 'LTA/TR Identical Renew'){
                renewStatus = 'Identical Renew';
            }
    
            if(program.TECH_StageName__c == 'Signing'){
                List<String> lstRequestFields = AP_Constant.getCreatableFieldsByObjName(AP_Constant.sObjectRequest);
                String strRequestFields = String.join(lstRequestFields , ', ');
                //RRA - ticket 1564 - Add TECH_BrokerReinsurer__c in soql | add Treaty__r.CessionShare__c in soql => RRA - ticket 1966 - 19032024
                String querySigning = 'SELECT Id, TECH_TreatyName__c, Treaty__r.CessionShare__c, TECH_BrokerReinsurer__c, Treaty__r.PlacementShare_Perc__c, TECH_BrokerName__c, TECH_IsBrokerPresent__c, TECH_ReinsurerName__c, TECH_Layer__c, TECH_UWyear__c,  SigningRegionalManager__r.Email, Treaty__r.Status__c, Section__r.Status__c ' //RRA - ticket 585 - 13032023
                        + ', RiskCarrier__r.Name, FinancialEntity__r.Name, Program__r.LossDepositMode__c, Program__r.LossDeposit__c '
                        + ', Treaty__r.LossDepositMode__c, Treaty__r.LossDeposit__c, Treaty__r.Deductions__c, TreatyReference__c '
                        + ', Treaty__r.TypeofTreaty__c, Treaty__r.PremiumDeposit__c, Program__r.LossDepositLevel__c, Pool__r.Name, Pool__r.AssignedTo__r.Email, Pool__r.AssignedTo__c, Program__r.Name, program__r.principalcedingcompany__r.Name, TECH_Recovery_RelatedLeadPlacementReq__c, ' 
                        +  strRequestFields
                        + ' from Request__c where (Program__c = :programId AND RecordTypeId = :recordTypeIdSigning AND Program__c != NULL) AND ((LastVersionSent__c = TRUE AND LastVersionAnswered__c = TRUE) OR (ReinsurerStatus__c = :statusSetup)) ';
    
                lstSigningRequest = Database.query(querySigning);
    
                if (treatyId!=null){
                    querySigning = querySigning + ' AND Treaty__c = :treatyId';
                }
    
                if (reinsurerId!=null){
                    querySigning = querySigning + ' AND Reinsurer__c = :reinsurerId';
                }
    
                if (brokerId!=null){
                    querySigning = querySigning + ' AND Broker__c = :brokerId';
                }
    
                if (reinsurerStatus!=null){
                    querySigning = querySigning + ' AND ReinsurerStatus__c = :reinsurerStatus ';
                }
    
                lstFilteredSigningRequest = Database.query(querySigning);
            }
    
            for(Request__c signingReq : lstSigningRequest){
                if(signingReq.Pool__c == null){
                    if(signingReq.PremiumDeposit__c == null && signingReq.Treaty__r.PremiumDeposit__c != null){
                        if(signingReq.Treaty__r.PremiumDeposit__c == 'No'){
                            signingReq.PremiumDeposit__c = '2';
                        }
                        else if(signingReq.Treaty__r.PremiumDeposit__c == 'Yes'){
                            signingReq.PremiumDeposit__c = '1';
                        }
                    }
    
                    signingReq.LossDeposit__c = signingReq.Program__r.LossDeposit__c;
    
                    if(signingReq.Program__r.LossDepositLevel__c != null && signingReq.Program__r.LossDepositLevel__c == 'Treaty'){
                        signingReq.LossDeposit__c = signingReq.Treaty__r.LossDeposit__c;
                    }
    
                    if(signingReq.Treaty__r.Deductions__c == '2'){
                        signingReq.Deductions__c = 0;
                    }
                }
            }
    
            if(program.TECH_ShowClosePreviousPhaseBtn__c == '1'){
                showClosePreviousPhaseBtn = true;
            }
            else if(program.TECH_ShowClosePreviousPhaseBtn__c == '2'){
                showClosePreviousPhaseBtn = false;
            }
    
            //Get sum of Ceded Premium for all Lead Request for this program
            Decimal totalCededPremium = 0;
            List<Request__c> lstLeadRequests = [SELECT Id, Name, CededPremium__c, Treaty__r.PlacementShare_Perc__c, FixedRate__c, Treaty__r.CessionShare__c, PerHeadPremium__c, MinPerHeadAmount__c, FlatPremium__c, MinRate__c, MDP__c, toLabel(Section__r.Currency__c), Section__r.Cession_Perc__c, Section__r.TotalEPI__c, Treaty__r.TypeofTreaty__c, Section__r.QuoteType__c, Treaty__c, Section__r.SectionNumber__c, Section__r.TECH_CessionShare__c FROM Request__c WHERE Program__c = :programId AND RecordTypeId = :recordTypeIdLead AND ((LastVersionSent__c = TRUE AND LastVersionAnswered__c = TRUE) OR (ReinsurerStatus__c = :statusSetup)) ORDER BY TECH_LeadType__c desc];//RRA - 1513 - 02062023 and RRA - 18032027 - 18032024
    
            System.debug('lstLeadRequests==' + lstLeadRequests);
    
            //check Currency in Section
            List<String> lstAvailableCurrencyForSection = new List<String>();
    
            
            // RRA - 1072 Manage the total EPI for value cededPremium without duplication
                //Decimal cededP;
                //List<Decimal> lstCededP = new List<Decimal>();
                //Decimal mathR;
                //RRA - 1513 - 02062023
                List<String> lstCededP = new List<String>();
                map<String, Decimal> mapKeyCededPremium = new map<String, Decimal> ();
                String cededP;
                Decimal mathR;
                if (lstRequestCededPremium.size() > 0){
                    for (AggregateResult rqCededPre : lstRequestCededPremium){
                        if ((Decimal)(rqCededPre.get('countCededPremium')) != null){
                            String nameAPI = (String)(rqCededPre.get('currency'));
                            String value = getValueForCurrency (nameAPI);
                            lstAvailableCurrencyForSection.add(value);
                            totalCededPremium = totalCededPremium + (Decimal)(rqCededPre.get('countCededPremium'));
                            String typeOfTreaty = (String)rqCededPre.get('typeTreaty');
                            String typeOfQuote = (String)rqCededPre.get('quoteType'); 
    
                        //QS + (FlatCommission or VariableCommission or RiskPremiumBasis)
                        if(typeOfTreaty == '3' && (typeOfQuote == '5' || typeOfQuote == '6' || typeOfQuote == '9')){
                            Decimal totalEPI = 0;
                            Decimal cessionPerc = 0;
                            if((Decimal)(rqCededPre.get('sectionEPI')) != null){
                                totalEPI = (Decimal)(rqCededPre.get('sectionEPI'));
                            }
                            if((Decimal)(rqCededPre.get('cessionPerc')) != null){
                                cessionPerc = (Decimal)(rqCededPre.get('cessionPerc'));
                            }
                            Decimal cededPremiumValue = totalEPI * (cessionPerc / 100);
    
                            //cededP =  (Decimal)(rqCededPre.get('countCededPremium')) + '_' + (Id)(rqCededPre.get('Treaty__c'));//RRA - 1513 - 02062023
                            mathR = Math.roundToLong(cededPremiumValue);
                            cededP = mathR + '_' + (Id)(rqCededPre.get('Treaty__c')) + '_' + (Id)(rqCededPre.get('Section__c'));//RRA - 1513 - 02062023
                            mapKeyCededPremium.put((Id)(rqCededPre.get('Treaty__c')) + '_' + (Id)(rqCededPre.get('Section__c')), mathR);
    
                        }//(QS or Surplus) + PerHead
                        else if((typeOfTreaty == '3' || typeOfTreaty == '4') && typeOfQuote == '7'){
                            Decimal totalEPI = 0;
                            if((Decimal)(rqCededPre.get('sectionEPI')) != null){
                                totalEPI = (Decimal)(rqCededPre.get('sectionEPI'));
                            }
                            Decimal cededPremiumValue = totalEPI;
    
                            //cededP =  (Decimal)(rqCededPre.get('countCededPremium')) + '_' + (Id)(rqCededPre.get('Treaty__c'));//RRA - 1513 - 02062023
                            mathR = Math.roundToLong(cededPremiumValue);
                            cededP = mathR + '_' + (Id)(rqCededPre.get('Treaty__c')) + '_' + (Id)(rqCededPre.get('Section__c'));//RRA - 1513 - 02062023
                            mapKeyCededPremium.put((Id)(rqCededPre.get('Treaty__c')) + '_' + (Id)(rqCededPre.get('Section__c')), mathR);
    
                        //RRA - ticket 1966 - 18032024
                        }else if(typeOfTreaty == '5' && (typeOfQuote == '5' || typeOfQuote == '6' || typeOfQuote == '9' || typeOfQuote == '7')){ 
                            Decimal totalEPI = 0;
                            Decimal cessionShare = 0;
                            if((Decimal)(rqCededPre.get('sectionEPI')) != null){
                                totalEPI = (Decimal)(rqCededPre.get('sectionEPI'));
                            }
                            
                            if((Decimal)(rqCededPre.get('cessionShare')) != null){
                                cessionShare = (Decimal)(rqCededPre.get('cessionShare'));
                            }
                            
                            Decimal cededPremiumValue = totalEPI * (cessionShare/100);
                            mathR = Math.roundToLong(cededPremiumValue);
                            cededP = mathR + '_' + (Id)(rqCededPre.get('Treaty__c')) + '_' + (Id)(rqCededPre.get('Section__c'));
                            mapKeyCededPremium.put((Id)(rqCededPre.get('Treaty__c')) + '_' + (Id)(rqCededPre.get('Section__c')), mathR);
                            
                        //Surplus + (FlatCommission or VariableCommission or RiskPremiumBasis)
                        }else if(typeOfTreaty == '4' && (typeOfQuote == '5' || typeOfQuote == '6' || typeOfQuote == '9')){
                            Decimal totalEPI = 0;
                            if((Decimal)(rqCededPre.get('sectionEPI')) != null){
                                totalEPI = (Decimal)(rqCededPre.get('sectionEPI'));
                            }
                            Decimal cededPremiumValue = totalEPI;
    
                            //cededP =  (Decimal)(rqCededPre.get('countCededPremium')) + '_' + (Id)(rqCededPre.get('Treaty__c'));//RRA - 1513 - 02062023
                            mathR = Math.roundToLong(cededPremiumValue);
                            cededP = mathR + '_' + (Id)(rqCededPre.get('Treaty__c')) + '_' + (Id)(rqCededPre.get('Section__c'));//RRA - 1513 - 02062023
                            mapKeyCededPremium.put((Id)(rqCededPre.get('Treaty__c')) + '_' + (Id)(rqCededPre.get('Section__c')), mathR);
                        }
                        
                        //(SL or XL) + FixedRate
                        else if((typeOfTreaty == '4' || typeOfTreaty == '2') && typeOfQuote == '1'){
                            Decimal totalEPI = 0;
                            Decimal fixedRate = 0;
                            if((Decimal)(rqCededPre.get('sectionEPI')) != null){
                                totalEPI = (Decimal)(rqCededPre.get('sectionEPI'));
                            }
                            if((Decimal)(rqCededPre.get('fixeRate')) != null){
                                fixedRate = (Decimal)(rqCededPre.get('fixeRate'));
                            }
                            Decimal cededPremiumValue = totalEPI * (fixedRate / 100);
                            //Decimal cededPremiumValue11 = (Decimal)(rqCededPre.get('countCededPremium'));
    
                            //cededP =  (Decimal)(rqCededPre.get('countCededPremium')) + '_' + (Id)(rqCededPre.get('Treaty__c'));//RRA - 1513 - 02062023
                            mathR = Math.roundToLong(cededPremiumValue);
                            cededP = mathR + '_' + (Id)(rqCededPre.get('Treaty__c')) + '_' + (Id)(rqCededPre.get('Section__c'));//RRA - 1513 - 02062023
                            mapKeyCededPremium.put((Id)(rqCededPre.get('Treaty__c')) + '_' + (Id)(rqCededPre.get('Section__c')), mathR);
                        }
    
                         //(SL or XL) + FixedRate
                         else if(typeOfTreaty == '1' && typeOfQuote == '1'){
                            Decimal totalEPI = 0;
                            Decimal fixedRate = 0;
                            if((Decimal)(rqCededPre.get('sectionEPI')) != null){
                                totalEPI = (Decimal)(rqCededPre.get('sectionEPI'));
                            }
                            if((Decimal)(rqCededPre.get('fixeRate')) != null){
                                fixedRate = (Decimal)(rqCededPre.get('fixeRate'));
                            }
                            Decimal cededPremiumValue = totalEPI * (fixedRate / 100);
    
                            //cededP =  (Decimal)(rqCededPre.get('countCededPremium')) + '_' + (Id)(rqCededPre.get('Treaty__c'));//RRA - 1513 - 02062023
                            mathR = Math.roundToLong(cededPremiumValue);
                            cededP = mathR + '_' + (Id)(rqCededPre.get('Treaty__c')) + '_' + (Id)(rqCededPre.get('Section__c'));//RRA - 1513 - 02062023
                            mapKeyCededPremium.put((Id)(rqCededPre.get('Treaty__c')) + '_' + (Id)(rqCededPre.get('Section__c')), mathR);
                            System.debug('fixedRate ==' + fixedRate);
                        }
    
                        //(SL or XL) + FlatPremium
                        else if((typeOfTreaty == '1' || typeOfTreaty == '2') && typeOfQuote == '3'){
                            Decimal flatPremium = 0;
                            if((Decimal)(rqCededPre.get('flatPremium')) != null){
                                flatPremium = (Decimal)(rqCededPre.get('flatPremium'));
                            }
                            Decimal cededPremiumValue = flatPremium;
    
                            //cededP =  (Decimal)(rqCededPre.get('countCededPremium')) + '_' + (Id)(rqCededPre.get('Treaty__c'));//RRA - 1513 - 02062023
                            mathR = Math.roundToLong(cededPremiumValue);
                            cededP = mathR + '_' + (Id)(rqCededPre.get('Treaty__c')) + '_' + (Id)(rqCededPre.get('Section__c'));//RRA - 1513 - 02062023
                            mapKeyCededPremium.put((Id)(rqCededPre.get('Treaty__c')) + '_' + (Id)(rqCededPre.get('Section__c')), mathR);
                        }
    
                        //(SL or XL) + MDP
                        else if((typeOfTreaty == '1' || typeOfTreaty == '2') && typeOfQuote == '4'){
                            Decimal MDP = 0;
                            if((Decimal)(rqCededPre.get('MDP')) != null){
                                MDP = (Decimal)(rqCededPre.get('MDP'));
                            }
                            Decimal cededPremiumValue = MDP;
    
                            //cededP =  (Decimal)(rqCededPre.get('countCededPremium')) + '_' + (Id)(rqCededPre.get('Treaty__c'));//RRA - 1513 - 02062023
                            mathR = Math.roundToLong(cededPremiumValue);
                            cededP = mathR + '_' + (Id)(rqCededPre.get('Treaty__c')) + '_' + (Id)(rqCededPre.get('Section__c'));//RRA - 1513 - 02062023
                            mapKeyCededPremium.put((Id)(rqCededPre.get('Treaty__c')) + '_' + (Id)(rqCededPre.get('Section__c')), mathR);
                        }
    
                        //(SL or XL) + VariableRate
                        else if((typeOfTreaty == '1' || typeOfTreaty == '2') && typeOfQuote == '2'){
                            Decimal totalEPI = 0;
                            Decimal minRate = 0;
                            if((Decimal)(rqCededPre.get('sectionEPI')) != null){
                                totalEPI = (Decimal)(rqCededPre.get('sectionEPI'));
                            }
                            if((Decimal)(rqCededPre.get('minRate')) != null){
                                minRate = (Decimal)(rqCededPre.get('minRate'));
                            }
                            Decimal cededPremiumValue = totalEPI * (minRate / 100);
    
                            //cededP =  (Decimal)(rqCededPre.get('countCededPremium')) + '_' + (Id)(rqCededPre.get('Treaty__c'));//RRA - 1513 - 02062023
                            mathR = Math.roundToLong(cededPremiumValue);
                            cededP = mathR + '_' + (Id)(rqCededPre.get('Treaty__c')) + '_' + (Id)(rqCededPre.get('Section__c'));//RRA - 1513 - 02062023
                            mapKeyCededPremium.put((Id)(rqCededPre.get('Treaty__c')) + '_' + (Id)(rqCededPre.get('Section__c')), mathR);
                        }
    
                        //(SL or XL) + PerHeadPremium
                        else if((typeOfTreaty == '1' || typeOfTreaty == '2') && typeOfQuote == '10'){
                            Decimal totalEPI = 0;
                            Decimal perHeadPremium = 0;
                            if((Decimal)(rqCededPre.get('sectionEPI')) != null){
                                totalEPI = (Decimal)(rqCededPre.get('sectionEPI'));
                            }
                            if((Decimal)(rqCededPre.get('perHeadPremium')) != null){
                                perHeadPremium = (Decimal)(rqCededPre.get('perHeadPremium'));
                            }
                            Decimal cededPremiumValue = totalEPI * perHeadPremium;
    
                            //cededP =  (Decimal)(rqCededPre.get('countCededPremium')) + '_' + (Id)(rqCededPre.get('Treaty__c'));//RRA - 1513 - 02062023
                            mathR = Math.roundToLong(cededPremiumValue);
                            cededP = mathR + '_' + (Id)(rqCededPre.get('Treaty__c')) + '_' + (Id)(rqCededPre.get('Section__c'));//RRA - 1513 - 02062023
                            mapKeyCededPremium.put((Id)(rqCededPre.get('Treaty__c')) + '_' + (Id)(rqCededPre.get('Section__c')), mathR);
                        }
    
                        //(SL or XL) + PerHeadVariable
                        else if((typeOfTreaty == '1' || typeOfTreaty == '2') && typeOfQuote == '8'){
                            Decimal totalEPI = 0;
                            Decimal minPerHeadAmount = 0;
                            if((Decimal)(rqCededPre.get('sectionEPI')) != null){
                                totalEPI = (Decimal)(rqCededPre.get('sectionEPI'));
                            }
                            if((Decimal)(rqCededPre.get('minPerHeadAmount')) != null){
                                minPerHeadAmount = (Decimal)(rqCededPre.get('minPerHeadAmount'));
                            }
                            Decimal cededPremiumValue = totalEPI * minPerHeadAmount;
    
                            //cededP =  (Decimal)(rqCededPre.get('countCededPremium')) + '_' + (Id)(rqCededPre.get('Treaty__c'));//RRA - 1513 - 02062023
                            mathR = Math.roundToLong(cededPremiumValue);
                            cededP = mathR + '_' + (Id)(rqCededPre.get('Treaty__c')) + '_' + (Id)(rqCededPre.get('Section__c'));//RRA - 1513 - 02062023
                            mapKeyCededPremium.put((Id)(rqCededPre.get('Treaty__c')) + '_' + (Id)(rqCededPre.get('Section__c')), mathR);
                        }
                        System.debug('cededP == '+cededP );
                        System.debug('mathR == '+mathR );
                    }
                    lstCededP.add(cededP);
                }
            }else{
                for(Request__c leadRequest : lstLeadRequests){
                    if(leadRequest.CededPremium__c != null){
                        lstAvailableCurrencyForSection.add(leadRequest.Section__r.Currency__c);
                        totalCededPremium = totalCededPremium + leadRequest.CededPremium__c;
                        String typeOfTreaty = leadRequest.Treaty__r.TypeofTreaty__c;
                        String typeOfQuote = leadRequest.Section__r.QuoteType__c;
        
                        //QS + (FlatCommission or VariableCommission or RiskPremiumBasis)
                        if(typeOfTreaty == '3' && (typeOfQuote == '5' || typeOfQuote == '6' || typeOfQuote == '9')){
                            Decimal totalEPI = 0;
                            Decimal cessionPerc = 0;
                            if(leadRequest.Section__r.TotalEPI__c != null){
                                totalEPI = leadRequest.Section__r.TotalEPI__c;
                            }
                            if(leadRequest.Section__r.Cession_Perc__c != null){
                                cessionPerc = leadRequest.Section__r.Cession_Perc__c;
                            }
        
                            Decimal cededPremiumValue = totalEPI * (cessionPerc / 100);
                            leadRequest.CededPremium__c = Math.roundToLong(cededPremiumValue);
                            System.debug('leadRequest.CededPremium__c == '+ leadRequest.CededPremium__c);
                        }
        
                        //(QS or Surplus) + PerHead
                        else if((typeOfTreaty == '3' || typeOfTreaty == '4') && typeOfQuote == '7'){
                            Decimal totalEPI = 0;
                            if(leadRequest.Section__r.TotalEPI__c != null){
                                totalEPI = leadRequest.Section__r.TotalEPI__c;
                            }
                            Decimal cededPremiumValue = totalEPI;
                            leadRequest.CededPremium__c = Math.roundToLong(cededPremiumValue);
        
                        //RRA - ticket 1966 - 18032024
                        }else if(typeOfTreaty == '5' && (typeOfQuote == '5' || typeOfQuote == '6' || typeOfQuote == '9' || typeOfQuote == '7')){ 
                            Decimal totalEPI = 0;
                            Decimal cessionShare = 0;
                            if(leadRequest.Section__r.TotalEPI__c != null){
                                totalEPI = leadRequest.Section__r.TotalEPI__c;
                            }
                            
                            if(leadRequest.Section__r.TECH_CessionShare__c != null){
                                cessionShare = leadRequest.Section__r.TECH_CessionShare__c;
                            }
                            
                            Decimal cededPremiumValue = totalEPI * (cessionShare/100);
                            leadRequest.CededPremium__c = Math.roundToLong(cededPremiumValue);
                            
                        //Surplus + (FlatCommission or VariableCommission or RiskPremiumBasis)
                        }else if(typeOfTreaty == '4' && (typeOfQuote == '5' || typeOfQuote == '6' || typeOfQuote == '9')){
                            Decimal totalEPI = 0;
                            if(leadRequest.Section__r.TotalEPI__c != null){
                                totalEPI = leadRequest.Section__r.TotalEPI__c;
                            }
                            Decimal cededPremiumValue = totalEPI;
                            leadRequest.CededPremium__c = Math.roundToLong(cededPremiumValue);
                        }
        
                        //(SL or XL) + FixedRate
                        else if((typeOfTreaty == '4' || typeOfTreaty == '2') && typeOfQuote == '1'){
                            Decimal totalEPI = 0;
                            Decimal fixedRate = 0;
                            if(leadRequest.Section__r.TotalEPI__c != null){
                                totalEPI = leadRequest.Section__r.TotalEPI__c;
                            }
                            if(leadRequest.FixedRate__c != null){
                                fixedRate = leadRequest.FixedRate__c;
                            }
                            Decimal cededPremiumValue = totalEPI * (fixedRate / 100);
                            leadRequest.CededPremium__c = Math.roundToLong(cededPremiumValue);
                        }
        
                        //(SL or XL) + FlatPremium
                        else if((typeOfTreaty == '1' || typeOfTreaty == '2') && typeOfQuote == '3'){
                            Decimal flatPremium = 0;
                            if(leadRequest.FlatPremium__c != null){
                                flatPremium = leadRequest.FlatPremium__c;
                            }
                            Decimal cededPremiumValue = flatPremium;
                            leadRequest.CededPremium__c = Math.roundToLong(cededPremiumValue);
                        }
        
                        //(SL or XL) + MDP
                        else if((typeOfTreaty == '1' || typeOfTreaty == '2') && typeOfQuote == '4'){
                            Decimal MDP = 0;
                            if(leadRequest.MDP__c != null){
                                MDP = leadRequest.MDP__c;
                            }
                            Decimal cededPremiumValue = MDP;
                            leadRequest.CededPremium__c = Math.roundToLong(cededPremiumValue);
                        }
        
                        //(SL or XL) + VariableRate
                        else if((typeOfTreaty == '1' || typeOfTreaty == '2') && typeOfQuote == '2'){
                            Decimal totalEPI = 0;
                            Decimal minRate = 0;
                            if(leadRequest.Section__r.TotalEPI__c != null){
                                totalEPI = leadRequest.Section__r.TotalEPI__c;
                            }
                            if(leadRequest.MinRate__c != null){
                                minRate = leadRequest.MinRate__c;
                            }
                            Decimal cededPremiumValue = totalEPI * (minRate / 100);
                            leadRequest.CededPremium__c = Math.roundToLong(cededPremiumValue);
                        }
        
                        //(SL or XL) + PerHeadPremium
                        else if((typeOfTreaty == '1' || typeOfTreaty == '2') && typeOfQuote == '10'){
                            Decimal totalEPI = 0;
                            Decimal perHeadPremium = 0;
                            if(leadRequest.Section__r.TotalEPI__c != null){
                                totalEPI = leadRequest.Section__r.TotalEPI__c;
                            }
                            if(leadRequest.PerHeadPremium__c != null){
                                perHeadPremium = leadRequest.PerHeadPremium__c;
                            }
                            Decimal cededPremiumValue = totalEPI * perHeadPremium;
                            leadRequest.CededPremium__c = Math.roundToLong(cededPremiumValue);
                        }
        
                        //(SL or XL) + PerHeadVariable
                        else if((typeOfTreaty == '1' || typeOfTreaty == '2') && typeOfQuote == '8'){
                            Decimal totalEPI = 0;
                            Decimal minPerHeadAmount = 0;
                            if(leadRequest.Section__r.TotalEPI__c != null){
                                totalEPI = leadRequest.Section__r.TotalEPI__c;
                            }
                            if(leadRequest.MinPerHeadAmount__c != null){
                                minPerHeadAmount = leadRequest.MinPerHeadAmount__c;
                            }
                            Decimal cededPremiumValue = totalEPI * minPerHeadAmount;
                            leadRequest.CededPremium__c = Math.roundToLong(cededPremiumValue);
                        }
                    }
                    lstCededPremiumCalculate.add(leadRequest.CededPremium__c);
                }
    
            }
    
            for (Decimal x : lstCededPremiumCalculate){
                if (x!=null){
                    System.debug('x== ' + x);
                }
            }//lstTest
    
        
            Integer currEURNumber = 0;
            Integer currOtherNumber = 0;
            Decimal totalCededPremiumOther = 0;
            Decimal totalCededPremiumEUR = 0;
            String currOtherStr = null;
            Boolean displayTwoFieldForPremium = false;
            Map<String, Decimal> mapRateByCurrencyLabel = new Map<String, Decimal>();
            Map<String, String> mapgetRateFromCurrency = new Map<String, String>(); //RRA - ticket 1395 - 03012023
            Map<String, Decimal> mapgetPlacemetShareFromCurrency = new Map<String, Decimal>(); //RRA - ticket 1513 - 03012023
            //RRA - ticket 1966 - 18032024
            String typeOfTreatie;
            Boolean isTypeTreatieQS = false;
            String typeOfTreaties;
            Boolean isTypeTreatieQSs = false;
    
            for(FXRate__c fxRate : [SELECT Id, toLabel(Currency__c), FX_Rate__c FROM FXRate__c WHERE UW_Year__c = :program.UwYear__c]){
                if(!mapRateByCurrencyLabel.containsKey(fxRate.Currency__c)){
                    mapRateByCurrencyLabel.put(fxRate.Currency__c, fxRate.FX_Rate__c);
                }
            }
    
            String currOther = null;
    
            for(String curr : lstAvailableCurrencyForSection){
                if(curr == 'EUR'){
                    currEURNumber++;
                }
                else if(currOther == null){
                    currOther = curr;
                    currOtherNumber++;
                }
                else if(currOther == curr){
                    currOtherNumber++;
                }
            }
    
            System.debug('lstGetCededPremiumEUREUR==' + lstGetCededPremiumEUR);
            System.debug('lstAvailableCurrencyForSection==' + lstAvailableCurrencyForSection);
            System.debug('lstAvailableCurrencyForSectionSIZE==' + lstAvailableCurrencyForSection.size());
            // Check if list CededPremimum exist after operation without duplication
            if (lstGetCededPremiumEUR.size() > 0){
                System.debug('lstGetCededPremiumEUR SIZE == ' + lstGetCededPremiumEUR.size());
                if(currEURNumber == 0 && (currOtherNumber == lstAvailableCurrencyForSection.size())){
                    //to display 2 fields - one is other and other one is EUR
                    displayTwoFieldForPremium = true;
                    for(Request__c leadRequest : lstLeadRequests){
                        currOtherStr = leadRequest.Section__r.Currency__c;
                        typeOfTreatie = leadRequest.Treaty__r.TypeofTreaty__c; //RRA - ticket 1966 - 18032024
                        //RRA - ticket 1395 - 03012023
                        mapgetRateFromCurrency.put(leadRequest.Treaty__c + '_' + leadRequest.Section__c, leadRequest.Section__r.Currency__c);
                        
                        //Create map between CededPremium and Treaty__c.PlacementShare to retrieve the placement Share attached)
                        if (typeOfTreatie == '5'){ //RRA - ticket 1966 - 18032024
                            isTypeTreatieQS = true;
                            mapgetPlacemetShareFromCurrency.put(leadRequest.Treaty__c + '_' + leadRequest.Section__c, leadRequest.Treaty__r.CessionShare__c); //RRA - ticket 1966 - 18032024
                        }else{
                            mapgetPlacemetShareFromCurrency.put(leadRequest.Treaty__c + '_' + leadRequest.Section__c, leadRequest.Treaty__r.PlacementShare_Perc__c);
                        }
                    }
                    System.debug('isTypeTreatieQS= ' + isTypeTreatieQS);
                    
                    
                    /*if (lstCededP.size() > 0){
                        System.debug('lstCededP= ' + lstCededP);
                        for(String ceded : lstCededP){
                            if (ceded != null){
                                List<String> lstPremiumCeded = ceded.split('_');
                                if(Decimal.valueOf(lstPremiumCeded[0]) != null){
                                    //AMI 25/05/22 : W-1105
                                    //The "totalCededPremiumOther" was omiited for this particular scenario
                                    //RRA - ticket 1395 - 03012023 and RRA - ticket 1966 - 18032024
                                     if (mapRateByCurrencyLabel.get(mapgetRateFromCurrency.get(lstPremiumCeded[1] + '_' + lstPremiumCeded[2])) != null){
                                        totalCededPremiumOther = (isTypeTreatieQS) ? totalCededPremiumOther + (Decimal.valueOf(lstPremiumCeded[0])) * (mapgetPlacemetShareFromCurrency.get(lstPremiumCeded[1])/100) : totalCededPremiumOther + (Decimal.valueOf(lstPremiumCeded[0]));
                                        //totalCededPremiumOther = totalCededPremiumOther + (Decimal.valueOf(lstPremiumCeded[0])) * (mapgetPlacemetShareFromCurrency.get(lstPremiumCeded[1] + '_' + lstPremiumCeded[2]    )/100);
                                        System.debug('totalCededPremiumOther = ' + totalCededPremiumOther);
                                     }
                                   
                                    //to convert ceded premium to EUR and add
                                    if(mapRateByCurrencyLabel.containsKey(mapgetRateFromCurrency.get(lstPremiumCeded[1] + '_' + lstPremiumCeded[2]))){
                                        //RRA - ticket 1395 - 03012023 and RRA - ticket 1966 - 18032024
                                        totalCededPremiumEUR =  (isTypeTreatieQS) ? totalCededPremiumEUR + (Decimal.valueOf(lstPremiumCeded[0]) / mapRateByCurrencyLabel.get(mapgetRateFromCurrency.get(lstPremiumCeded[1] ))) * (mapgetPlacemetShareFromCurrency.get(lstPremiumCeded[1])/100) :  totalCededPremiumEUR + (Decimal.valueOf(lstPremiumCeded[0]) / mapRateByCurrencyLabel.get(mapgetRateFromCurrency.get(lstPremiumCeded[1] ))); //RRA - ticket 1513 - 22052023;
                                        //totalCededPremiumEUR =  totalCededPremiumEUR + (Decimal.valueOf(lstPremiumCeded[0]) / mapRateByCurrencyLabel.get(mapgetRateFromCurrency.get(lstPremiumCeded[1] + '_' + lstPremiumCeded[2]))) * (mapgetPlacemetShareFromCurrency.get(lstPremiumCeded[1] + '_' + lstPremiumCeded[2])/100); //RRA - ticket 1513 - 22052023;
                                        System.debug('totalCededPremiumEUR xx= ' + totalCededPremiumEUR);
                                    }
                                }
                                }
                        }
                        System.debug('totalCededPremiumOther = ' + totalCededPremiumOther); 
                        
                    // if no, retrieve the value cededpremium for each section rattached on the program
                    }*/
                    
                    //RRA - ticket 1966 - 18032024
                    if (mapKeyCededPremium.size()>0){
                        System.debug('mapKeyCededPremium 11= ' + mapKeyCededPremium);
                        for(String keyCededPrem : mapKeyCededPremium.keySet()){
                            if (mapKeyCededPremium.get(keyCededPrem) !=null){
                                
                                //AMI 25/05/22 : W-1105
                                //The "totalCededPremiumOther" was omiited for this particular scenario
                                //RRA - ticket 1966 - 18032024
                                if (mapRateByCurrencyLabel.get(mapgetRateFromCurrency.get(keyCededPrem)) != null){
                                    totalCededPremiumOther = (isTypeTreatieQS) ? totalCededPremiumOther + (mapKeyCededPremium.get(keyCededPrem)) * (mapgetPlacemetShareFromCurrency.get(keyCededPrem)/100) : totalCededPremiumOther + (mapKeyCededPremium.get(keyCededPrem)) * (mapgetPlacemetShareFromCurrency.get(keyCededPrem)/100);
                                    //totalCededPremiumOther = totalCededPremiumOther + (Decimal.valueOf(lstPremiumCeded[0])) * (mapgetPlacemetShareFromCurrency.get(lstPremiumCeded[1] + '_' + lstPremiumCeded[2]    )/100);
                                    System.debug('totalCededPremiumOther = ' + totalCededPremiumOther);
                                }
                                //to convert ceded premium to EUR and add
                                if(mapRateByCurrencyLabel.containsKey(mapgetRateFromCurrency.get(keyCededPrem))){
                                    //RRA - ticket 1395 - 03012023 and RRA - ticket 1966 - 18032024
                                    totalCededPremiumEUR =  (isTypeTreatieQS) ? totalCededPremiumEUR + (mapKeyCededPremium.get(keyCededPrem) / mapRateByCurrencyLabel.get(mapgetRateFromCurrency.get(keyCededPrem))) * (mapgetPlacemetShareFromCurrency.get(keyCededPrem)/100) :  totalCededPremiumEUR + (mapKeyCededPremium.get(keyCededPrem) / mapRateByCurrencyLabel.get(mapgetRateFromCurrency.get(keyCededPrem))) * (mapgetPlacemetShareFromCurrency.get(keyCededPrem)/100); //RRA - ticket 1966 - 18032024;
                                    //totalCededPremiumEUR =  totalCededPremiumEUR + (Decimal.valueOf(lstPremiumCeded[0]) / mapRateByCurrencyLabel.get(mapgetRateFromCurrency.get(lstPremiumCeded[1] + '_' + lstPremiumCeded[2]))) * (mapgetPlacemetShareFromCurrency.get(lstPremiumCeded[1] + '_' + lstPremiumCeded[2])/100); //RRA - ticket 1513 - 22052023;
                                    System.debug('totalCededPremiumEUR xx= ' + totalCededPremiumEUR);
                                }
                            }
                        }
                    }else{
                        for(AggregateResult cedePremiumAgg : lstRequestCededPremium){
                            System.debug('countCededPremium = ' + (Decimal)(cedePremiumAgg.get('countCededPremium')));
                            totalCededPremiumOther = (isTypeTreatieQS) ? totalCededPremiumOther + (Decimal)(cedePremiumAgg.get('countCededPremium')) * (mapgetPlacemetShareFromCurrency.get((Id)(cedePremiumAgg.get('Treaty__c')) + '_' + (Id)(cedePremiumAgg.get('Section__c')))/100) : totalCededPremiumOther + (Decimal)(cedePremiumAgg.get('countCededPremium')) * (mapgetPlacemetShareFromCurrency.get((Id)(cedePremiumAgg.get('Treaty__c')) + '_' + (Id)(cedePremiumAgg.get('Section__c')))/100); //RRA - ticket 1513 - 22052023 and //RRA - ticket 1966 - 18032024
                            //totalCededPremiumOther = totalCededPremiumOther + (Decimal)(cedePremiumAgg.get('countCededPremium')) * (mapgetPlacemetShareFromCurrency.get((Id)(cedePremiumAgg.get('Treaty__c')) + '_' + (Id)(cedePremiumAgg.get('Section__c')))/100); //RRA - ticket 1513 - 22052023;
                            //convert currency to EUR
                            if(mapRateByCurrencyLabel.containsKey(mapgetRateFromCurrency.get((Id)(cedePremiumAgg.get('Treaty__c')) + '_' + (Id)(cedePremiumAgg.get('Section__c'))))){
                                //RRA - ticket 1395 - 03012023
                                totalCededPremiumEUR = (isTypeTreatieQS) ? totalCededPremiumEUR  + ((Decimal)(cedePremiumAgg.get('countCededPremium')) / mapRateByCurrencyLabel.get(mapgetRateFromCurrency.get((Id)(cedePremiumAgg.get('Treaty__c')) + '_' + (Id)(cedePremiumAgg.get('Section__c'))))) * (mapgetPlacemetShareFromCurrency.get((Id)(cedePremiumAgg.get('Treaty__c')) + '_' + (Id)(cedePremiumAgg.get('Section__c')))/100) : totalCededPremiumEUR  + ((Decimal)(cedePremiumAgg.get('countCededPremium')) / mapRateByCurrencyLabel.get(mapgetRateFromCurrency.get((Id)(cedePremiumAgg.get('Treaty__c')) + '_' + (Id)(cedePremiumAgg.get('Section__c'))))) * (mapgetPlacemetShareFromCurrency.get((Id)(cedePremiumAgg.get('Treaty__c')) + '_' + (Id)(cedePremiumAgg.get('Section__c')))/100); //RRA - ticket 1513 - 22052023 and //RRA - ticket 1966 - 18032024
                                //totalCededPremiumEUR = totalCededPremiumEUR  + ((Decimal)(cedePremiumAgg.get('countCededPremium')) / mapRateByCurrencyLabel.get(mapgetRateFromCurrency.get((Id)(cedePremiumAgg.get('Treaty__c')) + '_' + (Id)(cedePremiumAgg.get('Section__c'))))) * (mapgetPlacemetShareFromCurrency.get((Id)(cedePremiumAgg.get('Treaty__c')) + '_' + (Id)(cedePremiumAgg.get('Section__c')))/100); //RRA - ticket 1513 - 22052023
                            }
                        }
                    }
    
                    System.debug('totalCededPremiumEURPremiumOther==' + totalCededPremiumEUR);
                
                }else{
                    //to display 1 fields - convert all to EUR and add all
                        displayTwoFieldForPremium = false;
                        for(Request__c leadRequest : lstLeadRequests){
                            currOtherStr = leadRequest.Section__r.Currency__c;
                            typeOfTreaties = leadRequest.Treaty__r.TypeofTreaty__c;
                            //RRA - ticket 1395 - 03012023
                            mapgetRateFromCurrency.put(leadRequest.Treaty__c + '_' + leadRequest.Section__c, leadRequest.Section__r.Currency__c);
                            
                            //Create map between CededPremium and Treaty__c.PlacementShare to retrieve the placement Share attached) and //RRA - ticket 1966 - 18032024
                            if (typeOfTreaties == '5'){
                                isTypeTreatieQSs = true;
                                mapgetPlacemetShareFromCurrency.put(leadRequest.Treaty__c + '_' + leadRequest.Section__c, leadRequest.Treaty__r.CessionShare__c); //RRA - ticket 1966 - 18032024
                            }else{
                                mapgetPlacemetShareFromCurrency.put(leadRequest.Treaty__c + '_' + leadRequest.Section__c, leadRequest.Treaty__r.PlacementShare_Perc__c);
                            }
                        }
                        //RRA - ticket 1966 - 18032024
                        if (mapKeyCededPremium.size()>0){
                            System.debug('mapKeyCededPremium 11= ' + mapKeyCededPremium);
                            for(String keyCededPrem : mapKeyCededPremium.keySet()){
                                if (mapKeyCededPremium.get(keyCededPrem) !=null){
                                    if(mapRateByCurrencyLabel.containsKey(mapgetRateFromCurrency.get(keyCededPrem))){
                                        System.debug('mapKeyCededPremium.get(keyCededPrem) 11= ' + mapKeyCededPremium.get(keyCededPrem));
                                        System.debug('mapRateByCurrencyLabel.get(mapgetRateFromCurrency.get(keyCededPrem) 11= ' + mapRateByCurrencyLabel.get(mapgetRateFromCurrency.get(keyCededPrem)));
                                        System.debug('(mapgetPlacemetShareFromCurrency.get(keyCededPrem)/100) 11= ' + (mapgetPlacemetShareFromCurrency.get(keyCededPrem)/100));
                                        totalCededPremiumEUR = (isTypeTreatieQSs) ? totalCededPremiumEUR + (mapKeyCededPremium.get(keyCededPrem) / mapRateByCurrencyLabel.get(mapgetRateFromCurrency.get(keyCededPrem))) * (mapgetPlacemetShareFromCurrency.get(keyCededPrem)/100) : totalCededPremiumEUR + (mapKeyCededPremium.get(keyCededPrem) / mapRateByCurrencyLabel.get(mapgetRateFromCurrency.get(keyCededPrem))) * (mapgetPlacemetShareFromCurrency.get(keyCededPrem)/100); //RRA - ticket 1966 - 18032024;
                                        System.debug('totalCededPremiumEUR count 0 = ' + totalCededPremiumEUR);
                                        //totalCededPremiumEUR = totalCededPremiumEUR + (Decimal.valueOf(lstPremiumCeded[0]) / mapRateByCurrencyLabel.get(mapgetRateFromCurrency.get(lstPremiumCeded[1] + '_' + lstPremiumCeded[2]))) * (mapgetPlacemetShareFromCurrency.get(lstPremiumCeded[1] + '_' + lstPremiumCeded[2])/100); //RRA - ticket 1513 - 22052023;
                                    }
                                    //System.debug('totalCededPremiumEUR count 1 = ' + totalCededPremiumEUR);
                                }
                                
                            }
                        }else{
                            for(AggregateResult cedePremiumAgg : lstRequestCededPremium){
                                //convert currency to EUR
                                if(mapRateByCurrencyLabel.containsKey(mapgetRateFromCurrency.get((Id)(cedePremiumAgg.get('Treaty__c')) + '_' + (Id)(cedePremiumAgg.get('Section__c')) ))){
                                    //RRA - ticket 1395 - 03012023
                                    totalCededPremiumEUR = (isTypeTreatieQSs) ? totalCededPremiumEUR  + ((Decimal)(cedePremiumAgg.get('countCededPremium')) / mapRateByCurrencyLabel.get(mapgetRateFromCurrency.get((Id)(cedePremiumAgg.get('Treaty__c')) + '_' + (Id)(cedePremiumAgg.get('Section__c')) ))) * (mapgetPlacemetShareFromCurrency.get((Id)(cedePremiumAgg.get('Treaty__c')) + '_' + (Id)(cedePremiumAgg.get('Section__c')))/100) : totalCededPremiumEUR  + ((Decimal)(cedePremiumAgg.get('countCededPremium')) / mapRateByCurrencyLabel.get(mapgetRateFromCurrency.get((Id)(cedePremiumAgg.get('Treaty__c')) + '_' + (Id)(cedePremiumAgg.get('Section__c')) ))) * (mapgetPlacemetShareFromCurrency.get((Id)(cedePremiumAgg.get('Treaty__c')) + '_' + (Id)(cedePremiumAgg.get('Section__c')))/100);//RRA - ticket 1513 - 22052023 and RRA - ticket 1966 - 18032024;
                                    //totalCededPremiumEUR = totalCededPremiumEUR  + ((Decimal)(cedePremiumAgg.get('countCededPremium')) / mapRateByCurrencyLabel.get(mapgetRateFromCurrency.get((Id)(cedePremiumAgg.get('Treaty__c')) + '_' + (Id)(cedePremiumAgg.get('Section__c')) ))) * (mapgetPlacemetShareFromCurrency.get((Id)(cedePremiumAgg.get('Treaty__c')) + '_' + (Id)(cedePremiumAgg.get('Section__c')))/100);//RRA - ticket 1513 - 22052023
                               }
                               System.debug('totalCededPremiumEUR count 2 = ' + totalCededPremiumEUR);
                            }
                        }
                    System.debug('totalCededPremiumEUR 11 ==' + totalCededPremiumEUR);
                }
                
            }else{
                //if all currency same -> display 2 fields
                //else -> display EUR Field
                if(currEURNumber == 0 && (currOtherNumber == lstAvailableCurrencyForSection.size())){
                    //to display 2 fields - one is other and other one is EUR
                    displayTwoFieldForPremium = true;
    
                    for(Request__c leadRequest : lstLeadRequests){
                            if(leadRequest.CededPremium__c != null){
                                currOtherStr = leadRequest.Section__r.Currency__c;
                                typeOfTreaties = leadRequest.Treaty__r.TypeofTreaty__c;
                                
                                if (typeOfTreaties == '5'){
                                    isTypeTreatieQSs = true;
                                    mapgetPlacemetShareFromCurrency.put(leadRequest.Treaty__c + '_' + leadRequest.Section__c, leadRequest.Treaty__r.CessionShare__c); //RRA - ticket 1513 - 22052023
                                }else{
                                    mapgetPlacemetShareFromCurrency.put(leadRequest.Treaty__c + '_' + leadRequest.Section__c, leadRequest.Treaty__r.PlacementShare_Perc__c); //RRA - ticket 1513 - 22052023
                                }
                                
                                 //RRA - ticket 1395 - 03012023
                                totalCededPremiumOther = (isTypeTreatieQSs) ? totalCededPremiumOther + (leadRequest.CededPremium__c) * (mapgetPlacemetShareFromCurrency.get(leadRequest.Treaty__c + '_' + leadRequest.Section__c)/100) : totalCededPremiumOther + (leadRequest.CededPremium__c) * (mapgetPlacemetShareFromCurrency.get(leadRequest.Treaty__c  + '_' + leadRequest.Section__c)/100);//RRA - ticket 1513 - 22052023;
                                //totalCededPremiumOther = totalCededPremiumOther + (leadRequest.CededPremium__c) * (mapgetPlacemetShareFromCurrency.get(leadRequest.Treaty__c  + '_' + leadRequest.Section__c)/100);//RRA - ticket 1513 - 22052023;
                               //convert currency to EUR
                               if(mapRateByCurrencyLabel.containsKey(leadRequest.Section__r.Currency__c)){
                                //RRA - ticket 1395 - 03012023
                                totalCededPremiumEUR = (isTypeTreatieQSs) ? totalCededPremiumEUR + (leadRequest.CededPremium__c / mapRateByCurrencyLabel.get(leadRequest.Section__r.Currency__c)) * (mapgetPlacemetShareFromCurrency.get(leadRequest.Treaty__c + '_' + leadRequest.Section__c)/100) : totalCededPremiumEUR + (leadRequest.CededPremium__c / mapRateByCurrencyLabel.get(leadRequest.Section__r.Currency__c)) * (mapgetPlacemetShareFromCurrency.get(leadRequest.Treaty__c + '_' + leadRequest.Section__c)/100);//RRA - ticket 1513 - 22052023
                                //totalCededPremiumEUR = totalCededPremiumEUR + (leadRequest.CededPremium__c / mapRateByCurrencyLabel.get(leadRequest.Section__r.Currency__c)) * (mapgetPlacemetShareFromCurrency.get(leadRequest.Treaty__c + '_' + leadRequest.Section__c)/100);//RRA - ticket 1513 - 22052023
                            }
                            }
                    }
                }
                else{
                    //to display 1 fields - convert all to EUR and add all
                    displayTwoFieldForPremium = false;
                    for(Request__c leadRequest : lstLeadRequests){
                            if(leadRequest.CededPremium__c != null){
                                //to convert ceded premium to EUR and add
                                if(mapRateByCurrencyLabel.containsKey(leadRequest.Section__r.Currency__c)){
                                    //RRA - ticket 1395 - 03012023
                                    totalCededPremiumEUR = (isTypeTreatieQSs) ? totalCededPremiumEUR + (leadRequest.CededPremium__c / mapRateByCurrencyLabel.get(leadRequest.Section__r.Currency__c)) * (mapgetPlacemetShareFromCurrency.get(leadRequest.Treaty__c + '_' + leadRequest.Section__c)/100) : totalCededPremiumEUR + (leadRequest.CededPremium__c / mapRateByCurrencyLabel.get(leadRequest.Section__r.Currency__c)) * (mapgetPlacemetShareFromCurrency.get(leadRequest.Treaty__c + '_' + leadRequest.Section__c)/100);//RRA - ticket 1513 - 22052023
                                    //totalCededPremiumEUR = totalCededPremiumEUR + (leadRequest.CededPremium__c / mapRateByCurrencyLabel.get(leadRequest.Section__r.Currency__c)) * (mapgetPlacemetShareFromCurrency.get(leadRequest.Treaty__c + '_' + leadRequest.Section__c)/100);//RRA - ticket 1513 - 22052023
                            }
                        }
                    }
                }
            }
    
            System.debug('totalCededPremiumEUR 22 ==' + totalCededPremiumEUR);
            System.debug('totalCededPremiumOther==' + totalCededPremiumOther);
            String objectName = 'Program__c';
            String fieldName ='SigningPremiumCurrency__c';
            Map<String, String> mapCurrencyLabelByValue = new Map<String, String>();
            Schema.SObjectType s = Schema.getGlobalDescribe().get(objectName);
            Schema.DescribeSObjectResult r = s.getDescribe() ;
            Map<String,Schema.SObjectField> fields = r.fields.getMap() ;
            Schema.DescribeFieldResult fieldResult = fields.get(fieldName).getDescribe();
            List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            Boolean isFlagUpdate = false; 
            List<Request__c> lstReqToUpdateFlagAskValid = new List<Request__c>();
            List<Request__c> lstReqToUpdateFlagReopenprev = new List<Request__c>();
    
            for( Schema.PicklistEntry pickListVal : ple){
                mapCurrencyLabelByValue.put(pickListVal.getLabel(), pickListVal.getValue());
            }
    
            if(displayTwoFieldForPremium == true){
                program.SigningPremium__c = totalCededPremiumOther;
                if(mapCurrencyLabelByValue.containsKey(currOther)){
                    program.SigningPremiumCurrency__c = mapCurrencyLabelByValue.get(currOther);
                }
            }
            else{
                program.SigningPremium__c = totalCededPremiumEUR;
                if(mapCurrencyLabelByValue.containsKey('EUR')){
                    program.SigningPremiumCurrency__c = mapCurrencyLabelByValue.get('EUR');
                }
            }
    
            program.TECH_PremiumEUR__c = Math.roundToLong(totalCededPremiumEUR);
            program.TECH_PremiumOther__c = Math.roundToLong(totalCededPremiumOther);
    
            if(isClosePreviousBtnClick == true){
                // if(lstSigningRequest.size() > 0){
                //     update lstSigningRequest;
                // }
    
                if(lstLeadRequests.size() > 0){
                    update lstLeadRequests;
                }
            }
    
            if(program != null){
                update program;
            }
    
            System.debug('lstSigningRequest==' + lstSigningRequest);

            //RRA - ticket 1411 - 04042023
            for (Request__c req : lstSigningRequest){
                if (req.ReinsurerStatus__c == 'Sent' && req.isReopenPreviousPhase__c){
                     isFlagUpdate = true;
                }
                if (isFlagUpdate){
                    if (req.ReinsurerStatus__c == 'Setup' && req.isReopenPreviousPhase__c == false){
                        req.isReopenPreviousPhase__c = true;
                        lstReqToUpdateFlagReopenprev.add(req);
                    }else if ((req.ReinsurerStatus__c == 'Setup' || 
                                    req.ReinsurerStatus__c == 'Sent' || 
                                            req.ReinsurerStatus__c == 'Signed' || 
                                                    req.ReinsurerStatus__c == 'Timeout' ||
                                                            req.ReinsurerStatus__c == 'Signed By R.M.') && req.isAskValidation__c == false){
                        req.isAskValidation__c = true;
                        req.isAskValidateByDirecteur__c = true;
                        lstReqToUpdateFlagAskValid.add(req);
                    }
                }
            }

            //RRA - ticket 1411 - 04042023
            if (lstReqToUpdateFlagReopenprev.size()>0){
                update lstReqToUpdateFlagReopenprev;
            }

            //RRA - ticket 1411 - 04042023
            if (lstReqToUpdateFlagAskValid.size()>0){
                update lstReqToUpdateFlagAskValid;
            }

            Boolean isSignForPoolVisible = getSignForPoolVisibility();
            Boolean isDeleteVisible = getDeleteButtonVisibility();
            Boolean allowAskForValidation = allowAskForValidation(totalCededPremiumEUR);
            Boolean contractualDocSigningPresent = checkIfProgPhaseSigningHasDoc(programId);
    
            Profile profileObj = [select Id, Name from Profile where Id =: UserInfo.getProfileId()];
            
            mapResults.put('userProfile', profileObj.Name);
            mapResults.put('showClosePreviousPhaseBtn', showClosePreviousPhaseBtn);
            mapResults.put('lstSigningRequest', lstSigningRequest);
            mapResults.put('isSignPoolVisible', isSignForPoolVisible);
            mapResults.put('isDeleteVisible', isDeleteVisible);
            mapResults.put('displayTwoFieldForPremium', displayTwoFieldForPremium);
            mapResults.put('totalCededPremiumEUR', Math.roundToLong(totalCededPremiumEUR));
            mapResults.put('totalCededPremiumOther', Math.roundToLong(totalCededPremiumOther));
            mapResults.put('currencyOtherLabel', currOtherStr);
            mapResults.put('allowAskForValidation', allowAskForValidation);
            mapResults.put('contractualDocSigningPresent', contractualDocSigningPresent);
            mapResults.put('renewStatus', renewStatus);
            mapResults.put('lstFilteredSigningRequest', lstFilteredSigningRequest);
            mapResults.put('isDeactivatedProg', isDeactivatedProg); //RRA - ticket 585 -13032023
            return mapResults;
        }
    
        /**
        * @description Method get Risk carrier for request
        * @param Id null
        * @return List<OptionWrapper>
        */
        @AuraEnabled(Cacheable = true)
        public static List<OptionWrapper> getRiskCarrier(){
            Map<String, Id> mapRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectAcc});
            List<OptionWrapper> lstRiskCarrier = new List<OptionWrapper>();
    
            for(Account account : [SELECT Id, Name FROM Account WHERE RecordTypeId = :mapRecTypeId.get(AP_Constant.accRTReinsurer) AND IsRiskCarrier__c = TRUE AND IsActive__c = TRUE]){
                lstRiskCarrier.add(new OptionWrapper(account.Name, account.Id));
            }
    
            return lstRiskCarrier;
        }
    
        /**
        * @description Method get Financial Entity for request
        * @param Id null
        * @return List<OptionWrapper>
        */
        @AuraEnabled(Cacheable = true)
        public static List<OptionWrapper> getFinancialEntity(){
            Map<String, Id> mapRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectAcc});
            List<OptionWrapper> lstRiskCarrier = new List<OptionWrapper>();
    
            for(Account account : [SELECT Id, Name FROM Account WHERE RecordTypeId = :mapRecTypeId.get(AP_Constant.accRTReinsurer) AND IsFinancialEntity__c = TRUE AND IsActive__c = TRUE]){
                lstRiskCarrier.add(new OptionWrapper(account.Name, account.Id));
            }
    
            return lstRiskCarrier;
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
        * @description Method to Save Signing Request
        * @param List<Request__c> lstRequest
        * @return Map<String, Object>
        */
        @AuraEnabled
        public static Map<String, Object> saveSigningRequest(List<Request__c> lstRequest, List<Id> lstIdReqId, List<Id> lstReqId, String lossDepositMode, List<Id> lstIdReqOnChangeLossDep) { //RRA - ticket 1554 - 28082023
            System.debug('lstRequest == ' + lstRequest);
            System.debug('lstRequestSIZE == ' + lstRequest.size());
            
            System.debug('lstReqId == '+ lstReqId);
            System.debug('lstIdReqId == '+ lstIdReqId);
            Map<String, Object> mapResults = new Map<String, Object>();
            List<Request__c> lstNewVersionRequest = new List<Request__c>();
            List<Request__c> lstOriginalRequestToUpdate = new List<Request__c>();
            List<Request__c> lstUpdatedRequestsQry = new List<Request__c>();
            List<Request__c> lstUpdatedRequestVersions = new List<Request__c>();
            Set<Id> setOriginalRequestId = new Set<Id>();
            Set<Id> setLatestReqIds = new Set<Id>();
            Boolean latestRequestVersion = false;
            Map<String, Id> mapRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectRequest});
            String recordTypeIdSigning = mapRecTypeId.get(AP_Constant.reqRTSigning);
            List<String> lstRequestFields = AP_Constant.getCreatableFieldsByObjName(AP_Constant.sObjectRequest);
            String strRequestFields = String.join(lstRequestFields , ', ');
            Map<Id,Request__c> mapOriginalRequestToRequest = new Map<Id, Request__c>();
            List<Request__c> lstLatestReqVersions = new List<Request__c>();
            String statusSetup = AP_Constant.statusSetup;
            Set<Request__c> setReqSetup = new Set<Request__c>();
            Savepoint sp = Database.setSavepoint();
            List<Request__c> lstAllRequestToUpdate = new List<Request__c>();
            Map<Id, Request__c> mapRequestToUpdateById = new Map<Id, Request__c>();
            Map<Id, Request__c> mapRequestNewVersionById = new Map<Id, Request__c> ();
            Map<String, Request__c>  mapKeyBrokerReinsurerNewReq = new Map<String, Request__c> ();
            List<Request__c> lstOriginalRequestUpdated = new List<Request__c>();
            Set<Id> setIdReqIvent = new Set<Id>(); //RRA - ticket 1554 - 29082023
            Set<Id> setIdReqLossDeposit = new Set<Id>(); //RRA - Ticket 1866 - 11012023
            Boolean isDeleteVisible = getDeleteButtonVisibility(); //RRA - ticket 1554 - 28082023
            System.debug('isDeleteVisible == '+ isDeleteVisible);
            List<Request__c> lstReqUpdateLastversion = new List <Request__c>();  //RRA - ticket 1421 - 31082023
            List<Request__c> lstReqUpdateLastversionNotSelected = new List <Request__c>();  
            
            List<Request__c> lstReqUpdateOriginal = new List <Request__c>();  //RRA - ticket 1421 - 31082023
            List<Id> lstIdOrigReq = new  List<Id>();
            List<Id> lstIdRequest = new  List<Id>();
            List<Id> lstIdOrigReqNotNullTreaty = new  List<Id>();
            
            //RRA - ticket 1868 - 04012023
            List<Id> lstFinancial = new List<Id>();
            List<Id> lstProgramId = new List<Id>();
            List<Id> lstIdOrigReqLossDep = new List<Id>();//RRA - Ticket 1866 - 11012023
            List<Id> lstIdOrigReqLossDep2 = new List<Id>();//RRA - Ticket 1866 - 11012023
            List<Request__c> lstRequestOrigToUpdated = new List<Request__c>();//RRA - Ticket 1866 - 11012023
            List<Request__c> lstRequestOrigToUpdatedLossDep = new List<Request__c>();//RRA - Ticket 1866 - 11012023
            List<Request__c> lstRequestOrigToUpdatedDepLoss = new List<Request__c>();//RRA - Ticket 1866 - 11012023
            List<Request__c> lstOriginalRequestUpdatedFinal = new List<Request__c>();
            List<Request__c> lstOriginalRequestUpdatedRisk = new List<Request__c>();
            Set<Id> setIdTreaty = new Set<Id>();
            
            map <Id, Id> mapIdOrigReqIdFin = new map <Id, Id>();
            map <Id, Request__c> mapIdOrigReqIdReq = new map <Id, Request__c>();
            setIdReqIvent.addAll(lstReqId);
            setIdReqLossDeposit.addAll(lstIdReqOnChangeLossDep); //RRA - Ticket 1866 - 11012023
            System.debug('setIdReqIvent == '+ setIdReqIvent);
            System.debug('lstIdReqOnChangeLossDep == '+ lstIdReqOnChangeLossDep);
            System.debug('setIdReqLossDeposit == '+ setIdReqLossDeposit);
            try{
                for(Request__c req : lstRequest){
                    lstIdOrigReq.add(req.OriginalRequest__c);
                    lstIdRequest.add(req.Id);//RRA - ticket 1421 - 01092023
                    if(req.OriginalRequest__c != null){
                        mapOriginalRequestToRequest.put(req.OriginalRequest__c, req);
                    }else{
                        mapOriginalRequestToRequest.put(req.Id, req);
                    }
    
                    if(req.ReinsurerStatus__c == 'Setup'){
                        setReqSetup.add(req);
                    }
                    else if(req.OriginalRequest__c == null){
                        lstLatestReqVersions.add(req);
                    }
                    
                    //RRA - ticket 1554 - 28082023 - to know if Admin or CE clicked on button save signing - Update TECH_isAdmin__c value on requests last version
                    //**TECH_isAdmin__c = true => Admin insert lossDeposit in database 
                    //**TECH_isAdmin__c = false => CE insert lossdeposit in database */ 
                    for (Id idReq : setIdReqLossDeposit){ //RRA - Ticket 1866 - 11012023
                        //libe last version request
                        if (req.OriginalRequest__c == idReq){
                            if (isDeleteVisible){
                                req.LossDeposit__c = '1'; //RRA - Ticket 1866 - 11012023
                                req.TECH_isAdmin__c = true; 
                            }else {
                                req.TECH_isAdmin__c = false; 
                            }
                            lstReqUpdateLastversion.add(req);
                        }else if(req.Id == idReq){ //RRA - ticket 1421 - 01092023
                            if (isDeleteVisible){
                                req.LossDeposit__c = '1'; //RRA - Ticket 1866 - 11012023
                                req.TECH_isAdmin__c = true; 
                            }else {
                                req.TECH_isAdmin__c = false; 
                            }
                            lstReqUpdateLastversion.add(req);
                        }
                    }
                }
                 //RRA - ticket 1421 - 31082023 
                 if (lstReqUpdateLastversion.size()>0){
                    //update lstReqUpdateLastversion;
                }
                System.debug('lstReqUpdateLastversion == '+ lstReqUpdateLastversion);
                
                 /*List<Request__c> lstReqUpdate = [SELECT Id, Treaty__c FROM Request__c WHERE Id IN:setIdReqLossDeposit];
                 for (Request__c req : lstReqUpdate){
                    setIdTreaty.add(req.Treaty__c);
                 }
                 
                 System.debug('setIdTreaty == '+ setIdTreaty);
                 
                 List<Request__c> lstReqUpdateLossDep = [SELECT Id, Treaty__c, LossDeposit__c, TECH_isAdmin__c, LossDepositMode__c FROM Request__c WHERE Treaty__c IN:setIdTreaty AND LossDeposit__c = '2' AND TECH_isAdmin__c = false AND LossDepositMode__c != null AND recordtype.name = 'Signing Request'];
                 
                 System.debug('lstReqUpdateLossDep before == '+ lstReqUpdateLossDep);
                 
                 if (lstReqUpdateLossDep.size()>0){
                    for (Request__c reqUpdate : lstReqUpdate){
                        reqUpdate.LossDeposit__c = '1';
                        reqUpdate.TECH_isAdmin__c = true;
                    }
                    update lstReqUpdateLossDep;
                 }
                
                 System.debug('lstReqUpdateLossDep after == '+ lstReqUpdateLossDep);*/
                
                 
                 //RRA - Ticket 1866 - 11012023 
                 if (lstReqUpdateLastversion.size()>0){
                     for (Request__c req : lstReqUpdateLastversion){
                         if (req.OriginalRequest__c != null){
                            lstIdOrigReqLossDep.add(req.OriginalRequest__c);
                         }
                     }
                    
                     System.debug('lstIdOrigReqLossDep == '+ lstIdOrigReqLossDep);
                     if (lstIdOrigReqLossDep.size()>0){
                          //Update TECH_isAdmin__c = true for Original Request is null and  Original Request is not null
                        for (Request__c reqLoss : [SELECT Id, TECH_isAdmin__c, LossDeposit__c, OriginalRequest__c FROM Request__c WHERE (Id IN:lstIdOrigReqLossDep OR OriginalRequest__c IN: lstIdOrigReqLossDep )]){
                            if (reqLoss.TECH_isAdmin__c == false){
                                reqLoss.TECH_isAdmin__c = true;
                            }
                            if (reqLoss.LossDeposit__c == '2'){
                                reqLoss.LossDeposit__c = '1';
                            }
                            lstRequestOrigToUpdated.add(reqLoss);
                        }
                    }
                 }
                 
                  //RRA - Ticket 1866 - 11012023 
                if (lstRequestOrigToUpdated.size()>0){
                    update lstRequestOrigToUpdated;
                }
        
        
                System.debug('lstReqUpdateLastversion == ' + lstReqUpdateLastversion);
                 System.debug('lossDepositMode == ' + lossDepositMode);
                 
                //For LossDepositLevel = Treaty - Update line original request
                if (lossDepositMode == 'Treaty'){
                    if (setIdReqIvent != null){
                        for (Request__c req : [SELECT Id, OriginalRequest__c FROM Request__c WHERE Id IN: setIdReqIvent ]){
                            if (req.OriginalRequest__c != null){
                                lstIdOrigReqNotNullTreaty.add(req.OriginalRequest__c);
                            }
                        }
                        List<Request__c> lstReqUpdateReqOrig = [SELECT Id, OriginalRequest__c, TECH_isAdmin__c FROM Request__c WHERE Id IN: lstIdOrigReqNotNullTreaty ];
                        if (lstReqUpdateReqOrig.size()>0){
                            for(Request__c req : lstReqUpdateReqOrig){
                                if (isDeleteVisible){
                                    req.TECH_isAdmin__c = true; 
                                }else {
                                    req.TECH_isAdmin__c = false; 
                                }
                            }
                        }
                        
                        //RRA - ticket 1421 - 08092023 
                        if (lstReqUpdateReqOrig.size()>0){
                            update lstReqUpdateReqOrig;
                        }
                    }
                }else if (lossDepositMode == 'Program'){
                    //For LossDepositLevel = Program - Update line original request
                    if (lstIdOrigReq != null){
                        //RRA - ticket 1421 - 31082023 to know if Admin or CE clicked on button save signing - Update TECH_isAdmin__c value on original request
                        for(Request__c req : [SELECT Id, OriginalRequest__c FROM Request__c WHERE Id IN: lstIdOrigReq ]){
                            if (req.Id != null){
                                for (Id idReq : setIdReqIvent){
                                    //libe last version request
                                    if (req.Id == idReq){
                                        if (isDeleteVisible){
                                            req.TECH_isAdmin__c = true; 
                                        }else {
                                            req.TECH_isAdmin__c = false; 
                                        }
                                        lstReqUpdateOriginal.add(req);
                                    }
                                }
                            }
                        }
                    }
                    //RRA - ticket 1421 - 31082023 
                    if (lstReqUpdateOriginal.size()>0){
                        update lstReqUpdateOriginal;
                    }
                }

                System.debug('lstIdRequest == ' + lstIdRequest);
                System.debug('lstIdRequest 22 size== ' + lstIdRequest.size());
                
                System.debug('lstIdOrigReq == ' + lstIdOrigReq);
                System.debug('lstIdOrigReq 22 size== ' + lstIdOrigReq.size());
                
                System.debug('lstReqUpdateLastversion 22 size== ' + lstReqUpdateLastversion.size());
                System.debug('lstReqUpdateLastversion 22 == ' + lstReqUpdateLastversion);
                
                System.debug('lstReqUpdateOriginal 22 size== ' + lstReqUpdateOriginal.size());
                System.debug('lstReqUpdateOriginal 22 == ' + lstReqUpdateOriginal);
                //}
                System.debug('mapOriginalRequestToRequest == ' + mapOriginalRequestToRequest);
                System.debug('setReqSetup == ' + setReqSetup);
                System.debug('lstLatestReqVersions == ' + lstLatestReqVersions);
    
                String programId = lstRequest[0].Program__c;
    
                String querySigning = 'SELECT Id, TECH_TreatyName__c, Treaty__r.PlacementShare_Perc__c, TECH_BrokerName__c, TECH_IsBrokerPresent__c, TECH_ReinsurerName__c, TECH_Layer__c, TECH_UWyear__c, SigningRegionalManager__r.Email '
                + ', RiskCarrier__r.Name, FinancialEntity__r.Name, Program__r.LossDepositMode__c, Program__r.LossDeposit__c '
                + ', Treaty__r.LossDepositMode__c, Treaty__r.LossDeposit__c '
                + ', Treaty__r.TypeofTreaty__c, Treaty__r.PremiumDeposit__c, Program__r.LossDepositLevel__c, Pool__r.Name, Pool__r.AssignedTo__r.Email, Program__r.Name, program__r.principalcedingcompany__r.Name, '
                +  strRequestFields
                + ' from Request__c where (Program__c = :programId AND RecordTypeId = :recordTypeIdSigning AND Program__c != NULL AND LastVersionSent__c = True AND LastVersionAnswered__c = TRUE) '; //RRA - ticket 1397 - 09012023 
    
                lstUpdatedRequestsQry =  Database.query(querySigning);

                System.debug('lstUpdatedRequestsQry == ' + lstUpdatedRequestsQry);
    
                for(Request__c lastVersionReq : lstUpdatedRequestsQry){
                    if(lastVersionReq.ReinsurerStatus__c != 'Setup'){
                        // lstUpdatedRequestVersions.add(lastVersionReq);
                        if(mapOriginalRequestToRequest.containskey(lastVersionReq.OriginalRequest__c)){
                            Request__c request = mapOriginalRequestToRequest.get(lastVersionReq.OriginalRequest__c);
                            if(request.Id == lastVersionReq.Id){
                                lstLatestReqVersions.add(request);
                                System.debug('lstLatestReqVersions ok égaux');
                            }
                            else{
    
                                if(lastVersionReq.ReinsurerStatus__c != AP_Constant.statusSetup || request.ReinsurerStatus__c != AP_Constant.statusSetup) {
                                    //updates with latest data
                                    if(request.BrokerStatus__c != null) {
                                        lastVersionReq.BrokerStatus__c = request.BrokerStatus__c;
                                    }
    
                                    if(request.RiskCarrier__c != null) {
                                        lastVersionReq.RiskCarrier__c = request.RiskCarrier__c;
                                    }
    
                                    if(request.FinancialEntity__c != null) {
                                        lastVersionReq.FinancialEntity__c = request.FinancialEntity__c;
                                    }
                                    
                                    lastVersionReq.SignedShare__c = request.SignedShare__c;
                                    lastVersionReq.Deductions__c = request.Deductions__c;
                                    lastVersionReq.RetrocessionBrokerage__c = request.RetrocessionBrokerage__c != null ? request.RetrocessionBrokerage__c : 0; //RRA - 1090
                                    lstLatestReqVersions.add(lastVersionReq);

                                    System.debug('lstLatestReqVersions ko non  égaux');
                                }
                            }
                        }
                    }
                }

               // RRA - ticket 1397 - Update line original Request 
               List<Request__c> lstReqUpdateOrigReq = [SELECT Id, OriginalRequest__c, FinancialEntity__c, RiskCarrier__c, BrokerStatus__c, SignedShare__c, Deductions__c, RetrocessionBrokerage__c, LossDepositMode__c, PremiumDeposit__c FROM Request__c WHERE  Id IN: lstIdReqId];
               //map <Id, Request__c> mapIdReqReq = new map <Id,Request__c>();
               for (Request__c req1 : lstReqUpdateOrigReq){
                   if (req1.OriginalRequest__c == null){
                       System.debug('map == '+ mapOriginalRequestToRequest.get(req1.Id).FinancialEntity__c);
                       //mapIdReqReq.put(req.Id, req);
                       req1.FinancialEntity__c = mapOriginalRequestToRequest.get(req1.Id).FinancialEntity__c;
                       req1.RiskCarrier__c = mapOriginalRequestToRequest.get(req1.Id).RiskCarrier__c;
                       req1.BrokerStatus__c = mapOriginalRequestToRequest.get(req1.Id).BrokerStatus__c;
                       req1.SignedShare__c = mapOriginalRequestToRequest.get(req1.Id).SignedShare__c;
                       req1.Deductions__c = mapOriginalRequestToRequest.get(req1.Id).Deductions__c;
                       req1.RetrocessionBrokerage__c = mapOriginalRequestToRequest.get(req1.Id).RetrocessionBrokerage__c;
                       req1.LossDepositMode__c = mapOriginalRequestToRequest.get(req1.Id).LossDepositMode__c;
                       req1.PremiumDeposit__c = mapOriginalRequestToRequest.get(req1.Id).PremiumDeposit__c;
                   }
               }
           
               if (lstReqUpdateOrigReq.size()>0){
                   update lstReqUpdateOrigReq;
               }


                System.debug('lstLatestReqVersions22 == ' + lstLatestReqVersions);
    
                List<Request__c> lstRequestNew = new List<Request__c>();
    
                if(lstLatestReqVersions.size() > 0){
                    lstRequestNew.addAll(lstLatestReqVersions);
                }
    
                if(setReqSetup.size() > 0){
                    lstRequestNew.addAll(setReqSetup);
                }

                System.debug('lstRequestNew == ' + lstRequestNew);
                
              
                for(Request__c request : lstRequestNew) {
                    if(!mapRequestToUpdateById.containsKey(request.Id)){
                        //10/05/2022 Azhar Nahoor - W-1104 : Do not create versions
                        if(request.ReinsurerStatus__c != AP_Constant.statusSetup) {
                            /*request.LastVersionSent__c = false;
                            request.LastVersionAnswered__c = false;
                            request.VersionMinor__c = request.VersionMinor__c + 1;
    
                            if(request.OriginalRequest__c != null) {
                                Request__c originalRequest = request.clone(false, false, false, false);
                                originalRequest.Id = request.OriginalRequest__c;
                                originalRequest.OriginalRequest__c = null;
                                lstOriginalRequestToUpdate.add(originalRequest);
                            }
    
                            Request__c newVersionRequest = request.clone(false, false, false, false);
                            if(request.OriginalRequest__c == null) {
                                newVersionRequest.OriginalRequest__c = request.Id;
                                 //setOriginalRequestId.add(request.OriginalRequest__c);
                            }else {
                                newVersionRequest.OriginalRequest__c = request.OriginalRequest__c;
                                setOriginalRequestId.add(request.OriginalRequest__c);
                            }*/

                            // RRA - 1104 23/05/2022
                            if (request.OriginalRequest__c != null){
                                setOriginalRequestId.add(request.OriginalRequest__c);
                            }
    
                            /*newVersionRequest.LastVersionSent__c = true;
                            newVersionRequest.LastVersionAnswered__c = true;
                            newVersionRequest.TECH_Actor2Id__c = null;
                            lstNewVersionRequest.add(newVersionRequest);*/
                            if (request.Broker__c != null){
                                mapKeyBrokerReinsurerNewReq.put(request.Broker__c + '_' + request.Reinsurer__c + '_' + request.Treaty__c, request);
                            }else if (request.Reinsurer__c != null){
                                mapKeyBrokerReinsurerNewReq.put(request.Reinsurer__c + '_' + request.Treaty__c, request);
                            }
                          
                        }
                        mapRequestToUpdateById.put(request.Id, request);
                    }
                }

                System.debug('mapKeyBrokerReinsurerNewReq == ' + mapKeyBrokerReinsurerNewReq);
    
                List<Request__c> lstAllRequestVersion = new List<Request__c>();
    
                if(setOriginalRequestId.size() > 0){
                    lstAllRequestVersion = [SELECT Id, Name, LossDepositMode__c, LossDeposit__c, TECH_isAdmin__c, LastVersionSent__c, LastVersionAnswered__c, OriginalRequest__c FROM Request__c WHERE OriginalRequest__c IN :setOriginalRequestId];
                }

                System.debug('lstAllRequestVersion == ' + lstAllRequestVersion);
    
                mapResults.put('lstRequest', lstRequestNew);
    
                for(Request__c request : lstAllRequestVersion){
                    if(!mapRequestToUpdateById.containsKey(request.Id)){
                        request.LastVersionAnswered__c = false;
                        request.LastVersionSent__c = false;
                        mapRequestToUpdateById.put(request.Id, request);
                    }  
                }

                System.debug('mapRequestToUpdateById == ' + mapRequestToUpdateById);

                System.debug('lstIdReqId == ' + lstIdReqId);
                
                //***
                //RRA - 1104 23/05/2022 - Updating the original request line when a new version of the request has been created - 1104
                //****/

                List<Id> lstIdOriginalRequest = new List<Id>();

                // Get the Original Request cloned for the line origine of request 
                List<Request__c> lstIdOriginalReq = [SELECT OriginalRequest__c, FinancialEntity__c, RiskCarrier__c FROM Request__c WHERE Id IN: lstIdReqId];
                    
                //RRA - ticket 1421 - 01092023
                if (lstIdOriginalReq.size()>0 && lstIdOriginalReq != null){
                    // loop on the records Original Request cloned and get the OriginalRequestId
                    for (Request__c reqOrigine : lstIdOriginalReq){
                        if (reqOrigine.OriginalRequest__c != null){
                            lstIdOriginalRequest.add(reqOrigine.OriginalRequest__c);
                        }
                    }

                    System.debug('lstIdOriginalRequest == ' + lstIdOriginalRequest);
                    
                    
                    

                    // Get the request data original from OriginalRequestId of the request cloned
                    List<Request__c> lstOriginalReqData = [SELECT Id, BrokerStatus__c, Program__c, Broker__c, OriginalRequest__c, Reinsurer__c, Treaty__c, RiskCarrier__c, FinancialEntity__c, SignedShare__c, Deductions__c, RetrocessionBrokerage__c, LossDepositMode__c, PremiumDeposit__c FROM  Request__c WHERE Id IN: lstIdOriginalRequest];
                    System.debug('lstOriginalReqData == ' + lstOriginalReqData);
                        // Loop on the request origine and : 
                    for (Request__c reqOrigine : lstOriginalReqData){
                        // 1- chek if key (broker - reinsurer - treaty) exists on the last requests created (requests cloned)
                        if (mapKeyBrokerReinsurerNewReq.containsKey(reqOrigine.Broker__c + '_' + reqOrigine.Reinsurer__c + '_' + reqOrigine.Treaty__c)){
                            System.debug('is broker ');
                            reqOrigine.BrokerStatus__c = mapKeyBrokerReinsurerNewReq.get(reqOrigine.Broker__c + '_' + reqOrigine.Reinsurer__c + '_' + reqOrigine.Treaty__c).BrokerStatus__c;
                            reqOrigine.RiskCarrier__c = mapKeyBrokerReinsurerNewReq.get(reqOrigine.Broker__c + '_' + reqOrigine.Reinsurer__c + '_' + reqOrigine.Treaty__c).RiskCarrier__c;
                            reqOrigine.FinancialEntity__c = mapKeyBrokerReinsurerNewReq.get(reqOrigine.Broker__c + '_' + reqOrigine.Reinsurer__c + '_' + reqOrigine.Treaty__c).FinancialEntity__c;
                            reqOrigine.SignedShare__c = mapKeyBrokerReinsurerNewReq.get(reqOrigine.Broker__c + '_' + reqOrigine.Reinsurer__c + '_' + reqOrigine.Treaty__c).SignedShare__c;
                            reqOrigine.Deductions__c = mapKeyBrokerReinsurerNewReq.get(reqOrigine.Broker__c + '_' + reqOrigine.Reinsurer__c + '_' + reqOrigine.Treaty__c).Deductions__c;
                            reqOrigine.RetrocessionBrokerage__c = mapKeyBrokerReinsurerNewReq.get(reqOrigine.Broker__c + '_' + reqOrigine.Reinsurer__c + '_' + reqOrigine.Treaty__c).RetrocessionBrokerage__c;
                            reqOrigine.LossDepositMode__c = mapKeyBrokerReinsurerNewReq.get(reqOrigine.Broker__c + '_' + reqOrigine.Reinsurer__c + '_' + reqOrigine.Treaty__c).LossDepositMode__c;
                            reqOrigine.PremiumDeposit__c = mapKeyBrokerReinsurerNewReq.get(reqOrigine.Broker__c + '_' + reqOrigine.Reinsurer__c + '_' + reqOrigine.Treaty__c).PremiumDeposit__c;
                            lstOriginalRequestUpdated.add(reqOrigine);
                        }

                        //2- chek if key (reinsurer - treaty) exists on the last requests created (requests cloned)
                        if (mapKeyBrokerReinsurerNewReq.containsKey(reqOrigine.Reinsurer__c + '_' + reqOrigine.Treaty__c)){
                            System.debug('is reinsurer ');
                            reqOrigine.BrokerStatus__c = mapKeyBrokerReinsurerNewReq.get(reqOrigine.Reinsurer__c + '_' + reqOrigine.Treaty__c).BrokerStatus__c;
                            reqOrigine.RiskCarrier__c = mapKeyBrokerReinsurerNewReq.get(reqOrigine.Reinsurer__c + '_' + reqOrigine.Treaty__c).RiskCarrier__c;
                            reqOrigine.FinancialEntity__c = mapKeyBrokerReinsurerNewReq.get(reqOrigine.Reinsurer__c + '_' + reqOrigine.Treaty__c).FinancialEntity__c;
                            reqOrigine.SignedShare__c = mapKeyBrokerReinsurerNewReq.get(reqOrigine.Reinsurer__c + '_' + reqOrigine.Treaty__c).SignedShare__c;
                            reqOrigine.Deductions__c = mapKeyBrokerReinsurerNewReq.get(reqOrigine.Reinsurer__c + '_' + reqOrigine.Treaty__c).Deductions__c;
                            reqOrigine.RetrocessionBrokerage__c = mapKeyBrokerReinsurerNewReq.get(reqOrigine.Reinsurer__c + '_' + reqOrigine.Treaty__c).RetrocessionBrokerage__c;
                            reqOrigine.LossDepositMode__c = mapKeyBrokerReinsurerNewReq.get(reqOrigine.Reinsurer__c + '_' + reqOrigine.Treaty__c).LossDepositMode__c;
                            reqOrigine.PremiumDeposit__c = mapKeyBrokerReinsurerNewReq.get(reqOrigine.Reinsurer__c + '_' + reqOrigine.Treaty__c).PremiumDeposit__c;
                            lstOriginalRequestUpdated.add(reqOrigine);
                        }
                    }
                    System.debug('lstOriginalRequestUpdated.size == ' + lstOriginalRequestUpdated.size());
                    System.debug('lstOriginalRequestUpdated == ' + lstOriginalRequestUpdated);
                }
    
                //RRA - 1079
               /* if (lstOriginalRequestToUpdate.size() > 0){
                    update lstOriginalRequestToUpdate;
                }*/
                
                //W-1104
                // if(lstNewVersionRequest.size() > 0){
                //     insert lstNewVersionRequest;
                // }
                List<Request__c> lstReqUpdated = new List<Request__c>();
                if(mapRequestToUpdateById.size() > 0){
                    lstAllRequestToUpdate = mapRequestToUpdateById.values();
    
                    if(lstAllRequestToUpdate.size() > 0){
                        update lstAllRequestToUpdate;
                    }
                    
                    for (Request__c request : lstAllRequestToUpdate){
                        //RRA - Ticket 1866 - 15012024
                        if (request.LossDepositMode__c != null && request.LossDeposit__c == '2'){
                            request.LossDeposit__c = '1';
                        }
                        if (isDeleteVisible){
                            if (request.LossDepositMode__c != null && request.LossDeposit__c == '1' && request.TECH_isAdmin__c == false){
                                request.TECH_isAdmin__c = true; 
                            }
                        }else {
                            request.TECH_isAdmin__c = false; 
                        }
                        lstReqUpdated.add(request);
                    }
                    update lstReqUpdated;
                }

                // Update the line request origine
                if (lstOriginalRequestUpdated.size() > 0){
                    update lstOriginalRequestUpdated;
                }
                
                
                 //RRA - ticket 1868 - 04012023
                 //Get the financial entity completed on original Request
                for (Request__c req : lstOriginalRequestUpdated){
                    lstProgramId.add(req.Program__c);
                    if (req.OriginalRequest__c == null && req.FinancialEntity__c != null){
                        lstFinancial.add(req.FinancialEntity__c);
                    }
                }
                
                System.debug('lstFinancial == ' + lstFinancial);
                System.debug('lstProgramId == ' + lstProgramId);
                
                 //RRA - ticket 1868 - 04012023
                 //Get all Ids of OriginalRequest__c from list financial entity and the last version request (for many requests with the same reinsurer but treaty different) via map
                if (lstFinancial.size()>0){
                    for (Request__c req : [SELECT Id, FinancialEntity__c, OriginalRequest__c, Program__c FROM Request__c WHERE FinancialEntity__c IN:lstFinancial AND Program__c IN:lstProgramId AND RecordType.Name = 'Signing Request' AND OriginalRequest__c != null AND LastVersionSent__c= true AND LastVersionAnswered__c = true]){
                        if (req.OriginalRequest__c != null){
                            mapIdOrigReqIdFin.put(req.OriginalRequest__c, req.FinancialEntity__c);
                        }
                    } 
                }
                //RRA - ticket 1877 - 10012023
                //Get all request with last version
                List<Request__c> lstRequestSignLastversion = [SELECT Id, FinancialEntity__c, SignedShare__c, RiskCarrier__c, Deductions__c, RetrocessionBrokerage__c, LossDepositMode__c, PremiumDeposit__c, BrokerStatus__c, OriginalRequest__c, Program__c FROM Request__c WHERE Program__c IN:lstProgramId AND RecordType.Name = 'Signing Request' AND OriginalRequest__c != null AND LastVersionSent__c= true AND LastVersionAnswered__c = true];
                
                if (lstRequestSignLastversion.size()>0){
                    for (Request__c req : lstRequestSignLastversion){
                        if (req.OriginalRequest__c != null){
                            mapIdOrigReqIdReq.put(req.OriginalRequest__c, req);
                        }
                    } 
                }
  
                System.debug('mapIdOrigReqIdFin == ' + mapIdOrigReqIdFin);
                System.debug('mapIdOrigReqIdReq == ' + mapIdOrigReqIdReq);
                System.debug('mapIdOrigReqIdReq.KeySet() == ' + mapIdOrigReqIdReq.KeySet());
                System.debug('mapIdOrigReqIdFin.KeySet() == ' + mapIdOrigReqIdFin.KeySet());
                
                //RRA - ticket 1868 - 04012023 and RRA - ticket 1877 - 10012023
                // Get the Requests Origin to update from map request lastversion
                List<Request__c> lstRequestOrigToUpdate = [SELECT Id, FinancialEntity__c, SignedShare__c, RiskCarrier__c, RetrocessionBrokerage__c, PremiumDeposit__c, LossDepositMode__c, BrokerStatus__c, Deductions__c, OriginalRequest__c, Treaty__c FROM Request__c WHERE (Id IN:mapIdOrigReqIdFin.KeySet() OR  Id IN:mapIdOrigReqIdReq.KeySet()) AND OriginalRequest__c = null];
                
                System.debug('lstRequestOrigToUpdate == ' + lstRequestOrigToUpdate);
                
                if (lstRequestOrigToUpdate.size()>0){
                    for (Request__c req : lstRequestOrigToUpdate){
                        req.FinancialEntity__c = mapIdOrigReqIdReq.get(req.Id).FinancialEntity__c;
                        req.RiskCarrier__c = mapIdOrigReqIdReq.get(req.Id).RiskCarrier__c;
                        req.LossDepositMode__c = mapIdOrigReqIdReq.get(req.Id).LossDepositMode__c;
                        req.Deductions__c = mapIdOrigReqIdReq.get(req.Id).Deductions__c;
                        req.PremiumDeposit__c = mapIdOrigReqIdReq.get(req.Id).PremiumDeposit__c;
                        req.BrokerStatus__c = mapIdOrigReqIdReq.get(req.Id).BrokerStatus__c;
                        req.SignedShare__c = mapIdOrigReqIdReq.get(req.Id).SignedShare__c;
                        req.RetrocessionBrokerage__c = mapIdOrigReqIdReq.get(req.Id).RetrocessionBrokerage__c;
                        lstOriginalRequestUpdatedFinal.add(req);
                    }
                    //RRA - ticket 1868 - 04012023
                    if (lstOriginalRequestUpdatedFinal.size() > 0){
                        update lstOriginalRequestUpdatedFinal;
                    }
                }

                 //RRA - Ticket 1866 - 11012023
                List<Request__c> lstReqUpdate = [SELECT Id, Treaty__c FROM Request__c WHERE Id IN:setIdReqLossDeposit];
                List<Request__c> lstReqUpdateLossDeposit = new   List<Request__c>();
                for (Request__c req : lstReqUpdate){
                    setIdTreaty.add(req.Treaty__c);
                 }
                
                 System.debug('setIdTreaty == ' + setIdTreaty);
                 
                 if (setIdTreaty.size()>0){
                    for (Request__c reqUpdate : [SELECT Id, Treaty__c, LossDeposit__c, TECH_isAdmin__c, LossDepositMode__c FROM Request__c WHERE Treaty__c IN:setIdTreaty AND LossDeposit__c = '2' AND TECH_isAdmin__c = false AND LossDepositMode__c != null AND recordtype.name = 'Signing Request' AND OriginalRequest__c != null]){
                        reqUpdate.LossDeposit__c = '1';
                        reqUpdate.TECH_isAdmin__c = true;
                        lstReqUpdateLossDeposit.add(reqUpdate);
                    }
                 }
                 
                   
                 System.debug('lstReqUpdateLossDeposit == ' + lstReqUpdateLossDeposit);
                 
                 if (lstReqUpdateLossDeposit.size()>0){
                    update lstReqUpdateLossDeposit;
                 }
                
                System.debug('lstAllRequestToUpdate == ' + lstAllRequestToUpdate);
                System.debug('lstOriginalRequestUpdated UPDATED OK == ' + lstOriginalRequestUpdated);
    
                mapResults.put('Success', 'Success');
            }catch(Exception ex) {
                mapResults.put('Error', ex.getMessage());
                Database.rollback(sp);
            }
            return mapResults;
        }
    
        /**
        * @description Method to update Written Signed Share of Signing request
        * @param List<Request__c> lstRequest
        * @return Map<String, Object>
        */
        @AuraEnabled
        public static Map<String, Object> updateWrittenSignedShare(List<Request__c> lstRequest) {
            Map<String, Object> mapResults = new Map<String, Object>();
            try{
                List<Request__c> lstUpRequests = new List<Request__c>();
    
                for(Request__c req : lstRequest){
                    Request__c newRequest = new Request__c();
                    newRequest.Id = req.Id;
                    newRequest.SignedShare__c = req.SignedShare__c;
                    lstUpRequests.add(newRequest);
                }
    
                if(lstUpRequests.size() > 0){
                    update lstUpRequests;
                }
    
                mapResults.put('Success', 'Success');
            } catch (Exception ex) {
                mapResults.put('Error', ex.getMessage());
            }
            return mapResults;
        }
    
        /**
        * @description Method to check if SFP page is visible
        * @param null
        * @return Boolean
        */
        @AuraEnabled
        public static Boolean getSignForPoolVisibility(){
            Boolean isVisible = false;
            Id userId = UserInfo.getUserRoleId();
            List <UserRole> lstRoleNames = [SELECT Name
            FROM UserRole
            WHERE Id =: userId];
    
            for(Integer i = 0; i < lstRoleNames.size(); i++){
                UserRole role = lstRoleNames[i];
                isVisible = (role.Name == Label.Head_of_GRID)? true : false;
            }
            return isVisible;
        }
    
        /**
        * @description Method to check delete button visibility
        * @param null
        * @return Boolean
        */
        @AuraEnabled
        public static Boolean getDeleteButtonVisibility(){
            Boolean isVisible = false;
            Id userId = UserInfo.getProfileId();
            Profile profile = [SELECT Name  FROM Profile  WHERE Id =: userId];
            isVisible = (profile.Name == Label.Super_user || profile.Name == AP_Constant.profileSysAdmin || profile.Name == AP_Constant.profileSysAdminAGRe || profile.Name == AP_Constant.profileDelagatedAdmin )? true : false;
            return isVisible;
        }
    
        /**
        * @description Method to check if user may ask for validation
        * @param Integer premiumEUR
        * @return Boolean
        */
        @AuraEnabled
        public static Boolean allowAskForValidation(Decimal premiumEUR){
            Id userRoleId = UserInfo.getUserRoleId();
            Boolean allowAskForValidation = false;
    
            if(userRoleId != null){
                UserRole userRole = [SELECT Id, DeveloperName FROM UserRole WHERE Id =: userRoleId];
                if(userRole != null){
                    String userRoleName = userRole.DeveloperName;
    
                    // using Custom Metadata Types
                    List<CM_RoleRange__mdt> lstCMRoleRange = [SELECT MasterLabel, Premium_Limit__c FROM CM_RoleRange__mdt WHERE MasterLabel = :userRoleName];
    
                    // If premium > limit of user -> Open Validation Screen
                    // else -> "You don't need to ask for a validation and you can just send your Signing Requests"
                    if(lstCMRoleRange.size() > 0){
                        Integer premiumLimitForUser = (Integer) lstCMRoleRange[0].Premium_Limit__c;
                        if(premiumLimitForUser == 0){
                            allowAskForValidation = false;
                        }
                        else if(Math.roundToLong(premiumEUR) >= premiumLimitForUser){
                            allowAskForValidation = true;
                        }
                        else{
                            allowAskForValidation = false;
                        }
                    }
                }
            }
            return allowAskForValidation;
        }
    
        /**
        * @description Method to close and notify webXL signing requests
        * @param Id programId, List<String> lstSigningRequestId
        * @return Map<String, Object>
        */
        @AuraEnabled
        public static Map<String, Object> closeSigningNotifyWebXL(Id programId, List<String> lstSigningRequestId){
            System.debug('lstSigningRequestId == ' + lstSigningRequestId);
            Map<String,Object> mapResult = new Map<String,Object>();
            List<Messaging.SingleEmailMessage> lstMails =  new List<Messaging.SingleEmailMessage>();
            Boolean allRequestSigned = true;
            //RRA - 1078
            List<Request__c> lstRequestSigningLastVersionToTrue = new List<Request__c>();
            List<Request__c> lstRequestSigningLastVersionToFalse = new List<Request__c>();
            try {
                //Get the request lastVersion to true 
                List<Request__c> lstSigningRequests = [SELECT Id, Name, ReinsurerStatus__c, SigningStatus__c, TECH_OldSigningStatus__c FROM Request__c WHERE Id IN :lstSigningRequestId];
                //Get the request lastVersion to false 
                List<Request__c> lstRequestSigningAllLastVersToFalse = [SELECT Id, Program__c, ReinsurerStatus__c, SigningStatus__c FROM Request__c WHERE Program__c =:programId AND (ReinsurerStatus__c = 'Signed' OR ReinsurerStatus__c ='Signed By R.M.') AND LastVersionSent__c = FALSE AND LastVersionAnswered__c = FALSE];

                System.debug('lstSigningRequests == ' + lstSigningRequests);
                //SAU update
                for(Request__c req : lstSigningRequests){
                    if(req.ReinsurerStatus__c != AP_Constant.statusRequestSigned && req.ReinsurerStatus__c != AP_Constant.statusSigned){
                        allRequestSigned = false;
                    }else if (req.ReinsurerStatus__c == AP_Constant.statusRequestSigned && req.ReinsurerStatus__c == AP_Constant.statusSigned){
                        allRequestSigned = true;
                    }

                    System.debug('allRequestSigned == ' + allRequestSigned);
                }
    
                if(allRequestSigned == true){
                    for(Request__c signingRequest : lstSigningRequests){
                        signingRequest.TECH_OldSigningStatus__c = signingRequest.SigningStatus__c;
                        signingRequest.SigningStatus__c = AP_Constant.statusRequestClosed; // set SigningStatus__c to Closed
                        lstRequestSigningLastVersionToTrue.add(signingRequest); //RRA - 1078
                    }
    
                    /*if(lstSigningRequests.size() > 0){
                        update lstSigningRequests;
                    }*/
                    //RRA - 1078
                    if(lstRequestSigningLastVersionToTrue.size() > 0){
                        update lstRequestSigningLastVersionToTrue;
                    }


                    if (lstRequestSigningAllLastVersToFalse.size() >0){
                        for(Request__c req : lstRequestSigningAllLastVersToFalse){
                            if (req.SigningStatus__c == '1'){
                                req.SigningStatus__c = AP_Constant.statusRequestClosed;
                            }
                            lstRequestSigningLastVersionToFalse.add(req);
                        }
                    }

                    if(lstRequestSigningLastVersionToFalse.size() > 0){
                        update lstRequestSigningLastVersionToFalse;
                    }
    
                    Program__c program = [SELECT Id, Name, PrincipalCedingCompany__r.EmailPCLife__c FROM Program__c WHERE Id =: programId];
                    String strLstCCEmail = null;
                    List<String> lstCCEmailsToSend = new List<String>();
    
                    strLstCCEmail = program.PrincipalCedingCompany__r.EmailPCLife__c;
    
                    if(strLstCCEmail != null ){
                        if(strLstCCEmail.contains(';')){
                            lstCCEmailsToSend = strLstCCEmail.split(';');
                        }
                        else{
                            lstCCEmailsToSend.add(strLstCCEmail);
                        }
                    }
    
                    EmailTemplate emailTemplate = [SELECT Id, Name FROM EmailTemplate WHERE Name = :AP_Constant.emailTemplateCloseSigningReqNotifyWebXL];
                    Messaging.SingleEmailMessage m = Messaging.renderStoredEmailTemplate(emailTemplate.Id, UserInfo.getUserId(), lstSigningRequestId[0]);
                    m.setSaveAsActivity(false);
    
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    List<String> sendTo = new List<String>();
                    sendTo.add(Label.Notify_webXL_email_address);
                    mail.setToAddresses(sendTo);
                    mail.setReplyTo(UserInfo.getUserEmail());
                    mail.setSenderDisplayName(UserInfo.getFirstName() + ' ' + UserInfo.getLastName());
    
                    if(lstCCEmailsToSend.size() > 0){
                        mail.setCcAddresses(lstCCEmailsToSend);
                    }
    
                    String htmlBody = m.htmlBody;
                    String subject = m.getSubject();
                    htmlBody = htmlBody.replace('{ProgramName}', program.Name);
                    subject = subject.replace('{ProgramName}', program.Name);
                    mail.setHtmlBody(htmlBody);
                    mail.setSubject(subject);
                    lstMails.add(mail);
    
                    Messaging.sendEmail((List<Messaging.Email>) lstMails);
                    mapResult.put('Success', 'Success');
                }
                else{
                    mapResult.put('Error', 'You cannot close the signing as at least one of your signing request is not signed');
                }
    
    
            }catch (Exception ex) {
                mapResult.put('Error',ex.getMessage());
            }
            return mapResult;
        }
    
        /**
        * @description Method to reopen signing requests
        * @param List<String> lstSigningRequestId
        * @return Map<String, Object>
        */
        @AuraEnabled
        public static Map<String, Object> reopenSigningRequest(List<String> lstSigningRequestId){
            Map<String,Object> mapResult = new Map<String,Object>();
            try {
    
                List<Request__c> lstSigningRequests = [SELECT Id, Name, ReinsurerStatus__c, SigningStatus__c, TECH_OldSigningStatus__c FROM Request__c WHERE Id IN :lstSigningRequestId];
    
                //set SigningStatus to Previous value Before Close Signing and notify WexXL
                for(Request__c signingRequest : lstSigningRequests){
                    signingRequest.SigningStatus__c = signingRequest.TECH_OldSigningStatus__c;
                }
    
                if(lstSigningRequests.size() > 0){
                    update lstSigningRequests;
                }
    
                mapResult.put('Success', 'Success');
            }catch (Exception ex) {
                mapResult.put('Error',ex.getMessage());
            }
            return mapResult;
        }
    
        /**
        * @description Method to reopen placement phase
        * @param Id programId
        * @return Map<String, Object>
        */
        @AuraEnabled
        public static Map<String, Object> reopenPreviousPhase(Id programId) {
            Map<String, Object> mapResults = new Map<String, Object>();
            Map<String, Id> mapRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectRequest});
            String recordTypeIdLead = mapRecTypeId.get(AP_Constant.reqRTLead);
            String recordTypeIdPlacement = mapRecTypeId.get(AP_Constant.reqRTPlacement);
            String recordTypeIdSigning = mapRecTypeId.get(AP_Constant.reqRTSigning); //RRA - ticket 1410 - 24032023
            List<Request__c> lstRequestToUpdate = new List<Request__c>();
            try{
    
                Program__c program = new Program__c();
                program.Id = programId;
                program.TECH_ShowClosePreviousPhaseBtn__c = '1';
                update program;
    
                String queryRequest = 'select Id, PlacementStatus__c , LeadStatus__c, RecordTypeId from Request__c where (Program__c = :programId AND (RecordTypeId = :recordTypeIdLead OR RecordTypeId = :recordTypeIdPlacement) AND Program__c != NULL) ';

                String queryRequestSigning = 'select Id, isReopenPreviousPhase__c, RecordTypeId from Request__c where (Program__c = :programId AND RecordTypeId = :recordTypeIdSigning AND Program__c != NULL) '; //RRA - ticket 1410 - 24032023
    
                List<Request__c> lstAllLeadPlacementRequest = Database.query(queryRequest);
                List<Request__c> lstSigningRequestUpdateFlagReopPhase = Database.query(queryRequestSigning);

                for(Request__c request : lstAllLeadPlacementRequest){
                    if(request.RecordTypeId == recordTypeIdLead){
                        request.LeadStatus__c = '1';
                    }
                    if(request.RecordTypeId == recordTypeIdPlacement){
                        request.PlacementStatus__c = '1';
                    }
                    lstRequestToUpdate.add(request);
                }

                //RRA - ticket 1410 - 24032023
                if (lstSigningRequestUpdateFlagReopPhase.size()> 0 ){
                    for(Request__c request : lstSigningRequestUpdateFlagReopPhase){
                        if (request.isReopenPreviousPhase__c == false){
                            request.isReopenPreviousPhase__c = true;
                        }
                    }
                }

                System.debug('lstSigningRequestUpdateFlagReopPhase == ' + lstSigningRequestUpdateFlagReopPhase);
                /*if(lstRequestToUpdate.size() > 0){
                    update lstRequestToUpdate;
                }*/

                //RRA - ticket 1410 - 24032023
                if(lstSigningRequestUpdateFlagReopPhase.size() > 0){
                    update lstSigningRequestUpdateFlagReopPhase;
                }

                if(lstRequestToUpdate.size() > 0){
                    update lstRequestToUpdate;
                }
    
                mapResults.put('Success', 'Success');
            } catch (Exception ex) {
                mapResults.put('Error', ex.getMessage());
            }
            return mapResults;
        }
    
        /**
        * @description Method to Account for search value
        * @param String value, Id requestId, String lookupName
        * @return List<SObjectResult>
        */
        @AuraEnabled(Cacheable=true)
        public static List<SObjectResult> getLookupAccountField(String value, Id requestId, String lookupName) {
            List<SObjectResult> sObjectResultList = new List<SObjectResult>();
            Map<String, Id> mapRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectAcc});
            String recordTypeIdReinsurer = mapRecTypeId.get(AP_Constant.accRTReinsurer);
            String query = '';
            List<AccountContactRelation> lstAccountContactRelation = new List<AccountContactRelation>();
            Id parentId;
    
            Request__c request = [SELECT Id, Name, RiskCarrier__c, FinancialEntity__c, Reinsurer__c, Reinsurer__r.ParentId FROM Request__c WHERE Id = :requestId];
    
            if(request != null){
                parentId = request.Reinsurer__r.ParentId;
            }
            
             // SRA - ticket 1012.
             Profile userProfile = [SELECT Id, Name FROM Profile WHERE Id =: UserInfo.getProfileId()];
    
            if(String.isNotEmpty(value)) {
                String strValue = '%' + String.escapeSingleQuotes(value.trim()) + '%';
    
                /*if(lookupName == 'RiskCarrier'){
                    query = 'SELECT Id, Name FROM Account WHERE Name LIKE :strValue and IsActive__c = TRUE and RecordTypeId = :recordTypeIdReinsurer and IsRiskCarrier__c = TRUE AND ParentId = :parentId';
                    // query = 'SELECT Id,Name FROM Account WHERE Name LIKE \'%' + value.trim() + '%\' and IsActive__c = TRUE and RecordTypeId = :recordTypeIdReinsurer and IsRiskCarrier__c = TRUE AND ParentId = :parentId';
                }
                else if(lookupName == 'FinancialEntity'){
                    query = 'SELECT Id, Name FROM Account WHERE Name LIKE :strValue and IsActive__c = TRUE and RecordTypeId = :recordTypeIdReinsurer and IsFinancialEntity__c = TRUE AND ParentId = :parentId';
                    // query = 'SELECT Id,Name FROM Account WHERE Name LIKE \'%' + value.trim() + '%\' and IsActive__c = TRUE and RecordTypeId = :recordTypeIdReinsurer and IsFinancialEntity__c = TRUE AND ParentId = :parentId';
                }
    
                for(SObject so : Database.query(query)) {
                    String fieldvalue = (String)so.get('Name');
                    sObjectResultList.add(new SObjectResult(fieldvalue, so.Id));
                }*/
    
                 // SRA - ticket 1012 - Modify filter according the profile
                 if(lookupName == 'RiskCarrier'){
                    query = 'SELECT Id, Name FROM Account WHERE Name LIKE :strValue and IsActive__c = TRUE and RecordTypeId = :recordTypeIdReinsurer and IsRiskCarrier__c = TRUE ';
                }
                else if(lookupName == 'FinancialEntity'){
                    query = 'SELECT Id, Name FROM Account WHERE Name LIKE :strValue and IsActive__c = TRUE and RecordTypeId = :recordTypeIdReinsurer and IsFinancialEntity__c = TRUE ';             
                }
    
                if(userProfile.Name != AP_Constant.profileSysAdminAGRe){
                    query += ' AND ParentId = :parentId ';
                }
    
                for(SObject so : Database.query(query)) {
                    String fieldvalue = (String)so.get('Name');
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
        * @description Method to if Signing phase has document for Program
        * @param Id programId
        * @return Boolean
        */
        @AuraEnabled
        public static Boolean checkIfProgPhaseSigningHasDoc(Id programId) {
            Set<Id> setContentDocumentId = new Set<Id>();
            Map<Id, ContentVersion> mapContentVersionByDocumentId = new Map<Id, ContentVersion>();
            Boolean docPresent = false;
            String phaseSigning = '4';
            String phaseAll = '5';
            String groupTypeContractual = '1';
    
            for (ContentDocumentLink contentDocLink : [SELECT Id, ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :programId]){
                setContentDocumentId.add(contentDocLink.ContentDocumentId);
            }
    
            List<ContentVersion> lstContentVersion = [SELECT Id, DocumentType__c, GroupType__c, Phase__c, Title
                                                                , ContentDocumentId, VersionNumber
                                                      FROM ContentVersion
                                                      WHERE ContentDocumentId IN :setContentDocumentId
                                                      AND IsExternal__c = FALSE
                                                      AND (Phase__c = :phaseSigning OR Phase__c = :phaseAll)
                                                      AND GroupType__c = :groupTypeContractual];
    
             //Remove PathOnClient, VersionData in Query lstContentVersion
    
            if(lstContentVersion.size() > 0){
                docPresent = true;
            }
    
            return docPresent;
        }
    
        /**
        * @description Method to if Lead request are answered
        * @param Id programId
        * @return Boolean
        */
        @AuraEnabled
        public static Map<String, Object>  checkIfLeadReqAreAnswered(Id programId) {
            //You cannot perform this action as at least one of the lead request(s) is not answered
            Map<String, Id> mapRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectRequest});
            String recordTypeLeadId = mapRecTypeId.get(AP_Constant.reqRTLead);
            Map<String, Object> mapResults = new  Map<String, Object> ();
    
            String reinsurerStatusAnswered = AP_Constant.statusAnswered;
            Boolean allLeadReqAnswered = true;
            List<Request__c> lstLeadRequests = [ SELECT Id, Name, ReinsurerStatus__c
            FROM Request__c
            WHERE Program__c = :programId
            AND RecordTypeId = :recordTypeLeadId
            AND Reinsurer__c != NULL];
    
    
            for(Request__c leadRequest : lstLeadRequests){
                if(leadRequest.ReinsurerStatus__c != reinsurerStatusAnswered) {
                    allLeadReqAnswered = false;
                }
            }
            if(lstLeadRequests.size() == 0){
                mapResults.put('Error', 'You cannot perform this action as there are no Lead Request(s) present for this Program');
            }
            else{
                if(allLeadReqAnswered == false){
                    mapResults.put('Error', 'You cannot perform this action as at least one of the Lead Request(s) is not answered');
                }
                else{
                    mapResults.put('Success', 'Success');
                }
            }
            return mapResults;
        }


        /** RRA - 1088
        * @description Method to check if SFP page is visible
        * @param Id programId
        * @param lstRequestId list Request Id
        * @return String
        */
        @AuraEnabled
        public static Decimal checkFXRATEifExists(Id programId, List<Id> lstRequestTreatyId){
            Map<String, Decimal> mapRateByCurrencyLabel = new Map<String, Decimal>();
            Decimal fxRate;
            Program__c program = [SELECT Id, UwYear__c FROM Program__c WHERE Id =:programId];

            System.debug('program== '+ program);

            for(FXRate__c fxRat : [SELECT Id, toLabel(Currency__c), FX_Rate__c FROM FXRate__c WHERE UW_Year__c = :program.UwYear__c]){
                if(!mapRateByCurrencyLabel.containsKey(fxRat.Currency__c)){
                    mapRateByCurrencyLabel.put(fxRat.Currency__c, fxRat.FX_Rate__c);
                }
            }
            System.debug('mapRateByCurrencyLabel== '+ mapRateByCurrencyLabel);

            for(Section__c  section : [SELECT Treaty__c, toLabel(Currency__c), Program__c FROM Section__c  WHERE Treaty__c IN:lstRequestTreatyId AND Program__c =:programId]){
                if(mapRateByCurrencyLabel.containsKey(section.Currency__c)){
                    fxRate =  mapRateByCurrencyLabel.get(section.Currency__c);
                }else{
                    fxRate = null;
                }
            }

            System.debug('fxRate== '+ fxRate);
            return fxRate;
    }

    //RRA - ticket 1397 - 09012023
    /* @description Method to check if SFP page is visible
     @param Id programId
     @param Id pcc
     @param String uwy
     @param Id reinsurer
     @param Id broker
     @return List<Id>
    */
    @AuraEnabled
    public static Map<String, Object>  getListIdOrginalRequestNotNull(Id programId, Id pcc, String uwy, Id reinsurer){
        List<Id> lstOrigReqNotNull = new List<Id>();
        List<Id> lstOrigReqNull = new List<Id>();   //RRA - ticket 1421 - 08092023
        List<Id> lstIdBroker = new List<Id>();
        List<Id> lstIdReins = new List<Id>();
        Map<String, Object> mapResults = new  Map<String, Object> ();
        String query;
        Boolean isLossDepositModeTreatySetup = false;

        if (reinsurer != null){
            query = 'SELECT Id , OriginalRequest__c, Treaty__r.Name, Reinsurer__c, Broker__c,Reinsurer__r.Name, LastVersionAnswered__c, LastVersionSent__c FROM Request__c Where Program__c =: programId AND program__r.PrincipalCedingCompany__c =: pcc AND Program__r.UwYear__c =:uwy AND Reinsurer__c =: reinsurer AND RecordType.Name = \'Signing Request\' AND ((LastVersionAnswered__c = true AND LastVersionSent__c = true) OR ReinsurerStatus__c = \'Setup\')'; //RRA - ticket 1421 - 01092023
        }
        List <Request__c> lstReq = Database.query(query);

        for (Request__c req : lstReq){
            if (req.OriginalRequest__c != null){
                lstOrigReqNotNull.add(req.OriginalRequest__c); // if already Send /Refused/Timeout/Signed/Anwered
            }else {
                isLossDepositModeTreatySetup = true;
                lstOrigReqNull.add(req.Id);    //Setup
            }
        }
        System.debug('lstOrigReqNotNull == ' + lstOrigReqNotNull);
        System.debug('lstOrigReqNull == ' + lstOrigReqNull);
        mapResults.put('lstOrigReqNotNull', lstOrigReqNotNull);
        mapResults.put('lstOrigReqNull', lstOrigReqNull);
        mapResults.put('isLossDepositModeTreatySetup', isLossDepositModeTreatySetup);
        return mapResults;
    }
    
    //RRA - ticket 1421 - 31082023
    /* @description Method to check if SFP page is visible
     @param List<Id> lstIdOriginalRequest
    */
    @AuraEnabled
    public static List<Id>  getListIdRequest(List<Id> lstIdOriginalRequest){
        List<Id> lstIdReq = new List<Id>();

        for (Request__c req : [SELECT Id, OriginalRequest__c FROM Request__c WHERE ((OriginalRequest__c IN: lstIdOriginalRequest) OR (Id IN:lstIdOriginalRequest))]){//RRA - ticket 1421 - 01092023
            if (req.Id != null){
                lstIdReq.add(req.Id);
            }
        }
        System.debug('lstIdReq == ' + lstIdReq);
        return lstIdReq;
    }

     //RRA - ticket BUG Marouane sur SignedShare - 13012023	
    /* @description Method to check if SFP page is visible	
     @param List<Request__c> lstReqClosePrevPhase	
    */	
    @AuraEnabled	
    public static void updateSigningReqClosePrevPhase(List<Request__c> lstReqClosePrevPhase, Id idProgram){	 //RRA - ticket 1421 - 01092023
        Set <Id> setIdOrig = new Set <Id>();	
        map <String, Request__c> mapLatestVersionReq = new map <String, Request__c> (); 	
        List<Request__c> lstUpdateRequestorig = new List<Request__c>();	
        map<String, Request__c> mapReqLeadPlacement = new map <String, Request__c>();
        List<Request__c> lstUpdateWrittenShareFromPlacement = new List<Request__c>();
        
         //RRA - ticket 1421 - 01092023
        List<Request__c> lstRequestLeadPlacement = [SELECT Id, WrittenShare__c, Treaty__c,Broker__c, Reinsurer__c FROM Request__c WHERE Program__c =: idProgram AND RecordType.Name IN ('Placement Request', 'Lead Request') AND OriginalRequest__c = null];
        if (lstRequestLeadPlacement.size()> 0 && lstRequestLeadPlacement != null){
            for (Request__c reqLeadPlac : lstRequestLeadPlacement){
                mapReqLeadPlacement.put(reqLeadPlac.Treaty__c + '_' + reqLeadPlac.Broker__c + '_' + reqLeadPlac.Reinsurer__c, reqLeadPlac);
            }
        }
        System.debug('mapReqLeadPlacement == ' + mapReqLeadPlacement);
        if (lstReqClosePrevPhase != null && !lstReqClosePrevPhase.isEmpty()){	
            // Update line child original Request not null	
            //update lstReqClosePrevPhase;	 //RRA - ticket 1590 - 29092023
            for (Request__c req : lstReqClosePrevPhase){	
                setIdOrig.add(req.OriginalRequest__c);	
                //mapReqSigning.put(mapReqLeadPlacement.get(req.Treaty__c  + '_' + req.Broker__c  + '_' + req.Reinsurer__c), req);
                mapLatestVersionReq.put(req.OriginalRequest__c, req);	
            }	
            // Update line parent original Request null	
            for (Request__c req :[SELECT Id, OriginalRequest__c, WrittenShare__c, SignedShare__c FROM Request__c WHERE Id IN:setIdOrig]){	
                if (req.OriginalRequest__c == null){	
                    req.WrittenShare__c = mapLatestVersionReq.get(req.Id).WrittenShare__c;
                    req.SignedShare__c = mapLatestVersionReq.get(req.Id).SignedShare__c;
                    lstUpdateRequestorig.add(req);	
                }	
            }
            	
             //RRA - ticket 1421 - 01092023	- Compare Request Signing and Request Placement from key to update WrittenShare__c
            for (Request__c reqSigning : lstReqClosePrevPhase){
                if (reqSigning.Pool__c == null){ //RRA - 1590 - writtenShare of pool are not concerned for updating writtenShare of Lead or Placement
                    String key = reqSigning.Treaty__c + '_' +  reqSigning.Broker__c  + '_' + reqSigning.Reinsurer__c;
                    if (mapReqLeadPlacement.get(key) != null){
                        reqSigning.WrittenShare__c = mapReqLeadPlacement.get(reqSigning.Treaty__c + '_' +  reqSigning.Broker__c  + '_' + reqSigning.Reinsurer__c).WrittenShare__c;
                    }
                    lstUpdateWrittenShareFromPlacement.add(reqSigning);
                }
            }
        }
        System.debug('lstUpdateWrittenShareFromPlacement == ' + lstUpdateWrittenShareFromPlacement);
        if (lstUpdateRequestorig.size()>0){	
            update lstUpdateRequestorig;	
        }
        
        if (lstUpdateWrittenShareFromPlacement.size()>0){
            update lstUpdateWrittenShareFromPlacement;
        }
    }
    
    @AuraEnabled
    public static string getListAgreementIds(Id programId){
        String message =  null;
        System.debug('getListAgreementIds: Start with ' + programId );
        List<String> lstIdAgreements = new List<String>();
        List<CLM_UpdateAgreementByAGL.InputVariables> lstInputVar = new List<CLM_UpdateAgreementByAGL.InputVariables>();
        CLM_UpdateAgreementByAGL.InputVariables inputVar =  new CLM_UpdateAgreementByAGL.InputVariables ();
        List<Apttus__APTS_Agreement__c> listAgreements =  [SELECT ID FROM Apttus__APTS_Agreement__c WHERE Program__c = :programId]; 
        for(Apttus__APTS_Agreement__c record: listAgreements) {
            lstIdAgreements.add(record.Id);
        }
        if (lstIdAgreements.size()>0){
            inputVar.AgreementIdList = lstIdAgreements;
            lstInputVar.add(inputVar);
            CLM_UpdateAgreementByAGL.concatFieldAGLOnAgreement(lstInputVar);
            message = 'Update fields on Agreement by fields on AGL Successfully';
        }
        return message;
    }  
}