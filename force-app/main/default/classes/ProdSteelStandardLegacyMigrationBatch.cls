global class ProdSteelStandardLegacyMigrationBatch
    implements Database.Batchable<SObject>, Database.Stateful
{
    private String sourceObject; // 'ProductStandard__c' or 'WheelProductStandard__c'

    public Integer scanned = 0;
    public Integer parsed = 0;
    public Integer trash = 0;

    public ProdSteelStandardLegacyMigrationBatch(String sourceObject) {
        this.sourceObject = sourceObject;
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {

        String soql =
            'SELECT Id, ID_ERP__c, ERP_FacetGroup__c, ERP_StdName__c ' +
            'FROM ' + sourceObject + ' ' +
            'WHERE IsChecked__c = true';

        return Database.getQueryLocator(soql);
    }

    global void execute(Database.BatchableContext bc, List<SObject> scope) {

        List<ProdSteelStandardLegacyMap__c> toUpsert = new List<ProdSteelStandardLegacyMap__c>();

        for (SObject row : scope) {

            scanned++;

            String legacyId = (String)row.get('ID_ERP__c');
            String facet    = (String)row.get('ERP_FacetGroup__c');
            String stdName  = (String)row.get('ERP_StdName__c');

            if (String.isBlank(stdName)) {
                continue;
            }

            List<StandardParseResult> results =
                ProdSteelStandardParser.parse(stdName);

            for (StandardParseResult r : results) {

                parsed++;

                ProdSteelStandardLegacyMap__c rec = new ProdSteelStandardLegacyMap__c();
                rec.LegacyObjectApi__c = sourceObject;
                rec.LegacyRecordId__c = (String)row.get('Id');
                rec.LegacyErpId__c = legacyId;
                rec.LegacyFacetGroup__c = facet;
                rec.LegacyStdName__c = stdName;
                rec.ResolutionType__c = String.valueOf(r.type);

                if (r.type == StandardResolutionType.TRASH) {
                    trash++;
                }

                toUpsert.add(rec);
            }
        }

        if (!toUpsert.isEmpty()) {
            upsert toUpsert;
        }
    }

    global void finish(Database.BatchableContext bc) {
        System.debug(
            'ProdSteelStandardLegacyMigrationBatch(' + sourceObject + ') FINISH: ' +
            'scanned=' + scanned + ', parsed=' + parsed + ', trash=' + trash
        );
    }
}
