public with sharing class LWC58_SubSectionUIFlow {
    @AuraEnabled
    public static List<SubSection__c> getSubSection(String selectedSectionId, String idSubSec ) {
        return [
                SELECT Id, AAD__c, AAL__c, Deductible__c, LimitType__c, lstPortFolioSegment__c, lstIdPortFolioSegment__c, lstIdReferentialHazardBassin__c, lstNameReferentialHazardBassin__c, TAL__c, Section__c, Unlimited__c
                FROM SubSection__c
                WHERE Section__c = :selectedSectionId AND Id = :idSubSec
            ];
    }

    @AuraEnabled
    public static void delSelectedSubSection(List<Id> lstIdSubSec) {
        List<SubSection__c> lstSubSecToDelete = [ SELECT Id, AAD__c, AAL__c, Deductible__c, LimitType__c, lstPortFolioSegment__c, lstIdPortFolioSegment__c, lstIdReferentialHazardBassin__c, lstNameReferentialHazardBassin__c, TAL__c, Section__c, Unlimited__c FROM SubSection__c WHERE Id IN:lstIdSubSec];
        if (lstSubSecToDelete.size() > 0){
            delete lstSubSecToDelete;
        }
    }
    
    //RRA - ticket 1532 - 13062023
    @AuraEnabled
    public static List<SubSection__c> updateSubSectionSelected(List<SubSection__c> lstSubSection) {
        Id currentSubSec;
        try{
            if (lstSubSection.size() > 0){
                for (SubSection__c subSec : lstSubSection){
                    if(subSec.PrincipalSubSection__c == false){
                        subSec.PrincipalSubSection__c = true;
                        currentSubSec = subSec.Id;
                    }  
            }
            System.debug('lstSubSection before== ' + lstSubSection);
            System.debug('currentSubSec== ' + currentSubSec);
            update lstSubSection;
            
          if (currentSubSec != null){
            List<Subsection__c> lstSubSec = [SELECT Id, PrincipalSubSection__c FROM Subsection__c WHERE PrincipalSubSection__c = true AND Id !=: currentSubSec];
            if (lstSubSec.size()>0){
              for (Subsection__c secSub : lstSubSec){
                  if (secSub.PrincipalSubSection__c){
                      secSub.PrincipalSubSection__c = false;
                    }
                }
              update lstSubSec;
            }
            System.debug('lstSubSec == ' + lstSubSec);
          }
            System.debug('lstSubSection after== ' + lstSubSection);
        }
      } catch (Exception ex) {
        ex.getMessage();
      }
      return lstSubSection;
    }
}