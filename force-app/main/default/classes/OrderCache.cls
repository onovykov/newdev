public class OrderCache {

    private static final ExternalIdCache CACHE_ERP =
        ExternalIdCache.forObject(
            'Order',
            'ID_ERP__c',
            'local_OrderCache_ERP'
        );

    private static final ExternalIdCache CACHE_ITE =
        ExternalIdCache.forObject(
            'Order',
            'ITENumber__c',
            'local_OrderCache_ITE'
        );

    public static Id getOneByErpId(String erpId) {
        if (String.isBlank(erpId)) return null;

        if (Test.isRunningTest()) {
            List<Order> ords = [
                SELECT Id
                FROM Order
                WHERE ID_ERP__c = :erpId
                LIMIT 1
            ];
            return ords.isEmpty() ? null : ords[0].Id;
        }

        return CACHE_ERP.getOne(erpId);
    }

    public static Id getOneByIte(String ite) {
        if (String.isBlank(ite)) return null;

        if (Test.isRunningTest()) {
            List<Order> ords = [
                SELECT Id
                FROM Order
                WHERE ITENumber__c = :ite
                LIMIT 1
            ];
            return ords.isEmpty() ? null : ords[0].Id;
        }

        return CACHE_ITE.getOne(ite);
    }

    public static Map<String, Id> getManyByErpId(Set<String> erpIds) {
        Map<String, Id> result = new Map<String, Id>();
        if (erpIds == null || erpIds.isEmpty()) return result;

        if (Test.isRunningTest()) {
            for (Order o : [
                SELECT Id, ID_ERP__c
                FROM Order
                WHERE ID_ERP__c IN :erpIds
            ]) {
                result.put(o.ID_ERP__c, o.Id);
            }
            return result;
        }

        return CACHE_ERP.getMany(erpIds, true);
    }

    public static Map<String, Id> getManyByIte(Set<String> iteSet) {
        Map<String, Id> result = new Map<String, Id>();
        if (iteSet == null || iteSet.isEmpty()) return result;

        if (Test.isRunningTest()) {
            for (Order o : [
                SELECT Id, ITENumber__c
                FROM Order
                WHERE ITENumber__c IN :iteSet
            ]) {
                result.put(o.ITENumber__c, o.Id);
            }
            return result;
        }

        return CACHE_ITE.getMany(iteSet, true);
    }
}