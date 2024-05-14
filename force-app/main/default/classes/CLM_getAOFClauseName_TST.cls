/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 11-30-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
public class CLM_getAOFClauseName_TST {

    @isTest
    static void testGetFirstTemplateId() {
        // Test data setup
        CLM_getAOFClauseName.CLM_getAOFClauseNameInput input = new CLM_getAOFClauseName.CLM_getAOFClauseNameInput();
        input.MacroLob = 'Test MacroLob';
        input.reinsurer = 'Test Reinsurer';
        input.CoveredCedingCompanyNames = new List<String>{ 'Company A', 'Company B' };

        // Test method execution
        Test.startTest();
        List<CLM_getAOFClauseName.CLM_getAOFClauseNameInput> inputs = new List<CLM_getAOFClauseName.CLM_getAOFClauseNameInput>{ input };
        List<CLM_getAOFClauseName.CLM_getAOFClauseNameOutput> result = CLM_getAOFClauseName.getFirstTemplateId(inputs);
        Test.stopTest();

        // Assertion
        System.assertNotEquals(null, result, 'Result should not be null');
    }
}