/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 01-18-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class XmlRpcGenerator {
    public static String generateXmlRpcString(String methodName, Map<String, Object> params,List<sObject> contentVersions, List<Object> signers, Integer countTotalPages) {
        String xmlRpcString = '<methodCall>';
        xmlRpcString += '<methodName>' + escapeXmlRpc(methodName) + '</methodName>';
        xmlRpcString += '<params>';
        xmlRpcString += '<param><value>';
        xmlRpcString += getStructXmlRpcString(params,contentVersions,signers, countTotalPages);
        xmlRpcString += '</value></param>';
        xmlRpcString += '</params>';
        xmlRpcString += '</methodCall>';
        system.debug( 'Heap size is ' + limits.getHeapSize() + ' enforced is ' + limits.getLimitHeapSize());
        return xmlRpcString;
    }

    private static String getStructXmlRpcString(Map<String, Object> struct, List<sObject> contentVersions, List<Object> signers, Integer countTotalPages) {
        String xmlRpcString = '<struct>';

        for (String key : struct.keySet()) {
            Object value = struct.get(key);

            system.debug( 'Heap size is ' + limits.getHeapSize() + ' enforced is ' + limits.getLimitHeapSize());

            if(String.valueOf(value) == 'base64doc'){
                xmlRpcString += '<member>';
                xmlRpcString += '<name>' + escapeXmlRpc(key) + '</name>';
                xmlRpcString += '<value>' + getArrayXmlRpcString(universign_sendTransaction.getDocsBase64(contentVersions, signers, countTotalPages)) + '</value>';
                xmlRpcString += '</member>';
            }else{
                xmlRpcString += '<member>';
                xmlRpcString += '<name>' + escapeXmlRpc(key) + '</name>';
                xmlRpcString += '<value>' + getValueXmlRpcString(value) + '</value>';
                xmlRpcString += '</member>';
            }

            system.debug( 'Heap size is ' + limits.getHeapSize() + ' enforced is ' + limits.getLimitHeapSize());

        }

        xmlRpcString += '</struct>';

        return xmlRpcString;
    }

    private static String getValueXmlRpcString(Object value) {
        system.debug( 'Heap size is ' + limits.getHeapSize() + ' enforced is ' + limits.getLimitHeapSize());
        if (value instanceof String) {
            if (((String)value).startsWith('<base64>')) {
                // If the value is a base64 string, remove the <string> tags and directly include the base64 value
                return (String)value;
            } else {
                // Otherwise, wrap the string value with the <string> tags
                return '<string>' + escapeXmlRpc(String.valueOf(value)) + '</string>';
            }
        } else if (value instanceof Integer || value instanceof Double) {
            return '<int>' + String.valueOf(value) + '</int>';
        } else if (value instanceof Boolean) {
            return '<boolean>' + (String.valueOf(value) == 'true' ? 1 : 0) + '</boolean>';
        } else if (value instanceof Datetime) {
            return '<dateTime.iso8601>' + ((Datetime)value).formatGmt('yyyy-MM-dd\'T\'HH:mm:ss') + '</dateTime.iso8601>';
        } else if (value instanceof Map<String, Object>) {
            return getStructXmlRpcString((Map<String, Object>) value);
        } else if (value instanceof List<Object>) {
            return getArrayXmlRpcString((List<Object>) value);
        } else if (value == null) {
            return '<nil />';
        }
        system.debug( 'Heap size is ' + limits.getHeapSize() + ' enforced is ' + limits.getLimitHeapSize());
    
        return '';
    }

    private static String getStructXmlRpcString(Map<String, Object> struct) {
        system.debug( 'Heap size is ' + limits.getHeapSize() + ' enforced is ' + limits.getLimitHeapSize());
        String xmlRpcString = '<struct>';
        for (String key : struct.keySet()) {
            Object value = struct.get(key);

            system.debug( 'Heap size is ' + limits.getHeapSize() + ' enforced is ' + limits.getLimitHeapSize());

            
            xmlRpcString += '<member>';
            xmlRpcString += '<name>' + escapeXmlRpc(key) + '</name>';
            xmlRpcString += '<value>' + getValueXmlRpcString(value) + '</value>';
            xmlRpcString += '</member>';
            system.debug( 'Heap size is ' + limits.getHeapSize() + ' enforced is ' + limits.getLimitHeapSize());
        }
        xmlRpcString += '</struct>';
        return xmlRpcString;
    }
    

    private static String getArrayXmlRpcString(List<Object> jsonArray) {
        system.debug( 'Heap size is ' + limits.getHeapSize() + ' enforced is ' + limits.getLimitHeapSize());
        String xmlRpcString = '<array><data>';

        for (Object value : jsonArray) {
            system.debug( 'Heap size is ' + limits.getHeapSize() + ' enforced is ' + limits.getLimitHeapSize());
            xmlRpcString += '<value>' + getValueXmlRpcString(value) + '</value>';
            system.debug( 'Heap size is ' + limits.getHeapSize() + ' enforced is ' + limits.getLimitHeapSize());
        }

        xmlRpcString += '</data></array>';
        system.debug( 'Heap size is ' + limits.getHeapSize() + ' enforced is ' + limits.getLimitHeapSize());

        return xmlRpcString;
    }

    private static String escapeXmlRpc(String input) {
        system.debug( 'Heap size is ' + limits.getHeapSize() + ' enforced is ' + limits.getLimitHeapSize());
        if (input != null) {
            input = input.replace('&', '&amp;');
            input = input.replace('<', '&lt;');
            input = input.replace('>', '&gt;');
            input = input.replace('"', '&quot;');
            input = input.replace('\'', '&apos;');
        } else {
            input = '';
        }
        system.debug( 'Heap size is ' + limits.getHeapSize() + ' enforced is ' + limits.getLimitHeapSize());
        return input;
    }

    public static String generateXMLRPCMethodString(String methodName, String xxx) {
        system.debug( 'Heap size is ' + limits.getHeapSize() + ' enforced is ' + limits.getLimitHeapSize());
        String xmlString = '<?xml version=\'1.0\'?>' +
                            '<methodCall>' +
                            '    <methodName>' + methodName + '</methodName>' +
                            '    <params>' +
                            '        <param>' +
                            '            <value>' +
                            '                <string>' + xxx + '</string>' +
                            '            </value>' +
                            '        </param>' +
                            '    </params>' +
                            '</methodCall>';
        system.debug( 'Heap size is ' + limits.getHeapSize() + ' enforced is ' + limits.getLimitHeapSize());
        return xmlString;
    }
    
    
}