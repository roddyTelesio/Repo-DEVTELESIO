public with sharing class AP53_UpdateSAStatus {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Update Special Acceptance Status - Internal + Ceding Company Portal
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
--11-Jan-2021  MBE   1.0      Initial version
--01-JUL-2021  MBE   1.1      W-0973 - Special Acceptance - Problème de maj statut SA suite à une réponse sur le portail BR
--------------------------------------------------------------------------------------
**************************************************************************************/

    /**
    * @description Method to update Special Acceptance Status (Internal + Portal)
    * @param List<Request__c> lstNewRequests
    * @return void
    */
    public static void updateSaStatus(List<Request__c> lstNewRequests){
        Set<Id> setSaId = new Set<Id>();
        List<Request__c> lstAllSaRequests = new List<Request__c>();
        List<SpecialAcceptance__c> lstSaStatus = new List<SpecialAcceptance__c>();
        Map<Id, List<Request__c>> mapLstRequestBySa = new Map<Id, List<Request__c>>();
        Map<Id, Id> mapCedingSaByCeSa = new Map<Id, Id>();
        Savepoint sp = Database.setSavepoint();

        try {
            for(Request__c saReq : lstNewRequests){
                setSaId.add(saReq.Special_Acceptance__c);
            }

            if(setSaId.size() > 0){
                lstAllSaRequests = [SELECT Id, Name, SA_Request_Status__c, Special_Acceptance__r.SentAgreFromSpecialAcceptance__c, SA_Type__c FROM Request__c WHERE Special_Acceptance__c IN :setSaId AND OriginalRequest__c != NULL AND LastVersionSent__c = True AND LastVersionAnswered__c = True];
            }

            for(Request__c saReq : lstAllSaRequests){
                List<Request__c> lstSaRequest = new List<Request__c>();

                if(mapLstRequestBySa.containsKey(saReq.Special_Acceptance__c)){
                    lstSaRequest = mapLstRequestBySa.get(saReq.Special_Acceptance__c);
                }
                
                lstSaRequest.add(saReq);
                mapLstRequestBySa.put(saReq.Special_Acceptance__c, lstSaRequest);

                if(saReq.Special_Acceptance__r.SentAgreFromSpecialAcceptance__c != null){
                    if(!mapCedingSaByCeSa.containsKey(saReq.Special_Acceptance__r.SentAgreFromSpecialAcceptance__c)){
                        mapCedingSaByCeSa.put(saReq.Special_Acceptance__c, saReq.Special_Acceptance__r.SentAgreFromSpecialAcceptance__c);
                    }
                }
            }

            for(Id saId : mapLstRequestBySa.keySet()){
                Integer sentReq = 0;    
                Integer agreedReq = 0;
                Integer refusedReq = 0;
                Integer needMoreInfoSubjectivitiesReq = 0;
                Integer lengthOfReq = mapLstRequestBySa.get(saId).size();
                Integer notFollowerReq = 0;
                String saInternalStatus;
                String saPortalStatus;

                for(Request__c saReq : mapLstRequestBySa.get(saId)){
                    if(saReq.SA_Type__c != 'Follower'){
                        notFollowerReq = notFollowerReq + 1;
                    }

                    if(saReq.SA_Request_Status__c == AP_Constant.statusSent){
                        // When SA requests are sent to broker or reinsurer
                        sentReq = sentReq + 1;
                    }
                    else if(saReq.SA_Request_Status__c == AP_Constant.statusAgreed && saReq.SA_Type__c != 'Follower'){
                        // For internal : When all SA requests for Leaders, pools and followers as leader are on status agreed
                        agreedReq = agreedReq + 1;
                    }
                    else if(saReq.SA_Request_Status__c == AP_Constant.statusRefused && saReq.SA_Type__c != 'Follower'){
                        // For internal : When at least one SA request for Leaders, pools and followers as leader is on status refused
                        refusedReq = refusedReq + 1;
                    }
                    else if(saReq.SA_Request_Status__c == AP_Constant.statusNeedMoreInfo){
                        needMoreInfoSubjectivitiesReq = needMoreInfoSubjectivitiesReq + 1;
                    }        
                }

                Integer remainingSentReq = lengthOfReq - (agreedReq + needMoreInfoSubjectivitiesReq);

                if(sentReq == lengthOfReq){
                    saInternalStatus = AP_Constant.statusSent;
                    saPortalStatus = AP_Constant.statusSentToReinsurer;
                }
                else if(agreedReq == notFollowerReq){
                    saInternalStatus = AP_Constant.statusAgreed;
                    //to update portal status in Ceding Company Portal
                }
                else if(refusedReq > 0){
                    saInternalStatus = AP_Constant.statusRefused;
                    //to update portal status in Ceding Company Portal
                }
                else if((agreedReq > 0 || needMoreInfoSubjectivitiesReq > 0) && (sentReq == remainingSentReq)){
                    // For Internal : When some answered requests are on "agreed" or "need more information/subjectivies" and the rest is on status sent
                    saInternalStatus = AP_Constant.statusPending;
                }

                if(saInternalStatus != null){
                    SpecialAcceptance__c saCeInternal = new SpecialAcceptance__c();
                    saCeInternal.Id = saId;
                    saCeInternal.InternalStatus__c = saInternalStatus;
                    lstSaStatus.add(saCeInternal);

                    if(mapCedingSaByCeSa.containsKey(saCeInternal.Id)){
                        Id cedingSaId = mapCedingSaByCeSa.get(saCeInternal.Id);

                        if(saPortalStatus == AP_Constant.statusSentToReinsurer){
                            //to update ceding company portal sa status
                            SpecialAcceptance__c saCedingPortal = new SpecialAcceptance__c();
                            saCedingPortal.Id = cedingSaId;
                            saCedingPortal.PortalStatus__c = saPortalStatus;
                            lstSaStatus.add(saCedingPortal);
                        }
                    }
                }
            }

            if(lstSaStatus.size() > 0){
                update lstSaStatus;
            }
        }
        catch (Exception ex) {
            Database.rollback(sp);
        }  
    }
}