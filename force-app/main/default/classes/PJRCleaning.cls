global class PJRCleaning implements Database.Batchable<SObject> {
	
	private final String recType;
	private final Date periodStart;
	private final Date periodEnd;
	private final String messageTimeStamp;

	global PJRCleaning(String rType, Date pStart, Date pEnd, String msgTS) {
		recType = rType;
		periodStart = pStart;
		periodEnd = pEnd;
		messageTimeStamp = msgTS;
	}
	
	/**
	 * @description gets invoked when the batch job starts
	 * @param context contains the job ID
	 * @returns the record set as a QueryLocator object that will be batched for execution
	 */ 
	global Database.QueryLocator start(Database.BatchableContext context) {
		return Database.getQueryLocator(
			'SELECT Id, Name ' + 
			'FROM ProductionJournalRecord__c ' +
			'WHERE Type__c = :recType ' +
			'AND Period__c >= :periodStart AND Period__c <= :periodEnd ' +
			'AND ExchangeTimeStamp__c != :messageTimeStamp');
	}

	/**
	 * @description gets invoked when the batch job executes and operates on one batch of records. Contains or calls the main execution logic for the batch job.
	 * @param context contains the job ID
	 * @param scope contains the batch of records to process.
	 */ 
   	global void execute(Database.BatchableContext context, List<ProductionJournalRecord__c> scope) {
		delete scope;
	}
	
	/**
	 * @description gets invoked when the batch job finishes. Place any clean up code in this method.
	 * @param context contains the job ID
	 */ 
	global void finish(Database.BatchableContext context) {
		
	}
}