public with sharing class AP59_DeleteOldAccConRelation {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Delete old Account Contact Relation for Ceding Contact
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 05-JUL-2021  MBE    1.0     Initial Version
--------------------------------------------------------------------------------------
**************************************************************************************/

    /**
    * @description Method to delete old Account Contact Relation for Ceding Contact
    * @param List<AccountContactRelation> lstAccConRelation
    * @return void
    */
    public static void deleteOldAccConRelation(List<AccountContactRelation> lstAccConRelation){
        Set<Id> setContactId = new Set<Id>();
        Set<Id> setInsertedAccConRelId = new Set<Id>();
        Map<String, Id> mapRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectAcc});
        Id covCedComRecordType = mapRecTypeId.get(AP_Constant.accRTCoveredCedingCompany);
        List<AccountContactRelation> lstAccConRelToDelete = new List<AccountContactRelation>();
        
        List<AccountContactRelation> lstInsertedAccConRel = [SELECT Id, AccountId,Account.Name, Account.RecordTypeId, Contact.Account.RecordTypeId, Contact.Email, Roles, ContactId
                                                                    , Contact.MacroLoB__c, Contact.Nature__c, Contact.LastName
                                                                    , Contact.FirstName FROM AccountContactRelation
                                                            WHERE Id IN :lstAccConRelation];

        for(AccountContactRelation accConRel : lstInsertedAccConRel){
            if(accConRel.Contact.Account.RecordTypeId == covCedComRecordType){
                setContactId.add(accConRel.ContactId);
                setInsertedAccConRelId.add(accConRel.Id);
            }
        }

        if(setContactId.size() > 0){
            for(AccountContactRelation accConRel : [SELECT Id, AccountId,Account.Name, Account.RecordTypeId, Contact.Account.RecordTypeId, Contact.Email, Roles, ContactId
                                                            , Contact.MacroLoB__c, Contact.Nature__c, Contact.LastName
                                                            , Contact.FirstName FROM AccountContactRelation
                                                    WHERE ContactId IN :setContactId]){
                if(!setInsertedAccConRelId.contains(accConRel.Id)){
                    lstAccConRelToDelete.add(accConRel);
                }
            }
        }

        if(lstAccConRelToDelete.size() > 0){
            delete lstAccConRelToDelete;
        }
 
    }
}