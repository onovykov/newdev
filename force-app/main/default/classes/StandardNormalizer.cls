public class StandardNormalizer {

    private static final Pattern RE_ONLY_DIGITS = Pattern.compile('^\\d+$');
    private static final Pattern RE_ONLY_DIGITS_AND_DASH = Pattern.compile('^[0-9\\-]+$');
    private static final Pattern RE_STARTS_WITH_DIGIT = Pattern.compile('^[0-9].*');
    private static final Pattern RE_SINGLE_LETTER = Pattern.compile('^[A-ZА-Я]$');

    private static final List<String> NOISE_WORDS = new List<String>{
        'ПРОТОКОЛ','ПРОЕКТ','КАРТА','ЧЕРТЕЖ',
        'SPEC','SPECIFICATION','TEST','ANNEX','DTS',
        'ТЕХНИЧЕСК','НЕСТАНДАРТ','ТРУБ','КВОТА'
    };

    public static Set<String> splitNormalizeAndFilter(String raw) {
        Set<String> result = new Set<String>();
        if (String.isBlank(raw)) return result;

        for (String part : raw.split('/')) {
            String s = normalize(part);
            if (isHardRejected(s)) continue;
            if (isSoftRejected(s)) continue;
            result.add(s);
        }
        return result;
    }

    public static String normalize(String raw) {
        if (String.isBlank(raw)) {
            return null;
        }

        // 1. Base cleanup
        String s = raw.trim().toUpperCase();

        // 2. Detect API SPEC early (CRITICAL)
        Boolean isApiSpec = s.startsWith('API SPEC');

        /*
        * 3. Noise words removal
        * SPEC is noise ONLY for non-API standards
        */
        if (!isApiSpec) {
            s = s.replaceAll('\\bSPECIFICATION\\b', ' ');
            s = s.replaceAll('\\bSPEC\\b', ' ');
        }

        // Common garbage / separators
        s = s.replaceAll('[,;]', ' ');
        s = s.replaceAll('\\s+/\\s+', '/'); // normalize slashes

        /*
        * 4. Normalize year formats
        *  -2012, :2012 → 2012
        */
        s = s.replaceAll('[:\\-](\\d{4})', ' $1');

        /*
        * 5. Remove everything except:
        *   - latin letters
        *   - cyrillic letters (just in case)
        *   - digits
        *   - dash
        *   - slash
        *   - spaces
        */
        s = s.replaceAll('[^A-Z0-9А-Я\\-\\/\\s]', ' ');

        // 6. Collapse whitespace
        s = s.replaceAll('\\s+', ' ').trim();

        // 7. Final sanity check
        if (s.length() < 3) {
            return null;
        }

        return s;
    }

    private static Boolean isHardRejected(String s) {
        if (String.isBlank(s)) return true;
        if (s.length() < 3) return true;

        if (RE_ONLY_DIGITS.matcher(s).matches()) return true;
        if (RE_ONLY_DIGITS_AND_DASH.matcher(s).matches()) return true;
        if (RE_STARTS_WITH_DIGIT.matcher(s).matches()) return true;
        if (RE_SINGLE_LETTER.matcher(s).matches()) return true;

        if (s.startsWith('№')) return true;
        return false;
    }

    private static Boolean isSoftRejected(String s) {
        for (String w : NOISE_WORDS) {
            if (s.contains(w)) return true;
        }
        return false;
    }
}