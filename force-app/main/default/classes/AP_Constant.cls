public with sharing class AP_Constant {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Class for keeping all common constant variables and common methods
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 16-OCT-2019  MBE   1.0      Initial version
--------------------------------------------------------------------------------------
**************************************************************************************/

    //Method to generate a map that contains developer Name and id for a set of ObjectAPINames
    public static Map<String,Id> getDeveloperIdMap(Set<String> ObjectAPINames){
        Map<String, Id> developerIdMap = new Map<String, Id>();

        //returns a map where key is Sobject-RecDevName and value is recordtypeId
        //e.g Account-Customer, XXXXX
        for(RecordType r : [SELECT SobjectType,DeveloperName,Id
                            FROM RecordType
                            WHERE SobjectType IN:ObjectAPINames
                            ORDER BY SobjectType ASC ]){
            developerIdMap.put((r.SobjectType +'-'+ r.DeveloperName),r.Id);
        }
        return developerIdMap;
    }

    // Returns list of createable fields by object API name
    public static List<String> getCreatableFieldsByObjName(String objectName){
        Map<String, Schema.SObjectField> fMap =
                Schema.getGlobalDescribe().get(objectName.toLowerCase()).getDescribe().Fields.getMap();
        List<String> selectFields = new List<String>();

        if(fMap!=null){
            for(Schema.SObjectField ft : fMap.values()){ //loop through all field tokens (ft)
                Schema.DescribeFieldResult fd = ft.getDescribe(); //describe each field (fd)
                //field is isUpdateable, not checking on creatable since end user may not have create but only edit right on object
                if (fd.isUpdateable()){
                    selectFields.add(fd.getName());
                }
            }
        }
        return selectFields;
    }

    /**
    * @description Method to check if SA Email is available for selected Principal Ceding Company
    * @param String pccId
    * @return Map<String, Object>
    */
    @AuraEnabled
    public static Map<String, Object> checkIfSAEmailIsFound(String pccId){
        Map<String, Object> mapResults = new Map<String, Object>();
        List<Account> lstPCCAccount = new List<Account>();
        Boolean saEmailNull = true;
        String saEmail = null;

        try {
            if(pccId != null){
                lstPCCAccount = [SELECT Id, Name, EmailSA__c FROM Account WHERE Id = :pccId LIMIT 1];
                saEmail = lstPCCAccount[0].EmailSA__c;

                if(saEmail == null){
                    saEmailNull = true;
                }
                else{
                    saEmailNull = false;
                }
            }

            mapResults.put('saEmailNull',saEmailNull);

        }catch (Exception ex) {
            mapResults.put('Error', ex.getMessage());
        }
        return mapResults;
    }

    /***********************************************************************
    * Account
    ************************************************************************/
    /*sobject*/
    public static String sObjectAcc = 'Account';

    //Record Type
    public static String accRTPrincipalCedingCom = 'Account-PrincipalCedingCompany';
    public static String accRTCompanyGroup = 'Account-CompanyGroup';
    public static String accRTCoveredCedingCompany = 'Account-CoveredCedingCompany'; 
    public static String accRTReinsurer = 'Account-Reinsurer';
    public static String accRTBroker = 'Account-Broker';

    //Added by SAU
    public static String accRTPrincipalCedingComName = 'Principal Ceding Company';
    /***********************************************************************
    * Role developer name
    ************************************************************************/
    public static String HeadUGP = 'Head_of_UGP';
    public static String ClientExecutive = 'CM';
    public static String HeadOfGrid = 'DIR';
    public static String DeputyCEO = 'CEO';

    /***********************************************************************
    * Program
    ************************************************************************/
    /*sobject*/
    public static String sObjectProgram = 'Program__c';

    //Stage
    public static String stageConditions = 'Conditions';
    public static String stageQuote = 'Quote';
    public static String stageLead = 'Lead';
    public static String stagePlacement = 'Placement';
    public static String stageSigning = 'Signing';

    /***********************************************************************
    * Treaty
    ************************************************************************/
    /*sobject*/
    public static String sObjectTreaty = 'Treaty__c';

    //Status
    public static String statusActive = '1';
    public static String statusCancelled = '2';

    /***********************************************************************
    * Section
    ************************************************************************/
    /*sobject*/
    public static String sObjectSection = 'Section__c';

    /***********************************************************************
    * Covered Ceding Company
    ************************************************************************/
    /*sobject*/
    public static String sObjCoveredCedingComp = 'CoveredCedingCompany__c';

    /***********************************************************************
    * Pool Treaty Section
    ************************************************************************/
    /*sobject*/
    public static String sObjPoolTreatySection = 'PoolTreatySection__c';
    
    /***********************************************************************
    * Quote Request
    ************************************************************************/
    /*sobject*/
    public static String sObjectQuoteRequest = 'QuoteRequest__c';

    /***********************************************************************
    * Reinstatement
    ************************************************************************/
    /*sobject*/
    public static String sObjectReinstatement = 'Reinstatement__c';

    /***********************************************************************
    * Request
    ************************************************************************/
    /*sobject*/
    public static String sObjectRequest = 'Request__c';
    
    //Record Type
    public static String reqRTLead = 'Request__c-Lead';
    public static String reqRTPlacement = 'Request__c-Placement';
    public static String reqRTQuote = 'Request__c-Quote';
    public static String reqRTSigning = 'Request__c-Signing';
    public static String reqRTSA = 'Request__c-SA';

    //Reinsurer Status / SA_Request_Status__c
    public static String statusSetup = 'Setup';
    public static String statusSent = 'Sent';
    public static String statusAnswered = 'Answered';
    public static String statusTimeout = 'Timeout';
    public static String statusRefused = 'Refused';
    public static String statusSigned = 'Signed By R.M.';
    public static String statusRequestSigned = 'Signed';
    public static String statusRequestConfirmed = '3'; //Confirmed
    public static String statusRequestClosed = '4'; //Closed
    public static String statusAgreed = 'Agreed';
    public static String statusNotified = 'Notified';
    public static String statusMoreInfoRequired = 'More Infor Required';

    // RRA - 1054 : DocumentVisibility Status 
    public static String statusVisibleOnPortalDocVis = 'visibleOnPortal'; 

    // RRA - 939 : icon
    public static String iconComment = 'utility:comments';
    public static String iconAttach = 'utility:attach'; 
    
     //RRA - ticket 1541 - 05072023 : icon
     public static String iconDate = 'utility:expired'; 

    //SpecialAcceptanceAnswer__c
    public static String statusAgree = 'Agree';
    public static String statusRefuse = 'Refuse';
    public static String statusNeedMoreInfo = 'Need more information/Subjectivities';
    
    //Internal/Portal Sa Status
    public static String statusDraft = 'Draft';
    public static String statusSubmittedToAgre = 'Submitted to AXA SA';// RRA - ticket 1452 - 15032023
    public static String statusPending = 'Pending';
    public static String statusSentToReinsurer = 'Sent to Reinsurer(s)';
    
    /***********************************************************************
    * Special Acceptance
    ************************************************************************/
    /*sobject*/
    public static String sObjectSpecialAcceptance = 'SpecialAcceptance__c';

    //Record Type
    public static String saRTAutofac = 'SpecialAcceptance__c-Autofac';
    public static String saRTLife = 'SpecialAcceptance__c-Life';
    public static String saRTPC = 'SpecialAcceptance__c-PC';

    /***********************************************************************
    * Email Template
    ************************************************************************/
    /*sobject*/
    public static String sObjectEmailTemplate = 'EmailTemplate';

    //Email Template Name

    //TP Send
    public static String emailTemplateSendQuoteReqReinsurerForQuote = 'AGRE - Quote Request - Send - Reinsurer - For Quote';
    public static String emailTemplateSendRQuoteReqReinsurerForInformation = 'AGRE - Quote Request - Send - Reinsurer - For Information';
    public static String emailTemplateSendQuoteReqBrokerForQuote = 'AGRE - Quote Request - Send - Broker - For Quote';
    public static String emailTemplateSendQuoteReqBrokerForInformation = 'AGRE - Quote Request - Send - Broker - For Information';

    public static String emailTemplateSendRetainedBroker = 'AGRE - Lead Request - Send - Retained Broker';
    public static String emailTemplateSendRetainedReinsurer = 'AGRE - Lead Request - Send - Retained Reinsurer';
    public static String emailTemplateSendNonRetainedBroker = 'AGRE - Lead Request - Send - Non Retained Broker';
    public static String emailTemplateSendNonRetainedReinsurer = 'AGRE - Lead Request - Send - Non Retained Reinsurer';

    public static String emailTemplateSendPlacementReqBroker = 'AGRE - Placement Request - Send - Broker';
    public static String emailTemplateSendPlacementReqReinsurer = 'AGRE - Placement Request - Send - Reinsurer';

    public static String emailTemplateSendSigningReqBroker = 'AGRE - Signing Request - Send - Broker';
    public static String emailTemplateSendSigningReqReinsurer = 'AGRE - Signing Request - Send - Reinsurer';
    public static String emailTemplateSendSigningBrokerSignedShare = 'AGRE - Signing Request - Send - Broker - Signed Share Zero';
    public static String emailTemplateSendSigningReinsurerSignedShare = 'AGRE - Signing Request - Send - Reinsurer - Signed Share Zero';

    //TP Update
    public static String emailTemplateUpdateReq = 'AGRE - Request - Update';

    //TP Remind
    public static String emailTemplateRemindReq = 'AGRE - Request - Remind';

    //Signing
    public static String emailTemplateValidateReq = 'AGRE - Signing Request - Ask for Validation';
    public static String emailTemplateCloseSigningReqNotifyWebXL = 'AGRE - Signing Request - Close Signing & Notify WebXL';
    public static String emailTemplateSignForPoolSend = 'AGRE - Sign for Pool';
    public static String emailTemplateSignForPoolRemind = 'AGRE - Sign for pool - Remind';
    public static String emailTemplateSignForPoolUpdate = 'AGRE - Sign for pool - Update';
    public static String emailTemplatePoolAnswer = 'AGRE - Sign for Pool - Answer';

    //TP - Portal
    public static String emailTemplateRequestAnswer = 'AGRE - Request - Answer';

    //Special Acceptance
    public static String emailTemplateSpecialAcceptanceSubmitToAGRE = 'AGRE - Special Acceptance - Submit to AGRE';
    public static String emailTempSendSaReqBroker = 'AGRE - SA Request - Send - Internal - Broker';
    public static String emailTempSendSaReqReinsurer = 'AGRE - SA Request - Send - Internal - Reinsurer';
    public static String emailTempSendSaReqPool = 'AGRE - SA Request - Send - Internal - Pool';

    public static String emailTempUpdateSaReqBroker = 'AGRE - SA Request - Update - Internal - Broker';
    public static String emailTempUpdateSaReqReinsurer = 'AGRE - SA Request - Update - Internal - Reinsurer';
    public static String emailTempUpdateSaReqPool = 'AGRE - SA Request - Update - Internal - Pool';

    public static String emailTempRemindSaReqBroker = 'AGRE - SA Request - Remind - Internal - Broker';
    public static String emailTempRemindSaReqReinsurer = 'AGRE - SA Request - Remind - Internal - Reinsurer';
    public static String emailTempRemindSaReqPool = 'AGRE - SA Request - Remind - Internal - Pool';

    public static String emailTempNotifySaReqBroker = 'AGRE - SA Request - Notify - Internal - Broker';
    public static String emailTempNotifySaReqReinsurer = 'AGRE - SA Request - Notify - Internal - Reinsurer';

    public static String emailTempSaReqInformCedComAgreed = 'AGRE - SA Request - Inform Ceding Company - Agreed';
    public static String emailTempSaReqInformCedComRefused = 'AGRE - SA Request - Inform Ceding Company - Refused';
    public static String emailTempSaReqInformCedComAgreedDeclaratrion = 'AGRE - SA Request - Inform Ceding Company - Agreed - Declaration';// MRA W-1229 - 12/08/2022 - SA Declaration Type another email template


    public static String emailTempSaBindCedComPccSaEmail = 'AGRE - SA - Bind - Ceding Company - PCC SA Email';
    public static String emailTempSaBindCedComBroker = 'AGRE - SA - Bind - Ceding Company - Broker';
    public static String emailTempSaBindCedComReinsurer = 'AGRE - SA - Bind - Ceding Company - Reinsurer';

    public static String emailTempSaBindInternalCovCedCon = 'AGRE - SA - Bind - Internal - Covered Ceding Contact';
    public static String emailTempSaBindInternalBroker = 'AGRE - SA - Bind - Internal - Broker';
    public static String emailTempSaBindInternalReinsurer = 'AGRE - SA - Bind - Internal - Reinsurer';

    public static String emailTempSaBindReminder = 'AGRE - SA - Bind - Reminder';

    public static String emailTempSaReqAnswerAgree = 'AGRE - SA Request - Answer - Agree';
    public static String emailTempSaReqAnswerRefuse = 'AGRE - SA Request - Answer - Refuse';
    public static String emailTempSaReqAnswerNeedMoreInfo = 'AGRE - SA Request - Answer - Need More Info';

    /***********************************************************************
    * Contact
    ************************************************************************/
    /*sobject*/
    public static String sObjectContact = 'Contact';

    // Picklist Value
    public static String contactBroker = 'Broker';
    public static String contactReinsurer = 'Reinsurer';

    //Record type
    public static String contactSignatory = 'Signatory';

    //Profile name
    public static String profileSysAdmin = 'System Administrator';
    public static String profileSysAdminAGRe = 'AGRE_System Admin';
    public static String profileDelagatedAdmin = 'AGRE_Delegated Admin';

    /***********************************************************************
    * Public Group
    ************************************************************************/
    /*sobject*/
    public static String sObjectGroup = 'Group';

    //Custom_AllInternalUsers
    public static String groupCustomAllInternalUsers = 'Custom_AllInternalUsers';
    public static String groupCustomAllInternalUsersPCC = 'Custom_AllInternalUsersPCC';
}