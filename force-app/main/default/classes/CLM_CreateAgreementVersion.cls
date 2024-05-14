/**
 * @description       : 
 * @author            : Patrick Randrianarisoa
 * @group             : 
 * @last modified on  : 13-09-2023
 * @last modified by  : Patrick Randrianarisoa
 * Modifications Log
 * Ver   Date         Author                   Modification
 * 1.0   13-09-2023   Patrick Randrianarisoa   Initial Version
**/
public with sharing class CLM_CreateAgreementVersion {
    public class ObjectContext {     
        @InvocableVariable(required=true label='programId' )
        public String programId;

        @InvocableVariable(required=true label='reinsurerId' )
        public String reinsurerId;

        @InvocableVariable(required=true label='versionDetailId' )
        public String versionDetailsId;
    }

    public class Result {
        @InvocableVariable(required=false label='Is Success ?')
        public Boolean isSuccess;

        @InvocableVariable(required=false label='Error Message')
        public String errorMsg;

        @InvocableVariable(required=false label='Agreement Record Created')
        public String agreementId;

        public Result(Boolean isSuccess, String errorMsg){
            this.isSuccess = isSuccess;
            this.errorMsg = errorMsg;
        }


        public Result(Boolean isSuccess, String errorMsg, String agreementId){this.isSuccess = isSuccess;this.errorMsg = errorMsg;this.agreementId = agreementId;}
    }

    /***
    * @description	Method to prepare & do callout to book a b2g appointment
    * @param	    obj 
    * @return		List<Slots> 
    * @exception   	None
    ***/   
    @InvocableMethod(label='[CLM] create document version' description='Clones an agreement and generates document versions ' callout=true)
    public static List<Result> cloneAgreement(List<ObjectContext> obj) {

        try{
            System.debug(LoggingLevel.DEBUG, 'cloneAgreement START with : ' + obj);

            

            // select content version
            List<Apttus__DocumentVersionDetail__c> documentVersionDetails  = [
                SELECT Id, Apttus__ContentVersionId__c, TECH_TemplateId__c, TECH_AgreementId__c
                FROM Apttus__DocumentVersionDetail__c
                WHERE Id = :obj[0].versionDetailsId
            ];
			
            Apttus__APTS_Agreement__c newAgreement = new Apttus__APTS_Agreement__c(
                Program__c = obj[0].programId
                ,Reinsurer__c = obj[0].reinsurerId
                ,initialAgreement__c = documentVersionDetails[0].TECH_AgreementId__c
                );
            insert newAgreement;
            
            // generate version of document
            Apttus__DocumentVersionDetail__c  documentVersionDetail = Apttus.AgreementGenerateController.createDocVersionSO(newAgreement.Id,  documentVersionDetails[0].TECH_TemplateId__c,  Apttus.AgreementGenerateController.ACTION_GENERATE,  'DOCX',  'comments if any');

            if(!documentVersionDetails.isEmpty()){

                // calling merge    
                System.debug('cloneAgreement not empty');
                ContentVersion documentInitial = [SELECT Id, VersionData,FileExtension, FileType, PathOnClient, Title  FROM ContentVersion WHERE Id =:documentVersionDetails[0].Apttus__ContentVersionId__c];

                Apttus.CustomClass.ActionParams params = new Apttus.CustomClass.ActionParams();
                params.ParentId = newAgreement.Id;

                List<Apttus.CustomClass.AttachmentInfo> attachmentsInfoList = new List<Apttus.CustomClass.AttachmentInfo>();
                Apttus.CustomClass.AttachmentInfo att1 = new Apttus.CustomClass.AttachmentInfo();
                att1.Title = documentInitial.Title;
                att1.RecordId = documentInitial.Id;
                attachmentsInfoList.add(att1);

                Apttus.CustomClass.ActionParams apiParameters  = new Apttus.CustomClass.ActionParams();
                apiParameters.ParentId          = newAgreement.Id;
                apiParameters.Attachments       = attachmentsInfoList;
                apiParameters.ExternalLinks     = null;
                apiParameters.DocFileName       = 'docfilename.docx';
                apiParameters.SessionId         = UserInfo.getSessionId();
                apiParameters.SessionUrl        = System.Url.getSalesforceBaseUrl().toExternalForm() + '/services/Soap/u/55.0/' + UserInfo.getOrganizationId();

                ContentVersion clonedContent ; 
                if(!Test.isRunningTest()){
                    Id outputFile = Apttus.MergeWebService.mergeDocuments(apiParameters);
                    System.debug('cloneAgreement outfile: ' + outputFile);
                    System.debug('cloneAgreement not empty');
                    clonedContent = [SELECT Id, VersionData,FileExtension, FileType, PathOnClient, Title  FROM ContentVersion WHERE Id =:outputFile];
                }else{
                    clonedContent = [SELECT Id, VersionData,FileExtension, FileType, PathOnClient, Title  FROM ContentVersion LIMIT 1];
                }
                // end calling merge

                System.debug('cloneAgreement initial Document retrieved: ' + documentInitial);
                // ContentVersion clonedContent = documentInitial.clone();
                // ContentVersion clonedContent = new ContentVersion(
                //     title = documentInitial.Title
                //     ,VersionData = documentInitial.VersionData
                //     ,PathOnClient = documentInitial.PathOnClient
                // );
                // clonedContent.ContentBodyId = null; 
                // clonedContent.ContentLocation = 'S';

                insert clonedContent;

                ContentVersion cvInserted = [SELECT Id, ContentDocumentId, Title FROM ContentVersion WHERE Id = :clonedContent.Id]; 
                ContentDocumentLink link = new ContentDocumentLink();
                link.LinkedEntityId = documentVersionDetail.Id;
                link.ContentDocumentId = cvInserted.ContentDocumentId;
                link.ShareType = 'V';
                link.Visibility = 'AllUsers';
                insert link;
            }
            System.debug(LoggingLevel.DEBUG, 'cloneAgreement Agreement created ' + newAgreement);
            return new List<Result>{ new Result(true, null, newAgreement.Id)};

        }catch(Exception e){
            System.debug('Exception  : ' + e.getMessage());
            return new List<Result>{ new Result(false, e.getMessage())};
        }
    }
}