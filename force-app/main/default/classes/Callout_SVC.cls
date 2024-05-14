public with sharing class Callout_SVC implements Queueable, Database.AllowsCallouts{
    

    public String targetURL {get;set;}
    public String httpMethod {get;set;}
    public Map<String,String> headerParams {get;set;}
    public String requestBody {get;set;}
    public Map<String, Object> args {get;set;}
    
    public Callout_SVC()
    {
        System.debug('Callout_SVC : constructor');
    }

    public void execute(QueueableContext context) {
        //your code including the callout     
        System.debug('executeRequest: START');

        EventLog__c evt = new EventLog__c();

        HttpRequest request = new HttpRequest();
                                                
        System.debug('executeRequest: setting EndPoint ' + this.targetURL);
        request.setEndpoint(this.targetURL);
                                                
        System.debug('executeRequest: setting Method ' + this.httpMethod);                                     
        request.setMethod(this.httpMethod);
                                                
        //request.setHeader('Content-Type','application/json;charset=UTF-8');
        if ((null != this.headerParams) && (this.headerParams.size() != 0)) {
            System.debug('executeRequest: this.headerParams provided ' + this.headerParams);    
    
            for(String key:this.headerParams.keySet()) {
                System.debug('executeRequest: setting header Params' + key
                            + ' with value ' + this.headerParams.get(key));
                request.setHeader(key,this.headerParams.get(key));
            }       
        } else {
            System.debug('executeRequest: no this.headerParams provided ' + this.headerParams);
        }
                
        if ((null != this.requestBody) && (this.requestBody.length() != 0)) {
            System.debug('executeRequest: setting request Body' + this.requestBody);
            request.setBody(this.requestBody);
        } else {
            System.debug('executeRequest: no this.requestBody provided ' + this.requestBody);
        }
                                            
        System.debug('executeRequest: sending request' + request);

        evt.ClassName__c = 'Callout_SVC';
        evt.MethodName__c = 'execute';
        evt.Time__c = System.now();
        evt.Context__c = QuoteTable_CST.CONTEXT;
        evt.RecordId__c = this.args.containsKey('RecordId') ? (String)this.args.get('RecordId') : null;
        evt.Request__c = this.requestBody;
        evt.User__c = UserInfo.getUserId();


        Http http = new Http();  
        HttpResponse response;                                 
        try{
            response = http.send(request);
        }
        catch(Exception e){
            System.debug('executeRequest: Exception' + response);
            evt.Response__c = e.getMessage(); 
            insert evt;
            return;
        }
        System.debug('executeRequest: response received' + response);
         

        if (response.getStatusCode() != 200) {
            String statusMessage = response.getStatus() + ' (' + response.getStatusCode() + ')';
            System.debug('executeRequest: callout response NOT OK' + statusMessage);
            evt.Response__c = statusMessage;
            evt.Message__c = statusMessage;
            evt.statusCode__c = String.valueOf(response.getStatusCode()); 
        }      
        
        
        if (response.getStatusCode() == 200) {
            String statusMessage = response.getStatus() + ' (' + response.getStatusCode() + ')';
            evt.Message__c = statusMessage;
            evt.Response__c = response.getBody();
            evt.statusCode__c = String.valueOf(response.getStatusCode()); 
            System.debug('executeRequest: callout response OK ' + statusMessage);

        } 
        // return (String)(response.getBody());

        
       
        insert evt; 

    }

    public class applicationException extends Exception {}
}