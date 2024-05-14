@IsTest
public with sharing class LWC28_PortalDocuments_TEST {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Test class for LWC28_PortalDocuments
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 12-MAR-2021  NBI   1.0      Initial version
--------------------------------------------------------------------------------------
**************************************************************************************/

    static User testUserAdmin;
    static User testUserCE;
    static List<User> lstPortalUser = new List<User>();
    static List<User> lstUsers = new List<User>();
    static List<Account> lstAccount;
    static List<Contact> lstContact;
    static List<Program__c> lstProgram;
    static List<CoveredCedingCompany__c> lstCovCedCom;
    static List<Pool__c> lstPool;
    static List<PoolTreatySection__c> lstPoolTreatySections;
    static List<Treaty__c> lstTreaty;
    static List<Request__c> lstRequests;
    static List<Section__c> lstSection;
    static List<ContentVersion> lstContentVersion;
    static List<ContentDocumentLink> lstContentDocumentLink;
    static String fileContent = 'This is an example.';
    static Blob fileContentInBlob = Blob.valueOf(fileContent);
    static List<DocumentVisibility__c> lstDocumentVisibility;
    static Map<String, Id> mapRecTypeIdRequest = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectRequest});
    static Map<String, Id> mapAccountRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectAcc});
    static Map<String, Id> mapSARecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectSpecialAcceptance});

    static {
        //create User.
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

            lstAccount[0].EmailSA__c = 'test@test.com';
            update lstAccount;

            //create Ceding Portal Contact + Broker/Reinsurer Contact
            lstContact = new List<Contact> {
                    TestFactory.createContact('Account E - Covered Ceding', 'CedingPortal', lstAccount[2].Id, '2', '25009'),
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

            //create Request
            lstRequests = new List<Request__c>{
                    TestFactory.createRequest(lstProgram[0].Id, lstTreaty[0].Id, lstAccount[4].Id, lstAccount[5].Id, '1', '3',
                            mapRecTypeIdRequest.get(AP_Constant.reqRTQuote), '2', 'Sent', lstSection[0].Id),

                    TestFactory.createRequest(lstProgram[1].Id, lstTreaty[2].Id, lstAccount[4].Id, lstAccount[5].Id, '2', '1',
                            mapRecTypeIdRequest.get(AP_Constant.reqRTQuote), '2', 'Sent', lstSection[1].Id),

                    TestFactory.createRequest(lstProgram[0].Id, lstTreaty[0].Id, lstAccount[4].Id, lstAccount[5].Id, '1', '3',
                            mapRecTypeIdRequest.get(AP_Constant.reqRTPlacement), '2', 'Sent', lstSection[0].Id),

                    TestFactory.createRequest(lstProgram[1].Id, lstTreaty[2].Id, lstAccount[4].Id, lstAccount[5].Id, '2', '1',
                            mapRecTypeIdRequest.get(AP_Constant.reqRTPlacement), '2', 'Sent', lstSection[0].Id),

                    TestFactory.createRequest(lstProgram[0].Id, lstTreaty[0].Id, lstAccount[4].Id, lstAccount[5].Id, '1', '3',
                            mapRecTypeIdRequest.get(AP_Constant.reqRTSigning), '2', 'Sent', lstSection[0].Id),

                    TestFactory.createRequest(lstProgram[1].Id, lstTreaty[2].Id, lstAccount[4].Id, lstAccount[5].Id, '2', '1',
                            mapRecTypeIdRequest.get(AP_Constant.reqRTSigning), '2', 'Sent', lstSection[1].Id)
            };
            insert lstRequests;

            //create ContentVersion
            lstContentVersion = new List<ContentVersion>{
                    TestFactory.createContentVersion('2','1'
                            , '5', 'CV1', fileContentInBlob, 'CV1'),
                    TestFactory.createContentVersion('2','1'
                            , '5', 'CV2', fileContentInBlob, 'CV2'),
                    TestFactory.createContentVersion('2','1'
                            , '5', 'CV3', fileContentInBlob, 'CV3'),
                    TestFactory.createContentVersion('1','1'
                            , '5', 'CV4', fileContentInBlob, 'CV4'),
                    TestFactory.createContentVersion('1','1'
                            , '5', 'CV5', fileContentInBlob, 'CV5'),
                    TestFactory.createContentVersion('1','1'
                            , '5', 'CV6', fileContentInBlob, 'CV6')
            };
            insert lstContentVersion;

            List<Id> lstContentVersionId = new List<Id>();
            for(ContentVersion contentVersion : lstContentVersion){
                lstContentVersionId.add(contentVersion.Id);
            }

            lstContentVersion = [SELECT Id, ContentDocumentId, DocumentType__c, GroupType__c, Phase__c, Title, VersionData, VersionNumber FROM ContentVersion WHERE Id IN :lstContentVersionId];

            lstContentDocumentLink = new List<ContentDocumentLink>{
                    TestFactory.createContentDocumentLink(lstContentVersion[0].ContentDocumentId, lstProgram[0].Id, 'V'),
                    TestFactory.createContentDocumentLink(lstContentVersion[2].ContentDocumentId, lstProgram[0].Id, 'V'),
                    TestFactory.createContentDocumentLink(lstContentVersion[3].ContentDocumentId, lstProgram[0].Id, 'V'),
                    TestFactory.createContentDocumentLink(lstContentVersion[1].ContentDocumentId, lstProgram[0].Id, 'V'),
                    TestFactory.createContentDocumentLink(lstContentVersion[4].ContentDocumentId, lstProgram[0].Id, 'V'),
                    TestFactory.createContentDocumentLink(lstContentVersion[5].ContentDocumentId, lstProgram[0].Id, 'V')
            };
            insert lstContentDocumentLink;


            //create doc visibility
            lstDocumentVisibility = new List<DocumentVisibility__c>{
                    TestFactory.createDocumentVisibility(lstAccount[4].Id, lstAccount[5].Id,lstContentVersion[0].Id, lstProgram[0].Id),
                    TestFactory.createDocumentVisibility(lstAccount[4].Id, lstAccount[5].Id,lstContentVersion[0].Id, lstProgram[0].Id),
                    TestFactory.createDocumentVisibility(lstAccount[4].Id, lstAccount[5].Id,lstContentVersion[0].Id, lstProgram[0].Id),
                    TestFactory.createDocumentVisibility(lstAccount[4].Id, lstAccount[5].Id,lstContentVersion[0].Id, lstProgram[0].Id),
                    TestFactory.createDocumentVisibility(lstAccount[4].Id, lstAccount[5].Id,lstContentVersion[0].Id, lstProgram[0].Id),
                    TestFactory.createDocumentVisibility(lstAccount[4].Id, lstAccount[5].Id,lstContentVersion[0].Id, lstProgram[0].Id),
                    TestFactory.createDocumentVisibility(lstAccount[4].Id, lstAccount[5].Id,lstContentVersion[0].Id, lstProgram[0].Id),
                    TestFactory.createDocumentVisibility(lstAccount[4].Id, lstAccount[5].Id,lstContentVersion[0].Id, lstProgram[0].Id)
            };

            for(DocumentVisibility__c docVis : lstDocumentVisibility){
               docVis.DocumentUpdateDate__c = System.today();     
            }

            insert lstDocumentVisibility;

        }

        System.runAs(testUserAdmin) {
            lstPortalUser = new List<User>{
                    TestFactory.createUser('testUserCedingPortal', TestFactory.getProfileInternalId()),
                    TestFactory.createUser('testUserBrokerPortal', TestFactory.getProfileExternalId()),
                    TestFactory.createUser('testUserReinsurerPortal', TestFactory.getProfileExternalId())
            };

            lstPortalUser[0].ContactId = lstContact[0].Id;
            lstPortalUser[1].ContactId = lstContact[1].Id;
            lstPortalUser[2].ContactId = lstContact[2].Id;
            lstPortalUser[0].BypassTrigger__c = 'AP44_CreateSharingForUser;AP59_DeleteOldAccConRelation';
            lstPortalUser[1].BypassTrigger__c = 'AP44_CreateSharingForUser;AP59_DeleteOldAccConRelation';
            lstPortalUser[2].BypassTrigger__c = 'AP44_CreateSharingForUser;AP59_DeleteOldAccConRelation';

            insert lstPortalUser;

            List<AccountShare> lstAccShare = new List<AccountShare>();

            //Create Account Share for ceding portal user
            for(Account acc : lstAccount){
                AccountShare accShare = new AccountShare();
                accShare.UserOrGroupId = lstPortalUser[0].Id;
                accShare.AccountId = acc.Id;
                accShare.AccountAccessLevel = 'Edit';
                accShare.OpportunityAccessLevel = 'Edit';
                lstAccShare.add(accShare);
            }

            for(Account acc : lstAccount){
                AccountShare accShare = new AccountShare();
                accShare.UserOrGroupId = lstPortalUser[1].Id;
                accShare.AccountId = acc.Id;
                accShare.AccountAccessLevel = 'Edit';
                accShare.OpportunityAccessLevel = 'Edit';
                lstAccShare.add(accShare);
            }

            for(Account acc : lstAccount){
                AccountShare accShare = new AccountShare();
                accShare.UserOrGroupId = lstPortalUser[2].Id;
                accShare.AccountId = acc.Id;
                accShare.AccountAccessLevel = 'Edit';
                accShare.OpportunityAccessLevel = 'Edit';
                lstAccShare.add(accShare);
            }

            if(lstAccShare.size() > 0){
                insert lstAccShare;
            }

            List<Request__Share> lstRequestShare = new List<Request__Share>();

            for(Request__c req : lstRequests){
                Request__Share requestShare = new Request__Share();
                requestShare.RowCause = 'Manual';
                requestShare.AccessLevel = 'Edit';
                requestShare.ParentId = req.Id;
                requestShare.UserOrGroupId = lstPortalUser[0].Id;
                lstRequestShare.add(requestShare);
            }

            for(Request__c req : lstRequests){
                Request__Share requestShare = new Request__Share();
                requestShare.RowCause = 'Manual';
                requestShare.AccessLevel = 'Edit';
                requestShare.ParentId = req.Id;
                requestShare.UserOrGroupId = lstPortalUser[1].Id;
                lstRequestShare.add(requestShare);
            }

            for(Request__c req : lstRequests){
                Request__Share requestShare = new Request__Share();
                requestShare.RowCause = 'Manual';
                requestShare.AccessLevel = 'Edit';
                requestShare.ParentId = req.Id;
                requestShare.UserOrGroupId = lstPortalUser[2].Id;
                lstRequestShare.add(requestShare);
            }

            if(lstRequestShare.size() > 0){
                insert lstRequestShare;
            }

        }
    }

    @IsTest
    public static void testSaveDocuments(){
        System.runAs(lstPortalUser[1]) {

            List<ContentVersion> lstInsertConVersion = new List<ContentVersion>{
                    TestFactory.createContentVersion('2','1'
                            , '5', 'CV1', fileContentInBlob, 'CV1'),
                    TestFactory.createContentVersion('2','1'
                            , '5', 'CV2', fileContentInBlob, 'CV2'),
                    TestFactory.createContentVersion('2','1'
                            , '5', 'CV3', fileContentInBlob, 'CV3'),
                    TestFactory.createContentVersion('1','1'
                            , '5', 'CV4', fileContentInBlob, 'CV4'),
                    TestFactory.createContentVersion('1','1'
                            , '5', 'CV5', fileContentInBlob, 'CV5'),
                    TestFactory.createContentVersion('1','1'
                            , '5', 'CV6', fileContentInBlob, 'CV6')
            };
            Test.startTest();
                Map<String, Object> mapResults = LWC28_PortalDocuments.saveDocuments(lstInsertConVersion, lstProgram[0].Id);
            Test.stopTest();
            System.assert(mapResults != null);
        }
    }

    /*@IsTest
    public static void testupdateIdNameBrokerNotNullReinsurerNotNull(){
        System.runAs(lstPortalUser[1]) {

            List<ContentVersion> lstInsertConVersion = new List<ContentVersion>{
                    TestFactory.createContentVersion('2','1'
                            , '5', 'CV1', fileContentInBlob, 'CV1'),
                    TestFactory.createContentVersion('2','1'
                            , '5', 'CV2', fileContentInBlob, 'CV2'),
                    TestFactory.createContentVersion('2','1'
                            , '5', 'CV3', fileContentInBlob, 'CV3'),
                    TestFactory.createContentVersion('1','1'
                            , '5', 'CV4', fileContentInBlob, 'CV4'),
                    TestFactory.createContentVersion('1','1'
                            , '5', 'CV5', fileContentInBlob, 'CV5'),
                    TestFactory.createContentVersion('1','1'
                            , '5', 'CV6', fileContentInBlob, 'CV6')
            };
            //insert lstInsertConVersion;

            List<ContentDocumentLink> lstInsertCDL = new List<ContentDocumentLink>{
                TestFactory.createContentDocumentLink(lstInsertConVersion[0].Id, lstProgram[0].Id, 'V'),
                TestFactory.createContentDocumentLink(lstInsertConVersion[1].Id, lstProgram[0].Id, 'V'),
                TestFactory.createContentDocumentLink(lstInsertConVersion[2].Id, lstProgram[0].Id, 'V'),
                TestFactory.createContentDocumentLink(lstInsertConVersion[3].Id, lstProgram[0].Id, 'V'),
                TestFactory.createContentDocumentLink(lstInsertConVersion[4].Id, lstProgram[0].Id, 'V'),
                TestFactory.createContentDocumentLink(lstInsertConVersion[5].Id, lstProgram[0].Id, 'V') 
            };
            //insert lstInsertCDL;

            List<Id> lstIdCV = new List<Id>{
                lstInsertConVersion[0].Id,
                lstInsertConVersion[1].Id,
                lstInsertConVersion[2].Id,
                lstInsertConVersion[3].Id,
                lstInsertConVersion[4].Id,
                lstInsertConVersion[5].Id
            };
 
            Test.startTest();
                Map<String, Object> mapResults = LWC28_PortalDocuments.updateIdNameBrokerReinsurer(lstIdCV, lstProgram[0].Id, lstAccount[4].Id, lstAccount[5].Id);
            Test.stopTest();
            System.assert(mapResults != null);
        }
    }*/

    @IsTest
    public static void testGetDocuments(){
        System.runAs(lstPortalUser[1]) {
            Test.startTest();
            Map<String, Object> mapResults = LWC28_PortalDocuments.getDocuments(lstProgram[0].Id, lstAccount[5].Id, lstAccount[4].Id , lstAccount[5].Id);
            Test.stopTest();
            System.assert(mapResults != null);
        }
    }

    @IsTest
    public static void testGetDocumentsBrokerNotNull(){
        System.runAs(lstPortalUser[1]) {
            Test.startTest();
            Map<String, Object> mapResults = LWC28_PortalDocuments.getDocuments(lstProgram[0].Id, lstAccount[5].Id, lstAccount[4].Id , lstAccount[5].Id);
            Test.stopTest();
            System.assert(mapResults != null);
        }
    }

    @IsTest
    public static void testGetDocumentsReins(){
        System.runAs(lstPortalUser[2]) {
            Test.startTest();
            Map<String, Object> mapResults = LWC28_PortalDocuments.getDocuments(lstProgram[0].Id, lstAccount[5].Id, lstAccount[4].Id , lstAccount[5].Id);
            Test.stopTest();
            System.assert(mapResults != null);
        }
    }
    @IsTest
    public static void testGetDocumentsReinsBrokNull(){
        System.runAs(lstPortalUser[1]) {
            Test.startTest();
            Map<String, Object> mapResults = LWC28_PortalDocuments.getDocuments(lstProgram[0].Id, lstAccount[5].Id, null , lstAccount[5].Id);
            Test.stopTest();
            System.assert(mapResults != null);
        }
    }

    @IsTest
    public static void testGetDocumentsReinsNull(){
        System.runAs(lstPortalUser[1]) {
            Test.startTest();
            Map<String, Object> mapResults = LWC28_PortalDocuments.getDocuments(lstProgram[0].Id, lstAccount[5].Id, lstAccount[4].Id , null);
            Test.stopTest();
            System.assert(mapResults != null);
        }
    }

    @IsTest
    public static void testGetDocumentsAllNull(){
        System.runAs(lstPortalUser[1]) {
            Test.startTest();
            Map<String, Object> mapResults = LWC28_PortalDocuments.getDocuments(lstProgram[0].Id, lstAccount[5].Id, null , null);
            Test.stopTest();
            System.assert(mapResults != null);
        }
    }

    @IsTest
    public static void testGetContentVersionId(){
        System.runAs(lstPortalUser[1]) {
            Test.startTest();
            List<ContentVersion> lstResults = LWC28_PortalDocuments.getContentVersionId(new List<Id>{lstContentVersion[0].ContentDocumentId, lstContentVersion[1].ContentDocumentId, lstContentVersion[2].ContentDocumentId});
            Test.stopTest();
            System.assert(lstResults != null);
        }
    }

    @IsTest
    public static void testDeleteContentDocument1(){
        System.runAs(lstPortalUser[1]) {
            Test.startTest();
            Map<String, Object> mapResults = LWC28_PortalDocuments.deleteContentDocument(new List<Id>{lstContentVersion[0].ContentDocumentId, lstContentVersion[1].ContentDocumentId, lstContentVersion[2].ContentDocumentId});
            Test.stopTest();
            System.assert(mapResults != null);
        }
    }

    @IsTest
    public static void testDeleteContentDocumentVisibility(){
        System.runAs(lstPortalUser[1]) {
            Test.startTest();
            Map<String, Object> mapResults = LWC28_PortalDocuments.deleteDocVisibilityDocument(new List<Id>{lstContentVersion[0].ContentDocumentId, lstContentVersion[1].ContentDocumentId, lstContentVersion[2].ContentDocumentId}, lstProgram[0].Id);
            Test.stopTest();
            System.assert(mapResults != null);
        }
    }

    @IsTest
    public static void testReplaceDocuments() {
        System.runAs(testUserCE) {
            Test.startTest();
            Map<Id, List<String>> mapInitialDocuments = LWC28_PortalDocuments.getInitialDocuments(lstProgram[0].Id);
            ContentVersion contentVersion = new ContentVersion(GroupType__c = '1', DocumentType__c = '3',Phase__c = '3', VersionData = lstContentVersion[0].VersionData
                    , ContentDocumentId = lstContentVersion[0].ContentDocumentId, PathOnClient ='CV5', Title = 'CV5');
            insert contentVersion;
            Map<String, Object> mapResult = LWC28_PortalDocuments.replaceDocuments(mapInitialDocuments, lstProgram[0].Id);
            Test.stopTest();
            System.assertEquals('Success', mapResult.get('Success'));
        }
    }

    @IsTest
    public static void testDeleteContentDocument(){
        System.runAs(testUserCE) {
            Test.startTest();
            List<Id> lstDocId = new List<Id>();

            for(ContentDocument contentDocument : [SELECT Id FROM ContentDocument]){
                lstDocId.add(contentDocument.Id);
            }

            Map<String, Object> mapResult = LWC28_PortalDocuments.deleteContentDocument(lstDocId);
            Test.stopTest();

            System.assertEquals('Success', mapResult.get('Success'));
            List<ContentDocument> lstContentDocument = [SELECT Id FROM ContentDocument WHERE Id IN :lstDocId];
            System.assertEquals(0, lstContentDocument.size());
        }
    }

    @IsTest
    public static void testSaveReplaceDocument(){
        System.runAs(testUserCE) {
            Test.startTest();
            List<ContentVersion> lstNewContentVersion = new List<ContentVersion>{
                    TestFactory.createContentVersion('2','1'
                            , '1', 'CV3', fileContentInBlob, 'CV3')
            };
            insert lstNewContentVersion;

            lstNewContentVersion = [SELECT Id, ContentDocumentId, DocumentType__c, GroupType__c, Phase__c, Title, VersionData, VersionNumber FROM ContentVersion WHERE Id = :lstNewContentVersion[0].Id];
            Map<String, Object> mapResults = LWC28_PortalDocuments.saveReplaceDocument(lstNewContentVersion[0].ContentDocumentId, lstContentVersion[1].Id, '1//2//1;2');

            Map<String, Object> mapResultsError = LWC28_PortalDocuments.saveReplaceDocument(lstNewContentVersion[0].ContentDocumentId, lstContentVersion[1].Id, '1//2');
            Test.stopTest();
            System.assertEquals('Success', mapResults.get('Success'));
            System.assertEquals(null, mapResultsError.get('Success'));
        }
    }

    @IsTest
    public static void testDeleteContentVersionDocument(){
        System.runAs(testUserCE) {
            Test.startTest();
                List<Id> lstContentVersionIdToDelete = new List<Id>{lstContentVersion[0].Id};
                Map<String, Object> mapResults = LWC28_PortalDocuments.deleteContentVersionDocument(lstContentVersionIdToDelete);
            Test.stopTest();
            System.assertEquals('Success', mapResults.get('Success'));
            System.assertEquals(null, mapResults.get('Error'));
        }
    }

    @IsTest
    public static void testGetDateContentVersionId(){
        System.runAs(lstPortalUser[1]) {
            Test.startTest();
            DateTime resultsDate = LWC28_PortalDocuments.getDateContentVersionId(new List<Id>{lstContentVersion[0].ContentDocumentId, lstContentVersion[1].ContentDocumentId, lstContentVersion[2].ContentDocumentId});
            Test.stopTest();
            System.assert(resultsDate != null);
        }
    }

    
    @IsTest
    public static void testRetrieveNameBrokerReinsurer(){
        System.runAs(lstPortalUser[1]) {
            Test.startTest();
            Map<String, Object> mapResults = LWC28_PortalDocuments.retrieveNameBrokerReinsurer(lstRequests[0].Id);
            Test.stopTest();
            System.assertEquals('Success', mapResults.get('Success'));
            System.assertEquals(null, mapResults.get('Error'));
        }
    }

    @IsTest
    public static void testdeleteDocVisibilityDocument(){
        System.runAs(testUserCE) {
            Test.startTest();
                List<Id> lstContentVersionIdToDelete = new List<Id>{lstContentVersion[0].Id};
                Map<String, Object> mapResults = LWC28_PortalDocuments.deleteDocVisibilityDocument(lstContentVersionIdToDelete, lstProgram[0].Id);
            Test.stopTest();
            System.assertEquals('Success', mapResults.get('Success'));
            System.assertEquals(null, mapResults.get('Error'));
        }
    }

    @IsTest
    public static void testdeleteDocVisibilityDocumentOld(){
        System.runAs(testUserCE) {
            Test.startTest();
                List<Id> lstContentVersionIdToDelete = new List<Id>{lstContentVersion[0].Id};
                Map<String, Object> mapResults = LWC28_PortalDocuments.deleteDocVisibilityDocumentOld(lstContentVersionIdToDelete, lstProgram[0].Id);
            Test.stopTest();
            System.assertEquals('Success', mapResults.get('Success'));
            System.assertEquals(null, mapResults.get('Error'));
        }
    }
}