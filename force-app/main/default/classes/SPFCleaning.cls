global class SPFCleaning implements Database.Batchable<SObject> {
	
	private final String recType;
	private final Date periodStart;
	private final Date periodEnd;
	private final String messageTimeStamp;
	private final ERPRequestParser.MonthPlanFactMessage parsedMessage;


	global SPFCleaning(String rType, Date pStart, Date pEnd, String msgTS, String requestBody) {
		recType = rType;
		periodStart = pStart;
		periodEnd = pEnd;
		messageTimeStamp = msgTS;
		parsedMessage = (ERPRequestParser.MonthPlanFactMessage) JSON.deserialize(requestBody, ERPRequestParser.MonthPlanFactMessage.class);
		// system.debug('---------ParsedMessage.PackageNumber---------  ' + parsedMessage.PackageNumber);

	}
	global SPFCleaning(String rType, Date pStart, Date pEnd, String msgTS) {
		recType = rType;
		periodStart = pStart;
		periodEnd = pEnd;
		messageTimeStamp = msgTS;
	}

	global Database.QueryLocator start(Database.BatchableContext context) {
		System.debug('START -------------------------------------->');
		return Database.getQueryLocator(
			'SELECT Id, Name ' + 
			'FROM SalesPlanFact__c ' +
			'WHERE RecordType.Name = :recType ' +
			'AND Period__c >= :periodStart AND Period__c <= :periodEnd '
			);
	}

   	global void execute(Database.BatchableContext context, List<SalesPlanFact__c> scope) {
		System.debug('EXECUTE -------------------------------------->');

		system.debug('---------ParsedMessage.PackageNumber---------  ' + parsedMessage.PackageNumber);
		

		if (parsedMessage.PackageNumber == '1') {
            String emailBody = '\nScope size to delete: ' + scope.size();
           
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            String[] toAddresses = new String[] { 'v.rybak@polytech.software' };
            email.setToAddresses(toAddresses);
            email.setSubject('SPF Cleaning Batch');
            email.setPlainTextBody(emailBody);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });

            Database.delete(scope, false);
        }
	}
	
	global void finish(Database.BatchableContext context) {
		System.debug('FINISH -------------------------------------->');
//// system.debug('---------ParsedMessage.PackageNumber---------  ' + parsedMessage.PackageNumber);

ErpMessageHandlerMonthPlanFact.MessageProcessingResult res = ErpMessageHandlerMonthPlanFact.ProcessMessage(ParsedMessage, null);
	}
}