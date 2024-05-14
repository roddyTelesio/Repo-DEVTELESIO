public with sharing class LWC01_NewProgram {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Controller for Lightning Web Component lwc01NewProgram
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 22-OCT-2019  MBE   1.0      Initial version
-- 20-Apr-2020  SAU   1.1      Unique Treaty ref when copying
-- 27-Apr-2020  SAU   1.2      Copy related sections
-- 08-May-2020  SAU   1.3      Program name must be unique
-- 27-AUG-2020  SAU   1.4      Set LTA values of Treaties to null when LTA on Program = No
                               Set Loss deposit mode to null when Loss deposit = No
-- 04-SEP-2020  SAU   1.5      Set LTA values null when LTA = No
-- 07-JAN-2021  NBI   1.6      Do not retain Section/Option when copying Program - W-0786
-- 17-MAY-2021  MBE   1.7      W-0971 - CONDITION - TREATY - problème de calcul du champ Actor_Reference__cct
-- 26-MAY-2021  MBE   1.8      W-0971 - CONDITION - TREATY - problème de calcul du champ Actor_Reference__cct
-- 25-JUN-2021  MBE   1.9      Use Custom Setting for Treaty Reference
-- 08-JUL-2021  NBI   2.0      W-0992: Third Party Management	
-- 22-JUL-2021  MBE   2.1      W-0913 - ODS - Pas de SHARERATE au niveau des T_SECTION_POOLs
-- 24-JUL-2021  MBE   2.2      SOQL Injection for getCoveredCedingComp()	
-- 15-JUN-2022  AMI   2.3      W-0779: Changement de nature du programme																						   
--------------------------------------------------------------------------------------
**************************************************************************************/

    /**
    * @description Method to create and edit Program
    * @param Program__c objProg, List<String> lstAccIdCovCedCom, Id programId, Boolean editProgram
    * @return Map<String, Object>
    */
    @AuraEnabled
    public static Map<String, Object> saveProgramRecord(Program__c objProg, List<String> lstAccIdCovCedCom, Id programId, Boolean editProgram){
        Map<String, Object> mapResults = new Map<String, Object>();
        Map<Id, Section__c> mapOldSecdToNewSection = new Map<Id, Section__c>();
        List<String> lstLossDepositModeFromPrg = new List<String>();
        try{
            if(editProgram == false){
                if(objProg != null){
                    if(programId != null){
                        //copy program - to set TECH_Actor2Id__c to null
                        objProg.TECH_Actor2Id__c = null;
                    }
                    objProg.TECH_ShowClosePreviousPhaseBtn__c = '1';

                    insert objProg;
                }

                List<CoveredCedingCompany__c> lstCovCedCom = new List<CoveredCedingCompany__c>();
                for(String accId : lstAccIdCovCedCom){
                    CoveredCedingCompany__c covCedCom = new CoveredCedingCompany__c();
                    covCedCom.Account__c = accId;
                    covCedCom.Program__c = objProg.Id;
                    covCedCom.ProgramIsSelected__c = true;
                    lstCovCedCom.add(covCedCom);
                }

                if(lstCovCedCom.size() > 0){
                    insert lstCovCedCom;
                }
            }
            else{
                if(objProg != null){
                    objProg.Id = programId;
                    //SAU
                    if(objProg.LossDeposit__c == '2'){
                        objProg.LossDepositMode__c = null;
                        objProg.LossDepositLevel__c = null;
                    }
                    if(objProg.LTA__c == '2'){
                        objProg.LTAExpiryDate__c = null;
                        objProg.LTAInceptionDate__c = null;
                        objProg.LTAPattern__c = null;
                        objProg.LTARenegociation__c = null;
                    }
                    update objProg;
                    
                    //RRA - ticket 1554 - 07082023 
                    //Step 1 : Get LossDepositMode__c from program for existing Id's and convert multipicklist to list
                    for (Program__c prg :[SELECT Id, LossDepositMode__c FROM Program__c WHERE Id =:objProg.Id AND LossDepositMode__c != null]){ //RRA - ticket 1562 29082023
                        lstLossDepositModeFromPrg = prg.LossDepositMode__c.split(';');
                     }
                     System.debug('lstLossDepositModeFromPrg == '+ lstLossDepositModeFromPrg);
 
                     //Step 2 : Get LossDepositMode__c from Treaty for existing Id on program above
                     if (lstLossDepositModeFromPrg.size()>0){
                         List<Treaty__c> lstTreaty = [SELECT Id, Program__c, LossDepositMode__c FROM Treaty__c WHERE Program__c =:objProg.Id];
                         
                     //Step 3 : Update LossDepositMode__c on Treaty from LossDepositMode__c on program
                             if (lstTreaty.size()>0){
                                 for (Treaty__c treaty : lstTreaty){
                                     string strLossDepositModeFromPrg = string.join(lstLossDepositModeFromPrg,';'); // convert list to string with separator dot comma
                                     treaty.LossDepositMode__c = strLossDepositModeFromPrg; // set LossDepositMode__c field mulripicklist from string strLossDepositModeFromPrg 
                                 }
                                 update lstTreaty;
                         }
                     }
                }
                List<String> lstNewAccountId = new List<String>();
                List<String> lstNewAccountIdInsert = new List<String>();
                List<CoveredCedingCompany__c> lstCovCedCompDelete = new List<CoveredCedingCompany__c>();
                List<CoveredCedingCompany__c> lstCovCedCompInsert = new List<CoveredCedingCompany__c>();
                List<CoveredCedingCompany__c> lstNewCovCedComp = [SELECT Id, Account__c
                                                                    FROM CoveredCedingCompany__c
                                                                    WHERE Program__c = :objProg.Id
                                                                    AND ProgramIsSelected__c = TRUE];

                for(CoveredCedingCompany__c covCedCom : lstNewCovCedComp){
                    lstNewAccountId.add(covCedCom.Account__c);
                    if(!lstAccIdCovCedCom.contains(covCedCom.Account__c)){
                        lstCovCedCompDelete.add(covCedCom);
                    }
                }

                if(lstCovCedCompDelete.size() > 0){
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
                    covCedCom.Program__c = objProg.Id;
                    covCedCom.ProgramIsSelected__c = true;
                    lstCovCedCompInsert.add(covCedCom);
                }

                if(lstCovCedCompInsert.size() > 0){
                    insert lstCovCedCompInsert;
                }
                // SAU -- check if LTA of program == No
                if(editProgram == true && (objProg.LTA__c == '2' || objProg.TacitRenewal__c == '2') ){
                    List<Treaty__c> lstUpdatedTreaties = new List<Treaty__c>();
                    List <Treaty__c> lstProgramTreaties = [SELECT Id,
                            LTA__c,
                            LTAExpiryDate__c,
                            LTAInceptionDate__c,
                            LTAPattern__c,
                            LTARenegotiation__c,
                            EarlyTerminationDate__c,
                            TacitRenewal__c,
                            Advance_notice__c
                    FROM Treaty__c
                    WHERE Program__c =: objProg.Id];

                    for(Treaty__c treaty : lstProgramTreaties){
                        if(objProg.LTA__c == '2'){
                            treaty.LTA__c = '2';
                            treaty.LTAExpiryDate__c = null;
                            treaty.LTAInceptionDate__c = null;
                            treaty.LTAPattern__c = null;
                            treaty.LTARenegotiation__c = null;
                            treaty.EarlyTerminationDate__c = null;
                        }
                        if(objProg.TacitRenewal__c == '2'){
                            treaty.TacitRenewal__c = '2';
                            treaty.Advance_notice__c = null;
                        }
                        lstUpdatedTreaties.add(treaty);
                    }
                    if(lstUpdatedTreaties.size() > 0){
                        update lstUpdatedTreaties;
                    }
                }
            }

            if(programId != null && editProgram == false){
                /***
                *
                * Copy Treaty
                *
                */
                List<String> lstTreatyFields = AP_Constant.getCreatableFieldsByObjName(AP_Constant.sObjectTreaty);
                String strTreatyFields = String.join(lstTreatyFields , ', ');
                Set<Id> setTreatyId =  new Set<Id>();
                List<Treaty__c> lstNewTreaty = new List<Treaty__c>();
                String uwyProg = objProg.UwYear__c + '%' ; //MRA W-930 20/07/2022
                String queryTreaty = 'select Id, Program__c, '
                        + strTreatyFields
                        + ' from Treaty__c where (Program__c = :programId) ' ;
                List<Treaty__c> lstTreaty = Database.query(queryTreaty);

                Treaty__c lastTreaty = [SELECT Id, Actor_Reference__c, ReferenceSequence__c
                                        FROM Treaty__c WHERE Actor_Reference__c LIKE :UWYProg //MRA W-930 20/07/2022
                                        ORDER BY CreatedDate  DESC LIMIT 1];

                CS_TreatyReference__c treatyRefCustomSetting = [SELECT Id, ReferenceSequence__c FROM CS_TreatyReference__c LIMIT 1];
                Decimal treatyRef = Decimal.valueOf(treatyRefCustomSetting.ReferenceSequence__c);

                Decimal lastRef = 0;
                List<String> refArr = new List<String>();

                if(lastTreaty != null){
                    refArr = lastTreaty.Actor_Reference__c.split('-');
                    lastRef = Decimal.valueOf(lastTreaty.ReferenceSequence__c);
                }

                for(Integer i = 0; i < lstTreaty.size(); i ++){
//                  String newRef = (('0'.repeat(8))+(lastRef + (i + 1))).right(8);
                    String newRef = String.valueOf(treatyRef + (i + 1));
                    Treaty__c treaty = lstTreaty[i];
                    setTreatyId.add(treaty.Id);

                    Treaty__c newTreaty = treaty.clone(false, false, false, false);
                    newTreaty.Program__c = objProg.Id;
                    newTreaty.TECH_OldTreatyId__c = treaty.Id;
                    newTreaty.TreatyReference__c = refArr[0] + '-'+ String.valueOf(newRef);
                    newTreaty.WebXLReference__c = refArr[0] + '-'+ String.valueOf(newRef);
                    newTreaty.Actor_Reference__c = refArr[0] + '-'+ String.valueOf(newRef);
                    newTreaty.TECH_Actor2Id__c = null;
                    newTreaty.TECH_RenewedFromTreaty__c = null; //RRA ticket 1354 - 30112022
                    lstNewTreaty.add(newTreaty); 
                }
                if(lstNewTreaty.size() > 0){
                    insert lstNewTreaty;
                }

                /***
                *
                * Copy Covered Ceding Company on Treaty
                *
                */
                List<String> lstCoveredCedCompFields = AP_Constant.getCreatableFieldsByObjName(AP_Constant.sObjCoveredCedingComp);
                String strCoveredCedCompFields = String.join(lstCoveredCedCompFields , ', ');
                String queryCoveredCedComp = 'select Id, Program__c, Account__c,  '
                        + strCoveredCedCompFields
                        + ' from CoveredCedingCompany__c where (Program__c = :programId) '
                        + 'and (TreatyIsSelected__c = true ) '
                        + 'and (Account__c IN :lstAccIdCovCedCom) ';

                List<CoveredCedingCompany__c> lstCoveredCedComp = Database.query(queryCoveredCedComp);

                //Build map Covered Ceding Company (TreatyId, List CoveredCedingCompany)
                Map<Id, List<CoveredCedingCompany__c>> mapCoveredCedCompTreaty = new Map<Id, List<CoveredCedingCompany__c>>();
                for(CoveredCedingCompany__c covCedComp : lstCoveredCedComp){
                    List<CoveredCedingCompany__c> lstCov = new List<CoveredCedingCompany__c>();

                    if(mapCoveredCedCompTreaty.containsKey(covCedComp.Treaty__c)){
                        lstCov = mapCoveredCedCompTreaty.get(covCedComp.Treaty__c);
                        lstCov.add(covCedComp);
                        mapCoveredCedCompTreaty.put(covCedComp.Treaty__c, lstCov);
                    }
                    else{
                        lstCov.add(covCedComp);
                        mapCoveredCedCompTreaty.put(covCedComp.Treaty__c, lstCov);
                    }
                }

                List<CoveredCedingCompany__c> lstNewCoveredCedingCompanies = new List<CoveredCedingCompany__c>();

                for(Treaty__c treaty : lstNewTreaty){
                    List<CoveredCedingCompany__c> lstCoveredCedingCompanies = new List<CoveredCedingCompany__c>();

                    if(mapCoveredCedCompTreaty.containsKey(treaty.TECH_OldTreatyId__c)){
                        lstCoveredCedingCompanies = mapCoveredCedCompTreaty.get(treaty.TECH_OldTreatyId__c);
                    }

                    for(CoveredCedingCompany__c cov : lstCoveredCedingCompanies){
                        CoveredCedingCompany__c newCov = cov.clone(false, false, false, false);
                        newCov.Program__c = objProg.Id;
                        newCov.Treaty__c = treaty.Id;
                        newCov.TreatyIsSelected__c = true;
                        lstNewCoveredCedingCompanies.add(newCov);
                    }
                }

                if(lstNewCoveredCedingCompanies.size() > 0){
                    insert lstNewCoveredCedingCompanies;
                }

                /***
                *
                * Copy Pool Treaty Section on Treaty
                *
                */
                List<String> lstPoolTreatyFields = AP_Constant.getCreatableFieldsByObjName(AP_Constant.sObjPoolTreatySection);
                String strPoolTreatyFields  = String.join(lstPoolTreatyFields , ', ');
                String queryPoolTreaty = 'select Id, '
                        + strPoolTreatyFields
                        + ' from PoolTreatySection__c where (Treaty__c IN :setTreatyId) '
                        + 'and (TreatyIsSelected__c = true ) ';

                List<PoolTreatySection__c> lstPoolTreaty = Database.query(queryPoolTreaty);
                Map<Id, List<PoolTreatySection__c>> mapPoolTreaty = new Map<Id, List<PoolTreatySection__c>>();
                for(PoolTreatySection__c poolTreaty : lstPoolTreaty){
                    List<PoolTreatySection__c> lstPoolTr = new List<PoolTreatySection__c>();

                    if(mapPoolTreaty.containsKey(poolTreaty.Treaty__c)){
                        lstPoolTr = mapPoolTreaty.get(poolTreaty.Treaty__c);
                        lstPoolTr.add(poolTreaty);
                        mapPoolTreaty.put(poolTreaty.Treaty__c, lstPoolTr);
                    }
                    else{
                        lstPoolTr.add(poolTreaty);
                        mapPoolTreaty.put(poolTreaty.Treaty__c, lstPoolTr);
                    }
                }

                List<PoolTreatySection__c> lstNewPoolTreaty = new List<PoolTreatySection__c>();

                for(Treaty__c treaty : lstNewTreaty){
                    List<PoolTreatySection__c> lstPoolTreaties = new List<PoolTreatySection__c>();

                    if(mapPoolTreaty.containsKey(treaty.TECH_OldTreatyId__c)){
                        lstPoolTreaties = mapPoolTreaty.get(treaty.TECH_OldTreatyId__c);
                    }

                    for(PoolTreatySection__c poolTreaty : lstPoolTreaties){
                        PoolTreatySection__c newPoolTreaty = poolTreaty.clone(false, false, false, false);
                        newPoolTreaty.Treaty__c = treaty.Id;
                        lstNewPoolTreaty.add(newPoolTreaty);
                    }
                }
                if(lstNewPoolTreaty.size() > 0){
                    insert lstNewPoolTreaty;
                }

                /***
                *
                * Copy Section
                *
                */
                List<String> lstSectionFields = AP_Constant.getCreatableFieldsByObjName(AP_Constant.sObjectSection);
                String strSectionFields = String.join(lstSectionFields , ', ');
                Set<Id> setSectionId =  new Set<Id>();

                String querySection = 'select Id, Treaty__c, '
                        + strSectionFields
                        + ' from Section__c where (Program__c = :programId) ' ;

                List<Section__c> lstSection = Database.query(querySection);

                //Build map Section(Treaty Id, Section)
                Map<Id, List<Section__c>> mapSectionTreaty = new Map<Id, List<Section__c>>();

                for(Section__c section : lstSection){
                    List<Section__c> lstSections = new List<Section__c>();

                    if(mapSectionTreaty.containsKey(section.Treaty__c)){
                        lstSections = mapSectionTreaty.get(section.Treaty__c);
                        lstSections.add(section);
                    }
                    else{
                        lstSections.add(section);
                    }
                    mapSectionTreaty.put(section.Treaty__c, lstSections);
                }

                List<Section__c> lstNewSection = new List<Section__c>();
                List<Section__c> lstNewOptSections = new List<Section__c>();

                for(Treaty__c treaty : lstNewTreaty){
                    List<Section__c> lstSections = new List<Section__c>();

                    if(mapSectionTreaty.containsKey(treaty.TECH_OldTreatyId__c)){
                        lstSections = mapSectionTreaty.get(treaty.TECH_OldTreatyId__c);
                    }

                    for(Section__c section : lstSections){
                        Section__c newSection = section.clone(false, false, false, false);
                        newSection.Program__c = objProg.Id;
                        newSection.Treaty__c = treaty.Id;
                        newSection.TECH_OldSectionId__c = section.Id;
                        newSection.TECH_Actor2Id__c = null;
                        newSection.Retained_to_lead__c = false;
                        if(newSection.RelatedSection__c != null){
                            lstNewOptSections.add(newSection);
                        }else{
                            mapOldSecdToNewSection.put(section.Id, newSection);
                            lstNewSection.add(newSection);
                        }
                        setSectionId.add(section.Id);
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
                    lstNewSection.addAll(lstNewOptSections);
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
                        + ' from CoveredCedingCompany__c where (Program__c = :programId) '
                        + 'and (SectionIsSelected__c = true ) '
                        + 'and (Account__c IN :lstAccIdCovCedCom) ';
                List<CoveredCedingCompany__c> lstCoveredCedCompSection = Database.query(queryCoveredCedCompSection);

                //Build map Covered Ceding Company for section (SectionId, List<CoveredCedingCompany__c)
                Map<Id, List<CoveredCedingCompany__c>> mapCoveredCedCompSection = new Map<Id, List<CoveredCedingCompany__c>>();
                for(CoveredCedingCompany__c covCedCom : lstCoveredCedCompSection){
                    List<CoveredCedingCompany__c> lstCov = new List<CoveredCedingCompany__c>();

                    if(mapCoveredCedCompSection.containsKey(covCedCom.Section__c)){
                        lstCov = mapCoveredCedCompSection.get(covCedCom.Section__c);
                        lstCov.add(covCedCom);
                    }
                    else{
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
                        newCov.Program__c = objProg.Id;
                        newCov.Treaty__c = section.Treaty__c;
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

                //Build map Reinstatements (SectionId, List Reinstatement)
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
                String queryPoolSection = 'select Id, '
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
                        newPoolSection.Treaty__c = section.Treaty__c;
                        lstNewPoolSection.add(newPoolSection);
                    }
                }
                if(lstNewPoolSection.size() > 0){
                    insert lstNewPoolSection;
                }
            }
            mapResults.put('Success', 'Program Created Successfully');
        }
        catch(Exception ex) {
            mapResults.put('Error', ex.getMessage());
        }
        return mapResults;
    }

    /**
    * @description Method to get Covered Ceding Companies of selected Program/Treaty/Section
    * @param String ObjectName, String fieldName, String value, List<String> selectedRecId
    * @return List<SObjectResult>
    */
    @AuraEnabled(Cacheable=true)
    public static List<SObjectResult> getCoveredCedingComp(String ObjectName, String fieldName, String value, List<String> selectedRecId) {
        List<SObjectResult> sObjectResultList = new List<SObjectResult>();
        Map<String, Id> mapRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectAcc});
        String recordTypeIdCovCedingCom = mapRecTypeId.get(AP_Constant.accRTCoveredCedingCompany);
        if(selectedRecId == null) {
            selectedRecId = new List<String>();
        }

        if(String.isNotEmpty(value)) {
            // String strValue = '\'%' + value.trim() + '%\'';
            // String query = 'Select Id,'+fieldName+' FROM '+ObjectName+' WHERE IsActive__c = TRUE AND '+fieldName+' LIKE \'%' + value.trim() + '%\' and ID NOT IN: selectedRecId and RecordTypeId = :recordTypeIdCovCedingCom';
            
            String strValue = '%' + String.escapeSingleQuotes(value.trim()) + '%';
            String query = 'Select Id, Name from Account where Name LIKE :strValue and IsActive__c = TRUE and ID NOT IN: selectedRecId AND RecordTypeId = :recordTypeIdCovCedingCom ';

            for(SObject so : Database.query(query)) {
                String fieldvalue = (String)so.get(fieldName);
                sObjectResultList.add(new SObjectResult(fieldvalue, so.Id));
            }
        }
        return sObjectResultList;
    }

    /**
    * @description Method to get Covered Ceding Companies for a particular Program
    * @param String programId
    * @return List<SObjectResult>
    */
    @AuraEnabled
    public static List<CoveredCedingCompany__c> getCoveredCedingCompanies(String programId) {
        return [
                SELECT Id, Name, Account__r.Name
                FROM CoveredCedingCompany__c
                WHERE Program__c = :programId AND ProgramIsSelected__c = TRUE
        ];
    }

    /**
    * @description Method to check if there are Program(s) for a Principal Ceding Company and an UW Year
    * @param String uwYear, String principalCedingCompany
    * @return Boolean
    */
    @AuraEnabled(Cacheable = true)
    public static Boolean isProgramEmpty(String uwYear, String principalCedingCompany) {
        Boolean result = false;
        List<Program__c> lstPrograms = [SELECT Id FROM Program__c WHERE UwYear__c = :uwYear AND PrincipalCedingCompany__c = :principalCedingCompany];
        if(lstPrograms.size() > 0){
            result = false;
        }
        else{
            result = true;
        }
        return result;
    }

    /**
    * @description Method to get Covered Ceding Companies for Treaty
    * @param Id programId
    * @return Boolean
    */
    @AuraEnabled
    public static List<Id> getAllExistedCoveredCedingComForTreaty(Id programId){
        Set<Id> setExistedAccountId = new Set<Id>();
        List<CoveredCedingCompany__c> lstAllCovCedCom = [SELECT Id, Account__c, Account__r.Name FROM CoveredCedingCompany__c WHERE Program__c = :programId AND TreatyIsSelected__c = TRUE];

        for(CoveredCedingCompany__c cov : lstAllCovCedCom){
            if(!setExistedAccountId.contains(cov.Account__c)){
                setExistedAccountId.add(cov.Account__c);
            }
        }

        List<Id> lstExistedAccountId = new List<Id>(setExistedAccountId);
        return lstExistedAccountId;
    }

    /**
    * @description Method to get Program details
    * @param Id programId
    * @return Program__c
    */
    //AMI 15/06/22 W:0779
    //query "Tech_CountTreaty" in order to disable update on nature if counter > 0
    @AuraEnabled
    public static Program__c getProgram(Id programId){
        Program__c program = [SELECT Id,
                Name,
                LTA__c,
                InceptionDate__c,
                LTAExpiryDate__c,
                LTAInceptionDate__c,
                Macro_L_O_B__c,
                Expirydate__c,
                STLT__c,
                TacitRenewal__c,
                WordingName__c,
                WordingName2__c,
                WordingName3__c,
                WordingName4__c,
                Nature__c,
                LossDeposit__c,
                LossDepositMode__c,
                LossDepositLevel__c,
                LTARenegociation__c,
                EarlyTerminationDate__c,
                AdvanceNotice__c,
                RenewedFromProgram__c,
                TypeOfRenew__c,
                TechCountTreaty__c
        FROM Program__c WHERE Id =: programId];
        return program;
    }

    /**
    * @description Method to check if Program name exists for the UW year
    * @param String programName, String programId, Boolean isProgramCopy, String valueUWYear
    * @return Boolean
    */
    @AuraEnabled
    public static Boolean checkProgramName(String programName, String programId, Boolean isProgramCopy, String valueUWYear){
        Boolean result = false;
        String query = 'SELECT Name FROM Program__c WHERE UwYear__c = :valueUWYear AND Name = :programName';
        List <Program__c> lstProgramNames =  new List<Program__c>();

        if((programId != null || programId != '') && !isProgramCopy ){
            query += ' AND Id !=: programId';
        }

        lstProgramNames = Database.query(query);

        if(lstProgramNames.size() > 0){
            result = true;
        }

        return result;
    }

    /**
    * @description Method to check if Program has Lead Requests
    * @param Id programId
    * @return Boolean
    */
    @AuraEnabled
    public static Boolean checkIfLeadPresent(Id programId){
        List<String> lstRecordTypeArr = AP_Constant.reqRTLead.split('-');
        Boolean result = false;
        String strParent = 'parent';
        List<Request__c> lstProgramLeadRequests = [SELECT Id
                                                    FROM Request__c
                                                    WHERE Program__c =: programId
                                                    AND RecordType.DeveloperName =:lstRecordTypeArr[1]
                                                    AND ReinsurerStatus__c !=: AP_Constant.statusSetup
                                                    AND TECH_LeadType__c = :strParent];
        if(lstProgramLeadRequests.size() > 0){
            return true;
        }
        else{
            return false;
        }
    }

    /**
    * @description Method to get number of days between Inception and Expiry dates
    * @param Date ltaInceptionDate, Date ltaExpiryDate
    * @return Integer
    */
    @AuraEnabled
    public static Integer checkForFebruaryLeapYear(Date ltaInceptionDate, Date ltaExpiryDate){
        Integer count = 0;
        if(ltaInceptionDate != null){
            Integer i = ltaInceptionDate.year();

            if((ltaInceptionDate.month() > 2) || ((ltaInceptionDate.month() == 2) && (ltaInceptionDate.day() == 29) && (Date.isLeapYear(ltaInceptionDate.year())))){
                i++;
            }

            while (i <= ltaExpiryDate.year()){
                if (i == ltaExpiryDate.year()){
                    if ((ltaExpiryDate.month() == 2 && ltaExpiryDate.day() < 29) || (ltaExpiryDate.month() < 2)){
                        i++;
                        continue;
                    }
                }

                if(Math.mod(i, 4) == 0){
                    count++;
                }

                i++;
            }
        }

        return count;
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
        public SObjectResult(){}
    }
}