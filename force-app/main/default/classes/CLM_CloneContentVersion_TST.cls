/**
 * @description       : 
 * @author            : Patrick Randrianarisoa
 * @group             : 
 * @last modified on  : 07-09-2023
 * @last modified by  : Patrick Randrianarisoa
 * Modifications Log
 * Ver   Date         Author                   Modification
 * 1.0   07-09-2023   Patrick Randrianarisoa   Initial Version
**/
@isTest
public class CLM_CloneContentVersion_TST {
    
    @testSetup
    static void setupTestData() {
        // Créez un enregistrement ContentVersion pour les tests
        ContentVersion originalVersion = TestFactory.createContentVersion('1','1','1','Titre du contenu initial',Blob.valueOf('Contenu initial'),'test');
        insert originalVersion;
    }

    @isTest
    static void testCloneContentVersion() {
        CLM_CloneContentVersion.ObjectContext context = new CLM_CloneContentVersion.ObjectContext();
        ContentVersion cv= [SELECT Id FROM ContentVersion LIMIT 1 ];
        
        context.contentVersionId = cv.Id;

        // Appelez la méthode cloneContentVersion en passant le contexte d'objet
        List<CLM_CloneContentVersion.Result> results = CLM_CloneContentVersion.cloneContentVersion(new List<CLM_CloneContentVersion.ObjectContext>{context});

        // Vérifiez les résultats avec des assertions
        System.assertEquals(1, results.size(), 'Le résultat ne contient pas un seul élément.');
        CLM_CloneContentVersion.Result result = results[0];
        System.assertEquals(true, result.isSuccess, 'La clonage du contenu a échoué.');
        System.assertEquals(null, result.errorMsg, 'Un message erreur inattendu a été renvoyé.');
        System.assertNotEquals(null, result.clonedContentVersionId, 'ID du contenu cloné est manquant.');
        System.assertNotEquals(null, result.clonedContentDocId, 'ID du document de contenu cloné est manquant.');
    }
}