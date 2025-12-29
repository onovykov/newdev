global class StandardMigrationBatch
    implements Database.Batchable<SObject>, Database.Stateful {

    // ===================== START =====================
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Name, FullName__c, ID_ERP__c
            FROM ProductStandard__c
            WHERE Name != null OR FullName__c != null
        ]);
    }

    // ===================== EXECUTE =====================
    global void execute(
        Database.BatchableContext bc,
        List<SObject> scope
    ) {
        List<ProductStandard__c> records =
            (List<ProductStandard__c>) scope;        
        // --------- 1. Parse legacy data ---------
        List<Set<String>> groups = new List<Set<String>>();
        Set<String> allNorms = new Set<String>();
        Map<String, ProductStandard__c> legacyByNorm =
            new Map<String, ProductStandard__c>();

        for (ProductStandard__c r : records) {
            String source =
                !String.isBlank(r.FullName__c)
                    ? r.FullName__c
                    : r.Name;

            Set<String> norms =
                StandardNormalizer.splitNormalizeAndFilter(source);

            // SAFETY NET — ніколи не дозволяємо empty
            if (norms.isEmpty()) {
                String fallback = StandardNormalizer.normalize(source);
                if (!String.isBlank(fallback)) {
                    norms.add(fallback);
                }
            }

            if (norms.isEmpty()) {
                continue; // уже зовсім без шансів
            }

            groups.add(norms);
            allNorms.addAll(norms);

            for (String n : norms) {
                if (!legacyByNorm.containsKey(n)) {
                    legacyByNorm.put(n, r);
                }
            }
        }

        if (groups.isEmpty()) {
            return;
        }

        // --------- 2. Upsert Standard__c ---------
        Map<String, Standard__c> standardByNorm =
            new Map<String, Standard__c>();

        for (Standard__c s : [
            SELECT Id, NormalizedName__c
            FROM Standard__c
            WHERE NormalizedName__c IN :allNorms
        ]) {
            standardByNorm.put(s.NormalizedName__c, s);
        }

        List<Standard__c> standardsToUpsert = new List<Standard__c>();

        for (String norm : allNorms) {
            if (!standardByNorm.containsKey(norm)) {
                ProductStandard__c legacy = legacyByNorm.get(norm);

                standardsToUpsert.add(new Standard__c(
                    Name = norm,
                    NormalizedName__c = norm,
                    OldId__c = legacy.Id,
                    ID_ERP__c = legacy.ID_ERP__c
                ));
            }
        }

        if (!standardsToUpsert.isEmpty()) {
            upsert standardsToUpsert NormalizedName__c;
        }

        for (Standard__c s : [
            SELECT Id, NormalizedName__c, OldId__c, ID_ERP__c
            FROM Standard__c
            WHERE NormalizedName__c IN :allNorms
        ]) {
            standardByNorm.put(s.NormalizedName__c, s);
        }

        // --------- 3. Upsert Equivalence Groups ---------
        Map<String, StandardEquivalenceGroup__c> groupByHash =
            new Map<String, StandardEquivalenceGroup__c>();

        Set<String> hashes = new Set<String>();
        for (Set<String> g : groups) {
            hashes.add(buildGroupHash(g));
        }

        for (StandardEquivalenceGroup__c g : [
            SELECT Id, Hash__c, OldId__c, ID_ERP__c, PrimaryStandard__c
            FROM StandardEquivalenceGroup__c
            WHERE Hash__c IN :hashes
        ]) {
            groupByHash.put(g.Hash__c, g);
        }

        List<StandardEquivalenceGroup__c> groupsToUpsert =
            new List<StandardEquivalenceGroup__c>();

        Set<String> hashesScheduledForUpsert = new Set<String>();

        for (Set<String> g : groups) {
            String hash = buildGroupHash(g);
            if (!groupByHash.containsKey(hash)
                && !hashesScheduledForUpsert.contains(hash)
            ) {
                hashesScheduledForUpsert.add(hash);

            // беремо будь-який норм зі множини
            String anyNorm = g.iterator().next();
            ProductStandard__c legacy = legacyByNorm.get(anyNorm);

            if (legacy == null) {
                continue; // safety, не повинно траплятися
            }

            groupsToUpsert.add(new StandardEquivalenceGroup__c(
                Hash__c = hash,
                OldId__c = legacy.Id,
                ID_ERP__c = legacy.ID_ERP__c
            ));
            }
        }

        if (!groupsToUpsert.isEmpty()) {
            upsert groupsToUpsert Hash__c;
        }

        for (StandardEquivalenceGroup__c g : [
            SELECT Id, Hash__c, OldId__c, ID_ERP__c, PrimaryStandard__c
            FROM StandardEquivalenceGroup__c
            WHERE Hash__c IN :hashes
        ]) {
            groupByHash.put(g.Hash__c, g);
        }

        // --------- 4. Backfill PrimaryStandard__c ---------
        Map<String, Id> primaryByOldId = new Map<String, Id>();

        for (Standard__c s : [
            SELECT Id, OldId__c
            FROM Standard__c
            WHERE OldId__c != null
        ]) {
            if (!primaryByOldId.containsKey(s.OldId__c)) {
                primaryByOldId.put(s.OldId__c, s.Id);
            }
        }

        List<StandardEquivalenceGroup__c> groupsToUpdatePrimary =
            new List<StandardEquivalenceGroup__c>();

        for (StandardEquivalenceGroup__c g : groupByHash.values()) {
            if (g.PrimaryStandard__c == null && g.OldId__c != null) {
                Id ps = primaryByOldId.get(g.OldId__c);
                if (ps != null) {
                    g.PrimaryStandard__c = ps;
                    groupsToUpdatePrimary.add(g);
                }
            }
        }

        if (!groupsToUpdatePrimary.isEmpty()) {
            update groupsToUpdatePrimary;
        }

        // --------- 5. Build junctions ---------
        Set<String> uniqueKeys = new Set<String>();
        for (Set<String> g : groups) {
            String hash = buildGroupHash(g);
            for (String norm : g) {
                uniqueKeys.add(hash + '|' + standardByNorm.get(norm).Id);
            }
        }

        Map<String, StandardEquivalence__c> existing =
            new Map<String, StandardEquivalence__c>();

        for (StandardEquivalence__c se : [
            SELECT Id, UniqueKey__c
            FROM StandardEquivalence__c
            WHERE UniqueKey__c IN :uniqueKeys
        ]) {
            existing.put(se.UniqueKey__c, se);
        }

        List<StandardEquivalence__c> junctions =
            new List<StandardEquivalence__c>();
        Set<String> junctionsScheduled = new Set<String>();
        for (Set<String> g : groups) {
            StandardEquivalenceGroup__c grp =
                groupByHash.get(buildGroupHash(g));

            for (String norm : g) {
                Standard__c std = standardByNorm.get(norm);
                String uk = grp.Hash__c + '|' + std.Id;

            if (!existing.containsKey(uk)
                && !junctionsScheduled.contains(uk)
            ) {
                junctionsScheduled.add(uk);

                junctions.add(new StandardEquivalence__c(
                    EquivalenceGroup__c = grp.Id,
                    Standard__c = std.Id,
                    UniqueKey__c = uk
                ));
            }
            }
        }

        if (!junctions.isEmpty()) {
            insert junctions;
        }
    }

    // ===================== FINISH =====================
    global void finish(Database.BatchableContext bc) {
        System.debug('StandardMigrationBatch FINISHED');
    }

    private static String buildGroupHash(Set<String> norms) {
        List<String> sorted = new List<String>();
        sorted.addAll(norms);
        sorted.sort();

        String joined = String.join(sorted, '|');

        // SHA1 → 40 hex chars
        Blob digest = Crypto.generateDigest('SHA1', Blob.valueOf(joined));
        return EncodingUtil.convertToHex(digest);
    }

}