@IsTest
public with sharing class LWC32_SignForPool_TEST {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Test class for LWC32_SignForPool
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
    static User testUserValidator;
    static User assignedToUser;
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
    static Map<String, Id> mapRecTypeIdRequest = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectRequest});
    static Map<String, Id> mapAccountRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectAcc});
    static Map<String, Id> mapSARecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectSpecialAcceptance});
    static List<ContentVersion> lstContentVersion;
    static List<ContentDocumentLink> lstContentDocumentLink;
    static Map<String, Id> mapRecTypeId;
    static String fileContent = 'This is an example.';
    static Blob fileContentInBlob = Blob.valueOf(fileContent);

    static {
        //create User
        testUserAdmin = TestFactory.createUserWithRole('testUserAdmin', TestFactory.getProfileAdminId(), TestFactory.getCERoleId());
        testUserCE = TestFactory.createUser('testUserCE', TestFactory.getProfileCEId());
        testUserValidator = TestFactory.createUser('testUserCE', TestFactory.getProfileCEId());
        assignedToUser = TestFactory.createUserWithRole('TestAssignedTo', TestFactory.getProfileAdminId(), TestFactory.getHeadUGPRoleId());

        lstUsers.add(testUserAdmin);
        lstUsers.add(testUserCE);
        lstUsers.add(testUserValidator);
        lstUsers.add(assignedToUser);

        lstUsers[0].BypassTrigger__c = 'AP44_CreateSharingForUser;AP59_DeleteOldAccConRelation';
        lstUsers[1].BypassTrigger__c = 'AP44_CreateSharingForUser;AP59_DeleteOldAccConRelation';
        lstUsers[2].BypassTrigger__c = 'AP44_CreateSharingForUser;AP59_DeleteOldAccConRelation';
        insert lstUsers;

        System.runAs(testUserAdmin) {
            Map<String, Id> mapRequestRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{
                    AP_Constant.sObjectRequest
            });

            //create Account
            lstAccount = new List<Account>{
                    TestFactory.createAccount(mapAccountRecTypeId.get(AP_Constant.accRTPrincipalCedingCom), 'Account A', 'C_0001'),
                    TestFactory.createAccount(mapAccountRecTypeId.get(AP_Constant.accRTPrincipalCedingCom), 'Account B', 'C_0002'),
                    TestFactory.createAccount(mapAccountRecTypeId.get(AP_Constant.accRTCoveredCedingCompany), 'Account C', 'C_0003'),
                    TestFactory.createAccount(mapAccountRecTypeId.get(AP_Constant.accRTCoveredCedingCompany), 'Account D', 'C_0004'),
                    TestFactory.createAccount(mapAccountRecTypeId.get(AP_Constant.accRTBroker), 'Account E', 'C_0005'),
                    TestFactory.createAccount(mapAccountRecTypeId.get(AP_Constant.accRTReinsurer), 'Account F', 'C_0006'),
                    TestFactory.createAccount(mapAccountRecTypeId.get(AP_Constant.accRTBroker), 'Broker A', 'C_0007'),
                    TestFactory.createAccount(mapAccountRecTypeId.get(AP_Constant.accRTReinsurer), 'Reinsurer A', 'C_0009')
            };
            lstAccount[5].IsRiskCarrier__c = true;
            lstAccount[5].IsFinancialEntity__c = true;
            insert lstAccount;

            lstAccount[0].EmailSA__c = 'test@test.com;test2@test.com';
            lstAccount[1].EmailSA__c = 'test@test.com;test2@test.com';
            lstAccount[0].EmailPCLife__c = 'test@test.com;test2@test.com';
            lstAccount[1].EmailPCLife__c = 'test@test.com;test2@test.com';
            update lstAccount;

            //create Ceding Portal Contact + Broker/Reinsurer Contact
            lstContact = new List<Contact>{
                    TestFactory.createContact('Account E - Covered Ceding', 'CedingPortal', lstAccount[6].Id, '2', '25009'),
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

            for (Contact con : lstContact) {
                AccountContactRelation accCon = new AccountContactRelation();
                accCon.ContactId = con.Id;
                accCon.AccountId = lstAccount[0].Id;
                accCon.Roles = 'PrincipalCedingCompany';
                accCon.IsActive = true;
                lstAccConToInsert.add(accCon);
            }

            if (lstAccConToInsert.size() > 0) {
                insert lstAccConToInsert;
            }

            List<AccountContactRelation> lstAccCon = [
                    SELECT Id, AccountId, Account.RecordTypeId
                            , Contact.Account.RecordTypeId, Roles
                            , ContactId, Contact.MacroLoB__c
                            , Contact.Nature__c, IsDirect
                    FROM AccountContactRelation
            ];

            for (AccountContactRelation accCon : lstAccCon) {
                accCon.IsActive = true;

                if (accCon.AccountId == lstAccount[4].Id) {
                    accCon.Roles = 'Broker';
                } else if (accCon.AccountId == lstAccount[5].Id) {
                    accCon.Roles = 'RiskCarrier';
                } else if (accCon.AccountId == lstAccount[0].Id) {
                    accCon.Roles = 'PrincipalCedingCompany';
                }
            }
            update lstAccCon;

            List<AccountShare> lstAccShare = new List<AccountShare>();

            //Create Account Share for CE User - testUserCE
            for (Account acc : lstAccount) {
                AccountShare accShare = new AccountShare();
                accShare.UserOrGroupId = testUserCE.Id;
                accShare.AccountId = acc.Id;
                accShare.AccountAccessLevel = 'Edit';
                accShare.OpportunityAccessLevel = 'Edit';
                lstAccShare.add(accShare);
            }

            if (lstAccShare.size() > 0) {
                insert lstAccShare;
            }
        }

        System.runAs(testUserCE) {
            //create Pool
            lstPool = new List<Pool__c>{
                    TestFactory.createPool('Pool A', 78, '2020', assignedToUser.Id),
                    TestFactory.createPool('Pool B', 78, '2020', assignedToUser.Id)
            };

            lstPool[0].SA_Email__c = 'test@test.com';
            lstPool[1].SA_Email__c = 'test@test.com';
            insert lstPool;

            //create Program
            lstProgram = new List<Program__c>{
                    TestFactory.createProgram('TestProg1', '1', '1'
                            , Date.today(), Date.today().addYears(1), '2', Date.today(), Date.today().addYears(1)
                            , '2020', lstAccount[0].Id, '23002', '2'
                            , '25009'),


                    TestFactory.createProgram('TestProg2', '1', '1'
                            , Date.today(), Date.today().addYears(1), '2', Date.today(), Date.today().addYears(1)
                            , '2020', lstAccount[0].Id, '23002', '2'
                            , '25009')
            };

            lstProgram[0].TECH_StageName__c = 'Signing';
            lstProgram[1].TECH_StageName__c = 'Signing';
            lstProgram[1].LossDepositLevel__c = 'Treaty';
            insert lstProgram;

            lstProgram[1].RenewedFromProgram__c =  lstProgram[0].Id;
            lstProgram[1].TypeOfRenew__c = 'LTA/TR Identical Renew';
            update lstProgram;

            lstCovCedCom = new List<CoveredCedingCompany__c>{
                    TestFactory.createCovCedCom(lstAccount[2].Id, lstProgram[0].Id, true, null
                            , false, null, false, null, null),

                    TestFactory.createCovCedCom(lstAccount[3].Id, lstProgram[0].Id, true, null
                            , false, null, false, null, null),

                    TestFactory.createCovCedCom(lstAccount[3].Id, lstProgram[1].Id, true, null
                            , false, null, false, null, null)
            };
            insert lstCovCedCom;

            //create Treaty
            lstTreaty = new List<Treaty__c>{
                    TestFactory.createTreaty('TestTreaty1', 1, '2020-00000222/1', '2'
                            , lstProgram[0].Id, '1', 34, '45', '2020-00000222/1', '1', '2', '2', '2', '2'),

                    TestFactory.createTreaty('TestTreaty2', 1, '2020-00000222/1', '2'
                            , lstProgram[0].Id, '1', 34, '45', '2020-00000222/1', '1', '2', '2', '2', '2'),

                    TestFactory.createTreaty('TestTreaty3', 1, '2020-00000222/1', '2'
                            , lstProgram[1].Id, '1', 34, '45', '2020-00000222/1', '1', '2', '2', '2', '2'),

                    TestFactory.createTreaty('TestTreaty4', 1, '2020-00000222/1', '3'
                            , lstProgram[1].Id, '1', 34, '10', '2020-00000222/1', '1', '2', '2', '2', '2'),

                    TestFactory.createTreaty('TestTreaty5', 1, '2020-00000222/1', '4'
                            , lstProgram[1].Id, '1', 34, '20', '2020-00000222/1', '1', '2', '2', '2', '2')
            };

            lstTreaty[2].PremiumDeposit__c = 'No';
            lstTreaty[3].PremiumDeposit__c = 'Yes';
            insert lstTreaty;
            lstTreaty[0].WebXLReference__c = '020-00000222/1';
            lstTreaty[1].WebXLReference__c = '020-00000222/1';
            lstTreaty[2].WebXLReference__c = '020-00000222/1';
            lstTreaty[3].WebXLReference__c = '020-00000222/1';
            lstTreaty[4].WebXLReference__c = '020-00000222/1';
            update lstTreaty;

            //create Section
            lstSection = new List<Section__c>{
                    TestFactory.createSection('TestSection1', '1.1', '22003', '20006', '9052'
                            , 322, 34, lstProgram[0].Id, lstTreaty[0].Id, '2', '1'
                            , true, '2', null, '23001', '1', '5', '2', '2'),

                    TestFactory.createSection('TestSection2', '2.1', '22003', '20006', '9052'
                            , 23, 5, lstProgram[1].Id, lstTreaty[2].Id, '2', '1'
                            , false, '2', null, '23001', '1', '5', '2', '2'),

                    TestFactory.createSection('TestSection3', '2.1', '22003', '20006', '9052'
                            , 23, 5, lstProgram[1].Id, lstTreaty[3].Id, '3', '1'
                            , false, '6', null, '23001', '1', '5', '2', '2'),

                    TestFactory.createSection('TestSection4', '2.1', '22003', '20006', '9052'
                            , 23, 5, lstProgram[1].Id, lstTreaty[2].Id, '2', '1'
                            , false, '10', null, '23001', '1', '5', '2', '2'),

                    TestFactory.createSection('TestSection5', '2.1', '22003', '20006', '9052'
                            , 23, 5, lstProgram[1].Id, lstTreaty[2].Id, '2', '1'
                            , false, '3', null, '23001', '1', '5', '2', '2'),

                    TestFactory.createSection('TestSection6', '2.1', '22003', '20006', '9052'
                            , 23, 5, lstProgram[1].Id, lstTreaty[2].Id, '2', '1'
                            , false, '1', null, '23001', '1', '5', '2', '2'),

                    TestFactory.createSection('TestSection7', '2.1', '22003', '20006', '9052'
                            , 23, 5, lstProgram[1].Id, lstTreaty[2].Id, '2', '1'
                            , false, '8', null, '23001', '1', '5', '2', '2'),

                    TestFactory.createSection('TestSection8', '2.1', '22003', '20006', '9052'
                            , 23, 5, lstProgram[1].Id, lstTreaty[2].Id, '2', '1'
                            , false, '4', null, '23001', '1', '5', '2', '2'),

                    TestFactory.createSection('TestSection9', '2.1', '22003', '20006', '9052'
                            , 23, 5, lstProgram[1].Id, lstTreaty[4].Id, '4', '1'
                            , false, '5', null, '23001', '1', '5', '2', '2')
            };

            for(Section__c section : lstSection){
                section.TotalEPI__c = 50;
                section.Cession_Perc__c = 50;
            }
            insert lstSection;

            //create Pool Treaty Section
            lstPoolTreatySections = new List<PoolTreatySection__c>{
                    TestFactory.createPoolTreatySection(lstPool[0].Id, lstTreaty[2].Id, null
                            , false, true, 32, null),

                    TestFactory.createPoolTreatySection(lstPool[1].Id, lstTreaty[2].Id, null
                            , false, true, 40, null)
            };
            insert lstPoolTreatySections;

            //create ContentVersion
            lstContentVersion = new List<ContentVersion>{
                    TestFactory.createContentVersion('2','1'
                            , '5', 'CV1', fileContentInBlob, 'CV1'),
                    TestFactory.createContentVersion('2','1'
                            , '5', 'CV2', fileContentInBlob, 'CV2'),
                    TestFactory.createContentVersion('2','1'
                            , '5', 'CV3', fileContentInBlob, 'CV3')
            };
            lstContentVersion[2].IsExternal__c = true;
            insert lstContentVersion;

            ContentVersion contentVersionReplace = new ContentVersion(GroupType__c = '1', DocumentType__c = '3',Phase__c = '3', VersionData = lstContentVersion[0].VersionData
                    , ContentDocumentId = lstContentVersion[0].ContentDocumentId, PathOnClient ='VCV4', Title = 'CV4');
            insert contentVersionReplace;

            lstContentVersion.add(contentVersionReplace);

            List<Id> lstContentVersionId = new List<Id>();
            for(ContentVersion contentVersion : lstContentVersion){
                lstContentVersionId.add(contentVersion.Id);
            }

            lstContentVersion = [SELECT Id, ContentDocumentId, DocumentType__c, GroupType__c, Phase__c, Title, VersionData, VersionNumber FROM ContentVersion WHERE Id IN :lstContentVersionId];

            lstContentDocumentLink = new List<ContentDocumentLink>{
                    TestFactory.createContentDocumentLink(lstContentVersion[0].ContentDocumentId, lstProgram[0].Id, 'V'),
                    TestFactory.createContentDocumentLink(lstContentVersion[2].ContentDocumentId, lstProgram[1].Id, 'V')
            };
            insert lstContentDocumentLink;

            //create Request
            lstRequests = new List<Request__c>{
                    TestFactory.createRequest(lstProgram[1].Id, lstTreaty[2].Id, lstAccount[4].Id, lstAccount[5].Id, '1', '3',
                            mapRecTypeIdRequest.get(AP_Constant.reqRTQuote), '2', 'Setup', lstSection[1].Id),

                    TestFactory.createRequest(lstProgram[1].Id, lstTreaty[2].Id, lstAccount[4].Id, lstAccount[5].Id, '2', '1',
                            mapRecTypeIdRequest.get(AP_Constant.reqRTQuote), '2', 'Setup', lstSection[1].Id),

                    TestFactory.createRequest(lstProgram[1].Id, lstTreaty[2].Id, lstAccount[4].Id, lstAccount[5].Id, '1', '3',
                            mapRecTypeIdRequest.get(AP_Constant.reqRTPlacement), '2', 'Setup', lstSection[1].Id),

                    TestFactory.createRequest(lstProgram[1].Id, lstTreaty[2].Id, lstAccount[4].Id, lstAccount[5].Id, '2', '1',
                            mapRecTypeIdRequest.get(AP_Constant.reqRTPlacement), '2', 'Sent', lstSection[1].Id),

                    TestFactory.createRequest(lstProgram[1].Id, lstTreaty[2].Id, lstAccount[4].Id, lstAccount[5].Id, '1', '3',
                            mapRecTypeIdRequest.get(AP_Constant.reqRTSigning), '2', 'Setup', lstSection[1].Id),

                    TestFactory.createRequest(lstProgram[1].Id, lstTreaty[2].Id, lstAccount[4].Id, lstAccount[5].Id, '2', '1',
                            mapRecTypeIdRequest.get(AP_Constant.reqRTSigning), '2', 'Sent', lstSection[1].Id),

                    TestFactory.createRequest(lstProgram[1].Id, lstTreaty[2].Id, null, lstAccount[5].Id, '2', '1',
                            mapRecTypeIdRequest.get(AP_Constant.reqRTSigning), '2', 'Sent', lstSection[1].Id),

                    TestFactory.createRequest(lstProgram[1].Id, lstTreaty[2].Id, null, null, '2', '1',
                            mapRecTypeIdRequest.get(AP_Constant.reqRTSigning), '2', 'Sent', lstSection[1].Id),

                    TestFactory.createRequest(lstProgram[1].Id, lstTreaty[2].Id, lstAccount[4].Id, lstAccount[7].Id, '2', '1',
                            mapRecTypeIdRequest.get(AP_Constant.reqRTPlacement), '2', 'Sent', lstSection[1].Id),

                    TestFactory.createRequest(lstProgram[1].Id, lstTreaty[3].Id, null, lstAccount[7].Id, '2', '1',
                            mapRecTypeIdRequest.get(AP_Constant.reqRTSigning), '2', 'Sent', lstSection[2].Id)
            };
            insert lstRequests;

            for(Request__c req : lstRequests){
                if(req.ReinsurerStatus__c != 'Setup'){
                    req.LastVersionSent__c = true;
                    req.LastVersionAnswered__c = true;
                    req.VersionMinor__c = 2;
                }

                req.BrokerStatus__c = '2';
                req.RiskCarrier__c = lstAccount[5].Id;
                req.FinancialEntity__c = lstAccount[5].Id;
            }

            lstRequests[3].ReinsurerStatus__c = 'Answered';
            lstRequests[5].OriginalRequest__c = lstRequests[4].Id;
            lstRequests[7].Pool__c = lstPool[0].Id;
            update lstRequests;

            //create lead
            lstLeadRequests = new List<Request__c>{
                    // recordTypeId + status required
                    TestFactory.createLeadRequest(lstProgram[1].Id, lstTreaty[2].Id, lstAccount[4].Id, lstAccount[5].Id, '1', '4',
                            mapRecTypeIdRequest.get(AP_Constant.reqRTLead), '2', 'Sent',lstSection[3].Id),

                    TestFactory.createLeadRequest(lstProgram[1].Id, lstTreaty[2].Id, lstAccount[4].Id, lstAccount[5].Id, '2', '4',
                            mapRecTypeIdRequest.get(AP_Constant.reqRTLead), '2', 'Sent',lstSection[1].Id),

                    TestFactory.createLeadRequest(lstProgram[1].Id, lstTreaty[3].Id, lstAccount[4].Id, lstAccount[5].Id, '2', '4',
                            mapRecTypeIdRequest.get(AP_Constant.reqRTLead), '2', 'Sent',lstSection[2].Id),

                    TestFactory.createLeadRequest(lstProgram[1].Id, lstTreaty[2].Id, lstAccount[4].Id, lstAccount[5].Id, '2', '4',
                            mapRecTypeIdRequest.get(AP_Constant.reqRTLead), '2', 'Setup',lstSection[4].Id),

                    TestFactory.createLeadRequest(lstProgram[1].Id, lstTreaty[2].Id, lstAccount[4].Id, lstAccount[5].Id, '2', '4',
                            mapRecTypeIdRequest.get(AP_Constant.reqRTLead), '2', 'Setup',lstSection[5].Id),

                    TestFactory.createLeadRequest(lstProgram[1].Id, lstTreaty[2].Id, lstAccount[4].Id, lstAccount[5].Id, '2', '4',
                            mapRecTypeIdRequest.get(AP_Constant.reqRTLead), '2', 'Setup',lstSection[6].Id),

                    TestFactory.createLeadRequest(lstProgram[1].Id, lstTreaty[2].Id, lstAccount[4].Id, lstAccount[5].Id, '2', '4',
                            mapRecTypeIdRequest.get(AP_Constant.reqRTLead), '2', 'Setup',lstSection[7].Id),

                    TestFactory.createLeadRequest(lstProgram[1].Id, lstTreaty[4].Id, lstAccount[4].Id, lstAccount[5].Id, '2', '4',
                            mapRecTypeIdRequest.get(AP_Constant.reqRTLead), '2', 'Setup',lstSection[8].Id)
            };

            for(Request__c leadReq : lstLeadRequests){
                if(leadReq.ReinsurerStatus__c != 'Setup'){
                    leadReq.LastVersionSent__c = true;
                    leadReq.LastVersionAnswered__c = true;
                    leadReq.VersionMinor__c = 2;
                }

                leadReq.CededPremium__c = 20;
                leadReq.PerHeadPremium__c = 50;
                leadReq.MinRate__c = 50;
                leadReq.FixedRate__c = 50;
                leadReq.FlatPremium__c = 50;
                leadReq.MinPerHeadAmount__c = 50;
                leadReq.MDP__c = 50;
            }

            lstLeadRequests[1].OriginalRequest__c = lstLeadRequests[0].Id;
            lstLeadRequests[1].Accept__c = true;
            lstLeadRequests[2].Accept__c = true;
            update lstLeadRequests;

            lstChildLeadRequests = [SELECT Id, Name, ReinsurerStatus__c,LastVersionSent__c, LastVersionAnswered__c
                    , VersionMinor__c, Accept__c, Reinsurer__c, Broker__c, TECH_PhaseType__c
            FROM Request__c
            WHERE Reinsurer__c = NULL
            AND RecordTypeId = :mapRecTypeIdRequest.get(AP_Constant.reqRTLead)];


            for(Request__c leadReq : lstChildLeadRequests){
                if(leadReq.ReinsurerStatus__c != 'Setup'){
                    leadReq.LastVersionSent__c = true;
                    leadReq.LastVersionAnswered__c = true;
                    leadReq.VersionMinor__c = 2;
                }

                leadReq.CededPremium__c = 20;
                leadReq.PerHeadPremium__c = 50;
                leadReq.MinRate__c = 50;
                leadReq.FixedRate__c = 50;
                leadReq.FlatPremium__c = 50;
                leadReq.MinPerHeadAmount__c = 50;
            }
            update lstChildLeadRequests;
        }
    }

    @IsTest
    public static void testGetProgramName(){
        System.runAs(testUserCE) {
            Test.startTest();
                String result = LWC32_SignForPool.getProgramName(lstProgram[0].Id);
            Test.stopTest();
            System.assert(result != null);
            System.assertEquals('TestProg1', result);
        }
    }

    @IsTest
    public static void testGetDocuments(){
        System.runAs(testUserCE) {
            Test.startTest();
            Map<String, Object> result = LWC32_SignForPool.getDocuments(lstProgram[0].Id);
            Test.stopTest();
            System.assert(result != null);
        }
    }

    @IsTest
    public static void testGetLeadRequestDetails(){
        System.runAs(testUserCE) {
            Test.startTest();
                Map<String,Object> result = LWC32_SignForPool.getLeadRequestDetails(lstProgram[1].Id, lstPool[0].Id);
            Test.stopTest();
            System.assert(result != null);
        }
    }

    @IsTest
    public static void testGetSigningDetails(){
        System.runAs(testUserCE) {
            Test.startTest();
                List <Request__c> result = LWC32_SignForPool.getSigningReqDetails(lstPool[0].Id, lstProgram[1].Id);
            Test.stopTest();
            System.assert(result != null);
            System.assertEquals(1, result.size());
        }
    }

    @IsTest
    public static void testGetBtnVisibility(){
        System.runAs(testUserCE) {
            Test.startTest();
                Boolean result = LWC32_SignForPool.getButtonVisibility(lstRequests);
            Test.stopTest();
            System.assert(true, result);
        }
    }

    @IsTest
    public static void testGetBtnVisibilityUGP(){
        System.runAs(assignedToUser) {
            Test.startTest();
                Boolean result = LWC32_SignForPool.getButtonVisibility(lstRequests);
            Test.stopTest();
            System.assert(true, result);
        }
    }

    @IsTest
    public static void testSignPools(){
        System.runAs(assignedToUser) {
            Test.startTest();
                List<Request__c> lstSigningReq = new List<Request__c>{lstRequests[4], lstRequests[5], lstRequests[6], lstRequests[7], lstRequests[9]};
                Map<String, Object> result = LWC32_SignForPool.signPools(lstSigningReq);
            Test.stopTest();
            System.assert(result != null);
            //System.assertEquals(null, result.get('Error'));

            for(Request__c req : [SELECT Id, Name, ReinsurerStatus__c, TECH_DateSigned__c, ResponseDate__c FROM Request__c WHERE Id = :lstSigningReq]){
                System.assertEquals(AP_Constant.statusSigned, req.ReinsurerStatus__c);   
                System.assertEquals(System.today(), req.TECH_DateSigned__c);   
                System.assertEquals(System.today(), req.ResponseDate__c);   
            }
        }
    }
}