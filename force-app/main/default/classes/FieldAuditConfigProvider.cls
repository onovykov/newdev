public with sharing class FieldAuditConfigProvider {
    private static Map<String, Field_Audit_Config__mdt> cache;
    /* =========================
       Публічний API
       ========================= */
    public static Boolean isInboundEnabled(
        String objectApiName,
        String fieldApiName
    ) {
        Field_Audit_Config__mdt cfg = get(objectApiName, fieldApiName);
        return cfg != null && cfg.InboundActive__c;
    }

    public static Boolean isOutboundEnabled(
        String objectApiName,
        String fieldApiName
    ) {
        Field_Audit_Config__mdt cfg = get(objectApiName, fieldApiName);
        return cfg != null && cfg.OutboundActive__c;
    }

    public static Field_Audit_Config__mdt get(
        String objectApiName,
        String fieldApiName
    ) {
        init();
        return cache.get(buildKey(objectApiName, fieldApiName));
    }

    /* =========================
       INTERNALS
       ========================= */
    private static void init() {
        if (cache != null) return;

        cache = new Map<String, Field_Audit_Config__mdt>();

        for (Field_Audit_Config__mdt cfg : [
            SELECT
                ObjectApiName__c,
                FieldApiName__c,
                CompositeKey__c,
                IsEnabled__c,
                InboundActive__c,
                OutboundActive__c,
                StoreMode__c,
                CompareMode__c
            FROM Field_Audit_Config__mdt
            WHERE IsEnabled__c = true
        ]) {
            cache.put(
                buildKey(cfg.ObjectApiName__c, cfg.FieldApiName__c),
                cfg
            );
        }
    }
	//--- Генеруємо ключ CompositeKey__с
    private static String buildKey(
        String objectApiName,
        String fieldApiName
    ) {
        return objectApiName + '.' + fieldApiName;
    }
}