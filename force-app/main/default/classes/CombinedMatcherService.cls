public class CombinedMatcherService {

    public class MatchResult {
        public Decimal phoneticScore;
        public Decimal jaccardScore;
        public Decimal levenshteinScore;
        public Decimal finalScore;

        public String debugSummary() {
            return 'Phonetic=' + phoneticScore +
                ', Jaccard=' + jaccardScore +
                ', Levenshtein=' + levenshteinScore +
                ', Final=' + finalScore;
        }
    }

    public static MatchResult compare(String s1, String s2) {
        MatchResult result = new MatchResult();
    
        //String phon1 = PhoneticTranscoder.toPhoneticCode(s1);
        //String phon2 = PhoneticTranscoder.toPhoneticCode(s2);   
        //result.phoneticScore = phon1 == phon2 ? 1.0 : 0.0;
        String phon1 = String.join(StringUtils.getSoundexEx(PhoneticTranscoder.toPhoneticCode(StringUtils.getClearName(s1,true))), ' ');
        String phon2 = String.join(StringUtils.getSoundexEx(PhoneticTranscoder.toPhoneticCode(StringUtils.getClearName(s2,true))), ' ');       
        result.phoneticScore = (Decimal) StringUtils.getSoundexSimilarityEx(phon1,phon2,false);
        
        // Обидві версії Jaccard
        Decimal jaccardRaw = jaccardSimilarity(s1, s2, 2);
        Decimal jaccardPhon = jaccardSimilarity(phon1, phon2, 2);
        result.jaccardScore = Math.max(jaccardRaw, jaccardPhon);
    
        // Levenshtein по фонетичних формах
        result.levenshteinScore = normalizedLevenshtein(phon1, phon2);
    
        result.finalScore = (
            0.5 * result.phoneticScore +
            0.3 * result.jaccardScore +
            0.2 * result.levenshteinScore
        );
    
        return result;
    }


    // 🔤 Jaccard на біграмах
    public static Decimal jaccardSimilarity(String a, String b, Integer n) {
        Set<String> gramsA = generateNgrams(a.toLowerCase(), n);
        Set<String> gramsB = generateNgrams(b.toLowerCase(), n);

        Set<String> inter = new Set<String>(gramsA);
        inter.retainAll(gramsB);

        Set<String> union = new Set<String>(gramsA);
        union.addAll(gramsB);

        return (union.size() == 0) ? 0 : (((Decimal)inter.size()) / union.size()).setScale(3);
    }

    public static Set<String> generateNgrams(String str, Integer n) {
        Set<String> grams = new Set<String>();
        String clean = str.replaceAll('[^a-zа-яА-Я0-9]', '').toLowerCase();
        for (Integer i = 0; i <= clean.length() - n; i++) {
            grams.add(clean.substring(i, i + n));
        }
        return grams;
    }

    // 🔁 Levenshtein як 1 - нормалізована відстань
    public static Decimal normalizedLevenshtein(String a, String b) {
        Integer dist = levenshteinDistance(a, b);
        Integer maxLen = Math.max(a.length(), b.length());
        return maxLen == 0 ? 1.0 : 1.0 - ((Decimal)dist / maxLen);
    }

    public static Integer levenshteinDistance(String a, String b) {
        if (a == b) return 0;
        if (String.isEmpty(a)) return b.length();
        if (String.isEmpty(b)) return a.length();
    
        Integer lenA = a.length();
        Integer lenB = b.length();
    
        // Ініціалізуємо вручну 2D-масив
        List<List<Integer>> dp = new List<List<Integer>>();
        for (Integer i = 0; i <= lenA; i++) {
            List<Integer> row = new List<Integer>();
            for (Integer j = 0; j <= lenB; j++) {
                row.add(0);
            }
            dp.add(row);
        }
    
        for (Integer i = 0; i <= lenA; i++) dp[i][0] = i;
        for (Integer j = 0; j <= lenB; j++) dp[0][j] = j;
    
        for (Integer i = 1; i <= lenA; i++) {
            for (Integer j = 1; j <= lenB; j++) {
                Integer cost = a.substring(i - 1, i) == b.substring(j - 1, j) ? 0 : 1;
                dp[i][j] = Math.min(
                    Math.min(dp[i - 1][j] + 1, dp[i][j - 1] + 1),
                    dp[i - 1][j - 1] + cost
                );
            }
        }
    
        return dp[lenA][lenB];
    }
}