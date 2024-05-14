/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 08-08-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class universign_XMLRPCParser_getDocs {
    public class DocumentInfo {
        public MetaData metaData { get; set; }
        public String fileName { get; set; }
        public String documentType { get; set; }
        public String displayName { get; set; }
        public String name { get; set; }
        public List<String> checkBoxTexts { get; set; }
        public Integer id { get; set; }
        public String title { get; set; }
        public Blob content { get; set; }
    }

    public class MetaData {
        public String key1 { get; set; }
        public Integer key2 { get; set; }
        public Integer pages { get; set; }
        public Integer size { get; set; }
        public Boolean key3 { get; set; }
    }

    public static DocumentInfo parseXMLRPCString(String xmlString) {
        System.debug('Parsing XML-RPC String:\n' + xmlString);
        
        DocumentInfo documentInfo = new DocumentInfo();

        Dom.Document doc = new Dom.Document();
        doc.load(xmlString);

        Dom.XmlNode root = doc.getRootElement();
        
        System.debug('Root Element Name: ' + root.getName());

        // Extract id and url for success response
        // Dom.XmlNode paramsNode = root.getChildElement('params', null);
        // System.debug('paramsNode : ' + paramsNode);

        // Dom.XmlNode paramNode = paramsNode.getChildElement('param', null);
        // System.debug('paramNode : ' + paramNode);

        // System.debug('paramNode child elements : ' + paramNode.getChildElements());

        // Dom.XmlNode valueNode1 = paramNode.getChildElement('value', null);
        // System.debug('valueNode : ' + valueNode1);     

        // System.debug('valueNode child elements : ' + valueNode1.getChildElements());

        // Dom.XmlNode structNode = valueNode1.getChildElement('value', null);
        // System.debug('structNode : ' + structNode);     

        //Dom.XmlNode structNode = paramNode.getChildElement('value', null).getChildElement('struct', null);

        System.debug('Root Element Name: ' + root.getName());

        // Extract id and url for success response
        Dom.XmlNode paramsNode = root.getChildElement('params', null);
        Dom.XmlNode paramNode = paramsNode.getChildElement('param', null);
        Dom.XmlNode valueNode1 = paramNode.getChildElement('value', null);
        System.debug('Value Node Name: ' + valueNode1.getName());
        
        Dom.XmlNode arrayNode = valueNode1.getChildElement('array', null);
        System.debug('Array Node Name: ' + arrayNode.getName());
        
        Dom.XmlNode dataNode = arrayNode.getChildElement('data', null);
        System.debug('Data Node Name: ' + dataNode.getName());
        
        Dom.XmlNode structNode = dataNode.getChildElement('value', null).getChildElement('struct', null);
        System.debug('Struct Node Name: ' + structNode.getName());

        for (Dom.XmlNode memberNode : structNode.getChildElements()) {
            String memberName = memberNode.getChildElement('name', null).getText();
            Dom.XmlNode valueNode = memberNode.getChildElement('value', null);
            
            System.debug('Member Name: ' + memberName);
            
            if (memberName == 'metaData') {
                if (valueNode != null && valueNode.getChildElement('struct', null) != null) {
                    System.debug('Parsing MetaData...');
                    documentInfo.metaData = parseMetaData(valueNode.getChildElement('struct', null));
                    System.debug('MetaData: ' + documentInfo.metaData);
                }
            } else if (memberName == 'fileName') {
                if (valueNode != null && valueNode.getChildElement('string', null) != null) {
                    documentInfo.fileName = valueNode.getChildElement('string', null).getText();
                    System.debug('File Name: ' + documentInfo.fileName);
                }
            } else if (memberName == 'documentType') {
                if (valueNode != null && valueNode.getChildElement('string', null) != null) {
                    documentInfo.documentType = valueNode.getChildElement('string', null).getText();
                    System.debug('Document Type: ' + documentInfo.documentType);
                }
            } else if (memberName == 'displayName') {
                if (valueNode != null && valueNode.getChildElement('string', null) != null) {
                    documentInfo.displayName = valueNode.getChildElement('string', null).getText();
                    System.debug('Display Name: ' + documentInfo.displayName);
                }
            } else if (memberName == 'name') {
                if (valueNode != null && valueNode.getChildElement('string', null) != null) {
                    documentInfo.name = valueNode.getChildElement('string', null).getText();
                    System.debug('Name: ' + documentInfo.name);
                }
            } else if (memberName == 'checkBoxTexts') {
                if (valueNode != null && valueNode.getChildElement('array', null) != null) {
                    System.debug('Parsing CheckBoxTexts...');
                    documentInfo.checkBoxTexts = parseCheckBoxTexts(valueNode.getChildElement('array', null));
                    System.debug('CheckBoxTexts: ' + documentInfo.checkBoxTexts);
                }
            } else if (memberName == 'id') {
                if (valueNode != null && valueNode.getChildElement('i4', null) != null) {
                    documentInfo.id = Integer.valueOf(valueNode.getChildElement('i4', null).getText());
                    System.debug('ID: ' + documentInfo.id);
                }
            } else if (memberName == 'title') {
                if (valueNode != null && valueNode.getChildElement('string', null) != null) {
                    documentInfo.title = valueNode.getChildElement('string', null).getText();
                    System.debug('Title: ' + documentInfo.title);
                }
            } else if (memberName == 'content') {
                if (valueNode != null && valueNode.getChildElement('base64', null) != null) {
                    System.debug('Parsing Content...');
                    String base64Content = valueNode.getChildElement('base64', null).getText();
                    documentInfo.content = EncodingUtil.base64Decode(base64Content.trim()); // Remove leading/trailing whitespace
                    System.debug('Content Size: ' + documentInfo.content.size() + ' bytes');
                }
            }
        }

        return documentInfo;
    }

    private static MetaData parseMetaData(Dom.XmlNode structNode) {
        MetaData metaData = new MetaData();
        for (Dom.XmlNode memberNode : structNode.getChildElements()) {
            String memberName = memberNode.getChildElement('name', null).getText();
            Dom.XmlNode memberValueNode = memberNode.getChildElement('value', null);
            
            System.debug('MetaData - Member Name: ' + memberName);

            if (memberName == 'key1') {
                if (memberValueNode != null && memberValueNode.getChildElement('string', null) != null) {
                    metaData.key1 = memberValueNode.getChildElement('string', null).getText();
                    System.debug('MetaData - Key 1: ' + metaData.key1);
                }
            } else if (memberName == 'key2') {
                if (memberValueNode != null && memberValueNode.getChildElement('i4', null) != null) {
                    metaData.key2 = Integer.valueOf(memberValueNode.getChildElement('i4', null).getText());
                    System.debug('MetaData - Key 2: ' + metaData.key2);
                }
            } else if (memberName == 'pages') {
                if (memberValueNode != null && memberValueNode.getChildElement('i4', null) != null) {
                    metaData.pages = Integer.valueOf(memberValueNode.getChildElement('i4', null).getText());
                    System.debug('MetaData - Pages: ' + metaData.pages);
                }
            } else if (memberName == 'size') {
                if (memberValueNode != null && memberValueNode.getChildElement('i4', null) != null) {
                    metaData.size = Integer.valueOf(memberValueNode.getChildElement('i4', null).getText());
                    System.debug('MetaData - Size: ' + metaData.size);
                }
            } else if (memberName == 'key3') {
                if (memberValueNode != null && memberValueNode.getChildElement('boolean', null) != null) {
                    metaData.key3 = memberValueNode.getChildElement('boolean', null).getText() == '1';
                    System.debug('MetaData - Key 3: ' + metaData.key3);
                }
            }
        }
        return metaData;
    }
    
    private static List<String> parseCheckBoxTexts(Dom.XmlNode arrayNode) {
        List<String> checkBoxTexts = new List<String>();
        for (Dom.XmlNode valueNode : arrayNode.getChildElement('data', null).getChildElements()) {
            if (valueNode != null && valueNode.getChildElement('string', null) != null) {
                checkBoxTexts.add(valueNode.getChildElement('string', null).getText());
            }
        }
        return checkBoxTexts;
    }
}