public without sharing class ContactTriggerHandler {
    /**************************************************************************************
    -- - Author        : Spoon Consulting
    -- - Description   : Handler for trigger on Contact
    --
    -- Maintenance History:
    --
    -- Date         Name  Version  Remarks
    -- -----------  ----  -------  -------------------------------------------------------
    -- 16-JUN-2020  MBE   1.0      Initial version
    -- 27-SEP-2021  MBE   1.1      W-1031 - Error Account&Contact Relation
    -- 13-JUL-2021  AMI   2.0      CRM360 Lot1 - added validators before using split function to
    --                             avoid "System.NullPointerException"
    --------------------------------------------------------------------------------------
    **************************************************************************************/
    
        public ContactTriggerHandler() {}
    
        public void handleAfterUpdate(List<Contact> lstOldContacts, List<Contact> lstNewContacts){
            List<Id> lstContactId = new List<Id>();
            Id idCon;
            List<Id> lstContactIdOld = new List<Id>();
            Set<String> setKeysWithUserId = new  Set<String>();
            Set<String> setKeysWithUserIdOld = new  Set<String>();
            List<String> lstMacrolobOld = new List<String>();
            List<String> lstMacrolobNew = new List<String>();
            List<String> lstNatureOld = new List<String>();
            List<String> lstOldMacroToDelete= new List<String>();
            List<String> lstMacrolobOldd = new List<String>();
            List<String> lstMacrolobNeww = new List<String>();
            Set<String> setMacroOld = new Set<String>();
            Set<String> setMacroNew = new Set<String>();
            List<String> lstMacroNew = new List<String>();
            Boolean isMacrolobChanged = false;
            Boolean isNatureChanged =false;
            Boolean isIdAccChanged =false;
            Set<String> setMacrolobLifeOld = new Set<String>();
            Set<String> setMacrolobPCOld = new Set<String>();
            Map<String,List<String>> mapDependentPicklistValuesMap  = new  Map<String,List<String>>();
            String naturePC;
            String natureLife;
            Set<Id> setIdUser = new Set<Id> ();
    
            List<String> lstNaturePC;
            List<String> lstNatureLife;
    
            //Id rtPccId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PrincipalCedingCompany').getRecordTypeId();
            for(Integer i = 0; i < lstNewContacts.size(); i++) {
                if(PAD.canRun('AP36_CreateSharingForContact')){
                    if(lstOldContacts[i].MacroLoB__c != lstNewContacts[i].MacroLoB__c){
                        lstContactId.add(lstNewContacts[i].Id);
                        lstContactIdOld.add(lstOldContacts[i].Id);
                        lstMacrolobOld.add(lstOldContacts[i].Macrolob__c);
                        lstMacrolobNew.add(lstNewContacts[i].Macrolob__c);
                        isMacrolobChanged = true;
                    }
                     if(lstOldContacts[i].Nature__c != lstNewContacts[i].Nature__c){
                        lstContactId.add(lstNewContacts[i].Id);
                        lstContactIdOld.add(lstOldContacts[i].Id);
                        lstNatureOld.add(lstOldContacts[i].LabelNature__c);
                        isNatureChanged = true;
                    }
    
                    if(lstOldContacts[i].AccountId != lstNewContacts[i].AccountId){
                        lstContactId.add(lstNewContacts[i].Id);
                        lstContactIdOld.add(lstOldContacts[i].Id);

                        for(Id conId : lstContactId){
                            idCon = conId;
                        }
                        isIdAccChanged = true;
                    }
                }
            }

            
    
            System.debug('ContactAfterUpdate___lstContactIdOld= ' + lstContactIdOld);
            System.debug('ContactAfterUpdate___lstContactId= ' + lstContactId);
            System.debug('ContactAfterUpdate___lstMacrolobOld= ' + lstMacrolobOld);
    
    
           
            //if (lstNatureOld[0] == 'Life' || lstNatureOld[0] == 'P&C'){
                for (String macroOld : lstMacrolobOld){
                    //AMI 13/07/22: added validators before using split function to avoid "System.NullPointerException"
                    if(string.isNotEmpty(macroOld)){
                        lstMacrolobOldd = macroOld.Split(';');
                    }
                }
        
                for (String macroNew : lstMacrolobNew){
                    //AMI 13/07/22: added validators before using split function to avoid "System.NullPointerException"
                    if(string.isNotEmpty(macroNew)){
                        lstMacrolobNeww = macroNew.Split(';');
                    }
                }
        
                System.debug('ContactAfterUpdate___lstMacrolobOldd= ' + lstMacrolobOldd);
                System.debug('ContactAfterUpdate___lstMacrolobNeww= ' + lstMacrolobNeww);
    
        
                // Check if Old value macrolob  do not exist in the list of new value macrolob
                for(String mo : lstMacrolobOldd){
                    if(!lstMacrolobNeww.contains(mo) ){
                        setMacroOld.add(mo);
                    }
                }
        
                System.debug('ContactAfterUpdate___setMacroOld= ' + setMacroOld);
                // Check if New value macrolob  do not exist in the list of Old value macrolob
                for(String mn : lstMacrolobNeww){
                    //if(!lstMacrolobOldd.contains(mn) ){
                        setMacroNew.add(mn);
                    //}
                }
        
                System.debug('ContactAfterUpdate___setMacroNew= ' + setMacroNew);
                System.debug('ContactAfterUpdate___isMacrolobChanged= ' + isMacrolobChanged);
                System.debug('ContactAfterUpdate___isNatureChanged= ' + isNatureChanged);
                System.debug('ContactAfterUpdate___lstNatureOld= ' + lstNatureOld);
                //System.debug('ContactAfterUpdate___lstNewMacroToDeletelstMacroNew= ' + lstMacroNew);-
                

               // if ( lstNatureOld[0] != null && (lstNatureOld[0] == 'Life' || lstNatureOld[0] == 'P&C')){
                    if (isMacrolobChanged == true && isNatureChanged == false && lstNatureOld.isEmpty()){
                        System.debug('1');
                        AP61_CreateKeySharingContact.DeleteRecordIntOjRequestShareFromContact(lstContactIdOld, setMacroOld, lstNatureOld, true, false);
                    }else if (isMacrolobChanged == false && isNatureChanged == true && !lstNatureOld.isEmpty() && (lstNatureOld[0] == 'Life' || lstNatureOld[0] == 'P&C')){ 
                        System.debug('2');
                        AP61_CreateKeySharingContact.DeleteRecordIntOjRequestShareFromContact(lstContactIdOld, setMacroOld, lstNatureOld, false, true);
                    }else if (isMacrolobChanged == true && isNatureChanged == true && !lstNatureOld.isEmpty() && (lstNatureOld[0] == 'Life' || lstNatureOld[0] == 'P&C')){
                        System.debug('3');
                        AP61_CreateKeySharingContact.DeleteRecordIntOjRequestShareFromContact(lstContactIdOld, setMacroOld, lstNatureOld, true, true);
                    }else if (isMacrolobChanged == true && isNatureChanged == true && !lstNatureOld.isEmpty() && (lstNatureOld[0] == 'Life' || lstNatureOld[0] == 'P&C')){
                        System.debug('4');
                        AP61_CreateKeySharingContact.DeleteRecordIntOjRequestShareFromContact(lstContactIdOld, setMacroOld, lstNatureOld, true, true);
                    }else if (isMacrolobChanged == false && isNatureChanged == false && isIdAccChanged == true){
                        System.debug('5');
                        AP61_CreateKeySharingContact.DeleteRecordIntOjRequestShareFromContact(lstContactIdOld, setMacroOld, lstNatureOld, true, true);
                    }else if (!lstNatureOld.isEmpty() && lstNatureOld[0] == 'P&C + Life' && isNatureChanged == true){
                        System.debug('6');
                        System.debug('ContactAfterUpdate___P&C + Life');
                        List<IntermediateACRRequest__c> lstIntObj = [SELECT Id, Contact__c, Macrolob__c FROM IntermediateACRRequest__c WHERE Contact__c IN:lstContactIdOld AND Macrolob__c IN:setMacroOld];
        
                        for(User user : [SELECT Id, ContactId FROM User WHERE ContactId IN :lstContactIdOld AND isActive = true]){ 
                            setIdUser.add(user.Id);
                        }
        
                        List<Request__Share> lstReqShare = [SELECT Id, UserOrGroupId,Parent.Program__r.Macro_L_O_B__c FROM Request__Share WHERE UserOrGroupId IN:setIdUser AND Parent.Program__r.Macro_L_O_B__c IN:setMacroOld];

                        System.debug('ContactAfterUpdate___lstIntObj = ' + lstIntObj);
                        System.debug('ContactAfterUpdate___lstReqShare = ' + lstReqShare);
        
                        if (lstIntObj !=null && !lstIntObj.isEmpty()){ delete lstIntObj; } 
        
                        
                        if (lstReqShare !=null && !lstReqShare.isEmpty()){ delete lstReqShare; } 
                }
        
                    if(PAD.canRun('AP61_CreateUpdateKeySharingContact') && lstContactId.size() > 0){
                        setKeysWithUserId = AP61_CreateKeySharingContact.createKeyElligibleForSharingContact(lstContactId, false, true, setMacroNew);
                    }
        
                    System.debug('ContactAfterUpdate___setKeysWithUserId= ' + setKeysWithUserId);
        
                    // Create Sharing Request if macrolob and/or Nature are changed
                        if(setKeysWithUserId.size() > 0 && PAD.canRun('AP36_CreateSharingForContact') && lstContactId.size() > 0){
                            AP36_CreateSharingForContact.createSharingForContact(setKeysWithUserId, lstContactId, null);
                        }

                    // Create Sharing Request if company name is Changed
                    if (isIdAccChanged == true && lstContactId.size() > 0){
                        LWC56_SynchronizeIntermediateObj.asyncDeleteAndRecalculateSharingKeys(idCon);
                    }
    
                    if(PAD.canRun('AP62_DeleteSharing') && lstContactIdOld.size() > 0){
                        //AP62_DeleteSharing.deleteRequestAccountSharingAfterUpdateACRCont(null, lstContactIdOld, setMacroOld, lstNatureOld);
                    }
        }
    
        /*public void handleAfterInsert(List<Contact> lstNewContacts){
            System.debug('START handleAfterInsert');
            List<Id> lstContactId = new List<Id>();
            Set<String> setMacroLob = new Set<String>();
            Set<String> setNature = new Set<String>();
            Set<String> setKeysWithUserId;
            for(Integer i = 0; i < lstNewContacts.size(); i++) {
                lstContactId.add(lstNewContacts[i].Id);
                setMacroLob.add(lstNewContacts[i].MacroLoB__c);
                setNature.add(lstNewContacts[i].LabelNature__c);
            }
    
            if(PAD.canRun('AP61_CreateUpdateKeySharingContact') && lstContactId.size() > 0){
                setKeysWithUserId = AP61_CreateKeySharingContact.createKeyElligibleForSharingContact(lstContactId, true,false, setMacroLob);
            }
    
            System.debug('ACRAfterInsert___setKeysWithUserId= ' + setKeysWithUserId);
    
            if(setKeysWithUserId.size() > 0 && PAD.canRun('AP36_CreateSharingForContact') && lstContactId.size() > 0){
                AP36_CreateSharingForContact.createSharingForContact(setKeysWithUserId);
            }
            System.debug('STOP handleAfterInsert');
        }*/
    
        // public ContactTriggerHandler() {}
    
        // public void handleAfterUpdate(List<Contact> lstOldContacts, List<Contact> lstNewContacts){
        //     List<Contact> lstContacts = new List<Contact>();
    
        //     for(Integer i = 0; i < lstNewContacts.size(); i++) {
        //         if(PAD.canRun('AP36_CreateSharingForContact')){
        //             if(lstOldContacts[i].MacroLoB__c != lstNewContacts[i].MacroLoB__c){
        //                 lstContacts.add(lstNewContacts[i]);
        //             }
        //             else if(lstOldContacts[i].Nature__c != lstNewContacts[i].Nature__c){
        //                 lstContacts.add(lstNewContacts[i]);
        //             }
        //         }
        //     }
    
        //     if(PAD.canRun('AP36_CreateSharingForContact') && lstContacts.size() > 0){
        //         AP36_CreateSharingForContact.createSharingForContact(lstContacts);
        //     }
        // }
    
    }