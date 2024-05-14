global class BAT003_CreateSharingReqBigQuantity implements Database.Batchable<SObject> {

    global String query;
    global Set<String> setKeyWithUserId;
    global List<String> lstAccId;
    global List<Id> lstIdPccForContact;
    global List<String> lstInitial;
    global Set<String> setKeys;
    global List<String> lstIdContact;
    global Boolean isRunBatch;

    global BAT003_CreateSharingReqBigQuantity(String queryPcc, Set<String> setKeyWithUserId, List<String> lstAccId,  List<Id> lstIdPccForContact, List<String> lstInitial, Set<String> setKeys, List<Id> lstIdContact){
        System.debug('Begin BAT003_CreateSharingReqBigQuantity');
        this.query = queryPcc;   
        this.setKeyWithUserId =  setKeyWithUserId;
        this.lstAccId = lstAccId;
        this.lstIdPccForContact = lstIdPccForContact;
        this.lstInitial = lstInitial;
        this.lstIdContact = lstIdContact;
        this.setKeys = setKeys;
        //this.isRunBatch = isRunBatch;
        System.debug('BAT003_CreateSharingReqBigQuantity__setKeyWithUserId' + setKeyWithUserId);
        System.debug('BAT003_CreateSharingReqBigQuantity__lstAccId' + lstAccId);  
        System.debug('BAT003_CreateSharingReqBigQuantity__lstIdPccForContact' + lstIdPccForContact);  
        System.debug('BAT003_CreateSharingReqBigQuantity__lstInitial' + lstInitial);
        System.debug('BAT003_CreateSharingReqBigQuantity__setKeys' + setKeys);
        System.debug('BAT003_CreateSharingReqBigQuantity___lstIdContact= ' + lstIdContact);      
        //System.debug('BAT003_CreateSharingReqBigQuantity___isRunBatch= ' + isRunBatch);  
        System.debug('BAT003_CreateSharingReqBigQuantity___query= ' + query);
    }
    
    //Method to get the data to be proceesed  
    global Database.Querylocator Start(Database.BatchableContext bc){
        System.debug('querySOQL == ' + query);
        return Database.getQueryLocator(query);
    }

    //Method to execute the batch
    global void execute(Database.BatchableContext bc, List<Request__c> lstScope){
        System.debug('BAT003_CreateSharingReqBigQuantity__lstScope' + lstScope);   
        AP36_CreateSharingForContact.createSharingBigQuantityForContact(lstScope, setKeyWithUserId, lstAccId, lstIdPccForContact, lstInitial, setKeys);
        Contact con = [SELECT Id, isRunBatch__c FROM Contact WHERE Id IN:lstIdContact LIMIT 1];
        con.isRunBatch__c = false;
        update con;
    }

    //Method to be called after the excute
    global void finish(Database.BatchableContext bc){
        System.debug('End BAT003_CreateSharingReqBigQuantity');
        //Add your start code for the other batch job here
    }
}