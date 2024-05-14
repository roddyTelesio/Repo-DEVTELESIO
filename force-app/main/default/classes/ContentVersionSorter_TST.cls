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
public class ContentVersionSorter_TST {
    @isTest
    static void testSortByPhase() {
        // Create test ContentVersion records
        List<ContentVersion> contentVersions = new List<ContentVersion>();
        for (Integer i = 5; i > 0; i--) {
            ContentVersion cv = TestFactory.createContentVersion('1','1','1','Test Content ' + i,Blob.valueOf('Test Content 2'),'test');
            cv.TECH_PhaseNumber__c =i;
            contentVersions.add(cv);
        }
        insert contentVersions;

        // Call the sortByPhase method
        List<ContentVersion> sortedContentVersions = ContentVersionSorter.sortByPhase(contentVersions);

        // Verify that the ContentVersions are sorted by TECH_PhaseNumber__c in ascending order
        for (Integer i = 0; i < sortedContentVersions.size() - 1; i++) {
            System.assertEquals(true, sortedContentVersions[i].TECH_PhaseNumber__c <= sortedContentVersions[i + 1].TECH_PhaseNumber__c);
        }
    }
}