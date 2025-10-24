public class namesDuplicateSearch {
    // Функція для перевірки наявності спільних слів у назвах
    public static Boolean hasCommonWords(String name1, String name2) {
        Set<String> words1 = new Set<String>(name1.toLowerCase().split(' '));
        Set<String> words2 = new Set<String>(name2.toLowerCase().split(' '));
        
        // Перевіряємо наявність спільних слів між двома наборами
        words1.retainAll(words2);
        
        return !words1.isEmpty();
    }   

    // Функція для перевірки наявності спільних слів і підрахунку їх кількості
    public static Integer countCommonWords(String name1, String name2) {
        // Розбиваємо назви акаунтів на слова і перетворюємо на множини
        Set<String> words1 = new Set<String>(name1.toLowerCase().split(' '));
        Set<String> words2 = new Set<String>(name2.toLowerCase().split(' '));
        
        // Створюємо копію першого набору, оскільки .retainAll змінює оригінальний набір
        Set<String> commonWords = new Set<String>(words1);
        
        // Залишаємо лише спільні слова
        commonWords.retainAll(words2);
        
        // Повертаємо кількість спільних слів
        return commonWords.size();
    }

    //Кількість слів у рядку
    public static Integer countWordsInString(String s) {
        Set<String> words = new Set<String>(s.toLowerCase().split(' '));
        return words.size();
    }
    
    //Підхід із використанням Levenshtein Distance
    public static Integer levenshteinDistance(String s1, String s2) {
        if (s1 == null || s2 == null) {
            return -1;
        }

        Integer len1 = s1.length();
        Integer len2 = s2.length();
        
        // Використовуємо список списків для двовимірного масиву
        List<List<Integer>> d = new List<List<Integer>>();
        
        // Ініціалізуємо двовимірний список
        for (Integer i = 0; i <= len1; i++) {
            d.add(new List<Integer>());
            for (Integer j = 0; j <= len2; j++) {
                d[i].add(0);  // Заповнюємо нулями
            }
        }

        for (Integer i = 0; i <= len1; i++) {
            d[i][0] = i;
        }
        for (Integer j = 0; j <= len2; j++) {
            d[0][j] = j;
        }

        for (Integer i = 1; i <= len1; i++) {
            for (Integer j = 1; j <= len2; j++) {
                Integer cost = (s1.charAt(i - 1) == s2.charAt(j - 1)) ? 0 : 1;
                d[i][j] = Math.min(
                    Math.min(d[i - 1][j] + 1, d[i][j - 1] + 1),
                    d[i - 1][j - 1] + cost
                );
            }
        }

        return d[len1][len2];
    }
    
    // Метод для розрахунку Jaccard Similarity
    public static Double jaccardSimilarity(String name1, String name2) {
        // Розбиваємо рядки на слова і приводимо їх до нижнього регістру
        Set<String> words1 = new Set<String>(name1.toLowerCase().split(' '));
        Set<String> words2 = new Set<String>(name2.toLowerCase().split(' '));
        
        // Створюємо множину для об'єднаних елементів (A U B)
        Set<String> unionSet = new Set<String>(words1);
        unionSet.addAll(words2);
        
        // Створюємо множину для перетину (A ∩ B)
        Set<String> intersectionSet = new Set<String>(words1);
        intersectionSet.retainAll(words2);
        
        // Обчислюємо Jaccard Similarity як відношення перетину до об'єднання
        if (unionSet.size() == 0) {
            return 0.0;
        }
        
        Double similarity = (Double)intersectionSet.size() / unionSet.size();
        return similarity;
    }

    // Код для Soundex
    public static String soundex(String word) {
        if (word == null || word.trim().length() == 0) {
            return null;
        }

        // Масив для кодування Soundex з кирилицею та розширеними латинськими літерами
        Map<String, String> soundexMap = new Map<String, String>{
            // Латинські літери
            'B' => '1', 'F' => '1', 'P' => '1', 'V' => '1',
            'C' => '2', 'G' => '2', 'J' => '2', 'K' => '2', 'Q' => '2', 'S' => '2', 'X' => '2', 'Z' => '2',
            'D' => '3', 'T' => '3',
            'L' => '4',
            'M' => '5', 'N' => '5',
            'R' => '6',
            
            // Кирилиця
            'Б' => '1', 'П' => '1', 'В' => '1', 'Ф' => '1',
            'Г' => '2', 'Ґ' => '2', 'К' => '2', 'Х' => '2', 'Ц' => '2', 'Ч' => '2', 'Ш' => '2', 'Щ' => '2', 'С' => '2', 'З' => '2',
            'Д' => '3', 'Т' => '3',
            'Л' => '4',
            'М' => '5', 'Н' => '5',
            'Р' => '6',
            
            // Розширені латинські літери
            'Ç' => '2', 'Ś' => '2', 'Š' => '2', 'Ž' => '2',
            'Ł' => '4', 'Ñ' => '5',
            
            // Голосні та інші літери можна ігнорувати (в Soundex вони зазвичай не враховуються)
            'A' => '', 'E' => '', 'I' => '', 'O' => '', 'U' => '', 'Y' => '',
            'Ä' => '', 'Ö' => '', 'Ü' => '', 'Ó' => '', 'É' => '', 'Á' => '',
            'А' => '', 'О' => '', 'Е' => '', 'І' => '', 'У' => '', 'И' => '', 'Й' => '', 'Ї' => '', 'Є' => '', 'Я' => '', 'Ю' => ''
        };


        // Приводимо слово до верхнього регістру
        word = word.toUpperCase();

        // Беремо першу літеру
        String soundexCode = word.substring(0, 1);

        // Проходимо по решті літер і кодуємо їх
        for (Integer i = 1; i < word.length(); i++) {
            String currentChar = String.valueOf(word.charAt(i)); // Оскільки ми використовуємо тип String
            
            // Пропускаємо голосні та деякі інші літери
            if ('AEIOUHWY'.contains(currentChar)) {
                continue;
            }
            
            // Додаємо коди до результату
            if (soundexMap.containsKey(currentChar)) {
                String code = soundexMap.get(currentChar);
                if (!soundexCode.endsWith(code)) {  // Уникаємо повторень
                    soundexCode += code;
                }
            }
        }
        
        // Доповнюємо або обрізаємо до 4 символів
        if (soundexCode.length() >= 4) {
            return soundexCode.substring(0, 4);
        } else {
            // Додаємо нулі до кінця рядка
            while (soundexCode.length() < 4) {
                soundexCode += '0';
            }
            return soundexCode;
        }
    }
    
}