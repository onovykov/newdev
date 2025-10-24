public class SimilarityUtils {
    /****************************************************************************************/
    /****************** Методи фонетичного аналізу (Similarity Methods) *********************/
    /****************************************************************************************/
        /* ------- Dice-Sørensen Similarity
        Принцип оцінки
        Dice коефіцієнт вимірює відносну кількість спільних елементів:
        Значення 1 означає повну ідентичність
        Значення 0 — повна відсутність схожості
        Спец. параметри:
        Boolean normalizeDiacritics (true/false) - чи потрібно нормалізовувати діакритику
        Boolean transliterate (true/false) - чи потрібно приводити до трансліту
        */
        public static Double DiceSimilarity(String s1, String s2, Boolean normalizeDiacritics, Boolean transliterate) {
            if (String.isBlank(s1) || String.isBlank(s2)) return 0.0;

            if (normalizeDiacritics) {
                s1 = StringUtilsEx.normalizeDiacritics(s1);
                s2 = StringUtilsEx.normalizeDiacritics(s2);
            }

            if (transliterate) {
                s1 = StringUtilsEx.transliterateCyrillicToLatin(s1);
                s2 = StringUtilsEx.transliterateCyrillicToLatin(s2);
            }

            String a = StringNormalize.getClearName(s1, Consts.ToUpperCase.YES,
                                                    Consts.QuestionMarkRule.REMOVE_SIGN,
                                                    Consts.ClearCountryName.NO);
            String b = StringNormalize.getClearName(s2, Consts.ToUpperCase.YES,
                                                    Consts.QuestionMarkRule.REMOVE_SIGN,
                                                    Consts.ClearCountryName.NO);

            Set<String> bigramsA = generateNgrams(a, 2);
            Set<String> bigramsB = generateNgrams(b, 2);

            if (bigramsA.isEmpty() && bigramsB.isEmpty()) return 1.0;
            if (bigramsA.isEmpty() || bigramsB.isEmpty()) return 0.0;

            Set<String> intersection = new Set<String>(bigramsA);
            intersection.retainAll(bigramsB);

            Integer interSize = intersection.size();
            Integer total = bigramsA.size() + bigramsB.size();

            Double similarity = (2.0 * interSize) / total;
            return Math.round(similarity * 1000) / 1000.0;
        }

    /* ----- Метод косинусної подібності (Cosine Similarity)
            Принцип
            Косинусна подібність вимірює схожість між двома рядками шляхом порівняння кутів між векторами їхнього представлення.
            1.  Рядки розбиваються на набори слів.
            2.  Для кожного рядка будується вектор, де кожен елемент відповідає частоті появи певного слова.
            3.  Косинус кута між цими векторами вимірює подібність (1 — ідентичні рядки, 0 — зовсім різні).
            Критерії подібності
            •   Косинусна подібність наближається до 1 для схожих назв
            •   Якщо значення >= 0.8, рядки вважаються дуже схожими
            •   Якщо значення 0.6 - 0.8, рядки вважаються здебільшого схожими
            •   Якщо значення 0.4 - 0.6, рядки вважаються частково схожими
            •   Якщо значення 0.2 - 0.4, рядки вважаються мало схожими
            •   Якщо значення <= 0.2 - практично повна розбіжність
    */
    public static Double CosineSimilarity(String s1, String s2, Boolean normalizeDiacritics, Boolean transliterate) {
        if (String.isBlank(s1) || String.isBlank(s2)) return 0.0;

        if (normalizeDiacritics) {
            s1 = StringUtilsEx.normalizeDiacritics(s1);
            s2 = StringUtilsEx.normalizeDiacritics(s2);
        }

        if (transliterate) {
            s1 = StringUtilsEx.transliterateCyrillicToLatin(s1);
            s2 = StringUtilsEx.transliterateCyrillicToLatin(s2);
        }
        
        String name1 = StringNormalize.getClearName(s1, Consts.ToUpperCase.YES,
                                                Consts.QuestionMarkRule.REMOVE_SIGN,
                                                Consts.ClearCountryName.NO);
        String name2 = StringNormalize.getClearName(s2, Consts.ToUpperCase.YES,
                                                Consts.QuestionMarkRule.REMOVE_SIGN,
                                                Consts.ClearCountryName.NO);        

        List<String> words1 = name1.split('\\s+');
        List<String> words2 = name2.split('\\s+');

        Map<String, Integer> freq1 = new Map<String, Integer>();
        Map<String, Integer> freq2 = new Map<String, Integer>();

        for (String word : words1) {
            if (word != '') {
                freq1.put(word, freq1.containsKey(word) ? freq1.get(word) + 1 : 1);
            }
        }

        for (String word : words2) {
            if (word != '') {
                freq2.put(word, freq2.containsKey(word) ? freq2.get(word) + 1 : 1);
            }
        }

        Set<String> allWords = new Set<String>();
        allWords.addAll(freq1.keySet());
        allWords.addAll(freq2.keySet());

        Double dotProduct = 0.0;
        Double magnitude1 = 0.0;
        Double magnitude2 = 0.0;

        for (String word : allWords) {
            Integer f1 = freq1.containsKey(word) ? freq1.get(word) : 0;
            Integer f2 = freq2.containsKey(word) ? freq2.get(word) : 0;

            dotProduct += f1 * f2;
            magnitude1 += f1 * f1;
            magnitude2 += f2 * f2;
        }

        if (magnitude1 == 0.0 || magnitude2 == 0.0) return 0.0;

        Double similarity = dotProduct / (Math.sqrt(magnitude1) * Math.sqrt(magnitude2));
        return Math.round(similarity * 1000) / 1000.0;
    }

    /* ------- Підхід із використанням Levenshtein Distance
        Критерії подібності на основі Levenshtein Distance
        1.  Абсолютна редакційна відстань:
        o   Якщо Levenshtein Distance між двома рядками дорівнює 0, це означає, що назви абсолютно однакові.
        o   Якщо значення відстані є дуже малим (наприклад, 1 або 2), це може свідчити про незначну відмінність,
        яку можна вважати хибодруком або різницею в скороченнях (напр. "Company" і "Compani").
        Зазвичай вважається, що якщо Levenshtein Distance <3, то назви є дуже схожими
*/
    public static Double LevenshteinSimilarity(String s1, String s2, Boolean normalizeDiacritics, Boolean transliterate) {
        if (String.isBlank(s1) || String.isBlank(s2)) return 0.0;

        if (normalizeDiacritics) {
            s1 = StringUtilsEx.normalizeDiacritics(s1);
            s2 = StringUtilsEx.normalizeDiacritics(s2);
        }

        if (transliterate) {
            s1 = StringUtilsEx.transliterateCyrillicToLatin(s1);
            s2 = StringUtilsEx.transliterateCyrillicToLatin(s2);
        }

        String a = StringNormalize.getClearName(s1, Consts.ToUpperCase.YES,
                                                Consts.QuestionMarkRule.REMOVE_SIGN,
                                                Consts.ClearCountryName.NO);
        String b = StringNormalize.getClearName(s2, Consts.ToUpperCase.YES,
                                                Consts.QuestionMarkRule.REMOVE_SIGN,
                                                Consts.ClearCountryName.NO);

        Integer rows = a.length() + 1;
        Integer cols = b.length() + 1;

        List<List<Integer>> dp = new List<List<Integer>>();
        for (Integer i = 0; i < rows; i++) {
            List<Integer> row = new List<Integer>();
            for (Integer j = 0; j < cols; j++) {
                row.add(0);
            }
            dp.add(row);
        }

        for (Integer i = 0; i < rows; i++) dp[i][0] = i;
        for (Integer j = 0; j < cols; j++) dp[0][j] = j;

        for (Integer i = 1; i < rows; i++) {
            for (Integer j = 1; j < cols; j++) {
                Integer cost = (a.substring(i - 1, i) == b.substring(j - 1, j)) ? 0 : 1;
                dp[i][j] = Math.min(
                    Math.min(dp[i - 1][j] + 1, dp[i][j - 1] + 1),
                    dp[i - 1][j - 1] + cost
                );
            }
        }

        Integer distance = dp[rows - 1][cols - 1];
        Integer maxLen = Math.max(a.length(), b.length());
        if (maxLen == 0) return 1.0;

        Double similarity = 1.0 - ((Double)distance / maxLen);
        return Math.round(similarity * 1000) / 1000.0;
    }

     /* ----------------------------------------------------------------------
     Нормалізована Levenstein Distance
     o   Подібні назви: Якщо нормалізована Levenstein Distance ≤ 0.2 (або 20%), це означає, що назви дуже схожі і можуть бути дублями.
     o   Можливі дублікати:
               Якщо нормалізована Levenstein Distance між 0.2 і 0.4 (20-40%),
               це вказує на можливість дублювання, але потрібно додатково перевірити.
     o   Різні назви: Якщо нормалізована Levenstein Distance > 0.4 (або 40%), назви, ймовірно, є різними.
     */
     public static Decimal getNormalizedLevenstein(String name1, String name2, Boolean normalizeDiacritics, Boolean transliterate) {
         Decimal Result = 0.00;

                 Result = (Decimal) LevenshteinSimilarity(name1, name1, normalizeDiacritics, transliterate)/Math.max(name1.length(), name2.length());
         //Result = (Decimal)getLevensteinDistance(name1, name2)/Math.max(name1.length(), name2.length());
         return Result.setScale(3);
     }

    //---------------- JaccardSimilarity по словах -------------------------------------------------
    public static Double JaccardSimilarityByWords(String s1, String s2, Boolean normalizeDiacritics, Boolean transliterate) {
        if (String.isBlank(s1) || String.isBlank(s2)) return 0.0;

        if (normalizeDiacritics) {
            s1 = StringUtilsEx.normalizeDiacritics(s1);
            s2 = StringUtilsEx.normalizeDiacritics(s2);
        }

        if (transliterate) {
            s1 = StringUtilsEx.transliterateCyrillicToLatin(s1);
            s2 = StringUtilsEx.transliterateCyrillicToLatin(s2);
        }

        String name1 = StringNormalize.getClearName(s1, Consts.ToUpperCase.YES,
                                                Consts.QuestionMarkRule.REMOVE_SIGN,
                                                Consts.ClearCountryName.NO);
        String name2 = StringNormalize.getClearName(s2, Consts.ToUpperCase.YES,
                                                Consts.QuestionMarkRule.REMOVE_SIGN,
                                                Consts.ClearCountryName.NO);

        Set<String> set1 = new Set<String>(name1.split('\\s+'));
        Set<String> set2 = new Set<String>(name2.split('\\s+'));
        set1.remove('');
        set2.remove('');

        if (set1.isEmpty() || set2.isEmpty()) return 0.0;

        Set<String> intersection = new Set<String>(set1);
        intersection.retainAll(set2);

        Set<String> union = new Set<String>(set1);
        union.addAll(set2);

        Double similarity = (Double) intersection.size() / union.size();
        return Math.round(similarity * 1000) / 1000.0;
    }

    //-------------- JaccardSimilarity по літерах ---------------------------------------------------
    public static Double JaccardCharSimilarity(String name1, String name2) {
        if (String.isBlank(name1) || String.isBlank(name2)) return 0.0;
              
        String s1 = StringNormalize.getClearName(name1, Consts.ToUpperCase.YES,
                                                Consts.QuestionMarkRule.REMOVE_SIGN,
                                                Consts.ClearCountryName.NO);
        String s2 = StringNormalize.getClearName(name2, Consts.ToUpperCase.YES,
                                                Consts.QuestionMarkRule.REMOVE_SIGN,
                                                Consts.ClearCountryName.NO);        
        
        Set<String> set1 = new Set<String>();
        Set<String> set2 = new Set<String>();

        for (Integer i = 0; i < s1.length() - 1; i++) {
            set1.add(s1.substring(i, i + 2));
        }
        for (Integer i = 0; i < s2.length() - 1; i++) {
            set2.add(s2.substring(i, i + 2));
        }

        if (set1.isEmpty() || set2.isEmpty()) return 0.0;

        Set<String> intersection = new Set<String>(set1);
        intersection.retainAll(set2);

        Set<String> union = new Set<String>(set1);
        union.addAll(set2);

        Double similarity = (Double) intersection.size() / union.size();
        return Math.round(similarity * 1000) / 1000.0;
    }

        //-------------- Jaccard на N-грамах ---------------------------------------------------
    public static Decimal JaccardSimilarity(String name1, String name2, Integer n) {
    
        String a = StringNormalize.getClearName(name1, Consts.ToUpperCase.YES,
                                                Consts.QuestionMarkRule.REMOVE_SIGN,
                                                Consts.ClearCountryName.NO);
        String b = StringNormalize.getClearName(name2, Consts.ToUpperCase.YES,
                                                Consts.QuestionMarkRule.REMOVE_SIGN,
                                                Consts.ClearCountryName.NO);
            
        Set<String> gramsA = generateNgrams(a.toLowerCase(), n);
        Set<String> gramsB = generateNgrams(b.toLowerCase(), n);

        Set<String> inter = new Set<String>(gramsA);
        inter.retainAll(gramsB);

        Set<String> union = new Set<String>(gramsA);
        union.addAll(gramsB);

        return (union.size() == 0) ? 0 : ((Decimal)inter.size()) / union.size();
    }

        //-------------- Функція, що генерує n-грами для методу Jaccard на N-грамах --------------
    private static Set<String> generateNgrams(String str, Integer n) {
        Set<String> grams = new Set<String>();
        String clean = str.replaceAll('[^a-zа-яА-Я0-9]', '').toLowerCase();
        for (Integer i = 0; i <= clean.length() - n; i++) {
            grams.add(clean.substring(i, i + n));
        }
        return grams;
    }

/*---------------- Soundex Utils -------------------------------*/
        // Основний Soundex
    public static String soundex(String s) {
        if (s == null || s.trim().length() == 0) return null;

        String word = StringNormalize.getClearName(s, Consts.ToUpperCase.YES,
                                                   Consts.QuestionMarkRule.REMOVE_SIGN,
                                                   Consts.ClearCountryName.NO);

        Map<String, String> soundexMap = new Map<String, String>{
            'B'=>'1', 'F'=>'1', 'P'=>'1', 'V'=>'1',
            'C'=>'2', 'G'=>'2', 'J'=>'2', 'K'=>'2', 'Q'=>'2', 'S'=>'2', 'X'=>'2', 'Z'=>'2', 'H'=>'2',
            'D'=>'3', 'T'=>'3',
            'L'=>'4',
            'M'=>'5', 'N'=>'5',
            'R'=>'6',
            'Б'=>'1', 'П'=>'1', 'В'=>'1', 'Ф'=>'1',
            'Г'=>'2', 'Ґ'=>'2', 'К'=>'2', 'Х'=>'2', 'Ц'=>'2', 'Ч'=>'2', 'Ш'=>'2', 'Щ'=>'2', 'С'=>'2', 'З'=>'2',
            'Д'=>'3', 'Т'=>'3',
            'Л'=>'4',
            'М'=>'5', 'Н'=>'5',
            'Р'=>'6',
            'Ç'=>'2', 'Ś'=>'2', 'Š'=>'2', 'Ž'=>'2',
            'Ł'=>'4', 'Ñ'=>'5',
            'A'=>'', 'E'=>'', 'I'=>'', 'O'=>'', 'U'=>'', 'Y'=>'',
            'Ä'=>'', 'Ö'=>'', 'Ü'=>'', 'Ó'=>'', 'É'=>'', 'Á'=>'', 'Ø'=>'',
            'А'=>'', 'О'=>'', 'Е'=>'', 'І'=>'', 'У'=>'', 'И'=>'',
            'Й'=>'', 'Ї'=>'', 'Є'=>'', 'Я'=>'', 'Ю'=>'', 'Э'=>'',
            'Ъ'=>'', 'Ь'=>'', 'Ё'=>''
        };

        String code = '';
        if (word.length() > 0) code = word.substring(0, 1);

        for (Integer i = 1; i < word.length(); i++) {
            String ch = word.substring(i, i+1);
            if (soundexMap.containsKey(ch)) {
                String digit = soundexMap.get(ch);
                if (!code.endsWith(digit)) {
                    code += digit;
                }
            }
        }

        while (code.length() < 4) code += '0';
        return code.substring(0, 4);
    }

    // Soundex усіх слів
    public static List<String> getSoundexEx(String name) {
        List<String> result = new List<String>();
        if (String.isBlank(name)) return result;

        String clean = StringNormalize.getClearName(name, Consts.ToUpperCase.YES,
                                                    Consts.QuestionMarkRule.REMOVE_SIGN,
                                                    Consts.ClearCountryName.NO);
        List<String> words = new List<String>(clean.trim().replaceAll('\\s+', ' ').split(' '));
        for (String word : words) {
            result.add(soundex(word));
        }
        return result;
    }

    // Показник подібності між Soundex-кодами одного слова
    public static Decimal getSoundexSimilarityEx(String s1, String s2, Boolean mustFirstMatch) {
        if (s1 == null || s2 == null || s1.length() != 4 || s2.length() != 4) return 0.000;

        Integer matchCount = 0;
        Boolean sameFirstLetter = (s1.substring(0,1) == s2.substring(0,1));

        for (Integer i = 1; i < 4; i++) {
            if (s1.substring(i, i+1) == s2.substring(i, i+1)) {
                matchCount++;
            }
        }

        Decimal result;
        if (mustFirstMatch && !sameFirstLetter) {
            return 0.000;
        } else if (sameFirstLetter) {
            result = (Decimal)(matchCount + 1) / 4;
        } else {
            result = (Decimal)matchCount / 3;
        }

        return result.setScale(3);
    }

    // Агрегована подібність між двома назвами по Soundex
    public static Decimal getFullSoundexSimilarity(String name1, String name2, Boolean mustFirstMatch) {
        if (String.isBlank(name1) || String.isBlank(name2)) return 0.000;

        List<String> list1 = getSoundexEx(name1);
        List<String> list2 = getSoundexEx(name2);

        Integer count = Math.min(list1.size(), list2.size());
        Integer max = Math.max(list1.size(), list2.size());
        if (count == 0 || max == 0) return 0.000;

        Decimal total = 0;
        for (Integer i = 0; i < count; i++) {
            total += getSoundexSimilarityEx(list1[i], list2[i], mustFirstMatch);
        }

        return (total / max).setScale(3);
    }
}