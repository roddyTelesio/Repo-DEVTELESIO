/**
 * @description       : 
 * @author            : Patrick Randrianarisoa
 * @group             : 
 * @last modified on  : 22-11-2023
 * @last modified by  : Patrick Randrianarisoa
 * Modifications Log
 * Ver   Date         Author                   Modification
 * 1.0   22-11-2023   Patrick Randrianarisoa   Initial Version
**/
@isTest
public class CLM_StringUtility_TST {

    @isTest
    public static void testGetTextValueByList() {
        // Test data setup
        CLM_StringUtility.InputVariables input = new CLM_StringUtility.InputVariables();
        input.listParameter = new List<String>{'Value1', 'Value2', 'Value3'};
        input.isTreatyref = true;

        List<CLM_StringUtility.InputVariables> inputList = new List<CLM_StringUtility.InputVariables>();
        inputList.add(input);

        // Test the method
        Test.startTest();
        List<CLM_StringUtility.Result> result = CLM_StringUtility.getTextValueByList(inputList);
        input.isTreatyref = false;
        List<CLM_StringUtility.Result> result2 = CLM_StringUtility.getTextValueByList(inputList);
        Test.stopTest();

        // Verify the result
        System.assertEquals(1, result.size(), 'Expected one result');
        System.assertEquals(1, result2.size(), 'Expected one result');
    }

    @isTest
    public static void testGetTextValueByListfAIL() {
        // Test data setup
        CLM_StringUtility.InputVariables input = new CLM_StringUtility.InputVariables();

        List<CLM_StringUtility.InputVariables> inputList = new List<CLM_StringUtility.InputVariables>();
        inputList.add(input);

        // Test the method
        Test.startTest();
        List<CLM_StringUtility.Result> result = CLM_StringUtility.getTextValueByList(inputList);
        Test.stopTest();

        // Verify the result
        System.assertEquals(1, result.size(), 'Expected one result');
    }
}