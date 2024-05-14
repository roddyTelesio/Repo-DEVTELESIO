public with sharing class ContentDocumentLink_DMN {


    public static void markForDeletion(List<ContentDocumentLink> newList){
        System.debug('ContentDocumentLink_DMN.markForDeletion start' + newlist.size());
        
        // variables for retrieve related record information
        Set<String> dvdIds = new Set<String>(); 
        Set<String> agmtIds = new Set<String>();
        List<Apttus__DocumentVersionDetail__c> dvdToUpdate = new List<Apttus__DocumentVersionDetail__c>();
        Map<Id, Apttus__DocumentVersionDetail__c> finalVersionPerAgreement = new Map<Id, Apttus__DocumentVersionDetail__c>();


        // get Agreement info
        for(ContentDocumentLink cdl : newList){
        
            String sObjectType = SObjectTypeIdentifier.getSObjectTypeById(cdl.LinkedEntityId);
            if(sObjectType == 'Apttus__DocumentVersionDetail__c'){
                System.debug('ContentDocumentLink_DMN.markForDeletion Apttus__DocumentVersionDetail__c type true');
                dvdIds.add(cdl.LinkedEntityId);
            }
            System.debug('ContentDocumentLink_DMN.markForDeletion SObject Type: ' + sObjectType);
        }


        Map<Id, Apttus__DocumentVersionDetail__c> dvdDetails = new Map<Id, Apttus__DocumentVersionDetail__c>();
        Map<Id, Id> finalAgmtVersion = new Map<Id,Id>(); 
        Map<Id, Apttus__APTS_Agreement__c> agrmtToUpdate = new Map<Id, Apttus__APTS_Agreement__c>(); 


        if(!dvdIds.isEmpty()){
            finalAgmtVersion = getFinalVersionPerAgmt(dvdIds);
            dvdDetails = getDvdDetails(dvdIds);
        }


        // get Agreement info
        for(Id dvdId: dvdDetails.keySet()){
        
            Apttus__DocumentVersionDetail__c dvd = dvdDetails.get(dvdId);

            if(
                dvd.Apttus__DocumentVersionId__r.Apttus__AgreementId__r.Apttus__Status__c == 'In Renewal'
                && dvd.Apttus__DocumentInfo__c == 'Final'
                && timestampWithin2Minutes(dvd.Apttus__DocumentVersionId__r.Apttus__AgreementId__r.CreatedDate , dvd.createdDate)
                && (
                    finalAgmtVersion.containsKey(dvd.Apttus__DocumentVersionId__r.Apttus__AgreementId__c) 
                    && finalAgmtVersion.get(dvd.Apttus__DocumentVersionId__r.Apttus__AgreementId__c) == dvdId ) 
            ){
                System.debug('ContentDocumentLink_DMN.markForDeletion Absolute final version found');
                dvd.Name = '1.0.0';
                dvd.Apttus__VersionMajor__c = 1; 
                dvd.Apttus__VersionMinor__c = 0; 
                dvd.Apttus__VersionRevision__c = 0; 
                dvd.ToProcessDelete__c = false; 
                dvd.Apttus__ParentDocumentVersionDetailId__c = null; 
                dvdToUpdate.add(dvd);

                agrmtToUpdate.put(dvd.Apttus__DocumentVersionId__r.Apttus__AgreementId__c, 
                new Apttus__APTS_Agreement__c(
                    Id = dvd.Apttus__DocumentVersionId__r.Apttus__AgreementId__c
                    ,IsBeingRenewed__c = false
                    ,TECH_TriggerSyncAGL__c = true
                    ,DeleteRenewedAgreementDocuments__c = true
                    )
                );
            }else if(dvd.Apttus__DocumentVersionId__r.Apttus__AgreementId__r.Apttus__Status__c == 'In Renewal'
            && timestampWithin2Minutes(dvd.Apttus__DocumentVersionId__r.Apttus__AgreementId__r.CreatedDate , dvd.createdDate)
            ){
                System.debug('ContentDocumentLink_DMN.markForDeletion Apttus__DocumentVersionDetail__c loop 2 type true');
                dvd.ToProcessDelete__c = true; 
                dvdToUpdate.add(dvd);
            }
        }

        if(!dvdToUpdate.isEmpty()){
            System.debug('ContentDocumentLink_DMN.markForDeletion update dvds');
            update dvdToUpdate; 
            Queueable_SVC.checkLaunch('AgreementRenewal_QUE');
        }


        if(!agrmtToUpdate.isEmpty()){
            update agrmtToUpdate.values(); 
        }

        //retrieve required information for marking for deletion: 
        
        System.debug('ContentDocumentLink_DMN.markForDeletion end' + newlist.size());
    }


    public static Map<Id, Apttus__DocumentVersionDetail__c> getDvdDetails(Set<String> dvdIds){
        System.debug('ContentDocumentLink_DMN.getDvdDetails : Start with ' + dvdIds.size());
        Map<Id, Apttus__DocumentVersionDetail__c> result = new Map<Id, Apttus__DocumentVersionDetail__c>();

        // get data: 
        for(Apttus__DocumentVersionDetail__c dvd: [SELECT Id
            , Apttus__DocumentVersionId__r.Apttus__AgreementId__r.Apttus__Status__c
            , Apttus__DocumentInfo__c, Apttus__DocumentVersionId__r.Apttus__AgreementId__r.CreatedDate
            , CreatedDate 
            FROM Apttus__DocumentVersionDetail__c 
            WHERE Id IN :dvdIds])
            {
                
                result.put(dvd.Id, dvd);
        }
        System.debug('ContentDocumentLink_DMN.getDvdDetails : End');

        return result; 
    }


    public static Map<Id, Id> getFinalVersionPerAgmt(Set<String> dvdIds){
        System.debug('ContentDocumentLink_DMN.getDvdDetails : Start with ' + dvdIds.size());
        Map<Id, Id> result = new Map<Id, Id>();

        Set<Id> agreementIds = new Set<id>();

        // get list of agreements 
        for(Apttus__DocumentVersionDetail__c dvd: [SELECT Id
            , Apttus__DocumentVersionId__r.Apttus__AgreementId__r.Apttus__Status__c
            , Apttus__DocumentInfo__c, Apttus__DocumentVersionId__r.Apttus__AgreementId__r.CreatedDate
            ,Apttus__DocumentVersionId__r.Apttus__AgreementId__c
            , CreatedDate 
        FROM Apttus__DocumentVersionDetail__c 
        WHERE Id IN :dvdIds
        AND Apttus__DocumentInfo__c = 'Final'
        ORDER By CreatedDate DESC
            ])
        {  
            agreementIds.add(dvd.Apttus__DocumentVersionId__r.Apttus__AgreementId__c);
        }


        for(Apttus__DocumentVersionDetail__c dvd: [SELECT Id
            , Apttus__DocumentVersionId__r.Apttus__AgreementId__r.Apttus__Status__c
            , Apttus__DocumentInfo__c, Apttus__DocumentVersionId__r.Apttus__AgreementId__r.CreatedDate
            ,Apttus__DocumentVersionId__r.Apttus__AgreementId__c
            , CreatedDate 
        FROM Apttus__DocumentVersionDetail__c 
        WHERE Apttus__DocumentVersionId__r.Apttus__AgreementId__c IN :agreementIds
        AND Apttus__DocumentInfo__c = 'Final'
        ORDER By CreatedDate DESC]
        ){
            result.put(dvd.Apttus__DocumentVersionId__r.Apttus__AgreementId__c, dvd.Id);
        }
        System.debug('ContentDocumentLink_DMN.getDvdDetails : End');

        return result; 
    }

    public static boolean timestampWithin2Minutes(Datetime start, DateTime endTime){
        // Calculate the difference in milliseconds between the timestamps
        Long differenceInMilliseconds = Math.abs(endTime.getTime() - start.getTime());
        
        // Convert milliseconds to minutes
        Long differenceInMinutes = differenceInMilliseconds / (1000 * 60);
        
        // Check if the difference is within 2 minutes
        return differenceInMinutes <= 4;
    }

}