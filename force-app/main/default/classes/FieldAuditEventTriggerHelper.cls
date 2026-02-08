public with sharing class FieldAuditEventTriggerHelper {

    public static void handle(List<Field_Audit_Event__e> events) {
        if (events == null || events.isEmpty()) return;
        /* ===============================
         * 1. Collect Composite Keys
         * =============================== */
        Set<String> compositeKeys = new Set<String>();

        for (Field_Audit_Event__e e : events) {
            compositeKeys.add(
                e.ObjectApiName__c + '.' + e.FieldApiName__c
            );
        }

        /* ===============================
         * 2. Load CMDT
         * =============================== */
        Map<String, Field_Audit_Config__mdt> configByKey =
            loadConfigs(compositeKeys);

        if (configByKey.isEmpty()) return;

        /* ===============================
         * 3. Prepare DML
         * =============================== */
        List<Field_Audit_Log__c> toInsert = new List<Field_Audit_Log__c>();
        List<Field_Audit_Log__c> toUpsert = new List<Field_Audit_Log__c>();

        for (Field_Audit_Event__e e : events) {

            String compositeKey =
                e.ObjectApiName__c + '.' + e.FieldApiName__c;

            Field_Audit_Config__mdt cfg = configByKey.get(compositeKey);
            if (cfg == null) continue;

            String auditKey =
                e.ObjectApiName__c + '.' +
                e.RecordId__c + '.' +
                e.FieldApiName__c;

            String normOld = normalize(e.OldValue__c, cfg.CompareMode__c);
            String normNew = normalize(e.NewValue__c, cfg.CompareMode__c);

            String hashSource =
                auditKey + '|' +
                normOld + '|' +
                normNew + '|' +
                cfg.CompareMode__c;

            String valueHash = sha256(hashSource);

            Field_Audit_Log__c log = new Field_Audit_Log__c(
                AuditKey__c      = auditKey,
                ObjectApiName__c = e.ObjectApiName__c,
                RecordId__c      = e.RecordId__c,
                FieldApiName__c  = e.FieldApiName__c,
                OldValue__c      = e.OldValue__c,
                NewValue__c      = e.NewValue__c,
                ChangedBy__c     = e.ChangedById__c,
                ChangedAt__c     = e.ChangedAt__c,
                ValueHash__c     = valueHash,
                ChangeSource__c  = e.ChangeSource__c
            );

            if (cfg.StoreMode__c == 'LAST_ONLY') {
                toUpsert.add(log);
            } else {
                toInsert.add(log);
            }
        }

        /* ===============================
         * 4. DML
         * =============================== */
        if (!toInsert.isEmpty()) {
            insert toInsert;
        }

        if (!toUpsert.isEmpty()) {
            upsert toUpsert AuditKey__c;
        }
    }

    /* ===============================
     * Helpers
     * =============================== */
    @TestVisible
    private static Map<String, Field_Audit_Config__mdt> loadConfigs(
        Set<String> compositeKeys
    ) {
        Map<String, Field_Audit_Config__mdt> result =
            new Map<String, Field_Audit_Config__mdt>();

        for (Field_Audit_Config__mdt c :
            [
                SELECT CompositeKey__c,
                       StoreMode__c,
                       CompareMode__c
                FROM Field_Audit_Config__mdt
                WHERE CompositeKey__c IN :compositeKeys
                  AND IsEnabled__c = true
            ]
        ) {
            result.put(c.CompositeKey__c, c);
        }

        return result;
    }

    @TestVisible
    private static String normalize(String val, String compareMode) {
        if (val == null) return '';

        String mode = String.isBlank(compareMode) ? 'RAW' : compareMode;

        if (mode == 'STRING') {
            return val.trim().replaceAll('\\s+', ' ');
        }

        if (mode == 'DECIMAL_NORMALIZED') {
            Decimal d = Decimal.valueOf(val);
            return d.format();
        }

        return val;
    }

    @TestVisible
    private static String sha256(String input) {
        Blob hash = Crypto.generateDigest(
            'SHA-256',
            Blob.valueOf(input)
        );
        return EncodingUtil.convertToHex(hash);
    }
}