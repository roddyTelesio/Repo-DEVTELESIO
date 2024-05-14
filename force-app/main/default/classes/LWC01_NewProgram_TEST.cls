@IsTest
public with sharing class LWC01_NewProgram_TEST {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Test class for LWC01_NewProgram
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
   static List<Program__c> lstProgramEdit;
   static List<CoveredCedingCompany__c> lstCovCedCom;
   static List<Treaty__c> lstTreaty;
   static List<PoolTreatySection__c> lstPoolTreatySections;
   static List<Section__c> lstSection;
   static List<Reinstatement__c> lstReinstatement;
   static List<Account> lstAccount;
   static List<Pool__c> lstPool;
   static List<Section__c> lstRelatedSections;
   static List<User> lstUsers = new List<User>();
   static List<Request__c> lstLeadRequests;
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

           CS_TreatyReference__c treatyRefCustomSetting = new CS_TreatyReference__c();
           treatyRefCustomSetting.ReferenceSequence__c = '00000221';
           insert treatyRefCustomSetting;

           //create Account
           lstAccount = new List<Account> {
               TestFactory.createAccount(mapRecTypeId.get(AP_Constant.accRTPrincipalCedingCom),'Account A','C_0001'),
               TestFactory.createAccount(mapRecTypeId.get(AP_Constant.accRTPrincipalCedingCom),'Account B','C_0002'),
               TestFactory.createAccount(mapRecTypeId.get(AP_Constant.accRTCoveredCedingCompany),'Account C','C_0003'),
               TestFactory.createAccount(mapRecTypeId.get(AP_Constant.accRTCoveredCedingCompany),'Account D','C_0004'),
               TestFactory.createAccount(mapRecTypeId.get(AP_Constant.accRTReinsurer),'Account E','C_0005'),
               TestFactory.createAccount(mapRecTypeId.get(AP_Constant.accRTBroker),'Account F','C_0006')
           };

            for(Account acc : lstAccount){
               acc.IsActive__c = true;
            }

           insert lstAccount;

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
                                       , Date.today(), Date.today().addYears(1), '1', Date.newInstance(2020, 06, 31), Date.newInstance(2023, 06, 31)
                                       , '2018', lstAccount[1].Id, '23001', '2', '25001'),

               TestFactory.createProgram('TestProg3', '1', '3'
                                       , Date.today(), Date.today().addYears(1), '2',Date.newInstance(2019, 12, 31), Date.newInstance(2022, 12, 31)
                                       , '2020', lstAccount[1].Id, '23001', '1', '25001')
            };
            insert lstProgram;

            lstProgramEdit = new List<Program__c>{
               TestFactory.createProgram('TestProgChange', '1', '3'
                                          , Date.today(), Date.today().addYears(1), '2', Date.today(), Date.today().addYears(1)
                                          , '2020', lstAccount[1].Id, '23001', '2', '25001'),

               TestFactory.createProgram('TestProgChange2', '2', '2'
                                          , Date.today(), Date.today().addYears(1), '1', Date.today(), Date.today().addYears(1)
                                          , '2018', lstAccount[1].Id, '23001', '2', '25001')
            };

            //create Treaty
            lstTreaty = new List<Treaty__c> {
                TestFactory.createTreaty('TestTreaty1', 1, 'ref01', '3'
                                            , lstProgram[0].Id, '2', 34, '10', '2020-00000222', '1', '2', '2', '2', '2'),

                TestFactory.createTreaty('TestTreaty2', 2, 'ref02', '2', lstProgram[0].Id
                                            , '1', 44, '44', '2020-00000222', '2', '2', '2', '2', '2'),

                TestFactory.createTreaty('TestTreaty3', 3, 'ref03', '2'
                                            , lstProgram[1].Id, '2', 89, '44', '2020-00000222', '3', '2', '2', '2', '2'),
                TestFactory.createTreaty('TestTreaty3', 3, 'ref03', '2'
                                            , lstProgram[1].Id, '2', 89, '44', '2018-00000222', '3', '2', '2', '2', '2') // MRA 930 Correction class test 
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
                                       , 55, 87, lstProgram[1].Id, lstTreaty[2].Id, '1', '1'
                                       , true, '1',null, '23001', '1', '5', '2', '2')
            };
            insert lstSection;

            lstRelatedSections = new List<Section__c>{
                TestFactory.createSection('TestRelatedSection1', '3.2', '22003', '20006', '9052'
                                        , 322, 34, lstProgram[2].Id, lstTreaty[2].Id, '3', '2'
                                        , true, '5', lstSection[3].Id, '23001', '1', '5', '2', '2'),
                TestFactory.createSection('TestRelatedSection2', '3.2', '22003', '20006', '9052'
                                        , 322, 34, lstProgram[0].Id, lstTreaty[0].Id, '3', '2'
                                        , true, '5', lstSection[0].Id, '23001', '1', '5', '2', '2')
            };
            insert lstRelatedSections;

            lstCovCedCom = new List<CoveredCedingCompany__c> {
                TestFactory.createCovCedCom(lstAccount[2].Id, lstProgram[0].Id, true,null
                                                ,false,null,false,null,null),

                TestFactory.createCovCedCom(lstAccount[3].Id, lstProgram[0].Id, true,null
                                                ,false,null,false,null,null),

                TestFactory.createCovCedCom(lstAccount[2].Id, lstProgram[0].Id, false, lstTreaty[1].Id
                                                ,true,null,false,null,null),

                TestFactory.createCovCedCom(lstAccount[2].Id, lstProgram[0].Id, false, lstTreaty[0].Id
                                                ,true,null,false,null,null),

                TestFactory.createCovCedCom(lstAccount[3].Id, lstProgram[0].Id, false, lstTreaty[0].Id
                                                ,false, lstSection[0].Id,true,null,null)
            };
            insert lstCovCedCom;

            //create Pool Treaty Section
            lstPoolTreatySections = new List<PoolTreatySection__c> {
                TestFactory.createPoolTreatySection(lstPool[0].Id, lstTreaty[0].Id, null
                            , false,true, 32, null),

                TestFactory.createPoolTreatySection(lstPool[1].Id, lstTreaty[0].Id, null
                                , false,true, 40, null)
            };
            insert lstPoolTreatySections;

            //create reinstatement for treaty type XL
            lstReinstatement = new List<Reinstatement__c> {
                TestFactory.createReinstatement(lstSection[2].Id, true, 40, 39, '1'
                                                , '3'),

                TestFactory.createReinstatement(lstSection[2].Id, true, 34, 54, '1'
                        , '3')
            };
            insert lstReinstatement;

            //create lead requests
            lstLeadRequests = new List<Request__c>{
                TestFactory.createLeadRequest(lstProgram[0].Id, lstTreaty[1].Id, lstAccount[5].Id, lstAccount[4].Id, '2', '1',
                                            mapRecTypeIdRequest.get(AP_Constant.reqRTLead), '1', 'Answered',lstSection[1].Id)
            };
        }
    }

    @IsTest
    public static void testSaveProgramRecord(){
        System.runAs(testUserCE) {
            Test.startTest();
                lstTreaty[0].AGRe_Cession__c = 100.00;
                lstTreaty[1].AGRe_Cession__c = 100.00;
                update lstTreaty;
                List<String> lstAccId = new List<String>{lstAccount[2].Id, lstAccount[3].Id};
                List<Program__c> lstNewProgram = new List<Program__c>();

                Map<String, Object> mapSaveResult = (Map<String, Object>) LWC01_NewProgram.saveProgramRecord(lstProgramEdit[0], lstAccId, null, false);
                lstNewProgram = [SELECT Id, Name FROM Program__c WHERE Name = :lstProgramEdit[0].Name];

                for(Program__c program : lstNewProgram){
                    System.assertEquals('TestProgChange', program.Name);
                }

                Map<String, Object> mapSaveResultEdit = (Map<String, Object>) LWC01_NewProgram.saveProgramRecord(lstProgramEdit[0], lstAccId, lstProgram[0].Id, true);
                lstNewProgram = [SELECT Id, Name FROM Program__c WHERE Id = :lstProgram[0].Id];

                for(Program__c program : lstNewProgram){
                    System.assertEquals('TestProgChange', program.Name);
                }
                
                Map<String, Object> mapSaveResultCopy = (Map<String, Object>) LWC01_NewProgram.saveProgramRecord(lstProgramEdit[1], lstAccId, lstProgram[0].Id, false);
                lstNewProgram = [SELECT Id, Name FROM Program__c WHERE Name = :lstProgramEdit[1].Name];
                System.assertEquals(1, lstNewProgram.size());
            Test.stopTest();

            System.assertEquals('Program Created Successfully', mapSaveResult.get('Success'));
            System.assertEquals('Program Created Successfully', mapSaveResultEdit.get('Success'));
            //System.assertEquals('Program Created Successfully', mapSaveResultCopy.get('Success'));
        }
    }

    @IsTest
    public static void testGetCoveredCedingCompanies(){
        System.runAs(testUserCE) {
            Test.startTest();
                lstCovCedCom = LWC01_NewProgram.getCoveredCedingCompanies(lstProgram[0].Id);
            Test.stopTest();
            System.assertEquals(2, lstCovCedCom.size());
        }
    }

    @IsTest
    public static void testIfProgramIsEmpty(){
        System.runAs(testUserCE) {
            Test.startTest();
                Boolean result = LWC01_NewProgram.isProgramEmpty(lstProgram[0].UwYear__c, lstProgram[0].PrincipalCedingCompany__c);
                Boolean result2 = LWC01_NewProgram.isProgramEmpty('2010', lstAccount[2].Id);
            Test.stopTest();
            System.assertEquals(false, result);
            System.assertEquals(true, result2);
        }
    }

    @IsTest
    public static void testGetAllExistedCoveredCedingComForTreaty(){
        System.runAs(testUserCE) {
            Test.startTest();
                List<Id> lstResult = LWC01_NewProgram.getAllExistedCoveredCedingComForTreaty(lstProgram[0].Id);
            Test.stopTest();
            System.assertEquals(1, lstResult.size());
        }
    }

    @IsTest
    public static void testGetProgram(){
        System.runAs(testUserCE) {
            Test.startTest();
                Program__c progDetails = null;
                progDetails = LWC01_NewProgram.getProgram(lstProgram[0].Id);
            Test.stopTest();
            System.assertNotEquals(null, progDetails);
            System.assertEquals('TestProg1', progDetails.Name);
        }
    }

    @IsTest
    public static void testCheckProgramName(){
        System.runAs(testUserCE) {
            Test.startTest();
            Boolean result = LWC01_NewProgram.checkProgramName(lstProgram[0].Name, lstProgram[1].Id, false, lstProgram[0].UwYear__c);
            Boolean result2 = LWC01_NewProgram.checkProgramName(lstProgram[1].Name, lstProgram[1].Id, false, '2015');
            Test.stopTest();
            System.assertEquals(true, result);
            System.assertEquals(false, result2);
        }
    }

    @IsTest
    public static void testCheckForFebruaryLeapYear(){
        System.runAs(testUserCE) {
            Test.startTest();
                Integer result = LWC01_NewProgram.checkForFebruaryLeapYear(lstProgram[2].LTAInceptionDate__c, lstProgram[2].LTAExpiryDate__c);
                Integer result2 = LWC01_NewProgram.checkForFebruaryLeapYear(lstProgram[1].LTAInceptionDate__c, lstProgram[2].LTAExpiryDate__c);
            Test.stopTest();
            System.assertEquals(true, result > 0);
            System.assertEquals(false, result2 > 0);
        }
    }

    @IsTest
    public static void testCheckIfLeadPresent(){
        System.runAs(testUserCE) {
            Test.startTest();
                Boolean result = LWC01_NewProgram.checkIfLeadPresent(lstprogram[0].Id);
                Boolean result2 = LWC01_NewProgram.checkIfLeadPresent(lstprogram[1].Id);
            Test.stopTest();
            System.assertEquals(false, result2);
        }
    }

    @IsTest
    public static void testGetCoveredCedingComp(){
        System.runAs(testUserCE) {
            Test.startTest();
                Integer result = LWC01_NewProgram.getCoveredCedingComp('Account', 'Name', 'Account', null).size();
            Test.stopTest();
            System.assertEquals(2, result);
        }
    }
}