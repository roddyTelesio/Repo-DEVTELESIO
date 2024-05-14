public with sharing class RequestTriggerHandler {
    /**************************************************************************************
    -- - Author        : Spoon Consulting
    -- - Description   : Request Trigger Handler Class
    --
    -- Maintenance History:
    --
    -- Date         Name  Version  Remarks
    -- -----------  ----  -------  -------------------------------------------------------
    -- 25-JUN-2019  NBI    1.0     Initial Version
    -- 01-JUL-2021  MBE    1.1     W-0973 - Special Acceptance - Problème de maj statut SA suite à une réponse sur le portail BR
    -- 03-NOV-2021  MBE    1.2     W-1037 - message d'erreur à l'envoie des quotes
    --------------------------------------------------------------------------------------
    **************************************************************************************/
    
        public RequestTriggerHandler() {}
    
        public void handleAfterUpdate(List<Request__c> lstOldRequests, List<Request__c> lstNewRequests){
            System.debug ('START RequestTriggerHandler for handleAfterUpdate');
            List<Request__c> lstSaStatusRequests = new List<Request__c>();
            List<Id> lstRequestsId = new List<Id>();
            Map<Id, Request__c> mapOldReq = new Map<Id, Request__c>(lstOldRequests);
            Map<Id, Request__c> mapNewReq = new Map<Id, Request__c>(lstNewRequests);
            String phase;
    
            for(Request__c newReq : mapNewReq.values()){
                if(PAD.canRun('AP38_CreateSharingForRequest')){
                    if((newReq.ReinsurerStatus__c == 'Sent' || newReq.ReinsurerStatus__c == 'Timeout')){ //mapOldReq.get(newReq.Id).ReinsurerStatus__c != newReq.ReinsurerStatus__c && 
                        lstRequestsId.add(newReq.Id);
                        phase = newReq.TECH_PhaseType__c;
                        System.debug ('@@lstNewRequestsId ReinsurerStatus__c has changed and Send Button is clicked @@= ' + lstRequestsId);
                    }
                    else if(mapOldReq.get(newReq.Id).SA_Request_Status__c != newReq.SA_Request_Status__c && (newReq.SA_Request_Status__c == 'Sent' || newReq.SA_Request_Status__c == 'Notified')){
                        lstRequestsId.add(newReq.Id);
                        phase = newReq.TECH_PhaseType__c;
                    }
                    else if(mapOldReq.get(newReq.Id).SA_Request_Status__c == newReq.SA_Request_Status__c && newReq.SA_Request_Status__c == 'Agreed' && newReq.SA_Type__c != 'Follower' && mapOldReq.get(newReq.Id).TECH_NotifyBtnClick__c != newReq.TECH_NotifyBtnClick__c){
                        //Create Sharing for Leader/Pool/Follower As Leader after Notify Follower Requests
                        lstRequestsId.add(newReq.Id);
                        phase = newReq.TECH_PhaseType__c;
                    }
                     System.debug ('@@lstNewRequestsId with Original request null or not in After Update@@= ' + lstRequestsId);
                }
    
                if(PAD.canRun('AP53_UpdateSAStatus')){
                    if(mapOldReq.get(newReq.Id).SA_Request_Status__c != newReq.SA_Request_Status__c){
                        lstSaStatusRequests.add(newReq);
                    }
                }
            }
    
            Profile userProfile = [Select Name from Profile where Id =: userinfo.getProfileid()];
            String pname = userProfile.name;
    
            System.debug ('@@userProfile@@= ' + userProfile);
    
            if(pname == 'Partner Community User' || pname == 'AGRE_Community External User' || pname == 'AGRE_Community Internal User' || pname == 'AGRE_Community User OLD' || pname == 'portal_vf Profile') {
            }
            else if(PAD.canRun('AP38_CreateSharingForRequest') && lstRequestsId.size() > 0){
                AP38_CreateSharingForRequest.createRequestSharing(lstRequestsId, phase);
                System.debug ('handleAfterUpdate AP38_CreateSharingForRequest.createSharingForRequest DONE');
            }
    
            if(PAD.canRun('AP53_UpdateSAStatus') && lstSaStatusRequests.size() > 0){
                AP53_UpdateSAStatus.updateSaStatus(lstSaStatusRequests);
            }
            System.debug ('END RequestTriggerHandler for handleAfterUpdate');
        }
    
        public void handleAfterInsert(List<Request__c> lstNewRequests){
            System.debug ('START RequestTriggerHandler for handleAfterInsert');
            System.debug ('@@lstNewRequestsAfterInsert@@== '+ lstNewRequests);
            List<Request__c> lstSaStatusRequests = new List<Request__c>();
            List<Id> lstRequestsId = new List<Id>();
            String phase;
            Map<Id, Request__c> mapNewReq = new Map<Id, Request__c>(lstNewRequests);
    
            for(Request__c newReq : lstNewRequests){
                if(PAD.canRun('AP38_CreateSharingForRequest')){
                    System.debug ('handleAfterInsert lstRequestsId == ' + lstRequestsId);
                    if(newReq.OriginalRequest__c != null){
                        lstRequestsId.add(newReq.Id);
                        phase = newReq.TECH_PhaseType__c;
                        System.debug ('@@ lstNewRequestsId with OriginalRequest__c NOT NULL Only@@ = ' + lstRequestsId);
                    }
                }
    
                if(PAD.canRun('AP53_UpdateSAStatus')){
                    if(newReq.SA_Request_Status__c != null){
                        lstSaStatusRequests.add(newReq);
                    }
                }
            }
    
            if(PAD.canRun('AP38_CreateSharingForRequest') && lstRequestsId.size() > 0){
                AP38_CreateSharingForRequest.createRequestSharing(lstRequestsId, phase);
                 System.debug ('handleAfterInsert AP38_CreateSharingForRequest.createSharingForRequest DONE with OriginalRequest__c NOT NULL');
            }
    
            if(PAD.canRun('AP53_UpdateSAStatus') && lstSaStatusRequests.size() > 0){
                AP53_UpdateSAStatus.updateSaStatus(lstSaStatusRequests);
            }
             System.debug ('END RequestTriggerHandler for handleAfterInsert');
        }
    
        public void handleBeforeDelete(List<Request__c> lstDeletedRequests){
            if(PAD.canRun('AP43_DeleteClonedRequests') && lstDeletedRequests.size() > 0){
                AP43_DeleteClonedRequests.DeleteClonedRequests(lstDeletedRequests);
            }
        }
    
        public void handleAfterDelete(List<Request__c> lstDeletedRequests){
            if(PAD.canRun('AP42_DeleteDocumentVisibility') && lstDeletedRequests.size() > 0){
               AP42_DeleteDocumentVisibility.deleteDocumentVisibility(lstDeletedRequests);
            }
        }
    
        public void handleBeforeUpdate(List<Request__c> lstOldRequests, List<Request__c> lstNewRequests){
            if(PAD.canRun('AP60_UpdateRequestStatus') && lstNewRequests.size() > 0){
                AP60_UpdateRequestStatus.updateRequestStatus(lstOldRequests, lstNewRequests);
            }
        }
    }