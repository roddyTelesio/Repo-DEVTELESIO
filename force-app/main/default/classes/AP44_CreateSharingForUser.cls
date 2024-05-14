public without sharing class AP44_CreateSharingForUser {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Create Request Share and Account Share for User
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
--11-SEP-2020  MBE   1.0      Initial version
--18-JUN-2021  MBE   1.1      W-0997 - Special Acceptance - Visibilité des SA pour un user externe nouvellement créé
--28-SEP-2021  MBE   1.2      W-1031 - Error Account&Contact Relation
--08-DEC-2021  MBE   1.3      W-1038 - réassureurs qui ne voient pas l'historique des années précédantes
--------------------------------------------------------------------------------------
**************************************************************************************/

    /**
    * @description Method to recalculate sharing after inserting users
    * @param List<Id> lstContacts
    * @return void
    */
    @Future
    public static void createSharingForUser(List<Id> lstContacts){
        Map<String, Id> mapRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectRequest});
        Map<Id, Contact> mapContactById = new Map<Id, Contact>();
        Map<Id, User> mapUserByContactId = new Map<Id, User>();
        Map<Id, List<AccountContactRelation>> mapLstAccountContactRelationsByContactId = new Map<Id, List<AccountContactRelation>>();
        Map<Id, List<AccountContactRelation>> mapLstAccConRelByContactIdBR = new Map<Id, List<AccountContactRelation>>();
        Map<Id, List<AccountContactRelation>> mapLstAccConRelByContactIdPCC = new Map<Id, List<AccountContactRelation>>();
        Map<Id, Set<Id>> mapSetPCCByConId = new Map<Id, Set<Id>>();
        Map<Id, Id> mapChildRequestByParentLeadRequestId = new Map<Id, Id>();
        List<Request__Share> lstRequestShareToInsert = new List<Request__Share>();
        List<AccountShare> lstAccountShareToInsert = new List<AccountShare>();
        List<SpecialAcceptance__Share> lstSAShare = new List<SpecialAcceptance__Share>();
        Map<Id, Id> mapSAIdByRequestId = new Map<Id, Id>();
        Set<Id> setAccountPCCId = new Set<Id>();
        Set<Id> setUserId = new Set<Id>();
        Set<String> setAccountShareToInsert = new Set<String>();
        Set<String> setRequestShareToInsert = new Set<String>();
        String recordTypeIdLead = mapRecTypeId.get(AP_Constant.reqRTLead);
        String recordTypeIdSA = mapRecTypeId.get(AP_Constant.reqRTSA);
        Set<Id> setBrokerReinId = new Set<Id>();

        List<AccountContactRelation> lstAccountContactRelations = [SELECT Id, toLabel(Contact.Nature__c), Contact.MacroLoB__c, Contact.AccountId, AccountId,ContactId, Roles
                                                                   FROM AccountContactRelation
                                                                   WHERE ContactId IN :lstContacts
                                                                   AND IsActive = TRUE
                                                                   AND Contact.MacroLoB__c != NULL
                                                                   AND Contact.Nature__c != NULL];

        for(Contact contact : [SELECT Id, Name, MacroLoB__c, toLabel(Nature__c) FROM Contact WHERE Id IN :lstContacts]){
            //Map Contact Object by Contact Id to check nature and macrolob value
            mapContactById.put(contact.Id, contact);
        }

        for(User user : [SELECT Id, ContactId FROM User WHERE ContactId IN :mapContactById.keySet()]){
            //Map User Object by Contact Id to get user id of a contact
            mapUserByContactId.put(user.ContactId, user);
        }

        //Map of List of AccountContactRelation for each Contact
        //Add AccountId of PCC to a set to get all Request which has same PCC
        for(AccountContactRelation relation : lstAccountContactRelations){
            List<AccountContactRelation> lstRelations = new List<AccountContactRelation>();
            List<AccountContactRelation> lstRelationsPCC = new List<AccountContactRelation>();
            List<AccountContactRelation> lstRelationsBR = new List<AccountContactRelation>();
            Set<Id> setPCC = new Set<Id>();

            if(relation.Roles == 'PrincipalCedingCompany'){
                setAccountPCCId.add(relation.AccountId);

                if(mapLstAccConRelByContactIdPCC.containsKey(relation.ContactId)){
                    lstRelationsPCC = mapLstAccConRelByContactIdPCC.get(relation.ContactId);
                }

                lstRelationsPCC.add(relation);
                mapLstAccConRelByContactIdPCC.put(relation.ContactId, lstRelationsPCC);
                
                if(mapSetPCCByConId.containsKey(relation.ContactId)){
                    setPCC = mapSetPCCByConId.get(relation.ContactId);
                }

                setPCC.add(relation.AccountId);
                mapSetPCCByConId.put(relation.ContactId, setPCC);
            }
            else{
                setBrokerReinId.add(relation.AccountId);

                if(mapLstAccConRelByContactIdBR.containsKey(relation.ContactId)){
                    lstRelationsBR = mapLstAccConRelByContactIdBR.get(relation.ContactId);
                }
                lstRelationsBR.add(relation);
                mapLstAccConRelByContactIdBR.put(relation.ContactId, lstRelationsBR);
            }

            if(mapLstAccountContactRelationsByContactId.containsKey(relation.ContactId)){
                lstRelations = mapLstAccountContactRelationsByContactId.get(relation.ContactId);
            }

            lstRelations.add(relation);
            mapLstAccountContactRelationsByContactId.put(relation.ContactId, lstRelations);
        }

        //Get All Request where PCC of Request = AccountId of PCC AccountContactRelation
        List<Request__c> lstAllRequestWithSamePCC = [SELECT Id, Name, toLabel(Program__r.Nature__c), Program__r.PrincipalCedingCompany__c
                                                            , Program__r.Macro_L_O_B__c, RecordTypeId, PrincipalCedingCompany__c
                                                            , Broker__c, Reinsurer__c, BrokerStatus__c, Special_Acceptance__c, ReinsurerStatus__c
                                                     FROM Request__c
                                                     WHERE Program__r.PrincipalCedingCompany__c IN :setAccountPCCId
                                                     AND Reinsurer__c != NULL
                                                     AND (Broker__c IN :setBrokerReinId OR Reinsurer__c IN :setBrokerReinId)];

        for(Request__c req : lstAllRequestWithSamePCC){
            if(req.Special_Acceptance__c != null){
                mapSAIdByRequestId.put(req.Id, req.Special_Acceptance__c);
            }
        }

        //Get all Lead Parent Request where PCC of Request = AccountId of PCC AccountContactRelation
        List<Request__c> lstParentRequestId = [SELECT Id, Name, toLabel(Program__r.Nature__c), Program__r.PrincipalCedingCompany__c
                                                        , Program__r.Macro_L_O_B__c, RecordTypeId, PrincipalCedingCompany__c
                                                        , Broker__c, Reinsurer__c, ReinsurerStatus__c
                                               FROM Request__c
                                               WHERE Program__r.PrincipalCedingCompany__c IN :setAccountPCCId
                                               AND RecordTypeId = :recordTypeIdLead
                                               AND Reinsurer__c != NULL
                                               AND (Broker__c IN :setBrokerReinId OR Reinsurer__c IN :setBrokerReinId)];

        //Get junction leadRequestSelection for LeadParentRequest to map Child Request Id by Parent Request Id
        for(LeadRequestSelection__c leadRequestSelection : [SELECT Id, Name, LeadRequestChild__c, LeadRequestParent__c
                                                            FROM LeadRequestSelection__c
                                                            WHERE LeadRequestParent__c IN :lstParentRequestId]){
            mapChildRequestByParentLeadRequestId.put(leadRequestSelection.LeadRequestParent__c, leadRequestSelection.LeadRequestChild__c);
        }

        //Build map of List of Request by contact id
        Map<Id, List<Request__c>> mapLstRequestByContId = new Map<Id, List<Request__c>>();

        for(Id contactId : mapLstAccConRelByContactIdPCC.keySet()){
            Set<Id> setPCCByConId = new Set<Id>();
            List<Request__c> lstReq = new List<Request__c>();

            Contact contactInfo = mapContactById.get(contactId);
            String[] macroLOBArr = contactInfo.MacroLoB__c.split(';');

            if(mapSetPCCByConId.containsKey(contactId)){
                setPCCByConId = mapSetPCCByConId.get(contactId);
            }
            
            for(Request__c request : lstAllRequestWithSamePCC){
                if(setPCCByConId.contains(request.Program__r.PrincipalCedingCompany__c) 
                    && macroLOBArr.contains(request.Program__r.Macro_L_O_B__c)
                    && (contactInfo.Nature__c == request.Program__r.Nature__c || (contactInfo.Nature__c.contains(request.Program__r.Nature__c)))){
                        if(mapLstRequestByContId.containsKey(contactId)){
                            lstReq = mapLstRequestByContId.get(contactId);  
                        }

                        lstReq.add(request);
                        mapLstRequestByContId.put(contactId, lstReq);
                }
            }
        }

        for(Id contactId : mapLstAccountContactRelationsByContactId.keySet()){
            if(mapUserByContactId.containsKey(contactId)){
                setUserId.add(mapUserByContactId.get(contactId).Id);
                List<AccountContactRelation> lstRelationsOnlyPCC = new List<AccountContactRelation>();
                List<AccountContactRelation> lstRelationsOnlyBR = new List<AccountContactRelation>();
                List<Request__c> lstReqByCon = new List<Request__c>();

                if(mapLstAccConRelByContactIdPCC.containsKey(contactId)){
                    lstRelationsOnlyPCC = mapLstAccConRelByContactIdPCC.get(contactId);
                }

                if(mapLstAccConRelByContactIdBR.containsKey(contactId)){
                    lstRelationsOnlyBR = mapLstAccConRelByContactIdBR.get(contactId);
                }

                if(mapLstRequestByContId.containsKey(contactId)){
                    lstReqByCon = mapLstRequestByContId.get(contactId);
                }

                for(Request__c request : lstReqByCon){
                    Boolean foundPCCReq = false;
                    AccountContactRelation relationPCCReq = new AccountContactRelation();
                    for(AccountContactRelation relation : lstRelationsOnlyPCC){
                        if(relation.Roles == 'PrincipalCedingCompany' && request.Program__r.PrincipalCedingCompany__c == relation.AccountId){
                            //PCC AccountContactRelation match with PCC of request
                            foundPCCReq = true;
                            relationPCCReq = relation;
                        }
                    }

                    if(foundPCCReq == true){
                        //loop over AccountContactRelation to get associated Account which has same Broker or Reinsurer as Request
                        for(AccountContactRelation relation : lstRelationsOnlyBR){
                            if(request.RecordTypeId == recordTypeIdSA){
                                String brokReinId = null;
                                if(request.Broker__c != null && request.BrokerStatus__c != '1'){
                                    brokReinId = request.Broker__c;
                                }
                                else{
                                    brokReinId = request.Reinsurer__c;
                                }

                                if((brokReinId == relation.AccountId) && (request.ReinsurerStatus__c != AP_Constant.statusSetup)){
                                    setRequestShareToInsert.add(request.Id + '-' + mapUserByContactId.get(contactId).Id);
                                }
                            }
                            else if((request.Broker__c == relation.AccountId || request.Reinsurer__c == relation.AccountId)){
                                setRequestShareToInsert.add(request.Id + '-' + mapUserByContactId.get(contactId).Id);

                                if(request.RecordTypeId == recordTypeIdLead){
                                    //Check if Request is Lead + Request = Parent Lead Request since it has Reinsurer
                                    //Get the Child Lead Request from Parent Lead Request
                                    //Create Request Share for Corresponding Child Lead Request
                                    if(mapChildRequestByParentLeadRequestId.containsKey(request.Id)){
                                        Id childRequestId = mapChildRequestByParentLeadRequestId.get(request.Id);
                                        setRequestShareToInsert.add(childRequestId + '-' + mapUserByContactId.get(contactId).Id);
                                    }
                                }
                            }
                        }

                        //Add AccountId of PCC and User Id of Contact to create Account Share
                        setAccountShareToInsert.add(relationPCCReq.AccountId + '-' + mapUserByContactId.get(contactId).Id);
                    }
                }
            }
        }

        List<Request__Share> lstRequestShareToDelete = [SELECT Id, UserOrGroupId FROM Request__Share WHERE UserOrGroupId IN :setUserId];
        
        List<AccountShare> lstAccountShareToDelete = [SELECT Id, UserOrGroupId FROM AccountShare WHERE UserOrGroupId IN :setUserId AND OpportunityAccessLevel = 'Read'];

        if(lstRequestShareToDelete.size() > 0){
            delete lstRequestShareToDelete;
        }

        if(lstAccountShareToDelete.size() > 0){
            delete lstAccountShareToDelete;
        }

        for(String accString : setAccountShareToInsert){
            String accountId = accString.split('-')[0];
            String userId = accString.split('-')[1];

            if(accountId != null && userId != null && accountId != 'null' && userId != 'null'){
                AccountShare accountShare = new AccountShare();
                accountShare.AccountAccessLevel = 'Read';
                accountShare.OpportunityAccessLevel = 'Read';
                accountShare.AccountId = accountId;
                accountShare.UserOrGroupId = userId;
                lstAccountShareToInsert.add(accountShare);
            }
        }

        for(String requestShareString : setRequestShareToInsert){
            String requestId = requestShareString.split('-')[0];
            String userId = requestShareString.split('-')[1];

            if(requestId != null && userId != null && requestId != 'null' && userId != 'null'){
                Request__Share requestShare = new Request__Share();
                requestShare.RowCause = 'Manual';
                requestShare.AccessLevel = 'Edit';
                requestShare.ParentId = requestId;
                requestShare.UserOrGroupId = userId;
                lstRequestShareToInsert.add(requestShare);

                if(mapSAIdByRequestId.containsKey(requestId)){
                    SpecialAcceptance__Share saShare = new SpecialAcceptance__Share();
                    saShare.RowCause = 'Manual';
                    saShare.AccessLevel = 'Edit';
                    saShare.ParentId = mapSAIdByRequestId.get(requestId);
                    saShare.UserOrGroupId = userId;
                    lstSAShare.add(saShare);
                }
            }
        }

        if(lstAccountShareToInsert.size() > 0){
            //insert lstAccountShareToInsert;
        }

        if(lstRequestShareToInsert.size() > 0){
            //insert lstRequestShareToInsert;
        }

        if(lstSAShare.size() > 0){
            //insert lstSAShare;
        }
    }
}