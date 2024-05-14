@IsTest
public with sharing class LWC01_Programs_TEST {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Test class for LWC01_Programs
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
   static List<CoveredCedingCompany__c> lstCovCedCom;
   static List<Account> lstAccount;
   static List<Request__c> lstSigningRequests;
   static Map<String, Id> mapRecTypeIdRequest = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectRequest});
   static List<Treaty__c> lstTreaty;
   static List<Section__c> lstSection;
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
        Map<String, Id> mapRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectAcc});

       System.runAs(testUserCE){
            //create Account
            lstAccount = new List<Account> {
                TestFactory.createAccount(mapRecTypeId.get(AP_Constant.accRTPrincipalCedingCom),'Account A','C_0001'),
                TestFactory.createAccount(mapRecTypeId.get(AP_Constant.accRTPrincipalCedingCom),'Account B','C_0002'),
                TestFactory.createAccount(mapRecTypeId.get(AP_Constant.accRTCoveredCedingCompany),'Account C','C_0003'),
                TestFactory.createAccount(mapRecTypeId.get(AP_Constant.accRTCoveredCedingCompany),'Account D','C_0004'),
                TestFactory.createAccount(mapRecTypeId.get(AP_Constant.accRTReinsurer),'Account E','C_0005'),
                TestFactory.createAccount(mapRecTypeId.get(AP_Constant.accRTPrincipalCedingCom),'Account f','C_0006')
            };
            lstAccount[5].IsActive__c = false;
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
                                       , Date.today(), Date.today().addYears(1), '2', Date.today(), Date.today().addYears(1)   //inactive account
                                       , '2020', lstAccount[5].Id, '23001', '1', '25001'),

                TestFactory.createProgram('TestProg4', '1', '3'
                                       , Date.today(), Date.today().addYears(1), '2', Date.today(), Date.today().addYears(1) // SR signed and renewed
                                       , '2020', lstAccount[1].Id, '23001', '1', '25001'),

                TestFactory.createProgram('TestProg5', '1', '3'
                                       , Date.today(), Date.today().addYears(1), '2', Date.today(), Date.today().addYears(1) 
                                       , '2020', lstAccount[1].Id, '23001', '1', '25001'),

                TestFactory.createProgram('TestProg6', '1', '3'
                                       , Date.today(), Date.today().addYears(1), '1', Date.today(), Date.today().addYears(3) 
                                       , '2020', lstAccount[1].Id, '23001', '1', '25001')
                                       ,

                TestFactory.createProgram('TestPro76', '1', '3'
                                       , Date.today(), Date.today().addYears(1), '1', Date.today(), Date.today().addYears(3) 
                                       , '2020', lstAccount[1].Id, '23001', '1', '25001')
                                       ,

                TestFactory.createProgram('TestProg8', '1', '3'
                                       , Date.today(), Date.today().addYears(1), '2', Date.today(), Date.today().addYears(3) 
                                       , '2020', lstAccount[1].Id, '23001', '1', '25001')
           };
           lstProgram[1].RenewedFromProgram__c = lstProgram[0].Id;
           lstProgram[5].TacitRenewal__c = '1';
           lstProgram[7].TacitRenewal__c = '1';
           lstProgram[4].RenewedFromProgram__c = lstProgram[5].Id;
           insert lstProgram;

              //create Treaty
              lstTreaty = new List<Treaty__c> {
                TestFactory.createTreaty('TestTreaty1', 1, 'ref01', '3'
                                        , lstProgram[0].Id, '2', 34, '10', '2020-00000222', '1', '2', '2', '2', '2'),
 
                TestFactory.createTreaty('TestTreaty2', 2, 'ref02', '2', lstProgram[1].Id
                                        , '1', 44, '44', '2020-00000222', '2', '2', '2', '2', '2'),
 
                TestFactory.createTreaty('TestTreaty2', 2, 'ref02', '2', lstProgram[2].Id
                                         , '1', 44, '44', '2020-00000222', '2', '2', '2', '2', '2'),

                TestFactory.createTreaty('TestTreaty2', 2, 'ref02', '2', lstProgram[3].Id
                                        , '1', 44, '44', '2020-00000222', '2', '2', '2', '2', '2'),
 
                TestFactory.createTreaty('TestTreaty2', 2, 'ref02', '2', lstProgram[4].Id
                                        , '1', 44, '44', '2020-00000222', '2', '2', '2', '2', '2'),
 
                TestFactory.createTreaty('TestTreaty2', 2, 'ref02', '2', lstProgram[5].Id
                                         , '1', 44, '44', '2020-00000222', '2', '2', '2', '2', '2'),
 
                TestFactory.createTreaty('TestTreaty2', 2, 'ref02', '2', lstProgram[6].Id
                                          , '1', 44, '44', '2020-00000222', '2', '2', '2', '2', '2'),
 
                TestFactory.createTreaty('TestTreaty2', 2, 'ref02', '2', lstProgram[7].Id
                                          , '1', 44, '44', '2020-00000222', '2', '2', '2', '2', '2')
                
            };
            insert lstTreaty;
 
            //create Section
            lstSection = new List<Section__c> {
                TestFactory.createSection('TestSection1', '1.1', '22003', '20006', '9052'
                                        , 322, 34, lstProgram[0].Id, lstTreaty[0].Id, '3', '1'
                                        , true, '5', null, '23001', '1', '5', '2', '2'),
 
                TestFactory.createSection('TestSection2', '2.1', '22003', '20006', '9052'
                                        , 23, 5, lstProgram[1].Id, lstTreaty[1].Id, '3', '1'
                                        , false, '5', null, '23001', '1', '5', '2', '2'),
 
                TestFactory.createSection('TestSection2', '2.1', '22003', '20006', '9052'
                                        , 23, 5, lstProgram[2].Id, lstTreaty[2].Id, '3', '1'
                                        , false, '5', null, '23001', '1', '5', '2', '2'),
 
                TestFactory.createSection('TestSection2', '2.1', '22003', '20006', '9052'
                                           , 23, 5, lstProgram[3].Id, lstTreaty[3].Id, '3', '1'
                                           , false, '5', null, '23001', '1', '5', '2', '2'),
 
                TestFactory.createSection('TestSection2', '2.1', '22003', '20006', '9052'
                                           , 23, 5, lstProgram[4].Id, lstTreaty[4].Id, '3', '1'
                                           , false, '5', null, '23001', '1', '5', '2', '2'),
 
                TestFactory.createSection('TestSection2', '2.1', '22003', '20006', '9052'
                                           , 23, 5, lstProgram[5].Id, lstTreaty[5].Id, '3', '1'
                                           , false, '5', null, '23001', '1', '5', '2', '2'),
 
                TestFactory.createSection('TestSection2', '2.1', '22003', '20006', '9052'
                                           , 23, 5, lstProgram[6].Id, lstTreaty[6].Id, '3', '1'
                                           , false, '5', null, '23001', '1', '5', '2', '2'),
 
                TestFactory.createSection('TestSection2', '2.1', '22003', '20006', '9052'
                                           , 23, 5, lstProgram[7].Id, lstTreaty[7].Id, '3', '1'
                                           , false, '5', null, '23001', '1', '5', '2', '2')
                
            };
            insert lstSection;

           //create Covered Ceding Company
           lstCovCedCom = new List<CoveredCedingCompany__c> {
               TestFactory.createCovCedCom(lstAccount[2].Id, lstProgram[4].Id, true,null
                                           ,false,null,false,null,null),

               TestFactory.createCovCedCom(lstAccount[3].Id, lstProgram[0].Id, true,null
                                           ,false,null,false,null,null),

               TestFactory.createCovCedCom(lstAccount[2].Id, lstProgram[1].Id, true,null
                                           ,false,null,false,null,null),

               TestFactory.createCovCedCom(lstAccount[2].Id, lstProgram[5].Id, true,null
                                           ,false,null,false,null,null),
                                           
               TestFactory.createCovCedCom(lstAccount[2].Id, lstProgram[6].Id, true,null
                                           ,false,null,false,null,null),
                                           
               TestFactory.createCovCedCom(lstAccount[2].Id, lstProgram[7].Id, true,null
                                            ,false,null,false,null,null)
           };
           insert lstCovCedCom;

           //create signing requests
           lstSigningRequests = new List<Request__c>{
                // recordTypeId + status required
                TestFactory.createRequest(lstProgram[0].Id, lstTreaty[0].Id, lstAccount[3].Id, lstAccount[4].Id, '1', '3',
                                            mapRecTypeIdRequest.get(AP_Constant.reqRTSigning), '2', 'Setup',lstSection[0].Id),

                TestFactory.createRequest(lstProgram[1].Id, lstTreaty[1].Id, lstAccount[3].Id, lstAccount[4].Id, '2', '1',
                                            mapRecTypeIdRequest.get(AP_Constant.reqRTSigning), '2', 'Setup',lstSection[1].Id),
                
                TestFactory.createRequest(lstProgram[3].Id, lstTreaty[1].Id, lstAccount[3].Id, lstAccount[4].Id, '2', '1',
                                            mapRecTypeIdRequest.get(AP_Constant.reqRTSigning), '2', 'Signed',lstSection[0].Id)
                                            ,
                
                TestFactory.createRequest(lstProgram[2].Id, lstTreaty[1].Id, lstAccount[3].Id, lstAccount[4].Id, '2', '1',
                                            mapRecTypeIdRequest.get(AP_Constant.reqRTSigning), '2', 'Signed',lstSection[2].Id)
                                            ,
                
                TestFactory.createRequest(lstProgram[4].Id, lstTreaty[1].Id, lstAccount[3].Id, lstAccount[4].Id, '2', '1',
                                            mapRecTypeIdRequest.get(AP_Constant.reqRTSigning), '2', 'Signed',lstSection[4].Id)
                                            ,
                
                TestFactory.createRequest(lstProgram[5].Id, lstTreaty[1].Id, lstAccount[3].Id, lstAccount[4].Id, '2', '1',
                                            mapRecTypeIdRequest.get(AP_Constant.reqRTSigning), '2', 'Signed',lstSection[5].Id)
                                            ,
                
                TestFactory.createRequest(lstProgram[6].Id, lstTreaty[1].Id, lstAccount[3].Id, lstAccount[4].Id, '2', '1',
                                            mapRecTypeIdRequest.get(AP_Constant.reqRTSigning), '2', 'Signed',lstSection[6].Id)  ,
                
                TestFactory.createRequest(lstProgram[7].Id, lstTreaty[1].Id, lstAccount[3].Id, lstAccount[4].Id, '2', '1',
                                           mapRecTypeIdRequest.get(AP_Constant.reqRTSigning), '2', 'Signed',lstSection[7].Id)
            };
            lstSigningRequests[0].SigningStatus__c = '4';
            lstSigningRequests[2].SigningStatus__c = '4';
            lstSigningRequests[3].SigningStatus__c = '4';
            lstSigningRequests[4].SigningStatus__c = '4';
            lstSigningRequests[5].SigningStatus__c = '4';
            lstSigningRequests[6].SigningStatus__c = '4';
            lstSigningRequests[7].SigningStatus__c = '4';
            insert lstSigningRequests;

       }
   }

   @IsTest
   public static void testGetPrograms(){
       System.runAs(testUserCE) {
           Test.startTest();       
                lstProgram = LWC01_Programs.getPrograms('2018', lstAccount[1].Id);
           Test.stopTest();
           System.assertEquals(1, lstProgram.size());
           System.assertEquals('TestProg2', lstProgram[0].Name);
       }
   }

   @IsTest
   public static void testGetCoveredCedingCompanies(){
       System.runAs(testUserCE) {
           Test.startTest();
               lstCovCedCom = LWC01_Programs.getCoveredCedingCompanies(lstProgram[0].Id);
           Test.stopTest();
           System.assertEquals(1, lstCovCedCom.size());
       }
   }

   @IsTest
   public static void testCheckForRenewProgram(){
       System.runAs(testUserCE) {
           Test.startTest();         
            Map<String, Object> mapResultRequestsUnsigned = LWC01_Programs.checkForRenewProgram(lstProgram[1].Id);  
            Map<String, Object> mapResultInactivePCC = LWC01_Programs.checkForRenewProgram(lstProgram[2].Id);
            Map<String, Object> mapResultInactiveCCC = LWC01_Programs.checkForRenewProgram(lstProgram[3].Id);
            Map<String, Object> mapResult1 = LWC01_Programs.checkForRenewProgram(lstProgram[0].Id);
            Map<String, Object> mapResult2 = LWC01_Programs.checkForRenewProgram(lstProgram[6].Id);
            Map<String, Object> mapResult3 = LWC01_Programs.checkForRenewProgram(lstProgram[7].Id);
            
            System.assertEquals('You cannot renew this program as it is not signed yet', mapResultRequestsUnsigned.get('errorMsg'));
            System.assertEquals('You cannot renew this program as the PCC is inactive', mapResultInactivePCC.get('errorMsg'));
            System.assertEquals('You cannot renew this program as all CCC are inactive', mapResultInactiveCCC.get('errorMsg'));
            System.assertEquals('1', mapResult1.get('displayScreen'));
            System.assertEquals('2', mapResult2.get('displayScreen'));
            System.assertEquals('3', mapResult3.get('displayScreen'));
           Test.stopTest();
       }
   }
    
    @IsTest
   public static void testcheckActivePCC(){
       System.runAs(testUserCE) {
           Test.startTest();
               Boolean isActive = LWC01_Programs.checkActivePCC(lstAccount[0].Id);
           Test.stopTest();
           System.assertEquals(true, isActive);
       }
   }
    
     @IsTest
   public static void testcheckCCC(){
       System.runAs(testUserCE) {
           Test.startTest();
               Boolean isActive = LWC01_Programs.checkCCC(lstProgram[0].Id);
           Test.stopTest();
           System.assertEquals(true, isActive);
       }
   }
}