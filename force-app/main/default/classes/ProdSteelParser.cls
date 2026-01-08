public with sharing class ProdSteelParser {
    // ================== REGEX ==================

    // Wheels (RSMP): ER7, ER8, ER9, R7, R7T, R8T, R9T, RSW1
    private static final Pattern WHEEL_GRADE_PATTERN =
        Pattern.compile('(?i)\\b(ER\\d|R\\dT?|RSW\\d)\\b');

    // Tubes (SGMP): S355, S355J2H, P355N, E355
    private static final Pattern TUBE_GRADE_PATTERN =
        Pattern.compile('(?i)\\b([SEP]\\d{3}[A-Z0-9]*)\\b');

    // Alloy: 42CrMo4
    private static final Pattern ALLOY_GRADE_PATTERN =
        Pattern.compile('(?i)\\b(\\d{2}CRMO\\d)\\b');

    // Variants: +N, +SR, TC1, TC2, BTG
    private static final Pattern VARIANT_PATTERN =
        Pattern.compile('(?i)(\\+N|\\+SR|TC1|TC2|BTG)');

    // Categories: CAT.1 / КАТ.2
    private static final Pattern CATEGORY_PATTERN =
        Pattern.compile('(?i)(CAT\\.?\\s*(\\d)|КАТ\\.?\\s*(\\d))');

    // Explicit trash
    private static final List<Pattern> TRASH_PATTERNS = new List<Pattern>{
        Pattern.compile('(?i)^N/A$'),
        Pattern.compile('(?i)^ПО\\s+ТУ.*'),
        Pattern.compile('(?i)^ПО\\s+СПЕЦ.*'),
        Pattern.compile('(?i)^ПО\\s+СПЕЦИФИКАЦИИ.*'),
        Pattern.compile('(?i)^ACCORDING\\s+TO.*'),
        Pattern.compile('(?i)^АКТИВНО$')
    };

    // ================== API ==================

    public static List<SteelParseResult> parse(
        String rawName,
        String facetCode // RSMP / SGMP
    ) {
        List<SteelParseResult> results = new List<SteelParseResult>();

        if (String.isBlank(rawName)) {
            results.add(
                SteelParseResult.trash(null, 'empty-name')
            );
            return results;
        }

        String normalized = normalize(rawName);
        List<String> tokens = splitTokens(normalized);

        for (String token : tokens) {
            String t = token.trim();
            if (String.isBlank(t)) continue;

            // 1️⃣ Trash
            if (isTrash(t)) {
                results.add(
                    SteelParseResult.trash(t, 'trash:pattern')
                );
                continue;
            }

            // 2️⃣ Detect base grade
            String baseCode = detectBaseGrade(t, facetCode);

            if (baseCode == null) {
                results.add(
                    SteelParseResult.unknown(t, 'base:not-found')
                );
                continue;
            }

            baseCode = normalizeBaseCode(baseCode);

            // 3️⃣ Variant
            String variantCode = null;
            Matcher vm = VARIANT_PATTERN.matcher(t);
            if (vm.find()) {
                variantCode = vm.group(1).toUpperCase();
            }

            // 4️⃣ Category
            Integer category = null;
            Matcher cm = CATEGORY_PATTERN.matcher(t);
            if (cm.find()) {
                String c = cm.group(2) != null ? cm.group(2) : cm.group(3);
                if (c != null) category = Integer.valueOf(c);
            }

            // 5️⃣ Result
            if (variantCode != null) {
                results.add(
                    SteelParseResult.variant(
                        t,
                        baseCode,
                        variantCode,
                        category,
                        null,
                        'variant:regex',
                        0.95
                    )
                );
            } else {
                results.add(
                    SteelParseResult.grade(
                        t,
                        baseCode,
                        'grade:base',
                        0.80
                    )
                );
            }
        }

        return results;
    }

    // ================== CORE LOGIC ==================

    private static String detectBaseGrade(String text, String facetCode) {

        // Wheels first if RSMP
        if (facetCode == 'RSMP') {
            Matcher w = WHEEL_GRADE_PATTERN.matcher(text);
            if (w.find()) return w.group(1).toUpperCase();
        }

        // Tubes
        Matcher t = TUBE_GRADE_PATTERN.matcher(text);
        if (t.find()) return t.group(1).toUpperCase();

        // Alloy
        Matcher a = ALLOY_GRADE_PATTERN.matcher(text);
        if (a.find()) return a.group(1).toUpperCase();

        // Fallback for wheels
        Matcher w2 = WHEEL_GRADE_PATTERN.matcher(text);
        if (w2.find()) return w2.group(1).toUpperCase();

        return null;
    }

    // ================== HELPERS ==================

    private static String normalize(String input) {
        String s = input.toUpperCase();
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

    private static Boolean isTrash(String token) {
        for (Pattern p : TRASH_PATTERNS) {
            if (p.matcher(token).matches()) return true;
        }
        return false;
    }

    private static String normalizeBaseCode(String base) {
        if (base == '42CRM04' || base == '42CRMO4') {
            return '42CRMO4';
        }
        return base;
    }
}