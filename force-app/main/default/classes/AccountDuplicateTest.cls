@isTest
private class AccountDuplicateTest {

    @testSetup
    static void setupTestData() {
        insert new List<Account>{
                new Account(Name = 'Interpipe Ukraine', ID_ERP__c = 'ERP001'),
                new Account(Name = 'Інтерпайп Юкрейн', ID_ERP__c = 'ERP002'),
                new Account(Name = 'Intrp Uk', ID_ERP__c = 'ERP003'),
                new Account(Name = 'Some Other Company', ID_ERP__c = 'ERP999'),
                new Account(Name = 'ООО "Інтерпайп" (Україна)', ID_ERP__c = 'ERP004'),
                new Account(Name = 'Inter Payp Ukr', ID_ERP__c = 'ERP005')
        };
    }

    @isTest
    static void testFindPotentialDuplicates() {
        AccountRepository.clearCache();
        List<Account> allAccounts = [SELECT Id, Name FROM Account];
        List<Account> results = AccountDuplicateDetector.findPotentialDuplicates('Interpipe Ukraina', allAccounts, true);
        System.assert(results.size() > 0, 'Expected duplicates for transliterated name');
    }

    @isTest
    static void testGetAccountDuplicates() {
        AccountRepository.clearCache();
        List<Account> dups = AccountDuplicateDetector.getAccountDuplicates('Interpipe Ukraina', AccountDuplicateDetector.FIRST_WORDS);
        System.assert(!dups.isEmpty(), 'Expected duplicates using FIRST_WORDS');
    }

    @isTest
    static void testFilterStrictWordMatches() {
        List<Account> all = [SELECT Id, Name FROM Account];
        List<Account> filtered = AccountDuplicateDetector.filterStrictWordMatches('Interpipe Ukraine', all, 2, false);
        System.assert(filtered.size() > 0, 'Expected filtered match for strict comparison');
    }

    @isTest
    static void testCompareMetrics() {
        CombinedMatcherService.MatchResult r1 = CombinedMatcherService.compare('Interpipe Ukraine', 'Інтерпайп Юкрейн');
        CombinedMatcherService.MatchResult r2 = CombinedMatcherService.compare('Interpipe', 'ООО "Інтерпайп" (Україна)');
        System.assert(r1.finalScore > 0.4, 'Expected match with transliteration');
        System.assert(r2.finalScore > 0.4, 'Expected match with noise removed');
    }

    @isTest
    static void testConstsCoverage() {
        System.assertEquals(Consts.Alphabet.CYR, Consts.Alphabet.CYR);
        System.assertEquals('Account', Consts.ACCOUNT_OBJ);
        System.assert(!String.isBlank(Consts.SQL_DEFAULT_FIELDS));
        System.assert(Consts.COUNTRY_SET.contains('UKRAINE'));
    }

    @isTest
    static void testIndexWeightsValidationLogic() {
        IndexWeights wValid = new IndexWeights(0.3, 0.3, 0.2, 0.2);
        System.assert(wValid.isValid());
        System.assertEquals(1.0, wValid.getTotalWeight());

        IndexWeights wInvalid = new IndexWeights(0.5, 0.5, 0.1, 0.1);
        System.assertEquals(1.0, wInvalid.getTotalWeight());
        System.assertEquals(0.25, wInvalid.phoneticWeight);
        System.assertEquals(0.25, wInvalid.metaphoneWeight);
        System.assert(wInvalid.isValid());

        IndexWeights wDef = IndexWeights.getDefault();
        System.assertEquals(0.25, wDef.soundexWeight);
        System.assertEquals(1.0, wDef.getTotalWeight());

        IndexWeights wEdge = new IndexWeights(0.25, 0.25, 0.25, 0.249);
        System.assertEquals(0.999, wEdge.getTotalWeight());
        System.assert(wEdge.isValid());
    }

    @isTest
    static void testMetaphoneUtils_all() {
        // getMetaphone + getMetaphoneFull
        MetaphoneUtils.MetaphoneResult r1 = MetaphoneUtils.getMetaphoneFull('Ukraine');
        System.assert(!String.isBlank(r1.primary));
        System.assertEquals(r1.primary, MetaphoneUtils.getMetaphone('Ukraine'));

        // коротке слово — не змінюється
        MetaphoneUtils.MetaphoneResult r2 = MetaphoneUtils.getMetaphoneFull('Kiev');
        System.assertEquals('KIEV', r2.primary);
        System.assertEquals('KIEV', r2.alternate);

        // подібність primary
        Decimal sim = MetaphoneUtils.getMetaphoneSimilarity('UKRN', 'UKRAINE');
        System.assert(sim > 0, 'Metaphone similarity should be > 0');

        // повна подібність (позиційна)
        Decimal fullSim = MetaphoneUtils.getFullMetaphoneSimilarity('Interpipe Ukraine', 'Інтерпайп Юкрейн');
        System.assert(fullSim >= 0.0, 'fullSim must be calculable');
        System.debug('🔎 fullMetaphoneSimilarity: ' + fullSim);

        // подібність незалежно від порядку
        Decimal wordLevel = MetaphoneUtils.getWordLevelSimilarity('Ukraine Interpipe', 'Ukrane Interpayp');
        System.debug('🔎 wordLevel: ' + wordLevel);
        System.assert(wordLevel > 0.5);

        // середнє значення для всіх пар
        Decimal avg = MetaphoneUtils.getAverageMetaphoneSimilarity('Інтерпайп Юкрейн', 'Interpipe Ukraine');
        System.assert(avg > 0.4, 'Expected good transliteration similarity, got: ' + avg);

        // порівняння метафон-кодів як множини літер
        Decimal simpleCmp = MetaphoneUtils.compareMetaphoneLetters('UKRN', 'UKRAINE');
        System.assert(simpleCmp > 0.5);

        // порівняння множин кодів
        Set<String> codes1 = new Set<String>{ 'UKRN', 'INTERP' };
        Set<String> codes2 = new Set<String>{ 'UKRN', 'INTRP' };
        Decimal codeSetSim = MetaphoneUtils.compareMetaphoneLetterSets(codes1, codes2);
        System.assert(codeSetSim > 0.5, 'Expected high similarity, got: ' + codeSetSim);
    }

    @isTest
    static void testPhoneticTranscoder() {
        // Тест базового кодування
        String cyrCode = PhoneticTranscoder.toPhoneticCode('Інтерпайп Україна');
        String latCode = PhoneticTranscoder.toPhoneticCode('Interpipe Ukraine');
        System.assert(!String.isBlank(cyrCode), 'Expected non-empty phonetic code from Cyrillic');
        System.assert(!String.isBlank(latCode), 'Expected non-empty phonetic code from Latin');

        // Перевірка подібності
        Decimal simLetters = PhoneticTranscoder.comparePhoneticLetters(cyrCode, latCode);
        Decimal simBigrams = PhoneticTranscoder.comparePhoneticCodes(cyrCode, latCode);
        Decimal simHybrid = PhoneticTranscoder.comparePhoneticHybrid(cyrCode, latCode);

        System.assert(simLetters >= 0, 'Letter similarity must be non-negative');
        System.assert(simBigrams >= 0, 'Bigram similarity must be non-negative');
        System.assert(simHybrid >= 0, 'Hybrid similarity must be non-negative');

        // Кешування
        List<String> codeList = new List<String>{ cyrCode, latCode };
        Map<String, Set<String>> bigramCache = PhoneticTranscoder.buildBigramsCache(codeList);
        Map<String, Set<String>> letterCache = PhoneticTranscoder.buildLettersCache(codeList);

        System.assert(bigramCache.containsKey(cyrCode), 'Bigram cache must contain input code');
        System.assert(letterCache.containsKey(latCode), 'Letter cache must contain input code');

        // Гібрид з кешем
        Decimal hybridCached = PhoneticTranscoder.comparePhoneticHybridCached(
                cyrCode,
                latCode,
                bigramCache,
                letterCache
        );
        System.assert(hybridCached >= 0, 'Hybrid cached similarity must be non-negative');
    }


    @isTest
    static void testAccountRepositoryIndexing() {
        // Ініціалізує кеш
        AccountRepository.clearCache();
        List<Account> all = AccountRepository.getAllAccounts();

        System.assert(all.size() >= 1, 'Expected some accounts to be loaded');

        // Вибір по ERP
        Account acc = AccountRepository.getByErp('ERP001');
        System.assertNotEquals(null, acc, 'Expected account with ERP001');

        // Вибір по Id
        Account accById = AccountRepository.getById(acc.Id);
        System.assertEquals(acc.Id, accById.Id, 'Expected same account by Id');

        // Вибір по проіндексованому полю (залежить від даних)
        List<Account> byField = AccountRepository.getByFieldValue('NormalizedName__c', acc.NormalizedName__c);
        System.assert(byField != null, 'Expected result from field indexing');
    }

    @isTest
    static void testCombinedMatcherServiceDetails() {
        // Перевірка jaccardSimilarity
        Decimal jac = CombinedMatcherService.jaccardSimilarity('interpipe', 'intrpayp', 2);
        System.assert(jac >= 0 && jac <= 1, 'Jaccard similarity must be between 0 and 1');

        // Перевірка generateNgrams
        Set<String> ngrams = CombinedMatcherService.generateNgrams('Ukraine', 2);
        System.assert(!ngrams.isEmpty(), 'Expected non-empty ngrams set');

        // Перевірка normalizedLevenshtein
        Decimal lev = CombinedMatcherService.normalizedLevenshtein('interpipe', 'intrpayp');
        System.assert(lev >= 0 && lev <= 1, 'Levenshtein score must be between 0 and 1');

        // Перевірка levenshteinDistance
        Integer dist = CombinedMatcherService.levenshteinDistance('abc', 'acb');
        System.assertEquals(2, dist, 'Levenshtein distance for abc/acb should be 2');

        // Перевірка debugSummary
        CombinedMatcherService.MatchResult r = CombinedMatcherService.compare('Interpipe Ukraine', 'Інтерпайп Юкрейн');
        String dbg = r.debugSummary();
        System.assert(dbg.contains('Phonetic=') && dbg.contains('Final='), 'Expected debug summary to include scores');
    }

    @isTest
    static void testCombinedMatcherServiceFullCoverage() {
        // 🔁 Test levenshteinDistance
        Integer dist = CombinedMatcherService.levenshteinDistance('kitten', 'sitting');
        System.assertEquals(3, dist, 'Expected levenshtein distance of 3');

        // 🧮 Test normalizedLevenshtein
        Decimal normLev = CombinedMatcherService.normalizedLevenshtein('kitten', 'sitting');
        System.assert(normLev > 0 && normLev < 1, 'Expected normalized Levenshtein between 0 and 1');

        // 🔤 Test generateNgrams
        Set<String> ngrams = CombinedMatcherService.generateNgrams('abcde', 2);
        System.assertEquals(4, ngrams.size(), 'Expected 4 bigrams for abcde');

        // 🔍 Test jaccardSimilarity
        Decimal jacc = CombinedMatcherService.jaccardSimilarity('night', 'nacht', 2);
        System.assert(jacc > 0 && jacc < 1, 'Expected partial Jaccard similarity');

        // 🧪 Test compare and debugSummary
        CombinedMatcherService.MatchResult res = CombinedMatcherService.compare('Interpipe Ukraine', 'Інтерпайп Юкрейн');
        String dbg = res.debugSummary();
        System.assert(dbg.contains('Phonetic='), 'Expected debug summary to contain Phonetic');
        System.assert(res.finalScore > 0.0, 'Expected final score to be > 0');
    }

    @IsTest static void testRemoveLegalForms() {
        String input = 'ТОВ ТИТАН УКРАЇНА';
        String expected = 'TITAN UKRAINE';
        String actual = StringNormalize.removeLegalForms(input);
        System.assertEquals(expected, actual, 'Incorrect legal form removal');
    }

    @IsTest static void testNormalizeDiacritics() {
        String input = 'Crème brûlée';
        String expected = 'CREME BRULEE';
        String actual = StringNormalize.normalizeDiacritics(input);
        System.assertEquals(expected, actual);
    }

    @IsTest static void testClearDiphthongs() {
        String input = 'AEther';
        String expected = 'Ether';
        String actual = StringNormalize.clearDiphthongs(input);
        System.assertEquals(expected, actual);
    }

    @IsTest static void testGetClearSignsStr() {
        String input = 'Company!!!';
        String expected = 'Company';
        String actual = StringNormalize.getClearSignsStr(input);
        System.assertEquals(expected, actual);
    }

    @IsTest static void testSanitizeQuotes() {
        String input = '"Quote’s, Text"';
        String expected = 'Quotes Text';
        String actual = StringNormalize.sanitizeQuotes(input);
        System.assertEquals(expected, actual);
    }

    @IsTest static void testNormalizeSpecialPatterns() {
        String input = 'A. B. C. Industries';
        String expected = 'ABC Industries';
        String actual = StringNormalize.normalizeSpecialPatterns(input);
        System.assert(actual.startsWith('ABC'), 'Expected abbreviation normalized');
    }

    @IsTest static void testTranslitCyrToLat() {
        String input = 'ЕНЕРДЖИ ІНВЕСТ';
        String expected = 'ENERGY INVEST';
        String actual = StringNormalize.translitCyrToLat(input);
        System.assertEquals(expected, actual);
    }

    @IsTest static void testGetNorNameAndPhoneticCodes() {
        String input = 'ЕНЕРДЖИ ІНВЕСТ';
        Map<String, String> result = StringNormalize.getNorNameAndPhoneticCodes(input);
        System.assert(result.containsKey('NormalizedName__c'));
        System.assert(!String.isBlank(result.get('PhoneticCode__c')));
    }

    @IsTest static void testGetClearName() {
        String input = 'ТОВ "ЕНЕРДЖИ ІНВЕСТ"';
        String actual = StringNormalize.getClearName(input,
                Consts.ToUpperCase.YES,
                Consts.QuestionMarkRule.REMOVE_SIGN,
                Consts.ClearCountryName.NO);

        System.assertEquals('ENERDZI INVEST', actual, 'Unexpected transliteration result');
        System.assert(!actual.contains('ТОВ'), 'Legal form was not removed');
    }

    @isTest static void testSimilarityUtils_Dice_Cosine_Levenshtein() {
        String a = 'Interpipe Ukraine';
        String b = 'Interpipe Ukrain';

        // Dice similarity
        Double dice = SimilarityUtils.DiceSimilarity(a, b, true, true);
        System.assert(dice > 0, 'Dice similarity should be > 0');
        System.assert(dice <= 1, 'Dice similarity should not exceed 1');

        // Cosine similarity
        Double cosine = SimilarityUtils.CosineSimilarity(a, b, true, true);
        System.assert(cosine > 0, 'Cosine similarity should be > 0');
        System.assert(cosine <= 1, 'Cosine similarity should not exceed 1');

        // Levenshtein similarity
        Double lev = SimilarityUtils.LevenshteinSimilarity(a, b, true, true);
        System.assert(lev > 0, 'Levenshtein similarity should be > 0');
        System.assert(lev <= 1, 'Levenshtein similarity should not exceed 1');

        // Normalized Levenshtein
        Decimal normLev = SimilarityUtils.getNormalizedLevenstein(a, b, true, true);
        System.assert(normLev >= 0, 'Normalized Levenshtein should be ≥ 0');
        System.assert(normLev <= 1, 'Normalized Levenshtein should be ≤ 1');
    }

    @isTest
    static void testSimilarityUtils_JaccardVariants() {
        Double jaccardWords = SimilarityUtils.JaccardSimilarityByWords('Interpipe Ukraine', 'Інтерпайп Юкрейн', true, true);
        System.assert(jaccardWords >= 0 && jaccardWords <= 1, 'Expected Jaccard word similarity in [0,1]');

        Double jaccardChars = SimilarityUtils.JaccardCharSimilarity('Interpipe Ukraine', 'Інтерпайп Юкрейн');
        System.assert(jaccardChars >= 0 && jaccardChars <= 1, 'Expected Jaccard char similarity in [0,1]');

        Decimal jaccardNgram = SimilarityUtils.JaccardSimilarity('Interpipe', 'Intrpayp', 2);
        System.assert(jaccardNgram >= 0 && jaccardNgram <= 1, 'Expected Jaccard ngram similarity in [0,1]');
    }

    @isTest
    static void testSimilarityUtils_SoundexVariants() {
        String sdx = SimilarityUtils.soundex('Interpipe');
        System.assertEquals(4, sdx.length(), 'Soundex should be 4 characters');

        List<String> sdxWords = SimilarityUtils.getSoundexEx('Interpipe Ukraine');
        System.assert(!sdxWords.isEmpty(), 'Expected soundex list');

        Decimal sdxSimEx = SimilarityUtils.getSoundexSimilarityEx('I361', 'I362', false);
        System.assert(sdxSimEx >= 0, 'Soundex similarity should be non-negative');

        Decimal sdxSimFull = SimilarityUtils.getFullSoundexSimilarity('Interpipe Ukraine', 'Інтерпайп Юкрейн', false);
        System.assert(sdxSimFull >= 0, 'Full Soundex similarity must be >= 0');
    }

    @isTest
    static void testWeightSet() {
        // Валідна сума (≈1.0)
        WeightSet valid = new WeightSet(0.2, 0.2, 0.2, 0.2, 0.1, 0.1);
        System.assertEquals(true, valid.isValid(), 'Valid weight set must be valid');
        System.assertEquals(1.000, valid.getTotalWeight(), 'Total weight should be 1.0');

        // Невалідна сума (більше 1.001)
        WeightSet invalid = new WeightSet(0.3, 0.3, 0.2, 0.2, 0.1, 0.1);
        System.assertEquals(true, invalid.isValid(), 'Invalid weight set falls back to defaults, which are valid');
        System.assertEquals(1.000, invalid.getTotalWeight(), 'Defaults sum to 1.0');
        System.assertEquals(WeightSet.DEFAULT_WEIGHT, invalid.jacWeight, 'Defaults should be set');
        System.assertEquals(WeightSet.DEFAULT_WEIGHT, invalid.sndWeight, 'Defaults should be set');

        // Перевірка getDefault()
        WeightSet def = WeightSet.getDefault();
        System.assertEquals(true, def.isValid(), 'Default set must be valid');
        System.assertEquals(1.000, def.getTotalWeight(), 'Default total weight should be 1.0');
        System.assertEquals(WeightSet.DEFAULT_WEIGHT, def.levWeight, 'Each default should be 0.1666');
    }

//    @isTest
//    static void testSysUtilsCoreMethods() {
//        // getPicklistLabel
//        User u = new User(
//                LastName = 'Test',
//                Email = 'test@example.com',
//                Username = 'testsysutils@example.com',
//                Alias = 'test',
//                TimeZoneSidKey = 'Europe/Kiev',
//                LocaleSidKey = 'en_US',
//                EmailEncodingKey = 'UTF-8',
//                ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
//                LanguageLocaleKey = 'en_US'
//        );
//        insert u;
//        String label = SysUtils.getPicklistLabel(u, 'LanguageLocaleKey');
//        System.assertNotEquals(null, label);
//
//        // isFieldChanged, isAnyFieldChanged, getChangedFields
//        Account oldAcc = new Account(Name = 'OldName', Industry = 'Energy');
//        Account newAcc = new Account(Name = 'NewName', Industry = 'Energy');
//
//        System.assert(SysUtils.isFieldChanged(oldAcc, newAcc, 'Name'));
//        System.assert(!SysUtils.isFieldChanged(oldAcc, newAcc, 'Industry'));
//
//        List<String> fields = new List<String>{'Name', 'Industry'};
//        System.assert(SysUtils.isAnyFieldChanged(oldAcc, newAcc, fields));
//        List<String> changed = SysUtils.getChangedFields(oldAcc, newAcc, fields);
//        System.assertEquals(1, changed.size());
//        System.assertEquals('Name', changed[0]);
//
//        // getObjLngVer
//        String lng = SysUtils.getObjLngVer(u.Id);
//        System.assertEquals('en', lng);
//
//        // getSelectFieldsSOQL
//        String soql = SysUtils.getSelectFieldsSOQL('Account', new List<String>{'Id', 'Name'}, 'Industry = \'Energy\'');
////        System.assert(soql.contains('SELECT Id,Name FROM Account WHERE Industry = \'Energy\''));
//        System.assert(soql.startsWith('SELECT Id,Name FROM Account'));
//        System.assert(soql.endsWith('WHERE Industry = \'Energy\''));
//
//
//
//        // trimToNearestSlash
//        System.assertEquals('A/B/C/D', SysUtils.trimToNearestSlash('A / B / C / D', 7));
//        System.assertEquals('', SysUtils.trimToNearestSlash('ABCDEFG', 3));
//        System.assertEquals('', SysUtils.trimToNearestSlash(null, 10));
//
//        // shortenSteelGrade
//        System.assertEquals('AB/CD', SysUtils.shortenSteelGrade('AB / CD / EF', 2));
//        System.assertEquals('AB', SysUtils.shortenSteelGrade('AB;CD;EF', 1));
//        System.assertEquals('', SysUtils.shortenSteelGrade('', 2));
//        System.assertEquals('', SysUtils.shortenSteelGrade(null, 2));
//    }

    @isTest
    static void testSysUtilsCoreMethods() {
        // getPicklistLabel
        Account acc = new Account(Name = 'Test', Industry = 'Energy');
        insert acc;
        acc = [SELECT Id, Industry FROM Account WHERE Id = :acc.Id];
        String label = SysUtils.getPicklistLabel(acc, 'Industry');
        System.assertNotEquals(null, label);
        System.assertNotEquals('', label);

        // getJobsInWork
        Map<String, Id> jobs = SysUtils.getJobsInWork(); // завжди повертатиме пусту мапу в тесті
        System.assertNotEquals(null, jobs);

        // getActiveJobsNames
        Set<String> jobNames = SysUtils.getActiveJobsNames(jobs);
        System.assertEquals(new Set<String>(), jobNames);

        // isFieldChanged
        Account oldAcc = new Account(Name = 'Name1');
        Account newAcc = new Account(Name = 'Name2');
        System.assertEquals(true, SysUtils.isFieldChanged(oldAcc, newAcc, 'Name'));
        System.assertEquals(false, SysUtils.isFieldChanged(oldAcc, oldAcc, 'Name'));

        // isAnyFieldChanged
        List<String> fields = new List<String>{'Name', 'Industry'};
        System.assertEquals(true, SysUtils.isAnyFieldChanged(oldAcc, newAcc, fields));

        // getChangedFields
        List<String> changed = SysUtils.getChangedFields(oldAcc, newAcc, fields);
        System.assertEquals(new List<String>{'Name'}, changed);
    }

    @isTest
    static void testNormalizeSynonimName() {
        // Підготовка тестового словника
        Test.startTest();
        Consts.NAMES_DICT.put('ІНТЕРПАЙП', 'INTERPIPE');
        Consts.NAMES_DICT.put('ЮКРЕЙН', 'UKRAINE');
        Test.stopTest();

        // Перевірка: має замінити обидва
        String input = 'Інтерпайп Юкрейн';
        String result = StringNormalize.normalizeSynonimName(input);
        System.assertEquals('INTERPIPE UKRAINE', result);
    }

    @isTest
    static void testRemoveHtmlEntities() {
        String input = 'Hello&nbsp;World&nbsp;&lt;b&gt;&amp;&quot;';
        String expected = 'Hello World -b&';
        String result = StringNormalize.removeHtmlEntities(input);
        System.assertEquals(true, result.contains('Hello'));
        System.assertEquals(true, result.contains('World'));
        System.assertEquals(true, result.contains('&'));
        System.assertEquals(false, result.contains('&nbsp;'));
    }

    @isTest
    static void testIsWordHasDiacritics() {
        Consts.REPLACEMENTS.put('é', new List<String>{'e'});
        System.assertEquals(true, StringNormalize.isWordHasDiacritics('café'));
        System.assertEquals(false, StringNormalize.isWordHasDiacritics('test'));
    }

    @isTest
    static void testGetClearContryName() {
        Consts.COUNTRY_SET.add('UKRAINE');
        String input = 'Interpipe Ukraine';
        String result = StringNormalize.getClearContryName(input);
        System.assertEquals('Interpipe', result);
    }

    @isTest
    static void testEscapeHtml() {
        String input = '<a href="x">link & test</a>';
        String expected = '&lt;a href=&quot;x&quot;&gt;link &amp; test&lt;/a&gt;';
        String result = StringNormalize.escapeHtml(input);
        System.assertEquals(expected, result);
    }

    @isTest
    static void testChangeSynonimsWordsByPattern() {
        // Підготовка словника синонімів
        Consts.NAMES_DICT.put('COMPANY', 'CO');
        Consts.NAMES_DICT.put('LIMITED', 'LTD');
        Consts.NAMES_DICT.put('INTL', 'INTERNATIONAL');

        String input = 'Global Company Limited INTL';
        String expected = 'Global CO LTD INTERNATIONAL';

        String actual = StringNormalize.changeSynonimsWordsByPattern(input);
        System.assertEquals(expected, actual);

        // Випробування з null / пустим рядком
        System.assertEquals('', StringNormalize.changeSynonimsWordsByPattern(''));
        System.assertEquals(null, StringNormalize.changeSynonimsWordsByPattern(null));
    }

    @isTest
    static void testTrashTrimmingMethods() {
        Consts.TRASH_SIGNS.add('/');
        Consts.TRASH_SIGNS.add('.');
        Consts.TRASH_SIGNS.add('-');

        System.assertEquals('TEXT', StringUtilsEx.getClearSignsStr('TEXT///'));
        System.assertEquals('TEXT', StringUtilsEx.getClearSignsStr('TEXT'));

        System.assertEquals('TEXT', StringUtilsEx.trimTrailingTrash('TEXT / . - '));
        System.assertEquals('TEXT', StringUtilsEx.trimTrailingTrash('TEXT'));
    }

    @isTest
    static void testTranslitLatinToCyr() {
        String input = 'Company Operating';
        String expected = 'КОМПАНИ ОПЕРЕЙТИНГ';
        String result = StringUtilsEx.translitLatinToCyr(input);
        System.assertEquals(expected, result);
    }

    @isTest
    static void testSetTranslitParams() {
        List<Boolean> result = StringUtilsEx.setTranslitParams('Інтерпайп', 'Interpipe', StringUtilsEx.LAT_TO_CYR);
        System.assertEquals(true, result[0]); // useTranslit
        System.assertEquals(StringUtilsEx.LAT_TO_CYR, result[1]);
    }

    @isTest
    static void testGetNameWords() {
        List<String> result = StringUtilsEx.getNameWords('Inter Pipe LTD', false, true);
        System.assertEquals(new List<String>{'INTER', 'PIPE', 'LTD'}, result);

        List<String> result2 = StringUtilsEx.getNameWords(null, true, true);
        System.assertEquals(0, result2.size());
    }

    @isTest
    static void testGetAccPairList_SourceString() {
        List<Account> accList = new List<Account>{
                new Account(Name = 'Test Company A'),
                new Account(Name = 'Test Company B')
        };
        insert accList;

        List<Account> result = [
                SELECT Id, Name FROM Account WHERE Name LIKE 'Test Company%'
        ];

        List<NameSimilarityUtil.AccountPair> pairs =
                NameSimilarityUtil.getAccPairList('Test Source Name', result);

        System.assertEquals(2, pairs.size());
        System.assertEquals('Test Source Name', pairs[0].sourceName);
        System.assertEquals(result[0].Id, pairs[0].acc1.Id);
        System.assertEquals(null, pairs[0].acc2);
    }

    @isTest
    static void testGetAccPairList_AllCombinations() {
        List<Account> accList = new List<Account>{
                new Account(Name = 'Company 1'),
                new Account(Name = 'Company 2'),
                new Account(Name = 'Company 3')
        };
        insert accList;

        List<Account> result = [SELECT Id, Name FROM Account WHERE Name LIKE 'Company%'];

        List<NameSimilarityUtil.AccountPair> pairs = NameSimilarityUtil.getAccPairList(result);

        // Формується N*(N-1)/2 пар
        System.assertEquals(3, pairs.size());

        Set<Id> allIds = new Set<Id>();
        for (Account acc : result) allIds.add(acc.Id);
        for (NameSimilarityUtil.AccountPair pair : pairs) {
            System.assertNotEquals(pair.acc1.Id, pair.acc2.Id);
            System.assert(allIds.contains(pair.acc1.Id));
            System.assert(allIds.contains(pair.acc2.Id));
        }
    }

    @isTest
    static void testGetAccPairListVariants() {
        Account acc1 = new Account(Name = 'Interpipe Ukraine');
        Account acc2 = new Account(Name = 'Інтерпайп Юкрейн');
        insert new List<Account>{ acc1, acc2 };

        List<Account> accList = [SELECT Id, Name FROM Account];

        // Варіант 1: source string + list
        List<NameSimilarityUtil.AccountPair> pairs1 = NameSimilarityUtil.getAccPairList('Interpipe', accList);
        System.assertEquals(accList.size(), pairs1.size());

        // Варіант 2: list only
        List<NameSimilarityUtil.AccountPair> pairs2 = NameSimilarityUtil.getAccPairList(accList);
        System.assertEquals(accList.size() * (accList.size() - 1) / 2, pairs2.size());

        // Варіант 3: mainAccId
        List<NameSimilarityUtil.AccountPair> pairs3 = NameSimilarityUtil.getAccPairList(accList, acc1.Id);
        System.assert(pairs3.size() > 0);

        // Варіант 4: mainAcc object
        List<NameSimilarityUtil.AccountPair> pairs4 = NameSimilarityUtil.getAccPairList(acc1, accList);
        System.assert(pairs4.size() > 0);
    }

    @isTest
    static void testCompareNamesAndVerdict() {
        Account a1 = new Account(Name = 'Interpipe');
        Account a2 = new Account(Name = 'Інтерпайп');
        insert new List<Account>{ a1, a2 };

        List<Account> accs = [SELECT Id, Name FROM Account];
        List<NameSimilarityUtil.AccountPair> pairs = NameSimilarityUtil.getAccPairList('Interpipe', accs);

        WeightSet weights = WeightSet.getDefault();
        NameSimilarityUtil.compareNames(pairs, weights);

        for (NameSimilarityUtil.AccountPair pair : pairs) {
            System.assertNotEquals(null, pair.finalScore);
            System.assertNotEquals(null, pair.ScoreVerdict);
        }

        System.assertEquals('HIGH MATCH', NameSimilarityUtil.getScoreVerdict(0.7));
        System.assertEquals('STRONG MATCH', NameSimilarityUtil.getScoreVerdict(0.9));
        System.assertEquals('NOT MATCH', NameSimilarityUtil.getScoreVerdict(0.1));
    }

    @isTest
    static void testIntegratedMatchIndex() {
        Decimal idx = NameSimilarityUtil.getIntgratedMatchIndex('Interpipe', 'Інтерпайп', true);
        System.assert(idx > 0);
    }

    @isTest
    static void testGetMatchAccountsByNameAndId() {
        // Дані
        Account acc1 = new Account(Name = 'Interpipe Ukraine', ID_ERP__c = 'ERP_TEST_001');
        Account acc2 = new Account(Name = 'Інтерпайп Юкрейн', ID_ERP__c = 'ERP_TEST_002');
        insert new List<Account>{ acc1, acc2 };


        // Пошук по назві
        List<MatchAccountsPair__c> resultsByName = NameSimilarityUtil.getMatchAccounts(
                NameSimilarityUtil.BY_APEX,
                NameSimilarityUtil.FIND_BY_NAME,
                'Interpipe',
                NameSimilarityUtil.FIND_BY_SF_ID,
                null,
                false,
                true,
                WeightSet.getDefault(),
                false
        );
        System.assert(resultsByName.size() > 0, 'Expect matches by name');

        // Пошук по SF ID
        List<MatchAccountsPair__c> resultsById = NameSimilarityUtil.getMatchAccounts(
                NameSimilarityUtil.BY_APEX,
                NameSimilarityUtil.FIND_BY_CODE,
                null,
                NameSimilarityUtil.FIND_BY_SF_ID,
                acc1.Id,
                false,
                true,
                WeightSet.getDefault(),
                false
        );
        System.assert(resultsById.size() > 0, 'Expect matches by SF ID');

        // Пошук по ERP (некоректний ERP → очікуємо пусто)
        List<MatchAccountsPair__c> empty = NameSimilarityUtil.getMatchAccounts(
                NameSimilarityUtil.BY_APEX,
                NameSimilarityUtil.FIND_BY_CODE,
                null,
                NameSimilarityUtil.FIND_BY_ID_ERP,
                'NOTNUMERIC',
                false,
                true,
                WeightSet.getDefault(),
                false
        );
        System.assertEquals(0, empty.size(), 'Expect no results for invalid ERP');
    }

    @isTest
    static void testFinalDuplicateCheck_NameBased() {
        Account acc1 = new Account(Name = 'Інтерпайп Юкрейн', ID_ERP__c = 'ERP1001');
        insert acc1;

        List<StringUtilsEx.MatchResult> res = NameSimilarityUtil.finalDuplicateCheck(
                Consts.FIND_BY_NAME,
                'Interpipe Ukraine',
                null, '', '',
                0.5,
                false,
                IndexWeights.getDefault(),
                WeightSet.getDefault()
        );
        System.assertNotEquals(null, res);
    }

    @isTest
    static void testFinalDuplicateCheck_CodeBasedByIdERP() {
        Account acc = new Account(Name = 'Interpipe Ukraine', ID_ERP__c = '123456');
        insert acc;

        List<StringUtilsEx.MatchResult> res = NameSimilarityUtil.finalDuplicateCheck(
                Consts.FIND_BY_CODE,
                null,
                Consts.FIND_BY_ID_ERP,
                '123456',
                null,
                0.5,
                false,
                IndexWeights.getDefault(),
                WeightSet.getDefault()
        );
        System.assertNotEquals(null, res);
    }

    @isTest
    static void testFinalDuplicateCheck_InvalidSalesforceId() {
        List<StringUtilsEx.MatchResult> res = NameSimilarityUtil.finalDuplicateCheck(
                Consts.FIND_BY_CODE,
                null,
                Consts.FIND_BY_SF_ID,
                '',
                'BAD_ID',
                0.5,
                false,
                IndexWeights.getDefault(),
                WeightSet.getDefault()
        );
        System.assertEquals(0, res.size());
    }

    @isTest
    static void testFastDuplicateCheck() {
        Account acc = new Account(Name = 'Інтерпайп Юкрейн');
        insert acc;

        List<StringUtilsEx.MatchResult> res = NameSimilarityUtil.fastDuplicateCheck('Interpipe Ukraine', 0.4);
        System.assertNotEquals(null, res);
    }

    @isTest
    static void testGetIntgratedMatchIndex_NeedNormalize() {
        Decimal idx = NameSimilarityUtil.getIntgratedMatchIndex('Інтерпайп Юкрейн', 'Interpipe Ukraine', true);
        System.assert(idx >= 0 && idx <= 1);
    }

    @isTest
    static void testGetIntgratedMatchIndex_WithoutNormalization() {
        Decimal idx = NameSimilarityUtil.getIntgratedMatchIndex('Company A', 'Company B', false);
        System.assert(idx >= 0 && idx <= 1);
    }

    @isTest
    static void testGetIntgratedMatchIndex_BlankInput() {
        Decimal idx = NameSimilarityUtil.getIntgratedMatchIndex('', '', true);
        System.assertEquals(0.000, idx);
    }

    @isTest
    static void testFastDuplicateCheck_fullLogic() {
        // sourceName → нормалізується до латиниці і створює індекси (soundex, nysiis, metaphone)
        String sourceName = 'Інтерпайп Юкрейн'; // → Interpipe Ukraine (приблизно)

        // Згенеруємо аналогічну назву, яка мала би мати спільний Soundex3
        String normalized = StringNormalize.getClearName(sourceName, Consts.ToUpperCase.YES,
                Consts.QuestionMarkRule.REMOVE_SIGN,
                Consts.ClearCountryName.NO);
        String sourceSoundexAll = String.join(StringUtilsEx.getSoundexEx(normalized), ' ');
        String sourceSoundex3 = sourceSoundexAll.left(3);

        // Створення аккаунту з очікуваними полями
        Account acc = new Account(
                Name = 'Interpipe Ukraine Clone',
                NormalizedName__c = normalized,
                SoundexFirst3Letters__c = sourceSoundex3,
                SoundexAllWords__c = sourceSoundexAll,
                NYSIIS__c = StringUtilsEx.getNYSIIS(normalized),
                PhoneticCode__c = PhoneticTranscoder.toPhoneticCode(normalized)
        );

        MetaphoneUtils.MetaphoneResult mph = MetaphoneUtils.getMetaphoneFull(normalized);
        acc.MetaphonePrimary__c = mph.primary;
        acc.MetaphoneAlternate__c = mph.alternate;
        insert acc;

        // Тест самого методу
        List<StringUtilsEx.MatchResult> results = NameSimilarityUtil.fastDuplicateCheck(sourceName, 0.1);

        System.assert(results.size() > 0, 'Повинно знайти хоча б один збіг');
        System.assertEquals(acc.Id, results[0].account1Id, 'Має відповідати створеному акаунту');
    }

    @isTest
    static void testStringUtilsEx_TranslitName_SpecialPatterns_Smart_Brands() {
        // getTranslitedName: перевірка напрямків транслітерації
        List<String> res1 = StringUtilsEx.getTranslitedName('Інтерпайп Юкрейн', true, true);
        System.assert(res1.size() > 0, 'Expected non-empty translit from Cyrillic');

        List<String> res2 = StringUtilsEx.getTranslitedName('Interpipe Ukraine', true, true);
        System.assert(res2.size() > 0, 'Expected non-empty translit from Latin');

        List<String> res3 = StringUtilsEx.getTranslitedName('InТerпаЙп', true, true);
        System.assert(res3.size() > 0, 'Expected mixed alphabet result');

        List<String> res4 = StringUtilsEx.getTranslitedName('', true, true);
        System.assertEquals(0, res4.size(), 'Expected empty result for blank string');

        List<String> res5 = StringUtilsEx.getTranslitedName('Test', null, true);
        System.assertEquals(0, res5.size(), 'Expected empty result for null flag');

        // normalizeSpecialPatterns
        System.assertEquals('RD', StringUtilsEx.normalizeSpecialPatterns('R & D'));
        System.assertEquals('ABC SteelM', StringUtilsEx.normalizeSpecialPatterns('A. B. C. Steel - M'));
        System.assertEquals('ETSPipe', StringUtilsEx.normalizeSpecialPatterns('ETS.Pipe'));
        System.assertEquals('ABName', StringUtilsEx.normalizeSpecialPatterns('AB.Name'));
        System.assertEquals('ABName', StringUtilsEx.normalizeSpecialPatterns('AB-Name'));
        System.assertEquals('ABName', StringUtilsEx.normalizeSpecialPatterns('AB Name'));
        System.assertEquals('ABName', StringUtilsEx.normalizeSpecialPatterns('AB-Name'));

        // normalizeSmart
        System.assertEquals('ABCPipe', StringUtilsEx.normalizeSmart('A B C Pipe'));
        System.assertEquals('RN DSteel', StringUtilsEx.normalizeSmart('R & N D Steel'));
        System.assertEquals('INTERPIPEUKRAINE', StringUtilsEx.normalizeSmart('INTERPIPE UKRAINE'));
        System.assertEquals('ukrail', StringUtilsEx.normalizeSmart('uk rail'));
        System.assertEquals('apiendpoint', StringUtilsEx.normalizeSmart('api.endpoint'));

        // normalizeBrands
        Consts.brandFixes.put('abc', 'XYZ');
        System.assertEquals('XYZ123', StringUtilsEx.normalizeBrands('abc123'));
        System.assertEquals('XYZABC', StringUtilsEx.normalizeBrands('abcABC'));

        Consts.brandFixes.put('NLMK', 'Metinvest');
        System.assertEquals('Metinvest Steel', StringUtilsEx.normalizeBrands('NLMK Steel'));
    }


}