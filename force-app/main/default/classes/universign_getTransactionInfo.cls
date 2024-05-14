/*
* @author:      Azhar Nahoor
* @created:     24/07/2023
* @description: Invocable Apex class used in flow Universign to send transaction
*/
public without sharing class universign_getTransactionInfo{

    public class ObjectContext {     
        @InvocableVariable(required=true label='universign transaction' )
        public Universign_Transaction__c universignTransaction;
    }


    public class Result {
        @InvocableVariable(required=false label='Is Success ?')
        public Boolean isSuccess;

        @InvocableVariable(required=false label='Error Message')
        public String errorMsg;

        @InvocableVariable(required=false label='List of signers')
        public List<Universign_signer__c> signers;

        @InvocableVariable(required=false label='List of signers (From themis)')
        public List<Universign_signer__c> lstSigners;

        @InvocableVariable(required=false label='Current signer')
        public Universign_signer__c currentSigner;

        @InvocableVariable(required=false label='Universign Transaction')
        public Universign_Transaction__c universignTransaction;

        //For Transactions created on themis:
        @InvocableVariable(required=false label='Current signer Name')
        public String currentSignerName;

        public Result(){
            // this.isSuccess = isSuccess;
            // this.responseBody = responseBody;
            // this.transactionId = transactionId;
        }
    }

    /***
    * @description	Method to prepare & do callout to book a b2g appointment
    * @param	    obj 
    * @return		List<Slots> 
    * @exception   	None
    ***/   
    @InvocableMethod(label='[Universign] get transaction info' description='Make WS callout to Universign to get transaction info' callout=true)
    public static List<Result> sendTransaction(List<ObjectContext> obj) {

        try{
            System.debug(LoggingLevel.DEBUG, 'sendTransaction START with : ' + obj);

            Map<String, Universign_signer__c> emailToSigner = new Map<String, Universign_signer__c>();
            List<Universign_signer__c>        signersToUpd  = new List<Universign_signer__c>();
            List<Universign_signer__c>        lstSigners  = new List<Universign_signer__c>();
            Universign_signer__c              currentSigner = new Universign_signer__c();
            Universign_Transaction__c         univTransaction = new Universign_Transaction__c();
            String currentSignerName;

            univTransaction = obj[0].universignTransaction;


            String endpointUrl = 'callout:universign/sign/rpc/';
            String methodName  =   'requester.getTransactionInfo';
    
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
            System.debug('response statuscode' + response.getStatusCode());
            System.debug('response status' + response.getStatus());
    
            // Call the method to parse the XML-RPC string
            Universign_XMLRPCParser_transactionInfo.TransactionInfo transactionInfo = Universign_XMLRPCParser_transactionInfo.parseXMLRPCString(response.getBody());
    
            // Access the extracted data
            System.debug('Transaction ID: ' + transactionInfo.transactionId);
            System.debug('Status: ' + transactionInfo.status);
            System.debug('current signer: ' + transactionInfo.currentSigner);
            System.debug('current signer: ' + transactionInfo.creationDate);

            if(transactionInfo != null && transactionInfo.status != null){
                univTransaction.status__c = transactionInfo.status;
                update univTransaction;
            }
    
            if (transactionInfo.initiatorInfo != null) {
                System.debug('Initiator First Name: ' + transactionInfo.initiatorInfo.firstName);
                System.debug('Initiator Last Name: ' + transactionInfo.initiatorInfo.lastName);
                System.debug('Initiator Email: ' + transactionInfo.initiatorInfo.email);
            }

    
            //Query Universign signers
            for(Universign_signer__c signer : [
                SELECT Id, TECH_SignerName__c, User__c, Contact__c, Email__c, Role__c, SignerStatus__c, 
                       signerId__c, actionDate__c, refusalComment__c, SignerOrder__c, firstname__c
                FROM   Universign_signer__c
                WHERE  UniversignTransaction__c = :obj[0].universignTransaction.Id
            ]){
                String key = signer.email__c + signer.firstname__c;
                System.debug('key x: ' + key);
                emailToSigner.put(key, signer);
            }
            System.debug('emailToSigner : ' + emailToSigner);
    
    
            if (transactionInfo.signerInfos != null && !transactionInfo.signerInfos.isEmpty()) {

                Set<String> setKey = new Set<String>();

                for(Integer i = 0; i < transactionInfo.signerInfos.size(); i++){
                    String key = transactionInfo.signerInfos[i].email + transactionInfo.signerInfos[i].firstName;
                    System.debug('key y: ' + key);
                    if(emailToSigner.containsKey(key) && !setKey.contains(key)){
                        setKey.add(key);
                        Universign_signer__c signer  = emailToSigner.get(key);
                        signer.SignerOrder__c = i;
                        signer.SignerStatus__c = transactionInfo.signerInfos[i].status;
                        signer.actionDate__c = transactionInfo.signerInfos[i].actionDate;
                        signer.refusalComment__c = transactionInfo.signerInfos[i].refusalComment;
                        signer.signerId__c = transactionInfo.signerInfos[i].id;
                        signersToUpd.add(signer);

                        if(i == transactionInfo.currentSigner){
                            System.debug('current Signer  : ' + signer);
                            currentSigner = signer;
                            currentSignerName = transactionInfo.signerInfos[i].firstName + ' ' +  transactionInfo.signerInfos[i].lastName + ' (' + transactionInfo.signerInfos[i].email + ')';
                        }
                    }
                }


                for(Integer i = 0; i < transactionInfo.signerInfos.size(); i++){
                    Universign_signer__c signer  = new Universign_signer__c();
                    signer.Name = transactionInfo.signerInfos[i].firstName + ' ' +  transactionInfo.signerInfos[i].lastName;
                    signer.Email__c = transactionInfo.signerInfos[i].email;
                    signer.SignerOrder__c = i;
                    signer.SignerStatus__c = transactionInfo.signerInfos[i].status;
                    signer.actionDate__c = transactionInfo.signerInfos[i].actionDate;
                    signer.refusalComment__c = transactionInfo.signerInfos[i].refusalComment;
                    signer.signerId__c = transactionInfo.signerInfos[i].id;
                    lstSigners.add(signer);

                    if(i == transactionInfo.currentSigner){currentSignerName = transactionInfo.signerInfos[i].firstName + ' ' +  transactionInfo.signerInfos[i].lastName + ' (' + transactionInfo.signerInfos[i].email + ')';}
                }
    
                for (Universign_XMLRPCParser_transactionInfo.SignerInfo signerInfo : transactionInfo.signerInfos) {
                    System.debug('Signer First Name: ' + signerInfo.firstName);
                    System.debug('Signer Last Name: ' + signerInfo.lastName);
                    System.debug('Signer ID: ' + signerInfo.id);
                    System.debug('Signer URL: ' + signerInfo.url);
                    System.debug('Signer Email: ' + signerInfo.email);
                    System.debug('Signer Status: ' + signerInfo.status);
                    System.debug('Signer actionDate: ' + signerInfo.actionDate);
                    System.debug('Signer refusalComment: ' + signerInfo.refusalComment);
                }
            }
            System.debug('signersToUpd : ' + signersToUpd);
            
            if(!signersToUpd.isEmpty()){update signersToUpd;}

            Result r = new Result();
            r.currentSigner = currentSigner;
            r.isSuccess = true;
            r.signers = signersToUpd;
            r.universignTransaction = univTransaction;
            r.currentSignerName = currentSignerName;
            r.lstSigners  = lstSigners;
            universign_sendTransaction.createUniversignEventLog(String.valueOf(univTransaction.Id), 'universign_getTransactionInfo', String.valueOf(response.getStatus()), 'SUCCESS', req.getBody() , response.getBody());

            return new List<Result>{r};
    
        }catch(Exception e){
            Universign_Transaction__c         univTransaction = new Universign_Transaction__c();univTransaction = obj[0].universignTransaction;
            System.debug('Exception  : ' + e.getMessage());
            Result r = new Result();r.isSuccess = false;r.errorMsg = e.getMessage();universign_sendTransaction.createUniversignEventLog(String.valueOf(univTransaction.Id), 'universign_getTransactionInfo', null, (e.getMessage()).left(250), 'NOT_SET', e.getStackTraceString());
            return new List<Result>{r};
        }
    }
}