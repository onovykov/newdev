public class SteelGradeCompositeImporter {

    // =========================================================
    // CONFIG
    // =========================================================
    public class Config {
        public String facetCode;          // 'SGMP' / 'RSMP'
        public Boolean doCleanup = false; // cleanup ONLY this facet
        public Boolean dryRun = false;    // no DML, only debug

        public Config(String facetCode) {
            this.facetCode = facetCode;
        }
    }

    // =========================================================
    // ENTRY POINT
    // =========================================================
    public static void importFromSteelGrades(
        List<SteelGrade__c> srcList,
        Config cfg
    ) {
        if (srcList == null || srcList.isEmpty()) {
            System.debug('No source records');
            return;
        }
        if (cfg == null || String.isBlank(cfg.facetCode)) {
            throw new IllegalArgumentException('FacetCode is required');
        }

        String FACET = cfg.facetCode;

        // =====================================================
        // 0. CLEANUP (PER FACET)
        // =====================================================
        if (cfg.doCleanup && !cfg.dryRun) {
            delete [
                SELECT Id
                FROM SteelGradeComposite__c
                WHERE FacetCode__c = :FACET
            ];
            System.debug('=== CLEANUP DONE FOR FACET ' + FACET + ' ===');
        }

        // =====================================================
        // 1. PRELOAD BASES & ATTRIBUTES
        // =====================================================
        Map<String, Id> baseByName = new Map<String, Id>();
        for (SteelGradeBase__c b : [
            SELECT Id, Name
            FROM SteelGradeBase__c
            WHERE FacetCode__c = :FACET
        ]) {
            baseByName.put(b.Name, b.Id);
        }

        Map<String, Id> attrByName = new Map<String, Id>();
        for (SteelGradeAttribute__c a : [
            SELECT Id, Name
            FROM SteelGradeAttribute__c
        ]) {
            attrByName.put(a.Name, a.Id);
        }

        // =====================================================
        // 2. BUILD COMPOSITES (SEGMENT-AWARE)
        // =====================================================
        Map<String, SteelGradeComposite__c> toUpsert =
            new Map<String, SteelGradeComposite__c>();

        for (SteelGrade__c src : srcList) {

            if (src == null || String.isBlank(src.Name)) continue;
            if (src.Name == 'n/a' || src.ID_ERP__c == '00') continue;

            // 🔑 SEGMENTS: split by '/'
            List<String> segments = src.Name.split('/');

            for (String segment : segments) {
                segment = segment.trim();
                if (segment.length() < 2) continue;

                SteelGradeNormalizer.Result r =
                    SteelGradeNormalizer.normalize(segment);

                if (r.isGarbage || r.grades.isEmpty()) continue;

                for (String g : r.grades) {

                    String baseName = g;
                    if (!baseByName.containsKey(baseName)) continue;

                    Id baseId = baseByName.get(baseName);

                    // --- no attributes → base only composite
                    if (r.attributes.isEmpty()) {
                        String code = FACET + '_' + baseName;

                        toUpsert.put(
                            code,
                            buildComposite(
                                code, FACET, baseId, null, src
                            )
                        );
                        continue;
                    }

                    // --- attributes
                    for (String a : r.attributes) {
                        if (!attrByName.containsKey(a)) continue;

                        String code = FACET + '_' + baseName + '_' + a;

                        toUpsert.put(
                            code,
                            buildComposite(
                                code,
                                FACET,
                                baseId,
                                attrByName.get(a),
                                src
                            )
                        );
                    }
                }
            }
        }

        // =====================================================
        // 3. UPSERT
        // =====================================================
        if (!cfg.dryRun && !toUpsert.isEmpty()) {
            upsert toUpsert.values() CompositeCode__c;
        }

        System.debug('=== COMPOSITE IMPORT DONE ===');
        System.debug('FACET: ' + FACET);
        System.debug('COMPOSITES: ' + toUpsert.size());
    }

    // =========================================================
    // HELPERS
    // =========================================================
    private static SteelGradeComposite__c buildComposite(
        String code,
        String facet,
        Id baseId,
        Id attrId,
        SteelGrade__c src
    ) {
        SteelGradeComposite__c c = new SteelGradeComposite__c();
        c.CompositeCode__c = code;
        c.Name = code;
        c.FacetCode__c = facet;
        c.SteelGradeBase__c = baseId;
        c.SteelGradeAttibute__c = attrId;
        c.IsActive__c = true;
        c.ID_ERP__c = src.ID_ERP__c;
        c.OldID__c = src.Id;
        return c;
    }
}