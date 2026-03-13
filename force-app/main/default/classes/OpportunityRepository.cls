public with sharing class OpportunityRepository {

    // =====================================================
    // Cache keys
    // =====================================================
    private static final String CACHE_PREFIX_ERP = 'OPP_ERP_';
    private static final String CACHE_PREFIX_ITE = 'OPP_ITE_';

    // TTL (seconds) – loaded from CMDT
    private static Integer CACHE_TTL_SEC;

    static {
        CACHE_TTL_SEC = getCacheTTL();
    }

    // =====================================================
    // Public API
    // =====================================================

    public static Opportunity findByErpId(String erpId) {

        if (String.isBlank(erpId)) {
            return null;
        }

        String cacheKey = CACHE_PREFIX_ERP + erpId;

        // Try cache
        Opportunity cached = getFromCache(cacheKey);
        if (cached != null) {
            return cached;
        }

        // SOQL fallback
        List<Opportunity> opps = [
            SELECT Id,
                   Name,
                   ID_ERP__c,
                   ITENumber__c,
                   BidGuarantees__c,
                   LastModifiedDate
            FROM Opportunity
            WHERE ID_ERP__c = :erpId
            LIMIT 1
        ];

        if (opps.isEmpty()) {
            return null;
        }

        Opportunity opp = opps[0];

        // Cache by ERP key
        putToCacheSafe(cacheKey, opp, CACHE_TTL_SEC);

        // Cache by ITE key (if present)
        if (!String.isBlank(opp.ITENumber__c)) {
            putToCacheSafe(
                CACHE_PREFIX_ITE + opp.ITENumber__c,
                opp,
                CACHE_TTL_SEC
            );
        }

        return opp;
    }

    public static Opportunity findByIteNumber(String iteNumber) {

        if (String.isBlank(iteNumber)) {
            return null;
        }

        String cacheKey = CACHE_PREFIX_ITE + iteNumber;

        // Try cache
        Opportunity cached = getFromCache(cacheKey);
        if (cached != null) {
            return cached;
        }

        // SOQL fallback
        List<Opportunity> opps = [
            SELECT Id,
                   Name,
                   ID_ERP__c,
                   ITENumber__c,
                   BidGuarantees__c,
                   LastModifiedDate
            FROM Opportunity
            WHERE ITENumber__c = :iteNumber
            LIMIT 1
        ];

        if (opps.isEmpty()) {
            return null;
        }

        Opportunity opp = opps[0];

        // Cache by ITE key
        putToCacheSafe(cacheKey, opp, CACHE_TTL_SEC);

        // Cache by ERP key (if present)
        if (!String.isBlank(opp.ID_ERP__c)) {
            putToCacheSafe(
                CACHE_PREFIX_ERP + opp.ID_ERP__c,
                opp,
                CACHE_TTL_SEC
            );
        }

        return opp;
    }

    // =====================================================
    // Cache helpers (SAFE)
    // =====================================================

    private static Opportunity getFromCache(String cacheKey) {
        if (CACHE_TTL_SEC == null || CACHE_TTL_SEC <= 0) {
            return null; // cache disabled
        }

        try {
            return (Opportunity) Cache.Org.get(cacheKey);
        } catch (Exception e) {
            // No partition / cache disabled → ignore
            return null;
        }
    }

    private static void putToCacheSafe(
        String cacheKey,
        Opportunity opp,
        Integer ttlSeconds
    ) {
        if (opp == null || ttlSeconds == null || ttlSeconds <= 0) {
            return;
        }

        try {
            Cache.Org.put(cacheKey, opp, ttlSeconds);
        } catch (Exception e) {
            // No partition / cache disabled → ignore
        }
    }

    // =====================================================
    // Cache TTL from CMDT
    // =====================================================

    private static Integer getCacheTTL() {
        return IntegrationCacheConfigProvider.getTTL(
            'Opportunity',
            'ERP_LOOKUP',
            300 // fallback
        );
    }
}