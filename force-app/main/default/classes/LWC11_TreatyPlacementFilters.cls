public with sharing class LWC11_TreatyPlacementFilters {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Controller for Lightning Web Component lwc11TreatyPlacementFilters
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 05-DEC-2019  NBI   1.0      Initial version
--------------------------------------------------------------------------------------
**************************************************************************************/

    /**
    * @description Method to get getPrograms for PCC and UW year
    * @param String valueUWYear, String valuePrincipalCedComp
    * @return List<OptionWrapper>
    */
    @AuraEnabled(Cacheable = true)
    public static List<OptionWrapper> getPrograms(String valueUWYear, String valuePrincipalCedComp){
        List<OptionWrapper> lstPrograms = new List<OptionWrapper>();
        for(Program__c program : [SELECT Id, Name FROM Program__c
                                  WHERE UwYear__c = :valueUWYear AND PrincipalCedingCompany__c = :valuePrincipalCedComp
                                  ORDER BY Name]){
            lstPrograms.add(new OptionWrapper(program.Name, program.Id));
        }

        return lstPrograms;
    }

    /**
    * @description Method to get Program details
    * @param Id programId
    * @return Program__c
    */
    @AuraEnabled(Cacheable = true)
    public static Program__c getProgramDetails(Id programId) {
        List<String> lstProgramFields = AP_Constant.getCreatableFieldsByObjName(AP_Constant.sObjectProgram);
        String strProgramFields = String.join(lstProgramFields , ', ');
        String queryProgram = 'select Id, PrincipalCedingCompany__r.Name, PrincipalCedingCompany__c,  '
                + strProgramFields
                + ' from Program__c where (Id = :programId) ';
        Program__c program = Database.query(queryProgram);
        return program;
    }

    /**
    * @description Method to get Treaties for the Program
    * @param Id programId
    * @return List<OptionWrapper>
    */
    @AuraEnabled(Cacheable = true)
    public static List<OptionWrapper> getTreaties(Id programId ){
        List<OptionWrapper> lstTreaties = new List<OptionWrapper>();
        for(Treaty__c treaty : [SELECT Id, Name FROM Treaty__c
                                WHERE Program__c = :programId
                                ORDER BY Name]){
            lstTreaties.add(new OptionWrapper(treaty.Name, treaty.Id));
        }
        return lstTreaties;
    }

    /**
    * @description Method to get Broker(s) for the Requests of a Program
    * @param Id programId, String phase
    * @return List<OptionWrapper>
    */
    @AuraEnabled(Cacheable = true)
    public static List<OptionWrapper> getAccountBroker(Id programId, String phase){
        List<OptionWrapper> lstAccountBroker = new List<OptionWrapper>();
        Map<Id, String> mapIdName = new Map<Id, String>();

        for(Request__c request : [SELECT Id, Broker__c, Broker__r.Name FROM Request__c WHERE Program__c = :programId AND RecordType.DeveloperName = :phase]){
            mapIdName.put(request.Broker__c, request.Broker__r.Name);
        }

        for(Id brokerId : mapIdName.keySet()){
            lstAccountBroker.add(new OptionWrapper(mapIdName.get(brokerId), brokerId));
        }

        lstAccountBroker.sort();
        return lstAccountBroker;
    }

    /**
    * @description Method to get Reinsurer(s) for the Requests of a Program
    * @param Id programId, String phase
    * @return List<OptionWrapper>
    */
    @AuraEnabled(Cacheable = true)
    public static List<OptionWrapper> getAccountReinsurer(Id programId, String phase){
        List<OptionWrapper> lstAccountReinsurer = new List<OptionWrapper>();
        Map<Id, String> mapIdName = new Map<Id, String>();

        for(Request__c request : [SELECT Id, Reinsurer__c, Reinsurer__r.Name FROM Request__c WHERE Program__c = :programId AND RecordType.DeveloperName = :phase]){
            mapIdName.put(request.Reinsurer__c, request.Reinsurer__r.Name);
        }

        for(Id reinsurerId : mapIdName.keySet()){
            lstAccountReinsurer.add(new OptionWrapper(mapIdName.get(reinsurerId), reinsurerId));
        }

        lstAccountReinsurer.sort();
        return lstAccountReinsurer;
    }

    /**
    * @description Method to get Request Record Types
    * @param null
    * @return List<OptionWrapper>
    */
    @AuraEnabled
    public static List<OptionWrapper> getRequestRTId(){
        List<OptionWrapper> lstRTId = new List<OptionWrapper>();

        for(RecordType redType : [SELECT Id, DeveloperName FROM RecordType WHERE sObjectType = :AP_Constant.sObjectRequest]){
            lstRTId.add(new OptionWrapper(redType.DeveloperName, redType.Id));
        }

        return lstRTId;
    }

    public class OptionWrapper implements Comparable{
        @AuraEnabled
        public String label {get; set;}
        @AuraEnabled
        public String value {get; set;}

        public OptionWrapper(String label, String value) {
            this.label = label;
            this.value = value;
        }

        public Integer compareTo(Object compareTo)
        {
            OptionWrapper optWrapper = (OptionWrapper) compareTo;
            if (label == optWrapper.label) return 0;
            if (label > optWrapper.label) return 1;
            return -1;
        }
    }
}