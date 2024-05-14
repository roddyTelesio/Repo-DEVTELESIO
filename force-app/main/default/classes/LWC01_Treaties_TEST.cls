@IsTest
public with sharing class LWC01_Treaties_TEST {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Test class for LWC01_Treaties
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 17-OCT-2019  NBI   1.0      Initial version
-- 02-DEC-2019  MBE   1.1      New Test Method Added
-- 11-SEP-2020  SAU   1.2      Modified
--------------------------------------------------------------------------------------
**************************************************************************************/
   static User testUserAdmin;
   static User testUserCE;
   static List<Program__c> lstProgram;
   static List<Treaty__c> lstTreaty;
   static List<Account> lstAccount;
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
           Map<String, Id> mapRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectAcc});

           //create Account
           lstAccount = new List<Account> {
               TestFactory.createAccount(mapRecTypeId.get(AP_Constant.accRTPrincipalCedingCom),'Account A','C_0001'),
               TestFactory.createAccount(mapRecTypeId.get(AP_Constant.accRTPrincipalCedingCom),'Account B','C_0002'),
               TestFactory.createAccount(mapRecTypeId.get(AP_Constant.accRTCoveredCedingCompany),'Account C','C_0003'),
               TestFactory.createAccount(mapRecTypeId.get(AP_Constant.accRTCoveredCedingCompany),'Account D','C_0004')
           };
           insert lstAccount;

           //create Program
           lstProgram = new List<Program__c> {
               TestFactory.createProgram('TestProg1', '1', '1'
                                       , Date.today(), Date.today().addYears(1), '2', Date.today(), Date.today().addYears(1)
                                       , '2018', lstAccount[0].Id, '23002','2', '25009'),

               TestFactory.createProgram('TestProg2', '2', '2'
                                       , Date.today(), Date.today().addYears(1), '1', Date.today(), Date.today().addYears(1)
                                       , '2018', lstAccount[1].Id, '23001', '2', '25001'),

               TestFactory.createProgram('TestProg3', '1', '3'
                                       , Date.today(), Date.today().addYears(1), '2', Date.today(), Date.today().addYears(1)
                                       , '2020', lstAccount[1].Id, '23001', '1', '25001')
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
       }
   }

   @IsTest
   public static void testGetTreaties(){
       System.runAs(testUserAdmin) {
           Test.startTest();
               List<Id> lstSelectedProgramId = new List<Id>{lstProgram[0].Id};
               lstTreaty = LWC01_Treaties.getTreaties(lstSelectedProgramId);
           Test.stopTest();
           System.assertEquals(2, lstTreaty.size());
       }
   }

   @IsTest
   public static void testIsProgramEmpty(){
       System.runAs(testUserAdmin) {
           Test.startTest();
               Boolean resultProgramNotEmpty = LWC01_Treaties.isProgramEmpty('2018',  lstAccount[0].Id);
               Boolean resultProgramEmpty = LWC01_Treaties.isProgramEmpty('2019',  lstAccount[0].Id);
           Test.stopTest();
           System.assertEquals(false, resultProgramNotEmpty);
           System.assertEquals(true, resultProgramEmpty);
       }
   }
   
   @IsTest
   public static void testGetSelectedProgramDetail(){
       System.runAs(testUserAdmin) {
           Test.startTest();
              Program__c result = LWC01_Treaties.getSelectedProgramDetail(lstProgram[0].Id);
           Test.stopTest();
           System.assertEquals(lstProgram[0].Name, result.Name);
       }
   }
    
    @IsTest
   public static void testcheckPCC(){
       System.runAs(testUserCE) {
           Test.startTest();
               Boolean isActive = LWC01_Treaties.checkPCC(lstTreaty[0].Id);
           Test.stopTest();
           System.assertEquals(true, isActive);
       }
   }
    
     @IsTest
   public static void testcheckCCC(){
       System.runAs(testUserCE) {
           Test.startTest();
               Boolean isActive = LWC01_Treaties.checkCCC(lstTreaty[0].Id);
           Test.stopTest();
           System.assertEquals(true, isActive);
       }
   }
}