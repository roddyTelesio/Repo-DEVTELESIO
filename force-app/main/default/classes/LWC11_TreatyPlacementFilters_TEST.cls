@IsTest
public with sharing class LWC11_TreatyPlacementFilters_TEST {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Test class for LWC11_TreatyPlacementFilters
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 24-DEC-2019  MBE   1.0      Initial version
-- 11-SEP-2020  SAU   1.1      Modified
--------------------------------------------------------------------------------------
**************************************************************************************/
   static User testUserAdmin;
   static User testUserCE;
   static List<CoveredCedingCompany__c> lstCovCedCom;
   static List<Account> lstAccount;
   static List<Program__c> lstProgram;
   static List<Treaty__c> lstTreaty;
   static List<Request__c> lstQuoteRequests;
   static List<Section__c> lstSection;
   static List<User> lstUsers = new List<User>();
   static Map<String, Id> mapRecTypeIdRequest = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectRequest});

    static{
        //create User
        testUserAdmin = TestFactory.createUser('testUserAdmin', TestFactory.getProfileAdminId());
        testUserCE = TestFactory.createUser('testUserCE', TestFactory.getProfileCEId());
        User assignedToUser = TestFactory.createUserWithRole('TestAssignedTo', TestFactory.getProfileAdminId(),TestFactory.getHeadUGPRoleId());
        lstUsers.add(testUserAdmin);
        lstUsers.add(assignedToUser);
        lstUsers.add(testUserCE);
        insert lstUsers;

        System.runAs(testUserCE){
            Map<String, Id> mapRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectAcc});

            //create Account
            lstAccount = new List<Account> {
                TestFactory.createAccount(mapRecTypeId.get(AP_Constant.accRTPrincipalCedingCom),'Account A','C_0001'),
                TestFactory.createAccount(mapRecTypeId.get(AP_Constant.accRTPrincipalCedingCom),'Account B','C_0002'),
                TestFactory.createAccount(mapRecTypeId.get(AP_Constant.accRTCoveredCedingCompany),'Account C','C_0003'),
                TestFactory.createAccount(mapRecTypeId.get(AP_Constant.accRTCoveredCedingCompany),'Account D','C_0004'),
                TestFactory.createAccount(mapRecTypeId.get(AP_Constant.accRTBroker),'Account E','C_0005'),
                TestFactory.createAccount(mapRecTypeId.get(AP_Constant.accRTReinsurer),'Account F','C_0006')
            };
            insert lstAccount;

            //create Program
            lstProgram = new List<Program__c>{
                TestFactory.createProgram('TestProg1', '1', '1'
                                            , Date.today(), Date.today().addYears(1), '2', Date.today(), Date.today().addYears(1)
                                            , '2018', lstAccount[0].Id, '23002','2', '25009'),
                TestFactory.createProgram('TestProg3', '2', '3'
                                            , Date.today(), Date.today().addYears(1), '2', Date.today(), Date.today().addYears(1)
                                            , '2018', lstAccount[1].Id, '23001', '1', '25001')
            };
            insert lstProgram;

            //create Treaty
            lstTreaty = new List<Treaty__c> {
                TestFactory.createTreaty('TestTreaty1', 1, 'ref01', '3'
                , lstProgram[0].Id, '2', 34, '10', '2020-00000222', '1', '2', '2', '2', '2'),

                TestFactory.createTreaty('TestTreaty2', 2, 'ref02', '2', lstProgram[0].Id
                            , '1', 44, '44', '2020-00000222', '2', '2', '2', '2', '2'),

                TestFactory.createTreaty('TestTreaty3', 3, 'ref03', '2'
                            , lstProgram[1].Id, '2', 89, '44', '2020-00000222', '3', '2', '2', '2', '2')
            };
            insert lstTreaty;

            //create Section
            lstSection = new List<Section__c> {
                TestFactory.createSection('TestSection1', '1.0', '22003', '20006', '9052'
                                        , 322, 34, lstProgram[0].Id, lstTreaty[0].Id, '3', '1'
                                        , true, '5', null, '23001', '1', '5', '2', '2'),

                TestFactory.createSection('TestSection2', '2.0', '22003', '20006', '9052'
                                        , 23, 5, lstProgram[1].Id, lstTreaty[1].Id, '3', '1'
                                        , false, '5', null, '23001', '1', '5', '2', '2')
            };

            lstQuoteRequests = new List<Request__c>{
                // recordTypeId + status required
                TestFactory.createRequest(lstProgram[0].Id, lstTreaty[0].Id, lstAccount[4].Id, lstAccount[5].Id, '1', '3',
                                            mapRecTypeIdRequest.get(AP_Constant.reqRTQuote), '2', 'Setup',lstSection[0].Id),

                TestFactory.createRequest(lstProgram[1].Id, lstTreaty[1].Id, lstAccount[4].Id, lstAccount[5].Id, '2', '1',
                                        mapRecTypeIdRequest.get(AP_Constant.reqRTQuote), '2', 'Setup',lstSection[1].Id)
            };
            insert lstQuoteRequests;
        }
    }

    @IsTest
    public static void testGetPrograms(){
        System.runAs(testUserCE) {
            Test.startTest();
                List<LWC11_TreatyPlacementFilters.OptionWrapper> lstProgram = LWC11_TreatyPlacementFilters.getPrograms('2018', lstAccount[0].Id);
            Test.stopTest();
            System.assertEquals(1, lstProgram.size());
        }
    }

    @IsTest
    public static void testGetProgramDetails(){
        System.runAs(testUserCE) {
            Test.startTest();
                Program__c program = LWC11_TreatyPlacementFilters.getProgramDetails(lstProgram[0].Id);
            Test.stopTest();
            System.assertEquals(true, program != null);
            System.assertEquals('TestProg1', program.Name);
        }
    }

    @IsTest
    public static void testGetTreaties(){
        System.runAs(testUserCE) {
            Test.startTest();
                List<LWC11_TreatyPlacementFilters.OptionWrapper> lstTreaty = LWC11_TreatyPlacementFilters.getTreaties(lstProgram[0].Id);
            Test.stopTest();
            System.assertEquals(2, lstTreaty.size());
        }
    }

    @IsTest
    public static void testGetAccountBroker(){
        System.runAs(testUserCE) {
            Test.startTest();
                List <String> lstRecordTypeQuote = AP_Constant.reqRTQuote.split('-');
                List<LWC11_TreatyPlacementFilters.OptionWrapper> lstAccountBroker = LWC11_TreatyPlacementFilters.getAccountBroker(lstProgram[0].Id, lstRecordTypeQuote[1]);
            Test.stopTest();
            System.assertEquals(1, lstAccountBroker.size());
            System.assertEquals(lstAccount[4].Name, lstAccountBroker[0].label);
        }
    }

    @IsTest
    public static void testGetAccountReinsurer(){
        System.runAs(testUserCE) {
            Test.startTest();
            List <String> lstRecordTypeQuote = AP_Constant.reqRTQuote.split('-');
                List<LWC11_TreatyPlacementFilters.OptionWrapper> lstAccountReinsurer = LWC11_TreatyPlacementFilters.getAccountReinsurer(lstProgram[0].Id, lstRecordTypeQuote[1]);
            Test.stopTest();
            System.assertEquals(1, lstAccountReinsurer.size());
            System.assertEquals(lstAccount[5].Name, lstAccountReinsurer[0].label);
        }
    }
   
    @IsTest
    public static void testGetRequestRTId(){
        System.runAs(testUserCE) {
            Test.startTest();
                List<LWC11_TreatyPlacementFilters.OptionWrapper> lstRecordTypes = LWC11_TreatyPlacementFilters.getRequestRTId();
            Test.stopTest();
            System.assertEquals(7, lstRecordTypes.size());
        }
    }
}