public with sharing class LWC55_SAExternalPortal {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Controller for Lightning Web Component lwc55SAExternalPortal
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 03-FEB-2021  MBE   1.0      Initial version
--------------------------------------------------------------------------------------
**************************************************************************************/

    /**
    * @description Method to get Request Information
    * @param String reinsurerId, Boolean isBroker, String uwYear, String pcc
    * @return Map<String, Object>
    */
    @AuraEnabled
    public static Map<String, Object> getRequestsInfoFilter(String reinsurerId, Boolean isBroker, String uwYear, String pcc){
        Map<String, Object> mapResults = new Map<String, Object>();
        Map<String, Id> mapRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectRequest});
        Map<String, String> mapReinNameByReinId = new Map<String, String>();
        Map<String, List<Request__c>> mapLstRequestByReinsurer = new Map<String, List<Request__c>>();
        List<Request__c> lstSaRequest = new List<Request__c>();
        List<RequestWrapper> lstRequests = new List<RequestWrapper>();
        List<String> lstRequestFields = AP_Constant.getCreatableFieldsByObjName(AP_Constant.sObjectRequest);
        List<OptionWrapper> lstReinsurerOptionsAll = new List<OptionWrapper>();
        String strRequestFields = String.join(lstRequestFields, ', ');
        String reqSaRecordTypeId = mapRecTypeId.get(AP_Constant.reqRTSA);
        String setupStatus = AP_Constant.statusSetup;
        String sleepingPartnerBrokerStatus = '1';
        String financialIntermediaryBrokerStatus = '2';
        String activeStr = 'Active';
        Set<Id> setRelatedBroker = new Set<Id>();
        Set<Id> setRelatedReinsurer = new Set<Id>();
        Set<Id> setReinsurerOptionsAllId = new Set<Id>();
        Id brokerAcc = null;
        Id contactId;
        User usr = new User();
        Savepoint sp = Database.setSavepoint();

        try{
            if(isBroker == true){
                //broker contact logged in
                //no reinsurer value is selected(picklist) - value = 'All'
                //If request has broker + Broker Status =: financialIntermediaryBrokerStatus

                usr = [SELECT Id, ContactId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
                contactId = usr.ContactId;

                if(contactId != null){
                    Contact brokContact = [SELECT Id, AccountId FROM Contact WHERE Id = :contactId LIMIT 1];

                    if(brokContact != null && brokContact.AccountId != null){
                        brokerAcc = brokContact.AccountId;

                        for(AccountContactRelation relatedContactRelationBroker : [SELECT Id, AccountId, Account.RecordTypeId
                                                                                        , Contact.Account.RecordTypeId, Roles
                                                                                        , ContactId, Contact.MacroLoB__c
                                                                                        , Contact.Nature__c, IsDirect
                                                                                FROM AccountContactRelation
                                                                                WHERE ContactId = :contactId
                                                                                AND IsActive = TRUE
                                                                                AND Contact.MacroLoB__c != NULL
                                                                                AND Contact.Nature__c != NULL]){
                            //if(relatedContactRelationBroker.Roles == 'Broker' || relatedContactRelationBroker.IsDirect == true){
                                setRelatedBroker.add(relatedContactRelationBroker.AccountId);
                            //}
                        }
                    }

                    String querySaRequest = 'SELECT Id, TECH_TreatyName__c, Treaty__r.PlacementShare_Perc__c, TECH_BrokerName__c, TECH_IsBrokerPresent__c, TECH_ReinsurerName__c, TECH_Layer__c, TECH_UWyear__c,  SigningRegionalManager__r.Email '
                        + ', RiskCarrier__r.Name, FinancialEntity__r.Name, Program__r.LossDepositMode__c, Program__r.LossDeposit__c, Program__r.UwYear__c, Broker__r.Name, Reinsurer__r.Name, TECH_ProgramName__c '
                        + ', Treaty__r.LossDepositMode__c, Treaty__r.LossDeposit__c, Treaty__r.Deductions__c, TreatyReference__c, Treaty__r.TypeofTreaty__c, SA_Request_Status__c '
                        + ', Treaty__r.PremiumDeposit__c, Program__r.LossDepositLevel__c, Pool__r.Name, Pool__r.AssignedTo__r.Email, Pool__r.AssignedTo__c, Program__r.Name, program__r.principalcedingcompany__r.Name, Program__r.PrincipalCedingCompany__c '
                        + ', Special_Acceptance__r.SpecialAcceptanceName__c, Special_Acceptance__r.CoveredCedingCompany__r.Name, ExpectedResponseDate__c, Special_Acceptance__r.Active__c, Special_Acceptance__r.Bound__c, '
                        +  strRequestFields
                        + ' from Request__c where Broker__c IN :setRelatedBroker AND BrokerStatus__c = :financialIntermediaryBrokerStatus '
                        + ' AND Program__r.PrincipalCedingCompany__c = :pcc AND Program__r.UwYear__c = :uwYear '
                        + ' AND RecordTypeId = :reqSaRecordTypeId AND LastVersionSent__c = TRUE AND LastVersionAnswered__c = TRUE AND SA_Request_Status__c != :setupStatus '
                        + ' AND Special_Acceptance__r.Active__c = :activeStr ORDER BY Special_Acceptance__r.SpecialAcceptanceName__c ASC';// RRA - 1086//TECH_ProgramName__c

                    lstSaRequest = Database.query(querySaRequest);
                }
            }
            else if(isBroker == false){
                System.debug('isBroker ' + isBroker);
                //reinsurer contact logged in
                //no picklist

                Id reinsAcc;
                usr = [SELECT Id, ContactId FROM User WHERE Id =: UserInfo.getUserId() LIMIT 1];
                contactId = usr.ContactId;

                System.debug('contactId ' + contactId);

                if(contactId != null){
                    Contact reinsContact = [SELECT Id, AccountId FROM Contact WHERE Id = :contactId LIMIT 1];

                    if(reinsContact != null && reinsContact.AccountId != null){
                        reinsAcc = reinsContact.AccountId;

                        for(AccountContactRelation relatedContactRelationReinsurer : [SELECT Id, AccountId, Account.RecordTypeId
                                                                                        , Contact.Account.RecordTypeId, Roles
                                                                                        , ContactId, Contact.MacroLoB__c
                                                                                        , Contact.Nature__c, IsDirect
                                                                                FROM AccountContactRelation
                                                                                WHERE ContactId = :contactId
                                                                                AND IsActive = TRUE
                                                                                AND Contact.MacroLoB__c != NULL
                                                                                AND Contact.Nature__c != NULL]){
                            //if(relatedContactRelationReinsurer.Roles == 'RiskCarrier' || relatedContactRelationReinsurer.IsDirect == true){
                                setRelatedReinsurer.add(relatedContactRelationReinsurer.AccountId);
                            //}
                        }
                    }
                }

                System.debug('setRelatedReinsurer ' + setRelatedReinsurer);

                
                System.debug('pcc ' + pcc);
                
                System.debug('uwYear ' + uwYear);
                
                System.debug('activeStr ' + activeStr);

                System.debug('strRequestFields ' + strRequestFields);

                String querySaRequest = 'SELECT Id, TECH_TreatyName__c, Treaty__r.PlacementShare_Perc__c, TECH_BrokerName__c, TECH_IsBrokerPresent__c, TECH_ReinsurerName__c, TECH_Layer__c, TECH_UWyear__c,  SigningRegionalManager__r.Email '
                    + ', RiskCarrier__r.Name, FinancialEntity__r.Name, Program__r.LossDepositMode__c, Program__r.LossDeposit__c, Program__r.UwYear__c, Broker__r.Name, Reinsurer__r.Name, TECH_ProgramName__c '
                    + ', Treaty__r.LossDepositMode__c, Treaty__r.LossDeposit__c, Treaty__r.Deductions__c, TreatyReference__c, Treaty__r.TypeofTreaty__c, SA_Request_Status__c '
                    + ', Treaty__r.PremiumDeposit__c, Program__r.LossDepositLevel__c, Pool__r.Name, Pool__r.AssignedTo__r.Email, Pool__r.AssignedTo__c, Program__r.Name, program__r.principalcedingcompany__r.Name, Program__r.PrincipalCedingCompany__c '
                    + ', Special_Acceptance__r.SpecialAcceptanceName__c, Special_Acceptance__r.CoveredCedingCompany__r.Name, ExpectedResponseDate__c, Special_Acceptance__r.Active__c, Special_Acceptance__r.Bound__c, '
                    +  strRequestFields
                    + ' from Request__c where ((Reinsurer__c IN :setRelatedReinsurer AND Broker__c = NULL) OR (Reinsurer__c IN :setRelatedReinsurer AND Broker__c != NULL AND BrokerStatus__c = :sleepingPartnerBrokerStatus)) '
                    + ' AND Program__r.PrincipalCedingCompany__c = :pcc AND Program__r.UwYear__c = :uwYear '
                    + ' AND Special_Acceptance__r.Active__c = :activeStr '
                    + ' AND SA_Request_Status__c != :setupStatus AND LastVersionSent__c = TRUE AND LastVersionAnswered__c = TRUE AND RecordTypeId = :reqSaRecordTypeId ORDER BY Special_Acceptance__r.SpecialAcceptanceName__c ASC';// RRA - 1086//TECH_ProgramName__c

                lstSaRequest = Database.query(querySaRequest);
            }

            System.debug('lstSaRequest ' + lstSaRequest);

            for(Request__c saReq : lstSaRequest){
                //create map of list of request by reinsurer
                List<Request__c> lstRequestByReinsurer = new List<Request__c>();

                if(reinsurerId == 'All' || (isBroker == true && saReq.Reinsurer__c == reinsurerId) || (isBroker == true && reinsurerId == null) || (isBroker == false)){
                    if(mapLstRequestByReinsurer.containsKey(saReq.Reinsurer__c)){
                        lstRequestByReinsurer = mapLstRequestByReinsurer.get(saReq.Reinsurer__c);
                    }

                    lstRequestByReinsurer.add(saReq);
                    mapLstRequestByReinsurer.put(saReq.Reinsurer__c, lstRequestByReinsurer);            
                }
                System.debug('lstRequestByReinsurer ' + lstRequestByReinsurer);
                System.debug('mapLstRequestByReinsurer ' + mapLstRequestByReinsurer);

                if(saReq.Reinsurer__c != null){
                    mapReinNameByReinId.put(saReq.Reinsurer__c, saReq.TECH_ReinsurerName__c);
                    setReinsurerOptionsAllId.add(saReq.Reinsurer__c);
                }
                System.debug('mapReinNameByReinId ' + mapReinNameByReinId);
                System.debug('setReinsurerOptionsAllId ' + setReinsurerOptionsAllId);
            }

            if(mapLstRequestByReinsurer != null){
                for(String reinId : mapLstRequestByReinsurer.keySet()){
                    if(mapReinNameByReinId.containsKey(reinId)){
                        lstRequests.add(new RequestWrapper(mapReinNameByReinId.get(reinId), mapLstRequestByReinsurer.get(reinId)));
                    } 
                }

                System.debug('lstRequests ' + lstRequests);
            }

            for(Id reinId : setReinsurerOptionsAllId){
                lstReinsurerOptionsAll.add(new OptionWrapper(mapReinNameByReinId.get(reinId), reinId));
            }

            System.debug('lstReinsurerOptionsAll ' + lstReinsurerOptionsAll);

            lstReinsurerOptionsAll.sort();
            
            mapResults.put('setRelatedBroker', setRelatedBroker);
            mapResults.put('setRelatedReinsurer', setRelatedReinsurer);
            mapResults.put('lstSaRequest', lstSaRequest);
            mapResults.put('lstRequests', lstRequests);
            mapResults.put('reinsurerId', reinsurerId);
            mapResults.put('reinsurerOptionsAll', lstReinsurerOptionsAll);
            mapResults.put('Success', 'Success');
        } 
        catch (Exception ex) {
            Database.rollback(sp);
            mapResults.put('Error', ex.getMessage());
        }

        return mapResults;
    }

    public class OptionWrapper implements Comparable{
        @AuraEnabled public String label {get; set;}
        @AuraEnabled public String value {get; set;}

        public OptionWrapper(String label, String value) {
            this.label = label;
            this.value = value;
        }

        public Integer compareTo(Object compareTo){
            OptionWrapper optWrapper = (OptionWrapper) compareTo;
            if (label == optWrapper.label) return 0;
            if (label > optWrapper.label) return 1;
            return -1;
        }
    }

    public class RequestWrapper {
        @AuraEnabled public String reinsurerName {get; set;}
        @AuraEnabled public List<Request__c> lstRequests{get; set;}

        public RequestWrapper(String reinsurerName, List<Request__c> lstRequests) {
            this.reinsurerName = reinsurerName;
            this.lstRequests = lstRequests;
        }
    }
}