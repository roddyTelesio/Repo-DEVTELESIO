@IsTest
public with sharing class LWC48_CopySpecialAcceptance_TEST {
/**************************************************************************************
-- - Author        : Spoon Consulting RRA GITHUB 2
-- - Description   : Test class for LWC48_CopySpecialAcceptance
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 23-NOV-2020  MBE   1.0      Initial version
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
            lstRequest[0].SignedShare__c = 48;
            lstRequest[0].LastVersionSent__c = true;
            lstRequest[0].LastVersionAnswered__c = true;


            lstRequest[1].LastVersionSent__c = true;
            lstRequest[1].LastVersionAnswered__c = true;
            lstRequest[1].Program__r = lstProgram[0];
            lstRequest[1].Special_Acceptance__r = lstSpecialAcceptance[1];
            lstRequest[1].Special_Acceptance__r.CoveredCedingCompany__r = lstAccount[2];
            lstRequest[1].ExpectedResponseDate__c = Date.today();
            lstRequest[1].Pool__c = lstPool[0].Id;
            lstRequest[1].Pool__r = lstPool[0];
            lstRequest[1].SignedShare__c = 49;

            lstRequest[2].LastVersionSent__c = true;
            lstRequest[2].LastVersionAnswered__c = true;
            lstRequest[2].Special_Acceptance__c = lstSpecialAcceptance[0].Id;
            lstRequest[2].Program__r = lstProgram[0];
            lstRequest[2].Special_Acceptance__r = lstSpecialAcceptance[0];
            lstRequest[2].Special_Acceptance__r.CoveredCedingCompany__r = lstAccount[2];
            lstRequest[2].ExpectedResponseDate__c = Date.today();
            lstRequest[2].BrokerStatus__c = '2';
            lstRequest[2].SignedShare__c = 50;

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
            lstRequest[3].SignedShare__c = 51;

            lstRequest[5].LastVersionSent__c = true;
            lstRequest[5].LastVersionAnswered__c = true;
            lstRequest[5].Special_Acceptance__c = lstSentToAGRESpecialAcceptance[0].Id;
            lstRequest[5].Pool__c = lstPool[0].Id;
            lstRequest[5].Pool__r = lstPool[0];
            lstRequest[5].Special_Acceptance__r = lstSentToAGRESpecialAcceptance[0];
            lstRequest[5].Special_Acceptance__r.CoveredCedingCompany__r = lstAccount[2];
            lstRequest[5].SA_Request_Status__c = 'Setup';
            lstRequest[5].SignedShare__c = 52;

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
            lstRequest[9].SignedShare__c = 52;
            lstRequest[9].Program__r = lstProgram[0];

            lstRequest[10].LastVersionSent__c = true;
            lstRequest[10].LastVersionAnswered__c = true;
            lstRequest[10].SignedShare__c = 52;
            lstRequest[10].Program__r = lstProgram[0];
            insert lstRequest;

            lstRequest[4].OriginalRequest__c = lstRequest[2].Id;
            lstRequest[4].Program__r = lstProgram[0];
            lstRequest[4].BrokerStatus__c = '2';
            lstRequest[0].SA_Request_Status__c = 'Sent';
            lstRequest[1].SA_Request_Status__c = 'Sent';
            lstRequest[2].SA_Request_Status__c = 'Sent';
            lstRequest[3].SA_Request_Status__c = 'Sent';
            lstRequest[4].SA_Request_Status__c = 'Sent';
            lstRequest[5].SA_Request_Status__c = 'Sent';
            lstRequest[6].SA_Request_Status__c = 'Sent';
            lstRequest[7].SA_Request_Status__c = 'Sent';
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

            //Create Account Share for CE User - testUserCedingPortal
            for(Account acc : lstAccount){
                AccountShare accShareCeding = new AccountShare();
                accShareCeding.UserOrGroupId = testUserCedingPortal.Id; 
                accShareCeding.AccountId = acc.Id;
                accShareCeding.AccountAccessLevel = 'Edit';
                accShareCeding.OpportunityAccessLevel = 'Edit';
                lstAccShare.add(accShareCeding);
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
   
        System.runAs(testUserCedingPortal){
            lstSpecialAcceptanceCedingPortal = new List<SpecialAcceptance__c> {
                    TestFactory.createSpecialAcceptance(mapSARecTypeId.get(AP_Constant.saRTLife), lstProgram[0].Id, lstAccount[0].Id, 'TestSA10'
                    , '2020', 'Setup', null, '2020-23-00000000', true, false, '1', null
                    , null, '2','20043','Capacity', lstAccount[9].Id),

                    TestFactory.createSpecialAcceptance(mapSARecTypeId.get(AP_Constant.saRTLife), lstProgram[0].Id, lstAccount[0].Id, 'TestSA11'
                    , '2020', 'Setup', null, '2020-23-00000001', true, false, '1', null
                    , null, '2','20043','Capacity', lstAccount[9].Id)
                };

            insert lstSpecialAcceptanceCedingPortal;
        }
    }

    @IsTest
    public static void testGetSADetail(){
        System.runAs(testUserCE) {
            Test.startTest();
                lstSpecialAcceptance[0].Type__c = '2';
                update lstSpecialAcceptance;
                Map<String, Object> mapResults1 = LWC48_CopySpecialAcceptance.getSADetail(lstSpecialAcceptance[0].Id, true, false);
            Test.stopTest();
            System.assertEquals('Success', mapResults1.get('Success')); 
            List<SpecialAcceptance__c> lstSADetail = (List<SpecialAcceptance__c>) mapResults1.get('lstSpecialAcceptance');
            System.assertEquals('2020-23-00000000', lstSADetail[0].Reference__c); 

            List<Request__c> lstSAR = (List<Request__c>) mapResults1.get('lstSARequest');
            System.assertEquals(4, lstSAR.size()); 

            System.assertEquals('AGRE_Actor C.E', mapResults1.get('userProfile'));

            List<ContentVersion> lstContentVersion = (List<ContentVersion>) mapResults1.get('lstContentVersions');
            System.assertEquals(2, lstContentVersion.size());
        }
    }

    @IsTest
    public static void testGetSADetailCedingPortal(){
        System.runAs(testUserCedingPortal) {
            Test.startTest();
                Map<String, Object> mapResults1 = LWC48_CopySpecialAcceptance.getSADetail(lstSpecialAcceptanceCedingPortal[0].Id, false, false);
            Test.stopTest();
            System.assertEquals('Success', mapResults1.get('Success')); 

            List<SpecialAcceptance__c> lstSADetail = (List<SpecialAcceptance__c>) mapResults1.get('lstSpecialAcceptance');
            System.assertEquals('2020-23-00000000', lstSADetail[0].Reference__c); 

            List<Request__c> lstSAR = (List<Request__c>) mapResults1.get('lstSARequest');
            System.assertEquals(0, lstSAR.size()); 

            System.assertEquals('AGRE_Community Internal User', mapResults1.get('userProfile'));

            List<ContentVersion> lstContentVersion = (List<ContentVersion>) mapResults1.get('lstContentVersions');
            System.assertEquals(0, lstContentVersion.size());
        }
    }

    @IsTest
    public static void testGetProgramDetail(){
        System.runAs(testUserCE) {
            Test.startTest();
                Map<String, Object> mapResults1 = LWC48_CopySpecialAcceptance.getProgramDetail(lstProgram[0].Id, true);
            Test.stopTest();
            System.assertEquals('Success', mapResults1.get('Success')); 
            List<Program__c> lstProgram1 = (List<Program__c>) mapResults1.get('lstProgram');
            List<LWC48_CopySpecialAcceptance.OptionWrapper> lstCedingComp1 = (List<LWC48_CopySpecialAcceptance.OptionWrapper>) mapResults1.get('lstCedingComp');
            System.assertEquals('TestProg1', lstProgram1[0].Name);
            System.assertEquals(2, lstCedingComp1.size());
        }
    }

    @IsTest
    public static void testGetProgramDetailCedingCon(){
        System.runAs(testUserCedingPortal) {
            Test.startTest();
                Map<String, Object> mapResults1 = LWC48_CopySpecialAcceptance.getProgramDetail(lstProgram[0].Id, false);
            Test.stopTest();
            System.assertEquals('Success', mapResults1.get('Success')); 
            List<Program__c> lstProgram1 = (List<Program__c>) mapResults1.get('lstProgram');
            List<LWC48_CopySpecialAcceptance.OptionWrapper> lstCedingComp1 = (List<LWC48_CopySpecialAcceptance.OptionWrapper>) mapResults1.get('lstCedingComp');
            System.assertEquals('TestProg1', lstProgram1[0].Name);
            System.assertEquals(2, lstCedingComp1.size());
        }
    }

    @IsTest
    public static void testSaveCopySpecialAcceptanceRecordCE(){
        System.runAs(testUserCE) {
            Test.startTest();
                SpecialAcceptance__c specialAcceptanceRecord = lstSpecialAcceptance[1];
                specialAcceptanceRecord.Id = null;
                Map<String, Object> mapResults1 = LWC48_CopySpecialAcceptance.saveCopySpecialAcceptanceRecord(specialAcceptanceRecord, lstSpecialAcceptance[0].Program__c, true, lstSpecialAcceptance[0].Id, 'Save');
                
                System.assertEquals(null, mapResults1.get('Error')); 
                System.assertEquals('Success', mapResults1.get('Success')); 

                List<SpecialAcceptance__c> lstSA = [SELECT Id, Name FROM SpecialAcceptance__c];

                System.assertEquals(12, lstSA.size());
            Test.stopTest();
            
        }
    }

    @IsTest
    public static void testSaveCopySpecialAcceptanceRecordCedingPortal(){
        System.runAs(testUserCedingPortal) {
            Test.startTest();
                SpecialAcceptance__c specialAcceptanceRecord = lstSpecialAcceptanceCedingPortal[1];
                specialAcceptanceRecord.Id = null;
                Map<String, Object> mapResults1 = LWC48_CopySpecialAcceptance.saveCopySpecialAcceptanceRecord(specialAcceptanceRecord, lstSpecialAcceptanceCedingPortal[0].Program__c, true, lstSpecialAcceptanceCedingPortal[0].Id, 'Submit');

                System.assertEquals(null, mapResults1.get('Error')); 
                System.assertEquals('Success', mapResults1.get('Success'));    

                List<SpecialAcceptance__c> lstSA = [SELECT Id, Name FROM SpecialAcceptance__c];
                System.assertEquals(13, lstSA.size());
            Test.stopTest();        
        } 
    }

    @IsTest
    public static void testLoadPlacementTable(){
        System.runAs(testUserCE) {
            Test.startTest();
                List<Id> lstSAId = new List<Id>{lstSpecialAcceptance[0].Id, lstSpecialAcceptance[2].Id};
                List<Request__c> lstSAR = [SELECT Id, Name FROM Request__c WHERE Special_Acceptance__c IN :lstSAId];
                
                if(lstSAR.size() > 0){
                    delete lstSAR;
                }

                Map<String, Object> mapResultsSubmission = LWC48_CopySpecialAcceptance.loadPlacementTable(lstSpecialAcceptance[0]);
                Map<String, Object> mapResultsDeclaration = LWC48_CopySpecialAcceptance.loadPlacementTable(lstSpecialAcceptance[2]);
            Test.stopTest();

            System.assertEquals('Success', mapResultsSubmission.get('Success')); 
            System.assertEquals('Success', mapResultsDeclaration.get('Success')); 

            // List<Request__c> lstSigningReqSubmission = (List<Request__c>) mapResultsSubmission.get('lstRequest');
            // List<Request__c> lstSigningReqDeclaration = (List<Request__c>) mapResultsSubmission.get('lstRequest');

            // System.assertEquals(2, lstSigningReqSubmission.size());
            // System.assertEquals(2, lstSigningReqDeclaration.size());

            for(Request__c submissionSAR : [SELECT Id, SA_Request_Status__c FROM Request__c WHERE Special_Acceptance__c = :lstSpecialAcceptance[0].Id]){
                System.assertEquals(AP_Constant.statusSetup, submissionSAR.SA_Request_Status__c);
            }

            for(Request__c declarationSAR : [SELECT Id, SA_Request_Status__c, SA_Type__c FROM Request__c WHERE Special_Acceptance__c = :lstSpecialAcceptance[2].Id]){
                if(declarationSAR.SA_Type__c == 'Follower'){
                    System.assertEquals(AP_Constant.statusSetup, declarationSAR.SA_Request_Status__c);
                }
                else{
                    System.assertEquals(AP_Constant.statusAgreed, declarationSAR.SA_Request_Status__c);
                }
            }

        }
    }

    @IsTest
    public static void testLoadPlacementTableSharingSA(){
        System.runAs(testUserCE) {
            Test.startTest();

            lstRequest[2].Special_Acceptance__c =  lstSpecialAcceptance[2].Id;
            lstRequest[3].Special_Acceptance__c =  lstSpecialAcceptance[2].Id;
            lstRequest[4].Special_Acceptance__c =  lstSpecialAcceptance[2].Id;
            lstRequest[5].Special_Acceptance__c =  lstSpecialAcceptance[2].Id;

            lstRequest[2].Special_Acceptance__r.Type__c = '1';
            lstRequest[3].Special_Acceptance__r.Type__c = '1';
            //lstRequest[4].Special_Acceptance__r.Type__c = '1';
            lstRequest[5].Special_Acceptance__r.Type__c = '1';

            lstRequest[2].SA_Request_Status__c = 'Agreed';
            lstRequest[3].SA_Request_Status__c = 'Agreed';
            lstRequest[4].SA_Request_Status__c = 'Agreed';
            lstRequest[5].SA_Request_Status__c = 'Agreed';
            lstRequest[2].RecordTypeId = mapSARecTypeId.get(AP_Constant.reqRTSA);
            update lstRequest;
                List<Id> lstSAId = new List<Id>{lstSpecialAcceptance[0].Id, lstSpecialAcceptance[2].Id};
                List<Request__c> lstSAR = [SELECT Id, Name FROM Request__c WHERE Special_Acceptance__c IN :lstSAId];
                
                if(lstSAR.size() > 0){
                    delete lstSAR;
                }
                Map<String, Object> mapResultsDeclaration = LWC48_CopySpecialAcceptance.loadPlacementTable(lstSpecialAcceptance[2]);
            Test.stopTest();
        }
    }
    
    @IsTest
    public static void testSaveRenewSpecialAcceptanceRecordCE(){
        System.runAs(testUserCE) {
            Test.startTest();
                SpecialAcceptance__c specialAcceptanceRecord = lstSpecialAcceptance[1];
                specialAcceptanceRecord.Id = null;

                List<ContentVersion> lstContentVersionToUpdate = new List<ContentVersion>{lstContentVersion[0], lstContentVersion[1]};
                List<Id> lstDocIdToDelete = new List<Id>{lstContentVersion[2].Id};

                //create ContentVersion
                List<ContentVersion> lstContentVersionToInsert = new List<ContentVersion>{
                    TestFactory.createContentVersion(null, null
                                                    , null, 'CV1', fileContentInBlob, 'CV1')
                };

                lstContentVersionToInsert[0].Nature__c = 'Public';
                insert lstContentVersionToInsert;

                Map<String, Object> mapResults1 = LWC48_CopySpecialAcceptance.saveRenewSpecialAcceptanceRecord(specialAcceptanceRecord, lstProgram[1].Id, lstContentVersionToUpdate, lstDocIdToDelete, lstContentVersionToInsert, 'Save');
                System.assertEquals(null, mapResults1.get('Error')); 
                System.assertEquals('Success', mapResults1.get('Success'));

                List<SpecialAcceptance__c> lstSA = [SELECT Id, Name FROM SpecialAcceptance__c];

                System.assertEquals(12, lstSA.size());
            Test.stopTest();  
        }
    }

    @IsTest
    public static void testSaveRenewSpecialAcceptanceRecordCedingPortal(){
        System.runAs(testUserCedingPortal) {
            Test.startTest();
                SpecialAcceptance__c specialAcceptanceRecord = lstSpecialAcceptance[1];
                specialAcceptanceRecord.Id = null;

                List<ContentVersion> lstContentVersionToUpdate = new List<ContentVersion>{lstContentVersion[0], lstContentVersion[1]};
                List<Id> lstDocIdToDelete = new List<Id>{lstContentVersion[2].Id};

                //create ContentVersion
                List<ContentVersion> lstContentVersionToInsert = new List<ContentVersion>();

                Map<String, Object> mapResults1 = LWC48_CopySpecialAcceptance.saveRenewSpecialAcceptanceRecord(specialAcceptanceRecord, lstProgram[1].Id, lstContentVersionToUpdate, lstDocIdToDelete, lstContentVersionToInsert, 'Submit');

                System.assertEquals(null, mapResults1.get('Error')); 
                System.assertEquals('Success', mapResults1.get('Success'));

                List<SpecialAcceptance__c> lstSA = [SELECT Id, Name FROM SpecialAcceptance__c];

                System.assertEquals(12, lstSA.size());
            Test.stopTest();  
        }
    }

    @IsTest
    public static void testSaveEditSpecialAcceptanceRecordCE(){
        System.runAs(testUserCE) {
            Test.startTest();
                List<Id> lstDocIdToDeleteCe = new List<Id>{lstContentVersion[0].Id};
                List<Id> lstDocIdToDeleteCedingPortal = new List<Id>{lstContentVersion[1].Id};
                List<Request__c> lstSAR = new List<Request__c>{lstRequest[2]};
                Map<String, Object> mapResults1 = LWC48_CopySpecialAcceptance.saveEditSpecialAcceptanceRecord(lstSentToAGRESpecialAcceptance[0], lstContentVersion, lstDocIdToDeleteCe, 'Save', lstSAR, true);

                System.assertEquals(null, mapResults1.get('Error'));
                System.assertEquals('Success', mapResults1.get('Success'));
            Test.stopTest();    
        }
    }

    @IsTest
    public static void testSaveEditSpecialAcceptanceRecordCedingPortal(){
        System.runAs(testUserCedingPortal) {
            Test.startTest();
                List<Id> lstDocIdToDelete = new List<Id>{lstContentVersion[0].Id};
                List<Request__c> lstSAR = new List<Request__c>{lstRequest[2]};
                lstSpecialAcceptance[0].Bound__c = '1';
                Map<String, Object> mapResults1 = LWC48_CopySpecialAcceptance.saveEditSpecialAcceptanceRecord(lstSpecialAcceptance[0], lstContentVersion, lstDocIdToDelete, 'Submit', lstSAR, false);

                System.assertEquals(null, mapResults1.get('Error'));
                System.assertEquals('Success', mapResults1.get('Success'));

                List<SpecialAcceptance__c> lstSA = [SELECT Id, Name FROM SpecialAcceptance__c];

                System.assertEquals(11, lstSA.size());
            Test.stopTest();
        }
    }

    @IsTest
    public static void testGetContentVersionId(){
        System.runAs(testUserCE) {
            Test.startTest();
                List<Id> lstContentDocumentId = new List<Id>();
                lstContentDocumentId.add(lstContentDocumentLink[0].ContentDocumentId);
                List<ContentVersion> lstResults = LWC48_CopySpecialAcceptance.getContentVersionId(lstContentDocumentId);
            Test.stopTest();
            System.assertEquals(1, lstResults.size()); 
            System.assertEquals(lstContentVersion[0].Id, lstResults[0].Id);
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
                Map<String, Object> mapResults = LWC48_CopySpecialAcceptance.saveDocuments(lstContentVersionUpd);
            Test.stopTest();
            System.assertEquals('Success', mapResults.get('Success')); 

            ContentVersion cv = [SELECT Id, Nature__c FROM ContentVersion WHERE Id = :lstContentVersion[0].Id LIMIT 1];
            System.assertEquals('Public', cv.Nature__c);
        }
    }
    
    @IsTest
    public static void testDeletePlacementTable(){
        System.runAs(testUserCE) {
            Test.startTest();
                List<Request__c> lstSARBeforeDelete = [SELECT Id, Name FROM Request__c WHERE Special_Acceptance__c = :lstSentToAGRESpecialAcceptance[0].Id];
                System.assertEquals(3, lstSARBeforeDelete.size());

                Map<String, Object> mapResults = LWC48_CopySpecialAcceptance.deletePlacementTable(lstSentToAGRESpecialAcceptance[0].Id);
            Test.stopTest();
            //System.assertEquals('Success', mapResults.get('Success')); 

            List<Request__c> lstSARAfterDelete = [SELECT Id, Name FROM Request__c WHERE Special_Acceptance__c = :lstSentToAGRESpecialAcceptance[0].Id];
            //System.assertEquals(0, lstSARAfterDelete.size());
        }
    }

    @IsTest
    public static void testBindSACe(){
        System.runAs(testUserCE) {
            Test.startTest();
                List<SpecialAcceptance__c> lstSelectedSa = new List<SpecialAcceptance__c>{lstSentToAGRESpecialAcceptance[0]};
                lstSentToAGRESpecialAcceptance[0].Bound__c = '1';
                Map<String, Object> mapResult = LWC48_CopySpecialAcceptance.bindSA(lstSentToAGRESpecialAcceptance[0], true);
            Test.stopTest();
            System.assertEquals(null, mapResult.get('Error'));
            System.assertEquals('Success', mapResult.get('Success'));

            for(SpecialAcceptance__c sa : [SELECT Id, Bound__c FROM SpecialAcceptance__c WHERE Id IN :lstSelectedSa]){
                System.assertEquals('1', sa.Bound__c);
            }
        }
    }

    @IsTest
    public static void testBindSACedingPortal(){
        System.runAs(testUserCedingPortal) {
            Test.startTest();
                List<SpecialAcceptance__c> lstSelectedSa = new List<SpecialAcceptance__c>{lstSpecialAcceptance[0]};
                lstSpecialAcceptance[0].Bound__c = '1';
                update lstSpecialAcceptance;
                Map<String, Object> mapResult = LWC48_CopySpecialAcceptance.bindSA(lstSpecialAcceptance[0], false);   
            Test.stopTest();
            System.assertEquals(null, mapResult.get('Error'));
            System.assertEquals('Success', mapResult.get('Success'));

            for(SpecialAcceptance__c sa : [SELECT Id, Bound__c FROM SpecialAcceptance__c WHERE Id IN :lstSelectedSa]){
                System.assertEquals('1', sa.Bound__c);
            }
        }
    }
}