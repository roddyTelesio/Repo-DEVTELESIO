@IsTest
public with sharing class LWC58_SubSectionUIFlow_TEST {
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

            lstSubSec =new List<SubSection__c>{
                TestFactory.createSubSection(lstSection[0].Id, 12,'2'),
                TestFactory.createSubSection(lstSection[0].Id, 13,'2')
            } ;
            insert lstSubSec ;
            lstSubSec[0].PrincipalSubSection__c = false;
            lstSubSec[1].PrincipalSubSection__c = false;
            update lstSubSec;
            
        }
    }

    @IsTest
    public static void test_getSubSection(){
        System.runAs(testUserCE) {
            Test.startTest();
            List<SubSection__c> lstSubSec1 =  LWC58_SubSectionUIFlow.getSubSection(lstSection[0].Id,lstSubSec[0].Id);
            Test.stopTest();
            System.assertEquals(lstSubSec1.size(),1);
        }
    }

    @IsTest
    public static void test_delSelectedSubSection(){
        System.runAs(testUserCE) {
            Test.startTest();
            List<Id> lstSubSecId= new List<Id>() ;
            lstSubSecId.add(lstSubSec[0].Id) ;
            LWC58_SubSectionUIFlow.delSelectedSubSection(lstSubSecId);
            Test.stopTest();
            //System.assertEquals(lstReinstatement.size(),1);
        }
    }
    
    @IsTest
    public static void test_updateSubSectionSelected(){
        System.runAs(testUserCE) {
            Test.startTest();
            List<SubSection__c> lstSub = LWC58_SubSectionUIFlow.updateSubSectionSelected(lstSubSec);
            Test.stopTest();
        }
    }
}