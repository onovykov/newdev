public with sharing class OrderItemLookupImpl implements OrderItemLookup {

    public Id findByIte(String ite) {
        return OrderItemCache.getByIte(ite);
    }

    public Map<String, Id> findByItes(Set<String> ites) {
        return OrderItemCache.getByItes(ites);
    }
/*
    public OrderItem findEntityByIte(String ite) {
        return OrderItemPlatformCache.getOne(ite);
    }
*/
    public OrderItem findEntityByIte(String ite) {

        OrderItem oi = OrderItemPlatformCache.getOne(ite);

        if (oi != null) {
            return oi;
        }

        // fallback в DB
        List<OrderItem> items = [
            SELECT Id, ITENumber__c
            FROM OrderItem
            WHERE ITENumber__c = :ite
            LIMIT 1
        ];

        if (!items.isEmpty()) {
            return items[0];
        }

        return null;
    }

/*    
    public Map<String, OrderItem> findEntitiesByItes(Set<String> ites) {
        return OrderItemPlatformCache.getMany(ites);
    }
*/

    public Map<String, OrderItem> findEntitiesByItes(Set<String> ites) {

        Map<String, OrderItem> result = OrderItemPlatformCache.getMany(ites);

        Set<String> missing = new Set<String>();

        for (String ite : ites) {
            if (!result.containsKey(ite) || result.get(ite) == null) {
                missing.add(ite);
            }
        }

        if (!missing.isEmpty()) {
            for (OrderItem oi : [
                SELECT Id, ITENumber__c
                FROM OrderItem
                WHERE ITENumber__c IN :missing
            ]) {
                result.put(oi.ITENumber__c, oi);
            }
        }

        return result;
    }
}