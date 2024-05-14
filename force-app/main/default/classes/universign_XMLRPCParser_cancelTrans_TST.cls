/**
 * @description       : 
 * @author            : Patrick Randrianarisoa
 * @group             : 
 * @last modified on  : 12-09-2023
 * @last modified by  : Patrick Randrianarisoa
 * Modifications Log
 * Ver   Date         Author                   Modification
 * 1.0   12-09-2023   Patrick Randrianarisoa   Initial Version
**/
@isTest
public class universign_XMLRPCParser_cancelTrans_TST {
    @isTest
    static void testParseXMLRPCString_SuccessResponse() {
        String successResponse = '<?xml version="1.0" encoding="UTF-8"?><response><params><param><value><int>0</int></value></param></params></response>';
        universign_XMLRPCParser_cancelTrans.CancelTransactionResponse response = universign_XMLRPCParser_cancelTrans.parseXMLRPCString(successResponse);

        // Assert that the response is not a fault (error) response
        System.assertEquals(-1, response.faultCode);
        System.assertEquals('', response.faultString);
    }
    @isTest
    static void testParseXMLRPCString_ErrorResponse() {
        String errorResponse = '<?xml version="1.0" encoding="UTF-8"?><response><fault><value><struct><member><name>faultCode</name><value><int>500</int></value></member><member><name>faultString</name><value><string>Internal Server Error</string></value></member></struct></value></fault></response>';
        universign_XMLRPCParser_cancelTrans.CancelTransactionResponse response = universign_XMLRPCParser_cancelTrans.parseXMLRPCString(errorResponse);

        // Assert that the response is a fault (error) response
        System.assertEquals(500, response.faultCode);
        System.assertEquals('Internal Server Error', response.faultString);
    }
    // @isTest
    // static void testParseXMLRPCString_MalformedResponse() {
    //     String malformedResponse = '<?xml version="1.0" encoding="UTF-8"?><malformed></malformed>';
    //     universign_XMLRPCParser_cancelTrans.CancelTransactionResponse response = universign_XMLRPCParser_cancelTrans.parseXMLRPCString(malformedResponse);

    //     // Assert that the response is not a fault (error) response
    //     System.assertEquals(-1, response.faultCode);
    //     System.assertEquals('', response.faultString);

    // }
}