public class UpdateOrderItemsBatch implements Database.Batchable<sObject> {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([SELECT id FROM OrderItem]);
    }

    public void execute(Database.BatchableContext bc, List<OrderItem> scope) {
        update scope;
    }

    public void finish(Database.BatchableContext bc){

    }
}