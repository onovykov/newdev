public class OrderItemStageEventCleanupJob {
    public static void runCleanup() {
        List<OrderItemStageEvent__c> toDelete = [
            SELECT Id
            FROM OrderItemStageEvent__c
            WHERE Stage__c != 'Pending'
            LIMIT 10000
        ];

        if (!toDelete.isEmpty()) {
            delete toDelete;
        }
    }
}