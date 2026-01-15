public with sharing class ProdSteelStandardCleanupBatch
    implements Database.Batchable<SObject>, Database.Stateful {

    private Integer baseFixed = 0;
    private Integer editionsCreated = 0;
    private Integer compositesDetected = 0;
    private Integer legacyRewired = 0;

    public Database.QueryLocator start(Database.BatchableContext ctx) {
        return Database.getQueryLocator([
            SELECT Id, EditionCode__c, Part__c, Year__c, SubSpec__c,
                   Standard__c, Standard__r.Code__c, Standard__r.Name,
                   Key__c
            FROM ProdSteelStandardEdition__c
        ]);
    }

    public void execute(Database.BatchableContext ctx, List<ProdSteelStandardEdition__c> scope) {
        List<ProdSteelStandardEdition__c> toUpdate = new List<ProdSteelStandardEdition__c>();
        List<ProdSteelStandardEdition__c> toInsert = new List<ProdSteelStandardEdition__c>();

        Map<Id, ProdSteelStandardEdition__c> oldToNew = new Map<Id, ProdSteelStandardEdition__c>();

        for (ProdSteelStandardEdition__c e : scope) {
            Boolean isBase = (e.EditionCode__c == 'BASE');

            // BASE must NOT have Part
            if (isBase && e.Part__c != null) {
                // create a real edition instead
                ProdSteelStandardEdition__c newEd = new ProdSteelStandardEdition__c();
                newEd.Standard__c = e.Standard__c;
                newEd.EditionCode__c = 'PART ' + String.valueOf(e.Part__c);
                newEd.Part__c = e.Part__c;
                newEd.Year__c = e.Year__c;
                newEd.SubSpec__c = e.SubSpec__c;
                newEd.IsActive__c = true;
                newEd.Name = e.Standard__r.Name + ' part ' + e.Part__c;
                newEd.Key__c = e.Standard__r.Code__c + '|PART|' + String.valueOf(e.Part__c);

                toInsert.add(newEd);
                oldToNew.put(e.Id, newEd);

                // strip Part from BASE
                e.Part__c = null;
                toUpdate.add(e);
                baseFixed++;
            }
        }

        if (!toInsert.isEmpty()) {
            insert toInsert;
            editionsCreated += toInsert.size();
        }

        // rewire legacy
        if (!oldToNew.isEmpty()) {
            List<ProdSteelStandardLegacyMap__c> legacy =
                [SELECT Id, TargetEdition__c
                 FROM ProdSteelStandardLegacyMap__c
                 WHERE TargetEdition__c IN :oldToNew.keySet()];

            for (ProdSteelStandardLegacyMap__c m : legacy) {
                m.TargetEdition__c = oldToNew.get(m.TargetEdition__c).Id;
                legacyRewired++;
            }
            update legacy;
        }

        if (!toUpdate.isEmpty()) update toUpdate;
    }

    public void finish(Database.BatchableContext ctx) {
        System.debug(
            'Cleanup FINISH: baseFixed=' + baseFixed +
            ', editionsCreated=' + editionsCreated +
            ', legacyRewired=' + legacyRewired
        );
    }
}