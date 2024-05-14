public with sharing class AP58_UpdateCSTreatyReference {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Update Custom Setting for Treaty Reference
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 25-JUN-2021  MBE    1.0     Initial Version
--------------------------------------------------------------------------------------
**************************************************************************************/

    /**
    * @description Method to update Custom Setting for Treaty Reference
    * @param List<Treaty__c> lstTreaties
    * @return void
    */
    public static void updateCSTreatyReference(List<Treaty__c> lstTreaties){
        Decimal lastRefIndex = 0;

        for(Treaty__c treaty : lstTreaties){
            if(Decimal.valueOf(treaty.ReferenceSequence__c) > lastRefIndex){
                lastRefIndex = Decimal.valueOf(treaty.ReferenceSequence__c);
            }
        }

        List<CS_TreatyReference__c> lstTreatyRefCustomSetting = [SELECT Id, ReferenceSequence__c FROM CS_TreatyReference__c LIMIT 1];

        if(lstTreatyRefCustomSetting.size() > 0){
            Decimal treatyRef = Decimal.valueOf(lstTreatyRefCustomSetting[0].ReferenceSequence__c);

            if(lastRefIndex > treatyRef){
                lstTreatyRefCustomSetting[0].ReferenceSequence__c = String.valueOf(lastRefIndex);
            }

            update lstTreatyRefCustomSetting;
        }
    }
}