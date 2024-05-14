public with sharing class lwc57ReinstatementUIFlow {

    @AuraEnabled
    public static List<Reinstatement__c> getReinstatementsApiName(String selectedSectionId, String isSubSec ) {
        return [
                SELECT Id, Name, Order__c, Section__c, Sub_Section__c, Key_Insert_Update_Reinstatement__c, Percentage__c, Prorata__c, Free__c, Type__c
                FROM Reinstatement__c
                WHERE Section__c = :selectedSectionId AND Sub_Section__c = :isSubSec
        ];
    }

    @AuraEnabled
    public static void deleteReinstatementSelected(List<Id> lstIdReins) {
        List<Reinstatement__c> lstReinsToDelete = new List<Reinstatement__c> ();
        List<Reinstatement__c> lstReins = [ SELECT Id, Name, Order__c, Section__c, Key_Insert_Update_Reinstatement__c, Percentage__c, Prorata__c, Free__c, Type__c FROM Reinstatement__c WHERE Id IN:lstIdReins FOR UPDATE];
        for (Reinstatement__c reins : lstReins){
            if (reins.Key_Insert_Update_Reinstatement__c != null){
                lstReinsToDelete.add(reins);
            }
        }
        if (lstReinsToDelete.size() > 0){
            delete lstReinsToDelete;
        }
    }

    /*@AuraEnabled
    public static String deleteReinstatementSelected(List<Id> lstIdReins) {
        String message = null;
        List<Reinstatement__c> lstReinsToDelete = new List<Reinstatement__c> ();
        List<Reinstatement__c> lstReins = [ SELECT Id, Name, Order__c, Section__c, Key_Insert_Update_Reinstatement__c, Percentage__c, Prorata__c, Free__c, Type__c FROM Reinstatement__c WHERE Id IN:lstIdReins FOR UPDATE];
        for (Reinstatement__c reins : lstReins){
            if (reins.Key_Insert_Update_Reinstatement__c != null){
                message = null;
                lstReinsToDelete.add(reins);
            }else{
                message = message + 'deletion_not_permit';
            }
        }
        if (lstReinsToDelete.size() > 0){
            delete lstReinsToDelete;
        }
        return message;
    }*/
}