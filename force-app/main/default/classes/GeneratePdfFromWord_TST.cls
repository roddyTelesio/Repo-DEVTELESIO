/**
 * @description       : 
 * @author            : Patrick Randrianarisoa
 * @group             : 
 * @last modified on  : 11-09-2023
 * @last modified by  : Patrick Randrianarisoa
 * Modifications Log
 * Ver   Date         Author                   Modification
 * 1.0   11-09-2023   Patrick Randrianarisoa   Initial Version
**/
@isTest
public class GeneratePdfFromWord_TST {

    @isTest
    static void testGeneratePdf() {
        GeneratePdfFromWord GPF = New GeneratePdfFromWord();
        Test.startTest();
        GeneratePdfFromWord.GeneratePdf();
        Test.stopTest();
    }

    @isTest
    static void testGeneratePdf2() {
        Test.startTest();
        GeneratePdfFromWord.generatePdf2();
        Test.stopTest();
    }
}