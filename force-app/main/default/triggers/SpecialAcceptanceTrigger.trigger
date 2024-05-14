trigger SpecialAcceptanceTrigger on SpecialAcceptance__c (after update) {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Trigger on Special Acceptance
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 24-FEB-2021  MBE   1.0      Initial version
--------------------------------------------------------------------------------------
**************************************************************************************/

    SpecialAcceptanceTriggerHandler handler = new SpecialAcceptanceTriggerHandler();

    if(Trigger.isAfter && Trigger.isUpdate) {
        Profile userProfile = [Select Name from Profile where Id =: userinfo.getProfileid()];
        String pname = userProfile.name;
        System.debug(pname);

        if(pname == 'Partner Community User' || pname == 'AGRE_Community External User' || pname == 'AGRE_Community Internal User' || pname == 'AGRE_Community User OLD' || pname == 'portal_vf Profile') {
            System.debug('## portal user');
        }
        else{
            handler.handleAfterUpdate(Trigger.old, Trigger.new);
        }

    }
    
}