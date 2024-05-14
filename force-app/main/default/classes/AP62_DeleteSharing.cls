/**************************************************************************************
-- - Author        : Telesio
-- - Description   : class to delete the Request Sharing existing
--
-- Maintenance History:
--
-- Date          Name  Version  Remarks
-- -----------   ----  -------  -------------------------------------------------------
-- 30-MARCH-2022  RRA   1.0      Initial version
--------------------------------------------------------------------------------------
**************************************************************************************/
public without sharing class AP62_DeleteSharing {
        public static void deleteRequestAccountSharing(List<AccountContactRelation> lstACRDeleted, List<Id> lstContactIds){

            System.debug('DeletSharingRequestACR___lstACRDeleted= ' + lstACRDeleted);
            System.debug('DeletSharingRequestACR___lstContactIds= ' + lstContactIds);
            List<Id> lstPCCId = new List<Id>();
            List<Id> lstBrokerId = new List<Id>();
            List<Id> lstReinsurerId = new List<Id>();
            List<String> lstMacrolobOld= new List<String> ();
            List<String> lstNatureOld= new List<String> ();
            List<Request__Share> lstReqShare = new List<Request__Share>();
            List<AccountShare> lstAccShare = new List<AccountShare>();
            Set<Id> setUserId = new Set<Id>();
            Map<Id, Contact> mapContactById = new Map<Id, Contact>();
            Map<Id, Id> mapUserByContactId = new Map<Id, Id>();
            List<String> lstPCCIdOld= new List<String> ();
            List<String> lstBrokerIdOld= new List<String> ();
            List<String> lstReinsurerIdOld= new List<String> ();
            List<IntermediateACRRequest__c> lstIntObject = new List<IntermediateACRRequest__c>();

            for(Contact contact : [SELECT Id, Name, MacroLoB__c, toLabel(Nature__c), RecordType.DeveloperName FROM Contact WHERE Id IN :lstContactIds AND RecordType.DeveloperName = 'Broker_Reinsurer']){
                mapContactById.put(contact.Id, contact);
            }
    
            for(User user : [SELECT Id, ContactId FROM User WHERE ContactId IN :mapContactById.keySet() AND isActive = true]){ 
                //mapUserByContactId.put(user.ContactId, user.Id);
                setUserId.add(user.Id);
            }

            String queryRequestSharing = 'SELECT Id, UserOrGroupId, Parent.Program__r.PrincipalCedingCompany__c FROM Request__Share WHERE UserOrGroupId IN:setUserId ';
            String queryAccountSharing = 'SELECT Id, UserOrGroupId, AccountId FROM AccountShare WHERE UserOrGroupId IN:setUserId AND OpportunityAccessLevel = \'Read\' ';
            String queryIntObject =  ' SELECT Id, PCC__c, Reinsurer__c, Nature__c, Macrolob__c, SharingRequestKey__c, User__c, Broker__c FROM IntermediateACRRequest__c WHERE User__c IN: setUserId ';


            System.debug('DeletSharingRequestACR___setUserId= ' + setUserId);
            for (AccountContactRelation acr : lstACRDeleted){
                String acc = acr.Tech_AccountName__c;
                String lastStrAcc= acc.right(3);
                if (lastStrAcc == '(P)'){
                    lstPCCId.add(acr.AccountId);
                }
                if (lastStrAcc == '(B)'){
                    lstBrokerId.add(acr.AccountId);
                }
                if (lastStrAcc == '(R)') {
                    lstReinsurerId.add(acr.AccountId);
                }

                //lstMacrolobOld.add(acr.Contact.MacroLoB__c);
                //lstNatureOld.add(acr.Contact.Nature__c);
            }

       
    
            System.debug('DeleteRecordIntOjFromContact___query = ' + queryIntObject);
    
            System.debug('DeletSharingRequestACR___lstPCCIdDeleted= ' + lstPCCId);

            if (lstPCCId !=null && !lstPCCId.isEmpty()){
                queryRequestSharing = queryRequestSharing + ' AND Parent.Program__r.PrincipalCedingCompany__c IN: lstPCCId';
                queryAccountSharing = queryAccountSharing + ' AND AccountId IN: lstPCCId';
                queryIntObject = queryIntObject + '  AND PCC__c IN: lstPCCId';
                lstReqShare = Database.query(queryRequestSharing);
                lstAccShare = Database.query(queryAccountSharing);
                lstIntObject = Database.query(queryIntObject);
            }else if (lstBrokerId !=null && !lstBrokerId.isEmpty()){
                queryRequestSharing = queryRequestSharing + ' AND Parent.Broker__c IN: lstBrokerId';
                queryAccountSharing = queryAccountSharing + ' AND AccountId IN: lstBrokerId';
                queryIntObject = queryIntObject + '  AND Broker__c IN: lstBrokerId';
                lstReqShare = Database.query(queryRequestSharing);
                lstAccShare = Database.query(queryAccountSharing);
                lstIntObject = Database.query(queryIntObject);
            }else if (lstReinsurerId !=null && !lstReinsurerId.isEmpty() || Test.isRunningTest()){
                queryRequestSharing = queryRequestSharing + ' AND Parent.Reinsurer__c IN: lstReinsurerId';
                queryAccountSharing = queryAccountSharing + ' AND AccountId IN: lstReinsurerId';
                queryIntObject = queryIntObject + '  AND Reinsurer__c IN: lstReinsurerId';
                lstReqShare = Database.query(queryRequestSharing);
                lstAccShare = Database.query(queryAccountSharing);
                lstIntObject = Database.query(queryIntObject);
            }

            System.debug('DeletSharingRequestACR___queryRequestSharing= ' + queryRequestSharing);
            System.debug('DeletSharingRequestACR___queryAccountSharing= ' + queryAccountSharing);

            System.debug('DeletSharingRequestACR___lstReqShare= ' + lstReqShare);


            if (lstReqShare.size() > 0 ){
                delete lstReqShare;
            }

            System.debug('DeletSharingRequestACR___lstAccShare= ' + lstAccShare);
           
            if (lstAccShare.size() > 0 ){
                delete lstAccShare;
            }

            System.debug('DeletSharingRequestACR___lstIntObject= ' + lstIntObject);

            if (lstIntObject.size() > 0 ){
                delete lstIntObject;
            }

            System.debug('DeletSharingRequestACR__DeletedRequestShare =  ' + lstReqShare.size() + ' Done successfully');
            System.debug('DeletSharingRequestACR_DeletedlstAccShare =  ' + lstAccShare.size() + ' Done successfully');
            System.debug('DeletSharingRequestACR_DeletedlstIntObject =  ' + lstIntObject.size() + ' Done successfully');

           
        }


        /*public static void deleteRequestAccountSharingAfterUpdateACRCont(List<AccountContactRelation> lstACRDeletedOld, List<Id> lstContactIdOld, Set<String> setMacrolobOld, List<String> lstNatureOld){
            System.debug('DeletSharingRequestContact___lstACRDeletedOld= ' + lstACRDeletedOld);
            System.debug('DeletSharingRequestContact___lstContactIdOld= ' + lstContactIdOld);
            System.debug('DeletSharingRequestContact___setMacrolobOld= ' + setMacrolobOld);
            System.debug('DeletSharingRequestContact___lstNature= ' + lstNatureOld);

            List<Id> lstPCCIdDeleted = new List<Id>();
            Set<Id> setUserId = new Set<Id>();
            Map<Id, Contact> mapContactById = new Map<Id, Contact>();
            Map<Id, Id> mapUserByContactId = new Map<Id, Id>();
            Set<String> setKeys = new Set<String>();
            Id rtPccId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PrincipalCedingCompany').getRecordTypeId();

            if (lstACRDeletedOld !=null && !lstACRDeletedOld.isEmpty()){
                for(AccountContactRelation relationToDelete : lstACRDeletedOld){
                    if (relationToDelete.Account.RecordTypeId == rtPccId){
                        lstPCCIdDeleted.add(relationToDelete.AccountId);
                    }
                }
            }else{
                for(AccountContactRelation relationToDelete : [SELECT Id, toLabel(Contact.Nature__c), Contact.MacroLoB__c, Contact.AccountId, AccountId, Account.RecordTypeId, ContactId, Roles FROM AccountContactRelation WHERE ContactId IN :lstContactIdOld 
                                        AND IsActive = TRUE 
                                        AND Contact.MacroLoB__c != null
                                        AND Contact.Nature__c != null  ]){
                    if (relationToDelete.Account.RecordTypeId == rtPccId){
                        lstPCCIdDeleted.add(relationToDelete.AccountId);
                    }
                }
            }
            
            System.debug('DeletSharingRequestContact___lstPCCIdDeleted= ' + lstPCCIdDeleted);

            for(Contact contact : [SELECT Id, Name, MacroLoB__c, toLabel(Nature__c), RecordType.DeveloperName FROM Contact WHERE Id IN :lstContactIdOld  AND RecordType.DeveloperName = 'Broker_Reinsurer']){
                mapContactById.put(contact.Id, contact);
            }
    
            for(User user : [SELECT Id, ContactId FROM User WHERE ContactId IN :mapContactById.keySet() AND isActive = true]){ 
                setUserId.add(user.Id);
            }

            System.debug('DeletSharingRequestContact___setUserId= ' + setUserId);
            
            for (IntermediateACRRequest__c intACRReq : [SELECT Id, PCC__c, User__c, SharingKeyFormula__c, Macrolob__c, Nature__c FROM IntermediateACRRequest__c WHERE PCC__c IN:lstPCCIdDeleted AND User__c IN: setUserId ]){
                //System.debug('DeletSharingRequestContact___intACRReq.Macrolob__c= ' + intACRReq.Macrolob__c);
                if (setMacrolobOld !=null && !setMacrolobOld.isEmpty()){
                    for (String macro : setMacrolobOld){
                        if ((macro.contains(intACRReq.Macrolob__c) || macro == intACRReq.Macrolob__c)){
                            setKeys.add(intACRReq.SharingKeyFormula__c);
                        }
                    }
                }

                if (lstNatureOld !=null && !lstNatureOld.isEmpty()){
                    for (String nature : lstNatureOld){
                        if ((nature.contains(intACRReq.Nature__c) || nature == intACRReq.Nature__c)){
                            setKeys.add(intACRReq.SharingKeyFormula__c);
                        }
                    }
                }
            }


            System.debug('DeletSharingRequestContact___setKeys= ' + setKeys);

            List<Request__Share> lstReqShar = [SELECT Id, UserOrGroupId, Parent.KeyRequestSharing__c FROM Request__Share WHERE UserOrGroupId IN:setUserId AND Parent.KeyRequestSharing__c IN:setKeys AND Parent.OriginalRequest__c = null];

            System.debug('DeletSharingRequestContact___lstReqShar= ' + lstReqShar);

            if (lstReqShar.size() > 0 ){
                delete lstReqShar;
            } 
        }*/
    }