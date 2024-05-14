@IsTest
public with sharing class lwc57ReinstatementUIFlow_TEST {
    static User testUserAdmin;
    static User testUserCE;
    static List<Program__c> lstProgram;
    static List<Treaty__c> lstTreaty;
    static List<Section__c> lstSection;
    static List<Reinstatement__c> lstReinstatement;
    static List<Account> lstAccount;
    static List<User> lstUsers = new List<User>();
    static SubSection__c subSec = new SubSection__c() ;

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
                TestFactory.createAccount(mapRecTypeId.get(AP_Constant.accRTReinsurer),'Account E','C_0005')
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
            insert lstProgram;
            
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
            subSec =TestFactory.createSubSection(lstSection[0].Id, 12,'2') ;

            insert subSec ;

            //create reinstatement for treaty type XL
            lstReinstatement = new List<Reinstatement__c> {

                TestFactory.createReinstatement(lstSection[2].Id, true, 40, 39, '1', '3'),

                TestFactory.createReinstatement(lstSection[2].Id, true, 34, 4, '1', '3'),

                TestFactory.createReinstatement(lstSection[3].Id, true, 420, 9, '1', '3'),

                TestFactory.createReinstatement(lstSection[3].Id, true, 3, 54, '1', '3'),

                TestFactory.createReinstatement(lstSection[4].Id, true, 3, 54, '1', '3')
            };
            lstReinstatement[0].Sub_Section__c = subSec.Id ;
            lstReinstatement[2].Key_Insert_Update_Reinstatement__c = '007' ;
            
            insert lstReinstatement;
        }
    }

    @IsTest
    public static void test_getReinstatementsApiName(){
        System.runAs(testUserCE) {
            Test.startTest();
            List<Reinstatement__c> lstReins =  lwc57ReinstatementUIFlow.getReinstatementsApiName(lstSection[2].Id,subSec.Id);
            Test.stopTest();
            System.assertEquals(lstReins.size(),1);
        }
    }

    @IsTest
    public static void test_deleteReinstatementSelected(){
        System.runAs(testUserCE) {
            Test.startTest();
            List<Id> lstReinsId = new List<Id>() ;
            lstReinsId.add(lstReinstatement[2].Id) ;
            lwc57ReinstatementUIFlow.deleteReinstatementSelected(lstReinsId);
            Test.stopTest();
            System.assertEquals(lstReinstatement.size(),5);
        }
    }
}