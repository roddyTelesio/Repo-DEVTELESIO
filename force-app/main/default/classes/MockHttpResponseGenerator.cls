/**
 * @description       : 
 * @author            : Patrick Randrianarisoa
 * @group             : 
 * @last modified on  : 14-09-2023
 * @last modified by  : Patrick Randrianarisoa
 * Modifications Log
 * Ver   Date         Author                   Modification
 * 1.0   12-09-2023   Patrick Randrianarisoa   Initial Version
**/
@isTest
global class MockHttpResponseGenerator implements HttpCalloutMock {
    // Implement this interface method
    global HTTPResponse respond(HTTPRequest req) {
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('<?xml version="1.0" encoding="UTF-8"?>' +
        '<methodResponse>' +
        '    <params>' +
        '        <param>' +
        '            <value>' +
        '                <struct>' +
        '                    <member>' +
        '                        <name>signerInfos</name>' +
        '                        <value>' +
        '                            <array>' +
        '                                <data>' +
        '                                    <value>' +
        '                                        <struct>' +
        '                                            <member>' +
        '                                                <name>firstName</name>' +
        '                                                <value>' +
        '                                                    <string>John</string>' +
        '                                                </value>' +
        '                                            </member>' +
        '                                            <member>' +
        '                                                <name>lastName</name>' +
        '                                                <value>' +
        '                                                    <string>Doe</string>' +
        '                                                </value>' +
        '                                            </member>' +
        '                                            <member>' +
        '                                                <name>id</name>' +
        '                                                <value>' +
        '                                                    <string>123</string>' +
        '                                                </value>' +
        '                                            </member>' +
        '                                            <member>' +
        '                                                <name>url</name>' +
        '                                                <value>' +
        '                                                    <string>http://example.com</string>' +
        '                                                </value>' +
        '                                            </member>' +
        '                                            <member>' +
        '                                                <name>email</name>' +
        '                                                <value>' +
        '                                                    <string>john.doe@example.com</string>' +
        '                                                </value>' +
        '                                            </member>' +
        '                                            <member>' +
        '                                                <name>status</name>' +
        '                                                <value>' +
        '                                                    <string>Active</string>' +
        '                                                </value>' +
        '                                            </member>' +
        // '                                            <member>' +
        // '                                                <name>actionDate</name>' +
        // '                                                <value>' +
        // '                                                    <dateTime.iso8601>2023-09-13T12:00:00Z</dateTime.iso8601>' +
        // '                                                </value>' +
        // '                                            </member>' +
        '                                            <member>' +
        '                                                <name>refusalComment</name>' +
        '                                                <value>' +
        '                                                    <string>No comment</string>' +
        '                                                </value>' +
        '                                            </member>' +
        '                                        </struct>' +
        '                                    </value>' +
        '                                </data>' +
        '                            </array>' +
        '                        </value>' +
        '                    </member>' +
        '                    <member>' +
        '                        <name>currentSigner</name>' +
        '                        <value>' +
        '                            <i4>42</i4>' +
        '                        </value>' +
        '                    </member>' +
        '                    <member>' +
        '                        <name>eachField</name>' +
        '                        <value>' +
        '                            <boolean>1</boolean>' +
        '                        </value>' +
        '                    </member>' +
        // '                    <member>' +
        // '                        <name>creationDate</name>' +
        // '                        <value>' +
        // '                            <dateTime.iso8601>2023-09-13T12:00:00Z</dateTime.iso8601>' +
        // '                        </value>' +
        // '                    </member>' +
        '                    <member>' +
        '                        <name>signerCertificates</name>' +
        '                        <value>' +
        '                            <array>' +
        '                                <data>' +
        '                                    <value>' +
        '                                        <string>Certificate1</string>' +
        '                                    </value>' +
        '                                    <value>' +
        '                                        <string>Certificate2</string>' +
        '                                    </value>' +
        '                                </data>' +
        '                            </array>' +
        '                        </value>' +
        '                    </member>' +
        '                    <member>' +
        '                        <name>initiatorInfo</name>' +
        '                        <value>' +
        '                            <struct>' +
        '                                <member>' +
        '                                    <name>info1</name>' +
        '                                    <value>' +
        '                                        <string>InitiatorInfo1</string>' +
        '                                    </value>' +
        '                                </member>' +
        '                                <member>' +
        '                                    <name>info2</name>' +
        '                                    <value>' +
        '                                        <i4>99</i4>' +
        '                                    </value>' +
        '                                </member>' +
        '                            </struct>' +
        '                        </value>' +
        '                    </member>' +
        '                    <member>' +
        '                        <name>transactionId</name>' +
        '                        <value>' +
        '                            <string>Transaction123</string>' +
        '                        </value>' +
        '                    </member>' +
        '                    <member>' +
        '                        <name>status</name>' +
        '                        <value>' +
        '                            <string>ready</string>' +
        '                        </value>' +
        '                    </member>' +
        '                </struct>' +
        '            </value>' +
        '        </param>' +
        '    </params>' +
        '</methodResponse>');
        res.setStatusCode(200);
        return res;
    }
}