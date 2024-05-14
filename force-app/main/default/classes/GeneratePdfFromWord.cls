/**
 * @description       : 
 * @author            : Patrick Randrianarisoa
 * @group             : 
 * @last modified on  : 13-09-2023
 * @last modified by  : Patrick Randrianarisoa
 * Modifications Log
 * Ver   Date         Author                   Modification
 * 1.0   13-09-2023   Patrick Randrianarisoa   Initial Version
**/
public with sharing class GeneratePdfFromWord {
    public GeneratePdfFromWord() {

    }

    public static void GeneratePdf(){
    
        Id docId = '0695E000004ebqAQAQ';
        String filename = 'newPDFFile.pdf';
        Boolean addWatermark = true;
        Boolean removeWatermark = false;
        String headerText = 'This is Header';
        String footerText = 'This is Footer';
        String apiServerURL = System.Url.getSalesforceBaseUrl().toExternalForm() + '/services/Soap/u/50.0/' + UserInfo.getOrganizationId();
        String SessionId = UserInfo.getSessionId();
        String apiSessionId = UserInfo.getSessionId();
        Id convertedDocId;
        if(!Test.isRunningTest()){
            convertedDocId = Apttus.MergeWebService.convertWordDocToPDF(docId, fileName,
            addWatermark, removeWatermark, headerText, footerText, apiSessionId, apiServerURL);
        }else{
            convertedDocId = '0015E000037awhLQAQ';
        }

        System.debug('docId: ' + convertedDocId);
    }


    public static void generatePdf2(){
        ID docId = '0695E000004ehJvQAI';
        String docFileName = 'Agreementtest';
        ID sObjectId = null;
        String pLevel = null;
        Boolean addWatermark = true;
        Boolean removeWatermark = false;
        String headerText = 'Agreement Id: 0123456789';
        String footerText = 'Date Created: 11/27/2018 7:23:15 PM';
        String sessionId = UserInfo.getSessionId(); //This is the session Id.
        String serverUrl = System.Url.getSalesforceBaseUrl().toExternalForm() + '/services/Soap/u/50.0/' + UserInfo.getOrganizationId();
        ID ConvertedDocId;
        if(!Test.isRunningTest()){
            ConvertedDocId = Apttus.MergeWebService.convertWordDocToPDF2(docId,docFileName,sObjectId,pLevel,addWatermark,removeWatermark,headerText,footerText,sessionId,serverUrl);
        }else{
            ConvertedDocId = '0015E000037awhLQAQ';
        }
    }
}