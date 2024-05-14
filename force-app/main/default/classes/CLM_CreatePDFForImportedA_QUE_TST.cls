/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 01-04-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
public class CLM_CreatePDFForImportedA_QUE_TST {

    public static Id companygroupRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Principal Ceding Company').getRecordTypeId();


    // Test setup to create necessary test data
    @testSetup
    static void setupTestData() {

        Id acceptationRecordTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Acceptation').getRecordTypeId();
        // Create a test agreement record for the test
        Apttus__APTS_Agreement__c initialAgreement = TestFActory.createAgreement('Test Agreement');
        initialAgreement.recordTypeId = acceptationRecordTypeId;
        initialAgreement.contractCode__c = 'xxx';
        insert initialAgreement;


        // Créez un enregistrement Apttus__DocumentVersionDetail__c pour les tests
        ContentVersion cv = TestFactory.createContentVersion('1','1','1','Titre du contenu initial',Blob.valueOf('Contenu initial'),'test');
        insert cv;

        Apttus__APTS_Template__c tmp = TestFActory.createTemplate('test');
        insert tmp;

        Apttus__DocumentVersion__c documentVersion = TestFactory.createDocumentVersion('Document Version','last version','title test');
        documentVersion.Apttus__TemplateId__c = tmp.id;
        documentVersion.Apttus__AgreementId__c = initialAgreement.id;
        insert documentVersion;

        Apttus__DocumentVersionDetail__c documentVersionDetail = TestFactory.createDocumentVersionDetail('Document Version Detail',documentVersion.Id,'Title test',1,2,3);
        documentVersionDetail.Apttus__ContentVersionId__c = cv.id;
        documentVersionDetail.Apttus__DocumentInfo__c = 'Final';
        documentVersionDetail.TECH_GeneratePDFByBatch__c = true;

        insert documentVersionDetail;
        Account company = TestFactory.createAccount(companygroupRecordTypeId,'Test Account','TestReferentiel');
        
        insert company;
        Program__c createProgram = TestFactory.createProgram('Test program','1','1',System.today(),System.today().addYears(1),'1',System.today(),System.today().addYears(3),String.valueOf(System.today().year()),String.valueOf(company.id),'23002','2','25010');
        insert createProgram;
        
    }

    // Mock class for HTTP callouts
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"success":true}');
            res.setStatusCode(200);
            return res;
        }
    }

    // Test method for the execute method of CLM_CreatePDFForImportedAgreements_QUE
    @isTest
    static void testExecuteMethod() {
        // Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();

        // Enqueue the job
        Id jobId = System.enqueueJob(new CLM_CreatePDFForImportedAgreements_QUE());

        Test.stopTest();
    }

    // Additional test methods to cover other branches or scenarios can be added here
    // ...

}