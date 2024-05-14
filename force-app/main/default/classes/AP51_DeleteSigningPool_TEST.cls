@IsTest
public with sharing class AP51_DeleteSigningPool_TEST {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Test class for AP51_DeleteSigningPool_TEST
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 10-MAR-2021  NBI   1.0      Initial version
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
                    TestFactory.createContact('Account E - Covered Ceding', 'CedingPortal', lstAccount[2].Id, '2', '25009'),
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
            lstRequests[4].Pool__c = lstPool[1].Id;
            insert lstRequests;

        }
    }

    @IsTest
    public static void testDeletePool(){
        System.runAs(testUserAdmin) {
            Test.startTest();
                delete lstPoolTreatySections;

                List<Request__c> lstReq = [SELECT Id from Request__c];
                System.assertEquals(5, lstReq.size());
            Test.stopTest();
        }
    }
}