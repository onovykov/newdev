public with sharing class RSMPClassifier {

    // =========================
    // Result DTO
    // =========================
    public class ClassificationResult {
        public String rawText;
        public String resolutionType;   // GRADE / VARIANT / EXTENSION / TRASH / UNKNOWN
        public String resolutionRule;   // regex або reason
        public String standardText;     // ER7, 42CRMO4, EA1N
        public String baseCode;         

        public Boolean isUnknown() {
            return resolutionType == 'UNKNOWN';
        }

        public Boolean isTrash() {
            return resolutionType == 'TRASH';
        }
    }

    // =========================
    // Public API
    // =========================
    public ClassificationResult classify(String raw) {
        if (matchesTrash(raw)) {
            ClassificationResult r = new ClassificationResult();
            r.rawText = raw;
            r.resolutionType = 'TRASH';
            r.resolutionRule = 'TRASH_PATTERN';
            return r;
        }

        ClassificationResult res = new ClassificationResult();

        if (String.isBlank(raw)) {
            return unknown();
        }

        String text = normalize(raw);

        // 1️⃣ BASE (GRADE)
        ClassificationResult base = matchBase(text);
        if (base != null) {
            return base;
        }

        // 2️⃣ VARIANT / EXTENSION — буде наступним етапом
        // (поки intentionally не робимо)

        return unknown();
    }

    // =========================
    // BASE resolution
    // =========================
    private ClassificationResult matchBase(String text) {

        List<PatternSetting__c> patterns = PatternSettingCache.getRSMPBasePatterns();

        for (PatternSetting__c p : patterns) {

            if (String.isBlank(p.Regex__c)) {
                continue;
            }

            Pattern pat = Pattern.compile(p.Regex__c);
            Matcher m = pat.matcher(text);

            if (m.find()) {

                String standard = extractStandardText(m);

                if (String.isBlank(standard)) {
                    continue; // не ризикуємо
                }

                ClassificationResult r = new ClassificationResult();
                r.resolutionType = 'GRADE';
                r.resolutionRule = 'BASE:' + p.Regex__c;
                r.standardText = standard;

                return r;
            }
        }

        return null;
    }

    // =========================
    // Helpers
    // =========================
    private static Boolean matchesTrash(String text) {
        for (PatternSetting__c p : PatternSettingCache.getRSMPTrashPatterns()) {
            if (Pattern.matches(p.Regex__c, text)) {
                return true;
            }
        }
        return false;
    }

    private static ClassificationResult unknown() {
        ClassificationResult r = new ClassificationResult();
        r.resolutionType = 'UNKNOWN';
        r.resolutionRule = 'NO_PATTERN_MATCH';
        r.standardText = null;
        return r;
    }

    /**
     * Витягуємо StandardText ТІЛЬКИ з capture groups
     * (ER)(7) → ER7
     * (45)(Х)(Н) → 45ХН
     */
    private static String extractStandardText(Matcher m) {

        List<String> parts = new List<String>();

        Integer groupCount = m.groupCount();
        for (Integer i = 1; i <= groupCount; i++) {
            String g = m.group(i);
            if (!String.isBlank(g)) {
                parts.add(g.trim());
            }
        }

        if (parts.isEmpty()) {
            return null;
        }

        return String.join(parts, '');
    }

    /**
     * Нормалізація вхідного тексту:
     * - прибираємо [MS], [GMH] тощо
     * - уніфікуємо пробіли
     */
    private static String normalize(String raw) {

        String t = raw;

        // викидаємо сміття в квадратних дужках
        t = t.replaceAll('\\[[^\\]]+\\]', ' ');

        // уніфікуємо пробіли
        t = t.replaceAll('\\s+', ' ').trim();

        return t;
    }
}
