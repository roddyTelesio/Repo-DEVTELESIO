@IsTest
public with sharing class LWC39_RenewProgram_TEST {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Test class for LWC39_RenewProgram
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
    static List<Account> lstAccount;
    static List<Program__c> lstProgram;
    static List<Contact> lstContact;
    static List<Treaty__c> lstTreaty;
    static List<Section__c> lstSection;
    static List<Section__c> lstOption;
    static List<CoveredCedingCompany__c> lstCovCedComProgram;
    static List<CoveredCedingCompany__c> lstCovCedComTreaty;
    static List<CoveredCedingCompany__c> lstCovCedComSection;
    static List<PoolTreatySection__c> lstPoolTreatySections;
    static List<Reinstatement__c> lstReinstatement;
    static List<Pool__c> lstPool;
    static List<Request__c> lstRequests;
    static List<Request__c> lstReqVersions;
    static List<Request__c> lstLeadRequests;
    static List<Request__c> lstLeadRequestsOtherTreaty;
    static List<Request__c> lstSigningRequests;
    static List<User> lstUsers = new List<User>();
    static Map<String, Id> mapRecTypeIdRequest = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectRequest});
    static Map<String, Id> mapAccountRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectAcc});

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

            lstAccount[0].EmailSA__c = 'test@test.com';
            update lstAccount;

            //create Ceding Portal Contact + Broker/Reinsurer Contact
            lstContact = new List<Contact> {
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

            lstCovCedComProgram = new List<CoveredCedingCompany__c> {
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
            insert lstCovCedComProgram;

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

            lstCovCedComTreaty = new List<CoveredCedingCompany__c> {
                    TestFactory.createCovCedCom(lstAccount[3].Id, lstProgram[0].Id, true,lstTreaty[0].Id
                            ,true,null,false,null,null),

                    TestFactory.createCovCedCom(lstAccount[3].Id, lstProgram[1].Id, true,lstTreaty[2].Id
                            ,true,null,false,null,null),

                    TestFactory.createCovCedCom(lstAccount[3].Id, lstProgram[2].Id, true,lstTreaty[3].Id
                            ,true,null,false,null,null),

                    TestFactory.createCovCedCom(lstAccount[2].Id, lstProgram[0].Id, true,lstTreaty[0].Id
                            ,true,null,false,null,null),

                    TestFactory.createCovCedCom(lstAccount[2].Id, lstProgram[2].Id, true,lstTreaty[3].Id
                            ,true,null,false,null,null),

                    TestFactory.createCovCedCom(lstAccount[2].Id, lstProgram[2].Id, true,lstTreaty[3].Id
                            ,true,null,false,null,null)

            };
            insert lstCovCedComTreaty;

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

            //create Option
            lstOption = new List<Section__c> {
                    TestFactory.createSection('TestSection1', '1.1', '22003', '20006', '9052'
                            , 322, 34, lstProgram[0].Id, lstTreaty[0].Id, '3', '1'
                            , true, '5', null, '23001', '1', '5', '2', '2')
            };
            lstOption[0].RelatedSection__c = lstSection[0].Id;
            insert lstOption;

            lstCovCedComSection = new List<CoveredCedingCompany__c> {
                    TestFactory.createCovCedCom(lstAccount[3].Id, lstProgram[0].Id, true,lstTreaty[0].Id
                            ,false, lstSection[0].Id,true,null,null),
                    TestFactory.createCovCedCom(lstAccount[3].Id, lstProgram[2].Id, true,lstTreaty[3].Id
                            ,false,lstSection[4].Id,true,null,null),

                    TestFactory.createCovCedCom(lstAccount[2].Id, lstProgram[0].Id, true,lstTreaty[0].Id
                            ,false,lstSection[0].Id,true,null,null),

                    TestFactory.createCovCedCom(lstAccount[2].Id, lstProgram[2].Id, true,lstTreaty[3].Id
                            ,false,lstSection[4].Id,true,null,null),

                    TestFactory.createCovCedCom(lstAccount[2].Id, lstProgram[2].Id, true,lstTreaty[3].Id
                            ,false,lstSection[4].Id,true,null,null)

            };
            insert lstCovCedComSection;

            //create Pool Treaty Section
            lstPoolTreatySections = new List<PoolTreatySection__c> {
                    TestFactory.createPoolTreatySection(lstPool[0].Id, lstTreaty[1].Id, null
                            , false, true, 32, null),

                    TestFactory.createPoolTreatySection(lstPool[1].Id, lstTreaty[0].Id, lstSection[0].Id
                            , true, true, 40, null)
            };
            insert lstPoolTreatySections;

            //create reinstatement for treaty type XL
            lstReinstatement = new List<Reinstatement__c> {
                    TestFactory.createReinstatement(lstSection[0].Id, true, 40, 39, '1'
                            , '3'),

                    TestFactory.createReinstatement(lstSection[0].Id, true, 34, 54, '1'
                            , '3')
            };
            insert lstReinstatement;

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
                            mapRecTypeIdRequest.get(AP_Constant.reqRTSigning), '2', 'Setup', lstSection[0].Id),

                    TestFactory.createRequest(lstProgram[1].Id, lstTreaty[2].Id, lstAccount[4].Id, lstAccount[5].Id, '2', '1',
                            mapRecTypeIdRequest.get(AP_Constant.reqRTSigning), '2', 'Setup', lstSection[1].Id)
            };
            insert lstRequests;

            //create lead 
            lstLeadRequests = new List<Request__c>{
                    // recordTypeId + status required
                    TestFactory.createLeadRequest(lstProgram[0].Id, lstTreaty[0].Id, lstAccount[3].Id, lstAccount[5].Id, '1', '4',
                                                    mapRecTypeIdRequest.get(AP_Constant.reqRTLead), '2', 'Setup',lstSection[0].Id),
        
                    TestFactory.createLeadRequest(lstProgram[0].Id, lstTreaty[0].Id, lstAccount[3].Id, lstAccount[5].Id, '2', '4',
                                                    mapRecTypeIdRequest.get(AP_Constant.reqRTLead), '2', 'Setup',lstSection[0].Id)
            };
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
        }
    }

    @IsTest
    public static void testgetTreaties(){
        System.runAs(testUserCE) {
            Test.startTest();
                List<Treaty__c> lstResults = LWC39_RenewProgram.getTreaties(lstProgram[0].Id);
                System.assertEquals(2, lstResults.size());
            Test.stopTest();
        }
    }

    @IsTest
    public static void testgetSections(){
        System.runAs(testUserCE) {
            Test.startTest();
                List<Section__c> lstResults = LWC39_RenewProgram.getSections(new List<Id>{lstTreaty[0].Id});
                System.assertEquals(3, lstResults.size());
            Test.stopTest();
        }
    }

    @IsTest
    public static void testRenewStd(){
        System.runAs(testUserCE) {
            Test.startTest();
                Date newDate = Date.newInstance(2021, 2, 17);
                Map<String, Object> mapResults = LWC39_RenewProgram.saveProgram(lstProgram[0].Id, 'renewProgramNameStandard', '2021', new List<Id>{lstTreaty[0].Id}, new List<Id>{lstSection[0].Id, lstOption[0].Id}, newDate, true, 'Standard Renew');
                System.assertEquals(true, mapResults.containsKey('Success'));

                List<Program__c> lstRenewProgram = [SELECT Id, Name, RenewedFromProgram__c FROM Program__c WHERE RenewedFromProgram__c = :lstProgram[0].Id];
                System.assertEquals(1, lstRenewProgram.size());
                System.assertEquals('renewProgramNameStandard', lstRenewProgram[0].Name);
            Test.stopTest();
        }
    }

    @IsTest
    public static void testRenewError(){
        System.runAs(testUserCE) {
            Test.startTest();
                Date newDate = Date.newInstance(2021, 2, 17);
                Map<String, Object> mapResults = LWC39_RenewProgram.saveProgram(lstProgram[0].Id, 'renewProgramName', '2021', new List<Id>{lstTreaty[0].Id}, null, newDate, true, 'Standard Renew');
                System.assertEquals(false, mapResults.containsKey('Success'));
                System.assertEquals(true, mapResults.containsKey('Error'));
            Test.stopTest();
        }
    }

    @IsTest
    public static void testRenewIdentical(){
        System.runAs(testUserCE) {
            Test.startTest();
                Date newDate = Date.newInstance(2021, 2, 17);
                Map<String, Object> mapResults = LWC39_RenewProgram.saveProgram(lstProgram[0].Id, 'renewProgramNameIdentical', '2021', new List<Id>{lstTreaty[0].Id}, new List<Id>{lstSection[0].Id}, newDate, true, 'LTA/TR Identical Renew');
                System.assertEquals(true, mapResults.containsKey('Success'));

                List<Program__c> lstRenewProgram = [SELECT Id, Name, RenewedFromProgram__c FROM Program__c WHERE RenewedFromProgram__c = :lstProgram[0].Id];
                System.assertEquals(1, lstRenewProgram.size());
                System.assertEquals('renewProgramNameIdentical', lstRenewProgram[0].Name);
            Test.stopTest();
        }
    }

    @IsTest
    public static void testRenewRenegotiation(){
        System.runAs(testUserCE) {
            Test.startTest();
                Date newDate = Date.newInstance(2021, 2, 17);
                Map<String, Object> mapResults = LWC39_RenewProgram.saveProgram(lstProgram[0].Id, 'renewProgramNameRenegotiation', '2021', new List<Id>{lstTreaty[0].Id}, new List<Id>{lstSection[0].Id}, newDate, true, 'LTA/TR Renegotiation');
                System.assertEquals(true, mapResults.containsKey('Success'));

                List<Program__c> lstRenewProgram = [SELECT Id, Name, RenewedFromProgram__c FROM Program__c WHERE RenewedFromProgram__c = :lstProgram[0].Id];
                System.assertEquals(1, lstRenewProgram.size());
                System.assertEquals('renewProgramNameRenegotiation', lstRenewProgram[0].Name);
            Test.stopTest();
        }
    }

    @IsTest
    public static void testRenewStd2(){
        System.runAs(testUserCE) {
            Test.startTest();
                Date newDate = Date.newInstance(2021, 2, 17);
                Map<String, Object> mapResults = LWC39_RenewProgram.saveProgram(lstProgram[0].Id, 'renewProgramNameStandard2', '2021', new List<Id>{lstTreaty[0].Id}, new List<Id>{lstSection[0].Id, lstOption[0].Id}, newDate, false, 'Standard Renew');
                System.assertEquals(true, mapResults.containsKey('Success'));

                List<Program__c> lstRenewProgram = [SELECT Id, Name, RenewedFromProgram__c FROM Program__c WHERE RenewedFromProgram__c = :lstProgram[0].Id];
                System.assertEquals(1, lstRenewProgram.size());
                System.assertEquals('renewProgramNameStandard2', lstRenewProgram[0].Name);
            Test.stopTest();
        }
    }

    @IsTest
    public static void testRenewIdentical2(){
        System.runAs(testUserCE) {
            Test.startTest();
                Date newDate = Date.newInstance(2021, 2, 17);
                Map<String, Object> mapResults = LWC39_RenewProgram.saveProgram(lstProgram[0].Id, 'renewProgramNameIdentical2', '2021', new List<Id>{lstTreaty[0].Id}, new List<Id>{lstSection[0].Id}, newDate, false, 'LTA/TR Identical Renew');
                System.assertEquals(true, mapResults.containsKey('Success'));

                List<Program__c> lstRenewProgram = [SELECT Id, Name, RenewedFromProgram__c FROM Program__c WHERE RenewedFromProgram__c = :lstProgram[0].Id];
                System.assertEquals(1, lstRenewProgram.size());
                System.assertEquals('renewProgramNameIdentical2', lstRenewProgram[0].Name);
            Test.stopTest();
        }
    }

    @IsTest
    public static void testRenewRenegotiation2(){
        System.runAs(testUserCE) {
            Test.startTest();
                Date newDate = Date.newInstance(2021, 2, 17);
                Map<String, Object> mapResults = LWC39_RenewProgram.saveProgram(lstProgram[0].Id, 'renewProgramNameRenegotiation2', '2021', new List<Id>{lstTreaty[0].Id}, new List<Id>{lstSection[0].Id}, newDate, false, 'LTA/TR Renegotiation');
                System.assertEquals(true, mapResults.containsKey('Success'));

                List<Program__c> lstRenewProgram = [SELECT Id, Name, RenewedFromProgram__c FROM Program__c WHERE RenewedFromProgram__c = :lstProgram[0].Id];
                System.assertEquals(1, lstRenewProgram.size());
                System.assertEquals('renewProgramNameRenegotiation2', lstRenewProgram[0].Name);
            Test.stopTest();
        }
    }
}