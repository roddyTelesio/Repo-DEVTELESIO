/***
* @author      AMI
* @date        13/07/2022
* @description Apex class implementing the main business rules to prevent ACR deletion
***/
public with sharing class AP64_PreventACRDeletion {
    /***
    * @description Prevent ACR deletion if request for portal activation has been sent and connected user is CE
    * @param       list <AccountContactRelation> triggeredACRList
    * @return      void
    * @exception   none special.
    * @author      AMI
    * @date        13/07/2022      
    ***/ 
    public static void preventACRDeletion (list <AccountContactRelation> triggeredACRList) {
        system.debug(LoggingLevel.DEBUG,'START AP64_PreventACRDeletion - preventACRDeletion with triggeredACRList ' + triggeredACRList.size()); 

        //check if connected user is CE
        boolean isConnectedUserCE = isUserCE();

        //map of acr that should not be allowed to delete if request for portal activation has been sent and connected user is CE
        map <id,AccountContactRelation> filteredExceptionACR = new map <id,AccountContactRelation>();

        //Data Preparation
        for(AccountContactRelation iter : triggeredACRList){
            //check if associated contact is subjected to portal activation
            if(iter.Tech_ContactActivationReqSent__c){
                filteredExceptionACR.put(iter.Id,iter);
            } 
        }
        system.debug(LoggingLevel.DEBUG, 'AP64_PreventACRDeletion - preventACRDeletion: filteredExceptionACR: ' + filteredExceptionACR);

        //Exection of main logic
        for(AccountContactRelation iter1 : triggeredACRList){
            //prevent acr deletion
            if(isConnectedUserCE && filteredExceptionACR.containsKey(iter1.Id)){
                addErrorForACRDeletion(filteredExceptionACR.get(iter1.Id));
            }
        }
        
        system.debug(LoggingLevel.DEBUG,'END AP64_PreventACRDeletion - preventACRDeletion'); 
    } 

    /***
    * @description Utility method to determine if connected user has a Client Executive profile assigned
    * @param       none
    * @return      boolean
    * @exception   none special.
    * @author      AMI
    * @date        13/07/2022      
    ***/ 
    @TestVisible 
    private static boolean isUserCE() {
        system.debug(LoggingLevel.DEBUG,'START AP64_PreventACRDeletion - isUserCE'); 

        string connectedUserProfileName = [select Name from Profile where Id =: UserInfo.getProfileId()]?.Name;

        system.debug(LoggingLevel.DEBUG,'END AP64_PreventACRDeletion - isUserCE with connectedUserProfileName ' + connectedUserProfileName); 
        return connectedUserProfileName == 'AGRE_Actor C.E';
    } 

    /***
    * @description Utility method to add error to current record and stops all execution
    * @param       AccountContactRelation acr
    * @return      void
    * @exception   none special.
    * @author      AMI
    * @date        13/07/2022      
    ***/ 
    @TestVisible 
    private static void addErrorForACRDeletion(AccountContactRelation acr) {
        system.debug(LoggingLevel.DEBUG,'START AP64_PreventACRDeletion - addErrorForACRDeletion'); 

        acr.addError(system.label.ErrorMsgACRDeletion);

        system.debug(LoggingLevel.DEBUG,'END AP64_PreventACRDeletion - addErrorForACRDeletion'); 
    } 
}