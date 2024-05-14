/**
 * @description       : Schedulable class to enqueue CLM_UniversignDocRetrieval_QUE
 * @author            : Your Name
 * @group             : 
 * @last modified on  : 01-17-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class CLM_UniversignDocRetrieval_QUE_SCHEDULE implements Schedulable {

    // Constructor
    public CLM_UniversignDocRetrieval_QUE_SCHEDULE() {}

    /**
     * @description Executes the scheduled job.
     * @param sc SchedulableContext
     */
    public void execute(SchedulableContext sc) {
        // Enqueue the CLM_UniversignDocRetrieval_QUE
        System.debug('CLM_UniversignRetrieval_QUE_SCHEDULE Execute');

        System.enqueueJob(new CLM_UniversignDocRetrieval_QUE());
    }
}