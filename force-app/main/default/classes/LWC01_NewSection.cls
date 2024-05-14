public without sharing class LWC01_NewSection {
    /**************************************************************************************
    -- - Author        : Spoon Consulting
    -- - Description   : Controller for Lightning Web Component lwc01NewSection
    --
    -- Maintenance History:
    --
    -- Date         Name  Version  Remarks
    -- -----------  ----  -------  -------------------------------------------------------
    -- 04-NOV-2019  MBE   1.0      Initial version
    -- 02-SEP-2020  SAU   1.1      When Inclusion/Exclusion = No, related checkboxes should be false
    -- 21-DEC-2020  NBI   1.2      Do not retain to lead when copying Section/Option - W-0786
    -- 22-MAR-2021  MBE   1.3      W-0875 - Renew - Renewed from section option
    -- 08-JUL-2021  NBI   1.4      W-0992: Third Party Management		
    -- 13-OCT-2021  MBE   1.5      W-1035 - Production - Demande d'analyse du comportement des pools de la section suite à un renouvellement																								   
    --------------------------------------------------------------------------------------
    **************************************************************************************/
    
        /**
        * @description Method to create and edit Section
        * @param Section__c objectSection, List<CoveredCedingCompany__c> lstCovCedCom, List<Reinstatement__c> lstReinstatement, Boolean editSection, Id selectedSectionId, Boolean createPageSection, Boolean isPooledValue, List<PoolTreatySection__c> lstPool
        * @return Map<String, Object>
        */
        @AuraEnabled
        public static Map<String, Object> saveSectionRecord(Section__c objectSection, List<CoveredCedingCompany__c> lstCovCedCom, List<Reinstatement__c> lstReinstatement, Boolean editSection, Id selectedSectionId, Boolean createPageSection, Boolean isPooledValue, List<PoolTreatySection__c> lstPool) {
            Map<String, Object> mapResults = new Map<String, Object>();
            try {
                if(editSection == false){
                    if(objectSection != null){
                        objectSection.Retained_to_lead__c = false;
                        insert objectSection;
                    }
    
                    List<CoveredCedingCompany__c> lstInsCovCedCom = new List<CoveredCedingCompany__c>();
                    for(CoveredCedingCompany__c covCedCom : lstCovCedCom){
                        covCedCom.Program__c = objectSection.Program__c;
                        covCedCom.Treaty__c = objectSection.Treaty__c;
                        covCedCom.Section__c = objectSection.Id;
                        covCedCom.SectionIsSelected__c = true;
                        lstInsCovCedCom.add(covCedCom);
                    }
    
                    if (lstInsCovCedCom.size() > 0){
                        insert lstInsCovCedCom;
                    }
    
                    for(Reinstatement__c reinstatement : lstReinstatement){
                        reinstatement.Section__c = objectSection.Id;
                    }
    
                    if (lstReinstatement.size() > 0){
                        insert lstReinstatement;
                    }
    
                    if(isPooledValue == true){
                        for(PoolTreatySection__c poolTreatySection : lstPool){
                            poolTreatySection.Id = null;
                            poolTreatySection.Treaty__c = objectSection.Treaty__c;
                            poolTreatySection.Section__c = objectSection.Id;
                            poolTreatySection.SectionIsSelected__c = true;
                            poolTreatySection.TreatyIsSelected__c = false;
                        }
    
                        if(lstPool.size() > 0){
                            insert lstPool;
                        }
                    }
                }
                else{
                    map <String, Id> mapIdPoolTreatySecIdSec = new map <String, Id>();
                    //SAU -- clear Exclusion and inclusion
                    if(objectSection.InclusionOfCatastrophicGuarantees__c == '2'){
                        objectSection.Incl_Earthquake__c = false;
                        objectSection.isNoSubSection__c = false;//RRA - 1802
                        objectSection.Incl_Terrorism__c = false;
                        objectSection.Incl_Flood__c = false;
                        objectSection.Incl_SRCC__c = false;
                        objectSection.Incl_Hurricane__c = false;
                        objectSection.Incl_Others__c = false;
                        objectSection.Incl_OtherRisks__c = false;
                        objectSection.Incl_All__c = false;
                    }
                    if(objectSection.ExclusionOfCatastrophicGuarantees__c == '2'){
                        objectSection.Excl_War__c = false;
                        objectSection.Excl_NuclearRisks__c = false;
                        objectSection.Excl_Terrorism__c = false;
                        objectSection.Excl_Biological__c = false;
                        objectSection.Excl_NuclearBiological__c = false;
                        objectSection.Excl_Others__c = false;
                        objectSection.Excl_Epidemic__c = false;
                        objectSection.Excl_All__c = false;
                    }
    
                    if(objectSection != null){
                        objectSection.Id = selectedSectionId;
                        objectSection.SuccessErrorToastMessageOnFlow__c = 'Section Updated Successfully.';
                        update objectSection;
                    }
    
                    List<CoveredCedingCompany__c> lstDeleteCovCedCom = [SELECT Id
                                                                        FROM CoveredCedingCompany__c
                                                                        WHERE Section__c = :selectedSectionId
                                                                        AND SectionIsSelected__c = TRUE];
                    if (lstDeleteCovCedCom.size() > 0) {
                        delete lstDeleteCovCedCom;
                    }
    
                    List<CoveredCedingCompany__c> lstInsCovCedCom = new List<CoveredCedingCompany__c>();
                    for(CoveredCedingCompany__c covCedCom : lstCovCedCom){
                        covCedCom.Program__c = objectSection.Program__c;
                        covCedCom.Treaty__c = objectSection.Treaty__c;
                        covCedCom.Section__c = selectedSectionId;
                        covCedCom.SectionIsSelected__c = true;
                        lstInsCovCedCom.add(covCedCom);
                    }
    
                    if (lstInsCovCedCom.size() > 0){
                        insert lstInsCovCedCom;
                    }
    
                    List<Reinstatement__c> lstDeleteReinstatements = [SELECT Id
                                                                      FROM Reinstatement__c
                                                                      WHERE Section__c = :selectedSectionId AND Key_Insert_Update_Reinstatement__c = NULL];
    
                    if(lstDeleteReinstatements.size() > 0){
                        delete lstDeleteReinstatements;
                    }
    
                    for(Reinstatement__c reinstatement : lstReinstatement){
                        reinstatement.Section__c = objectSection.Id;
                    }
    
                    if (lstReinstatement.size() > 0){
                        insert lstReinstatement;
                    }
    
                    //RRA - ticket 1364 - 26072023 - this line is commented because do not delete record pooltreatySection related in section if it's already created on step Treaty condition
                    /*List<PoolTreatySection__c> lstExistingPoolForSection = [SELECT Id FROM PoolTreatySection__c
                                                                            WHERE Section__c = :selectedSectionId
                                                                            AND SectionIsSelected__c = :TRUE];
    
                    if(lstExistingPoolForSection.size() > 0){
                        delete lstExistingPoolForSection;
                    }*/
                    
                    System.debug('lstPool ==' + lstPool);
    
                    //RRA - ticket 1364 - 26072023 - create map to get Ids pooltreatySection related on Section selected
                    for (PoolTreatySection__c poolTreatySec :[SELECT Id, Section__c, Pool__c, TECH_upsertPoolTreatySection__c FROM PoolTreatySection__c WHERE Section__c =:selectedSectionId]){
                        mapIdPoolTreatySecIdSec.put(poolTreatySec.Pool__c, poolTreatySec.Id);
                    }
                    System.debug('mapIdPoolTreatySecIdSec ==' + mapIdPoolTreatySecIdSec);
                    System.debug('selectedSectionId ==' + selectedSectionId);
    
                    if(isPooledValue == true){
                        //RRA - ticket 1364 - update poolTreatySection related in section in DB from poolTreatySectionin related in section in UI
                       for(PoolTreatySection__c poolTreatySection : lstPool){
                           System.debug('mapIdPoolTreatySecIdSec.get ==' + mapIdPoolTreatySecIdSec.get(poolTreatySection.Pool__c ));
                               poolTreatySection.Id = mapIdPoolTreatySecIdSec.get(poolTreatySection.Pool__c);
                               poolTreatySection.Treaty__c = objectSection.Treaty__c;
                               poolTreatySection.Section__c = selectedSectionId;
                               poolTreatySection.SectionIsSelected__c = true;
                               poolTreatySection.TreatyIsSelected__c = false;
                       }
                       
                       if(lstPool.size() > 0){
                           map<Id,PoolTreatySection__c> maplstPoolTreatySec = new map<Id,PoolTreatySection__c>(); //Avoid System.ListException: Duplicate id in list:
                           maplstPoolTreatySec.putall(lstPool);
                           update maplstPoolTreatySec.values();
                           System.debug('maplstPoolTreatySec ==' + maplstPoolTreatySec);
                           //update lstPool;
                       }
                   }
                }
    
                String strSectionNumber;
                String[] parts;
                Integer beforeComma;
                Integer afterComma;
                String sectionNumberToStringInit;
                String sectionNumberToString;
    
                if(selectedSectionId != null && editSection == false && createPageSection == false){
                    //copy lookup related Section
                    /***
                    *
                    * Copy Section
                    *
                    */
                    List<String> lstSectionFields = AP_Constant.getCreatableFieldsByObjName(AP_Constant.sObjectSection);
                    String strSectionFields = String.join(lstSectionFields , ', ');
                    Set<Id> setSectionId =  new Set<Id>();
                    List<Section__c> lstNewSection = new List<Section__c>();
    
                    String querySection = 'select Id, Treaty__c, '
                            + strSectionFields
                            + ' from Section__c where (RelatedSection__c = :selectedSectionId) order by Name, ID__c, SectionNumber__c' ;
    
                    List<Section__c> lstRelatedSections = Database.query(querySection);
    
                    Decimal ParentSectionNumber =  Decimal.valueOf(objectSection.SectionNumber__c);
    
                    //RRA - 1083
                    Integer i = 1;
                    for(Section__c relatedSection : lstRelatedSections){
    
                        //ParentSectionNumber += 0.1;
                        // Increment the copy 
                        strSectionNumber = String.valueOf(ParentSectionNumber); 
                        parts = strSectionNumber.split('\\.');
                        beforeComma = Integer.valueOf(parts[0]);
                        afterComma =Integer.valueOf(parts[1]);
                        sectionNumberToStringInit = String.valueOf(beforeComma + '.' + (afterComma + i));
    
                        Section__c newSection = relatedSection.clone(false, false, false, false);
                        newSection.RelatedSection__c = objectSection.Id;
                        newSection.TECH_OldSectionId__c = relatedSection.Id;
                        newSection.SectionNumber__c = String.valueOf(sectionNumberToStringInit);
                        newSection.Retained_to_lead__c = false;
                        setSectionId.add(relatedSection.Id);
                        lstNewSection.add(newSection);
                        i++;
                    }
    
                    if(lstNewSection.size() > 0){
                        insert lstNewSection;
                    }
    
                    /***
                    *
                    * Copy Covered Ceding Company
                    *
                    */
                    List<String> lstCoveredCedCompFields = AP_Constant.getCreatableFieldsByObjName(AP_Constant.sObjCoveredCedingComp);
                    String strCoveredCedCompFields = String.join(lstCoveredCedCompFields , ', ');
                    String queryCoveredCedComp = 'select Id, Account__c,  '
                            + strCoveredCedCompFields
                            + ' from CoveredCedingCompany__c where (Section__c IN :setSectionId) '
                            + 'and (SectionIsSelected__c = true ) ';
    
                    List<CoveredCedingCompany__c> lstCoveredCedCompSection = Database.query(queryCoveredCedComp);
    
                    //Build map Covered Ceding Company for section (SectionId, List<CoveredCedingCompany__c)
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
                            newCov.Program__c = section.Program__c;
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
                    * Copy Reinstatement if typeOfTreaty = XL
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
                        List<Reinstatement__c> lstReinstatementNew = new List<Reinstatement__c>();
                        if(mapReinstatement.containsKey(reinstatement.Section__c)){
                            lstReinstatementNew = mapReinstatement.get(reinstatement.Section__c);
                            lstReinstatementNew.add(reinstatement);
                        }else{
                            lstReinstatementNew.add(reinstatement);
                        }
                        mapReinstatement.put(reinstatement.Section__c, lstReinstatementNew);
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
                    * Copy Pool
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
                        }else{
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
                mapResults.put('Success', 'Success');
            }
            catch (Exception ex) {
                mapResults.put('Error', ex.getMessage());
                if(editSection == true){
                    if(objectSection != null){
                        objectSection.SuccessErrorToastMessageOnFlow__c = 'An error has occurred. Please contact your System Administrator.';
                        update objectSection;
                    }
                }
            }
    
            return mapResults;
        }
    
        @AuraEnabled(Cacheable = true)
        public static List<Program__c> getProgram(String id) {
            return [
                    SELECT Id, Name, Nature__c FROM Program__c WHERE Id = :id
            ];
        }
    
        /**
        * @description Method to retrieve Covered Ceding Companies of Treaty
        * @param String selectedProgramId
        * @param String selectedTreatyId
        * @return List<CoveredCedingCompany__c>
        */
        @AuraEnabled
        public static List<CoveredCedingCompany__c> getCoveredCedingCompaniesByTreatyId(String selectedProgramId, String selectedTreatyId) {
            return [
                    SELECT Id, Name, Account__r.Name
                    FROM CoveredCedingCompany__c
                    WHERE Program__c = :selectedProgramId
                    AND Treaty__c = :selectedTreatyId
                    AND TreatyIsSelected__c = TRUE
            ];
        }
    
        /**
        * @description Method to retrieve Covered Ceding Companies of Treaty
        * @param String selectedProgramId
        * @param String selectedTreatyId
        * @return List<CoveredCedingCompany__c>
        * RRA - Ticket 1320 - Total EPI ne se calcule pas
        */
        @AuraEnabled
        public static List<CoveredCedingCompany__c> getCoveredCedingCompaniesBySectionId(String selectedSectionId) {
            return [
                    SELECT Id, EPI__c
                    FROM CoveredCedingCompany__c
                    WHERE Section__c = :selectedSectionId
            ];
        }
    
        /**
        * @description Method to retrieve Covered Ceding Companies of Section
        * @param String selectedSectionId
        * @return List<CoveredCedingCompany__c>
        */
        @AuraEnabled
        public static List<CoveredCedingCompany__c> getCovCedCompBySectionId(String selectedSectionId) {
            return [
                    SELECT Id, Name, Account__r.Name, EPI__c, AllocationKey__c
                    FROM CoveredCedingCompany__c
                    WHERE Section__c = :selectedSectionId
                    AND SectionIsSelected__c = TRUE
            ];
        }
    
        /**
       * @description Method to retrieve Reinstatements of Section
       * @param String selectedSectionId
       * @return List<Reinstatement__c>
       */
        @AuraEnabled
        public static List<Reinstatement__c> getReinstatements(String selectedSectionId) {
            return [
                    SELECT Id, Name, Order__c, Key_Insert_Update_Reinstatement__c, Percentage__c, toLabel(Prorata__c), Free__c, toLabel(Type__c)
                    FROM Reinstatement__c
                    WHERE Section__c = :selectedSectionId AND Key_Insert_Update_Reinstatement__c = NULL
            ];
        }
    
    
        /**
        * @description Method to get Section number
        * @param Id treatyId
        * @return String
        */
        @AuraEnabled
        public static String getSectionNumber(Id treatyId) {
            Decimal sectionNumber;
            List<Decimal> lstSectionNumber = new List<Decimal>();
            String sectionNumberToString;
    
            for (Section__c section : [SELECT Id, SectionNumber__c FROM Section__c WHERE Treaty__c = :treatyId ORDER BY SectionNumber__c DESC]){
                lstSectionNumber.add(Decimal.valueOf(section.SectionNumber__c));
            }
            System.debug('lstSectionNumber== ' + lstSectionNumber);
            lstSectionNumber.sort();
            if(lstSectionNumber.size() > 0){
                Integer sectionNumInt = (Integer)lstSectionNumber[lstSectionNumber.size() - 1];
                System.debug('sectionNumInt== ' + sectionNumInt);
                sectionNumber = (Decimal)sectionNumInt + 1.1;
            }
            else{
                sectionNumber = 1.1;
            }
            
            sectionNumberToString = String.valueOf(sectionNumber);
            return sectionNumberToString;
        }
    
        /**
        * @description Method to retrieve Option Section Number
        * @param String selectedSectionId
        * @param String parentSectionNumber
        * @return String
        * RRA 1083
        */
        @AuraEnabled
        public static String getOptionSectionNumber(Id selectedSectionId, String parentSectionNumber) {
            if(selectedSectionId != null && parentSectionNumber != null){
                Decimal sectionNumber;
                String sectionNumberToString;
                String sectionNumberToStringInit;
                String valueStr;
                //List<Decimal> lstSectionNumber = new List<Decimal>();
                List<Decimal> lstNumberSection= new List<Decimal>();
                String strSectionNumber;
                String[] parts;
                Integer beforeComma;
                Integer afterComma;
    
                for(Section__c section : [SELECT Id, SectionNumber__c, ID__c FROM Section__c WHERE RelatedSection__c = :selectedSectionId ORDER BY SectionNumber__c DESC]){
                    lstNumberSection.add(Decimal.valueOf(section.SectionNumber__c));
                }
                System.debug('lstSectionNumber== ' + lstNumberSection);
                
                List<Decimal> lstSectionNumber = selectionSorting(lstNumberSection, 'Sort by DecimalValue');  
                System.debug('lstSectionNumberTri== ' + lstSectionNumber);
                Decimal x = 10;
                if(lstSectionNumber.size() > 0){
    
                    sectionNumber = lstSectionNumber[lstSectionNumber.size() - 1]; // Calculate the section Number from x.0 to x.9 by step 0.1
                    System.debug('sectionNumberdernier == ' + sectionNumber);
    
                    strSectionNumber = String.valueOf(sectionNumber); // convert section number to string
                    System.debug('strSectionNumber== ' + strSectionNumber);
    
                    parts = strSectionNumber.split('\\.'); // split the value integer and value decmal
                    System.debug('parts== ' + parts);
    
                    beforeComma = Integer.valueOf(parts[0]); // integer value
                    System.debug('beforeComma== ' + beforeComma);
                    
                    afterComma =Integer.valueOf(parts[1]); // decimal value
                    System.debug('afterComma== ' + afterComma); 
    
                    if (afterComma == 0){ // if value decimal is zero
                        sectionNumberToStringInit = String.valueOf((beforeComma - 1) + '.' + (afterComma + x)); 
                        System.debug('sectionNumberToStringAA== ' + sectionNumberToStringInit);
                        sectionNumber = Decimal.valueOf(sectionNumberToStringInit);
                        //lstSectionNumber.add(sectionNumber);
                    }else if (afterComma >= 1){ // if value decimal is greater than 1
                        sectionNumberToString = String.valueOf(beforeComma + '.' + (afterComma - 1));
                        System.debug('sectionNumberToStringBB== ' + sectionNumberToString);
                    }
                    
                    System.debug('sectionNumber== ' + sectionNumber);
                }
                else{
                    sectionNumber = Decimal.valueOf(parentSectionNumber) + 0.1;
                    sectionNumberToString = String.valueOf(sectionNumber);
                }
                
                if (lstSectionNumber.contains(sectionNumber)){ // if the current value entered exists already on the database
                    System.debug('lstSectionNumber22== ' + lstSectionNumber);
                    Decimal sectionNumberRecent = lstSectionNumber[lstSectionNumber.size() - 1]; 
                    System.debug('sectionNumberRecent== ' + sectionNumberRecent);
                    String strSectionNumber2 = String.valueOf(sectionNumberRecent);
                    List<String> parts2 = strSectionNumber2.split('\\.');
                    Integer beforeComma2 = Integer.valueOf(parts2[0]);
                    Integer afterComma2 =Integer.valueOf(parts2[1]); 
                    if (afterComma2 > 0) {
                        sectionNumberToStringInit = String.valueOf(beforeComma2 + '.' + (afterComma2 + 1));
                        sectionNumber = Decimal.valueOf(sectionNumberToStringInit);
                        System.debug('sectionNumberToStringGreatherOrEqual10== ' + sectionNumberToStringInit);
                        sectionNumberToString = String.valueOf(sectionNumber);
                    }
                    //sectionNumberToString = String.valueOf(sectionNumber);
                }else{
                    sectionNumberToString = String.valueOf(sectionNumber); // display the value on UI
                }
    
                System.debug('sectionNumberToString== ' + sectionNumberToString);
                return sectionNumberToString;
            }
            else{
                return null;
            }
        }
    
        /**
        * @description Method of sort realized on the decimal part of SectionNumber
        * @param List<String> lstSort
        * @return List<Decimal>
        * RRA 1083
        */
        public static List<Decimal> selectionSorting(list<Decimal> lstSort, String typeSort)         
        {
            List<Decimal> lstSortNew = new List<Decimal>();
            List<Integer> lstAfterComma = new List<Integer>();
            List<Integer> lstBeforeComma = new List<Integer>();
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
            if (typeSort == 'Sort by DecimalValue'){
                Decimal len = lstAfterComma.size();
                for (Integer i = 0; i < len; i++)
                {
                   // Finding the minimum element in the unsorted part of array
                   Integer min = i;
                    for (Integer j = i+1; j < len; j++)
                        if (lstAfterComma[j] < lstAfterComma[min])
                            min = j;
         
                    /* Swapping the found minimum element with the first
                     * element of the sorted subarray using temp variable
                     */
                    Integer temp = lstAfterComma[min];
                    lstAfterComma[min] = lstAfterComma[i];
                    lstAfterComma[i] = temp;
                    sectionNumberToStringInit = String.valueOf(beforeComma + '.' + temp); 
                    sectionNumber = Decimal.valueOf(sectionNumberToStringInit);
                    lstSortNew.add(sectionNumber);
                }
            }else if (typeSort == 'Sort by IntegerValue'){
                Decimal len = lstBeforeComma.size();
                for (Integer i = 0; i < len; i++)
                {
                   // Finding the minimum element in the unsorted part of array
                   Integer min = i;
                    for (Integer j = i+1; j < len; j++)
                        if (lstBeforeComma[j] < lstBeforeComma[min])
                            min = j;
         
                    /* Swapping the found minimum element with the first
                     * element of the sorted subarray using temp variable
                     */
                    Integer temp = lstBeforeComma[min];
                    lstBeforeComma[min] = lstBeforeComma[i];
                    lstBeforeComma[i] = temp;
                    sectionNumberToStringInit = String.valueOf(temp + '.' + afterComma); 
                    sectionNumber = Decimal.valueOf(sectionNumberToStringInit);
                    lstSortNew.add(sectionNumber);
                }
            }
            
    
            System.debug('lstSortNew== ' + lstSortNew);
        return lstSortNew;
    }
    
        /**
        * @description Method to get selected Program Details
        * @param String selectedProgramId
        * @return Program__c
        */
        @AuraEnabled(Cacheable = true)
        public static Program__c getProgramDetails(Id selectedProgramId) {
            return [SELECT Id, UwYear__c, PrincipalCedingCompany__c, Nature__c, LTA__c , RenewedFromProgram__c, TypeOfRenew__c FROM Program__c WHERE Id = :selectedProgramId];
        }
    
        /**
        * @description Method to get selected Section Details
        * @param String selectedSectionId
        * @return Section__c
        */
        @AuraEnabled
        public static Section__c getSectionDetails(Id selectedSectionId) {
            List<String> lstSectionFields = AP_Constant.getCreatableFieldsByObjName(AP_Constant.sObjectSection);
            String strSectionFields = String.join(lstSectionFields , ', ');
            String querySection = 'select Id, Treaty__c, Treaty__r.IsPooled__c, Program__r.UwYear__c, Program__r.PrincipalCedingCompany__r.Name, TECH_ProgramName__c, TECH_TreatyName__c, TECH_RelatedSectionNumber__c, Program__r.LTA__c , Program__r.RenewedFromProgram__c, Program__r.TypeOfRenew__c, Program__r.TECH_ShowClosePreviousPhaseBtn__c, '
                    + strSectionFields
                    + ' from Section__c where (Id = :selectedSectionId) ';
            Section__c section = Database.query(querySection);
            return section;
        }
    
        /**
        * @description Method to check if Section has Quote Requests
        * @param Id programId
        * @param Id selectedSectionId
        * @return Boolean
        */
        @AuraEnabled
        public static Boolean checkIfQuoteRequestPresent(Id programId, Id selectedSectionId) {
            Boolean requestPresent = false;
            List <Request__c> lstQuoteRequests = [ SELECT Id
            FROM Request__c
            WHERE Section__c =: selectedSectionId
            AND ReinsurerStatus__c !=: AP_Constant.statusSetup
            AND Program__c =: programId];
            if(lstQuoteRequests != null){
                if(lstQuoteRequests.size() > 0){
                    requestPresent = true;
                }
            }
            return requestPresent;
        }
    
        /**
        * @description Method to get selected Treaty details
        * @param Id selectedTreatyId
        * @return Treaty__c
        */
        @AuraEnabled(Cacheable = true)
        public static Treaty__c getTreatyDetails(Id selectedTreatyId) {
            List<String> lstTreatyFields = AP_Constant.getCreatableFieldsByObjName(AP_Constant.sObjectTreaty);
            String strTreatyFields = String.join(lstTreatyFields , ', ');
            String queryTreaty = 'select Id, Program__c, Program__r.UwYear__c, Program__r.PrincipalCedingCompany__c, Program__r.PrincipalCedingCompany__r.Name, TECH_ProgramName__c, TECH_ProgramNature__c, Program__r.LTA__c, Program__r.RenewedFromProgram__c, '
                    + strTreatyFields
                    + ' from Treaty__c where (Id = :selectedTreatyId) ';
            Treaty__c treaty = Database.query(queryTreaty);
            return treaty;
        }
    
        /**
        * @description Method to get Pool Treaty details of selected Treaty
        * @param Id treatyId
        * @return List<PoolTreatySection__c>
        */
        @AuraEnabled
        public static List<PoolTreatySection__c> getPoolsTreatyDetails(Id treatyId) {
            List<PoolTreatySection__c> lstPoolTreatySections = [SELECT Id, Name, Pool__c, TECH_PoolShareRate__c, Section__c, SectionEpiCededToPool__c, Pool__r.Name
                    , SectionEpiSharedCeded__c, SectionIsSelected__c, SectionShareRate__c, SubLoB__c
                    , Treaty__c, TreatyIsSelected__c, TreatyShareRate__c
            FROM PoolTreatySection__c
            WHERE Treaty__c = :treatyId
            AND Section__c = NULL
            AND SectionIsSelected__c = FALSE];
            return lstPoolTreatySections;
        }
    
        /**
        * @description Method to get Pool Section details of selected Section
        * @param Id sectionId
        * @return List<PoolTreatySection__c>
        */
        @AuraEnabled
        public static List<PoolTreatySection__c> getPoolsSectionDetails(Id sectionId) {
            //RRA - ticket 1364 - 27072023
            List<PoolTreatySection__c> lstPoolTreatySections = [SELECT Id, Name, TECH_upsertPoolTreatySection__c, Pool__c, TECH_PoolShareRate__c, Section__c, SectionEpiCededToPool__c, Pool__r.Name
                                                                        , SectionEpiSharedCeded__c, SectionIsSelected__c, SectionShareRate__c, SubLoB__c
                                                                        , Treaty__c, TreatyIsSelected__c, TreatyShareRate__c
                                                                FROM PoolTreatySection__c
                                                                WHERE Section__c = :sectionId];
            return lstPoolTreatySections;
        }
    
        /**
        * @description Method to check if Quote Type field need to be disabled for the Renewed Program
        * @param Id treatyId
        * @return Boolean
        */
        @AuraEnabled
        public static Boolean disableQuoteTypeForRenewProg(Id treatyId) {
            //Quote type cannot be changed if at least one request is attached to this section or the treaty of this section
            Boolean disableQuoteTypeForRenewProg = false;
            List<Request__c> lstRequest = [SELECT Id, Name FROM Request__c WHERE Treaty__c = :treatyId];
            if(lstRequest.size() > 0){
                disableQuoteTypeForRenewProg = true;
            }
            return disableQuoteTypeForRenewProg;
        }
    
        /**
        * @description Method to get Picklist of Renewed From Section-Option of Original Program
        * @param Id programId
        * @return Map<String, Object>
        */
        @AuraEnabled
        public static Map<String, Object> getAllSectionOption(Id programId) {
            Map<String, Object> mapResults = new Map<String, Object>();
            List<OptionWrapper> lstAllSectionOption = new List<OptionWrapper>();
            Id renewedFromProgId;
            Boolean isProgramRenewed = false;
    
            try{
                Program__c selectedProgram = [SELECT Id, Name, RenewedFromProgram__c FROM Program__c WHERE Id =:programId LIMIT 1];
    
                if(selectedProgram != null){
                    if(selectedProgram.RenewedFromProgram__c != null){
                        renewedFromProgId = selectedProgram.RenewedFromProgram__c;
                        isProgramRenewed = true;
    
                        for(Section__c originalSection : [SELECT Id, Name, SectionNumber__c FROM Section__c WHERE Program__c = :renewedFromProgId]){
                            String originalSectionId = originalSection.Id;
                            lstAllSectionOption.add(new OptionWrapper(originalSection.SectionNumber__c + ' - ' + originalSection.Name, originalSectionId));
                        }
    
                    }
                }
    
                mapResults.put('lstAllSectionOption', lstAllSectionOption);
                mapResults.put('isProgramRenewed', isProgramRenewed);
                mapResults.put('Success', 'Success');
            } 
            catch (Exception ex) {
                mapResults.put('Error', ex.getMessage());
            }
    
            return mapResults;
        }
    
        @AuraEnabled
        public static String ObjectAPIName(Id myId){
            return myId.getSObjectType().getDescribe().getName();
        }
    
        public class OptionWrapper implements Comparable{
            @AuraEnabled public String label {get; set;}
            @AuraEnabled public String value {get; set;}
    
            public OptionWrapper(String label, String value) {
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