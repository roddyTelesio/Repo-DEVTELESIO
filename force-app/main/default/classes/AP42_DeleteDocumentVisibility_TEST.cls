@IsTest
public with sharing class AP42_DeleteDocumentVisibility_TEST {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Test class for AP42_DeleteDocumentVisibility
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 15-FEB-2021  NBI   1.0      Initial version
--------------------------------------------------------------------------------------
**************************************************************************************/

    static User testUserAdmin;
    static User testUserCE;
    static List<Account> lstAccount;
    static List<Program__c> lstProgram;
    static List<Treaty__c> lstTreaty;
    static List<Section__c> lstSection;
    static List<Request__c> lstRequests;
    static List<Request__c> lstLeadRequests;
    static List<Request__c> lstLeadRequestsOtherTreaty;
    static List<DocumentVisibility__c> lstDocVisibility;
    static List<ContentVersion> lstContentVersion;
    static List<ContentDocumentLink> lstContentDocumentLink;
    static String fileContent = 'Test data';
    static Blob fileContentInBlob = Blob.valueOf(fileContent);
    static List<User> lstUsers = new List<User>();
    static Map<String, Id> mapRecTypeIdRequest = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectRequest});

    static{
        //create User
        testUserAdmin = TestFactory.createUser('testUserAdmin', TestFactory.getProfileAdminId());
        testUserCE = TestFactory.createUser('testUserCE', TestFactory.getProfileCEId());
        testUserCE.BypassTrigger__c = 'AP38_CreateSharingForRequest;AP53_UpdateSAStatus;AP43_DeleteClonedRequests';
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
                    TestFactory.createTreaty('TestTreaty1', 1, 'ref01', '3'
                            , lstProgram[0].Id, '2', 34, '10', '2020-00000222', '1', '2', '2', '2', '2'),

                    TestFactory.createTreaty('TestTreaty2', 2, 'ref02', '2', lstProgram[0].Id
                            , '1', 44, '44', '2020-00000222', '2', '2', '2', '2', '2'),

                    TestFactory.createTreaty('TestTreaty3', 3, 'ref03', '2'
                            , lstProgram[1].Id, '2', 89, '44', '2020-00000222', '3', '2', '2', '2', '2')
            };
            insert lstTreaty;

            //create Section
            lstSection = new List<Section__c> {
                    TestFactory.createSection('TestSection1', '1.0', '22003', '20006', '9052'
                            , 322, 34, lstProgram[0].Id, lstTreaty[0].Id, '3', '1'
                            , true, '5', null, '23001', '1', '5', '2', '2'),

                    TestFactory.createSection('TestSection2', '2.0', '22003', '20006', '9052'
                            , 23, 5, lstProgram[0].Id, lstTreaty[1].Id, '3', '1'
                            , false, '5', null, '23001', '1', '5', '2', '2')
            };
            insert lstSection;

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
                            mapRecTypeIdRequest.get(AP_Constant.reqRTSigning), '2', 'Setup', lstSection[1].Id)
            };
            insert lstRequests;

            //create lead
            lstLeadRequests = new List<Request__c>{
                    // recordTypeId + status required
                    TestFactory.createLeadRequest(lstProgram[0].Id, lstTreaty[0].Id, lstAccount[4].Id, lstAccount[5].Id, '1', '4',
                            mapRecTypeIdRequest.get(AP_Constant.reqRTLead), '2', 'Setup',lstSection[0].Id),

                    TestFactory.createLeadRequest(lstProgram[0].Id, lstTreaty[0].Id, lstAccount[4].Id, lstAccount[5].Id, '2', '4',
                            mapRecTypeIdRequest.get(AP_Constant.reqRTLead), '2', 'Setup',lstSection[0].Id)
            };

            //create lead
            lstLeadRequestsOtherTreaty = new List<Request__c>{
                    // recordTypeId + status required
                    TestFactory.createLeadRequest(lstProgram[0].Id, lstTreaty[1].Id, lstAccount[4].Id, lstAccount[5].Id, '1', '4',
                            mapRecTypeIdRequest.get(AP_Constant.reqRTLead), '2', 'Setup',lstSection[1].Id),

                    TestFactory.createLeadRequest(lstProgram[0].Id, lstTreaty[1].Id, lstAccount[4].Id, lstAccount[5].Id, '2', '4',
                            mapRecTypeIdRequest.get(AP_Constant.reqRTLead), '2', 'Setup',lstSection[1].Id)
            };

            lstContentVersion = new List<ContentVersion>{
                    TestFactory.createContentVersion('2','1'
                            , '5', 'Test1', fileContentInBlob, 'Test1'),
                    TestFactory.createContentVersion('2','1'
                            , '5', 'Test2', fileContentInBlob, 'Test2'),
                    TestFactory.createContentVersion('2','1'
                            , '5', 'Test3', fileContentInBlob, 'Test3')
            };
            insert lstContentVersion;

            Set<Id> setContentVersionId = new Set<Id>();
            for(ContentVersion contentVersion : lstContentVersion){
                setContentVersionId.add(contentVersion.Id);
            }

            lstContentVersion = [SELECT Id, ContentDocumentId, DocumentType__c, GroupType__c, Phase__c, Title, VersionData, VersionNumber FROM ContentVersion WHERE Id IN :setContentVersionId];

            lstContentDocumentLink = new List<ContentDocumentLink>{
                    TestFactory.createContentDocumentLink(lstContentVersion[0].ContentDocumentId, lstProgram[0].Id, 'V'),
                    TestFactory.createContentDocumentLink(lstContentVersion[1].ContentDocumentId, lstProgram[1].Id, 'V'),
                    TestFactory.createContentDocumentLink(lstContentVersion[2].ContentDocumentId, lstProgram[1].Id, 'V')
            };
            insert lstContentDocumentLink;

            lstDocVisibility = new List<DocumentVisibility__c>{
                    TestFactory.createDocumentVisibility(lstAccount[4].Id, lstAccount[5].Id, lstContentVersion[0].Id, lstProgram[0].Id),
                    TestFactory.createDocumentVisibility(null, lstAccount[5].Id, lstContentVersion[0].Id, lstProgram[0].Id),
                    TestFactory.createDocumentVisibility(lstAccount[4].Id, lstAccount[5].Id, lstContentVersion[1].Id, lstProgram[1].Id)
            };
            insert lstDocVisibility;

        }
    }

    @IsTest
    public static void testDeleteRequestsQuote(){
        System.runAs(testUserCE) {

            lstDocVisibility[0].Tech_IsExternal__c = true;
            lstDocVisibility[0].Tech_Phase__c = '1';
            lstDocVisibility[1].Tech_Phase__c = '1';
            lstDocVisibility[1].Tech_Phase__c = '1';
            lstDocVisibility[2].Tech_Phase__c = '1';
            lstDocVisibility[2].Tech_Phase__c = '1';
            update lstDocVisibility;
            Test.startTest();
                delete lstRequests;
            Test.stopTest();
        }
    }

    @IsTest
    public static void testDeleteRequestsLead(){
        System.runAs(testUserCE) {
        lstDocVisibility[0].Tech_IsExternal__c = true;
        lstDocVisibility[0].Tech_Phase__c = '3';
        lstDocVisibility[1].Tech_Phase__c = '3';
        lstDocVisibility[1].Tech_Phase__c = '3';
        lstDocVisibility[2].Tech_Phase__c = '3';
        lstDocVisibility[2].Tech_Phase__c = '3';
        update lstDocVisibility;
            Test.startTest();
                delete lstRequests;
            Test.stopTest();
        }
    }

    @IsTest
    public static void testDeleteLeadRequests(){
        System.runAs(testUserCE) {
            Test.startTest();
                delete lstLeadRequests;
            Test.stopTest();
        }
    }

    @IsTest
    public static void testDeleteLeadRequests22(){
        System.runAs(testUserCE) {
        lstDocVisibility[0].Tech_IsExternal__c = true;
        lstDocVisibility[0].Tech_Phase__c = '3';
        lstDocVisibility[1].Tech_Phase__c = '3';
        lstDocVisibility[1].Tech_Phase__c = '3';
        lstDocVisibility[2].Tech_Phase__c = '3';
        lstDocVisibility[2].Tech_Phase__c = '3';
        update lstDocVisibility;
            Test.startTest();
                delete lstLeadRequests;
            Test.stopTest();
        }
    }
}