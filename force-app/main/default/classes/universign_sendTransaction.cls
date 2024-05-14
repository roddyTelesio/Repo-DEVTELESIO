/*
* @author:      Azhar Nahoor
* @created:     24/07/2023
* @description: Invocable Apex class used in flow Universign to send transaction
*/
public without sharing class universign_sendTransaction{

    public class ObjectContext {     
        @InvocableVariable(required=true label='ContentVersions' )
        public List<sObject> contentVersions;

        @InvocableVariable(required=true label='List of Head Signatories, signers, observers' )
        public List<sObject> signatories;

        @InvocableVariable(required=false label='transaction' )
        public Universign_Transaction__c universignTransaction;

        @InvocableVariable(required=false label='Agreement type (Recordtype developername)' )
        public String  agreementType;

        @InvocableVariable(required=false label='Signature Page (Optional for acceptation)' )
        public Integer signaturePage;

        @InvocableVariable(required=false label='Total pages in doc' )
        public Integer countTotalPages;
    }


    public class Result {
        @InvocableVariable(required=false label='Is Success ?')
        public Boolean isSuccess;

        @InvocableVariable(required=false label='Response Body')
        public String responseBody;

        @InvocableVariable(required=false label='transaction Id')
        public String transactionId;

        public Result(Boolean isSuccess, String responseBody, String transactionId){
            this.isSuccess = isSuccess;
            this.responseBody = responseBody;
            this.transactionId = transactionId;
        }
    }

    /***
    * @description	Method to prepare & do callout to send universign transaction
    * @param	    obj 
    * @return		List<Result>
    * @exception   	None
    ***/   
    @InvocableMethod(label='[Universign] Send transaction' description='Make WS callout to Universign to send transaction' callout=true)
    public static List<Result> sendTransaction(List<ObjectContext> obj) {
        // System.debug(LoggingLevel.DEBUG, 'sendTransaction START with : ' + obj);

        system.debug('Heap size is ' + limits.getHeapSize() + ' enforced is ' + limits.getLimitHeapSize());

        try{

            String endpointUrl = 'callout:universign/sign/rpc/';
            String methodName  =   'requester.requestTransaction';
            Universign_Transaction__c universignTransaction           = new Universign_Transaction__c();
            Map<String, Object> params                                = new Map<String, Object>();
    
            universignTransaction = obj[0].universignTransaction;
            List<Object> signers = new List<Object>();
            List<Object> signatureFields = new List<Object>();

            system.debug('Heap size is ' + limits.getHeapSize() + ' enforced is ' + limits.getLimitHeapSize());

            // if(obj[0].observers != null && !obj[0].observers.isEmpty()){
            //     signers.addAll(getSigners(obj[0].observers, 'observer', universignTransaction));
            // }    

            if(obj[0].signatories != null && !obj[0].signatories.isEmpty()){
                signers.addAll(getSigners(obj[0].signatories, universignTransaction));
                signatureFields.addAll(getSignatureFields(obj[0].signatories, obj[0].agreementType, obj[0].signaturePage));
            }
    
            system.debug('Heap size is ' + limits.getHeapSize() + ' enforced is ' + limits.getLimitHeapSize());

    
            // System.debug(LoggingLevel.DEBUG, 'signers : ' + signers);
            // System.debug(LoggingLevel.DEBUG, 'signatureFields : ' + signatureFields);
    
    
            params.put('signers', signers);
            params.put('profile', universignTransaction.profile__c);
            params.put('mustContactFirstSigner', universignTransaction.mustContactFirstSigner__c);
            params.put('finalDocSent', universignTransaction.finalDocSent__c);
            params.put('finalDocRequesterSent', universignTransaction.finalDocRequesterSent__c);
            params.put('description',  obj[0].contentVersions[0].get('title'));
            //params.put('language', universignTransaction.language__c);
            params.put('language', 'en');
            params.put('chainingMode', universignTransaction.chainingMode__c);
            params.put('handwrittenSignatureMode', 0);
            params.put('documents', 'base64doc');

            // System.debug(LoggingLevel.DEBUG, 'params : ' + params);
    
            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpointUrl);
            req.setMethod('POST');
            req.setTimeout(120000);
            req.setHeader('Content-Type', 'text/xml');

            List<ContentVersion> cvs = obj[0].contentVersions;
            String contentDocId = cvs[0].ContentDocumentId;

            String xmlRPC_withoutDoc = XmlRpcGenerator.generateXmlRpcString('requester.requestTransaction', params, obj[0].contentVersions, signatureFields, obj[0].countTotalPages);
            // xmlRPC_withoutDoc = xmlRPC_withoutDoc.replace('placeholderbase64', getBase64doc(obj[0].contentVersions[0].contentDocumentId))
            req.setBody(xmlRPC_withoutDoc.replace('placeholderbase64', getBase64doc(contentDocId)));
            System.debug('xmlRPC_withoutDoc : ' + xmlRPC_withoutDoc);

            // system.debug('reqBody:' + req.getBody());
            system.debug('Heap size is ' + limits.getHeapSize() + ' enforced is ' + limits.getLimitHeapSize());

            Http http = new Http();
            HttpResponse response = http.send(req);

            system.debug('Heap size is ' + limits.getHeapSize() + ' enforced is ' + limits.getLimitHeapSize());

    
            // Retrieve the response body
            String responseBody = response.getBody();
            System.debug('response body: '  + response.getBody());

            system.debug('Heap size is ' + limits.getHeapSize() + ' enforced is ' + limits.getLimitHeapSize());

    
            universign_XMLRPCParser.RPCResponse resp = new universign_XMLRPCParser.RPCResponse();
            resp = universign_XMLRPCParser.parseXMLRPCString(response.getBody());
    
            System.debug('response id: '  + resp.id);
            System.debug('response url: '  + resp.url);
            System.debug('response faultCode: '  + resp.faultCode);
            System.debug('response faultString: '  + resp.faultString);
    
    
            System.debug('response status: '  + response.getStatusCode());
            System.debug('response status: '  + response.getStatus());
    
            if(resp.id != null){
                createUniversignEventLog(String.valueOf(universignTransaction.Id), 'universign_sendTransaction', String.valueOf(response.getStatusCode()), 'Success', 'NOT_SET', response.getBody());
                return new List<Result>{new Result(true, resp.url, resp.id)};
            }else{
                String errMsg = resp.faultCode + resp.faultString +  resp.faultString;
                String errMsgSubstring = errMsg.left(250);
                createUniversignEventLog(String.valueOf(universignTransaction.Id), 'universign_sendTransaction', String.valueOf(response.getStatusCode()), errMsgSubstring, 'NOT_SET', response.getBody());
                return new List<Result>{new Result(false, resp.faultCode + resp.faultString, resp.faultString)};
            }
        }catch(Exception e){
            Universign_Transaction__c universignTransaction = obj[0].universignTransaction;
            System.debug('response Exception: '  + e.getMessage() + '#' + e.getLineNumber());
            createUniversignEventLog(String.valueOf(universignTransaction.Id), 'universign_sendTransaction', null, (e.getMessage()).left(250), 'NOT_SET', e.getStackTraceString());
            return new List<Result>{new Result(false, e.getMessage(), null)};
        }
    }

    /***
    * @description	Method to prepare and get list of signers
    * @param	    List<Contact> signatories 
    * @param	    String signerType - signer or observer
    * @return		List<Object> signers 
    * @exception   	None
    ***/  
    public static List<Object> getSigners(List<sObject> signers, Universign_Transaction__c u){
        System.debug(LoggingLevel.DEBUG, 'getSigners START ');
        List<Object> lstSigners = new List<Object>();

        System.debug(LoggingLevel.DEBUG, 'getSigners END adding contacts');
        for(sObject o : signers){
            Map<String, Object> signer = new Map<String, Object>();
            signer.put('firstname', o.get('FirstName__c'));
            signer.put('lastname', o.get('LastName__c'));
            signer.put('emailAddress', o.get('Email__c'));
            if(o.get('Phone__c') != null){signer.put('phoneNum', o.get('Phone__c'));}
            signer.put('successURL', u.successURL__c);
            signer.put('cancelURL', u.cancelURL__c);
            signer.put('failURL', u.failURL__c);
            signer.put('certificateType', u.certificateType__c);
            signer.put('role',  o.get('role__c'));
            signer.put('identificationType', 'email');//or sms
            signer.put('invitationMessage', u.invitationMessage__c);
            signer.put('handwrittenSignatureMode', 0);
            lstSigners.add(signer);
        }

        System.debug(LoggingLevel.DEBUG, 'getSigners END with ' + signers.size() + ' signers');

        return lstSigners;
    }

        /***
    * @description	Method to prepare and get list of signers
    * @param	    List<Contact> signers 
    * @return		List<Object> signatoryFields 
    * @exception   	None
    ***/  
    public static List<Object> getSignatureFields(List<sObject> signers, String agreementType, Integer totalPageNum){
        // System.debug(LoggingLevel.DEBUG, 'getSignatureFields START ');
        List<Object> signatureFields = new List<Object>();

        //Get custom metadata for signer positions
        Map<Double, Universign_signerPosition__mdt> signerPositionMap = new Map<Double, Universign_signerPosition__mdt>();

        // Query the custom metadata records
        List<Universign_signerPosition__mdt> signerPositions = [
            SELECT Id, SignerNumber__c, xCoordinate__c, yCoordinate__c
            FROM Universign_signerPosition__mdt
        ];

        // Populate the map
        for (Universign_signerPosition__mdt signerPosition : signerPositions) {
            signerPositionMap.put(signerPosition.SignerNumber__c, signerPosition);
        }
        // System.debug(LoggingLevel.DEBUG, 'signerPositionMap ' + signerPositionMap);

        Integer signaturePageNumber = -1; // -1 : last page
        if(totalPageNum != null){
            signaturePageNumber = totalPageNum;
        }

        Integer signerSize = 0;
        for(Integer i = 0; i < signers.size(); i++){
            sObject o = signers[i];
            if(o.get('role__c') != null && o.get('role__c') == 'observer'){
                continue;
            }
            signerSize = signerSize + 1;
        }

        Double signerIndex = 0;
        for(Integer i = 0; i < signers.size(); i++){

            sObject o = signers[i];
            if(o.get('role__c') != null && o.get('role__c') == 'observer'){
                continue;
            }
            signerIndex = signerIndex + 1;
            System.debug(LoggingLevel.DEBUG, 'getSignatureFields signerIndex ' + signerIndex);

            Map<String, Object> signatureField = new Map<String, Object>();
            //double keyVal = i+1;
            signatureField.put('page', getSignerPage(Integer.valueOf(signerIndex), signerSize, Integer.valueOf(signaturePageNumber)));
            signatureField.put('x', signerPositionMap.get(signerIndex).xCoordinate__c != null ? Integer.valueOf(signerPositionMap.get(signerIndex).xCoordinate__c) : 100);
            signatureField.put('y', signerPositionMap.get(signerIndex).yCoordinate__c != null ? Integer.valueOf(signerPositionMap.get(signerIndex).yCoordinate__c) : 100);
            signatureField.put('signerIndex', i);
            // signatureField.put('label', '[WORDING NAME – LINE 1]');
            signatureFields.add(signatureField);
        }
        System.debug(LoggingLevel.DEBUG, 'getSignatureFields END with ' + signatureFields.size() +' fields  : ' + signatureFields);

        return signatureFields;
    }

    /***
    * @description	Method to prepare and get list of documents as base64 characters
    * @param	    List<Contact> signatories 
    * @return		List<Object> signers 
    * @exception   	None
    ***/  
    public static List<Object> getDocsBase64(List<sObject> contentVersions, List<Object> signers, Integer countTotalPages){
        // System.debug(LoggingLevel.DEBUG, 'getDocsBase64 START  with ' + contentVersions + ' signers: ' + signers);
        List<Object> docs = new List<Object>();

        for(ContentVersion doc : (List<ContentVersion>) contentVersions){
            Map<String, Object> document = new Map<String, Object>();

            //Init metadata .. What'sthat ?
            Map<String, Object> metaData = new Map<String, Object>();
            metaData.put('key1', 'string value');
            metaData.put('key2', 1);
            metaData.put('key3', true);
            document.put('metaData', metaData);

            //Initialise consentement checkboxses
            List<Object> checkBoxTexts = new List<Object>();
            checkBoxTexts.add('I have read and I accept the above document of “' + countTotalPages + '” page(s)');
            checkBoxTexts.add('Case de consentement 2');
            // checkBoxTexts.add(''); // Empty string as per your example
            document.put('checkBoxTexts', checkBoxTexts);


            document.put('title', doc.Title);
            document.put('documentType', 'pdf');
            document.put('content', '<base64>' + getBase64docDummy(doc.ContentDocumentId) +  '</base64>'); 
            document.put('fileName', doc.Title);
            document.put('signatureFields', signers);
            
            docs.add(document);
        }
        // System.debug(LoggingLevel.DEBUG, 'getDocsBase64 END with ' + docs.size() + ' docs');

        return docs;
    }

    /***
    * @description	Method to prepare and get list of documents as base64 characters
    * @param	    String contentDocumentId
    * @return		String content in base64
    * @exception   	None
    ***/  
    @AuraEnabled(cacheable=false)
    public static String getBase64docDummy(String contentDocumentId){   
        // System.debug('getBase64doc START with contentDocumentId: ' + contentDocumentId);      

        // Step 1: Query ContentVersion
        //List<ContentVersion> contentVersions = [SELECT VersionData FROM ContentVersion WHERE ContentDocumentId = :contentDocumentId];

        // if (!contentVersions.isEmpty()) {
            return 'placeholderbase64';
        // } else {
        //     // System.debug('getBase64doc contentVersions not found ');      
        //     return null;
        // }
    }

        /***
    * @description	Method to prepare and get list of documents as base64 characters
    * @param	    String contentDocumentId
    * @return		String content in base64
    * @exception   	None
    ***/  
    @AuraEnabled(cacheable=false)
    public static String getBase64doc(String contentDocumentId){   
        // System.debug('getBase64doc START with contentDocumentId: ' + contentDocumentId);      

        // Step 1: Query ContentVersion
        //List<ContentVersion> contentVersions = [SELECT VersionData FROM ContentVersion WHERE ContentDocumentId = :contentDocumentId];

        // if (!contentVersions.isEmpty()) {
            return EncodingUtil.base64Encode([SELECT VersionData FROM ContentVersion WHERE ContentDocumentId = :contentDocumentId][0].VersionData);
        // } else {
        //     // System.debug('getBase64doc contentVersions not found ');      
        //     return null;
        // }
    }


    /***
    * @description	Method to prepare and get list of documents as base64 characters
    * @param	    Integer SignerIndex
    * @param	    Integer SignerSize
    * @param	    Integer totalPageNumber
    * @return		pageNumber for signer
    * @exception   	None
    ***/ 
    public static Integer getSignerPage(Integer SignerIndex, Integer SignerSize, Integer totalPageNumber) {
        Integer result = totalPageNumber; // Default value is totalPageNumber

        if (SignerIndex >= 1 && SignerIndex <= 4) {
            if (SignerSize < 5) {
                result = totalPageNumber;
            } else if (SignerSize >= 5 && SignerSize <= 10) {
                result = totalPageNumber - 1;
            } else if (SignerSize >= 11 && SignerSize <= 15) {
                result = totalPageNumber - 2;
            }
        } else if (SignerIndex >= 5 && SignerIndex <= 10) {
            if (SignerSize >= 5 && SignerSize <= 10) {
                result = totalPageNumber;
            } else if (SignerSize >= 11 && SignerSize <= 15) {
                result = totalPageNumber - 2;
            }
        } else if (SignerIndex >= 11 && SignerIndex <= 15) {
            if (SignerSize >= 11 && SignerSize <= 15) {
                result = totalPageNumber;
            }
        }

        return result;
    }

    public static void createUniversignEventLog(String recordId, String className, String statusCode, String message, String request, String response){
        EventLog__c eventLog = new EventLog__c();
        eventLog.Context__c = 'Universign';
        eventLog.RecordId__c = recordId;
        eventLog.ClassName__c = className;
        eventLog.StatusCode__c = statusCode;
        eventLog.Message__c = message;
        eventLog.Request__c = request;
        eventLog.response__c = response;
        eventLog.type__c = 'Callout';
        // event.StackTrace__c = 
        insert eventLog;
    }
    
}