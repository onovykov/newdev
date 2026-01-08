//   ProdSteelFamilyResolver (CMDT-based)
public with sharing class ProdSteelFamilyResolver {

    private static Boolean initialized = false;

    private static Map<String, Map<String, String>> familyByFacet =
        new Map<String, Map<String, String>>();

    private static Map<String, String> familyGeneric =
        new Map<String, String>();

    private static void init() {
        if (initialized) return;
        initialized = true;

        for (SteelFamily__mdt r : [
            SELECT Family__c, Grade__c, Facet__c
            FROM SteelFamily__mdt
            WHERE IsActive__c = true
        ]) {
            String grade = r.Grade__c != null
                ? r.Grade__c.trim().toUpperCase()
                : null;

            if (String.isBlank(grade)) continue;

            // facet-specific rule
            if (!String.isBlank(r.Facet__c)) {
                if (!familyByFacet.containsKey(r.Facet__c)) {
                    familyByFacet.put(
                        r.Facet__c,
                        new Map<String, String>()
                    );
                }
                familyByFacet
                    .get(r.Facet__c)
                    .put(grade, r.Family__c);
            }
            // generic rule
            else {
                familyGeneric.put(grade, r.Family__c);
            }
        }
    }

    // ===== Public API =====

    public static FamilyResult resolve(String baseCode, String facetCode) {
        init();

        FamilyResult r = new FamilyResult();
        String b = baseCode != null ? baseCode.trim().toUpperCase() : null;

        if (String.isBlank(b)) {
            r.familyApi = 'OTHER';
            r.rule = 'family:empty';
            r.confidence = 0.0;
            return r;
        }

        // 1️⃣ facet-specific
        if (!String.isBlank(facetCode)
            && familyByFacet.containsKey(facetCode)
            && familyByFacet.get(facetCode).containsKey(b)
        ) {
            r.familyApi = familyByFacet.get(facetCode).get(b);
            r.rule = 'family:cmdt:f:' + facetCode;
            r.confidence = 1.0;
            return r;
        }

        // 2️⃣ generic
        if (familyGeneric.containsKey(b)) {
            r.familyApi = familyGeneric.get(b);
            r.rule = 'family:cmdt:generic';
            r.confidence = 0.95;
            return r;
        }

        // 3️⃣ fallback
        r.familyApi = 'OTHER';
        r.rule = 'family:other';
        r.confidence = 0.10;
        return r;
    }

    // ===== DTO =====
    public class FamilyResult {
        public String familyApi;
        public String rule;
        public Decimal confidence;
    }
}