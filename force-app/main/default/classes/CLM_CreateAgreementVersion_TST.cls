/**
 * @description       : 
 * @author            : Patrick Randrianarisoa
 * @group             : 
 * @last modified on  : 13-09-2023
 * @last modified by  : Patrick Randrianarisoa
 * Modifications Log
 * Ver   Date         Author                   Modification
 * 1.0   07-09-2023   Patrick Randrianarisoa   Initial Version
**/
@isTest
public class CLM_CreateAgreementVersion_TST {
    public static Id companygroupRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Principal Ceding Company').getRecordTypeId();

    @testSetup
    static void setupTestData() {
        // Créez un enregistrement Apttus__DocumentVersionDetail__c pour les tests
        ContentVersion cv = TestFactory.createContentVersion('1','1','1','Titre du contenu initial',Blob.valueOf('Contenu initial'),'test');
        insert cv;
        Apttus__APTS_Template__c tmp = TestFActory.createTemplate('test');
        insert tmp;
        Apttus__DocumentVersion__c documentVersion = TestFactory.createDocumentVersion('Document Version','last version','title test');
        documentVersion.Apttus__TemplateId__c = tmp.id;
        insert documentVersion;
        Apttus__DocumentVersionDetail__c documentVersionDetail = TestFactory.createDocumentVersionDetail('Document Version Detail',documentVersion.Id,'Title test',1,2,3);
        documentVersionDetail.Apttus__ContentVersionId__c = cv.id;
        insert documentVersionDetail;
        Account company = TestFactory.createAccount(companygroupRecordTypeId,'Test Account','TestReferentiel');
        insert company;
        Program__c createProgram = TestFactory.createProgram('Test program','1','1',System.today(),System.today().addYears(1),'1',System.today(),System.today().addYears(3),String.valueOf(System.today().year()),String.valueOf(company.id),'23002','2','25010');
        insert createProgram;
    }

    @isTest
    static void testCloneAgreement() {
        CLM_CreateAgreementVersion.ObjectContext context = new CLM_CreateAgreementVersion.ObjectContext();
        Apttus__DocumentVersionDetail__c dvd = [SELECT id FROM Apttus__DocumentVersionDetail__c LIMIT 1];
        Account comp = [SELECT id FROM Account LIMIT 1];
        Program__c pro = [SELECT id FROM Program__c LIMIT 1];
        context.programId = pro.Id;
        context.reinsurerId = comp.Id;
        context.versionDetailsId = dvd.Id;
        // Appelez la méthode cloneAgreement en passant le contexte d'objet
        List<CLM_CreateAgreementVersion.Result> results = CLM_CreateAgreementVersion.cloneAgreement(new List<CLM_CreateAgreementVersion.ObjectContext>{context});

        // Vérifiez les résultats avec des assertions
        System.assertEquals(1, results.size(), 'Le résultat ne contient pas un seul élément.');
        CLM_CreateAgreementVersion.Result result = results[0];
        // System.assertEquals(true, result.isSuccess, 'La création de la version de accord a échoué.');
        // System.assertEquals(null, result.errorMsg, 'Un message erreur inattendu a été renvoyé.');
        // System.assertNotEquals(null, result.agreementId, 'ID de accord créé est manquant.');
    }
}