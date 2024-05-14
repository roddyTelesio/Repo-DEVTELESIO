@IsTest
public with sharing class LWC15_QuoteRequests_TEST {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Test class for LWC15_QuoteRequests
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 08-JAN-2020  MBE   1.0      Initial version
-- 21-MAY-2021  MBE   1.1      W-0974 - Bug bloquant Prod - Impossibilité de créer une Lead request - TECH_Actor2Id__c
--------------------------------------------------------------------------------------
**************************************************************************************/
    static User testUserAdmin;
    static User testUserCE;
    static List<CoveredCedingCompany__c> lstCovCedCom;
    static List<Account> lstAccount;
    static List<Program__c> lstProgram;
    static List<Treaty__c> lstTreaty;
    static List<Request__c> lstRequest;
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
            Map<String, Id> mapAccountRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectAcc});
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

            for(Account acc : lstAccount){
               acc.IsActive__c = true;
            }
            
            insert lstAccount;

            //create Program
            lstProgram = new List<Program__c> {
                TestFactory.createProgram('TestProg1', '1', '1'
                                        , Date.today(), Date.today().addYears(1), '2', Date.today(), Date.today().addYears(1)
                                        , '2018', lstAccount[0].Id, '23002','2'
                                        , '25009'),

                TestFactory.createProgram('TestProg2', '2', '2', Date.today()
                                        , Date.today().addYears(1), '1', Date.today(), Date.today().addYears(1), '2018'
                                        , lstAccount[1].Id, '23001', '2', '25001'),

                TestFactory.createProgram('TestProg3', '1', '3', Date.today()
                                        , Date.today().addYears(1), '2', Date.today(), Date.today().addYears(1), '2020'
                                        , lstAccount[1].Id, '23001', '1', '25001')
            };
            insert lstProgram;

            lstProgram[1].RenewedFromProgram__c =  lstProgram[0].Id;
            lstProgram[1].TypeOfRenew__c = 'Standard Renew';
            update lstProgram;

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

            //create Request
            lstRequest = new List<Request__c>{
                // recordTypeId + status required
                TestFactory.createRequest(lstProgram[0].Id, lstTreaty[0].Id, lstAccount[3].Id, lstAccount[5].Id, '1', '3',
                                            mapRecTypeIdRequest.get(AP_Constant.reqRTQuote), '2', 'Setup',lstSection[0].Id),

                TestFactory.createRequest(lstProgram[0].Id, lstTreaty[0].Id, lstAccount[3].Id, lstAccount[5].Id, '2', '1',
                                        mapRecTypeIdRequest.get(AP_Constant.reqRTQuote), '2', 'Sent',lstSection[0].Id)
            };

            lstRequest[0].LastVersionSent__c = true;
            lstRequest[0].LastVersionAnswered__c = true;

            lstRequest[1].LastVersionSent__c = true;
            lstRequest[1].LastVersionAnswered__c = true;
            insert lstRequest;
        }
    }

    @IsTest
    public static void testGetQuoteRequests(){
        System.runAs(testUserCE) {
            Test.startTest();
            Map<String, Object> mapRequestResult = LWC15_QuoteRequests.getQuoteRequests(lstProgram[0].Id, lstTreaty[0].Id, lstAccount[5].Id, lstAccount[3].Id, 'Sent');
            Test.stopTest();
            System.assertEquals(2, mapRequestResult.size());
        }
    }

    @IsTest
    public static void testGetTreaties(){
        System.runAs(testUserCE) {
            Test.startTest();
                List<LWC15_QuoteRequests.OptionWrapper> lstTreaty = LWC15_QuoteRequests.getTreaties(lstProgram[0].Id);
            Test.stopTest();
            System.assertEquals(1, lstTreaty.size());
        }
    }

    @IsTest
    public static void testGetAccountBroker(){
        System.runAs(testUserCE) {
            Test.startTest();
                List<LWC15_QuoteRequests.OptionWrapper> lstRequest = LWC15_QuoteRequests.getAccountBroker();
            Test.stopTest();
            System.assertEquals(3, lstRequest.size());
        }
    }

    @IsTest
    public static void testGetReinsurer(){
        System.runAs(testUserCE) {
            Test.startTest();
                List<LWC15_QuoteRequests.SObjectResult> lstReinsurer = LWC15_QuoteRequests.getReinsurer('Account', 'Name', 'Reinsurer A', null);
            Test.stopTest();
            System.assertEquals(0, lstReinsurer.size());
        }
    }

    @IsTest
    public static void testGetBroker(){
        System.runAs(testUserCE) {
            Test.startTest();
                List<LWC15_QuoteRequests.SObjectResult> lstBroker = LWC15_QuoteRequests.getBroker('Account', 'Name', 'Broker', null);
            Test.stopTest();
            System.assertEquals(2, lstBroker.size());
        }
    }

    @IsTest
    public static void testSaveReinsurer(){
        System.runAs(testUserCE) {
            Test.startTest();
                List<Id> lstTreatyIds = new List<Id>{lstTreaty[0].Id};

                List<Request__c> lstNewRequest = new List<Request__c> {
                            TestFactory.createRequest(lstProgram[0].Id, lstTreaty[0].Id, lstAccount[3].Id, lstAccount[5].Id, '1', '3',
                            mapRecTypeIdRequest.get(AP_Constant.reqRTQuote), '2', 'Setup',lstSection[0].Id),

                            TestFactory.createRequest(lstProgram[0].Id, lstTreaty[0].Id, lstAccount[3].Id, lstAccount[5].Id, '2', '1',
                                        mapRecTypeIdRequest.get(AP_Constant.reqRTQuote), '2', 'Setup',lstSection[0].Id)
                };

                Map<String, Object> mapResult = (Map<String, Object>) LWC15_QuoteRequests.saveReinsurer(lstNewRequest, lstTreatyIds);
                Map<String, Object> mapResultError = (Map<String, Object>) LWC15_QuoteRequests.saveReinsurer(null, null);

            Test.stopTest();
            System.assertEquals('Success', mapResult.get('Success'));
            System.assertEquals(null, mapResult.get('Error'));
            System.assertEquals(true, mapResult.get('lstRequestDetails') != null);
            System.assertEquals(null, mapResultError.get('Success'));
            System.assertEquals(true, mapResultError.get('Error') != null);

            List<Request__c> lstQuoteRequest = [SELECT Id, name FROM Request__c WHERE RecordTypeId = :mapRecTypeIdRequest.get(AP_Constant.reqRTQuote)];

            System.assertEquals(4, lstQuoteRequest.size());
        }
    }

    @IsTest
    public static void testLoadPreviousYearQuoteRequest(){
        System.runAs(testUserCE) {
            Test.startTest();
                Map<String, Object> mapResults = LWC15_QuoteRequests.loadPreviousYearQuoteRequest(lstProgram[0].Id, lstTreaty[0].Id);
            Test.stopTest();
            System.assertEquals(2, lstRequest.size());
        }
    }

    @IsTest
    public static void testIsProgramRenewed(){
        System.runAs(testUserCE) {
            Test.startTest();
                Boolean isProgramRenewed = LWC15_QuoteRequests.isProgramRenewed(lstProgram[1].Id);
            Test.stopTest();
            System.assertEquals(true, isProgramRenewed);
        }
    }
    @IsTest
    public static void testToggleRequestType(){
        System.runAs(testUserCE) {
            Test.startTest();
                Map<String, Object> mapResults = LWC15_QuoteRequests.toggleRequestType(lstRequest);
            Test.stopTest();
            System.assertEquals('Records successfully Updated.', mapResults.get('Success'));
        }
    }

    @IsTest
    public static void testGetUWYearForOriginalProgram(){
        System.runAs(testUserCE) {
            Test.startTest();
                String result = LWC15_QuoteRequests.getUWYearForOriginalProgram(lstProgram[1].Id);
            Test.stopTest();
            System.assertEquals('2018', result);
        }
    }
    
    @IsTest
    public static void testLoadCurrentYearQuoteRequest(){
        System.runAs(testUserCE) {
            Test.startTest();
                Map<String, Object> mapResults = LWC15_QuoteRequests.loadCurrentYearQuoteRequest(lstProgram[0].Id);
            Test.stopTest();
        }
    }
}