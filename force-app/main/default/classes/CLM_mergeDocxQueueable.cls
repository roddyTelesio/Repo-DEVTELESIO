/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 03-11-2023
 * @last modified by  : Patrick Randrianarisoa
**/
public class CLM_mergeDocxQueueable implements Queueable, Database.AllowsCallouts {
    private String parentId;
    private String agrementId;
    private String docFileName;
    private List<Apttus.CustomClass.AttachmentInfo> attachmentsInfoList;

    public CLM_mergeDocxQueueable(String parentId, String docFileName, List<Apttus.CustomClass.AttachmentInfo> attachmentsInfoList, String agreementId) {
        System.debug('CLM_MergeDocxQueueable Constructor start');
        this.parentId = parentId;
        this.docFileName = docFileName;
        this.attachmentsInfoList = attachmentsInfoList;
        this.agrementId = agreementId;
    }

    public void execute(QueueableContext context) {       
        System.debug('CLM_MergeDocxQueueable  execute START');
        Apttus.CustomClass.ActionParams apiParameters  = new Apttus.CustomClass.ActionParams();
        apiParameters.ParentId          = this.parentId;
        apiParameters.Attachments       = this.attachmentsInfoList;
        apiParameters.ExternalLinks     = null;
        apiParameters.DocFileName       = this.docFileName;
        apiParameters.SessionId         = UserInfo.getSessionId();
        apiParameters.SessionUrl        = Url.getOrgDomainUrl().toExternalForm() + '/services/Soap/u/50.0/' + UserInfo.getOrganizationId();
        String MergedContentDocId ;
        if(!Test.isRunningTest()){
            MergedContentDocId       = Apttus.MergeWebService.mergeDocuments(apiParameters);
        }else{
            MergedContentDocId       = 'Test';
        }
        System.debug('CLM_MergeDocxQueueable MergedContentDocId ' + MergedContentDocId);

        if(MergedContentDocId != null){
            Apttus__APTS_Agreement__c a = new Apttus__APTS_Agreement__c();
            a.Id = agrementId;
            a.RetrocessionDocGenerated__c = true;
            a.RetroMergeDocId__c = MergedContentDocId;
            if(!Test.isRunningTest()){
                update a;
            }
        }  
    }
}