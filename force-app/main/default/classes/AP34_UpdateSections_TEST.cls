@IsTest
public with sharing class AP34_UpdateSections_TEST {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Test class for AP34_UpdateSections
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
    static List<Reinstatement__c> lstReinstatement;
    static List<User> lstUsers = new List<User>();

    static {
        //create User
        testUserAdmin = TestFactory.createUser('testUserAdmin', TestFactory.getProfileAdminId());
        testUserCE = TestFactory.createUser('testUserCE', TestFactory.getProfileCEId());
        lstUsers.add(testUserAdmin);
        lstUsers.add(testUserCE);
        insert lstUsers;

        System.runAs(testUserCE) {
            Map<String, Id> mapRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{
                    AP_Constant.sObjectAcc
            });

            //create Account
            lstAccount = new List<Account>{
                    TestFactory.createAccount(mapRecTypeId.get(AP_Constant.accRTPrincipalCedingCom), 'Account A', 'C_0001'),
                    TestFactory.createAccount(mapRecTypeId.get(AP_Constant.accRTPrincipalCedingCom), 'Account B', 'C_0002'),
                    TestFactory.createAccount(mapRecTypeId.get(AP_Constant.accRTCoveredCedingCompany), 'Account C', 'C_0003'),
                    TestFactory.createAccount(mapRecTypeId.get(AP_Constant.accRTCoveredCedingCompany), 'Account D', 'C_0004'),
                    TestFactory.createAccount(mapRecTypeId.get(AP_Constant.accRTBroker), 'Account E', 'C_0005'),
                    TestFactory.createAccount(mapRecTypeId.get(AP_Constant.accRTReinsurer), 'Account F', 'C_0006')
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
            lstTreaty = new List<Treaty__c>{
                    TestFactory.createTreaty('TestTreaty1', 1, 'ref01', '3'
                            , lstProgram[0].Id, '2', 34, '10', '2020-00000222', '1', '2', '2', '2', '2'),

                    TestFactory.createTreaty('TestTreaty2', 2, 'ref02', '2', lstProgram[0].Id
                            , '1', 44, '44', '2020-00000222', '2', '2', '2', '2', '2'),

                    TestFactory.createTreaty('TestTreaty3', 3, 'ref03', '2'
                            , lstProgram[1].Id, '2', 89, '44', '2020-00000222', '3', '2', '2', '2', '2')
            };
            insert lstTreaty;

            //create Section
            lstSection = new List<Section__c>{
                    TestFactory.createSection('TestSection1', '1.0', '22003', '20006', '9052'
                            , 322, 34, lstProgram[0].Id, lstTreaty[0].Id, '2', '1'
                            , true, '3', null, '23001', '1', '5', '2', '2'),

                    TestFactory.createSection('TestSection2', '2.0', '22003', '20006', '9052'
                            , 23, 5, lstProgram[1].Id, lstTreaty[2].Id, '2', '1'
                            , false, '3', null, '23001', '1', '5', '2', '2'),

                    TestFactory.createSection('TestSection1', '1.0', '22003', '20006', '9052'
                            , 322, 34, lstProgram[0].Id, lstTreaty[0].Id, '2', '1'
                            , true, '3', null, '23001', '1', '5', '2', '2'),

                    TestFactory.createSection('TestSection2', '2.0', '22003', '20006', '9052'
                            , 23, 5, lstProgram[1].Id, lstTreaty[2].Id, '2', '1'
                            , false, '3', null, '23001', '1', '5', '2', '2')
            };
            lstSection[0].Reinstatements__c = '3';
            lstSection[1].Reinstatements__c = '3';
            lstSection[2].Reinstatements__c = '1';
            lstSection[3].Reinstatements__c = '2';
            insert lstSection;

            lstReinstatement = new List<Reinstatement__c>{
                    TestFactory.createReinstatement(lstSection[0].Id, true, 1, null,null, '3'),
                    TestFactory.createReinstatement(lstSection[0].Id, false, 2, 30,'1', '3'),
                    TestFactory.createReinstatement(lstSection[1].Id, true, 1, null,null, '3'),
                    TestFactory.createReinstatement(lstSection[1].Id, false, 2, 55,'2', '3')
            };
        }
    }

    @IsTest
    public static void testInsertReinstatement(){
        System.runAs(testUserCE) {
            Test.startTest();
                insert lstReinstatement;
            Test.stopTest();

            Section__c section = [SELECT Id, Reinstatements__c, TECH_Reinstatement__c FROM Section__c WHERE Id= :lstSection[0].Id];
            System.assertEquals(true, section.TECH_Reinstatement__c.contains('30%'));
        }
    }

    @IsTest
    public static void testUpdateReinstatement(){
        System.runAs(testUserCE) {
            Test.startTest();
                insert lstReinstatement;

                Section__c sectionBefore = [SELECT Id, Reinstatements__c, TECH_Reinstatement__c FROM Section__c WHERE Id = :lstSection[0].Id];
               // System.assertEquals(true, sectionBefore.TECH_Reinstatement__c.contains('30%'));

                lstReinstatement[1].Percentage__c = 10;
                update lstReinstatement[1];
            Test.stopTest();

            Section__c section = [SELECT Id, Reinstatements__c, TECH_Reinstatement__c FROM Section__c WHERE Id = :lstSection[0].Id];
          //  System.assertEquals(true, section.TECH_Reinstatement__c.contains('10%'));
        }
    }

    @IsTest
    public static void testDeleteReinstatement(){
        System.runAs(testUserCE) {
            Test.startTest();
                insert lstReinstatement;

                delete lstReinstatement[3];
            Test.stopTest();

            Section__c section = [SELECT Id, Reinstatements__c, TECH_Reinstatement__c FROM Section__c WHERE Id = :lstSection[1].Id];
            System.assertEquals(true, section.TECH_Reinstatement__c != null);
        }
    }
}