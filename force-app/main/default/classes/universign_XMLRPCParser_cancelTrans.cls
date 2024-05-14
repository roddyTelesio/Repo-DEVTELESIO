/**
 * @description       : Parse XML-RPC responses for cancelling transactions
 * @last modified on  : 08-23-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class universign_XMLRPCParser_cancelTrans {
    public static CancelTransactionResponse parseXMLRPCString(String xmlString) {
        System.debug('Parsing XML-RPC String:\n' + xmlString);
    
        CancelTransactionResponse response = new CancelTransactionResponse();
    
        Dom.Document doc = new Dom.Document();
        doc.load(xmlString);
    
        Dom.XmlNode root = doc.getRootElement();
    
        Dom.XmlNode faultNode = root.getChildElement('fault', null);
        if (faultNode != null) {
            Dom.XmlNode valueNode = faultNode.getChildElement('value', null);
            if (valueNode != null && valueNode.getChildElement('struct', null) != null) {
                response = parseFaultResponse(valueNode.getChildElement('struct', null));
            }
        } else {
            Dom.XmlNode paramsNode = root.getChildElement('params', null);
            Dom.XmlNode paramNode = paramsNode.getChildElement('param', null);
            Dom.XmlNode valueNode1 = paramNode.getChildElement('value', null);
            
            if (valueNode1 != null) {
                Dom.XmlNode i4Node = valueNode1.getChildElement('i4', null);
                if (i4Node != null) {
                    response.faultCode = Integer.valueOf(i4Node.getText());
                    System.debug('Fault Code: ' + response.faultCode);
                }
            }
        }
    
        return response;
    }
    
    private static CancelTransactionResponse parseFaultResponse(Dom.XmlNode structNode) {
        CancelTransactionResponse response = new CancelTransactionResponse();
        for (Dom.XmlNode memberNode : structNode.getChildElements()) {
            String memberName = memberNode.getChildElement('name', null).getText();
            Dom.XmlNode valueNode = memberNode.getChildElement('value', null);
    
            if (memberName == 'faultCode') {
                if (valueNode != null && valueNode.getChildElement('int', null) != null) {
                    response.faultCode = Integer.valueOf(valueNode.getChildElement('int', null).getText());
                    System.debug('Fault Code: ' + response.faultCode);
                }
            } else if (memberName == 'faultString') {
                if (valueNode != null && valueNode.getChildElement('string', null) != null) {
                    response.faultString = valueNode.getChildElement('string', null).getText();
                    System.debug('Fault String: ' + response.faultString);
                }
            }
        }
        return response;
    }
    
    public class CancelTransactionResponse {
        public Integer faultCode { get; set; }
        public String faultString { get; set; }
    
        public CancelTransactionResponse() {
            faultCode = -1;
            faultString = '';
        }
    }
    
}