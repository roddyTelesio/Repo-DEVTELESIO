/***
* @author      SBH (Telesio)
* @date        22/04/2022
* @description Class providing constants and common static flags related to Quote Table dev
* @group       QuoteTable
* @see         QuoteTable_SVC
***/
public with sharing class QuoteTable_CST {
    
    // #####################################################################
    // Record Type Developer Names
    // #####################################################################
    public static String RT_QUOTE = 'Quote';     
    public static String RT_LEAD = 'Lead';    

    // #####################################################################
    // Picklist values
    // #####################################################################

    public static String quoteForInformation = '1'; 
    
    /***
    * @description Custom Setting to dynamically influence Account Business Logic
    *              (mainly Trigger feature bypasses).
    ***/
    static final public QuoteTableSettings__c SETTING = QuoteTableSettings__c.getInstance();

    public static String allFields(String obj){

        System.debug('QuoteTable_CST.allFields Start');

        Set<String> SobjectFields = Schema.getGlobalDescribe().get(obj).getDescribe().fields.getMap().keySet();    
        List<String> fieldsInList = new List<String>(SobjectFields);
        System.debug('QuoteTable_CST.allFields :' + fieldsInList);
        return String.join(fieldsInList, ',');
    }


    public static String allParentFields(String obj, String prefix){

        System.debug('QuoteTable_CST.allFields Start');

        Set<String> SobjectFields = Schema.getGlobalDescribe().get(obj).getDescribe().fields.getMap().keySet();    

        List<String> fieldsToReturn = new List<String>();
        List<String> fieldsInList = new List<String>(SobjectFields);
        for(String currentField : fieldsInList){
            fieldsToReturn.add(prefix + '.' + currentField);
        }
        System.debug('QuoteTable_CST.allFields :' + fieldsInList);
        return String.join(fieldsToReturn, ',');
    }

    // #################################################
    // #            WS Callout variables
    // #################################################
    public static final String ORG_ID = QuoteTable_CST.SETTING.OrgID__c; 
    public static final String TEMPLATE_ID = QuoteTable_CST.SETTING.TemplateId__c; 
    public static final String CONTEXT = QuoteTable_CST.SETTING.ContextLog__c; 
    public static final String ID_DFUSER = QuoteTable_CST.SETTING.ApiUserId__c; 

}