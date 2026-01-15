global class ProdSteelStandardCompositeClassifBatch
        implements Database.Batchable<SObject>, Database.Stateful
{
    global Integer scanned = 0;
    global Integer markedComposite = 0;
    global Integer skippedAlreadyComposite = 0;
    global Integer skippedNullName = 0;

    global Database.QueryLocator start(Database.BatchableContext ctx) {
        return Database.getQueryLocator([
            SELECT Id, LegacyStdName__c, ResolutionType__c
            FROM ProdSteelStandardLegacyMap__c
            WHERE LegacyStdName__c != null
              AND (ResolutionType__c = null OR ResolutionType__c != 'COMPOSITE')
        ]);
    }

    global void execute(Database.BatchableContext ctx, List<ProdSteelStandardLegacyMap__c> scope) {
        List<ProdSteelStandardLegacyMap__c> toUpdate = new List<ProdSteelStandardLegacyMap__c>();

        for (ProdSteelStandardLegacyMap__c row : scope) {
            scanned++;

            if (row.LegacyStdName__c == null) {
                skippedNullName++;
                continue;
            }
            if (row.ResolutionType__c == 'COMPOSITE') {
                skippedAlreadyComposite++;
                continue;
            }

            if (isComposite(row.LegacyStdName__c)) {
                row.ResolutionType__c = 'COMPOSITE';
                toUpdate.add(row);
                markedComposite++;
            }
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }

    global void finish(Database.BatchableContext ctx) {
        System.debug('ProdSteelStandardCompositeClassifBatch FINISH: scanned=' + scanned
            + ', markedComposite=' + markedComposite
            + ', skippedAlreadyComposite=' + skippedAlreadyComposite
            + ', skippedNullName=' + skippedNullName);
    }

    // --------------------------------
    // Helpers
    // --------------------------------
    private static Boolean isComposite(String s) {
        if (String.isBlank(s)) return false;

        // швидкий “cheap check”
        String t = s;
        if (t.contains('/') || t.contains(';') || t.contains(',')) {
            // не завжди, але дуже часто
            // (ми все одно підстрахуємося парсером нижче)
        }

        try {
            List<StandardParseResult> parsed = ProdSteelStandardParser.parse(s);
            return parsed != null && parsed.size() > 1;
        } catch (Exception e) {
            // якщо парсер впав — fallback на роздільники
            return (t.contains('/') || t.contains(';') || t.contains(','));
        }
    }
}