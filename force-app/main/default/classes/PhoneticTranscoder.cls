public class PhoneticTranscoder {

    private static final Map<String, String> normalizationMap = new Map<String, String>{
        // Кирилиця
        'а'=>'a','б'=>'b','в'=>'v','г'=>'g','ґ'=>'g','д'=>'d','е'=>'e','є'=>'ye',
        'ж'=>'zh','з'=>'z','и'=>'i','й'=>'y','к'=>'k','л'=>'l','м'=>'m',
        'н'=>'n','о'=>'o','п'=>'p','р'=>'r','с'=>'s','т'=>'t','у'=>'u',
        'ф'=>'f','х'=>'h','ц'=>'ts','ч'=>'ch','ш'=>'sh','щ'=>'sch',
        'ь'=>'','ю'=>'yu','я'=>'ya','ы'=>'y','э'=>'e','ъ'=>'',
        'і'=>'i' /* укр-лат*/,  'ї'=>'i',

        // Діакритика і спецсимволи
        'ç'=>'c','ć'=>'c','ĉ'=>'c','ċ'=>'c','č'=>'c','ď'=>'d','ð'=>'d','ķ'=>'k','ĝ'=>'g',
        'ğ'=>'g','ġ'=>'g','ģ'=>'g','ĺ'=>'l','ļ'=>'l','ľ'=>'l','ŀ'=>'l','ł'=>'l','ń'=>'n',
        'ņ'=>'n','ň'=>'n','ŝ'=>'s','ş'=>'s','š'=>'s','ś'=>'s','ţ'=>'t','ť'=>'t','ź'=>'z',
        'ż'=>'z','ž'=>'z','à'=>'a','á'=>'a','â'=>'a','ã'=>'a','å'=>'a','ā'=>'a','ă'=>'a',
        'ą'=>'a','è'=>'e','é'=>'e','ê'=>'e','ë'=>'e','ē'=>'e','ĕ'=>'e','ė'=>'e','ę'=>'e',
        'ě'=>'e','ì'=>'i','í'=>'i','î'=>'i','ï'=>'i','ĩ'=>'i','ī'=>'i','ĭ'=>'i','į'=>'i',
        'ò'=>'o','ó'=>'o','ô'=>'o','õ'=>'o','ø'=>'o','ō'=>'o','ŏ'=>'o','ő'=>'o','ù'=>'u',
        'ú'=>'u','û'=>'u','ũ'=>'u','ū'=>'u','ŭ'=>'u','ů'=>'u','ű'=>'u','ų'=>'u','ö'=>'o' 
        /*,'ue'=>'u', 'ae'=>'a', 'oe'=>'o'*/

    };

    public static String toPhoneticCode(String input) {
        if (String.isBlank(input)) return '';
        /*
        String clean = input.toLowerCase()
            .replaceAll('[^a-zа-яёіїґøäöüœåçčłžśñëéèêáàâãîïìíôòóõûùú]', '')
            .replace('ё', 'е')
            .replace('і', 'и')
            .replace('ї', 'и')
            .replace('ґ', 'г');

        String normalized = normalizeCharacters(clean);
        */
        String clean = StringUtilsEx.prepareForComparison(input).toLowerCase(); 
        System.debug(clean);
        return buildMetaphoneCode(clean );
    }

    private static String normalizeCharacters(String text) {
        text = text.toLowerCase();
        String result = '';
        for (Integer i = 0; i < text.length(); i++) {
            String ch = text.substring(i, i + 1);
            result += normalizationMap.containsKey(ch) ? normalizationMap.get(ch) : ch;
        }
        return result;
    }

    private static String buildMetaphoneCode(String input) {
        String result = '';
        String lastChar = '';
        Integer i = 0;

        while (i < input.length()) {
            String ch = input.substring(i, i + 1);
            String nextCh = (i + 1 < input.length()) ? input.substring(i+1, i+2) : '';
            String triCh = (i + 2 < input.length()) ? input.substring(i+2, i+3) : '';

            if (ch == 'i' && nextCh == 'c' && triCh == 'k') {
                result += 'ISK';
                lastChar = 'k';
                i += 3;
                continue;
            }

            if (ch == 'c' && nextCh == 'k') {
                result += 'K';
                lastChar = 'k'; i += 2; continue;
            }
            if ((ch == 's' && nextCh == 'h') || (ch == 'c' && nextCh == 'h')) {
                result += 'K'; // змінили з X на K
                lastChar = nextCh; i += 2; continue;
            }
            if (ch == 'p' && nextCh == 'h') {
                result += 'F';
                lastChar = nextCh; i += 2; continue;
            }
            if (ch == 't' && nextCh == 'h') {
                result += 'T';
                lastChar = nextCh; i += 2; continue;
            }
            if (ch == 'z' && nextCh == 'h') {
                result += 'J';
                lastChar = nextCh; i += 2; continue;
            }
            if (ch == 's' && nextCh == 'c' && triCh == 'h') {
                result += 'K';
                lastChar = triCh; i += 3; continue;
            }
            if (ch == 't' && nextCh == 's') {
                result += 'C';
                lastChar = 's'; i += 2; continue;
            }
            if (ch == 'y' && (nextCh == 'e' || nextCh == 'u' || nextCh == 'a')) {
                result += 'Y';
                lastChar = nextCh; i += 2; continue;
            }

            if ('aeiou'.contains(ch) && result.length() == 0) {
                result += ch.toUpperCase();
                lastChar = ch;
                i++;
                continue;
            }

            if (ch == lastChar) {
                i++;
                continue;
            }

            switch on ch {
                when 'b' { result += 'B'; }
                when 'c' { result += 'C'; }
                when 'd' { result += 'T'; }
                when 'f' { result += 'F'; }
                when 'g' { result += 'K'; }
                when 'h' { result += 'H'; }
                when 'j' { result += 'J'; }
                when 'k' { result += 'K'; }
                when 'l' { result += 'L'; }
                when 'm' { result += 'M'; }
                when 'n' { result += 'N'; }
                when 'p' { result += 'P'; }
                when 'q' { result += 'K'; }
                when 'r' { result += 'R'; }
                when 's' { result += 'S'; }
                when 't' { result += 'T'; }
                when 'v' { result += 'F'; }
                when 'w' { result += 'V'; }
                when 'x' { result += 'KS'; }
                when 'y' { result += 'Y'; }
                when 'z' { result += 'S'; }
            }

            lastChar = ch;
            i++;
        }

        return result;
    }

    //--- Метод для побудови кешу біграм
    public static Map<String, Set<String>> buildBigramsCache(List<String> codes) {
        Map<String, Set<String>> result = new Map<String, Set<String>>();
        for (String code : codes) {
            if (String.isBlank(code) || code.length() < 2) continue;
            Set<String> bigrams = new Set<String>();
            for (Integer i = 0; i < code.length() - 1; i++) {
                bigrams.add(code.substring(i, i + 2));
            }
            result.put(code, bigrams);
        }
        return result;
    }
    
    //--- Метод для кешу букв
    public static Map<String, Set<String>> buildLettersCache(List<String> codes) {
        Map<String, Set<String>> result = new Map<String, Set<String>>();
        for (String code : codes) {
            if (String.isBlank(code)) continue;
            Set<String> letters = new Set<String>();
            for (Integer i = 0; i < code.length(); i++) {
                letters.add(code.substring(i, i + 1));
            }
            result.put(code, letters);
        }
        return result;
    }

    //--- Оновлені методи порівняння
    public static Decimal compareSets(Set<String> set1, Set<String> set2) {
        if (set1 == null || set2 == null || set1.isEmpty() || set2.isEmpty()) return 0.0;
        Set<String> intersection = new Set<String>(set1);
        intersection.retainAll(set2);
        Set<String> union = new Set<String>(set1);
        union.addAll(set2);
        return union.isEmpty() ? 0.0 : ((Decimal) intersection.size() / union.size()).setScale(3);
    }

    //---- Оновлений comparePhoneticHybrid
    public static Decimal comparePhoneticHybridCached(
        String code1,
        String code2,
        Map<String, Set<String>> bigramsMap,
        Map<String, Set<String>> lettersMap
    ) {
        if (String.isBlank(code1) || String.isBlank(code2)) return 0.0;
    
        Set<String> bigrams1 = bigramsMap.containsKey(code1) ? bigramsMap.get(code1) : new Set<String>();
        Set<String> bigrams2 = bigramsMap.containsKey(code2) ? bigramsMap.get(code2) : new Set<String>();
    
        Set<String> letters1 = lettersMap.containsKey(code1) ? lettersMap.get(code1) : new Set<String>();
        Set<String> letters2 = lettersMap.containsKey(code2) ? lettersMap.get(code2) : new Set<String>();
    
        Decimal simBigram = compareSets(bigrams1, bigrams2);
        Decimal simLetters = compareSets(letters1, letters2);
    
        return ((Decimal)Math.max(simBigram, simLetters)).setScale(3);
    }
        // Біграмне порівняння
    public static Decimal comparePhoneticCodes(String s1, String s2) {
        if (String.isBlank(s1) || String.isBlank(s2) || s1.length() < 2 || s2.length() < 2) return 0.0;

        Set<String> set1 = new Set<String>();
        Set<String> set2 = new Set<String>();

        for (Integer i = 0; i < s1.length() - 1; i++) {
            set1.add(s1.substring(i, i + 2));
        }
        for (Integer i = 0; i < s2.length() - 1; i++) {
            set2.add(s2.substring(i, i + 2));
        }

        Set<String> intersection = new Set<String>(set1);
        intersection.retainAll(set2);

        Set<String> union = new Set<String>(set1);
        union.addAll(set2);

        return union.isEmpty() ? 0.0 : ((Decimal) intersection.size() / union.size()).setScale(3);
    }

    // Порівняння по символах
    public static Decimal comparePhoneticLetters(String s1, String s2) {
        if (String.isBlank(s1) || String.isBlank(s2)) return 0.0;

        Set<String> set1 = new Set<String>();
        Set<String> set2 = new Set<String>();

        for (Integer i = 0; i < s1.length(); i++) {
            set1.add(s1.substring(i, i + 1));
        }
        for (Integer i = 0; i < s2.length(); i++) {
            set2.add(s2.substring(i, i + 1));
        }

        Set<String> intersection = new Set<String>(set1);
        intersection.retainAll(set2);

        Set<String> union = new Set<String>(set1);
        union.addAll(set2);

        return union.isEmpty() ? 0.0 : ((Decimal) intersection.size() / union.size()).setScale(3);
    }

    /**
     * Гібридна метрика: максимум з біграмної та символної подібності
     * @param s1 перший код
     * @param s2 другий код
     * @return значення подібності 0.000–1.000
     */
    public static Decimal comparePhoneticHybrid(String s1, String s2) {
        Decimal simBigram = comparePhoneticCodes(s1, s2);
        Decimal simLetters = comparePhoneticLetters(s1, s2);

        return (Decimal)(Math.max(simBigram, simLetters)).setScale(3);
    }
}