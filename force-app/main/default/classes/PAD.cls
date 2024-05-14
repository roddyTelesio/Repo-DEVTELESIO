public class PAD {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : PAD class for trigger bypass
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 23-OCT-2019  NBI    1.0     Initial Version
--------------------------------------------------------------------------------------
**************************************************************************************/

    private static PAD instance = null;
    private static Id currentUserId = null;
    public Map<String, Boolean> triggerStatus = null;

    private void load() {
        currentUserId = UserInfo.getUserId();
        String bypassApex = [SELECT BypassTrigger__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1].BypassTrigger__c;
        triggerStatus = new Map<String, Boolean>();
        if (bypassApex != null) {
            List<String> triggerList = bypassApex.split(';');

            for (String triggerName : triggerList) {
                if (triggerName != null && triggerName != '') {
                    triggerStatus.put(triggerName, false);
                }
            }
        }
    }

    public static PAD getInstance() {
        if (instance == null) {
            instance = new PAD();
        }
        if (currentUserId != UserInfo.getUserId()) {
            instance.load();
        }
        return instance;
    }

    public static void inactiveTrigger(String name) {
        getInstance().triggerStatus.put(name, false);
    }

    public static void activeTrigger(String name) {
        getInstance().triggerStatus.put(name, true);
    }

    public static Boolean canRun(String name) {
        if (getInstance().triggerStatus.containsKey(name)) {
            return (getInstance().triggerStatus.get(name));
        }
        return true;
    }

    @isTest
    private static void test() {
        Profile profile = [SELECT Id FROM Profile WHERE Name='Standard user'];

        User user = new User(Alias = 'standt', Email='standarduser@testorg.com',
                EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                LocaleSidKey='en_US', ProfileId = profile.Id,
                TimeZoneSidKey='America/Los_Angeles', Username='standarduser@agre.env', BypassTrigger__c='TR01;TR02');

        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        System.runAs(currentUser) {
            System.assert(canRun('TR01') == true);
            System.assert(canRun('TR03') == true);
            inactiveTrigger('TR01');
            inactiveTrigger('TR03');
            System.assert(canRun('TR01') == false);
            System.assert(canRun('TR03') == false);
            activeTrigger('TR01');
            activeTrigger('TR03');
            System.assert(canRun('TR01') == true);
            System.assert(canRun('TR03') == true);
        }
    }
}