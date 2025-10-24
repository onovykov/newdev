public class ProdPlanBalanceBatch implements Database.Batchable<sObject> {
    public Set<String> itemNumbers { get; set; }
    public List<ERPMessageParser.OrderItemsData> orderItemsData { get; set; }
    public ERPMessageParser.PeriodInfo orderItemsPeriodInfo {get; set;}



    public Database.QueryLocator start(Database.BatchableContext context) {
        
        // Populate the set of item numbers from parsedMessage.Items
        System.debug('itemNumbers ' +itemNumbers);
        String query = 'SELECT Id, ITENumber__c, BalanceForProduction__c,MonthlyProdPlan__c, WeeklyProdPlan__c,YearMonth__c,WeekNumber__c,WeekStartDate__c,WeekEndDate__c ' +
                       'FROM OrderItem WHERE ITENumber__c IN :itemNumbers';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext context, List<OrderItem> scope) {
        System.debug('orderItemsPeriodInfo'+ orderItemsPeriodInfo);
        Map<String, OrderItem> itemNumberToOrderItemMap = new Map<String, OrderItem>();
        for (OrderItem orderItem : scope) {
            itemNumberToOrderItemMap.put(orderItem.IteNumber__c, orderItem);
        }
        // System.debug('itemNumberToOrderItemMap: ' + itemNumberToOrderItemMap);

        List<OrderItem> orderItemsToUpdate = new List<OrderItem> ();
        for (ERPMessageParser.OrderItemsData itemData : orderItemsData) {
            OrderItem orderItemToUpdate = itemNumberToOrderItemMap.get(itemData.IteNumber);
            if (orderItemToUpdate != null) {
                orderItemToUpdate.BalanceForProduction__c = itemData.BalanceForProduction;
                orderItemToUpdate.MonthlyProdPlan__c = itemData.MonthlyProdPlan;
                orderItemToUpdate.WeeklyProdPlan__c = itemData.WeeklyProdPlan;
                orderItemToUpdate.YearMonth__c = orderItemsPeriodInfo.YearMonth;
                orderItemToUpdate.WeekNumber__c = orderItemsPeriodInfo.WeekNumber;
                orderItemToUpdate.WeekStartDate__c = Date.valueOf(orderItemsPeriodInfo.WeekStartDate);
                orderItemToUpdate.WeekEndDate__c = Date.valueOf(orderItemsPeriodInfo.WeekEndDate);
                orderItemsToUpdate.add(orderItemToUpdate);
            }

        }
        System.debug('orderItemsToUpdate: ' + orderItemsToUpdate);


        update orderItemsToUpdate;
    }

    public void finish(Database.BatchableContext context) {
        // Optional: Perform any post-processing tasks
    }
}