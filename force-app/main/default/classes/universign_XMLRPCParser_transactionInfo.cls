/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 08-07-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class universign_XMLRPCParser_transactionInfo {
    public class TransactionInfo {
        public List<SignerInfo> signerInfos { get; set; }
        public Integer currentSigner { get; set; }
        public Boolean eachField { get; set; }
        public Datetime creationDate { get; set; }
        public List<Object> signerCertificates { get; set; }
        public InitiatorInfo initiatorInfo { get; set; }
        public String transactionId { get; set; }
        public String status { get; set; }
    }

    public class SignerInfo {
        public String firstName { get; set; }
        public String lastName { get; set; }
        public String id { get; set; }
        public String url { get; set; }
        public String email { get; set; }
        public String status { get; set; }
        public Datetime actionDate { get; set; }
        public String refusalComment { get; set; }

    }

    public class InitiatorInfo {
        public String firstName { get; set; }
        public String lastName { get; set; }
        public String email { get; set; }
    }

    public static TransactionInfo parseXMLRPCString(String xmlString) {
        TransactionInfo transactionInfo = new TransactionInfo();

        Dom.Document doc = new Dom.Document();
        doc.load(xmlString);

        Dom.XmlNode root = doc.getRootElement();

        // Check if the response is a fault (error)
        Dom.XmlNode faultNode = root.getChildElement('fault', null);
        if (faultNode != null) {
            Dom.XmlNode faultStruct = faultNode.getChildElement('value', null).getChildElement('struct', null);
            Integer faultCode = Integer.valueOf(faultStruct.getChildElement('member', null).getChildElement('value', null).getChildElement('int', null).getText());
            String faultString = faultStruct.getChildElement('member', null).getChildElement('value', null).getChildElement('string', null).getText();
            System.debug('Error - Fault Code: ' + faultCode);
            System.debug('Error - Fault String: ' + faultString);
        } else {
            // Extract id and url for success response
            Dom.XmlNode paramsNode = root.getChildElement('params', null);
            Dom.XmlNode paramNode = paramsNode.getChildElement('param', null);
            Dom.XmlNode structNode = paramNode.getChildElement('value', null).getChildElement('struct', null);

            for (Dom.XmlNode memberNode : structNode.getChildElements()) {
                String memberName = memberNode.getChildElement('name', null).getText();
                Dom.XmlNode valueNode = memberNode.getChildElement('value', null);

                if (memberName == 'signerInfos') {
                    if (valueNode != null && valueNode.getChildElement('array', null) != null) {
                        transactionInfo.signerInfos = parseSignerInfos(valueNode.getChildElement('array', null));
                    }
                } else if (memberName == 'currentSigner') {
                    if (valueNode != null && valueNode.getChildElement('i4', null) != null) {
                        transactionInfo.currentSigner = Integer.valueOf(valueNode.getChildElement('i4', null).getText());
                    }
                } else if (memberName == 'eachField') {
                    if (valueNode != null && valueNode.getChildElement('boolean', null) != null) {
                        transactionInfo.eachField = valueNode.getChildElement('boolean', null).getText() == '1';
                    }
                } else if (memberName == 'creationDate') {
                    if (valueNode != null && valueNode.getChildElement('dateTime.iso8601', null) != null) {
                        String dateTimeStr = valueNode.getChildElement('dateTime.iso8601', null).getText();
                        transactionInfo.creationDate = parseIso8601DateTime(dateTimeStr);
                    }
                } else if (memberName == 'signerCertificates') {
                    if (valueNode != null && valueNode.getChildElement('array', null) != null) {
                        transactionInfo.signerCertificates = valueNode.getChildElement('array', null).getChildElement('data', null).getChildElements();
                    }
                } else if (memberName == 'initiatorInfo') {
                    if (valueNode != null && valueNode.getChildElement('struct', null) != null) {
                        transactionInfo.initiatorInfo = parseInitiatorInfo(valueNode.getChildElement('struct', null));
                    }
                } else if (memberName == 'transactionId') {
                    if (valueNode != null && valueNode.getChildElement('string', null) != null) {
                        transactionInfo.transactionId = valueNode.getChildElement('string', null).getText();
                    }
                } else if (memberName == 'status') {
                    if (valueNode != null && valueNode.getChildElement('string', null) != null) {
                        transactionInfo.status = valueNode.getChildElement('string', null).getText();
                    }
                }
            }
        }

        return transactionInfo;
    }

    private static List<SignerInfo> parseSignerInfos(Dom.XmlNode arrayNode) {
        List<SignerInfo> signerInfos = new List<SignerInfo>();
        for (Dom.XmlNode valueNode : arrayNode.getChildElement('data', null).getChildElements()) {
            if (valueNode != null && valueNode.getChildElement('struct', null) != null) {
                SignerInfo signerInfo = new SignerInfo();
                for (Dom.XmlNode memberNode : valueNode.getChildElement('struct', null).getChildElements()) {
                    String memberName = memberNode.getChildElement('name', null).getText();
                    Dom.XmlNode memberValueNode = memberNode.getChildElement('value', null);

                    if (memberName == 'firstName') {
                        if (memberValueNode != null && memberValueNode.getChildElement('string', null) != null) {
                            signerInfo.firstName = memberValueNode.getChildElement('string', null).getText();
                        }
                    } else if (memberName == 'lastName') {
                        if (memberValueNode != null && memberValueNode.getChildElement('string', null) != null) {
                            signerInfo.lastName = memberValueNode.getChildElement('string', null).getText();
                        }
                    } else if (memberName == 'id') {
                        if (memberValueNode != null && memberValueNode.getChildElement('string', null) != null) {
                            signerInfo.id = memberValueNode.getChildElement('string', null).getText();
                        }
                    } else if (memberName == 'url') {
                        if (memberValueNode != null && memberValueNode.getChildElement('string', null) != null) {
                            signerInfo.url = memberValueNode.getChildElement('string', null).getText();
                        }
                    } else if (memberName == 'email') {
                        if (memberValueNode != null && memberValueNode.getChildElement('string', null) != null) {
                            signerInfo.email = memberValueNode.getChildElement('string', null).getText();
                        }
                    } else if (memberName == 'status') {
                        if (memberValueNode != null && memberValueNode.getChildElement('string', null) != null) {
                            signerInfo.status = memberValueNode.getChildElement('string', null).getText();
                        }
                    }else if (memberName == 'actionDate') {
                        if (memberValueNode != null && memberValueNode.getChildElement('dateTime.iso8601', null) != null) {
                            String dateTimeStr = memberValueNode.getChildElement('dateTime.iso8601', null).getText();
                            signerInfo.actionDate = parseIso8601DateTime(dateTimeStr);
                        }
                    }else if (memberName == 'refusalComment') {
                        if (memberValueNode != null && memberValueNode.getChildElement('string', null) != null) {
                            signerInfo.refusalComment = memberValueNode.getChildElement('string', null).getText();
                        }
                    }
                
                }
                signerInfos.add(signerInfo);
            }
        }
        return signerInfos;
    }

    private static InitiatorInfo parseInitiatorInfo(Dom.XmlNode structNode) {
        InitiatorInfo initiatorInfo = new InitiatorInfo();
        for (Dom.XmlNode memberNode : structNode.getChildElements()) {
            String memberName = memberNode.getChildElement('name', null).getText();
            Dom.XmlNode memberValueNode = memberNode.getChildElement('value', null);

            if (memberName == 'firstName') {
                if (memberValueNode != null && memberValueNode.getChildElement('string', null) != null) {
                    initiatorInfo.firstName = memberValueNode.getChildElement('string', null).getText();
                }
            } else if (memberName == 'lastName') {
                if (memberValueNode != null && memberValueNode.getChildElement('string', null) != null) {
                    initiatorInfo.lastName = memberValueNode.getChildElement('string', null).getText();
                }
            } else if (memberName == 'email') {
                if (memberValueNode != null && memberValueNode.getChildElement('string', null) != null) {
                    initiatorInfo.email = memberValueNode.getChildElement('string', null).getText();
                }
            }
        }
        return initiatorInfo;
    }
    
    private static DateTime parseIso8601DateTime(String dateTimeStr) {
        // Format: 20230802T17:51:54
        Integer year = Integer.valueOf(dateTimeStr.substring(0, 4));
        Integer month = Integer.valueOf(dateTimeStr.substring(4, 6));
        Integer day = Integer.valueOf(dateTimeStr.substring(6, 8));
        Integer hour = Integer.valueOf(dateTimeStr.substring(9, 11));
        Integer minute = Integer.valueOf(dateTimeStr.substring(12, 14));
        Integer second = Integer.valueOf(dateTimeStr.substring(15, 17));
        
        return DateTime.newInstanceGMT(year, month, day, hour, minute, second);
    }
}