/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 08-02-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class universign_XMLRPCParser {
    public class RPCResponse {
        public String id { get; set; }
        public String url { get; set; }
        public Integer faultCode { get; set; }
        public String faultString { get; set; }
    }
    
    public static RPCResponse parseXMLRPCString(String xmlString) {
        RPCResponse response = new RPCResponse();
        
        Dom.Document doc = new Dom.Document();
        doc.load(xmlString);
        
        Dom.XmlNode root = doc.getRootElement();
        
        // Check if the response is a fault (error)
        Dom.XmlNode faultNode = root.getChildElement('fault', null);
        if (faultNode != null) {
            Dom.XmlNode faultStruct = faultNode.getChildElement('value', null).getChildElement('struct', null);
            response.faultCode = Integer.valueOf(faultStruct.getChildElement('member', null).getChildElement('value', null).getChildElement('int', null).getText());
            response.faultString = faultStruct.getChildElement('member', null).getChildElement('value', null).getChildElement('string', null).getText();
            System.debug('Error - Fault Code: ' + response.faultCode);
            System.debug('Error - Fault String: ' + response.faultString);
        } else {
            // Extract id and url for success response
            Dom.XmlNode paramsNode = root.getChildElement('params', null);
            Dom.XmlNode paramNode = paramsNode.getChildElement('param', null);
            Dom.XmlNode structNode = paramNode.getChildElement('value', null).getChildElement('struct', null);
            
            for (Dom.XmlNode memberNode : structNode.getChildElements()) {
                String memberName = memberNode.getChildElement('name', null).getText();
                String memberValue = memberNode.getChildElement('value', null).getChildElement('string', null).getText();
                
                if (memberName == 'id') {
                    response.id = memberValue;
                    System.debug('ID: ' + response.id);
                } else if (memberName == 'url') {
                    response.url = memberValue;
                    System.debug('URL: ' + response.url);
                }
            }
        }
        
        return response;
    }
}