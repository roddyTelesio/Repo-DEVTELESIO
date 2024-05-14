public with sharing class LWC01_Programs {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : Controller for Lightning Web Component lwc01Programs
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 14-OCT-2019  NBI   1.0      Initial version
-- 08-JUL-2021  NBI   1.1      W-0992: Third Party Management
-- 08-JUN-2022  AMI   1.2      W-0874: Renew - Intermediary screen options REOPEN
--------------------------------------------------------------------------------------
**************************************************************************************/

    /**
    * @description Method to get Program(s) for the selected UW Year and Principal Ceding Company
    * @param String valueUWYear, String valuePrincipalCedComp
    * @return List<Program__c>
    */
    @AuraEnabled(Cacheable = true)
    public static List<Program__c> getPrograms(String valueUWYear, String valuePrincipalCedComp){
        return [SELECT Id, Name, toLabel(Macro_L_O_B__c), toLabel(Status__c), toLabel(STLT__c), InceptionDate__c, Expirydate__c, toLabel(LTA__c), toLabel(TacitRenewal__c), LTAInceptionDate__c, LTAExpiryDate__c
                      ,WordingName__c, WordingName2__c, WordingName3__c, WordingName4__c, Nature__c, LossDeposit__c, AdvanceNotice__c, EarlyTerminationDate__c
                      ,LTARenegociation__c, LossDepositLevel__c, LossDepositMode__c, UwYear__c, PrincipalCedingCompany__c, TECH_StageName__c, RenewedFromProgram__c, TypeOfRenew__c
                FROM Program__c
                WHERE UwYear__c = :valueUWYear AND PrincipalCedingCompany__c = :valuePrincipalCedComp
                ORDER BY Name
        ];
    }

    /**
    * @description Method to get Covered Ceding Companies the selected Program
    * @param String selectedProgramId
    * @return List<Program__c>
    */
    @AuraEnabled(Cacheable = true)
    public static List<CoveredCedingCompany__c> getCoveredCedingCompanies(String selectedProgramId) {
        return [SELECT Id, Name, Account__r.Name
                FROM CoveredCedingCompany__c
                WHERE Program__c = :selectedProgramId AND ProgramIsSelected__c = TRUE AND Account__r.IsActive__c= TRUE
        ];
    }

    /**
    * @description Method to get check for Renew Program
    * @param Id programId
    * @return Map<String, Object>
    */
    @AuraEnabled
    public static Map<String, Object> checkForRenewProgram(Id programId) {
        Map<String, Object> mapResults = new Map<String, Object>();
        Map<String, Id> mapRecTypeId = AP_Constant.getDeveloperIdMap(new Set<String>{AP_Constant.sObjectRequest});
        String recordTypeIdSigning = mapRecTypeId.get(AP_Constant.reqRTSigning);
        String errorMsg = null;
        String displayScreen = '0';
        Set<Id> setAccCovCedCom = new Set<Id>();
        List<Account> lstAccCovCedCom = new List<Account>();

        Program__c program = [SELECT Id, RenewedFromProgram__c, PrincipalCedingCompany__c, LTA__c, TacitRenewal__c, LTAExpiryDate__c, Expirydate__c, LTARenegociation__c, EarlyTerminationDate__c FROM Program__c WHERE Id = :programId];

        List<Program__c> lstRenewedProgram = [SELECT Id, Name, RenewedFromProgram__c FROM Program__c WHERE RenewedFromProgram__c = :program.Id];

        List<Request__c> lstSigningReq = [SELECT Id, Name, SigningStatus__c FROM Request__c WHERE SigningStatus__c = :AP_Constant.statusRequestClosed AND RecordTypeId =:recordTypeIdSigning AND Program__c = :program.Id];

        List<Account> lstAccountPCC = [SELECT Id, Name FROM Account WHERE Id = :program.PrincipalCedingCompany__c AND IsActive__c = TRUE]; //to check for IsActive

        //AMI 08/06/22 W:0874
        //new attribute to cater for intermediary screen message
        string modalInfo = '';
        //new attribute to cater for intermediary screen title
        string modalTitle = '';
        //new attribute to determine if lta regociation is active
        boolean ltaRenegociation = false;

        //1. Display Working Scope, Program Name, Treaty, Section
        //2. Display Working Scope, Program Name
        //3. Display pop up with choice of renew between LTA/TR Identical Renew and LTA/TR Renegotiation

        for(CoveredCedingCompany__c covCedCom : [SELECT Id, Name, Account__c FROM CoveredCedingCompany__c WHERE Program__c = :program.Id]){
            setAccCovCedCom.add(covCedCom.Account__c);
        }

        if(setAccCovCedCom.size() > 0){
            lstAccCovCedCom = [SELECT Id, Name FROM Account WHERE Id = :setAccCovCedCom AND IsActive__c = TRUE];
        }

        if(lstAccountPCC.size() == 0){
            //if PCC is inactive
            errorMsg = 'You cannot renew this program as the PCC is inactive';
        }
        else if(lstRenewedProgram.size() > 0){
            //if program already renewed
            errorMsg = 'You cannot renew this program as it has already been renewed';
        }
        else if(lstSigningReq.size() == 0){
            //if close signing = false
            errorMsg = 'You cannot renew this program as it is not signed yet';
        }
        else if(lstAccCovCedCom.size() == 0){
            //if program contains no active Covered Ceding Companies
            errorMsg = 'You cannot renew this program as all CCC are inactive';
        }
        else{
            if((program.LTA__c == '2' && program.TacitRenewal__c == '2') || (program.LTA__c == '1' && program.LTAExpiryDate__c == program.Expirydate__c)){
                //A. Standard Renew : OR(AND(LTA = No, Tacit Renewal = No), AND(LTA = Yes, LTA Expiry Date = Expiry Date)) AND Close signing = true AND PCC is active.
                //Display Working Scope, Program Name, Treaty, Section
                displayScreen = '1';
            }
            //AMI 08/06/22 W:0874
            //reordering "if conditions" to not display option screen when LTARenegociation__c = true
            else if((program.LTA__c == '1' && program.LTAExpiryDate__c > program.Expirydate__c)){
                //B. LTA/TR Identical Renew : (LTA = Yes and LTA Expiry Date > Expiry Date) OR TR = Yes AND Close signing = true AND PCC is active.
                //Display Working Scope, Program Name
                displayScreen = '2';

                //AMI 08/06/22 W:0874
                //adding new modal title and body message
                if(program.LTA__c == '1'){
                    string messageLTANo = 'You are about to perform an identical Renew. If it is not the type of renew you want to perform on this LTA program, please go change the content of the field LTA renegotiation from "No" to "Yes" in the program form';
                    string messageLTAYes = 'You are about to perform a renegotiation Renew. If it is not the type of renew you want to perform on this LTA program, please go change the content of the field LTA renegotiation from "Yes" to "No" in the program form';
                    modalInfo = program.LTARenegociation__c == '1' ? messageLTAYes : messageLTANo;
                    modalTitle = program.LTARenegociation__c == '1' ? 'Renegotiation Renew Program' : 'Identical Renew Program';
                    ltaRenegociation = program.LTARenegociation__c == '1' ? true : false;
                }
            }
            else if(((program.LTA__c == '1' && program.LTAExpiryDate__c > program.Expirydate__c) || program.TacitRenewal__c == '1') &&
                    ((program.LTARenegociation__c == '1' && program.LTAExpiryDate__c > program.Expirydate__c && program.EarlyTerminationDate__c < program.LTAExpiryDate__c) || program.TacitRenewal__c == '1')) {
                //B. LTA/TR Identical Renew : (LTA = Yes and LTA Expiry Date > Expiry Date) OR TR = Yes AND Close signing = true AND PCC is active.
                //and
                //C. LTA/TR Renegotiation : OR(AND(LTA Renegotiation = Yes , LTA Expiry Date > Expiry Date, Early Termination Date < LTA Expiry Date), TR = Yes) AND Close signing = true AND PCC is active.
                //Display pop up with choice of renew between B and C
                displayScreen = '3';
            }
            // else if((program.LTA__c == '1' && program.LTAExpiryDate__c > program.Expirydate__c) || program.TacitRenewal__c == '1'){
            //     //B. LTA/TR Identical Renew : (LTA = Yes and LTA Expiry Date > Expiry Date) OR TR = Yes AND Close signing = true AND PCC is active.
            //     //Display Working Scope, Program Name
            //     displayScreen = '2';
            // }
            // else if((program.LTARenegociation__c == '1' && program.LTAExpiryDate__c > program.Expirydate__c && program.EarlyTerminationDate__c < program.LTAExpiryDate__c) || program.TacitRenewal__c == '1'){
            //     //C. LTA/TR Renegotiation : OR(AND(LTA Renegotiation = Yes , LTA Expiry Date > Expiry Date, Early Termination Date < LTA Expiry Date), TR = Yes) AND Close signing = true AND PCC is active.
            //     //Display Working Scope, Program Name, Treaty, Section
            //     displayScreen = '1';
            // }
        }

        mapResults.put('errorMsg', errorMsg);
        mapResults.put('lstRenewedProgram', lstRenewedProgram);
        mapResults.put('displayScreen', displayScreen);
        mapResults.put('modalInfo', modalInfo);
        mapResults.put('modalTitle', modalTitle);
        mapResults.put('ltaRenegociation', ltaRenegociation);
        
        return mapResults;
    }

    /**
    * @description Method to check if PCC is active
    * @param String valuePrincipalCedComp
    * @return Boolean
    */
    @AuraEnabled(Cacheable = true)
    public static Boolean checkActivePCC(String valuePrincipalCedComp) {
        Boolean pccActive = false;

        Account acc = [SELECT Id, Name, IsActive__c
        FROM Account
        WHERE Id = :valuePrincipalCedComp
        ];

        if(acc != null) {
            pccActive = acc.IsActive__c;
        }
        return pccActive;
    }

    /**
    * @description Method to check Active PCC
    * @param Id programId
    * @return Boolean
    */
    @AuraEnabled
    public static Boolean checkCCC(Id programId){
        Boolean cccActive = true;
        Set<Boolean> setIsActive = new Set<Boolean>();

        for(CoveredCedingCompany__c ccc : [SELECT Id, Name, Account__r.IsActive__c FROM CoveredCedingCompany__c
        WHERE Program__c = :programId AND TreatyIsSelected__c = FALSE AND SectionIsSelected__c = FALSE]){
            setIsActive.add(ccc.Account__r.IsActive__c);
        }

        if(setIsActive.size() > 0){
            if(!setIsActive.contains(true)){
                cccActive = false;
            }
        }

        return cccActive;
    }
}