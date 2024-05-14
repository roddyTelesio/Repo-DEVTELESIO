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
public class universign_XMLRPCParser_TST {

    @IsTest
    static void testParseXMLRPCString() {
        // Test XML response for a successful response
        String successResponse = '<?xml version="1.0" encoding="UTF-8"?><response><params><param><value><struct><member><name>id</name><value><string>12345</string></value></member><member><name>url</name><value><string>https://example.com</string></value></member></struct></value></param></params></response>';

        // Test XML response for an error (fault) response
        String errorResponse = '<?xml version="1.0" encoding="UTF-8"?><response><fault><value><struct><member><name>faultCode</name><value><int>500</int></value></member><member><name>faultString</name><value><string>Internal Server Error</string></value></member></struct></value></fault></response>';

        // Test parsing a successful response
        universign_XMLRPCParser.RPCResponse successResult = universign_XMLRPCParser.parseXMLRPCString(successResponse);
        System.assertEquals('12345', successResult.id);
        System.assertEquals('https://example.com', successResult.url);

        // Test parsing an error (fault) response
        // universign_XMLRPCParser.RPCResponse errorResult = universign_XMLRPCParser.parseXMLRPCString(errorResponse);
        // System.assertEquals(500, errorResult.faultCode);
        // System.assertEquals('Internal Server Error', errorResult.faultString);
    }
}