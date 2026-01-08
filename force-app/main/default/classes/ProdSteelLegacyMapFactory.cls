public class ProdSteelLegacyMapFactory {

    public static ProdSteelLegacyMap__c build(
        LegacySteelRow legacy,
        SteelParseResult r
    ) {
        ProdSteelLegacyMap__c m =
            new ProdSteelLegacyMap__c();

        m.LegacyObjectApi__c  = legacy.sourceObject;
        m.LegacyRecordId__c   = String.valueOf(legacy.sfId);
        m.LegacyErpCode__c    = legacy.erpId;
        m.LegacyFacetCode__c  = legacy.facetCode;
        m.LegacyName__c       = legacy.name;
        m.LegacyShortName__c  = legacy.shortName;

        m.ResolutionType__c   = r.type;
        m.ResolutionRule__c   = r.rule;
        m.ResolutionConfidence__c = r.confidence;

        m.TargetGrade__c      = r.gradeId;
        m.TargetVariant__c    = r.variantId;

        m.LegacyKey__c =
            legacy.sourceObject + '|' +
            legacy.erpId + '|' +
            legacy.facetCode + '|' +
            r.baseCode + '|' +
            r.variantCode + '|' +
            r.hashSuffix;

        m.IsActive__c = true;

        return m;
    }
}