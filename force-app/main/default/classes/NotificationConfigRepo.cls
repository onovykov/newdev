public with sharing class NotificationConfigRepo {

    private static Map<String, NotificationTypes.NotificationEventCfg> cacheByKey = new Map<String, NotificationTypes.NotificationEventCfg>();

    // Test injection для Notification_Event__mdt
    @TestVisible
    private static Map<String, NotificationTypes.NotificationEventCfg> testConfigs;

    /** Повертає конфіг події за eventKey (DeveloperName в Notification_Event__mdt). Кешує результат на час транзакції. */
    public static NotificationTypes.NotificationEventCfg getEventCfg(String eventKey) {
        String key = normalizeKey(eventKey);
        if (String.isBlank(key)) {
            return null;
        }

        // Test injection
        if (Test.isRunningTest() && testConfigs != null && testConfigs.containsKey(key)) {
            return testConfigs.get(key);
        }

        if (cacheByKey.containsKey(key)) {
            return cacheByKey.get(key);
        }

        Notification_Event__mdt mdt = Notification_Event__mdt.getInstance(key);
        NotificationTypes.NotificationEventCfg cfg = (mdt == null) ? null : mapToCfg(mdt);

        cacheByKey.put(key, cfg);
        return cfg;
    }

    /** Очищає кеш (корисно для тестів або якщо в межах транзакції треба примусово перечитати конфіг). */
    public static void clearCache() {
        cacheByKey.clear();
    }

    /** Перетворює запис CMDT у runtime-конфіг, який використовує NotificationService/Queueable/Channels. */
    @TestVisible
    private static NotificationTypes.NotificationEventCfg mapToCfg(Notification_Event__mdt mdt) {
        NotificationTypes.NotificationEventCfg cfg = new NotificationTypes.NotificationEventCfg();
        cfg.eventKey = mdt.DeveloperName;
        cfg.active = (mdt.Active__c == true);
        cfg.channel = safeTrim(mdt.Channel__c);
        cfg.templateApiName = safeTrim(mdt.TemplateApiName__c);
        cfg.saveAsActivity = (mdt.SaveAsActivity__c == true);

        cfg.throttleMinutes = (mdt.ThrottleMinutes__c == null) ? null : Integer.valueOf(mdt.ThrottleMinutes__c);
        cfg.batchSize = (mdt.BatchSize__c == null) ? null : Integer.valueOf(mdt.BatchSize__c);

        cfg.recipientGroupKeys = parseCsvKeys(mdt.RecipientGroups__c);
        return cfg;
    }

    /** Нормалізує eventKey: trim; повертає null, якщо порожньо. */
    @TestVisible
    private static String normalizeKey(String eventKey) {
        return safeTrim(eventKey);
    }

    /** Парсить CSV (RecipientGroups__c) у список ключів груп: trim, ігнор порожніх, без дублікатів, збереження порядку. */
    @TestVisible
    private static List<String> parseCsvKeys(String csv) {
        String raw = safeTrim(csv);
        if (String.isBlank(raw)) {
            return new List<String>();
        }

        List<String> parts = raw.split(',');
        List<String> result = new List<String>();
        Set<String> seen = new Set<String>();

        for (String p : parts) {
            String k = safeTrim(p);
            if (String.isBlank(k)) {
                continue;
            }
            if (seen.add(k)) {
                result.add(k);
            }
        }
        return result;
    }

    /** Безпечний trim для String: повертає null, якщо вхідний null, інакше trimmed string. */
    @TestVisible
    private static String safeTrim(String s) {
        return (s == null) ? null : s.trim();
    }
}