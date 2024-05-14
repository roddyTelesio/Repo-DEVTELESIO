public with sharing class LWC27_ProgramSummary {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Controller for Lightning Web Component lwc27ProgramSummary
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 28-FEB-2019  NBI   1.0      Initial version
-- 02-JUN-2021  MBE   1.1      loading time issue: chenge simple function to -> wired function (getProgramSummary)
-- 27-AUG-2021  MBE   1.2      Remove unused value for mapResult
--------------------------------------------------------------------------------------
**************************************************************************************/
    /**
    * @description Method to get data of Program
    * @param Id programId
    * @param Id reinsurerId
    * @param Boolean isUserBroker
    * @return Map<String, Object>
    */
    @AuraEnabled(Cacheable = true)
    public static Map<String, Object> getProgramSummary(Id programId, Id reinsurerId, Boolean isUserBroker){
        System.debug('@@START getProgramSummary@@');

        System.debug('@@programId@@== ' + programId);
        System.debug('@@reinsurerId@@== ' + reinsurerId);
        System.debug('@@isUserBroker@@== ' + isUserBroker);
        Map<String, Object> mapResults = new Map<String, Object>();
        List<Request__c> lstQuoteRequest = new List<Request__c>();
        List<Request__c> lstLeadRequest = new List<Request__c>();
        List<Request__c> lstPlacementRequest = new List<Request__c>();
        List<Request__c> lstSigningRequest = new List<Request__c>();
        List<Request__c> lstAllRequest = new List<Request__c>();
        String programStage;
        String valReinsurerId;
        String valBrokerId;
        Set<Id> setRelatedBroker = new Set<Id>();
        Program__c program = new Program__c();

        List<Program__c> lstProgram = [SELECT Id, Name, TECH_StageName__c FROM Program__c WHERE Id = :programId];

        if(lstProgram.size() > 0){
            program = lstProgram[0];
            programStage = program.TECH_StageName__c;
        }
        System.debug('@@program@@== ' + program);
        // Program__c program = [SELECT Id, Name, TECH_StageName__c FROM Program__c WHERE Id = :programId];
        // programStage = program.TECH_StageName__c;

        if(isUserBroker == false){
            //reinsurer contact logged in
            valReinsurerId = reinsurerId;

            lstAllRequest = [SELECT Id, Treaty__c, RecordType.DeveloperName, Program__c, Broker__c, ExpectedResponseDate__c, ResponseDate__c, Program__r.TECH_StageName__c, ReinsurerStatus__c, TECH_TreatyName__c, Version__c, TECH_SectionName__c, TECH_BrokerName__c, TECH_ReinsurerName__c FROM Request__c WHERE Program__c = :programId AND Reinsurer__c = :reinsurerId AND ReinsurerStatus__c != 'Setup' AND OriginalRequest__c = NULL];
        }
        else{
            //broker contact logged in
            Id brokerId;
            User usr = [SELECT Id, ContactId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            Id contactId = usr.ContactId;

            if(contactId != null){
                Contact brokContact = [SELECT Id, AccountId FROM Contact WHERE Id = :contactId LIMIT 1];

                if(brokContact != null && brokContact.AccountId != null){
                    brokerId = brokContact.AccountId;
                    valReinsurerId = reinsurerId;
                    valBrokerId = brokerId;

                    for(AccountContactRelation relatedContactRelationBroker : [SELECT Id, AccountId, Account.RecordTypeId
                                                                                      , Contact.Account.RecordTypeId, Roles
                                                                                      , ContactId, Contact.MacroLoB__c
                                                                                      , Contact.Nature__c, IsDirect
                                                                                FROM AccountContactRelation
                                                                                WHERE ContactId = :contactId
                                                                                AND IsActive = TRUE
                                                                                AND Contact.MacroLoB__c != NULL
                                                                                AND Contact.Nature__c != NULL]){
                        if(relatedContactRelationBroker.Roles == 'Broker' || relatedContactRelationBroker.IsDirect == true){
                            setRelatedBroker.add(relatedContactRelationBroker.AccountId);
                        }
                    }
                }
            }

            lstAllRequest = [SELECT Id, Treaty__c, RecordType.DeveloperName, Program__c, Broker__c, Program__r.TECH_StageName__c, ResponseDate__c, ExpectedResponseDate__c, ReinsurerStatus__c, TECH_TreatyName__c, Version__c, TECH_SectionName__c,	TECH_BrokerName__c, TECH_ReinsurerName__c, QuoteType__c FROM Request__c WHERE Program__c = :programId AND Reinsurer__c = :reinsurerId AND Broker__c IN :setRelatedBroker AND ReinsurerStatus__c != 'Setup' AND OriginalRequest__c = NULL];
        }

        System.debug('@@lstAllRequest for getProgramSummary@@== ' + lstAllRequest);

        for(Request__c request : lstAllRequest){
            if(request.RecordType.DeveloperName == 'Quote'){
                if((isUserBroker == false && request.Broker__c == null) || isUserBroker == true){
                    lstQuoteRequest.add(request);
                }
            }
            else if(request.RecordType.DeveloperName == 'Lead'){
                if((isUserBroker == false && request.Broker__c == null) || isUserBroker == true){
                    lstLeadRequest.add(request);
                }
            }
            else if(request.RecordType.DeveloperName == 'Placement'){
                if((isUserBroker == false && request.Broker__c == null) || isUserBroker == true){
                    lstPlacementRequest.add(request);
                    System.debug('@@lstPlacementRequest for getProgramSummary@@== ' + lstPlacementRequest);
                }
            }
            else if(request.RecordType.DeveloperName == 'Signing'){
                if((isUserBroker == false && request.Broker__c == null) || isUserBroker == true){
                    lstSigningRequest.add(request);
                }
            }
        }

        mapResults.put('isUserBroker',isUserBroker);
        mapResults.put('lstQuoteRequest',lstQuoteRequest);
        mapResults.put('lstAllRequest',lstAllRequest);
        mapResults.put('lstLeadRequest',lstLeadRequest);
        mapResults.put('lstPlacementRequest',lstPlacementRequest);
        mapResults.put('lstSigningRequest',lstSigningRequest);
        mapResults.put('programStage',programStage);
        mapResults.put('valReinsurerId',valReinsurerId);
        mapResults.put('valBrokerId',valBrokerId);

        System.debug('@@mapResults for getProgramSummary@@== ' + mapResults);
        System.debug('@@END getProgramSummary@@');

        return mapResults;
    }

    public class OptionWrapper {
        @AuraEnabled
        public String label {get; set;}
        @AuraEnabled
        public String value {get; set;}

        public OptionWrapper(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }
}