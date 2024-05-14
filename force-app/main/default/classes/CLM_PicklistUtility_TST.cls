/**
 * @description       : 
 * @author            : Patrick Randrianarisoa
 * @group             : 
 * @last modified on  : 13-11-2023
 * @last modified by  : Patrick Randrianarisoa
 * Modifications Log
 * Ver   Date         Author                   Modification
 * 1.0   10-11-2023   Patrick Randrianarisoa   Initial Version
**/
@IsTest
public class CLM_PicklistUtility_TST {

    @isTest
    static void testGetPicklistLabelByApiName() {
        CLM_PicklistUtility.InputVariables inputVariable1 = new CLM_PicklistUtility.InputVariables();
        inputVariable1.apiname = '1';
        inputVariable1.fieldApiname = 'LossDepositMode__c';
        CLM_PicklistUtility.InputVariables inputVariable2 = new CLM_PicklistUtility.InputVariables();
        inputVariable2.apiname = '1';
        inputVariable2.fieldApiname = 'LossAttachment__c';

        // Call the method
        List<CLM_PicklistUtility.Result> result1 = CLM_PicklistUtility.getPicklistLabelByApiName(new List<CLM_PicklistUtility.InputVariables>{ inputVariable1 });

        List<CLM_PicklistUtility.Result> result2 = CLM_PicklistUtility.getPicklistLabelByApiName(new List<CLM_PicklistUtility.InputVariables>{ inputVariable2 });

        // Validate the result
        System.assertEquals(true, result1[0].isSuccess, 'Expected isSuccess to be true');
        System.assertEquals(null, result1[0].errorMsg, 'Expected errorMsg to be null');
        System.assertEquals('Cash', result1[0].label, 'Expected label to match picklist value');

        System.assertEquals(true, result2[0].isSuccess, 'Expected isSuccess to be true');
        System.assertEquals(null, result2[0].errorMsg, 'Expected errorMsg to be null');
        System.assertEquals('Risk attaching', result2[0].label, 'Expected label to match picklist value');
    }

    @isTest
    static void testGetPicklistLabelByApiNameFail() {
        CLM_PicklistUtility.InputVariables inputVariable1 = new CLM_PicklistUtility.InputVariables();

        // Call the method
        List<CLM_PicklistUtility.Result> result1 = CLM_PicklistUtility.getPicklistLabelByApiName(new List<CLM_PicklistUtility.InputVariables>{ inputVariable1 });

        // Validate the result
        System.assertEquals(false, result1[0].isSuccess, 'Expected isSuccess to be true');
        System.assertNotEquals(null, result1[0].errorMsg, 'Expected errorMsg to be null');
        System.assertEquals(null, result1[0].label, 'Expected label to match picklist value');
    }
}