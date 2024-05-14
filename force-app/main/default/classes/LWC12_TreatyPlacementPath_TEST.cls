@IsTest
public with sharing class LWC12_TreatyPlacementPath_TEST {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Test class for LWC12_TreatyPlacementPath
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
    static List<User> lstUsers = new List<User>();
    static Map<String, Id> mapRecTypeIdRequest = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectRequest});

    static{
        //create User
        testUserAdmin = TestFactory.createUser('testUserAdmin', TestFactory.getProfileAdminId());
        testUserCE = TestFactory.createUser('testUserCE', TestFactory.getProfileCEId());
        lstUsers.add(testUserAdmin);
        lstUsers.add(testUserCE);
        insert lstUsers;

        System.runAs(testUserCE){
            Map<String, Id> mapRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{
                    AP_Constant.sObjectAcc
            });

            //create Account
            lstAccount = new List<Account>{
                    TestFactory.createAccount(mapRecTypeId.get(AP_Constant.accRTPrincipalCedingCom), 'Account A', 'C_0001'),
                    TestFactory.createAccount(mapRecTypeId.get(AP_Constant.accRTPrincipalCedingCom), 'Account B', 'C_0002')
            };
            insert lstAccount;

            //create Program
            lstProgram = new List<Program__c>{
                    TestFactory.createProgram('TestProg1', '1', '1'
                            , Date.today(), Date.today().addYears(1), '2', Date.today(), Date.today().addYears(1)
                            , '2018', lstAccount[0].Id, '23002', '2', '25009'),
                    TestFactory.createProgram('TestProg3', '2', '3'
                            , Date.today(), Date.today().addYears(1), '2', Date.today(), Date.today().addYears(1)
                            , '2018', lstAccount[1].Id, '23001', '1', '25001')
            };
        }
    }

    @IsTest
    public static void testUpdateStage(){
        System.runAs(testUserCE){
            Test.startTest();
                lstProgram[0].TECH_StageName__c = 'Conditions';
                insert lstProgram;
                Map<String, Object> mapResults = LWC12_TreatyPlacementPath.updateStage('Quote', lstProgram[0].Id);
            Test.stopTest();

            System.assertEquals(true, mapResults.containsKey('Success'));

            Program__c program = [SELECT Id, TECH_StageName__c FROM Program__c WHERE Id = :lstProgram[0].Id];
            System.assertEquals('Quote', program.TECH_StageName__c);
        }
    }

    @IsTest
    public static void testUpdateStageErr(){
        System.runAs(testUserCE) {
            Test.startTest();
                insert lstProgram;
                Map<String, Object> mapResults = LWC12_TreatyPlacementPath.updateStage('WrongStage', lstProgram[1].Id);

                System.assertEquals(true, mapResults.containsKey('Error'));
            Test.stopTest();
        }
    }

    @IsTest
    public static void testGetPreviousStage(){
        System.runAs(testUserCE){
            Test.startTest();
                lstProgram[0].TECH_StageName__c = 'Quote';
                insert lstProgram;
                Map<String, Object> mapResults = LWC12_TreatyPlacementPath.getPreviousStageName('Lead', lstProgram[0].Id);
            Test.stopTest();

            System.assertEquals(false, mapResults.containsKey('Error'));
//            System.assertEquals('Quote', (String)mapResults.get('previousStageName'));
        }
    }

    @IsTest
    public static void testGetPreviousStageErr(){
        System.runAs(testUserCE) {
            Test.startTest();
            insert lstProgram;

            try{
                Map<String, Object> mapResults = LWC12_TreatyPlacementPath.getPreviousStageName('WrongStage', 'WrongId');
                System.assertEquals(true, mapResults.containsKey('Error'));
            }
            catch(Exception e){
                System.assertEquals(true, e != null);
            }
            Test.stopTest();
        }
    }
}