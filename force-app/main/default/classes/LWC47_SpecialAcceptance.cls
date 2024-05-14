public without sharing class LWC47_SpecialAcceptance {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Controller for Lightning Web Component lwc47SpecialAcceptance
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 30-SEP-2020  MBE   1.0      Initial version
-- 08-JUN-2021  MBE   1.1      W-0985 - Special Acceptance - Le SA ID sur de la mêm SA n'est pas unique d'un portail à un autre
-- 17-JUN-2021  MBE   1.2      NACE CODE
-- 04-AUG-2021  MBE   1.3      W-1005 - Special Acceptance - Filtrer les SA sur le portail Cédante afin qu'il ne voit pas les SA des autres cédantes d'un programme régional
-- 11-AUG-2021  MBE   1.4      Code Optimization - Use Ternary Operator
-- 17-AUG-2021  MBE   1.5      W-1013 - Special Acceptance - Bind Response Emails    
-- 26-AUG-2021  MBE   1.6      SOQL Injection for getNaceCode()
-- 09-NOV-2021  MBE   1.7      W-1037 - remove renderedStoredEmailTemplate from Loop
-- 21-DEC-2021  MBE   1.8      W-0932 - Transversal - Ne pas proposer des utilisateurs inactifs
--------------------------------------------------------------------------------------
**************************************************************************************/

    /**
    * @description Method to get Program Details
    * @param String programId, Boolean isUserCE
    * @return Map<String, Object>
    */
    @AuraEnabled
    public static Map<String, Object> getProgramDetail(String programId, Boolean isUserCE){
        Map<String, Object> mapResults = new Map<String, Object>();
        Map<String, Decimal> mapRateByCurrencyLabel = new Map<String, Decimal>();
        Map<String, Id> mapAccountRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectAcc});
        List<OptionWrapper> lstCedingComp = new List<OptionWrapper>();
        List<SpecialAcceptance__c> lstSpecialAcceptance = new List<SpecialAcceptance__c>();
        List<Program__c> lstRenewedProgram = new List<Program__c>();
        List<SpecialAcceptance__c> lstLastSpecialAcceptance = new List<SpecialAcceptance__c>();
        Boolean isProgramRenewed = false;
        String renewedProgId;
        String lastRefIndex = '';
        List<Account> lstAccount = new List<Account>();
        List<Group> lstGroup = new List<Group>();
        List<AccountContactRelation> lstCCCAccConRelPublicGroup = new List<AccountContactRelation>();
        String referentialId;
        String groupId;
        Set<Id> setUserOrGroupId = new Set<Id>();
        Set<Id> setContactId = new Set<Id>();
        Set<Id> setAccConRelAccId = new Set<Id>();
        Contact cedingContact = new Contact();

        // get connected user contact -> Contact A -> get Covered Ceding Company of Contact - CCC 1
        // find all public group where Contact A is found -> get all Covered Ceding Company -> CCC1 + lstCovCedCom(CCC 2 + CCC 3)
        // display all SA where selected CCC is found in list of lstCovCedCom(CCC 1 or CCC 2 or CCC 3)

        User usr = [SELECT Id, ContactId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        Id contactId = usr.ContactId;
        Id cedingAcc = null;
        List<Id> lstGroupIds = new List<Id>();
        List<String> lstReferentialIds = new List<String>();
        Set<Id> setAccCedingPublicGroup = new Set<Id>();

        if(contactId != null){
            cedingContact = [SELECT Id, AccountId FROM Contact WHERE Id = :contactId LIMIT 1];

            if(cedingContact != null && cedingContact.AccountId != null){
                cedingAcc = cedingContact.AccountId;
                setAccCedingPublicGroup.add(cedingContact.AccountId);
            }
        }

        for(GroupMember groupMemberRecord : [SELECT Id, GroupId FROM GroupMember WHERE UserOrGroupId = :UserInfo.getUserId()]){
            lstGroupIds.add(groupMemberRecord.GroupId);
        }

        for(Group groupRecord : [SELECT Id, DeveloperName FROM Group WHERE Id IN :lstGroupIds]){
            lstReferentialIds.add(groupRecord.DeveloperName);
        }

        for(Account account : [SELECT Id, Name, IsActive__c FROM Account WHERE TECH_ReferentialId__c IN :lstReferentialIds AND RecordTypeId = :mapAccountRecTypeId.get(AP_Constant.accRTCoveredCedingCompany)]){
            setAccCedingPublicGroup.add(account.Id);    
        }

        List<Program__c> lstProgram =  [SELECT Id, Name, toLabel(Nature__c), PrincipalCedingCompany__r.Name, toLabel(Macro_L_O_B__c), UwYear__c, InceptionDate__c
                                        FROM Program__c
                                        WHERE Id = :programId];

        List<Id> lstCovCedCom = new List<Id>();

        for(CoveredCedingCompany__c covCedCom : [SELECT Id, Account__r.Name FROM CoveredCedingCompany__c WHERE Program__c = :programId AND ProgramIsSelected__c = TRUE]){
            if(isUserCE == true){
                lstCedingComp.add(new OptionWrapper(covCedCom.Account__r.Name, covCedCom.Account__c));
            }
            else if(setAccCedingPublicGroup.contains(covCedCom.Account__c)){
                lstCedingComp.add(new OptionWrapper(covCedCom.Account__r.Name, covCedCom.Account__c));
            }  
            lstCovCedCom.add(covCedCom.Account__c);
        }

        lstCedingComp.sort();

        Map<String, Id> mapAccIdByRefId = new Map<String, Id>();
        Map<Id, String> mapRefIdByGroupId = new Map<Id, String>();
        Map<Id, List<Id>> mapGroupMemberByGroupId = new Map<Id, List<Id>>();
        Map<Id, List<Id>> mapLstUserOrGroupIdByAccId = new Map<Id, List<Id>>();
        Map<Id, Id> mapConIdByUserId = new Map<Id, Id>();
        Map<Id, List<Id>> mapListCCCContactByAccId = new Map<Id, List<Id>>();
        Set<String> setReferentialId = new Set<String>();
        Set<String> setGroupId = new Set<String>();
        Set<Id> setAllUserOrGroupId = new Set<Id>();
        Set<Id> setAllContactId = new Set<Id>();
        List<Account> lstAccountCCC = new List<Account>(); 
        List<Group> lstGroupCCC = new List<Group>();
        Id accRTCCC = mapAccountRecTypeId.get(AP_Constant.accRTCoveredCedingCompany);

        lstAccountCCC = [SELECT Id, Name, TECH_ReferentialId__c FROM Account WHERE Id IN :lstCovCedCom];

        for(Account acc: lstAccountCCC){
            mapAccIdByRefId.put(acc.TECH_ReferentialId__c, acc.Id);
            setReferentialId.add(acc.TECH_ReferentialId__c);
        }

        lstGroupCCC = [SELECT Id, DeveloperName FROM Group WHERE DeveloperName IN :setReferentialId];

        for(Group gp : lstGroupCCC){
            mapRefIdByGroupId.put(gp.Id, gp.DeveloperName);
            setGroupId.add(gp.Id);
        }

        for(GroupMember groupMember : [SELECT Id, GroupId, UserOrGroupId FROM GroupMember WHERE GroupId IN :setGroupId]){
            List<Id> lstUserOrGroupId = new List<Id>();
            if(mapGroupMemberByGroupId.containsKey(groupMember.GroupId)){
                lstUserOrGroupId = mapGroupMemberByGroupId.get(groupMember.GroupId);
            }
            lstUserOrGroupId.add(groupMember.UserOrGroupId);
            mapGroupMemberByGroupId.put(groupMember.GroupId, lstUserOrGroupId);
            setAllUserOrGroupId.add(groupMember.UserOrGroupId);
        }

        for(Id gpId : mapGroupMemberByGroupId.keySet()) {
            List<Id> lstId = mapGroupMemberByGroupId.get(gpId);
            String refId = null;
            String accId = null;

            if(mapRefIdByGroupId.containsKey(gpId)){
                refId = mapRefIdByGroupId.get(gpId);

                if(refId != null){
                    if(mapAccIdByRefId.containsKey(refId)){
                        accId = mapAccIdByRefId.get(refId);

                        if(accId != null){
                            mapLstUserOrGroupIdByAccId.put(accId, lstId);
                        }
                    }
                }
            }
        }

        for(User user : [SELECT Id, ContactId FROM User WHERE Id IN :setAllUserOrGroupId]){
            if(user.ContactId != null){
                mapConIdByUserId.put(user.Id, user.ContactId);
                setAllContactId.add(user.ContactId);
            }
        }

        if(setAllContactId.size() > 0){
            for(AccountContactRelation accContactRelation : [SELECT Id, AccountId,Account.Name, Account.RecordTypeId, Contact.Account.RecordTypeId, Contact.Email, Roles, ContactId, Contact.MacroLoB__c, Contact.Nature__c, Contact.LastName, Contact.FirstName FROM AccountContactRelation
                                                         WHERE ContactId IN :setAllContactId
                                                         AND IsActive = TRUE 
                                                         AND Account.IsActive__c = TRUE
                                                         AND Account.RecordTypeId = :accRTCCC]){
                for(Id accId : mapLstUserOrGroupIdByAccId.keySet()){
                    for(Id userId : mapLstUserOrGroupIdByAccId.get(accId)){
                        if(mapConIdByUserId.containsKey(userId)){
                            Id conId = mapConIdByUserId.get(userId);
                            if(accContactRelation.ContactId == conId){
                                List<Id> lstCedingContact = new List<Id>();
                                if(mapListCCCContactByAccId.containsKey(accId)){
                                    lstCedingContact = mapListCCCContactByAccId.get(accId);
                                }

                                lstCedingContact.add(accContactRelation.ContactId);
                                mapListCCCContactByAccId.put(accId, lstCedingContact);
                            }
                        }
                    }
                }                 
            }
        }

        if(programId != null){
            if(isUserCE == true){
                lstSpecialAcceptance = [SELECT Id, Name, Reference__c, ReferenceOld__c, SpecialAcceptanceName__c, toLabel(LoB__c), toLabel(SubLoB__c), Active__c, TECH_MacroLobProgram__c, TECH_LocalSA__c
                                               , Reason__c, toLabel(Type__c), toLabel(ProposedToFac__c), toLabel(Bound__c), UnderWrittingYear__c, SentAgreFromSpecialAcceptance__c, PrincipalCedingCompany__r.Name, PrincipalCedingCompany__r.EmailSA__c, CoveredCedingCompany__r.Name
                                               , PortalStatus__c, InternalStatus__c, Program__c, Program__r.Name, Program__r.UwYear__c, Program__r.RenewedFromProgram__c, RenewedFromSpecialAcceptance__c
                                        FROM SpecialAcceptance__c
                                        WHERE Program__c = :programId
                                        AND InternalStatus__c != NULL
                                        AND PortalStatus__c = NULL ORDER BY SpecialAcceptanceName__c asc]; //RRA - 1086
            }
            else{
                List<SpecialAcceptance__c> lstAllSpecialAcceptance = [SELECT Id, Name, Reference__c, ReferenceOld__c, SpecialAcceptanceName__c, toLabel(LoB__c), toLabel(SubLoB__c), Active__c, TECH_MacroLobProgram__c, TECH_LocalSA__c
                                                                             , Reason__c, toLabel(Type__c), toLabel(ProposedToFac__c), toLabel(Bound__c), UnderWrittingYear__c, PrincipalCedingCompany__r.Name, PrincipalCedingCompany__r.EmailSA__c, CoveredCedingCompany__r.Name
                                                                             , PortalStatus__c, InternalStatus__c, Program__c, Program__r.Name, Program__r.UwYear__c, Program__r.RenewedFromProgram__c, RenewedFromSpecialAcceptance__c
                                                                      FROM SpecialAcceptance__c
                                                                      WHERE Program__c = :programId
                                                                      AND PortalStatus__c != NULL ORDER BY SpecialAcceptanceName__c asc]; //RRA - 1086

                for(SpecialAcceptance__c sa : lstAllSpecialAcceptance){
                    //get CovCedCom + get list of Contact for CovCedCom
                    //check if this contact is found list of Contact for CovCedCom is found 
                    if(sa.CoveredCedingCompany__c == cedingAcc){
                        lstSpecialAcceptance.add(sa);
                    }
                    else if(mapListCCCContactByAccId.containsKey(sa.CoveredCedingCompany__c)){
                        List<Id> lstCedingContactForCCC = new List<Id>();
                        lstCedingContactForCCC = mapListCCCContactByAccId.get(sa.CoveredCedingCompany__c);
                        Set<Id> setCedingContactForCCC = new Set<Id>(lstCedingContactForCCC);

                        if(setCedingContactForCCC.contains(cedingContact.Id)){
                            lstSpecialAcceptance.add(sa);
                        }
                    }
                }
            }

            lstRenewedProgram = [SELECT Id, Name, RenewedFromProgram__c FROM Program__c WHERE RenewedFromProgram__c = :programId];
        }

        if(lstProgram.size() > 0){
            for(FXRate__c fxRate : [SELECT Id, toLabel(Currency__c), FX_Rate__c FROM FXRate__c WHERE UW_Year__c = :lstProgram[0].UwYear__c]){
                if(!mapRateByCurrencyLabel.containsKey(fxRate.Currency__c)){
                    mapRateByCurrencyLabel.put(fxRate.Currency__c, fxRate.FX_Rate__c);
                }
            }
        }

        if(lstRenewedProgram.size() > 0){
            //if program is renewed
            isProgramRenewed = true;
            renewedProgId = lstRenewedProgram[0].Id;
        }

        lstLastSpecialAcceptance = [SELECT Id, Name, Reference__c, TECH_ReferenceIndex__c FROM SpecialAcceptance__c ORDER BY TECH_ReferenceIndex__c DESC LIMIT 1];

        if(lstLastSpecialAcceptance != null && lstLastSpecialAcceptance.size() > 0){
            if(lstLastSpecialAcceptance[0].Reference__c != null){
                String refIndex = lstLastSpecialAcceptance[0].Reference__c.split('-')[2];
                Decimal refIndexVal = Decimal.valueOf(refIndex) + 1;
                lastRefIndex = (('0'.repeat(8))+refIndexVal).right(8);
            }
        }
        else{
            lastRefIndex = System.Label.SAReferenceIndex;
        }

        mapResults.put('lstProgram', lstProgram);
        mapResults.put('lstCedingComp', lstCedingComp);
        mapResults.put('lstSpecialAcceptance', lstSpecialAcceptance);
        mapResults.put('mapRateByCurrencyLabel', mapRateByCurrencyLabel);
        mapResults.put('isProgramRenewed', isProgramRenewed);
        mapResults.put('lastRefIndex', lastRefIndex);
        mapResults.put('renewedProgId', renewedProgId);
        return mapResults;
    }

    /**
    * @description Method to get check for Renew Special Acceptance
    * @param Id programId
    * @return Map<String, Object>
    */
    //RRA - ticekt 1996 - 09042023 - Issue doublon on renew SA
    @AuraEnabled
    public static Map<String, Object> checkForRenewSA(Id selectedSaId) {
        System.debug('selectedSaId == '+ selectedSaId);
        Map<String, Object> mapResults = new Map<String, Object>();
        Boolean isSARenewed = false;

        List<SpecialAcceptance__c> lstSpecialAcceptance = [SELECT Id, RenewedFromSpecialAcceptance__c FROM SpecialAcceptance__c WHERE RenewedFromSpecialAcceptance__c = :selectedSaId LIMIT 1];
        
        if (lstSpecialAcceptance.size() > 0){
            isSARenewed = true;
        }
        System.debug('lstSpecialAcceptance == '+ lstSpecialAcceptance);

        System.debug('isSARenewed == '+ isSARenewed);
        mapResults.put('isSARenewed', isSARenewed);
        return mapResults;
    }

    /**
    * @description Method to get RecordTypeId for Appropriate Type of Special Acceptance
    * @param String typeOfSA
    * @return String
    */
    @AuraEnabled
    public static String getTypeOfSARecordTypeId(String typeOfSA){
        Map<String, Id> mapRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectSpecialAcceptance});
        String saRecordTypeId;
        
        if(typeOfSA == 'Autofac'){
            saRecordTypeId = mapRecTypeId.get(AP_Constant.saRTAutofac);
        }
        else if(typeOfSA == 'Life'){
            saRecordTypeId = mapRecTypeId.get(AP_Constant.saRTLife);
        }
        else if(typeOfSA == 'PC'){
            saRecordTypeId = mapRecTypeId.get(AP_Constant.saRTPC);
        }
        return saRecordTypeId;
    }

    /**
    * @description Method to get save Special Acceptance
    * @param SpecialAcceptance__c specialAcceptanceObj, List<ContentVersion> lstDocumentToUpdate, String actionBtnClick, Boolean isUserCE
    * @return Map<String, Object>
    */
    @AuraEnabled
    public static Map<String, Object> saveSpecialAcceptanceRecord(SpecialAcceptance__c specialAcceptanceObj, List<ContentVersion> lstDocumentToUpdate, String actionBtnClick, Boolean isUserCE) {
        Map<String, Object> mapResults = new Map<String, Object>();
        List<Id> lstContentDocument = new List<Id>();
        List<ContentDocumentLink> lstContentDocumentLinkToInsert = new List<ContentDocumentLink>();
        Savepoint sp = Database.setSavepoint();

        try {
            if(specialAcceptanceObj != null){
                specialAcceptanceObj.Bound__c = 'Pending';
                insert specialAcceptanceObj;
            }

            if(lstDocumentToUpdate.size() > 0){
                for(ContentVersion contentVersion : lstDocumentToUpdate){
                    contentVersion.SpecialAcceptance__c = specialAcceptanceObj.Id;
                    lstContentDocument.add(contentVersion.ContentDocumentId);
                }         

                for(Id contentDocumentId : lstContentDocument){
                    ContentDocumentLink cd = new ContentDocumentLink();
                    cd.LinkedEntityId = specialAcceptanceObj.Id;
                    cd.ContentDocumentId = contentDocumentId;
                    cd.Visibility = 'AllUsers';
                    cd.ShareType = 'V';
                    lstContentDocumentLinkToInsert.add(cd);
                }

                update lstDocumentToUpdate;

                if(lstContentDocumentLinkToInsert.size() > 0){
                    insert lstContentDocumentLinkToInsert;
                }
            }

            if(actionBtnClick == 'Submit'){
                submitSpecialAcceptanceRecord(specialAcceptanceObj.Id);
            }
        
            mapResults.put('Success', 'Success');

        }catch (Exception ex) {
            mapResults.put('Error', ex.getMessage());
            Database.rollback(sp);
        }
        return mapResults;
    }

    public class OptionWrapper implements Comparable{
        @AuraEnabled
        public String label {get; set;}
        @AuraEnabled
        public String value {get; set;}

        public OptionWrapper(String label, String value){
            this.label = label;
            this.value = value;
        }

        public Integer compareTo(Object compareTo){
            OptionWrapper optWrapper = (OptionWrapper) compareTo;
            if (label == optWrapper.label) return 0;
            if (label > optWrapper.label) return 1;
            return -1;
        }
    }

    /**
    * @description Method to Save Documents
    * @param List<ContentVersion> lstContentVersion
    * @return Map<String, Object>
    */
    @AuraEnabled
    public static Map<String, Object> saveDocuments(List<ContentVersion> lstContentVersion) {
        Map<String, Object> mapResults = new Map<String, Object>();

        try {
            if(lstContentVersion.size() > 0) {
                update lstContentVersion;
            }
            mapResults.put('Success', 'Success');
        }
        catch (Exception ex) {
            mapResults.put('Error', ex.getMessage());
        }
        return mapResults;
    }

    /**
    * @description Method to Delete Content Version for Document
    * @param List<Id> lstDeletedDocument
    * @return Map<String, Object>
    */
    @AuraEnabled
    public static Map<String, Object> deleteContentVersionDocument(List<Id> lstDeletedDocument) {
        Map<String, Object> mapResults = new Map<String, Object>();

        try{
            if (lstDeletedDocument.size() > 0) {
                Set<Id> setContentDocumentId = new Set<Id>();

                for (ContentVersion contentVersion : [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN :lstDeletedDocument]) {
                    setContentDocumentId.add(contentVersion.ContentDocumentId);
                }

                List<ContentDocument> lstContentDoc = [SELECT Id FROM ContentDocument WHERE Id IN :setContentDocumentId];

                if(lstContentDoc.size() > 0) {
                    delete lstContentDoc;
                }
            }

            mapResults.put('Success', 'Success');
        }
        catch (Exception ex) {
            mapResults.put('Error', ex.getMessage());
        }
        return mapResults;
    }

    /**
    * @description Method to Get Content Version for Document
    * @param List<Id> lstContentDocumentId
    * @return List<ContentVersion>
    */
    @AuraEnabled(Cacheable = true)
    public static List<ContentVersion> getContentVersionId(List<Id> lstContentDocumentId) {
        List<ContentVersion> lstContentVersion = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE ContentDocumentId IN :lstContentDocumentId];
        return lstContentVersion;
    }

    /**
    * @description Method to get Programs which have same nature
    * @param String programId, Boolean isUserCE
    * @return Map<String, Object>
    */
    @AuraEnabled
    public static Map<String, Object> getProgramNature(String programId, Boolean isUserCE){
        Map<String, Object> mapResults = new Map<String, Object>();
        List<OptionWrapper> lstProgramNatureOption = new List<OptionWrapper>();

        List<Program__c> lstProgram =  [SELECT Id, Name, Nature__c, PrincipalCedingCompany__r.Name, toLabel(Macro_L_O_B__c), UwYear__c, PrincipalCedingCompany__c
                                        FROM Program__c
                                        WHERE Id = :programId];

        User usr = [SELECT Id, ContactId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        Id contactId = usr.ContactId;
        Id cedingAcc = null;
        List<Id> lstProgramId = new List<Id>();
        Map<Id, List<Id>> mapLstCovCedComByProgId = new Map<Id, List<Id>>();
        Map<Id, String> mapProgramByProgId = new Map<Id, String>();

        if(contactId != null){
            Contact cedingContact = [SELECT Id, AccountId FROM Contact WHERE Id = :contactId LIMIT 1];

            if(cedingContact != null && cedingContact.AccountId != null){
                cedingAcc = cedingContact.AccountId;
            }
        }

        if(lstProgram.size() > 0){
            for(Program__c program : [SELECT Id, Name FROM Program__c
                                      WHERE PrincipalCedingCompany__c = :lstProgram[0].PrincipalCedingCompany__c
                                      AND UwYear__c = :lstProgram[0].UwYear__c
                                      AND Nature__c = :lstProgram[0].Nature__c]){
                lstProgramId.add(program.Id);
                mapProgramByProgId.put(program.Id, program.Name);

                if(isUserCE == true){
                    lstProgramNatureOption.add(new OptionWrapper(program.Name, program.Id));
                }
            }

            if(isUserCE == false){
                for(CoveredCedingCompany__c covCedCom : [SELECT Id, Name, Account__c, Program__c FROM CoveredCedingCompany__c WHERE Program__c IN :lstProgramId]){
                    List<Id> lstCovCedCom = new List<Id>();
                    
                    if(mapLstCovCedComByProgId.containsKey(covCedCom.Program__c)){
                        lstCovCedCom = mapLstCovCedComByProgId.get(covCedCom.Program__c);
                    }

                    lstCovCedCom.add(covCedCom.Account__c);
                    mapLstCovCedComByProgId.put(covCedCom.Program__c, lstCovCedCom);
                }

                for(Id progId : mapLstCovCedComByProgId.keySet()){
                    Set<Id> setCovCedComByProgId  = new Set<Id>(mapLstCovCedComByProgId.get(progId));
                    
                    if(setCovCedComByProgId.contains(cedingAcc)){
                        lstProgramNatureOption.add(new OptionWrapper(mapProgramByProgId.get(progId), progId));
                    }
                }
            }
        }

        lstProgramNatureOption.sort();

        mapResults.put('lstProgram', lstProgram);
        mapResults.put('lstProgramNatureOption', lstProgramNatureOption);
        return mapResults;
    }

    /**
    * @description Method to submit Special Acceptance
    * @param Id specialAcceptanceId
    * @return Map<String, Object>
    */
    @AuraEnabled
    public static Map<String, Object> submitSpecialAcceptanceRecord(Id specialAcceptanceId){
        Map<String, Object> mapResults = new Map<String, Object>();
        Savepoint sp = Database.setSavepoint();
        SpecialAcceptance__c specialAcceptanceNewClone = new SpecialAcceptance__c();
        SpecialAcceptance__c specialAcceptanceCloneExisted = new SpecialAcceptance__c();
        List<ContentVersion> lstNewContentVersionToInsert = new List<ContentVersion>();
        List<Account> lstPCCAccount = new List<Account>();
        List<SpecialAcceptance__c> lstLastSpecialAcceptance = new List<SpecialAcceptance__c>();
        List<Id> lstContentDocument = new List<Id>();
        List<ContentDocumentLink> lstContentDocumentLinkToInsert = new List<ContentDocumentLink>();
        List<ContentVersion> lstContentVersion = new List<ContentVersion>();
        List<String> lstSaPCCEmailsToSend = new List<String>();
        Set<Id> setContentDocumentId = new Set<Id>();
        String lastRefIndex = '';
        String programId;
        String pccId;
        String strLstSaPCCEmail;
        String strLstSaPCCEmailDisplay;

        try {
            //send email to PCC of the program to which the SA is linked
            //change portal status to 'Submitted'
            //to clone record + set portal status = null + set internal status = 'Setup'
            //to clone document

            List<String> lstSAFields = AP_Constant.getCreatableFieldsByObjName(AP_Constant.sObjectSpecialAcceptance);
            String strSAFields = String.join(lstSAFields , ', ');

            String querySA = 'select Id, Program__r.UwYear__c, Program__r.PrincipalCedingCompany__c, Program__r.Nature__c, SpaDurationDays__c, Program__r.Name, CoveredCedingCompany__r.Name, Program__r.PrincipalCedingCompany__r.Name, '
                    + strSAFields
                    + ' from SpecialAcceptance__c where (Id = :specialAcceptanceId) ' ;

            List<SpecialAcceptance__c> lstSpecialAcceptance = Database.query(querySA);

            if(lstSpecialAcceptance.size() > 0){
                programId = lstSpecialAcceptance[0].Program__c;
                pccId = lstSpecialAcceptance[0].Program__r.PrincipalCedingCompany__c;
                specialAcceptanceCloneExisted = lstSpecialAcceptance[0];
                specialAcceptanceCloneExisted.PortalStatus__c = AP_Constant.statusSubmittedToAgre;
                String newReference;

                if(lstSpecialAcceptance[0].Reference__c != null){
                    String[] refOldIndex = lstSpecialAcceptance[0].Reference__c.split('-');
                    newReference = refOldIndex[0] + '-' + refOldIndex[1] + '-' + refOldIndex[2];
                }

                specialAcceptanceNewClone = specialAcceptanceCloneExisted.clone(false, false, false, false);
                specialAcceptanceNewClone.TECH_Actor2Id__c = null;
                specialAcceptanceNewClone.Id = null;
                specialAcceptanceNewClone.PortalStatus__c = null;
                specialAcceptanceNewClone.InternalStatus__c = 'Setup';
                specialAcceptanceNewClone.SentAgreFromSpecialAcceptance__c = specialAcceptanceId;
                specialAcceptanceNewClone.Reference__c = newReference;
                specialAcceptanceNewClone.Bound__c = 'Pending';
            }

            if(specialAcceptanceCloneExisted != null){
                update specialAcceptanceCloneExisted;
            }

            if(specialAcceptanceNewClone != null){
                insert specialAcceptanceNewClone;
            }

            for(ContentDocumentLink contentDocLink : [SELECT Id, ContentDocumentId
                                                      FROM ContentDocumentLink
                                                      WHERE LinkedEntityId = :specialAcceptanceId]){
                setContentDocumentId.add(contentDocLink.ContentDocumentId);
            }

            if(setContentDocumentId.size() > 0){
                lstContentVersion = [SELECT Id, Phase__c, Title, IsExternal__c, ContentDocumentId
                                            , Nature__c, FileType, FileExtension, ContentUrl, ContentSize
                                            , PathOnClient, VersionData, FirstPublishLocationId, SpecialAcceptance__c
                                     FROM ContentVersion
                                     WHERE ContentDocumentId IN :setContentDocumentId];

                for(ContentVersion contentVersion : lstContentVersion){
                    ContentVersion newContentVersion = new ContentVersion();
                    newContentVersion.Title = contentVersion.Title;
                    newContentVersion.PathOnClient = contentVersion.PathOnClient;
                    newContentVersion.VersionData = contentVersion.VersionData;
                    newContentVersion.FirstPublishLocationId = contentVersion.FirstPublishLocationId;
                    newContentVersion.Nature__c = contentVersion.Nature__c;
                    newContentVersion.SpecialAcceptance__c = specialAcceptanceNewClone.Id;
                    newContentVersion.IsExternal__c = contentVersion.IsExternal__c;
                    lstNewContentVersionToInsert.add(newContentVersion);
                }
            }

            if(lstNewContentVersionToInsert.size() > 0) {
                insert lstNewContentVersionToInsert;  

                for(ContentVersion cv : [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN :lstNewContentVersionToInsert]){
                    lstContentDocument.add(cv.ContentDocumentId);
                }

                for(Id contentDocumentId : lstContentDocument){
                    ContentDocumentLink cd = new ContentDocumentLink();
                    cd.LinkedEntityId = specialAcceptanceNewClone.Id;
                    cd.ContentDocumentId = contentDocumentId;
                    cd.Visibility = 'AllUsers';
                    cd.ShareType = 'V';
                    lstContentDocumentLinkToInsert.add(cd);
                }

                if(lstContentDocumentLinkToInsert.size() > 0){
                    insert lstContentDocumentLinkToInsert;
                }
            }

            //send email to PCC of the program to which the SA is linked
            if(pccId != null){
                lstPCCAccount = [SELECT Id, Name, EmailSA__c FROM Account WHERE Id = :pccId LIMIT 1];
                strLstSaPCCEmail = lstPCCAccount[0].EmailSA__c;

                if(strLstSaPCCEmail != null ){
                    if(strLstSaPCCEmail.contains(';')){
                        lstSaPCCEmailsToSend = strLstSaPCCEmail.split(';');
                    }
                    else{
                        lstSaPCCEmailsToSend.add(strLstSaPCCEmail);
                    }
                }

                for(String pccEmail : lstSaPCCEmailsToSend){
                    if(strLstSaPCCEmailDisplay == null){
                        strLstSaPCCEmailDisplay = pccEmail;
                    }
                    else{
                        strLstSaPCCEmailDisplay = strLstSaPCCEmailDisplay + ' ' + pccEmail;   
                    }
                }
            }

            Id emailTempSASubmitId;
            String emailTempSASubmit = AP_Constant.emailTemplateSpecialAcceptanceSubmitToAGRE;
            List<Messaging.SingleEmailMessage> lstMailsToSend =  new List<Messaging.SingleEmailMessage>();
            
            List<EmailTemplate> lstEmailTempSASubmit= [SELECT Id, Name FROM EmailTemplate WHERE Name = :emailTempSASubmit];
            emailTempSASubmitId = lstEmailTempSASubmit[0].Id;

            Messaging.SingleEmailMessage m;
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            Id userId = UserInfo.getUserId();

            if(lstSaPCCEmailsToSend.size() > 0){
                m = Messaging.renderStoredEmailTemplate(emailTempSASubmitId, userId,null);
                m.setSaveAsActivity(false);
                mail.setToAddresses(lstSaPCCEmailsToSend); 
                mail.setReplyTo(UserInfo.getUserEmail());
                mail.setSenderDisplayName(UserInfo.getFirstName() + ' ' + UserInfo.getLastName());

                if(lstSaPCCEmailsToSend.size() > 0){
                    mail.setCcAddresses(lstSaPCCEmailsToSend);
                }

                String htmlBody = m.htmlBody;
                String htmlSubject = m.getSubject();
                String url = String.valueOf(System.URL.getOrgDomainUrl().toExternalForm());
                String htmlInternetLink = '<a href="' + url + '/lightning/page/home">ACTOR NewGen Page</a>';
                String urlLoadSARequest = '/lightning/n/LoadSARequest?s__id='+specialAcceptanceNewClone.Id+'-'+specialAcceptanceNewClone.Program__r.UwYear__c+'-'+pccId+'-'+specialAcceptanceNewClone.Program__c;
                String urlLoadSARequestLink = '<a href="' + url + urlLoadSARequest + '">Link</a>';

                if(specialAcceptanceCloneExisted != null){
                    htmlBody = htmlBody.replace('{U/W Year}', specialAcceptanceCloneExisted.Program__r.UwYear__c);
                    htmlBody = htmlBody.replace('{Coveredcedingcompany}', specialAcceptanceCloneExisted.CoveredCedingCompany__r.Name);
                    htmlBody = htmlBody.replace('{Programname}', specialAcceptanceCloneExisted.Program__r.Name);
                    htmlBody = htmlBody.replace('{SAname}', specialAcceptanceCloneExisted.SpecialAcceptanceName__c);
                    htmlBody = htmlBody.replace('{pccEmail}',  UserInfo.getUserEmail());  //covered ceding user email   
                    htmlBody = htmlBody.replace('[URL]', urlLoadSARequestLink);
                    htmlBody = htmlBody.replace('{ActorNewGenURL}', htmlInternetLink);
                    htmlSubject = htmlSubject.replace('{ProgramName}', specialAcceptanceCloneExisted.Program__r.Name);  
                    htmlSubject = htmlSubject.replace('{CedingCompanyName}', specialAcceptanceCloneExisted.CoveredCedingCompany__r.Name);
                }

                mail.setHtmlBody(htmlBody);
                mail.setSubject(htmlSubject);
                lstMailsToSend.add(mail);
            }

            if(lstMailsToSend.size() > 0){
                Messaging.sendEmail((List<Messaging.Email>) lstMailsToSend);
            }

            mapResults.put('Success', 'Success');
        }catch (Exception ex) {
            Database.rollback(sp);
            mapResults.put('Error', ex.getMessage());
        }
        return mapResults;
    }

    /**
    * @description Method to delete Special Acceptance
    * @param SpecialAcceptance__c specialAcceptanceObj
    * @return Map<String, Object>
    */
    @AuraEnabled
    public static Map<String, Object> deleteSpecialAcceptanceRecord(SpecialAcceptance__c specialAcceptanceObj) {
        Map<String, Object> mapResults = new Map<String, Object>();
        Set<Id> setContentDocumentId = new Set<Id>();
        Savepoint sp = Database.setSavepoint();

        try{
            if(specialAcceptanceObj != null){
                for(ContentDocumentLink contentDocLink : [SELECT Id, ContentDocumentId
                                                          FROM ContentDocumentLink
                                                          WHERE LinkedEntityId = :specialAcceptanceObj.Id]){
                    setContentDocumentId.add(contentDocLink.ContentDocumentId);
                }

                if(setContentDocumentId.size() > 0){
                    List<ContentDocument> lstContentDocToDelete = [SELECT Id FROM ContentDocument WHERE Id IN :setContentDocumentId];

                    if(lstContentDocToDelete.size() > 0) {
                        delete lstContentDocToDelete;
                    }
                }
                
                delete specialAcceptanceObj;               
            }

            mapResults.put('Success', 'Success');
        }catch (Exception ex) {
            Database.rollback(sp);
            mapResults.put('Error', ex.getMessage());
        }
        return mapResults;
    }

    /**
    * @description Method to deactivate Special Acceptance
    * @param List<Id> lstSpecialAcceptanceId
    * @return Map<String, Object>
    */
    @AuraEnabled
    public static Map<String, Object> deactivateSpecialAcceptanceRecord(List<Id> lstSpecialAcceptanceId) {
        Map<String, Object> mapResults = new Map<String, Object>();
        List<Id> lstSentAgreFromSAId = new List<Id>();
        List<SpecialAcceptance__c> lstSpecialAcceptance = new List<SpecialAcceptance__c>();
        List<SpecialAcceptance__c> lstSpecialAcceptanceSentAgreFromSA = new List<SpecialAcceptance__c>();
        List<SpecialAcceptance__c> lstSpecialAcceptanceGroupCover = new List<SpecialAcceptance__c>();
        Savepoint sp = Database.setSavepoint();

        try{
            if(lstSpecialAcceptanceId.size() > 0){

                lstSpecialAcceptance = [SELECT Id, InternalStatus__c, Bound__c, SentAgreFromSpecialAcceptance__c, Active__c FROM SpecialAcceptance__c WHERE ID IN :lstSpecialAcceptanceId];

                for(SpecialAcceptance__c sa : lstSpecialAcceptance){
                    sa.Active__c = 'Cancelled';
                    sa.Bound__c = '2';

                    if(sa.SentAgreFromSpecialAcceptance__c != null){
                        lstSentAgreFromSAId.add(sa.SentAgreFromSpecialAcceptance__c);
                    }
                }

                if(lstSentAgreFromSAId.size() > 0){
                    lstSpecialAcceptanceSentAgreFromSA = [SELECT Id, PortalStatus__c, Bound__c, Active__c FROM SpecialAcceptance__c WHERE Id IN :lstSentAgreFromSAId];

                    for(SpecialAcceptance__c sa : lstSpecialAcceptanceSentAgreFromSA){
                        sa.Active__c = 'Cancelled';
                        sa.Bound__c = '2';
                    }                 
                }  

                lstSpecialAcceptanceGroupCover = [SELECT Id, InternalStatus__c, Bound__c, SentAgreFromSpecialAcceptance__c, Active__c, TECH_LocalSA__c FROM SpecialAcceptance__c WHERE TECH_LocalSA__c IN :lstSpecialAcceptanceId];

                for(SpecialAcceptance__c sa : lstSpecialAcceptanceGroupCover){
                    sa.Active__c = 'Cancelled';
                    sa.Bound__c = '2';
                }   

                if(lstSpecialAcceptance.size() > 0){
                    update lstSpecialAcceptance;
                }     

                if(lstSpecialAcceptanceSentAgreFromSA.size() > 0){
                    update lstSpecialAcceptanceSentAgreFromSA;
                } 

                if(lstSpecialAcceptanceGroupCover.size() > 0){
                    update lstSpecialAcceptanceGroupCover;
                }    
            }

            mapResults.put('Success', 'Success');
        }catch (Exception ex) {
            Database.rollback(sp);
            mapResults.put('Error', ex.getMessage());
        }
        return mapResults;
    }

    /**
    * @description Method to reactivate Special Acceptance
    * @param List<Id> lstSpecialAcceptanceId
    * @return Map<String, Object>
    */
    @AuraEnabled
    public static Map<String, Object> reactivateSpecialAcceptanceRecord(List<Id> lstSpecialAcceptanceId) {
        Map<String, Object> mapResults = new Map<String, Object>();
        List<Id> lstSentAgreFromSAId = new List<Id>();
        List<SpecialAcceptance__c> lstSpecialAcceptance = new List<SpecialAcceptance__c>();
        List<SpecialAcceptance__c> lstSpecialAcceptanceSentAgreFromSA = new List<SpecialAcceptance__c>();
        List<SpecialAcceptance__c> lstSpecialAcceptanceGroupCover = new List<SpecialAcceptance__c>();
        Savepoint sp = Database.setSavepoint();

        try{
            if(lstSpecialAcceptanceId.size() > 0){

                lstSpecialAcceptance = [SELECT Id, InternalStatus__c, Bound__c, SentAgreFromSpecialAcceptance__c, Active__c FROM SpecialAcceptance__c WHERE ID IN :lstSpecialAcceptanceId];

                for(SpecialAcceptance__c sa : lstSpecialAcceptance){
                    sa.Active__c = 'Active';
                    sa.Bound__c = '2';

                    if(sa.SentAgreFromSpecialAcceptance__c != null){
                        lstSentAgreFromSAId.add(sa.SentAgreFromSpecialAcceptance__c);
                    }
                }

                if(lstSentAgreFromSAId.size() > 0){
                    lstSpecialAcceptanceSentAgreFromSA = [SELECT Id, PortalStatus__c, Bound__c, Active__c FROM SpecialAcceptance__c WHERE Id IN :lstSentAgreFromSAId];

                    for(SpecialAcceptance__c sa : lstSpecialAcceptanceSentAgreFromSA){
                        sa.Active__c = 'Active';
                        sa.Bound__c = '2';
                    }                 
                }  

                lstSpecialAcceptanceGroupCover = [SELECT Id, InternalStatus__c, Bound__c, SentAgreFromSpecialAcceptance__c, Active__c, TECH_LocalSA__c FROM SpecialAcceptance__c WHERE TECH_LocalSA__c IN :lstSpecialAcceptanceId];

                for(SpecialAcceptance__c sa : lstSpecialAcceptanceGroupCover){
                    sa.Active__c = 'Active';
                    sa.Bound__c = '2';
                }   

                if(lstSpecialAcceptance.size() > 0){
                    update lstSpecialAcceptance;
                }     

                if(lstSpecialAcceptanceSentAgreFromSA.size() > 0){
                    update lstSpecialAcceptanceSentAgreFromSA;
                }    

                if(lstSpecialAcceptanceGroupCover.size() > 0){
                    update lstSpecialAcceptanceGroupCover;
                } 
            }

            mapResults.put('Success', 'Success');
        }catch (Exception ex) {
            Database.rollback(sp);
            mapResults.put('Error', ex.getMessage());
        }
        return mapResults;
    }

    /**
    * @description Method to bind selected Special Acceptances
    * @param List<Id> lstSpecialAcceptanceId
    * @return Map<String, Object>
    */
    @AuraEnabled
    public static Map<String, Object> bindSpecialAcceptanceRecords(List<SpecialAcceptance__c> lstSelectedSpecialAcceptance, Boolean isUserCE){
        Map<String, Object> mapResults = new Map<String, Object>();
        Map<String, Id> mapEmailTempIdByName = new Map<String, Id>();
        Map<Id, Id> mapIntCeSaByCedingPortalSa = new Map<Id, Id>();
        List<Messaging.SingleEmailMessage> lstMailsToSend =  new List<Messaging.SingleEmailMessage>();
        List<SpecialAcceptance__c> lstSaPCCEmail = new List<SpecialAcceptance__c>();
        List<SpecialAcceptance__c> lstSaCovCedContactEmail = new List<SpecialAcceptance__c>();
        List<SpecialAcceptance__c> lstSABRPoolEmailToSend = new List<SpecialAcceptance__c>();
        List<String> lstEmailTemplateName = new List<String>();
        List<Request__c> lstAllRequests = new List<Request__c>();
        List<Request__c> lstAllRequestBR = new List<Request__c>();
        Map<Id, List<Request__c>> mapPoolReqBySaId = new Map<Id, List<Request__c>>();
        String statusSetup = AP_Constant.statusSetup;
        Savepoint sp = Database.setSavepoint();

        try{
            Network networkObjPortal = [SELECT Id
                                  FROM Network
                                  WHERE Name =: System.Label.Actor_portal_name];

            String urlPortal = Network.getLoginUrl(networkObjPortal.Id);
            List <String> urlArrPortal = urlPortal.split('login');
            Id userId = UserInfo.getUserId();

            lstEmailTemplateName = new List<String>{AP_Constant.emailTempSaBindCedComPccSaEmail
                                                   ,AP_Constant.emailTempSaBindCedComBroker
                                                   ,AP_Constant.emailTempSaBindCedComReinsurer
                                                   ,AP_Constant.emailTempSaBindInternalCovCedCon
                                                   ,AP_Constant.emailTempSaBindInternalBroker
                                                   ,AP_Constant.emailTempSaBindInternalReinsurer};

            for(EmailTemplate emailTemp: [SELECT Id, Name FROM EmailTemplate WHERE Name IN : lstEmailTemplateName]){
                mapEmailTempIdByName.put(emailTemp.Name, emailTemp.Id);
            }

            Messaging.SingleEmailMessage emailTempSaBindCedComPccSaEmail = new Messaging.SingleEmailMessage();       
            emailTempSaBindCedComPccSaEmail = Messaging.renderStoredEmailTemplate(mapEmailTempIdByName.get(AP_Constant.emailTempSaBindCedComPccSaEmail), userId, null);

            Messaging.SingleEmailMessage emailTempSaBindCedComBroker = new Messaging.SingleEmailMessage();       
            emailTempSaBindCedComBroker = Messaging.renderStoredEmailTemplate(mapEmailTempIdByName.get(AP_Constant.emailTempSaBindCedComBroker), userId, null);

            Messaging.SingleEmailMessage emailTempSaBindCedComReinsurer = new Messaging.SingleEmailMessage();       
            emailTempSaBindCedComReinsurer = Messaging.renderStoredEmailTemplate(mapEmailTempIdByName.get(AP_Constant.emailTempSaBindCedComReinsurer), userId, null);

            Messaging.SingleEmailMessage emailTempSaBindInternalCovCedCon = new Messaging.SingleEmailMessage();       
            emailTempSaBindInternalCovCedCon = Messaging.renderStoredEmailTemplate(mapEmailTempIdByName.get(AP_Constant.emailTempSaBindInternalCovCedCon), userId, null);

            Messaging.SingleEmailMessage emailTempSaBindInternalBroker = new Messaging.SingleEmailMessage();       
            emailTempSaBindInternalBroker = Messaging.renderStoredEmailTemplate(mapEmailTempIdByName.get(AP_Constant.emailTempSaBindInternalBroker), userId, null);

            Messaging.SingleEmailMessage emailTempSaBindInternalReinsurer = new Messaging.SingleEmailMessage();       
            emailTempSaBindInternalReinsurer = Messaging.renderStoredEmailTemplate(mapEmailTempIdByName.get(AP_Constant.emailTempSaBindInternalReinsurer), userId, null);
            
            lstSelectedSpecialAcceptance = [SELECT Id, SentAgreFromSpecialAcceptance__r.SpecialAcceptanceName__c, Bound__c, Comments__c, SpecialAcceptanceName__c
                                                        , PrincipalCedingCompany__r.EmailSA__c, PrincipalCedingCompany__r.Name, TECH_LocalSA__c
                                                        , Program__r.Name, Program__r.UwYear__c, CoveredCedingCompany__r.Name
                                            FROM SpecialAcceptance__c 
                                            WHERE Id IN :lstSelectedSpecialAcceptance];

            if(isUserCE == true){
                //Internal CE
                //Update Bind Status of Internal Ce + SA Ceding + Group Cover
                //Send email alert to Covered Ceding Contact of Internal Ce + Group Cover
                //Send email alert to Broker/Reinsurer/Pool of SA Internal Ce + Group Cover Sa

                List<Id> lstSaCedingPortalId = new List<Id>(); 
                Map<Id, SpecialAcceptance__c> mapSaCovCedConBySaId = new Map<Id, SpecialAcceptance__c>();

                for(SpecialAcceptance__c internalCeSa : lstSelectedSpecialAcceptance){
                    internalCeSa.Bound__c = '1'; 
                    lstSaCovCedContactEmail.add(internalCeSA);
                    mapSaCovCedConBySaId.put(internalCeSA.Id, internalCeSA);
                    lstSABRPoolEmailToSend.add(internalCeSa);
                    
                    if(internalCeSA.SentAgreFromSpecialAcceptance__c != null){
                        lstSaCedingPortalId.add(internalCeSA.SentAgreFromSpecialAcceptance__c);
                    }
                }

                //Get all Related Sa From Ceding Portal (these sa is created upon 'Submit' button in Ceding Portal or 'New' in Internal Ce)
                List<SpecialAcceptance__c> lstSaCedingPortal = [SELECT Id, SentAgreFromSpecialAcceptance__r.SpecialAcceptanceName__c, Bound__c, Comments__c
                                                                     , PrincipalCedingCompany__r.EmailSA__c, PrincipalCedingCompany__r.Name, TECH_LocalSA__c
                                                                     , Program__r.Name, Program__r.UwYear__c, CoveredCedingCompany__r.Name
                                                                FROM SpecialAcceptance__c 
                                                                WHERE Id IN :lstSaCedingPortalId];

                for(SpecialAcceptance__c cedingPortalSA : lstSaCedingPortal){
                    cedingPortalSA.Bound__c = '1';
                }

                if(lstSaCedingPortal.size() > 0){
                    update lstSaCedingPortal;
                }

                List<SpecialAcceptance__c> lstGroupCoverSaInternalCe = new List<SpecialAcceptance__c>();

                if(lstSelectedSpecialAcceptance.size() > 0){
                    update lstSelectedSpecialAcceptance;
                    
                    //Get group cover sa of internal ce sa 
                    lstGroupCoverSaInternalCe = [SELECT Id, SentAgreFromSpecialAcceptance__r.SpecialAcceptanceName__c, Bound__c, Comments__c, SpecialAcceptanceName__c
                                                        , PrincipalCedingCompany__r.EmailSA__c, PrincipalCedingCompany__r.Name, TECH_LocalSA__c
                                                        , Program__r.Name, Program__r.UwYear__c, CoveredCedingCompany__r.Name
                                                 FROM SpecialAcceptance__c 
                                                 WHERE TECH_LocalSA__c IN :lstSelectedSpecialAcceptance];

                    for(SpecialAcceptance__c groupCoverSa : lstGroupCoverSaInternalCe){
                        groupCoverSa.Bound__c = '1';
                        lstSaCovCedContactEmail.add(groupCoverSa);
                        mapSaCovCedConBySaId.put(groupCoverSa.Id, groupCoverSa);
                        lstSABRPoolEmailToSend.add(groupCoverSa);
                    }
                }

                if(lstGroupCoverSaInternalCe.size() > 0){
                    update lstGroupCoverSaInternalCe;
                }

                //Send email alert to Covered Ceding Contact of Internal Ce + Group Cover
                //build map of sa, list of covered ceding contact

                Map<Id, List<AccountContactRelation>> mapLstCovCedConBySaId = new Map<Id, List<AccountContactRelation>>();
                mapLstCovCedConBySaId = getCovCedContact(lstSaCovCedContactEmail);

                Network networkObj = [SELECT Id
                                      FROM Network
                                      WHERE Name =: System.Label.Actor_ceding_portal_name];

                String url = Network.getLoginUrl(networkObj.Id);
                List<String> urlArr = url.split('login');
                
                for(Id saId : mapLstCovCedConBySaId.keySet()) {
                    List<AccountContactRelation> lstCovAccCont = mapLstCovCedConBySaId.get(saId);
                    SpecialAcceptance__c sa = mapSaCovCedConBySaId.get(saId);

                    for(AccountContactRelation covCedCon : lstCovAccCont){
                        Messaging.SingleEmailMessage m = new Messaging.SingleEmailMessage();
                        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                        List<String> lstEmailsToSend = new List<String>();
                        Id emailTempSaBindInternalCovCedConEmailId = mapEmailTempIdByName.get(AP_Constant.emailTempSaBindInternalCovCedCon);
                        String pccSaEmail = sa.PrincipalCedingCompany__r.EmailSA__c;
                        String email = covCedCon.Contact.Email;
                        String pccSaEmailDisplay = null;
                        List<String> lstSaPCCEmailsToSend = new List<String>();
                        // m = Messaging.renderStoredEmailTemplate(emailTempSaBindInternalCovCedConEmailId, userId, null);

                        m.setTemplateId(emailTempSaBindInternalCovCedConEmailId);
                        m.setTargetObjectId(userId);
                        // m.setWhatId(reqId);
                        m.setSaveAsActivity(false);
                        m.setSubject(emailTempSaBindInternalCovCedCon.getSubject());
                        m.setHtmlBody(emailTempSaBindInternalCovCedCon.htmlBody);

                        if(pccSaEmail != null ){
                            if(pccSaEmail.contains(';')){
                                lstSaPCCEmailsToSend = pccSaEmail.split(';');
                            }
                            else{
                                lstSaPCCEmailsToSend.add(pccSaEmail);
                            }
                        }

                        for(String pccEmail : lstSaPCCEmailsToSend){
                            if(pccSaEmailDisplay == null){
                                pccSaEmailDisplay = pccEmail;
                            }
                            else{
                                pccSaEmailDisplay = pccSaEmailDisplay + ' ' + pccEmail;   
                            }
                        }

                        if(lstSaPCCEmailsToSend.size() > 0){
                            mail.setCcAddresses(lstSaPCCEmailsToSend);
                        }

                        lstEmailsToSend.add(email); // contact email
                        mail.setToAddresses(lstEmailsToSend);
                        mail.setReplyTo(UserInfo.getUserEmail());
                        mail.setSenderDisplayName(UserInfo.getFirstName() + ' ' + UserInfo.getLastName());

                        String htmlBody = m.htmlBody;
                        String htmlSubject = m.getSubject();
                        String saUrl = urlArr[0] + 'SADetail?s__id=' + sa.Id + '-' + sa.Program__r.UwYear__c + '-' + sa.PrincipalCedingCompany__c + '-' + sa.Program__c;
                        String saLink = '<a href="' + saUrl +'">Link of Special Acceptance</a>';
                        String htmlInternetLink = '<a href="' + urlArr[0] +'">ACTOR Page</a>';

                        htmlBody = htmlBody.replace('{U/W Year}', sa.Program__r.UwYear__c);
                        htmlBody = htmlBody.replace('{Programname}', sa.Program__r.Name);
                        htmlBody = htmlBody.replace('{SAname}', sa.SpecialAcceptanceName__c);        

                        String strPccSaEmailDisplay = pccSaEmailDisplay != null ? pccSaEmailDisplay : '';
                        htmlBody = htmlBody.replace('{SAEmailPCC}', strPccSaEmailDisplay);
                       
                        htmlBody = htmlBody.replace('[URLofTheSpecialAcceptance]', saLink);
                        htmlBody = htmlBody.replace('{ActorNewGenURL}', htmlInternetLink);

                        String strCCC = sa.CoveredCedingCompany__r != null ? sa.CoveredCedingCompany__r.Name : '';
                        htmlBody = htmlBody.replace('{Coveredcedingcompany}', strCCC);
                        htmlSubject = htmlSubject.replace('{CedingCompanyName}', strCCC);  

                        String strComment = sa.Comments__c != null ? sa.Comments__c : '';
                        String commentStrDesigned = '<b style="color:blue";><font face="Arial" size="50px">' + strComment + '</font></b>'; //RRA - ticket 1382 - 1912202
                        htmlBody = htmlBody.replace('{Comments}', commentStrDesigned); //RRA - ticket 1382 - 1912202

                        htmlSubject = htmlSubject.replace('{ProgramName}', sa.Program__r.Name);  

                        mail.setHtmlBody(htmlBody);
                        mail.setSubject(htmlSubject);
                        lstMailsToSend.add(mail);
                    }
                }
            }
            else{
                //Ceding Portal
                //Update Bind Status of SA Ceding + Internal Ce + Group Cover
                //Send email alert to SAEmail of PCC of SA Ceding + Group Cover
                //Send email alert to Broker/Reinsurer/Pool of SA Internal Ce + Group Cover Sa 

                User usr = [SELECT Id, ContactId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
                Id contactId = usr.ContactId;
                String covCedConEmail;

                if(contactId != null){
                    Contact covCedContact = [SELECT Id, AccountId, Email FROM Contact WHERE Id = :contactId LIMIT 1];
                    covCedConEmail = covCedContact.Email;
                }

                for(SpecialAcceptance__c cedingPortalSa : lstSelectedSpecialAcceptance){
                    cedingPortalSa.Bound__c = '1';
                    lstSaPCCEmail.add(cedingPortalSa);
                }

                if(lstSelectedSpecialAcceptance.size() > 0){
                    update lstSelectedSpecialAcceptance;
                }

                //Build a map of Ceding Portal Sa, Internal Ce Sa -> mapIntCeSaByCedingPortalSa
                //Get all Related Sa From Internal Ce (these sa is created upon 'Submit' button in Ceding Portal or 'New' in Internal Ce)
                List<SpecialAcceptance__c> lstSaInternalCe = [SELECT Id, SentAgreFromSpecialAcceptance__r.SpecialAcceptanceName__c, Bound__c, Comments__c
                                                                     , PrincipalCedingCompany__r.EmailSA__c, PrincipalCedingCompany__r.Name, TECH_LocalSA__c
                                                                     , Program__r.Name, Program__r.UwYear__c, CoveredCedingCompany__r.Name
                                                              FROM SpecialAcceptance__c 
                                                              WHERE SentAgreFromSpecialAcceptance__c IN :lstSelectedSpecialAcceptance];

                for(SpecialAcceptance__c internalCeSA : lstSaInternalCe){
                    mapIntCeSaByCedingPortalSa.put(internalCeSA.SentAgreFromSpecialAcceptance__c, internalCeSA.Id);
                    internalCeSA.Bound__c = '1';
                    lstSABRPoolEmailToSend.add(internalCeSA);
                }

                if(lstSaInternalCe.size() > 0){
                    update lstSaInternalCe;
                }

                List<SpecialAcceptance__c> lstGroupCoverSaInternalCe = new List<SpecialAcceptance__c>();

                if(lstSaInternalCe.size() > 0){
                    update lstSaInternalCe;
                    
                    //Get group cover sa of internal ce sa 
                    lstGroupCoverSaInternalCe = [SELECT Id, SentAgreFromSpecialAcceptance__r.SpecialAcceptanceName__c, Bound__c, Comments__c, SpecialAcceptanceName__c
                                                        , PrincipalCedingCompany__r.EmailSA__c, PrincipalCedingCompany__r.Name, TECH_LocalSA__c
                                                        , Program__r.Name, Program__r.UwYear__c, CoveredCedingCompany__r.Name
                                                 FROM SpecialAcceptance__c 
                                                 WHERE TECH_LocalSA__c IN :lstSaInternalCe];

                    lstSaPCCEmail.addAll(lstGroupCoverSaInternalCe);
                }

                for(SpecialAcceptance__c groupCoverSa : lstGroupCoverSaInternalCe){
                    groupCoverSa.Bound__c = '1';
                    lstSABRPoolEmailToSend.add(groupCoverSa);
                }

                if(lstGroupCoverSaInternalCe.size() > 0){
                    update lstGroupCoverSaInternalCe;
                }

                //Send email alert to SA Email of PCC for SA Ceding Portal + Group Cover SA

                for(SpecialAcceptance__c sa : lstSaPCCEmail){
                    Messaging.SingleEmailMessage m = new Messaging.SingleEmailMessage();
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    List<String> lstEmailsToSend = new List<String>();
                    // Id userId = UserInfo.getUserId();
                    Id emailTempSaBindCedComPccSaEmailId = mapEmailTempIdByName.get(AP_Constant.emailTempSaBindCedComPccSaEmail);
                    String pccSaEmail = sa.PrincipalCedingCompany__r.EmailSA__c;
                    String pccSaEmailDisplay = null;
                    List<String> lstLstPccSaEmail = new List<String>();

                    if(pccSaEmail != null ){
                        if(pccSaEmail.contains(';')){
                            lstLstPccSaEmail = pccSaEmail.split(';');
                        }
                        else{
                            lstLstPccSaEmail.add(pccSaEmail);
                        }
                    }

                    for(String pccEmail : lstLstPccSaEmail){
                        if(pccSaEmailDisplay == null){
                            pccSaEmailDisplay = pccEmail;
                        }
                        else{
                            pccSaEmailDisplay = pccSaEmailDisplay + ' ' + pccEmail;   
                        }
                    }

                    if(lstLstPccSaEmail.size() > 0){
                        m.setTemplateId(emailTempSaBindCedComPccSaEmailId);
                        m.setTargetObjectId(userId);
                        // m.setWhatId(reqId);
                        m.setSaveAsActivity(false);
                        m.setSubject(emailTempSaBindCedComPccSaEmail.getSubject());
                        m.setHtmlBody(emailTempSaBindCedComPccSaEmail.htmlBody);
                        
                        // m = Messaging.renderStoredEmailTemplate(emailTempSaBindCedComPccSaEmailId, userId, null);
                        mail.setToAddresses(lstLstPccSaEmail);
                        mail.setReplyTo(UserInfo.getUserEmail());
                        mail.setSenderDisplayName(UserInfo.getFirstName() + ' ' + UserInfo.getLastName());

                        if(lstLstPccSaEmail.size() > 0){
                            mail.setCcAddresses(lstLstPccSaEmail);
                        }

                        String htmlBody = m.htmlBody;
                        String htmlSubject = m.getSubject();
                        String url = String.valueOf(System.URL.getOrgDomainUrl().toExternalForm());
                        String htmlInternetLink = '<a href="' + url + '/lightning/page/home">ACTOR NewGen Page</a>';
                        Id internalCeSaId;

                        if(sa.TECH_LocalSA__c == null){
                            //Ceding portal sa
                            internalCeSaId = mapIntCeSaByCedingPortalSa.get(sa.Id); //to display related internal ce sa of ceding portal sa
                        }
                        else{
                            //Group cover sa
                            internalCeSaId = sa.Id; //group cover - internal ce sa
                        }

                        String urlLoadSARequest = '/lightning/n/LoadSARequest?s__id='+internalCeSaId+'-'+sa.Program__r.UwYear__c+'-'+sa.PrincipalCedingCompany__c+'-'+sa.Program__c;
                        String urlLoadSARequestLink = '<a href="' + url + urlLoadSARequest + '">Link</a>';

                        htmlBody = htmlBody.replace('{U/W Year}', sa.Program__r.UwYear__c);
                        htmlBody = htmlBody.replace('{Programname}', sa.Program__r.Name);
                        htmlBody = htmlBody.replace('{SAname}', sa.SpecialAcceptanceName__c);

                        String strPccSaEmailDisplay = pccSaEmailDisplay != null ? pccSaEmailDisplay : '';
                        htmlBody = htmlBody.replace('{pccEmail}', strPccSaEmailDisplay);
                        
                        htmlBody = htmlBody.replace('[URLofTheSpecialAcceptance]', urlLoadSARequestLink);
                        htmlBody = htmlBody.replace('{ActorNewGenURL}', htmlInternetLink);

                        if(covCedConEmail != null){
                            htmlBody = htmlBody.replace('{covCedContactEmail}', covCedConEmail);
                        }

                        String strCovCedCom = sa.CoveredCedingCompany__r != null? sa.CoveredCedingCompany__r.Name : '';
                        htmlBody = htmlBody.replace('{Coveredcedingcompany}', strCovCedCom);
                        htmlSubject = htmlSubject.replace('{CedingCompanyName}', strCovCedCom);

                        String strComments = sa.Comments__c != null ? sa.Comments__c : '';
                        String commentStrDesigned = '<b style="color:blue";><font face="Arial" size="50px">' + strComments + '</font></b>'; //RRA - ticket 1382 - 1912202
                        htmlBody = htmlBody.replace('{Comments}', commentStrDesigned); //RRA - ticket 1382 - 1912202

                        htmlSubject = htmlSubject.replace('{ProgramName}', sa.Program__r.Name);  
                        mail.setHtmlBody(htmlBody);
                        mail.setSubject(htmlSubject);
                        lstMailsToSend.add(mail);
                    }
                }
            }

            //Send email alert to Pool of Internal Ce + Group Cover Sa
            //build map of sa, list of Pool Request 

            if(lstSABRPoolEmailToSend.size() > 0){
                lstAllRequests = [SELECT Id, Name, Special_Acceptance__c, Program__r.Name, PrincipalCedingCompany__c, Program__r.UwYear__c
                                            , Program__r.Macro_L_O_B__c, toLabel(Program__r.Nature__c), Program__r.PrincipalCedingCompany__c
                                            , Pool__r.SA_Email__c, Pool__r.Name, Broker__r.Name, Reinsurer__r.Name, BrokerStatus__c, ExpectedResponseDate__c
                                            , Special_Acceptance__r.SpecialAcceptanceName__c, Special_Acceptance__r.Comments__c, SA_Type__c
                                            , Special_Acceptance__r.CoveredCedingCompany__r.Name, Special_Acceptance__r.PrincipalCedingCompany__r.EmailSA__c
                                  FROM Request__c 
                                  WHERE Special_Acceptance__c IN :lstSABRPoolEmailToSend
                                  AND (LastVersionSent__c = TRUE AND LastVersionAnswered__c = TRUE) AND SA_Request_Status__c <> :statusSetup];
            }

            for(Request__c saReq : lstAllRequests){
                List<Request__c> lstPoolReq = new List<Request__c>();
                if(mapPoolReqBySaId.containsKey(saReq.Special_Acceptance__c)){
                    lstPoolReq = mapPoolReqBySaId.get(saReq.Special_Acceptance__c);
                }

                if(saReq.Pool__c != null){
                    lstPoolReq.add(saReq);
                    mapPoolReqBySaId.put(saReq.Special_Acceptance__c, lstPoolReq);
                }
                else{
                    lstAllRequestBR.add(saReq);
                }
            }

            for(Id saId : mapPoolReqBySaId.keySet()){
                List<Request__c> lstPoolRequest = mapPoolReqBySaId.get(saId);
                for(Request__c poolReq : lstPoolRequest){
                    Messaging.SingleEmailMessage m = new Messaging.SingleEmailMessage();
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    List<String> lstEmailsToSend = new List<String>();
                    List<String> lstSaPCCEmailsToSend = new List<String>();
                    // Id userId = UserInfo.getUserId();
                    Id emailTempSaBindReinsurerEmailId;

                    if(isUserCE == true){
                        emailTempSaBindReinsurerEmailId = mapEmailTempIdByName.get(AP_Constant.emailTempSaBindInternalReinsurer);
                    }
                    else{
                        emailTempSaBindReinsurerEmailId = mapEmailTempIdByName.get(AP_Constant.emailTempSaBindCedComReinsurer);
                    }

                    String pccSaEmail = poolReq.Special_Acceptance__r.PrincipalCedingCompany__r.EmailSA__c;
                    String poolSaEmail = poolReq.Pool__r.SA_Email__c;
                    String pccSaEmailDisplay = null;

                    // m = Messaging.renderStoredEmailTemplate(emailTempSaBindReinsurerEmailId, userId, null);
                    m.setTemplateId(emailTempSaBindReinsurerEmailId);
                    m.setTargetObjectId(userId);
                    // m.setWhatId(reqId);

                    if(isUserCE == true){
                        m.setSubject(emailTempSaBindInternalReinsurer.getSubject());
                        m.setHtmlBody(emailTempSaBindInternalReinsurer.htmlBody);
                    }
                    else{
                        m.setSubject(emailTempSaBindCedComReinsurer.getSubject());
                        m.setHtmlBody(emailTempSaBindCedComReinsurer.htmlBody);
                    }
                    
                    m.setSaveAsActivity(false);
                    lstEmailsToSend.add(poolSaEmail); //Send to pool SA Email
                    mail.setToAddresses(lstEmailsToSend);
                    mail.setReplyTo(UserInfo.getUserEmail());
                    mail.setSenderDisplayName(UserInfo.getFirstName() + ' ' + UserInfo.getLastName());

                    if(pccSaEmail != null ){
                        if(pccSaEmail.contains(';')){
                            lstSaPCCEmailsToSend = pccSaEmail.split(';');
                        }
                        else{
                            lstSaPCCEmailsToSend.add(pccSaEmail);
                        }
                    }

                    for(String pccEmail : lstSaPCCEmailsToSend){
                        if(pccSaEmailDisplay == null){
                            pccSaEmailDisplay = pccEmail;
                        }
                        else{
                            pccSaEmailDisplay = pccSaEmailDisplay + ' ' + pccEmail;   
                        }
                    }

                    if(lstSaPCCEmailsToSend.size() > 0){
                        mail.setCcAddresses(lstSaPCCEmailsToSend);
                    }

                    String htmlBody = m.htmlBody;
                    String htmlSubject = m.getSubject();
                    String urlDomain = String.valueOf(System.URL.getOrgDomainUrl().toExternalForm());
                    String htmlInternetLink = '<a href="' + urlDomain + '/lightning/page/home">ACTOR NewGen Page</a>';
                    String urlLoadSARequest = '/lightning/n/LoadSARequest?s__id='+saId+'-'+poolReq.Program__r.UwYear__c+'-'+poolReq.PrincipalCedingCompany__c+'-'+poolReq.Program__c+'-All-ugp';
                    String urlLoadSARequestLink = '<a href="' + urlDomain + urlLoadSARequest + '">Link</a>';

                    htmlBody = htmlBody.replace('{U/W Year}', poolReq.Program__r.UwYear__c);
                    htmlBody = htmlBody.replace('{Programname}', poolReq.Program__r.Name);
                    htmlBody = htmlBody.replace('{SAname}', poolReq.Special_Acceptance__r.SpecialAcceptanceName__c);

                    String strPccSaEmailDisplays = pccSaEmailDisplay != null ? pccSaEmailDisplay : '';
                    htmlBody = htmlBody.replace('{SAEmailPCC}', strPccSaEmailDisplays);
                    
                    htmlBody = htmlBody.replace('[URLofTheSpecialAcceptance]', urlLoadSARequestLink);
                    htmlBody = htmlBody.replace('{ActorNewGenURL}', htmlInternetLink);

                    String strCCCName = poolReq.Special_Acceptance__r.CoveredCedingCompany__r != null ? poolReq.Special_Acceptance__r.CoveredCedingCompany__r.Name : '';
                    htmlBody = htmlBody.replace('{Coveredcedingcompany}', strCCCName);
                    htmlSubject = htmlSubject.replace('{CedingCompanyName}', strCCCName);  

                    String strCommentPool = poolReq.Special_Acceptance__r.Comments__c != null ? poolReq.Special_Acceptance__r.Comments__c : '';
                    String commentStrDesignedPool = '<b style="color:blue";><font face="Arial" size="50px">' + strCommentPool + '</font></b>'; //RRA - ticket 1382 - 1912202
                    htmlBody = htmlBody.replace('{Comments}', commentStrDesignedPool); //RRA - ticket 1382 - 1912202

                    htmlSubject = htmlSubject.replace('{ProgramName}', poolReq.Program__r.Name);  

                    mail.setHtmlBody(htmlBody);
                    mail.setSubject(htmlSubject);
                    lstMailsToSend.add(mail);
                }
            }

            //Send email alert to BR of Internal Ce + Group Cover Sa
            //Build map of sa, list of BR Request contact

            Map<Request__c, List<AccountContactRelation>> mapAccConRelBySAR = getBRContact(lstAllRequestBR);
            // Id userId = UserInfo.getUserId();

            for(Request__c saReq : mapAccConRelBySAR.keySet()){
                List<AccountContactRelation> lstBRContact = mapAccConRelBySAR.get(saReq);

                for(AccountContactRelation contactBR : lstBRContact){
                    Messaging.SingleEmailMessage m = new Messaging.SingleEmailMessage();
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    List<String> lstEmailsToSend = new List<String>();
                    
                    Id emailTempSaBindBREmailId;

                    String pccSaEmail = saReq.Special_Acceptance__r.PrincipalCedingCompany__r.EmailSA__c;
                    String contactEmail = contactBR.Contact.Email;
                    String pccSaEmailDisplay = null;
                    List<String> lstSaPCCEmailsToSend = new List<String>();

                    if(saReq.Broker__c != null && saReq.BrokerStatus__c != '1'){
                        //Send mail alert to Broker
                        if(isUserCE == true){
                            emailTempSaBindBREmailId = mapEmailTempIdByName.get(AP_Constant.emailTempSaBindInternalBroker);
                            m.setTemplateId(emailTempSaBindBREmailId);
                            m.setTargetObjectId(userId);
                            m.setSubject(emailTempSaBindInternalBroker.getSubject());
                            m.setHtmlBody(emailTempSaBindInternalBroker.htmlBody);
                        }
                        else{
                            emailTempSaBindBREmailId = mapEmailTempIdByName.get(AP_Constant.emailTempSaBindInternalBroker);
                            m.setTemplateId(emailTempSaBindBREmailId);
                            m.setTargetObjectId(userId);
                            m.setSubject(emailTempSaBindInternalBroker.getSubject());
                            m.setHtmlBody(emailTempSaBindInternalBroker.htmlBody);
                        }
                    }
                    else{
                        //Send mail alert to Reinsurer
                        if(isUserCE == true){
                            emailTempSaBindBREmailId = mapEmailTempIdByName.get(AP_Constant.emailTempSaBindInternalReinsurer);
                            m.setTemplateId(emailTempSaBindBREmailId);
                            m.setTargetObjectId(userId);
                            m.setSubject(emailTempSaBindInternalReinsurer.getSubject());
                            m.setHtmlBody(emailTempSaBindInternalReinsurer.htmlBody);
                        }
                        else{
                            emailTempSaBindBREmailId = mapEmailTempIdByName.get(AP_Constant.emailTempSaBindCedComReinsurer);
                            m.setTemplateId(emailTempSaBindBREmailId);
                            m.setTargetObjectId(userId);
                            m.setSubject(emailTempSaBindCedComReinsurer.getSubject());
                            m.setHtmlBody(emailTempSaBindCedComReinsurer.htmlBody);
                        }
                    }

                    // m = Messaging.renderStoredEmailTemplate(emailTempSaBindBREmailId, userId, null);
                    m.setSaveAsActivity(false);
                    lstEmailsToSend.add(contactEmail);
                    mail.setToAddresses(lstEmailsToSend);
                    mail.setReplyTo(UserInfo.getUserEmail());
                    mail.setSenderDisplayName(UserInfo.getFirstName() + ' ' + UserInfo.getLastName());

                    if(pccSaEmail != null ){
                        if(pccSaEmail.contains(';')){
                            lstSaPCCEmailsToSend = pccSaEmail.split(';');
                        }
                        else{
                            lstSaPCCEmailsToSend.add(pccSaEmail);
                        }
                    }

                    for(String pccEmail : lstSaPCCEmailsToSend){
                        if(pccSaEmailDisplay == null){
                            pccSaEmailDisplay = pccEmail;
                        }
                        else{
                            pccSaEmailDisplay = pccSaEmailDisplay + ' ' + pccEmail;   
                        }
                    }

                    if(lstSaPCCEmailsToSend.size() > 0){
                        mail.setCcAddresses(lstSaPCCEmailsToSend);
                    }

                    String urlLoadSARequestBrokerRein = 'SARespondOnBehalf?s__id='+saReq.Special_Acceptance__c+'-'+saReq.Program__r.UwYear__c+'-'+saReq.Program__r.PrincipalCedingCompany__c+'-'+saReq.Program__c+'-'+saReq.Broker__c+'-'+saReq.Reinsurer__c+'-undefined-portalBR-undefined-'+saReq.Id;
                    String urlLoadSARequestLinkBrokerRein = '<a href="' + urlArrPortal[0] + urlLoadSARequestBrokerRein + '">'+saReq.Reinsurer__r.Name+'</a>';
                    String strReinsurerName = '';

                    if(strReinsurerName == ''){
                        strReinsurerName = '<li style="text-align: left;">' + urlLoadSARequestLinkBrokerRein + ' {'+ saReq.SA_Type__c +'}</li>';
                    }
                    else{
                        strReinsurerName += '<li style="text-align: left;">' + urlLoadSARequestLinkBrokerRein + ' {'+ saReq.SA_Type__c +'}</li>';
                    }

                    String htmlBody = m.htmlBody;
                    String htmlSubject = m.getSubject();
                    String urlDomain = String.valueOf(System.URL.getOrgDomainUrl().toExternalForm());
                    String htmlInternetLink = '<a href="' + urlDomain + '/lightning/page/home">ACTOR NewGen Page</a>';
                    String urlLoadSARequest = '/lightning/n/LoadSARequest?s__id='+saReq.Special_Acceptance__c+'-'+saReq.Program__r.UwYear__c+'-'+saReq.PrincipalCedingCompany__c+'-'+saReq.Program__c;
                    String urlLoadSARequestLink = '<a href="' + urlDomain + urlLoadSARequest + '">Link</a>';
                    
                    htmlBody = htmlBody.replace('{U/W Year}', saReq.Program__r.UwYear__c);
                    htmlBody = htmlBody.replace('{Programname}', saReq.Program__r.Name);
                    htmlBody = htmlBody.replace('{SAname}', saReq.Special_Acceptance__r.SpecialAcceptanceName__c);

                    String strPccSaEmailDisplayRein = pccSaEmailDisplay != null ? pccSaEmailDisplay : '';
                    htmlBody = htmlBody.replace('{SAEmailPCC}', strPccSaEmailDisplayRein);  

                    htmlBody = htmlBody.replace('[URLofTheSpecialAcceptance]', urlLoadSARequestLink);
                    htmlBody = htmlBody.replace('{ActorNewGenURL}', htmlInternetLink);
                    htmlSubject = htmlSubject.replace('{ProgramName}', saReq.Program__r.Name); 
                    
                    if(strReinsurerName != null){
                        htmlBody = htmlBody.replace('{ListReinsurerLink}', strReinsurerName);
                    }
                    else{
                        htmlBody = htmlBody.replace('{ListReinsurerLink}', '');
                    }

                    String strCovCedComName = saReq.Special_Acceptance__r.CoveredCedingCompany__r != null? saReq.Special_Acceptance__r.CoveredCedingCompany__r.Name : '';
                    htmlBody = htmlBody.replace('{Coveredcedingcompany}', strCovCedComName);
                    htmlSubject = htmlSubject.replace('{CedingCompanyName}', strCovCedComName);

                    String strCommentRein = saReq.Special_Acceptance__r.Comments__c != null? saReq.Special_Acceptance__r.Comments__c : '';
                    String commentStrDesigned = '<b style="color:blue";><font face="Arial" size="50px">' + strCommentRein + '</font></b>'; //RRA - ticket 1382 - 1912202
                    htmlBody = htmlBody.replace('{Comments}', commentStrDesigned); //RRA - ticket 1382 - 1912202

                    String strExpectedResDate = saReq.ExpectedResponseDate__c != null ? String.valueOf(saReq.ExpectedResponseDate__c) : '';
                    htmlBody = htmlBody.replace('{expectedAnswerDate}', strExpectedResDate);

                    mail.setHtmlBody(htmlBody);
                    mail.setSubject(htmlSubject);
                    lstMailsToSend.add(mail);
                }
            }

            if(lstMailsToSend.size() > 0){
                Messaging.sendEmail((List<Messaging.Email>) lstMailsToSend);
            }

            mapResults.put('Success', 'Success');
        }catch (Exception ex) {
            Database.rollback(sp);
            mapResults.put('Error', ex.getMessage());
        }
        return mapResults;
    }

    /**
    * @description Method to get Contact(s) for Covered Ceding Company
    * @param SpecialAcceptance__c specialAcceptanceObj
    * @return Map<String, Object>
    */
    @AuraEnabled
    public static Map<Id, List<AccountContactRelation>> getCovCedContact(List<SpecialAcceptance__c> lstSpecialAcceptance) {
        Map<Id, Id> mapUserIdByContactId = new Map<Id, Id>();
        Map<Id, List<AccountContactRelation>> mapLstCovCedConBySaId = new Map<Id, List<AccountContactRelation>>();
        Map<Id, List<AccountContactRelation>> mapLstCovCedConBySaIdToDisplay = new Map<Id, List<AccountContactRelation>>();
        Map<Id, SpecialAcceptance__c> mapSaBySaId = new Map<Id, SpecialAcceptance__c>();
        Map<Id, String> mapReferentialIdByPCC = new Map<Id, String>();
        Map<String, Group> mapGroupByReferentialId = new Map<String, Group>();
        Map<Id, List<Id>> mapLstUserOrGroupIdByGroupId = new Map<Id, List<Id>>();
        List<AccountContactRelation> lstAccConRelation = new List<AccountContactRelation>(); 
        Set<String> setReferentialId = new Set<String>();
        Set<Id> setContactId = new Set<Id>();
        Set<Id> setCovCedComId = new Set<Id>();
        Set<Id> setPrinCedComId = new Set<Id>();

        try{
            for(SpecialAcceptance__c sa : lstSpecialAcceptance){
                setPrinCedComId.add(sa.PrincipalCedingCompany__c);
                mapSaBySaId.put(sa.Id, sa);
                if(sa.CoveredCedingCompany__c != null){
                    setCovCedComId.add(sa.CoveredCedingCompany__c);
                }
            }

            for(AccountContactRelation accContactRelation : [SELECT Id, AccountId,Account.Name, Account.RecordTypeId, Contact.Account.RecordTypeId, Contact.Email, Roles, ContactId, Contact.MacroLoB__c, Contact.Nature__c, Contact.LastName, Contact.FirstName FROM AccountContactRelation
                                                            WHERE AccountId IN :setCovCedComId
                                                            AND IsActive = TRUE]){
                if(accContactRelation.Account.RecordTypeId == accContactRelation.Contact.Account.RecordTypeId){
                    lstAccConRelation.add(accContactRelation);
                    setContactId.add(accContactRelation.ContactId);
                }
            }

            for(SpecialAcceptance__c sa : lstSpecialAcceptance){
                for(AccountContactRelation accContactRelation : lstAccConRelation){
                    List<AccountContactRelation> lstCovAccCon = new List<AccountContactRelation>();
                    if(sa.CoveredCedingCompany__c == accContactRelation.AccountId){
                        if(mapLstCovCedConBySaId.containsKey(sa.Id)){
                            lstCovAccCon = mapLstCovCedConBySaId.get(sa.Id);
                        }
                        lstCovAccCon.add(accContactRelation);
                        mapLstCovCedConBySaId.put(sa.Id, lstCovAccCon);
                    }
                }
            }

            for(User user : [SELECT Id, ContactId, IsActive FROM User WHERE ContactId IN :setContactId AND IsActive = true]){
                mapUserIdByContactId.put(user.ContactId, user.Id);
            }

            List<Account> lstAccount = [SELECT Id, Name, TECH_ReferentialId__c FROM Account WHERE Id IN :setPrinCedComId];

            for(Account acc : lstAccount){
                setReferentialId.add(acc.TECH_ReferentialId__c);
                mapReferentialIdByPCC.put(acc.Id, acc.TECH_ReferentialId__c);
            }
            
            List<Group> lstGroup = [SELECT Id, DeveloperName FROM Group WHERE DeveloperName IN :setReferentialId];
            
            for(Group gp : lstGroup){
                mapGroupByReferentialId.put(gp.DeveloperName, gp);
            }

            for(GroupMember groupMember : [SELECT Id, GroupId, UserOrGroupId FROM GroupMember WHERE GroupId IN :lstGroup]){
                List<Id> lstUserOrGroupId = new List<Id>();
                
                if(mapLstUserOrGroupIdByGroupId.containsKey(groupMember.GroupId)){
                    lstUserOrGroupId = mapLstUserOrGroupIdByGroupId.get(groupMember.GroupId);
                }

                lstUserOrGroupId.add(groupMember.UserOrGroupId);
                mapLstUserOrGroupIdByGroupId.put(groupMember.GroupId, lstUserOrGroupId);
            }

            for(Id saId : mapLstCovCedConBySaId.keySet()){
                SpecialAcceptance__c sa = mapSaBySaId.get(saId);
                Id pccId = sa.PrincipalCedingCompany__c;
                List<AccountContactRelation> lstCovCedAccConRelation = mapLstCovCedConBySaId.get(saId);
                List<AccountContactRelation> lstAccountContactRelationsToDisplay = new List<AccountContactRelation>();

                //get Referential Id of PCC
                if(mapReferentialIdByPCC.containsKey(pccId)){
                    String pccReferentialId = mapReferentialIdByPCC.get(pccId);
                    //get Group of Referential Id 0f PCC
                    if(mapGroupByReferentialId.containsKey(pccReferentialId)){
                        Group gp = mapGroupByReferentialId.get(pccReferentialId);

                        //get list of User or Group Id of group of Referential Id 0f PCC 
                        if(mapLstUserOrGroupIdByGroupId.containsKey(gp.Id)){
                            List<Id> lstUserOrGroupIdOfPCC = mapLstUserOrGroupIdByGroupId.get(gp.Id);
                            Set<Id> setUserOrGroupIdOfPCC = new Set<Id>();
                            setUserOrGroupIdOfPCC.addAll(lstUserOrGroupIdOfPCC);
                            for(AccountContactRelation covCedCon : lstCovCedAccConRelation){
                                //get userId for Covered Ceding Contact
                                if(mapUserIdByContactId.containsKey(covCedCon.ContactId)){
                                    Id userId = mapUserIdByContactId.get(covCedCon.ContactId);
                                    if(setUserOrGroupIdOfPCC.contains(userId)){
                                        lstAccountContactRelationsToDisplay.add(covCedCon);
                                    }
                                }
                            }
                        }
                    }
                }

                mapLstCovCedConBySaIdToDisplay.put(saId, lstAccountContactRelationsToDisplay);
            }
        }catch (Exception ex) {
        }
        
        return mapLstCovCedConBySaIdToDisplay;
    }

    /**
    * @description Method to get Broker/Reinsurer Contact(s) for Program
    * @param List<Request__c> lstSAR
    * @return Map<Request__c, List<AccountContactRelation>>
    */
    @AuraEnabled
    public static Map<Request__c, List<AccountContactRelation>> getBRContact(List<Request__c> lstSAR) {
        Map<Id, List<AccountContactRelation>> mapContactRel = new Map<Id, List<AccountContactRelation>>();
        Map<Request__c, List<AccountContactRelation>> mapContactRelBySAR = new Map<Request__c, List<AccountContactRelation>>();
        List<Id> lstAllAccountBRId = new List<Id>();
        Set<Id> setContactId = new Set<Id>();
        Map<Id, Contact> mapContactsDetails = new Map<Id, Contact>();
        Set<Id> setActiveContactId = new Set<Id>();

        for(Request__c saReq : lstSAR){
            if(saReq.Broker__c != null && saReq.BrokerStatus__c != '1'){
                lstAllAccountBRId.add(saReq.Broker__c);
            }
            else{
                lstAllAccountBRId.add(saReq.Reinsurer__c);
            }
        }

        for(AccountContactRelation accContactRelation : [SELECT Id, AccountId, Account.RecordTypeId, Contact.Account.RecordTypeId, Roles, ContactId, Contact.MacroLoB__c, Contact.Nature__c  FROM AccountContactRelation
                                                        WHERE AccountId IN :lstAllAccountBRId
                                                        AND IsActive = TRUE
                                                        AND Contact.MacroLoB__c != null
                                                        AND Contact.Nature__c != null]){

            if(accContactRelation.Account.RecordTypeId == accContactRelation.Contact.Account.RecordTypeId){
                setContactId.add(accContactRelation.ContactId);
            }
        }

        if(setContactId.size() > 0){
            for(User user: [SELECT Id, name, ContactId, IsActive FROM User WHERE ContactId IN :setContactId AND IsActive = true]){
                setActiveContactId.add(user.ContactId);
            }
        }

        if(setActiveContactId.size() > 0){
            for(Contact con : [SELECT Id, AccountType__c, AccountId, MacroLoB__c, toLabel(Nature__c), Account.Name,
                                      FirstName, LastName, Email FROM Contact WHERE Id IN :setActiveContactId]){
                mapContactsDetails.put(con.Id, con);
            }

            for(AccountContactRelation accContactRelation : [SELECT Id, AccountId, ContactId, IsDirect, Roles, IsActive, Contact.AccountType__c, Contact.AccountId,
                                                                    Contact.MacroLoB__c, toLabel(Contact.Nature__c), Account.Name,
                                                                    Contact.FirstName, Contact.LastName, Contact.Email
                                                            FROM AccountContactRelation
                                                            WHERE ContactId IN :setActiveContactId
                                                            AND IsActive = TRUE]){

                if(mapContactRel.containsKey(accContactRelation.ContactId)){
                    mapContactRel.get(accContactRelation.ContactId).add(accContactRelation);
                }
                else{
                    mapContactRel.put(accContactRelation.ContactId, new List<AccountContactRelation>{accContactRelation});
                }
            }
        }

        for(Request__c saReq : lstSAR){
            Id accountId;
            Set<AccountContactRelation> setAccConRel = new Set<AccountContactRelation>();
            List<AccountContactRelation> lstAccountContactRelationsToDisplay = new List<AccountContactRelation>();

            if(saReq.Broker__c != null && saReq.BrokerStatus__c != '1'){
                accountId = saReq.Broker__c;
            }
            else{
                accountId = saReq.Reinsurer__c;
            }

            for(Id key : mapContactsDetails.keySet()){
                Contact contactExterne = mapContactsDetails.get(key);
                String[] macroLOBArr = contactExterne.MacroLoB__c.split(';');
                Boolean checksOK = false;
                String macroLOBFromProgram = saReq.Program__r.Macro_L_O_B__c;
                String natureFromProgram = saReq.Program__r.Nature__c;
                String prinCedComFromProgram = saReq.Program__r.PrincipalCedingCompany__c;

                if(macroLOBArr.contains(macroLOBFromProgram)
                        && (contactExterne.Nature__c == natureFromProgram || (contactExterne.Nature__c.contains(natureFromProgram)))){
                    for(AccountContactRelation relation : mapContactRel.get(key)){
                        if(relation.Roles == 'PrincipalCedingCompany'){
                            if(relation.AccountId == prinCedComFromProgram){
                                checksOK = true;
                            }
                        }
                    }
                }

                if(checksOK == true){
                    for(AccountContactRelation relation : mapContactRel.get(key)){
                        if(accountId == relation.AccountId && relation.Contact.Email != null){
                            setAccConRel.add(relation);
                        }
                    }
                }
            }
            lstAccountContactRelationsToDisplay.addAll(setAccConRel);
            mapContactRelBySAR.put(saReq, lstAccountContactRelationsToDisplay);
        }

        return mapContactRelBySAR;
    }

    /**
    * @description Method to retrieve Nace Code in lookup field
    * @param String ObjectName, String fieldName, String value, List<String> selectedRecId
    * @return List<SObjectResult>
    */
    @AuraEnabled(Cacheable=true)
    public static List<SObjectResult> getNaceCode(String ObjectName, String fieldName, String value, List<String> selectedRecId) {
        List<SObjectResult> sObjectResultList = new List<SObjectResult>();
        String type = 'Autofac';

        if(selectedRecId == null) {
            selectedRecId = new List<String>();
        }
        
        if(String.isNotEmpty(value)) {
            String strValue = '%' + String.escapeSingleQuotes(value.trim()) + '%';
            String query = 'Select Id, OriginalInsuredActivity__c, NACECode__c FROM NACECode__c WHERE NACECode__c LIKE :strValue and ID NOT IN :selectedRecId and Type__c = :type';

            // String query = 'Select Id, OriginalInsuredActivity__c,'+fieldName+' FROM '+ObjectName+' WHERE '+fieldName+' LIKE \'%' + value.trim() + '%\' and ID NOT IN: selectedRecId and Type__c = :type';
  
            for(SObject so : Database.query(query)) {
                String fieldvalue = (String)so.get(fieldName);
                String originalInsuredActValue = (String)so.get('OriginalInsuredActivity__c');
                sObjectResultList.add(new SObjectResult(fieldvalue, so.Id, originalInsuredActValue));
            }
        }

        return sObjectResultList;
    }

    public class SObjectResult{
        @AuraEnabled
        public String recName;
        @AuraEnabled
        public Id recId;
        @AuraEnabled
        public String originalIsuredAct;

        public SObjectResult(String recNameTemp, Id recIdTemp, String originalIsuredActTemp) {
            recName = recNameTemp;
            recId = recIdTemp;
            originalIsuredAct = originalIsuredActTemp;
        }
        public SObjectResult() {

        }
    }
}