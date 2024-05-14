/**************************************************************************************
-- - Author        : Telesio
-- - Description   :  Program Trigger Handler Class
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 11-AUG-2022  RRA   1.0      Initial version
--------------------------------------------------------------------------------------
**************************************************************************************/

public with sharing class ProgramTriggerHandler {
    public void handleAfterUpdate(List<Program__c> lstOldPrograms, List<Program__c> lstNewPrograms){
        System.debug ('START ProgramTriggerHandler for handleAfterUpdate');
        List<Id> lstProgramId = new List<Id>();
        List<Id> lstIdProgram = new List<Id>();
        List<Program__c> lstNewProgram = new List<Program__c>();
        List<Id> lstProgramIdOld = new List<Id>();
        for(Integer i = 0; i < lstNewPrograms.size(); i++) {
            if(PAD.canRun('AP63_CreateSharingOrDeleteFromProgram')){
                if(lstOldPrograms[i].Macro_L_O_B__c != lstNewPrograms[i].Macro_L_O_B__c){
                    lstProgramId.add(lstNewPrograms[i].Id);
                    lstProgramIdOld.add(lstOldPrograms[i].Id);
                }
                 if(lstOldPrograms[i].Nature__c != lstNewPrograms[i].Nature__c){
                    lstProgramId.add(lstNewPrograms[i].Id);
                    lstProgramIdOld.add(lstOldPrograms[i].Id);
                }

                //RRA - ticket 1420 - 07022023
                if(lstOldPrograms[i].LossDeposit__c != lstNewPrograms[i].LossDeposit__c){
                    lstIdProgram.add(lstNewPrograms[i].Id);
                    lstNewProgram.add(lstNewPrograms[i]);
                }

            }
        }

        if (lstProgramIdOld.size() > 0 ){
            if(PAD.canRun('AP63_DeleteSharingRequestFromProgram') && lstProgramIdOld.size() > 0){
                AP63_CreateSharingOrDeleteFromProgram.DeleteSharingRequestFromProgram(lstProgramIdOld, 'Program');
                System.debug ('Delete Done');
            }
        }

        if (lstProgramId.size() > 0 ){
            if(PAD.canRun('AP63_CreateSharingOrDeleteFromProgram') && lstProgramId.size() > 0){
                AP63_CreateSharingOrDeleteFromProgram.createSharingRequestFromProgram(lstProgramId,'Program');
                System.debug ('Create. Done');
            }
        }

        if (lstIdProgram.size() > 0 ){
                AP64_UpdateRequestFromConditions.updateRequestFromConditions(lstIdProgram, lstNewProgram, 'Program');
        }
        
        System.debug ('END ProgramTriggerHandler for handleAfterUpdate');
    }
}