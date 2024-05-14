/**
 * @description       : 
 * @author            : Patrick Randrianarisoa
 * @group             : 
 * @last modified on  : 20-03-2024
 * @last modified by  : Patrick Randrianarisoa
 * Modifications Log
 * Ver   Date         Author                   Modification
 * 1.0   19-03-2024   Patrick Randrianarisoa   Initial Version
**/
@IsTest
public with sharing class LWC14_Documents_TEST {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Test class for LWC14_Documents
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 18-DEC-2019  MBE   1.0      Initial version
-- 11-SEP-2020  SAU   1.1      Modified.
--------------------------------------------------------------------------------------
**************************************************************************************/
   static User testUserAdmin;
   static User testUserCE;
   static List<Account> lstAcc;
   static List<Program__c> lstProgram;
   static List<ContentVersion> lstContentVersion;
   static List<ContentDocumentLink> lstContentDocumentLink;
   static List<ContentVersion> lstContentVersionThemis;
   static List<ContentDocumentLink> lstContentDocumentLinkThemis;
   static List<ContentVersion> lstContentVersionExt;
   static List<ContentVersion> lstContentVersionExtSelect;
   static List<ContentDocumentLink> lstContentDocumentLinkExt;
   static Map<String, Id> mapRecTypeId;
   static String fileContent = 'This is an example.';
   static List<User> lstUsers = new List<User>();
   static Blob fileContentInBlob = Blob.valueOf(fileContent);
   static List<Apttus__DocumentVersionDetail__c> lstdocumentVersionDetail;
   static List<Apttus__DocumentVersion__c> lstdocumentVersion;
   static List<Apttus__APTS_Template__c> lstTmp;

    static {
        //create User
        testUserAdmin = TestFactory.createUser('testUserAdmin', TestFactory.getProfileAdminId());
        testUserCE = TestFactory.createUser('testUserCE', TestFactory.getProfileCEId());
        User assignedToUser = TestFactory.createUserWithRole('TestAssignedTo', TestFactory.getProfileAdminId(),TestFactory.getHeadUGPRoleId());
        lstUsers.add(testUserAdmin);
        lstUsers.add(assignedToUser);
        lstUsers.add(testUserCE);
        insert lstUsers;


        System.runAs(testUserCE) {
            mapRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{
                    AP_Constant.sObjectAcc
            });

            //creating Account
            lstAcc = new List<Account>{
                    TestFactory.createAccount(mapRecTypeId.get(AP_Constant.accRTPrincipalCedingCom), 'testAcc1', 'Y_8392'),
                    TestFactory.createAccount(mapRecTypeId.get(AP_Constant.accRTReinsurer), 'testAccReinsurer', 'Y_8393'),
                    TestFactory.createAccount(mapRecTypeId.get(AP_Constant.accRTBroker), 'testAccBroker', 'Y_8394')
            };
            insert lstAcc;

            //create Program
            lstProgram = new List<Program__c>{
                    TestFactory.createProgram('TestProgChange', '1', '3'
                    , Date.today(), Date.today().addYears(1), '2', Date.today(), Date.today().addYears(1)
                    , '2020', lstAcc[0].Id, '23001', '2', '25001'),

                    TestFactory.createProgram('TestProgChange2', '1', '2'
                                , Date.today(), Date.today().addYears(1), '1', Date.today(), Date.today().addYears(1)
                                , '2018', lstAcc[0].Id, '23001', '2', '25001'),
                    TestFactory.createProgram('TestProgChange2', '1', '2'
                    , Date.today(), Date.today().addYears(1), '1', Date.today(), Date.today().addYears(1)
                    , '2018', lstAcc[0].Id, '23001', '2', '25001')

            };
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

            lstContentVersionExt = new List<ContentVersion>{
                TestFactory.createContentVersion('2','1'
                                                , '1', 'CV1', fileContentInBlob, 'CV1')
            };
            lstContentVersionExt[0].IsExternal__c = true;
            lstContentVersionExt[0].Phase__c = '1';
            lstContentVersionExt[0].Tech_BrokerId__c = lstAcc[2].Id;
            lstContentVersionExt[0].Tech_BrokerName__c =  lstAcc[2].Name;
            lstContentVersionExt[0].Tech_ReinsurerId__c = lstAcc[1].Id;
            lstContentVersionExt[0].Tech_ReinsurerName__c = lstAcc[1].Name;
            insert lstContentVersionExt;

            System.debug('lstContentVersionExt[0] = ' + lstContentVersionExt[0]);

    
            //create ContentVersion Themis
            lstContentVersionThemis = new List<ContentVersion>{
                TestFactory.createContentVersion('2','1'
                                                , '1', 'CV4', fileContentInBlob, 'CV4')
            };
            lstContentVersionThemis[0].IsExternal__c = false;
            lstContentVersionThemis[0].FromThemis__c = true;
            insert lstContentVersionThemis;

            ContentVersion contentVersionReplace = new ContentVersion(GroupType__c = '1', DocumentType__c = '3',Phase__c = '3', VersionData = lstContentVersion[0].VersionData
                    , ContentDocumentId = lstContentVersion[0].ContentDocumentId, PathOnClient ='VCV4', Title = 'CV4');
            insert contentVersionReplace;

            lstContentVersion.add(contentVersionReplace);

            List<Id> lstContentVersionId = new List<Id>();
            List<Id> lstContentVersionIdThemis = new List<Id>();
            List<Id> lstContentVersionIdExt = new List<Id>();

            for(ContentVersion contentVersion : lstContentVersion){
                lstContentVersionId.add(contentVersion.Id);
            }

            for(ContentVersion contentVersionThemis : lstContentVersionThemis){
                lstContentVersionIdThemis.add(contentVersionThemis.Id);
            }

            for(ContentVersion contentVersionExt : lstContentVersionExt){
                lstContentVersionIdExt.add(contentVersionExt.Id);
            }

            lstContentVersion = [SELECT Id, ContentDocumentId, DocumentType__c, GroupType__c, Phase__c, Title, VersionData, VersionNumber FROM ContentVersion WHERE Id IN :lstContentVersionId];

            lstContentDocumentLink = new List<ContentDocumentLink>{
                    TestFactory.createContentDocumentLink(lstContentVersion[0].ContentDocumentId, lstProgram[0].Id, 'V'),
                    TestFactory.createContentDocumentLink(lstContentVersion[2].ContentDocumentId, lstProgram[1].Id, 'V')
            };
            insert lstContentDocumentLink;

            lstContentVersionThemis = [SELECT Id, ContentDocumentId, DocumentType__c, GroupType__c, Phase__c, Title, VersionData, VersionNumber, FromThemis__c FROM ContentVersion WHERE Id IN :lstContentVersionIdThemis];

            lstContentDocumentLinkThemis = new List<ContentDocumentLink>{
                    TestFactory.createContentDocumentLink(lstContentVersionThemis[0].ContentDocumentId, lstProgram[1].Id, 'V')
            };
            insert lstContentDocumentLinkThemis;

            lstContentVersionExtSelect = [SELECT Id, ContentDocumentId, DocumentType__c, GroupType__c, Phase__c, Title, VersionData, VersionNumber, Tech_BrokerId__c, Tech_BrokerName__c, Tech_ReinsurerId__c, Tech_ReinsurerName__c, CreatedDate, Tech_NumberPhase__c FROM ContentVersion WHERE Id =:lstContentVersionExt[0].Id];

            System.debug('lstContentVersionExtSelect[0] = ' + lstContentVersionExtSelect[0].ContentDocumentId);

            lstContentDocumentLinkExt = new List<ContentDocumentLink>{
                    TestFactory.createContentDocumentLink(lstContentVersionExtSelect[0].ContentDocumentId, lstProgram[1].Id, 'V')
            };
            insert lstContentDocumentLinkExt;
            
            Apttus__APTS_Agreement__c agree = TestFactory.createAgreement('Agreement');
            agree.Program__c = lstProgram[1].Id;
            insert agree;

            lstTmp = new List<Apttus__APTS_Template__c>{
                    TestFactory.createTemplate('test')
            };
            insert lstTmp;
            
            lstdocumentVersion = new List<Apttus__DocumentVersion__c>{
                    TestFactory.createDocumentVersion('Document Version','last version','title test')
            };
            lstdocumentVersion[0].Apttus__TemplateId__c = lstTmp[0].id;
            lstdocumentVersion[0].Apttus__AgreementId__c = agree.id;
            insert lstdocumentVersion;
            
            ContentVersion cv = TestFactory.createContentVersion('1','1','1','Titre du contenu initial',Blob.valueOf('Contenu initial'),'test');
        	insert cv;
            lstdocumentVersionDetail = new List<Apttus__DocumentVersionDetail__c>{
                    TestFactory.createDocumentVersionDetail('Document Version Detail-pdf',lstdocumentVersion[0].Id,'Title test',1,2,3)
            };
            lstdocumentVersionDetail[0].Apttus__ContentVersionId__c = cv.id; 
            lstdocumentVersionDetail[0].Stage__c = 'Conditions';
             
            insert lstdocumentVersionDetail;
        }
    }

    @IsTest
    public static void testSaveDocuments(){
        System.runAs(testUserCE) {
            Test.startTest();
                ContentVersion contentVersion = new ContentVersion();
                contentVersion.Id = lstContentVersion[0].Id;
                contentVersion.GroupType__c = '1';
                contentVersion.DocumentType__c = '3';
                contentVersion.Phase__c = '3';
                contentVersion.Title = 'CV1';

                List<ContentVersion> lstContentVersionToSave = new List<ContentVersion>{contentVersion};
                List<Id> lstVersionIdToDelete = new List<Id>{lstContentVersion[1].Id};
                Map<String, Object> mapResults = LWC14_Documents.saveDocuments(lstContentVersionToSave, lstProgram[0].Id, lstVersionIdToDelete);

                ContentVersion contentVersionError = new ContentVersion();
                contentVersionError.GroupType__c = '1';
                contentVersionError.DocumentType__c = '3';
                contentVersionError.Phase__c = '3';
                contentVersionError.Title = 'CV1';

                List<ContentVersion> lstContentVersionToSaveError = new List<ContentVersion>{contentVersionError};
                List<Id> lstVersionIdToDeleteError = new List<Id>{lstContentVersion[1].Id};
                Map<String, Object> mapResultsError = LWC14_Documents.saveDocuments(lstContentVersionToSaveError, lstProgram[0].Id, lstVersionIdToDeleteError);

            Test.stopTest();
            System.assertEquals('Success', mapResults.get('Success'));
            System.assertEquals(null, mapResultsError.get('Success'));
        }
    }

    @IsTest
    public static void testGetDocuments(){
        System.runAs(testUserCE) {
            Test.startTest();
                ContentVersion contentVersion2 = new ContentVersion(GroupType__c = '1', DocumentType__c = '3',Phase__c = '3', VersionData = lstContentVersion[0].VersionData
                                                , ContentDocumentId = lstContentVersion[0].ContentDocumentId, PathOnClient ='VCV4', Title = 'CV4');
                insert contentVersion2;
                List<ContentVersion> lstContentVersionResult = LWC14_Documents.getDocuments( lstProgram[0].Id);
            Test.stopTest();
            System.assertEquals(true, lstContentVersionResult.size() > 0);
        }
    }

    @IsTest
    public static void testGetContentVersionId(){
        System.runAs(testUserCE) {
            Test.startTest();
                ContentVersion contentVersionResult = LWC14_Documents.getContentVersionId(lstContentDocumentLink[0].ContentDocumentId);
            Test.stopTest();
            System.assertEquals(true, contentVersionResult != null);
        }
    }

    @IsTest
    public static void testDeleteContentDocument(){
        System.runAs(testUserCE) {
            Test.startTest();
                List<Id> lstDocId = new List<Id>();

                for(ContentDocument contentDocument : [SELECT Id FROM ContentDocument]){
                    lstDocId.add(contentDocument.Id);
                }

                Map<String, Object> mapResult = LWC14_Documents.deleteContentDocument(lstDocId);
            Test.stopTest();

            System.assertEquals('Success', mapResult.get('Success'));
            List<ContentDocument> lstContentDocument = [SELECT Id FROM ContentDocument WHERE Id IN :lstDocId];
            System.assertEquals(0, lstContentDocument.size());
        }
    }

    @IsTest
    public static void testSaveReplaceDocument(){
        System.runAs(testUserCE) {
            Test.startTest();
                List<ContentVersion> lstNewContentVersion = new List<ContentVersion>{
                    TestFactory.createContentVersion('2','1'
                                                    , '1', 'CV3', fileContentInBlob, 'CV3')
                };
                insert lstNewContentVersion;

                lstNewContentVersion = [SELECT Id, ContentDocumentId, DocumentType__c, GroupType__c, Phase__c, Title, VersionData, VersionNumber FROM ContentVersion WHERE Id = :lstNewContentVersion[0].Id];
                Map<String, Object> mapResults = LWC14_Documents.saveReplaceDocument(lstNewContentVersion[0].ContentDocumentId, lstContentVersion[1].Id, '1//2//1;2');

                Map<String, Object> mapResultsError = LWC14_Documents.saveReplaceDocument(lstNewContentVersion[0].ContentDocumentId, lstContentVersion[1].Id, '1//2');
            Test.stopTest();
            System.assertEquals('Success', mapResults.get('Success'));
            System.assertEquals(null, mapResultsError.get('Success'));
        }
    }

    @IsTest
    public static void testDeleteReplaceDocument(){
        System.runAs(testUserCE) {
            Test.startTest();
                ContentVersion contentVersion = new ContentVersion(GroupType__c = '1', DocumentType__c = '3',Phase__c = '3', VersionData = lstContentVersion[0].VersionData
                                                , ContentDocumentId = lstContentVersion[0].ContentDocumentId, PathOnClient ='VCV4', Title = 'CV4');
                insert contentVersion;
                List<ContentVersion> lstContentVersionToDelete = new List<ContentVersion>{lstContentVersion[0], contentVersion};
                ContentVersion contentVersionReplace = new ContentVersion(GroupType__c = '1', DocumentType__c = '3',Phase__c = '3', VersionData = lstContentVersion[0].VersionData
                                                    , ContentDocumentId = lstContentVersion[0].ContentDocumentId, PathOnClient ='VCV4', Title = 'CV4');
                insert contentVersionReplace;
                Map<String, Object> mapResult = LWC14_Documents.deleteReplaceDocument(lstContentVersionToDelete);
            Test.stopTest();
            System.assertEquals('Success', mapResult.get('Success'));
        }
    }

    @IsTest
    public static void testGetInitialDocuments(){
        System.runAs(testUserCE) {
            Test.startTest();
                Map<Id, List<String>> mapResult = LWC14_Documents.getInitialDocuments( lstProgram[0].Id);
            Test.stopTest();
            System.assertEquals(true, mapResult.size() > 0);
        }
    }

    @IsTest
    public static void testReplaceDocuments() {
        System.runAs(testUserCE) {
            Test.startTest();
                Map<Id, List<String>> mapInitialDocuments = LWC14_Documents.getInitialDocuments(lstProgram[0].Id);
                ContentVersion contentVersion = new ContentVersion(GroupType__c = '1', DocumentType__c = '3',Phase__c = '3', VersionData = lstContentVersion[0].VersionData
                        , ContentDocumentId = lstContentVersion[0].ContentDocumentId, PathOnClient ='CV5', Title = 'CV5');
                insert contentVersion;
                Map<String, Object> mapResult = LWC14_Documents.replaceDocuments(mapInitialDocuments, lstProgram[0].Id);
            Test.stopTest();
            System.assertEquals('Success', mapResult.get('Success'));
        }
    }

    @IsTest
    public static void testGetExternalDocuments() {
        System.runAs(testUserCE) {
            Test.startTest();
                List <DocumentVisibility__c> lstExternalDocs = LWC14_Documents.getExternalDocumentVisibility(lstProgram[1].Id);
                System.debug('lstExternalDocs=='+ lstExternalDocs);
            Test.stopTest();
            System.assertEquals(0, lstExternalDocs.size());
        }
    }

    @IsTest
    public static void testGetTHEMISDocuments() {
        System.runAs(testUserCE) {
            Test.startTest();
                List<ContentVersion> lstThemisDocs = LWC14_Documents.getTHEMISDocuments(lstProgram[1].Id);
            Test.stopTest();
            System.assertEquals(1, lstThemisDocs.size());
        }
    }
    
    @IsTest
    public static void testGetCongaDocuments() {
        System.runAs(testUserCE) {
            Test.startTest();
        		List<ContentVersion> lstCongaDocs= LWC14_Documents.getCongaDocuments(lstProgram[1].Id);
            Test.stopTest();
        }
	}

    @IsTest
    public static void testViewOrCreateAgreement() {

        Id acceptationRecordTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Acceptation').getRecordTypeId();
        System.runAs(testUserCE) {
            Test.startTest();
        		Map<String,Object> mapRes= LWC14_Documents.viewOrCreateAgreement(lstProgram[1].Id, acceptationRecordTypeId);
            Test.stopTest();
        }
	}
    @IsTest
    public static void testrenewAgreement() {
        System.runAs(testUserAdmin){
            Test.startTest();
                lstProgram[2].RenewedFromProgram__c = lstProgram[1].id;
                update lstProgram[2];
                Map<String,Object> mapRes= LWC14_Documents.renewAgreement(lstProgram[2].Id);
            Test.stopTest();
        }
	}
    @IsTest
    public static void testgetMetadataFieldValue() {
        Test.startTest();
            String res= LWC14_Documents.getMetadataFieldValue('CLMSettings__mdt','ShowClmButtons');
        Test.stopTest();
	}

    @IsTest
    public static void testcheckAgreementGenerationStatus() {
        Test.startTest();
        Map<String,Object> mapRes= LWC14_Documents.checkAgreementGenerationStatus(lstProgram[1].Id);
        Test.stopTest();
	}
}