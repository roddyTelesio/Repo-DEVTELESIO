public with sharing class LWC54_SAGroupCover {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Controller for Lightning Web Component Lwc54SAGroupCover
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 15-JAN-2021  MBE   1.0      Initial version
-- 26-AUG-2021  MBE   1.1      SOQL Injection for generateGroupCoverSa()
--------------------------------------------------------------------------------------
**************************************************************************************/

   /**
    * @description Method to get Filter Values
    * @param String uwYearVal, String pccVal, String programVal, String poolVal
    * @return Map<String, Object>
    */
    @AuraEnabled
    public static Map<String, Object> getFilterValues(String uwYearVal, String pccVal, String programVal, String poolVal){
        Map<String, Object> mapResults = new Map<String, Object>();
        Map<String, Id> mapRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectRequest});
        Map<Id, OptionWrapper> mapPCCOptions = new Map<Id, OptionWrapper>();
        Map<Id, OptionWrapper> mapPoolOptions = new Map<Id, OptionWrapper>();
        Map<Id, List<OptionWrapper>> mapProgramOptionsByPCC = new Map<Id, List<OptionWrapper>>();
        Map<Id, List<OptionWrapper>> mapPoolOptionsByProgram = new Map<Id, List<OptionWrapper>>();
        Map<String, Set<Id>> mapSetSAByProgPoolId = new Map<String, Set<Id>>();
        Map<String, Set<Id>> mapSetSAByProgId = new Map<String, Set<Id>>();
        Map<String, List<SpecialAcceptance__c>> mapLstSADetailByProgPoolId = new Map<String, List<SpecialAcceptance__c>>();
        Map<String, List<SpecialAcceptance__c>> mapLstSADetailByProgId = new Map<String, List<SpecialAcceptance__c>>();
        Map<Id, SpecialAcceptance__c> mapSADetailById = new Map<Id, SpecialAcceptance__c>();
        Set<String> setPCCProgId = new Set<String>();
        Set<String> setProgramPoolId = new Set<String>();
        Set<String> setAllSaId = new Set<String>();
        String reqSaRecordTypeId = mapRecTypeId.get(AP_Constant.reqRTSA);
        String statusSetup = AP_Constant.statusSetup;
        List<Request__c> lstSaRequest = new List<Request__c>();
        List<OptionWrapper> lstPCCOption = new List<OptionWrapper>();
        List<OptionWrapper> lstProgramOption = new List<OptionWrapper>();
        List<OptionWrapper> lstPoolOption = new List<OptionWrapper>();

        try{
            String querysaRequest = 'SELECT Id, Program__r.Name, Program__r.UwYear__c, Program__r.PrincipalCedingCompany__r.name, Pool__r.name, ' 
                    + ' Special_Acceptance__r.InternalStatus__c, Special_Acceptance__r.PortalStatus__c, Special_Acceptance__r.SpecialAcceptanceName__c '
                    + ' FROM Request__c WHERE RecordTypeId = :reqSaRecordTypeId AND Program__r.UwYear__c = :uwYearVal AND Pool__c != NULL'
                    + ' AND Special_Acceptance__r.InternalStatus__c != NULL AND Special_Acceptance__r.PortalStatus__c = NULL'
                    + ' AND ((LastVersionSent__c = TRUE AND LastVersionAnswered__c = TRUE) OR (SA_Request_Status__c = :statusSetup)) ORDER BY Special_Acceptance__r.SpecialAcceptanceName__c asc'; // RRA - 1086';

            lstSaRequest = Database.query(querysaRequest);

            for(Request__c saReq : lstSaRequest){
                //to get all PCC
                if(saReq.Program__r.PrincipalCedingCompany__c != null){
                    mapPCCOptions.put(saReq.Program__r.PrincipalCedingCompany__c, new OptionWrapper(saReq.Program__r.PrincipalCedingCompany__r.Name, saReq.Program__r.PrincipalCedingCompany__c));
                }

                //to get all Program : Build map -> PCC - List<Program__c>
                List<OptionWrapper> lstProgramOptions = new List<OptionWrapper>();

                if(mapProgramOptionsByPCC.containsKey(saReq.Program__r.PrincipalCedingCompany__c)){
                    lstProgramOptions = mapProgramOptionsByPCC.get(saReq.Program__r.PrincipalCedingCompany__c);

                    if(!setPCCProgId.contains(saReq.Program__r.PrincipalCedingCompany__c + '-' + saReq.Program__c)){
                        lstProgramOptions.add(new OptionWrapper(saReq.Program__r.Name, saReq.Program__c));
                        setPCCProgId.add(saReq.Program__r.PrincipalCedingCompany__c + '-' + saReq.Program__c);
                        mapProgramOptionsByPCC.put(saReq.Program__r.PrincipalCedingCompany__c, lstProgramOptions);
                    }
                }
                else{
                    lstProgramOptions.add(new OptionWrapper(saReq.Program__r.Name, saReq.Program__c));
                    setPCCProgId.add(saReq.Program__r.PrincipalCedingCompany__c + '-' + saReq.Program__c);
                    mapProgramOptionsByPCC.put(saReq.Program__r.PrincipalCedingCompany__c, lstProgramOptions);
                }

                //to get all Pool : Build map -> Program - List<Pool__c>
                List<OptionWrapper> lstPoolOptions = new List<OptionWrapper>();

                if(mapPoolOptionsByProgram.containsKey(saReq.Program__c)){
                    lstPoolOptions = mapPoolOptionsByProgram.get(saReq.Program__c);

                    if(!setProgramPoolId.contains(saReq.Program__c + '-' + saReq.Pool__c)){
                        lstPoolOptions.add(new OptionWrapper(saReq.Pool__r.Name, saReq.Pool__c));
                        setProgramPoolId.add(saReq.Program__c + '-' + saReq.Pool__c);
                        mapPoolOptionsByProgram.put(saReq.Program__c, lstPoolOptions);
                    }
                }
                else{
                    lstPoolOptions.add(new OptionWrapper(saReq.Pool__r.Name, saReq.Pool__c));
                    setProgramPoolId.add(saReq.Program__c +'-' + saReq.Pool__c);
                    mapPoolOptionsByProgram.put(saReq.Program__c, lstPoolOptions);
                }

                //to get all SA
                //to build map for program-pool, List<SpecialAcceptance__c>

                Set<Id> setSaIdByProgPoolId = new Set<Id>();
                Set<Id> setSaIdByProgId = new Set<Id>();

                if(mapSetSAByProgPoolId.containsKey(saReq.Program__c + '-' + saReq.Pool__c)){
                    setSaIdByProgPoolId = mapSetSAByProgPoolId.get(saReq.Program__c + '-' + saReq.Pool__c);
                }

                setSaIdByProgPoolId.add(saReq.Special_Acceptance__c);
                mapSetSAByProgPoolId.put(saReq.Program__c + '-' + saReq.Pool__c, setSaIdByProgPoolId);

                if(mapSetSAByProgId.containsKey(saReq.Program__c)){
                    setSaIdByProgId = mapSetSAByProgId.get(saReq.Program__c);
                }

                setSaIdByProgId.add(saReq.Special_Acceptance__c);
                mapSetSAByProgId.put(saReq.Program__c, setSaIdByProgId);
                setAllSaId.add(saReq.Special_Acceptance__c);
            }

            for(SpecialAcceptance__c sa : [SELECT Id, Name, Reference__c, ReferenceOld__c, SpecialAcceptanceName__c, toLabel(LoB__c), toLabel(SubLoB__c)
                                                  , Active__c, TECH_MacroLobProgram__c, Reason__c, toLabel(Bound__c), toLabel(Type__c), toLabel(ProposedToFac__c)
                                                  , UnderWrittingYear__c, SentAgreFromSpecialAcceptance__c, PortalStatus__c, InternalStatus__c, Program__c
                                                  , Program__r.Name, Program__r.UwYear__c, Program__r.RenewedFromProgram__c, RenewedFromSpecialAcceptance__c 
                                           FROM SpecialAcceptance__c 
                                           WHERE Id IN :setAllSaId ORDER BY Name asc]){ // RRA - 1086
                mapSADetailById.put(sa.Id, sa);
            }

            for(String progPoolId: mapSetSAByProgPoolId.keyset()){
                Set<Id> setSaId = mapSetSAByProgPoolId.get(progPoolId);
                List<SpecialAcceptance__c> lstSA = new List<SpecialAcceptance__c>();

                for(Id saId : setSaId){
                    lstSa.add(mapSADetailById.get(saId));
                }

                mapLstSADetailByProgPoolId.put(progPoolId, lstSA);
            }

            for(String progId: mapSetSAByProgId.keyset()){
                Set<Id> setSaId = mapSetSAByProgId.get(progId);
                List<SpecialAcceptance__c> lstSA = new List<SpecialAcceptance__c>();

                for(Id saId : setSaId){
                    lstSa.add(mapSADetailById.get(saId));
                }

                mapLstSADetailByProgId.put(progId, lstSA);
            }

            if(mapPCCOptions != null){
                lstPCCOption = mapPCCOptions.values();
            }

            mapResults.put('lstPCCOption', lstPCCOption);
            mapResults.put('mapProgramOptionsByPCC', mapProgramOptionsByPCC);
            mapResults.put('mapPoolOptionsByProgram', mapPoolOptionsByProgram);
            mapResults.put('lstSaRequest', lstSaRequest);
            mapResults.put('mapLstSADetailByProgPoolId', mapLstSADetailByProgPoolId);
            mapResults.put('mapLstSADetailByProgId', mapLstSADetailByProgId);
            mapResults.put('Success', 'Success');
        }catch (Exception ex) {
            mapResults.put('Error', ex.getMessage());
        }

        return mapResults;
    }

    /**
    * @description Method to get Special Acceptance Requests
    * @param List<String> lstSAId, String poolVal
    * @return Map<String, Object>
    */
    @AuraEnabled
    public static Map<String, Object> getSAR(List<String> lstSAId, String poolVal){
        Map<String, Object> mapResults = new Map<String, Object>();
        Map<String, Id> mapRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectRequest});
        String reqSaRecordTypeId = mapRecTypeId.get(AP_Constant.reqRTSA);
        List<Request__c> lstSARequest = new List<Request__c>();
        List<String> lstRequestFields = AP_Constant.getCreatableFieldsByObjName(AP_Constant.sObjectRequest);
        List<String> lstSAFields = AP_Constant.getCreatableFieldsByObjName(AP_Constant.sObjectSpecialAcceptance);
        String strSAFields = String.join(lstSAFields , ', ');
        String strRequestFields = String.join(lstRequestFields, ', ');
        String statusSetup = AP_Constant.statusSetup;

        try{
            String querySaRequest = 'SELECT Id, TECH_TreatyName__c, Treaty__r.PlacementShare_Perc__c, TECH_BrokerName__c, TECH_IsBrokerPresent__c, TECH_ReinsurerName__c, TECH_Layer__c, TECH_UWyear__c,  SigningRegionalManager__r.Email '
                    + ', RiskCarrier__r.Name, FinancialEntity__r.Name, Program__r.LossDepositMode__c, Program__r.LossDeposit__c '
                    + ', Treaty__r.LossDepositMode__c, Treaty__r.LossDeposit__c, Treaty__r.Deductions__c, TreatyReference__c, Treaty__r.TypeofTreaty__c, Program__r.UwYear__c '
                    + ', Treaty__r.PremiumDeposit__c, Program__r.LossDepositLevel__c, Pool__r.Name, Pool__r.AssignedTo__r.Email, Pool__r.AssignedTo__c, Program__r.Name, program__r.principalcedingcompany__r.Name, Program__r.PrincipalCedingCompany__c '
                    + ', Special_Acceptance__r.SpecialAcceptanceName__c, Special_Acceptance__r.CoveredCedingCompany__r.Name,  Special_Acceptance__r.TECH_LocalSA__c, '
                    +  strRequestFields
                    + ' from Request__c where (Special_Acceptance__c IN :lstSAId) AND ((LastVersionSent__c = TRUE AND LastVersionAnswered__c = TRUE) OR (SA_Request_Status__c = :statusSetup)) '
                    + ' AND Pool__c != NULL';

            if(poolVal != 'All'){
                querySaRequest += ' AND Pool__c = :poolVal';
            }

            lstSARequest = Database.query(querySaRequest);
            mapResults.put('lstSARequest', lstSARequest);
            mapResults.put('Success', 'Success');
        }catch (Exception ex) {
            mapResults.put('Error', ex.getMessage());
        }

        return mapResults;
    }

    /**
    * @description Method to get Principal Ceding Companies
    * @param null
    * @return List<OptionWrapper>
    */
    @AuraEnabled
    public static List<OptionWrapper> getPrincipalCedingAcc(){
        Map<String, Id> mapRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectAcc});
        List<OptionWrapper> lstCedingComp = new List<OptionWrapper>();
        List<Id> lstGroupIds = new List<Id>();
        List<String> lstReferentialIds = new List<String>();

        for(GroupMember groupMemberRecord : [SELECT Id, GroupId FROM GroupMember WHERE UserOrGroupId = :UserInfo.getUserId()]){
            lstGroupIds.add(groupMemberRecord.GroupId);
        }

        for(Group groupRecord : [SELECT Id, DeveloperName FROM Group WHERE Id IN :lstGroupIds]){
            lstReferentialIds.add(groupRecord.DeveloperName);
        }

        for(Account account : [SELECT Id, Name FROM Account WHERE TECH_ReferentialId__c IN :lstReferentialIds AND RecordTypeId = :mapRecTypeId.get(AP_Constant.accRTPrincipalCedingCom)]){
            lstCedingComp.add(new OptionWrapper(account.Name, account.Id));
        }

        lstCedingComp.sort();
        return lstCedingComp;
    }

    /**
    * @description Method to get Group Cover Program
    * @param String selectedUwYear, String selectedPcc, Request__c selectedSAR
    * @return Map<String, Object>
    */
    @AuraEnabled
    public static Map<String, Object> getProgramForGroupCover(String selectedUwYear, String selectedPcc, Request__c selectedSAR){
        Map<String, Object> mapResults = new Map<String, Object>();
        List<Program__c> lstProgram = new List<Program__c>();

        try{
            Id selectedProgId = selectedSAR.Program__c;

            lstProgram = [SELECT Id, Name, PrincipalCedingCompany__c, UwYear__c 
                          FROM Program__c
                          WHERE PrincipalCedingCompany__c = :selectedPcc 
                          AND UwYear__c = :selectedUwYear AND Id != :selectedProgId];

            mapResults.put('lstProgram', lstProgram);
            mapResults.put('Success', 'Success');
        }catch (Exception ex) {
            mapResults.put('Error', ex.getMessage());
        }

        return mapResults;
    }

    /**
    * @description Method to generate Group Cover Special Acceptance
    * @param List<String> lstSelectedProgram, Request__c selectedSAR, String selectedUwYear, String selectedPcc
    * @return Map<String, Object>
    */
    @AuraEnabled
    public static Map<String, Object> generateGroupCoverSa(List<String> lstSelectedProgram, Request__c selectedSAR, String selectedUwYear, String selectedPcc){
        Map<String, Object> mapResults = new Map<String, Object>();
        List<String> lstSAFields = AP_Constant.getCreatableFieldsByObjName(AP_Constant.sObjectSpecialAcceptance);
        List<SpecialAcceptance__c> lstSA = new List<SpecialAcceptance__c>();
        List<SpecialAcceptance__c> lstSAToInsert = new List<SpecialAcceptance__c>();
        List<ContentVersion> lstContentVersion = new List<ContentVersion>();
        List<ContentVersion> lstNewContentVersionToInsert = new List<ContentVersion>();
        List<ContentDocumentLink> lstContentDocumentLinkToInsert = new List<ContentDocumentLink>();
        Id selectedSaId;
        String strSAFields = String.join(lstSAFields , ', ');
        Set<Id> setContentDocumentId = new Set<Id>();
        Savepoint sp = Database.setSavepoint();
        

        try{
            selectedSaId = selectedSAR.Special_Acceptance__c;

            // String querySA = 'select Id, Program__r.UwYear__c, Program__r.PrincipalCedingCompany__c, Program__r.Nature__c, SpaDurationDays__c, Program__r.Name, CoveredCedingCompany__r.Name, Program__r.PrincipalCedingCompany__r.Name, '
            //         + strSAFields
            //         + ' from SpecialAcceptance__c where Id = \''+selectedSaId+ '\' ';

            String querySA = 'select Id, Program__r.UwYear__c, Program__r.PrincipalCedingCompany__c, Program__r.Nature__c, SpaDurationDays__c, Program__r.Name, CoveredCedingCompany__r.Name, Program__r.PrincipalCedingCompany__r.Name, '
                    + strSAFields
                    + ' from SpecialAcceptance__c where Id = :selectedSaId';

            lstSA = Database.query(querySA);

            List<SpecialAcceptance__c> lstExistingGroupCoverSA = [SELECT Id, Name, Reference__c FROM SpecialAcceptance__c WHERE TECH_LocalSA__c = :selectedSaId ORDER BY CreatedDate];
            Decimal refLastIndexVal = 1;
            
            for(SpecialAcceptance__c groupCoverSa : lstExistingGroupCoverSA){
                if(groupCoverSa.Reference__c != null){
                    String refIndex = groupCoverSa.Reference__c.split('-')[3];
                    if(Decimal.valueOf(refIndex) > refLastIndexVal){
                        refLastIndexVal = Decimal.valueOf(refIndex);
                    }
                }
            }  

            if(lstExistingGroupCoverSA.size() > 0){
                refLastIndexVal = refLastIndexVal + 1;
            }

            for(String programId : lstSelectedProgram){
                for(SpecialAcceptance__c sa : lstSA){
                    SpecialAcceptance__c newSA = sa.clone(false, false, false, false);
                    newSA.TECH_Actor2Id__c = null;
                    newSA.Program__c = programId;
                    newSA.PrincipalCedingCompany__c = selectedPcc;
                    newSA.UnderWrittingYear__c = selectedUwYear;
                    newSA.Type__c = null;
                    newSA.CoveredCedingCompany__c = null; //Different programs may have different Covered Ceding Company
                    newSA.TECH_LocalSA__c = sa.Id;
                    newSA.InternalStatus__c = AP_Constant.statusSetup;
                    newSA.SentAgreFromSpecialAcceptance__c = null;
                    newSA.RenewedFromSpecialAcceptance__c = null;

                    String[] refOldIndex = sa.Reference__c.split('-');
                    String newReference;
                    newReference = refOldIndex[0] + '-' + refOldIndex[1] + '-' + refOldIndex[2] + '-' + refLastIndexVal;
                    newSA.Reference__c = newReference;
                    refLastIndexVal = refLastIndexVal + 1;
                    lstSAToInsert.add(newSA);
                }
            }

            if(lstSAToInsert.size() > 0){
                insert lstSAToInsert;
            }

            //Copy Document of Local SA to SA Group Cover
            for(ContentDocumentLink contentDocLink : [SELECT Id, ContentDocumentId
                                                      FROM ContentDocumentLink
                                                      WHERE LinkedEntityId = :selectedSaId]){
                setContentDocumentId.add(contentDocLink.ContentDocumentId);
            }

            if(setContentDocumentId.size() > 0){
                lstContentVersion = [SELECT Id, Phase__c, Title, IsExternal__c, ContentDocumentId
                                            , Nature__c, FileType, FileExtension, ContentUrl, ContentSize
                                            , PathOnClient, VersionData, FirstPublishLocationId, SpecialAcceptance__c
                                     FROM ContentVersion
                                     WHERE ContentDocumentId IN :setContentDocumentId];
            }

            for(SpecialAcceptance__c groupCoverSa : lstSAToInsert){
                for(ContentVersion contentVersion : lstContentVersion){
                    ContentVersion newContentVersion = new ContentVersion();
                    newContentVersion.Title = contentVersion.Title;
                    newContentVersion.PathOnClient = contentVersion.PathOnClient;
                    newContentVersion.VersionData = contentVersion.VersionData;
                    newContentVersion.FirstPublishLocationId = contentVersion.FirstPublishLocationId;
                    newContentVersion.Nature__c = contentVersion.Nature__c;
                    newContentVersion.SpecialAcceptance__c = groupCoverSa.Id;
                    newContentVersion.IsExternal__c = contentVersion.IsExternal__c;
                    lstNewContentVersionToInsert.add(newContentVersion);
                }
            }

            if(lstNewContentVersionToInsert.size() > 0){
                insert lstNewContentVersionToInsert;

                for(ContentVersion cv : [SELECT Id, ContentDocumentId, SpecialAcceptance__c FROM ContentVersion WHERE Id IN :lstNewContentVersionToInsert]){
                    ContentDocumentLink cd = new ContentDocumentLink();
                    cd.LinkedEntityId = cv.SpecialAcceptance__c;
                    cd.ContentDocumentId = cv.ContentDocumentId;
                    cd.Visibility = 'AllUsers';
                    cd.ShareType = 'V';
                    lstContentDocumentLinkToInsert.add(cd);
                }

                if(lstContentDocumentLinkToInsert.size() > 0){
                    insert lstContentDocumentLinkToInsert;
                }
            }

            mapResults.put('lstSAToInsert', lstSAToInsert);
            mapResults.put('Success', 'Success');
        }catch (Exception ex) {
            Database.rollback(sp);
            mapResults.put('Error', ex.getMessage());
        }

        return mapResults;
    }

    public class OptionWrapper implements Comparable{
        @AuraEnabled
        public String label {get; set;}
        @AuraEnabled
        public String value {get; set;}

        public OptionWrapper(String label, String value){
            this.label = label;
            this.value = value;
        }

        public Integer compareTo(Object compareTo){
            OptionWrapper optWrapper = (OptionWrapper) compareTo;
            if (label == optWrapper.label) return 0;
            if (label > optWrapper.label) return 1;
            return -1;
        }
    }
}