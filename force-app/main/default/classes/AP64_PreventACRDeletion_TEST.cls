@IsTest
public with sharing class AP64_PreventACRDeletion_TEST {
    static User testUserAdmin;
    static User testUserCE;
    static List<User> lstUsers = new List<User>();
    static List<Account> lstAccount;
    static List<Contact> lstContact;
    static Map<String, Id> mapAccountRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectAcc});
    static List<AccountContactRelation> lstAccConToInsert = new List<AccountContactRelation>();

    static {
        //create User
        testUserAdmin = TestFactory.createUserWithRole('testUserAdminAP64', TestFactory.getProfileAdminId(), TestFactory.getCERoleId());
        testUserCE = TestFactory.createUser('testUserCEAP64', TestFactory.getProfileCEId());
        testUserCE.BypassVR__c=true ;
        testUserAdmin.BypassVR__c=true ;

        lstUsers.add(testUserAdmin);
        lstUsers.add(testUserCE);
 
        lstUsers[0].BypassTrigger__c = 'AP36_CreateSharingForContact;AP59_DeleteOldAccConRelation';
        lstUsers[1].BypassTrigger__c = 'AP36_CreateSharingForContact;AP59_DeleteOldAccConRelation';
        insert lstUsers;

        System.runAs(testUserAdmin){
            //create Account
            lstAccount = new List<Account> {
                    TestFactory.createAccount(mapAccountRecTypeId.get(AP_Constant.accRTReinsurer),'Account F (R)','C_0006'),
                    TestFactory.createAccount(mapAccountRecTypeId.get(AP_Constant.accRTReinsurer),'Reinsurer A (R)','C_0009')
            };
            insert lstAccount;
        }
            
        System.runAs(testUserCE){
            //create Reinsurer Contact
            lstContact = new List<Contact> {
                TestFactory.createContact('Account F - Reinsurer', 'ReinsurerPortal1', lstAccount[0].Id, '3', '25001;25002'),
                TestFactory.createContact('Account F - Reinsurer', 'ReinsurerPortal2', lstAccount[0].Id, '3', '25001;25002'),
                TestFactory.createContact('Account F - Reinsurer', 'ReinsurerPortal3', lstAccount[1].Id, '3', '25001;25002')
            };

            lstContact[0].Email = 'test@test.com';
            lstContact[1].Email = 'test@test.com';
            lstContact[2].Email = 'test@test.com';
       
            insert lstContact;

            //create acr
            lstAccConToInsert = new List<AccountContactRelation>{
                new AccountContactRelation(AccountId = lstAccount[1].Id,
                                            ContactId = lstContact[0].Id,
                                            Roles = 'PrincipalCedingCompany',
                                            IsActive = true),
                new AccountContactRelation(AccountId = lstAccount[0].Id,
                                            ContactId = lstContact[2].Id,
                                            Roles = 'PrincipalCedingCompany',
                                            IsActive = true)
            };

            insert lstAccConToInsert;
        }

        System.runAs(testUserAdmin){
            lstContact[0].Tech_ContactActivationSent__c = true;
            lstContact[1].Tech_ContactActivationSent__c = true;
            lstContact[2].Tech_ContactActivationSent__c = true;

            update lstContact;
        } 
    }

    @IsTest
    public static void testhandleBeforeDelete(){
        System.runAs(testUserCE) {
            Test.startTest();
                try{
                    delete lstAccConToInsert[0];
                }Catch(DmlException e){
                    system.assertEquals(true,e.getMessage() != null);
                }
            Test.stopTest();
        }
    }
}