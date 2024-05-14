/***
* @description Class used as flow action to generate minute line items
* @author      AMI
* @date        05/09/2022
***/
public with sharing class FLW01_GenerateMinuteLineItems {
    /***
    * @description Method to generate minute line items
    * @param       list <minuteRequest> triggeredMinutes
    * @return      list <mliResult>
    * @exception   none special.
    * @author      AMI
    * @date        05/09/2022
    ***/
    @InvocableMethod(label='Generate Minute Line Items' description='Generate Minute Line Items')
    public static list <mliResult> generateMLI(list <minuteRequest> triggeredMinutes){
        system.debug(LoggingLevel.DEBUG, 'START FLW01_GenerateMinuteLineItems - generateMLI - with triggeredMinutes ' + triggeredMinutes);

        //method result list
        list <mliResult> result = new list <mliResult>();

        //parse inputs and variables
        list <Minute__c> minutes = triggeredMinutes.get(0).minutesInputList;

        //generated minutes
        list <MinuteLineItem__c> generatedMLI = new list <MinuteLineItem__c>();
        
        //loop in triggered records
        for(Minute__c min : minutes){
            if(string.isNotBlank(min.Description__c)){

                String currDesc = min.Description__c; 
                currDesc = currDesc.replaceAll('<[^>]+>',' ');
                List<string> strList = splitString(currDesc);

                System.debug('currDesc ' + currDesc);
                // list <string> strList = new list <string>(min.Description__c.split('<p><br></p><p><br></p>'));
                system.debug(LoggingLevel.DEBUG, 'FLW01_GenerateMinuteLineItems - generateMLI - strList' + strList);

                if(!strList.isEmpty()){
                    for(string str : strList){
                        generatedMLI.add(new MinuteLineItem__c(Minute__c = min.Id,
                                                                Content__c = str));
                    }
                }//end if !strList.isEmpty()
            }//end if string.isNotBlank(min.Description__c)
        }//end looping in triggered minutes

        System.debug('generate MLI: ' + generatedMLI);

        //parse output
        system.debug(LoggingLevel.DEBUG, 'FLW01_GenerateMinuteLineItems - generateMLI - generatedMLI ' + generatedMLI);
        if(!generatedMLI.isEmpty()){
            mliResult mliRes = new mliResult();
            mliRes.mliOutputList = generatedMLI;
            result.add(mliRes);
        }

        system.debug(LoggingLevel.DEBUG, 'END FLW01_GenerateMinuteLineItems - generateMLI');
        return result;
    }

    /***
    * @description Apex Object Request
    * @param       none special.
    * @exception   none special.
    * @author      AMI
    * @date        05/09/2022
    ***/
    public class minuteRequest{
        @InvocableVariable
        public list <Minute__c> minutesInputList;
    }
    
    /***
    * @description Apex Object Result
    * @param       none special.
    * @exception   none special.
    * @author      AMI
    * @date        05/09/2022
    ***/
    public class mliResult{
        @InvocableVariable
        public list <MinuteLineItem__c> mliOutputList;
    }


    /***
    * @description Splits a large string into smaller substrings 
    * @param       text The string that needs to be splitted
    * @return      list <String> : List of smaller string subsets
    * @exception   none special.
    * @author      SBH
    * @date        27/02/2023
    ***/
    public static List<String> splitString(String text) {
        List<String> result = new List<String>();
        List<String> words = text.split(' ');
        String currentLine = '';
        for (String word : words) {
            if (currentLine.length() + word.length() + 1 > 410) {
                result.add(currentLine.trim());
                currentLine = '';
            }
            currentLine += word + ' ';
        }
        result.add(currentLine.trim());
        return result;
    }
}