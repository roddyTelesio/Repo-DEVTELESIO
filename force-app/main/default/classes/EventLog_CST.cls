/***
* @author      Telesio Dev (SBH)
* @date        19/05/2022
* @description Class providing constants and common static flags related to the EventLog object.
* @group       EventLog
* @see         EventLog_DMN
*
*/ 

public with sharing class EventLog_CST {

    // #####################################################################
    // Custom settings to bypass certain Account logic
    // #####################################################################
    /***
    * @description Custom Setting to dynamically influence Account Business Logic
    *              (mainly Trigger feature bypasses).
    ***/
    static final public EventLogSettings__c SETTING = EventLogSettings__c.getInstance();

    // #####################################################################    
    // Dynamic trigger bypasses (may be set by other triggers or methods)
    // #####################################################################

    /***
    * @description Flag to dynamically bypass the After Insert trigger.
    ***/
    static public Boolean DoAfterInsert  = true;


    /***
    * @description Context for datafactory response
    ***/
    static public String CONTEXT_DF  = 'QuoteTable';

}