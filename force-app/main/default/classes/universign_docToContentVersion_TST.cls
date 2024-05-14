/**
 * @description       : 
 * @author            : Patrick Randrianarisoa
 * @group             : 
 * @last modified on  : 03-11-2023
 * @last modified by  : Patrick Randrianarisoa
 * Modifications Log
 * Ver   Date         Author                   Modification
 * 1.0   03-11-2023   Patrick Randrianarisoa   Initial Version
**/
@isTest
public class universign_docToContentVersion_TST {

    @isTest
    static void testConvertDocToContentVersion() {
        // Create a test Document record
        Document doc = new Document(
            Name = 'Test Document',
            Body = Blob.valueOf('Test Document Content'),
            FolderId = UserInfo.getUserId()
        );
        insert doc;

        // Create an ObjectContext with the Document Id
        universign_docToContentVersion.ObjectContext objContext = new universign_docToContentVersion.ObjectContext();
        objContext.documentId = doc.Id;

        // Call the convertDocToContentVersion method
        List<universign_docToContentVersion.Result> results = universign_docToContentVersion.convertDocToContentVersion(new List<universign_docToContentVersion.ObjectContext>{objContext});

        // Verify the result
        System.assertEquals(1, results.size(), 'Expected one result in the list');
        universign_docToContentVersion.Result result = results[0];
        System.assertEquals(true, result.isSuccess, 'Expected isSuccess to be true');
        System.assertNotEquals(null, result.contentVersionId, 'Expected contentVersionId not to be null');
    }
}