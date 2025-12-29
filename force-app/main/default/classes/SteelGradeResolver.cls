public with sharing class SteelGradeResolver {

    // ===============================
    // PUBLIC ENTRY POINT
    // ===============================
    public static void resolve(Boolean doCleanup, String facetCode) {

        System.assert(
            facetCode == 'SGMP' || facetCode == 'RSMP',
            'Unsupported facetCode: ' + facetCode
        );

        // ===============================
        // 0. CLEANUP (OPTIONAL)
        // ===============================
        if (doCleanup) {
            cleanupFacet(facetCode);
        }

        // ===============================
        // 1. LOAD SOURCE DATA
        // ===============================
        List<SObject> sourceRecords = loadSourceData(facetCode);
        System.debug('SOURCE RECORDS: ' + sourceRecords.size());

        // ===============================
        // 2. NORMALIZE
        // ===============================
        List<SteelGradeNormalizer.Result> results = new List<SteelGradeNormalizer.Result>();
        Map<SteelGradeNormalizer.Result, SObject> resultToSource =
            new Map<SteelGradeNormalizer.Result, SObject>();

        for (SObject src : sourceRecords) {

            String nameVal = (String)src.get('Name');
            if (String.isBlank(nameVal)) continue;

            SteelGradeNormalizer.Result r =
                facetCode == 'RSMP'
                    ? SteelGradeNormalizer.normalizeRSMP(nameVal)
                    : SteelGradeNormalizer.normalize(nameVal);            
            //    SteelGradeNormalizer.normalize(nameVal);

            if (r == null || r.isGarbage || r.grades.isEmpty()) {
                continue;
            }

            results.add(r);
            resultToSource.put(r, src);
        }

        System.debug('NORMALIZED RECORDS: ' + results.size());

        // ===============================
        // 3. PRELOAD EXISTING DATA
        // ===============================
        Map<String, SteelGradeBase__c> baseByName =
            loadExistingBases(facetCode);

        Map<String, SteelGradeAttribute__c> attrByName =
            loadExistingAttributes(facetCode);

        Set<String> existingAltKeys =
            loadExistingAlternativeKeys(facetCode);

        // ===============================
        // 4. COLLECT BASES & ATTRIBUTES
        // ===============================
        Map<String, SteelGradeBase__c> basesToInsert =
            new Map<String, SteelGradeBase__c>();

        Map<String, SteelGradeAttribute__c> attrsToInsert =
            new Map<String, SteelGradeAttribute__c>();

        for (SteelGradeNormalizer.Result r : results) {

            Boolean isSingleGradeSource = (r.grades.size() == 1);
            SObject src = resultToSource.get(r);

            for (String g : r.grades) {

                // ❌ НЕ створюємо числові бази з комбінацій
                if (!isSingleGradeSource && Pattern.matches('^\\d{1,3}$', g)) {
                    continue;
                }

                if (!baseByName.containsKey(g) &&
                    !basesToInsert.containsKey(g)) {

                    SteelGradeBase__c b = new SteelGradeBase__c(
                        Name = g,
                        FacetCode__c = facetCode,
                        IsActive__c = true
                    );

                    if (isSingleGradeSource && src != null) {
                        b.OldID__c = (Id)src.get('Id');
                        b.ID_ERP__c = (String)src.get('ID_ERP__c');
                    }

                    basesToInsert.put(g, b);
                }
            }

            for (String a : r.attributes) {
                if (!attrByName.containsKey(a) &&
                    !attrsToInsert.containsKey(a)) {

                    attrsToInsert.put(
                        a,
                        new SteelGradeAttribute__c(
                            Name = a,
                            FacetCode__c = facetCode,
                            IsActive__c = true
                        )
                    );
                }
            }
        }

        // ===============================
        // 5. INSERT BASES & ATTRIBUTES
        // ===============================
        if (!basesToInsert.isEmpty()) {
            insert basesToInsert.values();
            for (SteelGradeBase__c b : basesToInsert.values()) {
                baseByName.put(b.Name, b);
            }
        }

        if (!attrsToInsert.isEmpty()) {
            insert attrsToInsert.values();
            for (SteelGradeAttribute__c a : attrsToInsert.values()) {
                attrByName.put(a.Name, a);
            }
        }

        // ===============================
        // 6. COLLECT BASE ALTERNATIVES
        // ===============================
        Map<String, SteelGradeBaseAlternative__c> altsToInsert =
            new Map<String, SteelGradeBaseAlternative__c>();

        for (SteelGradeNormalizer.Result r : results) {

            if (r.grades.size() < 2) continue;

            List<String> gradeList = new List<String>(r.grades);

            for (Integer i = 0; i < gradeList.size(); i++) {
                for (Integer j = i + 1; j < gradeList.size(); j++) {

                    SteelGradeBase__c a = baseByName.get(gradeList[i]);
                    SteelGradeBase__c b = baseByName.get(gradeList[j]);
                    if (a == null || b == null) continue;

                    Id left  = a.Id < b.Id ? a.Id : b.Id;
                    Id right = a.Id < b.Id ? b.Id : a.Id;

                    String key = facetCode + '_' + left + '_' + right;

                    if (existingAltKeys.contains(key) ||
                        altsToInsert.containsKey(key)) {
                        continue;
                    }

                    altsToInsert.put(
                        key,
                        new SteelGradeBaseAlternative__c(
                            GradeBaseA__c = left,
                            GradeBaseB__c = right,
                            FacetCode__c = facetCode,
                            CanonicalKey__c = key,
                            IsActive__c = true
                        )
                    );
                }
            }
        }

        if (!altsToInsert.isEmpty()) {
            insert altsToInsert.values();
        }

        // ===============================
        // 7. SUMMARY
        // ===============================
        System.debug('==============================');
        System.debug('FACET: ' + facetCode);
        System.debug('BASES CREATED: ' + basesToInsert.size());
        System.debug('ATTRS CREATED: ' + attrsToInsert.size());
        System.debug('ALTS CREATED: ' + altsToInsert.size());
        System.debug('==============================');
    }

    // ============================================================
    // HELPERS
    // ============================================================

    private static void cleanupFacet(String facetCode) {

        delete [
            SELECT Id
            FROM SteelGradeBaseAlternative__c
            WHERE FacetCode__c = :facetCode
        ];

        delete [
            SELECT Id
            FROM SteelGradeAttribute__c
            WHERE FacetCode__c = :facetCode
        ];

        delete [
            SELECT Id
            FROM SteelGradeBase__c
            WHERE FacetCode__c = :facetCode
        ];
    }

    private static List<SObject> loadSourceData(String facetCode) {

        String sourceObject =
            facetCode == 'SGMP'
                ? 'SteelGrade__c'
                : 'WheelSteelGrade__c';

        String soql =
            'SELECT Id, Name, ID_ERP__c ' +
            'FROM ' + sourceObject +
            ' WHERE Name != null';

        return Database.query(soql);
    }

    private static Map<String, SteelGradeBase__c> loadExistingBases(String facetCode) {
        Map<String, SteelGradeBase__c> out = new Map<String, SteelGradeBase__c>();
        for (SteelGradeBase__c b : [
            SELECT Id, Name
            FROM SteelGradeBase__c
            WHERE FacetCode__c = :facetCode
        ]) {
            out.put(b.Name, b);
        }
        return out;
    }

    private static Map<String, SteelGradeAttribute__c> loadExistingAttributes(String facetCode) {
        Map<String, SteelGradeAttribute__c> out = new Map<String, SteelGradeAttribute__c>();
        for (SteelGradeAttribute__c a : [
            SELECT Id, Name
            FROM SteelGradeAttribute__c
            WHERE FacetCode__c = :facetCode
        ]) {
            out.put(a.Name, a);
        }
        return out;
    }

    private static Set<String> loadExistingAlternativeKeys(String facetCode) {
        Set<String> out = new Set<String>();
        for (SteelGradeBaseAlternative__c alt : [
            SELECT CanonicalKey__c
            FROM SteelGradeBaseAlternative__c
            WHERE FacetCode__c = :facetCode
        ]) {
            out.add(alt.CanonicalKey__c);
        }
        return out;
    }
}