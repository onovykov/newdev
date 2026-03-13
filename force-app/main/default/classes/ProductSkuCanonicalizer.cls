public class ProductSkuCanonicalizer {

    public static String buildCanonicalJson(Map<String, String> params) {

        // 1. Сортуємо ключі
        List<String> keys = new List<String>(params.keySet());
        keys.sort();

        // 2. Створюємо впорядкований Map
        Map<String, String> ordered = new Map<String, String>();

        for (String k : keys) {
            ordered.put(k, params.get(k));
        }

        // 3. Серіалізуємо
        return JSON.serialize(ordered);
    }
}