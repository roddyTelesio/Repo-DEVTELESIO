@IsTest
public with sharing class LWC01_NewTreaty_TEST {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Test class for LWC01_NewTreaty
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 02-DEC-2019  MBE   1.0      Initial version
--------------------------------------------------------------------------------------
**************************************************************************************/
   static User testUserAdmin;
   static User testUserCE;
   static List<Program__c> lstProgram;
   static List<CoveredCedingCompany__c> lstCovCedCom;
   static List<Treaty__c> lstTreaty;
   static List<Treaty__c> lstTreatyEdit;
   static List<PoolTreatySection__c> lstPoolTreatySections;
   static List<Section__c> lstSection;
   static List<Section__c> lstRelatedSection;
   static List<Reinstatement__c> lstReinstatement;
   static List<Pool__c> lstPool;
   static List<Account> lstAccount;
   static List<User> lstUsers = new List<User>();
   static List<Request__c> lstSigningRequests;
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
               TestFactory.createAccount(mapRecTypeId.get(AP_Constant.accRTReinsurer),'Account E','C_0005'),
               TestFactory.createAccount(mapRecTypeId.get(AP_Constant.accRTBroker),'Account F','C_0006')
           };
           insert lstAccount;

           CS_TreatyReference__c treatyRefCustomSetting = new CS_TreatyReference__c();
           treatyRefCustomSetting.ReferenceSequence__c = '00000221';
           insert treatyRefCustomSetting;

           //create Pool
           lstPool = new List<Pool__c>{
                TestFactory.createPool('Pool A', 78, '2018', lstUsers[1].Id),
                TestFactory.createPool('Pool B', 78, '2018', lstUsers[1].Id)
           };
           insert lstPool;

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

           lstTreatyEdit = new List<Treaty__c> {

                TestFactory.createTreaty('TestTreatyChange', 1, 'ref01', '3'
                                         , lstProgram[0].Id, '2', 34, '10', '2020-00000222', '1', '2', '2', '2', '2'),

                TestFactory.createTreaty('TestTreaty5', 2, 'ref02', '2', lstProgram[0].Id
                                         , '1', 44, '44', '2020-00000222', '2', '2', '2', '2', '2'),

                TestFactory.createTreaty('TestTreaty4', 3, 'ref03', '2'
                                       , lstProgram[1].Id, '2', 89, '44', '2020-00000222', '3', '2', '2', '2', '2')
           };

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
                                       , 55, 87, lstProgram[1].Id, lstTreaty[2].Id, '1', '1'
                                       , true, '1',null, '23001', '1', '5', '2', '2')};
           insert lstSection;

           //related section
           lstRelatedSection = new List<Section__c>{

            TestFactory.createSection('TestRelatedSection1', '3.2', '22003', '20006', '9052'
                                    , 322, 34, lstProgram[2].Id, lstTreaty[2].Id, '3', '2'
                                    , true, '5', lstSection[3].Id, '23001', '1', '5', '2', '2'),

            TestFactory.createSection('TestRelatedSection1', '3.2', '22003', '20006', '9052'
                                    , 322, 34, lstProgram[2].Id, lstTreaty[1].Id, '3', '2'
                                    , true, '5', lstSection[2].Id, '23001', '1', '5', '2', '2')
        };
        insert lstRelatedSection;

           //create Covered Ceding Company
           lstCovCedCom = new List<CoveredCedingCompany__c> {
               TestFactory.createCovCedCom(lstAccount[2].Id, lstProgram[0].Id, true,null
                                            , false, null, true, null, null),

               TestFactory.createCovCedCom(lstAccount[3].Id, lstProgram[0].Id, true,null
                                            , false, null, false, null, null),

               TestFactory.createCovCedCom(lstAccount[2].Id, lstProgram[0].Id, false, lstTreaty[1].Id
                                            , true, lstSection[2].Id, true, null, null),

               TestFactory.createCovCedCom(lstAccount[2].Id, lstProgram[0].Id, false, lstTreaty[0].Id
                                            , true, null, true, null, null),

               TestFactory.createCovCedCom(lstAccount[3].Id, lstProgram[0].Id, false, lstTreaty[0].Id
                                            ,false, lstSection[0].Id, true, null, null),

               TestFactory.createCovCedCom(lstAccount[3].Id, lstProgram[0].Id, false, lstTreaty[0].Id
                                            ,false, lstSection[0].Id, true, null, null)
           };
           insert lstCovCedCom;

           //create Pool Treaty Section
           lstPoolTreatySections = new List<PoolTreatySection__c> {
               TestFactory.createPoolTreatySection(lstPool[0].Id, lstTreaty[1].Id, null
                                                   , false, true, 32, null),

               TestFactory.createPoolTreatySection(lstPool[1].Id, lstTreaty[0].Id, null
                                                   , false, true, 40, null)
           };
           insert lstPoolTreatySections;

           //create reinstatement for treaty type XL
           lstReinstatement = new List<Reinstatement__c> {
               TestFactory.createReinstatement(lstSection[2].Id, true, 40, 39, '1', '3'),

               TestFactory.createReinstatement(lstSection[2].Id, true, 34, 54, '1', '3')
           };
           insert lstReinstatement;

           //create requests
           lstSigningRequests = new List<Request__c>{
            TestFactory.createRequest(lstProgram[1].Id, lstTreaty[2].Id, lstAccount[3].Id, lstAccount[4].Id, '2', '1',
                                        mapRecTypeIdRequest.get(AP_Constant.reqRTSigning), '2', 'Answered',lstSection[2].Id)
           };
        }
    }

    @IsTest
    public static void testSaveProgramRecord(){
        System.runAs(testUserCE) {
            Test.startTest();
               List<String> lstAccId = new List<String>{lstAccount[2].Id, lstAccount[3].Id};
               List<String> lstPool = new List<String>{lstPool[0].Id +';88', lstPool[1].Id+';66'};
               List<Treaty__c> lstNewTreaty = new List<Treaty__c>();

               Map<String, Object> mapSaveResult = (Map<String, Object>) LWC01_NewTreaty.saveTreatyRecord(lstTreatyEdit[0], lstAccId, lstPool,null, false);
               lstNewTreaty = [SELECT Id, Name FROM Treaty__c WHERE Name = :lstTreatyEdit[0].Name];

               for(Treaty__c treaty : lstNewTreaty){
                   System.assertEquals('TestTreatyChange',treaty.Name);
               }

               Map<String, Object> mapSaveResultEdit = (Map<String, Object>) LWC01_NewTreaty.saveTreatyRecord(lstTreatyEdit[0], lstAccId, lstPool, lstTreaty[1].Id, true);
               lstNewTreaty = [SELECT Id, Name FROM Treaty__c WHERE Id = :lstTreaty[1].Id];

               for(Treaty__c treaty : lstNewTreaty){
                   System.assertEquals('TestTreaty2',treaty.Name);
               }

               Map<String, Object> mapSaveResultCopy = (Map<String, Object>) LWC01_NewTreaty.saveTreatyRecord(lstTreatyEdit[1], lstAccId, lstPool, lstTreaty[1].Id, false);
               lstNewTreaty = [SELECT Id, Name FROM Treaty__c WHERE Name = :lstTreatyEdit[1].Name];
               System.assertEquals(1, lstNewTreaty.size());
            Test.stopTest();


            System.assertEquals('Success', mapSaveResult.get('Success'));
            //System.assertEquals('Success', mapSaveResultEdit.get('Success'));
            System.assertEquals('Success', mapSaveResultCopy.get('Success'));
        } 
    }

    @IsTest
    public static void testGetProgram(){
        System.runAs(testUserCE) {
            Test.startTest();
                List<Program__c> lstNewProgram = LWC01_NewTreaty.getProgram(lstProgram[0].Id);
            Test.stopTest();
            System.assertEquals(lstProgram[0].Name, lstNewProgram[0].Name);
        }
    }

    @IsTest
    public static void testGetCovCedComByProgramId(){
        System.runAs(testUserCE) {
            Test.startTest();
                lstCovCedCom = LWC01_NewTreaty.getCovCedComByProgramId(lstProgram[0].Id, false);
            Test.stopTest();
            System.assertEquals(2, lstCovCedCom.size());
        }
    }

    @IsTest
    public static void testGetCovCedComByTreatyId(){
        System.runAs(testUserCE) {
            Test.startTest();
                lstCovCedCom = LWC01_NewTreaty.getCovCedComByTreatyId(lstTreaty[0].Id);
            Test.stopTest();
            System.assertEquals(1, lstCovCedCom.size());
        }
    }

    @IsTest
    public static void testGetPools(){
        System.runAs(testUserCE) {
            Test.startTest();
                lstPool = LWC01_NewTreaty.getPools('2018');
            Test.stopTest();
            System.assertEquals(2, lstPool.size());
        }
    }

    @IsTest
    public static void testGetProgramDetails(){
        System.runAs(testUserCE) {
            Test.startTest();
                lstTreaty = LWC01_NewTreaty.getProgramDetails(lstTreaty[0].Id);
            Test.stopTest();
            System.assertEquals('TestProg1', lstTreaty[0].Program__r.Name);
        }
    }

    @IsTest
    public static void testGetPoolsByTreatyId(){
        System.runAs(testUserCE) {
            Test.startTest();
                lstPool = LWC01_NewTreaty.getPoolsByTreatyId(lstTreaty[0].Id);
            Test.stopTest();
            System.assertEquals(1, lstPool.size());
        }
    }

    @IsTest
    public static void testGetActorReferenceIndex(){
        System.runAs(testUserCE) {
            insert lstTreatyEdit[2];
            Test.startTest();
                String actorRefIndex = LWC01_NewTreaty.getActorReferenceIndex(lstProgram[0].UwYear__c);
            Test.stopTest();
            System.assertNotEquals(null, actorRefIndex);
        }
    }

   @IsTest
   public static void testgetAllExistedCoveredCedingComForSection(){
        System.runAs(testUserCE) {
            Test.startTest();
                List <Id> lstResult = LWC01_NewTreaty.getAllExistedCoveredCedingComForSection(lstTreaty[0].Id);
            Test.stopTest();
            System.assertEquals(lstResult.size(), 1);
        }
    }

    @IsTest
    public static void testCheckTreatyName(){
        System.runAs(testUserCE) {
            Test.startTest();
                Boolean result = LWC01_NewTreaty.checkTreatyName(lstTreaty[1].Id, lstTreaty[1].Program__c, lstTreaty[1].Name, true);
            Test.stopTest();
            System.assertEquals(true, result);
        }
    }

    @IsTest
    public static void testCheckFieldsVisibility(){
        System.runAs(testUserCE){
            Test.startTest();
                Map<String,Boolean> mapResults = LWC01_NewTreaty.checkFieldsVisibility(lstTreaty[2].Id);
                Map<String,Boolean> mapResults2 = LWC01_NewTreaty.checkFieldsVisibility(lstTreaty[0].Id);
            Test.stopTest();
            System.assertEquals(false, mapResults.get('PlacementShare'));
            System.assertEquals(true, mapResults.get('Type'));
            System.assertEquals(false, mapResults2.get('PlacementShare'));
            System.assertEquals(true, mapResults2.get('Type'));
        }   
    }
}