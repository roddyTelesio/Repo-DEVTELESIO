@IsTest
public with sharing class LWC20_LeadRequests_TEST {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Test class for LWC20_LeadRequests
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 22-SEPT-2020  SAU   1.0      Initial version
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
    static List<ContentVersion> lstContentVersion;
    static List<ContentDocumentLink> lstContentDocumentLink;
    static String fileContent = 'This is an example.';
    static Blob fileContentInBlob = Blob.valueOf(fileContent);
    static List<Contact> lstContact;
    static List<AccountContactRelation> lstAccContactRelation;
    static List<Pool__c> lstPool;
    static List<PoolTreatySection__c> lstPoolTreatySections;
    static List<DocumentVisibility__c> lstDocumentVisibility;
 
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
                                            , 322, 34, lstProgram[0].Id, lstTreaty[0].Id, '2', '1'
                                            , true, '1', null, '23001', '1', '5', '2', '2'),
                    TestFactory.createSection('TestSection2', '2.1', '22003', '20006', '9052'
                                            , 23, 5, lstProgram[1].Id, lstTreaty[2].Id, '2', '1' //MRA 935 4/08/2022 test class correction : START
                                            , false, '2', null, '23001', '1', '5', '2', '2'),
                    TestFactory.createSection('TestSection3', '2.1', '22003', '20006', '9052'
                                            , 23, 5, lstProgram[1].Id, lstTreaty[2].Id, '2', '1'
                                            , false, '3', null, '23001', '1', '5', '2', '2'),
                    TestFactory.createSection('TestSection4', '2.1', '22003', '20006', '9052'
                                            , 23, 5, lstProgram[1].Id, lstTreaty[2].Id, '2', '1'
                                            , false, '4', null, '23001', '1', '5', '2', '2'),
                    TestFactory.createSection('TestSection5', '2.1', '22003', '20006', '9052'
                                            , 23, 5, lstProgram[1].Id, lstTreaty[2].Id, '3', '1'
                                            , false, '5', null, '23001', '1', '5', '2', '2'),
                    TestFactory.createSection('TestSection6', '2.1', '22003', '20006', '9052'
                                            , 23, 5, lstProgram[1].Id, lstTreaty[2].Id, '4', '1'
                                            , false, '6', null, '23001', '1', '5', '2', '2'),    
                    TestFactory.createSection('TestSection6', '2.1', '22003', '20006', '9052'
                                            , 23, 5, lstProgram[1].Id, lstTreaty[2].Id, '4', '1'
                                            , false, '6', null, '23001', '1', '5', '2', '2'),
                    TestFactory.createSection('TestSection6', '2.1', '22003', '20006', '9052'
                                            , 23, 5, lstProgram[1].Id, lstTreaty[2].Id, '1', '1'
                                            , false, '8', null, '23001', '1', '5', '2', '2'),
                    TestFactory.createSection('TestSection6', '2.1', '22003', '20006', '9052'
                                            , 23, 5, lstProgram[1].Id, lstTreaty[2].Id, '3', '1'
                                            , false, '9', null, '23001', '1', '5', '2', '2'),
                    TestFactory.createSection('TestSection6', '2.1', '22003', '20006', '9052'
                                            , 23, 5, lstProgram[1].Id, lstTreaty[2].Id, '1', '1'
                                            , false, '10', null, '23001', '1', '5', '2', '2'),
                    TestFactory.createSection('TestSection6', '2.1', '22003', '20006', '9052'
                                            , 23, 5, lstProgram[1].Id, lstTreaty[2].Id, '4', '1'
                                            , false, '9', null, '23001', '1', '5', '2', '2')             //MRA 935 4/08/2022 test class correction : END                                                     
            };
            insert lstSection;


            //create Request
            lstRequest = new List<Request__c>{
                    // recordTypeId + status required
                    TestFactory.createRequest(lstProgram[0].Id, lstTreaty[0].Id, lstAccount[3].Id, lstAccount[5].Id, '1', '3',
                                                    mapRecTypeIdRequest.get(AP_Constant.reqRTQuote), '2', 'Setup',lstSection[0].Id),
        
                    TestFactory.createRequest(lstProgram[0].Id, lstTreaty[0].Id, lstAccount[3].Id, lstAccount[5].Id, '2', '1',
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
            insert lstRequest;

            //create lead 
            lstLeadRequests = new List<Request__c>{
                    // recordTypeId + status required
                    TestFactory.createLeadRequest(lstProgram[0].Id, lstTreaty[0].Id, lstAccount[3].Id, lstAccount[5].Id, '1', '4',
                                                    mapRecTypeIdRequest.get(AP_Constant.reqRTLead), '2', 'Setup',lstSection[1].Id),//MRA 935 4/08/2022 test class correction : START
        
                    TestFactory.createLeadRequest(lstProgram[0].Id, lstTreaty[0].Id, lstAccount[3].Id, lstAccount[5].Id, '2', '4',
                                                    mapRecTypeIdRequest.get(AP_Constant.reqRTLead), '2', 'Setup',lstSection[2].Id),
                    TestFactory.createLeadRequest(lstProgram[0].Id, lstTreaty[0].Id, lstAccount[3].Id, lstAccount[5].Id, '1', '4',
                                                    mapRecTypeIdRequest.get(AP_Constant.reqRTLead), '2', 'Setup',lstSection[3].Id),
                    TestFactory.createLeadRequest(lstProgram[0].Id, lstTreaty[0].Id, lstAccount[3].Id, lstAccount[5].Id, '2', '4',
                                                    mapRecTypeIdRequest.get(AP_Constant.reqRTLead), '2', 'Setup',lstSection[4].Id),
                    TestFactory.createLeadRequest(lstProgram[0].Id, lstTreaty[0].Id, lstAccount[3].Id, lstAccount[5].Id, '1', '4',
                                                    mapRecTypeIdRequest.get(AP_Constant.reqRTLead), '2', 'Setup',lstSection[5].Id),
                    TestFactory.createLeadRequest(lstProgram[0].Id, lstTreaty[0].Id, lstAccount[3].Id, lstAccount[5].Id, '2', '4',
                                                    mapRecTypeIdRequest.get(AP_Constant.reqRTLead), '2', 'Setup',lstSection[6].Id),
                    TestFactory.createLeadRequest(lstProgram[0].Id, lstTreaty[0].Id, lstAccount[3].Id, lstAccount[5].Id, '2', '4',
                                                    mapRecTypeIdRequest.get(AP_Constant.reqRTLead), '2', 'Setup',lstSection[7].Id),
                    TestFactory.createLeadRequest(lstProgram[0].Id, lstTreaty[0].Id, lstAccount[3].Id, lstAccount[5].Id, '2', '4',
                                                    mapRecTypeIdRequest.get(AP_Constant.reqRTLead), '2', 'Setup',lstSection[8].Id),
                    TestFactory.createLeadRequest(lstProgram[0].Id, lstTreaty[0].Id, lstAccount[3].Id, lstAccount[5].Id, '2', '4',
                                                    mapRecTypeIdRequest.get(AP_Constant.reqRTLead), '2', 'Setup',lstSection[10].Id),
                    TestFactory.createLeadRequest(lstProgram[0].Id, lstTreaty[0].Id, lstAccount[3].Id, lstAccount[5].Id, '2', '4',
                                                    mapRecTypeIdRequest.get(AP_Constant.reqRTLead), '2', 'Setup',lstSection[0].Id),
                    TestFactory.createLeadRequest(lstProgram[0].Id, lstTreaty[0].Id, lstAccount[3].Id, lstAccount[5].Id, '2', '4',
                                                    mapRecTypeIdRequest.get(AP_Constant.reqRTLead), '2', 'Setup',lstSection[9].Id) //MRA 935 4/08/2022 test class correction : END
            };
        }
    }

    @IsTest
    public static void testGetSectionDetail(){
        System.runAs(testUserAdmin) {
            Test.startTest();
                Map<String, Object>  mapResults = LWC20_LeadRequests.getSectionDetail(lstProgram[0].Id, lstTreaty[0].Id, lstAccount[5].Id, lstAccount[3].Id, 'Setup');
            Test.stopTest();
            System.assertEquals(true, mapResults.containsKey('lstLeadRequest')); 
        }
    }

    @IsTest
    public static void testToggleRequestType(){
        System.runAs(testUserAdmin) {
            Test.startTest();
                lstLeadRequests[0].LeadType__c = '1';
                lstLeadRequests[1].LeadType__c = '2';
                update lstLeadRequests;

                Map<String, Object>  mapResults = LWC20_LeadRequests.toggleRequestType(lstLeadRequests);
            Test.stopTest();
            System.assertEquals(true, mapResults.containsKey('Success')); 
            System.assertEquals(false, mapResults.containsKey('Error')); 
        }
    }
    
    @IsTest
    public static void testDisableLeadInfo(){
        System.runAs(testUserAdmin) {
            Test.startTest();
                lstProgram[0].TECH_ShowClosePreviousPhaseBtn__c = '2';
                lstProgram[1].TECH_ShowClosePreviousPhaseBtn__c = '1';
                update lstProgram;

                Boolean resultTrue = LWC20_LeadRequests.disableLeadInfo(lstProgram[0].Id);
                Boolean resultFalse = LWC20_LeadRequests.disableLeadInfo(lstProgram[1].Id);
            Test.stopTest();
            System.assertEquals(true, resultTrue);
            System.assertEquals(false, resultFalse); 

            for(Program__c program : [SELECT Id, Name, TECH_ShowClosePreviousPhaseBtn__c FROM Program__c WHERE Id = :lstProgram[0].Id]){
                System.assertEquals('2', program.TECH_ShowClosePreviousPhaseBtn__c);
            }

            for(Program__c program : [SELECT Id, Name, TECH_ShowClosePreviousPhaseBtn__c FROM Program__c WHERE Id = :lstProgram[1].Id]){
                System.assertEquals('1', program.TECH_ShowClosePreviousPhaseBtn__c);
            }
        }
    }

    @IsTest
    public static void testGetSelectedProgramDetail(){
        System.runAs(testUserAdmin) {
            Test.startTest();
                Program__c program = LWC20_LeadRequests.getSelectedProgramDetail(lstProgram[0].Id);
            Test.stopTest();
            System.assertEquals(lstProgram[0].Name, program.Name);
        }
    }
}