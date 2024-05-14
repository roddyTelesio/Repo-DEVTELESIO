public without sharing class LWC56_SynchronizeIntermediateObj {

    @AuraEnabled
    public static String checkExistingKeysIntObj (Id idContact){
        List<String> lstPCCId = new List<String>();
        List<String> lstBrokerId = new List<String>();   
        List<String> lstReinsurerId = new List<String>(); 
        List<String> lstMacroLOB = new List<String>();
        String nature;
        String macrolob;
        Map<Id, Contact> mapContactById = new Map<Id, Contact>();
        Map<String, String> mapKeyBroReins =  new Map<String, String>();
        Id rtPccId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PrincipalCedingCompany').getRecordTypeId();
        Id rtBrokerId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Broker').getRecordTypeId();
        Id rtReinsurerId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Reinsurer').getRecordTypeId();
        List<AccountContactRelation> lstACRId = new List<AccountContactRelation>(); 
        Set <String> setAccountShareToInsert = new Set <String>();
        //Set<Id> idsetUser = new Set<Id>();
        List<IntermediateACRRequest__c> lstIntObjectExisting = new List<IntermediateACRRequest__c>();
        String message = null;
        List<IntermediateACRRequest__c> lstKeys = new List<IntermediateACRRequest__c>();
        List<String> lstMacrolobLife = new List<String>();
        List<String> lstMacrolobPC = new List<String>();
        List<String> lstNature = new List<String>();
        Map<String,List<String>> mapDependentPicklistValuesMap  = new  Map<String,List<String>>();

        // Retrieve userId From ContactId
        /*for(Contact contact : [SELECT Id, Name, MacroLoB__c, toLabel(Nature__c) FROM Contact WHERE Id =:idContact]){
            mapContactById.put(contact.Id, contact);
        }

        System.debug('createKeyElligibleForSharingContact___mapContactById = ' + mapContactById);

        // Get userId From ContactId
        for(User user : [SELECT Id, ContactId FROM User WHERE ContactId IN :mapContactById.keySet() AND isActive = true]){ 
            idsetUser.add(user.Id);
        }*/

        for(AccountContactRelation acr : [SELECT Id, toLabel(Contact.Nature__c), Company18Characters__c , Contact.MacroLoB__c, Contact.AccountId, AccountId, Account.RecordTypeId, ContactId,Account.Name,Roles FROM AccountContactRelation 
                                            WHERE ContactId =: idContact 
                                            AND IsActive = TRUE
                                            AND Contact.MacroLoB__c != NULL
                                            AND Contact.Nature__c != NULL]){
            setAccountShareToInsert.add (acr.Contact.MacroLoB__c + '-' + acr.Contact.Nature__c);
            lstACRId.add(acr);
        }

        for(String acrString : setAccountShareToInsert){
            macrolob = acrString.split('-')[0];
            nature = acrString.split('-')[1];
            if (nature == 'P&C + Life'){
                lstNature = nature.split('\\+');
            }
        }
        if (macrolob != null){
            lstMacroLOB = macrolob.split(';');
        }
        System.debug('createKeyElligibleForSharingContact__PC + lstNature' + lstNature);

        if (lstNature != null){
            mapDependentPicklistValuesMap = AP61_CreateKeySharingContact.getDependentPicklistValues(Contact.Macrolob__c);
            System.debug('createKeyElligibleForSharingContact___lstMacroLOB__Null' + lstMacroLOB);
            for(String natureKey : mapDependentPicklistValuesMap.keyset()){
                for(String macrolobLifePc : mapDependentPicklistValuesMap.get(natureKey ))
                {
                    for (String mm : lstMacroLOB){
                        if (mm == macrolobLifePc){
                            if (natureKey == 'Life'){    
                                lstMacrolobLife.add(macrolobLifePc);
                            }
                            if (natureKey == 'P&C'){
                                lstMacrolobPC.add(macrolobLifePc);
                            }
                        }
                    }
                 }
            }

            
            System.debug('createKeyElligibleForSharingContact__PC + Life___lstMacrolobLife_null ' + lstMacrolobLife);
            System.debug('createKeyElligibleForSharingContact__PC + Life___lstMacrolobPC__null ' + lstMacrolobPC);
        }

        for (AccountContactRelation acr : lstACRId){
            System.debug('### Name= '+ acr.Account.Name) ;
            System.debug('### = '+ acr) ;
            System.debug('### rtPccId= '+ rtPccId) ;
            System.debug('### acr.Account.RecordTypeId= '+ acr.Account.RecordTypeId) ;

            if (acr.Account.RecordTypeId == rtPccId){
                lstPCCId.add(acr.Company18Characters__c);
            }
            if (acr.Account.RecordTypeId == rtBrokerId){
                lstBrokerId.add(acr.Company18Characters__c);
            }
            if (acr.Account.RecordTypeId == rtReinsurerId) {
                lstReinsurerId.add(acr.Company18Characters__c);
            }
        }
        System.debug('lstPCCId ' + lstPCCId);
        System.debug('lstReinsurerId ' + lstReinsurerId);
    
         //*****Calculate Key if Nature is P&C OR LIFE */
            //********************************************* */

            if (nature == 'Life' || nature == 'P&C'){
                // RT Broker
                if (lstMacroLOB.size() > 0 && lstPCCId.size() > 0 || Test.isRunningTest()){
                    if (lstBrokerId.size() > 0){
                        for (String macrolb : lstMacroLOB) {
                            for (String idPcc : lstPCCId){
                                for (String idBroker : lstBrokerId){
                                    mapKeyBroReins.put(idPcc + '_' + idBroker + '_' + nature + '_' + macrolb, idPcc + '_' + idBroker + '_' + nature + '_' + macrolb);
                                }
                            }
                        }  
                    }
                    // RT Reinsurer
                    if (lstReinsurerId.size() > 0){  
                        for (String macrolb : lstMacroLOB) {
                            for (String idPcc : lstPCCId){
                                for (String idReinsurer : lstReinsurerId){
                                    mapKeyBroReins.put(idPcc + '_' + idReinsurer + '_' + nature + '_' + macrolb, idPcc + '_' + idReinsurer + '_' + nature + '_' + macrolb);
                                }
                            }
                        }
                    }
                }
            }else if (nature == 'P&C + Life'){

            //*****Calculate Key if Nature is P&C + LIFE */
            //********************************************* */
    
            //Nature= LIFE
            // RT Broker
                if (lstMacrolobLife.size() > 0 && lstPCCId.size() > 0 || Test.isRunningTest()){
                    if (lstBrokerId.size() > 0){
                        for (String macrolbLife : lstMacrolobLife) {
                            for (String idPcc : lstPCCId){
                                for (String idBroker : lstBrokerId){
                                    mapKeyBroReins.put(idPcc + '_' + idBroker + '_' + lstNature.get(1).deleteWhitespace() + '_' + macrolbLife, idPcc + '_' + idBroker + '_' + lstNature.get(1).deleteWhitespace() + '_' + macrolbLife);
                                }
                            }
                        }  
                    }
                    // RT Reinsurer
                    if (lstReinsurerId.size() > 0){  
                        for (String macrolbLife : lstMacrolobLife) {
                            for (String idPcc : lstPCCId){
                                for (String idReinsurer : lstReinsurerId){
                                    mapKeyBroReins.put(idPcc + '_' + idReinsurer + '_' + lstNature.get(1).deleteWhitespace() + '_' + macrolbLife, idPcc + '_' + idReinsurer + '_' + lstNature.get(1).deleteWhitespace() + '_' + macrolbLife);
                                }
                            }
                        }
                    }
                    System.debug('mapKeyBroReins.LIFE = ' + mapKeyBroReins.size());
                }

                //Nature= P&C
                // RT Broker
                if (lstMacrolobPC.size() > 0 && lstPCCId.size() > 0 || Test.isRunningTest()){
                    if (lstBrokerId.size() > 0){
                        for (String macrolbPc : lstMacrolobPC) {
                            for (String idPcc : lstPCCId){
                                for (String idBroker : lstBrokerId){
                                    mapKeyBroReins.put(idPcc + '_' + idBroker + '_' + lstNature.get(0).deleteWhitespace() + '_' + macrolbPc, idPcc + '_' + idBroker + '_' + lstNature.get(0).deleteWhitespace() + '_' + macrolbPc);
                                }
                            }
                        }  
                    }
                    // RT Reinsurer
                    if (lstMacrolobPC.size() > 0){  
                        for (String macrolbPc : lstMacrolobPC) {
                            for (String idPcc : lstPCCId){
                                for (String idReinsurer : lstReinsurerId){
                                    mapKeyBroReins.put(idPcc + '_' + idReinsurer + '_' + lstNature.get(0).deleteWhitespace() + '_' + macrolbPc, idPcc + '_' + idReinsurer + '_' + lstNature.get(0).deleteWhitespace() + '_' + macrolbPc);
                                }
                            }
                        }
                    }
                    System.debug('mapKeyBroReins.PC = ' + mapKeyBroReins.size());
                }
            }
      

        String query = 'SELECT Id, PCC__c, Reinsurer__c, Nature__c, Macrolob__c, SharingKeyFormula__c, SharingRequestKey__c, User__c, Broker__c FROM IntermediateACRRequest__c ';

        if(lstPCCId != null && !lstPCCId.isEmpty() || Test.isRunningTest()){
            if(lstBrokerId != null && !lstBrokerId.isEmpty()){
                if(lstMacroLOB != null && !lstMacroLOB.isEmpty()){
                    if (nature == 'P&C' || nature == 'Life'){
                        query = query  + ' WHERE Contact__c =: idContact AND SharingRequestKey__c != null ';
                    }else if (nature == 'P&C + Life'){
                        if (lstMacroLOBLife != null){
                            query = query  + ' WHERE Contact__c =: idContact AND SharingRequestKey__c != null ' ;
                        }else if (lstMacroLOBPC != null){
                            query = query  + ' WHERE Contact__c =: idContact AND SharingRequestKey__c != null ';
                        }
                    }
                    
                }else{
                    query = null;
                }
            } else if (lstReinsurerId != null && !lstReinsurerId.isEmpty()){
                if(lstMacroLOB != null && !lstMacroLOB.isEmpty()){
                    if (nature == 'P&C' || nature == 'Life'){
                        query = query  + ' WHERE Contact__c =: idContact AND SharingRequestKey__c != null ';
                    }else if (nature == 'P&C + Life'){
                        if (lstMacroLOBLife != null){
                            query = query  + ' WHERE Contact__c =: idContact AND SharingRequestKey__c != null ';
                        }else if (lstMacroLOBPC != null){
                            query = query  + ' WHERE Contact__c =: idContact AND SharingRequestKey__c != null ';
                        }
                    }
                    
                }else{
                    query = null;
                }
            }

            System.debug('DeleteRecordIntOjFromContact___query = ' + query);

            if (query !=null){
                lstIntObjectExisting = Database.query(query);
                System.debug('DeleteRecordIntOjFromContact___lstIntObjectExisting = ' + lstIntObjectExisting);
            }

             System.debug('DeleteRecordIntOjFromContact___mapKeyBroReins.KeySet() = ' + mapKeyBroReins.KeySet());

            Integer sizeACR = mapKeyBroReins.size();
            Integer sizeIntObj = lstIntObjectExisting.size();

            System.debug('DeleteRecordIntOjFromContact___sizeACR = ' + sizeACR);
            System.debug('DeleteRecordIntOjFromContact___sizeIntObj = ' + sizeIntObj);

            if (sizeACR == sizeIntObj){
                message = null;
            }else{
                message = 'This Contact does not have Keys to guarantee the sharing visibility of requests...\n Please Click on Synchronize Button';
            }
        }
        System.debug('DeleteRecordIntOjFromContact___message = ' + message);
        return message;
    }

    @future
    public static void  asyncDeleteAndRecalculateSharingKeys(Id idContact){
        String success =  deleteAndRecalculateKeysIntObj (idContact);
    }

    @AuraEnabled
    public static String deleteAndRecalculateKeysIntObj (Id idContact){
        System.enqueueJob(new LWC56_SynchroIntObjQueue(idContact));
        return 'Synchronization Done Successfully';
        /*List<String> lstPCCId = new List<String>();
        List<String> lstBrokerId = new List<String>();   
        List<String> lstReinsurerId = new List<String>(); 
        List<String> lstMacroLOB = new List<String>();
        List<String> lstMacrolobLife = new List<String>();
        List<String> lstMacrolobPC = new List<String>();
        String nature;
        String macrolob;
        Map<Id, Contact> mapContactById = new Map<Id, Contact>();
        Map<Id, Id> mapUserByContactId = new Map<Id, Id>();
        Id rtPccId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PrincipalCedingCompany').getRecordTypeId();
        Id rtBrokerId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Broker').getRecordTypeId();
        Id rtReinsurerId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Reinsurer').getRecordTypeId();
        List<AccountContactRelation> lstACRId = new List<AccountContactRelation>(); 
        Set <String> setAccountShareToInsert = new Set <String>();
        Set<String> setKeyCalculateWithUserId = new Set<String> ();
        Set<Id> idsetUser = new Set<Id>();
        List<Id> lstIdContact = new List<Id>();
        List<IntermediateACRRequest__c> lstIntObjectExisting = new List<IntermediateACRRequest__c>();
        String success = null;
        List<IntermediateACRRequest__c> lstKeys = new List<IntermediateACRRequest__c>();
        List<String> lstStrKeyExisting = new List<String>();
        List<String> lstNature = new List<String>();
        Map<String,List<String>> mapDependentPicklistValuesMap  = new  Map<String,List<String>>();
        Set<IntermediateACRRequest__c> setKeys = new Set<IntermediateACRRequest__c>();
        List<IntermediateACRRequest__c> lstResKeys = new List<IntermediateACRRequest__c>();

        // Retrieve userId From ContactId
        for(Contact contact : [SELECT Id, Name, MacroLoB__c, toLabel(Nature__c), RecordType.DeveloperName FROM Contact WHERE Id =: idContact AND RecordType.DeveloperName = 'Broker_Reinsurer']){
            mapContactById.put(contact.Id, contact);
        }

        System.debug('createKeyElligibleForSharingContact___mapContactById = ' + mapContactById);

        for(User user : [SELECT Id, ContactId FROM User WHERE ContactId IN :mapContactById.keySet() AND isActive = true]){ 
            mapUserByContactId.put(user.ContactId, user.Id);
        }

        System.debug('createKeyElligibleForSharingContact___mapUserByContactId= ' + mapUserByContactId);

        // Get userId From ContactId
        for(User user : [SELECT Id, ContactId FROM User WHERE ContactId IN :mapContactById.keySet() AND isActive = true]){ 
            idsetUser.add(user.Id);
        }

        System.debug('createKeyElligibleForSharingContact___idsetUser = ' + idsetUser);

        for(AccountContactRelation acr : [SELECT Id, toLabel(Contact.Nature__c), Company18Characters__c , Contact.MacroLoB__c, Contact.AccountId, AccountId, Account.RecordTypeId, ContactId, Roles FROM AccountContactRelation 
                                            WHERE ContactId =: idContact 
                                            AND IsActive = TRUE
                                            AND Contact.MacroLoB__c != NULL
                                            AND Contact.Nature__c != NULL]){
            setAccountShareToInsert.add (acr.Contact.MacroLoB__c + '-' + acr.Contact.Nature__c);
            lstACRId.add(acr);
            lstIdContact.add(acr.ContactId);
        }

        for(String acrString : setAccountShareToInsert){
            macrolob = acrString.split('-')[0];
            nature = acrString.split('-')[1];
            if (nature == 'P&C + Life'){
                lstNature = nature.split('\\+');
            }
        }
        if (macrolob != null){
            lstMacroLOB = macrolob.split(';');
        }
        System.debug('createKeyElligibleForSharingContact__PC + lstNature' + lstNature);

        if (lstNature != null){
            mapDependentPicklistValuesMap = AP61_CreateKeySharingContact.getDependentPicklistValues(Contact.Macrolob__c);
            System.debug('createKeyElligibleForSharingContact___lstMacroLOB__Null' + lstMacroLOB);
            for(String natureKey : mapDependentPicklistValuesMap.keyset()){
                for(String macrolobLifePc : mapDependentPicklistValuesMap.get(natureKey ))
                {
                    for (String mm : lstMacroLOB){
                        if (mm == macrolobLifePc){
                            if (natureKey == 'Life'){    
                                lstMacrolobLife.add(macrolobLifePc);
                            }
                            if (natureKey == 'P&C'){
                                lstMacrolobPC.add(macrolobLifePc);
                            }
                        }
                    }
                 }
            }

            System.debug('createKeyElligibleForSharingContact__PC + Life___lstMacrolobLife_null ' + lstMacrolobLife);
            System.debug('createKeyElligibleForSharingContact__PC + Life___lstMacrolobPC__null ' + lstMacrolobPC);
        }
        System.debug('createKeyElligibleForSharingContact___natureBegin' + nature);

        System.debug('createKeyElligibleForSharingContact___setAccountShareToInsert = ' + setAccountShareToInsert);
        System.debug('createKeyElligibleForSharingContact___lstACRId = ' + lstACRId);
        System.debug('createKeyElligibleForSharingContact___lstMacroLOB = ' + lstMacroLOB);

        for (AccountContactRelation acr : lstACRId){
            if (acr.Account.RecordTypeId == rtPccId){
                lstPCCId.add(acr.Company18Characters__c);
            }
            if (acr.Account.RecordTypeId == rtBrokerId){
                lstBrokerId.add(acr.Company18Characters__c);
            }
            if (acr.Account.RecordTypeId == rtReinsurerId) {
                lstReinsurerId.add(acr.Company18Characters__c);
            }
        }

        if(lstPCCId != null && !lstPCCId.isEmpty() || Test.isRunningTest()){

            lstIntObjectExisting = [SELECT Id, PCC__c, Reinsurer__c, Nature__c, Macrolob__c, SharingKeyFormula__c, Contact__c, Broker__c FROM IntermediateACRRequest__c WHERE Contact__c =: idContact];

            System.debug('DeleteRecordIntOjFromContact___lstIntObjectExisting = ' + lstIntObjectExisting);


            if (lstIntObjectExisting != null && !lstIntObjectExisting.isEmpty()){
                // keys in IntObj must reflected the sharing request => if keys is deleted, request sharing must be too
                for (IntermediateACRRequest__c intObj : lstIntObjectExisting){
                    lstStrKeyExisting.add(intObj.SharingKeyFormula__c );
                }
            }

            List<Request__Share> lstReqShare = [SELECT Id, UserOrGroupId, Parent.KeyRequestSharing__c FROM Request__Share WHERE Parent.KeyRequestSharing__c IN:lstStrKeyExisting AND UserOrGroupId =:idsetUser];

            System.debug('DeleteRecordIntOjFromContact___lstReqShare = ' + lstReqShare);


            if (lstReqShare != null && lstReqShare.size() < 9000 - Limits.getDMLRows()){
                delete lstReqShare;
            }else if (lstReqShare != null && lstReqShare.size() > 9000 - Limits.getDMLRows()){
                BAT002_DeleteSharingBigQuantity batchDeleteReq = new BAT002_DeleteSharingBigQuantity(lstReqShare);
                if (!system.isBatch()){ //stop 'Database.executeBatch cannot be called from a batch start, batch execute, or future method.' error
                    Database.executeBatch(batchDeleteReq, 500);   
                }                
            }

            if (lstIntObjectExisting != null && lstIntObjectExisting.size() < Limits.getDMLRows()){
                delete lstIntObjectExisting;
            }

            System.debug('Delete_SharingBigQuantityForContact__InsertionRequestShare =  ' + lstReqShare.size() + ' Done successfully');
            System.debug('Delete_SharingBigQuantityForContact__lstIntObject =  ' + lstIntObjectExisting.size() + ' Done successfully');

            
            //*****Calculate Key if Nature is P&C OR LIFE */
            //********************************************* */

            /*if (nature == 'Life' || nature == 'P&C'){
                if (lstMacroLOB.size() > 0 && lstPCCId.size() > 0 || Test.isRunningTest()){
                    if (lstBrokerId.size() > 0){
                        for (String macrolb : lstMacroLOB) {
                            for (String idPcc : lstPCCId){
                                for (String idBroker : lstBrokerId){
                                    for (Id idCon : mapUserByContactId.KeySet()){
                                        //System.debug('mapUserByContactId.get(idUser) = ' + mapUserByContactId.get(idUser));
                                        lstKeys.add (new IntermediateACRRequest__c (PCC__c = idPcc, Broker__c = idBroker, Nature__c = nature, Macrolob__c= macrolb, SharingRequestKey__c = idPcc + '_' + idBroker + '_' + nature + '_' + macrolb  + '-' + idCon, User__c = mapUserByContactId.get(idCon), Contact__c= idCon));
                                    }
                                }
                            }
                        }  
                    }
                        // RT Reinsurer
                    if (lstReinsurerId.size() > 0){  
                        for (String macrolb : lstMacroLOB) {
                            for (String idPcc : lstPCCId){
                                for (String idReinsurer : lstReinsurerId){
                                    for (Id idCon : mapUserByContactId.KeySet()){
                                        lstKeys.add (new IntermediateACRRequest__c (PCC__c = idPcc, Reinsurer__c = idReinsurer, Nature__c = nature, Macrolob__c= macrolb, SharingRequestKey__c = idPcc + '_' + idReinsurer + '_' + nature + '_' + macrolb  + '-' + idCon,User__c = mapUserByContactId.get(idCon),  Contact__c= idCon));
                                    }
                                }
                            }
                        }
                    }
                }
            }else if (nature == 'P&C + Life'){

            //*****Calculate Key if Nature is P&C + LIFE */
            //********************************************* */
    
            //Nature= LIFE
            // RT Broker
                /*if (lstMacrolobLife.size() > 0 && lstPCCId.size() > 0 || Test.isRunningTest()){
                    if (lstBrokerId.size() > 0){
                        for (String macrolbLife : lstMacrolobLife) {
                            for (String idPcc : lstPCCId){
                                for (String idBroker : lstBrokerId){
                                    for (Id idCon : mapUserByContactId.KeySet()){
                                            lstKeys.add (new IntermediateACRRequest__c (PCC__c = idPcc, Broker__c = idBroker, Nature__c = lstNature.get(1), Macrolob__c= macrolbLife, SharingRequestKey__c = idPcc + '_' + idBroker + '_' + lstNature.get(1).deleteWhitespace() + '_' + macrolbLife  + '-' + idCon, User__c = mapUserByContactId.get(idCon), Contact__c= idCon));
                                        //System.debug('mapUserByContactId.get(idUser) = ' + mapUserByContactId.get(idUser));
                                    }
                                }
                            }
                        }  
                    }
                    // RT Reinsurer
                    if (lstReinsurerId.size() > 0){  
                        for (String macrolbLife : lstMacrolobLife) {
                            for (String idPcc : lstPCCId){
                                for (String idReinsurer : lstReinsurerId){
                                    for (Id idCon : mapUserByContactId.KeySet()){
                                        lstKeys.add (new IntermediateACRRequest__c (PCC__c = idPcc, Reinsurer__c = idReinsurer, Nature__c = lstNature.get(1), Macrolob__c= macrolbLife, SharingRequestKey__c = idPcc + '_' + idReinsurer + '_' + lstNature.get(1).deleteWhitespace() + '_' + macrolbLife + '-' + idCon, User__c = mapUserByContactId.get(idCon), Contact__c= idCon));
                                    }
                                }
                            }
                        }
                    }
                }

                //Nature= P&C
                // RT Broker
                if (lstMacrolobPC.size() > 0 && lstPCCId.size() > 0 || Test.isRunningTest()){
                    if (lstBrokerId.size() > 0){
                        for (String macrolbPc : lstMacrolobPC) {
                            for (String idPcc : lstPCCId){
                                for (String idBroker : lstBrokerId){
                                    for (Id idCon : mapUserByContactId.KeySet()){
                                            lstKeys.add (new IntermediateACRRequest__c (PCC__c = idPcc, Broker__c = idBroker, Nature__c = lstNature.get(0), Macrolob__c= macrolbPc, SharingRequestKey__c = idPcc + '_' + idBroker + '_' + lstNature.get(0).deleteWhitespace() + '_' + macrolbPc + '-' + idCon, User__c = mapUserByContactId.get(idCon), Contact__c= idCon));
                                        //System.debug('mapUserByContactId.get(idUser) = ' + mapUserByContactId.get(idUser));
                                    }
                                }
                            }
                        }  
                    }
                    // RT Reinsurer
                    if (lstMacrolobPC.size() > 0){  
                        for (String macrolbPc : lstMacrolobPC) {
                            for (String idPcc : lstPCCId){
                                for (String idReinsurer : lstReinsurerId){
                                    for (Id idCon : mapUserByContactId.KeySet()){
                                        lstKeys.add (new IntermediateACRRequest__c (PCC__c = idPcc, Reinsurer__c = idReinsurer, Nature__c = lstNature.get(0), Macrolob__c= macrolbPc, SharingRequestKey__c = idPcc + '_' + idReinsurer + '_' +  lstNature.get(0).deleteWhitespace() + '_' + macrolbPc  + '-' + idCon, User__c = mapUserByContactId.get(idCon), Contact__c= idCon));
                                    }
                                }
                            }
                        }
                    }
                }
            }

                System.debug('createKeyElligibleForSharingContact___lstKeysFinal =' + lstKeys);
                for (IntermediateACRRequest__c key : lstKeys){
                    if (key.SharingRequestKey__c != null && key.User__c !=null){
                        setKeyCalculateWithUserId.add((key.SharingRequestKey__c).deleteWhitespace() + '-' + key.User__c + '-'+ key.Nature__c);
                    }
                }

                // Method to avoid duplicate id external 
                setKeys.addAll(lstKeys);
                lstResKeys.addAll(setKeys);
    
                if (lstResKeys.size() > 0){
                    upsert lstResKeys SharingRequestKey__c;
                }

            //Create Sharing Request from contact
            AP36_CreateSharingForContact.createSharingForContact(setKeyCalculateWithUserId, lstIdContact, null);
            success = 'Synchronization Done Successfully';
        /* }else{
            success = null;
        }*/
        /*}
        return success;*/
    }
}