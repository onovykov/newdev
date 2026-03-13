public with sharing class RecipientGroupRepo {

    public class RecipientGroupCfg {
        public String key;
        public String kind;
        public String definition;
        public Boolean includeInactive;
        public String notes;
    }
    @TestVisible
    private static Map<String, RecipientGroupCfg> cacheByKey = new Map<String, RecipientGroupCfg>();

    /** Повертає конфіг групи отримувачів за key (DeveloperName в Recipient_Group__mdt). Кешує результат на час транзакції. */
    public static RecipientGroupCfg getGroupCfg(String groupKey) {
        String key = normalizeKey(groupKey);
        if (String.isBlank(key)) {
            return null;
        }

        if (cacheByKey.containsKey(key)) {
            return cacheByKey.get(key);
        }

        Recipient_Group__mdt mdt = Recipient_Group__mdt.getInstance(key);
        RecipientGroupCfg cfg = (mdt == null) ? null : mapToCfg(mdt);

        cacheByKey.put(key, cfg);
        return cfg;
    }

    /** Масово “прогріває” конфіги груп у кеш. Корисно перед великими розсилками/чанками. */
    public static void prime(Set<String> groupKeys) {
        if (groupKeys == null || groupKeys.isEmpty()) {
            return;
        }

        Set<String> need = new Set<String>();
        for (String k : groupKeys) {
            String nk = normalizeKey(k);
            if (!String.isBlank(nk) && !cacheByKey.containsKey(nk)) {
                need.add(nk);
            }
        }
        if (need.isEmpty()) {
            return;
        }

        Map<String, Recipient_Group__mdt> m = Recipient_Group__mdt.getAll();
        for (String k : need) {
            Recipient_Group__mdt rec = m.get(k);
            cacheByKey.put(k, rec == null ? null : mapToCfg(rec));
        }
    }

    /** Очищає кеш (корисно для тестів або якщо потрібно перечитати конфіг в межах транзакції). */
    public static void clearCache() {
        cacheByKey.clear();
    }

    /** Перетворює запис CMDT у runtime-конфіг групи. */
    private static RecipientGroupCfg mapToCfg(Recipient_Group__mdt mdt) {
        RecipientGroupCfg cfg = new RecipientGroupCfg();
        cfg.key = mdt.DeveloperName;
        cfg.kind = safeTrim(mdt.Kind__c);
        cfg.definition = safeTrim(mdt.Definition__c);
        cfg.includeInactive = (mdt.IncludeInactive__c == true);
        cfg.notes = safeTrim(mdt.Notes__c);
        return cfg;
    }

    /** Нормалізує ключ групи: trim; повертає null, якщо порожньо. */
    private static String normalizeKey(String key) {
        return safeTrim(key);
    }

    /** Безпечний trim для String: повертає null, якщо вхідний null, інакше trimmed string. */
    private static String safeTrim(String s) {
        return (s == null) ? null : s.trim();
    }
}