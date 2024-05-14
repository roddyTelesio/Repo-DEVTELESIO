/**
 * @description       : 
 * @author            : Patrick Randrianarisoa PRAA
 * @group             : 
 * @last modified on  : 20-03-2024
 * @last modified by  : Patrick Randrianarisoa
 * Modifications Log
 * Ver   Date         Author                   Modification
 * 1.0   19-03-2024   Patrick Randrianarisoa   Initial Version
**/
@isTest 
public class AgreementRenewal_QUE_TEST {

    @testSetup
    static void setupTestData() {
        // Create common test data
        Map<String, Id> mapRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{
            AP_Constant.sObjectAcc
        });

        //create Account
        Account compte = TestFactory.createAccount(mapRecTypeId.get(AP_Constant.accRTPrincipalCedingCom),'Account A','C_0001');
        insert compte;
        Program__c pro = TestFactory.createProgram('TestProg3', '2', '3'
        , Date.today(), Date.today().addYears(1), '2', Date.today(), Date.today().addYears(1)
        , '2018', compte.Id, '23001', '1', '25001');
        insert pro;
        Apttus__APTS_Agreement__c agreement = TestFactory.createAgreement('Test agreement');
        agreement.DeleteRenewedAgreementDocuments__c = true;
        agreement.program__c = pro.id;
        agreement.Apttus__Contract_End_Date__c = System.today()+360;
        insert agreement;
        Apttus__DocumentVersion__c testDocumentVersion = TestFactory.createDocumentVersion('1.0','1','Title');
        testDocumentVersion.Apttus__AgreementId__c = agreement.id;
        insert testDocumentVersion;
        Apttus__DocumentVersionDetail__c testDocumentVersionDetail = TestFactory.createDocumentVersionDetail('1.0',testDocumentVersion.id,'Ttitle',1,0,1);
        testDocumentVersionDetail.ToProcessDelete__c =true;
        // Add any required field assignments
        insert testDocumentVersionDetail;


        // Create a test ContentDocument
        List<ContentVersion> listContentVer = new List<ContentVersion>();
        ContentVersion testContentVersion1 = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'TestDocument.txt',
            VersionData = Blob.valueOf('Test document content')
        );
        listContentVer.add(testContentVersion1);

        ContentVersion testContentVersion2 = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'TestDocument.txt',
            VersionData = Blob.valueOf('Test document content')
        );
        listContentVer.add(testContentVersion2);

        insert listContentVer;

        List<ContentDocumentLink> lstContentDocLink = new List<ContentDocumentLink>();
        ContentDocumentLink testContentDocumentLink1 = new ContentDocumentLink(
            ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :testContentVersion1.Id].ContentDocumentId,
            LinkedEntityId = agreement.id,
            ShareType = 'V'
        );
        lstContentDocLink.add(testContentDocumentLink1);
        ContentDocumentLink testContentDocumentLink2 = new ContentDocumentLink(
            ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :testContentVersion2.Id].ContentDocumentId,
            LinkedEntityId = agreement.id,
            ShareType = 'V'
        );
        lstContentDocLink.add(testContentDocumentLink2);

        insert lstContentDocLink;

        
    }

    @isTest
    static void test1Execute_NoDocumentVersionDetails() {
        Test.startTest();
        Map<Id, Apttus__APTS_Agreement__c> mapAgree = new Map<Id, Apttus__APTS_Agreement__c>([SELECT Id FROM Apttus__APTS_Agreement__c LIMIT 1])
        ;
        Apttus__DocumentVersionDetail__c testDocumentVersionDetail = [SELECT id From Apttus__DocumentVersionDetail__c LIMIT 1];
        testDocumentVersionDetail.ToProcessDelete__c =false;
        update testDocumentVersionDetail;
        AgreementRenewal_QUE agreementRenewalQue = new AgreementRenewal_QUE(mapAgree);
        agreementRenewalQue.execute(null);
        Test.stopTest();

        // Add assertions here if needed
    }

    @isTest
    static void test2Execute_NoDocumentVersionDetails() {
        Test.startTest();
        Apttus__DocumentVersionDetail__c testDocumentVersionDetail = [SELECT id From Apttus__DocumentVersionDetail__c LIMIT 1];
        testDocumentVersionDetail.ToProcessDelete__c =false;
        update testDocumentVersionDetail;
        AgreementRenewal_QUE agreementRenewalQue = new AgreementRenewal_QUE();
        agreementRenewalQue.execute(null);
        Test.stopTest();
    }

    @isTest
    static void testExecute_WithDocumentVersionDetails() {
        Test.startTest();
        AgreementRenewal_QUE agreementRenewalQue = new AgreementRenewal_QUE();
        agreementRenewalQue.execute(null);
        Test.stopTest();
    }
    @isTest
    static void testExecute_WithDocumentVersionDetailsCopyFinalVersion() {
        Test.startTest();
        Apttus__APTS_Agreement__c agree = [SELECT Id,Renew_Type__c FROM Apttus__APTS_Agreement__c LIMIT 1]
        ;
        agree.Renew_Type__c = 'Copy Final Version And Signed PDF';
        update agree;
        AgreementRenewal_QUE agreementRenewalQue = new AgreementRenewal_QUE();
        agreementRenewalQue.execute(null);
        Test.stopTest();
    }

    @isTest
    static void testExecute_WithDocumentVersionDetailsLTATRIdenticalRenew() {
        Test.startTest();
        Program__c pro = [SELECT Id,TypeOfRenew__c FROM Program__c LIMIT 1]
        ;
        pro.TypeOfRenew__c = 'LTA/TR Identical Renew';
        update pro;
        Map<Id, Apttus__APTS_Agreement__c> mapAgree = new Map<Id, Apttus__APTS_Agreement__c>([SELECT Id FROM Apttus__APTS_Agreement__c LIMIT 1])
        ;
        Apttus__DocumentVersionDetail__c testDocumentVersionDetail = [SELECT id From Apttus__DocumentVersionDetail__c LIMIT 1];
        testDocumentVersionDetail.ToProcessDelete__c =false;
        update testDocumentVersionDetail;
        AgreementRenewal_QUE agreementRenewalQue = new AgreementRenewal_QUE(mapAgree);
        agreementRenewalQue.execute(null);
        Test.stopTest();
    }
    @isTest

    static void testExecute_WithDocumentVersionDetailsLTATRRenegotiation() {
        Test.startTest();
        Program__c pro = [SELECT Id,TypeOfRenew__c FROM Program__c LIMIT 1]
        ;
        pro.TypeOfRenew__c = 'LTA/TR Renegotiation';
        update pro;
        Map<Id, Apttus__APTS_Agreement__c> mapAgree = new Map<Id, Apttus__APTS_Agreement__c>([SELECT Id FROM Apttus__APTS_Agreement__c LIMIT 1])
        ;
        Apttus__DocumentVersionDetail__c testDocumentVersionDetail = [SELECT id From Apttus__DocumentVersionDetail__c LIMIT 1];
        testDocumentVersionDetail.ToProcessDelete__c =false;
        update testDocumentVersionDetail;
        AgreementRenewal_QUE agreementRenewalQue = new AgreementRenewal_QUE(mapAgree);
        agreementRenewalQue.execute(null);
        Test.stopTest();
    }

}