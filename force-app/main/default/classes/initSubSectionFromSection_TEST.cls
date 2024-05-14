@isTest
public with sharing class initSubSectionFromSection_TEST {
    static User testUserAdmin;
    static User testUserCE;
    static List<Program__c> lstProgram;
    static List<Treaty__c> lstTreaty;
    static List<Section__c> lstSection;
    static List<Reinstatement__c> lstReinstatement;
    static List<Account> lstAccount;
    static List<User> lstUsers = new List<User>();
    static List<SubSection__c> lstSubSec = new List<SubSection__c>() ;
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
                TestFactory.createAccount(mapRecTypeId.get(AP_Constant.accRTPrincipalCedingCom),'Account A','C_0001')
            };
            insert lstAccount;

            //create Program
            lstProgram = new List<Program__c> {
                TestFactory.createProgram('TestProg1', '1', '1'
                                        , Date.today(), Date.today().addYears(1), '2', Date.today(), Date.today().addYears(1)
                                        , '2018', lstAccount[0].Id, '23002','2'
                                        , '25009')
            };
            insert lstProgram;

            //create Treaty
            lstTreaty = new List<Treaty__c> {
                TestFactory.createTreaty('TestTreaty1', 1, 'ref01', '3'
                                        , lstProgram[0].Id, '2', 34, '10', '2020-00000222', '1', '2', '2', '2', '2')
            };
            insert lstTreaty;

            //create Section
            lstSection = new List<Section__c> {
                TestFactory.createSection('TestSection1', '1.1', '22003', '20006', '9052'
                                        , 322, 34, lstProgram[0].Id, lstTreaty[0].Id, '3', '1'
                                        , true, '5', null, '23001', '1', '5', '2', '2')
            };
            insert lstSection;

            //create reinstatement for treaty type XL
            lstReinstatement = new List<Reinstatement__c> {

                TestFactory.createReinstatement(lstSection[0].Id, true, 40, 39, '1', '3')
            };
            
            insert lstReinstatement;
        }
    }

    @IsTest
    public static void test_initCondition(){
        System.runAs(testUserCE) {
            initSubSectionFromSection.ObjectContext obj = new initSubSectionFromSection.ObjectContext() ;
            obj.recordId = lstSection[0].Id ;
            List<initSubSectionFromSection.ObjectContext> lstObj = new List<initSubSectionFromSection.ObjectContext>{obj} ;
            Test.startTest();
            List<Object> lstResult =  initSubSectionFromSection.initCondition(lstObj);
            Test.stopTest();
            System.assertEquals(lstResult.size(),1);
        }
    }
}