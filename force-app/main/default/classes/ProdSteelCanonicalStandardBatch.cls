global class ProdSteelCanonicalStandardBatch
    implements Database.Batchable<SObject>, Database.Stateful {

    global Integer scanned = 0;
    global Integer basesUpserted = 0;
    global Integer editionsUpserted = 0;
    global Integer legacyUpdated = 0;

    global Database.QueryLocator start(Database.BatchableContext ctx) {
        return Database.getQueryLocator([
            SELECT Id,
                   ResolutionType__c,
                   LegacyStdName__c,
                   LegacyFacetGroup__c,
                   TargetStandard__c,
                   TargetEdition__c
            FROM ProdSteelStandardLegacyMap__c
            WHERE ResolutionType__c IN ('BASE','EDITION')
        ]);
    }

    global void execute(Database.BatchableContext ctx, List<ProdSteelStandardLegacyMap__c> scope) {

        scanned += scope.size();

        // 1) Collect canonical base codes + edition keys
        Set<String> baseCodes = new Set<String>();
        Set<String> editionKeys = new Set<String>();

        Map<Id, ParsedStd> parsedById = new Map<Id, ParsedStd>();

        for (ProdSteelStandardLegacyMap__c r : scope) {
            ParsedStd p = parseLegacy(r);
            parsedById.put(r.Id, p);

            if (!String.isBlank(p.baseCode)) {
                baseCodes.add(p.baseCode);
            }
            if (r.ResolutionType__c == 'EDITION' && !String.isBlank(p.baseCode)) {
                editionKeys.add(buildEditionKey(p.baseCode, p.editionCode, p.year, p.part, p.subSpec));
            }
        }

        // 2) Load existing bases
        Map<String, ProdSteelStandard__c> basesByCode = new Map<String, ProdSteelStandard__c>();
        if (!baseCodes.isEmpty()) {
            for (ProdSteelStandard__c s : [
                SELECT Id, Code__c, Domain__c
                FROM ProdSteelStandard__c
                WHERE Code__c IN :baseCodes
            ]) {
                basesByCode.put(s.Code__c, s);
            }
        }

        // 3) Insert missing bases
        List<ProdSteelStandard__c> toInsertBases = new List<ProdSteelStandard__c>();
        for (String code : baseCodes) {
            if (!basesByCode.containsKey(code)) {
                // domain is derived from facet group in legacy rows; but base can appear in both.
                // For now we create per baseCode per domain (simple: store one domain - the first we see).
                // To keep it deterministic, we'll store BOTH via separate records? Your object doesn't have domain in external id,
                // so we keep 1 record and prefer Wheels if seen.
                String domain = pickDomainForBase(code, scope, parsedById);
                toInsertBases.add(new ProdSteelStandard__c(
                    Code__c = code,
                    //Name = code,
                    Name = prettyName(code),
                    Domain__c = domain,
                    IsActive__c = true
                ));
            }
        }
        if (!toInsertBases.isEmpty()) {
            insert toInsertBases;
            basesUpserted += toInsertBases.size();
            for (ProdSteelStandard__c s : toInsertBases) {
                basesByCode.put(s.Code__c, s);
            }
        }

        // 4) Load existing editions
        Map<String, ProdSteelStandardEdition__c> editionsByKey = new Map<String, ProdSteelStandardEdition__c>();
        if (!editionKeys.isEmpty()) {
            for (ProdSteelStandardEdition__c e : [
                SELECT Id, Key__c
                FROM ProdSteelStandardEdition__c
                WHERE Key__c IN :editionKeys
            ]) {
                editionsByKey.put(e.Key__c, e);
            }
        }

        // 5) Insert missing editions
        List<ProdSteelStandardEdition__c> toInsertEditions = new List<ProdSteelStandardEdition__c>();
        for (String k : editionKeys) {
            if (editionsByKey.containsKey(k)) continue;

            KeyParts kp = splitEditionKey(k);
            ProdSteelStandard__c base = basesByCode.get(kp.baseCode);
            if (base == null) continue; // should not happen

            String editionName = kp.baseCode + ' ' + kp.editionCode;
            toInsertEditions.add(new ProdSteelStandardEdition__c(
                Standard__c = base.Id,
                Name = editionName.length() > 80 ? editionName.substring(0, 80) : editionName,
                EditionCode__c = kp.editionCode,
                Year__c = kp.year,
                Part__c = kp.part,
                SubSpec__c = kp.subSpec,
                Key__c = k,
                IsActive__c = true
            ));
        }
        if (!toInsertEditions.isEmpty()) {
            insert toInsertEditions;
            editionsUpserted += toInsertEditions.size();
            for (ProdSteelStandardEdition__c e : toInsertEditions) {
                editionsByKey.put(e.Key__c, e);
            }
        }

        // 6) Update legacy links
        List<ProdSteelStandardLegacyMap__c> updates = new List<ProdSteelStandardLegacyMap__c>();

        for (ProdSteelStandardLegacyMap__c r : scope) {
            ParsedStd p = parsedById.get(r.Id);
            if (p == null || String.isBlank(p.baseCode)) continue;

            ProdSteelStandard__c base = basesByCode.get(p.baseCode);
            if (base == null) continue;

            Boolean changed = false;

            if (r.TargetStandard__c != base.Id) {
                r.TargetStandard__c = base.Id;
                changed = true;
            }

            if (r.ResolutionType__c == 'EDITION') {
                String key = buildEditionKey(p.baseCode, p.editionCode, p.year, p.part, p.subSpec);
                ProdSteelStandardEdition__c ed = editionsByKey.get(key);
                if (ed != null && r.TargetEdition__c != ed.Id) {
                    r.TargetEdition__c = ed.Id;
                    changed = true;
                }
            }

            if (changed) {
                updates.add(r);
            }
        }

        if (!updates.isEmpty()) {
            update updates;
            legacyUpdated += updates.size();
        }
    }

    global void finish(Database.BatchableContext ctx) {
        System.debug('ProdSteelCanonicalStandardBatch FINISH: scanned=' + scanned +
            ', basesUpserted=' + basesUpserted +
            ', editionsUpserted=' + editionsUpserted +
            ', legacyUpdated=' + legacyUpdated);
    }

    // ===================== parsing / helpers =====================

    private class ParsedStd {
        String baseCode;
        String editionCode;
        Integer year;
        Integer part;
        String subSpec;
        String domain; // Wheels/Tubes
    }

    // Light parsing: canonical baseCode from MDT alias; edition parts via simple regex.
    private static final Pattern YEAR_PATTERN = Pattern.compile('\\b(19\\d{2}|20\\d{2})\\b');
    private static final Pattern PART_PATTERN = Pattern.compile('-(\\d{1,2})\\b');
    private static final Pattern SUBSPEC_PATTERN =
    Pattern.compile('(?i)\\b(PSL\\s*[12]|ISO\\s*3183|TC\\d+|A\\d(?::\\d{4})?)\\b');
    //private static final Pattern SUBSPEC_PATTERN = Pattern.compile('\\b(PSL\\s*[12]|ISO\\s*3183|TC\\d+|A\\d(?::\\d{4})?)\\b', Pattern.CASE_INSENSITIVE);

    private static ParsedStd parseLegacy(ProdSteelStandardLegacyMap__c r) {
        ParsedStd p = new ParsedStd();

        p.domain = facetToDomain(r.LegacyFacetGroup__c);

        String raw = normalizeSpaces(r.LegacyStdName__c);
        if (String.isBlank(raw)) return p;

        // Canonical base code by alias resolver (MDT)
        String base = SteelStandardAliasResolver.resolve(raw);
        if (String.isBlank(base)) {
            // fallback: try EN #####
            base = fallbackBase(raw);
        }
        p.baseCode = base;

        // EditionCode: keep it human-stable (year, A2:2011, PSL2, ISO 3183 etc.)
        // For BASE rows, we still can have year in name; but legacy already classifies BASE vs EDITION.
        // We'll parse anyway; if nothing - keep 'BASE'.
        p.editionCode = 'BASE';

        Matcher mYear = YEAR_PATTERN.matcher(raw);
        if (mYear.find()) {
            p.year = Integer.valueOf(mYear.group(1));
            p.editionCode = String.valueOf(p.year);
        }

        Matcher mSub = SUBSPEC_PATTERN.matcher(raw);
        if (mSub.find()) {
            String ss = normalizeSpaces(mSub.group(1)).toUpperCase();
            p.subSpec = ss;
            // prefer subSpec as editionCode if it's meaningful (PSL2 etc.)
            p.editionCode = ss;
        }

        Matcher mPart = PART_PATTERN.matcher(raw);
        if (mPart.find()) {
            p.part = Integer.valueOf(mPart.group(1));
        }

        return p;
    }

    private static String facetToDomain(String facetGroup) {
        String fg = facetGroup == null ? null : facetGroup.trim().toUpperCase();
        if (fg == 'RAMP') return 'Wheels';
        if (fg == 'GAMP') return 'Tubes';
        return null;
    }

    private static String normalizeSpaces(String s) {
        if (s == null) return null;
        s = s.replace('\u00A0', ' '); // NBSP
        s = s.trim();
        while (s.contains('  ')) s = s.replace('  ', ' ');
        return s;
    }

    private static String fallbackBase(String raw) {
        // very light fallback: "EN 13262" etc.
        //Pattern p = Pattern.compile('\\b(EN\\s*\\d{4,5})\\b', Pattern.CASE_INSENSITIVE);
        Pattern p = Pattern.compile('\\b(EN\\s*\\d{4,5})\\b');
        Matcher m = p.matcher(raw);
        if (m.find()) {
            return normalizeSpaces(m.group(1)).toUpperCase().replace(' ', '_'); // EN_13262
        }
        return null;
    }

    private static String buildEditionKey(String baseCode, String editionCode, Integer year, Integer part, String subSpec) {
        String ed = String.isBlank(editionCode) ? 'BASE' : editionCode.trim().toUpperCase();
        String y = (year == null) ? '' : String.valueOf(year);
        String pt = (part == null) ? '' : String.valueOf(part);
        String ss = (subSpec == null) ? '' : subSpec.trim().toUpperCase();
        // Stable, deterministic key
        return baseCode + '|' + ed + '|' + y + '|' + pt + '|' + ss;
    }

    private class KeyParts {
        String baseCode;
        String editionCode;
        Integer year;
        Integer part;
        String subSpec;
    }

    private static KeyParts splitEditionKey(String key) {
        KeyParts kp = new KeyParts();
        List<String> parts = key.split('\\|', -1);
        kp.baseCode = parts.size() > 0 ? parts[0] : null;
        kp.editionCode = parts.size() > 1 ? parts[1] : null;
        kp.year = (parts.size() > 2 && parts[2] != '') ? Integer.valueOf(parts[2]) : null;
        kp.part = (parts.size() > 3 && parts[3] != '') ? Integer.valueOf(parts[3]) : null;
        kp.subSpec = (parts.size() > 4 && parts[4] != '') ? parts[4] : null;
        return kp;
    }

    private static String pickDomainForBase(String baseCode, List<ProdSteelStandardLegacyMap__c> scope, Map<Id, ParsedStd> parsedById) {
        // Prefer Wheels if seen, else Tubes.
        Boolean seenWheels = false;
        Boolean seenTubes = false;

        for (ProdSteelStandardLegacyMap__c r : scope) {
            ParsedStd p = parsedById.get(r.Id);
            if (p == null || p.baseCode != baseCode) continue;
            if (p.domain == 'Wheels') seenWheels = true;
            if (p.domain == 'Tubes') seenTubes = true;
        }
        if (seenWheels) return 'Wheels';
        if (seenTubes) return 'Tubes';
        return 'Tubes';
    }

    private static String prettyName(String code) {
        if (String.isBlank(code)) return code;

        String s = code.trim();

        // basic: underscores to spaces
        s = s.replace('_', ' ');

        // optional prettifiers
        // Cyrillic-friendly
        if (s.startsWith('GOST ')) {
            s = s.replace('GOST ', 'ГОСТ ');
        }
        if (s.startsWith('DSTU GOST ')) {
            s = s.replace('DSTU GOST ', 'ДСТУ ');
        }

        // AAR M-107
        //if (s == 'AAR M107') s = 'AAR M-107';

        return s;
    }
}
//Database.executeBatch(new ProdSteelCanonicalStandardBatch(), 200);
