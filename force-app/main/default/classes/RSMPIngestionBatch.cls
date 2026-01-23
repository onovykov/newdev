global class RSMPIngestionBatch implements Database.Batchable<SObject> {

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Name, ID_ERP__c
            FROM WheelSteelGrade__c
        ]);
    }

    global void execute(Database.BatchableContext bc, List<WheelSteelGrade__c> scope) {

        RSMPClassifier classifier = new RSMPClassifier();

        List<ProdSteelLegacyMap__c> toUpsert = new List<ProdSteelLegacyMap__c>();

        for (WheelSteelGrade__c src : scope) {

            String raw = (src.Name == null) ? '' : src.Name.trim();
            String rawHash = CryptoUtils.sha1(raw);

            // --- call classifier (INSTANCE method) ---
            RSMPClassifier.ClassificationResult r = classifier.classify(raw);

            // --- make it schema-agnostic: convert to map ---
            Map<String, Object> rm = toMap(r);

            // try to extract common fields (with fallback key variants)
            String resType = pickString(rm, new List<String>{
                'resolutionType', 'ResolutionType', 'resolutionType__c', 'ResolutionType__c', 'type', 'Type'
            });

            String rule = pickString(rm, new List<String>{
                'rule', 'Rule', 'resolutionRule', 'ResolutionRule', 'resolutionRule__c', 'ResolutionRule__c'
            });

            String standardText = pickString(rm, new List<String>{
                'standardText', 'StandardText', 'standard', 'Standard', 'normalized', 'Normalized', 'baseCode', 'BaseCode'
            });

            // detect unknown safely
            Boolean isUnknown = isBlank(resType) || 'UNKNOWN'.equalsIgnoreCase(resType) || 'TRASH'.equalsIgnoreCase(resType);

            ProdSteelLegacyMap__c m = new ProdSteelLegacyMap__c();
            m.IsActive__c        = true;
            m.LegacyObjectApi__c = 'WheelSteelGrade__c';
            m.LegacyRecordId__c  = src.Id;
            m.LegacyFacetCode__c = 'RSMP';

            // critical ERP key
            m.LegacyErpCode__c   = src.ID_ERP__c;

            m.LegacyName__c      = raw;
            m.Alias__c           = raw;

            if (isUnknown) {
                m.ResolutionType__c = 'UNKNOWN';
                m.ResolutionRule__c = 'NO_PATTERN_MATCH';
                m.StandardText__c   = null;

                m.LegacyKey__c =
                    'WheelSteelGrade__c' + '|' +
                    src.Id + '|' +
                    'RSMP' + '|UNKNOWN|' +
                    rawHash;

            } else {
                // We keep ONLY values allowed by picklist:
                // GRADE / VARIANT / STANDARD / TRASH / UNKNOWN
                // For RSMP ingestion we expect mostly GRADE/VARIANT.
                String normalizedType = normalizeResolutionType(resType);

                if (isBlank(normalizedType)) {
                    normalizedType = 'GRADE'; // safe default if classifier returned something else
                }

                m.ResolutionType__c = normalizedType;
                m.ResolutionRule__c = isBlank(rule) ? 'CLASSIFIER_RULE_MISSING' : rule;

                // StandardText__c = canonical/base/etc. (if classifier provided)
                m.StandardText__c   = isBlank(standardText) ? null : standardText;

                String rulePart = isBlank(rule) ? 'NO_RULE' : rule;

                m.LegacyKey__c =
                    'WheelSteelGrade__c' + '|' +
                    src.Id + '|' +
                    'RSMP' + '|' +
                    rulePart + '|' +
                    rawHash;
            }

            toUpsert.add(m);
        }

        if (!toUpsert.isEmpty()) {
            upsert toUpsert LegacyKey__c;
        }
    }

    global void finish(Database.BatchableContext bc) {
        // Поки пусто. Далі тут можна викликати classifier/builders для ProdSteelGrade__c.
    }

    // =========================
    // Helpers
    // =========================

    private static Map<String, Object> toMap(Object o) {
        if (o == null) return new Map<String, Object>();
        return (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(o));
    }

    private static String pickString(Map<String, Object> m, List<String> keys) {
        for (String k : keys) {
            if (m.containsKey(k) && m.get(k) != null) {
                Object v = m.get(k);
                if (v instanceof String) return (String) v;
                return String.valueOf(v);
            }
        }
        return null;
    }

    private static Boolean isBlank(String s) {
        return s == null || String.isBlank(s); //s.trim().isEmpty();
    }

    /**
     * Maps whatever classifier returned into allowed restricted picklist values.
     * Allowed values (your org): GRADE, VARIANT, STANDARD, TRASH, UNKNOWN
     */
    private static String normalizeResolutionType(String rawType) {
        if (isBlank(rawType)) return null;

        String t = rawType.trim().toUpperCase();

        if (t == 'GRADE' || t == 'VARIANT' || t == 'STANDARD' || t == 'TRASH' || t == 'UNKNOWN') {
            return t;
        }

        // common legacy aliases
        if (t == 'BASE') return 'GRADE';
        if (t == 'EXTENSION') return 'VARIANT';
        if (t == 'EXTENTION') return 'VARIANT';

        // otherwise we don't risk picklist failure
        return null;
    }
}