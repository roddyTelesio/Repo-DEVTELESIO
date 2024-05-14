public with sharing class SectionTriggerHandler {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Section Trigger Handler Class
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 25-JUN-2019  NBI    1.0     Initial Version
--------------------------------------------------------------------------------------
**************************************************************************************/

    public SectionTriggerHandler() {}

    public void handleBeforeUpdate(List<Section__c> lstSections){
        if(PAD.canRun('AP37_UpdateSectionCurrencyLabel') && lstSections.size() > 0){
            AP37_UpdateSectionCurrencyLabel.updateSectionCurrencyLabel(lstSections);
        }
    }
    public void handleBeforeInsert(List<Section__c> lstSections){
        if(PAD.canRun('AP37_UpdateSectionStructure') && lstSections.size() > 0){
            AP37_UpdateSectionCurrencyLabel.updateSectionCurrencyLabel(lstSections);
        }
    }
    
     //RRA - ticket 1745 - 09112023
    public void handleAfterUpdate(List<Section__c> lstSectionsOlds, List<Section__c> lstSectionsNews){
        List<Section__c> lstSections = new List<Section__c>();
        for(Integer i = 0; i < lstSectionsNews.size(); i++) {
            String typeOfTreaty = lstSectionsNews[i].TECH_TypeofTreaty__c;
            System.debug('typeOfTreaty == '+ typeOfTreaty);
            //Only SL or XL
            if (typeOfTreaty == '1' || typeOfTreaty == '2'){
                if(lstSectionsOlds[i].ExpectedMDP__c != lstSectionsNews[i].ExpectedMDP__c){
                    lstSections.add(lstSectionsNews[i]);
                }
                if(lstSectionsOlds[i].ExpectedDP__c != lstSectionsNews[i].ExpectedDP__c){
                    lstSections.add(lstSectionsNews[i]);
                }
                if(lstSectionsOlds[i].ExpectedMP__c != lstSectionsNews[i].ExpectedMP__c){
                    lstSections.add(lstSectionsNews[i]);
                }
                if(lstSectionsOlds[i].TotalEPI__c != lstSectionsNews[i].TotalEPI__c){
                    lstSections.add(lstSectionsNews[i]);
                }
            }
        }
        if (lstSections.size()>0){
            if(PAD.canRun('AP65_RecalculateFieldsLeadReq') && lstSections.size() > 0){
                AP65_RecalculateFieldsLeadReq.updatefieldsLeadRequests(lstSections);
            }
        }
    }
}