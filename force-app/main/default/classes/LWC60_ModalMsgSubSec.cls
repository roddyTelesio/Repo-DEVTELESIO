public with sharing class LWC60_ModalMsgSubSec {
    @AuraEnabled(Cacheable = true)
    public static List<Section__c> getSectionInfo(Id programId) {
         //RRA - ticket 1802 - 011023
        return [SELECT Id, isNoSubSection__c, Treaty__r.Layer__c, fieldLayer__c, TECH_TreatyName__c, Program__r.Macro_L_O_B__c, SectionNumber__c, Name, Sort_SectionNumber__c, Number_of_subsections__c, Program__c 
                FROM Section__c 
                WHERE Program__c =:programId
                AND Retained_to_lead__c = true
                AND Number_of_subsections__c = 0
                ORDER BY Treaty__r.Layer__c, Sort_SectionNumber__c ASC];
    }
}