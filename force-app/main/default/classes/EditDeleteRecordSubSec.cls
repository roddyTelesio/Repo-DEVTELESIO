/**
 * @description       : 
 * @author            : Telesio
 * @group             : 
 * @last modified on  : 19-08-2022
 * @last modified by  : Telesio (RRA)
**/
public with sharing class EditDeleteRecordSubSec {
    public class ObjectContext {     
        @InvocableVariable(required=true label='Subsection record Id' ) //ID from LWC
        public String idSubsection;

        @InvocableVariable(required=true label='Action Edit/Delete' ) //ID from LWC
        public String action;

        @InvocableVariable(required=true label='id Section Record' ) //ID from LWC
        public String recordId;
    }


    public class Result {
        @InvocableVariable(required=false label='Is Success ?')
        public Boolean isSuccess;

        @InvocableVariable(required=false label='Preselected PortfolioSegments')
        public List<PortfolioSegment__c> preselectedPSegs;

        @InvocableVariable(required=false label='Preselected HazardBassins')
        public List<ReferentialHazardBassin__c> preselectedHBs;

        @InvocableVariable(required=false label='Preselected Conditions')
        public SubSection__c preselecteConditions;

        @InvocableVariable(required=false label='Preselected Reinstatements')
        public List<Reinstatement__c> preselecteReins;

        @InvocableVariable(required=false label='Error message')
        public String errorMessage;

        public Result(Boolean isSuccess, List<ReferentialHazardBassin__c> preselectedHBs, List<PortfolioSegment__c> preselectedPSegs, SubSection__c preselecteConditions,  List<Reinstatement__c> preselecteReins, String errorMessage){
            this.isSuccess = isSuccess;
            this.preselectedPSegs = preselectedPSegs;
            this.preselectedHBs = preselectedHBs;
            this.preselecteConditions = preselecteConditions;
            this.preselecteReins = preselecteReins;
            this.errorMessage = errorMessage;
        }
    }

    /***
    * @description	Method to prepare callout to retrieve slots 
    * @param	    obj 
    * @return		List<Slots> 
    * @exception   	None
    ***/   
    @InvocableMethod(label='[NERE] Edit Records SubSection' description='Get Preselections' callout=false)
    public static List<Result> getPreselectionsSubSections(List<ObjectContext> obj) {

        System.debug(LoggingLevel.DEBUG, 'getPreselections START with : ' + obj);

        String selectedSubsection = obj[0].idSubsection;
        System.debug(LoggingLevel.DEBUG, 'getPreselections selectedSubsection: ' + selectedSubsection);

        String action = obj[0].action;
        System.debug(LoggingLevel.DEBUG, 'getPreselections action: ' + action);
        Savepoint sp = Database.setSavepoint();
        try{
             if(action == 'Edit'){
                // Get SubSection - RRA - ticket 1532 - 13062023
               SubSection__c Conditions = [
                SELECT Id, AAD__c, AAL__c, Deductible__c, Limit__c, LimitType__c, PrincipalSubSection__c, lstPortFolioSegment__c, lstNameReferentialHazardBassin__c, TAL__c, Unlimited__c
                FROM SubSection__c
                WHERE Id =: selectedSubsection 
            ];

                // Get Reinstatement
                List<Reinstatement__c> lstReins = [
                    SELECT Id, Free__c, Order__c, Percentage__c, Prorata__c, Type__c, FreeValue__c, ProrataValue__c, Section__c, Sub_Section__c
                    FROM Reinstatement__c
                    WHERE Sub_Section__c =: selectedSubsection AND Key_Insert_Update_Reinstatement__c != NULL ORDER BY Order__c
                    //WHERE (Section__c =: obj[0].recordId AND Sub_Section__c = NULL) OR (Sub_Section__c =: selectedSubsection) ORDER BY Order__c
                ];

                // Get ReferentialHazardBassin
                 List<ReferentialHazardBassin__c> PreselectedHBs = [
                     SELECT Id 
                     FROM ReferentialHazardBassin__c
                     WHERE Id IN (
                        SELECT Referential_Hazard_Bassin__c
                        FROM PortfolioSubsection__c
                        WHERE Referential_Hazard_Bassin__c != null 
                        AND PortfolioSegment__c = null
                        AND Subsection__c =: selectedSubsection
                     )
                 ];

                 // Get PortfolioSegment
                 List<PortfolioSegment__c> PreselectedPsegs= [
                    SELECT Id 
                    FROM PortfolioSegment__c
                    WHERE Id IN (
                        SELECT PortfolioSegment__c
                        FROM PortfolioSubsection__c
                        WHERE Referential_Hazard_Bassin__c = null 
                        AND PortfolioSegment__c != null
                        AND Subsection__c =: selectedSubsection
                     )
                 ];
                 System.debug(LoggingLevel.DEBUG, 'getPreselections 2 ');
             return new List<Result>{new Result(true, PreselectedHBs,PreselectedPsegs, Conditions, lstReins, null)};

             }else if(action == 'Delete'){
                System.debug(LoggingLevel.DEBUG, 'Delete Begin: ');
                 //delete HB 
                 deleteJunctionsHBassins(selectedSubsection);
                 //delete PS 
                 deleteJunctionsPSegments(selectedSubsection);
                 //delete Reinstatements
                 deleteReinstatements (selectedSubsection);
                 //delete conditions
                 deleteConditions(selectedSubsection);
                 
             }

            //System.debug(LoggingLevel.DEBUG, 'getPreselections END');
            // return new List<Result>{new Result(true, selectedSubsection, null)};
            return null;

        }catch(Exception e){
            Database.rollback( sp );
            System.debug(LoggingLevel.DEBUG, 'getPreselections Exception occured: ' + e.getMessage());
            return new List<Result>{new Result(false, null,null,null, null, e.getMessage())};
        }
    }

    public static void deleteConditions(String subsectionId){
        System.debug(LoggingLevel.DEBUG, 'deleteConditions START with subsectionId : ' + subsectionId);
        delete [
            SELECT Id 
            FROM  SubSection__c 
            WHERE Id =: subsectionId FOR UPDATE];
        System.debug(LoggingLevel.DEBUG, 'deleteConditions END');
    }

    public static void deleteJunctionsHBassins(String subsectionId){
        System.debug(LoggingLevel.DEBUG, 'deleteJunctionsHazardBassins START with subsectionId : ' + subsectionId);
        delete [
            SELECT Id 
            FROM  PortfolioSubsection__c 
            WHERE SubSection__c=: subsectionId 
            AND   Referential_Hazard_Bassin__c != NULL
            AND   PortfolioSegment__c = NULL FOR UPDATE];
        System.debug(LoggingLevel.DEBUG, 'deleteJunctionsHazardBassins END');
    }

    public static void deleteJunctionsPSegments(String subsectionId){
        System.debug(LoggingLevel.DEBUG, 'deleteJunctionsPSegments START with subsectionId : ' + subsectionId);
        delete [
            SELECT Id 
            FROM  PortfolioSubsection__c 
            WHERE SubSection__c=: subsectionId 
            AND   Referential_Hazard_Bassin__c = NULL
            AND   PortfolioSegment__c != NULL FOR UPDATE];
        System.debug(LoggingLevel.DEBUG, 'deleteJunctionsPSegments END');
    }


    public static void deleteReinstatements(String subsectionId){
        System.debug(LoggingLevel.DEBUG, 'deleteReinstatement START with subsectionId : ' + subsectionId);
        delete [
            SELECT Id 
            FROM  Reinstatement__c 
            WHERE Sub_Section__c=: subsectionId FOR UPDATE ];
        System.debug(LoggingLevel.DEBUG, 'deleteReinstatement END');
    }

}