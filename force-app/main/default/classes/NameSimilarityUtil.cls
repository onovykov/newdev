public class NameSimilarityUtil {
    public static final Boolean TO_UPPER_CASE = true;
    public static final Boolean TO_LOWER_CASE = false;
    public static final Boolean FIND_BY_NAME = true;
    public static final Boolean FIND_BY_CODE = false;
    public static final Boolean FIND_BY_ID_ERP = true;
    public static final Boolean FIND_BY_SF_ID = false;  
    public static final Boolean BY_SELECT = true;
    public static final Boolean BY_APEX = false;     
    public static final Boolean INSERT_YES = true;
    public static final Boolean INSERT_NO = false;
    
    // --- Повертає унікальні пари String/Account для початкового рядку пошуку ---
    //     Застосовується тоді, коли ми шукаємо можливі дублі для нової назви серед уже наявних акаунтів
    //     В пару додається
    //     - назва, яка є основою пошку (пошук за назвою - isFindByName=true)
    //     - об'єкт Account в поле acc1 класу AccountPair
    //       Поле acc2 в цьому разі завжди буде null
    //       Порівняння назв та обрахунок match-індексів робиться для рядку назви та поля acc1.Name
    public static List<AccountPair> getAccPairList(String sourceString, List<Account> accList) {
        List<AccountPair> accPairList = new List<AccountPair>();
        if (accList == null || accList.isEmpty()) {
            System.debug('❌ ERROR: List of arguments is invalid!');
            return accPairList;
        }

        for(Account recAcc : accList) {
            accPairList.add(new AccountPair(sourceString, recAcc, null));
        }
        return accPairList;
    }

    // --- Повертає унікальні пари акаунтів з довільного листа ---
    public static List<AccountPair> getAccPairList(List<Account> accList) {
        List<AccountPair> accPairList = new List<AccountPair>();
        if (accList == null || accList.isEmpty()) {
            System.debug('❌ ERROR: List of arguments is invalid!');
            return accPairList;
        }

        for (Integer i = 0; i < accList.size(); i++) {
            for (Integer j = i + 1; j < accList.size(); j++) {
                accPairList.add(new AccountPair('', accList[i], accList[j]));
            }
        }
        return accPairList;
    }

    // --- Побудова пар для основного акаунта з усіма іншими — знаємо Id ---
    public static List<AccountPair> getAccPairList(List<Account> accList, Id mainAccId) {
        List<AccountPair> accPairList = new List<AccountPair>();

        if (accList == null || accList.isEmpty() || mainAccId == null) {
            System.debug('❌ ERROR: List or mainAccId is invalid!');
            return accPairList;
        }

        Account mainAcc = null;
        for (Account acc : accList) {
            if (acc.Id == mainAccId) {
                mainAcc = acc;
                break;
            }
        }

        if (mainAcc == null) {
            System.debug('❌ ERROR: Main account with given Id not found in the list!');
            return accPairList;
        }

        return buildPairsWithMain(mainAcc, accList);
    }

    // --- Побудова пар для основного акаунта з усіма іншими — знаємо сам об'єкт ---
    public static List<AccountPair> getAccPairList(Account mainAcc, List<Account> accList) {
        if (mainAcc == null || accList == null || accList.isEmpty()) {
            System.debug('❌ ERROR (getAccPairList): Arguments are invalid!');
            return new List<AccountPair>();
        }

        return buildPairsWithMain(mainAcc, accList);
    }

    // --- Приватний допоміжний метод для формування пар ---
    private static List<AccountPair> buildPairsWithMain(Account mainAcc, List<Account> accList) {
        List<AccountPair> result = new List<AccountPair>();
        for (Account acc : accList) {
            if (acc.Id != mainAcc.Id) {
                result.add(new AccountPair('', mainAcc, acc));
            }
        }
        return result;
    }

    //-- Інвертуємо levensteinScore ---
    private static Decimal invLenevsteinScore(Decimal levensteinScore) {
            return (1.000 - levensteinScore).setScale(3);
    }

    // --- Обраховує метрики схожості й записує їх у AccountPair ---
    public static void compareNames(List<AccountPair> accountPairs, WeightSet weights) 
    {
        if (accountPairs == null || accountPairs.isEmpty()) {
            System.debug('❌ ERROR: List of arguments is invalid!');
            return;
        }

        for (AccountPair accPair : accountPairs) {
            String name1 = '';
            String name2 = '';
            if(accPair.acc1!=null && accPair.acc2!=null) {
                // Був пошук по Id - маємо пару об'єктів Account
                name1 = StringUtilsEx.getClearName(accPair.acc1.Name, TO_UPPER_CASE);
                name2 = StringUtilsEx.getClearName(accPair.acc2.Name, TO_UPPER_CASE);
            } else {
                if(accPair.acc1!=null && !String.isBlank(accPair.sourceName)) {
                    // Був пошук по назві (частині назви) - маємо пару + об'єкт Account
                    name1 = StringUtilsEx.getClearName(accPair.sourceName, TO_UPPER_CASE);
                    name2 = StringUtilsEx.getClearName(accPair.acc1.Name, TO_UPPER_CASE);
                }
            }

            Decimal jaccardScore = 0, levensteinScore = 0, metaphoneScore = 0, diceScore = 0, cosineScore = 0, soundexScore = 0, finalScore = 0;

            if (!String.isBlank(name1) && !String.isBlank(name2)) {
                // Якщо назви в різних абетках - примусово транслітеруємо до латинки
                String alpha1 = StringUtilsEx.detectAlphabet(name1);
                String alpha2 = StringUtilsEx.detectAlphabet(name2);
                if (alpha1 != alpha2) {
                    if (alpha1 == 'Cyrillic' && alpha2 == 'Latin') {
                        name1 = StringUtilsEx.transliterateCyrillicToLatin(name1);
                    } else if (alpha2 == 'Cyrillic' && alpha1 == 'Latin') {
                          name2 = StringUtilsEx.transliterateCyrillicToLatin(name2);
                      } else {
                            name1 = StringUtilsEx.transliterateCyrillicToLatin(name1);
                            name2 = StringUtilsEx.transliterateCyrillicToLatin(name2);
                        }
                    
                }
                // Обраховуємо match-індекси
                jaccardScore = StringUtilsEx.JaccardSimilarity(name1, name2, 2);
                levensteinScore = invLenevsteinScore(StringUtilsEx.getNormalizedLevenstein(name1, name2));
                metaphoneScore = MetaphoneUtils.getWordLevelSimilarity(name1, name2);
                diceScore = StringUtilsEx.DiceSimilarity(name1, name2);
                cosineScore = StringUtilsEx.CosineSimilarity(name1, name2);
                soundexScore = StringUtilsEx.compareSoundexFull(name1, name2);

                System.debug('jaccardScore: ' + jaccardScore);
                System.debug('levensteinScore: ' + levensteinScore);
                System.debug('metaphoneScore: ' + metaphoneScore);
                System.debug('diceScore: ' + diceScore);
                System.debug('cosineScore: ' + cosineScore);
                System.debug('soundexScore: ' + soundexScore);

                finalScore = (
                    jaccardScore * weights.jacWeight +
                    levensteinScore * weights.levWeight +
                    metaphoneScore * weights.metWeight +
                    diceScore * weights.dicWeight +
                    cosineScore * weights.cosWeight +
                    soundexScore * weights.sndWeight
                );
            }

            accPair.jaccardScore = jaccardScore.setScale(3);
            accPair.levensteinScore = levensteinScore.setScale(3);
            accPair.metaphoneScore = metaphoneScore.setScale(3);
            accPair.diceScore = diceScore.setScale(3);
            accPair.cosineScore = cosineScore.setScale(3);
            accPair.soundexScore = soundexScore.setScale(3);
            accPair.finalScore = finalScore.setScale(3);
            accPair.ScoreVerdict = getScoreVerdict(finalScore.setScale(3));
        }
    }

    public static String getScoreVerdict(Decimal finalScore) {
        String matchLevel = '';
        if(finalScore<0.0 || finalScore==null || finalScore>1.002) {
            System.debug('❌ ERROR: Argument is incorrect');
            return '';
        }
        if(finalScore>=0.000 && finalScore<=0.200) {
            matchLevel = 'NOT MATCH';
        }
        if(finalScore>0.200 && finalScore<=0.400) {
            matchLevel = 'LOW MATCH';
        }
        if(finalScore>0.400 && finalScore<=0.600) {
            matchLevel = 'MIDDLE MATCH';
        }
        if(finalScore>0.600 && finalScore<=0.800) {
            matchLevel = 'HIGH MATCH';
        }
        if(finalScore>0.800) {
            matchLevel = 'STRONG MATCH';
        }
        return matchLevel;
    }

    /***** Основний метод, що повертає лист об'єктів  MatchAccountsPair__c *****/
    /***************************************************************************/
    //  Параметр Boolean getAccMethodType визначає, яким методо отримуємо лист акаунтів
    //  Ці значення наперед задано в константах
    //  - BY_SELECT = true (старий метод, що використовує SOQL SELECT)
    //  - BY_APEX = false (новий метод без використвння SOQL SELECT, тільки кодом Apex)
    //-------------------------------------------------------------------------------------
    public static List<MatchAccountsPair__c> getMatchAccounts(Boolean getAccMethodType, Boolean matchType, String sourceName,
                                                              Boolean typeIdForMatch, String strIdForFind,
                                                              Boolean bFirstWordsOnly, Boolean bUseTranslit,
                                                              WeightSet weights, Boolean insertObject) {
                                                                  
        List<MatchAccountsPair__c> resultPairList = new List<MatchAccountsPair__c>();
        
        // Перевіряємо коректність параметрів
        if(matchType==FIND_BY_CODE) {
            System.debug('Пошук по коду');
            if(typeIdForMatch==FIND_BY_SF_ID) {
                System.debug('FIND_BY_SF_ID');
                System.debug('typeIdForMatch==FIND_BY_SF_ID : ' + (typeIdForMatch==FIND_BY_SF_ID));
                if(!StringUtilsEx.isValidSalesforceId(strIdForFind)) {
                    System.debug('❌ ERROR: Salesforce Id is invalid');
                    return resultPairList;
                }
            } else if(typeIdForMatch==FIND_BY_ID_ERP) {
                System.debug('FIND_BY_ID_ERP');
                System.debug('typeIdForMatch==FIND_BY_ID_ERP : ' + (typeIdForMatch==FIND_BY_ID_ERP));
                if(!strIdForFind.isNumeric()) {
                    System.debug('❌ ERROR: ID_ERP__c is invalid');
                    return resultPairList;
                }
            }       
        } else {
            if(String.isBlank(sourceName)){
                System.debug('❌ ERROR: Parameter "Source Name" is invalid');
                return resultPairList;
            }
        }
        
        List<Account> accList = new List<Account>();
        // Отримуємо лист акаунтів
        if(getAccMethodType == BY_SELECT) {
            accList = new List<Account>(StringUtilsEx.GetAccountsList(matchType, typeIdForMatch, strIdForFind,
                                                                                sourceName, bFirstWordsOnly, bUseTranslit));
        } else {
            accList = new List<Account>(StringUtilsEx.getAccountList(matchType, typeIdForMatch, strIdForFind,
                                                                                sourceName, bFirstWordsOnly));          
        }
        
        // Перевіряємо коректність отриманого листа акаунтів
        if(accList.isEmpty() || accList==null) {
            System.debug('❌ ERROR: Resulting List<Account> is empty!');
            return resultPairList;          
        }
        
        
        List<AccountPair> pairList = new List<AccountPair>();
        // Визначаємо тип конструктора AccountPair      
        if(matchType==FIND_BY_NAME) { // Пошук по назві
            // Формуємо лист пар збігів - рядок назви + List<Account> 
            pairList = new List<AccountPair>(getAccPairList(sourceName, accList));
        } else if(matchType==FIND_BY_CODE) { // Пошук по коду
            Account mainAcc = new Account();
            if(typeIdForMatch==FIND_BY_SF_ID) {
                mainAcc = AccountRepository.getById((Id)strIdForFind);                             
            } else if((typeIdForMatch==FIND_BY_ID_ERP)) {
                mainAcc = AccountRepository.getByErp(strIdForFind);
            }
            // Формуємо лист пар збігів - mainAcc + List<Account>               
            pairList = new List<AccountPair>(getAccPairList(mainAcc, accList)); 
        }

        if(!pairList.isEmpty() && pairList!=null) {
            compareNames(pairList, weights);
            for(AccountPair pairRec : pairList) {
                MatchAccountsPair__c matchRec = new MatchAccountsPair__c();
                matchRec.sourceString__c = (String.isBlank(pairRec.sourceName)) ? '' : pairRec.sourceName;
                matchRec.Account1__c = (pairRec.acc1==null) ? null : pairRec.acc1.Id;
                matchRec.Account2__c = (pairRec.acc2==null) ? null : pairRec.acc2.Id;
                matchRec.jaccardScore__c = pairRec.jaccardScore;
                matchRec.levensteinScore__c = pairRec.levensteinScore;
                matchRec.metaphoneScore__c = pairRec.metaphoneScore;
                matchRec.diceScore__c = pairRec.diceScore;
                matchRec.cosineScore__c = pairRec.cosineScore;
                matchRec.soundexScore__c = pairRec.soundexScore;
                matchRec.finalScore__c = pairRec.finalScore;
                matchRec.ScoreVerdict__c = pairRec.ScoreVerdict;
                resultPairList.add(matchRec);
            }
            if(insertObject) insert resultPairList;
        } else {
            System.debug('❌ ERROR: Resulting object is empty!'); 
        }

        System.debug('💥 Знайдені пари дублів:');
        for (MatchAccountsPair__c rec : resultPairList) {
            System.debug('➡ ' + rec.Account1__c + ' vs ' + rec.Account2__c +
                    ' | finalScore: ' + rec.finalScore__c +
                    ' | Jaccard: ' + rec.jaccardScore__c +
                    ' | Levenshtein: ' + rec.levensteinScore__c);
        }

        return resultPairList;      
    }       
    
    /***************************************************************/   
    // --- Структура для зберігання пари акаунтів і результатів ---
    /***************************************************************/
    public class AccountPair {
        public String sourceName;
        public Account acc1;
        public Account acc2;
        public Decimal jaccardScore;
        public Decimal levensteinScore;
        public Decimal metaphoneScore;
        public Decimal diceScore;
        public Decimal cosineScore;
        public Decimal soundexScore;
        public Decimal finalScore;
        public String ScoreVerdict;

        public AccountPair(String sourceName, Account a1, Account a2) {
            this.sourceName = sourceName;
            this.acc1 = a1;
            this.acc2 = a2;
            this.jaccardScore = 0;
            this.levensteinScore = 0;
            this.metaphoneScore = 0;
            this.diceScore = 0;
            this.cosineScore = 0;
            this.soundexScore = 0;
            this.finalScore = 0;
            this.ScoreVerdict = '';
        }

        public AccountPair(String sourceName, Account a1, Account a2, Decimal j, Decimal l, Decimal m, 
                           Decimal d, Decimal c, Decimal sndScore, Decimal f, String ScoreVerdict) {
            this.sourceName = sourceName;
            this.acc1 = a1;
            this.acc2 = a2;
            this.jaccardScore = (j != null ? j.setScale(3) : 0).setScale(3);
            this.levensteinScore = (l != null ? l.setScale(3) : 0).setScale(3);
            this.metaphoneScore = (m != null ? m.setScale(3) : 0).setScale(3);
            this.diceScore = (d != null ? d.setScale(3) : 0).setScale(3);
            this.cosineScore = (c != null ? c.setScale(3) : 0).setScale(3);
            this.soundexScore = (sndScore != null ? sndScore.setScale(3) : 0).setScale(3);
            this.finalScore = (f != null ? f.setScale(3) : 0).setScale(3);          
            this.ScoreVerdict = getScoreVerdict((f != null ? f.setScale(3) : 0).setScale(3));
        }
    }
    
    
    //--- Клас і метод для пошуку дублів серед наявних акаунтів
    public class MatchResult {
        public Id account1Id;
        public Id account2Id;
        public Decimal matchIndex;

        public MatchResult(Id a1, Id a2, Decimal idx) {
            this.account1Id = a1;
            this.account2Id = a2;
            this.matchIndex = idx;
        }
    }

    public static List<MatchResult> findPotentialDuplicates(Decimal threshold) {
        List<Account> accounts = [SELECT Id, Name, 
                                  PhoneticCode__c, MetaphonePrimary__c, MetaphoneAlternate__c,
                                  NYSIIS__c, SoundexAllWords__c
                                  FROM Account
                                  WHERE Name != null];

        List<MatchResult> results = new List<MatchResult>();

        for (Integer i = 0; i < accounts.size(); i++) {
            for (Integer j = i + 1; j < accounts.size(); j++) {
                Account a1 = accounts[i];
                Account a2 = accounts[j];

                Decimal matchIndex = StringUtilsEx.getCommonMatchIndex(
                    a1.PhoneticCode__c, a2.PhoneticCode__c,
                    a1.MetaphonePrimary__c, a2.MetaphonePrimary__c,
                    a1.MetaphoneAlternate__c, a2.MetaphoneAlternate__c,
                    a1.NYSIIS__c, a2.NYSIIS__c,
                    a1.SoundexAllWords__c, a2.SoundexAllWords__c
                );

                if (matchIndex >= threshold) {
                    results.add(new MatchResult(a1.Id, a2.Id, matchIndex));
                }
            }
        }

        return results;
    }    

    // Фінальний метод пошуку діблів
    public static List<StringUtilsEx.MatchResult> finalDuplicateCheck(Boolean findType, String sourceName, Boolean findCodeType, 
                                      String code_ID_ERP, String code_SF_Id, Decimal threshold, 
                                      Boolean insertObject, IndexWeights idxWeights, WeightSet pairWeights) {
                                          
        List<StringUtilsEx.MatchResult> resultList = new List<StringUtilsEx.MatchResult>();
        Account acc = new Account();
        Id sourceAccId = null;
        // 1. Перевірка параметрів                                  
        if (findType == Consts.FIND_BY_NAME) { // Пошук по довільній назві чи частині назви
            if(String.isBlank(sourceName)) {
                System.debug('❌ERROR! Source Name is invalid!');
                return resultList;
            }
        }
        if(findType == Consts.FIND_BY_CODE) {
            if(findCodeType == Consts.FIND_BY_SF_ID) {
                if(!StringUtilsEx.isValidSalesforceId(code_SF_Id)) {
                    System.debug('❌ERROR! Salesforce Id is invalid!');
                    return resultList;              
                }
            }
            if(findCodeType == Consts.FIND_BY_ID_ERP) {
                if(!code_ID_ERP.isNumeric()) {
                    System.debug('❌ERROR! Code ID_ERP__c is invalid!');
                    return resultList;                  
                }
            }       
        }
        if (threshold == null || threshold < 0.0 || threshold > 1.001) {
            System.debug('⚠️WARNING! Parameter threshold was set to default: 0.600');
            threshold = 0.6;
        }
        if(idxWeights == null) {
            System.debug('⚠️WARNING! IndexWeights was set to default: 0.600');
            idxWeights = IndexWeights.getDefault(); 
        }
        if(pairWeights == null) {
            System.debug('⚠️WARNING! WeightSet was set to default: 0.600');
            pairWeights = WeightSet.getDefault();
        }

        // 2. Джерело пошуку - по коду. Отримуємо назву для пошуку
        if (findType == Consts.FIND_BY_CODE) {
            acc = (findCodeType == Consts.FIND_BY_ID_ERP)
                ? AccountRepository.getByErp(code_ID_ERP)
                : AccountRepository.getById(code_SF_Id);

            sourceName = acc.Name;
            sourceAccId = acc.Id;
        }   
        
        // 3. Нормалізація назви
        String normalizedName = StringUtilsEx.getClearName(sourceName, true);
        if (StringUtilsEx.detectAlphabet(normalizedName) != Consts.LAT) {
            normalizedName = StringUtilsEx.transliterateCyrillicToLatin(normalizedName);
        } else {
            //normalizedName = StringUtilsEx.clearDiphthongs(normalizedName);
            normalizedName = StringUtilsEx.normalizeDiacritics(normalizedName);
        }   
        
        // 4. Отримання індексів
        String sourcePhonetic     = PhoneticTranscoder.toPhoneticCode(normalizedName);
        String sourceNYSIIS       = StringUtilsEx.getNYSIIS(normalizedName);
        String sourceSoundexAll   = String.join(StringUtilsEx.getSoundexEx(normalizedName), ' ');
        MetaphoneUtils.MetaphoneResult mphSource = MetaphoneUtils.getMetaphoneFull(normalizedName);

        System.debug('📊 sourcePhonetic: ' + sourcePhonetic);
        System.debug('📊 Soundex: ' + sourceSoundexAll);
        System.debug('📊 NYSIIS: ' + sourceNYSIIS);
        System.debug('📊 Metaphone: ' + mphSource.primary + ', ' + mphSource.alternate);


        // 5. Soundex3 кожного слова початкової назви
        List<String> sourceSoundex3List = new List<String>();
        for (String word : normalizedName.split(' ')) {
            sourceSoundex3List.add(StringUtilsEx.soundex(word).left(3));
        }

        // 6. Отримання всіх потенційних дублів (по Soundex3) через один SOQL
        Set<String> uniqueCodes = new Set<String>(sourceSoundex3List);
        List<Account> accListAll = [
            SELECT Id, Name, PhoneticCode__c, MetaphonePrimary__c, MetaphoneAlternate__c,
                   NYSIIS__c, SoundexAllWords__c, SoundexFirst3Letters__c
            FROM Account
            WHERE SoundexFirst3Letters__c IN :uniqueCodes
        ];

        System.debug('SEVEN');
        // 7. Порівняння через утиліту compareAllToOne
        resultList = StringUtilsEx.compareAllToOne(
            accListAll,
            SourceName,
            sourceAccId,
            findType,
            sourcePhonetic,
            mphSource.primary,
            mphSource.alternate,
            sourceNYSIIS,
            sourceSoundexAll,
            idxWeights,
            threshold,
            insertObject
        );
        
        // 8. Повертаємо знайдені збіги
        return resultList;
    }
    
    //--- Швидкий метод пошуку дублів по наявних фонет. кодах і норм неймах в полях Account
    public static List<StringUtilsEx.MatchResult> fastDuplicateCheck(String sourceName, Decimal threshold) {

        List<StringUtilsEx.MatchResult> resultList = new List<StringUtilsEx.MatchResult>();

        if(String.isBlank(sourceName)) {
            System.debug('❌ERROR! Source Name is invalid!');
            return resultList;
        }

        if (threshold == null || threshold < 0.0 || threshold > 1.000) {
            System.debug('⚠️WARNING! Parameter threshold was set to default: 0.8');
            threshold = 0.8;
        }
        String s = StringNormalize.getClearName(sourceName, Consts.ToUpperCase.YES,
                                                Consts.QuestionMarkRule.REMOVE_SIGN,
                                                Consts.ClearCountryName.NO);
        String sourceSoundexAll = String.join(StringUtilsEx.getSoundexEx(s), ' ');
        String sourceNysiisAll = StringUtilsEx.getNYSIIS(s);
        String sourcePhonetic  = PhoneticTranscoder.toPhoneticCode(s);
        MetaphoneUtils.MetaphoneResult mphResult = MetaphoneUtils.getMetaphoneFull(s);

        String sourceSoundex3 = sourceSoundexAll.left(3);
        List<Account> accList = AccountRepository.getAllAccounts();
        List<Account> matchAccList = AccountRepository.getByFieldValue('SoundexFirst3Letters__c', sourceSoundex3);
        if(matchAccList.isEmpty()) {
            System.debug('No match results');
            return resultList;
        }

        Integer lenS = s.length();
        String strAcc = '';
        String accSoundex = '';
        String accNysiis = '';
        String accPhonetic = '';
        MetaphoneUtils.MetaphoneResult accMetaphone = new MetaphoneUtils.MetaphoneResult();
        for(Account acc : matchAccList) {
            if(acc.NormalizedName__c.length()>lenS) {
                strAcc = acc.NormalizedName__c.substring(0,lenS);
            } else {
                strAcc = acc.NormalizedName__c;
            }
            accSoundex = String.join(StringUtilsEx.getSoundexEx(strAcc), ' ');
            accNysiis = StringUtilsEx.getNYSIIS(strAcc);
            accPhonetic = PhoneticTranscoder.toPhoneticCode(strAcc);
            accMetaphone = MetaphoneUtils.getMetaphoneFull(strAcc);

            Decimal sndIx = StringUtilsEx.compareSoundexAllCodes(sourceSoundexAll, accSoundex);
            Decimal nysIdx = StringUtilsEx.compareNysiisWords(sourceNysiisAll, accNysiis,
                                                              StringUtilsEx.getNysiisCache(sourceNysiisAll, accNysiis));
            Set<String> allCodes = new Set<String>();
            allCodes.add(sourcePhonetic);
            allCodes.add(accPhonetic);
            Map<String, Set<String>> bigramsMap = PhoneticTranscoder.buildBigramsCache(new List<String>(allCodes));
            Map<String, Set<String>> lettersMap = PhoneticTranscoder.buildLettersCache(new List<String>(allCodes));
            Decimal phnIdx = PhoneticTranscoder.comparePhoneticHybridCached(sourcePhonetic, accPhonetic, bigramsMap, lettersMap);

            // - сети для кодів Metaphone
            Set<String> mphCodes1 = new Set<String>();
            Set<String> mphCodes2 = new Set<String>();

            // - заповнюємо сети кодами
            mphCodes1.add(mphResult.primary);
            mphCodes1.add(mphResult.alternate);

            mphCodes2.add(accMetaphone.primary);
            mphCodes2.add(accMetaphone.alternate);

            Decimal mphIdx = MetaphoneUtils.compareMetaphoneLetterSets(mphCodes1, mphCodes2);

            Decimal resIdx = (sndIx + nysIdx + phnIdx + mphIdx)/4.0;
            if(resIdx >= threshold) {
                StringUtilsEx.MatchResult resRec = new StringUtilsEx.MatchResult(sourceName, acc.Id, null, resIdx.setScale(3));
                resultList.add(resRec);
            }
        }
        return resultList;
    }

    //--- Обраховуємо інтегрований match-індекс:
    //    Jaccard, Norm Levenstein, Dice, Cosine, Soundex (JLDCS)
    public static Decimal getIntgratedMatchIndex(String name1, String name2, Boolean needNormalize) {
        if(String.isBlank(name1) || String.isBlank(name2)) return 0.000;
        String s1='';
        String s2='';
        if(needNormalize) {
            s1=StringNormalize.getClearName(name1, Consts.ToUpperCase.YES,
                                                        Consts.QuestionMarkRule.REMOVE_SIGN,
                                                        Consts.ClearCountryName.NO);
            s2=StringNormalize.getClearName(name2, Consts.ToUpperCase.YES,
                                                        Consts.QuestionMarkRule.REMOVE_SIGN,
                                                        Consts.ClearCountryName.NO);
        } else {
            s1 = name1;
            s2 = name2;
        }

        Decimal idxJaccard = ((SimilarityUtils.JaccardSimilarityByWords(s1, s2, false, false) +
                              SimilarityUtils.JaccardCharSimilarity(s1, s2) +
                              SimilarityUtils.JaccardSimilarity(s1, s2, 2))/3.0).setScale(3);
        Decimal idxDice = SimilarityUtils.DiceSimilarity(s1, s2, false, false);
        Decimal idxNormLev = (1.000 - (SimilarityUtils.getNormalizedLevenstein(s1, s2, false, false)));
        Decimal idxCosine = SimilarityUtils.CosineSimilarity(s1, s2, false, false);
        Decimal idxSoundex = SimilarityUtils.getFullSoundexSimilarity(s1, s2, false);

        Decimal idxFull = 0.2*(idxJaccard+idxDice+idxNormLev+idxCosine+idxSoundex).setScale(3);
        return idxFull;
    }
    
}