@IsTest
public with sharing class LWC23_PlacementRequests_TEST {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Test class for LWC23_PlacementRequests
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 28-SEPT-2020  SAU   1.0      Initial version
--------------------------------------------------------------------------------------
**************************************************************************************/

    static User testUserAdmin;
    static User testUserCE;
    static List<CoveredCedingCompany__c> lstCovCedCom;
    static List<Account> lstAccount;
    static List<Program__c> lstProgram;
    static List<Treaty__c> lstTreaty;
    static List<Request__c> lstRequest;
    static List<Request__c> lstChildLeadRequests;
    static List<Section__c> lstSection;
    static Map<String, Id> mapRecTypeIdRequest = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectRequest});
    static List<User> lstUsers = new List<User>();
    static List<Request__c> lstLeadRequests;
    static List<Contact> lstContact;
    static List<AccountContactRelation> lstAccContactRelation;
    static List<Pool__c> lstPool;
    static List<PoolTreatySection__c> lstPoolTreatySections;

    static {
        //create User
        testUserAdmin = TestFactory.createUser('testUserAdmin', TestFactory.getProfileAdminId());
        testUserCE = TestFactory.createUser('testUserCE', TestFactory.getProfileCEId());
        User assignedToUser = TestFactory.createUserWithRole('TestAssignedTo', TestFactory.getProfileAdminId(),TestFactory.getHeadUGPRoleId());
        lstUsers.add(testUserAdmin);
        lstUsers.add(testUserCE);
        lstUsers.add(assignedToUser);
        insert lstUsers;

        System.runAs(testUserAdmin){
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

            lstProgram[0].TECH_ShowClosePreviousPhaseBtn__c = '1';
            lstProgram[1].TECH_ShowClosePreviousPhaseBtn__c = '2';
            insert lstProgram;

            lstProgram[2].RenewedFromProgram__c =  lstProgram[1].Id;
            lstProgram[1].RenewedFromProgram__c =  lstProgram[0].Id;
            lstProgram[1].TypeOfRenew__c = 'Standard Renew';
            update lstProgram;

            //create Treaty
            lstTreaty = new List<Treaty__c> {
                TestFactory.createTreaty('TestTreaty1', 1, 'ref01', '3'
                                       , lstProgram[0].Id, '2', 34, '10', '2020-00000222', '1', '2', '2', '2', '2'),

                TestFactory.createTreaty('TestTreaty2', 2, 'ref02', '2', lstProgram[1].Id
                                       , '1', 44, '44', '2020-00000222', '2', '2', '2', '2', '2'),

                TestFactory.createTreaty('TestTreaty3', 3, 'ref03', '2'
                                       , lstProgram[0].Id, '2', 89, '44', '2020-00000222', '3', '2', '2', '2', '2'),

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
                                       , 23, 5, lstProgram[0].Id, lstTreaty[1].Id, '3', '1'
                                       , false, '5', null, '23001', '1', '5', '2', '2'),

                TestFactory.createSection('TestSection2', '2.1', '22003', '20006', '9052'
                                       , 23, 5, lstProgram[0].Id, lstTreaty[2].Id, '3', '1'
                                       , false, '5', null, '23001', '1', '5', '2', '2')
            };
            lstSection[0].Retained_to_lead__c = true;
            lstSection[0].Status__c = AP_Constant.statusActive;
            lstSection[1].Retained_to_lead__c = true;
            lstSection[1].Status__c = AP_Constant.statusActive;
            insert lstSection;

            //create Request
            lstRequest = new List<Request__c>{
                // recordTypeId + status required
                TestFactory.createRequest(lstProgram[0].Id, lstTreaty[0].Id, lstAccount[4].Id, lstAccount[5].Id, '1', '3',
                                             mapRecTypeIdRequest.get(AP_Constant.reqRTQuote), '2', 'Setup',lstSection[0].Id),
   
                TestFactory.createRequest(lstProgram[0].Id, lstTreaty[0].Id, lstAccount[4].Id, lstAccount[8].Id, '2', '1',
                                           mapRecTypeIdRequest.get(AP_Constant.reqRTQuote), '2', 'Sent',lstSection[0].Id),

                TestFactory.createRequest(lstProgram[1].Id, lstTreaty[1].Id, lstAccount[4].Id, lstAccount[5].Id, '1', '3',
                                           mapRecTypeIdRequest.get(AP_Constant.reqRTQuote), '2', 'Sent',lstSection[1].Id),

                TestFactory.createRequest(lstProgram[1].Id, lstTreaty[1].Id, lstAccount[4].Id, lstAccount[5].Id, '2', '1',
                                           mapRecTypeIdRequest.get(AP_Constant.reqRTQuote), '2', 'Sent',lstSection[1].Id),

                TestFactory.createRequest(lstProgram[0].Id, lstTreaty[2].Id, lstAccount[4].Id, lstAccount[5].Id, '1', '5',
                                           mapRecTypeIdRequest.get(AP_Constant.reqRTPlacement), '2', 'Setup',lstSection[2].Id),

                TestFactory.createRequest(lstProgram[0].Id, lstTreaty[2].Id, lstAccount[4].Id, lstAccount[5].Id, '2', '5',
                                           mapRecTypeIdRequest.get(AP_Constant.reqRTPlacement), '2', 'Setup',lstSection[2].Id)
            };

            insert lstRequest;

            lstRequest[2].OriginalRequest__c = lstRequest[0].Id;
            lstRequest[3].OriginalRequest__c = lstRequest[1].Id;
            lstRequest[5].OriginalRequest__c = lstRequest[4].Id;
            // lstRequest[4].LastVersionSent__c = true;
            // lstRequest[4].LastVersionAnswered__c = true;
            lstRequest[5].LastVersionSent__c = true;
            lstRequest[5].LastVersionAnswered__c = true;
            update lstRequest;

            //create lead 
            lstLeadRequests = new List<Request__c>{
                // recordTypeId + status required
                TestFactory.createLeadRequest(lstProgram[0].Id, lstTreaty[2].Id, lstAccount[4].Id, lstAccount[5].Id, '1', '4',
                                               mapRecTypeIdRequest.get(AP_Constant.reqRTLead), '2', 'Setup',null),
   
                TestFactory.createLeadRequest(lstProgram[0].Id, lstTreaty[2].Id, lstAccount[4].Id, lstAccount[5].Id, '2', '4',
                                               mapRecTypeIdRequest.get(AP_Constant.reqRTLead), '2', 'Sent',null)
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

            //create Pool
            lstPool = new List<Pool__c>{
                TestFactory.createPool('Pool A', 78, '2018', lstUsers[2].Id),
                TestFactory.createPool('Pool B', 78, '2018', lstUsers[2].Id)
            };
            insert lstPool;

            //create Pool Treaty Section
            lstPoolTreatySections = new List<PoolTreatySection__c> {
                TestFactory.createPoolTreatySection(lstPool[0].Id, lstTreaty[0].Id, null
                        , false,true, 32, null),

                TestFactory.createPoolTreatySection(lstPool[1].Id, lstTreaty[0].Id, null
                         , false,true, 40, null)
            };
            insert lstPoolTreatySections;
        }
    }
    
    @IsTest
    public static void testGetPlacementRequests(){
        System.runAs(testUserAdmin) {
            Test.startTest();
            Map<String, Object> mapResults = LWC23_PlacementRequests.getPlacementRequests(lstProgram[0].Id, lstTreaty[2].Id, lstAccount[5].Id, lstAccount[4].Id, 'Setup');
            Test.stopTest();
        }
    }

    @IsTest
    public static void testViewPlacementTable(){
        System.runAs(testUserAdmin) {
            Test.startTest();
                List<LWC23_PlacementRequests.PlacementWrapper> lstResults = LWC23_PlacementRequests.viewPlacementTable(lstProgram[0].Id);
            Test.stopTest();
           System.assertEquals(1, lstResults.size());
        }
    }

    @IsTest
    public static void testDisablePlacementInfo(){
        System.runAs(testUserCE) {
            Test.startTest();
                Boolean result = LWC23_PlacementRequests.disablePlacementInfo(lstProgram[0].Id);
                Boolean result2 = LWC23_PlacementRequests.disablePlacementInfo(lstProgram[1].Id);
            Test.stopTest();
            System.assertEquals(false, result); 
            System.assertEquals(true, result2); 
        }
    }

    @IsTest
    public static void testCheckIfLeadRequestPresent(){
        System.runAs(testUserAdmin) {
            Test.startTest();
                Boolean result = LWC23_PlacementRequests.checkIfLeadRequestPresent(lstProgram[0].Id);
            Test.stopTest();
           System.assertEquals(true, result);
        }
    }

    @IsTest
    public static void testGetSelectedProgramDetail(){
        System.runAs(testUserCE) {
            Test.startTest();
                Program__c resultProgram = LWC23_PlacementRequests.getSelectedProgramDetail(lstProgram[0].Id);
            Test.stopTest();
            System.assertEquals(lstProgram[0].Name, resultProgram.Name); 
        }
    }


    @IsTest
    public static void testGetUWYearForOriginalProgram(){
        System.runAs(testUserCE) {
            Test.startTest();
                String year = LWC23_PlacementRequests.getUWYearForOriginalProgram(lstProgram[2].Id);
            Test.stopTest();
            System.assertEquals(lstProgram[1].UwYear__c, year);
        }
    }
}