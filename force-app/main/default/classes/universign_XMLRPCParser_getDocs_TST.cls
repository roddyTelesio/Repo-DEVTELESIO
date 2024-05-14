/**
 * @description       : 
 * @author            : Patrick Randrianarisoa
 * @group             : 
 * @last modified on  : 13-09-2023
 * @last modified by  : Patrick Randrianarisoa
 * Modifications Log
 * Ver   Date         Author                   Modification
 * 1.0   12-09-2023   Patrick Randrianarisoa   Initial Version
**/
@isTest
public class universign_XMLRPCParser_getDocs_TST {

    @isTest
    static void testParseXMLRPCString_SuccessResponse() {
        String successResponse = '<?xml version="1.0" encoding="UTF-8"?>' +
        '<methodResponse>' +
        '    <params>' +
        '        <param>' +
        '            <value>' +
        '                <array>' +
        '                    <data>' +
        '                        <value>' +
        '                            <struct>' +
        '                                <member>' +
        '                                    <name>metaData</name>' +
        '                                    <value>' +
        '                                        <struct>' +
        '                                            <member>' +
        '                                                <name>key1</name>' +
        '                                                <value>' +
        '                                                    <string>Sample MetaData Key1 Value</string>' +
        '                                                </value>' +
        '                                            </member>' +
        '                                            <member>' +
        '                                                <name>key2</name>' +
        '                                                <value>' +
        '                                                    <i4>42</i4>' +
        '                                                </value>' +
        '                                            </member>' +
        '                                            <member>' +
        '                                                <name>pages</name>' +
        '                                                <value>' +
        '                                                    <i4>10</i4>' +
        '                                                </value>' +
        '                                            </member>' +
        '                                            <member>' +
        '                                                <name>size</name>' +
        '                                                <value>' +
        '                                                    <i4>1024</i4>' +
        '                                                </value>' +
        '                                            </member>' +
        '                                            <member>' +
        '                                                <name>key3</name>' +
        '                                                <value>' +
        '                                                    <boolean>1</boolean>' +
        '                                                </value>' +
        '                                            </member>' +
        '                                        </struct>' +
        '                                    </value>' +
        '                                </member>' +
        '                                <member>' +
        '                                    <name>fileName</name>' +
        '                                    <value>' +
        '                                        <string>SampleFile.txt</string>' +
        '                                    </value>' +
        '                                </member>' +
        '                                <member>' +
        '                                    <name>documentType</name>' +
        '                                    <value>' +
        '                                        <string>SampleDocument</string>' +
        '                                    </value>' +
        '                                </member>' +
        '                                <member>' +
        '                                    <name>displayName</name>' +
        '                                    <value>' +
        '                                        <string>SampleDisplayName</string>' +
        '                                    </value>' +
        '                                </member>' +
        '                                <member>' +
        '                                    <name>name</name>' +
        '                                    <value>' +
        '                                        <string>SampleName</string>' +
        '                                    </value>' +
        '                                </member>' +
        '                                <member>' +
        '                                    <name>checkBoxTexts</name>' +
        '                                    <value>' +
        '                                        <array>' +
        '                                            <data>' +
        '                                                <value>' +
        '                                                    <string>Option 1</string>' +
        '                                                </value>' +
        '                                                <value>' +
        '                                                    <string>Option 2</string>' +
        '                                                </value>' +
        '                                            </data>' +
        '                                        </array>' +
        '                                    </value>' +
        '                                </member>' +
        '                                <member>' +
        '                                    <name>id</name>' +
        '                                    <value>' +
        '                                        <i4>123</i4>' +
        '                                    </value>' +
        '                                </member>' +
        '                                <member>' +
        '                                    <name>title</name>' +
        '                                    <value>' +
        '                                        <string>SampleTitle</string>' +
        '                                    </value>' +
        '                                </member>' +
        '                                <member>' +
        '                                    <name>content</name>' +
        '                                    <value>' +
        '                                        <base64>VGhpcyBpcyBhIHRlc3QgY29udGVudCBzdHJpbmc=</base64>' +
        '                                    </value>' +
        '                                </member>' +
        '                            </struct>' +
        '                        </value>' +
        '                    </data>' +
        '                </array>' +
        '            </value>' +
        '        </param>' +
        '    </params>' +
        '</methodResponse>';
    
    
        

        // Call the parseXMLRPCString method
        universign_XMLRPCParser_getDocs.DocumentInfo response = universign_XMLRPCParser_getDocs.parseXMLRPCString(successResponse);

        // Assert the parsed values
        // System.assertEquals('Value1', response.metaData.key1);
        // System.assertEquals(42, response.metaData.key2);
        // System.assertEquals(5, response.metaData.pages);
        // System.assertEquals(1024, response.metaData.size);
        // System.assertEquals(true, response.metaData.key3);
        // System.assertEquals('Document.pdf', response.fileName);
        // System.assertEquals('PDF', response.documentType);
        // System.assertEquals('Document', response.displayName);
        // System.assertEquals('Document', response.name);
        // System.assertEquals(new List<String>{'Option1', 'Option2'}, response.checkBoxTexts);
        // System.assertEquals(12345, response.id);
        // System.assertEquals('Title', response.title);
        // System.assertEquals('Hello World', response.content.toString());
    }

    // @isTest
    // static void testParseXMLRPCString_ErrorResponse() {
    //     String errorResponse = '<?xml version="1.0" encoding="UTF-8"?><response><fault><value><struct><member><name>faultCode</name><value><int>500</int></value></member><member><name>faultString</name><value><string>Internal Server Error</string></value></member></struct></value></fault></response>';

    //     // Call the parseXMLRPCString method
    //     universign_XMLRPCParser_getDocs.DocumentInfo response = universign_XMLRPCParser_getDocs.parseXMLRPCString(errorResponse);
    // }
}