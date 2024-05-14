@IsTest
public with sharing class AP65_RecalcFieldLeadReq_TEST {
    /**************************************************************************************
-- - Author        : Telesio
-- - Description   : Test class for AP64_UpdateRequestFromConditions
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 13-FEB-2023  RRA   1.0      Initial version
--------------------------------------------------------------------------------------
**************************************************************************************/
    static User testUserAdmin;
    static User testUserCE;
    static List<Account> lstAccount;
    static List<Program__c> lstProgram;
    static List<Treaty__c> lstTreaty;
    static List<Section__c> lstSection;
    static List<Request__c> lstLeadRequests;
    static List<User> lstUsers = new List<User>();
    static Map<String, Id> mapRecTypeIdRequest = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectRequest});

    static{
        //create User
        testUserAdmin = TestFactory.createUser('testUserAdmin', TestFactory.getProfileAdminId());
        testUserCE = TestFactory.createUser('testUserCE', TestFactory.getProfileCEId());
        testUserCE.BypassTrigger__c = 'AP38_CreateSharingForRequest;AP53_UpdateSAStatus;AP43_DeleteClonedRequests;AP42_DeleteDocumentVisibility';
        lstUsers.add(testUserAdmin);
        lstUsers.add(testUserCE);
        insert lstUsers;

        System.runAs(testUserCE){
            Map<String, Id> mapRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{
                    AP_Constant.sObjectAcc
            });

            //create Account
            lstAccount = new List<Account> {
                    TestFactory.createAccount(mapRecTypeId.get(AP_Constant.accRTPrincipalCedingCom),'Account A','C_0001'),
                    TestFactory.createAccount(mapRecTypeId.get(AP_Constant.accRTPrincipalCedingCom),'Account B','C_0002'),
                    TestFactory.createAccount(mapRecTypeId.get(AP_Constant.accRTCoveredCedingCompany),'Account C','C_0003'),
                    TestFactory.createAccount(mapRecTypeId.get(AP_Constant.accRTCoveredCedingCompany),'Account D','C_0004'),
                    TestFactory.createAccount(mapRecTypeId.get(AP_Constant.accRTBroker),'Account E','C_0005'),
                    TestFactory.createAccount(mapRecTypeId.get(AP_Constant.accRTReinsurer),'Account F','C_0006')
            };
            insert lstAccount;

            //create Program
            lstProgram = new List<Program__c>{
                    TestFactory.createProgram('TestProg1', '1', '1'
                            , Date.today(), Date.today().addYears(1), '2', Date.today(), Date.today().addYears(1)
                            , '2018', lstAccount[0].Id, '23002', '1', '25009'),
                    TestFactory.createProgram('TestProg3', '2', '3'
                            , Date.today(), Date.today().addYears(1), '2', Date.today(), Date.today().addYears(1)
                            , '2018', lstAccount[1].Id, '23001', '1', '25001')
            };
            insert lstProgram;

            //create Treaty
            lstTreaty = new List<Treaty__c> {
                    TestFactory.createTreaty('TestTreaty1', 1, '2020-00000222', '3'
                            , lstProgram[0].Id, '2', 34, '10', '2020-00000222', '1', '2', '2', '2', '2'),

                    TestFactory.createTreaty('TestTreaty2', 2, '2020-00000222', '2', lstProgram[0].Id
                            , '1', 44, '44', '2020-00000222', '2', '2', '2', '2', '2'),

                    TestFactory.createTreaty('TestTreaty3', 3, '2020-00000222', '2'
                            , lstProgram[1].Id, '2', 89, '44', '2020-00000222', '3', '2', '2', '2', '2')
            };
            lstTreaty[0].Deductions_Perc__c = 55;
            lstTreaty[2].Deductions_Perc__c = 68;
            insert lstTreaty;

            //create Section
            lstSection = new List<Section__c> {
                    TestFactory.createSection('TestSection1', '1.0', '22003', '20006', '9052'
                            , 322, 34, lstProgram[0].Id, lstTreaty[0].Id, '1', '1'
                            , true, '1', null, '23001', '1', '5', '2', '2'),

                    TestFactory.createSection('TestSection2', '2.0', '22003', '20006', '9052'
                            , 23, 5, lstProgram[1].Id, lstTreaty[2].Id, '2', '1'
                            , false, '1', null, '23001', '1', '5', '2', '2')
            };
            insert lstSection;
            
            /*lstLeadRequests = new List<Request__c>{
                    // recordTypeId + status required
                    TestFactory.createRequest(lstProgram[0].Id, lstTreaty[0].Id, lstAccount[4].Id, lstAccount[5].Id, '1', '4',
                            mapRecTypeIdRequest.get(AP_Constant.reqRTLead), '2', 'Setup', lstSection[0].Id),

                    TestFactory.createRequest(lstProgram[1].Id, lstTreaty[2].Id, lstAccount[4].Id, lstAccount[5].Id, '2', '4',
                            mapRecTypeIdRequest.get(AP_Constant.reqRTLead), '2', 'Setup', lstSection[1].Id)
            };*/
            
            lstLeadRequests = new List<Request__c>{
                // recordTypeId + status required
                TestFactory.createLeadRequest(lstProgram[0].Id, lstTreaty[0].Id, lstAccount[3].Id, lstAccount[5].Id, '1', '4',
                                                mapRecTypeIdRequest.get(AP_Constant.reqRTLead), '2', 'Setup',lstSection[0].Id),
    
                TestFactory.createLeadRequest(lstProgram[0].Id, lstTreaty[0].Id, lstAccount[3].Id, lstAccount[5].Id, '2', '4',
                                                mapRecTypeIdRequest.get(AP_Constant.reqRTLead), '2', 'Setup',lstSection[1].Id)
            };
        }
    }

    @IsTest
    public static void testUpdatefieldsLeadRequestsFixedRate(){
        System.runAs(testUserCE) {
            Test.startTest();
            /*lstLeadRequests[0].FixedRate__c = 30;
            lstLeadRequests[1].FixedRate__c = 40;
            update lstLeadRequests;*/
            
            Request__c parentRequest = new Request__c();
            parentRequest.Program__c = lstProgram[0].Id;
            parentRequest.Treaty__c = lstTreaty[0].Id;
            parentRequest.Broker__c = lstAccount[3].Id;
            parentRequest.Reinsurer__c = lstAccount[5].Id;
            parentRequest.QuoteType__c = '1';
            parentRequest.TECH_PhaseType__c = '4';
            parentRequest.ActiveStatus__c = '2';
            parentRequest.RecordTypeId = mapRecTypeIdRequest.get(AP_Constant.reqRTLead);
            parentRequest.ReinsurerStatus__c = 'Setup';
            parentRequest.Section__c = lstSection[0].Id;
            insert parentRequest;

            //create child request
            Request__c childRequest = new Request__c();
            childRequest.Program__c = lstProgram[0].Id;
            childRequest.Treaty__c = lstTreaty[0].Id;
            //  childRequest.Broker__c = brokerId;
            childRequest.Reinsurer__c = null;
            childRequest.QuoteType__c = '1';
            childRequest.TECH_PhaseType__c = '4';
            childRequest.ActiveStatus__c = '2';
            childRequest.RecordTypeId = mapRecTypeIdRequest.get(AP_Constant.reqRTLead);
            childRequest.ReinsurerStatus__c = 'Setup';
            childRequest.Section__c = lstSection[0].Id;
            childRequest.FixedRate__c = 2 ;
            childRequest.MinRate__c = null;
            childRequest.MaxRate__c= 6;
            childRequest.ProvisionalRate__c= 2;
            childRequest.FlatPremium__c= null;
            childRequest.MDP__c= 2;
            childRequest.FixedCommission__c= 2;
            childRequest.MinVarCommission__c= 2;
            childRequest.MaxVarCommission__c= 2;
            childRequest.ProvisionalCommission__c= 2;
            childRequest.PerHeadPremium__c= 2;
            childRequest.MinPerHeadAmount__c= null;
            childRequest.MaxPerHeadAmount__c= 2;
            childRequest.ProvisionalPerHeadPremium__c= 2;
            childRequest.EstimatedInsurancePremium__c= 2;
            childRequest.PerHeadPremium__c= null;
            childRequest.EstimatedReinsurancePremium__c = 3000000 ; 
            insert childRequest;

            //create junction object
            LeadRequestSelection__c leadReqSelection = new LeadRequestSelection__c();
            leadReqSelection.LeadRequestChild__c = childRequest.Id;
            leadReqSelection.LeadRequestParent__c = parentRequest.Id;
            insert leadReqSelection;
            
            lstSection[0].ExpectedMDP__c = 100;
            lstSection[0].ExpectedDP__c = 0;
            lstSection[0].ExpectedMP__c = 0;
            lstSection[1].ExpectedMDP__c = 0;
            lstSection[1].ExpectedDP__c = 52;
            lstSection[1].ExpectedMP__c = 10;
            lstSection[0].TotalEPI__c = 1000000;
            lstSection[1].TotalEPI__c = 1000000;
            update lstSection;

            AP65_RecalculateFieldsLeadReq.updatefieldsLeadRequests(new List<Section__c>{lstSection[0], lstSection[1]});
            Test.stopTest();
        }
    }

    @IsTest
    public static void testUpdatefieldsLeadRequestsFlatPremium(){
        System.runAs(testUserCE) {
            Test.startTest();
            Request__c parentRequest = new Request__c();
            parentRequest.Program__c = lstProgram[0].Id;
            parentRequest.Treaty__c = lstTreaty[0].Id;
            parentRequest.Broker__c = lstAccount[3].Id;
            parentRequest.Reinsurer__c = lstAccount[5].Id;
            parentRequest.QuoteType__c = '1';
            parentRequest.TECH_PhaseType__c = '4';
            parentRequest.ActiveStatus__c = '2';
            parentRequest.RecordTypeId = mapRecTypeIdRequest.get(AP_Constant.reqRTLead);
            parentRequest.ReinsurerStatus__c = 'Setup';
            parentRequest.Section__c = lstSection[0].Id;
            insert parentRequest;

            //create child request
            Request__c childRequest = new Request__c();
            childRequest.Program__c = lstProgram[0].Id;
            childRequest.Treaty__c = lstTreaty[0].Id;
            //  childRequest.Broker__c = brokerId;
            childRequest.Reinsurer__c = null;
            childRequest.QuoteType__c = '1';
            childRequest.TECH_PhaseType__c = '4';
            childRequest.ActiveStatus__c = '2';
            childRequest.RecordTypeId = mapRecTypeIdRequest.get(AP_Constant.reqRTLead);
            childRequest.ReinsurerStatus__c = 'Setup';
            childRequest.Section__c = lstSection[0].Id;
            childRequest.FixedRate__c = null ;
            childRequest.MinRate__c = null;
            childRequest.MaxRate__c= 6;
            childRequest.ProvisionalRate__c= 2;
            childRequest.FlatPremium__c= 200;
            childRequest.MDP__c= 2;
            childRequest.FixedCommission__c= 2;
            childRequest.MinVarCommission__c= 2;
            childRequest.MaxVarCommission__c= 2;
            childRequest.ProvisionalCommission__c= 2;
            childRequest.PerHeadPremium__c= 2;
            childRequest.MinPerHeadAmount__c= null;
            childRequest.MaxPerHeadAmount__c= 2;
            childRequest.ProvisionalPerHeadPremium__c= 2;
            childRequest.EstimatedInsurancePremium__c= 2;
            childRequest.PerHeadPremium__c= null;
            childRequest.EstimatedReinsurancePremium__c = 3000000 ; 
            insert childRequest;

            //create junction object
            LeadRequestSelection__c leadReqSelection = new LeadRequestSelection__c();
            leadReqSelection.LeadRequestChild__c = childRequest.Id;
            leadReqSelection.LeadRequestParent__c = parentRequest.Id;
            insert leadReqSelection;
            
            lstSection[0].ExpectedMDP__c = 100;
            lstSection[0].ExpectedDP__c = 0;
            lstSection[0].ExpectedMP__c = 0;
            lstSection[1].ExpectedMDP__c = 0;
            lstSection[1].ExpectedDP__c = 52;
            lstSection[1].ExpectedMP__c = 10;
            lstSection[0].TotalEPI__c = 1000000;
            lstSection[1].TotalEPI__c = 1000000;
            update lstSection;
            
            
            AP65_RecalculateFieldsLeadReq.updatefieldsLeadRequests(new List<Section__c>{lstSection[0], lstSection[1]});
            Test.stopTest();
        }
    }

    @IsTest
    public static void testUpdatefieldsLeadRequestsMinRate(){
        System.runAs(testUserCE) {
            Test.startTest();
            Request__c parentRequest = new Request__c();
            parentRequest.Program__c = lstProgram[0].Id;
            parentRequest.Treaty__c = lstTreaty[0].Id;
            parentRequest.Broker__c = lstAccount[3].Id;
            parentRequest.Reinsurer__c = lstAccount[5].Id;
            parentRequest.QuoteType__c = '1';
            parentRequest.TECH_PhaseType__c = '4';
            parentRequest.ActiveStatus__c = '2';
            parentRequest.RecordTypeId = mapRecTypeIdRequest.get(AP_Constant.reqRTLead);
            parentRequest.ReinsurerStatus__c = 'Setup';
            parentRequest.Section__c = lstSection[0].Id;
            insert parentRequest;

            //create child request
            Request__c childRequest = new Request__c();
            childRequest.Program__c = lstProgram[0].Id;
            childRequest.Treaty__c = lstTreaty[0].Id;
            //  childRequest.Broker__c = brokerId;
            childRequest.Reinsurer__c = null;
            childRequest.QuoteType__c = '1';
            childRequest.TECH_PhaseType__c = '4';
            childRequest.ActiveStatus__c = '2';
            childRequest.RecordTypeId = mapRecTypeIdRequest.get(AP_Constant.reqRTLead);
            childRequest.ReinsurerStatus__c = 'Setup';
            childRequest.Section__c = lstSection[0].Id;
            childRequest.FixedRate__c = null ;
            childRequest.MinRate__c = 5;
            childRequest.MaxRate__c= 6;
            childRequest.ProvisionalRate__c= 2;
            childRequest.FlatPremium__c= null;
            childRequest.MDP__c= 2;
            childRequest.FixedCommission__c= 2;
            childRequest.MinVarCommission__c= 2;
            childRequest.MaxVarCommission__c= 2;
            childRequest.ProvisionalCommission__c= 2;
            childRequest.PerHeadPremium__c= 2;
            childRequest.MinPerHeadAmount__c= null;
            childRequest.MaxPerHeadAmount__c= 2;
            childRequest.ProvisionalPerHeadPremium__c= 2;
            childRequest.EstimatedInsurancePremium__c= 2;
            childRequest.PerHeadPremium__c= null;
            childRequest.EstimatedReinsurancePremium__c = 3000000 ; 
            insert childRequest;

            //create junction object
            LeadRequestSelection__c leadReqSelection = new LeadRequestSelection__c();
            leadReqSelection.LeadRequestChild__c = childRequest.Id;
            leadReqSelection.LeadRequestParent__c = parentRequest.Id;
            insert leadReqSelection;
            
            lstSection[0].ExpectedMDP__c = 100;
            lstSection[0].ExpectedDP__c = 0;
            lstSection[0].ExpectedMP__c = 0;
            lstSection[1].ExpectedMDP__c = 0;
            lstSection[1].ExpectedDP__c = 52;
            lstSection[1].ExpectedMP__c = 10;
            lstSection[0].TotalEPI__c = 1000000;
            lstSection[1].TotalEPI__c = 1000000;
            update lstSection;
            AP65_RecalculateFieldsLeadReq.updatefieldsLeadRequests(new List<Section__c>{lstSection[0], lstSection[1]});
            Test.stopTest();
        }
    }

    @IsTest
    public static void testUpdatefieldsLeadRequestsPerHeadPremium(){
        System.runAs(testUserCE) {
            Test.startTest();
            Request__c parentRequest = new Request__c();
            parentRequest.Program__c = lstProgram[0].Id;
            parentRequest.Treaty__c = lstTreaty[0].Id;
            parentRequest.Broker__c = lstAccount[3].Id;
            parentRequest.Reinsurer__c = lstAccount[5].Id;
            parentRequest.QuoteType__c = '1';
            parentRequest.TECH_PhaseType__c = '4';
            parentRequest.ActiveStatus__c = '2';
            parentRequest.RecordTypeId = mapRecTypeIdRequest.get(AP_Constant.reqRTLead);
            parentRequest.ReinsurerStatus__c = 'Setup';
            parentRequest.Section__c = lstSection[0].Id;
            insert parentRequest;

            //create child request
            Request__c childRequest = new Request__c();
            childRequest.Program__c = lstProgram[0].Id;
            childRequest.Treaty__c = lstTreaty[0].Id;
            //  childRequest.Broker__c = brokerId;
            childRequest.Reinsurer__c = null;
            childRequest.QuoteType__c = '1';
            childRequest.TECH_PhaseType__c = '4';
            childRequest.ActiveStatus__c = '2';
            childRequest.RecordTypeId = mapRecTypeIdRequest.get(AP_Constant.reqRTLead);
            childRequest.ReinsurerStatus__c = 'Setup';
            childRequest.Section__c = lstSection[0].Id;
            childRequest.FixedRate__c = null ;
            childRequest.MinRate__c = null;
            childRequest.MaxRate__c= 6;
            childRequest.ProvisionalRate__c= 2;
            childRequest.FlatPremium__c= null;
            childRequest.MDP__c= 2;
            childRequest.FixedCommission__c= 2;
            childRequest.MinVarCommission__c= 2;
            childRequest.MaxVarCommission__c= 2;
            childRequest.ProvisionalCommission__c= 2;
            childRequest.PerHeadPremium__c= 2;
            childRequest.MinPerHeadAmount__c= null;
            childRequest.MaxPerHeadAmount__c= 2;
            childRequest.ProvisionalPerHeadPremium__c= 2;
            childRequest.EstimatedInsurancePremium__c= 2;
            childRequest.PerHeadPremium__c= 100;
            childRequest.EstimatedReinsurancePremium__c = 3000000 ; 
            insert childRequest;

            //create junction object
            LeadRequestSelection__c leadReqSelection = new LeadRequestSelection__c();
            leadReqSelection.LeadRequestChild__c = childRequest.Id;
            leadReqSelection.LeadRequestParent__c = parentRequest.Id;
            insert leadReqSelection;
            
            lstSection[0].ExpectedMDP__c = 100;
            lstSection[0].ExpectedDP__c = 0;
            lstSection[0].ExpectedMP__c = 0;
            lstSection[1].ExpectedMDP__c = 0;
            lstSection[1].ExpectedDP__c = 52;
            lstSection[1].ExpectedMP__c = 10;
            lstSection[0].TotalEPI__c = 1000000;
            lstSection[1].TotalEPI__c = 1000000;
            update lstSection;
            
            AP65_RecalculateFieldsLeadReq.updatefieldsLeadRequests(new List<Section__c>{lstSection[0], lstSection[1]});
            Test.stopTest();
        }
    }

    @IsTest
    public static void testUpdatefieldsLeadRequestsMinPerHeadAmount(){
        System.runAs(testUserCE) {
            Test.startTest();
            Request__c parentRequest = new Request__c();
            parentRequest.Program__c = lstProgram[0].Id;
            parentRequest.Treaty__c = lstTreaty[0].Id;
            parentRequest.Broker__c = lstAccount[3].Id;
            parentRequest.Reinsurer__c = lstAccount[5].Id;
            parentRequest.QuoteType__c = '1';
            parentRequest.TECH_PhaseType__c = '4';
            parentRequest.ActiveStatus__c = '2';
            parentRequest.RecordTypeId = mapRecTypeIdRequest.get(AP_Constant.reqRTLead);
            parentRequest.ReinsurerStatus__c = 'Setup';
            parentRequest.Section__c = lstSection[0].Id;
            insert parentRequest;

            //create child request
            Request__c childRequest = new Request__c();
            childRequest.Program__c = lstProgram[0].Id;
            childRequest.Treaty__c = lstTreaty[0].Id;
            //  childRequest.Broker__c = brokerId;
            childRequest.Reinsurer__c = null;
            childRequest.QuoteType__c = '1';
            childRequest.TECH_PhaseType__c = '4';
            childRequest.ActiveStatus__c = '2';
            childRequest.RecordTypeId = mapRecTypeIdRequest.get(AP_Constant.reqRTLead);
            childRequest.ReinsurerStatus__c = 'Setup';
            childRequest.Section__c = lstSection[0].Id;
            childRequest.FixedRate__c = null ;
            childRequest.MinRate__c = null;
            childRequest.MaxRate__c= 6;
            childRequest.ProvisionalRate__c= 2;
            childRequest.FlatPremium__c= null;
            childRequest.MDP__c= 2;
            childRequest.FixedCommission__c= 2;
            childRequest.MinVarCommission__c= 2;
            childRequest.MaxVarCommission__c= 2;
            childRequest.ProvisionalCommission__c= 2;
            childRequest.PerHeadPremium__c= 2;
            childRequest.MinPerHeadAmount__c= 2;
            childRequest.MaxPerHeadAmount__c= 2;
            childRequest.ProvisionalPerHeadPremium__c= 2;
            childRequest.EstimatedInsurancePremium__c= 2;
            childRequest.PerHeadPremium__c= null;
            childRequest.EstimatedReinsurancePremium__c = 3000000 ; 
            insert childRequest;

            //create junction object
            LeadRequestSelection__c leadReqSelection = new LeadRequestSelection__c();
            leadReqSelection.LeadRequestChild__c = childRequest.Id;
            leadReqSelection.LeadRequestParent__c = parentRequest.Id;
            insert leadReqSelection;
            
            lstSection[0].ExpectedMDP__c = 100;
            lstSection[0].ExpectedDP__c = 0;
            lstSection[0].ExpectedMP__c = 0;
            lstSection[1].ExpectedMDP__c = 0;
            lstSection[1].ExpectedDP__c = 52;
            lstSection[1].ExpectedMP__c = 10;
            lstSection[0].TotalEPI__c = 1000000;
            lstSection[1].TotalEPI__c = 1000000;
            update lstSection;
            
            AP65_RecalculateFieldsLeadReq.updatefieldsLeadRequests(new List<Section__c>{lstSection[0], lstSection[1]});
            Test.stopTest();
        }
    }
}