public with sharing class LWC22_NewRequestLeader {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Controller for Lightning Web Component lwc22NewRequestLeader
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 31-JAN-2020  MBE   1.0      Initial version
-- 24-AUG-2020  MBE   1.1      Get All Lead Requests
-- 08-JUL-2021  NBI   1.2      W-0992: Third Party Management
-- 24-JUL-2021  MBE   1.3      SOQL Injection for getReinsurer()
--------------------------------------------------------------------------------------
**************************************************************************************/
    /**
    * @description Method to get Reinsurer for search value
    * @param String ObjectName
    * @param String fieldName
    * @param String value
    * @param List<String> selectedRecId
    * @param String treatyValue
    * @param String brokerValue
    * @return List<SObjectResult>
    */
    @AuraEnabled(Cacheable=true)
    public static List<SObjectResult> getReinsurer(String ObjectName, String fieldName, String value, List<String> selectedRecId, String treatyValue, String brokerValue) {
        Map<String, Id> mapReqRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectRequest});
        Map<String, Id> mapAccRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectAcc});
        String recordTypeIdReinsurer = mapAccRecTypeId.get(AP_Constant.accRTReinsurer);
        List<SObjectResult> sObjectResultList = new List<SObjectResult>();

        List<Request__c> lstLeadRequest = [SELECT Id, Name, Reinsurer__c, Treaty__c
                                           FROM Request__c
                                           WHERE Broker__c = :brokerValue
                                           AND Treaty__c = :treatyValue
                                           AND RecordTypeId = :mapReqRecTypeId.get(AP_Constant.reqRTLead)
        ];

        for(Request__c request : lstLeadRequest){
            selectedRecId.add(request.Reinsurer__c);
        }

        if(selectedRecId == null) {
            selectedRecId = new List<String>();
        }

        if(String.isNotEmpty(value)) {
            String strValue = '%' + String.escapeSingleQuotes(value.trim()) + '%';
            String query = 'Select Id, Name from Account where Name LIKE :strValue and ID NOT IN: selectedRecId and RecordTypeId = :recordTypeIdReinsurer AND IsActive__c = TRUE AND IsRiskCarrier__c = true';

            // String query = 'Select Id,'+fieldName+' FROM '+ObjectName+' WHERE '+fieldName+' LIKE \'%' + value.trim() + '%\' and ID NOT IN: selectedRecId and RecordTypeId = :recordTypeIdReinsurer AND IsActive__c = TRUE AND IsRiskCarrier__c = true';
            for(SObject so : Database.query(query)) {
                String fieldvalue = (String)so.get(fieldName);
                sObjectResultList.add(new SObjectResult(fieldvalue, so.Id));
            }
        }

        return sObjectResultList;
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

        public SObjectResult() {}
    }

    /**
    * @description Method to get Account type Broker
    * @param null
    * @return List<OptionWrapper>
    */
    @AuraEnabled(Cacheable = true)
    public static List<OptionWrapper> getAccountBroker(){
        Map<String, Id> mapRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectAcc});
        List<OptionWrapper> lstAccountBroker = new List<OptionWrapper>();

        for(Account account : [SELECT Id, Name FROM Account WHERE RecordTypeId = :mapRecTypeId.get(AP_Constant.accRTBroker) AND IsActive__c = TRUE]){
            lstAccountBroker.add(new OptionWrapper(account.Name, account.Id));
        }

        return lstAccountBroker;
    }

    public class OptionWrapper {
        @AuraEnabled
        public String label {get; set;}
        @AuraEnabled
        public String value {get; set;}

        public OptionWrapper(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }

    /**
    * @description Method to check if Broker/Reinsurer is present
    * @param null
    * @return List<OptionWrapper>
    */
    @AuraEnabled(Cacheable=true)
    public static Boolean isBrokerReinPresent(Id treatyId, Id brokerId, Id reinsurerId) {
        Map<String, Id> mapRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectRequest});
        Boolean isBrokerReinPresent = false;

        List<Request__c> lstLeadRequest = [SELECT Id FROM Request__c WHERE Treaty__c = :treatyId
                                           AND Reinsurer__c = :reinsurerId
                                           AND Broker__c = :brokerId
                                           AND RecordTypeId = :mapRecTypeId.get(AP_Constant.reqRTLead)
        ];

        if(lstLeadRequest.size() > 0){
            isBrokerReinPresent = true;
        }
        else{
            isBrokerReinPresent = false;
        }

        return isBrokerReinPresent;
    }


    /**
    * @description Method to get all Lead Requests
    * @param Id programId
    * @return List<Request__c>
    */
    @AuraEnabled
    public static List<Request__c> getAllLeadRequests(Id programId) {
        Map<String, Id> mapRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectRequest});
        List<Request__c> lstLeadRequest = [SELECT Id, Reinsurer__c, Broker__c, Treaty__c, Program__c FROM Request__c WHERE Program__c = :programId AND RecordTypeId = :mapRecTypeId.get(AP_Constant.reqRTLead) AND Reinsurer__c != NULL];

        return lstLeadRequest;
    }
}