/*
* @author:      Azhar Nahoor
* @created:     24/07/2023
* @description: Invocable Apex class to generate document based on conga agreement
*/
public without sharing class CLM_generateDoc{

    public class ObjectContext {     
        @InvocableVariable(required=true label='template name' )
        public String templateName;

        @InvocableVariable(required=true label='agreement Id' )
        public String agreementId;

        @InvocableVariable(required=false label='doc format' )
        public String docFormat;

        @InvocableVariable(required=false label='pLevel' )
        public String pLevel;

        @InvocableVariable(required=false label='Launch in Queueable context ?' )
        public Boolean QueueableContext;
    }


    public class Result {
        @InvocableVariable(required=true label='Is Success ?')
        public Boolean isSuccess;

        @InvocableVariable(required=false label='Error message')
        public String errMsg;

        @InvocableVariable(required=false label='doc Id')
        public String docId;

        public Result(Boolean isSuccess, String errMsg, String docId){
            this.isSuccess = isSuccess;
            this.errMsg = errMsg;
            this.docId = docId;
        }
    }

    /***
    * @description	Method to generate document by calling Conga API
    * @param	    obj 
    * @return		List<Result> 
    * @exception   	None
    ***/   
    @InvocableMethod(label='[Conga API] Generate document' description='generate doc api' callout=true)
    public static List<Result> generateDoc(List<ObjectContext> obj) {
        System.debug(LoggingLevel.DEBUG, 'generateDoc START with : ' + obj);
        List<Id> contentVersionIds = new List<Id>();

        try {
            String templateId = getTemplateId(obj[0].templateName);
            if(templateId == null){
                return new List<Result>{new Result(false, 'No templates found for name: ' + obj[0].templateName + ' to generate signature page' , null)};
            }

            ID agreementId = obj[0].agreementId;
            String pLevel = obj[0].pLevel != null ?  obj[0].pLevel : 'Read only';
            String docFormat = obj[0].docFormat != null ?  obj[0].docFormat : 'DOC';
            String generatedDocId = callGenerateDocAPI(templateId, agreementId, pLevel, docFormat, obj[0].QueueableContext);
            System.debug('generateDoc (ContentDocumentId) docId: ' + generatedDocId);
            return new List<Result>{new Result(true, null, generatedDocId)};

        } catch (Exception e) {
            System.debug('generateDoc exception : '+ e.getMessage());
            return new List<Result>{new Result(false, e.getMessage(), null)};
        }
    }

    /**
    * @description Method to generate Doc via Conga API from a LWC
    * @param String agreementId
    * @return Map<String, Object>
    */
    @AuraEnabled
    public static Map<String, Object> getRetroDocId(String agreementId) {
        System.debug('getRetroDocId START with  ' + agreementId);
        Map<String, Object> mapResults = new Map<String, Object>();
        try{
            List<Apttus__APTS_Agreement__c> agreement = [
                SELECT Id, RetroGeneratedDocId__c
                FROM Apttus__APTS_Agreement__c 
                WHERE Id =:agreementId
                AND RetroGeneratedDocId__c != NULL 
                AND RetrocessionDocGenerated__c = true
                LIMIT 1
            ];

            if(agreement.isEmpty()){
                return new Map<String,Object>{'isSuccess' => true, 'docId'=> null};
            }else{
                return new Map<String,Object>{'isSuccess' => true, 'docId'=> agreement[0].RetroGeneratedDocId__c};
            }
        }
        catch (Exception ex) {
            return new Map<String,Object>{'isSuccess' => false, 'errMsg'=> ex.getMessage()};
        }
    }

    /**
    * @description Method to get delete a Document
    * @param  String templateName
    * @return String templateId
    */
    private static String getTemplateId(String templateName){
        System.debug(LoggingLevel.DEBUG, 'getTemplateId START with : ' + templateName);
        List<Apttus__APTS_Template__c> templates = [
            SELECT Id
            FROM   Apttus__APTS_Template__c
            WHERE  Name =: templateName
            LIMIT 1
        ];
        System.debug(LoggingLevel.DEBUG, 'getTemplateId END with : ' + templates);

        if(templates.isEmpty()){
            return null;
        }else{
            return templates[0].Id;
        }
    }

    /**
    * @description Method to get delete a Document
    * @param  String templateName
    * @return String templateId
    */
    // @future(callout=true)
    public static String callGenerateDocAPI(String templateId, String agreementId, String pLevel, String docFormat, Boolean QueueableContext){
        System.debug('callGenerateDocAPI START');
        // if(QueueableContext == null || !QueueableContext){
            System.debug('callGenerateDocAPI Not QueueableContext');
            String apiServerURL = System.Url.getOrgDomainUrl().toExternalForm() + '/services/Soap/u/50.0/' + UserInfo.getOrganizationId();
            String docId =  Apttus.MergeWebService.generateDoc(templateId, agreementId, pLevel, docFormat, UserInfo.getSessionId(), apiServerURL);
            System.debug('callGenerateDocAPI END with docId ' + docId);
            return docId;
        // }else{
        //     System.debug('callGenerateDocAPI QueueableContext');
        //     CLM_GenerateDocQueueable queueable = new CLM_GenerateDocQueueable(templateId, agreementId, pLevel, docFormat);
        //     System.enqueueJob(queueable);
        //     return null;
        // }
    }
}