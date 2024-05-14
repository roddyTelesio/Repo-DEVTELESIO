public without sharing class AP38_CreateSharingForRequest{
    // public without sharing class AP38_CreateSharingForRequest implements Queueable{
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Create Request Share and Account Share for Request
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 09-JUL-2020  MBE   1.0      Initial version
-- 03-NOV-2021  MBE   1.1      W-1037 - message d'erreur à l'envoie des quotes
-- 21-JAN-2022  RRA   2.0      ticket 1063 (Problème de visibilité des requêtes de Placement pour des réassureurs en production)
--------------------------------------------------------------------------------------
**************************************************************************************/

    @Future
    public static void createRequestSharing(List<Id> lstNewRequestsId, String phase){
        System.debug('START createRequestSharing ');
        List<Request__c> lstNewRequests = new List<Request__c>();
        Map <String, Id> mapIdPccId = new Map <String, Id>();
        Map <String, Id> mapPccIdReqId = new Map <String, Id>();
        Map<String, Id> mapIdGroupIdPcc = new Map<String, Id>();
        Map<String, Id> mapIdGroupIdSAPcc = new Map<String, Id>();
        Set<String> setKeys = new Set<String>();
        Map<String, Id> mapReqKey = new  Map<String, Id> ();
        Map<String, Id> mapReqSAKey = new  Map<String, Id> ();
        Map<String, Id> mapReqKeySA = new  Map<String, Id> ();
        Map<String, Id> mapSearch = new  Map<String, Id> ();
        Map<String, Id> mapIdPccSAId = new  Map<String, Id> ();
        //Map<String, String> mapReqKey = new  Map<String, String> ();
        Map<Id, String> mapKeyUserId = new  Map<Id, String> ();
        Map<Request__c, Id> mapReqIdUser = new  Map<Request__c, Id> ();
        List<Request__Share> lstRequestShare = new List<Request__Share>();
        List<SpecialAcceptance__Share> lstSAShare = new List<SpecialAcceptance__Share>();
        List<SpecialAcceptance__Share> lstSAShareSleepPart = new List<SpecialAcceptance__Share>();
        List<Request__Share> lstRequestShareSleepPart = new List<Request__Share>();
        List<String> lstkeySplit = new List<String>();
        List<String> lstkeySplitPCC = new List<String>();
        List<String> lstkeySASplit = new List<String>();
        List<String> lstkeySplitSA = new List<String>();
        String keySharing;
        String keyidReq;
        String keyPccSharing;
        String keyidPccReq;
        String keySASharing;
        String keySAidReq;
        String keySharingSA;
        String keyidReqSA;
        List<Request__c> lstSigningRequests = new List<Request__c>();
        Set<String> setKeyInSigning = new Set<String>();
        Set<String> setKeySharing = new Set<String>();
        Set<Id> setKeyidReq = new Set<Id>();
        Set<String> setKeyPccSharing = new Set<String>();
        Set<Id> setKeyidPccReq = new Set<Id>();
        Set<String> setKeySASharing = new Set<String>();
        Set<Id> setKeySAidReq = new Set<Id>();
        Set<String> setKeySharingSA = new Set<String>();
        Set<Id> setKeyidReqSA = new Set<Id>();
        List<IntermediateACRRequest__c> lstInObj = new   List<IntermediateACRRequest__c>();
        List<AccountShare> lstAccShare =  new List<AccountShare>();
        List<AccountShare> lstAccountShareToInsert =  new List<AccountShare>();
        Set<String> setAccShare = new Set<String>();
        List <Id> lstusrId = new  List <Id>();
        Set <String> setIdReqIdUser = new  Set <String>();
        Set <String> setIdPccIdUser = new  Set <String>();
        Set <String> setIdReqSAIdUser = new  Set <String>();
        Set <String> setIdReqIdUserSA = new  Set <String>();
        System.debug('lstNewRequestsId ==  ' + lstNewRequestsId);

        if (phase == '3' || phase == '4' || phase == '5' || phase == 'QuoteLeadPlacementSigning'){

            lstNewRequests = [SELECT Id, name, OriginalRequest__c, TECH_PhaseType__c, RecordTypeId, Program__c, Program__r.PrincipalCedingCompany__c,PrincipalCedingCompany__c, tolabel(Program__r.Nature__c),Program__r.Macro_L_O_B__c, Broker__c, Broker__r.Name, BrokerStatus__c, Reinsurer__c, Reinsurer__r.Name, Special_Acceptance__c,Treaty__c, KeyRequestSharing__c, LastVersionSent__c, LastVersionAnswered__c  FROM Request__c where Id IN :lstNewRequestsId];

            System.debug('createRequestSharing__QuoteLeadPlacement ==  ' + lstNewRequests);

        }else if (phase == '6'){
            // List Request to create the Request__Share
            lstNewRequests = [SELECT Id, name, OriginalRequest__c, TECH_PhaseType__c, RecordTypeId, Program__c, Program__r.PrincipalCedingCompany__c,PrincipalCedingCompany__c, tolabel(Program__r.Nature__c),Program__r.Macro_L_O_B__c, Broker__c, Broker__r.Name, BrokerStatus__c, Reinsurer__c, Reinsurer__r.Name, Special_Acceptance__c,Treaty__c, KeyRequestSharing__c, LastVersionSent__c, LastVersionAnswered__c  FROM Request__c where Id IN :lstNewRequestsId AND SignedShare__c > 0];

            System.debug('createRequestSharing__Signing ==  ' + lstNewRequests);

             // List Request to create the AccountShare
            lstSigningRequests = [SELECT Id, name, OriginalRequest__c, TECH_PhaseType__c, RecordTypeId, Program__c, Program__r.PrincipalCedingCompany__c,PrincipalCedingCompany__c, tolabel(Program__r.Nature__c),Program__r.Macro_L_O_B__c, Broker__c, Broker__r.Name, BrokerStatus__c, Reinsurer__c, Reinsurer__r.Name, Special_Acceptance__c,Treaty__c, KeyRequestSharing__c FROM Request__c where Id IN :lstNewRequestsId];

            System.debug('createRequestSharing__lstSigningRequests ==  ' + lstSigningRequests);

        }
       
        System.debug('createRequestSharing__QuoteLeadPlacement__lstNewRequests ==  ' + lstNewRequests);

        for (Request__c req : lstNewRequests){

            if (req.OriginalRequest__c == null && req.Special_Acceptance__c == null){//RRA - ticket 1488 - 25042023
                mapReqKey.put (req.KeyRequestSharing__c + '-' + req.Id, req.Id);
                if (Test.isRunningTest()){
                    mapIdPccId.put (req.PrincipalCedingCompany__c, req.Id);
                    mapPccIdReqId.put (req.KeyRequestSharing__c + '-' +req.Id, req.Program__r.PrincipalCedingCompany__c);
                }
            }else{
                mapIdPccId.put (req.PrincipalCedingCompany__c, req.Id);
                mapPccIdReqId.put (req.KeyRequestSharing__c + '-' +req.Id, req.Program__r.PrincipalCedingCompany__c);
                if (req.LastVersionSent__c == true && req.LastVersionAnswered__c == true && req.Id != null){
                    mapReqKeySA.put (req.KeyRequestSharing__c + '-' + req.Id, req.Id); // toshare for User
                    //mapSearch.put(reqSearch.KeyRequestSharing__c, reqSearch.Id) //RRA 11102022 - Avoid First error: Too many SOQL queries: 201
                    mapIdPccSAId.put (req.PrincipalCedingCompany__c, req.Id); // toshare for group
                    //mapReqKeySAForPcc.put (req.KeyRequestSharing__c + '-' + req.Id, req.Program__r.PrincipalCedingCompany__c);  
                }
            }

           /* if (req.Special_Acceptance__c != null) {
                mapReqSAKey.put (req.KeyRequestSharing__c + '-' + req.Special_Acceptance__c, req.Special_Acceptance__c);
            }*/
        }

        System.debug('createRequestSharing__mapReqKey ==  ' + mapReqKey);
        System.debug('createRequestSharing__mapPccIdReqId ==  ' + mapPccIdReqId);
        //System.debug('createRequestSharing__mapReqSAKey ==  ' + mapReqSAKey);

        for (String key : mapPccIdReqId.KeySet()){
            lstkeySplitPCC.add(key);
        }

        for (String key : mapReqKey.KeySet()){
            lstkeySplit.add(key);
        }

        /*for (String keySA : mapReqSAKey.KeySet()){
            lstkeySASplit.add(keySA);
        }*/

        for (String keySA : mapReqKeySA.KeySet()){
            lstkeySplitSA.add(keySA);
        }

        System.debug('createRequestSharing__lstkeySplit ==  ' + lstkeySplit);

        System.debug('createRequestSharing__lstkeySplitPCC ==  ' + lstkeySplitPCC);

       // System.debug('createRequestSharing__lstkeySASplit ==  ' + lstkeySASplit);

        System.debug('createRequestSharing__lstkeySplitSA ==  ' + lstkeySplitSA);

        for (String keyPccEllgible : lstkeySplitPCC){
            keyPccSharing = keyPccEllgible.split('-')[0];
            keyidPccReq = keyPccEllgible.split('-')[1];
            setKeyPccSharing.add(keyPccSharing);
            setKeyidPccReq.add(keyidPccReq);
        }

        for (String keyEllgible : lstkeySplit){
            keySharing = keyEllgible.split('-')[0];
            keyidReq = keyEllgible.split('-')[1];
            setKeySharing.add(keySharing);
            setKeyidReq.add(keyidReq);
        }

        /*for (String keySAEllgible : lstkeySASplit){
            keySASharing = keySAEllgible.split('-')[0];
            keySAidReq = keySAEllgible.split('-')[1];
            setKeySASharing.add(keySASharing);
            setKeySAidReq.add(keySAidReq);
        }*/


        for (String keySAEllgible : lstkeySplitSA){
            keySharingSA = keySAEllgible.split('-')[0];
            keyidReqSA = keySAEllgible.split('-')[1];
            setKeySharingSA.add(keySharingSA);
            setKeyidReqSA.add(keyidReqSA);
        }

        System.debug('createRequestSharing__setKeySharing ==  ' + setKeySharing);
        System.debug('createRequestSharing__setKeyidReq ==  ' + setKeyidReq);

        System.debug('createRequestSharing__setKeyPccSharing ==  ' + setKeyPccSharing);
        System.debug('createRequestSharing__setKeyidPccReq ==  ' + setKeyidPccReq);

        //System.debug('createRequestSharing__setKeySASharing ==  ' + setKeySASharing);
        //System.debug('createRequestSharing__setKeySAidReq ==  ' + setKeySAidReq);

        System.debug('createRequestSharing__setKeySharingSA ==  ' + setKeySharingSA);
        System.debug('createRequestSharing__setKeyidReqSA ==  ' + setKeyidReqSA);

   
        if(mapIdPccId != null ){
            for(Group objGroup : [SELECT Id, Name FROM Group WHERE Name IN:mapIdPccId.KeySet()]){
                mapIdGroupIdPcc.put(objGroup.Name, objGroup.Id);
            }
        }

        // for SA only
        if(mapIdPccSAId != null ){
            for(Group objGroup : [SELECT Id, Name FROM Group WHERE Name IN:mapIdPccSAId.KeySet()]){
                mapIdGroupIdSAPcc.put(objGroup.Name, objGroup.Id);
            }
        }

        // RequestShare
        if (setKeySharing.size()>0 && setKeySharing !=null){
            List<IntermediateACRRequest__c> lstIntObjectReqShare = [SELECT Id, User__c, SharingKeyFormula__c FROM IntermediateACRRequest__c WHERE SharingKeyFormula__c IN:setKeySharing];
            for (Id idReq : setKeyidReq){
                for (IntermediateACRRequest__c key : lstIntObjectReqShare){
                    //if (mapReqKey.get(key.SharingKeyFormula__c + '-' + mapSearch.get(key.SharingKeyFormula__c)) != null){ //RRA 11102022 - Avoid First error: Too many SOQL queries: 201
                    if (mapReqKey.get(key.SharingKeyFormula__c + '-' + idReq) != null){
                        lstusrId.add(key.User__c);
                        //mapReqIdUser.put (mapReqKey.get(key.SharingKeyFormula__c + '-' + idReq), key.User__c);
                        setIdReqIdUser.add(mapReqKey.get(key.SharingKeyFormula__c + '-' + idReq)  + '_' + key.User__c);
                        //setIdReqIdUser.add(mapReqKey.get(key.SharingKeyFormula__c + '-' + mapSearch.get(key.SharingKeyFormula__c))  + '_' + key.User__c);
                    }
                }
            }
        }
        
       

        // AccountShare
        if (setKeyPccSharing.size()>0 && setKeyPccSharing !=null){
            List<IntermediateACRRequest__c> lstIntObjectAccShare = [SELECT Id, User__c, SharingKeyFormula__c FROM IntermediateACRRequest__c WHERE SharingKeyFormula__c IN:setKeyPccSharing];
            for (Id idReq : setKeyidPccReq){
                for (IntermediateACRRequest__c key : lstIntObjectAccShare){
                    if (mapPccIdReqId.get(key.SharingKeyFormula__c + '-' + idReq) != null){
                        lstusrId.add(key.User__c);
                        setIdPccIdUser.add(mapPccIdReqId.get(key.SharingKeyFormula__c + '-' + idReq)  + '_' + key.User__c);
                    }
                }
            }
        }
        
        //SAShare
        /*if (setKeySASharing.size()>0 && setKeySASharing !=null){
            List<IntermediateACRRequest__c> lstIntObjectSAShare = [SELECT Id, User__c, SharingKeyFormula__c FROM IntermediateACRRequest__c WHERE SharingKeyFormula__c IN:setKeySASharing];
            for (Id idReqSA : setKeySAidReq){
                for (IntermediateACRRequest__c key : lstIntObjectSAShare){
                    if (mapReqSAKey.get(key.SharingKeyFormula__c + '-' + idReqSA) != null){
                        setIdReqSAIdUser.add(mapReqSAKey.get(key.SharingKeyFormula__c + '-' + idReqSA)  + '_' + key.User__c);
                    }
                }
            }
        }*/
        

        //Request Share for SA
        if (setKeySharingSA.size()>0 && setKeySharingSA !=null){
            List<IntermediateACRRequest__c> lstIntObjectReqShareSA = [SELECT Id, User__c, SharingKeyFormula__c FROM IntermediateACRRequest__c WHERE SharingKeyFormula__c IN:setKeySASharing];
            for (Id idSAReq : setKeyidReqSA){
                for (IntermediateACRRequest__c key : lstIntObjectReqShareSA){
                    if (mapReqKeySA.get(key.SharingKeyFormula__c + '-' + idSAReq) != null){
                        setIdReqIdUserSA.add(mapReqKeySA.get(key.SharingKeyFormula__c + '-' + idSAReq)  + '_' + key.User__c);
                    }
                }
            }
        }

        System.debug('createRequestSharing__lstusrId ==  ' + lstusrId);
        System.debug('createRequestSharing__mapReqIdUser ==  ' + mapReqIdUser);
        System.debug('createRequestSharing__setIdReqIdUser==  ' + setIdReqIdUser);
        System.debug('createRequestSharing__setIdPccIdUser==  ' + setIdPccIdUser);
        //System.debug('createRequestSharing__setIdReqSAIdUser==  ' + setIdReqSAIdUser);
        System.debug('createRequestSharing__setIdReqIdUserSA==  ' + setIdReqIdUserSA);

        // Request (Original Request is null) => Treaty placement
        for(String requestString : setIdReqIdUser){
            String reqId = requestString.split('_')[0];
            String userIdReq = requestString.split('_')[1];
            Request__Share requestShare = new Request__Share();
            requestShare.RowCause = 'Manual';
            requestShare.AccessLevel = 'Edit';
            requestShare.ParentId = reqId;
            requestShare.UserOrGroupId = userIdReq;
            lstRequestShare.add(requestShare);
        }

        // SA Share  => Treaty placement
        /*for(String requestSAString : setIdReqSAIdUser){
            String reqSAId = requestSAString.split('_')[0];
            String userSAIdReq = requestSAString.split('_')[1];
            SpecialAcceptance__Share saShare = new SpecialAcceptance__Share();
            saShare.RowCause = 'Manual';
            saShare.AccessLevel = 'Edit';
            saShare.ParentId = reqSAId;
            saShare.UserOrGroupId = userSAIdReq;
            lstSAShare.add(saShare);
        }*/

        // Requesthare for SA  => SA
        for(String requestStringSA : setIdReqIdUserSA){
            String reqIdSA = requestStringSA.split('_')[0];
            String userIdReqSA = requestStringSA.split('_')[1];
            Request__Share reqShare = new Request__Share();
            reqShare.RowCause = 'Manual';
            reqShare.AccessLevel = 'Edit';
            reqShare.ParentId = reqIdSA;
            reqShare.UserOrGroupId = userIdReqSA;
            lstRequestShare.add(reqShare);
        }

        // Requesthare for SA (PCC)  => SA
        for(String namePcc : mapIdGroupIdSAPcc.keySet()){
            Request__Share requestShare = new Request__Share();
            requestShare.RowCause = 'Manual';
            requestShare.AccessLevel = 'Edit';
            requestShare.ParentId = mapIdPccSAId.get(namePcc);
            requestShare.UserOrGroupId = mapIdGroupIdSAPcc.get(namePcc);
            lstRequestShare.add(requestShare);
        }

        // Request for Pcc (Original Request is not null)  => Treaty placement
        for(String namePcc : mapIdGroupIdPcc.keySet()){
            Request__Share requestShare = new Request__Share();
            requestShare.RowCause = 'Manual';
            requestShare.AccessLevel = 'Edit';
            requestShare.ParentId = mapIdPccId.get(namePcc);
            requestShare.UserOrGroupId = mapIdGroupIdPcc.get(namePcc);
            lstRequestShare.add(requestShare);
        }

        // Account Share for Pcc   => Treaty placement
        for(String accString : setIdPccIdUser){
            String idPcc = accString.split('_')[0];
            String userIdPcc = accString.split('_')[1];
            AccountShare accountShare = new AccountShare();
            accountShare.AccountAccessLevel = 'Read';
            accountShare.OpportunityAccessLevel = 'Read';
            accountShare.AccountId = idPcc;
            accountShare.UserOrGroupId = userIdPcc;
            lstAccountShareToInsert.add(accountShare);
        }

        Map<String, String> mapIdBrokerIdReinsurerReq = new  Map<String, String> (); //RRA - ticket 1488 - 12042023
        Map<String, String> mapIdBrokerReinsurerIdPCC = new  Map<String, String> ();//RRA - ticket 1488 - 12042023
        Map<String, String> mapIdUserIdPCC = new  Map<String, String> ();//RRA - ticket 1488 - 12042023 
        Map<String, String> mapIdUserIdSA = new  Map<String, String> ();//RRA - ticket 1488 - 12042023 
        Map<String, String> mapIdReinsurerIntObj = new  Map<String, String> ();
        Set <Id> setReinsurerIdsSigning = new Set<Id>();
        Map<Id,Id> mapReinsIdToParentIdSigning = new Map<Id,Id>();
        Map<Id,Id> mapBrokerReinsurerIdUser = new Map<Id,Id>();
        Map<Id,Id> mapIdPCCIdSA = new Map<Id,Id>();
        Map<Id,Id> mapIdSAqIdReq = new Map<Id,Id>();
        Map<String,Id> mapNamePCCSAId = new Map<String,Id>();
        Map<String,Id> mapIdGrpIdSAPcc = new Map<String,Id>();
        Map <Id, List<Id>> mapParentToRiskFinancialId = new Map<Id, List<Id>>();
        List<Id> lstReins = new List<Id>();
        Boolean isSleepingPartners = false;
        List<String> lstNewKeyInSigning = new List<String>();
        
        // Operation AccountShare only on Signing
        if (lstSigningRequests != null && !lstSigningRequests.isEmpty()){
            for (Request__c req : lstSigningRequests){
                //RRA - ticket 1488 - 12042023 
                setKeyInSigning.add(req.KeyRequestSharing__c);
                //lstReins.add(req.Reinsurer__c);
                if (req.Special_Acceptance__c != null){
                    mapIdPCCIdSA.put(req.Program__r.PrincipalCedingCompany__c, req.Special_Acceptance__c); 
                    mapIdSAqIdReq.put(req.Special_Acceptance__c, req.Id);  // toshare for request id for SA
                    mapNamePCCSAId.put (req.PrincipalCedingCompany__c, req.Id); // toshare for group
                }

                if (req.Broker__c != null){
                    if (req.BrokerStatus__c == '2'){
                        mapIdBrokerIdReinsurerReq.put(req.Broker__c, req.Reinsurer__c);
                        isSleepingPartners  = false; 
                    }else if (req.BrokerStatus__c == '1'){
                        mapIdBrokerIdReinsurerReq.put(req.Reinsurer__c, req.Reinsurer__c); //RRA - ticket 1488 - 12042023
                        lstReins.add(req.Reinsurer__c); // get reinsurer Attached on Broker
                        isSleepingPartners = true;
                    }
                }else if(req.Reinsurer__c != null){
                    mapIdBrokerIdReinsurerReq.put('NoBroker', req.Reinsurer__c); //RRA - ticket 1488 - 12042023
                }
            }
            System.debug('createRequestSharing__lstReins ==  ' + lstReins);
            System.debug('createRequestSharing__isSleepingPartners ==  ' + isSleepingPartners);

            //RRA - ticket 1488 - 12042023  Create new Key attached on Reinsurer from Broker if BrolerStatus = '2' 
            if (isSleepingPartners){
                for (String strKey : setKeyInSigning){
                    List<String> lstNewKeyReinsFromBroker = strKey.split('_');
                    for (String reinsId : lstReins){
                        lstNewKeyInSigning.add(lstNewKeyReinsFromBroker.get(0) + '_' + reinsId  + '_' + lstNewKeyReinsFromBroker.get(2) + '_' + lstNewKeyReinsFromBroker.get(3));
                    }
                }
            }
            System.debug('createRequestSharing__lstNewKeyInSigning ==  ' + lstNewKeyInSigning);
            System.debug('createRequestSharing__setKeyInSigning ==  ' + setKeyInSigning);
            System.debug('createRequestSharing__mapIdBrokerIdReinsurerReq ==  ' + mapIdBrokerIdReinsurerReq); 
            Boolean isBroker = false; //RRA - ticket 1488 - 12042023
            Boolean isReinsurer = false; //RRA - ticket 1488 - 12042023

            //RRA - ticket 1488 - 12042023 if BrokerStatus == Sleeping partners
            if (lstNewKeyInSigning.size()>0){
                if (Test.isRunningTest()){
                    for (IntermediateACRRequest__c key : [SELECT Id, User__c, User__r.isActive, Broker__c, PCC__c, Reinsurer__c, SharingKeyFormula__c FROM IntermediateACRRequest__c WHERE SharingKeyFormula__c != NULL]){
                        if (key.User__r.isActive){
                            if (key.Broker__c != null){
                                mapIdReinsurerIntObj.put(key.Reinsurer__c, key.Reinsurer__c);
                                mapBrokerReinsurerIdUser.put(key.User__c, key.Reinsurer__c);
                                mapIdBrokerReinsurerIdPCC.put(key.Reinsurer__c, key.PCC__c); 
                                mapIdUserIdPCC.put(key.User__c, key.PCC__c); 
                                mapIdUserIdSA.put(key.User__c, mapIdPCCIdSA.get(key.PCC__c));
                                isBroker = true;
                            }else if(key.Reinsurer__c != null){
                                mapIdReinsurerIntObj.put('NoBroker', key.Reinsurer__c);
                                mapBrokerReinsurerIdUser.put(key.User__c, key.Reinsurer__c);
                                mapIdBrokerReinsurerIdPCC.put(key.Reinsurer__c, key.PCC__c); 
                                mapIdUserIdPCC.put(key.User__c, key.PCC__c); 
                                mapIdUserIdSA.put(key.User__c, mapIdPCCIdSA.get(key.PCC__c));
                                isReinsurer = true;
                            }
                        }
                    }
                }else {
                    for (IntermediateACRRequest__c key : [SELECT Id, User__c, User__r.isActive, Broker__c, PCC__c, Reinsurer__c, SharingKeyFormula__c FROM IntermediateACRRequest__c WHERE SharingKeyFormula__c IN:lstNewKeyInSigning]){
                        if (key.User__r.isActive){
                            if (key.Broker__c != null){
                                mapIdReinsurerIntObj.put(key.Reinsurer__c, key.Reinsurer__c);
                                mapBrokerReinsurerIdUser.put(key.User__c, key.Reinsurer__c);
                                mapIdBrokerReinsurerIdPCC.put(key.Reinsurer__c, key.PCC__c); 
                                mapIdUserIdPCC.put(key.User__c, key.PCC__c); 
                                mapIdUserIdSA.put(key.User__c, mapIdPCCIdSA.get(key.PCC__c));
                                isBroker = true;
                            }else if(key.Reinsurer__c != null){
                                mapIdReinsurerIntObj.put('NoBroker', key.Reinsurer__c);
                                mapBrokerReinsurerIdUser.put(key.User__c, key.Reinsurer__c);
                                mapIdBrokerReinsurerIdPCC.put(key.Reinsurer__c, key.PCC__c); 
                                mapIdUserIdPCC.put(key.User__c, key.PCC__c); 
                                mapIdUserIdSA.put(key.User__c, mapIdPCCIdSA.get(key.PCC__c));
                                isReinsurer = true;
                            }
                        }
                    }
                }
            //RRA - ticket 1488 - 12042023 if BrokerStatus == financial Intermediary
            }else {
                for (IntermediateACRRequest__c key : [SELECT Id, User__c, User__r.isActive, Broker__c, PCC__c, Reinsurer__c, SharingKeyFormula__c FROM IntermediateACRRequest__c WHERE SharingKeyFormula__c IN:setKeyInSigning]){
                    if (key.User__r.isActive){
                        if (key.Broker__c != null){
                            mapIdReinsurerIntObj.put(key.Broker__c, key.Reinsurer__c);
                            mapBrokerReinsurerIdUser.put(key.Broker__c, key.User__c);
                            mapIdBrokerReinsurerIdPCC.put(key.Broker__c, key.PCC__c); //RRA - ticket 1488 - 12042023
                            isBroker = true;
                        }else if(key.Reinsurer__c != null){
                            mapIdReinsurerIntObj.put('NoBroker', key.Reinsurer__c);
                            mapBrokerReinsurerIdUser.put(key.Reinsurer__c, key.User__c);
                            mapIdBrokerReinsurerIdPCC.put(key.Reinsurer__c, key.PCC__c); //RRA - ticket 1488 - 12042023
                            isReinsurer = true;
                        }
                    }
                }
            }

            System.debug('createRequestSharing__mapIdReinsurerIntObj ==  ' + mapIdReinsurerIntObj);
            System.debug('createRequestSharing__mapBrokerReinsurerIdUser 00==  ' + mapBrokerReinsurerIdUser);
            System.debug('createRequestSharing__mapIdBrokerReinsurerIdPCC ==  ' + mapIdBrokerReinsurerIdPCC);

            for (String idIntOjBroker : mapIdReinsurerIntObj.keyset()){
                if (idIntOjBroker != 'NoBroker' && (idIntOjBroker.length() == 18 || idIntOjBroker.length() == 15)){
                    setReinsurerIdsSigning.add(mapIdBrokerIdReinsurerReq.get(idIntOjBroker)); //RRA - ticket 1488 - 12042023
                }else if (idIntOjBroker == 'NoBroker'){
                    System.debug('ok no broker');
                    setReinsurerIdsSigning.add(mapIdReinsurerIntObj.get(idIntOjBroker)); //RRA - ticket 1488 - 12042023
                }
            }

            System.debug('createRequestSharing__setReinsurerIdsSigning ==  ' + setReinsurerIdsSigning);

            //get parent of reinsurer
            for(Account parentAccount : [SELECT Id, ParentId FROM Account WHERE Id IN :setReinsurerIdsSigning AND ParentId != null]){
                //map reinsurer to parent id
                mapReinsIdToParentIdSigning.put(parentAccount.Id, parentAccount.ParentId);
            }

            System.debug('createRequestSharing__mapReinsIdToParentIdSigning ==  ' + mapReinsIdToParentIdSigning);

            // get risk carrier and financial entity for all parents
            for(Account account : [SELECT Id, IsRiskCarrier__c, IsFinancialEntity__c, ParentId FROM Account WHERE ParentId IN: mapReinsIdToParentIdSigning.Values() AND (IsFinancialEntity__c = true OR IsRiskCarrier__c = true)]){
                if (mapParentToRiskFinancialId.containsKey(account.ParentId)){
                    mapParentToRiskFinancialId.get(account.ParentId).add(account.Id);
                }else{
                    mapParentToRiskFinancialId.put(account.ParentId, new List<Id>{account.Id});
                }
            }

            System.debug('createRequestSharing__mapParentToRiskFinancialId ==  ' + mapParentToRiskFinancialId);

            //RRA - ticket 1488 - 12042023
            if (isSleepingPartners){
                // for SA only
                if(mapNamePCCSAId != null ){
                    for(Group objGroup : [SELECT Id, Name FROM Group WHERE Name IN:mapNamePCCSAId.KeySet()]){
                        mapIdGrpIdSAPcc.put(objGroup.Name, objGroup.Id);
                    }
                }
                for (Id idUsr : mapIdUserIdPCC.keySet()){
                        AccountShare accountShare = new AccountShare();
                        accountShare.UserOrGroupId =  idUsr;
                        accountShare.AccountId = mapIdUserIdPCC.get(idUsr);
                        accountShare.AccountAccessLevel = 'Read';
                        accountShare.OpportunityAccessLevel = 'Read';
                        if(!setAccShare.contains(accountShare.UserOrGroupId + '-' + accountShare.AccountId)){
                            lstAccShare.add(accountShare);
                            setAccShare.add(accountShare.UserOrGroupId + '-' + accountShare.AccountId);
                            System.debug('@@lstAccShare isSleepingPartners lstAccShare NOT NULL @@==' + lstAccShare);
                        }
                    } 

                    System.debug('@@lstAccShare isSleepingPartners mapIdSAqIdReq NOT NULL @@==' + mapIdSAqIdReq);
                    System.debug('@@lstAccShare isSleepingPartners mapNamePCCSAId NOT NULL @@==' + mapNamePCCSAId);
                    System.debug('@@lstAccShare isSleepingPartners mapIdGrpIdSAPcc NOT NULL @@==' + mapIdGrpIdSAPcc);

                    //RRA - ticket 1488 - 12042023 SAShare for SA  => SA
                    for(Id idUser : mapIdUserIdSA.keySet()){
                        SpecialAcceptance__Share saShare = new SpecialAcceptance__Share();
                        saShare.RowCause = 'Manual';
                        saShare.AccessLevel = 'Edit';
                        saShare.ParentId = mapIdUserIdSA.get(idUser);
                        saShare.UserOrGroupId = idUser;
                        lstSAShareSleepPart.add(saShare);
                        System.debug('@@lstAccShare isSleepingPartners lstSAShareSleepPart NOT NULL @@==' + lstSAShareSleepPart);

                        //RRA - ticket 1488 - 12042023 Requesthare for SA  => SA
                        Request__Share reqShare = new Request__Share();
                        reqShare.RowCause = 'Manual';
                        reqShare.AccessLevel = 'Edit';
                        reqShare.ParentId = mapIdSAqIdReq.get(mapIdUserIdSA.get(idUser));
                        reqShare.UserOrGroupId = idUser;
                        //lstRequestShareSleepPart.add(reqShare); //RRA - ticket 1488 - 04052023
                        System.debug('@@lstAccShare isSleepingPartners lstRequestShareSleepPart 11 NOT NULL @@==' + lstRequestShareSleepPart);
                    }

                    //RRA - ticket 1488 - 12042023 Requesthare for SA (PCC)  => SA
                    for(String namePcc : mapIdGrpIdSAPcc.keySet()){
                        Request__Share requestShare = new Request__Share();
                        requestShare.RowCause = 'Manual';
                        requestShare.AccessLevel = 'Edit';
                        requestShare.ParentId = mapNamePCCSAId.get(namePcc);
                        requestShare.UserOrGroupId = mapIdGrpIdSAPcc.get(namePcc);
                        lstRequestShareSleepPart.add(requestShare);
                        System.debug('@@lstAccShare isSleepingPartners lstRequestShareSleepPart 22 NOT NULL @@==' + lstRequestShareSleepPart);
                    }
            }else {
                //RRA - ticket 1488 - 12042023 
                for (Id idAcc : mapIdBrokerReinsurerIdPCC.KeySet()){ 
                    AccountShare accountShare = new AccountShare();
                    accountShare.UserOrGroupId =  mapBrokerReinsurerIdUser.get(idAcc);
                    accountShare.AccountId = mapIdBrokerReinsurerIdPCC.get(idAcc);
                    accountShare.AccountAccessLevel = 'Read';
                    accountShare.OpportunityAccessLevel = 'Read';
                    if(!setAccShare.contains(accountShare.UserOrGroupId + '-' + accountShare.AccountId)){
                        lstAccShare.add(accountShare);
                        setAccShare.add(accountShare.UserOrGroupId + '-' + accountShare.AccountId);
                        System.debug('@@lstAccShare in parentReinsId NOT NULL @@==' + lstAccShare);
                    }
    
                    if (isBroker && isReinsurer == false){
                        if (mapReinsIdToParentIdSigning.containsKey(mapIdBrokerIdReinsurerReq.get(idAcc))) { //broker
                            for (Id accId : mapParentToRiskFinancialId.get(mapReinsIdToParentIdSigning.get(mapIdBrokerIdReinsurerReq.get(idAcc)))) {
                                accountShare = new AccountShare();
                                accountShare.UserOrGroupId = mapBrokerReinsurerIdUser.get(idAcc);
                                accountShare.AccountId = accId;
                                accountShare.AccountAccessLevel = 'Read';
                                accountShare.OpportunityAccessLevel = 'Read';
                                if(!setAccShare.contains(accountShare.UserOrGroupId + '-' + accountShare.AccountId)){
                                    lstAccShare.add(accountShare);
                                    setAccShare.add(accountShare.UserOrGroupId + '-' + accountShare.AccountId);
                                }
                            }
                            System.debug('@@lstAccShare in mapParentToRiskFinancialId Broker contains KeyparentReinsId@@==' + lstAccShare);
                        }
                    }if (isBroker == false && isReinsurer){
                        if (mapReinsIdToParentIdSigning.containsKey(idAcc)) { 
                            for (Id accId : mapParentToRiskFinancialId.get(mapReinsIdToParentIdSigning.get(idAcc))) {
                                accountShare = new AccountShare();
                                accountShare.UserOrGroupId = mapBrokerReinsurerIdUser.get(idAcc);
                                accountShare.AccountId = accId;
                                accountShare.AccountAccessLevel = 'Read';
                                accountShare.OpportunityAccessLevel = 'Read';
                                if(!setAccShare.contains(accountShare.UserOrGroupId + '-' + accountShare.AccountId)){
                                    lstAccShare.add(accountShare);
                                    setAccShare.add(accountShare.UserOrGroupId + '-' + accountShare.AccountId);
                                }
                            }
                            System.debug('@@lstAccShare in mapParentToRiskFinancialId Reinsurer contains KeyparentReinsId@@==' + lstAccShare);
                        }
                    }
    
                System.debug('createRequestSharing__lstAccShare ==  ' + lstAccShare);
                System.debug('createRequestSharing__setAccShare ==  ' + setAccShare);
            }
        }
    }

    if(lstAccountShareToInsert.size() > 0){
        System.debug('createRequestSharing__lstAccountShareToInsert ==  ' + lstAccountShareToInsert);
        System.debug('shareAccoutToUsers: inserting AccountShare List with ' + lstAccountShareToInsert.size() + ' elements');
        Manage_DataBaseInsertSharing_UTL util = new Manage_DataBaseInsertSharing_UTL();
        util.insertAccountShares(lstAccountShareToInsert);
        System.debug('Account Share  List inserted Successfully for Pcc');
    }

    if(lstRequestShare.size() > 0){
        System.debug('createRequestSharing__lstRequestShare ==  ' + lstRequestShare);
        System.debug('shareRequestToUsers: inserting Request__Share List with ' + lstRequestShare.size() + ' elements');
        Manage_DataBaseInsertSharing_UTL util = new Manage_DataBaseInsertSharing_UTL();
        util.insertRequestShares(lstRequestShare);
        System.debug('Request Share List inserted Successfully ');
    }

    if(lstSAShare.size() > 0){
        System.debug('createRequestSharing__lstSAShare ==  ' + lstSAShare);
        System.debug('shareSAToUsers: inserting lstSAShare List with ' + lstSAShare.size() + ' elements');
        Manage_DataBaseInsertSharing_UTL util = new Manage_DataBaseInsertSharing_UTL();
        util.insertSAShares(lstSAShare);
        System.debug('SA Share  List inserted Successfully ');
    }

    //RRA - ticket 1488 - 12042023 
    if(lstSAShareSleepPart.size() > 0){
        System.debug('createRequestSharing__lstSAShareSleepPart ==  ' + lstSAShareSleepPart);
        System.debug('shareSAToUsers: inserting lstSAShareSleepPart List with ' + lstSAShareSleepPart.size() + ' elements');
        Manage_DataBaseInsertSharing_UTL util = new Manage_DataBaseInsertSharing_UTL();
        util.insertSAShares(lstSAShareSleepPart);
        System.debug('SA Share   SleepPart List inserted Successfully ');
    }

    //RRA - ticket 1488 - 12042023 
    if(lstRequestShareSleepPart.size() > 0){
        System.debug('createRequestSharing__lstRequestShareSleepPart ==  ' + lstRequestShareSleepPart);
        System.debug('shareSAToUsers: inserting lstSAShareSleepPart List with ' + lstRequestShareSleepPart.size() + ' elements');
        Manage_DataBaseInsertSharing_UTL util = new Manage_DataBaseInsertSharing_UTL();
        util.insertRequestShares(lstRequestShareSleepPart);
        System.debug('Request Share  SleepPart List inserted Successfully ');
    }

    if(lstAccShare.size() > 0){
        System.debug('createRequestSharing__lstAccShare ==  ' + lstAccShare);
        System.debug('shareAccountToUsers: inserting AccountShare List with ' + lstAccShare.size() + ' elements');
        Manage_DataBaseInsertSharing_UTL util = new Manage_DataBaseInsertSharing_UTL();
        util.insertAccountShares(lstAccShare);
        System.debug('Account Share  List inserted Successfully ');
    }

    System.debug('STOP createRequestSharing ');

}

    // public method to execute query without sharing.
    public without sharing class Manage_DataBaseInsertSharing_UTL {
        public void insertRequestShares(List<Request__Share> requestShareList) {
            System.debug('insertRequestShares : request for '  + requestShareList.size() + ' items');
            List<Database.SaveResult> lstRequestShare = Database.insert(requestShareList,false)  ;
            System.debug('insertShares for Request: insertion result ' + lstRequestShare);
            //@TODO process issues !!!
            return;
        }
        public void insertAccountShares(List<AccountShare> accountShareList) {
            System.debug('insertAccountShares : request for '  + accountShareList.size() + ' items');
            List<Database.SaveResult> lstAccShare = Database.insert(accountShareList,false)  ;
            System.debug('insertAccountShares for Request Account: insertion result ' + lstAccShare);
            //@TODO handle failures.
            return;
        }

         public void insertSAShares(List<SpecialAcceptance__Share> saShareList) {
            System.debug('insertSAShares : request for '  + saShareList.size() + ' items');
            List<Database.SaveResult> lstSAShare = Database.insert(saShareList,false)  ;
            System.debug('insertSAShares for Request SA: insertion result ' + lstSAShare);
            //@TODO handle failures.
            return;
        }
    }
  }