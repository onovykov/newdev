global class ProdSteelLegacyMigrationBatch
    implements Database.Batchable<SObject>, Database.Stateful {

    private Set<String> facetCodes;

    public ProdSteelLegacyMigrationBatch(Set<String> facetCodes) {
        this.facetCodes = facetCodes;
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {

        List<String> queries = new List<String>();

        if (facetCodes.contains('RSMP')) {
            queries.add(
                'SELECT Id, ID_ERP__c, Name, ShortName__c ' +
                'FROM WheelSteelGrade__c'
            );
        }

        if (facetCodes.contains('SGMP')) {
            queries.add(
                'SELECT Id, ID_ERP__c, Name, ShortName__c ' +
                'FROM SteelGrade__c'
            );
        }

        return Database.getQueryLocator(
            String.join(queries, ' UNION ALL ')
        );
    }

    global void execute(
        Database.BatchableContext bc,
        List<SObject> scope
    ) {
        List<ProdSteelLegacyMap__c> mapsToUpsert =
            new List<ProdSteelLegacyMap__c>();

        for (SObject row : scope) {

            LegacySteelRow legacy =
                LegacySteelRow.fromSObject(row);

            List<SteelParseResult> results =
                ProdSteelParser.parse(
                    legacy.name,
                    legacy.facetCode
                );

            for (SteelParseResult r : results) {

                ProdSteelLegacyMap__c legacyMap =
                    ProdSteelLegacyMapFactory.build(
                        legacy,
                        r
                    );

                mapsToUpsert.add(legacyMap);
            }
        }

        if (!mapsToUpsert.isEmpty()) {
            upsert mapsToUpsert
                ProdSteelLegacyMap__c.LegacyKey__c;
        }
    }

    global void finish(Database.BatchableContext bc) {
        // optional logging / notification
    }
}