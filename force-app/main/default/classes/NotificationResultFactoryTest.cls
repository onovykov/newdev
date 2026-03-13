@IsTest
private class NotificationResultFactoryTest {

    @IsTest
    static void testNone() {
        // Act
        NotificationTypes.ChannelResult result = NotificationResultFactory.none();

        // Assert
        System.assertNotEquals(null, result, 'Результат не має бути null');
        System.assertEquals(true, result.ok, 'Для none() ok має бути true за логікою класу');
        System.assertEquals(0, result.sentCount, 'Кількість відправлених має бути 0');
    }

    @IsTest
    static void testFromResults_Success() {
        // Створюємо імітацію успішного результату через JSON
        // Поле "success": true
        String successJson = '{"success":true}';
        Messaging.SendEmailResult successRes = (Messaging.SendEmailResult)JSON.deserialize(successJson, Messaging.SendEmailResult.class);

        List<Messaging.SendEmailResult> results = new List<Messaging.SendEmailResult>{ successRes, successRes };

        // Act
        NotificationTypes.ChannelResult result = NotificationResultFactory.fromResults(results);

        // Assert
        System.assertEquals(true, result.ok);
        System.assertEquals(2, result.sentCount, 'Має бути пораховано 2 успішних відправки');
    }



    @IsTest
    static void testFromResults_NullOrEmpty() {
        // Тест на Null
        NotificationTypes.ChannelResult resultNull = NotificationResultFactory.fromResults(null);
        System.assertEquals(true, resultNull.ok);
        System.assertEquals(0, resultNull.sentCount);

        // Тест на порожній список
        NotificationTypes.ChannelResult resultEmpty = NotificationResultFactory.fromResults(new List<Messaging.SendEmailResult>());
        System.assertEquals(0, resultEmpty.sentCount);
    }
}