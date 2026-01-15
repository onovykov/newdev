public with sharing class RSMPClassifier {
    // ---------------------------
    // DTO
    // ---------------------------

    public class Result {
        public String baseCode;
        public String baseRegex;

        public String variantCode;
        public String variantRegex;

        public Set<String> extensionCodes = new Set<String>();
        public Set<String> extensionRegexes = new Set<String>();

        public Boolean isUnknown() {
            return baseCode == null;
        }

        public String getRule() {
            List<String> parts = new List<String>();

            if (baseRegex != null) parts.add('BASE:' + baseRegex);
            if (variantRegex != null) parts.add('VARIANT:' + variantRegex);

            for (String r : extensionRegexes) {
                parts.add('EXT:' + r);
            }

            return String.join(parts, ' | ');
        }

        public String getStandardText() {
            List<String> parts = new List<String>();

            if (baseCode != null) parts.add(baseCode);
            if (variantCode != null) parts.add(variantCode);
            for (String e : extensionCodes) parts.add(e);

            return String.join(parts, '|');
        }
    }

    // ---------------------------
    // Cached patterns
    // ---------------------------
    private static List<PatternSetting__c> basePatterns;
    private static List<PatternSetting__c> variantPatterns;
    private static List<PatternSetting__c> extensionPatterns;

    private static void loadPatterns() {
        if (basePatterns != null) return;

        List<PatternSetting__c> rows = [
            SELECT Regex__c, Type__c
            FROM PatternSetting__c
            WHERE
                ObjectType__c = 'SteelGrade'
                AND Domain__c = 'Wheels'
                AND ERP_FacetGroup__c = 'RSMP'
        ];

        basePatterns = new List<PatternSetting__c>();
        variantPatterns = new List<PatternSetting__c>();
        extensionPatterns = new List<PatternSetting__c>();

        for (PatternSetting__c p : rows) {
            if (p.Type__c == 'Base') {
                basePatterns.add(p);
            } else if (p.Type__c == 'Variant') {
                variantPatterns.add(p);
            } else if (p.Type__c == 'Extension') {
                extensionPatterns.add(p);
            }
        }
    }

    // ---------------------------
    // Public API
    // ---------------------------
    public static Result classify(String raw) {
        loadPatterns();

        Result r = new Result();
        String text = raw == null ? '' : raw;

        // -------------------
        // BASE
        // -------------------
        for (PatternSetting__c p : basePatterns) {
            String regex = '(?i)' + p.Regex__c;
            if (Pattern.matches(regex, text)) {
                r.baseRegex = p.Regex__c;
                r.baseCode = extractMatchedText(p.Regex__c, text);
                break; // exactly one base
            }
        }

        // -------------------
        // VARIANT
        // -------------------
        for (PatternSetting__c p : variantPatterns) {
            String regex = '(?i)' + p.Regex__c;
            if (Pattern.matches(regex, text)) {
                r.variantRegex = p.Regex__c;
                r.variantCode = extractMatchedText(p.Regex__c, text);
                break; // RSMP supports single variant
            }
        }

        // -------------------
        // EXTENSIONS
        // -------------------
        for (PatternSetting__c p : extensionPatterns) {
            String regex = '(?i)' + p.Regex__c;
            if (Pattern.matches(regex, text)) {
                r.extensionRegexes.add(p.Regex__c);
                r.extensionCodes.add(extractMatchedText(p.Regex__c, text));
            }
        }

        return r;
    }

    // ---------------------------
    // Utils
    // ---------------------------
    private static String extractMatchedText(String regex, String text) {
        try {
            Pattern p = Pattern.compile('(?i)' + regex);
            Matcher m = p.matcher(text);

            if (m.find()) {
                return normalize(m.group(0));
            }
        } catch (Exception e) {
            // bad regex should not break ingestion
        }
        return null;
    }

    private static String normalize(String s) {
        if (s == null) return null;
        return s.trim().toUpperCase();
    }
}