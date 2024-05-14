public without sharing class AP36_CreateSharingForContact {
    /**************************************************************************************
    -- - Author        : Spoon Consulting
    -- - Description   : Create Request Share and Account Share for Contact
    --
    -- Maintenance History:
    --
    -- Date         Name  Version  Remarks
    -- -----------  ----  -------  -------------------------------------------------------
    --16-JUN-2020  MBE   1.0      Initial version
    --22-JUN-2021  MBE   1.1      W-0997 - Special Acceptance - Visibilité des SA pour un user externe nouvellement créé
    --27-SEP-2021  MBE   1.2      W-1031 - Error Account&Contact Relation
    --14-MARS-2022 RRA   1.3      Optimization Codes createSharingForContact
    --------------------------------------------------------------------------------------
    **************************************************************************************/
        /**
        * @description Method to recalculate sharing after Contact updates
        * @param List<Id> lstContacts
        * @param  Set<String> setKeyWithUserId
        * @param List<String> lstStrAcc
        * @return void
        */

        public static void createSharingForContact(Set<String> setKeyWithUserId, List<Id> lstIdContact, List<String> lstStrAcc){
            System.debug('createSharingForContact___setKeyWithUserId = ' + setKeyWithUserId);
            System.debug('createSharingForContact___lstStrAcc = ' + lstStrAcc);
            List<Request__c> lstNewRequests = new List<Request__c>();
            List<AccountContactRelation> lstNewAccountPcc = new List<AccountContactRelation>();
            List<Request__c> lstRequestsNew = new List<Request__c>();
            //Set<String> setKeyToInsertFromUser = new Set<String>();
            Set<String> setKeyToInsertFromPcc = new Set<String>();
            Map<Id, Id> mapSAIdByRequestId = new Map<Id, Id>();
            Set<String> setKeys = new Set<String>();
            //Set<String> setKeysWithNoIdCon = new Set<String>();
            Set<String> setAccountShareToInsert = new Set<String>();
            Set<String> setUserId;
            List<String> lstIdPccElligible = new List<String> ();
            List<AccountShare> lstAccountShareToInsert = new List<AccountShare> ();
            List<Request__Share> lstRequestShareToInsert = new List<Request__Share> ();
            List<SpecialAcceptance__Share> lstSAShare = new List<SpecialAcceptance__Share> ();
            Map<String, Id> mapRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectRequest});
            String recordTypeIdSA = mapRecTypeId.get(AP_Constant.reqRTSA);
            String key;
            //String keyWithNoIdCon;
            String userId;
            String nature;
            List<Id> lstIdPccForContact = new List<Id>();
            List<String> lstInitial = new List<String>();
            List<Id> lstBrokerReinsurer = new List<Id>();
            Map <String, String> mapNamePccExists = new Map <String, String>();
            Map<String, Id> mapIdGroupIdPcc = new Map<String, Id>();
            List<Id> lstAccId = new List<Id>();
            List<String> lstReqNature = new List<String>();
            List<Id> lstIdUser = new List<Id>();
            Map<Id, Id> mapIdAccIdUser = new Map <Id, Id>();
            Map<Id, Id> mapIdReqIdUser = new Map <Id, Id>();
            Map<Id, Id> mapIdReqIdPcc = new Map <Id, Id>();
            Map<Id, Id> mapIdSAReqIdUser = new Map <Id, Id>();
            Set<Id> setAccountPCCId = new Set<Id>();
            Map<String, Id> mapReqIdReqIdSA = new  Map<String, Id> ();
            Map<String, Id> mapIdPccSAId = new  Map<String, Id> ();
            Map<String, Id> mapIdGroupIdSAPcc = new Map<String, Id>();
            Integer countRowRequest;
            map<String, Id> mapKeyUserId = new map<String, Id>();
            map<Id, Id> mapKeyUserIdAcc = new map<Id, Id>();
            map<Id, Id> mapIdAccIdUserFromAcc = new map<Id, Id>();

            // Retrieve the list key and user attached on the Inte Object
            for(String keyContactId : setKeyWithUserId){
               key = keyContactId.split('-')[0].deleteWhitespace();
               setKeys.add(key);
               userId = keyContactId.split('-')[2];
               mapKeyUserId.put(key, userId);
               nature = keyContactId.split('-')[3];
            }

            for (User usr : [SELECT Id, ContactId FROM User WHERE ContactId IN:lstIdContact]){
                mapKeyUserIdAcc.put(usr.ContactId, usr.Id);
            }

            System.debug('createSharingForContact___mapKeyUserIdAcc= ' + mapKeyUserIdAcc);
            System.debug('createSharingForContact___setKeys.SIZE= ' +setKeys.size());
            System.debug('createSharingForContact___setKeys = ' + setKeys);
            System.debug('createSharingForContact___mapKeyUserId = ' + mapKeyUserId);

            // Check if account name is changed on ACR else if get all account name attached on the contact
            if (lstStrAcc != null){
                for (String acc : lstStrAcc){
                    String accStr = acc.split('_')[0]; 
                    String initial = acc.split('_')[1]; 
                    lstAccId.add(accStr);
                    lstInitial.add(initial);
                }
            }else{
                // for trigger Contact only
                for (String strKey : setKeys){
                    String keyPcc = strKey.split('_')[0]; 
                    lstIdPccForContact.add(keyPcc);
                }
            }

            System.debug('createSharingForContact___lstAccId= ' + lstAccId);
            System.debug('createSharingForContact___lstInitial= ' + lstInitial);
            System.debug('createSharingForContact___setKeys= ' + setKeys);
            System.debug('createSharingForContact___lstIdPccForContact= ' + lstIdPccForContact);
            
            String query = 'SELECT Id, Name, OriginalRequest__c, toLabel(Program__r.Nature__c), Program__r.PrincipalCedingCompany__c, Program__r.Macro_L_O_B__c, RecordTypeId, PrincipalCedingCompany__c,Broker__c, Reinsurer__c, BrokerStatus__c, Special_Acceptance__c, ReinsurerStatus__c, KeyRequestSharing__c FROM Request__c';

            //Request for Creation AccountShare only
            String queryAcc = 'SELECT Id, ContactId, AccountId FROM AccountContactRelation';

            String queryCount = 'SELECT Count() From Request__c';

            if (!Test.isRunningTest()){
                if (lstInitial.contains('(P)') && lstAccId != null){ // get Pcc
                    query = query + ' WHERE KeyRequestSharing__c IN: setKeys AND Program__r.PrincipalCedingCompany__c IN :lstAccId AND (Broker__c != NULL OR Reinsurer__c != NULL) AND RecordType.name in (\'Quote Request\',\'Lead Request\',\'Placement Request\',\'Signing Request\') AND ReinsurerStatus__c != \'Setup\' AND OriginalRequest__c  = NULL';
                    queryCount = queryCount + ' WHERE KeyRequestSharing__c IN: setKeys AND Program__r.PrincipalCedingCompany__c IN :lstAccId AND (Broker__c != NULL OR Reinsurer__c != NULL) AND RecordType.name in (\'Quote Request\',\'Lead Request\',\'Placement Request\',\'Signing Request\') AND ReinsurerStatus__c != \'Setup\' AND OriginalRequest__c  = NULL';
                    queryAcc = queryAcc + ' WHERE AccountId IN :lstAccId';
                }else if (lstInitial.contains('(B)') && lstAccId != null){ // get broker
                    query = query + ' WHERE KeyRequestSharing__c IN: setKeys AND Broker__c IN :lstAccId AND Reinsurer__c != NULL AND RecordType.name in (\'Quote Request\',\'Lead Request\',\'Placement Request\',\'Signing Request\') AND ReinsurerStatus__c != \'Setup\' AND OriginalRequest__c  = Null';
                    queryCount = queryCount + ' WHERE KeyRequestSharing__c IN: setKeys AND Broker__c IN :lstAccId AND Reinsurer__c != NULL AND RecordType.name in (\'Quote Request\',\'Lead Request\',\'Placement Request\',\'Signing Request\') AND ReinsurerStatus__c != \'Setup\' AND OriginalRequest__c  = NULL';
                }else if (lstInitial.contains('(R)') && lstAccId != null){ // get Reinsurer
                    query = query + ' WHERE KeyRequestSharing__c IN: setKeys AND Reinsurer__c IN :lstAccId AND Reinsurer__c != NULL AND RecordType.name in (\'Quote Request\',\'Lead Request\',\'Placement Request\',\'Signing Request\') AND ReinsurerStatus__c != \'Setup\' AND OriginalRequest__c  = Null';
                    queryCount = queryCount + ' WHERE KeyRequestSharing__c IN: setKeys AND Reinsurer__c IN :lstAccId AND Reinsurer__c != NULL AND RecordType.name in (\'Quote Request\',\'Lead Request\',\'Placement Request\',\'Signing Request\') AND ReinsurerStatus__c != \'Setup\' AND OriginalRequest__c  = NULL';
                }else{
                    query = query + ' WHERE KeyRequestSharing__c IN:setKeys AND Program__r.PrincipalCedingCompany__c IN :lstIdPccForContact AND Reinsurer__c != NULL AND RecordType.name in (\'Quote Request\',\'Lead Request\',\'Placement Request\',\'Signing Request\') AND ReinsurerStatus__c != \'Setup\' AND OriginalRequest__c  = NULL';
                    queryCount = queryCount + ' WHERE KeyRequestSharing__c IN:setKeys AND Program__r.PrincipalCedingCompany__c IN :lstIdPccForContact AND Reinsurer__c != NULL AND RecordType.name in (\'Quote Request\',\'Lead Request\',\'Placement Request\',\'Signing Request\') AND ReinsurerStatus__c != \'Setup\' AND OriginalRequest__c  = NULL';
                }
            }else{
                if (lstInitial.contains('(P)') && lstAccId != null){ // get Pcc
                    query = query + ' WHERE KeyRequestSharing__c IN: setKeys AND Program__r.PrincipalCedingCompany__c IN :lstAccId AND (Broker__c != NULL OR Reinsurer__c != NULL)';
                    queryCount = queryCount + ' WHERE KeyRequestSharing__c IN: setKeys AND Program__r.PrincipalCedingCompany__c IN :lstAccId AND (Broker__c != NULL OR Reinsurer__c != NULL)';
                    queryAcc = queryAcc + ' WHERE AccountId IN :lstAccId';
                }else if (lstInitial.contains('(B)') && lstAccId != null){ // get broker
                    query = query + ' WHERE KeyRequestSharing__c IN: setKeys AND Broker__c IN :lstAccId AND Reinsurer__c != NULL';
                    queryCount = queryCount + ' WHERE KeyRequestSharing__c IN: setKeys AND Broker__c IN :lstAccId AND Reinsurer__c != NULL';
                }else if (lstInitial.contains('(R)') && lstAccId != null){ // get Reinsurer
                    query = query + ' WHERE KeyRequestSharing__c IN: setKeys AND Reinsurer__c IN :lstAccId AND Reinsurer__c != NULL';
                    queryCount = queryCount + ' WHERE KeyRequestSharing__c IN: setKeys AND Reinsurer__c IN :lstAccId AND Reinsurer__c != NULL';
                }else{
                    query = query + ' WHERE KeyRequestSharing__c IN:setKeys AND Program__r.PrincipalCedingCompany__c IN :lstIdPccForContact AND Reinsurer__c != NULL';
                    queryCount = queryCount + ' WHERE KeyRequestSharing__c IN:setKeys AND Program__r.PrincipalCedingCompany__c IN :lstIdPccForContact AND Reinsurer__c != NULL';
                }
            }
           

            System.debug('createSharingForContact___query= ' + query);
            System.debug('createSharingForContact___queryCount= ' + queryCount);
            System.debug('createSharingForContact___queryAcc ' + queryAcc);

            if (query != null){
                countRowRequest = Database.countQuery(queryCount);
            }

            if (queryAcc != null){
                lstNewAccountPcc = Database.query(queryAcc);
            }

            System.debug('createSharingForContact___lstNewAccountPcc ' + lstNewAccountPcc);

           
            System.debug('createSharingForContact___countRowRequest ' + countRowRequest);

            // Check if size request is less than 9000 => process DML insertion normal to create the sharing key
            // Else if size request is more tha 9000 => call process batch to to create the sharing key
            if (countRowRequest < 45000){
                lstNewRequests = Database.query(query);
                System.debug('createSharingForContact___lstNewRequests= ' + lstNewRequests);
            }else if(countRowRequest > 45000){
                if (!System.isFuture()){
                    Contact con = [SELECT Id, isRunBatch__c FROM Contact WHERE Id IN:lstIdContact];
                    con.isRunBatch__c = true;
                    update con;
                    Database.executeBatch(new BAT003_CreateSharingReqBigQuantity(query, setKeyWithUserId, lstAccId, lstIdPccForContact, lstInitial, setKeys, lstIdContact), 2000);
                    lstNewRequests = null;
                }
            }

            if (lstNewAccountPcc != null){
                for (AccountContactRelation acr : lstNewAccountPcc){
                    if (lstAccId.contains(acr.AccountId) && String.isNotBlank(acr.AccountId)){
                    // Map relation between id Account and id User 
                    mapIdAccIdUserFromAcc.put(acr.AccountId, mapKeyUserIdAcc.get(acr.ContactId));
                }
              }

              System.debug('createSharingForContact___mapIdAccIdUserFromAcc' + mapIdAccIdUserFromAcc);

                // AccountShare from ACR => for treaty placement
                if (mapIdAccIdUserFromAcc != null){
                    for(Id accId : mapIdAccIdUserFromAcc.KeySet()){
                        if (mapIdAccIdUserFromAcc.get(accId) != null){
                            AccountShare accountShare = new AccountShare();
                            accountShare.AccountAccessLevel = 'Read';
                            accountShare.OpportunityAccessLevel = 'Read';
                            accountShare.AccountId = accId;
                            accountShare.UserOrGroupId = mapIdAccIdUserFromAcc.get(accId);
                            lstAccountShareToInsert.add(accountShare);
                        }
                    }
                }
            }

            if (lstNewRequests != null){
                //Get All Request to check if record is SA
                for(Request__c req : lstNewRequests){
                    mapNamePccExists.put (req.PrincipalCedingCompany__c, 'Exists');
                }

                System.debug('createSharingForContact___mapNamePccExists= ' + mapNamePccExists);

                if(mapNamePccExists != null ){
                    for(Group objGroup : [SELECT Id, Name FROM Group WHERE Name IN:mapNamePccExists.KeySet()]){
                        mapIdGroupIdPcc.put(objGroup.Name, objGroup.Id);
                    }
                }

                System.debug('createSharingForContact___mapIdGroupIdPcc= ' + mapIdGroupIdPcc);

                System.debug('createSharingForContact___mapSAIdByRequestId= ' + mapSAIdByRequestId);

                System.debug('createSharingForContact___nature= ' + nature);

                //Get All Request for only Request__Sharing

                String queryNew = 'SELECT Id, Name, OriginalRequest__c, toLabel(Program__r.Nature__c), Program__r.PrincipalCedingCompany__c, Program__r.Macro_L_O_B__c, RecordTypeId, PrincipalCedingCompany__c,Broker__c, Reinsurer__c, LastVersionSent__c, LastVersionAnswered__c, BrokerStatus__c, Special_Acceptance__c, ReinsurerStatus__c, KeyRequestSharing__c FROM Request__c';
                
            if (!Test.isRunningTest()){
                if (lstInitial.contains('(P)') && lstAccId != null){ // get Pcc
                    queryNew = queryNew + ' WHERE KeyRequestSharing__c IN: setKeys AND Program__r.PrincipalCedingCompany__c IN :lstAccId AND Reinsurer__c != NULL AND RecordType.name in (\'Quote Request\',\'Lead Request\',\'Placement Request\',\'Signing Request\') AND ReinsurerStatus__c != \'Setup\' AND OriginalRequest__c  = NULL';
                }else if (lstInitial.contains('(B)') && lstAccId != null){ // get broker
                    queryNew = queryNew + ' WHERE KeyRequestSharing__c IN: setKeys AND Broker__c IN :lstAccId AND Reinsurer__c != NULL AND RecordType.name in (\'Quote Request\',\'Lead Request\',\'Placement Request\',\'Signing Request\') AND ReinsurerStatus__c != \'Setup\' AND OriginalRequest__c  = NULL';
                }else if (lstInitial.contains('(R)') && lstAccId != null){ // get Reinsurer
                    queryNew = queryNew + ' WHERE KeyRequestSharing__c IN: setKeys AND Reinsurer__c IN :lstAccId AND Reinsurer__c != NULL AND RecordType.name in (\'Quote Request\',\'Lead Request\',\'Placement Request\',\'Signing Request\') AND ReinsurerStatus__c != \'Setup\' AND OriginalRequest__c  = NULL';
                }else{
                    queryNew = queryNew + ' WHERE KeyRequestSharing__c IN: setKeys AND Program__r.PrincipalCedingCompany__c IN :lstIdPccForContact AND Reinsurer__c != NULL AND RecordType.name in (\'Quote Request\',\'Lead Request\',\'Placement Request\',\'Signing Request\') AND ReinsurerStatus__c != \'Setup\' AND OriginalRequest__c  = NULL';
                }
            }else{
                if (lstInitial.contains('(P)') && lstAccId != null){ // get Pcc
                    queryNew = queryNew + ' WHERE KeyRequestSharing__c IN: setKeys AND Program__r.PrincipalCedingCompany__c IN :lstAccId AND Reinsurer__c != NULL';
                }else if (lstInitial.contains('(B)') && lstAccId != null){ // get broker
                    queryNew = queryNew + ' WHERE KeyRequestSharing__c IN: setKeys AND Broker__c IN :lstAccId AND Reinsurer__c != NULL';
                }else if (lstInitial.contains('(R)') && lstAccId != null){ // get Reinsurer
                    queryNew = queryNew + ' WHERE KeyRequestSharing__c IN: setKeys AND Reinsurer__c IN :lstAccId AND Reinsurer__c != NULL';
                }else{
                    queryNew = queryNew + ' WHERE KeyRequestSharing__c IN: setKeys AND Program__r.PrincipalCedingCompany__c IN :lstIdPccForContact AND Reinsurer__c != NULL';
                }
            }
               

                

                System.debug('createSharingForContact___queryNew= ' + queryNew);

                if (queryNew != null){
                    lstRequestsNew = Database.query(queryNew);
                }

                System.debug('createSharingForContact___lstRequestsNew= ' + lstRequestsNew);
                System.debug('createSharingForContact___lstRequestsNew.SIZE= ' + lstRequestsNew.size());

                for (Request__c req : lstRequestsNew){
                        if (req.OriginalRequest__c == null){
                            // Map relation between id request and id user
                            mapIdReqIdUser.put(req.Id, mapKeyUserId.get(req.KeyRequestSharing__c));
                        }else{
                            // Map relation between id request and id pcc
                            mapIdReqIdPcc.put(req.Id, mapIdGroupIdPcc.get(req.PrincipalCedingCompany__c));

                            if (req.LastVersionSent__c == true && req.LastVersionAnswered__c == true && req.Id != null){
                                // Map relation between id request and id rquest SA to share only user
                                mapReqIdReqIdSA.put (req.Id, mapKeyUserId.get(req.KeyRequestSharing__c)); 
                                // Map relation between id Pcc and id request SA to share only Group
                                mapIdPccSAId.put (req.PrincipalCedingCompany__c, req.Id); 
                            }
                        }

                    if(req.RecordTypeId == recordTypeIdSA){
                        if(req.BrokerStatus__c != '1' && req.ReinsurerStatus__c != AP_Constant.statusSetup && req.Special_Acceptance__c !=null){
                                // Map relation between id request SA and id User 
                            mapIdSAReqIdUser.put(req.Special_Acceptance__c, mapKeyUserId.get(req.KeyRequestSharing__c));
                        }
                    }
                    //Get All Account attached on contact to check if matching with request.Program__r.PrincipalCedingCompany__c 
                    if(lstStrAcc != null){
                        if (lstAccId.contains(req.Program__r.PrincipalCedingCompany__c ) && String.isNotBlank(req.Program__r.PrincipalCedingCompany__c)){
                                // Map relation between id Account and id User 
                            mapIdAccIdUser.put(req.Program__r.PrincipalCedingCompany__c, mapKeyUserId.get(req.KeyRequestSharing__c));
                        }
                    }else {
                        if (lstIdPccForContact.contains(req.Program__r.PrincipalCedingCompany__c ) && String.isNotBlank(req.Program__r.PrincipalCedingCompany__c)){
                            mapIdAccIdUser.put(req.Program__r.PrincipalCedingCompany__c, mapKeyUserId.get(req.KeyRequestSharing__c));
                        }
                    }
                    
                }
                System.debug('createSharingForContact___mapIdReqIdUser= ' + mapIdReqIdUser);
                System.debug('createSharingForContact___mapIdReqIdPcc= ' + mapIdReqIdPcc);

                System.debug('createSharingForContact___mapReqIdReqIdSA= ' + mapReqIdReqIdSA);
                System.debug('createSharingForContact___mapIdPccSAId= ' + mapIdPccSAId);

                System.debug('createSharingForContact___mapIdSAReqIdUser= ' + mapIdSAReqIdUser);
                System.debug('createSharingForContact___mapIdAccIdUser= ' + mapIdAccIdUser);

                // for SA only
                if(mapIdPccSAId != null ){
                    for(Group objGroup : [SELECT Id, Name FROM Group WHERE Name IN:mapIdPccSAId.KeySet()]){
                        mapIdGroupIdSAPcc.put(objGroup.Name, objGroup.Id);
                    }
                }

                // AccountShare from Request=> for treaty placement
                if (mapIdAccIdUser != null){
                    for(Id accId : mapIdAccIdUser.KeySet()){
                        if (mapIdAccIdUser.get(accId) != null){
                            AccountShare accountShare = new AccountShare();
                            accountShare.AccountAccessLevel = 'Read';
                            accountShare.OpportunityAccessLevel = 'Read';
                            accountShare.AccountId = accId;
                            accountShare.UserOrGroupId = mapIdAccIdUser.get(accId);
                            lstAccountShareToInsert.add(accountShare);
                        }
                    }
                }
                

                //RequestShare only user if original request is null => for treaty placement
                if (mapIdReqIdUser != null){
                    for(Id reqId : mapIdReqIdUser.KeySet()){
                        if (mapIdReqIdUser.get(reqId) != null){
                            Request__Share requestShare = new Request__Share();
                            requestShare.RowCause = 'Manual';
                            requestShare.AccessLevel = 'Edit';
                            requestShare.ParentId = reqId;
                            requestShare.UserOrGroupId = mapIdReqIdUser.get(reqId);
                            lstRequestShareToInsert.add(requestShare);
                        }
                    }
                }
                


                    //RequestShare only user if original request is not null => for SA
                    if (mapReqIdReqIdSA != null){
                        for(Id reqId : mapReqIdReqIdSA.KeySet()){
                            if (mapReqIdReqIdSA.get(reqId) != null){
                                Request__Share requestShare = new Request__Share();
                                requestShare.RowCause = 'Manual';
                                requestShare.AccessLevel = 'Edit';
                                requestShare.ParentId = reqId;
                                requestShare.UserOrGroupId = mapReqIdReqIdSA.get(reqId);
                                lstRequestShareToInsert.add(requestShare);
                            }
                    }
                }


                //RequestShareonly PCC if original request is not null => for SA
                if (mapIdGroupIdSAPcc != null){
                    for(String namePcc : mapIdGroupIdSAPcc.KeySet()){
                        if (mapIdGroupIdSAPcc.get(namePcc) != null){
                            Request__Share requestShare = new Request__Share();
                            requestShare.RowCause = 'Manual';
                            requestShare.AccessLevel = 'Edit';
                            requestShare.ParentId =  mapIdPccSAId.get(namePcc);
                            requestShare.UserOrGroupId = mapIdGroupIdSAPcc.get(namePcc);
                            lstRequestShareToInsert.add(requestShare);
                        }
                    }
                }

                //RequestShareonly PCC if original request is not null => for treaty placement
                if (mapIdReqIdPcc != null){
                    for(Id idReqPcc : mapIdReqIdPcc.KeySet()){
                        if (mapIdReqIdPcc.get(idReqPcc) != null){
                            Request__Share requestShare = new Request__Share();
                            requestShare.RowCause = 'Manual';
                            requestShare.AccessLevel = 'Edit';
                            requestShare.ParentId = idReqPcc;
                            requestShare.UserOrGroupId = mapIdReqIdPcc.get(idReqPcc);
                            lstRequestShareToInsert.add(requestShare);
                        }
                    }   
                }
                

                // SAShare => for treaty placement
                if (mapIdSAReqIdUser != null){
                    for(Id idReqSA : mapIdSAReqIdUser.KeySet()){
                        if (mapIdSAReqIdUser.get(idReqSA) != null){
                            SpecialAcceptance__Share saShare = new SpecialAcceptance__Share();
                            saShare.RowCause = 'Manual';
                            saShare.AccessLevel = 'Edit';
                            saShare.ParentId = idReqSA;
                            saShare.UserOrGroupId = mapIdSAReqIdUser.get(idReqSA);
                            lstSAShare.add(saShare);
                            
                        }
                    }
                }
                
                System.debug('createSharingForContact___lstAccountShareToInsert= ' + lstAccountShareToInsert);
                System.debug('createSharingForContact___lstRequestShareToInsert= ' + lstRequestShareToInsert);
                System.debug('createSharingForContact___lstRequestShareToInsertSIZE= ' + lstRequestShareToInsert.SIZE());
                System.debug('createSharingForContact___lstSAShare= ' + lstSAShare);


                /*if(lstAccountShareToInsert.size() > 0){
                    insert lstAccountShareToInsert;
                }*/

                /*if (lstRequestShareToInsert.size() > 0 ){
                    insert lstRequestShareToInsert;
                }*/
                System.debug('createSharingForContact___Limits.getDMLRows()= ' + Limits.getDMLRows());

                if (lstAccountShareToInsert != null && lstAccountShareToInsert.size() < 9000 - Limits.getDMLRows()){
                    insert lstAccountShareToInsert;
                }

                if (lstRequestShareToInsert != null && lstRequestShareToInsert.size() < 9000 - Limits.getDMLRows()){
                    insert lstRequestShareToInsert;
                }else{
                    BAT001_InsertSharingBigQuantity batchInsertReqShare = new BAT001_InsertSharingBigQuantity(lstRequestShareToInsert);
                    Database.executeBatch(batchInsertReqShare, 500);                        
                }

                if (lstSAShare != null && lstSAShare.size() < 9000 - Limits.getDMLRows()){
                    insert lstSAShare;
                }
                
                
                System.debug('createSharingBigQuantityForContact__lstAccountShareToInsert =  ' + lstAccountShareToInsert.size() + ' Done successfully');
                System.debug('createSharingBigQuantityForContact__InsertionRequestShare =  ' + lstRequestShareToInsert.size() + ' Done successfully');
                System.debug('createSharingBigQuantityForContact__InsertionSAShare =  ' + lstSAShare.size() + ' Done successfully');
               
        }
    }

        // This method is used to create sharing account, request and SA for only process BATCH 
        public static void createSharingBigQuantityForContact(List<Request__c> lstScope, Set<String> setKeyWithUserId, List<String> lstAccId, List<Id> lstIdPccForContact, List<String> lstInitial, Set<String> setKeys){
        System.debug('Begin createSharingBigQuantityForContact');

        System.debug('createSharingBigQuantityForContact__lstScope = ' + lstScope);
        System.debug('createSharingBigQuantityForContact__setKeyWithUserId = ' + setKeyWithUserId);

        List<Request__c> lstRequestsNew = new List<Request__c>();
        Set<String> setKeyToInsertFromPcc = new Set<String>();
        Map<Id, Id> mapSAIdByRequestId = new Map<Id, Id>();
        //Set<String> setKeys = new Set<String>();
        Set<String> setAccountShareToInsert = new Set<String>();
        Set<String> setUserId;
        List<String> lstIdPccElligible = new List<String> ();
        List<AccountShare> lstAccountShareToInsert = new List<AccountShare> ();
        List<Request__Share> lstRequestShareToInsert = new List<Request__Share> ();
        List<SpecialAcceptance__Share> lstSAShare = new List<SpecialAcceptance__Share> ();
        Map<String, Id> mapRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectRequest});
        String recordTypeIdSA = mapRecTypeId.get(AP_Constant.reqRTSA);
        String key;
        String userId;
        String nature;
        List<Id> lstBrokerReinsurer = new List<Id>();
        Map <String, String> mapNamePccExists = new Map <String, String>();
        Map<String, Id> mapIdGroupIdPcc = new Map<String, Id>();
        List<String> lstReqNature = new List<String>();
        List<Id> lstIdUser = new List<Id>();
        Map<Id, Id> mapIdAccIdUser = new Map <Id, Id>();
        Map<Id, Id> mapIdReqIdUser = new Map <Id, Id>();
        Map<Id, Id> mapIdReqIdPcc = new Map <Id, Id>();
        Map<Id, Id> mapIdSAReqIdUser = new Map <Id, Id>();
        Set<Id> setAccountPCCId = new Set<Id>();
        Map<String, Id> mapReqIdReqIdSA = new  Map<String, Id> ();
        Map<String, Id> mapIdPccSAId = new  Map<String, Id> ();
        Map<String, Id> mapIdGroupIdSAPcc = new Map<String, Id>();

        map<String, Id> mapKeyUserId = new map<String, Id>();
        for(String keyContactId : setKeyWithUserId){
            key = keyContactId.split('-')[0].deleteWhitespace();
            //setKeys.add(key);
            userId = keyContactId.split('-')[2];
            mapKeyUserId.put(key, userId);
            nature = keyContactId.split('-')[3];
        }
        if (lstInitial == null){
            lstInitial = new List<String>();
        }

        System.debug('createSharingBigQuantityForContact__mapKeyUserId= ' + mapKeyUserId);
        System.debug('createSharingBigQuantityForContact__nature= ' + nature);
        System.debug('createSharingBigQuantityForContact__setKeys= ' + setKeys);


        System.debug('createSharingBigQuantityForContact__lstAccId= ' + lstAccId);
        System.debug('createSharingBigQuantityForContact__lstInitial= ' + lstInitial);
        System.debug('createSharingBigQuantityForContact__lstIdPccForContact= ' + lstIdPccForContact);


        for(Request__c req : lstScope){ 
            mapNamePccExists.put (req.PrincipalCedingCompany__c, 'Exists');
        }

        System.debug('createSharingBigQuantityForContact__mapNamePccExists= ' + mapNamePccExists);

        if(mapNamePccExists != null ){
            for(Group objGroup : [SELECT Id, Name FROM Group WHERE Name IN:mapNamePccExists.KeySet()]){
                mapIdGroupIdPcc.put(objGroup.Name, objGroup.Id);
            }
        }

        System.debug('createSharingBigQuantityForContact__mapIdGroupIdPcc= ' + mapIdGroupIdPcc);

        //Get All Request for only Request__Sharing
        String queryNew = 'SELECT Id, Name, OriginalRequest__c, toLabel(Program__r.Nature__c), Program__r.PrincipalCedingCompany__c, Program__r.Macro_L_O_B__c, RecordTypeId, PrincipalCedingCompany__c,Broker__c, Reinsurer__c, LastVersionSent__c, LastVersionAnswered__c, BrokerStatus__c, Special_Acceptance__c, ReinsurerStatus__c, KeyRequestSharing__c FROM Request__c';

        if (!Test.isRunningTest()){
            if (lstInitial.contains('(P)') && lstAccId != null){ // get Pcc
                queryNew = queryNew + ' WHERE KeyRequestSharing__c IN: setKeys AND Program__r.PrincipalCedingCompany__c IN :lstAccId AND Reinsurer__c != NULL AND RecordType.name in (\'Quote Request\',\'Lead Request\',\'Placement Request\',\'Signing Request\') AND ReinsurerStatus__c != \'Setup\' AND OriginalRequest__c  = NULL';
            }else if (lstInitial.contains('(B)') && lstAccId != null){ // get broker
                queryNew = queryNew + ' WHERE KeyRequestSharing__c IN: setKeys AND Broker__c IN :lstAccId AND Reinsurer__c != NULL AND RecordType.name in (\'Quote Request\',\'Lead Request\',\'Placement Request\',\'Signing Request\') AND ReinsurerStatus__c != \'Setup\' AND OriginalRequest__c  = NULL';
            }else if (lstInitial.contains('(R)') && lstAccId != null){ // get Reinsurer
                queryNew = queryNew + ' WHERE KeyRequestSharing__c IN: setKeys AND Reinsurer__c IN :lstAccId AND Reinsurer__c != NULL AND RecordType.name in (\'Quote Request\',\'Lead Request\',\'Placement Request\',\'Signing Request\') AND ReinsurerStatus__c != \'Setup\' AND OriginalRequest__c  = NULL';
            }else{
                queryNew = queryNew + ' WHERE KeyRequestSharing__c IN: setKeys AND Program__r.PrincipalCedingCompany__c IN :lstIdPccForContact AND Reinsurer__c != NULL AND RecordType.name in (\'Quote Request\',\'Lead Request\',\'Placement Request\',\'Signing Request\') AND ReinsurerStatus__c != \'Setup\' AND OriginalRequest__c  = NULL';
            }
        }else{
            if (lstInitial.contains('(P)') && lstAccId != null){ // get Pcc
                queryNew = queryNew + ' WHERE KeyRequestSharing__c IN: setKeys AND Program__r.PrincipalCedingCompany__c IN :lstAccId AND Reinsurer__c != NULL';
            }else if (lstInitial.contains('(B)') && lstAccId != null){ // get broker
                queryNew = queryNew + ' WHERE KeyRequestSharing__c IN: setKeys AND Broker__c IN :lstAccId AND Reinsurer__c != NULL';
            }else if (lstInitial.contains('(R)') && lstAccId != null){ // get Reinsurer
                queryNew = queryNew + ' WHERE KeyRequestSharing__c IN: setKeys AND Reinsurer__c IN :lstAccId AND Reinsurer__c != NULL';
            }else{
                queryNew = queryNew + ' WHERE KeyRequestSharing__c IN: setKeys AND Program__r.PrincipalCedingCompany__c IN :lstIdPccForContact AND Reinsurer__c != NULL';
            }
        }

       

        if (queryNew != null){
            lstRequestsNew = Database.query(queryNew);
        }
        System.debug('createSharingBigQuantityForContact__queryNew= ' + queryNew);
        System.debug('createSharingBigQuantityForContact__lstRequestsNew= ' + lstRequestsNew);
        for (Request__c req : lstRequestsNew){
                if (req.OriginalRequest__c == null){
                    mapIdReqIdUser.put(req.Id, mapKeyUserId.get(req.KeyRequestSharing__c));
                }else{
                    mapIdReqIdPcc.put(req.Id, mapIdGroupIdPcc.get(req.PrincipalCedingCompany__c));

                    if (req.LastVersionSent__c == true && req.LastVersionAnswered__c == true && req.Id != null){
                        mapReqIdReqIdSA.put (req.Id, mapKeyUserId.get(req.KeyRequestSharing__c)); // toshare for User
                        mapIdPccSAId.put (req.PrincipalCedingCompany__c, req.Id); // toshare for group
                    }
                }

                if(req.RecordTypeId == recordTypeIdSA){
                if(req.BrokerStatus__c != '1' && req.ReinsurerStatus__c != AP_Constant.statusSetup && req.Special_Acceptance__c !=null){
                    mapIdSAReqIdUser.put(req.Special_Acceptance__c, mapKeyUserId.get(req.KeyRequestSharing__c));
                }
                }
                //Get All Account attached on contact to check if matching with request.Program__r.PrincipalCedingCompany__c 
                if(lstAccId != null){
                if (lstAccId.contains(req.Program__r.PrincipalCedingCompany__c ) && String.isNotBlank(req.Program__r.PrincipalCedingCompany__c)){
                    mapIdAccIdUser.put(req.Program__r.PrincipalCedingCompany__c, mapKeyUserId.get(req.KeyRequestSharing__c));
                }
                }else {
                if (lstIdPccForContact.contains(req.Program__r.PrincipalCedingCompany__c ) && String.isNotBlank(req.Program__r.PrincipalCedingCompany__c)){
                    mapIdAccIdUser.put(req.Program__r.PrincipalCedingCompany__c, mapKeyUserId.get(req.KeyRequestSharing__c));
                }
            } 
        }

            // for SA only
            if(mapIdPccSAId != null ){
                for(Group objGroup : [SELECT Id, Name FROM Group WHERE Name IN:mapIdPccSAId.KeySet()]){
                    mapIdGroupIdSAPcc.put(objGroup.Name, objGroup.Id);
                }
            }

            System.debug('createSharingBigQuantityForContact__mapIdAccIdUser= ' + mapIdAccIdUser);
            System.debug('createSharingBigQuantityForContact__mapIdSAReqIdUser= ' + mapIdSAReqIdUser);
            System.debug('createSharingBigQuantityForContact__mapReqIdReqIdSA= ' + mapReqIdReqIdSA);
            System.debug('createSharingBigQuantityForContact__mapIdGroupIdSAPcc= ' + mapIdGroupIdSAPcc);
            System.debug('createSharingBigQuantityForContact__mapIdReqIdPcc= ' + mapIdReqIdPcc);
            System.debug('createSharingBigQuantityForContact__mapIdReqIdUser= ' + mapIdReqIdUser);

            // AccountShare => for treaty placement
            if (mapIdAccIdUser != null){
                for(Id accId : mapIdAccIdUser.KeySet()){
                    if (mapIdAccIdUser.get(accId) != null){
                        AccountShare accountShare = new AccountShare();
                        accountShare.AccountAccessLevel = 'Read';
                        accountShare.OpportunityAccessLevel = 'Read';
                        accountShare.AccountId = accId;
                        accountShare.UserOrGroupId = mapIdAccIdUser.get(accId);
                        lstAccountShareToInsert.add(accountShare);
                    }
                }
            }
            

            //RequestShare only user if original request is null => for treaty placement
            if (mapIdReqIdUser != null){
                for(Id reqId : mapIdReqIdUser.KeySet()){
                    if (mapIdReqIdUser.get(reqId) != null){
                        Request__Share requestShare = new Request__Share();
                        requestShare.RowCause = 'Manual';
                        requestShare.AccessLevel = 'Edit';
                        requestShare.ParentId = reqId;
                        requestShare.UserOrGroupId = mapIdReqIdUser.get(reqId);
                        lstRequestShareToInsert.add(requestShare);
                    }
                }
            }
            


            //RequestShare only user if original request is not null => for SA
            if (mapReqIdReqIdSA != null){
                for(Id reqId : mapReqIdReqIdSA.KeySet()){
                    if (mapReqIdReqIdSA.get(reqId) != null){
                        Request__Share requestShare = new Request__Share();
                        requestShare.RowCause = 'Manual';
                        requestShare.AccessLevel = 'Edit';
                        requestShare.ParentId = reqId;
                        requestShare.UserOrGroupId = mapReqIdReqIdSA.get(reqId);
                        lstRequestShareToInsert.add(requestShare);
                    }
                }
            }
            


            //RequestShareonly PCC if original request is not null => for SA
            if (mapIdGroupIdSAPcc != null){
                for(String namePcc : mapIdGroupIdSAPcc.KeySet()){
                    if ( mapIdGroupIdSAPcc.get(namePcc) != null){
                        Request__Share requestShare = new Request__Share();
                        requestShare.RowCause = 'Manual';
                        requestShare.AccessLevel = 'Edit';
                        requestShare.ParentId =  mapIdPccSAId.get(namePcc);
                        requestShare.UserOrGroupId = mapIdGroupIdSAPcc.get(namePcc);
                        lstRequestShareToInsert.add(requestShare);
                    }
                }
            }
            

            //RequestShareonly PCC if original request is not null => for treaty placement
            if (mapIdReqIdPcc != null){
                for(Id idReqPcc : mapIdReqIdPcc.KeySet()){
                    if (mapIdReqIdPcc.get(idReqPcc) != null){
                        Request__Share requestShare = new Request__Share();
                        requestShare.RowCause = 'Manual';
                        requestShare.AccessLevel = 'Edit';
                        requestShare.ParentId = idReqPcc;
                        requestShare.UserOrGroupId = mapIdReqIdPcc.get(idReqPcc);
                        lstRequestShareToInsert.add(requestShare);
                    }
                }
            }
            

            // SAShare => for treaty placement
            if (mapIdSAReqIdUser != null){
                for(Id idReqSA : mapIdSAReqIdUser.KeySet()){
                    if (mapIdSAReqIdUser.get(idReqSA) != null){
                        SpecialAcceptance__Share saShare = new SpecialAcceptance__Share();
                        saShare.RowCause = 'Manual';
                        saShare.AccessLevel = 'Edit';
                        saShare.ParentId = idReqSA;
                        saShare.UserOrGroupId = mapIdSAReqIdUser.get(idReqSA);
                        lstSAShare.add(saShare);
                    }
                }
            }
            

           
            System.debug('createSharingBigQuantityForContact__lstRequestShareToInsert= ' + lstRequestShareToInsert);
            System.debug('createSharingBigQuantityForContact__lstSAShare= ' + lstSAShare);
            System.debug('createSharingBigQuantityForContact__lstAccountShareToInsert= ' + lstAccountShareToInsert);

            if (lstAccountShareToInsert != null && lstAccountShareToInsert.size() < 9000 - Limits.getDMLRows()){
                insert lstAccountShareToInsert;
            }

            if (lstRequestShareToInsert != null && lstRequestShareToInsert.size() < 9000 - Limits.getDMLRows()){
                insert lstRequestShareToInsert;
            }else{
                BAT001_InsertSharingBigQuantity batchInsertReqShare = new BAT001_InsertSharingBigQuantity(lstRequestShareToInsert);
                Database.executeBatch(batchInsertReqShare, 500);                        
            }

            if (lstSAShare != null && lstSAShare.size() < 9000 - Limits.getDMLRows()){
                insert lstSAShare;
            }

            System.debug('createSharingBigQuantityForContact__lstAccountShareToInsert =  ' + lstAccountShareToInsert.size() + ' Done successfully');
            System.debug('createSharingBigQuantityForContact__InsertionRequestShare =  ' + lstRequestShareToInsert.size() + ' Done successfully');
            System.debug('createSharingBigQuantityForContact__InsertionSAShare =  ' + lstSAShare.size() + ' Done successfully');
            System.debug('End createSharingBigQuantityForContact');
        }

        // Sharing when User is created
        public static void createSharingForUser(Set<String> setKeyWithUserId, List<Id> lstIdContact, List<Id> lstIdPcc){
            System.debug('createSharingForContact___setKeyWithUserId = ' + setKeyWithUserId);
            List<Request__c> lstNewRequests;
            Set<String> setKeyToInsertFromUser = new Set<String>();
            Set<String> setKeyToInsertFromPcc = new Set<String>();
            Map<Id, Id> mapSAIdByRequestId = new Map<Id, Id>();
            Set<String> setKeys = new Set<String>();
            Set<String> setAccountShareToInsert = new Set<String>();
            Set<String> setUserId;
            List<String> lstIdPccElligible = new List<String> ();
            List<AccountShare> lstAccountShareToInsert = new List<AccountShare> ();
            List<Request__Share> lstRequestShareToInsert = new List<Request__Share> ();
            List<SpecialAcceptance__Share> lstSAShare = new List<SpecialAcceptance__Share> ();
            Map<String, Id> mapRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectRequest});
            String recordTypeIdSA = mapRecTypeId.get(AP_Constant.reqRTSA);
            String key;
            String userId;
            String nature;
            List<Id> lstIdPccForContact = new List<Id>();
            Map <String, String> mapNamePccExists = new Map <String, String>();
            Map<String, Id> mapIdGroupIdPcc = new Map<String, Id>();
            Integer countRowRequest ;
            List<Id> lstIdAcc = new List<Id>();
            String query;
            String queryCount;
            //Set<String> setKeysWithNoIdCon = new Set<String>();

            map<String, Id> mapKeyUserId = new map<String, Id>();

            for(String keyContactId : setKeyWithUserId){
               key = keyContactId.split('-')[0].deleteWhitespace();
               setKeys.add(key);
               userId = keyContactId.split('-')[2];
               mapKeyUserId.put(key, userId);
               nature = keyContactId.split('-')[3];
            }

            System.debug('createSharingForContact___setKeys = ' + setKeys);
            System.debug('createSharingForContact___mapKeyUserId = ' + mapKeyUserId);

            if (lstIdPcc == null){ // for trigger Contact only
                for (String strKey : setKeys){
                    String keyPcc = strKey.split('_')[0]; 
                    lstIdPccForContact.add(keyPcc);
                }
            }

            lstIdAcc = lstIdPcc != null ? lstIdPcc : lstIdPccForContact;

            query = 'SELECT Id, Name, LastVersionSent__c, LastVersionAnswered__c, OriginalRequest__c, Program__r.Nature__c, Program__r.PrincipalCedingCompany__c, Program__r.Macro_L_O_B__c, RecordTypeId, PrincipalCedingCompany__c,Broker__c, Reinsurer__c, BrokerStatus__c, Special_Acceptance__c, ReinsurerStatus__c, KeyRequestSharing__c FROM Request__c WHERE Program__r.PrincipalCedingCompany__c IN:lstIdAcc AND Reinsurer__c != NULL AND RecordType.name in (\'Quote Request\',\'Lead Request\',\'Placement Request\',\'Signing Request\') AND ReinsurerStatus__c != \'Setup\' AND OriginalRequest__c  = NULL';

            queryCount = 'SELECT Count() From Request__c WHERE Program__r.PrincipalCedingCompany__c IN:lstIdAcc AND Reinsurer__c != NULL AND OriginalRequest__c = NULL AND RecordType.name in (\'Quote Request\',\'Lead Request\',\'Placement Request\',\'Signing Request\') AND ReinsurerStatus__c != \'Setup\' AND OriginalRequest__c  = NULL';
            
            /*System.debug('createSharingForContact___lstIdPcc= ' + lstIdPcc);
            query = 'SELECT Id, Name, LastVersionSent__c, LastVersionAnswered__c, OriginalRequest__c, Program__r.Nature__c, Program__r.PrincipalCedingCompany__c, Program__r.Macro_L_O_B__c, RecordTypeId, PrincipalCedingCompany__c,Broker__c, Reinsurer__c, BrokerStatus__c, Special_Acceptance__c, ReinsurerStatus__c, KeyRequestSharing__c FROM Request__c WHERE Program__r.PrincipalCedingCompany__c IN : (lstIdPcc !=null) ? lstIdPcc : lstIdPccForContact AND Reinsurer__c != NULL';

            queryCount = 'SELECT Count() From Request__c WHERE Program__r.PrincipalCedingCompany__c IN : (lstIdPcc !=null) ? lstIdPcc : lstIdPccForContact AND Reinsurer__c != NULL';*/
          
            System.debug('createSharingForContact___query= ' + query);
            System.debug('createSharingForContact___queryCount= ' + queryCount);
            System.debug('createSharingForContact___lstIdAcc= ' + lstIdAcc);
    
            if (query != null){
                countRowRequest = Database.countQuery(queryCount);
            }

            System.debug('createSharingForContact___countRowRequest= ' + countRowRequest);

            if (countRowRequest < 45000){
                lstNewRequests = Database.query(query);
            }else if(countRowRequest > 45000){
                Contact con = [SELECT Id, isRunBatch__c FROM Contact WHERE Id IN:lstIdContact];
                con.isRunBatch__c = false;
                update con;
                BAT003_CreateSharingReqBigQuantity batchInsertShare = new BAT003_CreateSharingReqBigQuantity(query, setKeyWithUserId, lstIdPcc, lstIdPccForContact, null, setKeys, lstIdContact);
                Database.executeBatch(batchInsertShare, 500);
                lstNewRequests = null;
            }

            System.debug('createSharingForContact___lstNewRequests= ' + lstNewRequests);

            if (lstNewRequests != null){
                //Get All Request to check if record is SA
                for(Request__c req : lstNewRequests){                                   
                    mapNamePccExists.put (req.PrincipalCedingCompany__c, 'Exists');
                }

                System.debug('createSharingForContact___mapNamePccExists= ' + mapNamePccExists);

                if(mapNamePccExists != null ){
                    for(Group objGroup : [SELECT Id, Name FROM Group WHERE Name IN:mapNamePccExists.KeySet()]){
                        mapIdGroupIdPcc.put(objGroup.Name, objGroup.Id);
                    }
                }
            }
            
            System.debug('createSharingForContact___mapIdGroupIdPcc= ' + mapIdGroupIdPcc);
            System.debug('createSharingForContact___mapSAIdByRequestId= ' + mapSAIdByRequestId);
            System.debug('createSharingForContact___nature= ' + nature);

          
            List<String> lstReqNature = new List<String>();
            List<Id> lstIdUser = new List<Id>();
            Map<Id, Id> mapIdAccIdUser = new Map <Id, Id>();
            Map<Id, Id> mapIdReqIdUser = new Map <Id, Id>();
            Map<Id, Id> mapIdReqIdPcc = new Map <Id, Id>();
            Map<Id, Id> mapIdSAReqIdUser = new Map <Id, Id>();
            Set<Id> setAccountPCCId = new Set<Id>();
            Map<String, Id> mapReqIdReqIdSA = new  Map<String, Id> ();
            Map<String, Id> mapIdPccSAId = new  Map<String, Id> ();
            Map<String, Id> mapIdGroupIdSAPcc = new Map<String, Id>();
            List<Request__c> lstRequest = new List<Request__c>();

            System.debug('createSharingForContact___setAccountPCCId= ' + setAccountPCCId);

            if (!Test.isRunningTest()){
                lstRequest = [SELECT Id, Name, OriginalRequest__c, LastVersionSent__c, LastVersionAnswered__c, toLabel(Program__r.Nature__c), Program__r.PrincipalCedingCompany__c, Program__r.Macro_L_O_B__c, RecordTypeId, PrincipalCedingCompany__c,  Broker__c, Reinsurer__c, BrokerStatus__c, Special_Acceptance__c, ReinsurerStatus__c, KeyRequestSharing__c FROM Request__c WHERE KeyRequestSharing__c IN: setKeys AND RecordType.name IN ('Quote Request','Lead Request','Placement Request','Signing Request') AND ReinsurerStatus__c != 'Setup' AND OriginalRequest__c  = NULL AND Program__r.PrincipalCedingCompany__c IN:(lstIdPcc !=null) ? lstIdPcc : lstIdPccForContact];
            }else{
                lstRequest = [SELECT Id, Name, OriginalRequest__c, LastVersionSent__c, LastVersionAnswered__c, toLabel(Program__r.Nature__c), Program__r.PrincipalCedingCompany__c, Program__r.Macro_L_O_B__c, RecordTypeId, PrincipalCedingCompany__c,  Broker__c, Reinsurer__c, BrokerStatus__c, Special_Acceptance__c, ReinsurerStatus__c, KeyRequestSharing__c FROM Request__c WHERE KeyRequestSharing__c IN: setKeys AND Program__r.PrincipalCedingCompany__c IN:(lstIdPcc !=null) ? lstIdPcc : lstIdPccForContact];
            }

            if (lstRequest != null && !lstRequest.isEmpty()){
                //Get All Request for only Request__Sharing
                for (Request__c req : lstRequest){

                    if (nature.contains(req.Program__r.Nature__c) || nature == req.Program__r.Nature__c){
                        if (req.OriginalRequest__c == null){
                            mapIdReqIdUser.put(req.Id, mapKeyUserId.get(req.KeyRequestSharing__c));
                        }else{                        
                            mapIdReqIdPcc.put(req.Id, mapIdGroupIdPcc.get(req.PrincipalCedingCompany__c));

                            //Share SA request fo user 
                            if (req.LastVersionSent__c == true && req.LastVersionAnswered__c == true && req.Id != null){
                                mapReqIdReqIdSA.put (req.Id, mapKeyUserId.get(req.KeyRequestSharing__c)); 
                                mapIdPccSAId.put (req.PrincipalCedingCompany__c, req.Id);
                            }
                        }
                    }
                        
                    if(req.RecordTypeId == recordTypeIdSA){
                        //Share SA fo user 
                        if(req.BrokerStatus__c != '1' && req.ReinsurerStatus__c != AP_Constant.statusSetup && req.Special_Acceptance__c !=null){
                            //setKeyToInsertFromUser.add(req.Id + '_' + mapKeyUserId.get(req.KeyRequestSharing__c));
                            mapIdSAReqIdUser.put(req.Special_Acceptance__c, mapKeyUserId.get(req.KeyRequestSharing__c));
                        }
                    }
                    //Get All Account attached on contact to check if matching with request.Program__r.PrincipalCedingCompany__c 
                    if(lstIdPcc != null){
                        if (lstIdPcc.contains(req.Program__r.PrincipalCedingCompany__c ) && String.isNotBlank(req.Program__r.PrincipalCedingCompany__c)){
                            mapIdAccIdUser.put(req.Program__r.PrincipalCedingCompany__c, mapKeyUserId.get(req.KeyRequestSharing__c));
                        }
                    }else {
                        if (lstIdPccForContact.contains(req.Program__r.PrincipalCedingCompany__c ) && String.isNotBlank(req.Program__r.PrincipalCedingCompany__c)){
                            mapIdAccIdUser.put(req.Program__r.PrincipalCedingCompany__c, mapKeyUserId.get(req.KeyRequestSharing__c));
                        }
                    }
                    
                }
            }

            System.debug('createSharingForContact___mapIdReqIdUser= ' + mapIdReqIdUser);
            System.debug('createSharingForContact___mapIdReqIdPcc= ' + mapIdReqIdPcc);

            System.debug('createSharingForContact___mapReqIdReqIdSA= ' + mapReqIdReqIdSA);
            System.debug('createSharingForContact___mapIdPccSAId= ' + mapIdPccSAId);

            System.debug('createSharingForContact___mapIdSAReqIdUser= ' + mapIdSAReqIdUser);
            System.debug('createSharingForContact___mapIdAccIdUser= ' + mapIdAccIdUser);

             // for SA only
        if(mapIdPccSAId != null ){
            for(Group objGroup : [SELECT Id, Name FROM Group WHERE Name IN:mapIdPccSAId.KeySet()]){
                mapIdGroupIdSAPcc.put(objGroup.Name, objGroup.Id);
            }
        }

            // AccountShare => for treaty placement
            if (mapIdAccIdUser != null) {
                    for(Id accId : mapIdAccIdUser.KeySet()){
                        if (mapIdAccIdUser.get(accId) != null) {
                        AccountShare accountShare = new AccountShare();
                        accountShare.AccountAccessLevel = 'Read';
                        accountShare.OpportunityAccessLevel = 'Read';
                        accountShare.AccountId = accId;
                        accountShare.UserOrGroupId = mapIdAccIdUser.get(accId);
                        lstAccountShareToInsert.add(accountShare);
                    }
                }
            }

            //RequestShare only user if original request is null => for treaty placement
            if (mapIdReqIdUser != null){
                    for(Id reqId : mapIdReqIdUser.KeySet()){
                        if (mapIdReqIdUser.get(reqId) != null){
                        Request__Share requestShare = new Request__Share();
                        requestShare.RowCause = 'Manual';
                        requestShare.AccessLevel = 'Edit';
                        requestShare.ParentId = reqId;
                        requestShare.UserOrGroupId = mapIdReqIdUser.get(reqId);
                        lstRequestShareToInsert.add(requestShare);
                    }
                }
            }

            //RequestShare only user if original request is not null => for SA
            if (mapReqIdReqIdSA != null){
                for(Id reqId : mapReqIdReqIdSA.KeySet()){
                    if (mapReqIdReqIdSA.get(reqId) != null){
                        Request__Share requestShare = new Request__Share();
                        requestShare.RowCause = 'Manual';
                        requestShare.AccessLevel = 'Edit';
                        requestShare.ParentId = reqId;
                        requestShare.UserOrGroupId = mapReqIdReqIdSA.get(reqId);
                        lstRequestShareToInsert.add(requestShare);
                    }
                }
            }
            


            //RequestShareonly PCC if original request is not null => for SA
            if (mapIdGroupIdSAPcc != null){
                for(String namePcc : mapIdGroupIdSAPcc.KeySet()){
                    if (mapIdGroupIdSAPcc.get(namePcc) != null){
                        Request__Share requestShare = new Request__Share();
                        requestShare.RowCause = 'Manual';
                        requestShare.AccessLevel = 'Edit';
                        requestShare.ParentId =  mapIdPccSAId.get(namePcc);
                        requestShare.UserOrGroupId = mapIdGroupIdSAPcc.get(namePcc);
                        lstRequestShareToInsert.add(requestShare);
                    }
                }
            }

            //RequestShareonly PCC if original request is not null => for treaty placement
            if (mapIdReqIdPcc != null){
                for(Id idReqPcc : mapIdReqIdPcc.KeySet()){
                    if (mapIdReqIdPcc.get(idReqPcc) != null){
                        Request__Share requestShare = new Request__Share();
                        requestShare.RowCause = 'Manual';
                        requestShare.AccessLevel = 'Edit';
                        requestShare.ParentId = idReqPcc;
                        requestShare.UserOrGroupId = mapIdReqIdPcc.get(idReqPcc);
                        lstRequestShareToInsert.add(requestShare);
                    }
                }
            }

            // SAShare => for treaty placement
            if (mapIdSAReqIdUser != null){
                for(Id idReqSA : mapIdSAReqIdUser.KeySet()){
                    if (mapIdSAReqIdUser.get(idReqSA) != null){
                        SpecialAcceptance__Share saShare = new SpecialAcceptance__Share();
                        saShare.RowCause = 'Manual';
                        saShare.AccessLevel = 'Edit';
                        saShare.ParentId = idReqSA;
                        saShare.UserOrGroupId = mapIdSAReqIdUser.get(idReqSA);
                        lstSAShare.add(saShare);
                    }
                }
            }
            
            System.debug('createSharingForContact___lstAccountShareToInsert= ' + lstAccountShareToInsert);
            System.debug('createSharingForContact___lstRequestShareToInsert= ' + lstRequestShareToInsert);
            System.debug('createSharingForContact___lstRequestShareToInsertSIZE= ' + lstRequestShareToInsert.SIZE());
            System.debug('createSharingForContact___lstSAShare= ' + lstSAShare);
            
            if (lstAccountShareToInsert != null && lstAccountShareToInsert.size() < Limits.getDMLRows()){
                upsert lstAccountShareToInsert;
            }
       
            if (lstAccountShareToInsert != null && lstAccountShareToInsert.size() < 9000 - Limits.getDMLRows()){
                upsert lstAccountShareToInsert;
            }

            if (lstRequestShareToInsert != null && lstRequestShareToInsert.size() < 9000 - Limits.getDMLRows()){
                upsert lstRequestShareToInsert;
            }else{
                BAT001_InsertSharingBigQuantity batchInsertReqShare = new BAT001_InsertSharingBigQuantity(lstRequestShareToInsert);
                Database.executeBatch(batchInsertReqShare, 500);                        
            }

            if (lstSAShare != null && lstSAShare.size() < 9000 - Limits.getDMLRows()){
                upsert lstSAShare;
            }

            System.debug('createSharingBigQuantityForContact__lstAccountShareToInsert =  ' + lstAccountShareToInsert.size() + ' Done successfully');
            System.debug('createSharingBigQuantityForContact__InsertionRequestShare =  ' + lstRequestShareToInsert.size() + ' Done successfully');
            System.debug('createSharingBigQuantityForContact__InsertionSAShare =  ' + lstSAShare.size() + ' Done successfully');
            
        }
    }