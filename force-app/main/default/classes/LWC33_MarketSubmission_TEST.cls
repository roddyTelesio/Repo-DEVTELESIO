@IsTest
public with sharing class LWC33_MarketSubmission_TEST {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Test class for LWC33_MarketSubmission
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 12-MAR-2021  NBI   1.0      Initial version
-- 25-MAY-2021  MBE   1.1      W-0974 - Bug bloquant Prod - Impossibilité de créer une Lead request - TECH_Actor2Id__c
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
    static Map<String, Id> mapRecTypeIdRequest = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectRequest});
    static Map<String, Id> mapAccountRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectAcc});
    static Map<String, Id> mapSARecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectSpecialAcceptance});
    static Map<String, Id> mapContactRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectContact});

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
            lstAccount[5].IsRiskCarrier__c = true;
            lstAccount[5].IsFinancialEntity__c = true;
            insert lstAccount;

            lstAccount[0].EmailSA__c = 'test@test.com;test2@test.com';
            lstAccount[1].EmailSA__c = 'test@test.com;test2@test.com';
            lstAccount[0].EmailPCLife__c = 'test@test.com;test2@test.com';
            lstAccount[1].EmailPCLife__c = 'test@test.com;test2@test.com';
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
                    TestFactory.createTreaty('TestTreaty1', 1, '2020-00000222/1', '3'
                            , lstProgram[0].Id, '2', 34, '10', '2020-00000222/1', '1', '2', '2', '2', '2'),

                    TestFactory.createTreaty('TestTreaty2', 2, '2020-00000222/1', '2', lstProgram[0].Id
                            , '1', 44, '44', '2020-00000222/1', '2', '2', '2', '2', '2'),

                    TestFactory.createTreaty('TestTreaty3', 3, '2020-00000222/1', '2'
                            , lstProgram[1].Id, '2', 89, '44', '2020-00000222/1', '3', '2', '2', '2', '2'),

                    TestFactory.createTreaty('TestTreaty4', 3, '2020-00000222/1', '3'
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
                    TestFactory.createRequest(lstProgram[0].Id, lstTreaty[0].Id, lstAccount[4].Id, lstAccount[5].Id, '1', '3',
                            mapRecTypeIdRequest.get(AP_Constant.reqRTQuote), '2', 'Setup', lstSection[0].Id),

                    TestFactory.createRequest(lstProgram[1].Id, lstTreaty[2].Id, lstAccount[4].Id, lstAccount[5].Id, '2', '1',
                            mapRecTypeIdRequest.get(AP_Constant.reqRTQuote), '2', 'Setup', lstSection[1].Id),

                    TestFactory.createRequest(lstProgram[0].Id, lstTreaty[0].Id, lstAccount[4].Id, lstAccount[5].Id, '1', '3',
                            mapRecTypeIdRequest.get(AP_Constant.reqRTPlacement), '2', 'Setup', lstSection[0].Id),

                    TestFactory.createRequest(lstProgram[1].Id, lstTreaty[2].Id, lstAccount[4].Id, lstAccount[5].Id, '2', '1',
                            mapRecTypeIdRequest.get(AP_Constant.reqRTPlacement), '2', 'Setup', lstSection[0].Id),

                    TestFactory.createRequest(lstProgram[0].Id, lstTreaty[0].Id, lstAccount[4].Id, lstAccount[5].Id, '1', '3',
                            mapRecTypeIdRequest.get(AP_Constant.reqRTSigning), '2', 'Sent', lstSection[0].Id),

                    TestFactory.createRequest(lstProgram[1].Id, lstTreaty[2].Id, lstAccount[4].Id, lstAccount[5].Id, '2', '1',
                            mapRecTypeIdRequest.get(AP_Constant.reqRTSigning), '2', 'Sent', lstSection[1].Id),

                    TestFactory.createRequest(lstProgram[0].Id, lstTreaty[0].Id, lstAccount[4].Id, lstAccount[5].Id, '1', '3',
                            mapRecTypeIdRequest.get(AP_Constant.reqRTSigning), '2', 'Sent', lstSection[0].Id)
            };

            for(Request__c req : lstRequests){
                req.VersionMinor__c = 1;
                req.LastVersionSent__c = true;
                req.LastVersionAnswered__c = true;
            }

            insert lstRequests;

            lstRequests[6].OriginalRequest__c = lstRequests[4].Id;
            lstRequests[4].OriginalRequest__c = lstRequests[1].Id;

            update lstRequests;
        }

        System.runAs(testUserAdmin) {
            lstPortalUser = new List<User>{
                    TestFactory.createUser('testUserBrokerPortal', TestFactory.getProfileExternalId()),
                    TestFactory.createUser('testUserReinsurerPortal', TestFactory.getProfileExternalId())
            };

            lstPortalUser[0].ContactId = lstContact[1].Id;
            lstPortalUser[1].ContactId = lstContact[2].Id;
            lstPortalUser[0].BypassTrigger__c = 'AP38_CreateSharingForRequest;AP44_CreateSharingForUser;AP59_DeleteOldAccConRelation';
            lstPortalUser[1].BypassTrigger__c = 'AP38_CreateSharingForRequest;AP44_CreateSharingForUser;AP59_DeleteOldAccConRelation';
            insert lstPortalUser;

            List<AccountShare> accSharePortal = new List<AccountShare>{
                    new AccountShare(UserOrGroupId = lstPortalUser[0].Id, AccountAccessLevel = 'Edit', AccountId = lstAccount[5].Id, OpportunityAccessLevel = 'Read', CaseAccessLevel = 'Edit', RowCause = 'Manual' ),
                    new AccountShare(UserOrGroupId = lstPortalUser[1].Id, AccountAccessLevel = 'Edit', AccountId = lstAccount[5].Id, OpportunityAccessLevel = 'Read', CaseAccessLevel = 'Edit', RowCause = 'Manual')
            };
            insert accSharePortal;

            List<Request__Share> lstRequestShare = new List<Request__Share>();
          
            for(Request__c req : lstRequests){
                for(User user : lstPortalUser){
                    Request__Share requestShare = new Request__Share();
                    requestShare.RowCause = 'Manual';
                    requestShare.AccessLevel = 'Edit';
                    requestShare.ParentId = req.Id;
                    requestShare.UserOrGroupId = user.Id;
                    lstRequestShare.add(requestShare);      
                }
            }

            if(lstRequestShare.size() > 0){
                insert lstRequestShare;
            }
        }
    }

    @IsTest
    public static void testGetReqDetails(){
        System.runAs(testUserCE) {
            Test.startTest();
                Request__c req = LWC33_MarketSubmission.getRequestDetails(lstRequests[4].Id);
                System.assertEquals(true, req != null );
                System.assertEquals(lstRequests[4].Broker__c, req.Broker__c);
                System.assertEquals(lstRequests[4].Reinsurer__c, req.Reinsurer__c);
                System.assertEquals(lstRequests[4].ReinsurerStatus__c, req.ReinsurerStatus__c);
            Test.stopTest();
        }
    }

    @IsTest
    public static void testGetReqDetailsErr(){
        System.runAs(testUserCE) {
            Test.startTest();
                try{
                    Request__c req = LWC33_MarketSubmission.getRequestDetails('WrongId');
                    System.assertEquals(false, req != null );
                }
                catch(Exception e){
                    System.assertEquals(true, e != null );
                }
            Test.stopTest();
        }
    }

    @IsTest
    public static void testGetReqListCE(){
        System.runAs(testUserCE) {
            Test.startTest();
                Map<String, Object> mapResults = LWC33_MarketSubmission.getRequestLists(lstProgram[0].Id, lstAccount[5].Id, false);
                System.assertEquals(true, mapResults != null );
                //System.assertEquals(null, mapResults.get('Error'));

                List<Request__c> lstSigningReq = (List<Request__c>) mapResults.get('Success');
                System.assertEquals(2, lstSigningReq.size());
            Test.stopTest();
        }
    }

    @IsTest
    public static void testGetReqLisErr(){
        System.runAs(testUserCE) {
            Test.startTest();
                try{
                    Map<String, Object> mapResults = LWC33_MarketSubmission.getRequestLists('WrongId', 'WrongId', false);
                    System.assertEquals(true, mapResults != null );
                }
                catch(Exception e){
                    System.assertEquals(true, e != null );
                }
            Test.stopTest();
        }
    }

    @IsTest
    public static void testGetReqListPortal1(){
        System.runAs(lstPortalUser[0]) {
            Test.startTest();
                Map<String, Object> mapResults = LWC33_MarketSubmission.getRequestLists(lstProgram[0].Id, lstAccount[5].Id, true);
                System.assertEquals(true, mapResults != null );
                //System.assertEquals(null, mapResults.get('Error'));

                List<Request__c> lstSigningReq = (List<Request__c>) mapResults.get('Success');
                System.assertEquals(0, lstSigningReq.size());
            Test.stopTest();
        }
    }

    @IsTest
    public static void testGetReqListPortal2(){
        System.runAs(lstPortalUser[1]) {
            Test.startTest();
                Map<String, Object> mapResults = LWC33_MarketSubmission.getRequestLists(lstProgram[0].Id, lstAccount[5].Id, true);
                System.assertEquals(true, mapResults != null );
                //System.assertEquals(null, mapResults.get('Error') );

                List<Request__c> lstSigningReq = (List<Request__c>) mapResults.get('Success');
                System.assertEquals(0, lstSigningReq.size());
            Test.stopTest();
        }
    }

    @IsTest
    public static void testSaveDetailsCE(){
        System.runAs(testUserCE) {
            Test.startTest();
                List<Contact> lstContactSig = new List<Contact> {
                    TestFactory.createContact('Sign1', 'Sign1', lstAccount[5].Id, '2', '25009')
                };

                lstContactSig[0].Email = 'test11@test.com';
                lstContactSig[0].BrokerReinsurer__c = 'Reinsurer';
                insert lstContactSig;

                lstRequests[4].Broker_s_Ref__c = '88';

                Map<String, Object> mapResults = LWC33_MarketSubmission.saveRequests(new List<Request__c>{lstRequests[4]}, 'Save', lstAccount[5].Id, false, lstProgram[0].Id);
                System.assertEquals(true, mapResults != null );
                //System.assertEquals(null, mapResults.get('Error') );
                System.assertEquals('Success', mapResults.get('Success') );

                for(Request__c req : [SELECT Id, Broker_s_Ref__c FROM Request__c WHERE Id = :lstRequests[4].Id]){
                    System.assertEquals('88', req.Broker_s_Ref__c);
                }
            Test.stopTest();
        }
    }

    @IsTest
    public static void testSaveDetailsPortal1(){
        System.runAs(lstPortalUser[0]) {
            Test.startTest();
                List<Contact> lstContactSig = new List<Contact> {
                        TestFactory.createContact('Sign1', 'Sign1', lstAccount[5].Id, '2', '25009')
                };

                lstContactSig[0].Email = 'test22@test.com';
                lstContactSig[0].BrokerReinsurer__c = 'Reinsurer';
                insert lstContactSig;

                lstRequests[4].Broker_s_Ref__c = '77';

                Map<String, Object> mapResults = LWC33_MarketSubmission.saveRequests(new List<Request__c>{lstRequests[4]}, 'Save', lstAccount[5].Id,true, lstProgram[0].Id);
                System.assertEquals(true, mapResults != null );
                //System.assertEquals(null, mapResults.get('Error') );
                System.assertEquals('Success', mapResults.get('Success') );

                for(Request__c req : [SELECT Id, Broker_s_Ref__c FROM Request__c WHERE Id = :lstRequests[4].Id]){
                    System.assertEquals('77', req.Broker_s_Ref__c);
                }
            Test.stopTest();
        }
    }

    @IsTest
    public static void testSaveDetailsPortal2(){
        System.runAs(lstPortalUser[1]) {
            Test.startTest();
                List<Contact> lstContactSig = new List<Contact> {
                        TestFactory.createContact('Sign1', 'Sign1', lstAccount[5].Id, '2', '25009')
                };

                lstContactSig[0].Email = 'test33@test.com';
                lstContactSig[0].BrokerReinsurer__c = 'Reinsurer';
                insert lstContactSig;

                lstRequests[4].Broker_s_Ref__c = '66';
                Map<String, Object> mapResults = LWC33_MarketSubmission.saveRequests(new List<Request__c>{lstRequests[4]}, 'Save', lstAccount[5].Id, true, lstProgram[0].Id);
                System.assertEquals(true, mapResults != null );
                //System.assertEquals(null, mapResults.get('Error') );
                System.assertEquals('Success', mapResults.get('Success') );

                for(Request__c req : [SELECT Id, Broker_s_Ref__c FROM Request__c WHERE Id = :lstRequests[4].Id]){
                    System.assertEquals('66', req.Broker_s_Ref__c);
                }
            Test.stopTest();
        }
    }

    @IsTest
    public static void testSaveDetailsPortal1Send(){
        System.runAs(lstPortalUser[0]) {
            Test.startTest();
                List<Contact> lstContactSig = new List<Contact> {
                        TestFactory.createContact('Sign1', 'Sign1', lstAccount[5].Id, '2', '25009')
                };

                lstContactSig[0].Email = 'test44@test.com';
                lstContactSig[0].BrokerReinsurer__c = 'Reinsurer';
                insert lstContactSig;

                lstRequests[4].Broker_s_Ref__c = '55';
                Map<String, Object> mapResults = LWC33_MarketSubmission.saveRequests(new List<Request__c>{lstRequests[4]}, 'Send', lstAccount[5].Id,true, lstProgram[0].Id);
                System.assertEquals(true, mapResults != null );
                //System.assertEquals(null, mapResults.get('Error') );
                System.assertEquals('Success', mapResults.get('Success') );

                for(Request__c req : [SELECT Id, Broker_s_Ref__c FROM Request__c WHERE Id = :lstRequests[4].Id]){
                    System.assertEquals('55', req.Broker_s_Ref__c);
                }
            Test.stopTest();
        }
    }

    @IsTest
    public static void testSaveDetailsPortal2Send(){
        System.runAs(lstPortalUser[1]) {
            Test.startTest();
                List<Contact> lstContactSig = new List<Contact> {
                        TestFactory.createContact('Sign1', 'Sign1', lstAccount[5].Id, '2', '25009')
                };

                lstContactSig[0].Email = 'test55@test.com';
                lstContactSig[0].BrokerReinsurer__c = 'Reinsurer';
                insert lstContactSig;

                lstRequests[4].Broker_s_Ref__c = '44';

                Map<String, Object> mapResults = LWC33_MarketSubmission.saveRequests(new List<Request__c>{lstRequests[4]}, 'Send', lstAccount[5].Id, true, lstProgram[0].Id);
                System.assertEquals(true, mapResults != null );
                //System.assertEquals(null, mapResults.get('Error') );
                System.assertEquals('Success', mapResults.get('Success') );

                for(Request__c req : [SELECT Id, Broker_s_Ref__c FROM Request__c WHERE Id = :lstRequests[4].Id]){
                    System.assertEquals('44', req.Broker_s_Ref__c);
                }
            Test.stopTest();
        }
    }

    @IsTest
    public static void testSendEmail(){
        System.runAs(lstPortalUser[0]) {
            Test.startTest();
                Map<String, Object> mapResults = LWC33_MarketSubmission.sendMail(lstRequests[4], null);
                System.assertEquals(true, mapResults != null );
                //System.assertEquals(null, mapResults.get('Error') );
                //System.assertEquals('Success', mapResults.get('Success') );
            Test.stopTest();
        }
    }
    
    @IsTest
    public static void testSendEmail2(){
        System.runAs(lstPortalUser[0]) {
            Test.startTest();
                Map<String, Object> mapResults = LWC33_MarketSubmission.sendMail(lstRequests[4], lstRequests);
                System.assertEquals(true, mapResults != null );
                //System.assertEquals(null, mapResults.get('Error') );
                //System.assertEquals('Success', mapResults.get('Success') );
            Test.stopTest();
        }
    }

    @IsTest
    public static void testSendEmailErr(){
        System.runAs(lstPortalUser[0]) {
            Test.startTest();
                try{
                    Request__c newReq = TestFactory.createRequest(lstProgram[0].Id, lstTreaty[0].Id, lstAccount[4].Id, lstAccount[5].Id, '1', '3',
                                        mapRecTypeIdRequest.get(AP_Constant.reqRTSigning), '2', 'Sent', lstSection[0].Id);
                    Map<String, Object> mapResults = LWC33_MarketSubmission.sendMail(newReq, null);

                    System.assertEquals(true, mapResults.containsKey('Error'));
                }
                catch(Exception e){
                    System.assertEquals(true, e != null );
                }
            Test.stopTest();
        }
    }

    @IsTest
    public static void testGetSignatoriesPortal(){
        System.runAs(lstPortalUser[1]) {
            Test.startTest();
                Map<String, Object> mapResults = LWC33_MarketSubmission.getSignatories(lstAccount[5].Id, lstProgram[0].Id);
                System.assertEquals(true, mapResults != null );

                List<ContactReinsurerProgramRelation__c> lstSignatories = (List<ContactReinsurerProgramRelation__c>) mapResults.get('Success');
                System.assertEquals(0, lstSignatories.size());
            Test.stopTest();
        }
    }

    @IsTest
    public static void testGetLookupRiskCarrier(){
        System.runAs(lstPortalUser[0]) {
            Test.startTest();
                List<LWC33_MarketSubmission.SObjectResult> lstResults = LWC33_MarketSubmission.getLookupAccountField('Acc', lstRequests[4].Id, 'RiskCarrier');
                System.assertEquals(true, lstResults != null );
                System.assertEquals(1, lstResults.size());
            Test.stopTest();
        }
    }

    @IsTest
    public static void testGetLookupFinancialEntity(){
        System.runAs(lstPortalUser[0]) {
            Test.startTest();
                List<LWC33_MarketSubmission.SObjectResult> lstResults = LWC33_MarketSubmission.getLookupAccountField('Acc', lstRequests[5].Id, 'FinancialEntity');
                System.assertEquals(true, lstResults != null );
                System.assertEquals(1, lstResults.size());
            Test.stopTest();
        }
    }
    
    @IsTest
    public static void testUpdateRequestForLossDeposit(){
        System.runAs(lstPortalUser[0]) {
            Test.startTest();
                LWC33_MarketSubmission.updateRequestForLossDeposit(lstRequests);
            Test.stopTest();
        }
    }
}