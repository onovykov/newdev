@IsTest
private class NotificationConstantsTest {

    /**
     * Тест: getInterpipeUkraineAccountId знаходить Account за назвою
     */
    @IsTest
    static void testGetInterpipeUkraineAccountId_AccountExists_ReturnsAccountId() {
        // Створюємо акаунт з потрібною назвою
        Account acc = new Account(Name = 'ІНТЕРПАЙП УКРАЇНА');
        insert acc;

        Test.startTest();
        Id resultId = NotificationConstants.getInterpipeUkraineAccountId();
        Test.stopTest();

        System.assertNotEquals(null, resultId, 'Id має бути повернуто');
        System.assertEquals(acc.Id, resultId, 'Має повернути Id створеного акаунту');
    }

    /**
     * Тест: getInterpipeUkraineAccountId повертає fallback якщо Account не знайдено
     */
    @IsTest
    static void testGetInterpipeUkraineAccountId_AccountNotFound_ReturnsFallback() {
        // Не створюємо жодного акаунту з назвою 'ІНТЕРПАЙП УКРАЇНА'

        Test.startTest();
        Id resultId = NotificationConstants.getInterpipeUkraineAccountId();
        Test.stopTest();

        System.assertNotEquals(null, resultId, 'Id має бути повернуто навіть без акаунту');
        System.assertEquals('0011n00002MXoKYAA1', resultId, 'Має повернути hardcoded fallback Id');
    }

    /**
     * Тест: getInterpipeUkraineAccountId з кількома акаунтами повертає перший
     */
    @IsTest
    static void testGetInterpipeUkraineAccountId_MultipleAccounts_ReturnsFirst() {
        // Створюємо кілька акаунтів з однаковою назвою
        List<Account> accounts = new List<Account>{
            new Account(Name = 'ІНТЕРПАЙП УКРАЇНА'),
            new Account(Name = 'ІНТЕРПАЙП УКРАЇНА')
        };
        insert accounts;

        Test.startTest();
        Id resultId = NotificationConstants.getInterpipeUkraineAccountId();
        Test.stopTest();

        System.assertNotEquals(null, resultId, 'Id має бути повернуто');
        // Має повернути один з двох (LIMIT 1 в SOQL)
        Boolean isOneOfThem = (resultId == accounts[0].Id || resultId == accounts[1].Id);
        System.assert(isOneOfThem, 'Має повернути Id одного з акаунтів');
    }

    /**
     * Тест: getInterpipeUkraineAccountId з іншою назвою акаунту повертає fallback
     */
    @IsTest
    static void testGetInterpipeUkraineAccountId_DifferentAccountName_ReturnsFallback() {
        // Створюємо акаунт з іншою назвою
        Account acc = new Account(Name = 'Інший акаунт');
        insert acc;

        Test.startTest();
        Id resultId = NotificationConstants.getInterpipeUkraineAccountId();
        Test.stopTest();

        System.assertNotEquals(null, resultId, 'Id має бути повернуто');
        System.assertEquals('0011n00002MXoKYAA1', resultId, 'Має повернути fallback Id');
        System.assertNotEquals(acc.Id, resultId, 'Не має повертати Id іншого акаунту');
    }

    /**
     * Тест: getInterpipeUkraineAccountId можна викликати кілька разів
     */
    @IsTest
    static void testGetInterpipeUkraineAccountId_MultipleCalls_Works() {
        Account acc = new Account(Name = 'ІНТЕРПАЙП УКРАЇНА');
        insert acc;

        Test.startTest();
        Id resultId1 = NotificationConstants.getInterpipeUkraineAccountId();
        Id resultId2 = NotificationConstants.getInterpipeUkraineAccountId();
        Id resultId3 = NotificationConstants.getInterpipeUkraineAccountId();
        Test.stopTest();

        System.assertEquals(resultId1, resultId2, 'Має повертати однаковий Id');
        System.assertEquals(resultId2, resultId3, 'Має повертати однаковий Id');
        System.assertEquals(acc.Id, resultId1, 'Має повернути Id створеного акаунту');
    }

    /**
     * Тест: getInterpipeUkraineAccountId перевірка типу повернутого значення
     */
    @IsTest
    static void testGetInterpipeUkraineAccountId_ReturnsValidId() {
        Test.startTest();
        Id resultId = NotificationConstants.getInterpipeUkraineAccountId();
        Test.stopTest();

        System.assertNotEquals(null, resultId, 'Має повернути не null Id');
        // Перевіряємо що це валідний 18-значний Id
        String idString = String.valueOf(resultId);
        System.assertEquals(18, idString.length(), 'Id має бути 18 символів');
    }

    /**
     * Тест: getInterpipeUkraineAccountId з частковим співпаданням назви не повертає акаунт
     */
    @IsTest
    static void testGetInterpipeUkraineAccountId_PartialMatch_ReturnsFallback() {
        // Створюємо акаунт з частково схожою назвою
        Account acc = new Account(Name = 'ІНТЕРПАЙП');
        insert acc;

        Test.startTest();
        Id resultId = NotificationConstants.getInterpipeUkraineAccountId();
        Test.stopTest();

        System.assertEquals('0011n00002MXoKYAA1', resultId, 'Часткове співпадання не має працювати');
        System.assertNotEquals(acc.Id, resultId, 'Не має повертати Id акаунту з частковою назвою');
    }

    /**
     * Тест: getInterpipeUkraineAccountId з точною назвою (case sensitive)
     */
    @IsTest
    static void testGetInterpipeUkraineAccountId_ExactMatch_Works() {
        Account acc = new Account(Name = 'ІНТЕРПАЙП УКРАЇНА');
        insert acc;

        Test.startTest();
        Id resultId = NotificationConstants.getInterpipeUkraineAccountId();
        Test.stopTest();

        System.assertEquals(acc.Id, resultId, 'Точна назва має працювати');
    }
}