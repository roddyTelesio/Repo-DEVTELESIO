@IsTest
public with sharing class LWC61_FilePreviewDownload_TEST {
    static User testUserAdmin;
    static User testUserCE;
    static User testUserValidator;
    static User assignedToUser;
    static List<User> lstUsers = new List<User>();
    static List<ContentVersion> lstContentVersion = new List<ContentVersion>();
    static ContentWorkspace contentWrkSpace = new ContentWorkspace();
    static List<ContentDocumentLink> lstContentDocumentLink = new List<ContentDocumentLink>();
    static String fileContent = 'This is an example.';
    static Blob fileContentInBlob = Blob.valueOf(fileContent);
    static List<Program__c> lstProgram;
    public static List<Account> lstAccount;
    
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

            lstAccount[0].EmailPCLife__c = 'test1@gmail.com;test2@gmail.com';
            lstAccount[1].EmailPCLife__c = 'test1@gmail.com;test2@gmail.com';
            insert lstAccount;
            
            //create Program
            lstProgram = new List<Program__c> {
                TestFactory.createProgram('TestProg1', '1', '1'
                                        , Date.today(), Date.today().addYears(1), '2', Date.today(), Date.today().addYears(1)
                                        , '2018', lstAccount[0].Id, '23002','3'
                                        , '25009'),
    
                TestFactory.createProgram('TestProg2', '2', '2', Date.today()
                                        , Date.today().addYears(1), '1', Date.today(), Date.today().addYears(1), '2018'
                                        , lstAccount[1].Id, '23002', '3', '25009'),
    
                TestFactory.createProgram('TestProg3', '1', '3', Date.today()
                                        , Date.today().addYears(1), '2', Date.today(), Date.today().addYears(1), '2020'
                                        , lstAccount[1].Id, '23002', '3', '25009')
            };

            lstProgram[0].TECH_StageName__c = 'Quote';
            insert lstProgram;
            
            //create ContentVersion
            lstContentVersion = new List<ContentVersion>{
                TestFactory.createContentVersion('2','1'
                                                , '1', 'CV1', fileContentInBlob, 'CV1'),
                TestFactory.createContentVersion('2','1'
                                                , '1', 'CV2', fileContentInBlob, 'CV2'),
                TestFactory.createContentVersion('2','1'
                                                , '1', 'CV3', fileContentInBlob, 'CV3')
            };
            insert lstContentVersion;
            
            List<Id> lstContentVersionId = new List<Id>();

            for(ContentVersion contentVersion : lstContentVersion){
                lstContentVersionId.add(contentVersion.Id);
            }

            lstContentVersion = [SELECT Id, ContentDocumentId, DocumentType__c, GroupType__c, Phase__c, Title, VersionData, VersionNumber FROM ContentVersion WHERE Id IN :lstContentVersionId];


            //create contentWrkSpace
            contentWrkSpace = new ContentWorkspace(Name='Portal General Conditions test');
            insert contentWrkSpace;
            
            lstContentDocumentLink = new List<ContentDocumentLink>{
                    createContentDocumentLinkT(lstContentVersion[0].ContentDocumentId, contentWrkSpace.Id),
                    createContentDocumentLinkT(lstContentVersion[1].ContentDocumentId, contentWrkSpace.Id),
                    createContentDocumentLinkT(lstContentVersion[2].ContentDocumentId, contentWrkSpace.Id)
            };
            insert lstContentDocumentLink;
        }
    }
    
       //create a ContentDocumentLink
    public static ContentDocumentLink createContentDocumentLinkT(Id contentDocId, Id linkedEntityId){
        return new ContentDocumentLink(
                ContentDocumentId = contentDocId,
                LinkedEntityId = linkedEntityId
        );
    }
    @IsTest
    public static void testGetRelatedFiles(){
        System.runAs(testUserAdmin) {
            Test.startTest();
            Map<String, Object> res = LWC61_FilePreviewDownload.getRelatedFiles();
            Test.stopTest();
        }
    }
}