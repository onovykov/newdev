public class OrderItemCache {
    private static final ExternalIdCache CACHE =
        ExternalIdCache.forObject(
            'OrderItem',
            'ITENumber__c',
            'local_OrderItemCache'
        );

    public static Id getByIte(String ite) {
        return CACHE.getOne(ite);
    }

    public static Map<String, Id> getByItes(Set<String> ites) {
        return CACHE.getMany(ites, true);
    }
}
/*
    Приклади використання:
    1) Один ітем
    Id orderItemId = OrderItemCache.getByIte('25-008871-001');

    if (orderItemId == null) {
        // OrderItem ще не існує → create / skip / error
    }

    2) Скоп ітемів
    Set<String> ites = new Set<String>{
        '25-008871-001',
        '25-008871-002',
        '25-008871-003'
    };

    Map<String, Id> orderItemIdsByIte =
        OrderItemCache.getByItes(ites);

    // usage
    for (String ite : ites) {
        Id oiId = orderItemIdsByIte.get(ite);

        if (oiId == null) {
            // missing → create
        } else {
            // exists → update
        }
    }    
*/