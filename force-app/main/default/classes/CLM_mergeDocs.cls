/*
* @author:      Azhar Nahoor
* @created:     24/07/2023
* @description: Invocable Apex class to merge docs
*/
public without sharing class CLM_mergeDocs{

    public class ObjectContext {     
        @InvocableVariable(required=true label='[For Merging PDFs] ContentVersions to merge' )
        public List<sObject> contentVersionsToMerge;

        @InvocableVariable(required=true label='Parent Id' )
        public String parentId;

        @InvocableVariable(required=true label='doc file name' )
        public String docFileName;
    }


    public class Result {
        @InvocableVariable(required=true label='Is Success ?')
        public Boolean isSuccess;

        @InvocableVariable(required=false label='Error message')
        public String errMsg;

        @InvocableVariable(required=false label='Merged doc Id')
        public String mergedDocId;

        public Result(Boolean isSuccess, String errMsg, String mergedDocId){
            this.isSuccess = isSuccess;
            this.errMsg = errMsg;
            this.mergedDocId = mergedDocId;
        }
    }

    /***
    * @description	Method to merge docs by calling Conga API
    * @param	    obj 
    * @return		List<Result>
    * @exception   	None
    ***/   
    @InvocableMethod(label='[Conga API] Merge PDF documents' description='Merge PDF doc api' callout=true)
    public static List<Result> mergeDocs(List<ObjectContext> obj) {
        System.debug(LoggingLevel.DEBUG, 'mergePdf START with : ' + obj);
        List<Id> contentVersionIds = new List<Id>();

        if(obj[0].contentVersionsToMerge != null && !obj[0].contentVersionsToMerge.isEmpty()){
            for(sObject o : obj[0].contentVersionsToMerge){
                contentVersionIds.add(o.Id);
            }
        }else{
            return new List<Result>{new Result(false, 'No content versions parsed in parameter', null)};
        }

        try {
            ID parentId = obj[0].parentId;
            ID[] docIds = contentVersionIds;   //List of content version Ids
            String docFileName = obj[0].docFileName;
            String sessionId = UserInfo.getSessionId();
            String serverUrl = System.Url.getOrgDomainUrl().toExternalForm() + '/services/Soap/u/50.0/' + UserInfo.getOrganizationId();
            ID docId;
            if(!Test.isRunningTest()){
                docId = Apttus.MergeWebService.mergeDocsToPDF(parentId,docIds,docFileName,sessionId,serverUrl);
            }else{
                docId = 'testId';
            }
            System.debug('mergePdf docId (ContentDocumentId): ' + docId);
            return new List<Result>{new Result(true, null, docId)};

        } catch (Exception e) {
            System.debug('mergePdf exception : '+ e.getMessage());
            return new List<Result>{new Result(false, e.getMessage(), null)};
        }
    }
}