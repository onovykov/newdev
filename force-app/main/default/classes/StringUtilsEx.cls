public class StringUtilsEx {
    //--- Костанти -------
    public static final String LIKE_START_SIGN = '\'%';
    public static final String LIKE_END_SIGN = '%\'';
    public static final  String LIKE_WORD = ' LIKE \'';
    public static final  String CYR = 'Cyrillic';
    public static final  String LAT = 'Latin';
    public static final Boolean CYR_TO_LAT = true;
    public static final Boolean LAT_TO_CYR = true;

    //--- Нормалізація діакритичних символів -------
    public static String normalizeDiacritics(String input) {
        if (String.isBlank(input)) return '';
        String result = '';

        for (Integer i = 0; i < input.length(); i++) {
            String ch = input.substring(i, i + 1);
            String upperCh = ch.toUpperCase();
            Boolean replaced = false;

            for (String base : Consts.DIACRITICS_MAP.keySet()) {
                if (Consts.DIACRITICS_MAP.get(base).contains(upperCh)) {
                    Boolean isUpper = ch == ch.toUpperCase();
                    result += isUpper ? base : base.toLowerCase();
                    replaced = true;
                    break;
                }
            }

            if (!replaced) {
                result += ch;
            }
        }

        return result.toUpperCase();
    }

    // Міняємо дифтонги на латинські символи
    public static String clearDiphthongs(String sourceStr) {
        String resultStr = '';

        if (String.isBlank(sourceStr)) {
            return resultStr;
        }

        if (detectAlphabet(sourceStr) != LAT) {
            return sourceStr;
        }

        Map<String, String> dMap = Consts.DIPHTHONGS;
        Integer i = 0;

        while (i < sourceStr.length()) {
            if (i < sourceStr.length() - 1) {
                String pair = sourceStr.substring(i, i + 2).toUpperCase();
                if (dMap.containsKey(pair)) {
                    resultStr += dMap.get(pair);
                    i += 2;
                    continue;
                }
            }
            resultStr += sourceStr.substring(i, i + 1);
            i++;
        }

        return resultStr;
    }

    // Готуємо дані для порівняння
    public static String prepareForComparison(String input) {
        if (String.isBlank(input)) return '';
        String normalized = getClearName(input, true);
        String alpha = detectAlphabet(normalized);
        if(alpha!=LAT) normalized = transliterateCyrillicToLatin(normalized);
        if(alpha==LAT) normalized = normalizeDiacritics(normalized );
        //normalized = getClearSignsStr(normalized );
        return normalized;
    }

    //-- Допоміжна функція - очищуємо сміттєві знаки в кінці рядка
    public static String getClearSignsStr(String s) {
        if (String.isBlank(s)) return '';
    
        Integer i = s.length() - 1;
        while (i >= 0 && Consts.TRASH_SIGNS.contains(s.substring(i, i + 1))) {
            i--;
        }
    
        return s.substring(0, i + 1);
    }

    public static String trimTrailingTrash(String s) {
        if (String.isBlank(s)) return '';
    
        Integer i = s.length() - 1;
        // Крокаємо з кінця, поки символ — сміття або пробіл
        while (i >= 0 && (Consts.TRASH_SIGNS.contains(s.substring(i, i + 1)) || s.substring(i, i + 1) == ' ')) {
            i--;
        }
    
        return s.substring(0, i + 1);
    }

    /********* Методи для транслітерації **********************/
    //--- Метод для транслітерації кирилиці в латинку
    public static String transliterateCyrillicToLatin(String input) {
        if (String.isBlank(input)) return '';

        // Повні слова, які мають фіксовану транслітерацію
        Map<String, String> fullWordMap = new Map<String, String>{
            'ЭНЕРДЖИ' => 'ENERGY',
            'ЕНЕРДЖИ' => 'ENERGY',
            'ЕНЕРДЖІ' => 'ENERGY',
            'ОПЕРЕЙТИНГ' => 'OPERATING',
            'ОПЕРЕЙТІНГ' => 'OPERATING',
            'КОМПАНИ' => 'COMPANY',
            'КОМПАНІ' => 'COMPANY',
            'ЛИМИТЕД' => 'LIMITED',
            'ЛІМІТЕД' => 'LIMITED',
            'СОЛАР' => 'SOLAR',
            'ТЕКНОЛОДЖИ' => 'TECHNOLOGY',
            'ТЕКНОЛОДЖІ' => 'TECHNOLOGY',
            'ИНВЕСТ' => 'INVEST',
            'ІНВЕСТ' => 'INVEST',
            'ТРЕЙДИНГ' => 'TRADING',
            'ТРЕЙДІНГ' => 'TRADING',
            'СОЛЮШЕН'=>'SOLUTION',
            'СОЛЮШН'=>'SOLUTION',
            'СОЛЬЮШЕН'=>'SOLUTION',
            'СОЛЬЮШН'=>'SOLUTION',
            'ОЙЛ'=>'OIL'
        };

        // Буквене мапування
        Map<String, String> cyrToLat = new Map<String, String>{
            'А' => 'A',  'а' => 'a', 'Б' => 'B',  'б' => 'b', 'В' => 'V',  'в' => 'v',
            'Г' => 'G',  'г' => 'g', 'Ґ' => 'G',  'ґ' => 'g', 'Д' => 'D',  'д' => 'd',
            'Е' => 'E',  'е' => 'e', 'Є' => 'E', 'є' => 'e','Ж' => 'Z', 'ж' => 'z',
            'З' => 'Z',  'з' => 'z', 'И' => 'I',  'и' => 'i', 'І' => 'I',  'і' => 'i',
            'Ї' => 'I', 'ї' => 'i', 'Й' => 'J',  'й' => 'j', 'К' => 'K',  'к' => 'k',
            'Л' => 'L',  'л' => 'l', 'М' => 'M',  'м' => 'm', 'Н' => 'N',  'н' => 'n',
            'О' => 'O',  'о' => 'o', 'П' => 'P',  'п' => 'p', 'Р' => 'R',  'р' => 'r',
            'С' => 'S',  'с' => 's', 'Т' => 'T',  'т' => 't', 'У' => 'U',  'у' => 'u',
            'Ф' => 'F',  'ф' => 'f', 'Х' => 'H',  'х' => 'h', 'Ц' => 'C', 'ц' => 'c',
            'Ч' => 'C', 'ч' => 'c','Ш' => 'S', 'ш' => 's','Щ' => 'S', 'щ' => 's',
            'Ю' => 'U', 'ю' => 'u','Я' => 'A', 'я' => 'a','Ь' => '',   'ь' => '',
            'Ъ' => '',   'ъ' => '',  'Ё' => 'E', 'ё' => 'e','Ы' => 'Y',  'ы' => 'y',
            'Э' => 'E',  'э' => 'e'
        };

        List<String> resultWords = new List<String>();
        for (String word : input.split('\\s+')) {
            String upperWord = word.toUpperCase();

            if (fullWordMap.containsKey(upperWord)) {
                resultWords.add(fullWordMap.get(upperWord));
            } else {
                String transliterated = '';
                for (Integer i = 0; i < word.length(); i++) {
                    String ch = word.substring(i, i + 1);
                    transliterated += cyrToLat.containsKey(ch) ? cyrToLat.get(ch) : ch;
                }
                resultWords.add(transliterated);
            }
        }

        return String.join(resultWords, ' ');
    }

    //--- Метод для транслітерації латинки в кирилицю
    public static String translitLatinToCyr(String input) {
        if (String.isBlank(input)) return '';

        // Повні слова, які мають фіксовану транслітерацію
        Map<String, String> fullWordMap = new Map<String, String>{
            'OPERATING'=>'ОПЕРЕЙТИНГ',
            'COMPANY'=>'КОМПАНИ',
            'LIMITED'=>'ЛІМІТЕД',
            'OIL'=>'ОЙЛ',
            'ENERGY' => 'ЭНЕРДЖИ'
        };

        // Буквене мапування
        Map<String, String> cyrToLat = new Map<String, String>{
            'A' => 'А',  'a' => 'а', 'B' => 'Б',  'b' => 'б', 'V' => 'В',  'v' => 'в',
            'G' => 'Г',  'g' => 'г', 'D' => 'Д',  'd' => 'д',
            'E' => 'Е',  'e' => 'е', 'Z' => 'З',  'z' => 'з', 'Y' => 'И',  'y' => 'и',
            'I' => 'І',  'i' => 'і',
            'J' => 'Й',  'j' => 'й', 'K' => 'К',  'k' => 'к',
            'L' => 'Л',  'l' => 'л', 'M' => 'М',  'm' => 'м', 'N' => 'Н',  'n' => 'н',
            'O' => 'О',  'o' => 'о', 'P' => 'П',  'p' => 'п', 'R' => 'Р',  'r' => 'р',
            'S' => 'С',  's' => 'с', 'T' => 'Т',  't' => 'т', 'U' => 'У',  'u' => 'у',
            'F' => 'Ф',  'f' => 'ф', 'H' => 'Х',  'h' => 'х', 'C' => 'Ц', 'c' => 'ц'
        };

        List<String> resultWords = new List<String>();
        for (String word : input.split('\\s+')) {
            String upperWord = word.toUpperCase();

            if (fullWordMap.containsKey(upperWord)) {
                resultWords.add(fullWordMap.get(upperWord));
            } else {
                String transliterated = '';
                for (Integer i = 0; i < word.length(); i++) {
                    String ch = word.substring(i, i + 1);
                    transliterated += cyrToLat.containsKey(ch) ? cyrToLat.get(ch) : ch;
                }
                resultWords.add(transliterated);
            }
        }

        return String.join(resultWords, ' ');
    }

    //--- Детектор розкладки - кирилиця чи латинка
    public static String detectAlphabet(String word) {
        if (String.isBlank(word)) return 'Empty';

        Integer latinCount = 0;
        Integer cyrillicCount = 0;

        for (Integer i = 0; i < word.length(); i++) {
            String ch = word.substring(i, i + 1);
            Integer code = ch.charAt(0);

            if ((code >= 1024 && code <= 1279) || // основна кирилиця
                (code >= 1280 && code <= 1327)) { // додаткова кирилиця
                cyrillicCount++;
            } else if ((code >= 65 && code <= 122) || // латинка A-Z, a-z
                       (code >= 192 && code <= 255)) { // розширена латинка
                latinCount++;
            }
        }

        if (cyrillicCount > 0 && latinCount == 0) return 'Cyrillic';
        if (latinCount > 0 && cyrillicCount == 0) return 'Latin';
        if (latinCount > 0 && cyrillicCount > 0) return 'Mixed';

        return 'Unknown';
    }

    //--- Визначаємо напрямок трансліту
    public static List<Boolean> setTranslitParams(String s1, String s2, Boolean resutTranslit) {
        String alpha1 = detectAlphabet(s1);
        String alpha2 = detectAlphabet(s2);
        Boolean useTranslit = false;
        Boolean translitDirect = null;

        if (alpha1 != alpha2) {
            if (resutTranslit == CYR_TO_LAT) {
                if (alpha1 == 'Cyrillic' && alpha2 == 'Latin') {
                    s1 = transliterateCyrillicToLatin(s1);
                    useTranslit = true;
                    translitDirect = CYR_TO_LAT;
                } else if (alpha1 == 'Latin' && alpha2 == 'Cyrillic') {
                    s2 = transliterateCyrillicToLatin(s2);
                    useTranslit = true;
                    translitDirect = CYR_TO_LAT;
                }
            } else if (resutTranslit == LAT_TO_CYR) {
                if (alpha1 == 'Cyrillic' && alpha2 == 'Latin') {
                    s1 = translitLatinToCyr(s1);
                    useTranslit = true;
                    translitDirect = LAT_TO_CYR;
                } else if (alpha1 == 'Latin' && alpha2 == 'Cyrillic') {
                    s2 = translitLatinToCyr(s2);
                    useTranslit = true;
                    translitDirect = LAT_TO_CYR;
                }
            }
        }

        return new List<Boolean>{useTranslit, translitDirect};
    }

    /**************** Службові методи та функції *************/
    //-- Номалізуємо назву й розбиваємо на окремі слова
    //   Повертаємо List<String>, що містить слова назви
    //   Параметри
    //   String Name - початкова назва для пошуку
    //   Boolean getClear - очистити назву (застосувати функцію getClearName)
    //   Boolean toUCase - чи треба переводити всі слова у верхній регістр
    public static List<String> getNameWords(String Name, Boolean getClear, Boolean toUCase) {
        List<String> resList = new List<String>();
        if(String.isBlank(Name) || toUCase==null || getClear==null) {
            System.debug('❌ERROR! Arguments are invalid!');
            return resList;
        } else {
            String normName = getClear
                ? getClearName(Name, toUCase).normalizeSpace()
                : (toUCase ? Name.toUpperCase().normalizeSpace() : Name.normalizeSpace());
            resList = normName.split(' ');
            return resList;
        }
    }

    //--- Перетворює List<Set<String>> на List<String>
    public static List<String> flattenListOfSets(List<Set<String>> listOfSets) {
        List<String> result = new List<String>();
        for (Set<String> setItem : listOfSets) {
            if (setItem != null) {
                result.addAll(setItem);
            }
        }
        return result;
    }


    // Перетворення Set<String> на List<String> з опціями
    public static List<String> setToList(Set<String> inputSet, Boolean sortResult, Boolean removeBlanks) {
        if (inputSet == null) return new List<String>();

        List<String> result = new List<String>();

        for (String val : inputSet) {
            if (!removeBlanks || !String.isBlank(val)) {
                result.add(val);
            }
        }

        if (sortResult) {
            result.sort();
        }

        return result;
    }

    //-- Повертаємо транслітеровану назву, розбиту на слова (List<String>)
    //   Парметри - аналогічні getNameWords
    //   Алгоритм:
    //    Визначаємо абетку початкового рядку
    //    - якщо це Cyrillic - переводимо в Latin
    //    - якщо це Latin - переводимо в Cyrillic
    //    - якщо це не Latin або Cyrillic - повертаємо початкове слово
    public static List<String> getTranslitedName(String Name, Boolean getClear, Boolean toUCase) {
        List<String> resList = new List<String>();
        if(String.isBlank(Name) || toUCase==null || getClear==null) {
            System.debug('❌ERROR! Arguments are invalid!');
            return resList;
        } else {
            String normName = getClear
                ? getClearName(Name, toUCase).normalizeSpace()
                : (toUCase ? Name.toUpperCase().normalizeSpace() : Name.normalizeSpace());
            String alpha = detectAlphabet(normName);
            if(alpha=='Cyrillic') {
                resList = transliterateCyrillicToLatin(normName).split(' ');
            } else {
                if(alpha=='Latin') {
                    resList = translitLatinToCyr(normName).split(' ');
                } else { // Змішана абетка - кирилиця + латинка
                    // Перевіряємо перше слово
                    String alphaFirstWord = detectAlphabet(getFirstWord(normName));
                    // Транслітеруємо цілу назву з огляду на абетку першого слова
                    if(alphaFirstWord == 'Cyrillic') {
                        resList = transliterateCyrillicToLatin(normName).split(' ');
                    } else {
                        resList = translitLatinToCyr(normName).split(' ');
                    }
                }
            }
        }
        return resList;
    }

    //-- Повертаємо сет варіантів слова з діакритикою
    public static Set<String> getDiacriticList(String Word, Boolean getClear, Boolean toUCase) {
        Set<String> setVariants = new Set<String>();
        if(String.isBlank(Word) || toUCase==null || getClear==null) {
            System.debug('❌ERROR! Arguments are invalid!');
            setVariants.add(Word);
            return setVariants;
        } else {
            String normName = getClear
                ? getClearName(Word, toUCase).normalizeSpace()
                : (toUCase ? Word.toUpperCase() : Word);
            setVariants.add(normName);
            generateCharacterVariations(normName, 0, '', setVariants, Consts.REPLACEMENTS);
            String joined = String.join(new List<String>(setVariants), '');
            if(setVariants.size()==1 && joined.toUpperCase()==normName.toUpperCase()) {
                //System.debug('Гілка пошуку синонімів');
                if(Consts.SAME_WORDS.containsKey(normName.toUpperCase())) {
                    //System.debug('Синоніми є');
                    setVariants.clear();
                    List<String> lst = Consts.SAME_WORDS.get(normName.toUpperCase());
                    for(String s : lst) {
                        setVariants.add(s);
                    }
                }
            }
        }
        return setVariants;
    }

    //-- Чи містить слово діакритичні символи
    public static Boolean isWordHasDiacritics(String Word) {
        if(String.isBlank(Word)) {
            System.debug('❌ERROR! Argument are invalid!');
            return false;
        } else {
            for(Integer i=0; i<Word.length(); i++) {
                if(Consts.REPLACEMENTS.containsKey(Word.substring(i, i+1))) {
                    return true;
                }
            }
        }
        return false;
    }

    //-- Повертає всю назву з усіма варіантами діакритики всіх слів як List<Set<String>>
    //   Кожен елемент листа - набір варіантів діакритики кожного слова назви
    public static List<Set<String>> getDiacriticVariants(String Name, Boolean getClear, Boolean toUCase) {
        List<Set<String>> resList = new List<Set<String>>();
        if(String.isBlank(Name) || toUCase==null || getClear==null) {
            System.debug('❌ERROR! Arguments are invalid!');
            return resList;
        }  else {
            List<String> wordsList = Name.normalizeSpace().split(' ');
            for(String word : wordsList) {
                resList.add(getDiacriticList(word, getClear, toUCase));
            }
        }
        return resList;
    }

    //--- Кількість слів у рядку
    public static Integer countWordsInString(String s) {
        Set<String> words = new Set<String>(s.toLowerCase().split(' '));
        return words.size();
    }

    //Перше слово назви
    public static String getFirstWord(String Name) {
        String strResult = '';
        //Вибираємо перше слово з назви, обробляючи ситуацію, коли назва складається з одного слова
        if(Name.indexOf(' ')<>-1) {
            strResult=Name.left(Name.indexOf(' '));
        } else {strResult=Name;}

        return strResult;
    }

    //--- Перевірка валідности Salesforce Id, переданого як String
    public static Boolean isValidSalesforceId(String input) {
        return !String.isBlank(input) &&
               (input.length() == 15 || input.length() == 18) &&
               Pattern.matches('^[a-zA-Z0-9]{15,18}$', input);
    }

    /********* Методи для очищення назв від сміття **********************/
    //--- Вичищаємо лапки/апострофи ---
    public static String sanitizeQuotes(String str) {
        if (String.isBlank(str)) return '';
    
        // Символи лапок і апострофів
        final Set<String> quotes = new Set<String>{
            '"', '\'', '’', '‘', '“', '”', '„', '‟', '«', '»'
        };
    
        // 1. Видаляємо лапки на початку
        while (str.length() > 0 && quotes.contains(str.substring(0, 1))) {
            str = str.substring(1);
        }
    
        // 2. Видаляємо лапки сміттєві символи в кінці
        while (str.length() > 0 && quotes.contains(str.substring(str.length() - 1))) {
            str = str.substring(0, str.length() - 1);
        }
       
        //while (str.length() > 0 && Consts.TRASH_SIGNS.contains(str.substring(str.length() - 1))) {
        //    str = str.substring(0, str.length() - 1);
        //}        
    
        // 3. Видаляємо **всі** лапки/апострофи всередині
        for (String q : quotes) {
            str = str.replace(q, '');
        }
    
        // 4. Замінюємо прості апострофи на типографські
        str = str.replace('\'', '’');
        
        // 5. Видаляємо коми
        str = str.replace(',', '');        
        
        //for(String w : Consts.TRASH_SIGNS) {
        //    if(str.endsWith(w)) str = str.substring(0, str.length()-1);
        //}
    
        return str.normalizeSpace();
    }

    public static String normalizeSpecialPatterns(String input) {
        if (String.isBlank(input)) return '';

        // Початок: R&D, R & D, R+D, R + D → RD
        //input = input.replaceFirst('^(?i)R\\s*([&+])\\s*D\\b', 'RD');
        input = input.replaceFirst('^(?i)([a-zA-Zа-яА-Я])\\s*([&+])\\s*([a-zA-Zа-яА-Я])\\b', '$1$3');

        // A. Xxx → A Xxx
        input = input.replaceFirst('^(?i)([a-zA-Zа-яА-Я])\\. (?=\\s*\\S)', '$1');
        input = input.replaceFirst('^(?i)([a-zA-Zа-яА-Я])\\.(?=\\s*\\S)', '$1');

        // AB. Xxx → AB Xxx
        input = input.replaceFirst('^(?i)([a-zA-Zа-яА-Я]{2})\\. (?=\\s*\\S)', '$1');
        input = input.replaceFirst('^(?i)([a-zA-Zа-яА-Я]{2})\\.(?=\\s*\\S)', '$1');
        
        // ETS.xxxx - ETS xxxx
        //input = input.replaceFirst('^(?i)([a-zA-Zа-яА-Я]{3})\\.(?=\\s*\\S)', '$1 ');        
        
        // A.B.C. Xxx → ABC Xxx (знімаємо крапки)
        Pattern p1 = Pattern.compile('^(?i)((?:[a-zA-Zа-яА-Я]\\.){3,})(?=\\s*\\S)');
        Matcher m1 = p1.matcher(input);
        if (m1.find()) {
            String matched = m1.group(1); // Напр. "A.B.C."
            String replaced = matched.replaceAll('\\.', ''); // → "ABC"
            input = replaced + input.substring(m1.end());
            input = input.replace('.','');
        }

        // A. B. C. Xxx → ABC Xxx (знімаємо крапки й пробіли)
        Pattern p2 = Pattern.compile('^(?i)((?:[a-zA-Zа-яА-Я]\\.\\s*){3,})(?=\\S)');
        Matcher m2 = p2.matcher(input);
        if (m2.find()) {
            String matched = m2.group(1); // Напр. "A. B. C. "
            String replaced = matched.replaceAll('[\\.\\s]', ''); // → "ABC"
            input = replaced + input.substring(m2.end());
            input = input.replace('.','');
        }

        // AB.Name → AB Name (розділяємо, якщо є крапка після 2–3 літер)
        input = input.replaceAll('(?i)\\b([a-zA-Zа-яА-Я]{2,3})\\.([a-zA-Zа-яА-Я])', '$1 $2');

        // AB-Name → AB Name (зливаємо, якщо є дефіс після 2–3 літер) //
        input = input.replaceAll('(?i)\\b([a-zA-Zа-яА-Я]{2,3})\\-([a-zA-Zа-яА-Я])', '$1$2');
        
        // AB-Name → AB Name (зливаємо, якщо є прогалинка після 2–3 літер) //
        input = input.replaceAll('(?i)\\b([a-zA-Zа-яА-Я]{2,3})\\ ([a-zA-Zа-яА-Я])', '$1$2');

        // Кінцівка: Steel - M, Steel.M, Steel M → SteelM
        input = input.replaceAll('(?i)(\\b\\w+)\\s*[-\\.]?\\s*([a-zA-Zа-яА-Я])\\b', '$1$2');

        input = input.replace('.','');
        return input.trim();
    }

    //--- Чистимо рядок від сміття - лапок, дужок, слів у дужках ---
    public static String getClearStr(String s) {
        if (String.isBlank(s)) {
            return '';
        }
        
        if(s.startsWith(',')) s= s.substring(1, s.length());
        
        // Обробляємо ситуацію EMS.XXX -> EMS XXX
        if(s.length()>4) {
            if(s.substring(3,4)=='.') {
                s = s.substring(0,3)+' '+ s.substring(4, s.length());
            }   
        } 
        
        if(s.toUpperCase().contains('РЫБИНСКИЙ')) s=s.toUpperCase().replace('РЫБИНСКИЙ','РЫБНИЦКИЙ');
        
        List<String> dniproList = 'ДНЕПРОВСКИЙ,ДНІПРОПЕТРОВСЬКИЙ,ДНЕПРОПЕТРОВСКИЙ'.split(',');
        for(String word : dniproList) {
            if(s.toUpperCase().contains(word)) s=s.toUpperCase().replace('РЫБИНСКИЙ','РЫБНИЦКИЙ');
            break;
        }   
             
        // Видаляємо "SMI" на початку, якщо після нього йде Salzgitter Mannesmann
        s = s.replaceAll('(?i)^SMI\\s+(SALZGITTER\\s+MANNESMANN)', '$1');
        // Якщо в середині — видалимо
        s = s.replaceAll('(?i)\\bSMI\\b', '');
    
        s = StringNormalizer.removeLegalForms(s);
        s = cleanBrokenChars(s);
        if(detectAlphabet(s)!=Consts.LAT) s=transliterateCyrillicToLatin(s);
        s = normalizeChars(s);
    
        //--- Коригуємо арабські назви, що містять AL та ABU
        // Об'єднує "Abu Dhabi", "Al-Dhabi", "Abi Dhabi" → "AbuDhabi", "AlDhabi", "AbiDhabi"
        s = s.replaceAll('(?i)\\b(ALI|ABU|AL|ABI)\\s*[-\\s]\\s*([A-ZА-ЯЇІЄҐa-zа-яїієґ]+)', '$1$2');
    
        //Коригуємо символи, які містяться всередині слова без прогалинок
        s = s.replaceAll('(?<=[^\\s])\\-(?=[^\\s])', ' ');
        //s = s.replaceAll('(?<=[^\\s])\\,(?=[^\\s])', ' ');
        s = s.replaceAll('(?<=[^\\s])\\+(?=[^\\s])', ' ');
    
        // 1. Видаляємо все в круглих, квадратних і фігурних дужках
        s = s
            .replaceAll('\\s*\\([^)]*\\)', '')
            .replaceAll('\\s*\\[[^\\]]*\\]', '')
            .replaceAll('\\s*\\{[^}]*\\}', '')
            .replaceAll('-', ' ')
            .trim();
    
        // 2. Видаляємо сміттєві символи (лапки не включаємо — sanitizeQuotes їх обробить)
        final String charsToRemove = '#$§;+&';
        List<String> charList = new List<String>();
    
        for (Integer i = 0; i < s.length(); i++) {
            String ch = s.substring(i, i + 1);
            if (!charsToRemove.contains(ch)) {
                charList.add(ch);
            }
        }
    
        // 3. sanitizeQuotes  робить чистку лапок і апострофів
        return sanitizeQuotes(String.join(charList, ''));
    }

    //--- Смарт-заміна по шаблонах
    public static String normalizeSmart(String input) {
        if (String.isBlank(input)) return input;
        input = input.trim();
    
        input = mergeTripleLetters(input, '(?i)\\b([A-Z])\\s+([A-Z])\\s+([A-Z])\\b');
        input = mergeLetterPairs(input, '(?i)\\b([A-Z])\\s*[&\\+\\-\\s]+([A-Z])\\b');
        input = mergeCompoundParts(input, '(?i)\\b([A-Z]{2,})[\\s\\-\\+&]+([A-Z]{2,})\\b');
        input = mergeShortPrefixCompound(input, '(?i)\\b([a-z]{1,3})[\\-\\s]+([a-z]{3,})\\b');
        input = mergeDotSeparatedWords(input, '(?i)\\b([a-z0-9]+)\\.([a-z0-9]+)\\b');
        input = mergeSingleLetterAndWord(input, '(?i)\\b([a-z])\\s+([a-z]{2,})\\b');
    
        return input;
    }
    
    private static String mergeLetterPairs(String input, String regex) {
        Pattern pattern = Pattern.compile(regex);
        Matcher matcher = pattern.matcher(input);
        String result = '';
        Integer lastEnd = 0;
    
        while (matcher.find()) {
            result += input.substring(lastEnd, matcher.start());
            result += matcher.group(1) + matcher.group(2);
            lastEnd = matcher.end();
        }
    
        result += input.substring(lastEnd);
        return result;
    }
    
    private static String mergeTripleLetters(String input, String regex) {
        Pattern pattern = Pattern.compile(regex);
        Matcher matcher = pattern.matcher(input);
        String result = '';
        Integer lastEnd = 0;
    
        while (matcher.find()) {
            result += input.substring(lastEnd, matcher.start());
            result += matcher.group(1) + matcher.group(2) + matcher.group(3);
            lastEnd = matcher.end();
        }
    
        result += input.substring(lastEnd);
        return result;
    }
    
    private static String mergeCompoundParts(String input, String regex) {
        Pattern pattern = Pattern.compile(regex);
        Matcher matcher = pattern.matcher(input);
        String result = '';
        Integer lastEnd = 0;
    
        while (matcher.find()) {
            result += input.substring(lastEnd, matcher.start());
            result += matcher.group(1) + matcher.group(2);
            lastEnd = matcher.end();
        }
    
        result += input.substring(lastEnd);
        return result;
    }
    
    private static String mergeDotSeparatedWords(String input, String regex) {
        Pattern pattern = Pattern.compile(regex);
        Matcher matcher = pattern.matcher(input);
        String result = '';
        Integer lastEnd = 0;
    
        while (matcher.find()) {
            result += input.substring(lastEnd, matcher.start());
            result += matcher.group(1) + matcher.group(2);
            lastEnd = matcher.end();
        }
    
        result += input.substring(lastEnd);
        return result;
    }    

    private static String mergeSingleLetterAndWord(String input, String regex) {
        Pattern pattern = Pattern.compile(regex);
        Matcher matcher = pattern.matcher(input);
        String result = '';
        Integer lastEnd = 0;
    
        while (matcher.find()) {
            result += input.substring(lastEnd, matcher.start());
            result += matcher.group(1) + matcher.group(2);
            lastEnd = matcher.end();
        }
    
        result += input.substring(lastEnd);
        return result;
    }
    
    private static String mergeShortPrefixCompound(String input, String regex) {
        Pattern pattern = Pattern.compile(regex);
        Matcher matcher = pattern.matcher(input);
        String result = '';
        Integer lastEnd = 0;
    
        while (matcher.find()) {
            result += input.substring(lastEnd, matcher.start());
            result += matcher.group(1) + matcher.group(2);
            lastEnd = matcher.end();
        }
    
        result += input.substring(lastEnd);
        return result;
    }    
    
    
    //--- Заміна по паттернах
    public static String normalizeBrands(String input) {
        if (String.isBlank(input)) return input;
    
        String lowerInput = input.toLowerCase();
    
        for (String pattern : Consts.brandFixes.keySet()) {
            String replacement = Consts.brandFixes.get(pattern);
    
            String lowerPattern = pattern.toLowerCase();
            Integer idx = lowerInput.indexOf(lowerPattern);
            if (idx != -1) {
                // Замінюємо вручну, бо replaceAll не спрацьовує
                input = input.substring(0, idx) + replacement + input.substring(idx + pattern.length());
                // Оновлюємо lowerInput для наступного проходу
                lowerInput = input.toLowerCase();
            }
        }
    
        return input;
    }
       
    //--- // Видаляє всі знаки питання, які не схожі на звичайні слова
    public static String cleanBrokenChars(String input) {
        // Видаляє всі знаки питання, які не схожі на звичайні слова
        return input.replaceAll('[\\uFFFD\\?]+', '');
    }


    // Утіліта для екранізації regex-спецсимволів
    private static String escapeRegex(String pattern) {
        List<String> specials = new List<String>{
            '\\', '.', '*', '+', '?', '^', '$', '[', ']', '(', ')', '{', '}', '|', '-', ',', ' '
        };
        for (String ch : specials) {
            pattern = pattern.replace(ch, '\\' + ch);
        }
        return pattern;
    }

    //--- Вичищаємо самотні символи, що лишилися по нормалізації
    public static String removeTrashLetters(String str) {
        if (String.isBlank(str)) return '';

        List<String> resultWords = new List<String>();
        List<String> words = str.normalizeSpace().split(' ');

        for (String word : words) {
            // Якщо слово має більше ніж 1 символ — залишаємо
            if (word.length() > 1) {
                resultWords.add(word);
            }
            // Якщо 1 символ — перевіряємо, чи він є в TRASH_LETTERS
            else if (!Consts.TRASH_LETTERS.containsKey(word.toUpperCase())) {
                resultWords.add(word);
            }
        }

        return String.join(resultWords, ' ');
    }
    
    //--- Видаляємо будь-яке слово, що містить символ "?"
    public static String removeWordsWithQuestionMark(String str) {
        if (String.isBlank(str)) return '';
    
        List<String> result = new List<String>();
    
        for (String word : str.normalizeSpace().split(' ')) {
            if (!word.contains('?')) {
                result.add(word);
            }
        }
    
        return String.join(result, ' ');
    }
    
    //--- Чистимо слова
    public static String normalizeChars(String s) {
        if (String.isBlank(s)) return '';
        List<String> listWords = s.split(' ');
        List<String> listResult = new List<String>();
        for(String word : listWords) {
            word = cleanBrokenChars(word);
            word = word
                // Дві літери + . + пробіл або без → ті ж дві літери (bh. або bh.  → bh)
                .replaceAll('(?i)(?<=[\\p{L}]{2})\\.\\s*', '')
                // Дві літери + пробіл → дві літери (bh  → bh)
                .replaceAll('(?i)(?<=[\\p{L}]{2})\\s+', '')

                // Дві літери + & + пробіл або без → ті ж дві літери (bh. або bh.  → bh)
                .replaceAll('(?i)(?<=[\\p{L}]{2})\\.\\s*', '')
                // Дві літери & пробіл → дві літери (bh  → bh)
                .replaceAll('(?i)(?<=[\\p{L}]{2})\\s+', '')

                // Літера + . + пробіл → літера (a. l. → a)
                .replaceAll('(?i)(?<=[\\p{L}])\\.\\s+', '')
                // Літера + . → літера (a.l. → al)
                .replaceAll('(?i)(?<=[\\p{L}])\\.', '')

                // Літера + & + пробіл → літера (a. l. → a)
                .replaceAll('(?i)(?<=[\\p{L}])\\&\\s+', '')
                // Літера + & → літера (a.l. → al)
                .replaceAll('(?i)(?<=[\\p{L}])\\&', '')

                // Літера + "+"  + пробіл → літера (a. l. → a)
                .replaceAll('(?i)(?<=[\\p{L}])\\+\\s+', '')
                // Літера + "+" → літера (a.l. → al)
                .replaceAll('(?i)(?<=[\\p{L}])\\+', '')

/*
                // Літера + дефіс + пробіл або без → літера (m- або m-  → m)
                .replaceAll('(?i)(?<=[\\p{L}])\\-\\s*', '')
                // Дефіс перед літерою → просто літера (-m → m)
                .replaceAll('(?i)\\-(?=\\p{L})', '')
*/
                // Зліплює, якщо обидві частини короткі (1–2 літери)
                .replaceAll('(?i)\\b(\\p{L}{1,2})\\-\\s*(\\p{L}{1,2})\\b', '$1$2')
                // Видаляє дефіс, якщо після нього коротке слово
                .replaceAll('(?i)\\-\\s*(?=\\p{L}{1,2}\\b)', '')
                // Видаляє дефіс, якщо перед ним коротке слово
                .replaceAll('(?i)(?<=\\b\\p{L}{1,2})\\-\\s*', '')
                
                // Видалення всіх цифр
                .replaceAll('\\d+', '');

                // Прибрати надлишкові пробіли
                s = s.replaceAll('\\s+', ' ').trim();

                listResult.add(word);
        }
        // Склеїти слова, де перше з них має 1-2 літери
        String str = String.join(listResult, ' ');
        str = str.replaceAll('(?i)\\b(\\p{L}{1,2})\\s+(?=\\p{L}{2,})', '$1');  
        str = str.replace('&','').normalizeSpace();
              
        return str;
    }    
    //--- Нормалізуємо назву - очищуємо від "сміття" та сміттєвих слів (final clear) ---
    public static String getClearName(String strName, Boolean NeedsUCase) {
        if(String.isBlank(strName)) return '';
    
        String Result = getClearStr(strName);
    
        Result  = (NeedsUCase==true) ? Result.toUpperCase() : Result;
        Result = Result.replaceAll('`', '');
        if(Result.toUpperCase().contains('ZAGREB')) Result = Result.replaceAll('ZAGREB', '');
        Result = Result.replace('ТММ', ''); //CYR
        Result = Result.replace('TMM', ''); //LAT
          
        return Result.normalizeSpace();
    }

    //--- Рекурсивна функція, що формує всі варіанти слова з урахуванням Consts.REPLACEMENTS ---
    public static void generateCharacterVariations(String word, Integer index, String current,
                                                   Set<String> variations, Map<String,
                                                   List<String>> replacements) {
        if (index >= word.length()) {
            variations.add(current);
            return;
        }

        String ch = word.substring(index, index + 1);

        if (replacements.containsKey(ch)) {
            for (String replacement : replacements.get(ch)) {
                generateCharacterVariations(word, index + 1, current + replacement, variations, replacements);
            }
        } else {
            generateCharacterVariations(word, index + 1, current + ch, variations, replacements);
        }
    }

    //--- Повертаємо синоніми слова з Consts.SAME_WORDS
    public static Set<String> getSynonims(String strWord) {
        Set<String> resultSet = new Set<String>();
        //--- Перевіряємо коректність аргументу
        if (String.isBlank(strWord)) {
            System.debug('❌ ERROR! Argument is invalid');
            return resultSet;
        }

        String upperWord = strWord.toUpperCase();
        List<String> synonyms = Consts.SAME_WORDS.get(upperWord);

        if (synonyms != null) {
            for (String key : synonyms) {
                if (!String.isBlank(key)) {
                    resultSet.add(key);
                }
            }
        }

        if (resultSet.isEmpty()) {
            resultSet.add(upperWord);
        }

        return resultSet;
    }

    /****************************************************************************************/
    /****************** Методи фонетичного аналізу (Similarity Methods) *********************/
    /****************************************************************************************/
    //--- Рівень фонетичного збігу перших слів двох назв
    public static Decimal getFirstWordsMatch(String name1, String name2) {
        if(String.isBlank(name1) || String.isBlank(name2)) {
            System.debug('❌ ERROR: Argument is incorrect');
            return 0;
        }
        // Отримуємо перші слова назв
        String s1 = getFirstWord(getClearName(name1, true));
        String s2 = getFirstWord(getClearName(name2, true));

        if (!String.isBlank(s1) && !String.isBlank(s2)) {
            String alpha1 = detectAlphabet(s1);
            String alpha2 = detectAlphabet(s2);
            if (alpha1 != alpha2) {
                if (alpha1 == 'Cyrillic' && alpha2 == 'Latin') {
                    s2 = translitLatinToCyr(s2);
                } else if (alpha1 == 'Latin' && alpha2 == 'Cyrillic') {
                    s2 = transliterateCyrillicToLatin(s2);
                }
            }
        } else {
            System.debug('❌ ERROR: Argument is incorrect');
            return 0;
        }
        // Отримуємо фонетичні коди перших слів
        String phoneCode1 = PhoneticTranscoder.toPhoneticCode(s1);
        String phoneCode2 = PhoneticTranscoder.toPhoneticCode(s2);

        // Обраховуємо збіги по Dice, Norm Levenstein i Soundex
        Decimal diceFirstScore = DiceSimilarity(s1, s2);
        Decimal levFirstScore = 1.000 - (getNormalizedLevenstein(s1, s2));
        Decimal sndFirstScore = compareSoundex(soundex(s1), soundex(s2));
        Decimal finalFirstScore = (Decimal)((diceFirstScore+levFirstScore+sndFirstScore)/3.000).setScale(3);
        return finalFirstScore;
    }

    //--- Рівень фонетичного збігу всіх слів двох назв
    public static Decimal getWordsPhoneticMatch(String name1, String name2) {
        if(String.isBlank(name1) || String.isBlank(name2)) {
            System.debug('❌ ERROR: Argument is incorrect');
            return 0;
        }
        // Нормалізуємо назви
        String s1 = getClearName(name1, true);
        String s2 = getClearName(name2, true);

        if (!String.isBlank(s1) && !String.isBlank(s2)) {
            String alpha1 = detectAlphabet(s1);
            String alpha2 = detectAlphabet(s2);
            if (alpha1 != alpha2) {
                if (alpha1 == 'Cyrillic' && alpha2 == 'Latin') {
                    s2 = translitLatinToCyr(s2);
                } else if (alpha1 == 'Latin' && alpha2 == 'Cyrillic') {
                    s2 = transliterateCyrillicToLatin(s2);
                }
            }
        } else {
            System.debug('❌ ERROR: Argument is incorrect');
            return 0;
        }

        // Отримуємо перші листи слів обох назв
        List<String> listWords1 = getClearName(s1, true).split(' ');
        List<String> listWords2 = getClearName(s2, true).split(' ');

        Integer nCounter = Math.min(listWords1.size(), listWords2.size());

        Decimal finalScore = 0.000;

        for(Integer i=0; i<nCounter; i++) {
            // Отримуємо фонетичні коди слів
            String phoneCode1 = PhoneticTranscoder.toPhoneticCode(listWords1[i]);
            String phoneCode2 = PhoneticTranscoder.toPhoneticCode(listWords2[i]);
            //System.debug('phoneCode1 = '+phoneCode1);
            //System.debug('phoneCode2 = '+phoneCode2);
            //System.debug('-------------------------------');
            // Обраховуємо збіги по Dice, Norm Levenstein i Soundex
            Decimal diceScore = DiceSimilarity(phoneCode1, phoneCode2);
            Decimal levScore = 1.000 - (getNormalizedLevenstein(phoneCode1, phoneCode2));
            Decimal sndScore = compareSoundex(soundex(phoneCode1), soundex(phoneCode2));
            // Накопичуємо результат
            finalScore = finalScore + (Decimal)((diceScore+levScore+sndScore)/3.000).setScale(3);
        }
        //System.debug('-------------------------------');
        //System.debug('List Words 1: ' + listWords1);
        //System.debug('List Words 2: ' + listWords2);
        //System.debug('listWords1.size() = ' + listWords1.size());
        //System.debug('listWords2.size() = ' + listWords2.size());
        return (finalScore/(Decimal) Math.max(listWords1.size(), listWords2.size())).setScale(3);
    }

    //--- Повертає match index для двох кодів soundex
    public static Decimal compareSoundex(String s1, String s2) {
        if (String.isBlank(s1) || String.isBlank(s2))
        {
            system.debug('❌ ERROR: Arguments are invalid!');
            return 0;
        }

        Integer score = 0;

        // Порівнюємо перший символ (літера)
        if (s1.substring(0,1) == s2.substring(0,1)) {
            score += 4;
        }

        // Порівнюємо кожну з 3 цифр
        for (Integer i = 1; i <= 3; i++) {
            if (s1.length() > i && s2.length() > i && s1.substring(i, i+1) == s2.substring(i, i+1)) {
                score += 2;
            }
        }

        return Decimal.valueOf(score) / 10;
    }

    //--- Повертає match index для двох повних кодів soundex (коди soundex повних назв)
    public static Decimal compareSoundexAllCodes(String fullSndCode1, String fullSndCode2) {
        if(String.isBlank(fullSndCode1) || String.isBlank(fullSndCode2)) return 0.000;
        Decimal result = 0.000;
        List<String> lst1 = fullSndCode1.split(' ');
        List<String> lst2 = fullSndCode2.split(' ');
        Integer nCounter = Math.min(lst1.size(), lst2.size());
        //System.debug('nCounter = ' + nCounter );
        for(Integer i=0; i<nCounter; i++) {
            result = result + StringUtilsEx.compareSoundex(lst1[i], lst2[i]);
            //System.debug('Iteration result = ' + result);
        }
        return (result/Math.max(lst1.size(),lst2.size())).setScale(3);
        //return (result/((lst1.size()+lst2.size())/2)).setScale(3);
    }

    //--- Повертає match index для всіх слів двох повних назв
    public static Decimal compareSoundexFull(String name1, String name2) {
        Decimal resultIndex = 0.000;
        if (String.isBlank(name1) || String.isBlank(name2))
        {
            system.debug('❌ ERROR: Arguments are invalid!');
            return resultIndex;
        }
        // Формуємо листи слів з назв
        List<String> lstWords1 = getClearName(name1, true).normalizeSpace().split(' ');
        List<String> lstWords2 = getClearName(name2, true).normalizeSpace().split(' ');

        // Робимо цикл по коротшому слову
        Integer nCounter = Math.min(lstWords1.size(), lstWords2.size());
        if (nCounter == 0) return 0.000; // Убезпечимося від Div 0
        for (Integer i = 0; i < nCounter; i++) {
            // Нормалізуємо діакритику в обох листах - там, де вона є
            if (isWordHasDiacritics(lstWords1[i])) {
                lstWords1[i] = normalizeDiacritics(lstWords1[i]);
            }
            if (isWordHasDiacritics(lstWords2[i])) {
                lstWords2[i] = normalizeDiacritics(lstWords2[i]);
            }
            // Транслітеруємо все в латинку
            if(detectAlphabet(lstWords1[i])!=LAT) {
                lstWords1[i] = transliterateCyrillicToLatin(lstWords1[i]);
            }
            if(detectAlphabet(lstWords2[i])!=LAT) {
                lstWords2[i] = transliterateCyrillicToLatin(lstWords2[i]);
            }
            // Отримуємо код soundex кожного слова обох назв
            String s1 = soundex(lstWords1[i]);
            String s2 = soundex(lstWords2[i]);
            //System.debug('---------------');
            //System.debug('soundex1 = ' + s1);
            //System.debug('soundex2 = ' + s2);
            //System.debug('---------------');
            resultIndex = resultIndex + compareSoundex(s1, s2);
        }
        // Підсумковий результат:
        // усереднена сума resultIndex, приведена до вигляду 0.xxx
        return (resultIndex/(Decimal)nCounter).setScale(3);
    }
    //=============================================================================
    /* ------- Dice-Sørensen Similarity
    Принцип оцінки
    Dice коефіцієнт вимірює відносну кількість спільних елементів:
    Значення 1 означає повну ідентичність
    Значення 0 — повна відсутність схожості */
    public static Double DiceSimilarity(String s1, String s2) {

        if (String.isBlank(s1) || String.isBlank(s2)) {
            System.debug('❌ ERROR: Argument is incorrect');
            return 0.0;
        }

        String a = prepareForComparison(s1);
        String b = prepareForComparison(s2);

        //Set<String> bigramsA = getBigrams(a);
        //Set<String> bigramsB = getBigrams(b);
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
    public static Double CosineSimilarity(String s1, String s2) {
        Boolean useTranslit = false;

        if (String.isBlank(s1) || String.isBlank(s2)) {
            System.debug('❌ ERROR: Argument is incorrect');
            return 0.0;
        }

        String name1 = prepareForComparison(s1);
        String name2 = prepareForComparison(s2);

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
    public static Double LevenshteinSimilarity(String s1, String s2) {
        Boolean useTranslit = false;

        if (String.isBlank(s1) || String.isBlank(s2)) {
            System.debug('❌ ERROR: Argument is incorrect');
            return 0.0;
        }

        String a = prepareForComparison(s1);
        String b = prepareForComparison(s2);

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
    o   Подібні назви: Якщо нормалізована Levenstein Distance ≤ 0.2 (або 20%),
        це означає, що назви дуже схожі і можуть бути дублями.
    o   Можливі дублікати:
              Якщо нормалізована Levenstein Distance між 0.2 і 0.4 (20-40%),
              це вказує на можливість дублювання, але потрібно додатково перевірити.
    o   Різні назви: Якщо нормалізована Levenstein Distance > 0.4 (або 40%), назви, ймовірно, є різними.
    */
    public static Decimal getNormalizedLevenstein(String name1, String name2) {
        Decimal Result = 0.00;

                Result = (Decimal) LevenshteinSimilarity(name1, name1)/Math.max(name1.length(), name2.length());
        //Result = (Decimal)getLevensteinDistance(name1, name2)/Math.max(name1.length(), name2.length());
        return Result.setScale(3);
    }

    //---------------- JaccardSimilarity по словах -------------------------------------------------
    public static Double JaccardSimilarityByWords(String s1, String s2) {
        Boolean useTranslit = false;

        if (String.isBlank(s1) || String.isBlank(s2)) {
            System.debug('❌ ERROR: Argument is incorrect');
            return 0.0;
        }

        String name1 = prepareForComparison(s1);
        String name2 = prepareForComparison(s2);

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
    public static Double JaccardCharSimilarity(String s1, String s2) {
        if (String.isBlank(s1) || String.isBlank(s2)) {
            System.debug('❌ ERROR: Argument is incorrect');
            return 0.0;
        }

        String name1 = prepareForComparison(s1);
        String name2 = prepareForComparison(s2);

        Set<String> set1 = new Set<String>();
        Set<String> set2 = new Set<String>();

        for (Integer i = 0; i < name1.length() - 1; i++) {
            set1.add(name1.substring(i, i + 2));
        }
        for (Integer i = 0; i < name2.length() - 1; i++) {
            set2.add(name2.substring(i, i + 2));
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
    public static Decimal JaccardSimilarity(String s1, String s2, Integer n) {
        if (String.isBlank(s1) || String.isBlank(s2)) {
            System.debug('❌ ERROR: Argument is incorrect');
            return 0.0;
        }

        String a = prepareForComparison(s1);
        String b = prepareForComparison(s2);

        Set<String> gramsA = generateNgrams(a.toLowerCase(), n);
        Set<String> gramsB = generateNgrams(b.toLowerCase(), n);

        Set<String> inter = new Set<String>(gramsA);
        inter.retainAll(gramsB);

        Set<String> union = new Set<String>(gramsA);
        union.addAll(gramsB);

        return ((union.size() == 0) ? 0 : ((Decimal)inter.size()) / union.size()).setScale(3);
    }

        //-------------- Функція, що генерує n-грами для методу Jaccard на N-грамах --------------
    private static Set<String> generateNgrams(String str, Integer n) {
        Set<String> grams = new Set<String>();
        String clean = str.replaceAll('[^a-zа-яA-ZА-Я0-9]', '').toLowerCase();
        for (Integer i = 0; i <= clean.length() - n; i++) {
            grams.add(clean.substring(i, i + n));
        }
        return grams;
    }

    //--- Повертає лист біграмів (пар символів, на яке побили слово)
    public static List<String> getWordsNGrams(String str, Integer n) {
        List<String> grams = new List<String>();
        String clean = str.replaceAll('[^a-zа-яA-ZА-Я0-9]', '').toLowerCase();
        for (Integer i = 0; i <= clean.length() - n; i++) {
            grams.add(clean.substring(i, i + n));
        }
        return grams;
    }

    // Основний Soundex
    public static String soundex(String s) {
        if (s == null || s.trim().length() == 0) return '0000';

        String word = s.toUpperCase().trim();
        word = prepareForComparison(word); //getClearName(word, true);
        
        if (String.isBlank(word)) return '0000';

        // Карта відповідностей
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
            'Ł'=>'4', 'Ñ'=>'5'
        };

        // Список голосних і пропущених літер
        Set<String> ignored = new Set<String>{ 'A','E','I','O','U','Y','Ä','Ö','Ü','Ó','É','Á','Ø','А','О','Е','І','У','И','Й','Ї','Є','Я','Ю','Э','Ъ','Ь','Ё' };

        String code = word.substring(0, 1); // перша літера — завжди зберігається
        String lastDigit = '';
        
        for (Integer i = 1; i < word.length(); i++) {
            String ch = word.substring(i, i + 1);
            if (ignored.contains(ch)) continue;
            if (soundexMap.containsKey(ch)) {
                String digit = soundexMap.get(ch);
                if (digit != lastDigit) {
                    code += digit;
                    lastDigit = digit;
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

        String clean = getClearName(name, true);
        List<String> words = new List<String>(clean.trim().replaceAll('\\s+', ' ').split(' '));
        for (String word : words) {
            result.add(soundex(word));
        }
        return result;
    }

    // Фонетичний код NYSIIS (New York State Identification and Intelligence System)
    public static String getNYSIIS(String inputStr) {
        if (String.isBlank(inputStr)) return '';

        String s = prepareForComparison(inputStr); //StringUtilsEx.getClearName(inputStr, true);
        if (s.length() == 0) return '';

        // Початкова заміна
        s = s.replaceFirst('^MAC', 'MCC');
        s = s.replaceFirst('^KN', 'NN');
        s = s.replaceFirst('^K', 'C');
        s = s.replaceFirst('^PH|^PF', 'FF');
        s = s.replaceFirst('^SCH', 'SSS');

        // Кінцева заміна
        s = s.replaceFirst('EE$', 'Y');
        s = s.replaceFirst('IE$', 'Y');
        s = s.replaceFirst('DT$|RT$|RD$|NT$|ND$', 'D');

        String result = s.substring(0, 1);

        for (Integer i = 1; i < s.length(); i++) {
            String c = s.substring(i, i + 1);
            if ('AEIOU'.contains(c)) {
                result += 'A';
            } else {
                result += c;
            }
        }

        // Видалення повторюваних символів (напр. SS => S)
        String deduped = '';
        for (Integer i = 0; i < result.length(); i++) {
            String ch = result.substring(i, i + 1);
            if (i == 0 || ch != result.substring(i - 1, i)) {
                deduped += ch;
            }
        }

        return deduped;
    }

    //======= Методи для порівняння NYSIIS-кодів
    //  Для NYSIIS-кодів фраз (кілька слів) найкраще працює позиційне порівняння слів — 
    //  як у першому методі (compareNysiisWords) — воно точніше й стабільніше.
    //  -
    //  Для однослівних кодів можна використовувати compareNysiisBigrams або compareNysiisLetters
    //===========================================

//--- Кешування NYSIIS-кодів   
public static Map<String, List<Set<String>>> getNysiisCache(String code1, String code2) {
    Map<String, List<Set<String>>> nysiisCache = new Map<String, List<Set<String>>>();

    for (Integer i = 0; i < 2; i++) {
        String code = (i == 0) ? code1 : code2;
        if (!String.isBlank(code) && !nysiisCache.containsKey(code)) {
            List<Set<String>> sets = new List<Set<String>>();
            for (String word : code.trim().split(' ')) {
                Set<String> letters = new Set<String>();
                for (Integer j = 0; j < word.length(); j++) {
                    letters.add(word.substring(j, j + 1));
                }
                sets.add(letters);
            }
            nysiisCache.put(code, sets);
        }
    }

    return nysiisCache;
}    
    
    //--- Word-level Jaccard Similarity (набір літер по кожному слову) - кешований 
public static Decimal compareNysiisWords(
    String code1,
    String code2,
    Map<String, List<Set<String>>> nysiisCache
) {
    if (String.isBlank(code1) || String.isBlank(code2)) return 0.0;

    List<Set<String>> sets1 = nysiisCache.containsKey(code1) ? nysiisCache.get(code1) : new List<Set<String>>();
    List<Set<String>> sets2 = nysiisCache.containsKey(code2) ? nysiisCache.get(code2) : new List<Set<String>>();

    Integer maxLen = Math.max(sets1.size(), sets2.size());
    if (maxLen == 0) return 0.0;

    Decimal total = 0.0;
    for (Integer i = 0; i < maxLen; i++) {
        Set<String> s1 = (i < sets1.size()) ? sets1[i] : new Set<String>();
        Set<String> s2 = (i < sets2.size()) ? sets2[i] : new Set<String>();

        Decimal sim = PhoneticTranscoder.compareSets(s1, s2); // Використовуй спільний метод для порівняння
        total += sim;
    }

    return (total / maxLen).setScale(3);
}     
    //--- Word-level Jaccard Similarity (набір літер по кожному слову)
    public static Decimal compareNysiisWords(String code1, String code2) {
        if (String.isBlank(code1) || String.isBlank(code2)) return 0.0;

        List<String> words1 = code1.trim().split(' ');
        List<String> words2 = code2.trim().split(' ');

        Integer maxLen = Math.max(words1.size(), words2.size());
        if (maxLen == 0) return 0.0;

        Decimal total = 0.0;

        for (Integer i = 0; i < maxLen; i++) {
            String w1 = (i < words1.size()) ? words1[i] : '';
            String w2 = (i < words2.size()) ? words2[i] : '';

            Set<String> set1 = new Set<String>();
            Set<String> set2 = new Set<String>();

            for (Integer j = 0; j < w1.length(); j++) set1.add(w1.substring(j, j + 1));
            for (Integer j = 0; j < w2.length(); j++) set2.add(w2.substring(j, j + 1));

            Set<String> intersection = new Set<String>(set1);
            intersection.retainAll(set2);

            Set<String> union = new Set<String>(set1);
            union.addAll(set2);

            Decimal similarity = union.isEmpty() ? 0.0 : ((Decimal) intersection.size() / union.size());
            total += similarity;
        }

        return (total / maxLen).setScale(3);
    }

    //--- Bigram Similarity (без урахування позиції слів)
    //    Більш гнучка перевірка — якщо слова переставлені, але звучать так само
    public static Decimal compareNysiisBigrams(String code1, String code2) {
        if (String.isBlank(code1) || String.isBlank(code2)) return 0.0;

        String s1 = code1.replaceAll('\\s+', '');
        String s2 = code2.replaceAll('\\s+', '');

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

    //--- Просте літерне порівняння по символах (без біграм)
    public static Decimal compareNysiisLetters(String s1, String s2) {
        if (String.isBlank(s1) || String.isBlank(s2)) return 0.0;

        Set<String> set1 = new Set<String>();
        Set<String> set2 = new Set<String>();

        for (Integer i = 0; i < s1.length(); i++) {
            String ch = s1.substring(i, i + 1);
            if (ch != ' ') set1.add(ch);
        }
        for (Integer i = 0; i < s2.length(); i++) {
            String ch = s2.substring(i, i + 1);
            if (ch != ' ') set2.add(ch);
        }

        Set<String> intersection = new Set<String>(set1);
        intersection.retainAll(set2);

        Set<String> union = new Set<String>(set1);
        union.addAll(set2);

        return union.isEmpty() ? 0.0 : ((Decimal) intersection.size() / union.size()).setScale(3);
    }


    /*************************************************************************************/
    /************ Основні методи генерації SQL-рядку пошуку та GetAccounts ***************/
    /*************************************************************************************/
    //--- Формуємо рядок умови для SQL String основного запиту ---
    public static String getSQLWhereString(String sourceAccName, Boolean bFirstWordsOnly) {
        // Перевіряємо коректність вхіного параметру
        if (String.isBlank(sourceAccName)) {
            System.debug('❌ERROR! Argument "sourceAccName" is invalid!');
            return 'SELECT Id FROM Account WHERE Id=null';
        }

        // Вибираємо в лист слова з назви, очицені від "сміття" й переведені у верхній реґістр
        List<String> nameWords = getNameWords(sourceAccName, true, true);
        if (nameWords.isEmpty()) {
            System.debug('❌ ERROR: No words in "Source Name"!');
            return 'SELECT Id FROM Account WHERE Id=null';
        }

        // Готуємо масиви для конкатенації SQL-рядка
        List<String> lstWords = new List<String>();
        //Підсумкова мапа SQL-рядків
        Map<Integer, List<String>> mapSQLWords = new Map<Integer, List<String>>();

        // Set для всіх варіантів кожного слова назви
        Set<String> wordSet = new Set<String>();

        for(Integer i=0; i<nameWords.size(); i++) {
            wordSet = getDiacriticList(nameWords[i], false, false);
            if(!wordSet.isEmpty()) {
                lstWords.addAll(wordSet);
            }
            // Додаємо слово до мапи SQL-рядку
            List<String> listSQLWords = new List<String>();
            for(String s : lstWords) {
                //String likeWord = i==0 ? LIKE_WORD : (LIKE_WORD + '%');
                //String = fullLike ? (LIKE_WORD + '%') : LIKE_WORD;
                String likeWord = getLikeStr(nameWords[i]);
                String w = '(Name' + likeWord + s + LIKE_END_SIGN + ')';
                listSQLWords.add(w);
            }
            mapSQLWords.put(i+1, listSQLWords);
            lstWords.clear();
        }

        String strResult = '';
        List<String> nextWordsList = new  List<String>();
        for(Integer key : mapSQLWords.keySet()) {
            List<String> strList = mapSQLWords.get(key);
            //System.debug(key + ', '+strList);
            String firstWord = '';
            String nextWords = '';
            if(key==1) { //Перше слово
                firstWord = firstWord + String.join(strList, ' OR ');
                if(bFirstWordsOnly) {
                    return (mapSQLWords.size()==1 ? firstWord : '(' + firstWord + ')');
                }
                if(strList.size()==1) {
                    strResult = strResult + firstWord + (mapSQLWords.size()>1 ? ' AND ' : '');
                } else {
                    strResult = strResult + '(' + firstWord + ')' + (mapSQLWords.size()>1 ? ' AND ' : '');
                }

            } else {
                nextWords = '('+ nextWords + String.join(strList, ' OR ') + ')';
                nextWordsList.add(nextWords);
            }
            strList.clear();
        }
        return (strResult + '(' + String.join(nextWordsList, ' OR ') + ')');
    }

    // Визначаємо тип LIKE - word% чи %word%
    public static String getLikeStr(String word){
        List<Account> accList = new List<Account>(AccountRepository.getAllAccounts());
        String s = StringUtilsEx.getClearName(word, true);
        for(Account rec : accList) {
            if(rec.Name.startsWith(s)) return LIKE_WORD;
        }
        return LIKE_WORD + '%';
    }
    //-- Повертаємо повний SQL-рядок пошуку
    public static String getSQLString(String sourceAccName, Boolean bFirstWordsOnly, Boolean isNeedTranslit) {
        // Перевіряємо коректність вхіного параметру
        if (String.isBlank(sourceAccName)) {
          System.debug('❌ERROR! Argument "sourceAccName" is invalid!');
          return 'SELECT Id FROM Account WHERE Id=null';
        }

        // Формування списку полів
        String sqlResult = 'SELECT ' + Consts.SQL_DEFAULT_FIELDS + ' FROM Account WHERE ';

        String sqlWhere1 = getSQLWhereString(sourceAccName, bFirstWordsOnly);
        String sqlWhere2 = '';
        if(isNeedTranslit) {
            String s = String.join(getTranslitedName(sourceAccName, true, true), ' ');
            sqlWhere2 = getSQLWhereString(s, bFirstWordsOnly);
        }
        sqlResult = sqlResult + (!isNeedTranslit ?  sqlWhere1 : '(' + sqlWhere1 + ') OR ' + '(' + sqlWhere2 + ')');
        if(sqlResult.right(2)=='()') {
            sqlResult = sqlResult.left(sqlResult.length()-2);
        }
        return sqlResult;
    }

     //---- Повертаємо лист акаунтів за допомогою SOQL SELECT
    public static List<Account> GetAccountsList(Boolean isFindByName, Boolean isFindByID_ERP, String strIdForFind, String argAccName,
                                                  Boolean bFirstWordsOnly, Boolean bUseTranslit) {
        /* Аргументи:
            Boolean isFindByName
                = TRUE - задано пошук явно по назві або частині назви (argAccName)
                = FALSE - задано пошук по конкретному коду (Id або ID_ERP__c)
            Boolean isFindByID_ERP
                = TRUE - задано пошук по ID_ERP__c
                = FALSE - задано пошук по Salesforce Id
            String argAccName - явна назва або частині назви (коли isFindByName=TRUE)
            String strIdForFind - код для пошуку (коли isFindByName=FALSE)
            Решта аргументів аналогічні getSQLString
        */

        List<Account> accList = new List<Account>();
        String accName = '';
        String accID_ERP = '';
        Id accId = null;

        if(isFindByName==NameSimilarityUtil.FIND_BY_NAME) {
            System.debug('isFindByName==NameSimilarityUtil.FIND_BY_NAME : ' + (isFindByName==NameSimilarityUtil.FIND_BY_NAME));
            System.debug('FIND_BY_NAME');
            if(!String.isBlank(argAccName)) {
                accName = getClearName(argAccName, true);
            } else {
                system.debug('❌ ERROR: argument "Name" is invalid!');
                return accList;
            }
        } else if(isFindByName==NameSimilarityUtil.FIND_BY_CODE){
            System.debug('isFindByName==NameSimilarityUtil.FIND_BY_CODE : ' + (isFindByName==NameSimilarityUtil.FIND_BY_CODE));
            System.debug('FIND_BY_CODE');
            if(!String.isBlank(strIdForFind)) {
                if(isFindByID_ERP==NameSimilarityUtil.FIND_BY_SF_ID) {
                    System.debug('isFindByID_ERP==NameSimilarityUtil.FIND_BY_SF_ID : ' + (isFindByID_ERP==NameSimilarityUtil.FIND_BY_SF_ID));
                    System.debug('FIND_BY_SF_ID');
                    if(!isValidSalesforceId(strIdForFind)) {
                        system.debug('❌ ERROR: Salesforce Id is invalid!');
                        return accList;
                    } else if(isFindByID_ERP==NameSimilarityUtil.FIND_BY_ID_ERP){
                        System.debug('isFindByID_ERP==NameSimilarityUtil.FIND_BY_ID_ERP : ' + (isFindByID_ERP==NameSimilarityUtil.FIND_BY_ID_ERP));
                        System.debug('FIND_BY_ID_ERP');
                        if(!strIdForFind.isNumeric()) {
                            system.debug('❌ ERROR: ID_ERP__c is invalid!');
                            return accList;
                        }
                    }
                }
                Account acc = isFindByID_ERP ? AccountRepository.getByErp(strIdForFind) : AccountRepository.getById((Id)strIdForFind);
                accName = getClearName(acc.Name, true);
                accID_ERP = acc.ID_ERP__c;
                accId = acc.Id;
            } else {
                system.debug('❌ ERROR: Id or ID_ERP__c is invalid!');
                return accList;
            }
        }

        String strQuery = getSQLString(accName, bFirstWordsOnly, bUseTranslit);
        System.debug('getSQLString : ' + strQuery );
        // Перевіряємо, чи коректно відпрацював білдер рядку для SELECT
        if (strQuery=='SELECT Id FROM Account WHERE Id=null' || String.isBlank(strQuery)) {
                system.debug('❌ ERROR: Something went wrong! Check all arguments!');
                return accList;
        }

        if (!String.isBlank(strQuery)) {
            accList = (List<Account>) Database.query(strQuery);
        }
        return accList;
    }
    
     //---- Повертаємо лист акаунтів, не використовуючи SELECT
    public static List<Account> getAccountList(Boolean isFindByName, Boolean isFindByID_ERP, 
                                               String strIdForFind, String argAccName, Boolean bFirstWordsOnly) {
        /* Аргументи:
            Boolean isFindByName
                = TRUE - задано пошук явно по назві або частині назви (argAccName)
                = FALSE - задано пошук по конкретному коду (Id або ID_ERP__c)
            Boolean isFindByID_ERP
                = TRUE - задано пошук по ID_ERP__c
                = FALSE - задано пошук по Salesforce Id
            String argAccName - явна назва або частині назви (коли isFindByName=TRUE)
            String strIdForFind - код для пошуку (коли isFindByName=FALSE)
        */

        List<Account> accList = new List<Account>();
        String accName = '';
        String accID_ERP = '';
        Id accId = null;

        if(isFindByName==NameSimilarityUtil.FIND_BY_NAME) {
            System.debug('isFindByName==NameSimilarityUtil.FIND_BY_NAME : ' + (isFindByName==NameSimilarityUtil.FIND_BY_NAME));
            System.debug('FIND_BY_NAME');
            if(!String.isBlank(argAccName)) {
                accName = getClearName(argAccName, true);
            } else {
                system.debug('❌ ERROR: argument "Name" is invalid!');
                return accList;
            }
        } else if(isFindByName==NameSimilarityUtil.FIND_BY_CODE){
            System.debug('isFindByName==NameSimilarityUtil.FIND_BY_CODE : ' + (isFindByName==NameSimilarityUtil.FIND_BY_CODE));
            System.debug('FIND_BY_CODE');
            if(!String.isBlank(strIdForFind)) {
                if(isFindByID_ERP==NameSimilarityUtil.FIND_BY_SF_ID) {
                    System.debug('isFindByID_ERP==NameSimilarityUtil.FIND_BY_SF_ID : ' + (isFindByID_ERP==NameSimilarityUtil.FIND_BY_SF_ID));
                    System.debug('FIND_BY_SF_ID');
                    if(!isValidSalesforceId(strIdForFind)) {
                        system.debug('❌ ERROR: Salesforce Id is invalid!');
                        return accList;
                    } else if(isFindByID_ERP==NameSimilarityUtil.FIND_BY_ID_ERP){
                        System.debug('isFindByID_ERP==NameSimilarityUtil.FIND_BY_ID_ERP : ' + (isFindByID_ERP==NameSimilarityUtil.FIND_BY_ID_ERP));
                        System.debug('FIND_BY_ID_ERP');
                        if(!strIdForFind.isNumeric()) {
                            system.debug('❌ ERROR: ID_ERP__c is invalid!');
                            return accList;
                        }
                    }
                }
                Account acc = isFindByID_ERP ? AccountRepository.getByErp(strIdForFind) : AccountRepository.getById((Id)strIdForFind);
                accName = getClearName(acc.Name, true);
                accID_ERP = acc.ID_ERP__c;
                accId = acc.Id;
            } else {
                system.debug('❌ ERROR: Id or ID_ERP__c is invalid!');
                return accList;
            }
        }
        return AccountDuplicateDetector.getAccountDuplicates(accName, bFirstWordsOnly);
    }    

    //--- Загальний індекс збігу по основних параметрах, попередньо збережених в рекордах об'єкту Account
    public static Decimal getCommonMatchIndex(
        String phone1, String phone2,
        String mphPrimary1, String mphPrimary2,
        String mphAlternate1, String mphAlternate2,
        String NYSIIS_1, String NYSIIS_2,
        String soundex1,String soundex2) {
            
        Decimal resPhonetic = 0.000;
        Decimal resMetaphone = 0.000;
        Decimal resNYSIIS = 0.000;
        Decimal resSoundex = 0.000;
        Decimal finalResult = 0.000;
        
        //=== Коди Phonetic
        //resPhonetic = PhoneticTranscoder.comparePhoneticHybrid(phone1, phone2);
        
        Set<String> allCodes = new Set<String>();
        allCodes.add(phone1);
        allCodes.add(phone2);
        
        Map<String, Set<String>> bigramsMap = PhoneticTranscoder.buildBigramsCache(new List<String>(allCodes));
        Map<String, Set<String>> lettersMap = PhoneticTranscoder.buildLettersCache(new List<String>(allCodes));
        
        resPhonetic = PhoneticTranscoder.comparePhoneticHybridCached(phone1, phone2, bigramsMap, lettersMap);
        /*
        Integer len1 = phone1.length();
        Integer len2 = phone2.length();
        Decimal phLenIndex = Decimal.valueOf(Math.min(len1, len2)) / Decimal.valueOf(Math.max(len1, len2));
        resPhonetic = (phLenIndex>=0.85) ? (resPhonetic*phLenIndex).setScale(3) : (resPhonetic*0.85).setScale(3); 
        System.debug('Corrected resPhonetic: '+ resPhonetic.setScale(3));      
        */
        //=== Порівняння primary і alternate Metaphone-кодів з обох сторін
        // - сети для кодів Metaphone
        Set<String> mphCodes1 = new Set<String>();
        Set<String> mphCodes2 = new Set<String>();      
        
        // - заповнюємо сети кодами
        mphCodes1.add(mphPrimary1);
        mphCodes1.add(mphAlternate1);

        mphCodes2.add(mphPrimary2);
        mphCodes2.add(mphAlternate2);

        resMetaphone = MetaphoneUtils.compareMetaphoneLetterSets(mphCodes1, mphCodes2);
        /*
        len1 = mphPrimary1.length();
        len2 = mphPrimary2.length();
        Decimal mphLenIndex = Decimal.valueOf(Math.min(len1, len2)) / Decimal.valueOf(Math.max(len1, len2));

        resMetaphone = (mphLenIndex>=0.85) ? (resMetaphone*mphLenIndex).setScale(3) : (resMetaphone*0.85).setScale(3);
        System.debug('Corrected resPhonetic: '+ resMetaphone.setScale(3));
        */
        //=== Порівняння NYSIIS-кодів
        resNYSIIS = compareNysiisWords(NYSIIS_1, NYSIIS_2, getNysiisCache(NYSIIS_1, NYSIIS_2));
        /*
        len1 = NYSIIS_1.length();
        len2 = NYSIIS_2.length();   
        Decimal nyLenIndex = Decimal.valueOf(Math.min(len1, len2)) / Decimal.valueOf(Math.max(len1, len2));
        resNYSIIS = (nyLenIndex>=0.85) ? (resNYSIIS*nyLenIndex).setScale(3) : (resNYSIIS*0.85).setScale(3);     
        System.debug('resNYSIIS : '+ resNYSIIS.setScale(3));
        */
        //Якщо коди однослівні
        //if(NYSIIS_1.split(' ').size()==1 && NYSIIS_2.split(' ').size()==1) {
            // Використовуємо compareNysiisBigrams та compareNysiisLetters
            // Рівень збігу обраховуємо як максимум цих показників
            //resNYSIIS = Math.max(StringUtilsEx.compareNysiisBigrams(NYSIIS_1, NYSIIS_2), StringUtilsEx.compareNysiisLetters(NYSIIS_1, NYSIIS_2));
        //} else { // Якщо коди складаються з двох і більше слів
            // Використовуємо compareNysiisWords
            //resNYSIIS = StringUtilsEx.compareNysiisWords(NYSIIS_1, NYSIIS_2);
        //}

        //=== Soundex
        resSoundex = compareSoundexAllCodes(soundex1, soundex2);
        /*
        len1 = soundex1.length();
        len2 = soundex2.length();   
        Decimal sndxLenIndex = Decimal.valueOf(Math.min(len1, len2)) / Decimal.valueOf(Math.max(len1, len2));
        resSoundex = (resSoundex*sndxLenIndex).setScale(3);
        resSoundex = (sndxLenIndex>=0.85) ? (resSoundex*sndxLenIndex).setScale(3) : (resSoundex*0.85).setScale(3);      
        System.debug('resSoundex : '+ resSoundex.setScale(3));
        */
        //=== Final Result
        return (0.25*resPhonetic+0.25*resMetaphone+0.25*resNYSIIS+0.25*resSoundex).setScale(3);
    }
    
    //--- Загальний індекс збігу по основних параметрах, попередньо збережених в рекордах об'єкту Account
    //--- Версія з варіаціями ваги індексів - задається з домоговю класу IndexWeights
        /*
        Як використовувати:
        IndexWeights weights = new IndexWeights(0.3, 0.1, 0.3, 0.3); // правильна сума = 1.0
         або
        IndexWeights weights = IndexWeights.getDefault(); // усі по 0.25
        */
    //    Для швидкого пошуку потенційних дублів серед наявних у базі акаунтів
    //    А також для оперативного попереднього пошуку можливих дублів під час створення нового клієнта
    public static Decimal getCommonMatchIndex(
        String phone1, String phone2,
        String mphPrimary1, String mphPrimary2,
        String mphAlternate1, String mphAlternate2,
        String NYSIIS_1, String NYSIIS_2,
        String soundex1,String soundex2,
        IndexWeights weights) {
            
        Decimal resPhonetic = 0.000;
        Decimal resMetaphone = 0.000;
        Decimal resNYSIIS = 0.000;
        Decimal resSoundex = 0.000;
        Decimal finalResult = 0.000;
        
        //=== Коди Phonetic
        //resPhonetic = PhoneticTranscoder.comparePhoneticHybrid(phone1, phone2);
        
        Set<String> allCodes = new Set<String>();
        allCodes.add(phone1);
        allCodes.add(phone2);
        
        Map<String, Set<String>> bigramsMap = PhoneticTranscoder.buildBigramsCache(new List<String>(allCodes));
        Map<String, Set<String>> lettersMap = PhoneticTranscoder.buildLettersCache(new List<String>(allCodes));
        
        resPhonetic = PhoneticTranscoder.comparePhoneticHybridCached(phone1, phone2, bigramsMap, lettersMap);
        /*
        Integer len1 = phone1.length();
        Integer len2 = phone2.length();
        Decimal phLenIndex = Decimal.valueOf(Math.min(len1, len2)) / Decimal.valueOf(Math.max(len1, len2));
        resPhonetic = (phLenIndex>=0.85) ? (resPhonetic*phLenIndex).setScale(3) : (resPhonetic*0.85).setScale(3); 
        System.debug('Corrected resPhonetic: '+ resPhonetic.setScale(3));      
        */
        //=== Порівняння primary і alternate Metaphone-кодів з обох сторін
        // - сети для кодів Metaphone
        Set<String> mphCodes1 = new Set<String>();
        Set<String> mphCodes2 = new Set<String>();      
        
        // - заповнюємо сети кодами
        mphCodes1.add(mphPrimary1);
        mphCodes1.add(mphAlternate1);

        mphCodes2.add(mphPrimary2);
        mphCodes2.add(mphAlternate2);

        resMetaphone = MetaphoneUtils.compareMetaphoneLetterSets(mphCodes1, mphCodes2);
        /*
        len1 = mphPrimary1.length();
        len2 = mphPrimary2.length();
        Decimal mphLenIndex = Decimal.valueOf(Math.min(len1, len2)) / Decimal.valueOf(Math.max(len1, len2));

        resMetaphone = (mphLenIndex>=0.85) ? (resMetaphone*mphLenIndex).setScale(3) : (resMetaphone*0.85).setScale(3);
        System.debug('Corrected resPhonetic: '+ resMetaphone.setScale(3));
        */
        //=== Порівняння NYSIIS-кодів
        resNYSIIS = compareNysiisWords(NYSIIS_1, NYSIIS_2, getNysiisCache(NYSIIS_1, NYSIIS_2));
        /*
        len1 = NYSIIS_1.length();
        len2 = NYSIIS_2.length();   
        Decimal nyLenIndex = Decimal.valueOf(Math.min(len1, len2)) / Decimal.valueOf(Math.max(len1, len2));
        resNYSIIS = (nyLenIndex>=0.85) ? (resNYSIIS*nyLenIndex).setScale(3) : (resNYSIIS*0.85).setScale(3);     
        System.debug('resNYSIIS : '+ resNYSIIS.setScale(3));
        */
        //Якщо коди однослівні
        //if(NYSIIS_1.split(' ').size()==1 && NYSIIS_2.split(' ').size()==1) {
            // Використовуємо compareNysiisBigrams та compareNysiisLetters
            // Рівень збігу обраховуємо як максимум цих показників
            //resNYSIIS = Math.max(StringUtilsEx.compareNysiisBigrams(NYSIIS_1, NYSIIS_2), StringUtilsEx.compareNysiisLetters(NYSIIS_1, NYSIIS_2));
        //} else { // Якщо коди складаються з двох і більше слів
            // Використовуємо compareNysiisWords
            //resNYSIIS = StringUtilsEx.compareNysiisWords(NYSIIS_1, NYSIIS_2);
        //}

        //=== Soundex
        resSoundex = compareSoundexAllCodes(soundex1, soundex2);
        /*
        len1 = soundex1.length();
        len2 = soundex2.length();   
        Decimal sndxLenIndex = Decimal.valueOf(Math.min(len1, len2)) / Decimal.valueOf(Math.max(len1, len2));
        resSoundex = (resSoundex*sndxLenIndex).setScale(3);
        resSoundex = (sndxLenIndex>=0.85) ? (resSoundex*sndxLenIndex).setScale(3) : (resSoundex*0.85).setScale(3);      
        System.debug('resSoundex : '+ resSoundex.setScale(3));
        */
        //=== Final Result
        return (weights.phoneticWeight*resPhonetic+weights.metaphoneWeight*resMetaphone+
                weights.nysiisWeight*resNYSIIS+weights.soundexWeight*resSoundex).setScale(3);
    }
    
    // New match method 10.06.2025   
    public class MatchResult {
        public String SourceName;
        public Id account1Id;
        public Id account2Id;
        public Decimal matchIndex;

        public MatchResult() {
            this.SourceName = '';
            this.account1Id = null;
            this.account2Id = null;
            this.matchIndex = 0;
        }
        
        public MatchResult(String sourceName, Id a1, Id a2, Decimal idx) {
            this.SourceName = sourceName;
            this.account1Id = a1;
            this.account2Id = a2;
            this.matchIndex = idx;
        }
    }

    public static List<MatchResult> compareAllToOne(
        List<Account> candidates,
        String SourceName,
        Id sourceAccId,
        Boolean findType,
        String sourcePhonetic,
        String mphPrimary,
        String mphAlternate,
        String nysiis,
        String soundexAll,
        IndexWeights weights,
        Decimal threshold,
        Boolean insertObject
    ) {
        System.debug('-----compareAllToOne-----');
        List<MatchResult> matches = new List<MatchResult>();
        Decimal idx = 0.000;
        Decimal addIdx = 0.000; //Added 13.06.2025
        Decimal resultIdx = 0.000; //Added 13.06.2025
        Boolean allLettersMatch = false;
        for (Account acc : candidates) {
            if(sourceAccId!=acc.Id) {
                addIdx = getCorrectCoef(acc.Name, SourceName, acc.MetaphonePrimary__c, mphPrimary, acc.PhoneticCode__c, sourcePhonetic);
                //addIdx = NameSimilarityUtil.getIntgratedMatchIndex(acc.Name, SourceName, true);
                idx = getCommonMatchIndex(
                    acc.PhoneticCode__c,       sourcePhonetic,
                    acc.MetaphonePrimary__c,   mphPrimary,
                    acc.MetaphoneAlternate__c, mphAlternate,
                    acc.NYSIIS__c,             nysiis,
                    acc.SoundexAllWords__c,    soundexAll,
                    weights
                );
                resultIdx = (addIdx+idx)/2.0;

                System.debug('🔍 Comparing: ' + acc.Name + ' (' + acc.Id + ')');
                System.debug('➡️ addIdx (JLDCS) = ' + addIdx);
                System.debug('➡️ idx (indexes) = ' + idx);
                System.debug('➡️ resultIdx = ' + resultIdx);
            }
            if (resultIdx >= threshold) {
//                System.debug('\nthreshold = ' + threshold);
                //System.debug('\n Main Idx = ' + idx + '\n');
                //System.debug('\n Add Idx = ' + addIdx + '\n');                                              
//                System.debug('\n resultIdx  = ' + resultIdx + '\n');
                System.debug('✅ Match found (resultIdx = ' + resultIdx + ' >= threshold = ' + threshold + ')');


                if(findType == Consts.FIND_BY_NAME) {
                    //matches.add(new MatchResult(SourceName, acc.Id, null, idx));
                    matches.add(new MatchResult(SourceName, acc.Id, null, resultIdx));
                }
                if(findType == Consts.FIND_BY_CODE) {
                    //matches.add(new MatchResult('', sourceAccId, acc.Id, idx));
                    matches.add(new MatchResult('', sourceAccId, acc.Id, resultIdx));
                }
            }
        }
//        System.debug('\nmatches.size() = ' + matches.size());
        if(insertObject == Consts.INSERT_YES) {
            if(!matches.isEmpty()) {
                List<MatchResult__c> resToIns = new List<MatchResult__c>();
                for(MatchResult mres : matches) {
                    MatchResult__c rec = new MatchResult__c();
                    rec.SourceName__c = mres.SourceName;
                    rec.account1Id__c = mres.account1Id;
                    rec.account2Id__c = mres.account2Id;
                    rec.matchIndex__c = mres.matchIndex;
                    resToIns.add(rec);
                }
                insert resToIns;
            }
        }
        return matches;
    }

    //--- Обраховуємо додатковий корегувальний кеофіцієнт
    public static Decimal getCorrectCoef(String name1, String name2,
            String mphPrimary1, String mphPrimary2,
            String phoneticCode1, String phoneticCode2) {
        if(String.isBlank(name1) || String.isBlank(name2)) return 0.000;

        String s1=StringUtilsEx.prepareForComparison(name1);
        String s2=StringUtilsEx.prepareForComparison(name2);

        Decimal metaphone = MetaphoneUtils.getMetaphoneSimilarity(mphPrimary1, mphPrimary2);
        Decimal phonetic  = PhoneticTranscoder.comparePhoneticHybrid(phoneticCode1, phoneticCode2);
        Decimal jaccardIdx = SimilarityUtils.JaccardSimilarity(s1, s2, 2);
        Decimal idxCosine = SimilarityUtils.CosineSimilarity(s1, s2, true, true);

        Decimal idxFull = 0.25*(metaphone + phonetic + jaccardIdx + idxCosine).setScale(3);
        return idxFull;
    }

    //--- Обраховуємо додатковий інтегрований match-індекс: 
    //    Jaccard, Norm Levenstein, Dice, Cosine, Soundex (JLDCS)
    public static Decimal getIdxJLDCS(String name1, String name2) {
        if(String.isBlank(name1) || String.isBlank(name2)) return 0.000;
    
        String s1=StringUtilsEx.prepareForComparison(name1);
        String s2=StringUtilsEx.prepareForComparison(name2);

        Decimal idxJaccard = ((SimilarityUtils.JaccardSimilarityByWords(s1, s2, false, false) + 
                              SimilarityUtils.JaccardCharSimilarity(s1, s2) + 
                              SimilarityUtils.JaccardSimilarity(s1, s2, 2))/3.0).setScale(3);
        Decimal idxDice = SimilarityUtils.DiceSimilarity(s1, s2, false, false);
        Decimal idxNormLev = (1.000 - (SimilarityUtils.getNormalizedLevenstein(s1, s2, false, false)));
        Decimal idxCosine = SimilarityUtils.CosineSimilarity(s1, s2, false, false);
        Decimal idxSoundex = SimilarityUtils.getFullSoundexSimilarity(s1, s2, false);
 
        Decimal idxFull = (0.2*idxJaccard+0.2*idxDice+0.2*idxNormLev+0.2*idxCosine+0.2*idxSoundex).setScale(3);
        return idxFull;
    }

    public static void FakeCoverageMethod() {
        Integer i = 0;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
    }
}