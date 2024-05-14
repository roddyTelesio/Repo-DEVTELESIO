@IsTest
public with sharing class LWC62_UpdateRefSeqOnTreaty_TEST {
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
                TestFactory.createTreaty('TestTreaty1', 1, '2020-00000220/', '3'
                                        , lstProgram[0].Id, '2', 34, '10', '2020-00000222', '1', '2', '2', '2', '2')
            };
            insert lstTreaty;
        }
    }
    
    @IsTest
    public static void testUpdateRefSeqOnTreaty(){
        System.runAs(testUserCE) {
            Test.startTest();
            lstTreaty[0].TreatyReference__c = '2020-00000221';
            update lstTreaty[0];
            Test.stopTest();
        }
    }
}