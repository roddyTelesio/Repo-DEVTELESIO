@IsTest
public with sharing class AP60_UpdateRequestStatus_TEST {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Test class for AP60_UpdateRequestStatus
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 23-NOV-2021  MBE   1.0      Initial version
--------------------------------------------------------------------------------------
**************************************************************************************/
    static User testUserAdmin;
    static User testUserCE;
    static User testUserCedingPortal;
    static User testUserBrokerPortal;
    static User testUserReinsurerPortal;
    static List<User> lstUsers = new List<User>();
    static List<User> lstCedingPortalUser = new List<User>();
    static List<User> lstPortalUser = new List<User>();
    static List<GroupMember> lstGroupMember = new List<GroupMember>();
    static List<Account> lstAccount;
    static List<Contact> lstContact;
    static List<Program__c> lstProgram;
    static List<Pool__c> lstPool;
    static List<PoolTreatySection__c> lstPoolTreatySections;
    static List<CoveredCedingCompany__c> lstCovCedCom;
    static List<SpecialAcceptance__c> lstSpecialAcceptance;
    static List<SpecialAcceptance__c> lstRenewedSpecialAcceptance;
    static List<SpecialAcceptance__c> lstSentToAGRESpecialAcceptance;
    static List<SpecialAcceptance__c> lstSpecialAcceptanceCedingPortal;
    static List<SpecialAcceptance__c> lstGroupCoverSpecialAcceptance;
    static List<Treaty__c> lstTreaty;
    static List<Request__c> lstRequest;
    static List<Section__c> lstSection;
    static String fileContent = 'This is an example.';
    static Blob fileContentInBlob = Blob.valueOf(fileContent);
    static List<ContentVersion> lstContentVersion;
    static List<ContentVersion> lstContentVersionCedingPortal;
    static List<ContentDocumentLink> lstContentDocumentLink;
    static Map<String, Id> mapRecTypeIdRequest = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectRequest});
    static Map<String, Id> mapSARecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectSpecialAcceptance});

    static { 
        //create User
        testUserAdmin = TestFactory.createUserWithRole('testUserAdmin', TestFactory.getProfileAdminId(), TestFactory.getCERoleId());
        testUserCE = TestFactory.createUser('testUserCE', TestFactory.getProfileCEId());
        User assignedToUser = TestFactory.createUserWithRole('TestAssignedTo', TestFactory.getProfileAdminId(),TestFactory.getHeadUGPRoleId());
        lstUsers.add(testUserAdmin);
        lstUsers.add(testUserCE);
        lstUsers.add(assignedToUser);

        lstUsers[0].BypassTrigger__c = 'AP59_DeleteOldAccConRelation';
        lstUsers[1].BypassTrigger__c = 'AP59_DeleteOldAccConRelation';
        lstUsers[2].BypassTrigger__c = 'AP59_DeleteOldAccConRelation';
        insert lstUsers;

        System.runAs(testUserAdmin){
            Map<String, Id> mapAccountRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectAcc});

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
                TestFactory.createAccount(mapAccountRecTypeId.get(AP_Constant.accRTReinsurer),'Reinsurer A','C_0009'),
                TestFactory.createAccount(mapAccountRecTypeId.get(AP_Constant.accRTCoveredCedingCompany),'Account E - Covered Ceding','C_0010')
            };
            insert lstAccount;

            lstAccount[0].EmailSA__c = 'test@test.com;test2@test.com';
            lstAccount[1].EmailSA__c = 'test@test.com;test2@test.com';
            lstAccount[0].EmailPCLife__c = 'test@test.com;test2@test.com';
            lstAccount[1].EmailPCLife__c = 'test@test.com;test2@test.com';
            lstAccount[9].IsPartner = true;//Covered Ceding Acc
            lstAccount[4].IsPartner = true;//Broker Acc
            lstAccount[5].IsPartner = true;//Reinsurer Acc
            update lstAccount;

            //create Ceding Portal Contact
            lstContact = new List<Contact> {
                TestFactory.createContact('AccountE', 'CedingPortal', lstAccount[9].Id, '2', '25009'),
                TestFactory.createContact('Account E - Broker', 'BrokerPortal', lstAccount[4].Id, '2', '25009'),
                TestFactory.createContact('Account F - Reinsurer', 'ReinsurerPortal', lstAccount[5].Id, '2', '25009')
            };

            lstContact[0].Email = 'test@test.com';
            lstContact[1].Email = 'test@test.com';
            lstContact[2].Email = 'test@test.com';
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
                AccountShare accShareCe = new AccountShare();
                accShareCe.UserOrGroupId = testUserCE.Id; 
                accShareCe.AccountId = acc.Id;
                accShareCe.AccountAccessLevel = 'Edit';
                accShareCe.OpportunityAccessLevel = 'Edit';
                lstAccShare.add(accShareCe);
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
                                    , lstAccount[1].Id, '23001', '2', '25001'),

                TestFactory.createProgram('TestProg3', '1', '3', Date.today()
                                    , Date.today().addYears(1), '2', Date.today(), Date.today().addYears(1), '2020'
                                    , lstAccount[1].Id, '23001', '1', '25001')
            };
            insert lstProgram;

            //Create renew program
            List<Program__c> lstRenewedProg = new List<Program__c>();

            lstRenewedProg = new List<Program__c> {
                TestFactory.createProgram('TestProg1Renewed', '1', '1'
                                    , Date.today(), Date.today().addYears(1), '2', Date.today(), Date.today().addYears(1)
                                    , '2021', lstAccount[0].Id, '23002','2'
                                    , '25009'),

                TestFactory.createProgram('TestProg2Renewed', '1', '1'
                                    , Date.today(), Date.today().addYears(1), '2', Date.today(), Date.today().addYears(1)
                                    , '2021', lstAccount[0].Id, '23002','2'
                                    , '25009')
            };

            lstRenewedProg[0].RenewedFromProgram__c = lstProgram[0].Id;
            lstRenewedProg[1].RenewedFromProgram__c = lstProgram[1].Id;
            insert lstRenewedProg;

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

            lstCovCedCom = new List<CoveredCedingCompany__c> {
                TestFactory.createCovCedCom(lstAccount[2].Id, lstProgram[1].Id, true,null
                                            ,false,null,false,null,null),

                TestFactory.createCovCedCom(lstAccount[3].Id, lstProgram[1].Id, true,null
                                            ,false,null,false,null,null),

                TestFactory.createCovCedCom(lstAccount[3].Id, lstProgram[2].Id, true,null
                                            ,false,null,false,null,null),

                TestFactory.createCovCedCom(lstAccount[9].Id, lstProgram[1].Id, true,null
                                            ,false,null,false,null,null),

                TestFactory.createCovCedCom(lstAccount[9].Id, lstProgram[0].Id, true,null
                                            ,false,null,false,null,null),

                TestFactory.createCovCedCom(lstAccount[2].Id, lstProgram[0].Id, true,null
                                            ,false,null,false,null,null)
            };
            insert lstCovCedCom;

            lstSpecialAcceptance = new List<SpecialAcceptance__c> {
                TestFactory.createSpecialAcceptance(mapSARecTypeId.get(AP_Constant.saRTLife), lstProgram[0].Id, lstAccount[0].Id, 'TestSA1'
                , '2020', 'Setup', null, '2020-23-00000000', true, false, '1', null
                , null, '2','20043','Capacity', lstAccount[9].Id),

                TestFactory.createSpecialAcceptance(mapSARecTypeId.get(AP_Constant.saRTPC), lstProgram[1].Id, lstAccount[0].Id, 'TestSA2'
                , '2020', 'Setup', null, '2020-23-00000001', true, false, '1', null
                , null, '2','20043','Capacity', lstAccount[9].Id),

                TestFactory.createSpecialAcceptance(mapSARecTypeId.get(AP_Constant.saRTLife), lstProgram[0].Id, lstAccount[0].Id, 'TestSA3'
                , '2020', 'Setup', null, '2020-23-00000002', true, false, '1', null
                , null, '1','20043','Capacity', lstAccount[9].Id)
            };
            lstSpecialAcceptance[0].Bound__c = '2';
            insert lstSpecialAcceptance;

            lstRenewedSpecialAcceptance = new List<SpecialAcceptance__c> {
                TestFactory.createSpecialAcceptance(mapSARecTypeId.get(AP_Constant.saRTLife), lstProgram[0].Id, lstAccount[0].Id, 'TestSA4'
                , '2020', 'Setup', null, '2019-23-00000001', true, false, '1', lstSpecialAcceptance[0].Id
                , null, '2','20043','Capacity', lstAccount[9].Id),

                TestFactory.createSpecialAcceptance(mapSARecTypeId.get(AP_Constant.saRTPC), lstProgram[1].Id, lstAccount[0].Id, 'TestSA5'
                , '2020', 'Setup', null, '2019-23-00000002', true, false, '1', lstSpecialAcceptance[1].Id
                , null, '2','20043','Capacity', lstAccount[9].Id)
            };
            insert lstRenewedSpecialAcceptance;

            lstSentToAGRESpecialAcceptance = new List<SpecialAcceptance__c> {
                TestFactory.createSpecialAcceptance(mapSARecTypeId.get(AP_Constant.saRTLife), lstProgram[0].Id, lstAccount[0].Id, 'TestSA6'
                , '2020', 'Setup', null, '2020-23-00000003', true, false, '1', null
                , lstSpecialAcceptance[0].Id, '2','20043','Capacity', lstAccount[9].Id),

                TestFactory.createSpecialAcceptance(mapSARecTypeId.get(AP_Constant.saRTPC), lstProgram[1].Id, lstAccount[0].Id, 'TestSA7'
                , '2020', 'Setup', null, '2020-23-00000004', true, false, '1', null
                , lstSpecialAcceptance[0].Id, '2','20043','Capacity', lstAccount[9].Id)
            };
            insert lstSentToAGRESpecialAcceptance;

            lstGroupCoverSpecialAcceptance = new List<SpecialAcceptance__c>{
                TestFactory.createSpecialAcceptance(mapSARecTypeId.get(AP_Constant.saRTPC), lstProgram[2].Id, lstAccount[1].Id, 'TestSA8'
                , '2020', 'Setup', null, '2020-23-00000005', true, false, '1', null
                , null, '2','20043','Capacity', lstAccount[9].Id),

                TestFactory.createSpecialAcceptance(mapSARecTypeId.get(AP_Constant.saRTPC), lstProgram[2].Id, lstAccount[1].Id, 'TestSA9'
                , '2020', 'Setup', null, '2020-23-00000006', true, false, '1', null
                , null, '2','20043','Capacity', lstAccount[9].Id)
            };

            lstGroupCoverSpecialAcceptance[0].TECH_LocalSA__c = lstSpecialAcceptance[0].Id;
            lstGroupCoverSpecialAcceptance[1].TECH_LocalSA__c = lstSentToAGRESpecialAcceptance[0].Id;
            insert lstGroupCoverSpecialAcceptance;

            //create ContentVersion
            lstContentVersion = new List<ContentVersion>{
                TestFactory.createContentVersion(null, null
                                                , null, 'CV1', fileContentInBlob, 'CV1'),
                TestFactory.createContentVersion(null, null
                                                , null, 'CV2', fileContentInBlob, 'CV2'),
                TestFactory.createContentVersion(null, null
                                                , null, 'CV3', fileContentInBlob, 'CV3')
            };

            lstContentVersion[0].SpecialAcceptance__c = lstSpecialAcceptance[0].Id;
            lstContentVersion[1].SpecialAcceptance__c = lstSpecialAcceptance[0].Id;
            lstContentVersion[2].SpecialAcceptance__c = lstSpecialAcceptance[0].Id;
            lstContentVersion[0].Nature__c = 'Public';
            lstContentVersion[1].Nature__c = 'Public';
            lstContentVersion[2].Nature__c = 'Private';
            lstContentVersion[2].IsExternal__c = true;
            insert lstContentVersion;

            List<Id> lstContentVersionId = new List<Id>();

            for(ContentVersion contentVersion : lstContentVersion){
                lstContentVersionId.add(contentVersion.Id);
            }

            lstContentVersion = [SELECT Id, ContentDocumentId, DocumentType__c, GroupType__c, Phase__c, Title, VersionData, VersionNumber, FirstPublishLocationId, Nature__c FROM ContentVersion WHERE Id IN :lstContentVersionId];

            lstContentDocumentLink = new List<ContentDocumentLink>{
                    TestFactory.createContentDocumentLink(lstContentVersion[0].ContentDocumentId, lstSpecialAcceptance[0].Id, 'V'),
                    TestFactory.createContentDocumentLink(lstContentVersion[1].ContentDocumentId, lstSpecialAcceptance[0].Id, 'V'),
                    TestFactory.createContentDocumentLink(lstContentVersion[2].ContentDocumentId, lstSpecialAcceptance[0].Id, 'V')
            };

            lstContentDocumentLink[0].Visibility = 'AllUsers';
            lstContentDocumentLink[1].Visibility = 'AllUsers';
            lstContentDocumentLink[2].Visibility = 'AllUsers';
            insert lstContentDocumentLink;

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
                                            mapRecTypeIdRequest.get(AP_Constant.reqRTSA), '2', 'Sent',null),

                TestFactory.createRequest(lstProgram[0].Id, null, null, null, '2', '1',
                                            mapRecTypeIdRequest.get(AP_Constant.reqRTSA), '2', 'Setup',null),
                
                TestFactory.createRequest(lstProgram[0].Id, null, null, null, '2', '1',
                                            mapRecTypeIdRequest.get(AP_Constant.reqRTSA), '2', 'Sent',null),

                TestFactory.createRequest(lstProgram[0].Id, null, lstAccount[4].Id, lstAccount[5].Id, '2', '1',
                                            mapRecTypeIdRequest.get(AP_Constant.reqRTSA), '2', 'Sent',null),

                TestFactory.createRequest(lstProgram[0].Id, null, null, lstAccount[5].Id, '2', '1',
                                            mapRecTypeIdRequest.get(AP_Constant.reqRTSA), '2', 'Sent',null),
                
                TestFactory.createRequest(lstProgram[0].Id, lstTreaty[0].Id, lstAccount[4].Id, lstAccount[5].Id, '1', '3',
                                            mapRecTypeIdRequest.get(AP_Constant.reqRTSigning), '2', 'Signed',lstSection[0].Id),

                TestFactory.createRequest(lstProgram[0].Id, lstTreaty[0].Id, lstAccount[4].Id, lstAccount[5].Id, '2', '1',
                                        mapRecTypeIdRequest.get(AP_Constant.reqRTSigning), '2', 'Signed',lstSection[0].Id)
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

            lstRequest[5].LastVersionSent__c = true;
            lstRequest[5].LastVersionAnswered__c = true;
            lstRequest[5].Special_Acceptance__c = lstSentToAGRESpecialAcceptance[0].Id;
            lstRequest[5].Pool__c = lstPool[0].Id;
            lstRequest[5].Pool__r = lstPool[0];
            lstRequest[5].Special_Acceptance__r = lstSentToAGRESpecialAcceptance[0];
            lstRequest[5].Special_Acceptance__r.CoveredCedingCompany__r = lstAccount[2];
            lstRequest[5].SA_Request_Status__c = 'Setup';

            lstRequest[6].LastVersionSent__c = true;
            lstRequest[6].LastVersionAnswered__c = true;
            lstRequest[6].Special_Acceptance__c = lstSentToAGRESpecialAcceptance[0].Id;
            lstRequest[6].Pool__c = lstPool[1].Id;
            lstRequest[6].Pool__r = lstPool[1];
            lstRequest[6].Special_Acceptance__r = lstSentToAGRESpecialAcceptance[0];
            lstRequest[6].Special_Acceptance__r.CoveredCedingCompany__r = lstAccount[2];
            lstRequest[6].SA_Request_Status__c = 'Setup';

            lstRequest[7].LastVersionSent__c = true;
            lstRequest[7].LastVersionAnswered__c = true;
            lstRequest[7].Special_Acceptance__c = lstSentToAGRESpecialAcceptance[0].Id;
            lstRequest[7].Special_Acceptance__r = lstSentToAGRESpecialAcceptance[0];
            lstRequest[7].Special_Acceptance__r.CoveredCedingCompany__r = lstAccount[2];
            lstRequest[7].SA_Request_Status__c = 'Setup';

            lstRequest[8].LastVersionSent__c = true;
            lstRequest[8].LastVersionAnswered__c = true;
            lstRequest[8].Special_Acceptance__c = lstSpecialAcceptance[0].Id;
            lstRequest[8].Program__r = lstProgram[0];
            lstRequest[8].Special_Acceptance__r = lstSpecialAcceptance[0];
            lstRequest[8].Special_Acceptance__r.CoveredCedingCompany__r = lstAccount[2];
            lstRequest[8].ExpectedResponseDate__c = Date.today();
            lstRequest[8].BrokerStatus__c = '2';

            lstRequest[9].LastVersionSent__c = true;
            lstRequest[9].LastVersionAnswered__c = true;

            lstRequest[10].LastVersionSent__c = true;
            lstRequest[10].LastVersionAnswered__c = true;
            insert lstRequest;

            lstRequest[4].OriginalRequest__c = lstRequest[2].Id;
            lstRequest[4].Program__r = lstProgram[0];
            lstRequest[4].BrokerStatus__c = '2';
            lstRequest[0].SA_Request_Status__c = 'Timeout';
            lstRequest[1].SA_Request_Status__c = 'Sent';
            lstRequest[2].SA_Request_Status__c = 'Sent';
            lstRequest[3].SA_Request_Status__c = 'Sent';
            lstRequest[4].SA_Request_Status__c = 'Sent';
            lstRequest[5].SA_Request_Status__c = 'Sent';
            lstRequest[6].SA_Request_Status__c = 'Sent';
            lstRequest[7].SA_Request_Status__c = 'Sent';
            update lstRequest;
        }
    }

    @IsTest
    public static void testUpdateSAStatusToTimeout(){
        System.runAs(testUserAdmin) {
            Test.startTest();
                lstRequest[0].SA_Request_Status__c = 'Sent';
                lstRequest[0].ExpectedResponseDate__c = Date.newInstance(2020, 11, 9);
                update lstRequest;
            Test.stopTest();

            List<Request__c> lstRequestSaStatusTimeout = [SELECT Id, SA_Request_Status__c FROM Request__c WHERE Id = :lstRequest[0].Id Limit 1];
            System.assertEquals('Timeout', lstRequestSaStatusTimeout[0].SA_Request_Status__c);
        }
    }

    @IsTest
    public static void testUpdateSAStatusToSent(){
        System.runAs(testUserAdmin) {
            Test.startTest();
                lstRequest[1].SA_Request_Status__c = 'Timeout';
                lstRequest[1].ExpectedResponseDate__c = Date.today() + 1;
                update lstRequest;
            Test.stopTest();

            List<Request__c> lstRequestSaStatusSent = [SELECT Id, SA_Request_Status__c FROM Request__c WHERE Id = :lstRequest[1].Id Limit 1];
            System.assertEquals('Sent', lstRequestSaStatusSent[0].SA_Request_Status__c);
        }
    }

    @IsTest
    public static void testUpdateReinsurerStatusToTimeout(){
        System.runAs(testUserAdmin) {
            Test.startTest();
                lstRequest[9].ReinsurerStatus__c = 'Sent';
                lstRequest[9].ExpectedResponseDate__c = Date.newInstance(2020, 11, 9);
                update lstRequest;
            Test.stopTest();

            List<Request__c> lstRequestReinsurerStatusTimeout = [SELECT Id, ReinsurerStatus__c FROM Request__c WHERE Id = :lstRequest[9].Id Limit 1];
            System.assertEquals('Timeout', lstRequestReinsurerStatusTimeout[0].ReinsurerStatus__c);
        }
    }

    @IsTest
    public static void testUpdateReinsurerStatusToSent(){
        System.runAs(testUserAdmin) {
            Test.startTest();
                lstRequest[10].ReinsurerStatus__c = 'Timeout';
                lstRequest[10].ExpectedResponseDate__c = Date.today() + 1;
                update lstRequest;
            Test.stopTest();

            List<Request__c> lstRequestReinsurerStatusSent = [SELECT Id, ReinsurerStatus__c FROM Request__c WHERE Id = :lstRequest[10].Id Limit 1];
            System.assertEquals('Sent', lstRequestReinsurerStatusSent[0].ReinsurerStatus__c);
        }
    }
}