public without sharing class AP43_DeleteClonedRequests {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Delete clones requests
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 13-AUG-2020  SAU   1.0      Initial version
-- 18-DEC-2020  NBI   1.1      Delete Signing phase
--------------------------------------------------------------------------------------
**************************************************************************************/
    /**
    * @description Method to delete cloned Requests of deleted Requests
    * @param List<Request__c> lstDeletedRequests
    * @return void
    */
    private static Boolean firstRun = true;

    public static Boolean isFirstRun(){
        if(firstRun){
            firstRun = false;
            return true;
        }else{
            return firstRun;
        }
    }

    public static void DeleteClonedRequests(List<Request__c> lstDeletedRequests){
        System.debug('lstDeletedRequests == ' + lstDeletedRequests);
         if(isFirstRun() == true){
            List<String> lstLeadRTName = AP_Constant.reqRTLead.split('-');
            List<String> lstQuoteRTName = AP_Constant.reqRTQuote.split('-');
            Id leadRT = Schema.SObjectType.Request__c.getRecordTypeInfosByDeveloperName().get(lstLeadRTName[1]).getRecordTypeId();
            Id quoteRT = Schema.SObjectType.Request__c.getRecordTypeInfosByDeveloperName().get(lstQuoteRTName[1]).getRecordTypeId();
            Set <Id> setClonedRequestsToDelete = new Set<Id>();
            Set<Id> setdeletedLeadReqIds = new Set<Id>();
            Set<Id> setdeletedQuoteReqIds = new Set<Id>();
            Set<Id> setIdSectionLeadRetain = new Set<Id>();
            Set <Id> setReqToRetrieve = new Set<Id>();
            List <Request__c> lstClonedReqToDelete = new List<Request__c>();
            List <Request__c> lstLeadRetainReqToUpdate = new List<Request__c>();
            Set<Id> setDelId = new Set<Id>();
            
            //RRA - ticket 1777 - 24112023
            /*Set<Id> setDelSecId = new Set<Id>();
            List <Id> lstRequestFromSameSection = new List<Id>();
            List <Id> lstRequestFromDeleteRec = new List<Id>();
            map <Id, Request__c> mapIdSecIdReq = new  map <Id, Request__c> ();
            map <Id, List<Request__c>> mapIdSeclstReq = new  map <Id, List<Request__c>> ();
            Boolean isUpdateRetainToLead = false;
            List<Id> lstIdReqSameSection = new List<Id>();*/

            for(Request__c request : lstDeletedRequests){
                
                //RRA - ticket 1777 - 24112023 - Create map <idSec, request> and get SectionId on Request
                /*if (request.Section__c !=  null && request.RecordTypeId == leadRT){
                    mapIdSecIdReq.put(request.Section__c, request);
                    setDelSecId.add(request.Section__c);
                }*/
               
                // a child request
                if(request.OriginalRequest__c != null){
                    setClonedRequestsToDelete.add(request.OriginalRequest__c);
                }
                else{
                    setClonedRequestsToDelete.add(request.Id);
                }

                if(request.RecordTypeId == leadRT){
                    setdeletedLeadReqIds.add(request.Id);
                    setIdSectionLeadRetain.add(request.Section__c); //RRA ticket 1317 - 15112022
                }
                setDelId.add(request.Id);
                
               
            }
            
            System.debug('setDelId == ' + setDelId);
            //System.debug('mapIdSecIdReq == ' + mapIdSecIdReq);
            //System.debug('setDelSecId == ' + setDelSecId);
          if(setClonedRequestsToDelete.size() > 0){
                lstClonedReqToDelete = [ SELECT Id, RecordTypeId, Section__r.Retained_to_lead__c 
                FROM Request__c
                WHERE Id IN: setClonedRequestsToDelete
                OR OriginalRequest__c IN: setClonedRequestsToDelete];

                for(Request__c clonedReq :lstClonedReqToDelete){
                    if(clonedReq.RecordTypeId == leadRT){
                        setdeletedLeadReqIds.add(clonedReq.Id);
                        setIdSectionLeadRetain.add(clonedReq.Section__c); //RRA ticket 1317 - 15112022
                    } 
                }
            }
            System.debug('setIdSectionLeadRetain == ' + setIdSectionLeadRetain);
        
          //RRA - ticket 1777 - 24112023 - Get the requests which contained the same section (take lastVerion's Request)
         /* List<Request__c> lstReq = [SELECT Id, Section__c FROM Request__c WHERE Section__c IN: setDelSecId AND (LastVersionAnswered__c=true AND LastVersionSent__c=true)];
          for (Request__c req : lstReq){
            if (mapIdSeclstReq.containsKey(req.Section__c)){
                mapIdSeclstReq.get(req.Section__c).add(req);
            }else{
                mapIdSeclstReq.put(req.Section__c, new List<Request__c>{req});
            }
          }
          System.debug('mapIdSeclstReq == ' + mapIdSeclstReq);*/
          
           //RRA - ticket 1777 - 24112023 - Get list Id of Request : 
                //1- lstRequestFromSameSection : for the requests with the same section
                //2 - lstRequestFromDeleteRec : for the request to delete on before trigger 
         /* for (Id idSec : mapIdSeclstReq.keySet()){
              for (Request__c request :  mapIdSeclstReq.get(idSec)){
                  lstRequestFromSameSection.add(request.Id);
              }
              lstRequestFromDeleteRec.add(mapIdSecIdReq.get(idSec).Id);
          }
          System.debug('lstRequestFromSameSection == ' + lstRequestFromSameSection);
          System.debug('lstRequestFromDeleteRec == ' + lstRequestFromDeleteRec);
          
          System.debug('lstRequestFromSameSectionSIZE == ' + lstRequestFromSameSection.size());
          System.debug('lstRequestFromDeleteRecSIZE == ' + lstRequestFromDeleteRec.size());*/
          
          //RRA - ticket 1777 - 24112023 :
          //if request still existe, store id Request in lstIdReqSameSection
          //if exist, initialize isUpdateRetainToLead to false (that's mean do not update flag Retained_to_lead__c to true)
         
          /*for (Id idReq : lstRequestFromSameSection){
              if (!lstRequestFromDeleteRec.contains(idReq)){
                lstIdReqSameSection.add(idReq);
              }
          }
          System.debug('lstIdReqSameSection == ' + lstIdReqSameSection);
          if (lstIdReqSameSection.size()>0){
            isUpdateRetainToLead = false;
          }else {
            isUpdateRetainToLead = true;
          }*/
          
          
          //System.debug('isUpdateRetainToLead == ' + isUpdateRetainToLead);
          //if (isUpdateRetainToLead){
               //RRA ticket 1317 and 1347 - 15112022
            List<Section__c> lstSections = [SELECT Id, Retained_to_lead__c FROM Section__c WHERE Id IN :setIdSectionLeadRetain]; 
            System.debug('lstSections == ' + lstSections);
            //RRA ticket 1317 - 15112022
            if(lstSections.size() > 0){
                for (Section__c sec : lstSections){
                    sec.Retained_to_lead__c = false;
                }
                update lstSections;
                System.debug('update done lstSections == ' + lstSections);
            }
          //}

            // get lead req selection
            List<LeadRequestSelection__c> lstLeadReqSelectionToDelete = [SELECT Id, LeadRequestChild__c, LeadRequestParent__c
            FROM LeadRequestSelection__c
            WHERE LeadRequestChild__c IN: setdeletedLeadReqIds
            OR LeadRequestParent__c IN: setdeletedLeadReqIds];
            
            System.debug('lstLeadReqSelectionToDelete == ' + lstLeadReqSelectionToDelete);

            for(LeadRequestSelection__c leadReq : lstLeadReqSelectionToDelete){
                if(setdeletedLeadReqIds.contains(leadReq.LeadRequestChild__c) && !setdeletedLeadReqIds.contains(leadReq.LeadRequestParent__c) ){
                    setReqToRetrieve.add(leadReq.LeadRequestParent__c);
                }
                if(setdeletedLeadReqIds.contains(leadReq.LeadRequestParent__c) && !setdeletedLeadReqIds.contains(leadReq.LeadRequestChild__c) ){
                    setReqToRetrieve.add(leadReq.LeadRequestChild__c);
                }
            }
            
            System.debug('setReqToRetrieve == ' + setReqToRetrieve);

            if(setReqToRetrieve.size() > 0){
                List <Request__c> lstReqToDelete = [SELECT Id
                FROM Request__c
                WHERE Id IN: setReqToRetrieve];
                if(lstReqToDelete.size() > 0){
                    lstClonedReqToDelete.addAll(lstReqToDelete);
                }
            }
            System.debug('lstClonedReqToDelete == ' + lstClonedReqToDelete);
            List<Request__c> lstReqToDelete = new List <Request__c>();
            for(Request__c request : lstClonedReqToDelete){
                if(!setDelId.contains(request.Id)){
                    lstReqToDelete.add(request);
                }
            }
            System.debug('lstReqToDelete == ' + lstReqToDelete);
            if(lstLeadReqSelectionToDelete.size() > 0){
                delete lstLeadReqSelectionToDelete;
            }

            if(lstClonedReqToDelete.size() > 0){
                delete lstReqToDelete;
            }
            firstRun = false;
        }
    }

    /**
    * @description Method to delete signing requests
    * @param Id programId
    * @return Map<String, Object>
    */
    @AuraEnabled
    public static Map<String, Object> deleteSigningRequests(Id programId){
        Map<String,Object> mapResult = new Map<String,Object>();
        Map<String, Id> mapRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectRequest});
        String recordTypeIdSigning = mapRecTypeId.get(AP_Constant.reqRTSigning);
        List<Request__c> lstUpdateFlagPreviousPhaseReq = new List<Request__c>();//RRA - ticket 1410 - 24032023
        List<Request__c> lstUpdateFlagAskValidation = new List<Request__c>();//RRA - ticket 01411 - 24032023
        List<Request__c> lstUpdateFlagAskValidationDeputyCEO = new List<Request__c>();//RRA - ticket 1827 - 08122023
        //Id recordTypeIdSignatory;

        try {
            List <Request__c> lstRequests = [SELECT Id, isReopenPreviousPhase__c, isAskValidation__c, isAskValidateByDirecteur__c
            FROM Request__c
            WHERE Program__c =: programId AND RecordTypeId = :recordTypeIdSigning
            ];//RRA - ticket 1410 / 01411 - 24032023
            Program__c program = [SELECT Id,
                    TECH_StageName__c,
                    TECH_ShowClosePreviousPhaseBtn__c
            FROM Program__c
            WHERE Id =: programId
            ];

            /*Schema.DescribeSObjectResult contactObj = Contact.SObjectType.getDescribe();

            for(Schema.RecordTypeInfo contactRT : contactObj.getRecordTypeInfos()){
                if(contactRT.getDeveloperName() == AP_Constant.contactSignatory){
                    recordTypeIdSignatory = contactRT.getRecordTypeId();
                }
            }

            List<Contact> lstSignatoriesContact = [SELECT Id
            FROM Contact
            WHERE TECH_ProgramId__c =: programId
            AND RecordTypeId = :recordTypeIdSignatory];*/
            List<ContactReinsurerProgramRelation__c> lstSignatoriesContact = [SELECT Id,ReinsurerId__c,ProgramId__c,OrderOfSignatory__c
                                                                        FROM ContactReinsurerProgramRelation__c 
                                                                        WHERE ProgramId__c =: programId
                                                                        ] ;//MRA 19/05/23 - Contact Signatory Rebuild 

            if(lstRequests.size() > 0){

                for (Request__c req : lstRequests){
                    //RRA - ticket 1410 - 24032023
                    if (req.isReopenPreviousPhase__c){
                        req.isReopenPreviousPhase__c = false;
                        lstUpdateFlagPreviousPhaseReq.add(req);
                    }
                    //RRA - ticket 01411 - 03042023
                    if (req.isAskValidation__c){
                        req.isAskValidation__c = false;
                        lstUpdateFlagAskValidation.add(req);
                    }
                    
                    //RRA - ticket 1827 - 08122023
                   if (req.isAskValidateByDirecteur__c){
                        req.isAskValidateByDirecteur__c = false;
                        lstUpdateFlagAskValidationDeputyCEO.add(req);
                    }
                }

                 //RRA - ticket 1410 - 24032023
                 if (lstUpdateFlagPreviousPhaseReq.size()>0){
                    update lstUpdateFlagPreviousPhaseReq;
                }
                //RRA - ticket 01411 - 03042023
                if (lstUpdateFlagAskValidation.size()>0){
                    update lstUpdateFlagAskValidation;
                }
                
                //RRA - ticket 1827 - 08122023
                if (lstUpdateFlagAskValidationDeputyCEO.size()>0){
                    update lstUpdateFlagAskValidationDeputyCEO;
                }

                delete lstRequests;
                if(lstSignatoriesContact.size() > 0){
                    delete lstSignatoriesContact;
                }
                program.TECH_StageName__c = Label.Placement_stage;
                program.TECH_ShowClosePreviousPhaseBtn__c = '1';
                update program;

                mapResult.put('Success', 'Success');
            }
            else{
                mapResult.put('Error', 'No signing requests found');
            }
        }catch (Exception ex) {
            mapResult.put('Error',ex.getMessage());
        }
        return mapResult;
    }
}