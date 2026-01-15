global class ProdSteelStandardCompositeBatch
        implements Database.Batchable<SObject>, Database.Stateful
{
    global Integer scanned = 0;
    global Integer compositesUpserted = 0;
    global Integer itemsUpserted = 0;

    global Integer skippedBlankName = 0;
    global Integer skippedNoParseItems = 0;
    global Integer skippedNoResolvedEditions = 0;

    global Database.QueryLocator start(Database.BatchableContext ctx) {
        return Database.getQueryLocator([
            SELECT Id, LegacyStdName__c, LegacyFacetGroup__c, ResolutionType__c
            FROM ProdSteelStandardLegacyMap__c
            WHERE ResolutionType__c = 'COMPOSITE'
              AND LegacyStdName__c != null
        ]);
    }

    global void execute(Database.BatchableContext ctx, List<ProdSteelStandardLegacyMap__c> scope) {
        scanned += scope.size();

        // 1) Parse all composite legacy texts, collect:
        //    - composite keys
        //    - edition keys to resolve
        Map<String, ProdSteelStandardComposite__c> compositesByKey = new Map<String, ProdSteelStandardComposite__c>();
        Map<Id, List<StandardParseResult>> parsedByLegacyId = new Map<Id, List<StandardParseResult>>();
        Set<String> neededEditionKeys = new Set<String>();

        for (ProdSteelStandardLegacyMap__c legacy : scope) {
            String legacyText = legacy.LegacyStdName__c;
            if (String.isBlank(legacyText)) {
                skippedBlankName++;
                continue;
            }

            List<StandardParseResult> parsed;
            try {
                parsed = ProdSteelStandardParser.parse(legacyText);
            } catch (Exception e) {
                parsed = null;
            }

            if (parsed == null || parsed.isEmpty()) {
                skippedNoParseItems++;
                continue;
            }

            // зберігаємо парс для подальшої побудови items
            parsedByLegacyId.put(legacy.Id, parsed);

            // composite key (без '|', щоб не ловити UTF-8/BLOB сюрпризи)
            String compositeKey = buildCompositeKey(legacy.LegacyFacetGroup__c, legacyText);

            if (!compositesByKey.containsKey(compositeKey)) {
                ProdSteelStandardComposite__c c = new ProdSteelStandardComposite__c();
                c.Key__c = compositeKey;
                c.LegacyText__c = safeTrim255(legacyText);
                c.Domain__c = facetGroupToDomain(legacy.LegacyFacetGroup__c); // Wheels/Tubes
                c.IsActive__c = true;
                c.Name = buildCompositeName(c.Domain__c, c.LegacyText__c);
                compositesByKey.put(compositeKey, c);
            }

            // collect edition keys
            for (StandardParseResult r : parsed) {
                if (r == null || String.isBlank(r.canonicalCode)) continue;
                String editionKey = buildEditionKey(r.canonicalCode, r);
                if (!String.isBlank(editionKey)) {
                    neededEditionKeys.add(editionKey);
                }
            }
        }

        if (compositesByKey.isEmpty()) {
            return;
        }

        // 2) Resolve editions in one query
        Map<String, ProdSteelStandardEdition__c> editionsByKey = new Map<String, ProdSteelStandardEdition__c>();
        if (!neededEditionKeys.isEmpty()) {
            for (ProdSteelStandardEdition__c e : [
                SELECT Id, Key__c, Standard__c, Standard__r.Domain__c
                FROM ProdSteelStandardEdition__c
                WHERE Key__c IN :neededEditionKeys
            ]) {
                editionsByKey.put(e.Key__c, e);
            }
        }

        // 3) Upsert composites (dedup-safe)
        List<ProdSteelStandardComposite__c> compositesToUpsert = compositesByKey.values();
        upsert compositesToUpsert Key__c;
        compositesUpserted += compositesToUpsert.size();

        // reload ids into map (upsert fills Ids in list; sync back)
        Map<String, Id> compositeIdByKey = new Map<String, Id>();
        for (ProdSteelStandardComposite__c c : compositesToUpsert) {
            compositeIdByKey.put(c.Key__c, c.Id);
        }

        // 4) Build items (dedup-safe) — only for resolved editions
        Map<String, ProdSteelStandardCompositeItem__c> itemsByKey = new Map<String, ProdSteelStandardCompositeItem__c>();

        for (ProdSteelStandardLegacyMap__c legacy : scope) {
            if (!parsedByLegacyId.containsKey(legacy.Id)) continue;

            String compositeKey = buildCompositeKey(legacy.LegacyFacetGroup__c, legacy.LegacyStdName__c);
            Id compositeId = compositeIdByKey.get(compositeKey);
            if (compositeId == null) continue;

            List<StandardParseResult> parsed = parsedByLegacyId.get(legacy.Id);

            Integer order = 1;
            Integer resolvedInThisComposite = 0;

            for (StandardParseResult r : parsed) {
                if (r == null || String.isBlank(r.canonicalCode)) {
                    order++;
                    continue;
                }

                String editionKey = buildEditionKey(r.canonicalCode, r);
                ProdSteelStandardEdition__c edition = String.isBlank(editionKey) ? null : editionsByKey.get(editionKey);

                if (edition == null) {
                    // edition не знайдено — НЕ валимо композит, просто пропускаємо item
                    order++;
                    continue;
                }

                resolvedInThisComposite++;

                String itemKey = compositeKey + '__' + String.valueOf(order) + '__' + String.valueOf(edition.Id);

                if (!itemsByKey.containsKey(itemKey)) {
                    ProdSteelStandardCompositeItem__c item = new ProdSteelStandardCompositeItem__c();
                    item.Key__c = itemKey;
                    item.Composite__c = compositeId;
                    item.StandardEdition__c = edition.Id;
                    item.Order__c = order;
                    item.IsActive__c = true;
                    itemsByKey.put(itemKey, item);
                }

                order++;
            }

            if (resolvedInThisComposite == 0) {
                skippedNoResolvedEditions++;
            }
        }

        if (!itemsByKey.isEmpty()) {
            List<ProdSteelStandardCompositeItem__c> itemsToUpsert = itemsByKey.values();
            upsert itemsToUpsert Key__c;
            itemsUpserted += itemsToUpsert.size();
        }
    }

    global void finish(Database.BatchableContext ctx) {
        System.debug('ProdSteelStandardCompositeBatch FINISH: scanned=' + scanned
            + ', compositesUpserted=' + compositesUpserted
            + ', itemsUpserted=' + itemsUpserted
            + ', skippedBlankName=' + skippedBlankName
            + ', skippedNoParseItems=' + skippedNoParseItems
            + ', skippedNoResolvedEditions=' + skippedNoResolvedEditions);
    }

    // ----------------------------------------------------
    // Helpers
    // ----------------------------------------------------
    private static String facetGroupToDomain(String facetGroup) {
        String fg = (facetGroup == null) ? '' : facetGroup.trim().toUpperCase();
        if (fg == 'RAMP') return 'Wheels';
        if (fg == 'GAMP') return 'Tubes';
        // fallback
        return 'Tubes';
    }

    private static String buildCompositeKey(String facetGroup, String legacyText) {
        String fg = (facetGroup == null) ? 'UNK' : facetGroup.trim().toUpperCase();
        String norm = normalizeForKey(legacyText);
        return fg + '__' + norm;
    }

    private static String normalizeForKey(String s) {
        if (s == null) return 'NULL';
        String t = s.trim();

        // уніфікуємо роздільники композитів
        t = t.replace('\u2013', '-'); // en-dash
        t = t.replace('\u2014', '-'); // em-dash
        t = t.replace('\u2212', '-'); // minus
        t = t.replace('|', '_');      // на всяк випадок
        t = t.replace('/', ' / ');
        t = t.replace(';', ' ; ');
        t = t.replace(',', ' , ');

        // прибираємо зайві пробіли
        t = t.replaceAll('\\s+', ' ').trim();

        // ключ не повинен бути > 160 (External ID)
        // залишимо “хвіст” хешем, якщо треба
        if (t.length() > 140) {
            String prefix = t.substring(0, 140);
            String hash = EncodingUtil.convertToHex(Crypto.generateDigest('MD5', Blob.valueOf(t)));
            t = prefix + '_' + hash.substring(0, 16);
        }
        return t;
    }

    private static String safeTrim255(String s) {
        if (s == null) return null;
        String t = s.trim();
        if (t.length() <= 255) return t;
        return t.substring(0, 255);
    }

    private static String buildCompositeName(String domain, String legacyText255) {
        // Name Text(80)
        String d = (domain == null) ? '' : domain.trim();
        String t = (legacyText255 == null) ? '' : legacyText255.trim();
        String n = (d == '' ? '' : (d + ': ')) + t;
        if (n.length() <= 80) return n;
        return n.substring(0, 80);
    }

    /**
     * Будує Key__c для ProdSteelStandardEdition__c під вашу вже існуючу схему з '|'
     *
     * Приклади, які у вас вже є:
     *  EN_10210|BASE||1|
     *  EN_10210|2019|2019|1|
     *  API_5L|PSL1|||PSL1
     *  EN_13262|A2:2011|2004||A2:2011
     */
    private static String buildEditionKey(String canonicalCode, StandardParseResult r) {
        if (String.isBlank(canonicalCode) || r == null) return null;

        String code = canonicalCode.trim().toUpperCase();

        // editionCode:
        // - якщо є r.editionCode -> беремо його
        // - інакше якщо є year -> editionCode = year
        // - інакше BASE
        String editionCode = null;
        if (!String.isBlank(r.editionCode)) {
            editionCode = r.editionCode.trim();
        } else if (r.year != null) {
            editionCode = String.valueOf(r.year);
        } else {
            editionCode = 'BASE';
        }

        String yearStr = (r.year == null) ? '' : String.valueOf(r.year);
        String partStr = (r.part == null) ? '' : String.valueOf(r.part);

        // subSpec: якщо є subSpec -> він
        // інакше якщо editionCode типу PSL1/PSL2/ISO 3183 то можна дублювати у subSpec (як у вас вже в даних)
        String subSpec = '';
        if (!String.isBlank(r.subSpec)) {
            subSpec = r.subSpec.trim();
        } else {
            // якщо editionCode виглядає як підспек — кладемо в subSpec
            String ecU = editionCode.toUpperCase();
            if (ecU.startsWith('PSL') || ecU.startsWith('ISO') || ecU.startsWith('TC')) {
                subSpec = editionCode;
            } else if (ecU.contains('A')) {
                // A2:2011 теж у вас дублювався в SubSpec__c
                subSpec = editionCode;
            }
        }

        // Важливо: НЕ використовуємо тут Id стандарту, бо у вас вже ключі на Code.
        return code + '|' + editionCode + '|' + yearStr + '|' + partStr + '|' + subSpec;
    }
}
