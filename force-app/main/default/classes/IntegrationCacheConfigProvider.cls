public with sharing class IntegrationCacheConfigProvider {

    // key = ObjectApiName.CachePurpose
    private static Map<String, Integration_Cache_Config__mdt> cache;

    /* ============================================================
     * Lazy load CMDT into static cache
     * ============================================================ */
    private static void loadIfNeeded() {
        if (cache != null) {
            return;
        }

        cache = new Map<String, Integration_Cache_Config__mdt>();

        for (Integration_Cache_Config__mdt cfg :
            Integration_Cache_Config__mdt.getAll().values()
        ) {
            if (String.isBlank(cfg.ObjectApiName__c) ||
                String.isBlank(cfg.CachePurpose__c)) {
                continue;
            }

            String key =
                cfg.ObjectApiName__c + '.' + cfg.CachePurpose__c;

            cache.put(key, cfg);
        }
    }

    /* ============================================================
     * Public API
     * ============================================================ */
    public static Integer getTTL(
        String objectApiName,
        String cachePurpose,
        Integer fallbackSeconds
    ) {
        loadIfNeeded();

        String key = objectApiName + '.' + cachePurpose;
        Integration_Cache_Config__mdt cfg = cache.get(key);

        // no config → fallback
        if (cfg == null) {
            return fallbackSeconds;
        }

        // explicitly disabled
        if (!cfg.IsEnabled__c) {
            return 0; // means "do not cache"
        }

        // TTL not defined → fallback
        if (cfg.TTLSeconds__c == null) {
            return fallbackSeconds;
        }

        return Integer.valueOf(cfg.TTLSeconds__c);
    }
}