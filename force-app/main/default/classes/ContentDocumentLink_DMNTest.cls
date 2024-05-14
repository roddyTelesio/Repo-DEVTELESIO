/**
 * @description       : 
 * @author            : Patrick Randrianarisoa
 * @group             : 
 * @last modified on  : 20-03-2024
 * @last modified by  : Patrick Randrianarisoa
 * Modifications Log
 * Ver   Date         Author                   Modification
 * 1.0   20-03-2024   Patrick Randrianarisoa   Initial Version
**/
@isTest
public class ContentDocumentLink_DMNTest {

    static List<ContentDocumentLink> lstContentDocLink;

    static User adminUser = TestFactory.createAdminUserWithCLMAdminPermissionSet(); 

    static {

        System.runAs(adminUser){
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
            agreement.program__c = pro.id;
            agreement.Apttus__Status__c = 'In Renewal';
            insert agreement;
            Apttus__DocumentVersion__c testDocumentVersion = TestFactory.createDocumentVersion('1.0','1','Title');
            testDocumentVersion.Apttus__AgreementId__c = agreement.id;
            insert testDocumentVersion;
            Apttus__DocumentVersionDetail__c testDocumentVersionDetail = TestFactory.createDocumentVersionDetail('1.0',testDocumentVersion.id,'Ttitle',1,0,1);
            testDocumentVersionDetail.ToProcessDelete__c =true;
            testDocumentVersionDetail.Apttus__DocumentInfo__c = 'Final';
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
    
            lstContentDocLink = new List<ContentDocumentLink>();
            ContentDocumentLink testContentDocumentLink1 = new ContentDocumentLink(
                ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :testContentVersion1.Id].ContentDocumentId,
                LinkedEntityId = testDocumentVersionDetail.id,
                ShareType = 'V'
            );
            lstContentDocLink.add(testContentDocumentLink1);
            ContentDocumentLink testContentDocumentLink2 = new ContentDocumentLink(
                ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :testContentVersion2.Id].ContentDocumentId,
                LinkedEntityId = testDocumentVersionDetail.id,
                ShareType = 'V'
            );
            lstContentDocLink.add(testContentDocumentLink2);
    
            insert lstContentDocLink;
        }
        
    }
    @isTest
    static void testMarkForDeletion() {
        // Créer des enregistrements fictifs de ContentDocumentLink pour les tests
        // Ajoutez des enregistrements de ContentDocumentLink à testLinks selon vos besoins

        Test.startTest();
        System.runAs(adminUser){
            // Appel de la méthode markForDeletion
            ContentDocumentLink_DMN.markForDeletion(lstContentDocLink);   
        }
        
        Test.stopTest();

        // Ajoutez des assertions pour vérifier si la méthode markForDeletion a fonctionné correctement
        // Vérifiez si les enregistrements de Apttus__DocumentVersionDetail__c et Apttus__APTS_Agreement__c ont été mis à jour comme prévu
    }

    @isTest
    static void testGetDvdDetails() {
        Test.startTest();
        // Créez des enregistrements fictifs de Apttus__DocumentVersionDetail__c pour les tests
        Set<String> testIds = new Set<String>();
        // Ajoutez des IDs fictifs à testIds selon vos besoins
        Map<Id, Apttus__DocumentVersionDetail__c> result;
        // Appelez la méthode getDvdDetails
        System.runAs(adminUser){
            result = ContentDocumentLink_DMN.getDvdDetails(testIds);
        }
        
        Test.stopTest();

        // Ajoutez des assertions pour vérifier si la méthode getDvdDetails a fonctionné correctement
        System.assertNotEquals(null, result); // Vérifiez si le résultat n'est pas nul
        // Vérifiez si le résultat contient les enregistrements attendus
    }

    @isTest
    static void testGetFinalVersionPerAgmt() {
        Test.startTest();
        // Créez des enregistrements fictifs de Apttus__DocumentVersionDetail__c pour les tests
        Set<String> testIds = new Set<String>();
        // Ajoutez des IDs fictifs à testIds selon vos besoins

        // Appelez la méthode getFinalVersionPerAgmt
        Map<Id, Id> result;
        System.runAs(adminUser){
            result = ContentDocumentLink_DMN.getFinalVersionPerAgmt(testIds);
        }
        
        Test.stopTest();

        // Ajoutez des assertions pour vérifier si la méthode getFinalVersionPerAgmt a fonctionné correctement
        System.assertNotEquals(null, result); // Vérifiez si le résultat n'est pas nul
        // Vérifiez si le résultat contient les enregistrements attendus
    }

    @isTest
    static void testTimestampWithin2Minutes() {
        // Créez des objets Datetime pour les tests
        Datetime startDate = Datetime.now();
        Datetime endDate = startDate.addMinutes(1); // Modifier cela selon vos besoins

        Test.startTest();
        // Appelez la méthode timestampWithin2Minutes
        Boolean result; 
        System.runAs(adminUser){
            result = ContentDocumentLink_DMN.timestampWithin2Minutes(startDate, endDate);
        }
        
        Test.stopTest();

        // Ajoutez des assertions pour vérifier si la méthode timestampWithin2Minutes a fonctionné correctement
        System.assertEquals(true, result); // Vérifiez si le résultat est conforme aux attentes
    }
}