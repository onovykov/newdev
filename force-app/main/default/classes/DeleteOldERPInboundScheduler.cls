global class DeleteOldERPInboundScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        String q = 'SELECT Id FROM ERP_InboundPart__c';
        Database.executeBatch(new DeleteRecordsBatch(q), 200);
    }
}