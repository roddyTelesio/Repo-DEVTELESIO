/**
 * @description       : 
 * @author            : Patrick Randrianarisoa
 * @group             : 
 * @last modified on  : 19-02-2024
 * @last modified by  : Patrick Randrianarisoa
 * Modifications Log
 * Ver   Date         Author                   Modification
 * 1.0   13-09-2023   Patrick Randrianarisoa   Initial Version
**/
public with sharing class ConvertToPdf {

    @future(callout=true)
    public static void ConvertToPdf(String contentId, String title) {
            Id docId = contentId;
            String filename = title;
            Boolean addWatermark = false;
            Boolean removeWatermark = true;
            String headerText ;
            String footerText ;
            String apiServerURL = System.Url.getSalesforceBaseUrl().toExternalForm() + '/services/Soap/u/50.0/' + UserInfo.getOrganizationId();
            String apiSessionId = UserInfo.getSessionId();
            Id convertedDocId;
            if(!Test.isRunningTest()){
                convertedDocId = Apttus.MergeWebService.convertWordDocToPDF(docId, fileName,
                addWatermark, removeWatermark, headerText, footerText, apiSessionId, apiServerURL);
                System.debug('convertedDocId : ' + convertedDocId);
            }else{
                convertedDocId = '0015E000037awhLQAQ';
            }
    }
}