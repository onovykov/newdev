public without sharing class ExternalIdCache {

    // ========================
    // STATE
    // ========================
    private final Schema.SObjectType sobjectType;
    private final String externalIdField;
    private final CacheSettingsProvider.CacheSettings cfg;

    private ExternalIdCache(
        Schema.SObjectType sobjectType,
        String externalIdField,
        CacheSettingsProvider.CacheSettings cfg
    ) {
        this.sobjectType     = sobjectType;
        this.externalIdField = externalIdField;
        this.cfg             = cfg;
    }

    // ========================
    // FACTORY
    // ========================
    public static ExternalIdCache forObject(
        String sobjectApiName,
        String externalIdField,
        String settingsDeveloperName
    ) {
        return new ExternalIdCache(
            Schema.getGlobalDescribe().get(sobjectApiName),
            externalIdField,
            CacheSettingsProvider.load(settingsDeveloperName)
        );
    }

    // ========================
    // PUBLIC API
    // ========================

    public Id getOne(String externalId) {
        if (String.isBlank(externalId)) {
            return null;
        }

        Map<String, Id> mapMany =
            getMany(new Set<String>{ externalId }, true);

        return mapMany.get(externalId);
    }

    public Map<String, Id> getMany(
        Set<String> externalIds,
        Boolean allowNegativeCache
    ) {
        Map<String, Id> result = new Map<String, Id>();
        if (externalIds == null || externalIds.isEmpty()) {
            return result;
        }

        Cache.OrgPartition partition = tryGetPartition();

        // 1️. Split by shard
        Map<String, Set<String>> shardToKeys = splitByShard(externalIds);
        Set<String> toLoadFromDb = new Set<String>();

        // 2️. Read cache
        if (partition != null) {
            for (String shard : shardToKeys.keySet()) {
                String cacheKey = buildKey(shard);
                Map<String, Id> cached =
                    (Map<String, Id>) partition.get(cacheKey);

                if (cached == null) {
                    toLoadFromDb.addAll(shardToKeys.get(shard));
                    continue;
                }

                for (String extId : shardToKeys.get(shard)) {
                    if (cached.containsKey(extId)) {
                        result.put(extId, cached.get(extId)); // may be null
                    } else {
                        toLoadFromDb.add(extId);
                    }
                }
            }
        } else {
            toLoadFromDb.addAll(externalIds);
        }

        // 3️. DB fallback
        if (!toLoadFromDb.isEmpty()) {
            Map<String, Id> loaded =
                loadFromDb(toLoadFromDb, allowNegativeCache);
            result.putAll(loaded);
        }

        return result;
    }

    public void invalidate(String externalId) {
        if (String.isBlank(externalId)) return;

        Cache.OrgPartition partition = tryGetPartition();
        if (partition == null) return;

        partition.remove(buildKey(getShard(externalId)));
    }

    // ========================
    // INTERNAL — DB LOAD
    // ========================
    private Map<String, Id> loadFromDb(
        Set<String> externalIds,
        Boolean allowNegativeCache
    ) {
        Map<String, Id> result = new Map<String, Id>();
        if (externalIds.isEmpty()) return result;

        Map<String, Set<String>> shardToKeys = splitByShard(externalIds);
        Map<String, Map<String, Id>> shardMaps = new Map<String, Map<String, Id>>();

        for (String shard : shardToKeys.keySet()) {
            shardMaps.put(shard, new Map<String, Id>());
        }

        // ===== dynamic SOQL =====
        String soql =
            'SELECT Id, ' + externalIdField +
            ' FROM ' + sobjectType.getDescribe().getName() +
            ' WHERE ' + externalIdField + ' IN :externalIds';

        for (SObject sob : Database.query(soql)) {
            String extId = (String) sob.get(externalIdField);
            Id recordId  = (Id) sob.get('Id');

            String shard = getShard(extId);

            shardMaps.get(shard).put(extId, recordId);
            result.put(extId, recordId);
        }

        // ===== negative cache =====
        if (allowNegativeCache) {
            for (String extId : externalIds) {
                if (!result.containsKey(extId)) {
                    String shard = getShard(extId);
                    shardMaps.get(shard).put(extId, null);
                    result.put(extId, null);
                }
            }
        }

        // ===== put to cache =====
        Cache.OrgPartition partition = tryGetPartition();
        if (partition != null) {
            for (String shard : shardMaps.keySet()) {
                Map<String, Id> data = shardMaps.get(shard);
                if (data.isEmpty()) continue;

                Integer ttl =
                    containsAnyNull(data)
                        ? cfg.ttlNegative
                        : cfg.ttlSuccess;

                partition.put(buildKey(shard), data, ttl);
            }
        }

        return result;
    }

    // ========================
    // INTERNAL — HELPERS
    // ========================
    private Cache.OrgPartition tryGetPartition() {
        try {
            return Cache.Org.getPartition(cfg.cacheName);
        } catch (Exception e) {
            return null; // cache must NEVER break logic
        }
    }

    private Map<String, Set<String>> splitByShard(Set<String> keys) {
        Map<String, Set<String>> mapShard = new Map<String, Set<String>>();
        for (String key : keys) {
            String shard = getShard(key);
            if (!mapShard.containsKey(shard)) {
                mapShard.put(shard, new Set<String>());
            }
            mapShard.get(shard).add(key);
        }
        return mapShard;
    }

    private String getShard(String key) {
        return key.length() <= cfg.shardLen
            ? key
            : key.substring(0, cfg.shardLen);
    }

    private String buildKey(String shard) {
        String safeShard = normalizeKey(shard);
        String safePrefix = normalizeKey(cfg.keyPrefix);

        return safePrefix + safeShard;
    }

    private Boolean containsAnyNull(Map<String, Id> mapIds) {
        for (Id v : mapIds.values()) {
            if (v == null) return true;
        }
        return false;
    }

    //===== HELPER =====
    private static String normalizeKey(String raw) {
        if (String.isBlank(raw)) {
            return 'EMPTY';
        }

        // залишаємо тільки A-Z a-z 0-9
        return raw.replaceAll('[^A-Za-z0-9]', '');
    }    
}
/*
    Як це використовувати - на прикладі OrderItem
    ExternalIdCache cache =
        ExternalIdCache.forObject(
            'OrderItem',
            'ITENumber__c',
            'local_OrderItemCache'
        );

    Id oiId = cache.getOne('25-008871-001');

    Map<String, Id> ids =
        cache.getMany(
            new Set<String>{ '25-008871-001', '25-008871-002' },
            true
        );
*/