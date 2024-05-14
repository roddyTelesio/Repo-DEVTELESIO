/**
 * @description       : 
 * @author            : Telesio
 * @group             : 
 * @ticket            : 1574
 * @last modified on  : 16-10-2023
 * @last modified by  : Telesio (RRA)
 * Note: -schedule bacth BAT004_ReminderQuoteValidity
**/
global class ScheduleReminderMailQuoteValidity implements Schedulable{
    global void execute(SchedulableContext sc){
        Integer batchSize = 200;             
        BAT004_ReminderQuoteValidity myBatch = new BAT004_ReminderQuoteValidity();
        Id batchprocessid = Database.executeBatch(myBatch,batchSize);            
    }
}