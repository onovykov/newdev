@IsTest
private class EmailRawChannelTest {

    @IsTest
    static void send_ValidData_ShouldAttemptSend() {
        // 1. Arrange - Підготовка даних згідно з вашими конструкторами
        EmailRawChannel channel = new EmailRawChannel();

        // Створюємо контекстний об'єкт (наприклад, Account), якщо Builders його потребують
        Account acc = new Account(Name = 'Test Account');

        // Заповнюємо vars, оскільки Builders зазвичай шукають дані там
        Map<String, Object> testVars = new Map<String, Object>{
                'subject' => 'Test Subject',
                'body' => 'Test Body Content'
        };

        NotificationTypes.NotificationPayload payload = new NotificationTypes.NotificationPayload(
                'TEST_EVENT',
                acc,
                testVars
        );

        NotificationTypes.RecipientBundle recipient = new NotificationTypes.RecipientBundle();
        recipient.emails.add('work@example.com');
        recipient.emails.add('personal@example.com');

        NotificationTypes.NotificationEventCfg cfg = new NotificationTypes.NotificationEventCfg();
        cfg.eventKey = 'TEST_EVENT';

        // 2. Act
        Test.startTest();
        NotificationTypes.ChannelResult result = channel.send(payload, recipient, cfg);
        Integer emailInvocations = Limits.getEmailInvocations();
        Test.stopTest();

        // 3. Assert
        System.assertNotEquals(null, result, 'Результат не повинен бути null');
        System.assertEquals(1, emailInvocations, 'Має бути зафіксовано 1 виклик Messaging.sendEmail');
    }

    @IsTest
    static void send_EmptyEmails_ShouldReturnNone() {
        // Arrange
        EmailRawChannel channel = new EmailRawChannel();
        NotificationTypes.NotificationPayload payload = new NotificationTypes.NotificationPayload();
        NotificationTypes.RecipientBundle emptyRecipient = new NotificationTypes.RecipientBundle();
        // recipient.emails залишаємо порожнім

        // Act
        Test.startTest();
        NotificationTypes.ChannelResult result = channel.send(payload, emptyRecipient, null);
        Test.stopTest();

        // Assert
        System.assertEquals(0, Limits.getEmailInvocations(), 'Відправка не повинна відбуватися');
        // Перевіряємо, що фабрика відпрацювала (зазвичай це ok = false або sentCount = 0)
        System.assertNotEquals(null, result);
    }

    @IsTest
    static void send_IntegrationWithBuilders_VerifyNoCrash() {
        // Цей тест перевіряє, що навіть з мінімальними даними білдери не кидають NullPointerException
        EmailRawChannel channel = new EmailRawChannel();

        NotificationTypes.NotificationPayload payload = new NotificationTypes.NotificationPayload(
                'MINIMAL_EVENT', null, null
        );

        NotificationTypes.RecipientBundle recipient = new NotificationTypes.RecipientBundle();
        recipient.emails.add('simple@test.com');

        Test.startTest();
        try {
            NotificationTypes.ChannelResult result = channel.send(payload, recipient, null);
            System.assert(true, 'Метод завершився без критичних помилок');
        } catch (Exception e) {
            System.assert(false, 'Метод не повинен кидати виключення: ' + e.getMessage());
        }
        Test.stopTest();
    }
}