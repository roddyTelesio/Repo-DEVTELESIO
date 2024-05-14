@IsTest
public with sharing class LWC17_RespondOnBehalf_TEST {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Test class for LWC17_RespondOnBehalf
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 30-JAN-2020  MBE   1.0      Initial version
-- 21-MAY-2021  MBE   1.1      W-0974 - Bug bloquant Prod - Impossibilité de créer une Lead request - TECH_Actor2Id__c
--------------------------------------------------------------------------------------
**************************************************************************************/

    static User testUserAdmin;
    static User testUserCE;
    static List<CoveredCedingCompany__c> lstCovCedCom;
    static List<Account> lstAccount;
    static List<Program__c> lstProgram;
    static List<Treaty__c> lstTreaty;
    static List<Request__c> lstRequest;
    static List<Section__c> lstSection;
    static Map<String, Id> mapRecTypeIdRequest = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectRequest});
    static List<User> lstUsers = new List<User>();
    static List<Request__c> lstLeadRequests;
    static List<Request__c> lstChildLeadRequests;
 
    static {
        //create User
        testUserAdmin = TestFactory.createUser('testUserAdmin', TestFactory.getProfileAdminId());
        testUserCE = TestFactory.createUser('testUserCE', TestFactory.getProfileCEId());
        lstUsers.add(testUserAdmin);
        lstUsers.add(testUserCE);
        insert lstUsers;

        System.runAs(testUserAdmin){
            Map<String, Id> mapAccountRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectAcc});
            Map<String, Id> mapRequestRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectRequest});

            //create Account
            lstAccount = new List<Account> {
                    TestFactory.createAccount(mapAccountRecTypeId.get(AP_Constant.accRTPrincipalCedingCom),'Account A','C_0001'),
                    TestFactory.createAccount(mapAccountRecTypeId.get(AP_Constant.accRTPrincipalCedingCom),'Account B','C_0002'),
                    TestFactory.createAccount(mapAccountRecTypeId.get(AP_Constant.accRTCoveredCedingCompany),'Account C','C_0003'),
                    TestFactory.createAccount(mapAccountRecTypeId.get(AP_Constant.accRTCoveredCedingCompany),'Account D','C_0004'),
                    TestFactory.createAccount(mapAccountRecTypeId.get(AP_Constant.accRTBroker),'Account E','C_0005'),
                    TestFactory.createAccount(mapAccountRecTypeId.get(AP_Constant.accRTReinsurer),'Account F','C_0006'),
                    TestFactory.createAccount(mapAccountRecTypeId.get(AP_Constant.accRTBroker),'Broker A','C_0007'),
                    TestFactory.createAccount(mapAccountRecTypeId.get(AP_Constant.accRTBroker),'Broker B','C_0008'),
                    TestFactory.createAccount(mapAccountRecTypeId.get(AP_Constant.accRTReinsurer),'Reinsurer A','C_0009')
            };
            insert lstAccount;

            //create Program
            lstProgram = new List<Program__c> {
                    TestFactory.createProgram('TestProg1', '1', '1'
                            , Date.today(), Date.today().addYears(1), '2', Date.today(), Date.today().addYears(1)
                            , '2018', lstAccount[0].Id, '23002','2'
                            , '25009'),

                    TestFactory.createProgram('TestProg2', '2', '2', Date.today()
                            , Date.today().addYears(1), '1', Date.today(), Date.today().addYears(1), '2018'
                            , lstAccount[0].Id, '23001', '2', '25001')
            };
            insert lstProgram;

            lstProgram[1].RenewedFromProgram__c =  lstProgram[0].Id;
            lstProgram[1].TECH_ShowClosePreviousPhaseBtn__c =  '1';
            lstProgram[1].TypeOfRenew__c = 'LTA/TR Identical Renew';
            update lstProgram;

            //create Treaty
            lstTreaty = new List<Treaty__c> {
                    TestFactory.createTreaty('TestTreaty1', 1, '2020-00000221', '3'
                            , lstProgram[0].Id, '2', 34, '10', '2020-00000222', '1', '2', '2', '2', '2'),

                    TestFactory.createTreaty('TestTreaty2', 2, '2020-00000222', '2', lstProgram[0].Id
                            , '1', 44, '44', '2020-00000222', '2', '2', '2', '2', '2'),

                    TestFactory.createTreaty('TestTreaty3', 3, '2020-00000223', '2'
                            , lstProgram[1].Id, '2', 89, '44', '2020-00000222', '3', '2', '2', '2', '2')
            };
            insert lstTreaty;

            //create Section
            lstSection = new List<Section__c> {
                    TestFactory.createSection('TestSection1', '1.1', '22003', '20006', '9052'
                            , 322, 34, lstProgram[0].Id, lstTreaty[0].Id, '3', '1'
                            , true, '5', null, '23001', '1', '5', '2', '2'),

                    TestFactory.createSection('TestSection2', '2.1', '22003', '20006', '9052'
                            , 23, 5, lstProgram[1].Id, lstTreaty[2].Id, '3', '1'
                            , false, '5', null, '23001', '1', '5', '2', '2')
            };
            insert lstSection;


            //create Request
            lstRequest = new List<Request__c>{
                    // recordTypeId + status required
                    TestFactory.createRequest(lstProgram[1].Id, lstTreaty[2].Id, lstAccount[4].Id, lstAccount[5].Id, '1', '3',
                            mapRecTypeIdRequest.get(AP_Constant.reqRTQuote), '2', 'Setup',lstSection[1].Id),

                    TestFactory.createRequest(lstProgram[1].Id, lstTreaty[2].Id, lstAccount[4].Id, lstAccount[5].Id, '2', '1',
                            mapRecTypeIdRequest.get(AP_Constant.reqRTQuote), '2', 'Setup',lstSection[1].Id),

                    TestFactory.createRequest(lstProgram[1].Id, lstTreaty[2].Id, lstAccount[4].Id, lstAccount[5].Id, '1', '3',
                            mapRecTypeIdRequest.get(AP_Constant.reqRTQuote), '2', 'Sent',lstSection[1].Id),

                    TestFactory.createRequest(lstProgram[1].Id, lstTreaty[2].Id, lstAccount[4].Id, lstAccount[5].Id, '2', '1',
                            mapRecTypeIdRequest.get(AP_Constant.reqRTQuote), '2', 'Sent',lstSection[1].Id),

                    TestFactory.createRequest(lstProgram[1].Id, lstTreaty[2].Id, lstAccount[4].Id, lstAccount[5].Id, '1', '5',
                            mapRecTypeIdRequest.get(AP_Constant.reqRTPlacement), '2', 'Sent',lstSection[1].Id),

                    TestFactory.createRequest(lstProgram[1].Id, lstTreaty[2].Id, lstAccount[4].Id, lstAccount[5].Id, '2', '5',
                            mapRecTypeIdRequest.get(AP_Constant.reqRTPlacement), '2', 'Sent',lstSection[1].Id)
            };

            lstRequest[0].Quote__c = '1';
            lstRequest[0].QuoteDeadline__c = Date.today();
            lstRequest[0].VersionMinor__c = 1;
            lstRequest[0].ProfitCommission__c = 10;
            lstRequest[0].fixedCommission__c = 11;
            lstRequest[0].FixedRate__c = 12;
            lstRequest[0].MinRate__c = 13;
            lstRequest[0].MaxRate__c = 14;
            lstRequest[0].ProvisionalRate__c = 15;
            lstRequest[0].FlatPremium__c = 16;
            lstRequest[0].MDP__c = 17;
            lstRequest[0].MinVarCommission__c = 18;
            lstRequest[0].MaxVarCommission__c = 19;
            lstRequest[0].ProvisionalCommission__c = 20;
            lstRequest[0].PerHeadPremium__c = 21;
            lstRequest[0].MinPerHeadAmount__c = 22;
            lstRequest[0].MaxPerHeadAmount__c = 23;
            lstRequest[0].ProvisionalPerHeadPremium__c = 24;
            lstRequest[0].EstimatedReinsurancePremium__c = 25;
            lstRequest[0].EstimatedInsurancePremium__c = 26;
            lstRequest[0].ReinsurerStatus__c = 'Sent';
            lstRequest[0].LastVersionSent__c = true;
            lstRequest[0].LastVersionAnswered__c = true;

            lstRequest[1].Quote__c = '2';
            lstRequest[1].VersionMinor__c = 1;
            lstRequest[1].QuoteDeadline__c = Date.today(); 
            lstRequest[1].ProfitCommission__c = 10;
            lstRequest[1].fixedCommission__c = 11;
            lstRequest[1].FixedRate__c = 12;
            lstRequest[1].MinRate__c = 13;
            lstRequest[1].MaxRate__c = 14;
            lstRequest[1].ProvisionalRate__c = 15;
            lstRequest[1].FlatPremium__c = 16;
            lstRequest[1].MDP__c = 17;
            lstRequest[1].MinVarCommission__c = 18;
            lstRequest[1].MaxVarCommission__c = 19;
            lstRequest[1].ProvisionalCommission__c = 20;
            lstRequest[1].PerHeadPremium__c = 21;
            lstRequest[1].MinPerHeadAmount__c = 22;
            lstRequest[1].MaxPerHeadAmount__c = 23;
            lstRequest[1].ProvisionalPerHeadPremium__c = 24;
            lstRequest[1].EstimatedReinsurancePremium__c = 25;
            lstRequest[1].EstimatedInsurancePremium__c = 26;
            lstRequest[1].LastVersionSent__c = true;
            lstRequest[1].LastVersionAnswered__c = true;
            lstRequest[1].ReinsurerStatus__c = 'Sent';

            lstRequest[2].Quote__c = '1';
            lstRequest[2].VersionMinor__c = 2;
            lstRequest[2].ProfitCommission__c = 10;
            lstRequest[2].fixedCommission__c = 11;
            lstRequest[2].FixedRate__c = 12;
            lstRequest[2].MinRate__c = 13;
            lstRequest[2].MaxRate__c = 14;
            lstRequest[2].ProvisionalRate__c = 15;
            lstRequest[2].FlatPremium__c = 16;
            lstRequest[2].MDP__c = 17;
            lstRequest[2].MinVarCommission__c = 18;
            lstRequest[2].MaxVarCommission__c = 19;
            lstRequest[2].ProvisionalCommission__c = 20;
            lstRequest[2].PerHeadPremium__c = 21;
            lstRequest[2].MinPerHeadAmount__c = 22;
            lstRequest[2].MaxPerHeadAmount__c = 23;
            lstRequest[2].ProvisionalPerHeadPremium__c = 24;
            lstRequest[2].EstimatedReinsurancePremium__c = 25;
            lstRequest[2].EstimatedInsurancePremium__c = 26;

            lstRequest[3].Quote__c = '2';
            lstRequest[3].VersionMinor__c = 2;


            lstRequest[4].LastVersionSent__c = true;
            lstRequest[4].LastVersionAnswered__c = true;
            lstRequest[4].VersionMinor__c = 1;
            lstRequest[4].ProfitCommission__c = 10;
            lstRequest[4].fixedCommission__c = 11;
            lstRequest[4].FixedRate__c = 12;
            lstRequest[4].MinRate__c = 13;
            lstRequest[4].MaxRate__c = 14;
            lstRequest[4].ProvisionalRate__c = 15;
            lstRequest[4].FlatPremium__c = 16;
            lstRequest[4].MDP__c = 17;
            lstRequest[4].MinVarCommission__c = 18;
            lstRequest[4].MaxVarCommission__c = 19;
            lstRequest[4].ProvisionalCommission__c = 20;
            lstRequest[4].PerHeadPremium__c = 21;
            lstRequest[4].MinPerHeadAmount__c = 22;
            lstRequest[4].MaxPerHeadAmount__c = 23;
            lstRequest[4].ProvisionalPerHeadPremium__c = 24;
            lstRequest[4].EstimatedReinsurancePremium__c = 25;
            lstRequest[4].EstimatedInsurancePremium__c = 26;

            lstRequest[5].LastVersionSent__c = true;
            lstRequest[5].LastVersionAnswered__c = true;
            lstRequest[5].VersionMinor__c = 2;
            lstRequest[5].ProfitCommission__c = 10;
            lstRequest[5].fixedCommission__c = 11;
            lstRequest[5].FixedRate__c = 12;
            lstRequest[5].MinRate__c = 13;
            lstRequest[5].MaxRate__c = 14;
            lstRequest[5].ProvisionalRate__c = 15;
            lstRequest[5].FlatPremium__c = 16;
            lstRequest[5].MDP__c = 17;
            lstRequest[5].MinVarCommission__c = 18;
            lstRequest[5].MaxVarCommission__c = 19;
            lstRequest[5].ProvisionalCommission__c = 20;
            lstRequest[5].PerHeadPremium__c = 21;
            lstRequest[5].MinPerHeadAmount__c = 22;
            lstRequest[5].MaxPerHeadAmount__c = 23;
            lstRequest[5].ProvisionalPerHeadPremium__c = 24;
            lstRequest[5].EstimatedReinsurancePremium__c = 25;
            lstRequest[5].EstimatedInsurancePremium__c = 26;

            insert lstRequest;

            //create lead
            lstLeadRequests = new List<Request__c>{
                    // recordTypeId + status required
                    TestFactory.createLeadRequest(lstProgram[1].Id, lstTreaty[2].Id, lstAccount[4].Id, lstAccount[5].Id, '1', '4',
                            mapRecTypeIdRequest.get(AP_Constant.reqRTLead), '2', 'Setup',lstSection[1].Id),

                    TestFactory.createLeadRequest(lstProgram[1].Id, lstTreaty[2].Id, lstAccount[4].Id, lstAccount[5].Id, '2', '4',
                            mapRecTypeIdRequest.get(AP_Constant.reqRTLead), '2', 'Sent',lstSection[1].Id)
            };

            lstLeadRequests[0].LastVersionSent__c = false;
            lstLeadRequests[0].LastVersionAnswered__c = false;
            lstLeadRequests[0].VersionMinor__c = 1;
            lstLeadRequests[0].Accept__c = true;
            lstLeadRequests[0].ProfitCommission__c = 10;
            lstLeadRequests[0].fixedCommission__c = 11;
            lstLeadRequests[0].FixedRate__c = 12;
            lstLeadRequests[0].MinRate__c = 13;
            lstLeadRequests[0].MaxRate__c = 14;
            lstLeadRequests[0].ProvisionalRate__c = 15;
            lstLeadRequests[0].FlatPremium__c = 16;
            lstLeadRequests[0].MDP__c = 17;
            lstLeadRequests[0].MinVarCommission__c = 18;
            lstLeadRequests[0].MaxVarCommission__c = 19;
            lstLeadRequests[0].ProvisionalCommission__c = 20;
            lstLeadRequests[0].PerHeadPremium__c = 21;
            lstLeadRequests[0].MinPerHeadAmount__c = 22;
            lstLeadRequests[0].MaxPerHeadAmount__c = 23;
            lstLeadRequests[0].ProvisionalPerHeadPremium__c = 24;
            lstLeadRequests[0].EstimatedReinsurancePremium__c = 25;
            lstLeadRequests[0].EstimatedInsurancePremium__c = 26;

            lstLeadRequests[1].LastVersionSent__c = true;
            lstLeadRequests[1].LastVersionAnswered__c = true;
            lstLeadRequests[1].VersionMinor__c = 2;
            lstLeadRequests[1].OriginalRequest__c = lstLeadRequests[0].Id;
            lstLeadRequests[1].Accept__c = true;
            lstLeadRequests[1].ProfitCommission__c = 10;
            lstLeadRequests[1].fixedCommission__c = 11;
            lstLeadRequests[1].FixedRate__c = 12;
            lstLeadRequests[1].MinRate__c = 13;
            lstLeadRequests[1].MaxRate__c = 14;
            lstLeadRequests[1].ProvisionalRate__c = 15;
            lstLeadRequests[1].FlatPremium__c = 16;
            lstLeadRequests[1].MDP__c = 17;
            lstLeadRequests[1].MinVarCommission__c = 18;
            lstLeadRequests[1].MaxVarCommission__c = 19;
            lstLeadRequests[1].ProvisionalCommission__c = 20;
            lstLeadRequests[1].PerHeadPremium__c = 21;
            lstLeadRequests[1].MinPerHeadAmount__c = 22;
            lstLeadRequests[1].MaxPerHeadAmount__c = 23;
            lstLeadRequests[1].ProvisionalPerHeadPremium__c = 24;
            lstLeadRequests[1].EstimatedReinsurancePremium__c = 25;
            lstLeadRequests[1].EstimatedInsurancePremium__c = 26;
            update lstLeadRequests;

            lstChildLeadRequests = [SELECT Id, Name, ReinsurerStatus__c,LastVersionSent__c, LastVersionAnswered__c
                                            , VersionMinor__c, Accept__c, Reinsurer__c, Broker__c, TECH_PhaseType__c,
                                            ProfitCommission__c,FixedRate__c,PlacementParticipation__c,ReasonRefusal__c, WrittenShare__c,MinRate__c, WrittenShareResponse__c, QuoteOnBehalf__c, LeadOnBehalf__c, PlacementOnBehalf__c,CommentsResponse__c, ReinsurerExpenses__c, LossCarryingForward__c, OrUnlimited__c, LossCorridorPart__c, LossCorridorMaxLR__c, LossCorridorMinLR__c, NoClaimBonus__c,NoClaimBonusAmount__c,  MaxRate__c, ProvisionalRate__c, FlatPremium__c, MDP__c, FixedCommission__c, MinVarCommission__c, MaxVarCommission__c, ProvisionalCommission__c, PerHeadPremium__c, MinPerHeadAmount__c, MaxPerHeadAmount__c, ProvisionalPerHeadPremium__c, EstimatedReinsurancePremium__c, EstimatedInsurancePremium__c
                                    FROM Request__c
                                    WHERE Reinsurer__c = NULL
                                    AND RecordTypeId = :mapRecTypeIdRequest.get(AP_Constant.reqRTLead)];

            lstChildLeadRequests[0].LastVersionSent__c = false;
            lstChildLeadRequests[0].LastVersionAnswered__c = false;
            lstChildLeadRequests[0].VersionMinor__c = 1;
            lstChildLeadRequests[0].Accept__c = true;
            lstChildLeadRequests[0].ProfitCommission__c = 10;
            lstChildLeadRequests[0].fixedCommission__c = 11;
            lstChildLeadRequests[0].FixedRate__c = 12;
            lstChildLeadRequests[0].MinRate__c = 13;
            lstChildLeadRequests[0].MaxRate__c = 14;
            lstChildLeadRequests[0].ProvisionalRate__c = 15;
            lstChildLeadRequests[0].FlatPremium__c = 16;
            lstChildLeadRequests[0].MDP__c = 17;
            lstChildLeadRequests[0].MinVarCommission__c = 18;
            lstChildLeadRequests[0].MaxVarCommission__c = 19;
            lstChildLeadRequests[0].ProvisionalCommission__c = 20;
            lstChildLeadRequests[0].PerHeadPremium__c = 21;
            lstChildLeadRequests[0].MinPerHeadAmount__c = 22;
            lstChildLeadRequests[0].MaxPerHeadAmount__c = 23;
            lstChildLeadRequests[0].ProvisionalPerHeadPremium__c = 24;
            lstChildLeadRequests[0].EstimatedReinsurancePremium__c = 25;
            lstChildLeadRequests[0].EstimatedInsurancePremium__c = 26;

            lstChildLeadRequests[1].LastVersionSent__c = true;
            lstChildLeadRequests[1].LastVersionAnswered__c = true;
            lstChildLeadRequests[1].VersionMinor__c = 2;
            lstChildLeadRequests[1].OriginalRequest__c = lstChildLeadRequests[0].Id;
            lstChildLeadRequests[1].Accept__c = true;
            lstChildLeadRequests[1].ProfitCommission__c = 10;
            lstChildLeadRequests[1].fixedCommission__c = 11;
            lstChildLeadRequests[1].FixedRate__c = 12;
            lstChildLeadRequests[1].MinRate__c = 13;
            lstChildLeadRequests[1].MaxRate__c = 14;
            lstChildLeadRequests[1].ProvisionalRate__c = 15;
            lstChildLeadRequests[1].FlatPremium__c = 16;
            lstChildLeadRequests[1].MDP__c = 17;
            lstChildLeadRequests[1].MinVarCommission__c = 18;
            lstChildLeadRequests[1].MaxVarCommission__c = 19;
            lstChildLeadRequests[1].ProvisionalCommission__c = 20;
            lstChildLeadRequests[1].PerHeadPremium__c = 21;
            lstChildLeadRequests[1].MinPerHeadAmount__c = 22;
            lstChildLeadRequests[1].MaxPerHeadAmount__c = 23;
            lstChildLeadRequests[1].ProvisionalPerHeadPremium__c = 24;
            lstChildLeadRequests[1].EstimatedReinsurancePremium__c = 25;
            lstChildLeadRequests[1].EstimatedInsurancePremium__c = 26;

            lstChildLeadRequests[1].Accept__c = true;
            lstChildLeadRequests[1].LeadOnBehalf__c = true;
            lstChildLeadRequests[1].CommentsResponse__c = '';

            update lstChildLeadRequests;
        }
    }

    @IsTest
    public static void testGetRequests(){
        System.runAs(testUserAdmin) {
            Test.startTest();
                List<Request__c> lstRequests = LWC17_RespondOnBehalf.getRequests(lstProgram[1].Id, lstAccount[5].Id);
            Test.stopTest();
            System.assertEquals(8, lstRequests.size());
        }
    }

    @IsTest
    public static void testGetRequestDetails(){
        System.runAs(testUserAdmin) {
            Test.startTest();
                Map<String, Object> mapResultQuote = LWC17_RespondOnBehalf.getRequestDetails(lstRequest[0].Id);
                Map<String, Object> mapResultLead = LWC17_RespondOnBehalf.getRequestDetails(lstLeadRequests[0].Id);
                Map<String, Object> mapResultPlacement = LWC17_RespondOnBehalf.getRequestDetails(lstRequest[5].Id);
            Test.stopTest();

            List<Request__c> lstQuoteRequest = (List<Request__c>)mapResultQuote.get('lstRequestAll');
            List<Request__c> lstLeadRequest = (List<Request__c>)mapResultQuote.get('lstRequestAll');
            List<Request__c> lstPlacementRequest = (List<Request__c>)mapResultQuote.get('lstRequestAll');
            System.assertEquals(2, lstQuoteRequest.size());
            System.assertEquals(2, lstLeadRequest.size());
            System.assertEquals(2, lstPlacementRequest.size());
        }
    }

    @IsTest
    public static void testSaveRequestRecordQuoteTrue(){
        System.runAs(testUserAdmin) {
            Test.startTest();
                List <Request__c> lstRequestToSave = new List<Request__c>{lstRequest[2], lstRequest[3]};
                List <Request__c> lstRequestParent = new List<Request__c>{lstRequest[2], lstRequest[3]};
                Date quotedeadLine = Date.today();
                Map<String, Object> mapResultQuote = LWC17_RespondOnBehalf.saveRequestRecord(lstRequestToSave, 'Quote', lstRequestParent, lstRequest[5].Id, quotedeadLine, true);
            Test.stopTest();
            System.assertEquals(null, mapResultQuote.get('Error'));
            System.assertEquals('Success', mapResultQuote.get('Success'));

            for(Request__c quoteAns : [SELECT Id, ReinsurerStatus__c FROM Request__c WHERE Id = :lstRequest[2].Id]){
                System.assertEquals(AP_Constant.statusAnswered, quoteAns.ReinsurerStatus__c);
            }

            for(Request__c quoteRefused : [SELECT Id, ReinsurerStatus__c FROM Request__c WHERE Id = :lstRequest[3].Id]){
                System.assertEquals(AP_Constant.statusRefused, quoteRefused.ReinsurerStatus__c);
            }
        }
    }
    
    @IsTest
    public static void testSaveRequestRecordQuoteFalse(){
        System.runAs(testUserAdmin) {
            Test.startTest();
                List <Request__c> lstRequestToSave = new List<Request__c>{lstRequest[2], lstRequest[3]};
                List <Request__c> lstRequestParent = new List<Request__c>{lstRequest[2], lstRequest[3]};
                Date quotedeadLine = Date.today();
                Map<String, Object> mapResultQuote = LWC17_RespondOnBehalf.saveRequestRecord(lstRequestToSave, 'Quote', lstRequestParent, lstRequest[5].Id, quotedeadLine, false);
            Test.stopTest();
            System.assertEquals(null, mapResultQuote.get('Error'));
            System.assertEquals('Success', mapResultQuote.get('Success'));

            for(Request__c quoteAns : [SELECT Id, ReinsurerStatus__c FROM Request__c WHERE Id = :lstRequest[2].Id]){
                System.assertEquals(AP_Constant.statusAnswered, quoteAns.ReinsurerStatus__c);
            }

            for(Request__c quoteRefused : [SELECT Id, ReinsurerStatus__c FROM Request__c WHERE Id = :lstRequest[3].Id]){
                System.assertEquals(AP_Constant.statusRefused, quoteRefused.ReinsurerStatus__c);
            }
        }
    }

    @IsTest
    public static void testSaveRequestRecordLeadTrue(){
        System.runAs(testUserAdmin) {
            Test.startTest();
            lstLeadRequests[0].Accept__c = true;
            lstLeadRequests[0].LeadOnBehalf__c = true;
            lstLeadRequests[0].CommentsResponse__c = '';

            lstLeadRequests[1].Accept__c = true;
            lstLeadRequests[1].LeadOnBehalf__c = true;
            lstLeadRequests[1].CommentsResponse__c = '';
            Date quotedeadLine = Date.today();

            update lstLeadRequests;
                Map<String, Object> mapResultLead = LWC17_RespondOnBehalf.saveRequestRecord(lstChildLeadRequests, 'Lead', lstLeadRequests, null, quotedeadLine, true);
            Test.stopTest();
        }
    }
    
    
    @IsTest
    public static void testSaveRequestRecordLeadFalse(){
        System.runAs(testUserAdmin) {
            Test.startTest();
            lstLeadRequests[0].Accept__c = true;
            lstLeadRequests[0].LeadOnBehalf__c = true;
            lstLeadRequests[0].CommentsResponse__c = '';

            lstLeadRequests[1].Accept__c = true;
            lstLeadRequests[1].LeadOnBehalf__c = true;
            lstLeadRequests[1].CommentsResponse__c = '';
            Date quotedeadLine = Date.today();

            update lstLeadRequests;
                Map<String, Object> mapResultLead = LWC17_RespondOnBehalf.saveRequestRecord(lstChildLeadRequests, 'Lead', lstLeadRequests, null, quotedeadLine, false);
            Test.stopTest();
        }
    }

    @IsTest
    public static void testSaveRequestRecordPlacement(){
        System.runAs(testUserAdmin) {
            Test.startTest();
                lstRequest[4].PlacementParticipation__c = '1';
                lstRequest[5].PlacementParticipation__c = '1';
                update lstRequest;
                List <Request__c> lstRequestToSave = new List<Request__c>{lstRequest[5]};
                List <Request__c> lstRequestParent = new List<Request__c>{lstRequest[4]};
                Date quotedeadLine = Date.today();
                
                Map<String, Object> mapResultPlacement = LWC17_RespondOnBehalf.saveRequestRecord(lstRequestToSave, 'Placement', lstRequestParent, lstRequest[0].Id, quotedeadLine, false);
            Test.stopTest();
            //System.assertEquals(null, mapResultPlacement.get('Error'));
            System.assertEquals('Success', mapResultPlacement.get('Success'));

            for(Request__c placementReq : [SELECT Id, ReinsurerStatus__c FROM Request__c WHERE Id = :lstRequest[4].Id]){
                System.assertEquals('Answered', placementReq.ReinsurerStatus__c);
            }
        }
    }

    @IsTest
    public static void testDisableLeadPlacementInfo1(){
        System.runAs(testUserAdmin) {
            Test.startTest();
                Boolean result = LWC17_RespondOnBehalf.disableLeadPlacementInfo(lstProgram[1].Id);
            Test.stopTest();
            System.assertEquals(false, result);
        }
    }

    @IsTest
    public static void testDisableLeadPlacementInfo2(){
        System.runAs(testUserAdmin) {
            Test.startTest();
                lstProgram[1].TECH_ShowClosePreviousPhaseBtn__c = '2';
                update lstProgram[1];
                Boolean result = LWC17_RespondOnBehalf.disableLeadPlacementInfo(lstProgram[1].Id);
            Test.stopTest();
            System.assertEquals(true, result);
        }
    }

    @IsTest
    public static void testGetPlacementRTQuote(){
        System.runAs(testUserAdmin) {
            Test.startTest();
                String result = LWC17_RespondOnBehalf.getPlacementRequestRecordTypeId('Quote');
            Test.stopTest();
            System.assertNotEquals(null,result);
        }
    }

    @IsTest
    public static void testGetPlacementRTPlacement(){
        System.runAs(testUserAdmin) {
            Test.startTest();
                String result = LWC17_RespondOnBehalf.getPlacementRequestRecordTypeId('Placement');
            Test.stopTest();
            System.assertNotEquals(null,result);
        }
    }
}