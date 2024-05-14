@IsTest
public with sharing class LWC21_NewLeadRequest_TEST {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Test class for LWC21_NewLeadRequest
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 23-SEPT-2020  SAU   1.0      Initial version
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
 
    static {
        //create User
        testUserAdmin = TestFactory.createUser('testUserAdmin', TestFactory.getProfileAdminId());
        testUserCE = TestFactory.createUser('testUserCE', TestFactory.getProfileCEId());
        lstUsers.add(testUserAdmin);
        lstUsers.add(testUserCE);
        insert lstUsers;

        System.runAs(testUserCE){
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
            insert lstProgram;

            lstProgram[1].RenewedFromProgram__c =  lstProgram[0].Id;
            lstProgram[1].TypeOfRenew__c = 'Standard Renew';
            update lstProgram;

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
                                        , 23, 5, lstProgram[0].Id, lstTreaty[1].Id, '3', '1'
                                        , false, '5', null, '23001', '1', '5', '2', '2'),

                TestFactory.createSection('TestSection2', '2.1', '22003', '20006', '9052'
                                        , 23, 5, lstProgram[1].Id, lstTreaty[2].Id, '3', '1'
                                        , false, '5', null, '23001', '1', '5', '2', '2')
            };

            lstSection[0].Retained_to_lead__c = true;
            lstSection[0].Status__c = AP_Constant.statusActive;
            lstSection[1].Retained_to_lead__c = true;
            lstSection[1].Status__c = AP_Constant.statusActive;
            insert lstSection;

            //create Request
            lstRequest = new List<Request__c>{
                // recordTypeId + status required
                TestFactory.createRequest(lstProgram[0].Id, lstTreaty[0].Id, lstAccount[3].Id, lstAccount[5].Id, '1', '3',
                                                mapRecTypeIdRequest.get(AP_Constant.reqRTQuote), '2', 'Setup',lstSection[0].Id),
    
                TestFactory.createRequest(lstProgram[0].Id, lstTreaty[0].Id, lstAccount[4].Id, lstAccount[8].Id, '2', '1',
                                            mapRecTypeIdRequest.get(AP_Constant.reqRTQuote), '2', 'Sent',lstSection[0].Id),

                TestFactory.createRequest(lstProgram[1].Id, lstTreaty[2].Id, lstAccount[3].Id, lstAccount[5].Id, '1', '3',
                                            mapRecTypeIdRequest.get(AP_Constant.reqRTQuote), '2', 'sent',lstSection[0].Id),

                TestFactory.createRequest(lstProgram[1].Id, lstTreaty[2].Id, lstAccount[3].Id, lstAccount[5].Id, '2', '1',
                                            mapRecTypeIdRequest.get(AP_Constant.reqRTQuote), '2', 'Sent',lstSection[0].Id),

                TestFactory.createRequest(lstProgram[1].Id, lstTreaty[2].Id, lstAccount[3].Id, lstAccount[5].Id, '1', '5',
                                            mapRecTypeIdRequest.get(AP_Constant.reqRTPlacement), '2', 'sent',lstSection[0].Id),

                TestFactory.createRequest(lstProgram[1].Id, lstTreaty[2].Id, lstAccount[3].Id, lstAccount[5].Id, '2', '5',
                                            mapRecTypeIdRequest.get(AP_Constant.reqRTPlacement), '2', 'Sent',lstSection[0].Id)
            };

            lstRequest[2].OriginalRequest__c = lstRequest[0].Id;
            lstRequest[3].OriginalRequest__c = lstRequest[1].Id;

            for(Request__c req : lstRequest){
                req.LastVersionSent__c = true;
                req.LastVersionAnswered__c = true;
            }

            insert lstRequest;
            
            //create lead 
            lstLeadRequests = new List<Request__c>{
                // recordTypeId + status required
                TestFactory.createLeadRequest(lstProgram[0].Id, lstTreaty[0].Id, lstAccount[3].Id, lstAccount[5].Id, '1', '4',
                                                mapRecTypeIdRequest.get(AP_Constant.reqRTLead), '2', 'Setup',lstSection[0].Id),
    
                TestFactory.createLeadRequest(lstProgram[0].Id, lstTreaty[0].Id, lstAccount[3].Id, lstAccount[5].Id, '2', '4',
                                                mapRecTypeIdRequest.get(AP_Constant.reqRTLead), '2', 'Setup',lstSection[0].Id)
            };
        }
    }

    @IsTest
    public static void testGetTreaties(){
        System.runAs(testUserCE) {
            Test.startTest();
                List<LWC21_NewLeadRequest.OptionWrapper> lstResults = LWC21_NewLeadRequest.getTreaties(lstProgram[0].Id);
            Test.stopTest();
            System.assertEquals(1, lstResults.size()); 
            System.assertEquals('TestTreaty2', lstResults[0].label); 
        }
    }

    @IsTest
    public static void testGetBroker(){
        System.runAs(testUserCE) {
            Test.startTest();
                List<LWC21_NewLeadRequest.SObjectResult> lstResults = LWC21_NewLeadRequest.getBroker('Account', 'Name', 'Broker', null);
            Test.stopTest();
            System.assertEquals(2, lstResults.size()); 
        }
    }

    @IsTest
    public static void testGetSectionRetainToLeadDetails(){
        System.runAs(testUserCE) {
            Test.startTest();
                String leader = lstAccount[3].Id + '-' + lstAccount[5].Id;
                String leader2 = '-' + lstAccount[5].Id;

                List<String> lstLeaders = new List<String>{leader, leader2};
                Map<String, Object> mapResult = LWC21_NewLeadRequest.getSectionRetainToLeadDetails(lstTreaty[0].Id, lstLeaders);
                List<Section__c> lstSectionResult = (List<Section__c>)mapResult.get('lstSections');
            Test.stopTest();
            System.assertEquals(1, lstSectionResult.size());
            System.assertEquals('TestSection1', lstSectionResult[0].name); 
        }
    }

    @IsTest
    public static void testLoadReinsurerFromQuote(){
        System.runAs(testUserCE) {
            Test.startTest();
                List<Request__c> lstResult = LWC21_NewLeadRequest.loadReinsurerFromQuote(lstTreaty[0].Id);
            Test.stopTest();
            System.assertEquals(1, lstResult.size()); 
        }
    }

    @IsTest
    public static void saveLeadRequestRecord(){
        System.runAs(testUserCE) {
            Test.startTest();
                List<Request__c> lstLeadReqToCreate = new List<Request__c>{
                    // recordTypeId + status required
                    TestFactory.createRequest(lstProgram[0].Id, lstTreaty[0].Id, lstAccount[3].Id, lstAccount[5].Id, '1', '3',
                                                mapRecTypeIdRequest.get(AP_Constant.reqRTQuote), '2', 'Setup',lstSection[0].Id),
        
                    TestFactory.createRequest(lstProgram[0].Id, lstTreaty[0].Id, null, null, '2', '1',
                                                mapRecTypeIdRequest.get(AP_Constant.reqRTQuote), '2', 'Sent',lstSection[0].Id)
                };
                
                List<Request__c> lstParent = new List <Request__c> { lstLeadReqToCreate[0]};
                List<Request__c> lstChild = new List<Request__c> { lstLeadReqToCreate[1]};
                
                Map<String, Object> mapResult = LWC21_NewLeadRequest.saveLeadRequestRecord(lstParent, lstChild);
            Test.stopTest();
            System.assertEquals(true, mapResult.containsKey('Success')); 

            List<Request__c> lstLeadReq = [SELECT Id, name FROM Request__c WHERE RecordTypeId = :mapRecTypeIdRequest.get(AP_Constant.reqRTLead)];
            System.assertEquals(6, lstLeadReq.size()); 
        }
    }

    @IsTest
    public static void testGetBrokersAndReinsurers(){
        System.runAs(testUserCE) {
            Test.startTest();
                Map<String, Object> mapResult = LWC21_NewLeadRequest.getBrokersAndReinsurers(lstProgram[0].Id);
                List<Request__c> lstReqResult = (List<Request__c>)mapResult.get('AllRequests');
            Test.stopTest();
            System.assertEquals(4, lstReqResult.size()); 
        }
    }
}