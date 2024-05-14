@IsTest
public with sharing class LWC30_SigningRequests_TEST {
/**************************************************************************************
-- - Author        : Spoon Consulting RRA GITHUB 1
-- - Description   : Test class for LWC30_SigningRequests 
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 15-MAR-2021  NBI   1.0      Initial version
-- 25-MAY-2021  MBE   1.1      W-0974 - Bug bloquant Prod - Impossibilité de créer une Lead request - TECH_Actor2Id__c
-- 02-AUG-2021  MBE   1.2      W-1000 - Signing - Impossibilité de modifier les champs modifiables du signing sur des programmes migrés ou renouvelés à l'identique à partir de données migrées
--------------------------------------------------------------------------------------
**************************************************************************************/

    static User testUserAdmin;
    static User testUserCE;
    static User testUserValidator;
    static User assignedToUser;
    static List<User> lstPortalUser = new List<User>();
    static List<User> lstUsers = new List<User>();
    static List<Account> lstAccount;
    static List<Contact> lstContact;
    static List<Program__c> lstProgram;
    static List<CoveredCedingCompany__c> lstCovCedCom;
    static List<Pool__c> lstPool;
    static List<PoolTreatySection__c> lstPoolTreatySections;
    static List<Treaty__c> lstTreaty;
    static List<FxRate__c> lstFxRate;
    static List<Request__c> lstRequests;
    static List<Request__c> lstLeadRequests;
    static List<Request__c> lstChildLeadRequests;
    static List<Section__c> lstSection;
    static Map<String, Id> mapRecTypeIdRequest = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectRequest});
    static Map<String, Id> mapAccountRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectAcc});
    static Map<String, Id> mapSARecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectSpecialAcceptance});

    static {
        //create User
        testUserAdmin = TestFactory.createUserWithRole('testUserAdmin', TestFactory.getProfileAdminId(), TestFactory.getCERoleId());
        testUserCE = TestFactory.createUser('testUserCE', TestFactory.getProfileCEId());
        testUserValidator = TestFactory.createUser('testUserCE', TestFactory.getProfileCEId());
        assignedToUser = TestFactory.createUserWithRole('TestAssignedTo', TestFactory.getProfileAdminId(), TestFactory.getHeadUGPRoleId());

        lstUsers.add(testUserAdmin);
        lstUsers.add(testUserCE);
        lstUsers.add(testUserValidator);
        lstUsers.add(assignedToUser);

        lstUsers[0].BypassTrigger__c = 'AP44_CreateSharingForUser;AP59_DeleteOldAccConRelation';
        lstUsers[1].BypassTrigger__c = 'AP44_CreateSharingForUser;AP59_DeleteOldAccConRelation';
        lstUsers[2].BypassTrigger__c = 'AP44_CreateSharingForUser;AP59_DeleteOldAccConRelation';
        insert lstUsers;

        System.runAs(testUserAdmin) {
            Map<String, Id> mapRequestRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{
                    AP_Constant.sObjectRequest
            });

            //create Account
            lstAccount = new List<Account>{
                TestFactory.createAccount(mapAccountRecTypeId.get(AP_Constant.accRTPrincipalCedingCom), 'Account A', 'C_0001'),
                TestFactory.createAccount(mapAccountRecTypeId.get(AP_Constant.accRTPrincipalCedingCom), 'Account B', 'C_0002'),
                TestFactory.createAccount(mapAccountRecTypeId.get(AP_Constant.accRTCoveredCedingCompany), 'Account C', 'C_0003'),
                TestFactory.createAccount(mapAccountRecTypeId.get(AP_Constant.accRTCoveredCedingCompany), 'Account D', 'C_0004'),
                TestFactory.createAccount(mapAccountRecTypeId.get(AP_Constant.accRTBroker), 'Account E', 'C_0005'),
                TestFactory.createAccount(mapAccountRecTypeId.get(AP_Constant.accRTReinsurer), 'Account F', 'C_0006'),
                TestFactory.createAccount(mapAccountRecTypeId.get(AP_Constant.accRTBroker), 'Broker A', 'C_0007'),
                TestFactory.createAccount(mapAccountRecTypeId.get(AP_Constant.accRTReinsurer), 'Reinsurer A', 'C_0009')
            };
            lstAccount[5].IsRiskCarrier__c = true;
            lstAccount[5].IsFinancialEntity__c = true;
            insert lstAccount;

            lstAccount[0].EmailSA__c = 'test@test.com';
            update lstAccount;

            //create Ceding Portal Contact + Broker/Reinsurer Contact
            lstContact = new List<Contact>{
                    TestFactory.createContact('Account E - PccCeding', 'CedingPortal', lstAccount[6].Id, '2', '25009'),
                    TestFactory.createContact('Account E - Broker', 'BrokerPortal', lstAccount[4].Id, '2', '25009'),
                    TestFactory.createContact('Account F - Reinsurer', 'ReinsurerPortal', lstAccount[5].Id, '2', '25009'),
                    TestFactory.createContact('Account F - Reinsurer', 'ReinsurerPortal', lstAccount[5].Id, '2', '25009')
            };


            
            lstContact[0].Email = 'test@test.com';
            lstContact[0].BrokerReinsurer__c = 'Broker';
            lstContact[1].Email = 'test@test.com';
            lstContact[1].BrokerReinsurer__c = 'Broker';
            lstContact[2].Email = 'test@test.com';
            lstContact[2].BrokerReinsurer__c= 'Reinsurer';
            lstContact[3].Email = 'test@test.com';
            lstContact[3].BrokerReinsurer__c= 'Reinsurer';
            

            insert lstContact;

            List<AccountContactRelation> lstAccConToInsert = new List<AccountContactRelation>();

            for(Contact con : lstContact) {
                AccountContactRelation accCon = new AccountContactRelation();
                accCon.ContactId = con.Id;
                accCon.AccountId = lstAccount[0].Id;
                accCon.Roles = 'PrincipalCedingCompany';
                accCon.IsActive = true;
                lstAccConToInsert.add(accCon);
            }

            if (lstAccConToInsert.size() > 0) {
                insert lstAccConToInsert;
            }

            List<AccountContactRelation> lstAccCon = [
                    SELECT Id, AccountId, Account.RecordTypeId
                            , Contact.Account.RecordTypeId, Roles
                            , ContactId, Contact.MacroLoB__c
                            , Contact.Nature__c, IsDirect
                    FROM AccountContactRelation
            ];

            for (AccountContactRelation accCon : lstAccCon) {
                accCon.IsActive = true;

                if (accCon.AccountId == lstAccount[4].Id) {
                    accCon.Roles = 'Broker';
                } else if (accCon.AccountId == lstAccount[5].Id) {
                    accCon.Roles = 'RiskCarrier';
                } else if (accCon.AccountId == lstAccount[0].Id) {
                    accCon.Roles = 'PrincipalCedingCompany';
                }
            }
            update lstAccCon;

            List<AccountShare> lstAccShare = new List<AccountShare>();

            //Create Account Share for CE User - testUserCE
            for (Account acc : lstAccount) {
                AccountShare accShare = new AccountShare();
                accShare.UserOrGroupId = testUserCE.Id;
                accShare.AccountId = acc.Id;
                accShare.AccountAccessLevel = 'Edit';
                accShare.OpportunityAccessLevel = 'Edit';
                lstAccShare.add(accShare);
            }

            if (lstAccShare.size() > 0) {
                insert lstAccShare;
            }
        }

        System.runAs(testUserCE) {
            //create Pool
            lstPool = new List<Pool__c>{
                    TestFactory.createPool('Pool A', 78, '2020', assignedToUser.Id),
                    TestFactory.createPool('Pool B', 78, '2020', assignedToUser.Id)
            };

            lstPool[0].SA_Email__c = 'test@test.com';
            lstPool[1].SA_Email__c = 'test@test.com';
            insert lstPool;

            //create Program
            lstProgram = new List<Program__c>{
                TestFactory.createProgram('TestProg1', '1', '1'
                        , Date.today(), Date.today().addYears(1), '2', Date.today(), Date.today().addYears(1)
                        , '2020', lstAccount[0].Id, '23002', '2'
                        , '25009'),


                TestFactory.createProgram('TestProg2', '1', '1'
                        , Date.today(), Date.today().addYears(1), '2', Date.today(), Date.today().addYears(1)
                        , '2020', lstAccount[0].Id, '23002', '2'
                        , '25009'),
                TestFactory.createProgram('TestProg3', '1', '1'
                        , Date.today(), Date.today().addYears(1), '2', Date.today(), Date.today().addYears(1)
                        , '2020', lstAccount[0].Id, '23002', '2'
                        , '25009')
            };

            lstProgram[0].TECH_StageName__c = 'Signing';
            lstProgram[1].TECH_StageName__c = 'Signing';
            lstProgram[1].LossDepositLevel__c = 'Treaty';
            insert lstProgram;

            lstProgram[1].RenewedFromProgram__c =  lstProgram[0].Id;
            lstProgram[1].TypeOfRenew__c = 'LTA/TR Identical Renew';

            lstProgram[2].TypeOfRenew__c = 'LTA/TR Renegotiation';
            lstProgram[2].RenewedFromProgram__c = lstProgram[1].Id ;
            update lstProgram;
            
            //MRA 19/05/23 - Contact Signatory Rebuild
            //lstContact[3].RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get(AP_Constant.contactSignatory).getRecordTypeId();
            lstContact[3].TECH_ProgramId__c = lstProgram[1].Id;

            //update lstContact[3] ;

            lstCovCedCom = new List<CoveredCedingCompany__c>{
                TestFactory.createCovCedCom(lstAccount[2].Id, lstProgram[0].Id, true, null
                        , false, null, false, null, null),

                TestFactory.createCovCedCom(lstAccount[3].Id, lstProgram[0].Id, true, null
                        , false, null, false, null, null),

                TestFactory.createCovCedCom(lstAccount[3].Id, lstProgram[1].Id, true, null
                        , false, null, false, null, null)   
            };
            insert lstCovCedCom;

            //create Treaty
            lstTreaty = new List<Treaty__c>{
                TestFactory.createTreaty('TestTreaty1', 1, '2020-00000222', '2'
                        , lstProgram[0].Id, '1', 34, '45', '2020-00000222', '1', '2', '2', '2', '2'),

                TestFactory.createTreaty('TestTreaty2', 1, '2020-00000222', '2'
                        , lstProgram[0].Id, '1', 34, '45', '2020-00000222', '1', '2', '2', '2', '2'),
                
                TestFactory.createTreaty('TestTreaty3', 1, '2020-00000222', '2'
                        , lstProgram[1].Id, '1', 34, '45', '2020-00000222', '1', '2', '2', '2', '2'),

                TestFactory.createTreaty('TestTreaty4', 1, '2020-00000222', '3'
                        , lstProgram[1].Id, '1', 34, '10', '2020-00000222', '1', '2', '2', '2', '2'),

                TestFactory.createTreaty('TestTreaty5', 1, '2020-00000222', '4'
                        , lstProgram[1].Id, '1', 34, '20', '2020-00000222', '1', '2', '2', '2', '2')
            };

            lstTreaty[2].PremiumDeposit__c = 'No';
            lstTreaty[3].PremiumDeposit__c = 'Yes';
            insert lstTreaty;


            //Create FxRate
            lstFxRate = new List<FxRate__c>{
                new FxRate__c (Currency__c = '9052', FX_Rate__c = 1.000000)
                
            };
            insert lstFxRate;

            //create Section
            lstSection = new List<Section__c>{
                TestFactory.createSection('TestSection1', '1.1', '22003', '20006', '9052'
                        , 322, 34, lstProgram[0].Id, lstTreaty[0].Id, '2', '1'
                        , true, '2', null, '23001', '1', '5', '2', '2'),

                TestFactory.createSection('TestSection2', '2.1', '22003', '20006', '9052'
                        , 23, 5, lstProgram[1].Id, lstTreaty[2].Id, '2', '1'
                        , false, '2', null, '23001', '1', '5', '2', '2'),

                TestFactory.createSection('TestSection3', '2.1', '22003', '20006', '9052'
                        , 23, 5, lstProgram[1].Id, lstTreaty[3].Id, '3', '1'
                        , false, '6', null, '23001', '1', '5', '2', '2'),

                TestFactory.createSection('TestSection4', '2.1', '22003', '20006', '9052'
                        , 23, 5, lstProgram[1].Id, lstTreaty[2].Id, '2', '1'
                        , false, '10', null, '23001', '1', '5', '2', '2'),

                TestFactory.createSection('TestSection5', '2.1', '22003', '20006', '9052'
                        , 23, 5, lstProgram[1].Id, lstTreaty[2].Id, '2', '1'
                        , false, '3', null, '23001', '1', '5', '2', '2'),

                TestFactory.createSection('TestSection6', '2.1', '22003', '20006', '9052'
                        , 23, 5, lstProgram[1].Id, lstTreaty[2].Id, '2', '1'
                        , false, '1', null, '23001', '1', '5', '2', '2'),

                TestFactory.createSection('TestSection7', '2.1', '22003', '20006', '9052'
                        , 23, 5, lstProgram[1].Id, lstTreaty[2].Id, '2', '1'
                        , false, '8', null, '23001', '1', '5', '2', '2'),

                TestFactory.createSection('TestSection8', '2.1', '22003', '20006', '9052'
                        , 23, 5, lstProgram[1].Id, lstTreaty[2].Id, '2', '1'
                        , false, '4', null, '23001', '1', '5', '2', '2'),

                TestFactory.createSection('TestSection9', '2.1', '22003', '20006', '9052'
                        , 23, 5, lstProgram[1].Id, lstTreaty[4].Id, '4', '1'
                        , false, '5', null, '23001', '1', '5', '2', '2')
            };

            for(Section__c section : lstSection){
                section.TotalEPI__c = 50;
                section.Cession_Perc__c = 50;
                section.Currency__c ='9052';
            }
            insert lstSection;

            //create Pool Treaty Section
            lstPoolTreatySections = new List<PoolTreatySection__c>{
                TestFactory.createPoolTreatySection(lstPool[0].Id, lstTreaty[2].Id, null
                        , false, true, 32, null),

                TestFactory.createPoolTreatySection(lstPool[1].Id, lstTreaty[2].Id, null
                        , false, true, 40, null)
            };
            insert lstPoolTreatySections;

            //create Request
            //(lstProgram[1].Id, lstTreaty[2].Id, lstAccount[5].Id, lstAccount[4].Id, 'Sent', true);
            lstRequests = new List<Request__c>{
                TestFactory.createRequest(lstProgram[1].Id, lstTreaty[2].Id, lstAccount[4].Id, lstAccount[5].Id, '1', '3',
                        mapRecTypeIdRequest.get(AP_Constant.reqRTQuote), '2', 'Setup', lstSection[1].Id),

                TestFactory.createRequest(lstProgram[1].Id, lstTreaty[2].Id, lstAccount[4].Id, lstAccount[5].Id, '2', '1',
                        mapRecTypeIdRequest.get(AP_Constant.reqRTQuote), '2', 'Setup', lstSection[1].Id),

                TestFactory.createRequest(lstProgram[1].Id, lstTreaty[2].Id, lstAccount[4].Id, lstAccount[5].Id, '1', '3',
                        mapRecTypeIdRequest.get(AP_Constant.reqRTPlacement), '2', 'Setup', lstSection[1].Id),

                TestFactory.createRequest(lstProgram[1].Id, lstTreaty[2].Id, lstAccount[4].Id, lstAccount[5].Id, '2', '1',
                        mapRecTypeIdRequest.get(AP_Constant.reqRTPlacement), '2', 'Sent', lstSection[1].Id),

                TestFactory.createRequest(lstProgram[1].Id, lstTreaty[2].Id, lstAccount[4].Id, lstAccount[5].Id, '1', '3',
                        mapRecTypeIdRequest.get(AP_Constant.reqRTSigning), '2', 'Setup', lstSection[1].Id),

                TestFactory.createRequest(lstProgram[1].Id, lstTreaty[2].Id, lstAccount[4].Id, lstAccount[5].Id, '2', '1',
                        mapRecTypeIdRequest.get(AP_Constant.reqRTSigning), '2', 'Sent', lstSection[1].Id),

                TestFactory.createRequest(lstProgram[1].Id, lstTreaty[2].Id, null, lstAccount[5].Id, '2', '1',
                        mapRecTypeIdRequest.get(AP_Constant.reqRTSigning), '2', 'Sent', lstSection[1].Id),

                TestFactory.createRequest(lstProgram[1].Id, lstTreaty[2].Id, null, null, '2', '1',
                        mapRecTypeIdRequest.get(AP_Constant.reqRTSigning), '2', 'Sent', lstSection[1].Id),

                TestFactory.createRequest(lstProgram[1].Id, lstTreaty[2].Id, lstAccount[4].Id, lstAccount[7].Id, '2', '1',
                        mapRecTypeIdRequest.get(AP_Constant.reqRTPlacement), '2', 'Sent', lstSection[1].Id),

                TestFactory.createRequest(lstProgram[1].Id, lstTreaty[3].Id, null, lstAccount[7].Id, '2', '1',
                        mapRecTypeIdRequest.get(AP_Constant.reqRTSigning), '2', 'Sent', lstSection[2].Id)
            };
            insert lstRequests;

            for(Request__c req : lstRequests){
                if(req.ReinsurerStatus__c != 'Setup'){
                    req.LastVersionSent__c = true;
                    req.LastVersionAnswered__c = true;
                    req.VersionMinor__c = 2;
                }

                req.BrokerStatus__c = '2';
                req.RiskCarrier__c = lstAccount[5].Id;
                req.FinancialEntity__c = lstAccount[5].Id;
            }

            lstRequests[3].ReinsurerStatus__c = 'Answered';
            lstRequests[1].OriginalRequest__c = lstRequests[0].Id;
            lstRequests[2].OriginalRequest__c = lstRequests[1].Id;
            lstRequests[3].OriginalRequest__c = lstRequests[2].Id;
            lstRequests[4].OriginalRequest__c = lstRequests[3].Id;

            lstRequests[5].OriginalRequest__c = lstRequests[4].Id;
            lstRequests[6].OriginalRequest__c = lstRequests[5].Id;
            lstRequests[7].OriginalRequest__c = lstRequests[6].Id;
            lstRequests[8].OriginalRequest__c = lstRequests[7].Id;
            lstRequests[9].OriginalRequest__c = lstRequests[8].Id;

            lstRequests[7].Pool__c = lstPool[0].Id;
            update lstRequests;

            //create lead 
            lstLeadRequests = new List<Request__c>{
                // recordTypeId + status required
                TestFactory.createLeadRequest(lstProgram[1].Id, lstTreaty[2].Id, lstAccount[4].Id, lstAccount[5].Id, '1', '4',
                                                mapRecTypeIdRequest.get(AP_Constant.reqRTLead), '2', 'Sent',lstSection[3].Id),
    
                TestFactory.createLeadRequest(lstProgram[1].Id, lstTreaty[2].Id, lstAccount[4].Id, lstAccount[5].Id, '2', '4',
                                                mapRecTypeIdRequest.get(AP_Constant.reqRTLead), '2', 'Sent',lstSection[1].Id),

                TestFactory.createLeadRequest(lstProgram[1].Id, lstTreaty[3].Id, lstAccount[4].Id, lstAccount[5].Id, '2', '4',
                                                mapRecTypeIdRequest.get(AP_Constant.reqRTLead), '2', 'Sent',lstSection[2].Id),

                TestFactory.createLeadRequest(lstProgram[1].Id, lstTreaty[2].Id, lstAccount[4].Id, lstAccount[5].Id, '2', '4',
                                                mapRecTypeIdRequest.get(AP_Constant.reqRTLead), '2', 'Setup',lstSection[4].Id),

                TestFactory.createLeadRequest(lstProgram[1].Id, lstTreaty[2].Id, lstAccount[4].Id, lstAccount[5].Id, '2', '4',
                                                mapRecTypeIdRequest.get(AP_Constant.reqRTLead), '2', 'Setup',lstSection[5].Id),
                
                TestFactory.createLeadRequest(lstProgram[1].Id, lstTreaty[2].Id, lstAccount[4].Id, lstAccount[5].Id, '2', '4',
                                                mapRecTypeIdRequest.get(AP_Constant.reqRTLead), '2', 'Setup',lstSection[6].Id),
                
                TestFactory.createLeadRequest(lstProgram[1].Id, lstTreaty[2].Id, lstAccount[4].Id, lstAccount[5].Id, '2', '4',
                                                mapRecTypeIdRequest.get(AP_Constant.reqRTLead), '2', 'Setup',lstSection[7].Id),

                TestFactory.createLeadRequest(lstProgram[1].Id, lstTreaty[4].Id, lstAccount[4].Id, lstAccount[5].Id, '2', '4',
                                                mapRecTypeIdRequest.get(AP_Constant.reqRTLead), '2', 'Setup',lstSection[8].Id)
            };

            for(Request__c leadReq : lstLeadRequests){
                if(leadReq.ReinsurerStatus__c != 'Setup'){
                    leadReq.LastVersionSent__c = true;
                    leadReq.LastVersionAnswered__c = true;
                    leadReq.VersionMinor__c = 2;
                }

                leadReq.CededPremium__c = 20;
                leadReq.PerHeadPremium__c = 50;
                leadReq.MinRate__c = 50;
                leadReq.FixedRate__c = 50;
                leadReq.FlatPremium__c = 50;
                leadReq.MinPerHeadAmount__c = 50;
                leadReq.MDP__c = 50;
            }

            lstLeadRequests[1].OriginalRequest__c = lstLeadRequests[0].Id;
            lstLeadRequests[1].Accept__c = true;
            lstLeadRequests[2].Accept__c = true;
            update lstLeadRequests;

            lstChildLeadRequests = [SELECT Id, Name, ReinsurerStatus__c,LastVersionSent__c, LastVersionAnswered__c
                                            , VersionMinor__c, Accept__c, Reinsurer__c, Broker__c, TECH_PhaseType__c
                                    FROM Request__c
                                    WHERE Reinsurer__c = NULL 
                                    AND RecordTypeId = :mapRecTypeIdRequest.get(AP_Constant.reqRTLead)];


            for(Request__c leadReq : lstChildLeadRequests){
                if(leadReq.ReinsurerStatus__c != 'Setup'){
                    leadReq.LastVersionSent__c = true;
                    leadReq.LastVersionAnswered__c = true;
                    leadReq.VersionMinor__c = 2;
                }

                leadReq.CededPremium__c = 20;
                leadReq.PerHeadPremium__c = 50;
                leadReq.MinRate__c = 50;
                leadReq.FixedRate__c = 50;
                leadReq.FlatPremium__c = 50;
                leadReq.MinPerHeadAmount__c = 50;
            }
            update lstChildLeadRequests;
        }
    }

    @IsTest
    public static void testClosePrevPhases(){
        System.runAs(testUserCE) {
            Test.startTest();
                Map<String, Object> mapResults = LWC30_SigningRequests.closePreviousPhase(lstProgram[1].Id);
            Test.stopTest();
            //System.assertEquals(null, mapResults.get('Error'));
           // System.assertEquals('Updated successfully', mapResults.get('Success'));

            List<Request__c> lstSigningReq = [SELECT Id, Name FROM Request__c WHERE Program__c = :lstProgram[1].Id AND RecordTypeId =: mapRecTypeIdRequest.get(AP_Constant.reqRTSigning)];
            System.assertEquals(8, lstSigningReq.size());
        }
    }
    @IsTest
    public static void testClosePrevPhasesRenew(){
        System.runAs(testUserCE) {
            Test.startTest();
                Map<String, Object> mapResults = LWC30_SigningRequests.closePreviousPhase(lstProgram[2].Id);
            Test.stopTest();
            System.assertEquals(null, mapResults.get('Error'));
            System.assertEquals('Updated successfully', mapResults.get('Success'));
        }
    }

    @IsTest
    public static void testGetSigningDetails(){
        System.runAs(testUserCE) {
            Test.startTest();
                Map<String, Object> mapResults = LWC30_SigningRequests.getSigningDetails(lstProgram[1].Id, lstTreaty[2].Id, lstAccount[5].Id, lstAccount[4].Id, 'Sent', true);
            Test.stopTest();

            System.assertEquals(true, mapResults != null);

            List<Request__c> lstSigningReq  = (List<Request__c>)  mapResults.get('lstSigningRequest');
            System.assertEquals(5, lstSigningReq.size());
            System.assertEquals(true, mapResults.get('showClosePreviousPhaseBtn'));
            System.assertEquals(false, mapResults.get('isDeleteVisible'));
            System.assertEquals(false, mapResults.get('allowAskForValidation'));
        }
    }

    @IsTest
    public static void testGetRiskCarrier(){
        System.runAs(testUserCE) {
            Test.startTest();
                List<LWC30_SigningRequests.OptionWrapper> lstResults = LWC30_SigningRequests.getRiskCarrier();
                System.assertEquals(true, lstResults != null );
                System.assertEquals(1, lstResults.size() );
            Test.stopTest();
        }
    }

    @IsTest
    public static void testGetFinancialEntity(){
        System.runAs(testUserCE) {
            Test.startTest();
                List<LWC30_SigningRequests.OptionWrapper> lstResults = LWC30_SigningRequests.getFinancialEntity();
                System.assertEquals(true, lstResults != null );
                System.assertEquals(1, lstResults.size() );
            Test.stopTest();
        }
    }

    @IsTest
    public static void testSaveSigningRequestProgram(){
        System.runAs(testUserCE) {
            Test.startTest();
                Map<String, Object> mapResults = LWC30_SigningRequests.saveSigningRequest(new List<Request__c>{lstRequests[4], lstRequests[5], lstRequests[6]}, new List<Id>{lstRequests[4].Id, lstRequests[5].Id, lstRequests[6].Id}, new List<Id>{lstRequests[4].Id, lstRequests[5].Id, lstRequests[6].Id}, 'Program', new List<Id>{lstRequests[4].Id, lstRequests[5].Id, lstRequests[6].Id});
                //System.assertEquals(null, mapResults.get('Error'));
                //System.assertEquals('Success', mapResults.get('Success'));
            Test.stopTest();
        }
    }

    @IsTest
    public static void testSaveSigningRequestProgram2(){
        System.runAs(testUserCE) {
            Test.startTest();
                Map<String, Object> mapResults = LWC30_SigningRequests.saveSigningRequest(new List<Request__c>{lstRequests[0],lstRequests[1], lstRequests[2], lstRequests[3], lstRequests[4], lstRequests[5], lstRequests[6], lstRequests[7], lstRequests[8], lstRequests[9]}, new List<Id>{lstRequests[0].OriginalRequest__c,lstRequests[1].OriginalRequest__c,lstRequests[2].OriginalRequest__c,lstRequests[3].OriginalRequest__c, lstRequests[4].OriginalRequest__c, lstRequests[5].OriginalRequest__c, lstRequests[6].OriginalRequest__c, lstRequests[7].OriginalRequest__c, lstRequests[8].OriginalRequest__c, lstRequests[9].OriginalRequest__c}, new List<Id>{lstRequests[0].OriginalRequest__c,lstRequests[1].OriginalRequest__c,lstRequests[2].OriginalRequest__c, lstRequests[3].OriginalRequest__c}, 'Program', new List<Id>{lstRequests[4].Id, lstRequests[5].Id, lstRequests[6].Id});
                //System.assertEquals(null, mapResults.get('Error'));
                //System.assertEquals('Success', mapResults.get('Success'));
            Test.stopTest();
        }
    }
    
    @IsTest
    public static void testSaveSigningRequestTreaty(){
        System.runAs(testUserCE) {
            Test.startTest();
                Map<String, Object> mapResults = LWC30_SigningRequests.saveSigningRequest(new List<Request__c>{lstRequests[4], lstRequests[5], lstRequests[6]}, new List<Id>{lstRequests[4].Id, lstRequests[5].Id, lstRequests[6].Id}, new List<Id>{lstRequests[4].Id, lstRequests[5].Id, lstRequests[6].Id}, 'Treaty', new List<Id>{lstRequests[4].Id, lstRequests[5].Id, lstRequests[6].Id});
                //System.assertEquals(null, mapResults.get('Error'));
                //System.assertEquals('Success', mapResults.get('Success'));
            Test.stopTest();
        }
    }
    
    @IsTest
    public static void testSaveSigningRequestNoLossDepositLevel(){
        System.runAs(testUserAdmin) {
            Test.startTest();

            lstRequests[4].LossDeposit__c = '2';
            lstRequests[5].LossDeposit__c = '2';
            lstRequests[6].LossDeposit__c = '2';
            
            lstRequests[4].TECH_isAdmin__c = false;
            lstRequests[5].TECH_isAdmin__c = false;
            lstRequests[6].TECH_isAdmin__c = false;
            
            lstRequests[4].LossDepositMode__c = '1';
            lstRequests[5].LossDepositMode__c = '1';
            lstRequests[6].LossDepositMode__c = '1';
            
            lstRequests[4].FinancialEntity__c =  lstAccount[5].Id;
            lstRequests[5].FinancialEntity__c =   lstAccount[5].Id;
            lstRequests[6].FinancialEntity__c =  lstAccount[5].Id;
         
            /*lstRequests[4].RiskCarrier__c = lstAccount[5].Id;
            lstRequests[5].RiskCarrier__c =  lstAccount[5].Id;
            lstRequests[6].RiskCarrier__c = lstAccount[5].Id;*/
            
            lstRequests[4].RetrocessionBrokerage__c = 2;
            lstRequests[5].RetrocessionBrokerage__c =  2;
            lstRequests[6].RetrocessionBrokerage__c = 2;
            
            //update lstRequests;
                Map<String, Object> mapResults = LWC30_SigningRequests.saveSigningRequest(new List<Request__c>{lstRequests[4], lstRequests[5], lstRequests[6]}, new List<Id>{lstRequests[4].Id, lstRequests[5].Id, lstRequests[6].Id}, new List<Id>{lstRequests[4].Id, lstRequests[5].Id, lstRequests[6].Id}, null, new List<Id>{lstRequests[4].Id, lstRequests[5].Id, lstRequests[6].Id});
                //System.assertEquals(null, mapResults.get('Error'));
                //System.assertEquals('Success', mapResults.get('Success'));
            Test.stopTest();
        }
    }
    
    @IsTest
    public static void testSaveSigningRequestNoLossDepositLevel2(){
        System.runAs(testUserAdmin) {
            Test.startTest();

            lstRequests[4].LossDeposit__c = '1';
            lstRequests[5].LossDeposit__c = '1';
            lstRequests[6].LossDeposit__c = '1';
            
            lstRequests[4].TECH_isAdmin__c = true;
            lstRequests[5].TECH_isAdmin__c = false;
            lstRequests[6].TECH_isAdmin__c = false;
            
            lstRequests[4].LossDepositMode__c = '1';
            lstRequests[5].LossDepositMode__c = '1';
            lstRequests[6].LossDepositMode__c = '1';
            
            lstRequests[4].FinancialEntity__c =  lstAccount[5].Id;
            lstRequests[5].FinancialEntity__c =   lstAccount[5].Id;
            lstRequests[6].FinancialEntity__c =  lstAccount[5].Id;
            
            /*lstRequests[4].RiskCarrier__c = lstAccount[5].Id;
            lstRequests[5].RiskCarrier__c =  lstAccount[5].Id;
            lstRequests[6].RiskCarrier__c = lstAccount[5].Id;
            
            lstRequests[4].RetrocessionBrokerage__c = 2;
            lstRequests[5].RetrocessionBrokerage__c =  2;
            lstRequests[6].RetrocessionBrokerage__c = 2;*/
            
            lstRequests[4].LastVersionSent__c = true;
            lstRequests[5].LastVersionSent__c =  true;
            lstRequests[6].LastVersionSent__c = true;
            
            update lstRequests;
                Map<String, Object> mapResults = LWC30_SigningRequests.saveSigningRequest(new List<Request__c>{lstRequests[4], lstRequests[5], lstRequests[6]}, new List<Id>{lstRequests[4].Id, lstRequests[5].Id, lstRequests[6].Id}, new List<Id>{lstRequests[4].Id, lstRequests[5].Id, lstRequests[6].Id}, null, new List<Id>{lstRequests[4].Id, lstRequests[5].Id, lstRequests[6].Id});
                //System.assertEquals(null, mapResults.get('Error'));
                //System.assertEquals('Success', mapResults.get('Success'));
            Test.stopTest();
        }
    }

    @IsTest
    public static void testSaveSigningRequestTreaty2(){
        System.runAs(testUserCE) {
            Test.startTest();
                Map<String, Object> mapResults = LWC30_SigningRequests.saveSigningRequest(new List<Request__c>{lstRequests[0],lstRequests[1], lstRequests[2], lstRequests[3], lstRequests[4], lstRequests[5], lstRequests[6], lstRequests[7], lstRequests[8], lstRequests[9]}, new List<Id>{lstRequests[0].OriginalRequest__c,lstRequests[1].OriginalRequest__c,lstRequests[2].OriginalRequest__c,lstRequests[3].OriginalRequest__c, lstRequests[4].OriginalRequest__c, lstRequests[5].OriginalRequest__c, lstRequests[6].OriginalRequest__c, lstRequests[7].OriginalRequest__c, lstRequests[8].OriginalRequest__c, lstRequests[9].OriginalRequest__c}, new List<Id>{lstRequests[0].OriginalRequest__c,lstRequests[1].OriginalRequest__c,lstRequests[2].OriginalRequest__c,lstRequests[3].OriginalRequest__c}, 'Treaty', new List<Id>{lstRequests[4].Id, lstRequests[5].Id, lstRequests[6].Id});
                //System.assertEquals(null, mapResults.get('Error'));
                //System.assertEquals('Success', mapResults.get('Success'));
            Test.stopTest();
        }
    }

    @IsTest
    public static void testUpdateWS(){
        System.runAs(testUserCE) {
            Test.startTest();
                Map<String, Object> mapResults = LWC30_SigningRequests.updateWrittenSignedShare(new List<Request__c>{lstRequests[4]});
                //System.assertEquals(null, mapResults.get('Error'));
                //System.assertEquals('Success', mapResults.get('Success'));
            Test.stopTest();
        }
    }

    @IsTest
    public static void testSignforPool1(){
        System.runAs(assignedToUser) {
            Test.startTest();
                Boolean result = LWC30_SigningRequests.getSignForPoolVisibility();
                System.assertEquals(false, result);
            Test.stopTest();
        }
    }

    @IsTest
    public static void testReopenSigningReq(){
        System.runAs(testUserCE) {
            Test.startTest();
            	lstRequests[4].TECH_OldSigningStatus__c = '2';
            	update lstRequests;
                Map<String, Object> mapResults = LWC30_SigningRequests.reopenSigningRequest(new List<String>{lstRequests[4].Id});
                //System.assertEquals(null, mapResults.get('Error'));
                //System.assertEquals('Success', mapResults.get('Success'));
            Test.stopTest();
            
            for(Request__c req : [SELECT Id, name, SigningStatus__c FROM Request__c WHERE Id = :lstRequests[4].Id]){
                System.assertEquals('2', req.SigningStatus__c);
            }
        }
    }

    @IsTest
    public static void testReopenPreviousPhase(){
        System.runAs(testUserCE) {
            Test.startTest();
                Map<String, Object> mapResults = LWC30_SigningRequests.reopenPreviousPhase(lstProgram[1].Id);
                //System.assertEquals(null, mapResults.get('Error'));
                //System.assertEquals('Success', mapResults.get('Success'));
            Test.stopTest();

            Program__c prog = [SELECT Id, TECH_ShowClosePreviousPhaseBtn__c FROM Program__c WHERE Id = :lstProgram[1].Id];

            System.assertEquals('1', prog.TECH_ShowClosePreviousPhaseBtn__c);
        }
    }

    @IsTest
    public static void testDelBtnAdmin(){
        System.runAs(testUserAdmin) {
            Test.startTest();
                Boolean result = LWC30_SigningRequests.getDeleteButtonVisibility();
                System.assertEquals(true, result);
            Test.stopTest();
        }
    }

    @IsTest
    public static void testCloseSigning(){
        System.runAs(testUserAdmin) {
            Test.startTest();
                lstRequests[4].ReinsurerStatus__c = 'Signed';
                update lstRequests;
                Map<String, Object> mapResults = LWC30_SigningRequests.closeSigningNotifyWebXL(lstProgram[1].Id, new List<String>{lstRequests[4].Id});
                //System.assertEquals(null, mapResults.get('Error'));
                //System.assertEquals('Success', mapResults.get('Success'));
            Test.stopTest();

            for(Request__c req : [SELECT Id, name, SigningStatus__c FROM Request__c WHERE Id = :lstRequests[4].Id]){
                System.assertEquals(AP_Constant.statusRequestClosed, req.SigningStatus__c);
            }
        }
    }

    @IsTest
    public static void testGetLookupRiskCarrier(){
        System.runAs(testUserAdmin) {
            Test.startTest();
                List<LWC30_SigningRequests.SObjectResult> lstResults = LWC30_SigningRequests.getLookupAccountField('Acc', lstRequests[4].Id, 'RiskCarrier');
                System.assertEquals(true, lstResults != null);
                System.assertEquals(1, lstResults.size() );
            Test.stopTest();
        }
    }

    @IsTest
    public static void testGetLookupFinancialEntity(){
        System.runAs(testUserAdmin) {
            Test.startTest();
                List<LWC30_SigningRequests.SObjectResult> lstResults = LWC30_SigningRequests.getLookupAccountField('Acc', lstRequests[4].Id, 'FinancialEntity');
                System.assertEquals(true, lstResults != null );
                System.assertEquals(1, lstResults.size() );
            Test.stopTest();
        }
    }

    @IsTest
    public static void testCheckIfLeadReqAreAnswered(){
        System.runAs(testUserAdmin) {
            Test.startTest();
                Map<String, Object> mapResults = LWC30_SigningRequests.checkIfLeadReqAreAnswered(lstProgram[1].Id);
                System.assertEquals(true, mapResults != null );
            	System.assertEquals('You cannot perform this action as at least one of the Lead Request(s) is not answered', mapResults.get('Error') );
            Test.stopTest();
        }
    }

    @IsTest
    public static void testAllowAskForValidation(){
        System.runAs(testUserAdmin) {
            Test.startTest();
                Boolean result = LWC30_SigningRequests.allowAskForValidation(1000);
                System.assertEquals(false, result);
            Test.stopTest();
        }
    }
    @IsTest
    public static void testlstRequest(){
        System.runAs(testUserAdmin) {
            Test.startTest();
                List<Request__c> lstReq= LWC30_SigningRequests.lstRequestResult(lstRequests[1].Id, lstProgram[1].Id);
                System.assertEquals(true, lstReq != null );
            Test.stopTest();
        }
    }
    @IsTest
    public static void testcheckFXRATEifExists(){
        System.runAs(testUserAdmin) {
            Test.startTest();
                Decimal lstFxRate= LWC30_SigningRequests.checkFXRATEifExists(lstProgram[1].Id, new List<Id>{lstTreaty[0].Id, lstTreaty[1].Id, lstTreaty[2].Id});
                //System.assertEquals(true, lstFxRate != null );
            Test.stopTest();
        }
    }

    @IsTest
    public static void testgetListIdOrginalRequestNotNull(){
        System.runAs(testUserAdmin) {
            Test.startTest();
                Map<String, Object>  lstIdReq = LWC30_SigningRequests.getListIdOrginalRequestNotNull(lstProgram[1].Id, lstAccount[0].Id, '2020', lstAccount[5].Id);
            Test.stopTest();
        }
    }

    @IsTest
    public static void testUpdateSigningReqClosePrevPhase(){
        System.runAs(testUserAdmin) {
            Test.startTest();
                LWC30_SigningRequests.updateSigningReqClosePrevPhase(new List<Request__c>{lstRequests[0],lstRequests[1], lstRequests[2], lstRequests[3], lstRequests[4], lstRequests[5], lstRequests[6], lstRequests[7], lstRequests[8], lstRequests[9]}, lstProgram[0].Id);
            Test.stopTest();
        }
    }

    @IsTest
    public static void testGetSigningDetailslstRequestCededPremiumisNull(){
        System.runAs(testUserCE) {
            Test.startTest();
            lstLeadRequests[0].CededPremium__c = null;
            lstLeadRequests[1].CededPremium__c = null;
            lstLeadRequests[2].CededPremium__c = null;
            lstLeadRequests[3].CededPremium__c = null;
            lstLeadRequests[4].CededPremium__c = null;
            lstLeadRequests[5].CededPremium__c = null;
            lstLeadRequests[6].CededPremium__c = null;
            lstLeadRequests[7].CededPremium__c = null;

            update lstLeadRequests;

            lstChildLeadRequests[0].CededPremium__c = null;
            lstChildLeadRequests[1].CededPremium__c = null;
            lstChildLeadRequests[2].CededPremium__c = null;
            lstChildLeadRequests[3].CededPremium__c = null;
            lstChildLeadRequests[4].CededPremium__c = null;
            lstChildLeadRequests[5].CededPremium__c = null;
            lstChildLeadRequests[6].CededPremium__c = null;
            lstChildLeadRequests[7].CededPremium__c = null;

            update lstChildLeadRequests;

                Map<String, Object> mapResults = LWC30_SigningRequests.getSigningDetails(lstProgram[1].Id, lstTreaty[2].Id, lstAccount[5].Id, lstAccount[4].Id, 'Sent', true);
            Test.stopTest();
        }
    }
    
    @IsTest
    public static void testgetListIdRequest(){
        System.runAs(testUserAdmin) {
            Test.startTest();
                LWC30_SigningRequests.getListIdRequest(new List<Id>{lstRequests[0].OriginalRequest__c,lstRequests[1].OriginalRequest__c,lstRequests[2].OriginalRequest__c,lstRequests[3].OriginalRequest__c});
            Test.stopTest();
        }
    }

	@IsTest
    public static void testgetListAgreementIds(){
        System.runAs(testUserAdmin) {
            Test.startTest();
                LWC30_SigningRequests.getListAgreementIds(lstProgram[1].Id);
            Test.stopTest();
        }
    }
}