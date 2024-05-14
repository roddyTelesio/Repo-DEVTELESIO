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
public class CLM_AmmendAgreement_TST {

    public static Id acceptationRecordTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Acceptation').getRecordTypeId();
    @testSetup
    static void setupTestData() {
        // Create test data here, such as an initial agreement record
        Apttus__APTS_Agreement__c initialAgreement = TestFActory.createAgreement('Test Agreement');
        initialAgreement.recordTypeId = acceptationRecordTypeId;
        insert initialAgreement;
    }

    @isTest
    static void testCreateAmmendment() {
        CLM_AmmendAgreement.ObjectContext objContext = new CLM_AmmendAgreement.ObjectContext();
        Apttus__APTS_Agreement__c agre= [SELECT Id FROM Apttus__APTS_Agreement__c LIMIT 1 ];
        objContext.agreementId = agre.Id;
        List<CLM_AmmendAgreement.Result> results = CLM_AmmendAgreement.createAmmendment(new List<CLM_AmmendAgreement.ObjectContext>{objContext});

        // Assert the results
        System.assertEquals(1, results.size(), 'Expected one result');
        CLM_AmmendAgreement.Result result = results[0];
        System.assertEquals(true, result.isSuccess, 'Expected isSuccess to be true');
        System.assertEquals(null, result.errorMsg, 'Expected errorMsg to be null');
        System.assertNotEquals(null, result.agreementGenerated, 'Expected agreementGenerated to not be null');
    }

	@isTest
    static void testCreateAmmendmentFailure() {
        CLM_AmmendAgreement.ObjectContext objContext = new CLM_AmmendAgreement.ObjectContext();
        List<CLM_AmmendAgreement.Result> results = CLM_AmmendAgreement.createAmmendment(new List<CLM_AmmendAgreement.ObjectContext>{objContext});
    }
}