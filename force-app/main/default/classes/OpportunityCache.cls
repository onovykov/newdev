public class OpportunityCache {

    private static final ExternalIdCache CACHE_ERP =
        ExternalIdCache.forObject(
            'Opportunity',
            'ID_ERP__c',
            'local_OpportunityCache_ERP'
        );

    private static final ExternalIdCache CACHE_ITE =
        ExternalIdCache.forObject(
            'Opportunity',
            'ITENumber__c',
            'local_OpportunityCache_ITE'
        );

    // ===== SINGLE =====

    public static Id getOneByErpId(String erpId) {
        if (String.isBlank(erpId)) return null;

        if (Test.isRunningTest()) {
            List<Opportunity> opps = [
                SELECT Id
                FROM Opportunity
                WHERE ID_ERP__c = :erpId
                LIMIT 1
            ];
            return opps.isEmpty() ? null : opps[0].Id;
        }

        return CACHE_ERP.getOne(erpId);
    }

    public static Id getOneByIte(String ite) {
        if (String.isBlank(ite)) return null;

        if (Test.isRunningTest()) {
            List<Opportunity> opps = [
                SELECT Id
                FROM Opportunity
                WHERE ITENumber__c = :ite
                LIMIT 1
            ];
            return opps.isEmpty() ? null : opps[0].Id;
        }

        return CACHE_ITE.getOne(ite);
    }

    // ===== MANY =====

    public static Map<String, Id> getManyByErpId(Set<String> erpIds) {
        Map<String, Id> result = new Map<String, Id>();
        if (erpIds == null || erpIds.isEmpty()) return result;

        if (Test.isRunningTest()) {
            for (Opportunity o : [
                SELECT Id, ID_ERP__c
                FROM Opportunity
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
            for (Opportunity o : [
                SELECT Id, ITENumber__c
                FROM Opportunity
                WHERE ITENumber__c IN :iteSet
            ]) {
                result.put(o.ITENumber__c, o.Id);
            }
            return result;
        }

        return CACHE_ITE.getMany(iteSet, true);
    }
}