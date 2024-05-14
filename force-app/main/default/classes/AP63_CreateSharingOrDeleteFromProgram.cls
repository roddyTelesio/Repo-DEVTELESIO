/**************************************************************************************
-- - Author        : Telesio
-- - Description   : class to Create /Delete  Sharing from Program
-- Maintenance History:
--
-- Date          Name  Version  Remarks
-- -----------   ----  -------  -------------------------------------------------------
-- 27-APRIL-2022  RRA   1.0      Initial version
--------------------------------------------------------------------------------------
**************************************************************************************/
public without sharing class AP63_CreateSharingOrDeleteFromProgram {
    public static void createSharingRequestFromProgram(List<Id> lstIds, String objectName){
        List<Id> lstIdNewRequests = new List<String>();
        String phase = 'QuoteLeadPlacementSigning';
        if (objectName == 'Program'){
            for (Request__c req : [SELECT Id, TECH_PhaseType__c FROM Request__c where Program__c IN :lstIds AND TECH_PhaseType__c IN('3', '4', '5', '6')]){
                lstIdNewRequests.add(req.Id);
            }
        } else if  (objectName == 'Treaty'){
            for (Request__c req : [SELECT Id, TECH_PhaseType__c FROM Request__c where Program__c IN :lstIds AND TECH_PhaseType__c IN('3', '4', '5', '6')]){
                lstIdNewRequests.add(req.Id);
            }
        }
        AP38_CreateSharingForRequest.createRequestSharing(lstIdNewRequests, phase);
    }


    public static void DeleteSharingRequestFromProgram(List<Id> lstOldIds, String objectName){
        List<Request__Share> lstReqShareExisting = new  List<Request__Share> ();
        if (objectName == 'Program'){
            for (Request__Share reqShareAttachedOnProg : [SELECT ParentId, Parent.KeyRequestSharing__c, Parent.Program__c, UserOrGroupId FROM Request__Share WHERE RowCause = 'Manual' AND UserOrGroup.Profile.Name = 'AGRE_Community External User' AND Parent.Program__c IN:lstOldIds ]){
                lstReqShareExisting.add(reqShareAttachedOnProg);
            }
        }else if (objectName == 'Treaty'){
            for (Request__Share reqShareAttachedOnProg : [SELECT ParentId, Parent.KeyRequestSharing__c, Parent.Program__c, UserOrGroupId FROM Request__Share WHERE RowCause = 'Manual' AND UserOrGroup.Profile.Name = 'AGRE_Community External User' AND Parent.Program__c IN:lstOldIds ]){
                lstReqShareExisting.add(reqShareAttachedOnProg);
            }
        }
       
        // RRA - Optimization Code - ticket 585 - 07122022
        if (lstReqShareExisting != null && lstReqShareExisting.size() < 9000 - Limits.getDMLRows()){
            delete lstReqShareExisting;
        }else if (lstReqShareExisting != null && lstReqShareExisting.size() > 9000 - Limits.getDMLRows()){
            BAT002_DeleteSharingBigQuantity batchDeleteReq = new BAT002_DeleteSharingBigQuantity(lstReqShareExisting);
            if (!system.isBatch()){ //stop 'Database.executeBatch cannot be called from a batch start, batch execute, or future method.' error
                Database.executeBatch(batchDeleteReq, 500);   
            }                
        }

    }
}