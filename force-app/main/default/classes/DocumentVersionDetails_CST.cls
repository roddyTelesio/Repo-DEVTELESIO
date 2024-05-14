public with sharing class DocumentVersionDetails_CST {

    // Constants for trigger bypass


     // #####################################################################
    // Custom settings to bypass certain DocumentVersionDetails logic
    // #####################################################################
    /***
    * @description Custom Setting to dynamically influence Account Business Logic
    *              (mainly Trigger feature bypasses).
    ***/
    static final public DocumentVersionDetailsSettings__c	 SETTING = DocumentVersionDetailsSettings__c.getInstance();

    // #####################################################################    
    // Dynamic trigger bypasses (may be set by other triggers or methods)
    // #####################################################################

    /***
    * @description Flag to dynamically bypass the After update trigger.
    ***/
    static public Boolean DoAfterUpdate  = true;

}