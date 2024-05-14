@IsTest
public with sharing class LWC24_NewPlacementRequest_TEST {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Test class for LWC24_NewPlacementRequest
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 04-FEB-2021  MBE   1.0      Initial version
-- 24-MAY-2021   MBE   1.1      W-0974 - Bug bloquant Prod - Impossibilité de créer une Lead request - TECH_Actor2Id__c
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
    static List<Contact> lstContact;
    static List<AccountContactRelation> lstAccContactRelation;
    static List<Pool__c> lstPool;
    static List<PoolTreatySection__c> lstPoolTreatySections;

    static {
        //create User
        testUserAdmin = TestFactory.createUser('testUserAdmin', TestFactory.getProfileAdminId());
        testUserCE = TestFactory.createUser('testUserCE', TestFactory.getProfileCEId());
        User assignedToUser = TestFactory.createUserWithRole('TestAssignedTo', TestFactory.getProfileAdminId(),TestFactory.getHeadUGPRoleId());
        lstUsers.add(testUserAdmin);
        lstUsers.add(testUserCE);
        lstUsers.add(assignedToUser);
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

            for(Account acc : lstAccount){
                acc.IsActive__c = true;
            }

            insert lstAccount;

            //create Program
            lstProgram = new List<Program__c> {
                TestFactory.createProgram('TestProg1', '1', '1'
                                    , Date.today(), Date.today().addYears(1), '2', Date.today(), Date.today().addYears(1)
                                    , '2018', lstAccount[0].Id, '23002','2'
                                    , '25009'),

                TestFactory.createProgram('TestProg2', '2', '2', Date.today()
                                    , Date.today().addYears(1), '1', Date.today(), Date.today().addYears(1), '2018'
                                    , lstAccount[1].Id, '23001', '2', '25001'),

                TestFactory.createProgram('TestProg3', '1', '3', Date.today()
                                    , Date.today().addYears(1), '2', Date.today(), Date.today().addYears(1), '2020'
                                    , lstAccount[1].Id, '23001', '1', '25001')
            };

            lstProgram[0].TECH_ShowClosePreviousPhaseBtn__c = '1';
            lstProgram[1].TECH_ShowClosePreviousPhaseBtn__c = '2';
            lstProgram[2].RenewedFromProgram__c = lstProgram[1].Id;
            insert lstProgram;

            lstProgram[2].RenewedFromProgram__c = lstProgram[1].Id;
            lstProgram[1].RenewedFromProgram__c =  lstProgram[0].Id;
            lstProgram[1].TypeOfRenew__c = 'Standard Renew';
            update lstProgram;

            //create Treaty
            lstTreaty = new List<Treaty__c> {
                TestFactory.createTreaty('TestTreaty1', 1, 'ref01', '3'
                                    , lstProgram[0].Id, '1', 34, '10', '2020-00000222', '1', '2', '2', '2', '2'),

                TestFactory.createTreaty('TestTreaty2', 2, 'ref02', '2', lstProgram[0].Id
                                    , '1', 44, '44', '2020-00000222', '2', '2', '2', '2', '2'),

                TestFactory.createTreaty('TestTreaty3', 3, 'ref03', '2'
                                    , lstProgram[1].Id, '1', 89, '44', '2020-00000222', '3', '2', '2', '2', '2'),

                TestFactory.createTreaty('TestTreaty4', 3, 'ref03', '3'
                                    , lstProgram[2].Id, '1', 89, '10', '2020-00000222', '1', '2', '2', '2', '2')
            };
            insert lstTreaty;

            //create Section
            lstSection = new List<Section__c> {
                TestFactory.createSection('TestSection1', '1.1', '22003', '20006', '9052'
                                    , 322, 34, lstProgram[0].Id, lstTreaty[0].Id, '3', '1'
                                    , true, '5', null, '23001', '1', '5', '2', '2'),

                TestFactory.createSection('TestSection2', '2.1', '22003', '20006', '9052'
                                    , 23, 5, lstProgram[0].Id, lstTreaty[1].Id, '3', '1'
                                    , false, '5', null, '23001', '1', '5', '2', '2'),

                TestFactory.createSection('TestSection3', '2.1', '22003', '20006', '9052'
                                    , 23, 5, lstProgram[1].Id, lstTreaty[2].Id, '3', '1'
                                    , false, '5', null, '23001', '1', '5', '2', '2'),

                TestFactory.createSection('TestSection4', '2.1', '22003', '20006', '9052'
                , 23, 5, lstProgram[1].Id, lstTreaty[2].Id, '3', '1'
                , false, '5', null, '23001', '1', '5', '2', '2')
            };

            lstSection[0].Retained_to_lead__c = true;
            lstSection[0].Status__c = AP_Constant.statusActive;
            lstSection[1].Retained_to_lead__c = true;
            lstSection[1].Status__c = AP_Constant.statusActive;
            lstSection[2].Status__c = AP_Constant.statusActive;
            lstSection[2].Retained_to_lead__c = true;
            lstSection[3].Status__c = AP_Constant.statusActive;
            lstSection[3].Retained_to_lead__c = true;
            insert lstSection;

            //create Request
            lstRequest = new List<Request__c>{
                // recordTypeId + status required
                TestFactory.createRequest(lstProgram[0].Id, lstTreaty[0].Id, lstAccount[4].Id, lstAccount[5].Id, '1', '3',
                                            mapRecTypeIdRequest.get(AP_Constant.reqRTQuote), '2', 'Setup',lstSection[0].Id),

                TestFactory.createRequest(lstProgram[0].Id, lstTreaty[0].Id, lstAccount[4].Id, lstAccount[5].Id, '2', '1',
                                        mapRecTypeIdRequest.get(AP_Constant.reqRTQuote), '2', 'Sent',lstSection[0].Id),

                TestFactory.createRequest(lstProgram[1].Id, lstTreaty[2].Id, lstAccount[4].Id, lstAccount[8].Id, '1', '3',
                                        mapRecTypeIdRequest.get(AP_Constant.reqRTQuote), '2', 'sent',lstSection[2].Id),

                TestFactory.createRequest(lstProgram[1].Id, lstTreaty[2].Id, lstAccount[4].Id, lstAccount[8].Id, '2', '1',
                                        mapRecTypeIdRequest.get(AP_Constant.reqRTQuote), '2', 'Sent',lstSection[2].Id),

                TestFactory.createRequest(lstProgram[1].Id, lstTreaty[2].Id, lstAccount[4].Id, lstAccount[5].Id, '1', '5',
                                        mapRecTypeIdRequest.get(AP_Constant.reqRTPlacement), '2', 'Setup',lstSection[2].Id),

                TestFactory.createRequest(lstProgram[1].Id, lstTreaty[2].Id, lstAccount[4].Id, lstAccount[5].Id, '2', '5',
                                        mapRecTypeIdRequest.get(AP_Constant.reqRTPlacement), '2', 'Sent',lstSection[2].Id)
            };

            lstRequest[2].OriginalRequest__c = lstRequest[0].Id;
            lstRequest[3].OriginalRequest__c = lstRequest[1].Id;
            lstRequest[3].OriginalRequest__c = lstRequest[1].Id;
            lstRequest[4].LastVersionSent__c = true;
            lstRequest[5].LastVersionAnswered__c = true;
            lstRequest[4].LastVersionSent__c = true;
            lstRequest[5].LastVersionAnswered__c = true;

            for(Request__c req : lstRequest){
                req.LastVersionSent__c = true;
                req.LastVersionAnswered__c = true;
            }

            insert lstRequest;

            //create lead 
            lstLeadRequests = new List<Request__c>{
                // recordTypeId + status required
                TestFactory.createLeadRequest(lstProgram[1].Id, lstTreaty[2].Id, lstAccount[4].Id, lstAccount[5].Id, '1', '4',
                                            mapRecTypeIdRequest.get(AP_Constant.reqRTLead), '1', 'Setup',lstSection[2].Id),

                TestFactory.createLeadRequest(lstProgram[1].Id, lstTreaty[2].Id, lstAccount[4].Id, lstAccount[5].Id, '2', '4',
                                            mapRecTypeIdRequest.get(AP_Constant.reqRTLead), '1', 'Sent',lstSection[2].Id),

                TestFactory.createLeadRequest(lstProgram[0].Id, lstTreaty[0].Id, lstAccount[4].Id, lstAccount[5].Id, '1', '4',
                        mapRecTypeIdRequest.get(AP_Constant.reqRTLead), '1', 'Setup',lstSection[0].Id),

                TestFactory.createLeadRequest(lstProgram[0].Id, lstTreaty[0].Id, lstAccount[7].Id, lstAccount[8].Id, '2', '4',
                        mapRecTypeIdRequest.get(AP_Constant.reqRTLead), '1', 'Setup',lstSection[0].Id)
            };

            for(Request__c req : lstLeadRequests){
                req.LastVersionSent__c = true;
                req.LastVersionAnswered__c = true;
            }

            update lstLeadRequests;

            //create Pool
            lstPool = new List<Pool__c>{
                TestFactory.createPool('Pool A', 78, '2018', lstUsers[2].Id),
                TestFactory.createPool('Pool B', 78, '2018', lstUsers[2].Id)
            };
            insert lstPool;

            //create Pool Treaty Section
            lstPoolTreatySections = new List<PoolTreatySection__c> {
                TestFactory.createPoolTreatySection(lstPool[0].Id, lstTreaty[0].Id, null
                        , false,true, 32, null),

                TestFactory.createPoolTreatySection(lstPool[1].Id, lstTreaty[0].Id, null
                        , false,true, 40, null)
            };
            insert lstPoolTreatySections;  
        }
    }

    @IsTest
    public static void testGetAllSections(){
        System.runAs(testUserAdmin) {
            Test.startTest();
                List<Request__c> lstPlacementRequest = new List<Request__c>{lstRequest[4], lstRequest[5]};
                Map<String, Object> mapResults = LWC24_NewPlacementRequest.getAllSections(lstTreaty[2].Id, lstPlacementRequest);
            Test.stopTest();

            List<Section__c> lstSections = (List<Section__c>) mapResults.get('lstSections');
            System.assertEquals(2, lstSections.size()); 
        }
    }

    @IsTest
    public static void testSavePlacementRequestRecord(){
        System.runAs(testUserCE) {
            Test.startTest();
                Request__c placementReq1 = lstRequest[4];
                placementReq1.Id = null;

                Request__c placementReq2 = lstRequest[5];
                placementReq2.Id = null;

                List<Request__c> lstPlacementRequest = new List<Request__c>{placementReq1, placementReq2};
                Map<String, Object> mapResults = LWC24_NewPlacementRequest.savePlacementRequestRecord(lstPlacementRequest);
            Test.stopTest();
            System.assertEquals('Success', mapResults.get('Success')); 
        }
    }

    @IsTest
    public static void testLoadPreviousYear(){
        System.runAs(testUserCE) {
            Test.startTest();
                List<Request__c> lstResults = LWC24_NewPlacementRequest.loadPreviousYear(lstProgram[2].Id);
            Test.stopTest();
            // System.assertEquals(0, lstResults.size()); 
        }
    }

    @IsTest
    public static void testGetUWYearForOriginalProgram(){
        System.runAs(testUserCE) {
            Test.startTest();
                Map<String, Object> mapResults = LWC24_NewPlacementRequest.getUWYearForOriginalProgram(lstProgram[1].Id);
            Test.stopTest();
            System.assertEquals('2018', mapResults.get('uwYearOriginalProgram')); 
            System.assertEquals(true, mapResults.get('isProgRenewedStandRene')); 
        }
    }

    @IsTest
    public static void testGetTreaties(){
        System.runAs(testUserCE) {
            Test.startTest();
                List<LWC24_NewPlacementRequest.OptionWrapper> lstResults = LWC24_NewPlacementRequest.getTreaties(lstProgram[1].Id);
            Test.stopTest();
            System.assertEquals(0, lstResults.size()); 

            List<Request__c> lstParentLeadRequest = [ SELECT Id, Treaty__c
                                                      FROM Request__c
                                                      WHERE  RecordTypeId =: mapRecTypeIdRequest.get(AP_Constant.reqRTLead)];
        }
    }

    @IsTest
    public static void testGetTreaties2(){
        System.runAs(testUserCE) {
            Test.startTest();
                List<LWC24_NewPlacementRequest.OptionWrapper> lstResults = LWC24_NewPlacementRequest.getTreaties(lstProgram[0].Id);
            Test.stopTest();
            System.assertEquals(0, lstResults.size());
        }
    }

    @IsTest
    public static void testLoadReinsurerFromQuote(){
        System.runAs(testUserAdmin) {
            Test.startTest();
                List<Id> lstTreatyIds = new List<Id>{lstTreaty[0].Id, lstTreaty[1].Id, lstTreaty[2].Id, lstTreaty[3].Id};
                List<Request__c> lstRequest = LWC24_NewPlacementRequest.loadReinsurerFromQuote(lstTreatyIds);
            Test.stopTest();                                 
            System.assertEquals(1, lstRequest.size()); 
        }
    }

    @IsTest
    public static void testCheckReinsurerBrokerQuote(){
        System.runAs(testUserAdmin) {
            Test.startTest();
                List<String> lstIds = new List<String>{lstTreaty[2].Id+'-'+lstAccount[7].Id+'-'+lstAccount[8].Id,
                                                    lstTreaty[2].Id+'-'+lstAccount[4].Id+'-'+lstAccount[5].Id};
                Boolean result = LWC24_NewPlacementRequest.checkReinsurerBroker(lstIds, lstProgram[1].Id, 'Quote');
            Test.stopTest();
           System.assertEquals(false, result);
        }
    }
    
    @IsTest
    public static void testCheckReinsurerBrokerPlacement(){
        System.runAs(testUserAdmin) {
            Test.startTest();
                List<String> lstIds = new List<String>{lstTreaty[2].Id+'-'+lstAccount[7].Id+'-'+lstAccount[8].Id,
                                                    lstTreaty[2].Id+'-'+lstAccount[4].Id+'-'+lstAccount[5].Id};
                Boolean result = LWC24_NewPlacementRequest.checkReinsurerBroker(lstIds, lstProgram[1].Id, 'Placement');
            Test.stopTest();
           System.assertEquals(true, result);
        }
    }

    @IsTest
    public static void testFilterBrokerReinsAll(){
        System.runAs(testUserCE) {
            Test.startTest();
                String str = lstTreaty[2].Id + '-' + lstAccount[7].Id + '-' + lstAccount[8].Id;
                List<String> lstStr = LWC24_NewPlacementRequest.filterBrokerReinsAll(new List<String>{str}, lstProgram[1].Id);
            Test.stopTest();
            System.assertEquals(1, lstStr.size()); 
        }
    }
}