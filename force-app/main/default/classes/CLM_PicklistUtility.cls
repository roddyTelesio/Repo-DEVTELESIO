/**
 * @description       : 
 * @author            : Patrick Randrianarisoa
 * @group             : 
 * @last modified on  : 17-11-2023
 * @last modified by  : Patrick Randrianarisoa
 * Modifications Log
 * Ver   Date         Author                   Modification
 * 1.0   10-11-2023   Patrick Randrianarisoa   Initial Version
**/
public class CLM_PicklistUtility {
    public class InputVariables{
        @InvocableVariable(required=false label='picklist API name' )
        public String apiname;
        @InvocableVariable(required=true label='picklist field API name' )
        public String fieldApiname;
    }

    public class Result {
        @InvocableVariable(required=false label='Is Success ?')
        public Boolean isSuccess;

        @InvocableVariable(required=false label='Error Message')
        public String errorMsg;

        @InvocableVariable(required=false label='label picklist')
        public String label;

        public Result(Boolean isSuccess, String errorMsg, String label){
            this.isSuccess = isSuccess;
            this.errorMsg = errorMsg;
            this.label = label;
        }
    }

    @InvocableMethod(label='[CLM] Get picklist label by apiname' description='Get picklist label by apiname')
    public static List<Result> getPicklistLabelByApiName(List<InputVariables> lstInputVariables) {
        try{
            String labelValue;
            List<Schema.PicklistEntry> picklistEntries;
            List<Result> resultlist = new List<Result>();
            for(inputVariables inputVar : lstInputVariables){
                if(inputVar.fieldApiname == 'LossDepositMode__c'){
                    picklistEntries = Schema.SObjectType.Request__c.fields.LossDepositMode__c.getPicklistValues();
                }if(inputVar.fieldApiname == 'LossAttachment__c'){
                    picklistEntries = Schema.SObjectType.Treaty__c.fields.LossAttachment__c.getPicklistValues();
                }// Add instruction here for another picklist field
                For(Schema.PicklistEntry sp : picklistEntries){
                    if(inputVar.apiname == sp.getValue()){
                        labelValue = sp.getLabel();
                        break;
                    }
                }
                resultlist.add(new Result(true, null, labelValue));
            }
            return resultlist;
        }
        catch(Exception e){  
            System.debug('getPicklistLabelByApiName Exception  : ' + e.getMessage());
            return new List<Result>{ new Result(false, e.getMessage(), null)};
        }
    }
}