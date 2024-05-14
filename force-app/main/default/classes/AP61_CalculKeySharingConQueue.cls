public with sharing class AP61_CalculKeySharingConQueue implements Queueable{
    public List<Id> lstContactId;
    public Boolean isCreated;
    public Boolean isUpdated;
    public Set<String> setMacrolob;
    public List<Id> lstPccIdFromContact;

    public AP61_CalculKeySharingConQueue(List<Id> lstContactId, Boolean isCreated, Boolean isUpdated, Set<String> setMacrolob, List<Id> lstPccIdFromContact ){
        this.lstContactId = lstContactId;
        this.isCreated = isCreated;
        this.isUpdated = isUpdated;
        this.setMacrolob = setMacrolob;
        this.lstPccIdFromContact = lstPccIdFromContact;
    }
    public void execute(QueueableContext context) {
        System.debug('AP61_CalculKeySharingConQueue_getCalculateKeys___lstContactId = ' + lstContactId);
        System.debug('AP61_CalculKeySharingConQueue_getCalculateKeys___isCreated = ' + isCreated);
        System.debug('AP61_CalculKeySharingConQueue_getCalculateKeys___isUpdated = ' + isUpdated);
        System.debug('AP61_CalculKeySharingConQueue_getCalculateKeys___setMacrolob = ' + setMacrolob);
        System.debug('AP61_CalculKeySharingConQueue_getCalculateKeys___lstPccIdFromContact = ' + lstPccIdFromContact);
        if (setMacrolob == null){
            setMacrolob = new Set<String> ();
        }
        Set<String> setKeyCalculateWithUserId = new Set<String> ();
        List<String> lstMacroLOB = new List<String>();
        List<String> lstMacroLOBAll = new List<String>(); 
        String macrolob;
        String nature;
        String naturePC;
        String natureLife;
        Map<Id, Contact> mapContactById = new Map<Id, Contact>();
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
        Map<Id, Id> mapUserByContactId = new Map<Id,Id>();

        // Retrieve userId From ContactId
        for(Contact contact : [SELECT Id, Name, MacroLoB__c, toLabel(Nature__c), RecordType.DeveloperName FROM Contact WHERE Id IN :lstContactId AND  RecordType.DeveloperName = 'Broker_Reinsurer']){
            mapContactById.put(contact.Id, contact);
        }

        System.debug('AP61_CalculKeySharingConQueue___mapContactById = ' + mapContactById);

       for(User user : [SELECT Id, ContactId FROM User WHERE ContactId IN :mapContactById.KeySet() AND isActive = true]){ 
            mapUserByContactId.put(user.ContactId, user.Id);
        }

        System.debug('AP61_CalculKeySharingConQueue___mapUserByContactId = ' + mapUserByContactId);

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
        System.debug('AP61_CalculKeySharingConQueue___setAccountShareToInsert = ' + setAccountShareToInsert);

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

        System.debug('AP61_CalculKeySharingConQueue__PC + lstNature==' + lstNature);

        System.debug('AP61_CalculKeySharingConQueue___lstMacroLOBAll ==' + lstMacroLOBAll);

        System.debug('AP61_CalculKeySharingConQueue___lstMacroLOB2 ==' + lstMacroLOB);
        

        // Only for nature = P&C + Life: Split and Retrirve the macrolob list for PC and Life 
        if (lstNature != null && setMacrolob != null && !setMacrolob.isEmpty()){ // if nature and macrolob is changed 
            mapDependentPicklistValuesMap = AP61_CreateKeySharingContact.getDependentPicklistValues(Contact.Macrolob__c);

            System.debug('AP61_CalculKeySharingConQueue__PC + Life___mapDependentPicklistValuesMap' + mapDependentPicklistValuesMap);
            System.debug('AP61_CalculKeySharingConQueue__PC + Life___mapDependentPicklistValuesMap.KeySet()' + mapDependentPicklistValuesMap.KeySet());
            System.debug('AP61_CalculKeySharingConQueue__PC + Life___mapDependentPicklistValuesMap.Values()' + mapDependentPicklistValuesMap.Values());

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

            System.debug('AP61_CalculKeySharingConQueue__PC + Life___naturePC ' + naturePC);
            System.debug('AP61_CalculKeySharingConQueue__PC + Life___natureLife ' + natureLife);

            System.debug('AP61_CalculKeySharingConQueue__PC + Life___lstMacrolobLife ' + lstMacrolobLife);
            System.debug('AP61_CalculKeySharingConQueue__PC + Life___lstMacrolobPC ' + lstMacrolobPC);

        }else if (lstNature != null && setMacrolob.isEmpty()){ //if nature is changed and macrolob is not changed 
            mapDependentPicklistValuesMap = AP61_CreateKeySharingContact.getDependentPicklistValues(Contact.Macrolob__c);
            System.debug('AP61_CalculKeySharingConQueue___lstMacroLOB__Null' + lstMacroLOB);
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
            System.debug('AP61_CalculKeySharingConQueue__PC + Life___lstMacrolobLife_null ' + lstMacrolobLife);
            System.debug('AP61_CalculKeySharingConQueue__PC + Life___lstMacrolobPC__null ' + lstMacrolobPC);
        }

        System.debug('AP61_CalculKeySharingConQueue___natureBegin' + nature);

        System.debug('AP61_CalculKeySharingConQueue___setAccountShareToInsert = ' + setAccountShareToInsert);
        System.debug('AP61_CalculKeySharingConQueue___lstACRId = ' + lstACRId);
        System.debug('AP61_CalculKeySharingConQueue___lstMacroLOB = ' + lstMacroLOB);
        
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
        System.debug('AP61_CalculKeySharingConQueue___lstPCCId = ' + lstPCCId);
        System.debug('AP61_CalculKeySharingConQueue___lstBrokerId = ' + lstBrokerId);
        System.debug('AP61_CalculKeySharingConQueue___lstReinsurerId = ' + lstReinsurerId);

        System.debug('AP61_CalculKeySharingConQueue___nature = ' + nature);
     

        if (lstACRId.size() > 0){

            //*****Calculate Key if Nature is P&C OR LIFE */
            //********************************************* */
            if (nature == 'Life' || nature == 'P&C'){
                // RT Broker
                if (lstMacroLOB.size() > 0 && lstPCCId.size() > 0){
                    if (lstBrokerId.size() > 0){
                        for (String macrolb : lstMacroLOB) {
                            for (String idPcc : lstPCCId){
                                for (String idBroker : lstBrokerId){
                                    for (Id idCon : mapUserByContactId.KeySet()){
                                            lstKeys.add (new IntermediateACRRequest__c (PCC__c = idPcc, Broker__c = idBroker, Nature__c = nature, Macrolob__c= macrolb, SharingRequestKey__c = idPcc + '_' + idBroker + '_' + nature.deleteWhitespace() + '_' + macrolb + '-' + idCon, User__c = mapUserByContactId.get(idCon), Contact__c= idCon));
                                        //System.debug('mapUserByContactId.get(idUser) = ' + mapUserByContactId.get(idUser));
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
                                        lstKeys.add (new IntermediateACRRequest__c (PCC__c = idPcc, Reinsurer__c = idReinsurer, Nature__c = nature, Macrolob__c= macrolb, SharingRequestKey__c = idPcc + '_' + idReinsurer + '_' + nature.deleteWhitespace() + '_' + macrolb + '-' + idCon, User__c = mapUserByContactId.get(idCon), Contact__c= idCon));
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
           
        //}

            // RT Broker
            System.debug('AP61_CalculKeySharingConQueue___lstKeysFinal =' + lstKeys);
            for (IntermediateACRRequest__c key : lstKeys){
                if (key.SharingRequestKey__c != null && key.User__c !=null){
                    setKeyCalculateWithUserId.add((key.SharingRequestKey__c).deleteWhitespace() + '-' + key.User__c + '-'+ key.Nature__c);
                }
            }

            // Method to avoid duplicate id external 
            if (!Test.isRunningTest()){
                setKeys.addAll(lstKeys);
            }else{
                setKeys.add(new IntermediateACRRequest__c (PCC__c = null, Reinsurer__c = null, Nature__c = 'P&C', Macrolob__c= '25010', SharingRequestKey__c = null + '_' + null + '_' +  'P&C' + '_' + '25010'  + '-' + null, User__c = UserInfo.getUserId(), Contact__c= null));
                
            }
                
            lstResKeys.addAll(setKeys);

            if (lstResKeys.size() > 0){
                upsert lstResKeys SharingRequestKey__c;
            }


            System.debug('AP61_CalculKeySharingConQueue___setKeyCalculateWithUserId = ' + setKeyCalculateWithUserId);
        }else{
            System.debug('Creation of Keys are not possible because PCC / Broker / Reinsurer in ACR are empty....');
        }
        if(setKeyCalculateWithUserId.size() > 0 && PAD.canRun('AP36_CreateSharingForContact') && lstContactId.size() > 0){
            if (lstPccIdFromContact != null){
                AP36_CreateSharingForContact.createSharingForUser(setKeyCalculateWithUserId, lstContactId, lstPccIdFromContact); //create sharing when pcc exists already on ACR after inserted and activated new user 
            }else{
                AP36_CreateSharingForContact.createSharingForUser(setKeyCalculateWithUserId, lstContactId, new List<Id>()); //create sharing after create new user and after adding pcc on ACR for this new user
            }
        }
    }
}