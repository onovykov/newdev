public class MetaphoneUtils { 

    public class MetaphoneResult {
        public String primary;
        public String alternate;

        public MetaphoneResult() {
            this.primary = '';
            this.alternate = '';
        }
        
        public MetaphoneResult(String primary, String alternate) {
            this.primary = primary;
            this.alternate = alternate;
        }
    }

    // Публічний інтерфейс
    public static String getMetaphone(String word) {
        return getMetaphoneFull(word).primary;
    }

    public static MetaphoneResult getMetaphoneFull(String wordRaw) {
        if (String.isBlank(wordRaw)) return new MetaphoneResult('', '');

        String word = StringUtilsEx.prepareForComparison(wordRaw); //normalizeWord(wordRaw);

        // 🔹 Префікс AL — спеціальна обробка
        /* Скасовно - перфікс AL обробляємо в prepareForComparison-> getClearName
        if (word.startsWith('AL') && word.length() > 2) {
            String rest = word.substring(2);
            MetaphoneResult innerRes = getMetaphoneFull(rest);
            return new MetaphoneResult('AL' + innerRes.primary, 'AL' + innerRes.alternate);
        }
        */
        // 🔹 Короткі слова — не спотворюємо
        if (word.length() <= 5) {
            return new MetaphoneResult(word, word);
        }

        String primary = '';
        String alternate = '';
        Integer i = 0;
        Integer len = word.length();

        while (i < len) {
            String ch = word.substring(i, i + 1);
            String nxt = (i + 1 < len) ? word.substring(i + 1, i + 2) : '';

            if (i > 0 && ch == word.substring(i - 1, i)) {
                i++; continue;
            }

            if ('AEIOU'.contains(ch) && i == 0) {
                primary += ch; alternate += ch;
            } else if (ch == 'B') {
                primary += 'B'; alternate += 'B';
            } else if (ch == 'C') {
                if (nxt == 'H') {
                    primary += 'X'; alternate += 'X'; i++;
                } else {
                    primary += 'K'; alternate += 'K';
                }
            } else if (ch == 'D') {
                primary += 'T'; alternate += 'T';
            } else if (ch == 'G') {
                if (nxt == 'H') {
                    i++; // Пропускаємо 'GH'
                } else {
                    primary += 'K'; alternate += 'K';
                }
            } else if (ch == 'H') {
                // H пропускаємо
            } else if (ch == 'K') {
                primary += 'K'; alternate += 'K';
            } else if (ch == 'P') {
                if (nxt == 'H') {
                    primary += 'F'; alternate += 'F'; i++;
                } else {
                    primary += 'P'; alternate += 'P';
                }
            } else if (ch == 'Q') {
                primary += 'K'; alternate += 'K';
            } else if (ch == 'S') {
                if (nxt == 'H') {
                    primary += 'X'; alternate += 'X'; i++;
                } else {
                    primary += 'S'; alternate += 'S';
                }
            } else if (ch == 'T') {
                primary += 'T'; alternate += 'T';
            } else if (ch == 'V') {
                primary += 'F'; alternate += 'F';
            } else if (ch == 'X') {
                primary += 'KS'; alternate += 'KS';
            } else if (ch == 'Z') {
                primary += 'S'; alternate += 'S';
            } else if ('LMNR'.contains(ch)) {
                primary += ch; alternate += ch;
            }

            i++;
        }

        return new MetaphoneResult(primary, alternate);
    }

    // 🔧 Нормалізація слова
    private static String normalizeWord(String wordRaw) {
        return StringUtilsEx.normalizeDiacritics(StringUtilsEx.transliterateCyrillicToLatin(wordRaw))
            .toUpperCase()
            .replaceAll('[^A-Z]', '');
    }

    // Біграмна подібність
    public static Decimal getMetaphoneSimilarity(String s1, String s2) {
        if (String.isBlank(s1) || String.isBlank(s2) || s1.length() < 2 || s2.length() < 2) return 0.0;

        Set<String> set1 = new Set<String>();
        Set<String> set2 = new Set<String>();

        for (Integer i = 0; i < s1.length() - 1; i++) set1.add(s1.substring(i, i + 2));
        for (Integer i = 0; i < s2.length() - 1; i++) set2.add(s2.substring(i, i + 2));

        Set<String> intersection = new Set<String>(set1);
        intersection.retainAll(set2);

        Set<String> union = new Set<String>(set1);
        union.addAll(set2);

        return union.isEmpty() ? 0.0 : ((Decimal) intersection.size() / union.size()).setScale(3);
    }

    // 🔹 Порівняння фраз по словах (позиційно)
    public static Decimal getFullMetaphoneSimilarity(String name1, String name2) {
        if (String.isBlank(name1) || String.isBlank(name2)) return 0.000;

        List<String> words1 = normalizeWords(name1);
        List<String> words2 = normalizeWords(name2);

        Integer minLength = Math.min(words1.size(), words2.size());
        Integer maxLength = Math.max(words1.size(), words2.size());
        if (minLength == 0 || maxLength == 0) return 0.000;

        Decimal total = 0.000;
        for (Integer i = 0; i < minLength; i++) {
            MetaphoneResult mp1 = getMetaphoneFull(words1[i]);
            MetaphoneResult mp2 = getMetaphoneFull(words2[i]);

            List<Decimal> allScores = new List<Decimal>{
                getMetaphoneSimilarity(mp1.primary, mp2.primary),
                getMetaphoneSimilarity(mp1.primary, mp2.alternate),
                getMetaphoneSimilarity(mp1.alternate, mp2.primary),
                getMetaphoneSimilarity(mp1.alternate, mp2.alternate)
            };

            Decimal bestMatch = 0.0;
            for (Decimal score : allScores) {
                if (score > bestMatch) bestMatch = score;
            }

            total += bestMatch;
        }

        return (total / maxLength).setScale(3);
    }

    // 🔹 Порівняння кожного слова з усіма (незалежно від порядку)
    public static Decimal getWordLevelSimilarity(String name1, String name2) {
        if (String.isBlank(name1) || String.isBlank(name2)) return 0.000;

        List<String> words1 = normalizeWords(name1);
        List<String> words2 = normalizeWords(name2);

        if (words1.isEmpty() || words2.isEmpty()) return 0.000;

        Decimal total = 0.000;

        for (String w1 : words1) {
            MetaphoneResult mp1 = getMetaphoneFull(w1);

            Decimal bestMatch = 0.0;

            for (String w2 : words2) {
                MetaphoneResult mp2 = getMetaphoneFull(w2);

                List<Decimal> scores = new List<Decimal>{
                    getMetaphoneSimilarity(mp1.primary, mp2.primary),
                    getMetaphoneSimilarity(mp1.primary, mp2.alternate),
                    getMetaphoneSimilarity(mp1.alternate, mp2.primary),
                    getMetaphoneSimilarity(mp1.alternate, mp2.alternate)
                };

                for (Decimal score : scores) {
                    if (score > bestMatch) bestMatch = score;
                }
            }

            total += bestMatch;
        }

        return (total / words1.size()).setScale(3);
    }

    // 🔹 Розбиття і транслітерація фрази
    private static List<String> normalizeWords(String name) {
        return StringUtilsEx.normalizeDiacritics(StringUtilsEx.transliterateCyrillicToLatin(name))
            .trim().replaceAll('\\s+', ' ')
            .toUpperCase().split(' ');
    }
    
    // Метод обрахунку збігів з усередненням усіх біграм незалежно від позицій
    //  - порівнює всі слова з name1 з усіма словами з name2,
    //  - для кожної пари бере найкращу метафонну схожість (по 4 комбінаціях primary/alternate),
    //  - повертає середнє значення для всіх пар.    
    public static Decimal getAverageMetaphoneSimilarity(String name1, String name2) {
        if (String.isBlank(name1) || String.isBlank(name2)) return 0.000;
    
        List<String> words1 = normalizeWords(name1);
        List<String> words2 = normalizeWords(name2);
    
        if (words1.isEmpty() || words2.isEmpty()) return 0.000;
    
        Decimal total = 0.000;
        Integer count = 0;
    
        for (String w1 : words1) {
            MetaphoneResult mp1 = getMetaphoneFull(w1);
    
            for (String w2 : words2) {
                MetaphoneResult mp2 = getMetaphoneFull(w2);
    
                List<Decimal> scores = new List<Decimal>{
                    getMetaphoneSimilarity(mp1.primary, mp2.primary),
                    getMetaphoneSimilarity(mp1.primary, mp2.alternate),
                    getMetaphoneSimilarity(mp1.alternate, mp2.primary),
                    getMetaphoneSimilarity(mp1.alternate, mp2.alternate)
                };
    
                Decimal best = 0.0;
                for (Decimal score : scores) {
                    if (score > best) best = score;
                }
    
                total += best;
                count++;
            }
        }
    
        return count == 0 ? 0.000 : (total / count).setScale(3);
    }
    
    //--- Просте порівняння двох primary Metaphone-кодів за унікальними літерами (без позиційності)   
    public static Decimal compareMetaphoneLetters(String mph1, String mph2) {
        if (String.isBlank(mph1) || String.isBlank(mph2)) return 0.000;
    
        Set<String> set1 = new Set<String>();
        Set<String> set2 = new Set<String>();
    
        for (Integer i = 0; i < mph1.length(); i++) {
            set1.add(mph1.substring(i, i + 1));
        }
        for (Integer i = 0; i < mph2.length(); i++) {
            set2.add(mph2.substring(i, i + 1));
        }
    
        Set<String> intersection = new Set<String>(set1);
        intersection.retainAll(set2);
    
        Set<String> union = new Set<String>(set1);
        union.addAll(set2);
    
        return union.isEmpty() ? 0.000 : ((Decimal) intersection.size() / union.size()).setScale(3);
    }
 
     //--- Порівняння primary і alternate кодів з обох сторін
    /* 
    public static Decimal compareMetaphoneLetterSets(Set<String> codes1, Set<String> codes2) {
        if (codes1 == null || codes2 == null || codes1.isEmpty() || codes2.isEmpty()) return 0.000;
    
        // Упрощення: замість букв — самі коди
        Set<String> set1 = new Set<String>(codes1);
        Set<String> set2 = new Set<String>(codes2);
    
        Set<String> intersection = new Set<String>(set1);
        intersection.retainAll(set2);
    
        Set<String> union = new Set<String>(set1);
        union.addAll(set2);
    
        return union.isEmpty() ? 0.000 : ((Decimal) intersection.size() / union.size()).setScale(3);
    }
    */
     
     public static Decimal compareMetaphoneLetterSets(Set<String> codes1, Set<String> codes2) {
        if (codes1 == null || codes2 == null || codes1.isEmpty() || codes2.isEmpty()) return 0.000;
    
        Set<String> letters1 = new Set<String>();
        Set<String> letters2 = new Set<String>();
    
        for (String code : codes1) {
            for (Integer i = 0; i < code.length(); i++) {
                letters1.add(code.substring(i, i + 1));
            }
        }
        for (String code : codes2) {
            for (Integer i = 0; i < code.length(); i++) {
                letters2.add(code.substring(i, i + 1));
            }
        }
    
        Set<String> intersection = new Set<String>(letters1);
        intersection.retainAll(letters2);
    
        Set<String> union = new Set<String>(letters1);
        union.addAll(letters2);
    
        return union.isEmpty() ? 0.000 : ((Decimal) intersection.size() / union.size()).setScale(3);
    }
    
}