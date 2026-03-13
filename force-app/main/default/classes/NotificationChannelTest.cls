@IsTest
private class NotificationChannelTest {

    // =====================================================
    // MOCK РЕАЛІЗАЦІЯ ДЛЯ ТЕСТУВАННЯ
    // =====================================================

    /**
     * Mock реалізація NotificationChannel для тестування.
     * Дозволяє контролювати результат і перевіряти що метод викликався з правильними параметрами.
     */
    public class MockNotificationChannel implements NotificationChannel {
        public Boolean shouldSucceed = true;
        public Integer sentCount = 0;
        public String customMessage = null;

        // Параметри останнього виклику для перевірки
        public NotificationTypes.NotificationPayload lastPayload;
        public NotificationTypes.RecipientBundle lastRecipients;
        public NotificationTypes.NotificationEventCfg lastCfg;
        public Integer callCount = 0;

        public NotificationTypes.ChannelResult send(
            NotificationTypes.NotificationPayload payload,
            NotificationTypes.RecipientBundle recipients,
            NotificationTypes.NotificationEventCfg cfg
        ) {
            // Зберігаємо параметри виклику
            this.lastPayload = payload;
            this.lastRecipients = recipients;
            this.lastCfg = cfg;
            this.callCount++;

            // Створюємо результат
            NotificationTypes.ChannelResult result = new NotificationTypes.ChannelResult();
            result.ok = shouldSucceed;
            result.sentCount = sentCount;
            result.message = customMessage != null ? customMessage : (shouldSucceed ? 'Success' : 'Failed');

            return result;
        }
    }

    /**
     * Mock реалізація яка завжди повертає успішний результат
     */
    public class SuccessChannel implements NotificationChannel {
        public NotificationTypes.ChannelResult send(
            NotificationTypes.NotificationPayload payload,
            NotificationTypes.RecipientBundle recipients,
            NotificationTypes.NotificationEventCfg cfg
        ) {
            NotificationTypes.ChannelResult result = new NotificationTypes.ChannelResult();
            result.ok = true;
            result.sentCount = recipients != null ? recipients.totalCount() : 0;
            result.message = 'Sent successfully';
            return result;
        }
    }

    /**
     * Mock реалізація яка завжди повертає помилку
     */
    public class FailureChannel implements NotificationChannel {
        public NotificationTypes.ChannelResult send(
            NotificationTypes.NotificationPayload payload,
            NotificationTypes.RecipientBundle recipients,
            NotificationTypes.NotificationEventCfg cfg
        ) {
            NotificationTypes.ChannelResult result = new NotificationTypes.ChannelResult();
            result.ok = false;
            result.sentCount = 0;
            result.message = 'Channel failed to send';
            return result;
        }
    }

    /**
     * Mock реалізація яка кидає exception
     */
    public class ExceptionChannel implements NotificationChannel {
        public NotificationTypes.ChannelResult send(
            NotificationTypes.NotificationPayload payload,
            NotificationTypes.RecipientBundle recipients,
            NotificationTypes.NotificationEventCfg cfg
        ) {
            throw new CustomChannelException('Channel encountered an error');
        }
    }

    public class CustomChannelException extends Exception {}

    // =====================================================
    // ТЕСТИ ДЛЯ MockNotificationChannel
    // =====================================================

    @IsTest
    static void testMockChannel_SuccessfulSend() {
        // Arrange
        MockNotificationChannel channel = new MockNotificationChannel();
        channel.shouldSucceed = true;
        channel.sentCount = 5;

        NotificationTypes.NotificationPayload payload = createTestPayload();
        NotificationTypes.RecipientBundle recipients = createTestRecipients();
        NotificationTypes.NotificationEventCfg cfg = createTestConfig();

        // Act
        Test.startTest();
        NotificationTypes.ChannelResult result = channel.send(payload, recipients, cfg);
        Test.stopTest();

        // Assert
        System.assertEquals(true, result.ok, 'Result should be successful');
        System.assertEquals(5, result.sentCount, 'Sent count should be 5');
        System.assertEquals('Success', result.message, 'Message should be Success');
        System.assertEquals(1, channel.callCount, 'Call count should be 1');
        System.assertEquals(payload, channel.lastPayload, 'Payload should be stored');
        System.assertEquals(recipients, channel.lastRecipients, 'Recipients should be stored');
        System.assertEquals(cfg, channel.lastCfg, 'Config should be stored');
    }

    @IsTest
    static void testMockChannel_FailedSend() {
        // Arrange
        MockNotificationChannel channel = new MockNotificationChannel();
        channel.shouldSucceed = false;
        channel.sentCount = 0;
        channel.customMessage = 'Custom error message';

        NotificationTypes.NotificationPayload payload = createTestPayload();
        NotificationTypes.RecipientBundle recipients = createTestRecipients();
        NotificationTypes.NotificationEventCfg cfg = createTestConfig();

        // Act
        Test.startTest();
        NotificationTypes.ChannelResult result = channel.send(payload, recipients, cfg);
        Test.stopTest();

        // Assert
        System.assertEquals(false, result.ok, 'Result should be failure');
        System.assertEquals(0, result.sentCount, 'Sent count should be 0');
        System.assertEquals('Custom error message', result.message, 'Message should be custom');
    }

    @IsTest
    static void testMockChannel_MultipleInvocations() {
        // Arrange
        MockNotificationChannel channel = new MockNotificationChannel();
        channel.shouldSucceed = true;
        channel.sentCount = 1;

        NotificationTypes.NotificationPayload payload = createTestPayload();
        NotificationTypes.RecipientBundle recipients = createTestRecipients();
        NotificationTypes.NotificationEventCfg cfg = createTestConfig();

        // Act
        Test.startTest();
        channel.send(payload, recipients, cfg);
        channel.send(payload, recipients, cfg);
        channel.send(payload, recipients, cfg);
        Test.stopTest();

        // Assert
        System.assertEquals(3, channel.callCount, 'Call count should be 3');
    }

    @IsTest
    static void testMockChannel_NullParameters() {
        // Arrange
        MockNotificationChannel channel = new MockNotificationChannel();
        channel.shouldSucceed = true;
        channel.sentCount = 0;

        // Act
        Test.startTest();
        NotificationTypes.ChannelResult result = channel.send(null, null, null);
        Test.stopTest();

        // Assert
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(true, result.ok, 'Result should handle null parameters');
        System.assertEquals(null, channel.lastPayload, 'Payload should be null');
        System.assertEquals(null, channel.lastRecipients, 'Recipients should be null');
        System.assertEquals(null, channel.lastCfg, 'Config should be null');
    }

    // =====================================================
    // ТЕСТИ ДЛЯ SuccessChannel
    // =====================================================

    @IsTest
    static void testSuccessChannel_WithRecipients() {
        // Arrange
        SuccessChannel channel = new SuccessChannel();
        NotificationTypes.NotificationPayload payload = createTestPayload();
        NotificationTypes.RecipientBundle recipients = createTestRecipients();
        recipients.userIds.add(UserInfo.getUserId());
        recipients.emails.add('test@example.com');
        NotificationTypes.NotificationEventCfg cfg = createTestConfig();

        // Act
        Test.startTest();
        NotificationTypes.ChannelResult result = channel.send(payload, recipients, cfg);
        Test.stopTest();

        // Assert
        System.assertEquals(true, result.ok, 'Result should be successful');
        System.assertEquals(2, result.sentCount, 'Sent count should match recipient count');
        System.assertEquals('Sent successfully', result.message, 'Message should indicate success');
    }

    @IsTest
    static void testSuccessChannel_WithoutRecipients() {
        // Arrange
        SuccessChannel channel = new SuccessChannel();
        NotificationTypes.NotificationPayload payload = createTestPayload();
        NotificationTypes.RecipientBundle recipients = new NotificationTypes.RecipientBundle();
        NotificationTypes.NotificationEventCfg cfg = createTestConfig();

        // Act
        Test.startTest();
        NotificationTypes.ChannelResult result = channel.send(payload, recipients, cfg);
        Test.stopTest();

        // Assert
        System.assertEquals(true, result.ok, 'Result should be successful');
        System.assertEquals(0, result.sentCount, 'Sent count should be 0');
    }

    @IsTest
    static void testSuccessChannel_NullRecipients() {
        // Arrange
        SuccessChannel channel = new SuccessChannel();
        NotificationTypes.NotificationPayload payload = createTestPayload();
        NotificationTypes.NotificationEventCfg cfg = createTestConfig();

        // Act
        Test.startTest();
        NotificationTypes.ChannelResult result = channel.send(payload, null, cfg);
        Test.stopTest();

        // Assert
        System.assertEquals(true, result.ok, 'Result should be successful');
        System.assertEquals(0, result.sentCount, 'Sent count should be 0 for null recipients');
    }

    // =====================================================
    // ТЕСТИ ДЛЯ FailureChannel
    // =====================================================

    @IsTest
    static void testFailureChannel_AlwaysFails() {
        // Arrange
        FailureChannel channel = new FailureChannel();
        NotificationTypes.NotificationPayload payload = createTestPayload();
        NotificationTypes.RecipientBundle recipients = createTestRecipients();
        NotificationTypes.NotificationEventCfg cfg = createTestConfig();

        // Act
        Test.startTest();
        NotificationTypes.ChannelResult result = channel.send(payload, recipients, cfg);
        Test.stopTest();

        // Assert
        System.assertEquals(false, result.ok, 'Result should be failure');
        System.assertEquals(0, result.sentCount, 'Sent count should be 0');
        System.assertEquals('Channel failed to send', result.message, 'Error message should be present');
    }

    @IsTest
    static void testFailureChannel_WithNullParameters() {
        // Arrange
        FailureChannel channel = new FailureChannel();

        // Act
        Test.startTest();
        NotificationTypes.ChannelResult result = channel.send(null, null, null);
        Test.stopTest();

        // Assert
        System.assertEquals(false, result.ok, 'Result should be failure even with null params');
        System.assertEquals(0, result.sentCount, 'Sent count should be 0');
    }

    // =====================================================
    // ТЕСТИ ДЛЯ ExceptionChannel
    // =====================================================

    @IsTest
    static void testExceptionChannel_ThrowsException() {
        // Arrange
        ExceptionChannel channel = new ExceptionChannel();
        NotificationTypes.NotificationPayload payload = createTestPayload();
        NotificationTypes.RecipientBundle recipients = createTestRecipients();
        NotificationTypes.NotificationEventCfg cfg = createTestConfig();

        // Act & Assert
        Test.startTest();
        try {
            channel.send(payload, recipients, cfg);
            System.assert(false, 'Should have thrown exception');
        } catch (CustomChannelException e) {
            System.assertEquals('Channel encountered an error', e.getMessage(), 'Exception message should match');
        } catch (Exception e) {
            System.assert(false, 'Should have thrown CustomChannelException, got: ' + e.getTypeName());
        }
        Test.stopTest();
    }

    // =====================================================
    // ТЕСТИ ДЛЯ ChannelResult
    // =====================================================

    @IsTest
    static void testChannelResult_SuccessState() {
        // Arrange & Act
        NotificationTypes.ChannelResult result = new NotificationTypes.ChannelResult();
        result.ok = true;
        result.sentCount = 10;
        result.message = 'All emails sent';

        // Assert
        System.assertEquals(true, result.ok, 'Result should be successful');
        System.assertEquals(10, result.sentCount, 'Sent count should be 10');
        System.assertEquals('All emails sent', result.message, 'Message should be set');
    }

    @IsTest
    static void testChannelResult_FailureState() {
        // Arrange & Act
        NotificationTypes.ChannelResult result = new NotificationTypes.ChannelResult();
        result.ok = false;
        result.sentCount = 0;
        result.message = 'Failed to send';

        // Assert
        System.assertEquals(false, result.ok, 'Result should be failure');
        System.assertEquals(0, result.sentCount, 'Sent count should be 0');
        System.assertNotEquals(null, result.message, 'Error message should be present');
    }

    @IsTest
    static void testChannelResult_PartialSuccess() {
        // Arrange & Act
        NotificationTypes.ChannelResult result = new NotificationTypes.ChannelResult();
        result.ok = false;
        result.sentCount = 5;
        result.message = 'Sent 5 out of 10';

        // Assert
        System.assertEquals(false, result.ok, 'Result should indicate failure');
        System.assertEquals(5, result.sentCount, 'Should track partial success count');
        System.assert(result.message.contains('5'), 'Message should mention sent count');
    }

    @IsTest
    static void testChannelResult_DefaultValues() {
        // Arrange & Act
        NotificationTypes.ChannelResult result = new NotificationTypes.ChannelResult();

        // Assert - перевіряємо default значення
        System.assertEquals(null, result.ok, 'ok should be null by default');
        System.assertEquals(null, result.sentCount, 'sentCount should be null by default');
        System.assertEquals(null, result.message, 'message should be null by default');
    }

    // =====================================================
    // INTEGRATION ТЕСТИ
    // =====================================================

    @IsTest
    static void testChannelInterface_PolymorphicBehavior() {
        // Arrange - створюємо список різних реалізацій
        List<NotificationChannel> channels = new List<NotificationChannel>{
            new MockNotificationChannel(),
            new SuccessChannel(),
            new FailureChannel()
        };

        NotificationTypes.NotificationPayload payload = createTestPayload();
        NotificationTypes.RecipientBundle recipients = createTestRecipients();
        NotificationTypes.NotificationEventCfg cfg = createTestConfig();

        // Act & Assert
        Test.startTest();
        for (NotificationChannel channel : channels) {
            NotificationTypes.ChannelResult result = channel.send(payload, recipients, cfg);
            System.assertNotEquals(null, result, 'Each channel should return result');
            System.assertNotEquals(null, result.ok, 'Result should have ok status');
        }
        Test.stopTest();
    }

    @IsTest
    static void testChannelInterface_ConsistentReturnType() {
        // Arrange
        List<NotificationChannel> channels = new List<NotificationChannel>{
            new SuccessChannel(),
            new FailureChannel()
        };

        // Act
        Test.startTest();
        for (NotificationChannel channel : channels) {
            NotificationTypes.ChannelResult result = channel.send(null, null, null);

            // Assert - кожен канал повинен повертати валідний об'єкт
            System.assertNotEquals(null, result, 'Result should never be null');
            System.assert(
                result.ok != null || result.sentCount != null || result.message != null,
                'Result should have at least one field populated'
            );
        }
        Test.stopTest();
    }

    @IsTest
    static void testMultipleChannels_SequentialExecution() {
        // Arrange
        MockNotificationChannel channel1 = new MockNotificationChannel();
        channel1.sentCount = 5;

        MockNotificationChannel channel2 = new MockNotificationChannel();
        channel2.sentCount = 3;

        NotificationTypes.NotificationPayload payload = createTestPayload();
        NotificationTypes.RecipientBundle recipients = createTestRecipients();
        NotificationTypes.NotificationEventCfg cfg = createTestConfig();

        // Act
        Test.startTest();
        NotificationTypes.ChannelResult result1 = channel1.send(payload, recipients, cfg);
        NotificationTypes.ChannelResult result2 = channel2.send(payload, recipients, cfg);
        Test.stopTest();

        // Assert
        System.assertEquals(5, result1.sentCount, 'First channel sent 5');
        System.assertEquals(3, result2.sentCount, 'Second channel sent 3');
        System.assertEquals(1, channel1.callCount, 'Channel 1 called once');
        System.assertEquals(1, channel2.callCount, 'Channel 2 called once');
    }

    // =====================================================
    // HELPER METHODS
    // =====================================================

    private static NotificationTypes.NotificationPayload createTestPayload() {
        NotificationTypes.NotificationPayload payload = new NotificationTypes.NotificationPayload();
        payload.eventKey = 'TEST_EVENT';
        payload.vars = new Map<String, Object>{
            'testVar' => 'testValue'
        };
        return payload;
    }

    private static NotificationTypes.RecipientBundle createTestRecipients() {
        NotificationTypes.RecipientBundle recipients = new NotificationTypes.RecipientBundle();
        return recipients;
    }

    private static NotificationTypes.NotificationEventCfg createTestConfig() {
        NotificationTypes.NotificationEventCfg cfg = new NotificationTypes.NotificationEventCfg();
        cfg.eventKey = 'TEST_EVENT';
        cfg.channel = 'Email';
        cfg.templateApiName = 'Test_Template';
        return cfg;
    }
}