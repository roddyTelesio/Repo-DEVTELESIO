@isTest
public with sharing class CreateClasseurs_TEST{
    /**************************************************************************************
-- - Author        : Telesio DEV (SBH)
-- - Description   : Test class for CreateClasseurs - Project Quote Table
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 6-JUNE-2022  SBH   1.0      Initial version
--------------------------------------------------------------------------------------
**************************************************************************************/
    static User testUserAdmin;
    static User testUserCE;
    static List<Account> lstAccount;
    static List<Program__c> lstProgram;
    static List<Treaty__c> lstTreaty;
    static List<Section__c> lstSection;
    static List<Request__c> lstRequests;
    static List<User> lstUsers = new List<User>();
    static Map<String, Id> mapRecTypeIdRequest = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectRequest});
    static List<Classeur__c> lstClasseurs; 
    static List<QuoteTableSettings__c> lstQuoteSettings;


    static List<ContentVersion> lstContentVersion;
    static List<ContentDocumentLink> lstContentDocumentLink;
    static String fileContent = 'Test data';
    static Blob fileContentInBlob = Blob.valueOf(fileContent);

    static{
        testUserAdmin = TestFactory.createUser('testUserAdmin', TestFactory.getProfileAdminId());
        testUserCE = TestFactory.createUser('testUserCE', TestFactory.getProfileCEId());
        testUserCE.BypassTrigger__c = 'AP38_CreateSharingForRequest;AP53_UpdateSAStatus;AP43_DeleteClonedRequests;AP42_DeleteDocumentVisibility';
        lstUsers.add(testUserAdmin);
        lstUsers.add(testUserCE);
        insert lstUsers;

        System.runAs(testUserCE){

            lstQuoteSettings = new List<QuoteTableSettings__c>{
                new QuoteTableSettings__c(
                    ApiUserId__c = lstUsers[0].Id,
                    OrgID__c = 'TABCOTA'
                )
            };
            insert lstQuoteSettings; 
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
            lstProgram[0].LossDepositLevel__c = 'Program';
            lstProgram[0].LossDepositMode__c = '1;2;3;4';
            lstProgram[1].LossDepositLevel__c = 'Treaty';
            insert lstProgram;

            //create Treaty
            lstTreaty = new List<Treaty__c> {
                    TestFactory.createTreaty('TestTreaty1', 1, '2020-00000221/', '3'
                            , lstProgram[0].Id, '2', 34, '10', '2020-00000222/', '1', '2', '2', '2', '2'),

                    TestFactory.createTreaty('TestTreaty2', 2, '2020-00000222/', '2', lstProgram[0].Id
                            , '1', 44, '44', '2020-00000222/', '2', '2', '2', '2', '2'),

                    TestFactory.createTreaty('TestTreaty3', 3, '2020-00000222/', '2'
                            , lstProgram[1].Id, '2', 89, '44', '2020-00000222/', '3', '2', '2', '2', '2')
            };
            lstTreaty[2].LossDepositMode__c = '1;2;3';
            insert lstTreaty;

            //create Section
            lstSection = new List<Section__c> {
                    TestFactory.createSection('TestSection1', '1.0', '22003', '20006', '9052'
                            , 322, 34, lstProgram[0].Id, lstTreaty[0].Id, '3', '1'
                            , true, '5', null, '23001', '1', '5', '2', '2'),

                    TestFactory.createSection('TestSection2', '2.0', '22003', '20006', '9052'
                            , 23, 5, lstProgram[1].Id, lstTreaty[2].Id, '3', '1'
                            , false, '5', null, '23001', '1', '5', '2', '2')
            };
            insert lstSection;

            lstRequests = new List<Request__c>{
                    // recordTypeId + status required
                    TestFactory.createRequest(lstProgram[0].Id, lstTreaty[0].Id, lstAccount[4].Id, lstAccount[5].Id, '1', '3',
                            mapRecTypeIdRequest.get(AP_Constant.reqRTQuote), '2', 'Setup', lstSection[0].Id),

                    TestFactory.createRequest(lstProgram[1].Id, lstTreaty[2].Id, lstAccount[4].Id, lstAccount[5].Id, '2', '1',
                            mapRecTypeIdRequest.get(AP_Constant.reqRTQuote), '2', 'Setup', lstSection[1].Id)
            };

            lstRequests[0].LossDepositMode__c = '1';
            lstRequests[1].LossDepositMode__c = '2';
            lstRequests[0].lastVersionAnswered__c = true;
            lstRequests[1].lastVersionAnswered__c = true;
            insert lstRequests;

            lstClasseurs = new List<Classeur__c>{
                ClasseurFactory.createClasseur(
                    'Classeur1'
                    , lstAccount[0].Id
                    , lstProgram[0].Id
                ),
                ClasseurFactory.createClasseur(
                    'Classeur2'
                    , lstAccount[1].Id
                    , lstProgram[1].Id
                )
            };

            insert lstClasseurs; 

            lstContentVersion = new List<ContentVersion>{
                    TestFactory.createContentVersion('2','1'
                            , '1', 'Test1', fileContentInBlob, 'Test1'),
                    TestFactory.createContentVersion('2','1'
                            , '1', 'Test2', fileContentInBlob, 'Test2')
            };
            insert lstContentVersion;

            Set<Id> setContentVersionId = new Set<Id>();
            for(ContentVersion contentVersion : lstContentVersion){
                setContentVersionId.add(contentVersion.Id);
            }

            lstContentVersion = [SELECT Id, ContentDocumentId, DocumentType__c, GroupType__c, Phase__c, Title, VersionData, VersionNumber FROM ContentVersion WHERE Id IN :setContentVersionId];

            lstContentDocumentLink = new List<ContentDocumentLink>{
                    TestFactory.createContentDocumentLink(lstContentVersion[0].ContentDocumentId, lstClasseurs[0].Id, 'V'),
                    TestFactory.createContentDocumentLink(lstContentVersion[1].ContentDocumentId, lstClasseurs[1].Id, 'V')
            };
            insert lstContentDocumentLink;
            
        }
    }

    @IsTest
    public static void testFetchPrograms(){
        System.runAs(testUserCE) {
            Test.startTest();
                List<CreateClasseurs.programsData> testResult = CreateClasseurs.fetchPrograms(lstAccount[0].Id, '2018'); 
                System.assertEquals(testResult.size(), 1, 'Number of programs fetched incorrect');
            Test.stopTest();
        }
    }


    @IsTest
    public static void testFetchClasseur(){
        System.runAs(testUserCE) {
            Test.startTest();
                Map<String,Object> testResult = CreateClasseurs.fetchClasseur(lstClasseurs[0].Id);
                System.assertEquals(testResult.size(), 3, 'No result returned in fetch classeur');
                System.assertEquals(((List<createClasseurs.Tab>)testResult.get('tabs')).size(), 0, 'Wrong number of tabs returned for fetch classeur');
            Test.stopTest();
        }
    }

    @IsTest
    public static void testFetchTreatys(){
        System.runAs(testUserCE) {
            Test.startTest();
                List<CreateClasseurs.treatyData> testResult = CreateClasseurs.fetchTreatys(lstProgram[0].Id); 
                System.assertEquals(testResult.size(), 2, 'Number of treaties fetched incorrect');
            Test.stopTest();
        }
    }
    @IsTest
    public static void testFetchSections(){
        System.runAs(testUserCE) {
            Test.startTest();
                Map<String, Object> testResult = createClasseurs.fetchSections(lstProgram[0].Id, lstTreaty[0].Id, '2018', lstAccount[0].Id);
                System.assert(!testResult.isEmpty(), 'No Sections found');
                System.assert(testResult.containsKey('data'), 'No data found');
                System.assert(testResult.containsKey('sectionsPerTreaty'), 'No sections found');
                System.assert(testResult.containsKey('sectionsInfoPerTreaty'), 'No section infos found');
                System.assert(testResult.containsKey('mapSections'), 'No mapSections found');
            Test.stopTest();
        }
    }

    @isTest
    public static void testRefreshClasseur(){
        System.runAs(testUserCE) {
            Test.setMock(HttpCalloutMock.class, 
                        new QuoteTableMock(
                            200, 
                            '{"Checks":["Connect to DEV_TABCOTA for Classeur__c a0M7a000004fBlGEAU and ContentVersion 0687a000001qpIBAAY"],"Workbook":{"ContentDocumentId":"0697a000001OnX0AAK","ContentDocumentLinkId":"06A7a000009ipulEAA","ContentVersionId":"0687a000001T9kcAAC"}}')
            );
            Test.startTest();
                createClasseurs.refreshClasseur(lstClasseurs[0].Id, lstContentVersion[0].ContentDocumentId);

                try{
                    createClasseurs.refreshClasseur(lstClasseurs[0].Id, null);  
                }catch(Exception e){
                    System.assertEquals('No File Uploaded', e.getMessage());
                }

                try{
                    createClasseurs.refreshClasseur(null, 'file');  
                }catch(Exception e){
                    System.assertEquals('No Classeur Record Selected', e.getMessage());
                }

            Test.stopTest();
        }
    }

    @isTest 
    public static void testCreateClasseur(){
        String tabs = '{"a":{"treatySelected":"","sectionsUnselected":[],"sectionsSelected":["'+lstSection[0].Id+'"],"type":"XLSL_DYN"}}';
        String basic = '{"name":"TEST CLASSEUR","principalCedingCompany":"'+lstAccount[0].Id+'","uwYear":"2018","program":"'+lstProgram[0].Id+'"}';
        String tabDetails = '[{"name":"a","type":"XLSL_DYN","selected":false}]';

        System.runAs(testUserCE) {
            Test.startTest();
                createClasseurs.insertClasseurs(tabs, basic, tabDetails);
            Test.stopTest();
        }
    }

    @isTest 
    public static void testGetClasseurs(){
        

        System.runAs(testUserCE) {
            Test.startTest();
                List<Classeur__c> result = createClasseurs.getClasseurs('Classeur1', 'Name', 'ASC', 'Id,Name', '2018', lstAccount[0].Id , '\''+ lstAccount[0].Id + '\'');
            Test.stopTest();
        }
    }

    @isTest 
    public static void testGetFileList(){
        

        System.runAs(testUserCE) {
            List<string> classeurIds = new List<String>(); 

            for(Classeur__c c : lstClasseurs){
                classeurIds.add(c.Id);
            }
            Test.startTest();
                String result = createClasseurs.getFileList(classeurIds);
            Test.stopTest();
        }
    }


    

}