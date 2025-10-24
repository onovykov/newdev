global class OrderItemProdPlanBatch implements Database.Batchable<sObject>, Database.Stateful {

    private Map<String, Id> weekMap = new Map<String, Id>(); // "Week-Month-Year" -> ProdWeekId

    global Database.QueryLocator start(Database.BatchableContext BC) {
    
        for (ProdWeeksH__c week : [SELECT Id, WeekNum__c, Month__c, Year__c FROM ProdWeeksH__c]) {
            String key = week.WeekNum__c + '-' + week.Month__c + '-' + week.Year__c;
            weekMap.put(key, week.Id);
        }

        return Database.getQueryLocator(
            'SELECT Id, ITENumber__c, WeekNum__c, Month__c, Year__c FROM OrderItemProdPlan__c' +
            ' WHERE Order__c = NULL OR OrderItem__c = NULL OR ProdWeek__c = NULL'
        );
    }
    
    global void execute(Database.BatchableContext BC, List<OrderItemProdPlan__c> prodPlans) {
        List<OrderItemProdPlan__c> updates = new List<OrderItemProdPlan__c>();
        Map<String, OrderItem> itemMap = new Map<String, OrderItem>();
        Set<String> itemNumbers = new Set<String>();

        for(OrderItemProdPlan__c plan : prodPlans) {
            if (plan.ITENumber__c != null) {
                itemNumbers.add(plan.ITENumber__c);
            }
        }

        for (OrderItem oi : [SELECT Id, ITENumber__c, OrderId, Shop__c FROM OrderItem WHERE ITENumber__c IN :itemNumbers]) {
            itemMap.put(oi.ITENumber__c, oi);
        }
        
        for (OrderItemProdPlan__c plan : prodPlans) {
            // 1. Знаходимо OrderItem і Order
            if (itemMap.containsKey(plan.ITENumber__c)) {
                OrderItem item = itemMap.get(plan.ITENumber__c);
                plan.OrderItem__c = item.Id;
                plan.Order__c = item.OrderId;
                plan.Shop__c = item.Shop__c;
            }
            
            // 2. Знаходимо ProdWeek
            String key = plan.WeekNum__c + '-' + plan.Month__c + '-' + plan.Year__c;
            if (weekMap.containsKey(key)) {
                plan.ProdWeek__c = weekMap.get(key);
            }
            
            updates.add(plan);
        }

        if (!updates.isEmpty()) {
            update updates;
        }
    }

    global void finish(Database.BatchableContext BC) {
        System.debug('Batch process completed.');
    }
}