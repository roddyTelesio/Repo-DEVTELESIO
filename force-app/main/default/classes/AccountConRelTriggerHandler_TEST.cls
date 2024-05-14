@IsTest
//Test RRA - 14052024 OKOK
public with sharing class AccountConRelTriggerHandler_TEST {
    static User testUserAdmin;
    static User testUserCE;
    static List<User> lstPortalUser = new List<User>();
    static List<User> lstUsers = new List<User>();
    static List<Account> lstAccount;
    static List<Contact> lstContact;
    static List<Id> lstIdContact = new List<Id>();
    static Map<String, Id> mapRecTypeIdRequest = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectRequest});
    static Map<String, Id> mapAccountRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectAcc});
    static Map<String, Id> mapSARecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectSpecialAcceptance});
    static List<AccountContactRelation> lstAccConToInsert = new List<AccountContactRelation>();
    static List<AccountContactRelation> lstACR = new List<AccountContactRelation>();
    static List<IntermediateACRRequest__c> lstIntObj = new List<IntermediateACRRequest__c>();
    static List<Id> lstIdAcc =new  List<Id>();
    static {
        //create User
        testUserAdmin = TestFactory.createUserWithRole('testUserAdmin', TestFactory.getProfileAdminId(), TestFactory.getCERoleId());
        testUserCE = TestFactory.createUser('testUserCE', TestFactory.getProfileCEId());
        User assignedToUser = TestFactory.createUserWithRole('TestAssignedTo', TestFactory.getProfileAdminId(),TestFactory.getHeadUGPRoleId());
        testUserAdmin.BypassVR__c=true ;

        lstUsers.add(testUserAdmin);
        lstUsers.add(testUserCE);
        lstUsers.add(assignedToUser);

        lstUsers[0].BypassTrigger__c = 'AP36_CreateSharingForContact;AP59_DeleteOldAccConRelation';
        lstUsers[1].BypassTrigger__c = 'AP36_CreateSharingForContact;AP59_DeleteOldAccConRelation';
        lstUsers[2].BypassTrigger__c = 'AP36_CreateSharingForContact;AP59_DeleteOldAccConRelation';
        insert lstUsers;

        System.runAs(testUserAdmin){
            Map<String, Id> mapRequestRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectRequest});

            //create Account
            lstAccount = new List<Account> {
                    TestFactory.createAccount(mapAccountRecTypeId.get(AP_Constant.accRTPrincipalCedingCom),'Account A (P)','C_0001'),
                    TestFactory.createAccount(mapAccountRecTypeId.get(AP_Constant.accRTPrincipalCedingCom),'Account B (P)','C_0002'),
                    TestFactory.createAccount(mapAccountRecTypeId.get(AP_Constant.accRTCoveredCedingCompany),'Account C ','C_0003'),
                    TestFactory.createAccount(mapAccountRecTypeId.get(AP_Constant.accRTCoveredCedingCompany),'Account D','C_0004'),
                    TestFactory.createAccount(mapAccountRecTypeId.get(AP_Constant.accRTBroker),'Account E (B)','C_0005'),
                    TestFactory.createAccount(mapAccountRecTypeId.get(AP_Constant.accRTReinsurer),'Account F (R)','C_0006'),
                    TestFactory.createAccount(mapAccountRecTypeId.get(AP_Constant.accRTBroker),'Broker A (B)','C_0007'),
                    TestFactory.createAccount(mapAccountRecTypeId.get(AP_Constant.accRTBroker),'Broker B (B)','C_0008'),
                    TestFactory.createAccount(mapAccountRecTypeId.get(AP_Constant.accRTReinsurer),'Reinsurer A (R)','C_0009')
            };
            insert lstAccount;
            
            for (Account acc : lstAccount){
                lstIdAcc.add(acc.Id);
            }

            lstAccount[0].EmailSA__c = 'test@test.com';

            lstAccount[0].Name = 'Test A (P)';
            lstAccount[1].Name = 'Test B (P)';
            lstAccount[2].Name = 'Test C (C)';
            lstAccount[3].Name = 'Test C (C)';
            lstAccount[4].Name = 'Test D (B)';
            lstAccount[5].Name = 'Test E (R)';
            lstAccount[6].Name = 'Test F (B)';
            lstAccount[7].Name = 'Test G (B)';
            lstAccount[8].Name = 'Test H (R)';
            update lstAccount;

            //create Ceding Portal Contact + Broker/Reinsurer Contact
            lstContact = new List<Contact> {
                TestFactory.createContact('Account D - Reinsurer', 'ReinsurerPortal', lstAccount[5].Id, '3', '25001;25002;25003;25017;25004;25005;25006;25007;25008;25009;25010;25011;25012;25013;25016;25014;25015'),
                TestFactory.createContact('Account E - Broker', 'BrokerPortal', lstAccount[4].Id, '3', '25001;25002;25003;25017;25004;25005;25006;25007;25008;25009;25010;25011;25012;25013;25016;25014;25015'),
                TestFactory.createContact('Account F - Reinsurer', 'ReinsurerPortal', lstAccount[5].Id, '3', '25001;25002;25003;25017;25004;25005;25006;25007;25008;25009;25010;25011;25012;25013;25016;25014;25015')
            };

            lstContact[0].Email = 'test@test.com';
            //lstContact[0].RecordType.DeveloperName = 'Broker_Reinsurer';
            lstContact[1].Email = 'test@test.com';
            //lstContact[1].RecordType.DeveloperName = 'Broker_Reinsurer';
            lstContact[2].Email = 'test@test.com';
            //lstContact[2].RecordType.DeveloperName = 'Broker_Reinsurer';
            
            insert lstContact;

            System.debug('lstAccount[1].Name == ' + lstAccount[1].Name);
            for(Contact con : lstContact){
                AccountContactRelation accCon = new AccountContactRelation();
                accCon.ContactId = con.Id;
                accCon.AccountId = lstAccount[1].Id;
                accCon.Roles = 'PrincipalCedingCompany';
                accCon.IsActive = true;
                lstAccConToInsert.add(accCon);
                lstIdContact.add(con.Id);
            }

            System.debug('lstAccConToInsert == ' + lstAccConToInsert);
            insert lstAccConToInsert;

            // Create IntObj
            lstIntObj = new List<IntermediateACRRequest__c> {
                    TestFactory.createIntermediateObject('NameIntObjA',lstAccount[1].Id, lstAccount[4].Id, lstAccount[5].Id, 'P&C', '25001', lstUsers[0].Id, lstContact[0].Id),
                    TestFactory.createIntermediateObject('NameIntObjB',lstAccount[1].Id, lstAccount[4].Id, lstAccount[5].Id, 'P&C', '25002', lstUsers[0].Id, lstContact[0].Id),
                    TestFactory.createIntermediateObject('NameIntObjC',lstAccount[1].Id, lstAccount[4].Id, lstAccount[5].Id, 'P&C', '25003', lstUsers[0].Id, lstContact[0].Id),
                    TestFactory.createIntermediateObject('NameIntObjD',lstAccount[1].Id, lstAccount[4].Id, lstAccount[5].Id, 'P&C', '25004', lstUsers[0].Id, lstContact[0].Id),
                    TestFactory.createIntermediateObject('NameIntObjE',lstAccount[1].Id, lstAccount[4].Id, lstAccount[5].Id, 'P&C', '25005', lstUsers[0].Id, lstContact[0].Id)
            };
            insert lstIntObj;

            //Create AccountContactRelation
           lstACR = [SELECT Id, toLabel(Contact.Nature__c), Contact.MacroLoB__c, Contact.AccountId, AccountId, Account.RecordTypeId, ContactId, Roles, Tech_AccountName__c FROM AccountContactRelation  WHERE ContactId IN :lstIdContact AND AccountId IN: lstIdAcc AND IsActive = TRUE AND Contact.MacroLoB__c != NULL AND Contact.Nature__c != NULL];

        }
        System.runAs(testUserAdmin) {
            lstPortalUser = new List<User>{
                    TestFactory.createUser('testUserCedingPortal', TestFactory.getProfileInternalId()),
                    TestFactory.createUser('testUserBrokerPortal', TestFactory.getProfileExternalId()),
                    TestFactory.createUser('testUserReinsurerPortal', TestFactory.getProfileExternalId())
            };

            lstPortalUser[0].ContactId = lstContact[0].Id;
            lstPortalUser[1].ContactId = lstContact[1].Id;
            lstPortalUser[2].ContactId = lstContact[2].Id;
            lstPortalUser[0].BypassTrigger__c = 'AP36_CreateSharingForContact;AP59_DeleteOldAccConRelation';
            lstPortalUser[1].BypassTrigger__c = 'AP36_CreateSharingForContact;AP59_DeleteOldAccConRelation';
            lstPortalUser[2].BypassTrigger__c = 'AP36_CreateSharingForContact;AP59_DeleteOldAccConRelation';

            insert lstPortalUser;
        }
    }

    @IsTest
    public static void testhandleAfterDelete(){
        System.runAs(testUserAdmin) {
            Test.startTest();
            delete lstAccConToInsert;
            Test.stopTest();

        }
    }
}