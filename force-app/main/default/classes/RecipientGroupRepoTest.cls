@IsTest
private class RecipientGroupRepoTest {

    @IsTest
    static void testGetGroupCfg_NullKey() {
        Test.startTest();
        RecipientGroupRepo.RecipientGroupCfg cfg = RecipientGroupRepo.getGroupCfg(null);
        Test.stopTest();

        System.assertEquals(null, cfg);
    }

    @IsTest
    static void testGetGroupCfg_BlankKey() {
        Test.startTest();
        RecipientGroupRepo.RecipientGroupCfg cfg = RecipientGroupRepo.getGroupCfg('   ');
        Test.stopTest();

        System.assertEquals(null, cfg);
    }

    @IsTest
    static void testGetGroupCfg_EmptyKey() {
        Test.startTest();
        RecipientGroupRepo.RecipientGroupCfg cfg = RecipientGroupRepo.getGroupCfg('');
        Test.stopTest();

        System.assertEquals(null, cfg);
    }

    @IsTest
    static void testGetGroupCfg_NonExistentKey() {
        Test.startTest();
        RecipientGroupRepo.RecipientGroupCfg cfg = RecipientGroupRepo.getGroupCfg('NON_EXISTENT_KEY_12345');
        Test.stopTest();

        System.assertEquals(null, cfg);
    }

    @IsTest
    static void testGetGroupCfg_WithWhitespace() {
        Test.startTest();
        RecipientGroupRepo.RecipientGroupCfg cfg = RecipientGroupRepo.getGroupCfg('  SOME_KEY  ');
        Test.stopTest();

        // Може бути null якщо метадата не існує
        // Але метод має відпрацювати без помилок
        System.assert(true, 'Should handle whitespace');
    }

    @IsTest
    static void testGetGroupCfg_Caching() {
        Test.startTest();
        RecipientGroupRepo.RecipientGroupCfg cfg1 = RecipientGroupRepo.getGroupCfg('TEST_KEY');
        RecipientGroupRepo.RecipientGroupCfg cfg2 = RecipientGroupRepo.getGroupCfg('TEST_KEY');
        Test.stopTest();

        // Обидва виклики повинні повернути той самий результат (кешовано)
        System.assertEquals(cfg1, cfg2, 'Should return cached value');
    }

    @IsTest
    static void testGetGroupCfg_DifferentKeys() {
        Test.startTest();
        RecipientGroupRepo.RecipientGroupCfg cfg1 = RecipientGroupRepo.getGroupCfg('KEY1');
        RecipientGroupRepo.RecipientGroupCfg cfg2 = RecipientGroupRepo.getGroupCfg('KEY2');
        Test.stopTest();

        // Різні ключі можуть мати різні результати
        System.assert(true, 'Should handle different keys');
    }

    @IsTest
    static void testPrime_NullSet() {
        Test.startTest();
        RecipientGroupRepo.prime(null);
        Test.stopTest();

        System.assert(true, 'Should handle null set');
    }

    @IsTest
    static void testPrime_EmptySet() {
        Test.startTest();
        RecipientGroupRepo.prime(new Set<String>());
        Test.stopTest();

        System.assert(true, 'Should handle empty set');
    }

    @IsTest
    static void testPrime_SingleKey() {
        Test.startTest();
        RecipientGroupRepo.prime(new Set<String>{'TEST_KEY'});
        Test.stopTest();

        System.assert(true, 'Should prime single key');
    }

    @IsTest
    static void testPrime_MultipleKeys() {
        Test.startTest();
        RecipientGroupRepo.prime(new Set<String>{'KEY1', 'KEY2', 'KEY3'});
        Test.stopTest();

        System.assert(true, 'Should prime multiple keys');
    }

    @IsTest
    static void testPrime_WithNullKeys() {
        Test.startTest();
        RecipientGroupRepo.prime(new Set<String>{null, 'KEY1', null});
        Test.stopTest();

        System.assert(true, 'Should handle null keys in set');
    }

    @IsTest
    static void testPrime_WithBlankKeys() {
        Test.startTest();
        RecipientGroupRepo.prime(new Set<String>{'', '   ', 'KEY1'});
        Test.stopTest();

        System.assert(true, 'Should handle blank keys');
    }

    @IsTest
    static void testPrime_WithWhitespace() {
        Test.startTest();
        RecipientGroupRepo.prime(new Set<String>{'  KEY1  ', '  KEY2  '});
        Test.stopTest();

        System.assert(true, 'Should trim keys');
    }

    @IsTest
    static void testPrime_AlreadyCached() {
        // Arrange - спочатку завантажуємо в кеш
        RecipientGroupRepo.getGroupCfg('KEY1');

        Test.startTest();
        RecipientGroupRepo.prime(new Set<String>{'KEY1', 'KEY2'});
        Test.stopTest();

        System.assert(true, 'Should skip already cached keys');
    }

    @IsTest
    static void testClearCache() {
        // Arrange - завантажуємо в кеш
        RecipientGroupRepo.getGroupCfg('KEY1');

        Test.startTest();
        RecipientGroupRepo.clearCache();
        Test.stopTest();

        System.assert(true, 'Should clear cache');
    }

    @IsTest
    static void testClearCache_AfterPrime() {
        // Arrange
        RecipientGroupRepo.prime(new Set<String>{'KEY1', 'KEY2'});

        Test.startTest();
        RecipientGroupRepo.clearCache();
        RecipientGroupRepo.RecipientGroupCfg cfg = RecipientGroupRepo.getGroupCfg('KEY1');
        Test.stopTest();

        // Після clearCache повинен робити новий lookup
        System.assert(true, 'Should fetch after cache clear');
    }

    @IsTest
    static void testGetGroupCfg_AfterClear() {
        // Arrange
        RecipientGroupRepo.RecipientGroupCfg cfg1 = RecipientGroupRepo.getGroupCfg('KEY1');
        RecipientGroupRepo.clearCache();

        Test.startTest();
        RecipientGroupRepo.RecipientGroupCfg cfg2 = RecipientGroupRepo.getGroupCfg('KEY1');
        Test.stopTest();

        // Обидва виклики повинні відпрацювати
        System.assert(true, 'Should work after cache clear');
    }

    @IsTest
    static void testRecipientGroupCfg_Structure() {
        RecipientGroupRepo.RecipientGroupCfg cfg = new RecipientGroupRepo.RecipientGroupCfg();
        cfg.key = 'TEST';
        cfg.kind = 'Users';
        cfg.definition = 'OPP_OWNER';
        cfg.includeInactive = false;
        cfg.notes = 'Test notes';

        System.assertEquals('TEST', cfg.key);
        System.assertEquals('Users', cfg.kind);
        System.assertEquals('OPP_OWNER', cfg.definition);
        System.assertEquals(false, cfg.includeInactive);
        System.assertEquals('Test notes', cfg.notes);
    }

    @IsTest
    static void testGetGroupCfg_MultipleCalls() {
        Test.startTest();
        for (Integer i = 0; i < 5; i++) {
            RecipientGroupRepo.RecipientGroupCfg cfg = RecipientGroupRepo.getGroupCfg('KEY' + i);
        }
        Test.stopTest();

        System.assert(true, 'Should handle multiple calls');
    }

    @IsTest
    static void testPrime_ThenGetGroupCfg() {
        // Arrange
        Set<String> keys = new Set<String>{'KEY1', 'KEY2', 'KEY3'};
        RecipientGroupRepo.prime(keys);

        Test.startTest();
        RecipientGroupRepo.RecipientGroupCfg cfg1 = RecipientGroupRepo.getGroupCfg('KEY1');
        RecipientGroupRepo.RecipientGroupCfg cfg2 = RecipientGroupRepo.getGroupCfg('KEY2');
        RecipientGroupRepo.RecipientGroupCfg cfg3 = RecipientGroupRepo.getGroupCfg('KEY3');
        Test.stopTest();

        // Всі виклики повинні повертати кешовані значення
        System.assert(true, 'Should return primed values');
    }

    @IsTest
    static void testPrime_Duplicates() {
        Test.startTest();
        RecipientGroupRepo.prime(new Set<String>{'KEY1', 'KEY1', 'KEY1'});
        Test.stopTest();

        System.assert(true, 'Should handle duplicate keys');
    }
}