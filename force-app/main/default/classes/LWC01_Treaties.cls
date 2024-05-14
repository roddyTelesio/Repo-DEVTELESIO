public with sharing class LWC01_Treaties {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Controller for Lightning Web Component lwc01Treaties
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 15-OCT-2019  MBE   1.0      Initial version
-- 07-APR-2020  NBI   1.1      LTA Pattern
-- 17-MAY-2021  MBE   1.2      W-0971 - CONDITION - TREATY - problème de calcul du champ Actor_Reference__cct
-- 08-JUL-2021  NBI   1.3      W-0992: Third Party Management
--------------------------------------------------------------------------------------
**************************************************************************************/

    /**
    * @description Method to get Treaties for selected Programs
    * @param List<Id> lstSelectedPrograms
    * @return List<Treaty__c>
    */
    @AuraEnabled(Cacheable = true)
    public static List<Treaty__c> getTreaties(List<Id> lstSelectedPrograms){
        return [
                SELECT Id, Name, Layer__c, WebXLReference__c, toLabel(TypeofTreaty__c), TECH_ProgramName__c, toLabel(Status__c), PlacementShare_Perc__c,TECH_ProgramNature__c
                        ,WordingName__c, WordingName2__c, WordingName3__c, WordingName4__c, Inceptiondate__c, Expirydate__c, Actor_Reference__c, LTA__c
                        ,LTAInceptionDate__c, LTAExpiryDate__c, LTARenegotiation__c, EarlyTerminationDate__c, TacitRenewal__c, Advance_notice__c, TypeofReinsurance__c
                        ,LossAttachment__c, Deductions__c, NotManagedByAgre__c, Deductions_Perc__c, LossDeposit__c, LossDepositMode__c, PremiumDeposit__c
                        ,IsPooled__c, TECH_LTA__c, LTAPattern__c, AGRe_Cession__c, Ceded_Re_Cession__c, GI_Cession__c
                FROM Treaty__c
                WHERE Program__c IN :lstSelectedPrograms
                ORDER BY Name
        ];
    }

    /**
    * @description Method to check if there are Program(s) for Principal Ceding Company and UW year
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
    * @description Method to check Active PCC
    * @param Id TreatyId
    * @return Boolean
    */
    @AuraEnabled
    public static Boolean checkPCC(Id treatyId){
        Boolean pccActive = false;

        Treaty__c treaty = [SELECT Id, Name, Program__r.PrincipalCedingCompany__r.IsActive__c FROM Treaty__c
                            WHERE Id = :treatyId];

        if(treaty != null) {
            pccActive = treaty.Program__r.PrincipalCedingCompany__r.IsActive__c;
        }
        return pccActive;
    }

    /**
    * @description Method to check Active PCC
    * @param Id TreatyId
    * @return Boolean
    */
    @AuraEnabled
    public static Boolean checkCCC(Id treatyId){
        Boolean cccActive = true;
        Set<Boolean> setIsActive = new Set<Boolean>();

        for(CoveredCedingCompany__c ccc : [SELECT Id, Name, Account__r.IsActive__c FROM CoveredCedingCompany__c
                                            WHERE Treaty__c = :treatyId AND TreatyIsSelected__c = TRUE]){
            setIsActive.add(ccc.Account__r.IsActive__c);
        }

        if(setIsActive.size() > 0){
            if(!setIsActive.contains(true)){
                cccActive = false;
            }
        }

        return cccActive;
    }
}