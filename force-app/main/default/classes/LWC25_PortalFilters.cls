public with sharing class LWC25_PortalFilters {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Controller for Lightning Web Component lwc25PortalFilters
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 24-FEB-2019  NBI   1.0      Initial version
-- 07-APR-2021  NBI   1.1      Program Summary Issue - add getReinsurerLabelName()
-- 02-JUN-2021  MBE   1.1      loading time issue: chenge simple function to -> wired function (getProgramNature)
--------------------------------------------------------------------------------------
**************************************************************************************/
    /**
    * @description Method to check if connected User is a Broker
    * @param null
    * @return Boolean
    */
    @AuraEnabled(Cacheable = true)
    public static Boolean checkBrokerContact(){
        Boolean isBroker = false;
        Map<String, Id> mapRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectAcc});

        User usr = [SELECT Id, ContactId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        Id contactId = usr.ContactId;

        if(contactId != null){
            Contact brokContact = [SELECT Id, AccountId, Account.RecordTypeId FROM Contact WHERE Id = :contactId LIMIT 1];

            if(brokContact.Account.RecordTypeId == mapRecTypeId.get(AP_Constant.accRTBroker)){
                isBroker = true;
            }
            else if(brokContact.Account.RecordTypeId == mapRecTypeId.get(AP_Constant.accRTReinsurer)){
                isBroker = false;
            }
        }

        return isBroker;
    }

    /**
    * @description Method to get Programs for the UW year and Principle Ceding Company
    * @param String valueUWYear
    * @param String valuePrincipalCedComp
    * @return List<OptionWrapper>
    */
    @AuraEnabled(Cacheable = true)
    public static List<OptionWrapper> getPrograms(String valueUWYear, String valuePrincipalCedComp, Boolean isCedingPortal){
        List<OptionWrapper> lstPrograms = new List<OptionWrapper>();

        if(isCedingPortal == true){
            User usr = [SELECT Id, ContactId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            Id contactId = usr.ContactId;
            Id cedingAcc = null;
            List<Id> lstProgramId = new List<Id>();
            Map<Id, List<Id>> mapLstCovCedComByProgId = new Map<Id, List<Id>>();
            Map<Id, String> mapProgramIdByProgId = new Map<Id, String>();

            if(contactId != null){
                Contact cedingContact = [SELECT Id, AccountId FROM Contact WHERE Id = :contactId LIMIT 1];

                if(cedingContact != null && cedingContact.AccountId != null){
                    cedingAcc = cedingContact.AccountId;
                }
            }

            for(Program__c program : [SELECT Id, Name
            FROM Program__c
            WHERE UwYear__c = :valueUWYear AND PrincipalCedingCompany__c = :valuePrincipalCedComp]){
                lstProgramId.add(program.Id);
                mapProgramIdByProgId.put(program.Id, program.Name);
            }

            for(CoveredCedingCompany__c covCedCom : [SELECT Id, Name, Account__c, Program__c FROM CoveredCedingCompany__c WHERE Program__c IN :lstProgramId]){
                List<Id> lstCovCedCom = new List<Id>();
                if(mapLstCovCedComByProgId.containsKey(covCedCom.Program__c)){
                    lstCovCedCom = mapLstCovCedComByProgId.get(covCedCom.Program__c);
                }
                lstCovCedCom.add(covCedCom.Account__c);
                mapLstCovCedComByProgId.put(covCedCom.Program__c, lstCovCedCom);
            }

            for(Id programId : mapLstCovCedComByProgId.keySet()){
                Set<Id> setCovCedComByProgId  = new Set<Id>(mapLstCovCedComByProgId.get(programId));
                If(setCovCedComByProgId.contains(cedingAcc)){
                    lstPrograms.add(new OptionWrapper(mapProgramIdByProgId.get(programId), programId));
                }
            }
        }
        else{
            for(Program__c program : [SELECT Id, Name
            FROM Program__c
            WHERE UwYear__c = :valueUWYear AND PrincipalCedingCompany__c = :valuePrincipalCedComp
            ORDER BY Name]){
                lstPrograms.add(new OptionWrapper(program.Name, program.Id));
            }
        }

        return lstPrograms;
    }

    /**
    * @description Method to get Reinsurers
    * @param null
    * @return List<OptionWrapper>
    */
    @AuraEnabled(Cacheable = true)
    public static List<OptionWrapper> getAccountReinsurer(){
        List<OptionWrapper> lstReinsurer = new List<OptionWrapper>();
        Id brokerAcc = null;
        Set<Id> setReinsurerIds = new Set<Id>();

        User usr = [SELECT Id, ContactId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        Id contactId = usr.ContactId;

        if(contactId != null){
            Contact brokContact = [SELECT Id, AccountId FROM Contact WHERE Id = :contactId LIMIT 1];

            if(brokContact != null && brokContact.AccountId != null){
                brokerAcc = brokContact.AccountId;
            }
        }

        Map<Id, OptionWrapper> mapReinsOptions = new Map<Id, OptionWrapper>();

        if(brokerAcc != null){
            for(Request__c req : [SELECT Id, Broker__c, Reinsurer__c, TECH_ReinsurerName__c FROM Request__c WHERE Broker__c = :brokerAcc and ReinsurerStatus__c != :AP_Constant.statusSetup]){
                setReinsurerIds.add(req.Reinsurer__c);
                mapReinsOptions.put(req.Reinsurer__c, new OptionWrapper(req.TECH_ReinsurerName__c, req.Reinsurer__c));
            }
        }

        if(mapReinsOptions != null){
            lstReinsurer = mapReinsOptions.values();
        }

        lstReinsurer.sort();

        return lstReinsurer;
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

    /**
    * @description Method to get Nature of Program
    * @param String programId
    * @return Map<String, Object>
    */
    @AuraEnabled(Cacheable = true)
    public static Map<String, Object> getProgramNature(String programId){
        Map<String, Object> mapResults = new Map<String, Object>();
        List<OptionWrapper> lstProgramNatureOption = new List<OptionWrapper>();
        String natureProgram;

        List<Program__c> lstProgram =  [SELECT Id, Name, toLabel(Nature__c), PrincipalCedingCompany__r.Name, toLabel(Macro_L_O_B__c), UwYear__c, PrincipalCedingCompany__c
        FROM Program__c
        WHERE Id = :programId];

        if(lstProgram.size() > 0){
            natureProgram = lstProgram[0].Nature__c;
        }

        mapResults.put('natureProgram', natureProgram);
        return mapResults;
    }

    /**
    * @description Method to get Reinsurer label
    * @param String programId
    * @return Map<String, Object>
    */
    @AuraEnabled
    public static Map<String, Object> getReinsurerLabelName(String progId, String reinId){
        Map<String, Object> mapResults = new Map<String, Object>();
        String reinsurerLabelName;

        for(Request__c req : [SELECT Id, RecordType.DeveloperName, Program__c, Reinsurer__r.Name, TECH_ReinsurerName__c, Program__r.UwYear__c 
                              FROM Request__c 
                              WHERE Reinsurer__c = :reinId 
                              AND Program__c = :progId LIMIT 1]){
            reinsurerLabelName = req.TECH_ReinsurerName__c; 
        }

        mapResults.put('reinsurerLabelName', reinsurerLabelName);
        return mapResults;
    }
}