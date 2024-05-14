/**************************************************************************************
-- - Author        : Telesio
--
-- Maintenance History:
--
-- Date         Name  Version  Remarks
-- -----------  ----  -------  -------------------------------------------------------
-- 25-OCT-2023  RRA   1.0      Initial version
-- Ticket 1681 
***************************************************************************************/
public with sharing class LWC62_UpdateRefSeqOnTreaty {

public static void updateRefSeqOnTreaty(List<Treaty__c> lstNewTreaties){
    System.debug('lstNewTreaties old == ' + lstNewTreaties);
    String strTreatyRef;
    String strWebXLRef;
    String strActorRef;
    String strRefSequence;
    String treatyRef;
    String webXLRef;
    String actorRef;
    List<String> lstTreatyRefWitSlash;
    List<String> lstWebXLRefWitSlash;
    List<String> lstActorRefWitSlash;
    
    for(Integer i = 0; i < lstNewTreaties.size(); i++){   
        System.debug('TECH_RenewedFromTreaty__c BeforeUpdate== ' + lstNewTreaties[i].TECH_RenewedFromTreaty__c);     
        treatyRef = lstNewTreaties[i].TreatyReference__c;
        webXLRef = lstNewTreaties[i].WebXLReference__c;
        actorRef = lstNewTreaties[i].Actor_Reference__c;
        List<String> lstTreatyRef = treatyRef.split('-');
        List<String> lstWebXLRef= webXLRef.split('-');
        List<String> lstActorRef = actorRef.split('-');
        
        if (lstTreatyRef[1].contains('/')){
            lstTreatyRefWitSlash =  lstTreatyRef[1].split('/');
            strTreatyRef = String.ValueOf(lstTreatyRefWitSlash[0]);
        }else{
            strTreatyRef = String.ValueOf(lstTreatyRef[1]);
        }
        
        if (lstWebXLRef[1].contains('/')){
            lstWebXLRefWitSlash =  lstWebXLRef[1].split('/');
            strWebXLRef = String.ValueOf(lstWebXLRefWitSlash[0]);
        }else {
            strWebXLRef = String.ValueOf(lstWebXLRef[1]);
        }
        
        if (lstActorRef[1].contains('/')){
            lstActorRefWitSlash =  lstActorRef[1].split('/');
            strActorRef = String.ValueOf(lstActorRefWitSlash[0]);
        }else {
            strActorRef = String.ValueOf(lstActorRef[1]);
        }
        
        strRefSequence = String.ValueOf(lstNewTreaties[i].ReferenceSequence__c);
        
        if (!strRefSequence.equals(strTreatyRef) || !strRefSequence.equals(strWebXLRef) || !strRefSequence.equals(strActorRef)){
            lstNewTreaties[i].TreatyReference__c = lstTreatyRef[0] + '-' + strRefSequence;
            lstNewTreaties[i].WebXLReference__c = lstWebXLRef[0] + '-' + strRefSequence;
            lstNewTreaties[i].Actor_Reference__c = lstActorRef[0] + '-' + strRefSequence;
        }
        
        /*if (refSequence != intTreatyRef || refSequence != intWebXLRef || refSequence != intActorRef){
            lstNewTreaties[i].TreatyReference__c = lstTreatyRef[0] + '-' + refSequence;
            lstNewTreaties[i].WebXLReference__c = lstWebXLRef[0] + '-' + refSequence;
            lstNewTreaties[i].Actor_Reference__c = lstActorRef[0] + '-' + refSequence;
        }*/
    }
    System.debug('intTreatyRef BeforeUpdate== ' + strTreatyRef);
    System.debug('intWebXLRef BeforeUpdate== ' + strWebXLRef);
    System.debug('intActorRef BeforeUpdate== ' + strActorRef);
    System.debug('refSequence BeforeUpdate== ' + strRefSequence);
    System.debug('lstNewTreaties update BeforeUpdate== ' + lstNewTreaties);
  }
}