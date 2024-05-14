@IsTest
public with sharing class AP57_DocumentFromThemis_TEST {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Test class for AP57_DocumentFromThemis
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 31-MAY-2021  MBE   1.0      Initial version
--------------------------------------------------------------------------------------
**************************************************************************************/

    static User testUserAdmin;
    static User testUserCE;
    static List<User> lstUsers = new List<User>();
    static List<Account> lstAccount;
    static List<Program__c> lstProgram;
    static List<CoveredCedingCompany__c> lstCovCedCom;
    static List<Treaty__c> lstTreaty;
    static List<Section__c> lstSection;
    static List<ContentVersion> lstContentVersion;
    static Map<String, Id> mapAccountRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectAcc});
    static String fileContent = 'This is an example.';
    static Blob fileContentInBlob = Blob.valueOf(fileContent);

    static { 
        //create User
        testUserAdmin = TestFactory.createUserWithRole('testUserAdmin', TestFactory.getProfileAdminId(), TestFactory.getCERoleId());
        testUserCE = TestFactory.createUser('testUserCE', TestFactory.getProfileCEId());
        User assignedToUser = TestFactory.createUserWithRole('TestAssignedTo', TestFactory.getProfileAdminId(),TestFactory.getHeadUGPRoleId());

        lstUsers.add(testUserAdmin);
        lstUsers.add(testUserCE);
        lstUsers.add(assignedToUser);
        insert lstUsers;

        System.runAs(testUserAdmin){
            Map<String, Id> mapRequestRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectRequest});

            //create Account
            lstAccount = new List<Account> {
                TestFactory.createAccount(mapAccountRecTypeId.get(AP_Constant.accRTPrincipalCedingCom),'Account A','C_0001'),
                TestFactory.createAccount(mapAccountRecTypeId.get(AP_Constant.accRTCoveredCedingCompany),'Account B','C_0002')
            };

            lstAccount[0].EmailSA__c = 'test@test.com';
            insert lstAccount;

            //create Program
            lstProgram = new List<Program__c> {
                TestFactory.createProgram('TestProg1', '1', '1'
                                    , Date.today(), Date.today().addYears(1), '2', Date.today(), Date.today().addYears(1)
                                    , '2020', lstAccount[0].Id, '23002','2', '25009'),

                TestFactory.createProgram('TestProg2', '2', '2', Date.today()
                                    , Date.today().addYears(1), '1', Date.today(), Date.today().addYears(1), '2020'
                                    , lstAccount[0].Id, '23001', '2', '25001')
            };

            insert lstProgram;

            lstCovCedCom = new List<CoveredCedingCompany__c> {
                TestFactory.createCovCedCom(lstAccount[1].Id, lstProgram[0].Id, true,null
                                            ,false,null,false,null,null),

                TestFactory.createCovCedCom(lstAccount[1].Id, lstProgram[1].Id, true,null
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
                                        , lstProgram[1].Id, '2', 89, '44', '2020-00000222', '3', '2', '2', '2', '2')
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
                                        , 76, 43, lstProgram[1].Id, lstTreaty[1].Id, '1', '1'
                                        , true, '1',null, '23001', '1', '5', '2', '2')
            };

            insert lstSection;

            //create ContentVersion
            lstContentVersion = new List<ContentVersion>{
                TestFactory.createContentVersion(null,null
                                                 , null, 'CV1', fileContentInBlob, 'CV1'),
                TestFactory.createContentVersion(null,null
                                                 , null, 'CV2', fileContentInBlob, 'CV2')
            };

            lstContentVersion[0].IsExternal__c = false;
            lstContentVersion[0].ProgramID__c = lstProgram[0].Id;
            lstContentVersion[0].FromThemis__c = true;
            lstContentVersion[0].VersionThemis__c = 1;
            lstContentVersion[0].DocumentID__c = '1111';
            lstContentVersion[0].Phase__c = '1';
            lstContentVersion[0].Version__c = 1;

            lstContentVersion[1].IsExternal__c = true;
            lstContentVersion[1].ProgramID__c = lstProgram[1].Id;
            lstContentVersion[1].FromThemis__c = true;
            lstContentVersion[1].VersionThemis__c = 1;
            lstContentVersion[1].DocumentID__c = '1111';
            lstContentVersion[1].Version__c = 2;

            insert lstContentVersion;
        }            
    }

    @IsTest
    public static void testUpdateSaStatus(){
        System.runAs(testUserAdmin) {
            Test.startTest();
                List<ContentVersion> lstContentNewVersion = new List<ContentVersion>{
                    TestFactory.createContentVersion(null,null
                                                    , null, 'CV1', fileContentInBlob, 'CV1'),
                    TestFactory.createContentVersion(null,null
                                                    , null, 'CV2', fileContentInBlob, 'CV2'),
                    TestFactory.createContentVersion(null,null
                                                    , null, 'CV3', fileContentInBlob, 'CV3')
                };

                lstContentNewVersion[0].IsExternal__c = false;
                lstContentNewVersion[0].ProgramID__c = lstProgram[0].Id;
                lstContentNewVersion[0].FromThemis__c = true;
                lstContentNewVersion[0].VersionThemis__c = 1;
                lstContentNewVersion[0].DocumentID__c = '1111';
                lstContentNewVersion[0].Phase__c = '1';

                lstContentNewVersion[1].IsExternal__c = true;
                lstContentNewVersion[1].ProgramID__c = lstProgram[1].Id;
                lstContentNewVersion[1].FromThemis__c = true;
                lstContentNewVersion[1].VersionThemis__c = 1;
                lstContentNewVersion[1].DocumentID__c = '1111';
                lstContentNewVersion[1].Phase__c = '1';

                lstContentNewVersion[1].IsExternal__c = true;
                lstContentNewVersion[1].ProgramID__c = lstProgram[1].Id;
                lstContentNewVersion[1].FromThemis__c = true;
                lstContentNewVersion[1].VersionThemis__c = 1;
                lstContentNewVersion[1].DocumentID__c = '2222';
                lstContentNewVersion[1].Phase__c = '1';
                insert lstContentNewVersion; 
            Test.stopTest();

            lstContentVersion = [SELECT Id, ProgramID__c, FromThemis__c, Phase__c, Version__c, DocumentID__c, ContentDocumentId FROM ContentVersion WHERE Id IN :lstContentVersion];

            Set<Id> setContentDocId = new Set<Id>();
            List<ContentDocumentLink> lstContentDocLink = new List<ContentDocumentLink>();
            Decimal lastVersion = 0;

            for(ContentVersion cv : lstContentVersion){
                setContentDocId.add(cv.ContentDocumentId);

                if(cv.Version__c > lastVersion){
                    lastVersion = cv.Version__c;
                }
            }

            if(setContentDocId.size() > 0){
                lstContentDocLink = [SELECT Id, ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE ContentDocumentId IN :setContentDocId];
            }

            System.assertEquals(4, lstContentDocLink.size());
            System.assertEquals(1, lastVersion);
        }
    }
}