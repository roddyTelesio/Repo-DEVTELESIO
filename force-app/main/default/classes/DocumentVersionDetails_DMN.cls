/***
* @author      Telesio Dev
* @date        14/08/2023
* @description Class implementing the main business rules for the DocumentVersionDetails object.
* @group       DocumentVersionDetails
* @see         DocumentVersionDetails_CST
*
***/
public with sharing class DocumentVersionDetails_DMN {


    /***
    * @description  Document version details generate pdf when user flags a record to generate PDF
    * @param       newList     trigger.new
    * @param       oldmap      trigger.oldMap
    * @return      void           Nothing (pdf is generated)
    * @exception   none special.
    * @author      telesio dev
    * @date        14/08/2023      
    ***/
    public static void generatePdf(List<Apttus__DocumentVersionDetail__c> newList, Map<Id,Apttus__DocumentVersionDetail__c> oldMap ){

        System.debug('DocumentVersionDetails_DMN.generatePdf Start');
        List<Apttus__DocumentVersionDetail__c> lstDocumentVersionToupdate = new List<Apttus__DocumentVersionDetail__c>();
        Id DocumentVersionIdinit; 
        Apttus__DocumentVersionDetail__c  documentVersionDetail;

        for(Apttus__DocumentVersionDetail__c iter : newList){

            if(
                iter.Generate_Pdf__c <> oldMap.get(iter.Id).Generate_Pdf__c
            ){
                DocumentVersionIdinit = iter.Apttus__ContentVersionId__c; 
                System.debug('DocumentVersionDetails_DMN.generatePdf : Satisfies conditions to generate PDF');
                String templateId = iter.TECH_TemplateId__c != null ? iter.TECH_TemplateId__c : null;
                System.debug('DocumentVersionDetails_DMN.generatePdf: ' + templateId);

                if(templateId != null){
                    documentVersionDetail = Apttus.AgreementGenerateController.createDocVersionSO(iter.TECH_AgreementId__c,  templateId,  Apttus.AgreementGenerateController.ACTION_GENERATE,  'PDF',  'Converted To PDF');
                    System.debug('documentVersionDetail generated: ' + documentVersionDetail);
                    lstDocumentVersionToupdate.add(
                    new Apttus__DocumentVersionDetail__c(
                            Id = documentVersionDetail.Id
                            ,Apttus__Title__c = changeToPDF(iter.Apttus__Title__c)
                            ,Name = iter.name + '-pdf'
                            ,Apttus__IsTransient__c = false
                            ,Apttus__VersionMajor__c = iter.Apttus__VersionMajor__c
                            ,Apttus__VersionMinor__c = iter.Apttus__VersionMinor__c
                        )
                    );
                }else{
                    System.debug('documentVersionDetail no templates found');
                    // create document Version details for offline documents
                    documentVersionDetail = new Apttus__DocumentVersionDetail__c(
                            Name = iter.name + '-pdf'
                            ,Apttus__DocumentVersionId__c = iter.Apttus__DocumentVersionId__c
                            ,Apttus__Title__c = changeToPDF(iter.Apttus__Title__c)
                            ,Apttus__Comment__c = ''
                            ,Apttus__DocumentInfo__c = 'Draft'
                            ,Apttus__IsTransient__c = false
                            ,Apttus__VersionMajor__c = iter.Apttus__VersionMajor__c
                            ,Apttus__VersionMinor__c = iter.Apttus__VersionMinor__c
                            ,Apttus__VersionRevision__c = iter.Apttus__VersionRevision__c
                    );
                

                    insert documentVersionDetail;
                }
                
                System.debug('DocumentVersionDetails_DMN.generatePdf : documentVersionDetail Generated > ' + documentVersionDetail);
            }
        }

        if(!lstDocumentVersionToupdate.isEmpty()){
            update lstDocumentVersionToupdate;
        }

        if(DocumentVersionIdinit <> null){
            // selecting content version of existing version
            ContentVersion documentInitial = [SELECT Id, VersionData,FileExtension, FileType, PathOnClient, Title  FROM ContentVersion WHERE Id =:DocumentVersionIdinit];
            ContentVersion clonedContent = documentInitial.clone();
            clonedContent.ContentBodyId = null; 
            clonedContent.ContentLocation = 'S';

            insert clonedContent;

            ContentVersion cvInserted = [SELECT Id, ContentDocumentId, Title FROM ContentVersion WHERE Id = :clonedContent.Id]; 
            ContentDocumentLink link = new ContentDocumentLink();
            link.LinkedEntityId = documentVersionDetail.Id;
            link.ContentDocumentId = cvInserted.ContentDocumentId;
            link.ShareType = 'V';
            link.Visibility = 'AllUsers';
            insert link;

            ConvertToPdf.ConvertToPdf(cvInserted.ContentDocumentId, cvInserted.title);
        }
        System.debug('DocumentVersionDetails_DMN.generatePdf End');
    }


    public static void beforeInsert(List<Apttus__DocumentVersionDetail__c> newList){
        
        System.debug('beforeInsert : Start with ' + newList.size());
        //initialising variables
        Set<String> dvIds = new Set<String>(); 
        Map<Id, Apttus__DocumentVersion__c> dvInfo = new Map<Id, Apttus__DocumentVersion__c>(); 

        // Preparing info
        for(Apttus__DocumentVersionDetail__c dvd : newList){
            System.debug('beforeInsert : Adding to prepare info ' + dvd);
            dvIds.add(dvd.Apttus__DocumentVersionId__c);
        }


        //retrieve additional information
        dvInfo = getAgreementsDetails(dvIds);


        // executing logic
        for(Apttus__DocumentVersionDetail__c iter : newList){
            System.debug('beforeInsert : Processing before insert logics');
            flagRenewalRecords(iter, dvInfo);
        }
    }



    public static Map<Id, Apttus__DocumentVersion__c> getAgreementsDetails(Set<String> dvIds){
        System.debug('DocumentVersionDetails_DMN.getAgreementsDetails : Start with ' + dvIds.size());
        Map<Id, Apttus__DocumentVersion__c> result = new Map<Id, Apttus__DocumentVersion__c>();

        // get data: 
        for(Apttus__DocumentVersion__c dv: [SELECT Id
            , Apttus__AgreementId__r.Apttus__Status__c
            , Apttus__AgreementId__r.CreatedDate
            FROM 	Apttus__DocumentVersion__c 
            WHERE Id IN :dvIds])
            {
                
                result.put(dv.Id, dv);
        }
        System.debug('DocumentVersionDetails_DMN.getAgreementsDetails : End');

        return result; 
    }

    public static void flagRenewalRecords(Apttus__DocumentVersionDetail__c iter, Map<Id, Apttus__DocumentVersion__c> dvInfo){
        
        System.debug('DocumentVersionDetails_DMN.flagRenewalRecords : Start');
        String agmtStatus = dvInfo.get(iter.Apttus__DocumentVersionId__c).Apttus__AgreementId__r.Apttus__Status__c; 
        Datetime agrmtCreatedDate = dvInfo.get(iter.Apttus__DocumentVersionId__c).Apttus__AgreementId__r.CreatedDate;        

        if(iter.Apttus__DocumentInfo__c != 'Final'
        && agmtStatus == 'In Renewal'
        && timestampWithin2Minutes(agrmtCreatedDate, System.now())
        ){
            System.debug('DocumentVersionDetails_DMN.flagRenewalRecords flagging record');
            iter.ToProcessDelete__c = true;
        }
        System.debug('DocumentVersionDetails_DMN.flagRenewalRecords : End');
    }

    public static boolean timestampWithin2Minutes(Datetime start, DateTime endTime){
        // Calculate the difference in milliseconds between the timestamps
        Long differenceInMilliseconds = Math.abs(endTime.getTime() - start.getTime());
        
        // Convert milliseconds to minutes
        Long differenceInMinutes = differenceInMilliseconds / (1000 * 60);
        
        // Check if the difference is within 2 minutes
        return differenceInMinutes <= 2;
    }

    public static String changeToPDF(String inputString) {
        Integer lastDotIndex = inputString.lastIndexOf('.');
        if (lastDotIndex != -1) {
            // Extract the substring before the last dot
            String substringBeforeDot = inputString.substring(0, lastDotIndex + 1);
            // Concatenate the substring before the dot with ".pdf"
            return substringBeforeDot + 'pdf';
        } else {
            // If there's no dot in the input string, simply append ".pdf"
            return inputString + '.pdf';
        }
    }
}