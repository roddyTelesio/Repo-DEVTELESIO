@IsTest
public with sharing class LWC01_WorkingScope_TEST {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Test class for LWC01_WorkingScope
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 17-OCT-2019  NBI   1.0      Initial version
-- 11-SEP-2020  SAU   1.1      Modified
-- 20-SEP-2021  MBE   1.2      W-0999 - Signing - la page Sign for Pool devrait être accessible sans prendre en compte la PCC
--------------------------------------------------------------------------------------
**************************************************************************************/
    static User testUserAdmin;
    static User testUserCE;
    static List<Account> lstAcc;
    static Map<String, Id> mapRecTypeId;
    static List<Group> lstGroup;
    static List<GroupMember> lstGroupMember;
    static List<Program__c> lstProgram;
    static List<User> lstUsers = new List<User>();

    static{
        //create User
        testUserAdmin = TestFactory.createUser('testUserAdmin', TestFactory.getProfileAdminId());
        testUserCE = TestFactory.createUser('testUserCE', TestFactory.getProfileCEId());
        User assignedToUser = TestFactory.createUserWithRole('TestAssignedTo', TestFactory.getProfileAdminId(),TestFactory.getHeadUGPRoleId());
        lstUsers.add(testUserAdmin);
        lstUsers.add(assignedToUser);
        lstUsers.add(testUserCE);
        insert lstUsers;

        System.runAs(testUserAdmin){
            mapRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectAcc});

            //creating Account
            lstAcc = new List<Account> {TestFactory.createAccount(mapRecTypeId.get(AP_Constant.accRTPrincipalCedingCom), 'testAcc1', 'Y_8392')};
            insert lstAcc;

            lstGroup = [SELECT Id, Name, Type, DeveloperName FROM Group WHERE DeveloperName = :lstAcc[0].TECH_ReferentialId__c];

            //create Group Member
            lstGroupMember = new List<GroupMember> {TestFactory.createGroupMember(lstGroup[0].Id, UserInfo.getUserId())};
            insert lstGroupMember;

            //create Program
            lstProgram = new List<Program__c> {
                    TestFactory.createProgram('TestProg1', '1', '1'
                            , Date.today(), Date.today().addYears(1), '2', Date.today(), Date.today().addYears(1)
                            , '2020', lstAcc[0].Id, '23002','2'
                            , '25009'),

                    TestFactory.createProgram('TestProg2', '2', '2', Date.today()
                            , Date.today().addYears(1), '1', Date.today(), Date.today().addYears(1), '2020'
                            , lstAcc[0].Id, '23001', '2', '25001'),

                    TestFactory.createProgram('TestProg3', '1', '3', Date.today()
                            , Date.today().addYears(1), '2', Date.today(), Date.today().addYears(1), '2020'
                            , lstAcc[0].Id, '23001', '1', '25001')
            };
            insert lstProgram;
        }
    }

    @IsTest
    public static void testGetPrincipalCedingAcc(){
        System.runAs(testUserAdmin) {
            Test.startTest();
                List<Object> lstCedingComp = LWC01_WorkingScope.getPrincipalCedingAcc();
            Test.stopTest();
            System.assertEquals(1, lstCedingComp.size());
        }
    }

    @IsTest
    public static void testGetPrincipalCedingAccSignForPool(){
        System.runAs(testUserAdmin) {
            Test.startTest();
                List<Object> lstCedingComp = LWC01_WorkingScope.getPrincipalCedingAccSignForPool();
            Test.stopTest();
            System.assertEquals(1, lstCedingComp.size());
        }
    }

    @IsTest
    public static void testGetProgramDetails(){
        System.runAs(testUserAdmin) {
            Test.startTest();
                List<Program__c> lstProg = LWC01_WorkingScope.getProgramDetails(lstProgram[0].Id);
            Test.stopTest();
            System.assertEquals(1, lstProg.size());
            System.assertEquals('TestProg1', lstProg[0].Name);
        }
    }
}