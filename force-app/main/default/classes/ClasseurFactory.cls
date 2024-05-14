public with sharing class ClasseurFactory {

    /**************************************************************************************
-- - Author        : Telesio
-- - Description   : Test Data for QuoteTable Project
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 17-OCT-2019  SBH   1.0      Initial version
--------------------------------------------------------------------------------------
**************************************************************************************/

    // Creates classeur Record
    public static Classeur__c createClasseur(String Name, String AccountId, String programId){
        return new Classeur__c(
            Name = Name
            ,Cedente__c = AccountId 
            ,Program__c = programId
        );
    }

    // Creates EventLog Recordd
    public static EventLog__c createEventLog(String className, String context, String recordId , String Request, String response){
        return new EventLog__c(
            ClassName__c = className
            , Context__c = context
            , RecordId__c = recordId
            , Request__c = Request
            , Response__c = response
        );
    }
}