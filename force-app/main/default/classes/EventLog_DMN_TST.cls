/***
* @author      Telesio Dev
* @date        09/06/2022
* @description Event Log test class
* @group       EventLog
* @see         EventLog_CST, EventLog_DMN
*
***/
@isTest
public with sharing class EventLog_DMN_TST {

    static User testUserAdmin;
    static User testUserCE;


    static List<Account> lstAccount;
    static List<Program__c> lstProgram;
    static List<EventLog__c> lstEventLog = new List<EventLog__c>(); 
    static Map<String, Id> mapRecTypeIdRequest = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectRequest});
    static EventLogSettings__c eventLogSettings; 
    static List<User> lstUsers = new List<User>();
    static List<Classeur__c> lstClasseurs; 

    static{
        testUserAdmin = TestFactory.createUser('testUserAdmin', TestFactory.getProfileAdminId());
        testUserCE = TestFactory.createUser('testUserCE', TestFactory.getProfileCEId());
        testUserCE.BypassTrigger__c = 'AP38_CreateSharingForRequest;AP53_UpdateSAStatus;AP43_DeleteClonedRequests;AP42_DeleteDocumentVisibility';
        lstUsers.add(testUserAdmin);
        lstUsers.add(testUserCE);
        insert lstUsers;
        
        eventLogSettings = new EventLogSettings__c(
            CanAfterInsert__c = true
            , DataFactoryNotify__c = true
        );

        insert eventLogSettings; 

        Map<String, Id> mapRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{
                AP_Constant.sObjectAcc
        });
        //create Account
        lstAccount = new List<Account> {
            TestFactory.createAccount(mapRecTypeId.get(AP_Constant.accRTPrincipalCedingCom),'Account A','C_0001')
        };
        insert lstAccount;

        //create Program
        lstProgram = new List<Program__c>{
            TestFactory.createProgram('TestProg1', '1', '1'
                    , Date.today(), Date.today().addYears(1), '2', Date.today(), Date.today().addYears(1)
                    , '2018', lstAccount[0].Id, '23002', '1', '25009')
        };
        lstProgram[0].LossDepositLevel__c = 'Program';
        insert lstProgram;


        lstClasseurs = new List<Classeur__c>{
            ClasseurFactory.createClasseur(
                'Classeur1'
                , lstAccount[0].Id
                , lstProgram[0].Id
            )
        };

        insert lstClasseurs; 
    }

    @IsTest
    public static void testOnDataFactoryNotify(){
        
        lstEventLog.add(
            ClasseurFactory.createEventLog('TestClass', EventLog_CST.CONTEXT_DF ,lstClasseurs[0].Id, 'String Request', 'String response')
        );
        System.runAs(testUserCE) {
            Test.startTest();
                insert lstEventLog; 
            Test.stopTest(); 
        }
    }   

}