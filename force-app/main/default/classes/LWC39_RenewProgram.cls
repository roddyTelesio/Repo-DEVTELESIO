public with sharing class LWC39_RenewProgram {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Controller for Lightning Web Component lwc39RenewProgram
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 13-JUL-2019  MBE   1.0      Initial version
-- 22-DEC-2020  NBI   1.1      Do not retain Section/Option when copying - W-0786
-- 24-DEC-2020  NBI   1.2      Align env. after Luc's changes on UAT 23/12
                                - removed Pool/Treaty from PoolTreatySection query
                                - added TECH_Actor2Id__c = null for Requests
-- 22-MAR-2021  MBE   1.3      W-0875 - Renew - Renewed from section option
-- 13-OCT-2021  MBE   1.4      W-1035 - Production - Demande d'analyse du comportement des pools de la section suite à un renouvellement
-- 01-JUN-2022  AMI   1.5      W-0941 - Renew - Message d'erreur sur Loss deposit mode alors que Loss deposit = No
--------------------------------------------------------------------------------------
**************************************************************************************/

    /**
    * @description Method to get Treaties for selected Program
    * @param Id programId
    * @return List<Treaty__c>
    */
    @AuraEnabled
    public static List<Treaty__c> getTreaties(Id programId){
        return [
                SELECT Id, Name, Layer__c, WebXLReference__c, toLabel(TypeofTreaty__c), TECH_ProgramName__c, toLabel(Status__c), PlacementShare_Perc__c,TECH_ProgramNature__c
                        ,WordingName__c, WordingName2__c, WordingName3__c, WordingName4__c, Inceptiondate__c, Expirydate__c, Actor_Reference__c, LTA__c
                        ,LTAInceptionDate__c, LTAExpiryDate__c, LTARenegotiation__c, EarlyTerminationDate__c, TacitRenewal__c, Advance_notice__c, TypeofReinsurance__c
                        ,LossAttachment__c, Deductions__c, NotManagedByAgre__c, Deductions_Perc__c, LossDeposit__c, LossDepositMode__c, PremiumDeposit__c
                        ,IsPooled__c, TECH_LTA__c, LTAPattern__c
                FROM Treaty__c
                WHERE Program__c = :programId
                ORDER BY Layer__c //RRA - ticket 1536 - 09062023
        ];
    }

    /**
    * @description Method to get Sections of selected Treaties
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

        //RRA - ticket 1326 - 08052023
        String querySection = 'select Id, Treaty__c, fieldLimit__c, fieldRetention__c, fieldLayer__c, Treaty__r.Layer__c, Treaty__r.IsPooled__c, TECH_ProgramName__c, TECH_TreatyName__c, TECH_RelatedSectionNumber__c, toLabel(Status__c), toLabel(Currency__c), '
            + strSectionFields
            + ' from Section__c where (Treaty__c IN :lstSelectedTreaties) '
            + 'order by Treaty__r.Layer__c, Sort_SectionNumber__c';//RRA - ticket 1536 / 1540 - 09062023
        List<Section__c> lstSections = Database.query(querySection);

        return lstSections;
    }




    public static List<Decimal> sortingDecimalValue(list<Decimal> lstSort)         
    {
        List<Integer> lstAfterComma = new List<Integer>();
        List<Integer> lstBeforeComma = new List<Integer>();
        List<Decimal> lstSortNew = new List<Decimal>();
        Decimal sectionNumber;
        String sectionNumberToStringInit;
        String strlstSort;
        List<String> partslstSort;
        Integer beforeComma;
        Integer afterComma;

        for (Decimal secNumb : lstSort){
            strlstSort = String.valueOf(secNumb); 
            partslstSort = strlstSort.split('\\.'); 
            beforeComma = Integer.valueOf(partslstSort[0]); 
            afterComma =Integer.valueOf(partslstSort[1]); 
            lstAfterComma.add(afterComma);
            lstBeforeComma.add(beforeComma);
        }
        Decimal len = lstAfterComma.size();
        lstAfterComma.sort();
        for (Integer afterDec : lstAfterComma){
            sectionNumberToStringInit = String.valueOf(beforeComma + '.' + afterDec);
            sectionNumber = Decimal.valueOf(sectionNumberToStringInit);
               lstSortNew.add(sectionNumber);
        }
        System.debug('lstSortNew == ' + lstSortNew);
        return lstSortNew;
    }



    /**
    * @description Method to save Renewed Program
    * @param Id programId, String renewProgramName, String uwYear, List<Id> lstSelectedTreatiesId, List<Id> lstSelectedSectionsId, Date expiryDate, Boolean displayTreatySection, String typeOfRenew
    * @return Map<String, Object>
    */
    @AuraEnabled
    public static Map<String, Object> saveProgram(Id programId, String renewProgramName, String uwYear, List<Id> lstSelectedTreatiesId, List<Id> lstSelectedSectionsId, Date expiryDate, Boolean displayTreatySection, String typeOfRenew) {
        Map<String, Object> mapResults = new Map<String, Object>();
        Savepoint sp = Database.setSavepoint();
        System.debug('###Begining save Program###');
        System.debug('###displayTreatySection### == '+ displayTreatySection);
        try {
            List<String> lstProgramFields = AP_Constant.getCreatableFieldsByObjName(AP_Constant.sObjectProgram);
            String strProgramFields = String.join(lstProgramFields , ', ');

            List<String> lstTreatyFields = AP_Constant.getCreatableFieldsByObjName(AP_Constant.sObjectTreaty);
            String strTreatyFields = String.join(lstTreatyFields , ', ');

            List<String> lstSectionFields = AP_Constant.getCreatableFieldsByObjName(AP_Constant.sObjectSection);
            String strSectionFields = String.join(lstSectionFields , ', ');

            String queryProgram = 'select Id, PrincipalCedingCompany__c, '
                + strProgramFields
                + ' from Program__c where (Id = :programId) ' ;
            Program__c programOld = Database.query(queryProgram);

            String queryTreaty = 'select Id, Program__c, '
                + strTreatyFields
                + ' from Treaty__c where (Id IN :lstSelectedTreatiesId) ' ;
            List<Treaty__c> lstTreaty = Database.query(queryTreaty);

            String querySection = 'select Id, Treaty__c, Rigth_Section_Number__c, '
                + strSectionFields
                + ' from Section__c where (Id IN :lstSelectedSectionsId) ' ; // RRA - Add Rigth_Section_Number__c field formula to correct sectionNumber on Renew
            List<Section__c> lstSections = Database.query(querySection);

            Map<Id, List<Section__c>> mapLstSectionsByTreatyId = new Map<Id, List<Section__c>>(); //map of list of Sections by Treaty Id

            for(Section__c section : lstSections){
                List<Section__c> lstSectionByTreatyId = new List<Section__c>();
                if(mapLstSectionsByTreatyId.containsKey(section.Treaty__c)){
                    lstSectionByTreatyId = mapLstSectionsByTreatyId.get(section.Treaty__c);
                }
                lstSectionByTreatyId.add(section);
                mapLstSectionsByTreatyId.put(section.Treaty__c, lstSectionByTreatyId);
            }

            System.debug('###mapLstSectionsByTreatyId### ==' + mapLstSectionsByTreatyId);
            /***
            *
            * Copy Renew Program
            *
            */
            Program__c programRenew = programOld.clone(false, false, false, false);
            programRenew.UwYear__c = uwYear;
            programRenew.Name = renewProgramName;
            programRenew.InceptionDate__c = programOld.Expirydate__c.addDays(1); //Expiry Date of the original program + 1 day
            programRenew.TypeOfRenew__c = typeOfRenew;
            programRenew.RenewedFromProgram__c = programId;
            programRenew.TECH_StageName__c = AP_Constant.stageConditions;
            programRenew.TECH_Actor2Id__c = null; //copy program - to set TECH_Actor2Id__c to null

            //Inception Date of new program + 365 days (or 366 days for bissextile year)
            if(Date.isLeapYear(programRenew.InceptionDate__c.year()) && programRenew.InceptionDate__c.month() <= 2){
                programRenew.Expirydate__c = programRenew.InceptionDate__c.addDays(365);
            }
            else{
                programRenew.Expirydate__c = programRenew.InceptionDate__c.addDays(364);
            }

            System.debug('###typeOfRenew### ==' + typeOfRenew);

            if(typeOfRenew == 'LTA/TR Identical Renew' || typeOfRenew == 'LTA/TR Renegotiation'){
                //Original advanced notice + 1 year if TR = Yes
                if(programOld.TacitRenewal__c == '1'){
                    if(Date.isLeapYear(programOld.AdvanceNotice__c.year())){
                        programRenew.AdvanceNotice__c = programOld.AdvanceNotice__c.addDays(366); //bissextile/leap year: 366 days
                    }
                    else{
                        programRenew.AdvanceNotice__c = programOld.AdvanceNotice__c.addDays(365); //common year: 365 days
                    }
                }
            }

            if(typeOfRenew == 'Standard Renew'){
                programRenew.AdvanceNotice__c = null;
                programRenew.EarlyTerminationDate__c = null;
                programRenew.LTAExpiryDate__c = null;
                programRenew.LTAInceptionDate__c = null;
                programRenew.LTAPattern__c = null;
                programRenew.LTARenegociation__c = null;
                programRenew.TRInceptionDate__c = null;
                programRenew.LTA__c = '2';
                programRenew.TacitRenewal__c = '2';
                programRenew.TECH_ShowClosePreviousPhaseBtn__c = '1';
            }
            else if(typeOfRenew == 'LTA/TR Identical Renew'){
                programRenew.EarlyTerminationDate__c = null;
                programRenew.LTARenegociation__c = '2';
            }
            else if(typeOfRenew == 'LTA/TR Renegotiation'){
                programRenew.EarlyTerminationDate__c = null;
                programRenew.LTA__c = '2';
                programRenew.LTAExpiryDate__c = null;
                programRenew.LTAPattern__c = null;
                programRenew.LTARenegociation__c = '2';
                programRenew.TacitRenewal__c = '2';
                programRenew.LTAInceptionDate__c = programRenew.InceptionDate__c;
                programRenew.TRInceptionDate__c = programRenew.InceptionDate__c; //Inception Date of the new program
                programRenew.TECH_ShowClosePreviousPhaseBtn__c = '1';
            }

            //AMI 01/06/22 : W-0941
            //compare loss deposit against original program
            //if "no" selected in original program, clear loss deposit level on renew
            //if "yes", it will automatically by taken into account during clone
            if(programOld.LossDeposit__c == '2'){
                programRenew.LossDepositLevel__c = null;
            }
            System.debug('### MRA ==' + programRenew.SigningPremiumCurrency__c);
            if(programRenew != null){
                insert programRenew;
            }
            mapResults.put('programRenew',programRenew);

            System.debug('###mapResults### ==' + mapResults);

            /***
            *
            * Copy Covered Ceding Company on Renew Program
            *
            */
            List<String> lstCoveredCedCompFields = AP_Constant.getCreatableFieldsByObjName(AP_Constant.sObjCoveredCedingComp);
            String strCoveredCedCompFields = String.join(lstCoveredCedCompFields , ', ');
            String queryCoveredCedComp = 'select Id, Program__c, Account__c,  '
                + strCoveredCedCompFields
                + ' from CoveredCedingCompany__c where (Program__c = :programId) '
                + 'and (ProgramIsSelected__c = true) and (Account__r.IsActive__c = TRUE)';

            List<CoveredCedingCompany__c> lstCoveredCedCompProgram = Database.query(queryCoveredCedComp);
            List<CoveredCedingCompany__c> lstCoveredCedCompRenewProgram = new List<CoveredCedingCompany__c>();

            for(CoveredCedingCompany__c covCedCom : lstCoveredCedCompProgram){
                CoveredCedingCompany__c covCedComRenew = new CoveredCedingCompany__c();
                covCedComRenew.Account__c = covCedCom.Account__c;
                covCedComRenew.Program__c = programRenew.Id;
                covCedComRenew.ProgramIsSelected__c = true;
                lstCoveredCedCompRenewProgram.add(covCedComRenew);
            }

            if(lstCoveredCedCompRenewProgram.size() > 0){
                insert lstCoveredCedCompRenewProgram;
            }

            System.debug('###lstCoveredCedCompRenewProgram### ==' + lstCoveredCedCompRenewProgram);

            /***
            *
            * Copy Treaty
            *
            */
            List<Treaty__c> lstRenewTreaty = new List<Treaty__c>();

            for(Integer i = 0; i < lstTreaty.size(); i ++){
                Treaty__c oldTreaty = lstTreaty[i];
                Treaty__c renewTreaty = oldTreaty.clone(false, false, false, false);
                renewTreaty.Program__c = programRenew.Id;
                renewTreaty.TECH_OldTreatyId__c = oldTreaty.Id;
                renewTreaty.TECH_Actor2Id__c = null;

                renewTreaty.Advance_notice__c = programRenew.AdvanceNotice__c;
                renewTreaty.EarlyTerminationDate__c = null;
                renewTreaty.Expirydate__c = programRenew.Expirydate__c;
                renewTreaty.Inceptiondate__c = programRenew.InceptionDate__c;
                renewTreaty.LTA__c = programRenew.LTA__c;
                renewTreaty.LTAExpiryDate__c = programRenew.LTAExpiryDate__c;
                renewTreaty.LTAInceptionDate__c = programRenew.LTAInceptionDate__c;
                renewTreaty.LTAPattern__c = programRenew.LTAPattern__c;
                renewTreaty.LTARenegotiation__c = programRenew.LTARenegociation__c;
                renewTreaty.TECH_RenewedFromTreaty__c = oldTreaty.Id;// AZR - 1124

                //Premium deposit remains non fillable for treaty type SL and XL
                if(renewTreaty.TypeofTreaty__c == '1' || renewTreaty.TypeofTreaty__c == '2'){
                    //SL or XL - Premium deposit remains non fillable for treaty type SL and XL
                    renewTreaty.PremiumDeposit__c = null;
                }
                renewTreaty.TacitRenewal__c = programRenew.TacitRenewal__c;

                //YEAR of Renewal Program + original reference w/o the Year
                String ref = oldTreaty.TreatyReference__c.split('-')[1];
                renewTreaty.TreatyReference__c = uwYear + '-' + ref;

                //YEAR of Renewal Program + original reference w/o the Year + second part?
                renewTreaty.WebXLReference__c = uwYear + '-' + ref;

                String actorRef = oldTreaty.Actor_Reference__c.split('-')[1];
                renewTreaty.Actor_Reference__c = uwYear + '-' + actorRef;

                lstRenewTreaty.add(renewTreaty);
            }

            if(lstRenewTreaty.size() > 0){
                insert lstRenewTreaty;
            }
            System.debug('###lstRenewTreaty.SIZE### ==' + lstRenewTreaty.size());
            System.debug('###lstRenewTreaty### ==' + lstRenewTreaty);

            /***
            *
            * Copy Covered Ceding Company on Treaty
            *
            */
            List<String> lstCoveredCedCompFieldsTreaty = AP_Constant.getCreatableFieldsByObjName(AP_Constant.sObjCoveredCedingComp);
            String strCoveredCedCompFieldsTreaty = String.join(lstCoveredCedCompFieldsTreaty , ', ');
            String queryCoveredCedCompTreaty = 'select Id, Program__c, Account__c,  '
                + strCoveredCedCompFieldsTreaty
                + ' from CoveredCedingCompany__c where (Program__c = :programId) '
                + 'and (TreatyIsSelected__c = true ) '
                + 'and (Treaty__c IN :lstSelectedTreatiesId) and (Account__r.IsActive__c = TRUE)';

            List<CoveredCedingCompany__c> lstCoveredCedCompTreaty = Database.query(queryCoveredCedCompTreaty);

            //Build map Covered Ceding Company (TreatyId, List CoveredCedingCompany)
            Map<Id, List<CoveredCedingCompany__c>> mapCoveredCedCompByTreaty = new Map<Id, List<CoveredCedingCompany__c>>();

            for(CoveredCedingCompany__c covCedComp : lstCoveredCedCompTreaty){
                List<CoveredCedingCompany__c> lstCov = new List<CoveredCedingCompany__c>();
                if(mapCoveredCedCompByTreaty.containsKey(covCedComp.Treaty__c)){
                    lstCov = mapCoveredCedCompByTreaty.get(covCedComp.Treaty__c);
                    lstCov.add(covCedComp);
                    mapCoveredCedCompByTreaty.put(covCedComp.Treaty__c, lstCov);
                }
                else{
                    lstCov.add(covCedComp);
                    mapCoveredCedCompByTreaty.put(covCedComp.Treaty__c, lstCov);
                }
            }

            System.debug('###mapCoveredCedCompByTreaty### ==' + mapCoveredCedCompByTreaty);

            List<CoveredCedingCompany__c> lstRenewCoveredCedingCompanies = new List<CoveredCedingCompany__c>();

            for(Treaty__c renewTreaty : lstRenewTreaty){
                List<CoveredCedingCompany__c> lstCoveredCedingCompanies = new List<CoveredCedingCompany__c>();

                if(mapCoveredCedCompByTreaty.containsKey(renewTreaty.TECH_OldTreatyId__c)){
                    lstCoveredCedingCompanies = mapCoveredCedCompByTreaty.get(renewTreaty.TECH_OldTreatyId__c);
                }

                for(CoveredCedingCompany__c cov : lstCoveredCedingCompanies){
                    CoveredCedingCompany__c newCov = cov.clone(false, false, false, false);
                    newCov.Program__c = programRenew.Id;
                    newCov.Treaty__c = renewTreaty.Id;
                    newCov.TreatyIsSelected__c = true;
                    newCov.EPI__c = 0;
                    lstRenewCoveredCedingCompanies.add(newCov);
                }
            }

            if(lstRenewCoveredCedingCompanies.size() > 0){
                insert lstRenewCoveredCedingCompanies;
            }

            System.debug('###lstRenewCoveredCedingCompanies### ==' + lstRenewCoveredCedingCompanies);

            /***
            *
            * Copy Pool on Treaty
            *
            */
            List<String> lstPoolTreatyFields = AP_Constant.getCreatableFieldsByObjName(AP_Constant.sObjPoolTreatySection);
            String strPoolTreatyFields  = String.join(lstPoolTreatyFields , ', ');
            String queryPoolTreaty = 'select Id, '
                + strPoolTreatyFields
                + ' from PoolTreatySection__c where (Treaty__c IN :lstSelectedTreatiesId) '
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

            System.debug('###mapPoolTreaty### ==' + mapPoolTreaty);

            List<PoolTreatySection__c> lstRenewPoolTreaty = new List<PoolTreatySection__c>();

            for(Treaty__c renewTreaty : lstRenewTreaty){
                List<PoolTreatySection__c> lstPoolTreaties = new List<PoolTreatySection__c>();
                if(mapPoolTreaty.containsKey(renewTreaty.TECH_OldTreatyId__c)){
                    lstPoolTreaties = mapPoolTreaty.get(renewTreaty.TECH_OldTreatyId__c);
                }

                for(PoolTreatySection__c poolTreaty : lstPoolTreaties){
                    PoolTreatySection__c newPoolTreaty = poolTreaty.clone(false, false, false, false);
                    newPoolTreaty.Treaty__c = renewTreaty.Id;
                    lstRenewPoolTreaty.add(newPoolTreaty);
                }
            }

            if(lstRenewPoolTreaty.size() > 0){
                insert lstRenewPoolTreaty;
            }

            System.debug('###lstRenewPoolTreaty### ==' + lstRenewPoolTreaty);

            /***
            *
            * Copy Section
            *
            */
            List<Section__c> lstRenewSection = new List<Section__c>();
            List<Section__c> lstNewOptRenewSections = new List<Section__c>();
            Map<Id, Section__c> mapOldSecdToNewSection = new Map<Id, Section__c>();
            Set<Id> setTreatyId = new  Set<Id>();
            for(Treaty__c renewTreaty : lstRenewTreaty){
                setTreatyId.add(renewTreaty.Id);  // RRA - corrects and recalculates the number section when renewing a program 08/06/2022
                List<Section__c> lstSectionByOldTreatyId = new List<Section__c>();
                Decimal sectionNumber = 0.1;
                if(mapLstSectionsByTreatyId.containsKey(renewTreaty.TECH_OldTreatyId__c)){
                    lstSectionByOldTreatyId = mapLstSectionsByTreatyId.get(renewTreaty.TECH_OldTreatyId__c);
                }

                for(Section__c section : lstSectionByOldTreatyId){
                    Section__c newSection = section.clone(false, false, false, false);
                    newSection.Program__c = programRenew.Id;
                    newSection.Treaty__c = renewTreaty.Id;
                    newSection.TECH_OldSectionId__c = section.Id;
                    newSection.MethodOfDistributionOfThePremium__c = 'EPI prorata';
                    newSection.TotalEPI__c = 0;
                    newSection.Number_of_subsections__c = 0; //RRA - ticket 1673 - 03102023
                    newSection.Status__c = '1'; // all renewed sections are active by default
                    newSection.TECH_Actor2Id__c = null;

                    //MBE: 22/03/2021 - W-0875 - Renew - Renewed from section option
                    
                    newSection.TECH_RenewedSection_ID__c = section.Id; //lookup
                    newSection.RenewedFromSectionOption__c = section.SectionNumber__c + ' - ' + section.Name; //section number - section name of old section
                    newSection.Tech_OriginalSectionId__c = section.Id; //lookup

                    if(displayTreatySection == true){
                        newSection.Retained_to_lead__c = false;
                    }

                    if(newSection.RelatedSection__c != null){
                        lstNewOptRenewSections.add(newSection);
                    }
                    else{
                        //sectionNumber = sectionNumber + 1.0; //RRA - 1276 - comment this line to correct incrementation of Section Number
                        //newSection.SectionNumber__c = String.valueOf(sectionNumber); //RRA - 1276 - comment this line to correct incrementation of Section Number
                        mapOldSecdToNewSection.put(section.Id, newSection);
                        lstRenewSection.add(newSection);
                    }
                }
            }

            if(lstRenewSection.size() > 0){
                insert lstRenewSection;
            }

            //Add related sections
            Map<Id, Decimal> mapSectionOptionNumByParentRenewSection = new Map<Id, Decimal>();
            Decimal newValueSectionOptNum;
            for(Section__c section : lstNewOptRenewSections){
                Id newSectionId = mapOldSecdToNewSection.get(section.RelatedSection__c).Id;
                Decimal sectionOptionNum = Decimal.valueOf(mapOldSecdToNewSection.get(section.RelatedSection__c).SectionNumber__c);

                if(mapSectionOptionNumByParentRenewSection.containsKey(newSectionId)){
                    sectionOptionNum = mapSectionOptionNumByParentRenewSection.get(newSectionId);
                }

                //sectionOptionNum = sectionOptionNum + 0.1;//RRA - 1276 - comment this line to correct incrementation of Section Number

                //mapSectionOptionNumByParentRenewSection.put(newSectionId, sectionOptionNum); 
                //section.SectionNumber__c = String.valueOf(sectionOptionNum); //RRA - 1276 - comment this line to correct incrementation of Section Number
                section.RelatedSection__c = newSectionId;

                if(displayTreatySection == true){
                    section.Retained_to_lead__c = false;
                }
            }


            if(lstNewOptRenewSections.size() > 0){
                insert lstNewOptRenewSections;
                lstRenewSection.addAll(lstNewOptRenewSections);
            }

            System.debug('###lstNewOptRenewSections### ==' + lstNewOptRenewSections);
            System.debug('###lstRenewSection### ==' + lstRenewSection);

            // RRA - corrects and recalculates the number section when renewing a program 08/06/2022
            //LWC01_HomePageActions.recalculateSectionNumbers(setTreatyId);
             //List<Decimal> lstDecValue = LWC01_HomePageActions.recalculateSectionNumbersDecimal(setTreatyId);
             //lstDecValue.sort();

            // mapResults.put('lstDecValue', lstDecValue);

            //LWC01_NewSection.selectionSortingNoReturnValue (lstDecValue, 'Sort by DecimalValue');

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
                + 'and (SectionIsSelected__c = true ) and (Account__r.IsActive__c = TRUE)';
            List<CoveredCedingCompany__c> lstCoveredCedCompSection = Database.query(queryCoveredCedCompSection);
            Map<Id, List<CoveredCedingCompany__c>> mapCoveredCedCompSection = new Map<Id, List<CoveredCedingCompany__c>>(); //Build map Covered Ceding Company for section (SectionId, List<CoveredCedingCompany__c)

            for(CoveredCedingCompany__c covCedCom : lstCoveredCedCompSection){
                List<CoveredCedingCompany__c> lstCov = new List<CoveredCedingCompany__c>();
                if(mapCoveredCedCompSection.containsKey(covCedCom.Section__c)){
                    lstCov = mapCoveredCedCompSection.get(covCedCom.Section__c);
                }
                lstCov.add(covCedCom);
                mapCoveredCedCompSection.put(covCedCom.Section__c, lstCov);
            }

            System.debug('###mapCoveredCedCompSection### ==' + mapCoveredCedCompSection);

            List<CoveredCedingCompany__c> lstRenewCoveredCedCompSection = new List<CoveredCedingCompany__c>();

            for(Section__c section : lstRenewSection){
                List<CoveredCedingCompany__c> lstCoveredCedingCompanies = new List<CoveredCedingCompany__c>();
                if(mapCoveredCedCompSection.containsKey(section.TECH_OldSectionId__c)){
                    lstCoveredCedingCompanies = mapCoveredCedCompSection.get(section.TECH_OldSectionId__c);
                }
                for(CoveredCedingCompany__c cov : lstCoveredCedingCompanies){
                    CoveredCedingCompany__c newCov = cov.clone(false, false, false, false);
                    newCov.Program__c = programRenew.Id;
                    newCov.Treaty__c = section.Treaty__c;
                    newCov.Section__c = section.Id;
                    newCov.EPI__c = 0;
                    newCov.AllocationKey__c = 100 / lstCoveredCedingCompanies.size();
                    lstRenewCoveredCedCompSection.add(newCov);
                }
            }

            if(lstRenewCoveredCedCompSection.size() > 0){
                insert lstRenewCoveredCedCompSection;
            }
            System.debug('###lstRenewCoveredCedCompSection### ==' + lstRenewCoveredCedCompSection);

            /***
            *
            * Copy Pool on Section
            *
            */
            List<String> lstPoolSectionFields = AP_Constant.getCreatableFieldsByObjName(AP_Constant.sObjPoolTreatySection);
            String strPoolSectionFields  = String.join(lstPoolSectionFields , ', ');
            String queryPoolSection = 'select Id, '
                + strPoolSectionFields
                + ' from PoolTreatySection__c where (Section__c IN :lstSelectedSectionsId) '
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

            List<PoolTreatySection__c> lstRenewPoolSection = new List<PoolTreatySection__c>();

            for(Section__c renewSection : lstRenewSection){
                List<PoolTreatySection__c> lstPoolSections = new List<PoolTreatySection__c>();
                if(mapPoolSection.containsKey(renewSection.TECH_OldSectionId__c)){
                    lstPoolSections = mapPoolSection.get(renewSection.TECH_OldSectionId__c);
                }
                
                for(PoolTreatySection__c poolSection : lstPoolSections){
                    PoolTreatySection__c newPoolSection = poolSection.clone(false, false, false, false);
                    newPoolSection.Section__c = renewSection.Id;
                    newPoolSection.Treaty__c = renewSection.Treaty__c;
                    newPoolSection.SectionEpiCededToPool__c = 0;
                    lstRenewPoolSection.add(newPoolSection);
                }
            }
            if(lstRenewPoolSection.size() > 0){
                insert lstRenewPoolSection;
            }

            System.debug('###lstRenewPoolSection### ==' + lstRenewPoolSection);

            /***
            *
            * Copy Reinstatement on Section
            *
            */
            List<String> lstReinstatementFields = AP_Constant.getCreatableFieldsByObjName(AP_Constant.sObjectReinstatement);
            String strReinstatementFields = String.join(lstReinstatementFields , ', ');
            String queryReinstatement = 'select Id,  '
                + strReinstatementFields
                + ' from Reinstatement__c where (Section__c IN :lstSelectedSectionsId) ';
            List<Reinstatement__c> lstReinstatements = Database.query(queryReinstatement);
            Map<Id, List<Reinstatement__c>> mapReinstatement = new Map<Id, List<Reinstatement__c>>();//Build map Reinstatements (SectionId, List Reinstatement)

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

            System.debug('###mapReinstatement### ==' + mapReinstatement);

            List<Reinstatement__c> lstRenewReinstatement = new List<Reinstatement__c>();

            for(Section__c section : lstRenewSection){
                List<Reinstatement__c> lstReins = new List<Reinstatement__c>();
                if(mapReinstatement.containsKey(section.TECH_OldSectionId__c)){
                    lstReins = mapReinstatement.get(section.TECH_OldSectionId__c);
                }

                for(Reinstatement__c reinstatement : lstReins) {
                    Reinstatement__c newReinstatement = reinstatement.clone(false, false, false, false);
                    newReinstatement.Section__c = section.Id;
                    newReinstatement.TECH_Actor2Id__c = null;
                    lstRenewReinstatement.add(newReinstatement);
                }
            }

            if(lstRenewReinstatement.size() > 0){
                insert lstRenewReinstatement;
            }
            System.debug('###lstRenewReinstatement### ==' + lstRenewReinstatement);

            System.debug('###displayTreatySection### ==' + displayTreatySection);

            if(displayTreatySection == false){

                /***
                *
                * Copy Quote/Lead/Placement request
                *
                */
                Map<String, Id> mapRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectRequest});
                String recordQuoteTypeId = mapRecTypeId.get(AP_Constant.reqRTQuote);
                String recordLeadTypeId = mapRecTypeId.get(AP_Constant.reqRTLead);
                String recordPlacementTypeId = mapRecTypeId.get(AP_Constant.reqRTPlacement);
                String recordSigningTypeId = mapRecTypeId.get(AP_Constant.reqRTSigning);
                List<String> lstRequestFields = AP_Constant.getCreatableFieldsByObjName(AP_Constant.sObjectRequest);
                String strRequestFields = String.join(lstRequestFields , ', ');
                String queryRequest = 'select Id,  '
                    + strRequestFields
                    + ' from Request__c where (Program__c = :programId) ';

                //create map of treaty old, treaty new from list of treaty of renew program
                //create map of section old, section new from list of section of renew program
                Map<Id, Id> mapRenewTreatyIdByOldTreaty = new Map<Id, Id>();
                Map<Id, Id> mapRenewSectionIdByOldSection = new Map<Id, Id>();

                for(Treaty__c renewTreaty : [SELECT Id, TECH_OldTreatyId__c FROM Treaty__c WHERE Program__c = :programRenew.Id]){
                    mapRenewTreatyIdByOldTreaty.put(renewTreaty.TECH_OldTreatyId__c, renewTreaty.Id);
                }

                for(Section__c renewSection : [SELECT Id, TECH_OldSectionId__c FROM Section__c WHERE Program__c = :programRenew.Id]){
                    mapRenewSectionIdByOldSection.put(renewSection.TECH_OldSectionId__c, renewSection.Id);
                }

                String queryQuotePlacementRequest = queryRequest + ' AND (RecordTypeId = :recordQuoteTypeId OR RecordTypeId = :recordPlacementTypeId OR RecordTypeId = :recordSigningTypeId )';
                String queryLeadRequest = queryRequest + ' AND RecordTypeId = :recordLeadTypeId';
                List<Request__c> lstQuotePlacementRequest = Database.query(queryQuotePlacementRequest);
                List<Request__c> lstLeadRequest = Database.query(queryLeadRequest);
                List<Request__c> lstQuotePlacementRequestToInsert = new List<Request__c>();
                List<Request__c> lstLeadRequestToInsert = new List<Request__c>();
                Set<Id> setLeadParentRequest = new Set<Id>();

                System.debug('###lstQuotePlacementRequest### ==' + lstQuotePlacementRequest);

                for(Request__c oldRequest : lstQuotePlacementRequest){
                    if (oldRequest.OriginalRequest__c == null){ //RRA - 1315 24/10/2022
                        if(oldRequest.RecordTypeId == recordQuoteTypeId && mapRenewTreatyIdByOldTreaty.containsKey(oldRequest.Treaty__c) && mapRenewSectionIdByOldSection.containsKey(oldRequest.Section__c)){
                            Request__c newRequest = oldRequest.clone(false, false, false, false);
                            newRequest.Program__c = programRenew.Id;
                            newRequest.Treaty__c = mapRenewTreatyIdByOldTreaty.get(oldRequest.Treaty__c);
                            newRequest.Section__c = mapRenewSectionIdByOldSection.get(oldRequest.Section__c);
                            newRequest.RecordTypeId = recordQuoteTypeId;
                            newRequest.TECH_Actor2Id__c = null;
                            newRequest.LastVersionSent__c = true;  //RRA - 1315 24/10/2022
                            newRequest.LastVersionAnswered__c = true;  //RRA - 1315 24/10/2022
                            lstQuotePlacementRequestToInsert.add(newRequest);  
                    }
                        else if(oldRequest.RecordTypeId == recordPlacementTypeId && mapRenewTreatyIdByOldTreaty.containsKey(oldRequest.Treaty__c)){
                            Request__c newRequest = oldRequest.clone(false, false, false, false);
                            newRequest.Program__c = programRenew.Id;
                            newRequest.Treaty__c = mapRenewTreatyIdByOldTreaty.get(oldRequest.Treaty__c);
                            newRequest.RecordTypeId = recordPlacementTypeId;
                            newRequest.TECH_Actor2Id__c = null;
                            newRequest.LastVersionSent__c = true;  //RRA - 1315 24/10/2022
                            newRequest.LastVersionAnswered__c = true;  //RRA - 1315 24/10/2022
                            lstQuotePlacementRequestToInsert.add(newRequest);
                        }
                        else if(oldRequest.RecordTypeId == recordSigningTypeId && mapRenewTreatyIdByOldTreaty.containsKey(oldRequest.Treaty__c)){
                            Request__c newRequest = oldRequest.clone(false, false, false, false);
                            newRequest.Program__c = programRenew.Id;
                            newRequest.Treaty__c = mapRenewTreatyIdByOldTreaty.get(oldRequest.Treaty__c);
                            newRequest.RecordTypeId = recordSigningTypeId;
                            newRequest.TECH_Actor2Id__c = null;
                            newRequest.LastVersionSent__c = true;  //RRA - 1315 24/10/2022
                            newRequest.LastVersionAnswered__c = true;  //RRA - 1315 24/10/2022
                            lstQuotePlacementRequestToInsert.add(newRequest);
                        }
                    }
                    
                }

                System.debug('###lstLeadRequest### ==' + lstLeadRequest);

                for(Request__c oldRequest : lstLeadRequest){
                    if (oldRequest.OriginalRequest__c == null){  //RRA - 1315 24/10/2022
                        if(mapRenewTreatyIdByOldTreaty.containsKey(oldRequest.Treaty__c)){
                            if(oldRequest.Reinsurer__c == null){
                                if(mapRenewSectionIdByOldSection.containsKey(oldRequest.Section__c)){
                                    Request__c newChildRequest = oldRequest.clone(false, false, false, false);
                                    newChildRequest.Program__c = programRenew.Id;
                                    newChildRequest.Treaty__c = mapRenewTreatyIdByOldTreaty.get(oldRequest.Treaty__c);
                                    newChildRequest.Section__c = mapRenewSectionIdByOldSection.get(oldRequest.Section__c);
                                    newChildRequest.RecordTypeId = recordLeadTypeId;
                                    newChildRequest.TECH_OldRequestId__c = oldRequest.Id;
                                    newChildRequest.TECH_Actor2Id__c = null;
                                    newChildRequest.LastVersionSent__c = true;  //RRA - 1315 24/10/2022
                                    newChildRequest.LastVersionAnswered__c = true;  //RRA - 1315 24/10/2022
                                    lstLeadRequestToInsert.add(newChildRequest);
                                }
                            }
                            else{
                                Request__c newParentRequest = oldRequest.clone(false, false, false, false);
                                newParentRequest.Program__c = programRenew.Id;
                                newParentRequest.Treaty__c = mapRenewTreatyIdByOldTreaty.get(oldRequest.Treaty__c);
                                newParentRequest.RecordTypeId = recordLeadTypeId;
                                newParentRequest.TECH_OldRequestId__c = oldRequest.Id;
                                newParentRequest.TECH_Actor2Id__c = null;
                                newParentRequest.LastVersionSent__c = true;
                                newParentRequest.LastVersionAnswered__c = true;
                                setLeadParentRequest.add(oldRequest.Id);
                                lstLeadRequestToInsert.add(newParentRequest);
                            }
                        }
                    }
                }

                if(lstLeadRequestToInsert.size() > 0) {
                    insert lstLeadRequestToInsert;
                }

                System.debug('###lstLeadRequestToInsert### ==' + lstLeadRequestToInsert);

                Map<Id, Id> mapNewRequestIdByOldRequest = new Map<Id, Id>();

                for(Request__c newLeadRequest : lstLeadRequestToInsert){
                    mapNewRequestIdByOldRequest.put(newLeadRequest.TECH_OldRequestId__c, newLeadRequest.Id);
                }

                List<LeadRequestSelection__c> lstNewLeadRequestSelectionToInsert = new List<LeadRequestSelection__c>();

                for(LeadRequestSelection__c leadRequestSelection:  [SELECT Id, LeadRequestChild__c, LeadRequestParent__c, Treaty__c FROM LeadRequestSelection__c WHERE LeadRequestParent__c IN :setLeadParentRequest]){
                    if(mapNewRequestIdByOldRequest.containsKey(leadRequestSelection.LeadRequestParent__c) && mapNewRequestIdByOldRequest.containsKey(leadRequestSelection.LeadRequestChild__c)){
                        LeadRequestSelection__c newLeadRequestSelection = leadRequestSelection.clone(false,false,false,false);
                        newLeadRequestSelection.LeadRequestChild__c = mapNewRequestIdByOldRequest.get(leadRequestSelection.LeadRequestChild__c);
                        newLeadRequestSelection.LeadRequestParent__c = mapNewRequestIdByOldRequest.get(leadRequestSelection.LeadRequestParent__c);
                        lstNewLeadRequestSelectionToInsert.add(newLeadRequestSelection);
                    }
                }

                if(lstNewLeadRequestSelectionToInsert.size() > 0) {
                    insert lstNewLeadRequestSelectionToInsert;
                }

                System.debug('###lstNewLeadRequestSelectionToInsert### ==' + lstNewLeadRequestSelectionToInsert);

                if(lstQuotePlacementRequestToInsert.size() > 0){
                    insert lstQuotePlacementRequestToInsert;
                }

                System.debug('###programRenew.Id### ==' + programRenew.Id);
                System.debug('###lstQuotePlacementRequestToInsert### ==' + lstQuotePlacementRequestToInsert);
            }

            mapResults.put('displayTreatySection', displayTreatySection);
            mapResults.put('Success', 'Success');
        }
        catch (Exception ex) {
            mapResults.put('Error', ex.getMessage());
            Database.rollback(sp);
        }
        return mapResults;
    }
}