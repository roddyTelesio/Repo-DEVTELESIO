public with sharing class AP37_UpdateSectionCurrencyLabel {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Update Currency Label for Section
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
--25-JUN-2020  MBE   1.0      Initial version
--------------------------------------------------------------------------------------
**************************************************************************************/

    /**
    * @description Method to populate Currency label when Sections are created/updated
    * @param List<Section__c> lstSections
    * @return void
    */
    public static void updateSectionCurrencyLabel(List<Section__c> lstSections){
        Map<String, String> mapCurrencyApiNameByLabel = new Map<String, String>();

        Schema.SObjectType s = Schema.getGlobalDescribe().get('Section__c') ;
        Schema.DescribeSObjectResult r = s.getDescribe() ;
        Map<String,Schema.SObjectField> fields = r.fields.getMap() ;
        Schema.DescribeFieldResult fieldResult = fields.get('Currency__c').getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();

        for( Schema.PicklistEntry pickListVal : ple){
            mapCurrencyApiNameByLabel.put(pickListVal.getValue(), pickListVal.getLabel());
        }

        for(Section__c section : lstSections) {
            if (mapCurrencyApiNameByLabel.containsKey(section.Currency__c)) {
                section.TECH_CurrencyLabel__c = mapCurrencyApiNameByLabel.get(section.Currency__c);
            }
        }
    }
}