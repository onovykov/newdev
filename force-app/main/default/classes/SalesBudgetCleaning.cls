global class SalesBudgetCleaning implements Database.Batchable<SObject> {

    private final String budgetId;
    private final Long messageTimeStamp;
    private Integer recordsDeleted = 0;

    global SalesBudgetCleaning(String budId, Long msgTS) {
        budgetId = budId;
        messageTimeStamp = msgTS;
    }

    global Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator('SELECT Id FROM SalesBudgetRecord__c WHERE SalesBudget__r.ID_ERP__c  = :budgetId AND ExchangeTimestamp__c < :messageTimestamp');
    }

    global void execute(Database.BatchableContext context, List<SObject> scope) {
        Database.delete(scope, false);
        recordsDeleted += scope.size();
    }

    global void finish(Database.BatchableContext context) {
        // Send an email with execution information
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new List<String>{'v.rybak@polytech.software'});
        email.setSubject('SalesBudgetCleaning Batch Job Completed');
        email.setPlainTextBody('The SalesBudgetCleaning batch job has completed. ' + recordsDeleted + ' records were deleted.');
        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{email});
    }

}