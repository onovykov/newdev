public with sharing class MapUtils {

    // ========================================
    // CASE-INSENSITIVE GET (String → String)
    // ========================================
    public static String getIgnoreCase(Map<String, String> mapData, String key) {
        if (mapData == null || String.isBlank(key)) {
            return null;
        }

        for (String k : mapData.keySet()) {
            if (k != null && k.equalsIgnoreCase(key)) {
                return mapData.get(k);
            }
        }

        return null;
    }

    // ========================================
    // CASE-INSENSITIVE GET (String → Object)
    // ========================================
    public static Object getIgnoreCase(Map<String, Object> mapData, String key) {
        if (mapData == null || String.isBlank(key)) {
            return null;
        }

        for (String k : mapData.keySet()) {
            if (k != null && k.equalsIgnoreCase(key)) {
                return mapData.get(k);
            }
        }

        return null;
    }

    // ========================================
    // TYPED GET (Boolean)
    // ========================================
    public static Boolean getBoolean(Map<String, Object> mapData, String key) {
        Object val = getIgnoreCase(mapData, key);

        if (val == null) return false;

        if (val instanceof Boolean) {
            return (Boolean)val;
        }

        if (val instanceof String) {
            return ((String)val).toLowerCase() == 'true';
        }

        return false;
    }

    // ========================================
    // TYPED GET (String)
    // ========================================
    public static String getString(Map<String, Object> mapData, String key) {
        Object val = getIgnoreCase(mapData, key);

        return val == null ? null : String.valueOf(val);
    }

    // ========================================
    // SAFE PUT (no overwrite case duplicates)
    // ========================================
    public static void putSafe(Map<String, String> mapData, String key, String value) {
        if (mapData == null || String.isBlank(key)) return;

        // remove existing key ignoring case
        String existingKey = findKeyIgnoreCase(mapData.keySet(), key);
        if (existingKey != null) {
            mapData.remove(existingKey);
        }

        mapData.put(key, value);
    }

    // ========================================
    // KEY EXISTS (case-insensitive)
    // ========================================
    public static Boolean containsKeyIgnoreCase(Set<String> keys, String key) {
        return findKeyIgnoreCase(keys, key) != null;
    }

    // ========================================
    // INTERNAL HELPER
    // ========================================
    private static String findKeyIgnoreCase(Set<String> keys, String key) {
        if (keys == null || String.isBlank(key)) return null;

        for (String k : keys) {
            if (k != null && k.equalsIgnoreCase(key)) {
                return k;
            }
        }

        return null;
    }
}