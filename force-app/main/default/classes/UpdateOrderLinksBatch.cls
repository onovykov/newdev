global class UpdateOrderLinksBatch implements Database.Batchable<SObject>, Database.Stateful {

    global Database.QueryLocator start(Database.BatchableContext BC) {
        System.debug('--- STARTING BATCH ---');
        return Database.getQueryLocator([
                // Order__c та OrderProduct__c ми додали в SalesPlanFact__c, але вони ще всі пусті
                SELECT Id, ITENumber__c, Order__c, OrderProduct__c
                FROM SalesPlanFact__c
                WHERE (Order__c = NULL OR OrderProduct__c = NULL)
                    AND ITENumber__c != NULL
        ]);
    }

    global void execute(Database.BatchableContext BC, List<SalesPlanFact__c> scope) {
        Map<String, Id> orderMap = new Map<String, Id>();
        Map<String, Id> orderItemMap = new Map<String, Id>();

        Set<String> orderKeys = new Set<String>();
        Set<String> orderItemKeys = new Set<String>();

        System.debug('--- Scope Start ---');
        for (SalesPlanFact__c rec : scope) {
            System.debug('Record: ' + rec.Id + ' | ITENumber__c: ' + rec.ITENumber__c);
            if (rec.ITENumber__c != null && rec.ITENumber__c.length() >= 9) {
                String orderKey = rec.ITENumber__c.substring(0, 9);
                orderKeys.add(orderKey);
                orderItemKeys.add(rec.ITENumber__c);
            } else {
                System.debug('Skipped record (missing or short ITENumber__c): ' + rec.Id);
            }
        }

        System.debug('Order keys to match: ' + orderKeys);
        System.debug('OrderItem keys to match: ' + orderItemKeys);

        for (Order ord : [SELECT Id, ITENumber__c FROM Order WHERE ITENumber__c IN :orderKeys]) {
            orderMap.put(ord.ITENumber__c, ord.Id);
        }
        System.debug('Matched Orders: ' + orderMap);

        for (OrderItem item : [SELECT Id, ITENumber__c FROM OrderItem WHERE ITENumber__c IN :orderItemKeys]) {
            orderItemMap.put(item.ITENumber__c, item.Id);
        }
        System.debug('Matched OrderItems: ' + orderItemMap);

        List<SalesPlanFact__c> toUpdate = new List<SalesPlanFact__c>();

        for (SalesPlanFact__c rec : scope) {
            Boolean changed = false;
            String orderKey = (rec.ITENumber__c != null && rec.ITENumber__c.length() >= 9) ? rec.ITENumber__c.substring(0, 9) : null;

            System.debug('Processing record: ' + rec.Id);
            System.debug('Order__c current: ' + rec.Order__c);
            System.debug('OrderProduct__c current: ' + rec.OrderProduct__c);

            if (orderKey != null) {
                if (orderMap.containsKey(orderKey)) {
                    if (rec.Order__c == null) {
                        rec.Order__c = orderMap.get(orderKey);
                        changed = true;
                        System.debug('Assigned Order__c: ' + rec.Order__c);
                    } else {
                        System.debug('Order__c already set: ' + rec.Order__c);
                    }
                } else {
                    System.debug('No match in orderMap for key: ' + orderKey);
                }

                if (orderItemMap.containsKey(rec.ITENumber__c)) {
                    if (rec.OrderProduct__c == null) {
                        rec.OrderProduct__c = orderItemMap.get(rec.ITENumber__c);
                        changed = true;
                        System.debug('Assigned OrderProduct__c: ' + rec.OrderProduct__c);
                    } else {
                        System.debug('OrderProduct__c already set: ' + rec.OrderProduct__c);
                    }
                } else {
                    System.debug('No match in orderItemMap for full ITENumber__c: ' + rec.ITENumber__c);
                }
            }

            if (changed) {
                toUpdate.add(rec);
            }
        }

        System.debug('Records to update: ' + toUpdate.size());

        if (!toUpdate.isEmpty()) {
            update toUpdate;
            System.debug('Updated SalesPlanFact__c records: ' + toUpdate);
        }
    }


    global void finish(Database.BatchableContext BC) {
        System.debug('Batch UpdateOrderLinksBatch completed.');
    }
}