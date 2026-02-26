public with sharing class OrderItemPlatformCache {

    // ========================
    // CONFIG
    // ========================
    private static final String PARTITION = 'local.OrderItemCache';
    private static final Integer SHARD_COUNT = 20;

    // ========================
    // PUBLIC API
    // ========================

    public static Map<String, OrderItem> getMany(Set<String> iteNumbers) {

        Map<String, OrderItem> result = new Map<String, OrderItem>();
        if (iteNumbers == null || iteNumbers.isEmpty()) {
            return result;
        }

        Map<Integer, Set<String>> shards = splitToShards(iteNumbers);

        for (Integer shard : shards.keySet()) {

            String shardKey = shardKey(shard);
            Set<String> keys = shards.get(shard);

            Map<String, OrderItem> shardData = getShardFromCacheSafe(shardKey);

            if (shardData == null) {
                shardData = queryAndBuildShard(keys);
                putShardToCacheSafe(shardKey, shardData);
            }

            for (String k : keys) {
                result.put(k, shardData.get(k)); // may be null (negative cache)
            }
        }

        return result;
    }

    public static OrderItem getOne(String iteNumber) {
        if (String.isBlank(iteNumber)) {
            return null;
        }
        Map<String, OrderItem> m = getMany(new Set<String>{ iteNumber });
        return m.get(iteNumber);
    }

    public static void invalidateByIte(Set<String> iteNumbers) {
        if (iteNumbers == null || iteNumbers.isEmpty()) {
            return;
        }
        for (Integer shard : splitToShards(iteNumbers).keySet()) {
            removeShardFromCacheSafe(shardKey(shard));
        }
    }

    public static void invalidateAll() {
        for (Integer i = 0; i < SHARD_COUNT; i++) {
            removeShardFromCacheSafe(shardKey(i));
        }
    }

    // ========================
    // CACHE SAFE ACCESS
    // ========================

    private static Map<String, OrderItem> getShardFromCacheSafe(String key) {
        try {
            Cache.OrgPartition p = Cache.Org.getPartition(PARTITION);
            Object v = p.get(key);
            if (v != null) {
                return (Map<String, OrderItem>) v;
            }
        } catch (Exception e) {
            // Cache not available (tests / disabled / no partition)
        }
        return null;
    }

    private static void putShardToCacheSafe(String key, Map<String, OrderItem> data) {
        try {
            Cache.OrgPartition p = Cache.Org.getPartition(PARTITION);
            p.put(key, data);
        } catch (Exception e) {
            // silently ignore
        }
    }

    private static void removeShardFromCacheSafe(String key) {
        try {
            Cache.OrgPartition p = Cache.Org.getPartition(PARTITION);
            p.remove(key);
        } catch (Exception e) {
            // silently ignore
        }
    }

    // ========================
    // DB FALLBACK
    // ========================

    private static Map<String, OrderItem> queryAndBuildShard(Set<String> iteNumbers) {

        Map<String, OrderItem> result = new Map<String, OrderItem>();

        for (String k : iteNumbers) {
            result.put(k, null); // negative cache default
        }

        for (OrderItem oi : [
            SELECT Id, ITENumber__c
            FROM OrderItem
            WHERE ITENumber__c IN :iteNumbers
        ]) {
            result.put(oi.ITENumber__c, oi);
        }

        return result;
    }

    // ========================
    // SHARDING
    // ========================

    private static Map<Integer, Set<String>> splitToShards(Set<String> keys) {

        Map<Integer, Set<String>> shards = new Map<Integer, Set<String>>();

        for (String k : keys) {
            Integer shard = Integer.valueOf(
                Math.mod(Math.abs(k.hashCode()), SHARD_COUNT)
            );

            if (!shards.containsKey(shard)) {
                shards.put(shard, new Set<String>());
            }
            shards.get(shard).add(k);
        }

        return shards;
    }

    private static String shardKey(Integer shard) {
        return 'OIBYITEV1S' + shard;
    }
}