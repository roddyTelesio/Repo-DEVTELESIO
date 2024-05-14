/***
* @description	Generic service class for asynchronous operations, providing
*				various methods to launch, monitor... Queueable Apex processes. 
* @group		Common
* @author		P-E GROS (Salesforce)
* @date			2021-04-16
***/

//#######################################################################
//#######################################################################
// @TODO: Test the framework in parallel mode
// --> potential need to move to a Platform Event based design to register executions
//#######################################################################
//#######################################################################

public with sharing class Queueable_SVC {
    
    /***
     * @description	Configuration constant setting the number of minutes
     * 				for the aggregation of each Log record.
     ***/
        private final static Integer LOG_WINDOW = 10;
    
    /***
     * @description	Configuration constant setting the number of times
     * 				the upsert of a log record is retried.
     ***/
        private final static Integer MAX_RETRIES = 10;
        
        //############################################
        //######### QUEUE EXECUTION CONTROL ##########
        //############################################
        
    /***
    * @description	Static method to check if a Queuable process is currently
    *				running and launch it if not already running/queued.
    * @param		qClassName	Name of the Queuable Apex class to check/launch
    * @return		ID of the currently queued job (possibly just created)
    * @exception	None special.
    ***/ 
        public static ID checkLaunch(final String qClassName) {
            System.debug('checkLaunch: START for ' + qClassName);
            
               List<AsyncApexJob> apexJobs =
                [	SELECT Id, Status, JobType FROM AsyncApexJob 
                    WHERE JobType = 'Queueable'
                        AND Status IN ('Queued','Preparing','Processing')
                        AND ApexClass.Name = :qClassName
                    LIMIT 1];
            System.debug(LoggingLevel.FINE,'checkLaunch: apexJobs retrieved ' + apexJobs);
            
            ID jobId;
            if (apexJobs.size() == 0) {
                System.debug('checkLaunch: launching new queueable');
                Type qClass = Type.forName(qClassName);   
                if(!Test.isRunningTest()){
                       jobId = System.enqueueJob((Queueable)(qClass.newInstance()), 2);
                }
            }
            else {
                jobId = apexJobs[0].Id;
            }
            
            System.debug('checkLaunch: END with jobID ' + jobId);
            return jobId;
        }
    
            
        
        //############################################
        //########## QUEUE LOG REGISTRATION ##########
        //############################################
    
    /***
    * @description	Static method to register the results of a Queuable process
    *				execution, in terms of record processed and failures.
    *				This method should be called last within the Queueable
    *				execute method to properly evaluate CPU and callout measurements.
    *				QueueableLog record is locked by this method until transaction end.
    * @param		qClassName	Name of the Queuable Apex class executed
    * @param		rcdNbr		Number of records processed in the Queueable execution (OK + failed)
    * @param		failedRcdNbr	Number of records with failure in the Queueable execution
    * @param		message		Message to be appended (error logs, iteration stops...)
    * @param		context		Context data to be stored for reuse by next executions (typically when
    *							queuable process is relaunched after interruption).
    * @param		waitTime	WaitTime measured by current execution (in milliseconds),
    *							typically computed via the getTimeDelta() method.
    * @exception	DmlException raised if the log cannot be upserted after a MAX_RETRIES
    *							number of retries.
    ***/ 
        public static void logExecution(final String qClassName, final Integer rcdNbr, final Integer failedRcdNbr, final String message, final String context, final Integer waitTime) {
            System.debug('logExecution: START for ' + qClassName);
            
            QueueableLog__c currentLog = getLogData(qClassName, rcdNbr, failedRcdNbr, message, context, waitTime);
            System.debug('logExecution: currentLog init');
            
            registerLogData(currentLog,0);
            System.debug('logExecution: END');
    
            //logExecution(qClassName, rcdNbr, failedRcdNbr, message, context, waitTime, 0);
            /*try {
                QueueableLog__c currentLog = getQueueableLog(qClassName, rcdNbr, failedRcdNbr, message, context, waitTime,true);
                System.debug('logExecution: queueLog fetched');
            
                upsert currentLog;
            }
            catch (Exception e) {
                System.debug('logExecution: exception raised ' + e.getMessage());
                logExecution(qClassName, rcdNbr, failedRcdNbr, message, context, waitTime);
            }
    
            System.debug('logExecution: END');*/
        }
    
    /***
    * @description	logExecution method override with only rcdNbr registration.
    ***/
        public static void logExecution(final String qClassName, final Integer rcdNbr) {
            logExecution(qClassName,rcdNbr,0,'','',0);
        }
        
    /***
    * @description	logExecution method override with only rcdNbr, failedRcdNbr and message registration.
    ***/
         public static void logExecution(final String qClassName, final Integer rcdNbr, final Integer failedRcdNbr, final String message) {
            logExecution(qClassName,rcdNbr,failedRcdNbr,message,'',0);
        }
    
    /***
    * @description	logExecution method override with only rcdNbr and waitTime registration.
    ***/
        public static void logExecution(final String qClassName, final Integer rcdNbr, final Integer waitTime) {
            logExecution(qClassName,rcdNbr,0,'','',waitTime);
        }
    
    /***
    * @description	logExecution method override with only rcdNbr, failedRcdNbr and waitTime registration.
    ***/
        public static void logExecution(final String qClassName, final Integer rcdNbr, final Integer failedRcdNbr, final Integer waitTime) {
            logExecution(qClassName,rcdNbr,failedRcdNbr,'','',waitTime);
        }
     
    /***
    * @description	Alternate version to the standard logExecution method to simply
    *				register a prior log initialized via the getLogData() method.
    *				Its main purpose is to generate the log of a Queueable execution
    *				(via the getLogData() method) but actually register it in a later 
    *				chained Queeuable execution (typically to handle 'MixedDML' constraints).
    * @param		log		QueueableLog__c record fully initialized (e.g. via the getLogData() method)
    * @exception	DmlException raised if the log cannot be upserted after a MAX_RETRIES
    *						number of retries.
    ***/
        public static void logPriorExecution(final QueueableLog__c log) {
            System.debug('logPriorExecution: START for ' + log.Name);
            registerLogData(log,0);
            System.debug('logPriorExecution: END');
        }
    
        
        //#############################################
        //############## UTILITY METHODS ##############
        //#############################################
      
    /***
    * @description	Static method to fetch the last Context stored on the most recent
    *				QueueableLog for a given Queuable process.
    * @param		qClassName	Name of the Queuable Apex class
    * @return		String Value of the most recent of the currently queued job (possibly just created)
    * @exception	None special.
    ***/ 
        public static String getLastContext(final String qClassName) {
            System.debug(LoggingLevel.FINE,'getLastContext: START for ' + qClassName);
            
            List<QueueableLog__c> lastLog = [select LastContext__c
                                             from QueueableLog__c
                                             where ProcessName__c = :qClassName
                                             order by CreatedDate desc limit 1];
            System.debug(LoggingLevel.FINEST,'getLastContext: lastLog fetched ' + lastLog);
            
            String contextValue = '';
            if ((lastLog != null) && (lastLog.size() > 0)) {
                contextValue = (lastLog[0]).LastContext__c;
                if (contextValue == null) contextValue = '';
            }
            System.debug(LoggingLevel.FINE,'getLastContext: END with ' + contextValue);
            
            return contextValue;
        }
            
    /***
    * @description	Static utility method to compute the time difference (in milliseconds)
    *				between two timestamps. 
    *				Usually used to compute the waitTime of a queuable process, i.e. the difference
    *				between class instanciation and execute() method start timestamps.
    * @param		startTS	First start timestamp
    * @param		endTS	Last end timestamp
    * @return		Time difference in milliseconds
    * @exception	None special
    ***/
        public static Integer getTimeDelta(final DateTime startTS, final DateTime endTS){
            return (Integer) (endTS.getTime() - startTS.getTime());
        }
    
    /***
    * @description	Method to upsert the current Log record of a Queueable process with
    *				data from one of its execution.
    *				It looks for the QueueableLog__c with same name in the database and
    *				if not found tries to insert it, otherwise updates it (by merging
    *				the existing record with the new, via the mergeLogData() method).
    *				QueueableLog__c are fetched in FOR UPDATE mode to ensure only one
    *				Queueable (of the same process) updates the current log record at a time.
    *				In case of failure, it retries the operation a MAX_RETRY_NBR number
    *				of times (e.g. to cope with parallel inserts on new records for
    *				Queueable processes of same class executing in parallel).
    * @param		qClassName	Name of the Queuable Apex class
    * @param		iteration	Retry iteration number (should be set at 0 by default)
    * @return		String Value of the most recent of the currently queued job (possibly just created)
    * @exception	None special.
    ***/ 
        private static void registerLogData(final QueueableLog__c newLog, final Integer iteration) {
            System.debug(LoggingLevel.FINE,'registerLogData: START for ' + newLog.Name);
            System.debug(LoggingLevel.FINE,'registerLogData: iteration ' + iteration);
            
            try {
                List<QueueableLog__c>  currentLogs =
                    [	SELECT	Name, ExternalID__c, Period__c, ProcessName__c,
                                 CPUTime__c, WaitTime__c, CalloutNbr__c,
                                JobEmptyNbr__c, JobFailNbr__c, JobNbr__c, 
                                RcdFailNbr__c, RcdNbr__c,
                                 Message__c, LastContext__c
                        FROM QueueableLog__c  WHERE Name = :newLog.Name	LIMIT 1 FOR UPDATE];
                System.debug('registerLogData: current Log retrieved ' + currentLogs);
            
                if (currentLogs.size() == 0) {
                    System.debug('registerLogData: inserting new Log');
                    insert newLog;
                }
                else {
                    System.debug('registerLogData: existing Log to update');
                    mergeLogData(currentLogs[0],newLog);
                    System.debug('registerLogData: existing Log updated');
                    update currentLogs[0];
                }
                System.debug('registerLogData: END - queueableLog upserted');
            }
            catch (Exception e) {
                if (iteration < MAX_RETRIES) {
                    System.debug(LoggingLevel.INFO,'logExecution: END KO - retrying because '  + e.getMessage());
                    registerLogData(newLog, iteration + 1);
                } 
                else {
                    System.debug('registerLogData: END KO - Permanent failure '  + e.getMessage());
                    throw new DmlException(e.getMessage());
                }
            }
        }
        
    /***
    * @description	Utility method to merge a QueueableLog__c record data with
    *				the results of a Queuable process execution.
    *				It increment/updates the following fields on the current record
    *				with values from the new record: CPUTime, WaitTime, CalloutNbr,
    *				JobNbr, JobEmptyNbr, JobFailNbr, Message, LastContext.
    *				Message may be truncated if resulting value is too long.
    * @param		currentlog	Current log record to be updated (updated by the method)
    * @param		newlog		New log record with data corresponding to the new execution
    *							(usually coming from the getLogData() method)
    * @exception	None special
    ***/    
        private static void mergeLogData(QueueableLog__c currentlog, final QueueableLog__c newlog) {
            System.debug(LoggingLevel.FINE,'mergeLogData: START' + newlog.Name);
            
            currentlog.CPUTime__c 		+= newlog.CPUTime__c;
            currentlog.CalloutNbr__c	+= newlog.CalloutNbr__c;           
            currentlog.JobEmptyNbr__c	+= newlog.JobEmptyNbr__c;
            currentlog.JobFailNbr__c	+= newlog.JobFailNbr__c;
            currentlog.JobNbr__c		+= newlog.JobNbr__c;        
            currentlog.RcdNbr__c		+= newlog.RcdNbr__c;
            currentlog.RcdFailNbr__c	+= newlog.RcdFailNbr__c;
            if (!String.isEmpty(newlog.Message__c)) {
                currentlog.Message__c	= (String.isEmpty(currentlog.Message__c) ? '' : currentlog.Message__c + '<br/>')
                                        + newlog.Message__c;
                if (currentlog.Message__c.length() > 125000)
                    currentlog.Message__c = currentlog.Message__c.left(125000);
            }
            if (!String.isEmpty(newlog.LastContext__c)) currentlog.LastContext__c = newlog.LastContext__c;
            currentlog.WaitTime__c		+= newlog.WaitTime__c;
            
            System.debug(LoggingLevel.FINE,'mergeLogData: END with ' + currentlog.Name);
        }
        
    /***
    * @description	Utility method to init a QueueableLog__c record data with
    *				the results of a Queuable process execution.
    *				It sets the following fields: CPUTime, WaitTime, CalloutNbr,
    *				JobNbr, JobEmptyNbr, JobFailNbr, Message, LastContext.
    *				Message may be truncated if resulting value is too long.
    *				This method is usually called by the standard logExecution()
    *				method but can be also called directly by the Queueable 
    *				execute method to get log data to be actually registered
    *				at a later execution via the logPriorExecution() method
    *				(typically because of 'MixedDML' issues).
    * @param		qClassName	Name of the Queuable Apex class executed.
    * @param		rcdNbr		Number of records processed in the Queueable execution (OK + failed)
    * @param		failedRcdNbr	Number of records with failure in the Queueable execution
    * @param		message		Message to be appended (error logs, iteration stops...)
    * @param		context		Context at the end of the Queueable execution (context not updated
    *							if empty).
    * @param		waitTime	Wait Time (in milliseconds) of the Queueable execution.
    * @exception	None special
    ***/    
        public static QueueableLog__c getLogData(final String qClassName, final Integer rcdNbr, final Integer failedRcdNbr, final String message, final String context, final Integer waitTime) {
            System.debug(LoggingLevel.FINE,'getLogData: START for ' + qClassName);
            
            // LogName init
            DateTime currentTS = System.now();
            System.debug(LoggingLevel.FINE,'getLogData: current time fetched for ' + currentTS);
            Integer minuteSlot = ((Integer)(currentTS.minute() / LOG_WINDOW)) * LOG_WINDOW;
            System.debug(LoggingLevel.FINEST,'getLogData: minuteSlot generated for ' + minuteSlot);
            DateTime logTS = DateTime.newInstance(currentTS.year(),currentTS.month(),currentTS.day(),
                                                  currentTS.hour(),minuteSlot, 0);
            System.debug(LoggingLevel.FINEST,'getLogData: logTS init as ' + logTS);
            String logName = qClassName + '-' + logTS.format('yyyy-MM-dd-HH-mm');
            System.debug(LoggingLevel.FINE,'getLogData: logName init as ' + logName);
            
            // LogName init        
            QueueableLog__c newLog = new QueueableLog__c(
                    Name = logName,
                    ExternalID__c = logName,
                    Period__c = logTS,
                    ProcessName__c = qClassName);
            System.debug(LoggingLevel.FINEST,'getLogData: newLog init ' + newLog);
                
            newLog.CPUTime__c 		= Limits.getCpuTime();
            newLog.CalloutNbr__c	= Limits.getCallouts();  
            newLog.WaitTime__c 		= waitTime;
    
            newLog.JobEmptyNbr__c	= (rcdNbr == 0 ? 1 : 0);
            newLog.JobFailNbr__c	= (failedRcdNbr > 0 ? 1 : 0);
            newLog.JobNbr__c		= 1;        
            
            newLog.RcdNbr__c		= rcdNbr;
            newLog.RcdFailNbr__c	= failedRcdNbr;
            System.debug(LoggingLevel.FINEST,'getLogData: newLog stats update ' + newLog);
            
            if (!String.isEmpty(message)) {
                newLog.Message__c = currentTS.format('HH:mm') + ' - ' + message;
                if (newLog.Message__c.length() > 125000)
                    newLog.Message__c = newLog.Message__c.left(125000);
            }
            System.debug(LoggingLevel.FINEST,'getLogData: newLog msg update ' + newLog);        
            if (!String.isEmpty(context)) newLog.LastContext__c = context;
    
            System.debug(LoggingLevel.FINE,'initLogData: END with ' + newLog);
            return newLog;
        }
    
    }