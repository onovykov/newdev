global with sharing class ProdSteelCanonicalGradeBatch
    implements Database.Batchable<SObject>, Database.Stateful {

    // ---- stats (optional, but helps to understand if it "does nothing") ----
    private Integer scanned = 0;
    private Integer parsedWithBase = 0;
    private Integer gradesUpserted = 0;
    private Integer legacyUpdated = 0;

    global Database.QueryLocator start(Database.BatchableContext bc) {
        // максимально "чисто": беремо ВСЕ активне, без прив’язки до ResolutionType__c
        return Database.getQueryLocator([
            SELECT Id,
                   LegacyName__c,
                   LegacyFacetCode__c,
                   IsActive__c,
                   TargetGrade__c
            FROM ProdSteelLegacyMap__c
            WHERE IsActive__c = true
        ]);
    }

    global void execute(Database.BatchableContext bc, List<SObject> scope) {
        List<ProdSteelLegacyMap__c> maps = (List<ProdSteelLegacyMap__c>) scope;
        scanned += maps.size();

        // mapId -> detected baseCode
        Map<Id, String> baseByMapId = new Map<Id, String>();

        // baseCode -> set of facets seen (RSMP/SGMP)
        Map<String, Set<String>> facetsByBase = new Map<String, Set<String>>();

        Set<String> baseCodes = new Set<String>();

        // ===== 1) PARSE LEGACY NAMES (fresh) =====
        for (ProdSteelLegacyMap__c m : maps) {
            String facet = normFacet(m.LegacyFacetCode__c);

            List<SteelParseResult> parses = ProdSteelParser.parse(m.LegacyName__c, facet);
            String base = chooseBestBaseCode(parses);

            if (String.isBlank(base)) {
                continue;
            }

            base = base.trim().toUpperCase();
            baseByMapId.put(m.Id, base);

            baseCodes.add(base);
            parsedWithBase++;

            if (!facetsByBase.containsKey(base)) {
                facetsByBase.put(base, new Set<String>());
            }
            if (!String.isBlank(facet)) {
                facetsByBase.get(base).add(facet);
            }
        }

        if (baseCodes.isEmpty()) {
            return; // реально нема що робити в цьому чанку
        }

        // ===== 2) LOAD EXISTING GRADES =====
        Map<String, ProdSteelGrade__c> gradeByCode = new Map<String, ProdSteelGrade__c>();
        for (ProdSteelGrade__c g : [
            SELECT Id, Code__c, SteelFamily__c, IsActive__c
            FROM ProdSteelGrade__c
            WHERE Code__c IN :baseCodes
        ]) {
            String code = (g.Code__c == null ? null : g.Code__c.trim().toUpperCase());
            if (!String.isBlank(code)) {
                gradeByCode.put(code, g);
            }
        }

        // ===== 3) CREATE/UPDATE CANONICAL GRADES (family via CMDT) =====
        List<ProdSteelGrade__c> toUpsert = new List<ProdSteelGrade__c>();

        for (String base : baseCodes) {
            // family: пробуємо facet-specific (якщо є), потім generic (facet=null)
            FamilyPick famPick = pickBestFamily(base, facetsByBase.get(base));

            ProdSteelGrade__c existing = gradeByCode.get(base);

            if (existing == null) {
                ProdSteelGrade__c gNew = new ProdSteelGrade__c();
                gNew.Name = base;
                gNew.Code__c = base;
                gNew.IsActive__c = true;

                // family заповнюємо, якщо знайшли не OTHER
                if (famPick != null && famPick.familyApi != 'OTHER') {
                    gNew.SteelFamily__c = famPick.familyApi;
                } else {
                    // можна залишити null або OTHER — я лишаю OTHER, щоб було явно
                    gNew.SteelFamily__c = 'OTHER';
                }

                toUpsert.add(gNew);
            } else {
                Boolean changed = false;

                // derived field: перераховуємо, якщо стало краще
                if (famPick != null && famPick.familyApi != 'OTHER') {
                    if (existing.SteelFamily__c == null
                        || existing.SteelFamily__c == 'OTHER'
                        || existing.SteelFamily__c != famPick.familyApi) {

                        existing.SteelFamily__c = famPick.familyApi;
                        changed = true;
                    }
                }

                // активність (на всяк)
                if (existing.IsActive__c != true) {
                    existing.IsActive__c = true;
                    changed = true;
                }

                if (changed) {
                    toUpsert.add(existing);
                }
            }
        }

        if (!toUpsert.isEmpty()) {
            upsert toUpsert ProdSteelGrade__c.Code__c;
            gradesUpserted += toUpsert.size();
        }

        // ===== 4) RELOAD GRADES FOR IDS =====
        // (потрібно, щоб оновити TargetGrade__c в legacy map)
        gradeByCode.clear();
        for (ProdSteelGrade__c g2 : [
            SELECT Id, Code__c
            FROM ProdSteelGrade__c
            WHERE Code__c IN :baseCodes
        ]) {
            String code2 = (g2.Code__c == null ? null : g2.Code__c.trim().toUpperCase());
            if (!String.isBlank(code2)) {
                gradeByCode.put(code2, g2);
            }
        }

        // ===== 5) UPDATE LEGACY MAP TARGETGRADE =====
        List<ProdSteelLegacyMap__c> mapsToUpdate = new List<ProdSteelLegacyMap__c>();

        for (ProdSteelLegacyMap__c m2 : maps) {
            String base2 = baseByMapId.get(m2.Id);
            if (String.isBlank(base2)) continue;

            ProdSteelGrade__c gLink = gradeByCode.get(base2);
            if (gLink == null) continue;

            if (m2.TargetGrade__c != gLink.Id) {
                m2.TargetGrade__c = gLink.Id;
                mapsToUpdate.add(m2);
            }
        }

        if (!mapsToUpdate.isEmpty()) {
            update mapsToUpdate;
            legacyUpdated += mapsToUpdate.size();
        }
    }

    global void finish(Database.BatchableContext bc) {
        System.debug('ProdSteelCanonicalGradeBatch FINISH: '
            + 'scanned=' + scanned
            + ', parsedWithBase=' + parsedWithBase
            + ', gradesUpserted=' + gradesUpserted
            + ', legacyUpdated=' + legacyUpdated
        );
    }

    // ============================================================
    // Helpers
    // ============================================================

    private static String normFacet(String facet) {
        return facet == null ? null : facet.trim().toUpperCase();
    }

    /**
     * Витягуємо baseCode "чисто": беремо найкращий запис з парсера,
     * але НЕ залежимо від ResolutionType__c.
     *
     * Пріоритет:
     *  1) GRADE з найбільшим confidence
     *  2) VARIANT з найбільшим confidence (бо variant теж містить baseCode)
     */
    private static String chooseBestBaseCode(List<SteelParseResult> parses) {
        if (parses == null || parses.isEmpty()) return null;

        SteelParseResult bestGrade = null;
        SteelParseResult bestVar = null;

        for (SteelParseResult r : parses) {
            if (r == null || String.isBlank(r.baseCode)) continue;

            if (r.type == 'GRADE') {
                if (bestGrade == null || r.confidence > bestGrade.confidence) bestGrade = r;
            } else if (r.type == 'VARIANT') {
                if (bestVar == null || r.confidence > bestVar.confidence) bestVar = r;
            }
        }

        if (bestGrade != null) return bestGrade.baseCode;
        if (bestVar != null) return bestVar.baseCode;
        return null;
    }

    private class FamilyPick {
        public String familyApi;
        public Decimal confidence;
        public String rule;
        public String facetUsed;
    }

    /**
     * Обираємо family для baseCode:
     *  - пробуємо всі facets, які зустрілися для цього baseCode (RSMP/SGMP),
     *    беремо найкращий (family != OTHER, max confidence)
     *  - якщо не вийшло — пробуємо generic (facet = null)
     */
    private FamilyPick pickBestFamily(String base, Set<String> facets) {
        FamilyPick best = null;

        // facet-specific
        if (facets != null && !facets.isEmpty()) {
            for (String f : facets) {
                String facet = normFacet(f);
                ProdSteelFamilyResolver.FamilyResult r =
                    ProdSteelFamilyResolver.resolve(base, facet);

                if (r == null) continue;
                if (r.familyApi == 'OTHER') continue;

                FamilyPick pick = new FamilyPick();
                pick.familyApi = r.familyApi;
                pick.confidence = r.confidence;
                pick.rule = r.rule;
                pick.facetUsed = facet;

                if (best == null || pick.confidence > best.confidence) {
                    best = pick;
                }
            }
        }

        // generic fallback
        if (best == null) {
            ProdSteelFamilyResolver.FamilyResult r2 =
                ProdSteelFamilyResolver.resolve(base, null);

            if (r2 != null && r2.familyApi != 'OTHER') {
                best = new FamilyPick();
                best.familyApi = r2.familyApi;
                best.confidence = r2.confidence;
                best.rule = r2.rule;
                best.facetUsed = null;
            }
        }

        return best;
    }
}