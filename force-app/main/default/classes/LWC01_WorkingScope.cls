public with sharing class LWC01_WorkingScope {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Controller for Lightning Web Component lwc01WorkingScope
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 14-OCT-2019  NBI   1.0      Initial version
-- 13-SEP-2021  MBE   1.1      W-0999 - Signing - la page Sign for Pool devrait être accessible sans prendre en compte la PCC
--------------------------------------------------------------------------------------
**************************************************************************************/

    /**
    * @description Method to get Principal Ceding Companies
    * @param null
    * @return List<OptionWrapper>
    */
    @AuraEnabled(Cacheable=true)
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

        for(Account account : [SELECT Id, Name, IsActive__c FROM Account WHERE TECH_ReferentialId__c IN :lstReferentialIds AND RecordTypeId = :mapRecTypeId.get(AP_Constant.accRTPrincipalCedingCom)]){
            lstCedingComp.add(new OptionWrapper(account.Name, account.Id, account.IsActive__c));
        }

        lstCedingComp.sort();
        return lstCedingComp;
    }

    /**
    * @description Method to get Principal Ceding Companies for Sign for Pool
    * @param null
    * @return List<OptionWrapper>
    */
    @AuraEnabled(Cacheable=true)
    public static List<OptionWrapper> getPrincipalCedingAccSignForPool(){
        Map<String, Id> mapRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectAcc});
        List<OptionWrapper> lstCedingComp = new List<OptionWrapper>();
        List<Id> lstGroupIds = new List<Id>();
        List<String> lstReferentialIds = new List<String>();
        Id groupCustomAllIntUserId;

        List<Group> lstCustomAllIntUser = [SELECT Id, name FROM Group WHERE Name = :AP_Constant.groupCustomAllInternalUsersPCC LIMIT 1];

        if(lstCustomAllIntUser.size() > 0){
            groupCustomAllIntUserId = lstCustomAllIntUser[0].Id;
        }

        for(GroupMember groupMemberRecord : [SELECT Id, GroupId FROM GroupMember WHERE UserOrGroupId = :UserInfo.getUserId() OR UserOrGroupId = :groupCustomAllIntUserId]){
            lstGroupIds.add(groupMemberRecord.GroupId);
        }

        for(Group groupRecord : [SELECT Id, DeveloperName FROM Group WHERE Id IN :lstGroupIds]){
            lstReferentialIds.add(groupRecord.DeveloperName);
        }

        for(Account account : [SELECT Id, Name, IsActive__c FROM Account WHERE TECH_ReferentialId__c IN :lstReferentialIds AND RecordTypeId = :mapRecTypeId.get(AP_Constant.accRTPrincipalCedingCom)]){
            lstCedingComp.add(new OptionWrapper(account.Name, account.Id, account.IsActive__c));
        }

        lstCedingComp.sort();
        return lstCedingComp;
    }

    public class OptionWrapper implements Comparable{
        @AuraEnabled
        public String label {get; set;}
        @AuraEnabled
        public String value {get; set;}
        @AuraEnabled
        public Boolean isActive {get; set;}

        public OptionWrapper(String label, String value, Boolean isActive){
            this.label = label;
            this.value = value;
            this.isActive = isActive;
        }

        public Integer compareTo(Object compareTo){
            OptionWrapper optWrapper = (OptionWrapper) compareTo;
            if (label == optWrapper.label) return 0;
            if (label > optWrapper.label) return 1;
            return -1;
        }
    }

    /**
    * @description Method to get Program details
    * @param String id
    * @return List<Program__c>
    */
    @AuraEnabled
    public static List<Program__c> getProgramDetails(String id) {
        return [
                SELECT Id, Name, PrincipalCedingCompany__r.Name
                FROM Program__c
                WHERE Id = :id
        ];
    }
}