public with sharing class UserTriggerHandler {
    /**************************************************************************************
    -- - Author        : Spoon Consulting
    -- - Description   : handler for trigger on User
    --
    -- Maintenance History:
    --
    -- Date         Name  Version  Remarks
    -- -----------  ----  -------  -------------------------------------------------------
    -- 02-SEP-2020  MBE   1.0      Initial version
    -- 12-NOV-2021  MBE   1.1      W-1038 - réassureurs qui ne voient pas l'historique des années précédantes - Add handleAfterUpdate
    -- 08-DEC-2021  MBE   1.2      W-1038 - réassureurs qui ne voient pas l'historique des années précédantes 
    --------------------------------------------------------------------------------------
    **************************************************************************************/
        public UserTriggerHandler(){}
    
        public void handleAfterInsert(List<User> lstNewUser){
            List<Id> lstContactId = new List<Id>();
            List<Contact> lstContact = new List<Contact>();
            Set<String> setKeysWithUserId = new  Set<String>();
            map<String, Id> mapAccNameId = new map<String, Id>();
            List<Id> lstAccGetPccId = new List<Id>();
    
            List<User> lstUser = [SELECT Id, ProfileId, Profile.Name, ContactId FROM User WHERE Id IN :lstNewUser];
    
            for(User user : lstUser){
                if(user.Profile.Name == 'AGRE_Community External User'){
                    lstContactId.add(user.ContactId);
                }
            }

            // Check if pcc exists on ACR when create contact 
            if (lstContactId != null){
                for (AccountContactRelation acc :  [SELECT Id, Account.Name, ContactId, AccountId FROM AccountContactRelation WHERE ContactId IN :lstContactId]){
                    mapAccNameId.put(acc.Account.Name, acc.AccountId);
                }
                System.debug('mapAccNameId = ' + mapAccNameId);
                for (String strAcc : mapAccNameId.keySet()){
                    if (strAcc.contains('(P)') && (strAcc != null || strAcc=='')){
                        lstAccGetPccId.add(mapAccNameId.get(strAcc));
                    }
                }
            }
            System.debug('lstAccGetPccId = ' + lstAccGetPccId);
            System.debug('lstAccGetPccId = ' + lstAccGetPccId);


            /*if(PAD.canRun('AP44_CreateSharingForUser') && lstContactId.size() > 0){
                AP44_CreateSharingForUser.createSharingForUser(lstContactId);
            }*/
    
            if(PAD.canRun('AP61_CreateUpdateKeySharingContact') && lstContactId.size() > 0){
                AP61_CreateKeySharingContact.getCalculateKeysForUserOnly(lstContactId, true, false, null, lstAccGetPccId);
            }
        }
    
        public void handleAfterUpdate(List<User> lstOldUser, List<User> lstNewUser){
            List<User> lstUser = new List<User>();
            List<Id> lstContactId = new List<Id>();
            List<Contact> lstContact = new List<Contact>();
            Set<String> setKeysWithUserId = new  Set<String>();
            map<String, Id> mapAccNameId = new map<String, Id>();
            List<Id> lstAccGetPccId = new List<Id>();
    
            for(Integer i = 0; i < lstNewUser.size(); i++) {
                if(PAD.canRun('AP61_CreateUpdateKeySharingContact')){
                    if(lstOldUser[i].IsActive != lstNewUser[i].IsActive && lstNewUser[i].IsActive == true){
                        lstUser.add(lstNewUser[i]);
                    }
                }
            }
            System.debug('lstUser = ' + lstUser);
            if(lstUser.size() > 0){
                List<User> lstAllUser = [SELECT Id, ProfileId, Profile.Name, ContactId FROM User WHERE Id IN :lstUser];
    
                for(User user : lstAllUser){
                    if(user.Profile.Name == 'AGRE_Community External User'){
                        lstContactId.add(user.ContactId);
                    }
                }
            }
            System.debug('lstContactId = ' + lstContactId);
            
               // Check if pcc exists on ACR when create contact 
             if (lstContactId != null){
                for (AccountContactRelation acc :  [SELECT Id, Account.Name, ContactId, AccountId FROM AccountContactRelation WHERE ContactId IN :lstContactId]){
                    mapAccNameId.put(acc.Account.Name, acc.AccountId);
                }
                System.debug('mapAccNameId = ' + mapAccNameId);
                for (String strAcc : mapAccNameId.keySet()){
                    if (strAcc.contains('(P)') && (strAcc != null || strAcc=='')){
                        lstAccGetPccId.add(mapAccNameId.get(strAcc));
                    }
                }
            }
            System.debug('lstAccGetPccId = ' + lstAccGetPccId);
    
             /*if(PAD.canRun('AP44_CreateSharingForUser') && lstContactId.size() > 0){
                AP44_CreateSharingForUser.createSharingForUser(lstContactId);
            }*/
    
            if(PAD.canRun('AP61_CreateUpdateKeySharingContact') && lstContactId.size() > 0){
                AP61_CreateKeySharingContact.getCalculateKeysForUserOnly(lstContactId, true, false, null, lstAccGetPccId);
                
            }
        }
    }