global class RSMPIngestionBatch implements Database.Batchable<SObject> {

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Name, ID_ERP__c
            FROM WheelSteelGrade__c
        ]);
    }

    global void execute(Database.BatchableContext bc, List<WheelSteelGrade__c> scope) {

        List<PatternSetting__c> patterns = PatternCache.getRSMPSteelPatterns();
        List<ProdSteelLegacyMap__c> toUpsert = new List<ProdSteelLegacyMap__c>();
        for (WheelSteelGrade__c src : scope) {

            String raw = (src.Name == null ? '' : src.Name.trim());
            String rawHash = CryptoUtils.sha1(raw);

            Boolean matched = false;

            for (PatternSetting__c p : patterns) {
                if (String.isBlank(p.Regex__c)) continue;

                if (PatternMatcher.matches(raw, p.Regex__c)) {
                    matched = true;

                    ProdSteelLegacyMap__c m = new ProdSteelLegacyMap__c();
                    m.IsActive__c = true;
                    m.LegacyErpCode__c = src.ID_ERP__c;
                    m.LegacyObjectApi__c = 'WheelSteelGrade__c';
                    m.LegacyRecordId__c  = (String)src.Id;
                    m.LegacyName__c      = raw;
                    m.LegacyFacetCode__c = 'RSMP';
                    m.Alias__c           = raw;
                    //m.IsActive__c = true;
                    m.ResolutionType__c = mapType(p.Type__c);
                    m.ResolutionRule__c = 'PATTERN:' + p.Regex__c;

                    // ===== LegacyKey for MATCH =====
                    String legacyKey =
                        'WheelSteelGrade__c' + '|' +
                        src.Id + '|' +
                        'RSMP' + '|' +
                        p.Regex__c + '|' +
                        rawHash;
                        //--- Класифікація Version/Edition
                        RSMPClassifier.Result r = RSMPClassifier.classify(src.Name);

                        if (r.isUnknown()) {
                            m.ResolutionType__c = 'UNKNOWN';
                            m.ResolutionRule__c = 'NO_PATTERN_MATCH';
                        } else {
                            m.ResolutionType__c = r.variantCode == null ? 'GRADE' : 'VARIANT';
                            m.ResolutionRule__c = r.getRule();
                            m.StandardText__c   = r.getStandardText();
                        }
                        //---
                    m.LegacyKey__c = legacyKey;

                    toUpsert.add(m);

                    // для Base-патернів беремо перший збіг
                    break;
                }
            }

            if (!matched) {
                ProdSteelLegacyMap__c m = new ProdSteelLegacyMap__c();
                m.IsActive__c = true;
                m.LegacyErpCode__c = src.ID_ERP__c;
                m.LegacyObjectApi__c = 'WheelSteelGrade__c';
                m.LegacyRecordId__c  = (String)src.Id;
                m.LegacyName__c      = raw;
                m.LegacyFacetCode__c = 'RSMP';
                m.Alias__c           = raw;

                m.ResolutionType__c = 'UNKNOWN';
                m.ResolutionRule__c = 'NO_PATTERN_MATCH';

                // ===== LegacyKey for UNKNOWN =====
                String legacyKey =
                    'WheelSteelGrade__c' + '|' +
                    src.Id + '|' +
                    'RSMP' + '|UNKNOWN|' +
                    rawHash;
                /* Класифікація Version/Edition
                RSMPClassifier.Result r = RSMPClassifier.classify(src.Name);

                if (r.isUnknown()) {
                    m.ResolutionType__c = 'UNKNOWN';
                    m.ResolutionRule__c = 'NO_PATTERN_MATCH';
                } else {
                    m.ResolutionType__c = r.variantCode == null ? 'GRADE' : 'VARIANT';
                    m.ResolutionRule__c = r.getRule();
                    m.StandardText__c   = r.getStandardText();
                }
                */
                m.LegacyKey__c = legacyKey;

                toUpsert.add(m);
            }
        }

        if (!toUpsert.isEmpty()) {
            upsert toUpsert LegacyKey__c;
        }
    }

    private static String mapType(String typeFromPattern) {
        if (typeFromPattern == 'Base')      return 'GRADE';
        if (typeFromPattern == 'Variant')   return 'VARIANT';
        if (typeFromPattern == 'Extension') return 'TRASH';
        return 'UNKNOWN';
    }

    global void finish(Database.BatchableContext bc) {}
}