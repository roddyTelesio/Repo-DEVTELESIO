@IsTest
public with sharing class LWC29_AnswerRequests_TEST {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Test class for LWC29_AnswerRequests
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 12-MAR-2021   NBI   1.0      Initial version
-- 24-MAY-2021   MBE   1.1      W-0974 - Bug bloquant Prod - Impossibilité de créer une Lead request - TECH_Actor2Id__c
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
    static List<Request__c> lstLeadRequests;
    static List<Request__c> lstChildLeadRequests;
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
        //create User
        testUserAdmin = TestFactory.createUserWithRole('testUserAdmin', TestFactory.getProfileAdminId(), TestFactory.getCERoleId());
        testUserCE = TestFactory.createUser('testUserCE', TestFactory.getProfileCEId());
        User assignedToUser = TestFactory.createUserWithRole('TestAssignedTo', TestFactory.getProfileAdminId(),TestFactory.getHeadUGPRoleId());

        lstUsers.add(testUserAdmin);
        lstUsers.add(testUserCE);
        lstUsers.add(assignedToUser);

        lstUsers[0].BypassTrigger__c = 'AP44_CreateSharingForUser;AP59_DeleteOldAccConRelation;AP36_CreateSharingForContact';
        lstUsers[1].BypassTrigger__c = 'AP44_CreateSharingForUser;AP59_DeleteOldAccConRelation;AP36_CreateSharingForContact';
        lstUsers[2].BypassTrigger__c = 'AP44_CreateSharingForUser;AP59_DeleteOldAccConRelation;AP36_CreateSharingForContact';
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

            lstAccount[0].EmailSA__c = 'test1@gmail.com;test2@gmail.com';
            lstAccount[1].EmailSA__c = 'test1@gmail.com;test2@gmail.com';
            lstAccount[0].EmailPCLife__c = 'test1@gmail.com;test2@gmail.com';
            lstAccount[1].EmailPCLife__c = 'test1@gmail.com;test2@gmail.com';
            update lstAccount;

            //create Ceding Portal Contact + Broker/Reinsurer Contact
            lstContact = new List<Contact> {
                TestFactory.createContact('Account E - PccCeding', 'CedingPortal', lstAccount[6].Id, '2', '25009'),
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
                TestFactory.createTreaty('TestTreaty1', 1, '2020-00000221/1', '3'
                        , lstProgram[0].Id, '2', 34, '10', '2020-00000222/1', '1', '2', '2', '2', '2'),

                TestFactory.createTreaty('TestTreaty2', 2, '2020-00000222/1', '2', lstProgram[0].Id
                        , '1', 44, '44', '2020-00000222/1', '2', '2', '2', '2', '2'),

                TestFactory.createTreaty('TestTreaty3', 3, '2020-00000223/1', '2'
                        , lstProgram[1].Id, '2', 89, '44', '2020-00000222/1', '3', '2', '2', '2', '2'),

                TestFactory.createTreaty('TestTreaty4', 3, '2020-00000224/1', '3'
                        , lstProgram[2].Id, '2', 89, '10', '2020-00000222/1', '1', '2', '2', '2', '2')
            };
            insert lstTreaty;
            lstTreaty[0].WebXLReference__c = '020-00000222/1';
            lstTreaty[1].WebXLReference__c = '020-00000222/1';
            lstTreaty[2].WebXLReference__c = '020-00000222/1';
            lstTreaty[3].WebXLReference__c = '020-00000222/1';
            update lstTreaty;

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
                // recordTypeId + status required
                TestFactory.createRequest(lstProgram[1].Id, lstTreaty[2].Id, lstAccount[4].Id, lstAccount[5].Id, '1', '3',
                        mapRecTypeIdRequest.get(AP_Constant.reqRTQuote), '2', 'Sent',lstSection[1].Id),

                TestFactory.createRequest(lstProgram[1].Id, lstTreaty[2].Id, lstAccount[4].Id, lstAccount[5].Id, '2', '1',
                        mapRecTypeIdRequest.get(AP_Constant.reqRTQuote), '2', 'Sent',lstSection[1].Id),

                TestFactory.createRequest(lstProgram[1].Id, lstTreaty[2].Id, lstAccount[4].Id, lstAccount[5].Id, '1', '3',
                        mapRecTypeIdRequest.get(AP_Constant.reqRTQuote), '2', 'Sent',lstSection[1].Id),

                TestFactory.createRequest(lstProgram[1].Id, lstTreaty[2].Id, lstAccount[4].Id, lstAccount[5].Id, '2', '1',
                        mapRecTypeIdRequest.get(AP_Constant.reqRTQuote), '2', 'Sent',lstSection[1].Id),

                TestFactory.createRequest(lstProgram[1].Id, lstTreaty[2].Id, lstAccount[4].Id, lstAccount[5].Id, '1', '5',
                        mapRecTypeIdRequest.get(AP_Constant.reqRTPlacement), '2', 'Setup',lstSection[1].Id),

                TestFactory.createRequest(lstProgram[1].Id, lstTreaty[2].Id, lstAccount[4].Id, lstAccount[5].Id, '2', '5',
                        mapRecTypeIdRequest.get(AP_Constant.reqRTPlacement), '2', 'Sent',lstSection[1].Id)
            };

            lstRequests[0].Quote__c = '1';
            lstRequests[0].VersionMinor__c = 1;
            lstRequests[0].TECH_PortalFirstSend__c = false;
            lstRequests[0].TECH_PhaseType__c = '6';//MRA Sprint 5 
            lstRequests[0].QuoteDeadline__c = Date.today();
            lstRequests[0].ReinsurerStatus__c = 'Sent';
            lstRequests[0].LastVersionSent__c = true;
            lstRequests[0].LastVersionAnswered__c = true;

            lstRequests[1].Quote__c = '2';
            lstRequests[1].QuoteDeadline__c = Date.today(); 
            lstRequests[1].VersionMinor__c = 1;
            lstRequests[1].LastVersionSent__c = true;
            lstRequests[1].LastVersionAnswered__c = true;
            lstRequests[1].ReinsurerStatus__c = 'Sent';

            lstRequests[2].OriginalRequest__c = lstRequests[0].Id;
            lstRequests[2].Quote__c = '1';
            lstRequests[2].VersionMinor__c = 2;

            lstRequests[3].Quote__c = '2';
            lstRequests[3].OriginalRequest__c = lstRequests[1].Id;
            lstRequests[3].VersionMinor__c = 2;

            lstRequests[4].LastVersionSent__c = false;
            lstRequests[4].LastVersionAnswered__c = false;
            lstRequests[4].VersionMinor__c = 1;
            lstRequests[4].TECH_PortalFirstSend__c = false;

            lstRequests[5].LastVersionSent__c = true;
            lstRequests[5].LastVersionAnswered__c = true;
            lstRequests[5].OriginalRequest__c = lstRequests[4].Id;
            lstRequests[5].TECH_PortalFirstSend__c = false;
            lstRequests[5].VersionMinor__c = 2;

            insert lstRequests;

            //create lead
            lstLeadRequests = new List<Request__c>{
                // recordTypeId + status required
                TestFactory.createLeadRequest(lstProgram[1].Id, lstTreaty[2].Id, lstAccount[4].Id, lstAccount[5].Id, '1', '4',
                        mapRecTypeIdRequest.get(AP_Constant.reqRTLead), '2', 'Sent',lstSection[1].Id),

                TestFactory.createLeadRequest(lstProgram[1].Id, lstTreaty[2].Id, lstAccount[4].Id, lstAccount[5].Id, '2', '4',
                        mapRecTypeIdRequest.get(AP_Constant.reqRTLead), '2', 'Sent',lstSection[1].Id)
            };

            lstLeadRequests[0].LastVersionSent__c = false;
            lstLeadRequests[0].LastVersionAnswered__c = false;
            lstLeadRequests[0].VersionMinor__c = 1;
            lstLeadRequests[0].Accept__c = true;

            lstLeadRequests[1].LastVersionSent__c = true;
            lstLeadRequests[1].LastVersionAnswered__c = true;
            lstLeadRequests[1].VersionMinor__c = 2;
            lstLeadRequests[1].OriginalRequest__c = lstLeadRequests[0].Id;
            lstLeadRequests[1].Accept__c = true;

            update lstLeadRequests;

            lstChildLeadRequests = [SELECT Id, Name, ReinsurerStatus__c,LastVersionSent__c, LastVersionAnswered__c
                                            , VersionMinor__c, Accept__c, Reinsurer__c, Broker__c, TECH_PhaseType__c
                                    FROM Request__c
                                    WHERE Reinsurer__c = NULL
                                    AND RecordTypeId = :mapRecTypeIdRequest.get(AP_Constant.reqRTLead)];

            lstChildLeadRequests[0].LastVersionSent__c = false;
            lstChildLeadRequests[0].LastVersionAnswered__c = false;
            lstChildLeadRequests[0].VersionMinor__c = 1;
            lstChildLeadRequests[0].Accept__c = true;

            lstChildLeadRequests[1].LastVersionSent__c = true;
            lstChildLeadRequests[1].LastVersionAnswered__c = true;
            lstChildLeadRequests[1].VersionMinor__c = 2;
            lstChildLeadRequests[1].OriginalRequest__c = lstChildLeadRequests[0].Id;
            lstChildLeadRequests[1].Accept__c = true;
            update lstChildLeadRequests;

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
                TestFactory.createDocumentVisibility(lstAccount[4].Id, lstAccount[5].Id,lstContentVersion[0].Id, lstProgram[1].Id),
                TestFactory.createDocumentVisibility(lstAccount[4].Id, lstAccount[5].Id,lstContentVersion[0].Id, lstProgram[1].Id),
                TestFactory.createDocumentVisibility(lstAccount[4].Id, lstAccount[5].Id,lstContentVersion[0].Id, lstProgram[1].Id),
                TestFactory.createDocumentVisibility(lstAccount[4].Id, lstAccount[5].Id,lstContentVersion[0].Id, lstProgram[1].Id),
                TestFactory.createDocumentVisibility(lstAccount[4].Id, lstAccount[5].Id,lstContentVersion[0].Id, lstProgram[1].Id),
                TestFactory.createDocumentVisibility(lstAccount[4].Id, lstAccount[5].Id,lstContentVersion[0].Id, lstProgram[1].Id),
                TestFactory.createDocumentVisibility(lstAccount[4].Id, lstAccount[5].Id,lstContentVersion[0].Id, lstProgram[1].Id),
                TestFactory.createDocumentVisibility(lstAccount[4].Id, lstAccount[5].Id,lstContentVersion[0].Id, lstProgram[1].Id)
            };
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
            lstPortalUser[0].BypassTrigger__c = 'AP44_CreateSharingForUser;AP59_DeleteOldAccConRelation;AP36_CreateSharingForContact';
            lstPortalUser[1].BypassTrigger__c = 'AP44_CreateSharingForUser;AP59_DeleteOldAccConRelation;AP36_CreateSharingForContact';
            lstPortalUser[2].BypassTrigger__c = 'AP44_CreateSharingForUser;AP59_DeleteOldAccConRelation;AP36_CreateSharingForContact';

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

            for(Request__c req : lstLeadRequests){
                Request__Share requestShare = new Request__Share();
                requestShare.RowCause = 'Manual';
                requestShare.AccessLevel = 'Edit';
                requestShare.ParentId = req.Id;
                requestShare.UserOrGroupId = lstPortalUser[1].Id;
                lstRequestShare.add(requestShare);
            }

            for(Request__c req : lstLeadRequests){
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
    public static void testGetReqQuoteB0(){
        System.runAs(lstPortalUser[1]) {
            Test.startTest();
                Map<String, Object> mapResults = LWC29_AnswerRequests.getRequestDetails(lstProgram[0].Id, lstAccount[5].Id, lstAccount[4].Id, 'Quote');
            Test.stopTest();
            System.assert(mapResults != null);

            List<Request__c> lstRequestAll = (List<Request__c>) mapResults.get('lstRequestAll');

            System.assertEquals(0, lstRequestAll.size());
        }
    }

    @IsTest
    public static void testGetReqLeadB0(){
        System.runAs(lstPortalUser[1]) {
            Test.startTest();
                Map<String, Object> mapResults = LWC29_AnswerRequests.getRequestDetails(lstProgram[0].Id, lstAccount[5].Id, lstAccount[4].Id, 'Lead');
            Test.stopTest();
            System.assert(mapResults != null);

            List<Request__c> lstRequestAll = (List<Request__c>) mapResults.get('lstRequestAll');

            System.assertEquals(0, lstRequestAll.size());
        }
    }

    @IsTest
    public static void testGetReqPlacementB0(){
        System.runAs(lstPortalUser[1]) {
            Test.startTest();
                Map<String, Object> mapResults = LWC29_AnswerRequests.getRequestDetails(lstProgram[0].Id, lstAccount[5].Id, lstAccount[4].Id, 'Placement');
            Test.stopTest();
            System.assert(mapResults != null);

            List<Request__c> lstRequestAll = (List<Request__c>) mapResults.get('lstRequestAll');

            System.assertEquals(0, lstRequestAll.size());
        }
    }

    @IsTest
    public static void testGetReqQuoteB1(){
        System.runAs(lstPortalUser[1]) {
            Test.startTest();
                Map<String, Object> mapResults = LWC29_AnswerRequests.getRequestDetails(lstProgram[1].Id, lstAccount[5].Id, lstAccount[4].Id, 'Quote');
                List<Request__c> lstRequestAll = (List<Request__c>) mapResults.get('lstRequestAll');

                System.assertEquals(4, lstRequestAll.size());
                System.assert(mapResults != null);
            Test.stopTest();
        }
    }

    @IsTest
    public static void testGetReqLeadB1(){
        System.runAs(lstPortalUser[1]) {
            Test.startTest();
                Map<String, Object> mapResults = LWC29_AnswerRequests.getRequestDetails(lstProgram[1].Id, lstAccount[5].Id, lstAccount[4].Id, 'Lead');
            Test.stopTest();
            System.assert(mapResults != null);

            List<Request__c> lstRequestAll = (List<Request__c>) mapResults.get('lstRequestAll');

            System.assertEquals(1, lstRequestAll.size());
        }
    }

    @IsTest
    public static void testGetReqPlacementB1(){
        System.runAs(lstPortalUser[1]) {
            Test.startTest();
                Map<String, Object> mapResults = LWC29_AnswerRequests.getRequestDetails(lstProgram[1].Id, lstAccount[5].Id, lstAccount[4].Id, 'Placement');
                List<Request__c> lstRequestAll = (List<Request__c>) mapResults.get('lstRequestAll');

                System.assertEquals(1, lstRequestAll.size());
                System.assert(mapResults != null);
            Test.stopTest();       
        }
    }

    @IsTest
    public static void testGetReqQuoteR0(){
        System.runAs(lstPortalUser[2]) {
            Test.startTest();
                Map<String, Object> mapResults = LWC29_AnswerRequests.getRequestDetails(lstProgram[0].Id, lstAccount[5].Id, lstAccount[4].Id, 'Quote');
            Test.stopTest();
            System.assert(mapResults != null);

            List<Request__c> lstRequestAll = (List<Request__c>) mapResults.get('lstRequestAll');

            System.assertEquals(0, lstRequestAll.size());
        }
    }

    @IsTest
    public static void testGetReqLeadR0(){
        System.runAs(lstPortalUser[2]) {
            Test.startTest();
                Map<String, Object> mapResults = LWC29_AnswerRequests.getRequestDetails(lstProgram[0].Id, lstAccount[5].Id, lstAccount[4].Id, 'Lead');
            Test.stopTest();
            System.assert(mapResults != null);

            List<Request__c> lstRequestAll = (List<Request__c>) mapResults.get('lstRequestAll');

            System.assertEquals(0, lstRequestAll.size());
        }
    }

    // MRA Sprint 5
    @IsTest
    public static void test_LabelPhaseRequest(){
        System.runAs(lstPortalUser[2]) {
            Test.startTest();
                String result = LWC29_AnswerRequests.LabelPhaseRequest('6');
            Test.stopTest();
            System.assert(result != null);
        }
    }

    @IsTest
    public static void testGetReqPlacementR0(){
        System.runAs(lstPortalUser[2]) {
            Test.startTest();
                Map<String, Object> mapResults = LWC29_AnswerRequests.getRequestDetails(lstProgram[0].Id, lstAccount[5].Id, lstAccount[4].Id, 'Placement');
                List<Request__c> lstRequestAll = (List<Request__c>) mapResults.get('lstRequestAll');
                System.assert(mapResults != null);
            Test.stopTest();
        }
    }

    @IsTest
    public static void testGetReqQuoteR1(){
        System.runAs(lstPortalUser[1]) {
            Test.startTest();
                Map<String, Object> mapResults = LWC29_AnswerRequests.getRequestDetails(lstProgram[1].Id, lstAccount[5].Id, lstAccount[4].Id, 'Quote');
            Test.stopTest();
            System.assert(mapResults != null);

            List<Request__c> lstRequestAll = (List<Request__c>) mapResults.get('lstRequestAll');

            System.assertEquals(4, lstRequestAll.size());
        }
    }

    @IsTest
    public static void testGetReqLeadR1(){
        System.runAs(lstPortalUser[1]) {
            Test.startTest();
                Map<String, Object> mapResults = LWC29_AnswerRequests.getRequestDetails(lstProgram[1].Id, lstAccount[5].Id, lstAccount[4].Id, 'Lead');
            Test.stopTest();
            System.assert(mapResults != null);

            List<Request__c> lstRequestAll = (List<Request__c>) mapResults.get('lstRequestAll');

            System.assertEquals(1, lstRequestAll.size());
        }
    }

    @IsTest
    public static void testGetReqPlacementR1(){
        System.runAs(lstPortalUser[1]) {
            Test.startTest();
                Map<String, Object> mapResults = LWC29_AnswerRequests.getRequestDetails(lstProgram[1].Id, lstAccount[5].Id, lstAccount[4].Id, 'Placement');

                List<Request__c> lstRequestAll = (List<Request__c>) mapResults.get('lstRequestAll');

                System.assertEquals(1, lstRequestAll.size());
                System.assert(mapResults != null);
            Test.stopTest();
        }
    }

    @IsTest
    public static void testSendQuoteTrue(){
        List<DocumentVisibility__c> lstDocQuote = new List<DocumentVisibility__c>();
        System.runAs(lstPortalUser[2]) {
            for (Integer i = 0; i< lstDocumentVisibility.size();i++){
                lstDocumentVisibility[i].Tech_Phase__c = '1';
                lstDocumentVisibility[i].Tech_IsExternal__c = true;
                lstDocQuote.add(lstDocumentVisibility[i]);
            }
            update lstDocQuote;
            Test.startTest();
                lstRequests[0].Quote__c = '1';
                lstRequests[1].Quote__c = '2';
                Date quotedeadLine = Date.today();
                Map<String, Object> mapResults = LWC29_AnswerRequests.saveRequestRecord(lstRequests, 'Quote', lstRequests, 'Send', quotedeadLine, true, lstRequests[0].Id, true);
            Test.stopTest();
            //System.assertEquals(null, mapResults.get('Error'));
            //System.assertEquals('Success', mapResults.get('Success'));

            for(Request__c req : [SELECT Id, Name, ReinsurerStatus__c FROM Request__c WHERE Id = :lstRequests[0].Id]){
                System.assertEquals(AP_Constant.statusAnswered, req.ReinsurerStatus__c);
            }

            for(Request__c req : [SELECT Id, Name, ReinsurerStatus__c FROM Request__c WHERE Id = :lstRequests[1].Id]){
                System.assertEquals(AP_Constant.statusRefused, req.ReinsurerStatus__c);
            }
        }
    }
    
    @IsTest
    public static void testSendLeadTrue(){
        System.runAs(lstPortalUser[2]) {
            List<DocumentVisibility__c> lstDocLead = new List<DocumentVisibility__c>();
            for (Integer i = 0; i< lstDocumentVisibility.size();i++){
                lstDocumentVisibility[i].Tech_Phase__c = '3';
                lstDocumentVisibility[i].Tech_IsExternal__c = true;
                lstDocLead.add(lstDocumentVisibility[i]);
            }
            update lstDocLead;
            Test.startTest();
                for(Request__c req : lstLeadRequests){
                    req.Accept__c = true;
                }
                Date quotedeadLine = Date.today();
                Map<String, Object> mapResults = LWC29_AnswerRequests.saveRequestRecord(lstLeadRequests, 'Lead', lstLeadRequests, 'Send', quotedeadLine, true, lstRequests[0].Id, true);
            Test.stopTest();
            //System.assertEquals(null, mapResults.get('Error'));
            //System.assertEquals('Success', mapResults.get('Success'));

            for(Request__c req : [SELECT Id, Name, ReinsurerStatus__c FROM Request__c WHERE Id = :lstLeadRequests]){
                System.assertEquals(AP_Constant.statusAnswered, req.ReinsurerStatus__c);
            }
        }
    }
    

    @IsTest
    public static void testSendPlacement(){
        System.runAs(lstPortalUser[2]) {
            List<DocumentVisibility__c> lstDocPlacement= new List<DocumentVisibility__c>();
            for (Integer i = 0; i< lstDocumentVisibility.size();i++){
                lstDocumentVisibility[i].Tech_Phase__c = '2';
                lstDocumentVisibility[i].Tech_IsExternal__c = true;
                lstDocPlacement.add(lstDocumentVisibility[i]);
            }
            update lstDocPlacement;
            Test.startTest();
                lstRequests[2].PlacementParticipation__c = '1';
                lstRequests[3].PlacementParticipation__c = '2';
                Date quotedeadLine = Date.today();
                
                Map<String, Object> mapResults = LWC29_AnswerRequests.saveRequestRecord(lstRequests, 'Placement', lstRequests, 'Send', quotedeadLine, true, lstRequests[0].Id, true);
            Test.stopTest();
            //System.assertEquals(null, mapResults.get('Error'));
            //System.assertEquals('Success', mapResults.get('Success'));

            for(Request__c req : [SELECT Id, Name, ReinsurerStatus__c FROM Request__c WHERE Id = :lstRequests[2].Id]){
                System.assertEquals(AP_Constant.statusAnswered, req.ReinsurerStatus__c);
            }

            for(Request__c req : [SELECT Id, Name, ReinsurerStatus__c FROM Request__c WHERE Id = :lstRequests[3].Id]){
                System.assertEquals(AP_Constant.statusRefused, req.ReinsurerStatus__c);
            }
        }
    }

    @IsTest
    public static void testSaveQuoteTrue(){
        System.runAs(lstPortalUser[2]) {
            Test.startTest();
                lstRequests[0].Quote__c = '1';
                lstRequests[1].Quote__c = '2';
                Date quotedeadLine = Date.today();
                
                Map<String, Object> mapResults = LWC29_AnswerRequests.saveRequestRecord(lstRequests, 'Quote', lstRequests, 'Save',quotedeadLine, true, lstRequests[0].Id, true);
            Test.stopTest();
            //System.assertEquals(null, mapResults.get('Error'));
            //System.assertEquals('Success', mapResults.get('Success'));

            for(Request__c req : [SELECT Id, Name, ReinsurerStatus__c FROM Request__c WHERE Id = :lstRequests[2].Id]){
                System.assertEquals(AP_Constant.statusSent, req.ReinsurerStatus__c);
            }

            for(Request__c req : [SELECT Id, Name, ReinsurerStatus__c FROM Request__c WHERE Id = :lstRequests[3].Id]){
                System.assertEquals(AP_Constant.statusSent, req.ReinsurerStatus__c);
            }
        }
    }

    @IsTest
    public static void testSaveLeadTrue(){
        System.runAs(lstPortalUser[2]) {
            Test.startTest();
                for(Request__c req : lstLeadRequests){
                    req.Accept__c = true;
                }
                Date quotedeadLine = Date.today();
                Map<String, Object> mapResults = LWC29_AnswerRequests.saveRequestRecord(lstLeadRequests, 'Lead', lstLeadRequests, 'Save', quotedeadLine, true, lstRequests[0].Id, true);
            Test.stopTest();
            //System.assertEquals(null, mapResults.get('Error'));
            //System.assertEquals('Success', mapResults.get('Success'));

            for(Request__c req : [SELECT Id, Name, ReinsurerStatus__c FROM Request__c WHERE Id = :lstLeadRequests]){
                System.assertEquals(AP_Constant.statusSent, req.ReinsurerStatus__c);
            }
        }
    }

    @IsTest
    public static void testSavePlacement(){
        System.runAs(lstPortalUser[2]) {
            Test.startTest();
                lstRequests[2].PlacementParticipation__c = '1';
                lstRequests[3].PlacementParticipation__c = '2';
                Date quotedeadLine = Date.today();
                Map<String, Object> mapResults = LWC29_AnswerRequests.saveRequestRecord(lstRequests, 'Placement', lstRequests, 'Save', quotedeadLine, true, lstRequests[0].Id, true);
            Test.stopTest();
            //System.assertEquals(null, mapResults.get('Error'));
            //System.assertEquals('Success', mapResults.get('Success'));

            for(Request__c req : [SELECT Id, Name, ReinsurerStatus__c FROM Request__c WHERE Id = :lstRequests[2].Id]){
                System.assertEquals(AP_Constant.statusSent, req.ReinsurerStatus__c);
            }

            for(Request__c req : [SELECT Id, Name, ReinsurerStatus__c FROM Request__c WHERE Id = :lstRequests[3].Id]){
                System.assertEquals(AP_Constant.statusSent, req.ReinsurerStatus__c);
            }
        }
    }

    @IsTest
    public static void testMail1(){
        System.runAs(lstPortalUser[2]) {
            Test.startTest();
                List<Request__c> lstParentReq = new List<Request__c>();
                List<Request__c> lstQuoteReq = new List<Request__c>{lstRequests[0]};
                Map<String, Object> mapResults = LWC29_AnswerRequests.sendMail(lstQuoteReq, 'Quote', null, lstAccount[5].Id, lstAccount[4].Id, lstParentReq);
            Test.stopTest();
            //System.assertEquals(null, mapResults.get('Error'));
            //System.assertEquals('Success', mapResults.get('Success'));
        }
    }

    @IsTest
    public static void testMail2(){
        System.runAs(lstPortalUser[2]) {
            Test.startTest();
                List<Request__c> lstParentReq = new List<Request__c>();
                List<Request__c> lstPlacementReq = new List<Request__c>{lstRequests[4], lstRequests[5]};
                Map<String, Object> mapResults = LWC29_AnswerRequests.sendMail(lstPlacementReq, 'Placement', lstRequests[4], lstAccount[5].Id, lstAccount[4].Id, lstPlacementReq);
            Test.stopTest();
            //System.assertEquals(null, mapResults.get('Error'));
            //System.assertEquals('Success', mapResults.get('Success'));
        }
    }

    @IsTest
    public static void testMail3(){
        System.runAs(lstPortalUser[2]) {
            Test.startTest();
                Map<String, Object> mapResults = LWC29_AnswerRequests.sendMail(lstChildLeadRequests, 'Lead', lstLeadRequests[1], lstAccount[5].Id, lstAccount[4].Id, lstLeadRequests);
            Test.stopTest();
            //System.assertEquals(null, mapResults.get('Error'));
            //System.assertEquals('Success', mapResults.get('Success'));
        }
    }

    @IsTest
    public static void testGetPlacementRT(){
        System.runAs(testUserAdmin) {
            Test.startTest();
                String result = LWC29_AnswerRequests.getPlacementRequestRecordTypeId('Quote');
            Test.stopTest();
            System.assertNotEquals(null, result);
        }
    }
    
}