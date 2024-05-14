/*
* @author:      Azhar Nahoor
* @created:     23/08/2023
* @description: Invocable Apex class used in flow Universign to cancel a transaction
*/
public without sharing class universign_cancelTransaction{

    public class ObjectContext {     
        @InvocableVariable(required=true label='universign transaction' )
        public Universign_Transaction__c universignTransaction;
    }


    public class Result {
        @InvocableVariable(required=false label='Is Success ?')
        public Boolean isSuccess;

        @InvocableVariable(required=false label='Error Message')
        public String errorMsg;

        public Result(Boolean isSuccess, String errorMsg){
            this.isSuccess = isSuccess;
            this.errorMsg = errorMsg;
        }
    }

    /***
    * @description	Method to prepare & do callout to book a b2g appointment
    * @param	    obj 
    * @return		List<Slots> 
    * @exception   	None
    ***/   
    @InvocableMethod(label='[Universign] cancel transactioon' description='Make WS callout to Cancel Universign transaction' callout=true)
    public static List<Result> cancelTransaction(List<ObjectContext> obj) {

        try{
            System.debug(LoggingLevel.DEBUG, 'sendTransaction START with : ' + obj);

            Universign_Transaction__c  univTransaction = new Universign_Transaction__c();
            univTransaction = obj[0].universignTransaction;

            String endpointUrl = 'callout:universign/sign/rpc/';
            String methodName  =   'requester.cancelTransaction';
    
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
    
            // Call the method to parse the XML-RPC string
            universign_XMLRPCParser_cancelTrans.CancelTransactionResponse resp = universign_XMLRPCParser_cancelTrans.parseXMLRPCString(response.getBody());
            if(resp != null && resp.faultCode == 0){
                //Update transaction record
                update new Universign_Transaction__c(Id = univTransaction.id, status__c = 'canceled');

                return new List<Result>{new Result(true, null)};
            }else{
                return new List<Result>{new Result(false, resp.faultString + '( fault code: ' + resp.faultCode + ') ')};
            }

        }catch(Exception e){
            System.debug('Exception  : ' + e.getMessage());
            Result r = new Result(false, e.getMessage());
            return new List<Result>{r};
        }
    }
}