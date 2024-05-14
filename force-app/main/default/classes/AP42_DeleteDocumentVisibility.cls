public with sharing class AP42_DeleteDocumentVisibility {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Delete document/document visibility for request
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 05-AUG-2020  SAU   1.0      Initial version
-- 01-DEC-2020  NBI   1.1      Bug on delete Placement Requests
                               Changes for new Broker/Reinsurer fields on Document Visibility
-- 26-AUG-2021  MBE   1.2      SOQL Injection 
--------------------------------------------------------------------------------------
**************************************************************************************/

    /**
    * @description Method to delete Document/Document Visibility when Requests are deleted
    * @param List<Request__c> lstDeletedRequests
    * @return void
    */
    public static void deleteDocumentVisibility(List<Request__c> lstDeletedRequests){
        Map<String, Id> mapRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectRequest});
        String recordTypeIdQuote = mapRecTypeId.get(AP_Constant.reqRTQuote);
        String recordTypeIdLead = mapRecTypeId.get(AP_Constant.reqRTLead);
        String recordTypeIdPlacement = mapRecTypeId.get(AP_Constant.reqRTPlacement);
        List <DocumentVisibility__c> lstDocVisibilityToDelete = new List<DocumentVisibility__c>();
        List <ContentDocument> lstContentDocumentTodelete = new List<ContentDocument>();

        //handle bulk
        List <Request__c> lstDelQuoteRequests = new List<Request__c>();
        List <Request__c> lstDelLeadRequests = new List<Request__c>();
        List <Request__c> lstDelPlacementRequests = new List<Request__c>();

        //set request id
        Set <Id> setQuoteReqId = new Set<Id>();
        Set <Id> setLeadReqId = new Set<Id>();
        Set <Id> setPlacementReqId = new Set<Id>();
        
        //set program Id
        Set <Id> setQuoteProgramId = new Set<Id>();
        Set <Id> setLeadProgramId = new Set<Id>();
        Set <Id> setPlacementProgramId = new Set<Id>();

        //Set of broker and reins
        Set <Id> setQuoteBrokerId = new Set<Id>();
        Set <Id> setQuoteReinsId = new Set<Id>();
        Set <Id> setLeadBrokerId = new Set<Id>();
        Set <Id> setLeadReinsId = new Set<Id>();
        Set <Id> setPlacementBrokerId = new Set<Id>();
        Set <Id> setPlacementReinsId = new Set<Id>();

        Set<Id> setDocVisibilityId = new Set <Id>();

        //Phase
        Boolean isQuote = false;
        Boolean isLead = false;
        Boolean isPlacement = false;

        for(Request__c deletedRequest : lstDeletedRequests){
            if(deletedRequest.RecordTypeId == recordTypeIdQuote){
               lstDelQuoteRequests.add(deletedRequest);
               setQuoteReqId.add(deletedRequest.Id);
               setQuoteProgramId.add(deletedRequest.Program__c);
               isQuote = true;

               if(deletedRequest.Broker__c != null){
                    setQuoteBrokerId.add(deletedRequest.Broker__c);
               }
               if(deletedRequest.Reinsurer__c != null){
                    setQuoteReinsId.add(deletedRequest.Reinsurer__c);
               }
            }
            else if(deletedRequest.RecordTypeId == recordTypeIdLead){
                lstDelLeadRequests.add(deletedRequest);
                setLeadReqId.add(deletedRequest.Id);
                setLeadProgramId.add(deletedRequest.Program__c);
                isLead = true;

                if(deletedRequest.Broker__c != null){
                    setLeadBrokerId.add(deletedRequest.Broker__c);
                }
                if(deletedRequest.Reinsurer__c != null){
                    setLeadReinsId.add(deletedRequest.Reinsurer__c);
                }
            }
            else if(deletedRequest.RecordTypeId == recordTypeIdPlacement){
                lstDelPlacementRequests.add(deletedRequest);
                setPlacementReqId.add(deletedRequest.Id);
                setPlacementProgramId.add(deletedRequest.Program__c);
                isPlacement = true;

                if(deletedRequest.Broker__c != null){
                    setPlacementBrokerId.add(deletedRequest.Broker__c);
                }
                if(deletedRequest.Reinsurer__c != null){
                    setPlacementReinsId.add(deletedRequest.Reinsurer__c);
                }
            }
        }
        if(isQuote == true){
            Set<Id> setOtherReins = new Set<Id>();
            Set<String> setOtherBrokerReins = new Set<String>();
            Set<String> setBrokerReinsToDelete = new Set<String>();
            List <Request__c> lstOtherQuoteRequests =[SELECT Id, Broker__c, Reinsurer__c
                                                      FROM Request__c
                                                      WHERE Id NOT IN :setQuoteReqId
                                                      AND Program__c IN :setQuoteProgramId
                                                      AND RecordTypeId =:recordTypeIdQuote];

            for(Request__c otherReq : lstOtherQuoteRequests){
                if(otherReq.Broker__c == null){
                    setOtherReins.add(otherReq.Reinsurer__c);
                }
                else{
                    setOtherBrokerReins.add(otherReq.Broker__c + '-' + otherReq.Reinsurer__c);
                }
            }

            for(Request__c req : lstDelQuoteRequests){
                String brokerReins = req.Broker__c + '-' + req.Reinsurer__c;
                if(req.Broker__c == null && !setOtherReins.contains(req.Reinsurer__c)){
                    setBrokerReinsToDelete.add('NoBroker - ' + req.Reinsurer__c);
                }
                if(req.Broker__c != null && !setOtherBrokerReins.contains(brokerReins)){
                    setBrokerReinsToDelete.add(brokerReins);
                }
            }

            if(setBrokerReinsToDelete.size() > 0){
                Set<Id> setProgContentDocumentId = new Set<Id>();
                Set<Id> setContentVersionId = new Set<Id>();
                Set<Id> setDocToDelete = new Set<Id>();
                Set<Id> setAXAQuoteDocs = new Set<Id>();
        
                for(ContentDocumentLink contentDocLink : [SELECT Id, ContentDocumentId
                                                          FROM ContentDocumentLink
                                                          WHERE LinkedEntityId IN :setQuoteProgramId]){
                    setProgContentDocumentId.add(contentDocLink.ContentDocumentId);
                }

                List <ContentDocument> lstDocs = [SELECT Id, LatestPublishedVersionId
                                                  FROM ContentDocument 
                                                  WHERE Id IN: setProgContentDocumentId];

                for(ContentDocument doc : lstDocs){
                    setContentVersionId.add(doc.LatestPublishedVersionId);
                }

                String contentVersionType = '1';

                for(ContentVersion contentVersion : [SELECT Id, 
                                                            ContentDocumentId,
                                                            IsExternal__c
                                                     FROM ContentVersion
                                                     WHERE Id IN :setContentVersionId
                                                     AND Phase__c = :contentVersionType]){

                    if(contentVersion.IsExternal__c == true){
                        setDocToDelete.add(contentVersion.Id);
                    }
                    else{
                        setAXAQuoteDocs.add(contentVersion.Id);
                    }
                }

                for(ContentDocument doc : lstDocs){
                   if(setDocToDelete.contains(doc.LatestPublishedVersionId)){
                       lstContentDocumentTodelete.add(doc);
                   }
                }

                // delete visibility to axa documents for quote phase
                for(DocumentVisibility__c docVisibility : [ SELECT Id, ContentVersionId__c, Broker__c, Reinsurer__c
                                                            FROM DocumentVisibility__c
                                                            WHERE Program__c IN: setQuoteProgramId
                                                          ]){
                    String brkReins = docVisibility.Broker__c ==  null ? 'NoBroker - ' + docVisibility.Reinsurer__c : docVisibility.Broker__c + '-' + docVisibility.Reinsurer__c;
                    if(setBrokerReinsToDelete.contains(brkReins)){
                        if(setDocVisibilityId.contains(docVisibility.Id) == false && (setAXAQuoteDocs.contains(docVisibility.ContentVersionId__c) || setDocToDelete.contains(docVisibility.ContentVersionId__c))) {
                            lstDocVisibilityToDelete.add(docVisibility);
                            setDocVisibilityId.add(docVisibility.Id);
                        }
                    }
                }
            }
        }

        if(isLead == true){
            Map<Id,List<Request__c>> mapTreatyIdToLeadRequests = new Map<Id, List<Request__c>>();
            Set<Id> setOtherReins = new Set<Id>();
            Set<String> setOtherBrokerReins = new Set<String>();
            Set<String> setBrokerReinsToDelete = new Set<String>();
            Set<Id> setAXALeadDocs = new Set<Id>();
            String strParent = 'parent';

            for(Request__c leadRequest : [SELECT Id, Treaty__c, Broker__c, Reinsurer__c
                                          FROM Request__c
                                          WHERE RecordTypeId =: recordTypeIdLead
                                          AND Id NOT IN :setLeadReqId
                                          AND Program__c IN :setLeadProgramId
                                          AND TECH_LeadType__c = :strParent]){

                if(leadRequest.Broker__c == null){
                    setOtherReins.add(leadRequest.Reinsurer__c);
                }
                else{
                    setOtherBrokerReins.add(leadRequest.Broker__c + '-' + leadRequest.Reinsurer__c);
                }

                if(mapTreatyIdToLeadRequests.containsKey(leadRequest.Treaty__c)){
                    List <Request__c> lstReq = mapTreatyIdToLeadRequests.get(leadRequest.Treaty__c);
                    lstReq.add(leadRequest);
                    mapTreatyIdToLeadRequests.put(leadRequest.Treaty__c, lstReq);
                }
                else{
                    List <Request__c> lstReq = new List<Request__c>();
                    lstReq.add(leadRequest);
                    mapTreatyIdToLeadRequests.put(leadRequest.Treaty__c, lstReq);
                }
            }

            for(Request__c req : lstDelLeadRequests){
                String brokerReins = req.Broker__c + '-' + req.Reinsurer__c;
                if(req.Broker__c == null && !setOtherReins.contains(req.Reinsurer__c)){
                    setBrokerReinsToDelete.add('NoBroker - ' + req.Reinsurer__c);
                }
                if(req.Broker__c != null && !setOtherBrokerReins.contains(brokerReins)){
                    setBrokerReinsToDelete.add(brokerReins);
                }
            }

            //delete doc visibility + content document
            if(setBrokerReinsToDelete.size() > 0){
                Set <Id> setContentVersionId = new Set <Id>(); 

                Set<Id> setProgContentDocumentId = new Set<Id>();
                Set<Id> setDocToDelete = new Set<Id>();
        
                for(ContentDocumentLink contentDocLink : [SELECT Id, ContentDocumentId
                                                          FROM ContentDocumentLink
                                                          WHERE LinkedEntityId IN :setLeadProgramId]){
                    setProgContentDocumentId.add(contentDocLink.ContentDocumentId);
                }

                List <ContentDocument> lstDocs = [SELECT Id, LatestPublishedVersionId
                                                  FROM ContentDocument 
                                                  WHERE Id IN: setProgContentDocumentId];
                for(ContentDocument doc : lstDocs){
                    setContentVersionId.add(doc.LatestPublishedVersionId);
                }

                // get content version which is external
                String strContentVersionPhase = '3';
                for(ContentVersion contentVersion : [SELECT Id,
                                                            ContentDocumentId,
                                                            IsExternal__c
                                                     FROM ContentVersion
                                                     WHERE Id IN :setContentVersionId
                                                     AND Phase__c = :strContentVersionPhase]){
                    if(contentVersion.IsExternal__c == true){
                        setDocToDelete.add(contentVersion.Id);
                    }
                    else{
                        setAXALeadDocs.add(contentVersion.Id);
                    }
                }

                for(ContentDocument doc : lstDocs){
                   if(setDocToDelete.contains(doc.LatestPublishedVersionId)){
                        lstContentDocumentTodelete.add(doc);
                   }
                }
                  // visibility of axa documents to broker/reins for phase Lead
                for(DocumentVisibility__c docVisibility : [ SELECT Id, ContentVersionId__c, Broker__c, Reinsurer__c
                                                          FROM DocumentVisibility__c
                                                          WHERE Program__c IN: setLeadProgramId]){
                    String brkReins = docVisibility.Broker__c ==  null ? 'NoBroker - ' + docVisibility.Reinsurer__c : docVisibility.Broker__c + '-' + docVisibility.Reinsurer__c;

                    if(setBrokerReinsToDelete.contains(brkReins)) {
                        if (setDocVisibilityId.contains(docVisibility.Id) == false && (setAXALeadDocs.contains(docVisibility.ContentVersionId__c) || setDocToDelete.contains(docVisibility.ContentVersionId__c))) {
                            lstDocVisibilityToDelete.add(docVisibility);
                            setDocVisibilityId.add(docVisibility.Id);
                        }
                    }
                }
            }

            //when all lead request for a treaty is deleted, set retained sections to false
            Set <Id> setTreatyIds = new Set<Id>();
            for(Request__c deletedReq : lstDeletedRequests){
                if(!mapTreatyIdToLeadRequests.containsKey(deletedReq.Treaty__c)){
                    setTreatyIds.add(deletedReq.Treaty__c);
                }
            }
        }
        
        if(isPlacement == true){
            Set<Id> setOtherReins = new Set<Id>();
            Set<String> setOtherBrokerReins = new Set<String>();
            Set<String> setBrokerReinsToDelete = new Set<String>();
            Set <Id> setAXAPlacementDocs = new Set<Id>();

            for(Request__c placementReq : [SELECT Id, Treaty__c, Broker__c, Reinsurer__c
                                          FROM Request__c
                                          WHERE RecordTypeId =: recordTypeIdPlacement
                                          AND Id NOT IN :setPlacementReqId
                                          AND Program__c IN :setPlacementProgramId]){

                if(placementReq.Broker__c == null){
                    setOtherReins.add(placementReq.Reinsurer__c);
                }
                else{
                    setOtherBrokerReins.add(placementReq.Broker__c + '-' + placementReq.Reinsurer__c);
                }
            }

            for(Request__c req : lstDelPlacementRequests){
                String brokerReins = req.Broker__c + '-' + req.Reinsurer__c;
                if(req.Broker__c == null && !setOtherReins.contains(req.Reinsurer__c)){
                    setBrokerReinsToDelete.add('NoBroker - ' + req.Reinsurer__c);
                }
                if(req.Broker__c != null && !setOtherBrokerReins.contains(brokerReins)){
                    setBrokerReinsToDelete.add(brokerReins);
                }
            }

            //delete doc visibility + content document
            if(setBrokerReinsToDelete.size() > 0){
                Set <Id> setContentVersionId = new Set <Id>();
                Set<Id> setProgContentDocumentId = new Set<Id>();
                Set<Id> setDocToDelete = new Set<Id>();
                for(ContentDocumentLink contentDocLink : [SELECT Id, ContentDocumentId
                                                          FROM ContentDocumentLink
                                                          WHERE LinkedEntityId IN :setPlacementProgramId]){
                    setProgContentDocumentId.add(contentDocLink.ContentDocumentId);
                }

                List <ContentDocument> lstDocs = [SELECT Id,
                                                         LatestPublishedVersionId 
                                                  FROM ContentDocument 
                                                  WHERE Id IN: setProgContentDocumentId];
                for(ContentDocument doc : lstDocs){
                    setContentVersionId.add(doc.LatestPublishedVersionId);
                }

                // get content version which is external
                String strContentVersionPhase2 = '2';
                for(ContentVersion contentVersion : [SELECT Id, ContentDocumentId, IsExternal__c
                                                     FROM ContentVersion
                                                     WHERE Id IN :setContentVersionId
                                                     AND Phase__c = :strContentVersionPhase2]){

                    if(contentVersion.IsExternal__c == true){
                        setDocToDelete.add(contentVersion.Id);
                    }
                    else{
                        setAXAPlacementDocs.add(contentVersion.Id);
                    }
                }

                // visibility of axa documents to broker/reins for placement only
                for(DocumentVisibility__c docVisibility : [ SELECT Id, ContentVersionId__c, Broker__c, Reinsurer__c
                                                            FROM DocumentVisibility__c
                                                            WHERE Program__c IN :setPlacementProgramId]){

                    String brkReins = docVisibility.Broker__c ==  null ? 'NoBroker - ' + docVisibility.Reinsurer__c : docVisibility.Broker__c + '-' + docVisibility.Reinsurer__c;

                    if(setBrokerReinsToDelete.contains(brkReins)) {

                        if (setDocVisibilityId.contains(docVisibility.Id) == false && (setAXAPlacementDocs.contains(docVisibility.ContentVersionId__c) || setDocToDelete.contains(docVisibility.ContentVersionId__c))) {
                            lstDocVisibilityToDelete.add(docVisibility);
                            setDocVisibilityId.add(docVisibility.Id);
                        }
                    }
                }

                for(ContentDocument doc : lstDocs){
                   if(setDocToDelete.contains(doc.LatestPublishedVersionId)){
                       lstContentDocumentTodelete.add(doc);
                   }
                }
            }
        }
        
        if(lstDocVisibilityToDelete.size() > 0){
            delete lstDocVisibilityToDelete;
        }

        if(lstContentDocumentTodelete.size() > 0){
            delete lstContentDocumentTodelete;
        }
    }
}