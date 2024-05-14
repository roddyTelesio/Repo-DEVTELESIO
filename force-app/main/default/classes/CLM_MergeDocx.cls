/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 11-07-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class CLM_MergeDocx {


    public class ObjectContext {     
        @InvocableVariable(required=true label='[For Merging DOCX] ContentDocuments to merge' )
        public List<sObject> contentDocsToMerge;

        @InvocableVariable(required=true label='parentId' )
        public String parentId;

        @InvocableVariable(required=true label='agreementId' )
        public String agreementId;

        @InvocableVariable(required=true label='Doc file name' )
        public String docFileName;

        @InvocableVariable(required=false label='Launch in Queueable context ?' )
        public Boolean QueueableContext;
    }

    public class Result {
        @InvocableVariable(required=false label='Is Success ?')
        public Boolean isSuccess;

        @InvocableVariable(required=false label='Error Message')
        public String errorMsg;

        @InvocableVariable(required=false label='Content Record Created')
        public String contentIdGenerated;

        public Result(Boolean isSuccess, String errorMsg){this.isSuccess = isSuccess;this.errorMsg = errorMsg;
        }


        public Result(Boolean isSuccess, String errorMsg, String docId){
            this.isSuccess = isSuccess;
            this.errorMsg = errorMsg;
            this.contentIdGenerated = docId;
        }
    }

    /***
    * @description	Merge CLM documents in docX format through API 
    * @param	    obj 
    * @return		List<Slots> 
    * @exception   	None
    ***/   
    @InvocableMethod(label='[CLM] merge documents docx' description='Merges multiple documents' callout=true)
    public static List<Result> mergeDocuments(List<ObjectContext> obj) {
        List<Apttus.CustomClass.AttachmentInfo> attachmentsInfoList = new List<Apttus.CustomClass.AttachmentInfo>();
        
        System.debug(LoggingLevel.DEBUG, 'mergeDocuments START with : ' + obj);
        try {

            if(obj[0].contentDocsToMerge != null && !obj[0].contentDocsToMerge.isEmpty()){
                for(sObject o : obj[0].contentDocsToMerge){
                    Apttus.CustomClass.AttachmentInfo attInfo = new Apttus.CustomClass.AttachmentInfo();
                    attInfo.DocType  = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
                    attInfo.Title    = (String) o.get('Title');
                    attInfo.RecordId = (Id) o.get('Id');
                    attachmentsInfoList.add(attInfo);
                }
                System.debug(LoggingLevel.DEBUG, 'mergeDocuments attachments : ' + attachmentsInfoList);
            }else{return new List<Result>{new Result(false, 'No content documents parsed in parameter', null)};}

            if(obj[0].QueueableContext == null || obj[0].QueueableContext == false){
                Apttus.CustomClass.ActionParams apiParameters  = new Apttus.CustomClass.ActionParams();
                apiParameters.ParentId          = obj[0].parentId;
                apiParameters.Attachments       = attachmentsInfoList;
                apiParameters.ExternalLinks     = null;
                apiParameters.DocFileName       = obj[0].docFileName;
                apiParameters.SessionId         = UserInfo.getSessionId();
                apiParameters.SessionUrl        = Url.getOrgDomainUrl().toExternalForm() + '/services/Soap/u/50.0/' + UserInfo.getOrganizationId();

                String MergedContentDocId;
                if(!Test.isRunningTest()){
                    MergedContentDocId = Apttus.MergeWebService.mergeDocuments(apiParameters);
                }else{
                    MergedContentDocId = 'testId';
                }
                return new List<Result>{new Result(true, null, MergedContentDocId)};
            }else{
                CLM_mergeDocxQueueable queueable = new CLM_mergeDocxQueueable(obj[0].parentId, obj[0].docFileName, attachmentsInfoList, obj[0].agreementId);System.enqueueJob(queueable);return new List<Result>{new Result(true, null, null)};
            }
        } catch (Exception e) {System.debug('mergeDocuments exception : '+ e.getMessage()); return new List<Result>{new Result(false, e.getMessage(), null)};}
    }

    /**
    * @description Method to generate Doc via Conga API from a LWC
    * @param String agreementId
    * @return Map<String, Object>
    */
    @AuraEnabled
    public static Map<String, Object> getMergeDocId(String agreementId) {
        System.debug('getRetroDocId START with  ' + agreementId);
        Map<String, Object> mapResults = new Map<String, Object>();
        try{
            List<Apttus__APTS_Agreement__c> agreement = [
                SELECT Id, RetroMergeDocId__c
                FROM Apttus__APTS_Agreement__c 
                WHERE Id =:agreementId
                AND RetroMergeDocId__c != NULL 
                AND RetrocessionDocGenerated__c = true
                LIMIT 1
            ];

            if(agreement.isEmpty()){
                return new Map<String,Object>{'isSuccess' => true, 'docId'=> null};
            }else{
                return new Map<String,Object>{'isSuccess' => true, 'docId'=> agreement[0].RetroMergeDocId__c};
            }
        }
        catch (Exception ex) {return new Map<String,Object>{'isSuccess' => false, 'errMsg'=> ex.getMessage()};}
    }
}