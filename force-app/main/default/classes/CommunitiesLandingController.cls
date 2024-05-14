/**
 * An apex page controller that takes the user to the right start page based on credentials or lack thereof
 */
public with sharing class CommunitiesLandingController {
/**************************************************************************************
-- - Author        : Spoon Consulting
-- - Description   : CommunitiesLandingController
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 12-MAR-2021  NBI   1.0      Initial version (Standard class - modified)
--------------------------------------------------------------------------------------
**************************************************************************************/    
    public static String url;
    
    // Code we will invoke on page load.
    public PageReference forwardToStartPage() {
        // return Network.communitiesLanding();
        
        String ntwrkId = Network.getNetworkId();
        if(!Test.isRunningTest()){
            ConnectApi.Community comm = ConnectApi.Communities.getCommunity(ntwrkId);
            url = comm.siteUrl;
        }
        List<String> urlArr = url.split('login');
        String communityUrl;
        
        if(urlArr[0].contains('cedingPortal')){
            communityUrl = urlArr[0] + '/s/';
        }
        else{
            communityUrl = urlArr[0] + '/s/homepage';
        }  
        
        return new PageReference(communityUrl);
    }
    
    public CommunitiesLandingController() {}
}