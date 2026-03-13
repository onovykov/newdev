@IsTest
private class RecipientChunkerTest {

    @IsTest
    static void testSplit_UserIdsChunks() {
        // Arrange: Створюємо 5 ID користувачів
        NotificationTypes.RecipientBundle bundle = new NotificationTypes.RecipientBundle();
        for (Integer i = 0; i < 5; i++) {
            // Генеруємо фейковий User ID
            bundle.userIds.add(Id.valueOf('00500000000000' + i));
        }

        // Act: Розбиваємо по 2 отримувачі на чанк
        Test.startTest();
        List<NotificationTypes.RecipientBundle> results = RecipientChunker.split(bundle, 2);
        Test.stopTest();

        // Assert: 5 осіб по 2 на чанк = 3 чанки (2 + 2 + 1)
        System.assertEquals(3, results.size(), 'Має бути 3 чанки');
        System.assertEquals(2, results[0].userIds.size());
        System.assertEquals(2, results[1].userIds.size());
        System.assertEquals(1, results[2].userIds.size());
    }

    @IsTest
    static void testSplit_EmailChunksAndCleaning() {
        // Arrange: Створюємо імейли, включаючи пробіли та пусті рядки
        NotificationTypes.RecipientBundle bundle = new NotificationTypes.RecipientBundle();
        bundle.emails.add('test1@example.com');
        bundle.emails.add('  test2@example.com  '); // має бути trimmed
        bundle.emails.add(''); // має бути ігнороване
        bundle.emails.add(null); // має бути ігнороване

        // Act: Чанк великий, все має влізти в один
        Test.startTest();
        List<NotificationTypes.RecipientBundle> results = RecipientChunker.split(bundle, 10);
        Test.stopTest();

        // Assert
        System.assertEquals(1, results.size());
        System.assertEquals(2, results[0].emails.size(), 'Тільки 2 валідних імейли мали залишитися');
        System.assert(results[0].emails.contains('test2@example.com'), 'Email має бути очищений від пробілів');
    }

    @IsTest
    static void testSplit_ContactIdsExactMatch() {
        // Arrange: Рівно 4 контакти
        NotificationTypes.RecipientBundle bundle = new NotificationTypes.RecipientBundle();
        for (Integer i = 0; i < 4; i++) {
            bundle.contactIds.add(Id.valueOf('00300000000000' + i));
        }

        // Act: Розбиваємо по 2 (кратне число)
        Test.startTest();
        List<NotificationTypes.RecipientBundle> results = RecipientChunker.split(bundle, 2);
        Test.stopTest();

        // Assert: Має бути рівно 2 чанки
        System.assertEquals(2, results.size());
        System.assertEquals(2, results[0].contactIds.size());
        System.assertEquals(2, results[1].contactIds.size());
    }

    @IsTest
    static void testSplit_DefaultChunkSize() {
        // Arrange
        NotificationTypes.RecipientBundle bundle = new NotificationTypes.RecipientBundle();
        bundle.userIds.add(Id.valueOf('005000000000001'));

        // Act: Передаємо null або 0 як розмір чанка
        Test.startTest();
        List<NotificationTypes.RecipientBundle> resultsNull = RecipientChunker.split(bundle, null);
        List<NotificationTypes.RecipientBundle> resultsZero = RecipientChunker.split(bundle, 0);
        Test.stopTest();

        // Assert: Має використати дефолтний розмір 100, тобто 1 запис влізе в 1 чанк
        System.assertEquals(1, resultsNull.size());
        System.assertEquals(1, resultsZero.size());
    }

    @IsTest
    static void testSplit_NullInput() {
        // Act
        Test.startTest();
        List<NotificationTypes.RecipientBundle> results = RecipientChunker.split(null, 100);
        Test.stopTest();

        // Assert
        System.assertNotEquals(null, results);
        System.assertEquals(0, results.size());
    }

    @IsTest
    static void testSplit_MixedTypes() {
        // Перевіряємо, що метод коректно обробляє бандл, де є і юзери, і контакти
        NotificationTypes.RecipientBundle bundle = new NotificationTypes.RecipientBundle();
        bundle.userIds.add(Id.valueOf('005000000000001'));
        bundle.contactIds.add(Id.valueOf('003000000000001'));

        // Act
        Test.startTest();
        List<NotificationTypes.RecipientBundle> results = RecipientChunker.split(bundle, 1);
        Test.stopTest();

        // Assert: Кожен тип додає свої чанки в загальний список
        // 1 юзер (1 чанк) + 1 контакт (1 чанк) = 2 чанки
        System.assertEquals(2, results.size());
    }
}