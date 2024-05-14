public with sharing class LWC01_PortalWorkingScope {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Controller for Lightning Web Component lwc01WorkingScope - Portal
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 13-MAR-2020 NBI   1.0      Initial version
--------------------------------------------------------------------------------------
**************************************************************************************/

    /**
    * @description Method to get Principal Ceding Companies for the connected user
    * @param null
    * @return List<OptionWrapper>
    */
    @AuraEnabled(Cacheable=true)
    public static List<OptionWrapper> getPrincipalCedingAccPortal(){
        List<OptionWrapper> lstCedingComp = new List<OptionWrapper>();
        Map<Id, String> mapPCC = new Map<Id, String>();

        //To get contactId of selected reinsurer/broker from User
        //Get all account contact relation where it has same contactid and role = 'Principal Ceding Company'

        User usr = [SELECT Id, ContactId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        Id contactId = usr.ContactId;

        String strPrincipalCedingCompany = 'PrincipalCedingCompany';

        List<AccountContactRelation> lstAccountContactRelations = [SELECT Id, ContactId, AccountId, Account.Name
                                                                   FROM AccountContactRelation
                                                                   WHERE ContactId = :contactId
                                                                   AND Roles = :strPrincipalCedingCompany];

        for(AccountContactRelation accConRelation : lstAccountContactRelations){
            mapPCC.put(accConRelation.AccountId, accConRelation.Account.Name);
        }

        if(mapPCC != null){
            for(Id pccId : mapPCC.keySet()){
                lstCedingComp.add(new OptionWrapper(mapPCC.get(pccId), pccId));
            }
        }

        lstCedingComp.sort();
        return lstCedingComp;
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