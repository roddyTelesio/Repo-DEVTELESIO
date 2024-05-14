public with sharing class AccountContactRelationTriggerHandler {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : handler for trigger on AccountContactRelation
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 02-SEP-2020  MBE   1.0      Initial version
-- 27-SEP-2021  MBE   1.1      W-1031 - Error Account&Contact Relation
-- 13-JUL-2021  AMI   2.0      CRM360 Lot1 - Prevent ACR relationship removal
--                             for Client Executive
--------------------------------------------------------------------------------------
**************************************************************************************/
    public AccountContactRelationTriggerHandler() {}

    public void handleAfterUpdate(List<AccountContactRelation> lstOldAccConRelation, List<AccountContactRelation> lstNewAccConRelation){
        System.debug('START handleAfterUpdate');
        List<AccountContactRelation> lstNewAccountContactRelation = new List<AccountContactRelation>();
        List<AccountContactRelation> lstOldAccountContactRelation = new List<AccountContactRelation>();
        List<Id> lstContactId = new List<Id>();
        List<Id> lstContactIdOld = new List<Id>();
        List<Id> lstACROldId = new List<Id>();
        //Set<String> setKeysWithUserId;
        //List<Contact> lstContact = new List<Contact>();

        for(Integer i = 0; i < lstNewAccConRelation.size(); i++) {
            if(PAD.canRun('AP36_CreateSharingForContact')){
                if(lstOldAccConRelation[i].Roles != lstNewAccConRelation[i].Roles){
                    lstNewAccountContactRelation.add(lstNewAccConRelation[i]);
                    lstOldAccountContactRelation.add(lstOldAccConRelation[i]);
                }
            }
        }

        for(AccountContactRelation relation : lstNewAccountContactRelation){
            lstContactId.add(relation.ContactId);
        }
        for(AccountContactRelation relationOld : lstOldAccountContactRelation){
            lstContactIdOld.add(relationOld.ContactId);
        }

        for(AccountContactRelation relation : lstOldAccountContactRelation){
            lstContactIdOld.add(relation.ContactId);
            lstACROldId.add(relation.Id);
        }

        if (lstACROldId != null){
            AP61_CreateKeySharingContact.DeleteRecordIntOjFromACR(lstContactIdOld, lstACROldId);
        }

        System.debug('lstContactId_AfterUpdate== '+ lstContactId);

        /*if(PAD.canRun('AP61_CreateUpdateKeySharingContact') && lstContactId.size() > 0){
            setKeysWithUserId = AP61_CreateKeySharingContact.createKeyElligibleForSharingContact(lstContactId, false, true, null);
        }

        if(PAD.canRun('AP36_CreateSharingForContact') && lstContactId.size() > 0){
            AP36_CreateSharingForContact.createSharingForContact(setKeysWithUserId);
        }

        if(PAD.canRun('AP62_DeleteSharing') && lstOldAccountContactRelation.size() > 0 && lstContactIdOld.size() > 0){
            AP62_DeleteSharing.deleteRequestAccountSharingAfterUpdateACRCont(lstOldAccountContactRelation, lstContactIdOld,null,null);
        }*/
        System.debug('STOP handleAfterUpdate');
    }

    public void handleAfterInsert(List<AccountContactRelation> lstNewAccConRelationNew){
        System.debug('START handleAfterInsert');
        List<Id> lstContactId = new List<Id>();
        Set<String> setKeysWithUserId;
        List<AccountContactRelation> lstACR= new List<AccountContactRelation>();
        List<String> lstStrAcc = new List<String>();
        /*List<Id> lstPCCId = new List<Id>();
        List<Id> lstBrokerId = new List<Id>();
        List<Id> lstReinsurerId = new List<Id>();*/

        for(AccountContactRelation relation : lstNewAccConRelationNew){
            lstContactId.add(relation.ContactId);
            lstACR.add(relation);
        }

        System.debug('lstContactId_AfterInsert__lstACR== '+ lstACR);

        for (AccountContactRelation acr : lstACR){
            String acc = acr.Tech_AccountName__c;
            String lastStrAcc= acc.right(3);
            if (lastStrAcc == '(P)'){
                lstStrAcc.add(acr.AccountId + '_' +lastStrAcc);
            }else if (lastStrAcc == '(B)'){
                lstStrAcc.add(acr.AccountId + '_' +lastStrAcc);
            }else if (lastStrAcc == '(R)') {
                lstStrAcc.add(acr.AccountId + '_' +lastStrAcc);
            }
        }
        System.debug('lstContactId_AfterInsert__lstStrAcc== '+ lstStrAcc);

        /*if(lstContactId.size() > 0){
            lstContact = [SELECT Id, Name FROM Contact WHERE Id IN: lstContactId];
        }*/

        System.debug('lstContactId_AfterInsert== '+ lstContactId);

        if(PAD.canRun('AP61_CreateUpdateKeySharingContact') && lstContactId.size() > 0){
            setKeysWithUserId = AP61_CreateKeySharingContact.createKeyElligibleForSharingContact(lstContactId, true,false, new Set<String>());
        }

        System.debug('ACRAfterInsert___setKeysWithUserId= ' + setKeysWithUserId);

   
        if(setKeysWithUserId.size() > 0 && PAD.canRun('AP36_CreateSharingForContact') && lstContactId.size() > 0){
            AP36_CreateSharingForContact.createSharingForContact(setKeysWithUserId, lstContactId, lstStrAcc);
        }

        if(PAD.canRun('AP59_DeleteOldAccConRelation') && lstNewAccConRelationNew.size() > 0){
            AP59_DeleteOldAccConRelation.deleteOldAccConRelation(lstNewAccConRelationNew);
        }
        System.debug('STOP handleAfterUpdate');
    }

    /*public void handleAfterInsertOld(List<AccountContactRelation> lstNewAccConRelationOld){
        List<Id> lstContactIdOld = new List<Id>();
        List<Id> lstACROldId = new List<Id>();
        for(AccountContactRelation relation : lstNewAccConRelationOld){
            lstContactIdOld.add(relation.ContactId);
            lstACROldId.add(relation.Id);
        }

        if (lstACROldId != null){
            AP61_CreateKeySharingContact.DeleteRecordIntOjFromACR(lstContactIdOld, lstACROldId);
        }
    }*/

    public void handleAfterDelete(List<AccountContactRelation> lstDeletedACR){
        System.debug('START handleAfterDelete');
        List<Id> lstContactId = new List<Id>();
        for(AccountContactRelation relation : lstDeletedACR){
            lstContactId.add(relation.ContactId);
        }
        AP62_DeleteSharing.deleteRequestAccountSharing(lstDeletedACR, lstContactId);
        System.debug('STOP handleAfterDelete');
    }

    /***
    * @description Handler for ACR Before Deletion Event
    * @param       List<AccountContactRelation> listDeletedACR
    * @exception   none special.
    * @author      AMI
    * @date        13/07/2022 
    ***/
    public void handleBeforeDelete(List<AccountContactRelation> listDeletedACR){
        system.debug(LoggingLevel.DEBUG, 'START AccountContactRelationTriggerHandler - handleBeforeDelete');
        
        if(PAD.canRun('AP64_PreventACRDeletion')){
            AP64_PreventACRDeletion.preventACRDeletion(listDeletedACR);
        }

        system.debug(LoggingLevel.DEBUG, 'END AccountContactRelationTriggerHandler - handleBeforeDelete');
    }
}