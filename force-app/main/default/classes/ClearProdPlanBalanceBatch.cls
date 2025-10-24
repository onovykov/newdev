public class ClearProdPlanBalanceBatch implements Database.Batchable<sObject> {

    public Set<String> itemNumbers { get; set; }
    public List<ERPMessageParser.OrderItemsData> orderItemsData { get; set; }
    public ERPMessageParser.PeriodInfo orderItemsPeriodInfo {get; set;}



    public Database.QueryLocator start(Database.BatchableContext context) {
        // Create a query to select all OrderItem records
        String query = 'SELECT Id, BalanceForProduction__c, MonthlyProdPlan__c, WeeklyProdPlan__c, YearMonth__c, WeekNumber__c, WeekStartDate__c, WeekEndDate__c FROM OrderItem ';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext context, List<OrderItem> scope) {
        // Loop through the selected OrderItem records and clear the field values
        for (OrderItem orderItem : scope) {
            orderItem.BalanceForProduction__c = null;
            orderItem.MonthlyProdPlan__c = null;
            orderItem.WeeklyProdPlan__c = null;
            orderItem.YearMonth__c = null;
            orderItem.WeekNumber__c = null;
            orderItem.WeekStartDate__c = null;
            orderItem.WeekEndDate__c = null;
        }

        // Update the OrderItem records with cleared values
        update scope;
    }

    public void finish(Database.BatchableContext context) {
        ProdPlanBalanceBatch updateBatch = new ProdPlanBalanceBatch();
        updateBatch.itemNumbers = itemNumbers;
        updateBatch.orderItemsData = orderItemsData;
        updateBatch.orderItemsPeriodInfo = orderItemsPeriodInfo;
        Database.executeBatch(updateBatch);
    }
}