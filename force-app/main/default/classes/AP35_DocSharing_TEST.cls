@IsTest
public with sharing class AP35_DocSharing_TEST {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Test class for AP35_DocSharing
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
    static List<DocumentVisibility__c> lstDocVisibility;
    static List<ContentVersion> lstContentVersion;
    static List<ContentDocumentLink> lstContentDocumentLink;
    static String fileContent = 'Test data';
    static Blob fileContentInBlob = Blob.valueOf(fileContent);
    static List<User> lstUsers = new List<User>();

    static {
        //create User
        testUserAdmin = TestFactory.createUser('testUserAdmin', TestFactory.getProfileAdminId());
        testUserCE = TestFactory.createUser('testUserCE', TestFactory.getProfileCEId());
        lstUsers.add(testUserAdmin);
        lstUsers.add(testUserCE);
        insert lstUsers;

        System.runAs(testUserCE) {
            Map<String, Id> mapRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{
                    AP_Constant.sObjectAcc
            });

            //create Account
            lstAccount = new List<Account>{
                    TestFactory.createAccount(mapRecTypeId.get(AP_Constant.accRTPrincipalCedingCom), 'Account A', 'C_0001'),
                    TestFactory.createAccount(mapRecTypeId.get(AP_Constant.accRTPrincipalCedingCom), 'Account B', 'C_0002'),
                    TestFactory.createAccount(mapRecTypeId.get(AP_Constant.accRTCoveredCedingCompany), 'Account C', 'C_0003'),
                    TestFactory.createAccount(mapRecTypeId.get(AP_Constant.accRTCoveredCedingCompany), 'Account D', 'C_0004'),
                    TestFactory.createAccount(mapRecTypeId.get(AP_Constant.accRTBroker), 'Account E', 'C_0005'),
                    TestFactory.createAccount(mapRecTypeId.get(AP_Constant.accRTReinsurer), 'Account F', 'C_0006')
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

            lstContentVersion = new List<ContentVersion>{
                    TestFactory.createContentVersion('2','1'
                            , '1', 'Test1', fileContentInBlob, 'Test1'),
                    TestFactory.createContentVersion('2','1'
                            , '1', 'Test2', fileContentInBlob, 'Test2'),
                    TestFactory.createContentVersion('2','1'
                            , '1', 'Test3', fileContentInBlob, 'Test3')
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
        }
    }

    @IsTest
    public static void testInsertDocVisibility(){
        System.runAs(testUserCE) {
            Test.startTest();
                insert lstDocVisibility;
            Test.stopTest();

            Set<Id> setContentDocLinkId = new Set<Id>();
            for(ContentDocumentLink contentDocLink : lstContentDocumentLink){
                setContentDocLinkId.add(contentDocLink.Id);
            }

            lstContentDocumentLink = [SELECT Id, Visibility FROM ContentDocumentLink WHERE Id IN :setContentDocLinkId];
            System.assertEquals('AllUsers', lstContentDocumentLink[0].Visibility);
            System.assertEquals('AllUsers', lstContentDocumentLink[1].Visibility);
        }
    }
}