/**************************************************************************************
-- - Author        : Telesio
-- - Description   : test class for AP61_CreateKeySharingContact
--
-- Maintenance History:
--
-- Date          Name  Version  Remarks
-- -----------   ----  -------  -------------------------------------------------------
-- 21-AUG-2022  RRA   1.0      Initial version
--------------------------------------------------------------------------------------
**************************************************************************************/
@IsTest
public with sharing class AP61_CreateKeySharingContact_TEST {
    static User testUserAdmin;
    static User testUserCE;
    static User testInactiveUsr;
    static List<User> lstPortalUser = new List<User>();
    static List<User> lstUsers = new List<User>();
    static List<Account> lstAccount;
    static List<Contact> lstContact;
    static List<Id> lstIdContact = new List<Id>();
    static List<Id> lstIdContactBroker = new List<Id>();
    static List<Id> lstIdContactReinsurer = new List<Id>();
    static Map<String, Id> mapRecTypeIdRequest = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectRequest});
    static Map<String, Id> mapAccountRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectAcc});
    static Map<String, Id> mapSARecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectSpecialAcceptance});
    static List<AccountContactRelation> lstAccConToInsert = new List<AccountContactRelation>();
    static List<AccountContactRelation> lstAccConToInsertBroker = new List<AccountContactRelation>();
    static List<AccountContactRelation> lstAccConToInsertReinsurer = new List<AccountContactRelation>();
    static List<AccountContactRelation> lstACR = new List<AccountContactRelation>();
    static List<IntermediateACRRequest__c> lstIntObj = new List<IntermediateACRRequest__c>();
    static List<Id> lstIdAcc =new  List<Id>();
    static {
        //create User
        testUserAdmin = TestFactory.createUserWithRole('testUserAdmin', TestFactory.getProfileAdminId(), TestFactory.getCERoleId());
        testUserCE = TestFactory.createUser('testUserCE', TestFactory.getProfileCEId());
        User assignedToUser = TestFactory.createUserWithRole('TestAssignedTo', TestFactory.getProfileAdminId(),TestFactory.getHeadUGPRoleId());

        //05/05/2022 - Updating user to trigger UserTriggerHandler
        testInactiveUsr = TestFactory.createUserWithRole('testUserAdmin', TestFactory.getProfileAdminId(), TestFactory.getCERoleId());
        testInactiveUsr.isActive = false;
        testUserAdmin.BypassVR__c=true ;


        lstUsers.add(testUserAdmin);
        lstUsers.add(testUserCE);
        lstUsers.add(assignedToUser);
        lstUsers.add(testInactiveUsr);

        //lstUsers[0].BypassTrigger__c = 'AP36_CreateSharingForContact;AP59_DeleteOldAccConRelation';
        lstUsers[1].BypassTrigger__c = 'AP36_CreateSharingForContact;AP59_DeleteOldAccConRelation';
        lstUsers[2].BypassTrigger__c = 'AP36_CreateSharingForContact;AP59_DeleteOldAccConRelation';

        insert lstUsers;

        lstUsers[3].isActive = true;
        update lstUsers;

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
                    TestFactory.createAccount(mapAccountRecTypeId.get(AP_Constant.accRTReinsurer),'Reinsurer A (R)','C_0009'),
                    TestFactory.createAccount(mapAccountRecTypeId.get(AP_Constant.accRTBroker),'Broker A (B)','C_0010'),
                    TestFactory.createAccount(mapAccountRecTypeId.get(AP_Constant.accRTBroker),'Broker B (B)','C_0011'),
                    TestFactory.createAccount(mapAccountRecTypeId.get(AP_Constant.accRTReinsurer),'Reinsurer A (R)','C_0012')
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
                TestFactory.createContact('Account F - Reinsurer', 'ReinsurerPortal', lstAccount[5].Id, '3', '25001;25002;25003;25017;25004;25005;25006;25007;25008;25009;25010;25011;25012;25013;25016;25014;25015'),
                TestFactory.createContact('Account G - Reinsurer', 'ReinsurerPortal', lstAccount[6].Id, '3', '25017;25004;25005;25006;25007;25008;25009;25010;25011;25012;25013;25016;25014;25015'),
                TestFactory.createContact('Account H - Reinsurer Change Nature', 'ReinsurerPortal', lstAccount[7].Id, '3', '25002')
            };

            lstContact[0].Email = 'test@test.com';
            //lstContact[0].RecordType.DeveloperName = 'Broker_Reinsurer';
            lstContact[1].Email = 'test@test.com';
            //lstContact[1].RecordType.DeveloperName = 'Broker_Reinsurer';
            lstContact[2].Email = 'test@test.com';
            //lstContact[2].RecordType.DeveloperName = 'Broker_Reinsurer';
            
            insert lstContact;

            //05/05/2022 - Update contacts to trigger contactTriggerHandler
            lstContact[3].MacroLoB__c = '25001';
            lstContact[4].Nature__c = '1';
            lstContact[4].AccountId = lstAccount[8].Id;
            update lstContact;

            System.debug('lstAccount[1].Name == ' + lstAccount[1].Name);

            //PCC
            for(Contact con : lstContact){
                AccountContactRelation accCon = new AccountContactRelation();
                accCon.ContactId = con.Id;
                accCon.AccountId = lstAccount[1].Id;
                accCon.Roles = 'PrincipalCedingCompany';
                accCon.IsActive = true;
                lstAccConToInsert.add(accCon);
                lstIdContact.add(con.Id);
            }


            //Broker
            for(Contact con : lstContact){
                AccountContactRelation accCon = new AccountContactRelation();
                accCon.ContactId = con.Id;
                accCon.AccountId = lstAccount[4].Id;
                accCon.Roles = 'Broker';
                accCon.IsActive = true;
                lstAccConToInsertBroker.add(accCon);
                lstIdContactBroker.add(con.Id);
            }

            //Reinsurer
            for(Contact con : lstContact){
                AccountContactRelation accCon = new AccountContactRelation();
                accCon.ContactId = con.Id;
                accCon.AccountId = lstAccount[5].Id;
                accCon.Roles = 'Reinsurer';
                accCon.IsActive = true;
                lstAccConToInsertReinsurer.add(accCon);
                lstIdContactReinsurer.add(con.Id);
            }

            System.debug('lstAccConToInsert == ' + lstAccConToInsert);
            System.debug('lstAccConToInsertBroker == ' + lstAccConToInsertBroker);
            System.debug('lstAccConToInsertReinsurer == ' + lstAccConToInsertReinsurer);

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
    public static void testcreateKeyElligibleForSharingContactForMacrolobNull_PCplusLife(){
        System.runAs(testUserAdmin) {
            Test.startTest();
            List<Id> lstConId= new List<Id>();
                //upsert lstAccConToInsert;
                for (AccountContactRelation acr: lstAccConToInsert){
                    lstConId.add(acr.ContactId);
                }

                AP61_CreateKeySharingContact.createKeyElligibleForSharingContact( lstConId, true, false, new Set<String>());
            Test.stopTest();

        }
    }

    @IsTest
    public static void testcreateKeyElligibleForSharingContactForMacrolobNotNull_PCplusLife(){
        System.runAs(testUserAdmin) {
            Test.startTest();
            List<Id> lstConId= new List<Id>();
            Set<String> setMacrolob= new Set<String>();
                //upsert lstAccConToInsert;

                for (AccountContactRelation acr: lstAccConToInsert){
                    lstConId.add(acr.ContactId);
                }


                AP61_CreateKeySharingContact.createKeyElligibleForSharingContact( lstConId, false, true, setMacrolob);
            Test.stopTest();

        }
    }
    
    @IsTest
    public static void testcreateKeyElligibleForSharingContactForNullMacrolob_PCplusLife(){
        System.runAs(testUserAdmin) {
            Test.startTest();
            List<Id> lstConId= new List<Id>();
                //upsert lstAccConToInsert;

                for (AccountContactRelation acr: lstAccConToInsert){
                    lstConId.add(acr.ContactId);
                }

                AP61_CreateKeySharingContact.createKeyElligibleForSharingContact( lstConId, false, true, new Set<String>());
            Test.stopTest();

        }
    }


    @IsTest
    public static void testcreateKeyElligibleForSharingContactForMacrolobNull_PCorLife(){
        System.runAs(testUserCE) {
            Test.startTest();
            List<Id> lstIdCon= new List<Id>();
            for (AccountContactRelation acr: lstAccConToInsert){
                lstIdCon.add(acr.ContactId);
            }
                AP61_CreateKeySharingContact.createKeyElligibleForSharingContact( lstIdContact, true, false, new Set<String>());
            Test.stopTest();

        }
    }

    @IsTest
    public static void testcreateKeyElligibleForSharingContactForMacrolobNotNullCompanyNullPCorLife(){
        System.runAs(testUserCE) {
            Test.startTest();
            List<Id> lstIdCon= new List<Id>();
            Set<String> setMacrolob= new Set<String>();
            for (AccountContactRelation acr: lstAccConToInsert){
                lstIdCon.add(acr.ContactId);
                //setMacrolob.add('25009');
                setMacrolob.add('25010');
            }
                AP61_CreateKeySharingContact.createKeyElligibleForSharingContact( lstIdContact, false, true, setMacrolob);
            Test.stopTest();

        }
    }

    
    @IsTest
    public static void testcreateKeyElligibleForSharingContactForMacrolobNullCompanyNullPCorLife(){
        System.runAs(testUserCE) {
            Test.startTest();
            List<Id> lstIdCon= new List<Id>();
            Set<String> setMacrolob= new Set<String>();
            for (AccountContactRelation acr: lstAccConToInsert){
                lstIdCon.add(acr.ContactId);
            }
                AP61_CreateKeySharingContact.createKeyElligibleForSharingContact( lstIdContact, false, true, new Set<String>());
            Test.stopTest();

        }
    }


    @IsTest
    public static void testgetCalculateKeysForUserOnlyCreateTrue(){
        System.runAs(testUserCE) {
            Test.startTest();
            List<Id> lstIdCon= new List<Id>();
            List<Id> lstIdAcc= new List<Id>();
            Set<String> setMacrolob= new Set<String>();
            for (AccountContactRelation acr: lstAccConToInsert){
                lstIdCon.add(acr.ContactId);
                lstIdAcc.add(acr.AccountId);
            }
                AP61_CreateKeySharingContact.getCalculateKeysForUserOnly( lstIdContact, true, false, new Set<String>(), lstIdAcc);
            Test.stopTest();

        }
    }

    @IsTest
    public static void testgetCalculateKeysForUserOnlyCreateFalse(){
        System.runAs(testUserCE) {
            Test.startTest();
            List<Id> lstIdCon= new List<Id>();
            List<Id> lstIdAcc= new List<Id>();
            Set<String> setMacrolob= new Set<String>();
            for (AccountContactRelation acr: lstAccConToInsert){
                lstIdCon.add(acr.ContactId);
                lstIdAcc.add(acr.AccountId);
            }
                AP61_CreateKeySharingContact.getCalculateKeysForUserOnly( lstIdContact, false, true, new Set<String>(), lstIdAcc);
            Test.stopTest();

        }
    }

    @IsTest
    public static void testgetCalculateKeysForUserOnlyMacrolobExists(){
        System.runAs(testUserCE) {
            Test.startTest();
            List<Id> lstIdCon= new List<Id>();
            List<Id> lstIdAcc= new List<Id>();
            Set<String> setMacrolob= new Set<String>();
            for (AccountContactRelation acr: lstAccConToInsert){
                lstIdCon.add(acr.ContactId);
                lstIdAcc.add(acr.AccountId);
            }
            setMacrolob.add('25010');
                AP61_CreateKeySharingContact.getCalculateKeysForUserOnly( lstIdContact, false, true, setMacrolob, lstIdAcc);
            Test.stopTest();

        }
    }

    @IsTest
    public static void testgetCalculateKeysForUserOnlyMacrolobAndBrokerExists(){
        System.runAs(testUserCE) {
            Test.startTest();
            List<Id> lstIdCon= new List<Id>();
            List<Id> lstIdAcc= new List<Id>();
            Set<String> setMacrolob= new Set<String>();
            for (AccountContactRelation acr: lstAccConToInsertBroker){
                lstIdCon.add(acr.ContactId);
                lstIdAcc.add(acr.AccountId);
            }

            setMacrolob.add('25010');
                AP61_CreateKeySharingContact.getCalculateKeysForUserOnly( lstIdContactBroker, true, false, setMacrolob, lstIdAcc);
            Test.stopTest();
        }
    }

     @IsTest
    public static void testgetCalculateKeysForUserOnlyMacrolobAndReinsurerExists(){
        System.runAs(testUserCE) {
            Test.startTest();
            List<Id> lstIdCon= new List<Id>();
            List<Id> lstIdAcc= new List<Id>();
            Set<String> setMacrolob= new Set<String>();
            for (AccountContactRelation acr: lstAccConToInsertReinsurer){
                lstIdCon.add(acr.ContactId);
                lstIdAcc.add(acr.AccountId);
            }

            setMacrolob.add('25010');
                AP61_CreateKeySharingContact.getCalculateKeysForUserOnly( lstIdContactReinsurer, true, false, setMacrolob, lstIdAcc);
            Test.stopTest();
        }
    }


    @IsTest
    public static void testDeleteRecordIntOjRequestShareFromContactMacrolobExists(){
        System.runAs(testUserCE) {
            Test.startTest();
            List<Id> lstIdCon= new List<Id>();
            Set<String> setMacrolob= new Set<String>();
            for (AccountContactRelation acr: lstAccConToInsert){
                lstIdCon.add(acr.ContactId);
                setMacrolob.add('25001');
            }
                AP61_CreateKeySharingContact.DeleteRecordIntOjRequestShareFromContact(lstIdContact, setMacrolob, null, null, true);
            Test.stopTest();

        }
    }


    @IsTest
    public static void testDeleteRecordIntOjRequestShareFromContactNatureExists(){
        System.runAs(testUserCE) {
            Test.startTest();
            List<Id> lstIdCon= new List<Id>();
            List<String> lstNature= new List<String>();
            for (AccountContactRelation acr: lstAccConToInsert){
                lstIdCon.add(acr.ContactId);
                lstNature.add('P&C');
            }
                AP61_CreateKeySharingContact.DeleteRecordIntOjRequestShareFromContact(lstIdContact, null, lstNature, null, false);
            Test.stopTest();
        }
    }

    @IsTest
    public static void testDeleteRecordIntOjRequestShareFromContactNatureAndMacrolobExists(){
        System.runAs(testUserCE) {
            Test.startTest();
            List<Id> lstIdCon= new List<Id>();
            Set<String> setMacrolob= new Set<String>();
            List<String> lstNature= new List<String>();
            for (AccountContactRelation acr: lstAccConToInsert){
                lstIdCon.add(acr.ContactId);
                lstNature.add('P&C');
                setMacrolob.add('25001');
            }
                AP61_CreateKeySharingContact.DeleteRecordIntOjRequestShareFromContact(lstIdCon, setMacrolob, lstNature, null, true);
            Test.stopTest();
        }
    }

    @IsTest
    public static void testDeleteRecordIntOjRequestShareFromContactPCCExists(){
        System.runAs(testUserCE) {
            Test.startTest();
            List<Id> lstIdCon= new List<Id>();
            Set<String> setMacrolob= new Set<String>();
            List<String> lstNature= new List<String>();
            List<AccountContactRelation> lstAccConToInsertPCC = new List<AccountContactRelation>();
            AccountContactRelation accConPcc = new AccountContactRelation();
            accConPcc.ContactId = lstContact[0].Id;
            accConPcc.AccountId = lstAccount[1].Id;
            accConPcc.Roles = 'PrincipalCedingCompany';
            accConPcc.IsActive = true;
            lstAccConToInsertPCC.add(accConPcc);
            lstIdCon.add(accConPcc.ContactId);
            lstNature.add('P&C');
            setMacrolob.add('25001');

           /* for (AccountContactRelation acr: lstAccConToInsert){
                lstIdCon.add(acr.ContactId);
                lstNature.add('P&C');
                setMacrolob.add('25001');
            }*/
                AP61_CreateKeySharingContact.DeleteRecordIntOjRequestShareFromContact(lstIdCon, setMacrolob, lstNature, null, true);
            Test.stopTest();
        }
    }

    @IsTest
    public static void testDeleteRecordIntOjFromACR(){
        System.runAs(testUserCE) {
            Test.startTest();
            List<Id> lstIdACR= new List<Id>();
            for (AccountContactRelation acr: lstACR){
                lstIdACR.add(acr.Id);
            }
                AP61_CreateKeySharingContact.DeleteRecordIntOjFromACR(lstIdContact, lstIdACR);
            Test.stopTest();
        }
    }

}