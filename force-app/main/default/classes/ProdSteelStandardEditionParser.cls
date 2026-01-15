public class ProdSteelStandardEditionParser {

    public static EditionParseResult parse(String input) {
        if (String.isBlank(input)) return null;

        String s = input.toUpperCase();

        Integer year = extractYear(s);
        Integer part = extractPart(s);
        String sub = extractSubSpec(s);

        if (year == null && sub == null)
            return null;

        String code = '';
        if (year != null)
            code = String.valueOf(year);

        if (s.contains('+A')) {
            Integer p = s.indexOf('+A');
            if (p > 0)
                code += s.substring(p, Math.min(p + 3, s.length()));
        }

        if (sub != null) {
            if (code != '') code += ' ';
            code += sub;
        }

        EditionParseResult r = new EditionParseResult();
        r.year = year;
        r.part = part;
        r.subSpec = sub;
        r.editionCode = code;
        r.displayName = code;

        return r;
    }

    private static Integer extractYear(String s) {
        for (Integer i = 0; i < s.length() - 3; i++) {
            String t = s.substring(i, i + 4);
            if (t.isNumeric()) {
                Integer y = Integer.valueOf(t);
                if (y > 1900 && y < 2100)
                    return y;
            }
        }
        return null;
    }

    private static Integer extractPart(String s) {
        Integer p = s.indexOf('-');
        if (p > 0 && p + 2 < s.length()) {
            String t = s.substring(p + 1, p + 2);
            if (t.isNumeric())
                return Integer.valueOf(t);
        }
        return null;
    }

    private static String extractSubSpec(String s) {
        if (s.contains('PSL1')) return 'PSL1';
        if (s.contains('PSL2')) return 'PSL2';
        if (s.contains('ISO 3183')) return 'ISO 3183';
        return null;
    }
}