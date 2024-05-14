public with sharing class LWC34_TreatyDetails {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Controller for Lightning Web Component lwc34TreatyDetails
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 01-AUG-2020  SAU   1.0      Initial version
-- 22-APR-2021  MBE   1.1     W-0929 - Transversal - Respond on behalf et pages de réponses réassureur - affichage champs
--------------------------------------------------------------------------------------
**************************************************************************************/

    /**
    * @description Method to get Lead request details for selected Treaty
    * @param Id requestId, Id treatyId
    * @return Map<String, Object>
    */
    @AuraEnabled
    public static Map<String, Object> getLeadRequestDetails(Id requestId, Id treatyId){
        Map<String,Object> mapResults = new Map<String,Object>();
        Request__c requestById = [SELECT Id, Program__c, Reinsurer__c, Broker__c, ReinsurerStatus__c, Treaty__c, TECH_PhaseType__c, Program__r.PrincipalCedingCompany__c, Program__r.UwYear__c, Program__r.TECH_StageName__c FROM Request__c WHERE Id =: requestId ];
        Id programId = requestById.Program__c;
        Map<String, Id> mapRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectRequest});
        String reqLeadRecordTypeId = mapRecTypeId.get(AP_Constant.reqRTLead);
        List<String> lstRequestFields = AP_Constant.getCreatableFieldsByObjName(AP_Constant.sObjectRequest);
        String strRequestFields = String.join(lstRequestFields , ', ');

        List<Request__c> lstLeadParentRequests = new List<Request__c>();
        List<Request__c> lstAllLeadRequests = new List<Request__c>();
        lstLeadParentRequests = [SELECT Id, Name, Treaty__c, WrittenShare__c, Accept__c, Program__r.PrincipalCedingCompany__c, Program__r.UwYear__c, Program__r.TECH_StageName__c
                                FROM Request__c
                                WHERE Treaty__c = :treatyId
                                AND RecordTypeId = :reqLeadRecordTypeId
                                AND OriginalRequest__c = NULL];

        Set<Id> setChildRequestId = new Set<Id>();
        for(LeadRequestSelection__c leadRequestSelection : [SELECT Id, Name, LeadRequestChild__c
                                                                FROM LeadRequestSelection__c
                                                                WHERE LeadRequestParent__c IN :lstLeadParentRequests]){
            setChildRequestId.add(leadRequestSelection.LeadRequestChild__c);
        }
        String queryLeadRequest = 'select Id, Treaty__r.Name, Treaty__r.Layer__c, Program__r.PrincipalCedingCompany__c, Program__r.UwYear__c, Program__r.TECH_StageName__c'
                + ', Broker__r.Name, TECH_BrokerName__c, TECH_ReinsurerName__c, Program__r.LTA__c, Section__r.TECH_TypeofTreaty__c, Section__r.QuoteType__c, Section__r.SectionNumber__c'
                + ', Section__r.Cession_Perc__c, Section__r.Name, Section__r.Currency__c, Section__r.Unlimited__c, Treaty__r.TypeofTreaty__c, ToLabel(Treaty__r.LossDeposit__c), Treaty__r.Deductions_Perc__c, ToLabel(Treaty__r.PremiumDeposit__c)'
                + ', Section__r.EventLimit__c, Section__r.RetentionLine__c, Section__r.TAL__c, Section__r.Retention__c, Section__r.CessionAmount__c, Program__r.Name, Program__r.LossDeposit__c, Program__r.InceptionDate__c, Program__r.Expirydate__c'
                + ', Section__r.RetentionAmount__c, Section__r.Reinstatements__c, Section__r.TotalEPI__c, Section__r.Nature__c, Section__r.LineAmount__c, Section__r.CededLines__c, Section__r.CededPremium__c'
                + ', Section__r.Capacity__c, Section__r.Limit__c, Section__r.Deductible__c, Section__r.AAD__c, Section__r.AAL__c, TECH_SectionName__c, Section__r.TECH_Reinstatement__c'
                + ', Section__r.LimitPercent__c, Section__r.DeductiblePercent__c, Section__r.MaxLimitAmount__c, Section__r.MinLimitAmount__c, Section__r.ExpectedMDP__c, Section__r.ExpectedDP__c, Section__r.ExpectedMP__c, '
                + strRequestFields
                + ' from Request__c where (Id IN :setChildRequestId AND RecordTypeId = :reqLeadRecordTypeId AND Treaty__c =: treatyId AND OriginalRequest__c = NULL) ';

        lstAllLeadRequests = Database.query(queryLeadRequest);
        mapResults.put('lstAllLeadRequests', lstAllLeadRequests);

        return mapResults;
    }
}