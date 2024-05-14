@IsTest
public with sharing class LWC54_SAGroupCover_TEST {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Test class for LWC54_SAGroupCover
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 27-FEB-2021  MBE   1.0      Initial version
--------------------------------------------------------------------------------------
**************************************************************************************/
    static User testUserAdmin;
    static User testUserCE;
    static User testUserBRPortal;
    static List<User> lstBRPortalUser = new List<User>();
    static List<User> lstUsers = new List<User>();
    static List<Account> lstAccount;
    static List<Contact> lstContact;
    static List<Program__c> lstProgram;
    static List<CoveredCedingCompany__c> lstCovCedCom;
    static List<GroupMember> lstGroupMember = new List<GroupMember>();
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

            lstAccount[0].EmailSA__c = 'test@test.com';
            update lstAccount;

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

            //create BR Portal Contact
            lstContact = new List<Contact> {
                TestFactory.createContact('AccountE', 'BRPortal', lstAccount[4].Id, '2', '25009')
            };
            insert lstContact;

            // create Ceding Portal User
            testUserBRPortal = TestFactory.createUser('testUserBRPortal', TestFactory.getProfileExternalId());
            testUserBRPortal.ContactId = lstContact[0].Id;
            lstBRPortalUser.add(testUserBRPortal);
            insert lstBRPortalUser;

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
                if(mapGroupByReferentialId.containsKey(acc.TECH_ReferentialId__c)){
                    GroupMember groupMember = new GroupMember();
                    groupMember.GroupId = mapGroupByReferentialId.get(acc.TECH_ReferentialId__c).Id;
                    groupMember.UserOrGroupId = testUserCE.Id;
                    lstGroupMember.add(groupMember);
                } 
            }

            if(lstGroupMember.size() > 0){
                insert lstGroupMember;
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
                TestFactory.createCovCedCom(lstAccount[2].Id, lstProgram[1].Id, true,null
                                            ,false,null,false,null,null),

                TestFactory.createCovCedCom(lstAccount[3].Id, lstProgram[1].Id, true,null
                                            ,false,null,false,null,null),

                TestFactory.createCovCedCom(lstAccount[3].Id, lstProgram[2].Id, true,null
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
                , null, '2','20043','Capacity', lstAccount[2].Id),

                TestFactory.createSpecialAcceptance(mapSARecTypeId.get(AP_Constant.saRTPC), lstProgram[1].Id, lstAccount[1].Id, 'TestSA1'
                , '2020', 'Setup', null, '2020-23-00000001', true, false, '1', null
                , null, '2','20043','Capacity', lstAccount[2].Id),

                TestFactory.createSpecialAcceptance(mapSARecTypeId.get(AP_Constant.saRTLife), lstProgram[0].Id, lstAccount[0].Id, 'TestSA1'
                , '2020', 'Setup', null, '2020-23-00000002', true, false, '1', null
                , null, '1','20043','Capacity', lstAccount[2].Id)
            };

            insert lstSpecialAcceptance;

            lstSpecialAcceptance[0].SentAgreFromSpecialAcceptance__c = lstSpecialAcceptance[1].Id;
            update lstSpecialAcceptance;

            lstRenewedSpecialAcceptance = new List<SpecialAcceptance__c> {
                TestFactory.createSpecialAcceptance(mapSARecTypeId.get(AP_Constant.saRTLife), lstProgram[0].Id, lstAccount[0].Id, 'TestSA1'
                , '2020', 'Setup', null, '2021-23-00000001', true, false, '1', lstSpecialAcceptance[0].Id
                , null, '2','20043','Capacity', lstAccount[2].Id),

                TestFactory.createSpecialAcceptance(mapSARecTypeId.get(AP_Constant.saRTPC), lstProgram[1].Id, lstAccount[0].Id, 'TestSA1'
                , '2020', 'Setup', null, '2021-23-00000002', true, false, '1', lstSpecialAcceptance[1].Id
                , null, '2','20043','Capacity', lstAccount[2].Id)
            };

            insert lstRenewedSpecialAcceptance;

            lstSentToAGRESpecialAcceptance = new List<SpecialAcceptance__c> {
                TestFactory.createSpecialAcceptance(mapSARecTypeId.get(AP_Constant.saRTLife), lstProgram[0].Id, lstAccount[0].Id, 'TestSA1'
                , '2020', 'Setup', null, '2020-23-00000003', true, false, '1', null
                , lstSpecialAcceptance[0].Id, '2','20043','Capacity', lstAccount[2].Id),

                TestFactory.createSpecialAcceptance(mapSARecTypeId.get(AP_Constant.saRTPC), lstProgram[1].Id, lstAccount[0].Id, 'TestSA1'
                , '2020', 'Setup', null, '2020-23-00000004', true, false, '1', null
                , lstSpecialAcceptance[0].Id, '2','20043','Capacity', lstAccount[2].Id)
            };
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

            lstContentVersion[0].IsExternal__c = true;
            lstContentVersion[1].IsExternal__c = true;
            lstContentVersion[2].IsExternal__c = false;
            lstContentVersion[3].IsExternal__c = true;
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
                                            mapRecTypeIdRequest.get(AP_Constant.reqRTSigning), '2', 'Signed',lstSection[0].Id),

                TestFactory.createRequest(lstProgram[0].Id, lstTreaty[0].Id, lstAccount[4].Id, lstAccount[5].Id, '2', '1',
                                            mapRecTypeIdRequest.get(AP_Constant.reqRTSigning), '2', 'Signed',lstSection[0].Id),
            
                TestFactory.createRequest(lstProgram[0].Id, null, lstAccount[4].Id, lstAccount[5].Id, '2', '1',
                                            mapRecTypeIdRequest.get(AP_Constant.reqRTSA), '2', 'Setup',null),

                TestFactory.createRequest(lstProgram[0].Id, null, null, null, '2', '1',
                                            mapRecTypeIdRequest.get(AP_Constant.reqRTSA), '2', 'Setup',null),
                
                TestFactory.createRequest(lstProgram[0].Id, null, lstAccount[4].Id, lstAccount[5].Id, '2', '1',
                                            mapRecTypeIdRequest.get(AP_Constant.reqRTSA), '2', 'Sent',null)
            };
            lstRequest[0].LastVersionSent__c = true;
            lstRequest[0].LastVersionAnswered__c = true;
            lstRequest[3].Program__r = lstProgram[0];

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
            
            insert lstRequest;

            lstRequest[4].OriginalRequest__c = lstRequest[2].Id;
            lstRequest[4].Program__r = lstProgram[0];

            update lstRequest;
        }
    }

    @IsTest
    public static void testGetFilterValues(){
        System.runAs(testUserCE) {
            Test.startTest();
                Map<String, Object> mapResult = LWC54_SAGroupCover.getFilterValues('2020', lstAccount[0].Id, lstProgram[0].Id, lstPool[0].Id);
            Test.stopTest();
            System.assertEquals(null, mapResult.get('Error'));
            System.assertEquals('Success', mapResult.get('Success')); 

            List<LWC54_SAGroupCover.OptionWrapper> lstPCCOption = (List<LWC54_SAGroupCover.OptionWrapper>) mapResult.get('lstPCCOption');
            System.assertEquals(1, lstPCCOption.size()); 
        }
    }

    @IsTest
    public static void testGetSAR(){
        System.runAs(testUserCE) {
            Test.startTest();
                List<String> lstSelectedSA = new List<String>{lstSpecialAcceptance[0].Id};
                Map<String, Object> mapResult = LWC54_SAGroupCover.getSAR(lstSelectedSA, lstPool[0].Id);
            Test.stopTest();
            System.assertEquals(null, mapResult.get('Error'));
            System.assertEquals('Success', mapResult.get('Success')); 

            List<Request__c> lstSARequest = (List<Request__c>) mapResult.get('lstSARequest');
            System.assertEquals(1, lstSARequest.size()); 
        }
    }

    @IsTest
    public static void testGetPrincipalCedingAcc(){
        System.runAs(testUserCE) {
            Test.startTest();
            List<LWC54_SAGroupCover.OptionWrapper> lstPCC = LWC54_SAGroupCover.getPrincipalCedingAcc();
            Test.stopTest();
            System.assertEquals(2, lstPCC.size()); 
        }
    }

    @IsTest
    public static void testGetProgramForGroupCover(){
        System.runAs(testUserCE) {
            Test.startTest();
                Map<String, Object> mapResult = LWC54_SAGroupCover.getProgramForGroupCover('2020', lstAccount[0].Id, lstRequest[3]);
            Test.stopTest();
            System.assertEquals(null, mapResult.get('Error'));
            System.assertEquals('Success', mapResult.get('Success')); 

            List<Program__c> lstProgram = (List<Program__c>) mapResult.get('lstProgram');
            System.assertEquals(1, lstProgram.size()); 
        }
    }

    @IsTest
    public static void testGenerateGroupCoverSa(){
        System.runAs(testUserCE) {
            Test.startTest();
                List<String> lstProgId = new List<String>{lstProgram[1].Id};
                Map<String, Object> mapResult = LWC54_SAGroupCover.generateGroupCoverSa(lstProgId, lstRequest[3], '2020', lstAccount[0].Id);

                System.assertEquals(null, mapResult.get('Error'));
                System.assertEquals('Success', mapResult.get('Success')); 

                List<SpecialAcceptance__c> lstGroupCoverSa = [SELECT Id, Name, TECH_LocalSA__c FROM SpecialAcceptance__c WHERE TECH_LocalSA__c = :lstRequest[3].Special_Acceptance__c];

                System.assertEquals(2, lstGroupCoverSa.size()); 
            Test.stopTest(); 
        }
    } 
}