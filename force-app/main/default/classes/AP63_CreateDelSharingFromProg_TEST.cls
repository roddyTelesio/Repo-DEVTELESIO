/**************************************************************************************
-- - Author        : Telesio
-- - Description   : test class for AP63_CreateDelSharingFromProg

-- Maintenance History:
--
-- Date          Name  Version  Remarks
-- -----------   ----  -------  -------------------------------------------------------
-- 27-APRIL-2022  RRA   1.0      Initial version
--------------------------------------------------------------------------------------
**************************************************************************************/

@IsTest
public with sharing class AP63_CreateDelSharingFromProg_TEST {

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
    static List<AccountContactRelation> lstACRAcc = new List<AccountContactRelation>();
    static List<IntermediateACRRequest__c> lstIntObj = new List<IntermediateACRRequest__c>();
    static List<Id> lstBrokerId =new  List<Id>();
    static List<Id> lstReinsurerId =new  List<Id>();
    static List<AccountShare> lstAccShare = new List<AccountShare>();
    static List<Program__c> lstProgram;
    static List<CoveredCedingCompany__c> lstCovCedCom;
    static List<Pool__c> lstPool;
    static List<PoolTreatySection__c> lstPoolTreatySections;
    static List<Treaty__c> lstTreaty;
    static List<Request__c> lstRequests;
    static List<SpecialAcceptance__c> lstSpecialAcceptance;
    static List<Section__c> lstSection;
    static List<Id> lstIdProg = new List<Id>();
   

    static {
        //create User
        testUserAdmin = TestFactory.createUserWithRole('testUserAdmin', TestFactory.getProfileAdminId(), TestFactory.getCERoleId());
        testUserCE = TestFactory.createUser('testUserCE', TestFactory.getProfileCEId());
        User assignedToUser = TestFactory.createUserWithRole('TestAssignedTo', TestFactory.getProfileAdminId(),TestFactory.getHeadUGPRoleId());

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

            for (Account acc : lstAccount){
                String accName = acc.Name;
                String lastStrAcc= accName.right(3);
                if (lastStrAcc == '(B)'){
                   lstBrokerId.add(acc.Id);
                }
                if (lastStrAcc == '(R)') {
                   lstReinsurerId.add(acc.Id);
                }    
                
            }

            //create Ceding Portal Contact + Broker/Reinsurer Contact
            lstContact = new List<Contact> {
                TestFactory.createContact('Account E - Covered Ceding', 'CedingPortal', lstAccount[6].Id, '3', '25001;25002;25003;25017;25004;25005;25006;25007;25008;25009;25010;25011;25012;25013;25016;25014;25015'),
                TestFactory.createContact('Account E - Broker', 'BrokerPortal', lstAccount[4].Id, '3', '25001;25002;25003;25017;25004;25005;25006;25007;25008;25009;25010;25011;25012;25013;25016;25014;25015'),
                TestFactory.createContact('Account F - Reinsurer', 'ReinsurerPortal', lstAccount[5].Id, '3', '25001;25002;25003;25017;25004;25005;25006;25007;25008;25009;25010;25011;25012;25013;25016;25014;25015')
            };

            lstContact[0].Email = 'test@test.com';
            lstContact[0].BrokerReinsurer__c = 'Broker';
            lstContact[1].Email = 'test@test.com';
            lstContact[1].BrokerReinsurer__c = 'Broker';
            lstContact[2].Email = 'test@test.com';
            lstContact[2].BrokerReinsurer__c= 'Reinsurer';
            
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
           lstACR = [SELECT Id, toLabel(Contact.Nature__c), Contact.MacroLoB__c, Contact.AccountId, AccountId, Account.RecordTypeId, ContactId, Roles, Tech_AccountName__c FROM AccountContactRelation  WHERE ContactId IN :lstIdContact AND AccountId IN: lstBrokerId AND IsActive = TRUE AND Contact.MacroLoB__c != NULL AND Contact.Nature__c != NULL];
           lstACRAcc = [SELECT Id, toLabel(Contact.Nature__c), Contact.MacroLoB__c, Contact.AccountId, AccountId, Account.RecordTypeId, ContactId, Roles, Tech_AccountName__c FROM AccountContactRelation  WHERE ContactId IN :lstIdContact AND AccountId IN: lstReinsurerId AND IsActive = TRUE AND Contact.MacroLoB__c != NULL AND Contact.Nature__c != NULL];

        }

        List<AccountContactRelation> lstAccCon = [SELECT Id, AccountId, Account.RecordTypeId
                    , Contact.Account.RecordTypeId, Roles
                    , ContactId, Contact.MacroLoB__c
                    , Contact.Nature__c, IsDirect
            FROM AccountContactRelation];

            for(AccountContactRelation accCon : lstAccCon){
                accCon.IsActive = true;

                if(accCon.AccountId == lstAccount[4].Id){
                    accCon.Roles = 'Broker';
                }
                else if(accCon.AccountId == lstAccount[5].Id){
                    accCon.Roles = 'RiskCarrier';
                }
                else if(accCon.AccountId == lstAccount[0].Id){
                    accCon.Roles = 'PrincipalCedingCompany';
                }
            }

            //update lstAccCon;

            //Create Account Share for CE User - testUserCE
            for(Account acc : lstAccount){
                AccountShare accShare = new AccountShare();
                accShare.UserOrGroupId = testUserCE.Id;
                accShare.AccountId = acc.Id;
                accShare.AccountAccessLevel = 'Edit';
                accShare.OpportunityAccessLevel = 'Edit';
                lstAccShare.add(accShare);
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
        

        System.runAs(testUserAdmin){
      //create Pool
            lstPool = new List<Pool__c>{
                    TestFactory.createPool('Pool A', 78, '2020', lstUsers[2].Id),
                    TestFactory.createPool('Pool B', 78, '2020', lstUsers[2].Id)
            };

            lstPool[0].SA_Email__c = 'test@test.com';
            lstPool[1].SA_Email__c = 'test@test.com';
            insert lstPool;

            //create Program
            lstProgram = new List<Program__c> {
                    TestFactory.createProgram('TestProg1', '1', '1'
                            , Date.today(), Date.today().addYears(1), '2', Date.today(), Date.today().addYears(1)
                            , '2020', lstAccount[0].Id, '23002','2'
                            , '25009'),

                    TestFactory.createProgram('TestProg2', '2', '2', Date.today()
                            , Date.today().addYears(1), '1', Date.today(), Date.today().addYears(1), '2020'
                            , lstAccount[0].Id, '23001', '2', '25001'),

                    TestFactory.createProgram('TestProg3', '1', '3', Date.today()
                            , Date.today().addYears(1), '2', Date.today(), Date.today().addYears(1), '2020'
                            , lstAccount[1].Id, '23001', '1', '25001')
            };

            insert lstProgram;
            lstProgram[0].Name = 'TestProg11';
            lstProgram[0].Macro_L_O_B__c = '25010';
            lstProgram[0].Nature__c = '23002';
            lstProgram[1].Name = 'TestProg22';
            lstProgram[1].Macro_L_O_B__c = '25009';
            lstProgram[1].Nature__c = '23002';
            lstProgram[2].Name = 'TestProg33';
            lstProgram[2].Macro_L_O_B__c = '25001';
            lstProgram[2].Nature__c = '23001';

            update lstProgram;

            for (Program__c prog : lstProgram){
                lstIdProg.add(prog.Id);
            }

            lstCovCedCom = new List<CoveredCedingCompany__c> {
                    TestFactory.createCovCedCom(lstAccount[3].Id, lstProgram[0].Id, true,null
                            ,false,null,false,null,null),

                    TestFactory.createCovCedCom(lstAccount[3].Id, lstProgram[1].Id, true,null
                            ,false,null,false,null,null),

                    TestFactory.createCovCedCom(lstAccount[3].Id, lstProgram[2].Id, true,null
                            ,false,null,false,null,null),

                    TestFactory.createCovCedCom(lstAccount[2].Id, lstProgram[0].Id, true,null
                            ,false,null,false,null,null),

                    TestFactory.createCovCedCom(lstAccount[2].Id, lstProgram[2].Id, true,null
                            ,false,null,false,null,null),

                    TestFactory.createCovCedCom(lstAccount[2].Id, lstProgram[2].Id, true,null
                            ,false,null,false,null,null)

            };
            insert lstCovCedCom;

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

            //create Pool Treaty Section
            lstPoolTreatySections = new List<PoolTreatySection__c> {
                    TestFactory.createPoolTreatySection(lstPool[0].Id, lstTreaty[1].Id, null
                            , false, true, 32, null),

                    TestFactory.createPoolTreatySection(lstPool[1].Id, lstTreaty[0].Id, null
                            , false, true, 40, null)
            };
            insert lstPoolTreatySections;

            lstSpecialAcceptance = new List<SpecialAcceptance__c> {
                TestFactory.createSpecialAcceptance(mapSARecTypeId.get(AP_Constant.saRTLife), lstProgram[0].Id, lstAccount[0].Id, 'TestSA1'
                , '2020', 'Setup', null, '2020-23-00000000', true, false, '1', null
                , null, '1','20043','Capacity', lstAccount[2].Id),

                TestFactory.createSpecialAcceptance(mapSARecTypeId.get(AP_Constant.saRTPC), lstProgram[1].Id, lstAccount[1].Id, 'TestSA1'
                , '2020', 'Setup', null, '2020-23-00000001', true, false, '1', null
                , null, '2','20043','Capacity', lstAccount[2].Id),

                TestFactory.createSpecialAcceptance(mapSARecTypeId.get(AP_Constant.saRTLife), lstProgram[0].Id, lstAccount[0].Id, 'TestSA1'
                , '2020', 'Setup', null, '2020-23-00000002', true, false, '1', null
                , null, '1','20043','Capacity', lstAccount[2].Id)
            };

            insert lstSpecialAcceptance;

            //create Request
            lstRequests = new List<Request__c>{
                    TestFactory.createRequest(lstProgram[0].Id, lstTreaty[0].Id, lstAccount[4].Id, lstAccount[5].Id, '1', '3',
                            mapRecTypeIdRequest.get(AP_Constant.reqRTQuote), '2', 'Setup', lstSection[0].Id),

                    TestFactory.createRequest(lstProgram[1].Id, lstTreaty[2].Id, lstAccount[4].Id, lstAccount[5].Id, '2', '1',
                            mapRecTypeIdRequest.get(AP_Constant.reqRTQuote), '2', 'Setup', lstSection[1].Id),

                    TestFactory.createRequest(lstProgram[0].Id, lstTreaty[0].Id, lstAccount[4].Id, lstAccount[5].Id, '1', '3',
                            mapRecTypeIdRequest.get(AP_Constant.reqRTPlacement), '2', 'Setup', lstSection[0].Id),

                    TestFactory.createRequest(lstProgram[1].Id, lstTreaty[2].Id, lstAccount[4].Id, lstAccount[5].Id, '2', '1',
                            mapRecTypeIdRequest.get(AP_Constant.reqRTPlacement), '2', 'Setup', lstSection[0].Id),

                    TestFactory.createRequest(lstProgram[0].Id, lstTreaty[0].Id, lstAccount[4].Id, lstAccount[5].Id, '1', '3',
                            mapRecTypeIdRequest.get(AP_Constant.reqRTSigning), '2', 'Setup', lstSection[0].Id),

                    TestFactory.createRequest(lstProgram[1].Id, lstTreaty[2].Id, lstAccount[4].Id, lstAccount[5].Id, '2', '1',
                            mapRecTypeIdRequest.get(AP_Constant.reqRTSigning), '2', 'Setup', lstSection[1].Id),

                    TestFactory.createRequest(lstProgram[0].Id, lstTreaty[0].Id, lstAccount[4].Id, lstAccount[5].Id, '1', '3',
                                            mapRecTypeIdRequest.get(AP_Constant.reqRTSA), '2', 'Sent',lstSection[0].Id),

                    TestFactory.createRequest(lstProgram[0].Id, lstTreaty[0].Id, lstAccount[4].Id, lstAccount[5].Id, '2', '1',
                                            mapRecTypeIdRequest.get(AP_Constant.reqRTSA), '2', 'Sent',lstSection[0].Id)

            };
            insert lstRequests;

            lstRequests[6].LastVersionSent__c = true;
            lstRequests[6].LastVersionAnswered__c = true;
            lstRequests[6].Program__r = lstProgram[0];
            lstRequests[6].Special_Acceptance__c = lstSpecialAcceptance[0].Id;
            lstRequests[6].Program__r = lstProgram[0];
            lstRequests[6].Special_Acceptance__r = lstSpecialAcceptance[0];
            lstRequests[6].Special_Acceptance__r.CoveredCedingCompany__r = lstAccount[2];
            lstRequests[6].ExpectedResponseDate__c = Date.today();
            lstRequests[6].BrokerStatus__c = '2';

            lstRequests[7].LastVersionSent__c = true;
            lstRequests[7].LastVersionAnswered__c = true;
            lstRequests[7].Program__r = lstProgram[0];
            lstRequests[7].Special_Acceptance__c = lstSpecialAcceptance[0].Id;
            lstRequests[7].Program__r = lstProgram[0];
            lstRequests[7].Special_Acceptance__r = lstSpecialAcceptance[0];
            lstRequests[7].Special_Acceptance__r.CoveredCedingCompany__r = lstAccount[2];
            lstRequests[7].ExpectedResponseDate__c = Date.today();
            lstRequests[7].BrokerStatus__c = '1';

            update lstRequests;

            List<Request__Share> lstRequestShare = new List<Request__Share>();
                for(Request__c req : lstRequests){
                        Request__Share requestShare = new Request__Share();
                        requestShare.RowCause = 'Manual';
                        requestShare.AccessLevel = 'Edit';
                        requestShare.ParentId = req.Id;
                        requestShare.UserOrGroupId = lstPortalUser[0].Id;
                        lstRequestShare.add(requestShare);
                }

                for(Request__c req : lstRequests){
                        Request__Share requestShare = new Request__Share();
                        requestShare.RowCause = 'Manual';
                        requestShare.AccessLevel = 'Edit';
                        requestShare.ParentId = req.Id;
                        requestShare.UserOrGroupId = lstPortalUser[1].Id;
                        lstRequestShare.add(requestShare);
                }

                for(Request__c req : lstRequests){
                        Request__Share requestShare = new Request__Share();
                        requestShare.RowCause = 'Manual';
                        requestShare.AccessLevel = 'Edit';
                        requestShare.ParentId = req.Id;
                        requestShare.UserOrGroupId = lstPortalUser[2].Id;
                        lstRequestShare.add(requestShare);
                }

                if(lstRequestShare.size() > 0){
                        insert lstRequestShare;
                }
        }
        
    }

    @IsTest
    public static void testcreateSharingRequestFromProgram(){
        System.runAs(testUserCE) {
            Test.startTest();
            AP63_CreateSharingOrDeleteFromProgram.createSharingRequestFromProgram(lstIdProg, 'Program');
            Test.stopTest();
        }
    }

    @IsTest
    public static void testDeleteSharingRequestFromProgram(){
        System.runAs(testUserCE) {
            Test.startTest();
            AP63_CreateSharingOrDeleteFromProgram.DeleteSharingRequestFromProgram(lstIdProg, 'Program');
            Test.stopTest();
        }
    }

    @IsTest
    public static void testcreateSharingRequestFromTreaty(){
        System.runAs(testUserCE) {
            Test.startTest();
            AP63_CreateSharingOrDeleteFromProgram.createSharingRequestFromProgram(lstIdProg, 'Treaty');
            Test.stopTest();
        }
    }

    @IsTest
    public static void testDeleteSharingRequestFromTreaty(){
        System.runAs(testUserCE) {
            Test.startTest();
            AP63_CreateSharingOrDeleteFromProgram.DeleteSharingRequestFromProgram(lstIdProg, 'Treaty');
            Test.stopTest();
        }
    }
}