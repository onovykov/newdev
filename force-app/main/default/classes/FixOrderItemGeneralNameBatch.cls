public class FixOrderItemGeneralNameBatch implements Database.Batchable<sObject> {

    public Database.QueryLocator start(Database.BatchableContext BC) {
        // Query all OrderItemGeneral__c records created after 03.11.2024
        return Database.getQueryLocator([
            SELECT Id, Name, OrderProduct__c, OrderProduct__r.ITENumber__c
            FROM OrderItemGeneral__c
            WHERE CreatedDate >= 2024-11-03T00:00:00Z
            AND OrderProduct__r.ITENumber__c != null
        ]);
    }

    public void execute(Database.BatchableContext BC, List<OrderItemGeneral__c> scope) {
        List<OrderItemGeneral__c> toUpdate = new List<OrderItemGeneral__c>();

        for (OrderItemGeneral__c gen : scope) {
            String iteNumber = gen.OrderProduct__r.ITENumber__c;

            // Only update if Name is different from ITENumber
            if (iteNumber != null && gen.Name != iteNumber) {
                gen.Name = iteNumber;
                toUpdate.add(gen);
            }
        }

        if (!toUpdate.isEmpty()) {
            try {
                update toUpdate;
                System.debug('Successfully updated ' + toUpdate.size() + ' OrderItemGeneral__c records');
            } catch (Exception e) {
                System.debug('Error updating records: ' + e.getMessage());
            }
        }
    }

    public void finish(Database.BatchableContext BC) {
        System.debug('=== FixOrderItemGeneralNameBatch completed ===');

        // Optional: Send email notification
        AsyncApexJob job = [
            SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email
            FROM AsyncApexJob
            WHERE Id = :BC.getJobId()
        ];

        System.debug('Job Status: ' + job.Status);
        System.debug('Total batches processed: ' + job.TotalJobItems);
        System.debug('Records processed: ' + job.JobItemsProcessed);
        System.debug('Errors: ' + job.NumberOfErrors);
    }
}