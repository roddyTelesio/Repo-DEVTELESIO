/**
 * @description       : 
 * @author            : Patrick Randrianarisoa
 * @group             : 
 * @last modified on  : 23-11-2023
 * @last modified by  : Patrick Randrianarisoa
 * Modifications Log
 * Ver   Date         Author                   Modification
 * 1.0   14-11-2023   Patrick Randrianarisoa   Initial Version
**/
public class CLM_StringUtility {
    public class InputVariables{
        @InvocableVariable(required=true label='List String' )
        public List<String> listParameter;
        @InvocableVariable(required=false label='is List treaty ref' )
        public Boolean isTreatyref ; 
    }

    public class Result {
        @InvocableVariable(required=false label='Is Success ?')
        public Boolean isSuccess;

        @InvocableVariable(required=false label='Error Message')
        public String errorMsg;

        @InvocableVariable(required=false label='treaty ref')
        public String textValue;

        public Result(Boolean isSuccess, String errorMsg, String textValue){
            this.isSuccess = isSuccess;
            this.errorMsg = errorMsg;
            this.textValue = textValue;
        }
    }

    @InvocableMethod(label='[CLM] List to Text' description='Change List value to text')
    public static List<Result> getTextValueByList(List<InputVariables> lstInputVariables) {
        try{
            List<Result> resultlist = new List<Result>();
            for (InputVariables inputVar : lstInputVariables) {
                String text='';
                for(String ele : inputVar.listParameter ){
                    if(inputVar.isTreatyref){
                        text+= ele +';';
                    }else{
                        text+= ele +'\n ';
                        text+= ' ';
                    }
                }
                if(inputVar.isTreatyref && text.length() > 254){
                    text = text.substring(0, 254);
                }
                resultlist.add(new Result(true, null, text));
            }
            return resultlist;
        }
        catch(Exception e){  
            System.debug('getTextValueByList Exception  : ' + e.getMessage());
            return new List<Result>{ new Result(false, e.getMessage(), null)};
        }
    }
}