public class StringNormalize {
    //--- Чистимо назви від "сміття" - ТОВ, Ltd тощо
    public static String removeLegalForms(String input) {
        if(String.isBlank(input)) return '';
        if(input.toLowerCase().contains('филиал компании каймановых островов karasu')) return 'KARASU KAYMAN';
        if(input.toUpperCase().contains('ТИТАН УКРАЇНА')) return 'TITAN UKRAINE';
        if(input.toUpperCase().contains('/KEYSTONE')) input = input.toUpperCase().replace('/KEYSTONE',' KEYSTONE');
        if(input.toUpperCase().contains('/HENDAYE')) input = input.toUpperCase().replace('/HENDAYE',' HENDAYE');
        if(input.toUpperCase().contains('/KEOLIS')) input = input.toUpperCase().replace('/KEOLIS',' KEOLIS');
        if(input.toUpperCase().contains('УКРТРАНСГАЗ , ФІЛІЯ')) return 'UKRTRANSGAZ FILIA';
        if(input.toUpperCase().contains('УКРАЇНСЬКА ЗАЛІЗНИЦЯ ФІЛІЯ ПАСАЖИРСЬКА КОМПАНІЯ АТ')) return 'PASSERGER FILIA UKRZALIZNICA';
        if(input.toUpperCase().contains('ФІЛІЯ ПАСАЖИРСЬКА КОМПАНІЯ АКЦІОНЕРНОГО ТОВАРИСТВА УКРАЇНСЬКА ЗАЛІЗНИЦЯ')) return 'PASSERGER FILIA UKRZALIZNICA';
        if(input.toUpperCase().contains('ФІЛІЯ ЦЗВ АТ УКРЗАЛІЗНИЦЯ')) return 'FILIA-CZV UKRZALIZNICA';
        if(input.toUpperCase().contains('QALF DRILING SAPLAY')) return 'QALF DRILING SAPLAY';

        input = input.toUpperCase().remove('A. S.');
        input = input.replaceAll('(?i)([A-Z])\\d+\\s+', '$1');
        input = input.toUpperCase().replace('ASIA PACIFIC','AP');

        input = changeSynonimsWords(normalizeDiacritics(input));

        List<String> listWords = input.normalizeSpace().split(' ');
        List<String> listClean = new List<String>();

        for (String word : listWords) {
            if (!Consts.TRASH_WORDS_SET.contains(word.toUpperCase())) {
                    listClean.add(word);
            }
        }
        return String.join(listClean, ' ').normalizeSpace().replaceAll('\\|', '');
    }

    //--- Номалізуємо синонімічні назви
    public static String normalizeSynonimName(String s) {
        if (String.isBlank(s)) return s;

        String upper = s.toUpperCase();

        for (String variant : Consts.NAMES_DICT.keySet()) {
            if (upper.contains(variant)) {
                upper = upper.replace(variant, Consts.NAMES_DICT.get(variant));
            }
        }
        return upper;
    }


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

        if (detectAlphabet(sourceStr) != Consts.Alphabet.LAT) {
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

    //-- Допоміжна функція - очищуємо сміттєві знаки в кінці рядка
    public static String getClearSignsStr(String s) {
        if (String.isBlank(s)) return '';

        Integer i = s.length() - 1;
        while (i >= 0 && Consts.TRASH_SIGNS.contains(s.substring(i, i + 1))) {
            i--;
        }
        return s.substring(0, i + 1);
    }

    //--- Чистимо html та спецю символи
    public static String removeHtmlEntities(String input) {
        if (String.isBlank(input)) return '';

        // HTML сутності → звичайні символи
        input = input
            .replace('&nbsp;', ' ')
            .replace('&#160;', ' ')
            .replace('&amp;', '&')
            .replace('&quot;', '')
            .replace('&apos;', '')
            .replace('&lt;', '')
            .replace('&gt;', '')
            .replace('&#124;', ' ')
            .replace('|', ' ')
            .replace('\u00A0', ' ')    // Non-breaking space
            .replace('\u200B', '')     // Zero-width space
            .replace('\uFEFF', '')     // BOM
            .replace('\u2013', '-')    // –
            .replace('\u2014', '-')    // —
            .replace('\u2026', '')     // …
            .replace('\u00AD', '');    // Soft hyphen

        return input;
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

        // 3. Видаляємо **всі** лапки/апострофи всередині
        for (String q : quotes) {
            str = str.replace(q, '');
        }

        // 4. Замінюємо прості апострофи на типографські
        str = str.replace('\'', '’');

        // 5. Видаляємо коми
        str = str.replace(',', '');

        return str.normalizeSpace();
    }

    //--- Нормалізація назви по регексах і паттернах
    public static String normalizeSpecialPatterns(String input) {
        if (String.isBlank(input)) return '';
        //System.debug('normalizeSpecialPatterns\n');
        // Початок: R&D, R & D, R+D, R + D → RD
        //input = input.replaceFirst('^(?i)R\\s*([&+])\\s*D\\b', 'RD');
        input = input.replaceFirst('^(?i)([a-zA-Zа-яА-Я])\\s*([&+])\\s*([a-zA-Zа-яА-Я])\\b', '$1$3');
        //System.debug('1: ' + input);

        // A. Xxx → A Xxx
        input = input.replaceFirst('^(?i)([a-zA-Zа-яА-Я])\\. (?=\\s*\\S)', '$1');
        input = input.replaceFirst('^(?i)([a-zA-Zа-яА-Я])\\.(?=\\s*\\S)', '$1');
        //System.debug('2: ' + input);

        // AB. Xxx → AB Xxx
        input = input.replaceFirst('^(?i)([a-zA-Zа-яА-Я]{2})\\. (?=\\s*\\S)', '$1');
        input = input.replaceFirst('^(?i)([a-zA-Zа-яА-Я]{2})\\.(?=\\s*\\S)', '$1');
        //System.debug('3: ' + input);

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
        //System.debug('4: ' + input);

        // A. B. C. Xxx → ABC Xxx (знімаємо крапки й пробіли)
        Pattern p2 = Pattern.compile('^(?i)((?:[a-zA-Zа-яА-Я]\\.\\s*){3,})(?=\\S)');
        Matcher m2 = p2.matcher(input);
        if (m2.find()) {
            String matched = m2.group(1); // Напр. "A. B. C. "
            String replaced = matched.replaceAll('[\\.\\s]', ''); // → "ABC"
            input = replaced + input.substring(m2.end());
            input = input.replace('.','');
        }
        //System.debug('5: ' + input);

        // AB.Name → AB Name (розділяємо, якщо є крапка після 2–3 літер)
        input = input.replaceAll('(?i)\\b([a-zA-Zа-яА-Я]{2,3})\\.([a-zA-Zа-яА-Я])', '$1 $2');
        //System.debug('6: ' + input);

        // AB-Name → AB Name (зливаємо, якщо є дефіс після 2–3 літер) //
        input = input.replaceAll('(?i)\\b([a-zA-Zа-яА-Я]{2,3})\\-([a-zA-Zа-яА-Я])', '$1$2');
        //System.debug('7: ' + input);

        //A-Name
        input = input.replaceAll('(?i)\\b([a-zA-Zа-яА-Я])\\-([a-zA-Zа-яА-Я])', '$1$2');
        //System.debug('A-Name: ' + input);
        //A Name
        input = input.replaceAll('(?i)\\b([a-zA-Zа-яА-Я])\\ ([a-zA-Zа-яА-Я])', '$1$2');
        //System.debug('A Name: ' + input);

        // AB-Name → AB Name (зливаємо, якщо є прогалинка після 2–3 літер) //
        input = input.replaceAll('(?i)\\b([a-zA-Zа-яА-Я]{2,3})\\ ([a-zA-Zа-яА-Я])', '$1$2');
        //System.debug('8: ' + input);
        input = removeTrashLetters(input);
        // Кінцівка: Steel - M, Steel.M, Steel M → SteelM
        input = input.replaceAll('(?i)(\\b\\w+)\\s*[-\\.]?\\s*([a-zA-Zа-яА-Я])\\b', '$1$2');
        //System.debug('9: ' + input);

        input = input.replace('.','');
        //System.debug('10: ' + input);
        return input.trim();
    }

    //--- Чистимо "хвости"
    public static String cleanTailSymbols(String s) {
        if (String.isBlank(s)) return s;

        String result = s.trim();

        // Видаляємо всі "хвости": пробіли, дефіси (-), EN DASH (–), EM DASH (—), коми, крапки
        result = result.replaceAll('^[\\-–—\\.,\\s]+', ''); // з початку
        result = result.replaceAll('[\\-–—\\.,\\s]+$', ''); // з кінця

        return result;
    }


    //--- Чистимо рядок від сміття - лапок, дужок, слів у дужках ---
    public static String getClearStr(String s, Consts.QuestionMarkRule questMarkRule) {
        if (String.isBlank(s)) {
            return '';
        }
        //System.debug('getClearStr');
        //if(s.startsWith(',')) s= s.substring(1, s.length());

        if(s.toUpperCase().contains('РЫБИНСКИЙ')) s=s.toUpperCase().replace('РЫБИНСКИЙ','РЫБНИЦКИЙ');
        //System.debug('РЫБИНСКИЙ: ' + s);
        List<String> dniproList = 'ДНЕПРОВСКИЙ,ДНІПРОПЕТРОВСЬКИЙ,ДНЕПРОПЕТРОВСКИЙ'.split(',');
        for(String word : dniproList) {
            if(s.toUpperCase().contains(word)) s=s.toUpperCase().replace(word, 'ДНІПРОВСЬКИЙ');
            break;
        }
        //System.debug('ДНЕПРОВСКИЙ: ' + s);

        // Видаляємо "SMI" на початку, якщо після нього йде Salzgitter Mannesmann
        s = s.replaceAll('(?i)^SMI\\s+(SALZGITTER\\s+MANNESMANN)', '$1');
        //System.debug('SMI: ' + s);
        // Якщо в середині — видалимо
        s = s.replaceAll('(?i)\\bSMI\\b', '');
        //System.debug('SMI2: ' + s);

        s = removeLegalForms(s);
        //System.debug('removeLegalForms: ' + s);
        // Знаки ?
        // - або чистимо тільки знаки ?
        if(questMarkRule==Consts.QuestionMarkRule.REMOVE_SIGN) s = cleanBrokenChars(s);
        // - або видаляємо повністю слово, що містить знаки ?
        if(questMarkRule==Consts.QuestionMarkRule.REMOVE_WORD) s = removeWordsWithQuestionMark(s);
        // Якщо НЕ LAT - трансліт CYR->LAT
        if(detectAlphabet(s)!=Consts.Alphabet.LAT) s=translitCyrToLat(s);

        s = normalizeSpecialPatterns(s);
        //System.debug('2: ' + s);

        //--- Коригуємо арабські назви, що містять AL, ABU, Abi, Ali
        // Об'єднує "Abu Dhabi", "Al-Dhabi", "Abi Dhabi" → "AbuDhabi", "AlDhabi", "AbiDhabi"
        s = s.replaceAll('(?i)\\b(ALI|ABU|AL|ABI)\\s*[-\\s]\\s*([A-ZА-ЯЇІЄҐa-zа-яїієґ]+)', '$1$2');
        //System.debug('3: ' + s);
        //Коригуємо символи, які містяться всередині слова без прогалинок
        s = s.replaceAll('(?<=[^\\s])\\-(?=[^\\s])', ' ');
        //System.debug('4: ' + s);
        //s = s.replaceAll('(?<=[^\\s])\\,(?=[^\\s])', ' ');
        s = s.replaceAll('(?<=[^\\s])\\+(?=[^\\s])', ' ');
        //System.debug('5: ' + s);

        // 1. Видаляємо все в круглих, квадратних і фігурних дужках
        s = s
            .replaceAll('\\s*\\([^)]*\\)', '')
            .replaceAll('\\s*\\[[^\\]]*\\]', '')
            .replaceAll('\\s*\\{[^}]*\\}', '')
            .replaceAll('-', ' ')
            .trim();
        //System.debug('6: ' + s);
        // 2. Видаляємо сміттєві символи (лапки не включаємо — sanitizeQuotes їх обробить)
        final String charsToRemove = '#$§;+&';
        List<String> charList = new List<String>();

        for (Integer i = 0; i < s.length(); i++) {
            String ch = s.substring(i, i + 1);
            if (!charsToRemove.contains(ch)) {
                charList.add(ch);
            }
        }
        //System.debug('7: ' + s);
        // 3. sanitizeQuotes  робить чистку лапок і апострофів
        s = sanitizeQuotes(String.join(charList, ''));
        //System.debug('8: ' + s);

        return s;
    }

    //--- Нормалізуємо назву - очищуємо від "сміття" та сміттєвих слів (final clear) ---
    public static String getClearName(String strName, Consts.ToUpperCase toUpper,
                                      Consts.QuestionMarkRule questMarkRule,
                                      Consts.ClearCountryName clearCountry) {
        if(String.isBlank(strName)) return '';

        String Result = getClearStr(strName, questMarkRule);

        Result  = (toUpper==Consts.ToUpperCase.YES) ? Result.toUpperCase() : Result;
        Result = Result.replaceAll('`', '');
        Result = normalizeDiacritics(Result);
        
        if(clearCountry==Consts.ClearCountryName.YES) Result = getClearContryName(Result);
        Result= cleanTailSymbols(Result);
        // Вилучаємо цифри
        Result = Result.replaceAll('\\d+', '');
        // Видаляємо частину назви після / всередині
        Result = Result.replaceAll('/.*$', '').trim();
        return Result.normalizeSpace();
    }

    //--- Видаляє всі знаки питання, які не схожі на звичайні слова
    public static String cleanBrokenChars(String input) {
        return input.replaceAll('[\\uFFFD\\?]+', '');
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

    public static String getClearContryName(String name) {
        if(String.isBlank(name)) return '';
        List<String> listWords = name.normalizeSpace().split(' ');
        List<String> listClean = new List<String>();

        for (String word : listWords) {
            if (!Consts.COUNTRY_SET.contains(word.toUpperCase())) {
                    listClean.add(word);
            }
        }
        return String.join(listClean, ' ').normalizeSpace();
    }

    //--- Утиліта для екранування HTML-символів
    public static String escapeHtml(String input) {
        if (String.isBlank(input)) return '';
        return input
            .replaceAll('&', '&amp;')
            .replaceAll('<', '&lt;')
            .replaceAll('>', '&gt;')
            .replaceAll('"', '&quot;')
            .replaceAll('\'', '&#39;');
    }

    /********* Методи для транслітерації **********************/
    //--- Метод для транслітерації кирилиці в латинку
    public static String translitCyrToLat(String input) {
        if (String.isBlank(input)) return '';

        // Повні слова, які мають фіксовану транслітерацію
        Map<String, String> fullWordMap = new Map<String, String>{
            'ЭНЕРДЖИ' => 'ENERGY','ЕНЕРДЖИ' => 'ENERGY','ЕНЕРДЖІ' => 'ENERGY',
            'ОПЕРЕЙТИНГ' => 'OPERATING','ОПЕРЕЙТІНГ' => 'OPERATING',
            'КОМПАНИ' => 'COMPANY','КОМПАНІ' => 'COMPANY',
            'ЛИМИТЕД' => 'LIMITED','ЛІМІТЕД' => 'LIMITED',
            'СОЛАР' => 'SOLAR','ТЕКНОЛОДЖИ' => 'TECHNOLOGY',
            'ТЕКНОЛОДЖІ' => 'TECHNOLOGY','ИНВЕСТ' => 'INVEST',
            'ІНВЕСТ' => 'INVEST','ТРЕЙДИНГ' => 'TRADING',
            'ТРЕЙДІНГ' => 'TRADING','СОЛЮШЕН'=>'SOLUTION',
            'СОЛЮШН'=>'SOLUTION','СОЛЬЮШЕН'=>'SOLUTION',
            'СОЛЬЮШН'=>'SOLUTION','ОЙЛ'=>'OIL'
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

    //--- Детектор розкладки - кирилиця чи латинка
    public static Consts.Alphabet detectAlphabet(String word) {
        if (String.isBlank(word)) return Consts.Alphabet.UNKNOWN;

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

        if (cyrillicCount > 0 && latinCount == 0) return Consts.Alphabet.CYR;
        if (latinCount > 0 && cyrillicCount == 0) return Consts.Alphabet.LAT;
        if (latinCount > 0 && cyrillicCount > 0) return Consts.Alphabet.MIXED;

        return Consts.Alphabet.UNKNOWN;
    }
    
    //--- Повертає мапу нормализованої назви та фонетичних кодів
    public static Map<String, String> getNorNameAndPhoneticCodes(String sourceName) {
        Map<String, String> resultMap = new Map<String, String>();
        if(String.isBlank(sourceName)) {
            System.debug('❌ ERROR: Lead Name is invalid!');
            return resultMap;
        }
        String s = getClearName(sourceName, Consts.ToUpperCase.YES,
                                                Consts.QuestionMarkRule.REMOVE_SIGN,
                                                Consts.ClearCountryName.NO);

        String sourceSoundexAll = String.join(StringUtilsEx.getSoundexEx(s), ' ');
        String sourceNysiisAll = StringUtilsEx.getNYSIIS(s);
        String sourcePhonetic  = PhoneticTranscoder.toPhoneticCode(s);
        MetaphoneUtils.MetaphoneResult mphResult = MetaphoneUtils.getMetaphoneFull(s);
        //String sourceSoundex3 = sourceSoundexAll.left(3);
        resultMap.put('NormalizedName__c', s);
        resultMap.put('PhoneticCode__c', sourcePhonetic);
        resultMap.put('NYSIIS__c', sourceNysiisAll);
        resultMap.put('NYSIISFirstCode__c', StringUtilsEx.getFirstWord(sourceNysiisAll));
        resultMap.put('SoundexAllWords__c', sourceSoundexAll);
        resultMap.put('SoundexFirstWord__c', StringUtilsEx.getFirstWord(sourceSoundexAll));
        resultMap.put('SoundexFirst3Letters__c', sourceSoundexAll.left(3));
        resultMap.put('MetaphonePrimary__c', mphResult.primary);
        resultMap.put('MetaphoneAlternate__c', mphResult.alternate);
        return resultMap;       
    } 

    /*--- Повертає лист лист або акаунтів(List<Account), або кастомних лідів (List<ClientLead__c)
          залежно від того, який параметр передано в метод - Consts.ACCOUNT_OBJ чи Consts.LEAD_OBJ
    */
    public static List<SObject> fetchRecords(String sObjectName, String whereClause) {
        // Однаковий список полів для обох об'єктів
        String fields = 'Id, Name, NormalizedName__c, PhoneticCode__c, MetaphonePrimary__c, ' +
                        'MetaphoneAlternate__c, NYSIISFirstCode__c, NYSIIS__c, ' +
                        'SoundexFirst3Letters__c, SoundexFirstWord__c, SoundexAllWords__c';

        String soql = 'SELECT ' + fields + ' FROM ' + sObjectName;
        if(!String.isBlank(whereClause)) soql = soql + ' WHERE ' + whereClause;
        return Database.query(soql);
    }

    //--- Методи-обгортки
    public static List<Account> fetchAccounts(String whereClause) {
        List<SObject> raw = fetchRecords(Consts.ACCOUNT_OBJ, whereClause);
        List<Account> result = new List<Account>();
        for (SObject s : raw) {
            result.add((Account)s);
        }
        return result;
    }

    public static List<ClientLead__c> fetchLeads(String whereClause) {
        List<SObject> raw = fetchRecords(Consts.LEAD_OBJ, whereClause);
        List<ClientLead__c> result = new List<ClientLead__c>();
        for (SObject s : raw) {
            result.add((ClientLead__c)s);
        }
        return result;
    }  
      
    //--- Метод для апдейту NormalizedName__c і фонетичних індексів
    public static void updatePhoneticFields(String sObjectName, String whereClause) {
        String fieldList = 'Id, Name';
        List<String> targetFields = new List<String>{
            'NormalizedName__c',
            'PhoneticCode__c',
            'NYSIIS__c',
            'NYSIISFirstCode__c',
            'SoundexAllWords__c',
            'SoundexFirstWord__c',
            'SoundexFirst3Letters__c',
            'MetaphonePrimary__c',
            'MetaphoneAlternate__c'
        };
        fieldList += ', ' + String.join(targetFields, ', ');

        String query = 'SELECT ' + fieldList + ' FROM ' + sObjectName;
        if (!String.isBlank(whereClause)) {
            query += ' WHERE ' + whereClause;
        }

        List<SObject> records = Database.query(query);
        List<SObject> toUpdate = new List<SObject>();
        List<UpdateFailure__c> failureLogs = new List<UpdateFailure__c>();

        for (SObject rec : records) {
            String name = (String)rec.get('Name');
            if (String.isBlank(name)) continue;

            Map<String, String> values = getNorNameAndPhoneticCodes(name);
            Boolean hasChanged = false;

            for (String field : targetFields) {
                if (rec.get(field) != values.get(field)) {
                    rec.put(field, values.get(field));
                    hasChanged = true;
                }
            }

            if (hasChanged) {
                toUpdate.add(rec);
            }
        }

        if (!toUpdate.isEmpty()) {
            Database.SaveResult[] results = Database.update(toUpdate, false);

            for (Integer i = 0; i < results.size(); i++) {
                if (!results[i].isSuccess()) {
                    SObject failed = toUpdate[i];
                    for (Database.Error err : results[i].getErrors()) {
                        failureLogs.add(new UpdateFailure__c(
                            RecordId__c = (Id)failed.get('Id'),
                            ObjectType__c = sObjectName,
                            ErrorMessage__c = err.getMessage(),
                            Context__c = 'PhoneticFieldUpdater'
                        ));
                    }
                }
            }

            if (!failureLogs.isEmpty()) {
                insert failureLogs;
            }
        }
    } 
    
    /********* Нормалізація назв за словником синонімів *********/
    //--- ВАРІАНТ 1 — Простий і оптимальний (для нормалізації назв)
    public static String changeSynonimsWords(String s) {
        if (String.isBlank(s)) return s;
    
        Map<String, String> dict = Consts.NAMES_DICT;
        List<String> words = s.split('[\\s,;\\-\\/\\\\\\.\\(\\)]');
        List<String> resultWords = new List<String>();
    
        for (String word : words) {
            if (String.isBlank(word)) continue;
    
            String upper = word.toUpperCase();
            if (dict.containsKey(upper)) {
                resultWords.add(dict.get(upper));
            } else {
                resultWords.add(word);
            }
        }
    
        return String.join(resultWords, ' ');
    }
    
    //--- ВАРІАНТ 2 — З точковою заміною в тексті (з розділовими знаками)
    public static String changeSynonimsWordsByPattern(String s) {
        if (String.isBlank(s)) return s;
    
        Map<String, String> dict = Consts.NAMES_DICT;
    
        // Побудова патерну з ключів у верхньому регістрі
        List<String> upperKeys = new List<String>();
        for (String key : dict.keySet()) {
            upperKeys.add(Pattern.quote(key.toUpperCase())); // на випадок спецсимволів у ключах
        }
    
        String pattern = '\\b(' + String.join(upperKeys, '|') + ')\\b';
        System.Pattern p = System.Pattern.compile(pattern);
        System.Matcher m = p.matcher(s.toUpperCase());
    
        String result = '';
        Integer lastEnd = 0;
    
        while (m.find()) {
            String matchedWord = m.group(1);
            String replacement = dict.get(matchedWord);
    
            // Додаємо частину оригінального рядка + заміну
            result += s.substring(lastEnd, m.start()) + replacement;
            lastEnd = m.end();
        }
    
        result += s.substring(lastEnd);
        return result;
    }        
}