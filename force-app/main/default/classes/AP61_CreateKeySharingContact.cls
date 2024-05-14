/**************************************************************************************
-- - Author        : Telesio
-- - Description   : handler for trigger on Intermediate ACR/ Request
--
-- Maintenance History:
--
-- Date          Name  Version  Remarks
-- -----------   ----  -------  -------------------------------------------------------
-- 23-MARCH-2022  RRA   1.0      Initial version
--------------------------------------------------------------------------------------
**************************************************************************************/
public without sharing class AP61_CreateKeySharingContact { 

    public static Set<String> createKeyElligibleForSharingContact(List<Id> lstContactIds, Boolean isCreated, Boolean isUpdated, set<String> setMacrolob){
        Set<String> setKeyWithUserId = new Set<String> ();
        List<AccountContactRelation> lstACRId = new List<AccountContactRelation>(); 
        // Action insert in trigger
        System.debug('createKeyElligibleForSharingContact___lstContactIds = ' + lstContactIds);
        System.debug('createKeyElligibleForSharingContact___setMacrolob= ' + setMacrolob);
        System.debug('createKeyElligibleForSharingContact___isCreated= ' + isCreated);
        System.debug('createKeyElligibleForSharingContact___isUpdated= ' + isUpdated);
        
        if (isCreated == true && isUpdated == false && setMacrolob.isEmpty()){
            System.debug('createKeyElligibleForSharingContact___setMacrolob is null ');
            setKeyWithUserId = getCalculateKeys (lstContactIds, true, false, setMacrolob);
        // Action update in trigger
        }else if (isCreated == false && isUpdated == true && !setMacrolob.isEmpty()){
            System.debug('createKeyElligibleForSharingContact___setMacrolob is not null ');
            setKeyWithUserId = getCalculateKeys (lstContactIds, false, true, setMacrolob);
        }else { // case if nature is only changed
            System.debug('createKeyElligibleForSharingContact___OKOK ');
            setKeyWithUserId = getCalculateKeys (lstContactIds, false, true, setMacrolob);
        }

        System.debug('createKeyElligibleForSharingContact___setKeyWithUserId = ' + setKeyWithUserId);

    return setKeyWithUserId;
    }

    //@future //to avoid MIXED_DML_OPERATION, DML operation on setup object is not permitted after you have updated a non-setup object 
    public static void  getCalculateKeysForUserOnly(List<Id> lstContactId, Boolean isCreated, Boolean isUpdated, Set<String> setMacrolob, List<Id> lstPccIdFromContact){
        System.enqueueJob(new AP61_CalculKeySharingConQueue(lstContactId, isCreated, isUpdated, setMacrolob, lstPccIdFromContact));
        /*Set<String> setKeyWithUserId = new Set<String> ();
        setKeyWithUserId = getCalculateKeys (lstContactId, isCreated, isUpdated, new Set<String>());
        if(setKeyWithUserId.size() > 0 && PAD.canRun('AP36_CreateSharingForContact') && lstContactId.size() > 0){
            if (lstPccIdFromContact != null){
                AP36_CreateSharingForContact.createSharingForUser(setKeyWithUserId, lstContactId, lstPccIdFromContact); //create sharing when pcc exists already on ACR after inserted and activated new user 
            }else{
                AP36_CreateSharingForContact.createSharingForUser(setKeyWithUserId, lstContactId, new List<Id>()); //create sharing after create new user and after adding pcc on ACR for this new user
            }
        }*/
    }

    public static Set<String> getCalculateKeys (List<Id> lstContactId, Boolean isCreated, Boolean isUpdated, Set<String> setMacrolob){
        System.debug('getCalculateKeys___lstContactId = ' + lstContactId);
        System.debug('getCalculateKeys___isCreated = ' + isCreated);
        System.debug('getCalculateKeys___isUpdated = ' + isUpdated);
        System.debug('getCalculateKeys___setMacrolob = ' + setMacrolob);
        Set<String> setKeyCalculateWithUserId = new Set<String> ();
        List<String> lstMacroLOB = new List<String>();
        List<String> lstMacroLOBAll = new List<String>(); 
        String macrolob;
        String nature;
        String naturePC;
        String natureLife;
        Map<Id, Contact> mapContactById = new Map<Id, Contact>();
        Map<Id, Id> mapUserByContactId = new Map<Id, Id>();
        List<String> lstNatureSplit = new List <String>();
        List<String> lstNaturePCLifeSplit = new List <String>();
        Set <String> setAccountShareToInsert = new Set <String>();
        Id rtPccId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PrincipalCedingCompany').getRecordTypeId();
        Id rtBrokerId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Broker').getRecordTypeId();
        Id rtReinsurerId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Reinsurer').getRecordTypeId();
        List<AccountContactRelation> lstACRId = new List<AccountContactRelation>(); 
        List<String> lstPCCId = new List<String>();
        List<String> lstBrokerId = new List<String>();   
        List<String> lstReinsurerId = new List<String>();  
        List<IntermediateACRRequest__c> lstKeys = new List<IntermediateACRRequest__c>(); 
        List<String> lstMacrolobLife = new List<String>();
        List<String> lstMacrolobPC = new List<String>();
        Map<String,List<String>> mapDependentPicklistValuesMap  = new  Map<String,List<String>>();
        Set<IntermediateACRRequest__c> setKeys = new Set<IntermediateACRRequest__c>();
        List<IntermediateACRRequest__c> lstResKeys = new List<IntermediateACRRequest__c>();
        List<String> lstNature = new List<String>();

        // Retrieve userId From ContactId
        for(Contact contact : [SELECT Id, Name, MacroLoB__c, toLabel(Nature__c), RecordType.DeveloperName FROM Contact WHERE Id IN :lstContactId AND  RecordType.DeveloperName = 'Broker_Reinsurer']){
            mapContactById.put(contact.Id, contact);
        }

        System.debug('createKeyElligibleForSharingContact___mapContactById = ' + mapContactById);

        for(User user : [SELECT Id, ContactId FROM User WHERE ContactId IN :mapContactById.keySet() AND isActive = true]){ 
            mapUserByContactId.put(user.ContactId, user.Id);
        }

        System.debug('createKeyElligibleForSharingContact___mapUserByContactId = ' + mapUserByContactId);

        // Retrieve All ACR Attached ont the contact
        for (AccountContactRelation acr: [SELECT Id, toLabel(Contact.Nature__c), Company18Characters__c , Contact.MacroLoB__c, Contact.AccountId, AccountId, Account.RecordTypeId, ContactId, Roles, Contact.RecordType.DeveloperName FROM AccountContactRelation
                                            WHERE ContactId IN :lstContactId
                                            AND IsActive = TRUE
                                            AND Contact.MacroLoB__c != NULL
                                            AND Contact.RecordType.DeveloperName = 'Broker_Reinsurer'
                                            AND Contact.Nature__c != NULL]){
            setAccountShareToInsert.add (acr.Contact.MacroLoB__c + '-' + acr.Contact.Nature__c);
            lstACRId.add(acr);
        }

        // Case Update Trigger
        System.debug('createKeyElligibleForSharingContact___setAccountShareToInsert = ' + setAccountShareToInsert);

        if ((!setMacrolob.isEmpty()) && isCreated == false && isUpdated == true){
            System.debug('setMacrolob is not null ');
            for(String acrString : setAccountShareToInsert){
                macrolob = acrString.split('-')[0];
                nature = acrString.split('-')[1];
                if (nature == 'P&C + Life'){
                    lstNature = nature.split('\\+');
                }
            }
            if (macrolob != null){
                lstMacroLOBAll = macrolob.split(';');
            }
            for (String macro : lstMacroLOBAll){
                if (setMacrolob.contains(macro)){
                    lstMacroLOB.add(macro);
                }
            }
            
        }// Case Insert Trigger
        else if  (setMacrolob.isEmpty() && isCreated == true && isUpdated == false ){
            System.debug('setMacrolob is null 1111');
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
        } // Case update Trigger and Macrolob is not changed
        else if  (setMacrolob.isEmpty() && isCreated == false && isUpdated == true ){
            System.debug('setMacrolob is null 2222');
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
        }

        System.debug('createKeyElligibleForSharingContact__PC + lstNature==' + lstNature);

        System.debug('createKeyElligibleForSharingContact___lstMacroLOBAll ==' + lstMacroLOBAll);

        System.debug('createKeyElligibleForSharingContact___lstMacroLOB2 ==' + lstMacroLOB);
        

        // Only for nature = P&C + Life: Split and Retrirve the macrolob list for PC and Life 
        if (lstNature != null && setMacrolob != null && !setMacrolob.isEmpty()){ // if nature and macrolob is changed 
            mapDependentPicklistValuesMap = getDependentPicklistValues(Contact.Macrolob__c);

            System.debug('createKeyElligibleForSharingContact__PC + Life___mapDependentPicklistValuesMap' + mapDependentPicklistValuesMap);
            System.debug('createKeyElligibleForSharingContact__PC + Life___mapDependentPicklistValuesMap.KeySet()' + mapDependentPicklistValuesMap.KeySet());
            System.debug('createKeyElligibleForSharingContact__PC + Life___mapDependentPicklistValuesMap.Values()' + mapDependentPicklistValuesMap.Values());

            for(String natureKey : mapDependentPicklistValuesMap.keyset()){
                for(String macrolobLifePc : mapDependentPicklistValuesMap.get(natureKey ))
                {
                    for (String mm : setMacrolob){
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

            System.debug('createKeyElligibleForSharingContact__PC + Life___naturePC ' + naturePC);
            System.debug('createKeyElligibleForSharingContact__PC + Life___natureLife ' + natureLife);

            System.debug('createKeyElligibleForSharingContact__PC + Life___lstMacrolobLife ' + lstMacrolobLife);
            System.debug('createKeyElligibleForSharingContact__PC + Life___lstMacrolobPC ' + lstMacrolobPC);

        }else if (lstNature != null && setMacrolob.isEmpty()){ //if nature is changed and macrolob is not changed 
            mapDependentPicklistValuesMap = getDependentPicklistValues(Contact.Macrolob__c);
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
        System.debug('createKeyElligibleForSharingContact___lstPCCId = ' + lstPCCId);
        System.debug('createKeyElligibleForSharingContact___lstBrokerId = ' + lstBrokerId);
        System.debug('createKeyElligibleForSharingContact___lstReinsurerId = ' + lstReinsurerId);

        System.debug('createKeyElligibleForSharingContact___nature = ' + nature);
     

        if (lstACRId.size() > 0){

            //*****Calculate Key if Nature is P&C OR LIFE */
            //********************************************* */
            if (nature == 'Life' || nature == 'P&C'){
                // RT Broker 
                if (lstMacroLOB.size() > 0 && lstPCCId.size() > 0){
                    if (lstBrokerId != null && !lstBrokerId.isEmpty()){  //RRA - ticket 1839 - 18022024
                        for (String macrolb : lstMacroLOB) {
                            for (String idPcc : lstPCCId){
                                for (String idBroker : lstBrokerId){
                                    for (Id idCon : mapUserByContactId.KeySet()){
                                            //lstKeys.add (new IntermediateACRRequest__c (PCC__c = idPcc, Broker__c = idBroker, Nature__c = nature, Macrolob__c= macrolb, SharingRequestKey__c = idPcc + '_' + idBroker + '_' + nature.deleteWhitespace() + '_' + macrolb + '-' + idCon, User__c = mapUserByContactId.get(idCon), Contact__c= idCon));
                                            lstKeys.add (new IntermediateACRRequest__c (PCC__c = idPcc, Broker__c = idBroker, Nature__c = nature, Macrolob__c= macrolb, SharingRequestKey__c = idPcc + '_' + idBroker + '_' + macrolb + '-' + idCon, User__c = mapUserByContactId.get(idCon), Contact__c= idCon)); //RRA - ticket 1839 - 28022024
                                        //System.debug('mapUserByContactId.get(idUser) = ' + mapUserByContactId.get(idUser));
                                    }
                                }
                            }
                        }  
                    }
                    // RT Reinsurer
                    if (lstReinsurerId != null && !lstReinsurerId.isEmpty()){    //RRA - ticket 1839 - 18022024
                        for (String macrolb : lstMacroLOB) {
                            for (String idPcc : lstPCCId){
                                for (String idReinsurer : lstReinsurerId){
                                    for (Id idCon : mapUserByContactId.KeySet()){
                                        //lstKeys.add (new IntermediateACRRequest__c (PCC__c = idPcc, Reinsurer__c = idReinsurer, Nature__c = nature, Macrolob__c= macrolb, SharingRequestKey__c = idPcc + '_' + idReinsurer + '_' + nature.deleteWhitespace() + '_' + macrolb + '-' + idCon, User__c = mapUserByContactId.get(idCon), Contact__c= idCon));
                                        lstKeys.add (new IntermediateACRRequest__c (PCC__c = idPcc, Reinsurer__c = idReinsurer, Nature__c = nature, Macrolob__c= macrolb, SharingRequestKey__c = idPcc + '_' + idReinsurer + '_' + macrolb + '-' + idCon, User__c = mapUserByContactId.get(idCon), Contact__c= idCon)); //RRA - ticket 1839 - 28022024
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
                if (lstMacrolobLife.size() > 0 && lstPCCId.size() > 0 || Test.isRunningTest()){
                    if (lstBrokerId != null && !lstBrokerId.isEmpty()){  //RRA - ticket 1839 - 18022024
                        for (String macrolbLife : lstMacrolobLife) {
                            for (String idPcc : lstPCCId){
                                for (String idBroker : lstBrokerId){
                                    for (Id idCon : mapUserByContactId.KeySet()){
                                            //lstKeys.add (new IntermediateACRRequest__c (PCC__c = idPcc, Broker__c = idBroker, Nature__c = lstNature.get(1), Macrolob__c= macrolbLife, SharingRequestKey__c = idPcc + '_' + idBroker + '_' + lstNature.get(1).deleteWhitespace() + '_' + macrolbLife  + '-' + idCon, User__c = mapUserByContactId.get(idCon), Contact__c= idCon));
                                            lstKeys.add (new IntermediateACRRequest__c (PCC__c = idPcc, Broker__c = idBroker, Nature__c = lstNature.get(1), Macrolob__c= macrolbLife, SharingRequestKey__c = idPcc + '_' + idBroker + '_' + macrolbLife  + '-' + idCon, User__c = mapUserByContactId.get(idCon), Contact__c= idCon)); //RRA - ticket 1839 - 28022024
                                        //System.debug('mapUserByContactId.get(idUser) = ' + mapUserByContactId.get(idUser));
                                    }
                                }
                            }
                        }  
                    }
                    // RT Reinsurer
                    if (lstReinsurerId != null && !lstReinsurerId.isEmpty()){   //RRA - ticket 1839 - 18022024
                        for (String macrolbLife : lstMacrolobLife) {
                            for (String idPcc : lstPCCId){
                                for (String idReinsurer : lstReinsurerId){
                                    for (Id idCon : mapUserByContactId.KeySet()){
                                        //lstKeys.add (new IntermediateACRRequest__c (PCC__c = idPcc, Reinsurer__c = idReinsurer, Nature__c = lstNature.get(1), Macrolob__c= macrolbLife, SharingRequestKey__c = idPcc + '_' + idReinsurer + '_' + lstNature.get(1).deleteWhitespace() + '_' + macrolbLife + '-' + idCon, User__c = mapUserByContactId.get(idCon), Contact__c= idCon)); 
                                        lstKeys.add (new IntermediateACRRequest__c (PCC__c = idPcc, Reinsurer__c = idReinsurer, Nature__c = lstNature.get(1), Macrolob__c= macrolbLife, SharingRequestKey__c = idPcc + '_' + idReinsurer + '_' + macrolbLife + '-' + idCon, User__c = mapUserByContactId.get(idCon), Contact__c= idCon)); //RRA - ticket 1839 - 28022024
                                    }
                                }
                            }
                        }
                    }
                }

                //Nature= P&C
                // RT Broker
                if (lstMacrolobPC.size() > 0 && lstPCCId.size() > 0 || Test.isRunningTest()){
                    if (lstBrokerId != null && !lstBrokerId.isEmpty()){  //RRA - ticket 1839 - 18022024
                        for (String macrolbPc : lstMacrolobPC) {
                            for (String idPcc : lstPCCId){
                                for (String idBroker : lstBrokerId){
                                    for (Id idCon : mapUserByContactId.KeySet()){
                                            //lstKeys.add (new IntermediateACRRequest__c (PCC__c = idPcc, Broker__c = idBroker, Nature__c = lstNature.get(0), Macrolob__c= macrolbPc, SharingRequestKey__c = idPcc + '_' + idBroker + '_' + lstNature.get(0).deleteWhitespace() + '_' + macrolbPc + '-' + idCon, User__c = mapUserByContactId.get(idCon), Contact__c= idCon));
                                            lstKeys.add (new IntermediateACRRequest__c (PCC__c = idPcc, Broker__c = idBroker, Nature__c = lstNature.get(0), Macrolob__c= macrolbPc, SharingRequestKey__c = idPcc + '_' + idBroker + '_' + macrolbPc + '-' + idCon, User__c = mapUserByContactId.get(idCon), Contact__c= idCon)); //RRA - ticket 1839 - 28022024
                                        //System.debug('mapUserByContactId.get(idUser) = ' + mapUserByContactId.get(idUser));
                                    }
                                }
                            }
                        }  
                    }
                    // RT Reinsurer
                    if (lstReinsurerId != null && !lstReinsurerId.isEmpty()){   //RRA - ticket 1839 - 18022024
                        for (String macrolbPc : lstMacrolobPC) {
                            for (String idPcc : lstPCCId){
                                for (String idReinsurer : lstReinsurerId){
                                    for (Id idCon : mapUserByContactId.KeySet()){
                                        //lstKeys.add (new IntermediateACRRequest__c (PCC__c = idPcc, Reinsurer__c = idReinsurer, Nature__c = lstNature.get(0), Macrolob__c= macrolbPc, SharingRequestKey__c = idPcc + '_' + idReinsurer + '_' +  lstNature.get(0).deleteWhitespace() + '_' + macrolbPc  + '-' + idCon, User__c = mapUserByContactId.get(idCon), Contact__c= idCon)); 
                                        lstKeys.add (new IntermediateACRRequest__c (PCC__c = idPcc, Reinsurer__c = idReinsurer, Nature__c = lstNature.get(0), Macrolob__c= macrolbPc, SharingRequestKey__c = idPcc + '_' + idReinsurer + '_' + macrolbPc  + '-' + idCon, User__c = mapUserByContactId.get(idCon), Contact__c= idCon)); //RRA - ticket 1839 - 28022024
                                    }
                                }
                            }
                        }
                    }
                }
            }
           
        //}

            // RT Broker
            System.debug('createKeyElligibleForSharingContact___lstKeysFinal =' + lstKeys);
            for (IntermediateACRRequest__c key : lstKeys){
                if (key.SharingRequestKey__c != null && key.User__c !=null){
                    setKeyCalculateWithUserId.add((key.SharingRequestKey__c).deleteWhitespace() + '-' + key.User__c + '-'+ key.Nature__c);
                }
            }

           /* if (lstKeys.size() > 0){
                if (!Test.isRunningTest()){
                    upsert lstKeys SharingRequestKey__c;
                }else{
                    map<Id,IntermediateACRRequest__c> IntObjMap = new map<Id,IntermediateACRRequest__c>(); 
                    IntObjMap.putall(lstKeys);
                    upsert IntObjMap.values();
                }
                
            }*/

            // Method to avoid duplicate id external 
            setKeys.addAll(lstKeys);
            lstResKeys.addAll(setKeys);

            if (lstResKeys.size() > 0){
                upsert lstResKeys SharingRequestKey__c;
            }


            System.debug('createKeyElligibleForSharingContact___setKeyCalculateWithUserId = ' + setKeyCalculateWithUserId);
        }else{
            System.debug('Creation of Keys are not possible because PCC / Broker / Reinsurer in ACR are empty....');
        }

        return setKeyCalculateWithUserId;
    }

    public static void DeleteRecordIntOjRequestShareFromContact (List<Id> lstContactIdOld, Set<String> setMacrolobOld, List<String> lstNatureOld, Boolean isMacrolobChanged, Boolean isNatureChanged){
            List<String> lstMacrolob= new List<String> ();
            List<String> lstNature= new List<String> ();
            Map<Id, Contact> mapContactById = new Map<Id, Contact>();
            Map<Id, Id> mapUserByContactId = new Map<Id, Id>();

            List<String> lstPCCIdOld= new List<String> ();
            List<String> lstBrokerIdOld= new List<String> ();
            List<String> lstReinsurerIdOld= new List<String> ();
            List<Id> lstIdUser = new List<Id>();
            List<Request__Share> lstReqShare = new List<Request__Share>();
            String query;

            List<IntermediateACRRequest__c> lstIntObject = new List<IntermediateACRRequest__c>();
            
            // Retrieve userId From ContactId
            for(Contact contact : [SELECT Id, Name, MacroLoB__c, toLabel(Nature__c) FROM Contact WHERE Id IN :lstContactIdOld]){
                mapContactById.put(contact.Id, contact);
            }

            System.debug('createKeyElligibleForSharingContact___mapContactById = ' + mapContactById);

            for(User user : [SELECT Id, ContactId FROM User WHERE ContactId IN :mapContactById.keySet() AND isActive = true]){ 
                mapUserByContactId.put(user.ContactId, user.Id);
            }

            for (Id contactIdOld : lstContactIdOld){
                lstIdUser.add(mapUserByContactId.get(contactIdOld));
            }

            System.debug('createKeyElligibleForSharingContact___lstIdUser = ' + lstIdUser);

            for (AccountContactRelation acr : [SELECT Id, toLabel(Contact.Nature__c), Contact.MacroLoB__c, Contact.AccountId, AccountId, Account.RecordTypeId, ContactId, Roles, Tech_AccountName__c                             
                                                FROM AccountContactRelation
                                                WHERE ContactId IN :lstContactIdOld
                                                AND IsActive = TRUE
                                                AND Contact.MacroLoB__c != NULL
                                                AND Contact.Nature__c != NULL]){
                String acc = acr.Tech_AccountName__c;
                String lastStrAcc= acc.right(3);
                if (lastStrAcc == '(P)' || Test.isRunningTest()){
                    lstPCCIdOld.add(acr.AccountId);
                }
                if (lastStrAcc == '(B)'){
                    lstBrokerIdOld.add(acr.AccountId);
                }
                if (lastStrAcc == '(R)') {
                    lstReinsurerIdOld.add(acr.AccountId);
                }
            }

            System.debug('DeleteRecordIntOjFromContact___lstPCCIdOld = ' + lstPCCIdOld);
            System.debug('DeleteRecordIntOjFromContact___lstBrokerIdOld = ' + lstBrokerIdOld);
            System.debug('DeleteRecordIntOjFromContact___lstReinsurerIdOld = ' + lstReinsurerIdOld);

            System.debug('DDeleteRecordIntOjFromContact___setMacrolobOld = ' + setMacrolobOld);
            System.debug('DeleteRecordIntOjFromContact___lstNatureOld = ' + lstNatureOld);

            System.debug('DeleteRecordIntOjFromContact___mapUserByContactId.values() = ' + mapUserByContactId.values());

            //System.debug('DeleteRecordIntOjFromContact___queryOrigine = ' + query);

            if(lstPCCIdOld != null && !lstPCCIdOld.isEmpty()){
                query = 'SELECT Id, PCC__c, Reinsurer__c, Nature__c, Macrolob__c, SharingKeyFormula__c, User__c, Broker__c FROM IntermediateACRRequest__c';

                //*** If Nature is PC Or Life */
                /// Retrieve the list of intermediate object to delete 
                //**************** ************/
                //if (lstNatureOld[0] != null && (lstNatureOld[0] == 'Life' || lstNatureOld[0] == 'P&C')){
                    if(lstBrokerIdOld != null && !lstBrokerIdOld.isEmpty()){
                        if(setMacrolobOld != null && !setMacrolobOld.isEmpty() && isMacrolobChanged == true && isNatureChanged ==false){
                            query = query  + ' WHERE User__c IN: lstIdUser';
                        }else if (lstNatureOld != null && !lstNatureOld.isEmpty() && isMacrolobChanged == false && isNatureChanged ==true){
                            query = query  + ' WHERE User__c IN: lstIdUser';
                        }else if (setMacrolobOld != null && lstNatureOld != null && isMacrolobChanged == true && isNatureChanged ==true){
                            query = query  + ' WHERE User__c IN: lstIdUser';
                        }else{
                            query = null;
                        }
                    }else if (lstReinsurerIdOld != null && !lstReinsurerIdOld.isEmpty()){
                        System.debug('DeleteRecordIntOjFromContact___OKOK');
                        if(setMacrolobOld != null && !setMacrolobOld.isEmpty() && isMacrolobChanged == true && isNatureChanged ==false){
                            query = query  + ' WHERE User__c IN: lstIdUser';
                        }else if (lstNatureOld != null && !lstNatureOld.isEmpty() && isMacrolobChanged == false && isNatureChanged ==true ){
                            query = query  + ' WHERE User__c IN: lstIdUser';
                        }else if (setMacrolobOld != null && lstNatureOld != null && isMacrolobChanged == true && isNatureChanged ==true){
                            query = query  + ' WHERE User__c IN: lstIdUser';
                        }else{
                            query = null;
                        }
                    }
            }

            

            System.debug('DeleteRecordIntOjFromContact___query = ' + query);

            if (query !=null){
                lstIntObject = Database.query(query);
                System.debug('DeleteRecordIntOjFromContact___lstIntObject = ' + lstIntObject);
            }

            List<String> lstStrKey = new List<String>();
            for (IntermediateACRRequest__c intObj : lstIntObject){
                lstStrKey.add(intObj.SharingKeyFormula__c );
            }

            System.debug('DeleteRecordIntOjFromContact___lstStrKey = ' + lstStrKey);


            if (lstStrKey.size() > 0){
                lstReqShare = [SELECT Id, UserOrGroupId, Parent.KeyRequestSharing__c FROM Request__Share WHERE Parent.KeyRequestSharing__c IN:lstStrKey AND UserOrGroupId IN:mapUserByContactId.Values()];
            }

            System.debug('DeleteRecordIntOjFromContact___lstReqShare = ' + lstReqShare);
            System.debug('DeleteRecordIntOjFromContact___Limits.getDMLRows()= ' + Limits.getDMLRows());

            if (lstReqShare != null && lstReqShare.size() < 9000 - Limits.getDMLRows()){
                delete lstReqShare;
            }else if (lstReqShare != null && lstReqShare.size() > 9000 - Limits.getDMLRows()){
                BAT002_DeleteSharingBigQuantity batchDeleteReq = new BAT002_DeleteSharingBigQuantity(lstReqShare);
                Database.executeBatch(batchDeleteReq, 500);                   
            }

            if (lstIntObject != null && lstIntObject.size() < Limits.getDMLRows()){
                delete lstIntObject;
            }

            System.debug('createSharingBigQuantityForContact__InsertionRequestShare =  ' + lstReqShare.size() + ' Done successfully');
            System.debug('createSharingBigQuantityForContact__lstIntObject =  ' + lstIntObject.size() + ' Done successfully');

            
            /*if (lstReqShare != null){
                if (lstReqShare.size() > 0 && lstReqShare.size() < 10000){
                    delete lstReqShare;
                }else if (lstReqShare.size() > 9999){
                    BAT002_DeleteSharingBigQuantity batchDeleteReqShare = new BAT002_DeleteSharingBigQuantity(lstReqShare);
                        Database.executeBatch(batchDeleteReqShare, 500);
                    
                }
            }

            if (lstIntObject != null && !lstIntObject.isEmpty() ){
                try {
                    delete lstIntObject;
                    System.debug('DeleteRecordIntOjFromContact___lstIntObject size = ' + lstIntObject.size() + 'deleted successfully');
                } catch (Exception ex) {
                    System.debug(ex.getMessage());
                }
               
            }*/
    }


    public static void DeleteRecordIntOjFromACR (List<Id> lstContactIdOld, List<String> lstACROldId){
        List<String> lstMacrolobOld= new List<String> ();
        List<String> lstNatureOld= new List<String> ();
        Map<Id, Contact> mapContactById = new Map<Id, Contact>();
        Map<Id, Id> mapUserByContactId = new Map<Id, Id>();

        List<String> lstPCCIdOld= new List<String> ();
        List<String> lstBrokerIdOld= new List<String> ();
        List<String> lstReinsurerIdOld= new List<String> ();
        List<Id> lstIdUser = new List<Id>();
        List<IntermediateACRRequest__c> lstIntObject = new List<IntermediateACRRequest__c>();

        // Retrieve userId From ContactId
        for(Contact contact : [SELECT Id, Name, MacroLoB__c, toLabel(Nature__c), RecordType.DeveloperName FROM Contact WHERE Id IN :lstContactIdOld AND RecordType.DeveloperName = 'Broker_Reinsurer']){
            mapContactById.put(contact.Id, contact);
        }

        System.debug('createKeyElligibleForSharingContact___mapContactById = ' + mapContactById);

        for(User user : [SELECT Id, ContactId FROM User WHERE ContactId IN :mapContactById.keySet() AND isActive = true]){ 
            mapUserByContactId.put(user.ContactId, user.Id);
        }

        for (Id contactIdOld : lstContactIdOld){
            lstIdUser.add(mapUserByContactId.get(contactIdOld));
        }


        for (AccountContactRelation acr : [SELECT Id, toLabel(Contact.Nature__c), Contact.MacroLoB__c, Contact.AccountId, AccountId, Account.RecordTypeId, ContactId, Roles, Tech_AccountName__c                             
                                            FROM AccountContactRelation
                                            WHERE ContactId IN :lstContactIdOld
                                            AND IsActive = TRUE
                                            AND Id IN:lstACROldId
                                            AND Contact.MacroLoB__c != NULL
                                            AND Contact.Nature__c != NULL]){
            String acc = acr.Tech_AccountName__c;
            String lastStrAcc= acc.right(3);
            if (lastStrAcc == '(P)'){
                lstPCCIdOld.add(acr.AccountId);
            }
            if (lastStrAcc == '(B)'){
                lstBrokerIdOld.add(acr.AccountId);
            }
            if (lastStrAcc == '(R)') {
                lstReinsurerIdOld.add(acr.AccountId);
            }

            lstMacrolobOld.add(acr.Contact.MacroLoB__c);
            lstNatureOld.add(acr.Contact.Nature__c);

        }
        System.debug('DeleteRecordIntOjFromACR___lstPCCIdOld = ' + lstPCCIdOld);
        System.debug('DeleteRecordIntOjFromACR___lstBrokerIdOld = ' + lstBrokerIdOld);
        System.debug('DeleteRecordIntOjFromACR___lstReinsurerIdOld = ' + lstReinsurerIdOld);

        System.debug('DeleteRecordIntOjFromACR___lstMacrolobOld = ' + lstMacrolobOld);
        System.debug('DeleteRecordIntOjFromACR___lstNatureOld = ' + lstNatureOld);

        String query =  ' SELECT Id, PCC__c, Reinsurer__c, Nature__c, Macrolob__c, SharingRequestKey__c, User__c, Broker__c FROM IntermediateACRRequest__c WHERE PCC__c IN:lstPCCIdOld AND Macrolob__c IN: lstMacrolobOld AND Nature__c IN: lstNatureOld AND User__c IN: lstIdUser ';

        if(lstBrokerIdOld != null){
            query = query + ' AND Broker__c IN:lstBrokerIdOld ';
        }else if (lstReinsurerIdOld != null){
            query = query + ' AND Reinsurer__c IN:lstReinsurerIdOld ';
        }else{
            query = null;
        }

        System.debug('DeleteRecordIntOjFromContact___query = ' + query);

        if (query !=null){
            lstIntObject = Database.query(query);
            System.debug('DeleteRecordIntOjFromContact___lstIntObject = ' + lstIntObject);
            if (lstIntObject != null && !lstIntObject.isEmpty() ){
                delete lstIntObject;
            }
        }
    }

    // Get dependent picklist with Nature and Macrolob
    public static Map<String, List<String>> getDependentPicklistValues(Schema.sObjectField dependToken) {
        Schema.DescribeFieldResult depend = dependToken.getDescribe();
        Schema.sObjectField controlToken = depend.getController();
        if (controlToken == null) {
            return new Map<String, List<String>>();
        }
     
        Schema.DescribeFieldResult control = controlToken.getDescribe();
        List<Schema.PicklistEntry> controlEntries;
        if(control.getType() != Schema.DisplayType.Boolean) {
            controlEntries = control.getPicklistValues();
        }
     
        String base64map = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
        Map<String,List<String>> dependentPicklistValues = new Map<String,List<String>>();
        for (Schema.PicklistEntry entry : depend.getPicklistValues()) {
            if (entry.isActive() && String.isNotEmpty(String.valueOf(((Map<String,Object>) JSON.deserializeUntyped(JSON.serialize(entry))).get('validFor')))) {
                List<String> base64chars =
                        String.valueOf(((Map<String,Object>) JSON.deserializeUntyped(JSON.serialize(entry))).get('validFor')).split('');
                for (Integer index = 0; index < (controlEntries != null ? controlEntries.size() : 2); index++) {
                    Object controlValue =
                            (controlEntries == null
                                    ?   (Object) (index == 1)
                                    :   (Object) (controlEntries[index].isActive() ? controlEntries[index].getLabel() : null)
                            );
                    Integer bitIndex = index / 6;
                    if (bitIndex > base64chars.size() - 1) {
                        break;
                    }
                    Integer bitShift = 5 - Math.mod(index, 6);
                    if  (controlValue == null || (base64map.indexOf( base64chars[ bitIndex ] ) & (1 << bitShift)) == 0)
                        continue;
                    if (!dependentPicklistValues.containsKey((String) controlValue)) {
                        dependentPicklistValues.put((String) controlValue, new List<String>());
                    }
                    dependentPicklistValues.get((String) controlValue).add(entry.getValue());
                }
            }
        }
        return dependentPicklistValues;
    }
}