public with sharing class OrderItemPlatformCache {
    // ===== Налаштування кешу =====
    private static final String  PARTITION   = 'local.OrderItemCache';
    private static final String  VERSION     = 'V1';
    private static final Integer TTL_SECS    = 6 * 3600;  // 6 годин
    private static final Integer SHARD_COUNT = 20;
    private static final Integer IN_CHUNK    = 500;

    // Мінімально потрібні поля (додайте свої — при зміні підніміть VERSION)
    private static final List<String> FIELDS = new List<String>{
        'Id','ITENumber__c','OrderId','Product2Id','Quantity','UnitPrice'
    };

    // ===== Публічний API =====

    /** Масово отримати OrderItem за ITENumber__c (із кешем і дозавантаженням). */
    public static Map<String, OrderItem> getMany(Set<String> iteNumbers) {
        Map<String, OrderItem> out = new Map<String, OrderItem>();
        if (iteNumbers == null || iteNumbers.isEmpty()) return out;

        // 1) Читаємо з кешу; збираємо відсутні по шардах
        Map<Integer, Set<String>> missingByShard = new Map<Integer, Set<String>>();
        for (String ite : iteNumbers) {
            Integer shard = shardOf(ite);
            Map<String, OrderItem> shardMap = getShardFromCache(shard);
            if (shardMap != null && shardMap.containsKey(ite)) {
                out.put(ite, shardMap.get(ite)); // може бути null (негативний кеш)
            } else {
                if (!missingByShard.containsKey(shard)) {
                    missingByShard.put(shard, new Set<String>());
                }
                missingByShard.get(shard).add(ite);
            }
        }

        // 2) Доладовуємо відсутні з БД, оновлюємо кеш
        if (!missingByShard.isEmpty()) {
            for (Integer shard : missingByShard.keySet()) {
                Set<String> toLoad = missingByShard.get(shard);
                if (toLoad == null || toLoad.isEmpty()) continue;

                Map<String, OrderItem> shardMap = getShardFromCache(shard);
                if (shardMap == null) shardMap = new Map<String, OrderItem>();

                // чанкуємо WHERE IN
                List<String> bucket = new List<String>();
                for (String key : toLoad) {
                    bucket.add(key);
                    if (bucket.size() == IN_CHUNK) {
                        queryAndMerge(bucket, shardMap, out);
                        bucket.clear();
                    }
                }
                if (!bucket.isEmpty()) {
                    queryAndMerge(bucket, shardMap, out);
                }

                // негативний кеш для ненайдених
                for (String k : toLoad) {
                    if (!shardMap.containsKey(k)) shardMap.put(k, null);
                    if (!out.containsKey(k)) out.put(k, null);
                }

                putShardToCache(shard, shardMap);
            }
        }

        return out;
    }

    /** Отримати один елемент. */
    public static OrderItem getOne(String iteNumber) {
        if (String.isBlank(iteNumber)) return null;
        Map<String, OrderItem> m = getMany(new Set<String>{ iteNumber });
        return m.get(iteNumber);
    }

    /** Інвалідувати всі шарди. */
    public static void invalidateAll() {
        Cache.OrgPartition p = part();
        for (Integer shard = 0; shard < SHARD_COUNT; shard++) {
            p.remove(cacheKey(shard));
        }
    }

    /** Інвалідувати конкретні ключі ITENumber__c. */
    public static void invalidateByIte(Set<String> iteNumbers) {
        if (iteNumbers == null || iteNumbers.isEmpty()) return;

        // групуємо по шардах
        Map<Integer, Set<String>> byShard = new Map<Integer, Set<String>>();
        for (String k : iteNumbers) {
            Integer shard = shardOf(k);
            if (!byShard.containsKey(shard)) byShard.put(shard, new Set<String>());
            byShard.get(shard).add(k);
        }

        // видаляємо ключі з відповідних шард-мап і кладемо назад
        for (Integer shard : byShard.keySet()) {
            Map<String, OrderItem> shardMap = getShardFromCache(shard);
            if (shardMap == null) continue;
            for (String k : byShard.get(shard)) shardMap.remove(k);
            putShardToCache(shard, shardMap);
        }
    }

    // ===== Внутрішні утиліти =====

    private static Cache.OrgPartition part() {
        return Cache.Org.getPartition(PARTITION);
    }

    private static String cacheKey(Integer shard) {
        // Тільки літери та цифри: без розділових знаків і підкреслень
        String ver = VERSION == null ? 'V1' : VERSION.replaceAll('[^A-Za-z0-9]', '');
        // Приклад ключа: OIBYITEV1S3
        return 'OIBYITE' + ver + 'S' + String.valueOf(shard);
    }

    /**
     * Шардінг без hashCode(): беремо останні до 9 цифр з ITENumber (як правило, вони є),
     * обчислюємо mod по кількості шардів. Якщо цифр немає — 0.
     */
    private static Integer shardOf(String ite) {
        if (String.isBlank(ite)) return 0;
        String digits = ite.replaceAll('[^0-9]', '');
        if (String.isBlank(digits)) return 0;
        Integer take = Math.min(9, digits.length());
        Integer n = Integer.valueOf(digits.substring(digits.length() - take));
        if (n < 0) n = -n;
        return Math.mod(n, SHARD_COUNT);
    }

    @SuppressWarnings('unchecked')
    private static Map<String, OrderItem> getShardFromCache(Integer shard) {
        Object raw = part().get(cacheKey(shard));
        return (raw == null) ? null : (Map<String, OrderItem>) raw;
    }

    private static void putShardToCache(Integer shard, Map<String, OrderItem> data) {
        // Пам'ятайте про ~100 kB ліміт на одне значення кешу.
        part().put(cacheKey(shard), data, TTL_SECS);
    }

    private static void queryAndMerge(List<String> bucket,
                                      Map<String, OrderItem> shardMap,
                                      Map<String, OrderItem> out) {
        String soql = 'SELECT ' + String.join(FIELDS, ',') +
                      ' FROM OrderItem WHERE ITENumber__c IN :bucket';
        for (OrderItem oi : Database.query(soql)) {
            shardMap.put(oi.ITENumber__c, oi);
            out.put(oi.ITENumber__c, oi);
        }
    }
}