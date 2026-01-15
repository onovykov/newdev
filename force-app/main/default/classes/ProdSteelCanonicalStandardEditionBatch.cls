global class ProdSteelCanonicalStandardEditionBatch
    implements Database.Batchable<SObject>, Database.Stateful {

    global Integer scanned = 0;
    global Integer editionsCreated = 0;
    global Integer legacyUpdated = 0;

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, LegacyStdName__c, LegacyFacetGroup__c,
                   TargetStandard__c, ResolutionType__c
            FROM ProdSteelStandardLegacyMap__c
            WHERE ResolutionType__c IN ('BASE','EDITION')
              AND TargetStandard__c != null
        ]);
    }

    global void execute(Database.BatchableContext bc, List<ProdSteelStandardLegacyMap__c> scope) {

        scanned += scope.size();

        Map<String, ProdSteelStandardEdition__c> editionsByKey = new Map<String, ProdSteelStandardEdition__c>();
        List<ProdSteelStandardLegacyMap__c> legacyUpdates = new List<ProdSteelStandardLegacyMap__c>();

        for (ProdSteelStandardLegacyMap__c m : scope) {
            EditionParseResult r = ProdSteelStandardEditionParser.parse(m.LegacyStdName__c);
            if (r == null) continue;

            String key = buildKey(m.TargetStandard__c, r);

            if (!editionsByKey.containsKey(key)) {
                ProdSteelStandardEdition__c e = new ProdSteelStandardEdition__c();
                e.Standard__c = m.TargetStandard__c;
                e.Key__c = key;
                e.Name = r.displayName;
                e.EditionCode__c = r.editionCode;
                e.Year__c = r.year;
                e.Part__c = r.part;
                e.SubSpec__c = r.subSpec;
                e.IsActive__c = true;

                editionsByKey.put(key, e);
            }

            legacyUpdates.add(m);
        }

        if (!editionsByKey.isEmpty()) {
            upsert editionsByKey.values() Key__c;
            editionsCreated += editionsByKey.size();

            Map<String, Id> idByKey = new Map<String, Id>();
            for (ProdSteelStandardEdition__c e :
                [SELECT Id, Key__c FROM ProdSteelStandardEdition__c WHERE Key__c IN :editionsByKey.keySet()]) {
                idByKey.put(e.Key__c, e.Id);
            }

            for (ProdSteelStandardLegacyMap__c m : legacyUpdates) {
                EditionParseResult r = ProdSteelStandardEditionParser.parse(m.LegacyStdName__c);
                if (r == null) continue;

                String key = buildKey(m.TargetStandard__c, r);
                if (idByKey.containsKey(key))
                    m.TargetEdition__c = idByKey.get(key);

                m.ResolutionType__c = 'EDITION';
            }

            update legacyUpdates;
            legacyUpdated += legacyUpdates.size();
        }
    }

    global void finish(Database.BatchableContext bc) {
        System.debug('EditionBatch FINISH scanned=' + scanned +
                     ', editions=' + editionsCreated +
                     ', legacyUpdated=' + legacyUpdated);
    }

    private static String buildKey(Id baseId, EditionParseResult r) {
        return String.valueOf(baseId)
            + '|' + String.valueOf(r.year)
            + '|' + (r.part == null ? '' : String.valueOf(r.part))
            + '|' + (r.subSpec == null ? '' : r.subSpec);
    }
}