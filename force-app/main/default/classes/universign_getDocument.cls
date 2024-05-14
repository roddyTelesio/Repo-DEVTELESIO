/*
* @author:      Azhar Nahoor
* @created:     24/07/2023
* @description: Invocable Apex class used in flow Universign signed document
*/
public without sharing class universign_getDocument{

    public class ObjectContext {     
        @InvocableVariable(required=true label='universign transaction' )
        public Universign_Transaction__c universignTransaction;
    }


    public class Result {
        @InvocableVariable(required=false label='Is Success ?')
        public Boolean isSuccess;

        @InvocableVariable(required=false label='Error Message')
        public String errorMsg;

        @InvocableVariable(required=false label='Signed document (Content version Id)')
        public String contentVersionId;

        public Result(Boolean isSuccess, String errorMsg){
            this.isSuccess = isSuccess;
            this.errorMsg = errorMsg;
        }


        public Result(Boolean isSuccess, String errorMsg, String contentVersionId){
            this.isSuccess = isSuccess;
            this.errorMsg = errorMsg;
            this.contentVersionId = contentVersionId;
        }
    }

    /***
    * @description	Method to prepare & do callout to book a b2g appointment
    * @param	    obj 
    * @return		List<Slots> 
    * @exception   	None
    ***/   
    @InvocableMethod(label='[Universign] get document' description='Make WS callout to Universign to get ' callout=true)
    public static List<Result> getTransactionDoc(List<ObjectContext> obj) {
        Universign_Transaction__c univTransaction  = new Universign_Transaction__c();
        univTransaction = obj[0].universignTransaction;

        try{
            System.debug(LoggingLevel.DEBUG, 'getTransactionDoc START with : ' + obj);

            String                    contentVersionId = null;

            String endpointUrl = 'callout:universign/sign/rpc/';
            String methodName  =   'requester.getDocuments';
            String xmlRpcString = XmlRpcGenerator.generateXMLRPCMethodString(methodName, univTransaction.transactionId__c);

            System.debug('xmlRpcString: ' + xmlRpcString);
    
            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpointUrl);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'text/xml');
            req.setBody(xmlRpcString);
            Http http = new Http();
            HttpResponse response = http.send(req);
    
            // Retrieve the response body
            String responseBody = response.getBody();
            System.debug('response body: '  + response.getBody());
    
            //Call the method to parse the XML-RPC string
            universign_XMLRPCParser_getDocs.DocumentInfo documentInfo = universign_XMLRPCParser_getDocs.parseXMLRPCString(response.getBody());

            System.debug('Meta Data: ' + documentInfo.metaData);
            System.debug('File Name: ' + documentInfo.fileName);
            System.debug('Document Type: ' + documentInfo.documentType);
            System.debug('Display Name: ' + documentInfo.displayName);
            System.debug('Name: ' + documentInfo.name);
            System.debug('Check Box Texts: ' + documentInfo.checkBoxTexts);
            System.debug('ID: ' + documentInfo.id);
            System.debug('Title: ' + documentInfo.title);
            // Note: You may want to avoid printing the Blob content directly using System.debug due to its size.

            if(documentInfo.content != null){
                System.debug('content not null');
                contentVersionId = createContentDocument(documentInfo.content, documentInfo.fileName, univTransaction.agreement__c);
            }else{
                universign_sendTransaction.createUniversignEventLog(String.valueOf(univTransaction.Id), 'universign_getDocument', String.valueOf(response.getStatus()), 'ERROR', req.getBody() , (response.getBody()).left(100000));
                return new List<Result>{ new Result(false, 'No content found')};
            }

            universign_sendTransaction.createUniversignEventLog(String.valueOf(univTransaction.Id), 'universign_getDocument', String.valueOf(response.getStatus()), 'SUCCESS', req.getBody() , (response.getBody()).left(100000));
            return new List<Result>{ new Result(true, null, contentVersionId)};
        }catch(Exception e){
            System.debug('Exception  : ' + e.getMessage());
            universign_sendTransaction.createUniversignEventLog(String.valueOf(univTransaction.Id), 'universign_getDocument', null, (e.getMessage()).left(250), 'NOT_SET', e.getStackTraceString());
            return new List<Result>{ new Result(false, e.getMessage())};
        }
    }

    public static string createContentDocument(Blob content, String fileName, String agreementId) {
        System.debug('createContentDocument START');
        ContentVersion contentVersion = new ContentVersion();
        contentVersion.Title = 'Signed_' + fileName;
        contentVersion.VersionData = content;
        contentVersion.PathOnClient = 'Signed_' + fileName;
        contentVersion.Origin = 'H';
        contentVersion.UniversignSignedDoc__c = true;

        insert contentVersion;

        String contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id].ContentDocumentId;

        // ContentDocumentLink cdl = new ContentDocumentLink();
        // cdl.LinkedEntityId = UserInfo.getUserId();
        // cdl.ContentDocumentId = contentDocumentId;
        // cdl.ShareType = 'V';

        ContentDocumentLink cdl2 = new ContentDocumentLink();
        cdl2.LinkedEntityId = agreementId;
        cdl2.ContentDocumentId = contentDocumentId;
        // cdl2.ShareType = 'V';

        insert new List<ContentDocumentLink>{cdl2};
        System.debug('createContentDocument END');
        return contentVersion.Id;
    }
}