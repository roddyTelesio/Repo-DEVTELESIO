@IsTest
public with sharing class LWC52_SARespondOnBehalf_TEST {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Test class for LWC52_SARespondOnBehalf
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 25-JAN-2020  MBE   1.0      Initial version
--------------------------------------------------------------------------------------
**************************************************************************************/
    static User testUserAdmin;
    static User testUserCE;
    static User testUserBRPortal;
    static User testUserCedingPortal;
    static User testUserBrokerPortal;
    static User testUserReinsurerPortal;
    static List<User> lstBRPortalUser = new List<User>();
    static List<User> lstPortalUser = new List<User>();
    static List<User> lstUsers = new List<User>();
    static List<GroupMember> lstGroupMember = new List<GroupMember>();
    static List<Account> lstAccount;
    static List<Contact> lstContact;
    static List<Program__c> lstProgram;
    static List<CoveredCedingCompany__c> lstCovCedCom;
    static List<Pool__c> lstPool;
    static List<PoolTreatySection__c> lstPoolTreatySections;
    static List<SpecialAcceptance__c> lstSpecialAcceptance;
    static List<SpecialAcceptance__c> lstRenewedSpecialAcceptance;
    static List<SpecialAcceptance__c> lstSentToAGRESpecialAcceptance;
    static List<SpecialAcceptance__c> lstGroupCoverSpecialAcceptance;
    static List<Treaty__c> lstTreaty;
    static List<Request__c> lstRequest;
    static List<Section__c> lstSection;
    static String fileContent = 'This is an example.';
    static Blob fileContentInBlob = Blob.valueOf(fileContent);
    static List<ContentVersion> lstContentVersion;
    static List<ContentDocumentLink> lstContentDocumentLink;
    static List<DocumentVisibility__c> lstDocumentVisibility;
    static Map<String, Id> mapRecTypeIdRequest = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectRequest});
    static Map<String, Id> mapAccountRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectAcc});
    static Map<String, Id> mapSARecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectSpecialAcceptance});

    static { 
        //create User
        testUserAdmin = TestFactory.createUserWithRole('testUserAdmin', TestFactory.getProfileAdminId(), TestFactory.getCERoleId());
        testUserCE = TestFactory.createUser('testUserCE', TestFactory.getProfileCEId());
        User assignedToUser = TestFactory.createUserWithRole('TestAssignedTo', TestFactory.getProfileAdminId(),TestFactory.getHeadUGPRoleId());

        lstUsers.add(testUserAdmin);
        lstUsers.add(testUserCE);
        lstUsers.add(assignedToUser);

        lstUsers[0].BypassTrigger__c = 'AP44_CreateSharingForUser;AP59_DeleteOldAccConRelation';
        lstUsers[1].BypassTrigger__c = 'AP44_CreateSharingForUser;AP59_DeleteOldAccConRelation';
        lstUsers[2].BypassTrigger__c = 'AP44_CreateSharingForUser;AP59_DeleteOldAccConRelation';
        insert lstUsers;

        System.runAs(testUserAdmin){
            Map<String, Id> mapRequestRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectRequest});

            //create Account
            lstAccount = new List<Account> {
                TestFactory.createAccount(mapAccountRecTypeId.get(AP_Constant.accRTPrincipalCedingCom),'Account A','C_0001'),
                TestFactory.createAccount(mapAccountRecTypeId.get(AP_Constant.accRTPrincipalCedingCom),'Account B','C_0002'),
                TestFactory.createAccount(mapAccountRecTypeId.get(AP_Constant.accRTCoveredCedingCompany),'Account C','C_0003'),
                TestFactory.createAccount(mapAccountRecTypeId.get(AP_Constant.accRTCoveredCedingCompany),'Account D','C_0004'),
                TestFactory.createAccount(mapAccountRecTypeId.get(AP_Constant.accRTBroker),'Account E','C_0005'),
                TestFactory.createAccount(mapAccountRecTypeId.get(AP_Constant.accRTReinsurer),'Account F','C_0006'),
                TestFactory.createAccount(mapAccountRecTypeId.get(AP_Constant.accRTBroker),'Broker A','C_0007'),
                TestFactory.createAccount(mapAccountRecTypeId.get(AP_Constant.accRTBroker),'Broker B','C_0008'),
                TestFactory.createAccount(mapAccountRecTypeId.get(AP_Constant.accRTReinsurer),'Reinsurer A','C_0009')
            };
            insert lstAccount;

            lstAccount[0].EmailSA__c = 'test@test.com;test2@test.com';
            lstAccount[1].EmailSA__c = 'test@test.com;test2@test.com';
            lstAccount[2].EmailSA__c = 'test@test.com;test2@test.com';
            lstAccount[0].EmailPCLife__c = 'test@test.com;test2@test.com';
            lstAccount[1].EmailPCLife__c = 'test@test.com;test2@test.com';
            lstAccount[2].EmailPCLife__c = 'test@test.com;test2@test.com';
            lstAccount[2].IsPartner = true;
            lstAccount[4].IsPartner = true;
            lstAccount[5].IsPartner = true;
            update lstAccount;

            //create Ceding Portal Contact + Broker/Reinsurer Contact
            lstContact = new List<Contact> {
                TestFactory.createContact('AccountE', 'CedingPortal', lstAccount[6].Id, '2', '25009'),
                TestFactory.createContact('Account E - Broker', 'BrokerPortal', lstAccount[4].Id, '2', '25009'),
                TestFactory.createContact('Account F - Reinsurer', 'ReinsurerPortal', lstAccount[5].Id, '2', '25009')
            };

            lstContact[0].Email = 'test@test.com';
            lstContact[0].BrokerReinsurer__c = 'Broker';
            lstContact[1].Email = 'test@test.com';
            lstContact[1].BrokerReinsurer__c = 'Broker';
            lstContact[2].Email = 'test@test.com';
            lstContact[2].BrokerReinsurer__c= 'Reinsurer';
            insert lstContact;

            List<AccountContactRelation> lstAccConToInsert = new List<AccountContactRelation>();

            for(Contact con : lstContact){
                AccountContactRelation accCon = new AccountContactRelation();
                accCon.ContactId = con.Id;
                accCon.AccountId = lstAccount[0].Id;
                accCon.Roles = 'PrincipalCedingCompany';
                accCon.IsActive = true;
                lstAccConToInsert.add(accCon);
            }

            if(lstAccConToInsert.size() > 0){
                insert lstAccConToInsert;
            }

            List<AccountContactRelation> lstAccCon = [SELECT Id, AccountId, Account.RecordTypeId
                                                            , Contact.Account.RecordTypeId, Roles
                                                            , ContactId, Contact.MacroLoB__c
                                                            , Contact.Nature__c, IsDirect
                                                      FROM AccountContactRelation];

            for(AccountContactRelation accCon : lstAccCon){
                accCon.IsActive = true;

                if(accCon.AccountId == lstAccount[4].Id){
                    accCon.Roles = 'Broker';
                }
                else if(accCon.AccountId == lstAccount[5].Id){
                    accCon.Roles = 'RiskCarrier';
                }
                else if(accCon.AccountId == lstAccount[0].Id){
                    accCon.Roles = 'PrincipalCedingCompany';
                }
            }
            update lstAccCon;

            List<AccountShare> lstAccShare = new List<AccountShare>();

            //Create Account Share for CE User - testUserCE
            for(Account acc : lstAccount){
                AccountShare accShare = new AccountShare();
                accShare.UserOrGroupId = testUserCE.Id; 
                accShare.AccountId = acc.Id;
                accShare.AccountAccessLevel = 'Edit';
                accShare.OpportunityAccessLevel = 'Edit';
                lstAccShare.add(accShare);
            }

            if(lstAccShare.size() > 0){
                insert lstAccShare;
            }
        }

        System.runAs(testUserCE){
            //create Pool
            lstPool = new List<Pool__c>{
                TestFactory.createPool('Pool A', 78, '2020', lstUsers[2].Id),
                TestFactory.createPool('Pool B', 78, '2020', lstUsers[2].Id)
            };

            lstPool[0].SA_Email__c = 'test@test.com';
            lstPool[1].SA_Email__c = 'test@test.com';
            insert lstPool;

            //create Program
            lstProgram = new List<Program__c> {
                TestFactory.createProgram('TestProg1', '1', '1'
                                    , Date.today(), Date.today().addYears(1), '2', Date.today(), Date.today().addYears(1)
                                    , '2020', lstAccount[0].Id, '23002','2'
                                    , '25009'),

                TestFactory.createProgram('TestProg2', '2', '2', Date.today()
                                    , Date.today().addYears(1), '1', Date.today(), Date.today().addYears(1), '2020'
                                    , lstAccount[0].Id, '23001', '2', '25001'),

                TestFactory.createProgram('TestProg3', '1', '3', Date.today()
                                    , Date.today().addYears(1), '2', Date.today(), Date.today().addYears(1), '2020'
                                    , lstAccount[1].Id, '23001', '1', '25001')
            };
            insert lstProgram;

            lstCovCedCom = new List<CoveredCedingCompany__c> {
                TestFactory.createCovCedCom(lstAccount[3].Id, lstProgram[0].Id, true,null
                                            ,false,null,false,null,null),

                TestFactory.createCovCedCom(lstAccount[3].Id, lstProgram[1].Id, true,null
                                            ,false,null,false,null,null),

                TestFactory.createCovCedCom(lstAccount[3].Id, lstProgram[2].Id, true,null
                                            ,false,null,false,null,null),

                TestFactory.createCovCedCom(lstAccount[2].Id, lstProgram[0].Id, true,null
                                            ,false,null,false,null,null),

                TestFactory.createCovCedCom(lstAccount[2].Id, lstProgram[2].Id, true,null
                                            ,false,null,false,null,null),

                TestFactory.createCovCedCom(lstAccount[2].Id, lstProgram[2].Id, true,null
                                            ,false,null,false,null,null)

            };
            insert lstCovCedCom;

            //create Treaty
            lstTreaty = new List<Treaty__c> {
                TestFactory.createTreaty('TestTreaty1', 1, 'ref01', '3'
                                        , lstProgram[0].Id, '2', 34, '10', '2020-00000222', '1', '2', '2', '2', '2'),
 
                TestFactory.createTreaty('TestTreaty2', 2, 'ref02', '2', lstProgram[0].Id
                                        , '1', 44, '44', '2020-00000222', '2', '2', '2', '2', '2'),
 
                TestFactory.createTreaty('TestTreaty3', 3, 'ref03', '2'
                                        , lstProgram[1].Id, '2', 89, '44', '2020-00000222', '3', '2', '2', '2', '2'),
 
                TestFactory.createTreaty('TestTreaty4', 3, 'ref03', '3'
                                        , lstProgram[2].Id, '2', 89, '10', '2020-00000222', '1', '2', '2', '2', '2')
            };
            insert lstTreaty;

            //create Section
            lstSection = new List<Section__c> {
                TestFactory.createSection('TestSection1', '1.1', '22003', '20006', '9052'
                                        , 322, 34, lstProgram[0].Id, lstTreaty[0].Id, '3', '1'
                                        , true, '5', null, '23001', '1', '5', '2', '2'),
 
                TestFactory.createSection('TestSection2', '2.1', '22003', '20006', '9052'
                                        , 23, 5, lstProgram[0].Id, lstTreaty[0].Id, '3', '1'
                                        , false, '5', null, '23001', '1', '5', '2', '2'),
 
                TestFactory.createSection('TestSection3', '3.1', '22003', '20006', '9052'
                                        , 76, 43, lstProgram[0].Id, lstTreaty[1].Id, '1', '1'
                                        , true, '1',null, '23001', '1', '5', '2', '2'),
 
                TestFactory.createSection('TestSection4', '4.1', '22003', '20006', '9052'
                                        , 55, 87, lstProgram[1].Id, lstTreaty[3].Id, '1', '1'
                                        , true, '1',null, '23001', '1', '5', '2', '2'),
 
                TestFactory.createSection('TestSection5', '4.1', '22003', '20006', '9052'
                                        , 55, 87, lstProgram[2].Id, lstTreaty[3].Id, '3', '1'
                                        , true, '5',null, '23001', '1', '5', '2', '2')
            };
            insert lstSection;

            //create Pool Treaty Section
            lstPoolTreatySections = new List<PoolTreatySection__c> {
               TestFactory.createPoolTreatySection(lstPool[0].Id, lstTreaty[1].Id, null
                                                   , false, true, 32, null),

               TestFactory.createPoolTreatySection(lstPool[1].Id, lstTreaty[0].Id, null
                                                   , false, true, 40, null)
            };
            insert lstPoolTreatySections;

            lstSpecialAcceptance = new List<SpecialAcceptance__c> {
                TestFactory.createSpecialAcceptance(mapSARecTypeId.get(AP_Constant.saRTLife), lstProgram[0].Id, lstAccount[0].Id, 'TestSA1'
                , '2020', 'Setup', null, '2020-23-00000000', true, false, '1', null
                , null, '1','20043','Capacity', lstAccount[2].Id),

                TestFactory.createSpecialAcceptance(mapSARecTypeId.get(AP_Constant.saRTPC), lstProgram[1].Id, lstAccount[1].Id, 'TestSA1'
                , '2020', 'Setup', null, '2020-23-00000001', true, false, '1', null
                , null, '2','20043','Capacity', lstAccount[2].Id),

                TestFactory.createSpecialAcceptance(mapSARecTypeId.get(AP_Constant.saRTLife), lstProgram[0].Id, lstAccount[0].Id, 'TestSA1'
                , '2020', 'Setup', null, '2020-23-00000002', true, false, '1', null
                , null, '1','20043','Capacity', lstAccount[2].Id)
            };
            insert lstSpecialAcceptance;

            lstSpecialAcceptance[0].SentAgreFromSpecialAcceptance__c = lstSpecialAcceptance[1].Id;
            lstSpecialAcceptance[0].Active__c = 'Active';
            lstSpecialAcceptance[1].Active__c = 'Active';
            lstSpecialAcceptance[2].Active__c = 'Active';
            update lstSpecialAcceptance;

            lstRenewedSpecialAcceptance = new List<SpecialAcceptance__c> {
                TestFactory.createSpecialAcceptance(mapSARecTypeId.get(AP_Constant.saRTLife), lstProgram[0].Id, lstAccount[0].Id, 'TestSA1'
                , '2020', 'Setup', null, '2021-23-00000001', true, false, '1', lstSpecialAcceptance[0].Id
                , null, '2','20043','Capacity', lstAccount[2].Id),

                TestFactory.createSpecialAcceptance(mapSARecTypeId.get(AP_Constant.saRTPC), lstProgram[1].Id, lstAccount[0].Id, 'TestSA1'
                , '2020', 'Setup', null, '2021-23-00000002', true, false, '1', lstSpecialAcceptance[1].Id
                , null, '2','20043','Capacity', lstAccount[2].Id)
            };

            lstRenewedSpecialAcceptance[0].Active__c = 'Active';
            lstRenewedSpecialAcceptance[1].Active__c = 'Active';
            insert lstRenewedSpecialAcceptance;

            lstSentToAGRESpecialAcceptance = new List<SpecialAcceptance__c> {
                TestFactory.createSpecialAcceptance(mapSARecTypeId.get(AP_Constant.saRTLife), lstProgram[0].Id, lstAccount[0].Id, 'TestSA1'
                , '2020', 'Setup', null, '2020-23-00000003', true, false, '1', null
                , lstSpecialAcceptance[0].Id, '2','20043','Capacity', lstAccount[2].Id),

                TestFactory.createSpecialAcceptance(mapSARecTypeId.get(AP_Constant.saRTPC), lstProgram[1].Id, lstAccount[0].Id, 'TestSA1'
                , '2020', 'Setup', null, '2020-23-00000004', true, false, '1', null
                , lstSpecialAcceptance[0].Id, '2','20043','Capacity', lstAccount[2].Id)
            };

            lstSentToAGRESpecialAcceptance[0].Active__c = 'Active';
            lstSentToAGRESpecialAcceptance[1].Active__c = 'Active';
            insert lstSentToAGRESpecialAcceptance;

            lstGroupCoverSpecialAcceptance = new List<SpecialAcceptance__c>{
                TestFactory.createSpecialAcceptance(mapSARecTypeId.get(AP_Constant.saRTPC), lstProgram[2].Id, lstAccount[1].Id, 'TestSA1'
                , '2020', 'Setup', null, '2020-23-00000005-1', true, false, '1', null
                , null, '2','20043','Capacity', lstAccount[2].Id),

                TestFactory.createSpecialAcceptance(mapSARecTypeId.get(AP_Constant.saRTPC), lstProgram[2].Id, lstAccount[1].Id, 'TestSA1'
                , '2020', 'Setup', null, '2020-23-00000006-1', true, false, '1', null
                , null, '2','20043','Capacity', lstAccount[2].Id)
            };

            lstGroupCoverSpecialAcceptance[0].TECH_LocalSA__c = lstSpecialAcceptance[0].Id;
            lstGroupCoverSpecialAcceptance[1].TECH_LocalSA__c = lstSentToAGRESpecialAcceptance[0].Id;
            lstGroupCoverSpecialAcceptance[0].Active__c = 'Active';
            lstGroupCoverSpecialAcceptance[1].Active__c = 'Active';
            insert lstGroupCoverSpecialAcceptance;

            //create ContentVersion
            lstContentVersion = new List<ContentVersion>{
                TestFactory.createContentVersion(null,null
                                                , null, 'CV1', fileContentInBlob, 'CV1'),
                TestFactory.createContentVersion(null,null
                                                , null, 'CV2', fileContentInBlob, 'CV2'),
                TestFactory.createContentVersion(null, null
                                                , null, 'CV3', fileContentInBlob, 'CV3'),
                TestFactory.createContentVersion(null, null
                                                , null, 'CV4', fileContentInBlob, 'CV4')
            };

            lstContentVersion[0].IsExternal__c = false;
            lstContentVersion[1].IsExternal__c = true;
            lstContentVersion[2].IsExternal__c = true;
            lstContentVersion[3].IsExternal__c = true;

            lstContentVersion[0].Nature__c = 'Public';
            insert lstContentVersion;

            List<Id> lstContentVersionId = new List<Id>();

            for(ContentVersion contentVersion : lstContentVersion){
                lstContentVersionId.add(contentVersion.Id);
            }

            lstContentVersion = [SELECT Id, ContentDocumentId, DocumentType__c, GroupType__c, Phase__c, Title, VersionData, VersionNumber, Nature__c FROM ContentVersion WHERE Id IN :lstContentVersionId];

            lstContentDocumentLink = new List<ContentDocumentLink>{
                    TestFactory.createContentDocumentLink(lstContentVersion[0].ContentDocumentId, lstSpecialAcceptance[0].Id, 'V'),
                    TestFactory.createContentDocumentLink(lstContentVersion[1].ContentDocumentId, lstSpecialAcceptance[0].Id, 'V'),
                    TestFactory.createContentDocumentLink(lstContentVersion[2].ContentDocumentId, lstSpecialAcceptance[0].Id, 'V'),
                    TestFactory.createContentDocumentLink(lstContentVersion[3].ContentDocumentId, lstSpecialAcceptance[0].Id, 'V')
            };

            lstContentDocumentLink[0].Visibility = 'AllUsers';
            lstContentDocumentLink[1].Visibility = 'AllUsers';
            lstContentDocumentLink[2].Visibility = 'AllUsers';
            lstContentDocumentLink[3].Visibility = 'AllUsers';
            insert lstContentDocumentLink;

            lstDocumentVisibility = new List<DocumentVisibility__c>{
                TestFactory.createDocumentVisibility(lstAccount[4].Id, lstAccount[5].Id,lstContentVersion[0].Id, lstProgram[0].Id)
            };

            lstDocumentVisibility[0].SpecialAcceptance__c = lstSpecialAcceptance[0].Id;
            insert lstDocumentVisibility;

           //create Request
            lstRequest = new List<Request__c>{
                // recordTypeId + status required
                TestFactory.createRequest(lstProgram[0].Id, lstTreaty[0].Id, lstAccount[4].Id, lstAccount[5].Id, '1', '3',
                                            mapRecTypeIdRequest.get(AP_Constant.reqRTSA), '2', 'Setup',lstSection[0].Id),

                TestFactory.createRequest(lstProgram[0].Id, lstTreaty[0].Id, lstAccount[4].Id, lstAccount[5].Id, '2', '1',
                                            mapRecTypeIdRequest.get(AP_Constant.reqRTSA), '2', 'Setup',lstSection[0].Id),
            
                TestFactory.createRequest(lstProgram[0].Id, null, lstAccount[4].Id, lstAccount[5].Id, '2', '1',
                                            mapRecTypeIdRequest.get(AP_Constant.reqRTSA), '2', 'Setup',null),

                TestFactory.createRequest(lstProgram[0].Id, null, null, null, '2', '1',
                                            mapRecTypeIdRequest.get(AP_Constant.reqRTSA), '2', 'Setup',null),
                
                TestFactory.createRequest(lstProgram[0].Id, null, lstAccount[4].Id, lstAccount[5].Id, '2', '1',
                                            mapRecTypeIdRequest.get(AP_Constant.reqRTSA), '2', 'Sent',null)
            };
            lstRequest[0].LastVersionSent__c = true;
            lstRequest[0].LastVersionAnswered__c = true;
            lstRequest[0].Program__r = lstProgram[0];
            lstRequest[0].Special_Acceptance__c = lstSpecialAcceptance[0].Id;
            lstRequest[0].Program__r = lstProgram[0];
            lstRequest[0].Special_Acceptance__r = lstSpecialAcceptance[0];
            lstRequest[0].Special_Acceptance__r.CoveredCedingCompany__r = lstAccount[2];
            lstRequest[0].ExpectedResponseDate__c = Date.today();
            lstRequest[0].BrokerStatus__c = '2';

            lstRequest[1].LastVersionSent__c = true;
            lstRequest[1].LastVersionAnswered__c = true;
            lstRequest[1].Program__r = lstProgram[0];
            lstRequest[1].Special_Acceptance__r = lstSpecialAcceptance[1];
            lstRequest[1].Special_Acceptance__r.CoveredCedingCompany__r = lstAccount[2];
            lstRequest[1].ExpectedResponseDate__c = Date.today();
            lstRequest[1].Pool__c = lstPool[0].Id;
            lstRequest[1].Pool__r = lstPool[0];

            lstRequest[2].LastVersionSent__c = true;
            lstRequest[2].LastVersionAnswered__c = true;
            lstRequest[2].Special_Acceptance__c = lstSpecialAcceptance[0].Id;
            lstRequest[2].Program__r = lstProgram[0];
            lstRequest[2].Special_Acceptance__r = lstSpecialAcceptance[0];
            lstRequest[2].Special_Acceptance__r.CoveredCedingCompany__r = lstAccount[2];
            lstRequest[2].ExpectedResponseDate__c = Date.today();
            lstRequest[2].BrokerStatus__c = '2';
            lstRequest[2].CommentsResponse__c = 'Testing Comment';

            lstRequest[3].LastVersionSent__c = true;
            lstRequest[3].LastVersionAnswered__c = true;
            lstRequest[3].Special_Acceptance__c = lstSpecialAcceptance[0].Id;
            lstRequest[3].Pool__c = lstPool[0].Id;
            lstRequest[3].Pool__r = lstPool[0];
            lstRequest[3].Program__r = lstProgram[0];
            lstRequest[3].Special_Acceptance__r = lstSpecialAcceptance[0];
            lstRequest[3].Special_Acceptance__r.CoveredCedingCompany__r = lstAccount[2];
            lstRequest[3].ExpectedResponseDate__c = Date.today();
            lstRequest[3].Comments__c = 'Testing Comment';
            lstRequest[3].CommentsResponse__c = 'Testing Comment';

            lstRequest[4].LastVersionSent__c = true;
            lstRequest[4].LastVersionAnswered__c = true;
            lstRequest[4].Special_Acceptance__c = lstSpecialAcceptance[0].Id;
            lstRequest[4].Program__r = lstProgram[0];
            lstRequest[4].Special_Acceptance__r = lstSpecialAcceptance[0];
            lstRequest[4].Special_Acceptance__r.CoveredCedingCompany__r = lstAccount[2];
            lstRequest[4].ExpectedResponseDate__c = Date.today();
            lstRequest[4].Comments__c = 'Testing Comment';
            lstRequest[4].CommentsResponse__c = 'Testing Comment';
            insert lstRequest;

            lstRequest[4].OriginalRequest__c = lstRequest[2].Id;
            lstRequest[4].Program__r = lstProgram[0];
            lstRequest[4].BrokerStatus__c = '2';
            lstRequest[0].SA_Request_Status__c = 'Sent';
            lstRequest[1].SA_Request_Status__c = 'Sent';
            lstRequest[2].SA_Request_Status__c = 'Sent';
            lstRequest[3].SA_Request_Status__c = 'Sent';
            lstRequest[4].SA_Request_Status__c = 'Sent';
            update lstRequest;

            List<Request__Share> lstRequestShare = new List<Request__Share>();

            for(Request__c req : lstRequest){
                Request__Share requestShareAdmin = new Request__Share();
                requestShareAdmin.RowCause = 'Manual';
                requestShareAdmin.AccessLevel = 'Edit';
                requestShareAdmin.ParentId = req.Id;
                requestShareAdmin.UserOrGroupId = testUserAdmin.Id;
                lstRequestShare.add(requestShareAdmin);
            }

            if(lstRequestShare.size() > 0){
                insert lstRequestShare;
            }
        }

        System.runAs(testUserAdmin){
            lstPortalUser = new List<User>{
                TestFactory.createUser('testUserCedingPortal', TestFactory.getProfileInternalId()),
                TestFactory.createUser('testUserBrokerPortal', TestFactory.getProfileExternalId()),
                TestFactory.createUser('testUserReinsurerPortal', TestFactory.getProfileExternalId())
            };

            lstPortalUser[0].ContactId = lstContact[0].Id;
            lstPortalUser[1].ContactId = lstContact[1].Id;
            lstPortalUser[2].ContactId = lstContact[2].Id;
            lstPortalUser[0].BypassTrigger__c='AP44_CreateSharingForUser;AP59_DeleteOldAccConRelation';
            lstPortalUser[1].BypassTrigger__c='AP44_CreateSharingForUser;AP59_DeleteOldAccConRelation';
            lstPortalUser[2].BypassTrigger__c='AP44_CreateSharingForUser;AP59_DeleteOldAccConRelation';
            insert lstPortalUser;

            testUserCedingPortal = lstPortalUser[0];
            testUserBrokerPortal = lstPortalUser[1];
            testUserReinsurerPortal = lstPortalUser[2];

            List<Request__Share> lstRequestShare = new List<Request__Share>();
            List<AccountShare> lstAccShare = new List<AccountShare>();
            List<SpecialAcceptance__Share> lstSAShare = new List<SpecialAcceptance__Share>();

            for(User user : lstPortalUser){ 
                AccountShare accShare = new AccountShare();
                accShare.UserOrGroupId = user.Id; 
                accShare.AccountId = lstAccount[0].Id;
                accShare.AccountAccessLevel = 'Edit';
                accShare.OpportunityAccessLevel = 'Edit';
                lstAccShare.add(accShare);
            }

            if(lstAccShare.size() > 0){
                insert lstAccShare;
            }

            for(Request__c req : lstRequest){
                for(User user : lstPortalUser){
                    Request__Share requestShare = new Request__Share();
                    requestShare.RowCause = 'Manual';
                    requestShare.AccessLevel = 'Edit';
                    requestShare.ParentId = req.Id;
                    requestShare.UserOrGroupId = user.Id;
                    lstRequestShare.add(requestShare); 

                    if(req.Special_Acceptance__c != null){
                        SpecialAcceptance__Share saShare = new SpecialAcceptance__Share();
                        saShare.RowCause = 'Manual';
                        saShare.AccessLevel = 'Edit';
                        saShare.ParentId = req.Special_Acceptance__c;
                        saShare.UserOrGroupId = user.Id;
                        lstSAShare.add(saShare);      
                    }            
                }
            }

            if(lstRequestShare.size() > 0){
                insert lstRequestShare;
            }

            if(lstSAShare.size() > 0){
                insert lstSAShare;
            }   

            Set<String> setReferentialId = new Set<String>();
            Map<String, Group> mapGroupByReferentialId = new Map<String, Group>();

            for(Account acc : lstAccount){
                setReferentialId.add(acc.TECH_ReferentialId__c);
            }
            
            List<Group> lstGroup = [SELECT Id, DeveloperName FROM Group WHERE DeveloperName IN :setReferentialId];
            
            for(Group gp : lstGroup){
                mapGroupByReferentialId.put(gp.DeveloperName, gp);
            }

            for(Account acc : lstAccount){
                for(User user: lstPortalUser){
                    if(mapGroupByReferentialId.containsKey(acc.TECH_ReferentialId__c)){
                        GroupMember groupMember = new GroupMember();
                        groupMember.GroupId = mapGroupByReferentialId.get(acc.TECH_ReferentialId__c).Id;
                        groupMember.UserOrGroupId = user.Id;
                        lstGroupMember.add(groupMember);
                    } 
                }
            }

            if(lstGroupMember.size() > 0){
                insert lstGroupMember;
            }
        }
    }

    @IsTest
    public static void testGetRequestDetails(){
        System.runAs(testUserCE) {
            Test.startTest();
                Map<String, Object> mapResultBrokRein = LWC52_SARespondOnBehalf.getRequestDetails(lstSpecialAcceptance[0].Id, lstAccount[4].Id, lstAccount[5].Id, 'null', lstRequest[2].Id, false);
                Map<String, Object> mapResultPool = LWC52_SARespondOnBehalf.getRequestDetails(lstSpecialAcceptance[0].Id, 'null', 'null', 'null', lstRequest[2].Id, false);//to create pool
            Test.stopTest();
            //System.assertEquals('Success', mapResultBrokRein.get('Success'));
            //System.assertEquals(null, mapResultBrokRein.get('Error'));
            Program__c programBrokerRein = (Program__c) mapResultBrokRein.get('program');
            //System.assertNotEquals(null, programBrokerRein);
            List<Request__c> lstRequestBrokRein = (List<Request__c>) mapResultBrokRein.get('lstSaRequest');
            //System.assertEquals(1, lstRequestBrokRein.size());

            //System.assertEquals('Success', mapResultPool.get('Success'));
            //System.assertEquals(null, mapResultPool.get('Error'));
            List<Request__c> lstRequestPool = (List<Request__c>) mapResultPool.get('lstSaRequest');
            //System.assertEquals(1, lstRequestPool.size());
        }
    }

    @IsTest
    public static void testGetRequestDetailsBRPortal(){
        System.runAs(testUserBrokerPortal) {
            Test.startTest();
                Map<String, Object> mapResultBrokRein = LWC52_SARespondOnBehalf.getRequestDetails(lstSpecialAcceptance[0].Id, lstAccount[4].Id, lstAccount[5].Id, 'null', lstRequest[2].Id, true);
            Test.stopTest();
            //System.assertEquals('Success', mapResultBrokRein.get('Success'));
            //System.assertEquals(null, mapResultBrokRein.get('Error'));

            Program__c programBrokerRein = (Program__c) mapResultBrokRein.get('program');
            //System.assertEquals('TestProg1', programBrokerRein.Name);
            List<Request__c> lstRequestBrokRein = (List<Request__c>) mapResultBrokRein.get('lstSaRequest');
            //System.assertEquals(1, lstRequestBrokRein.size());
        }
    }

    @IsTest
    public static void testSendRespondOnBehalfCe(){
        System.runAs(testUserCE) {
            Test.startTest();
                List<String> lstReqId = new List<String>();
                List<ContentVersion> lstContentVersionToUpdate = new List<ContentVersion>();
                List<Id> lstContentVersionToDelete = new List<Id>();

                for(Request__c req : lstRequest){
                    if(req.RecordTypeId == mapRecTypeIdRequest.get(AP_Constant.reqRTSA)){
                        lstReqId.add(req.Id);
                    }
                }

                Map<String, Object> mapResultAgree = LWC52_SARespondOnBehalf.sendRespondOnBehalf('Test Comment', 'Agree', lstReqId, false, lstSpecialAcceptance[0].Id, lstContentVersionToUpdate, lstContentVersionToDelete, false, lstAccount[4].Id, lstAccount[5].Id);
                System.assertEquals('Success', mapResultAgree.get('Success'));
                System.assertEquals(null, mapResultAgree.get('Error'));

                for(Request__c reqAgreed : [SELECT Id, SA_Request_Status__c FROM Request__c WHERE Id IN :lstReqId]){
                    System.assertEquals(AP_Constant.statusAgreed, reqAgreed.SA_Request_Status__c);
                }

                Map<String, Object> mapResultRefuse = LWC52_SARespondOnBehalf.sendRespondOnBehalf('Test Comment', 'Refuse', lstReqId, false, lstSpecialAcceptance[0].Id, lstContentVersionToUpdate, lstContentVersionToDelete, false, lstAccount[4].Id, lstAccount[5].Id);
                System.assertEquals('Success', mapResultRefuse.get('Success'));
                System.assertEquals(null, mapResultRefuse.get('Error'));

                for(Request__c reqRefused : [SELECT Id, SA_Request_Status__c FROM Request__c WHERE Id IN :lstReqId]){
                    System.assertEquals(AP_Constant.statusRefused, reqRefused.SA_Request_Status__c);
                }

                Map<String, Object> mapResultNeedMoreInfo = LWC52_SARespondOnBehalf.sendRespondOnBehalf('Test Comment', 'Need more information/Subjectivities', lstReqId, false, lstSpecialAcceptance[0].Id, lstContentVersionToUpdate, lstContentVersionToDelete, false, lstAccount[4].Id, lstAccount[5].Id);
                System.assertEquals('Success', mapResultNeedMoreInfo.get('Success'));
                System.assertEquals(null, mapResultNeedMoreInfo.get('Error'));

                for(Request__c reqNeedMoreInfo : [SELECT Id, SA_Request_Status__c FROM Request__c WHERE Id IN :lstReqId]){
                    System.assertEquals(AP_Constant.statusMoreInfoRequired, reqNeedMoreInfo.SA_Request_Status__c);
                }
            Test.stopTest();        
        }
    }

    @IsTest
    public static void testSendRespondOnBehalfBRPortal(){
        System.runAs(testUserBrokerPortal) {
            Test.startTest();
                List<String> lstReqId = new List<String>();
                List<ContentVersion> lstContentVersionToUpdate = new List<ContentVersion>{lstContentVersion[0]};
                List<Id> lstContentVersionToDelete = new List<Id>{lstContentVersion[3].Id};

                for(Request__c req : lstRequest){
                    if(req.RecordTypeId == mapRecTypeIdRequest.get(AP_Constant.reqRTSA)){
                        lstReqId.add(req.Id);
                    }
                }

                Map<String, Object> mapResultAgree = LWC52_SARespondOnBehalf.sendRespondOnBehalf('Test Comment', 'Agree', lstReqId, true, lstSpecialAcceptance[0].Id, lstContentVersionToUpdate, lstContentVersionToDelete, false, lstAccount[4].Id, lstAccount[5].Id);
                System.assertEquals('Success', mapResultAgree.get('Success'));
                System.assertEquals(null, mapResultAgree.get('Error'));

                Map<String, Object> mapSendMailToCeResultAgree = (Map<String, Object>) mapResultAgree.get('mapSendMailToCeResult');
                System.assertEquals('Success', mapSendMailToCeResultAgree.get('Success'));
                System.assertEquals(null, mapSendMailToCeResultAgree.get('Error'));

                for(Request__c reqAgreed : [SELECT Id, SA_Request_Status__c FROM Request__c WHERE Id IN :lstReqId]){
                    System.assertEquals(AP_Constant.statusAgreed, reqAgreed.SA_Request_Status__c);
                }

                Map<String, Object> mapResultRefuse = LWC52_SARespondOnBehalf.sendRespondOnBehalf('Test Comment', 'Refuse', lstReqId, true, lstSpecialAcceptance[0].Id, lstContentVersionToUpdate, lstContentVersionToDelete, false, lstAccount[4].Id, lstAccount[5].Id);
                System.assertEquals('Success', mapResultRefuse.get('Success'));
                System.assertEquals(null, mapResultRefuse.get('Error'));

                Map<String, Object> mapSendMailToCeResultRefuse = (Map<String, Object>) mapResultRefuse.get('mapSendMailToCeResult');
                System.assertEquals('Success', mapSendMailToCeResultRefuse.get('Success'));
                System.assertEquals(null, mapSendMailToCeResultRefuse.get('Error'));

                for(Request__c reqRefused : [SELECT Id, SA_Request_Status__c FROM Request__c WHERE Id IN :lstReqId]){
                    System.assertEquals(AP_Constant.statusRefused, reqRefused.SA_Request_Status__c);
                }

                Map<String, Object> mapResultNeedMoreInfo = LWC52_SARespondOnBehalf.sendRespondOnBehalf('Test Comment', 'Need more information/Subjectivities', lstReqId, true, lstSpecialAcceptance[0].Id, lstContentVersionToUpdate, lstContentVersionToDelete, false, lstAccount[4].Id, lstAccount[5].Id);
                System.assertEquals('Success', mapResultNeedMoreInfo.get('Success'));
                System.assertEquals(null, mapResultNeedMoreInfo.get('Error'));

                Map<String, Object> mapSendMailToCeResultNeedMoreInfo = (Map<String, Object>) mapResultNeedMoreInfo.get('mapSendMailToCeResult');
                System.assertEquals('Success', mapSendMailToCeResultNeedMoreInfo.get('Success'));
                System.assertEquals(null, mapSendMailToCeResultNeedMoreInfo.get('Error'));

                for(Request__c reqNeedMoreInfo : [SELECT Id, SA_Request_Status__c FROM Request__c WHERE Id IN :lstReqId]){
                    System.assertEquals(AP_Constant.statusMoreInfoRequired, reqNeedMoreInfo.SA_Request_Status__c);
                }
            Test.stopTest();
        }
    }

    @IsTest
    public static void testSaveRespondOnBehalfBRPortal(){
        System.runAs(testUserBrokerPortal) {
            Test.startTest();
                List<String> lstReqId = new List<String>();
                List<ContentVersion> lstContentVersionToUpdate = new List<ContentVersion>{lstContentVersion[0]};
                List<Id> lstContentVersionToDelete = new List<Id>{lstContentVersion[3].Id};

                for(Request__c req : lstRequest){
                    if(req.RecordTypeId == mapRecTypeIdRequest.get(AP_Constant.reqRTSA)){
                        lstReqId.add(req.Id);
                    }
                }

                Map<String, Object> mapResultAgree = LWC52_SARespondOnBehalf.saveRespondOnBehalf('Test Comment', 'Agree', lstReqId, false, lstSpecialAcceptance[0].Id, lstContentVersionToUpdate, lstContentVersionToDelete, lstAccount[4].Id, lstAccount[5].Id);
                System.assertEquals('Success', mapResultAgree.get('Success'));
                System.assertEquals(null, mapResultAgree.get('Error'));

                for(Request__c reqAgreed : [SELECT Id, SA_Request_Status__c FROM Request__c WHERE Id IN :lstReqId]){
                    System.assertEquals(AP_Constant.statusAgreed, reqAgreed.SA_Request_Status__c);
                }

                Map<String, Object> mapResultRefuse = LWC52_SARespondOnBehalf.saveRespondOnBehalf('Test Comment', 'Refuse', lstReqId, false, lstSpecialAcceptance[0].Id, lstContentVersionToUpdate, lstContentVersionToDelete, lstAccount[4].Id, lstAccount[5].Id);
                System.assertEquals('Success', mapResultRefuse.get('Success'));
                System.assertEquals(null, mapResultRefuse.get('Error'));

                for(Request__c reqRefused : [SELECT Id, SA_Request_Status__c FROM Request__c WHERE Id IN :lstReqId]){
                    System.assertEquals(AP_Constant.statusRefused, reqRefused.SA_Request_Status__c);
                }

                Map<String, Object> mapResultNeedMoreInfo = LWC52_SARespondOnBehalf.saveRespondOnBehalf('Test Comment', 'Need more information/Subjectivities', lstReqId, false, lstSpecialAcceptance[0].Id, lstContentVersionToUpdate, lstContentVersionToDelete, lstAccount[4].Id, lstAccount[5].Id);
                System.assertEquals('Success', mapResultNeedMoreInfo.get('Success'));
                System.assertEquals(null, mapResultNeedMoreInfo.get('Error'));

                for(Request__c reqNeedMoreInfo : [SELECT Id, SA_Request_Status__c FROM Request__c WHERE Id IN :lstReqId]){
                    System.assertEquals(AP_Constant.statusMoreInfoRequired, reqNeedMoreInfo.SA_Request_Status__c);
                }
            Test.stopTest(); 
        }
    }

    @IsTest
    public static void testSaveDocuments(){
        System.runAs(testUserCE) {
            Test.startTest();
                List<ContentVersion> lstContentVersionUpd = new List<ContentVersion>();
                ContentVersion cv1 = lstContentVersion[0];
                cv1.Nature__c = 'Public';
                lstContentVersionUpd.add(cv1);

                ContentVersion cv2 = lstContentVersion[1];
                cv2.Nature__c = 'Public';
                lstContentVersionUpd.add(cv2);
                Map<String, Object> mapResult = LWC52_SARespondOnBehalf.saveDocuments(lstContentVersionUpd);

                System.assertEquals('Success', mapResult.get('Success'));
                System.assertEquals(null, mapResult.get('Error'));

                for(ContentVersion cv : [SELECT Id, Nature__c FROM ContentVersion WHERE Id = :lstContentVersionUpd]){
                    System.assertEquals('Public', cv.Nature__c);
                }
            Test.stopTest();
        }
    }
}