public with sharing class LC45_UIPortal {
    /**************************************************************************************
    -- - Author        : Spoon Consulting
    -- - Description   : Controller for Lightning Web Component lwc21NewLeadRequest
    --
    -- Maintenance History:
    --
    -- Date         Name  Version  Remarks
    -- -----------  ----  -------  -------------------------------------------------------
    -- 23-SEPT-2020  SAU   1.0      Initial version
    --------------------------------------------------------------------------------------
    **************************************************************************************/
	public static String url;
    
    @AuraEnabled
    public static User getUserDetails(){
        User connectedUser = [SELECT Id, 
                                     Email, 
                                     ProfileId, 
                                     Contact.AccountId, 
                                     SmallPhotoUrl 
                                     FROM User 
                                     WHERE Id =: UserInfo.getUserId()];
        return connectedUser;
    }

    @AuraEnabled
    public static String getPortalURL(){
        String ntwrkId = Network.getNetworkId();
        if(!Test.isRunningTest()){
            ConnectApi.Community comm = ConnectApi.Communities.getCommunity(ntwrkId);
            url = comm.siteUrl;
        }
        
        List<String> urlArr = url.split('login');
        String communityUrl = urlArr[0] + '/s/';
        return communityUrl;
    }

}