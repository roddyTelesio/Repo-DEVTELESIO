/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 11-30-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class CLM_getAOFClauseName {
    // Create a wrapper class to hold both parameters
    public class CLM_getAOFClauseNameInput {
        @InvocableVariable(label='Macro Lob' description='Macro Line of Business')
        public String MacroLob;

        @InvocableVariable(label='ReinsurerName' description='Reinsurer')
        public String reinsurer;

        @InvocableVariable(label='Covered Ceding Company Names' description='List of Covered Ceding Company Names')
        public List<String> CoveredCedingCompanyNames;
    }

    // Output class to return the template Id
    public class CLM_getAOFClauseNameOutput {
        @InvocableVariable(label='Template Name' description='Name of the first template')
        public String templateName;

        @InvocableVariable(label='Template Id' description='Id of the first template')
        public String templateId;
    }

    @InvocableMethod(label='Get AOF Clause Name' description='Returns the Id of the first template')
    public static List<CLM_getAOFClauseNameOutput> getFirstTemplateId(List<CLM_getAOFClauseNameInput> inputs) {
        List<CLM_getAOFClauseNameOutput> templateNames = new List<CLM_getAOFClauseNameOutput>();

        for (CLM_getAOFClauseNameInput input : inputs) {
            String macroLob = input.MacroLob;
            String reinsurer = input.reinsurer;
            List<String> coveredCedingCompanies = input.CoveredCedingCompanyNames;

            System.debug('Macro Lob: ' + macroLob);
            System.debug('Covered Ceding Companies: ' + coveredCedingCompanies);

            List<Apttus__APTS_Template__c> templates = [
                SELECT Id, Name
                FROM Apttus__APTS_Template__c 
                WHERE Apttus__Agreement_Types__c includes ('Retrocession')
                AND Apttus__Type__c = 'Clause'
                AND Macro_LOB__c includes (:macroLob)
               // AND CedingCompanies__c IN :coveredCedingCompanies
                AND Reinsurer__c includes (:reinsurer)
                ORDER BY CreatedDate ASC
                LIMIT 1
            ];

            CLM_getAOFClauseNameOutput output = new CLM_getAOFClauseNameOutput();
            if (!templates.isEmpty()) {
                System.debug('Found template: ' + templates);
                output.templateName = templates[0].Name;
                output.templateId = templates[0].Id;
            }else{
                System.debug('Did not found any template');
                output.templateName = null;
                output.templateId = null;
            }               
            templateNames.add(output);
        }

        return templateNames;
    }
    
}