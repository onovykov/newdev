public with sharing class ProdSteelParser {

    // ================= CACHE =================

    private static Boolean isLoaded = false;

    private static List<AliasRule> aliasRules = new List<AliasRule>();
    private static List<VariantRule> variantRules = new List<VariantRule>();
    private static List<ExtensionRule> extensionRules = new List<ExtensionRule>();

    // ================= PUBLIC API =================

    public static List<SteelParseResult> parse(String rawName, String facetCode) {

        loadIfNeeded();

        List<SteelParseResult> results = new List<SteelParseResult>();

        if (String.isBlank(rawName)) {
            results.add(SteelParseResult.trash(null, 'empty-name'));
            return results;
        }

        String normalized = normalize(rawName);
        List<String> tokens = splitTokens(normalized);

        for (String token : tokens) {
            String t = token.trim();
            if (String.isBlank(t)) continue;

            AliasRule alias = findAlias(t, facetCode);

            if (alias == null) {
                results.add(SteelParseResult.unknown(t, 'alias:not-found'));
                continue;
            }

            String canonical = alias.canonical;

            Set<String> extensions = new Set<String>();
            for (ExtensionRule er : extensionRules) {
                if (er.pattern.matcher(t).find()) {
                    extensions.add(er.code);
                }
            }

            Boolean isVariant = false;
            for (VariantRule vr : variantRules) {
                if (vr.facet == facetCode && vr.canonical == canonical) {
                    if (vr.pattern.matcher(t).find()) {
                        isVariant = true;
                        break;
                    }
                }
            }

            if (!extensions.isEmpty() || isVariant) {
                results.add(
                    SteelParseResult.variant(
                        t,
                        canonical,
                        String.join(new List<String>(extensions), '+'),
                        null,
                        null,
                        'mdt',
                        0.95
                    )
                );
            } else {
                results.add(
                    SteelParseResult.grade(
                        t,
                        canonical,
                        'mdt',
                        0.85
                    )
                );
            }
        }

        return results;
    }

    // ================= CORE =================

    private static AliasRule findAlias(String text, String facet) {
        for (AliasRule r : aliasRules) {
            if (r.facet == facet && r.pattern.matcher(text).find()) {
                return r;
            }
        }
        return null;
    }

    // ================= LOADING =================

    private static void loadIfNeeded() {
        if (isLoaded) return;
        isLoaded = true;

        for (SteelGradeAlias__mdt m :
            [SELECT Regex__c, CanonicalGrade__c, ERP_FacetGroup__c
             FROM SteelGradeAlias__mdt
             WHERE IsActive__c = true
             ORDER BY Priority__c DESC]) {

            AliasRule r = new AliasRule();
            r.pattern = Pattern.compile(addCaseInsensitive(m.Regex__c));
            r.canonical = m.CanonicalGrade__c;
            r.facet = m.ERP_FacetGroup__c;
            aliasRules.add(r);
        }

        for (SteelGradeVariant__mdt m :
            [SELECT VariantRegex__c, CanonicalGrade__c, ERP_FacetGroup__c
             FROM SteelGradeVariant__mdt
             WHERE IsActive__c = true
             ORDER BY Priority__c DESC]) {

            VariantRule r = new VariantRule();
            r.pattern = Pattern.compile(addCaseInsensitive(m.VariantRegex__c));
            r.canonical = m.CanonicalGrade__c;
            r.facet = m.ERP_FacetGroup__c;
            variantRules.add(r);
        }

        for (SteelGradeExtension__mdt m :
            [SELECT Regex__c, ExtensionCode__c
             FROM SteelGradeExtension__mdt
             WHERE IsActive__c = true
             ORDER BY Priority__c DESC]) {

            ExtensionRule r = new ExtensionRule();
            r.pattern = Pattern.compile(addCaseInsensitive(m.Regex__c));
            r.code = m.ExtensionCode__c;
            extensionRules.add(r);
        }
    }

    // ================= HELPERS =================

    private static String addCaseInsensitive(String r) {
        if (r == null) return r;
        if (r.startsWith('(?i)')) return r;
        return '(?i)' + r;
    }

    private static String normalize(String s) {
        s = s.toUpperCase();
        s = s.replace(',', ' ');
        s = s.replace('(', ' ');
        s = s.replace(')', ' ');
        s = s.replace('[', ' ');
        s = s.replace(']', ' ');
        s = s.replaceAll('\\s+', ' ');
        return s.trim();
    }

    private static List<String> splitTokens(String input) {
        List<String> parts = new List<String>();
        for (String p : input.split('/')) {
            parts.add(p.trim());
        }
        return parts;
    }

    // ================= INTERNAL DTO =================

    private class AliasRule {
        Pattern pattern;
        String canonical;
        String facet;
    }

    private class VariantRule {
        Pattern pattern;
        String canonical;
        String facet;
    }

    private class ExtensionRule {
        Pattern pattern;
        String code;
    }
}