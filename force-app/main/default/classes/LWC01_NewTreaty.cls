public without sharing class LWC01_NewTreaty {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Controller for Lightning Web Component lwc01NewTreaty
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 28-OCT-2019  MBE   1.0      Initial version
-- 17-APR-2020  SAU   1.1      Copy related sections
-- 08-MAY-2020  SAU   1.2      Check if treaty name is unique
-- 03-SEP-2020  SAU   1.3      Placement share editable based on user profile
-- 15-DEC-2020  NBI   1.4      Upsert Pool
-- 21-DEC-2020  NBI   1.5      Do not retain Section/Option when copying Treaty - W-0786
-- 22-FEB-2021  NBI   1.6      W-0887 - La suppression d'un pool sur un traité entraîne se suppression sur tous les traités du programme
-- 17-MAY-2021  MBE   1.7      W-0971 - CONDITION - TREATY - problème de calcul du champ Actor_Reference__cct
-- 26-MAY-2021  MBE   1.8      W-0971 - CONDITION - TREATY - problème de calcul du champ Actor_Reference__cct
-- 25-JUN-2021  MBE   1.9      Use Custom Setting for Treaty Reference
-- 08-JUL-2021  NBI   2.0      W-0992: Third Party Management
-- 22-JUL-2021  MBE   2.1      W-0913 - ODS - Pas de SHARERATE au niveau des T_SECTION_POOLs																								   
--------------------------------------------------------------------------------------
**************************************************************************************/

    /**
    * @description Method to get Program details
    * @param String id
    * @return List<Program__c>
    */
    @AuraEnabled
    public static List<Program__c> getProgram(String id) {
        return [
                SELECT Id, Name, toLabel(Macro_L_O_B__c), Status__c, STLT__c, InceptionDate__c, Expirydate__c, LTA__c, TacitRenewal__c, LTAInceptionDate__c
                        , LTAExpiryDate__c, LossDepositLevel__c, LossDeposit__c, LossDepositMode__c, UwYear__c, WordingName__c, WordingName2__c
                        , WordingName3__c, WordingName4__c, PrincipalCedingCompany__c, EarlyTerminationDate__c, LTARenegociation__c, AdvanceNotice__c
                FROM Program__c
                WHERE Id = :id
        ];
    }
    /**
    * @description Method to get Covered Ceding Companies of selected Program
    * @param String selectedProgramId
    * @return  List<CoveredCedingCompany__c>
    */
    @AuraEnabled
    public static List<CoveredCedingCompany__c> getCovCedComByProgramId(String selectedProgramId, Boolean isEdit) {
//        return [
//                SELECT Id, Name, Account__r.Name
//                FROM CoveredCedingCompany__c
//                WHERE Program__c = :selectedProgramId AND ProgramIsSelected__c = TRUE AND Account__r.IsActive__c = TRUE
//        ];
        String queryCCC = ' SELECT Id, Name, Account__r.Name FROM CoveredCedingCompany__c ';
        queryCCC += ' WHERE Program__c = :selectedProgramId AND ProgramIsSelected__c = TRUE ';
        if(isEdit == false){
            queryCCC += ' AND Account__r.IsActive__c = TRUE ';
        }
        return Database.query(queryCCC);
    }

    /**
    * @description Method to get Covered Ceding Companies of selected Treaty
    * @param String selectedTreatyId
    * @return  List<CoveredCedingCompany__c>
    */
    @AuraEnabled
    public static List<CoveredCedingCompany__c> getCovCedComByTreatyId(String selectedTreatyId) {
        return [
                SELECT Id, Name, Account__r.Name
                FROM CoveredCedingCompany__c
                WHERE Treaty__c = :selectedTreatyId AND TreatyIsSelected__c = TRUE
        ];
    }

    /**
    * @description Method to return Pools of a particular Underwriting Year
    * @param String uwyear
    * @return List<Pool__c>
    */
    @AuraEnabled(Cacheable = true)
    public static List<Pool__c> getPools(String uwyear) {
        return [
                SELECT Id, Name, ShareRate__c
                FROM Pool__c
                WHERE Year__c = :uwyear
        ];
    }

    /**
    * @description Method to return Program details of the selected Treaty
    * @param String treatyId
    * @return List<Treaty__c>
    */
    @AuraEnabled
    public static List<Treaty__c> getProgramDetails(String treatyId){
        return [SELECT Id, Program__r.Name,  CessionShare__c, Program__r.UwYear__c, Program__r.TECH_ShowClosePreviousPhaseBtn__c,
                Program__r.PrincipalCedingCompany__c, Program__r.LossDepositLevel__c,
                Program__r.LossDeposit__c, Program__r.LossDepositMode__c, Program__r.InceptionDate__c,
                Program__r.LTA__c, Program__r.TacitRenewal__c, Program__r.LTAInceptionDate__c, Program__r.LTAExpiryDate__c,
                Program__r.EarlyTerminationDate__c, Program__r.LTARenegociation__c, Program__r.AdvanceNotice__c,
                IsPooled__c, LossDepositMode__c, LossDeposit__c, TECH_LTA__c, Program__r.RenewedFromProgram__c FROM Treaty__c WHERE Id = :treatyId];
    }

    /**
    * @description Method to create/edit Treaty
    * @param Treaty__c objectTreaty, List<String> lstAccIdCovCedCom, List<String> lstPools, Id treatyId, Boolean editTreaty
    * @return Map<String, Object>
    */
    @AuraEnabled
    public static Map<String, Object> saveTreatyRecord(Treaty__c objectTreaty, List<String> lstAccIdCovCedCom, List<String> lstPools, Id treatyId, Boolean editTreaty){
        Map<String, Object> mapResults = new Map<String, Object>();
        Map<Id, Section__c> mapOldSecdToNewSection = new Map<Id, Section__c>();
        Map<Id, Id> mapTreatyIdBySectionId = new Map<Id, Id>();
        Savepoint sp = Database.setSavepoint();

        try{
            if(editTreaty == false){
                if (objectTreaty != null){
                    if(treatyId != null){
                        //copy treaty - to set TECH_Actor2Id__c to null
                        objectTreaty.TECH_Actor2Id__c = null;
                    }
                    insert objectTreaty;
                }

                List<CoveredCedingCompany__c> lstCovCedCom = new List<CoveredCedingCompany__c>();
                for (String accId : lstAccIdCovCedCom){
                    CoveredCedingCompany__c covCedCom = new CoveredCedingCompany__c();
                    covCedCom.Account__c = accId;
                    covCedCom.Program__c = objectTreaty.Program__c;
                    covCedCom.Treaty__c = objectTreaty.Id;
                    covCedCom.TreatyIsSelected__c = true;
                    lstCovCedCom.add(covCedCom);
                }

                if (lstCovCedCom.size() > 0){
                    insert lstCovCedCom;
                }

                List<PoolTreatySection__c> lstPoolTreatySections = new List<PoolTreatySection__c>();

                for (String pool : lstPools){
                    String poolId = pool.split(';')[0];
                    Decimal shareRate = Decimal.valueOf(pool.split(';')[1]);

                    PoolTreatySection__c poolTreatySection = new PoolTreatySection__c();
                    poolTreatySection.Pool__c = poolId;
                    poolTreatySection.Treaty__c = objectTreaty.Id;
                    poolTreatySection.TreatyIsSelected__c = true;
                    poolTreatySection.TreatyShareRate__c = shareRate;
                    lstPoolTreatySections.add(poolTreatySection);
                }

                if (lstPoolTreatySections.size() > 0){
                    insert lstPoolTreatySections;
                }

                if(treatyId != null){
                    /***
                    *
                    * Copy Section
                    *
                    */
                    List<String> lstSectionFields = AP_Constant.getCreatableFieldsByObjName(AP_Constant.sObjectSection);
                    String strSectionFields = String.join(lstSectionFields , ', ');
                    Set<Id> setSectionId =  new Set<Id>();
                    List<Section__c> lstNewSection = new List<Section__c>();

                    String querySection = 'select Id,RelatedSection__r.Treaty__c,'
                            + strSectionFields
                            + ' from Section__c where (Treaty__c = :treatyId) ' ;

                    List<Section__c> lstSection = Database.query(querySection);
                    List<Section__c> lstNewOptSections = new List<Section__c>();

                    for(Section__c section : lstSection){
                        setSectionId.add(section.Id);
                        Section__c newSection = section.clone(false, false, false, false);
                        newSection.Treaty__c = objectTreaty.Id;
                        newSection.TECH_OldSectionId__c = section.Id;
                        newSection.TECH_Actor2Id__c = null;
                        newSection.Retained_to_lead__c = false;
                        if(newSection.RelatedSection__c != null){
                            lstNewOptSections.add(newSection);
                        }else{
                            mapOldSecdToNewSection.put(section.Id, newSection);
                            lstNewSection.add(newSection);
                        }
                    }
                    if(lstNewSection.size() > 0){
                        insert lstNewSection;
                    }
                    //Add related sections
                    for(Section__c section : lstNewOptSections){
                        Id newSectionId = mapOldSecdToNewSection.get(section.RelatedSection__c).Id;
                        section.RelatedSection__c = newSectionId;
                        section.Retained_to_lead__c = false;
                    }
                    if(lstNewOptSections.size() > 0){
                        insert lstNewOptSections;
                    }

                    /***
                    *
                    * Copy Covered Ceding Company on Section
                    *
                    */
                    List<String> lstCoveredCedCompFieldSection = AP_Constant.getCreatableFieldsByObjName(AP_Constant.sObjCoveredCedingComp);
                    String strCoveredCedCompFieldSection = String.join(lstCoveredCedCompFieldSection , ', ');
                    String queryCoveredCedCompSection = 'select Id, Account__c,  '
                            + strCoveredCedCompFieldSection
                            + ' from CoveredCedingCompany__c where (Treaty__c = :treatyId) '
                            + 'and (SectionIsSelected__c = true ) '
                            + 'and (Account__c IN :lstAccIdCovCedCom) ';
                    List<CoveredCedingCompany__c> lstCoveredCedCompSection = Database.query(queryCoveredCedCompSection);

                    Map<Id, List<CoveredCedingCompany__c>> mapCoveredCedCompSection = new Map<Id, List<CoveredCedingCompany__c>>();
                    for(CoveredCedingCompany__c covCedCom : lstCoveredCedCompSection){
                        List<CoveredCedingCompany__c> lstCov = new List<CoveredCedingCompany__c>();

                        if(mapCoveredCedCompSection.containsKey(covCedCom.Section__c)){
                            lstCov = mapCoveredCedCompSection.get(covCedCom.Section__c);
                            lstCov.add(covCedCom);
                        }else{
                            lstCov.add(covCedCom);
                        }
                        mapCoveredCedCompSection.put(covCedCom.Section__c, lstCov);
                    }

                    List<CoveredCedingCompany__c> lstNewCoveredCedCompSection = new List<CoveredCedingCompany__c>();
                    for(Section__c section : lstNewSection){
                        List<CoveredCedingCompany__c> lstCoveredCedingCompanies = new List<CoveredCedingCompany__c>();
                        if(mapCoveredCedCompSection.containsKey(section.TECH_OldSectionId__c)){
                            lstCoveredCedingCompanies = mapCoveredCedCompSection.get(section.TECH_OldSectionId__c);
                        }
                        for(CoveredCedingCompany__c cov : lstCoveredCedingCompanies){
                            CoveredCedingCompany__c newCov = cov.clone(false, false, false, false);
                            newCov.Treaty__c = objectTreaty.Id;
                            newCov.Program__c = objectTreaty.Program__c;
                            newCov.Section__c = section.Id;
                            lstNewCoveredCedCompSection.add(newCov);
                        }
                    }

                    if(lstNewCoveredCedCompSection.size() > 0){
                        insert lstNewCoveredCedCompSection;
                    }

                    /***
                    *
                    * Copy Reinstatement on Section
                    *
                    */
                    List<String> lstReinstatementFields = AP_Constant.getCreatableFieldsByObjName(AP_Constant.sObjectReinstatement);
                    String strReinstatementFields = String.join(lstReinstatementFields , ', ');
                    String queryReinstatement = 'select Id,  '
                            + strReinstatementFields
                            + ' from Reinstatement__c where (Section__c IN :setSectionId) ';
                    List<Reinstatement__c> lstReinstatements = Database.query(queryReinstatement);

                    Map<Id, List<Reinstatement__c>> mapReinstatement = new Map<Id, List<Reinstatement__c>>();
                    for(Reinstatement__c reinstatement : lstReinstatements){
                        List<Reinstatement__c> lstReinstatement = new List<Reinstatement__c>();

                        if(mapReinstatement.containsKey(reinstatement.Section__c)){
                            lstReinstatement = mapReinstatement.get(reinstatement.Section__c);
                            lstReinstatement.add(reinstatement);
                        }
                        else{
                            lstReinstatement.add(reinstatement);
                        }

                        mapReinstatement.put(reinstatement.Section__c, lstReinstatement);
                    }

                    List<Reinstatement__c> lstNewReinstatement = new List<Reinstatement__c>();
                    for(Section__c section : lstNewSection){
                        List<Reinstatement__c> lstReins = new List<Reinstatement__c>();

                        if(mapReinstatement.containsKey(section.TECH_OldSectionId__c)){
                            lstReins = mapReinstatement.get(section.TECH_OldSectionId__c);
                        }

                        for(Reinstatement__c reinstatement : lstReins) {
                            Reinstatement__c newReinstatement = reinstatement.clone(false, false, false, false);
                            newReinstatement.Section__c = section.Id;
                            newReinstatement.TECH_Actor2Id__c = null;
                            lstNewReinstatement.add(newReinstatement);
                        }
                    }

                    if(lstNewReinstatement.size() > 0){
                        insert lstNewReinstatement;
                    }

                    /***
                    *
                    * Copy Pool Treaty Section on Section
                    *
                    */
                    List<String> lstPoolSectionFields = AP_Constant.getCreatableFieldsByObjName(AP_Constant.sObjPoolTreatySection);
                    String strPoolSectionFields  = String.join(lstPoolSectionFields , ', ');
                    String queryPoolSection = 'select Id,  '
                            + strPoolSectionFields
                            + ' from PoolTreatySection__c where (Section__c IN :setSectionId) '
                            + 'and (SectionIsSelected__c = true ) ';

                    List<PoolTreatySection__c> lstPoolSection = Database.query(queryPoolSection);
                    Map<Id, List<PoolTreatySection__c>> mapPoolSection = new Map<Id, List<PoolTreatySection__c>>();
                    for(PoolTreatySection__c poolSection : lstPoolSection){
                        List<PoolTreatySection__c> lstPoolSec = new List<PoolTreatySection__c>();

                        if(mapPoolSection.containsKey(poolSection.Section__c)){
                            lstPoolSec = mapPoolSection.get(poolSection.Section__c);
                            lstPoolSec.add(poolSection);
                            mapPoolSection.put(poolSection.Section__c, lstPoolSec);
                        }
                        else{
                            lstPoolSec.add(poolSection);
                            mapPoolSection.put(poolSection.Section__c, lstPoolSec);
                        }
                    }

                    List<PoolTreatySection__c> lstNewPoolSection = new List<PoolTreatySection__c>();

                    for(Section__c section : lstNewSection){
                        List<PoolTreatySection__c> lstPoolSections = new List<PoolTreatySection__c>();

                        if(mapPoolSection.containsKey(section.TECH_OldSectionId__c)){
                            lstPoolSections = mapPoolSection.get(section.TECH_OldSectionId__c);
                        }

                        for(PoolTreatySection__c poolSection : lstPoolSections){
                            PoolTreatySection__c newPoolSection = poolSection.clone(false, false, false, false);
                            newPoolSection.Section__c = section.Id;
                            newPoolSection.Treaty__c = objectTreaty.Id;
                            lstNewPoolSection.add(newPoolSection);
                        }
                    }

                    if(lstNewPoolSection.size() > 0){
                        insert lstNewPoolSection;
                    }

                    List<PoolTreatySection__c> lstAllPoolTreaty = [SELECT Id, Pool__c, TECH_PoolShareRate__c, TreatyShareRate__c,SectionShareRate__c, SectionEpiSharedCeded__c, SectionEpiCededToPool__c, Treaty__c, Section__c, TreatyIsSelected__c, SectionIsSelected__c FROM PoolTreatySection__c WHERE Treaty__c = :objectTreaty.Id AND TreatyIsSelected__c = TRUE];
                    Decimal totalPoolShareTreaty = 0;
                    Map<Id, Decimal> mapTreatyShareRateByPool = new Map<Id, Decimal>();
                    Map<Id, Decimal> mapTotalSelectedPoolShareSectionBySectionId = new Map<Id, Decimal>();

                    for(PoolTreatySection__c poolTreaty : lstAllPoolTreaty){
                        totalPoolShareTreaty += poolTreaty.TreatyShareRate__c;
                        mapTreatyShareRateByPool.put(poolTreaty.Pool__c, poolTreaty.TreatyShareRate__c);
                    }

                    List<PoolTreatySection__c> lstAllPoolSection = [SELECT Id, Pool__c, TECH_PoolShareRate__c, TreatyShareRate__c,SectionShareRate__c, SectionEpiSharedCeded__c, SectionEpiCededToPool__c, Treaty__c, Section__c, TreatyIsSelected__c, SectionIsSelected__c, Section__r.TotalEPI__c FROM PoolTreatySection__c WHERE Treaty__c = :objectTreaty.Id AND SectionIsSelected__c = TRUE];

                    for(PoolTreatySection__c poolSection : lstAllPoolSection){
                        if(mapTreatyShareRateByPool.containsKey(poolSection.Pool__c)){
                            poolSection.TreatyShareRate__c = mapTreatyShareRateByPool.get(poolSection.Pool__c);
                            Decimal totalSelectedPoolShare = 0;

                            if(mapTotalSelectedPoolShareSectionBySectionId.containsKey(poolSection.Section__c)){
                                totalSelectedPoolShare = mapTotalSelectedPoolShareSectionBySectionId.get(poolSection.Section__c);
                            }

                            totalSelectedPoolShare += poolSection.TreatyShareRate__c;
                            mapTotalSelectedPoolShareSectionBySectionId.put(poolSection.Section__c, totalSelectedPoolShare);
                        } 
                    }

                    for(PoolTreatySection__c poolSection : lstAllPoolSection){
                        if(mapTotalSelectedPoolShareSectionBySectionId.containsKey(poolSection.Section__c)){
                            Decimal totalSelectedSectionPoolShareTreaty = mapTotalSelectedPoolShareSectionBySectionId.get(poolSection.Section__c);
                            Decimal sectionEpiSharedCededValue = (poolSection.TreatyShareRate__c / totalSelectedSectionPoolShareTreaty) * 100;
                            poolSection.SectionShareRate__c = totalPoolShareTreaty.setscale(6);
                            poolSection.SectionEpiSharedCeded__c = sectionEpiSharedCededValue.setscale(6);

                            Decimal sectionEpiCededToPoolValue = (sectionEpiSharedCededValue / 100) * poolSection.Section__r.TotalEPI__c;
                            poolSection.SectionEpiCededToPool__c = sectionEpiCededToPoolValue.setscale(6);
                        }   
                    }

                    if(lstAllPoolSection.size() > 0){
                        update lstAllPoolSection;
                    }
                }
            }
            else{
               //RRA - ticket 1364 - 26072023 
                //**** */
                List<Id> lstIdSec = new List<Id>();  
                List<String> lstPoolConvert = new List<String>();  
                List<PoolTreatySection__c> lstPoolTreatySections = new List<PoolTreatySection__c>();
                map<Id, List<Id>> mapIdSeclstIdPool = new  map<Id, List<Id>>(); 
                Set<String> setExistedPoolId = new Set<String>();
                Boolean isPoolTreatySectionNotExist = false;
  
                 if(objectTreaty != null){
                     objectTreaty.Id = treatyId;
                     update objectTreaty;
                 }
                 
                 //RRA - ticket 1364 - 26072023 - convert lstPools to List Pools only
                 for (String pool : lstPools){
                     String pooId = pool.split(';')[0];
                     lstPoolConvert.add(pooId);
                 }
 
                 System.debug('lstPoolConvert == ' + lstPoolConvert );
                 System.debug('treatyId == ' + objectTreaty.Id );
 
               //RRA - ticket 1364 - 26072023 - create map related betwenn id Section and list pool
                 for (Section__c sec :  [SELECT Id, Treaty__c FROM Section__c WHERE Treaty__c =:objectTreaty.Id]){  
                     mapIdSeclstIdPool.put(sec.Id, lstPoolConvert);
                 }
 
                 System.debug('mapIdSeclstIdPool == ' + mapIdSeclstIdPool );
                 System.debug('mapIdSeclstIdPool == ' + mapIdSeclstIdPool.size() );
                 //MRA W-1364 27/10/23 Pool duplicate on treaty save : START
                 List<PoolTreatySection__c> existingPool = new List<PoolTreatySection__c> () ;
                 existingPool = [SELECT Id,Section__c,Treaty__c,Pool__c FROM PoolTreatySection__c WHERE Section__c IN :mapIdSeclstIdPool.keySet()] ;
                 System.debug('existingPool == ' + existingPool );

                 Map<String,PoolTreatySection__c> mapTECHIds = new Map<String,PoolTreatySection__c>() ;
                 if (existingPool.size() > 0) {
                    for (PoolTreatySection__c poolObj : existingPool) {
                        mapTECHIds.put(poolObj.Treaty__c + '-' + poolObj.Section__c + '-' + poolObj.Pool__c,poolObj) ;
                     }
                     System.debug('mapTECHIds == ' + mapTECHIds );
                 }
                 //MRA W-1364 27/10/23 Pool duplicate on treaty save : END
                 //RRA - ticket 1364 - 26072023 - Create/Update PoolTreatySection if Section exist already and Pool has been adding recently on Treaty
                 if (lstPoolConvert.size()>0 && mapIdSeclstIdPool.size() >0){
                     for (Id idSec : mapIdSeclstIdPool.keySet()){ 
                         for (Id idPool : mapIdSeclstIdPool.get(idSec)){
                             setExistedPoolId.add(objectTreaty.Id + '-' + idSec + '-' + idPool);
                             System.debug('setExistedPoolId == ' + setExistedPoolId );
                             PoolTreatySection__c poolTreatySection = new PoolTreatySection__c();
                             poolTreatySection.Pool__c = idPool;
                             poolTreatySection.Id = null;
                             poolTreatySection.TECH_upsertPoolTreatySection__c = objectTreaty.Id + '-' + idSec + '-' + idPool;
                             poolTreatySection.Treaty__c = objectTreaty.Id;
                             poolTreatySection.Section__c = idSec;
                             poolTreatySection.SectionIsSelected__c = true;
                             poolTreatySection.TreatyIsSelected__c = false;
                             System.debug('poolTreatySection == ' + poolTreatySection );
                            if (!mapTECHIds.keySet().contains(poolTreatySection.TECH_upsertPoolTreatySection__c)) {//MRA W-1364 27/10/23 Pool duplicate on treaty save
                                lstPoolTreatySections.add(poolTreatySection);
                            }
                         }
                     }
                 }
                 System.debug('lstPoolTreatySections.size() > 0 == ' + lstPoolTreatySections.size() );

                 if (lstPoolTreatySections.size() > 0){
                         //upsert lstPoolTreatySections TECH_upsertPoolTreatySection__c;
                         insert lstPoolTreatySections ;
                 } 

                //Covered Ceding Company
                List<String> lstNewAccountId = new List<String>();
                List<String> lstNewAccountIdInsert = new List<String>();
                List<CoveredCedingCompany__c> lstCovCedCompDelete = new List<CoveredCedingCompany__c>();
                List<CoveredCedingCompany__c> lstCovCedCompInsert = new List<CoveredCedingCompany__c>();
                List<CoveredCedingCompany__c> lstNewCovCedComp = [SELECT Id, Account__c
                                                                    FROM CoveredCedingCompany__c
                                                                    WHERE Treaty__c = :objectTreaty.Id
                                                                    AND TreatyIsSelected__c = TRUE];
                for(CoveredCedingCompany__c covCedCom : lstNewCovCedComp){
                    lstNewAccountId.add(covCedCom.Account__c);

                    if(!lstAccIdCovCedCom.contains(covCedCom.Account__c)){
                        lstCovCedCompDelete.add(covCedCom);
                    }
                }
                if (lstCovCedCompDelete.size() > 0){
                    delete lstCovCedCompDelete;
                }
                for(String accountId : lstAccIdCovCedCom){
                    if(!lstNewAccountId.contains(accountId)){
                        lstNewAccountIdInsert.add(accountId);
                    }
                }
                List<CoveredCedingCompany__c> lstNewCovCedCom = new List<CoveredCedingCompany__c>();
                for(String accId : lstNewAccountIdInsert){
                    CoveredCedingCompany__c covCedCom = new CoveredCedingCompany__c();
                    covCedCom.Account__c = accId;
                    covCedCom.Program__c = objectTreaty.Program__c;
                    covCedCom.Treaty__c = objectTreaty.Id;
                    covCedCom.TreatyIsSelected__c = true;
                    lstCovCedCompInsert.add(covCedCom);
                }
                if (lstCovCedCompInsert.size() > 0){
                    insert lstCovCedCompInsert;
                }

                //Pool Treaty Section
                List<PoolTreatySection__c> lstNewPoolTreatySect = new List<PoolTreatySection__c>();
                List<PoolTreatySection__c> lstOldPool = [SELECT Id, TreatyShareRate__c, Pool__c FROM PoolTreatySection__c WHERE Treaty__c = :objectTreaty.Id AND TreatyIsSelected__c = true];
                Set<Id> setOldPoolId = new Set<Id>();
                Set<Id> setNewPoolId = new Set<Id>();
                Set<Id> setPoolDel = new Set<Id>();
                Map<Id, Id> mapPoolVSpTreatySet = new Map<Id, Id>();

                for(PoolTreatySection__c oldPool : lstOldPool){
                    setOldPoolId.add(oldPool.Pool__c);
                    mapPoolVSpTreatySet.put(oldPool.Pool__c, oldPool.Id);
                }

                for(String pool : lstPools) {
                    String poolId = pool.split(';')[0];
                    Decimal shareRate = Decimal.valueOf(pool.split(';')[1]);

                    setNewPoolId.add(Id.valueOf(poolId));

                    if(mapPoolVSpTreatySet.containsKey(Id.valueOf(poolId))){
                        PoolTreatySection__c poolTreatySection = new PoolTreatySection__c();
                        poolTreatySection.Id = mapPoolVSpTreatySet.get(poolId);
                        poolTreatySection.TreatyShareRate__c = shareRate;
                        lstNewPoolTreatySect.add(poolTreatySection);
                    }

                    if(!setOldPoolId.contains(poolId)){
                        PoolTreatySection__c poolTreatySection = new PoolTreatySection__c();
                        poolTreatySection.Pool__c = poolId;
                        poolTreatySection.Treaty__c = objectTreaty.Id;
                        poolTreatySection.TreatyIsSelected__c = true;
                        poolTreatySection.TreatyShareRate__c = shareRate;
                        lstNewPoolTreatySect.add(poolTreatySection);
                    }
                }

                for(Id poolId : setOldPoolId){
                    if(!setNewPoolId.contains(poolId)){
                        setPoolDel.add(poolId);
                    }
                }

                if(setPoolDel.size() > 0){
                    List<PoolTreatySection__c> lstPoolDel = [SELECT Id, TreatyShareRate__c, Pool__c FROM PoolTreatySection__c WHERE Pool__c IN :setPoolDel AND Treaty__c = :objectTreaty.Id];

                    if(lstPoolDel.size() > 0){
                        delete lstPoolDel;
                    }
                }

                if (lstNewPoolTreatySect.size() > 0){
                    upsert lstNewPoolTreatySect;
                }

                List<PoolTreatySection__c> lstAllPoolTreaty = [SELECT Id, Pool__c, TECH_PoolShareRate__c, TreatyShareRate__c,SectionShareRate__c, SectionEpiSharedCeded__c, SectionEpiCededToPool__c, Treaty__c, Section__c, TreatyIsSelected__c, SectionIsSelected__c FROM PoolTreatySection__c WHERE Treaty__c = :treatyId AND TreatyIsSelected__c = TRUE];
                Decimal totalPoolShareTreaty = 0;
                Map<Id, Decimal> mapTreatyShareRateByPool = new Map<Id, Decimal>();
                Map<Id, Decimal> mapTotalSelectedPoolShareSectionBySectionId = new Map<Id, Decimal>();

                for(PoolTreatySection__c poolTreaty : lstAllPoolTreaty){
                    totalPoolShareTreaty += poolTreaty.TreatyShareRate__c;
                    mapTreatyShareRateByPool.put(poolTreaty.Pool__c, poolTreaty.TreatyShareRate__c);
                }

                List<PoolTreatySection__c> lstAllPoolSection = [SELECT Id, Pool__c, TECH_PoolShareRate__c, TreatyShareRate__c,SectionShareRate__c, SectionEpiSharedCeded__c, SectionEpiCededToPool__c, Treaty__c, Section__c, TreatyIsSelected__c, SectionIsSelected__c, Section__r.TotalEPI__c FROM PoolTreatySection__c WHERE Treaty__c = :treatyId AND SectionIsSelected__c = TRUE];

                for(PoolTreatySection__c poolSection : lstAllPoolSection){
                    if(mapTreatyShareRateByPool.containsKey(poolSection.Pool__c)){
                        poolSection.TreatyShareRate__c = mapTreatyShareRateByPool.get(poolSection.Pool__c);
                        Decimal totalSelectedPoolShare = 0;

                        if(mapTotalSelectedPoolShareSectionBySectionId.containsKey(poolSection.Section__c)){
                            totalSelectedPoolShare = mapTotalSelectedPoolShareSectionBySectionId.get(poolSection.Section__c);
                        }

                        totalSelectedPoolShare += poolSection.TreatyShareRate__c;
                        mapTotalSelectedPoolShareSectionBySectionId.put(poolSection.Section__c, totalSelectedPoolShare);
                    } 
                }

                for(PoolTreatySection__c poolSection : lstAllPoolSection){
                    if(mapTotalSelectedPoolShareSectionBySectionId.containsKey(poolSection.Section__c)){
                        Decimal totalSelectedSectionPoolShareTreaty = mapTotalSelectedPoolShareSectionBySectionId.get(poolSection.Section__c);
                        Decimal sectionEpiSharedCededValue = (poolSection.TreatyShareRate__c / totalSelectedSectionPoolShareTreaty) * 100;
                        poolSection.SectionShareRate__c = totalPoolShareTreaty.setscale(6);
                        poolSection.SectionEpiSharedCeded__c = sectionEpiSharedCededValue.setscale(6);

                        Decimal sectionEpiCededToPoolValue = (sectionEpiSharedCededValue / 100) * poolSection.Section__r.TotalEPI__c;
                        poolSection.SectionEpiCededToPool__c = sectionEpiCededToPoolValue.setscale(6);
                    }   
                }

                if(lstAllPoolSection.size() > 0){
                    update lstAllPoolSection;
                }

                mapResults.put('lstAllPoolSection', lstAllPoolSection);

            }

            
            mapResults.put('Success', 'Success');
        }catch(Exception ex) {
            mapResults.put('Error', ex.getMessage());
            Database.rollback(sp);
        }
        return mapResults;
    }

    /**
    * @description Method to check visibility of fields on selected Treaty
    * @param Id selectedTreatyId
    * @return Map<String,Boolean>
    */
    @AuraEnabled
    public static Map<String,Boolean> checkFieldsVisibility(Id selectedTreatyId){
        Map<String,Boolean> mapResults = new Map<String,Boolean>();
        List<String> lstRecordType = AP_Constant.reqRTSigning.split('-');
        List<Section__c> lstTreatySections = [SELECT Id
        FROM Section__c
        WHERE Treaty__c = :selectedTreatyId ];

        List<Request__c> lstTreatyRequests = [SELECT Id
        FROM Request__c
        WHERE Treaty__c = :selectedTreatyId
        AND RecordType.DeveloperName =: lstRecordType[1]
        AND ReinsurerStatus__c !=: AP_Constant.statusSetup ];

        Profile userProfile = [SELECT Id, Name FROM Profile WHERE Id =: UserInfo.getProfileId()];

        if(lstTreatyRequests.size() > 0 && userProfile.Name != AP_Constant.profileSysAdmin && userProfile.Name != AP_Constant.profileSysAdminAGRe && userProfile.Name != AP_Constant.profileDelagatedAdmin){
            mapResults.put('PlacementShare', true);
            mapResults.put('CessionShare', true); //RRA - ticekt 1966 - 14032024
        }
        else{
            mapResults.put('PlacementShare', false);
            mapResults.put('CessionShare', false); //RRA - ticekt 1966 - 14032024
        }
        if(lstTreatySections.size() > 0){
            mapResults.put('Type', true);
        }
        else{
            mapResults.put('Type', false);
        }
        return mapResults;
    }

    /**
    * @description Method to return Pools of the selected Treaty
    * @param Id selectedTreatyId
    * @return  List<Pool__c>
    */
    @AuraEnabled
    public static List<Pool__c> getPoolsByTreatyId(String selectedTreatyId) {
        List<PoolTreatySection__c> lstPoolTreatySections = [SELECT Id, Pool__r.ShareRate__c, Pool__c, Pool__r.Name, TreatyShareRate__c
        FROM PoolTreatySection__c
        WHERE Treaty__c = :selectedTreatyId
        AND TreatyIsSelected__c = TRUE
        ];
        List<Pool__c> lstPools = new List<Pool__c>();

        for(PoolTreatySection__c poolTreatySection : lstPoolTreatySections){
            Pool__c pool = new Pool__c();
            pool.Id = poolTreatySection.Pool__c;
            pool.Name = poolTreatySection.Pool__r.Name;
            pool.ShareRate__c = poolTreatySection.TreatyShareRate__c;
            lstPools.add(pool);
        }

        return lstPools;
    }

    /**
    * @description Method to return ActorReferenceIndex of the selected UW year
    * @param String uwYear
    * @return String
    */
    @AuraEnabled(Cacheable = true)
    public static String getActorReferenceIndex(String uwYear) {
        String lastActorRefIndex = '';
        List<Treaty__c> lstTreaty = [SELECT Id, Name, Actor_Reference__c, ReferenceSequence__c FROM Treaty__c ORDER BY CreatedDate  DESC LIMIT 1];
        
        CS_TreatyReference__c treatyRefCustomSetting = [SELECT Id, ReferenceSequence__c FROM CS_TreatyReference__c LIMIT 1];
        Decimal treatyRef = Decimal.valueOf(treatyRefCustomSetting.ReferenceSequence__c);

        if(lstTreaty != null && lstTreaty.size() > 0){
            if(treatyRef < Decimal.valueOf(System.Label.ActorReferenceIndex)){
                lastActorRefIndex = System.Label.ActorReferenceIndex;
            }
            else{
                Decimal actorRefIndexVal = treatyRef + 1;
                lastActorRefIndex = String.valueOf(actorRefIndexVal);
            }
        }
        else {
            lastActorRefIndex = System.Label.ActorReferenceIndex;
        }

        return uwYear + '-' + String.valueOf(lastActorRefIndex);
    }

    /**
    * @description Method to get covered ceding companies of the selected Treaty
    * @param String treatyId
    * @return List<Id>
    */
    @AuraEnabled
    public static List<Id> getAllExistedCoveredCedingComForSection(String treatyId){
        Set<Id> setExistedAccountId = new Set<Id>();

        for(CoveredCedingCompany__c cov : [SELECT Id, Account__c, Account__r.Name FROM CoveredCedingCompany__c WHERE Treaty__c = :treatyId AND TreatyIsSelected__c = FALSE AND SectionIsSelected__c = TRUE]){
            setExistedAccountId.add(cov.Account__c);
        }

        List<Id> lstExistedAccountId = new List<Id>(setExistedAccountId);
        return lstExistedAccountId;
    }

    /**
    * @description Method to if treaty name exists
    * @param Id treatyId, String programId, String treatyName, Boolean isTreatyCopy
    * @return Boolean
    */
    @AuraEnabled
    public static Boolean checkTreatyName(Id treatyId, String programId, String treatyName, Boolean isTreatyCopy){
        Boolean result = false;
        //    String query = 'SELECT Name FROM Treaty__c  WHERE Program__r.UwYear__c =:uwYearOpenModal AND Name =:treatyName';
        String query = 'SELECT Name FROM Treaty__c  WHERE Program__c =: programId  AND Name =:treatyName';
        List <Treaty__c> lstTreatyNames = new List<Treaty__c>();
        if( (treatyId != null || treatyId != '') && !isTreatyCopy){
            query += ' AND Id !=: treatyId';
        }
        lstTreatyNames = Database.query(query);
        if(lstTreatyNames.size() > 0){
            result = true;
        }

        return result;
    }
}