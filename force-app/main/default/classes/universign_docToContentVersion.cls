/*
* @author:      Azhar Nahoor
* @created:     24/07/2023
* @description: Invocable Apex class used in flow Universign to send transaction
*/
public without sharing class universign_docToContentVersion{

    public class ObjectContext {     
        @InvocableVariable(required=true label='documentId' )
        public String documentId;
    }


    public class Result {
        @InvocableVariable(required=false label='Is Success ?')
        public Boolean isSuccess;

        @InvocableVariable(required=false label='errorMsg')
        public String errorMsg;

        @InvocableVariable(required=false label='contentVersionId')
        public String contentVersionId;

        public Result(Boolean isSuccess, String errorMsg, String contentVersionId){
            this.isSuccess = isSuccess;
            this.contentVersionId = contentVersionId;
            this.errorMsg = errorMsg;
        }
    }

    /***
    * @description	Method to prepare & do callout to send universign transaction
    * @param	    obj 
    * @return		List<Result>
    * @exception   	None
    ***/   
    @InvocableMethod(label='[Universign] Convert Document to Contentversion' callout=false)
    public static List<Result> convertDocToContentVersion(List<ObjectContext> obj) {
        try{

            String documentId = obj[0].documentId;
            System.debug('documentId : '  + documentId);

             // Step 1: Query the relevant fields from the Document record
            Document doc = [SELECT Id, Name, Body FROM Document WHERE Id = :documentId LIMIT 1];
            
            // Step 2: Create a Content Version
            ContentVersion contentVersion = new ContentVersion(
                Title = doc.Name,  // Set the Title for the ContentVersion
                VersionData = doc.Body,  // Set the document's body
                PathOnClient = doc.Name  // Set the file name
                // Set other metadata as needed
                //FirstPublishLocationId = doc.Id  // Set the ParentId for the ContentVersion
            );
            
            // Step 3: Insert the Content Version
            insert contentVersion;
            
            // Step 4: Return the ID of the created Content Version
            // return contentVersion.Id;

            return new List<Result>{new Result(true, null,contentVersion.Id)};


        }catch(Exception e){
            System.debug('response Exception: '  + e.getMessage());
            return new List<Result>{new Result(false, null, e.getMessage())};
        }
    }

    
}