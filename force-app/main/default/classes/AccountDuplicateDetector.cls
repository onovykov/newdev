public class AccountDuplicateDetector {
    public static final Boolean FIRST_WORDS = true;
    public static final Boolean ALL_WORDS = false;
    public static final Boolean NEED_TRANSLIT = true;
    public static final Boolean NOT_TRANSLIT = false;
    
    //--- Метод, який шукає потенційні дублікати серед листа акаунтів
    //    Параметри:
    //    - String newAccountName - початкова назва, для якої шукаємо дублікати
    //    - List<Account> accList - лист акаунтів, серед яких шукаємо дублікати
    //    - Boolean isNeedTranslit - чи потрібно також шукати варіанти з транслітерацією
    //------------------------------------------------------------------------------------
    public static List<Account> findPotentialDuplicates(String newAccountName, List<Account> accList, Boolean isNeedTranslit) {
        List<Account> potentialDuplicates = new List<Account>();
        // Перевіряємо коректність параметрів
        if(String.isBlank(newAccountName) || (accList.isEmpty() || accList==null)) {
            System.debug('❌ERROR! Arguments are invalid!');
            return potentialDuplicates; 
        }
        // Визначаємо абетку нової назви
        String alphabet = StringUtilsEx.detectAlphabet(newAccountName); // 'Cyr' або 'Lat'
        
        // Нормалізуємо назву
        String normalizedNewName = normalize(newAccountName, alphabet, isNeedTranslit);
        // Розбиваємо назву на окремі слова
        Set<String> newNameWords = splitIntoWords(normalizedNewName);
        // Для кожного запису листа акаунті:
        for (Account acc : accList) {
            // Нормалізуємо назву поточного акаунта
            String normalizedExistingName = normalize(acc.Name, alphabet, isNeedTranslit);
            // Розбиваємо назву на окремі слова
            Set<String> existingNameWords = splitIntoWords(normalizedExistingName);
            
            // Вибираємо до окремого сету всі спільні слова з початкової та поточної назви
            Set<String> common = new Set<String>(newNameWords);
            common.retainAll(existingNameWords);
            // Якщо спільних слів одне або більше - записуємо як потенційний дубль
            if (common.size() >= 1) { // поріг
                potentialDuplicates.add(acc);
            }
        }

        return potentialDuplicates;
    }

    //--- Приватний метод, який нормалізує назву для пошуку
    private static String normalize(String input, String targetAlphabet, Boolean isNeedTranslit) {
        // Чистимо назву від сміття
        String s = StringUtilsEx.getClearName(input, true);
        // Якщо не треба трансліту - повертаємо результат
        if (!isNeedTranslit) return s;
        // Інакше - визначаємо абетку початкової назви
        String currentAlphabet = StringUtilsEx.detectAlphabet(s);
        
        // Якщо абетки початкової назви та тої, в яку треба транслітерувати, збігаються - повертаємо результат
        if (currentAlphabet == targetAlphabet) {
            return s;
        }
        
        // Транслітеруємо назву
        if (targetAlphabet == 'Cyrillic') {
            return StringUtilsEx.translitLatinToCyr(s);
        } else {
            return StringUtilsEx.transliterateCyrillicToLatin(s);
        }
    }

    //--- Приватний метод, який розбиває назву на сет слів
    private static Set<String> splitIntoWords(String input) {
        input = StringUtilsEx.getClearName(input, true);
        List<String> words = input.split('\\s+');
        return new Set<String>(words);
    }
    
    //--- Метод, який підготовує назву для методу getAccountDuplicates
    //  - чистить від сміття, додає діакритичні варіанти, синоніми тощо
    public static String getPreparedName(String sourceString) {
        if (String.isBlank(sourceString)) {
            System.debug('❌ERROR! Argument is invalid!');
            return '';
        }
        // Чистимо початковий рядок від сміття
        String s = StringUtilsEx.getClearName(sourceString, true);
        // Нормалізуємо дифтонги
        s = StringUtilsEx.clearDiphthongs(s);
        // Отримуємо можливі діакритичні варіанти
        List<Set<String>> lss = StringUtilsEx.getDiacriticVariants(sourceString, true, true);
        // Переносимо знайдені діакритичні варіанти до початкового рядка
        List<String> newLS = new List<String>(StringUtilsEx.flattenListOfSets(lss));
        String new_str = String.join(newLS,' ');
        Set<String> setTmp = new Set<String>(new_str.split(' '));
        List<String> new_s_list = StringUtilsEx.setToList(setTmp, false, true);
        
        return String.join(new_s_list, ' ');
    }   

    //--- Метод для більш точного фільтрування отриманого листа можливих збігів
    //    Передаються параметри:
    //    - String sourceRawName - початкова назва для пошуку
    //    - List<Account> candidates - лист акаунтів після першого пошуку
    public static List<Account> filterStrictWordMatches(String sourceRawName, List<Account> candidates) {
        String cleanSource = StringUtilsEx.getClearName(sourceRawName, true);
        Set<String> sourceWords = new Set<String>(cleanSource.split('\\s+'));
    
        List<Account> result = new List<Account>();
    
        for (Account acc : candidates) {
            String accCleanName = StringUtilsEx.getClearName(acc.Name, true);
            Set<String> accWords = new Set<String>(accCleanName.split('\\s+'));
    
            // Підходить, лише якщо ВСІ слова з acc є в джерельній назві
            if (sourceWords.containsAll(accWords)) {
                result.add(acc);
            }
        }
    
        return result;
    }  

    //--- Метод для більш точного фільтрування отриманого листа можливих збігів - розширена версія
    //    Передаються параметри:
    //    - String sourceRawName - початкова назва для пошуку
    //    - List<Account> candidates - лист акаунтів після першого пошуку
    //    - Integer minWordsToMatch - скільки подібних слів мусять мати назви, які ми порівнюємо
    //    - Boolean matchFirstWordsOnly - чи треба шукати відповідники тільки по перших словах
    public static List<Account> filterStrictWordMatches(
        String sourceRawName,
        List<Account> candidates,
        Integer minWordsToMatch,
        Boolean matchFirstWordsOnly
    ) {
        String cleanSource = StringUtilsEx.getClearName(sourceRawName, true);
        List<String> sourceWordList = cleanSource.split('\\s+');
        Set<String> sourceWords = new Set<String>(sourceWordList);
    
        // Обираємо лише перші N або будь-які N слів для порівняння
        Set<String> referenceWords = new Set<String>();
        if (matchFirstWordsOnly) {
            for (Integer i = 0; i < Math.min(minWordsToMatch, sourceWordList.size()); i++) {
                referenceWords.add(sourceWordList[i]);
            }
        } else {
            Integer count = 0;
            for (String word : sourceWords) {
                if (count >= minWordsToMatch) break;
                referenceWords.add(word);
                count++;
            }
        }
    
        List<Account> result = new List<Account>();
    
        for (Account acc : candidates) {
            String accCleanName = StringUtilsEx.getClearName(acc.Name, true);
            Set<String> accWords = new Set<String>(accCleanName.split('\\s+'));
    
            // Підходить, якщо accWords містить ВСІ слова з referenceWords
            if (accWords.containsAll(referenceWords)) {
                result.add(acc);
            }
        }
    
        return result;
    }  

    //--- Метод, що повертає лист дублікатів, не використовуючи SELECT
    public static List<Account> getAccountDuplicates(String sourceString, Boolean matchFirstWordsOnly) {

        if(String.isBlank(sourceString)) return null;
        // Підготовуємо назву
        String newAccountName = AccountDuplicateDetector.getPreparedName(sourceString);
        
        // Отримуємо перший набір можливих дублікатів
        List<Account> duplicatesAll = AccountDuplicateDetector.findPotentialDuplicates(newAccountName, AccountRepository.getAllAccounts(), true);
        // Уточнюємо пошук
        List<Account> duplicates2 = AccountDuplicateDetector.filterStrictWordMatches(newAccountName, duplicatesAll , 2, matchFirstWordsOnly);
        
        // Якщо уточнений пошук повернув результат - повертаємо його, інакше повертаємо перший набір
        return duplicates2.size()>0 ? duplicates2 : duplicatesAll;         
    }   
}