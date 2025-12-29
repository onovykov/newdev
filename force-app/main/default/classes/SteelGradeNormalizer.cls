public with sharing class SteelGradeNormalizer {

    // ===============================
    // RESULT DTO
    // ===============================
    public class Result {
        public Set<String> grades = new Set<String>();
        public Set<String> attributes = new Set<String>();
        public Boolean isGarbage = false;

        public Result markGarbage() {
            this.isGarbage = true;
            return this;
        }

        public override String toString() {
            return 'grades=' + grades + ' attrs=' + attributes + ' garbage=' + isGarbage;
        }
    }

    // ===============================
    // v1.1 CONFIG: HARD GARBAGE
    // ===============================
    private static final Set<String> HARD_GARBAGE_VALUES = new Set<String>{
        'N/A', 'NA', '00', '0', '-', '—', 'NONE', 'NULL'
    };

    // ===============================
    // v1.1 CONFIG: JUNK TOKENS (supplier/notes)
    // ===============================
    private static final Set<String> JUNK_TOKENS = new Set<String>{
        // RU/UA
        'ОЭМК','УРАЛСТАЛЬ','УРАЛ','ОБТОЧКА','ОБТОЧ','ЗАТОЧКА','ЗАТОЧ',
        'ММК','НЛМК','СЕВЕРСТАЛЬ','АЗОВСТАЛЬ','ЕВРАЗ','МЕЧЕЛ',

        // EN
        'TURNED','MACHINED','GRIND','GRINDED','GRINDING',
        'SUPPLIER','PLANT','MILL',

        // very common noise
        'MM'
    };

    private static Boolean isJunkToken(String tokenUpper) {
        if (String.isBlank(tokenUpper)) return true;

        String t = tokenUpper;

        if (JUNK_TOKENS.contains(t)) return true;

        // partial junk patterns
        if (t.contains('ОЭМК')) return true;
        if (t.contains('УРАЛ')) return true;
        if (t.contains('ОБТОЧ')) return true;
        if (t.contains('ЗАТОЧ')) return true;

        return false;
    }

    // ===============================
    // v1.1 PREPROCESS
    // ===============================
    private static String preprocess(String raw) {
        if (raw == null) return null;

        String s = raw.toUpperCase().trim();

        // remove bracket comments entirely
        s = s.replaceAll('\\(.*?\\)', ' ');

        // '+' is meaningless for us
        s = s.replace('+', ' ');

        // normalize OR separators to spaces
        s = s.replace('/', ' ');
        s = s.replace(',', ' ');
        s = s.replace(';', ' ');
        s = s.replace('|', ' ');

        // normalize ST forms: "ST 52.0" -> "ST52.0"
        s = s.replaceAll('\\bST\\s+(\\d)', 'ST$1');

        // collapse spaces
        s = s.replaceAll('\\s+', ' ').trim();

        return s;
    }

    // ===============================
    // TOKEN CLASSIFICATION HELPERS
    // ===============================

    private static Boolean isPureNumber(String t) {
        return Pattern.matches('^\\d{1,3}$', t); // allow 3 digits (355)
    }

    private static Boolean isLetterDigitGrade(String t) {
        // E355, S355, P355, X52, L360MB, L290MB, ST52.0, etc.
        return Pattern.matches('^[A-Z]{1,5}\\d{2,4}([A-Z]{0,5})?(\\.\\d)?$', t);
    }

    private static Boolean isPureAttributeToken(String t) {
        // N, NH, NL, QT, AR, SR, SP, PS, HFA, GSF, etc.
        return Pattern.matches('^[A-ZА-Я]{1,6}\\d{0,3}[A-ZА-Я]{0,6}$', t);
    }

    // ===============================
    // v1.1 MAIN NORMALIZER
    // ===============================
    public static Result normalize(String raw) {
        if (String.isBlank(raw)) {
            return new Result().markGarbage();
        }

        String s = preprocess(raw);
        if (String.isBlank(s)) {
            return new Result().markGarbage();
        }

        // hard garbage by value
        if (HARD_GARBAGE_VALUES.contains(s)) {
            return new Result().markGarbage();
        }

        Result res = new Result();

        // tokenize by space (we already normalized OR separators)
        List<String> tokens = s.split(' ');

        for (String token : tokens) {
            if (String.isBlank(token)) continue;

            String t = token.trim().toUpperCase();

            if (String.isBlank(t)) continue;
            if (HARD_GARBAGE_VALUES.contains(t)) continue;
            if (isJunkToken(t)) continue;

            // ---------------------------
            // RANGE: 10-20 or 10-20Г2 or 3-20SP
            // ---------------------------
            Matcher mRange = Pattern.compile('^(\\d{1,3})-(\\d{1,3})([A-ZА-Я0-9]{1,10})?$').matcher(t);
            if (mRange.matches()) {
                res.grades.add(mRange.group(1));
                res.grades.add(mRange.group(2));

                if (mRange.group(3) != null && !isJunkToken(mRange.group(3))) {
                    // treat suffix as attribute (Г, Г2, СП, ПС ...)
                    res.attributes.add(mRange.group(3));
                }
                continue;
            }

            // ---------------------------
            // NUM + ATTR (legacy style): 17G1SU / 09G2S / 20СП
            // grade = leading digits, attr = rest
            // ---------------------------
            Matcher mNumAttr = Pattern.compile('^(\\d{1,3})([A-ZА-Я][A-ZА-Я0-9]{0,10})$').matcher(t);
            if (mNumAttr.matches()) {
                res.grades.add(mNumAttr.group(1));
                String attr = mNumAttr.group(2);

                if (!isJunkToken(attr)) {
                    res.attributes.add(attr);
                }
                continue;
            }

            // ---------------------------
            // LETTER+DIGIT grade with optional suffix attribute:
            // P355NH -> grade P355, attr NH
            // X52N   -> grade X52, attr N
            // ---------------------------
            // ---- LxxxMB as whole grade (not suffix split) ----
            if (Pattern.matches('^L\\d{3}MB$', t)) {
                res.grades.add(t);
                continue;
            }

            // LETTER+DIGIT grade with optional suffix attribute:
            Matcher mEnSuffix = Pattern.compile('^([A-Z]{1,5}\\d{2,4})([A-Z]{1,4})$').matcher(t);
            if (mEnSuffix.matches()) {
                String g = mEnSuffix.group(1);
                String a = mEnSuffix.group(2);

                res.grades.add(g);
                if (!isJunkToken(a)) {
                    res.attributes.add(a);
                }
                continue;
            }

            // ---------------------------
            // STxx(.x)
            // ---------------------------
            if (Pattern.matches('^ST\\d{2}(\\.\\d)?$', t)) {
                res.grades.add(t);
                continue;
            }

            // ---------------------------
            // "normal" grades like E355, S355, P355, L360MB, L290MB, X52 ...
            // ---------------------------
            if (isLetterDigitGrade(t)) {
                res.grades.add(t);
                continue;
            }

            // ---------------------------
            // pure number grade: 10, 20, 355
            // ---------------------------
            if (isPureNumber(t)) {
                res.grades.add(t);
                continue;
            }

            // ---------------------------
            // attribute fallback: N, NH, QT, SP, PS, HFA, ...
            // but exclude junk tokens
            // ---------------------------
            if (isPureAttributeToken(t) && !isJunkToken(t)) {
                // avoid single-letter noise like stray "A" if you want stricter
                // (left permissive for now)
                res.attributes.add(t);
                continue;
            }

            // else: ignore unknown token (treat as noise)
        }

        res.isGarbage = res.grades.isEmpty();
        return res;
    }

    //--- Overload ---
    public static Result normalize(String raw, String facetCode) {
        if (facetCode == 'RSMP') {
            return normalizeRSMP(raw);
        }
        // default = SGMP
        return normalize(raw);
    }

// ===============================
// RSMP NORMALIZER (SEPARATE BRANCH)
// ===============================
public static Result normalizeRSMP(String raw) {
    Result res = new Result();

    if (String.isBlank(raw)) {
        return res.markGarbage();
    }

    String s = raw.toUpperCase().trim();

    // ---------------------------
    // 1. Drop everything in [] and ()
    // ---------------------------
    s = s.replaceAll('\\[.*?\\]', ' ');
    s = s.replaceAll('\\(.*?\\)', ' ');


// BEFORE separator normalization
if (s.contains('CLASS D+')) {
    res.grades.add('CLASS D+');
    return res;
}
    // ---------------------------
    // 2. Normalize separators
    // ---------------------------
    s = s.replace(';', ' ');
    s = s.replace(',', ' ');
    s = s.replace('|', ' ');
    s = s.replace('/', ' ');
    s = s.replace('+', ' ');

    s = s.replaceAll('\\s+', ' ').trim();
    if (String.isBlank(s)) {
        return res.markGarbage();
    }

    // ---------------------------
    // 3. Explicit RSMP garbage
    // ---------------------------
    Set<String> RSMP_GARBAGE = new Set<String>{
        'ВА', 'КОЛЕС', 'ВАК', 'КП', 'ПО', 'ПОТУ', 'ТУ',
        'ПОСПЕЦИФИКАЦИИ', 'СТАЛЬ', 'МАРКИ'
    };

    // ---------------------------
    // 4. Tokenize
    // ---------------------------
    List<String> tokens = s.split(' ');

    for (String token : tokens) {
        if (String.isBlank(token)) continue;

        String t = token.trim();
        
        // Cyrillic chemistry indexes
        if (t.endsWith('ХН') || t.endsWith('XN')) {
            String baseNum = t.substring(0, t.length() - 2);
            if (isPureNumber(baseNum)) {
                res.grades.add(baseNum);
                res.attributes.add('CrNi');
                continue;
            }
        }        
        // RSMP: normalize cyrillic lookalikes to latin
        t = t
            .replace('А','A')
            .replace('В','B')
            .replace('С','C')
            .replace('М','M')
            .replace('Т','T')
            .replace('Н','N')
            .replace('К','K');

        if (String.isBlank(t)) continue;
// Class X / EA1N
Matcher mClassEa = Pattern.compile(
    '^CLASS\\s+([A-Z]\\+?)\\s*/\\s*(EA1N)$'
).matcher(t);

if (t == 'EA1N') {
    res.grades.add('EA1N');
    continue;
}

Matcher mCmod = Pattern.compile('^C-MOD-(\\d+)$').matcher(t);
if (mCmod.matches()) {
    res.grades.add('CLASS C');
    res.attributes.add('MOD' + mCmod.group(1));
    continue;
}

if (Pattern.matches('^A\\d+$', t)) {
    res.grades.add('CLASS ' + t);
    continue;
}
/*
if (Pattern.matches('^CLASS\\s+D\\+$', t)) {
    res.grades.add('CLASS D+');
    continue;
}

if (t == 'Class D+') {
    res.grades.add('Class D+');
    continue;
}

if (Pattern.matches('^CLASS\\s+[A-Z]\\+$', t)) {
    res.grades.add(t);
    continue;
}
*/
Matcher mIrs = Pattern.compile('^IRS\\s+R-(\\d+)-(\\d+)$').matcher(t);
if (mIrs.matches()) {
    res.grades.add('R' + mIrs.group(1));
    res.attributes.add(mIrs.group(2));
    continue;
}

if (t == 'RSW1') {
    res.grades.add('RSW1');
    continue;
}

/*
if (t.endsWith('ХН')) {
    String baseNum = t.substring(0, t.length() - 2);
    if (isPureNumber(baseNum)) {
        res.grades.add(baseNum);
        res.attributes.add('CrNi');
        continue;
    }
}
*/

        if (mClassEa.matches()) {
            res.grades.add('CLASS ' + mClassEa.group(1));
            res.grades.add('EA1N');
            continue;
        }

        // 1️⃣ RSMP garbage FIRST
        if (RSMP_GARBAGE.contains(t)) continue;

        // 2️⃣ CLASS A, CLASS B
        if (Pattern.matches('^CLASS\\s*[A-Z]$', t)) {
            res.grades.add(t.replaceAll('\\s+', ' '));
            //res.grades.add(t.replace(' ', ''));
            continue;
        }

        // 3️⃣ single-letter → CLASS
        if (Pattern.matches('^[A-Z]$', t)) {
            res.grades.add('CLASS ' + t);
            continue;
        }

        // 4️⃣ ER / R grades
        if (Pattern.matches('^(ER|R)\\d{1,2}T?$', t)) {
            res.grades.add(t);
            continue;
        }

        // 5️⃣ 42CRMO4 / 45ХН
        Matcher mNumAttr =
            Pattern.compile('^(\\d{1,4})([A-ZА-Я0-9]{1,10})$').matcher(t);
        if (mNumAttr.matches()) {
            res.grades.add(mNumAttr.group(1));
            res.attributes.add(mNumAttr.group(2));
            continue;
        }

        // 6️⃣ pure numeric
        if (Pattern.matches('^\\d{1,4}$', t)) {
            res.grades.add(t);
            continue;
        }

        // 7️⃣ attributes (BUT NOT CLASS)
        if (Pattern.matches('^[A-Z]{1,5}\\d{0,3}$', t)
            && t != 'CLASS') {
            res.attributes.add(t);
            continue;
        }
    }

    res.isGarbage = res.grades.isEmpty();
    return res;
}

    // ===============================
    // BULK NORMALIZATION
    // ===============================
public static List<Result> normalizeList(
    List<SteelGrade__c> records,
    String facetCode
) {
    List<Result> out = new List<Result>();
    if (records == null) return out;

    for (SteelGrade__c sg : records) {
        if (sg == null || String.isBlank(sg.Name)) {
            out.add(new Result().markGarbage());
        } else {
            out.add(normalize(sg.Name, facetCode));
        }
    }
    return out;
}

    /*
    public static List<Result> normalizeList(List<SteelGrade__c> records) {
        List<Result> out = new List<Result>();
        if (records == null) return out;

        for (SteelGrade__c sg : records) {
            if (sg == null) {
                out.add(new Result().markGarbage());
            } else {
                //out.add(normalize(sg.Name));
                out.add(normalize(sg.Name, facetCode));
            }
        }
        return out;
    }
        */
}