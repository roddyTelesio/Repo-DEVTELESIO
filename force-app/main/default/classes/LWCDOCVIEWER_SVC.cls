public with sharing class LWCDOCVIEWER_SVC {
    
    @AuraEnabled
    public static Map<String,Object> getDocumentDetails(String processId){
        Map<String,Object> result = new Map<String,Object>() ;
        try {
            Id objectId = [SELECT Id,ProcessInstance.TargetObjectId FROM ProcessInstanceWorkitem WHERE Id = :processId LIMIT 1].ProcessInstance.TargetObjectId ;
            result.put('ObjectName',objectId.getSObjectType().getDescribe().getName()) ;
            System.debug('### '+ objectId) ;
            System.debug('### '+ result.get('ObjectName')) ;

            if(result.get('ObjectName') == 'Apttus__APTS_Template__c'){
                Apttus__APTS_Template__c clause = [SELECT Id,Name,Apttus__Type__c, (SELECT Id, Name FROM Attachments) FROM Apttus__APTS_Template__c WHERE Id = :objectId][0] ;
                System.debug('### aa'+ clause) ;

                Attachment attach = clause.Attachments[0]	 ;
                result.put('attach',attach) ;
                result.put('tempType',clause.Apttus__Type__c) ;
                System.debug('### '+ clause) ;

            }
        } catch (Exception e) {
            result.put('error',e.getMessage()) ;
        }
        return result ; 
    }
}