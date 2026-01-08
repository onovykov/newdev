/*
*   Prod Steel Resolver - MAIN CLASS
    2. Bulk-resolver (без SOQL у циклі)
*/
public with sharing class ProdSteelResolver {

    public static Map<Integer, ProdSteelResolution> resolveAll(
        String orderType,
        List<ERPMessageParser.ERPObject_OrderItem> items
    ) {
        Set<String> erpIds = new Set<String>();

        for (ERPMessageParser.ERPObject_OrderItem item : items) {
            if (item != null &&
                item.productCharacteristic != null &&
                item.productCharacteristic.steelGrade != null &&
                item.productCharacteristic.steelGrade.id != null) {

                erpIds.add(item.productCharacteristic.steelGrade.id);
            }
        }

        if (erpIds.isEmpty()) {
            return new Map<Integer, ProdSteelResolution>();
        }

        List<ProdSteelLegacyMap__c> maps = [
            SELECT
                LegacyErpCode__c,
                LegacyFacetCode__c,
                TargetGrade__c,
                TargetVariant__c,
                ResolutionConfidence__c
            FROM ProdSteelLegacyMap__c
            WHERE LegacyErpCode__c IN :erpIds
              AND IsActive__c = true
            ORDER BY ResolutionConfidence__c DESC
        ];

        Map<Integer, ProdSteelResolution> result =
            new Map<Integer, ProdSteelResolution>();

        for (ProdSteelLegacyMap__c m : maps) {

            Integer erpId = Integer.valueOf(m.LegacyErpCode__c);

            // беремо перший (з найвищим confidence)
            if (result.containsKey(erpId)) {
                continue;
            }

            ProdSteelResolution r = new ProdSteelResolution();
            r.application = m.LegacyFacetCode__c; // RSMP / SGMP
            r.gradeId     = m.TargetGrade__c;
            r.variantId   = m.TargetVariant__c;
            r.source      = 'LegacyMap';

            result.put(erpId, r);
        }

        return result;
    }
}