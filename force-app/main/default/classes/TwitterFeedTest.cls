@IsTest
public with sharing class TwitterFeedTest {
    static User testUserAdmin;
    static List<User> lstUsers = new List<User>();
    static List<Account> lstAccount;
    static Map<String, Id> mapAccountRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectAcc});


    static {
        //create User
        testUserAdmin = TestFactory.createUserWithRole('testUserAdminAP64', TestFactory.getProfileAdminId(), TestFactory.getCERoleId());
        testUserAdmin.BypassTrigger__c = 'AP36_CreateSharingForContact;AP59_DeleteOldAccConRelation';
        insert testUserAdmin;

        System.runAs(testUserAdmin){
            //create Account
            lstAccount = new List<Account> {
                    TestFactory.createAccount(mapAccountRecTypeId.get(AP_Constant.accRTReinsurer),'Account F (R)','C_0006'),
                    TestFactory.createAccount(mapAccountRecTypeId.get(AP_Constant.accRTReinsurer),'Reinsurer A (R)','C_0009')
            };

            lstAccount[0].AccountNumber = 'salesforce';
            insert lstAccount;
        }
    }

    @IsTest
    public static void runTests(){
        System.runAs(testUserAdmin) {
            Test.startTest();
                String url = TwitterFeed.getCommunityURL();
                System.assertEquals(TwitterFeed.getTwitterScreenName(lstAccount[0].Id, 'Account', 'AccountNumber'), 'salesforce');
                System.assertEquals(TwitterFeed.getTwitterScreenName(lstAccount[0].Id, 'Account', 'John__c'), null);
                System.assertEquals(TwitterFeed.getTwitterScreenName(lstAccount[1].Id, 'Account', 'AccountNumber'), '');
            Test.stopTest();
        }
    }
}