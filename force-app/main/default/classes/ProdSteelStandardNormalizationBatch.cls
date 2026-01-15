public with sharing class ProdSteelStandardNormalizationBatch
    implements Database.Batchable<SObject>, Database.Stateful {

    // duplicateEditionId -> canonicalEditionId
    private Map<Id, Id> remap = new Map<Id, Id>();

    private Integer editionsScanned = 0;
    private Integer editionsMerged = 0;
    private Integer legacyUpdated = 0;
    private Integer compositesDetected = 0;

    public Database.QueryLocator start(Database.BatchableContext ctx) {
        return Database.getQueryLocator([
            SELECT Id, Key__c, Standard__c, Standard__r.Code__c,
                   EditionCode__c, Year__c, SubSpec__c, Part__c
            FROM ProdSteelStandardEdition__c
        ]);
    }

    public void execute(Database.BatchableContext ctx, List<ProdSteelStandardEdition__c> scope) {
        editionsScanned += scope.size();

        // canonicalKey -> canonical edition record
        Map<String, ProdSteelStandardEdition__c> canonicalByKey = new Map<String, ProdSteelStandardEdition__c>();

        for (ProdSteelStandardEdition__c e : scope) {
            String stdCode = (e.Standard__r == null) ? null : e.Standard__r.Code__c;
            if (String.isBlank(stdCode)) continue; // safety

            String key = buildCanonicalKey(stdCode, e.EditionCode__c, e.Year__c, e.SubSpec__c);

            if (!canonicalByKey.containsKey(key)) {
                canonicalByKey.put(key, e);
            } else {
                // duplicate found in THIS chunk
                remap.put(e.Id, canonicalByKey.get(key).Id);
                editionsMerged++;
            }
        }

        // Update legacy maps that reference duplicates
        if (!remap.isEmpty()) {
            List<ProdSteelStandardLegacyMap__c> legacy =
                [SELECT Id, TargetEdition__c
                 FROM ProdSteelStandardLegacyMap__c
                 WHERE TargetEdition__c IN :remap.keySet()];

            for (ProdSteelStandardLegacyMap__c m : legacy) {
                m.TargetEdition__c = remap.get(m.TargetEdition__c);
                legacyUpdated++;
            }
            if (!legacy.isEmpty()) update legacy;
        }
    }

    public void finish(Database.BatchableContext ctx) {
        // Delete duplicates
        if (!remap.isEmpty()) {
            delete [SELECT Id FROM ProdSteelStandardEdition__c WHERE Id IN :remap.keySet()];
        }

        // Detect COMPOSITES (simple heuristic)
        List<ProdSteelStandardLegacyMap__c> maps =
            [SELECT Id, LegacyStdName__c, ResolutionType__c, TargetEdition__c, TargetStandard__c
             FROM ProdSteelStandardLegacyMap__c
             WHERE ResolutionType__c IN ('BASE','EDITION')];

        List<ProdSteelStandardLegacyMap__c> toUpdate = new List<ProdSteelStandardLegacyMap__c>();

        for (ProdSteelStandardLegacyMap__c m : maps) {
            if (isComposite(m.LegacyStdName__c)) {
                m.ResolutionType__c = 'COMPOSITE';
                m.TargetEdition__c = null;
                m.TargetStandard__c = null;
                toUpdate.add(m);
                compositesDetected++;
            }
        }
        if (!toUpdate.isEmpty()) update toUpdate;

        System.debug('ProdSteelStandardNormalizationBatch FINISH: scanned=' + editionsScanned
            + ', merged=' + editionsMerged
            + ', legacyUpdated=' + legacyUpdated
            + ', composites=' + compositesDetected);
    }

    // NOTE: Year__c is Decimal in Apex (Number field)
    private static String buildCanonicalKey(String stdCode, String edition, Decimal year, String subSpec) {
        String y = '';
        if (year != null) {
            // force integer-looking value
            y = String.valueOf(year.setScale(0));
        }

        String s = String.isBlank(subSpec) ? '' : subSpec.trim().toUpperCase();
        String e = String.isBlank(edition) ? 'BASE' : edition.trim().toUpperCase();

        // IMPORTANT: Part is NOT part of canonical key (we dedupe by ignoring Part)
        return stdCode.trim().toUpperCase() + '|' + e + '|' + y + '|' + s;
    }

    private static Boolean isComposite(String raw) {
        if (raw == null) return false;

        String s = raw.toUpperCase();

        // lists like "EN 10210-1 / EN 10210-2 / ..."
        if (s.contains(' / ') || s.contains('/')) return true;

        // extra local tech conditions
        if (s.contains(' ТП ') || s.contains(' TP ')) return true;
        if (s.contains(' TC ')) return true;
        if (s.contains(' ТУ ') || s.contains(' TU ')) return true;

        return false;
    }
}