@IsTest
public with sharing class AP40_UpdateSigningReqDeductions_TEST {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Test class for AP40_UpdateSigningReqDeductions
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 15-FEB-2021  NBI   1.0      Initial version
--------------------------------------------------------------------------------------
**************************************************************************************/

    static User testUserAdmin;
    static User testUserCE;
    static List<Account> lstAccount;
    static List<Program__c> lstProgram;
    static List<Treaty__c> lstTreaty;
    static List<Section__c> lstSection;
    static List<Request__c> lstRequests;
    static List<User> lstUsers = new List<User>();
    static Map<String, Id> mapRecTypeIdRequest = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectRequest});

    static{
        //create User
        testUserAdmin = TestFactory.createUser('testUserAdmin', TestFactory.getProfileAdminId());
        testUserCE = TestFactory.createUser('testUserCE', TestFactory.getProfileCEId());
        testUserCE.BypassTrigger__c = 'AP38_CreateSharingForRequest;AP53_UpdateSAStatus;AP43_DeleteClonedRequests;AP42_DeleteDocumentVisibility';
        lstUsers.add(testUserAdmin);
        lstUsers.add(testUserCE);
        insert lstUsers;

        System.runAs(testUserCE){
            Map<String, Id> mapRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{
                    AP_Constant.sObjectAcc
            });

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
                            , '2018', lstAccount[0].Id, '23002', '1', '25009'),
                    TestFactory.createProgram('TestProg3', '2', '3'
                            , Date.today(), Date.today().addYears(1), '2', Date.today(), Date.today().addYears(1)
                            , '2018', lstAccount[1].Id, '23001', '1', '25001')
            };
            insert lstProgram;

            //create Treaty
            lstTreaty = new List<Treaty__c> {
                    TestFactory.createTreaty('TestTreaty1', 1, '2020-00000222', '3'
                            , lstProgram[0].Id, '2', 34, '10', '2020-00000222', '1', '2', '2', '2', '2'),

                    TestFactory.createTreaty('TestTreaty2', 2, '2020-00000222', '2', lstProgram[0].Id
                            , '1', 44, '44', '2020-00000222', '2', '2', '2', '2', '2'),

                    TestFactory.createTreaty('TestTreaty3', 3, '2020-00000222', '2'
                            , lstProgram[1].Id, '2', 89, '44', '2020-00000222', '3', '2', '2', '2', '2')
            };
            lstTreaty[0].Deductions_Perc__c = 55;
            lstTreaty[2].Deductions_Perc__c = 68;
            insert lstTreaty;

            //create Section
            lstSection = new List<Section__c> {
                    TestFactory.createSection('TestSection1', '1.0', '22003', '20006', '9052'
                            , 322, 34, lstProgram[0].Id, lstTreaty[0].Id, '3', '1'
                            , true, '5', null, '23001', '1', '5', '2', '2'),

                    TestFactory.createSection('TestSection2', '2.0', '22003', '20006', '9052'
                            , 23, 5, lstProgram[1].Id, lstTreaty[2].Id, '3', '1'
                            , false, '5', null, '23001', '1', '5', '2', '2')
            };
            insert lstSection;

            lstRequests = new List<Request__c>{
                    // recordTypeId + status required
                    TestFactory.createRequest(lstProgram[0].Id, lstTreaty[0].Id, lstAccount[4].Id, lstAccount[5].Id, '1', '3',
                            mapRecTypeIdRequest.get(AP_Constant.reqRTSigning), '2', 'Setup', lstSection[0].Id),

                    TestFactory.createRequest(lstProgram[1].Id, lstTreaty[2].Id, lstAccount[4].Id, lstAccount[5].Id, '2', '1',
                            mapRecTypeIdRequest.get(AP_Constant.reqRTSigning), '2', 'Setup', lstSection[1].Id)
            };

            lstRequests[0].Deductions__c = 55;
            lstRequests[1].Deductions__c = 20;
            insert lstRequests;
        }
    }

    @IsTest
    public static void testUpdateTreaty(){
        System.runAs(testUserCE) {
            Test.startTest();

                Request__c req = [SELECT Id, Deductions__c FROM Request__c WHERE Id = :lstRequests[0].Id];
                System.assertEquals(55, req.Deductions__c);

                lstTreaty[0].Deductions_Perc__c = 30;
                update lstTreaty[0];
            Test.stopTest();

            System.assertEquals(30, lstTreaty[0].Deductions_Perc__c);

            Request__c reqUpdated = [SELECT Id, Deductions__c FROM Request__c WHERE Id = :lstRequests[0].Id];
            System.assertEquals(30, reqUpdated.Deductions__c);
        }
    }
}