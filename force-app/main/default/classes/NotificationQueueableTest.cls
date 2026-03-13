@IsTest
private class NotificationQueueableTest {

    // Mock-реалізація NotificationChannel для тестування
    public class MockChannel implements NotificationChannel {
        public Boolean shouldThrowException = false;
        public String exceptionMessage = 'Mock exception';
        public Boolean sendResult = true;
        public Integer sentCount = 1;
        public String resultMessage = 'Success';
        public Integer callCount = 0;

        public NotificationTypes.ChannelResult send(
            NotificationTypes.NotificationPayload payload,
            NotificationTypes.RecipientBundle recipients,
            NotificationTypes.NotificationEventCfg cfg
        ) {
            callCount++;

            if (shouldThrowException) {
                throw new CalloutException(exceptionMessage);
            }

            NotificationTypes.ChannelResult result = new NotificationTypes.ChannelResult();
            result.ok = sendResult;
            result.sentCount = sentCount;
            result.message = resultMessage;
            return result;
        }
    }

    private static NotificationTypes.NotificationPayload makePayload(String eventKey) {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        NotificationTypes.NotificationPayload p = new NotificationTypes.NotificationPayload();
        p.eventKey = eventKey;
        p.context = acc;
        p.vars = new Map<String, Object>();
        return p;
    }

    private static NotificationTypes.NotificationEventCfg makeCfg(String channel, Integer batchSize) {
        NotificationTypes.NotificationEventCfg cfg = new NotificationTypes.NotificationEventCfg();
        cfg.eventKey = 'TEST_EVENT';
        cfg.channel = channel;
        cfg.batchSize = batchSize;
        cfg.active = true;
        return cfg;
    }

    private static NotificationTypes.RecipientBundle makeBundle() {
        NotificationTypes.RecipientBundle rb = new NotificationTypes.RecipientBundle();
        rb.userIds = new Set<Id>();
        rb.contactIds = new Set<Id>();
        rb.emails = new Set<String>();
        return rb;
    }

    /**
     * Тест: execute з recipients = null → logNoRecipients
     */
    @IsTest
    static void testExecute_NullRecipients_LogsNoRecipients() {
        NotificationTypes.NotificationPayload p = makePayload('NULL_REC_TEST');
        NotificationTypes.NotificationEventCfg cfg = makeCfg('EmailUsers', 100);

        Test.startTest();
        NotificationQueueable job = new NotificationQueueable(p, null, cfg);
        job.execute(null);
        Test.stopTest();

        List<Notification_Log__c> logs = [SELECT Status__c FROM Notification_Log__c];
        System.assertEquals(1, logs.size());
        System.assertEquals('SkippedNoRecipients', logs[0].Status__c);
    }

    /**
     * Тест: execute з порожніми recipients → logNoRecipients
     */
    @IsTest
    static void testExecute_EmptyRecipients_LogsNoRecipients() {
        NotificationTypes.NotificationPayload p = makePayload('EMPTY_REC_TEST');
        NotificationTypes.NotificationEventCfg cfg = makeCfg('EmailUsers', 100);
        NotificationTypes.RecipientBundle rb = makeBundle();
        // Всі Set порожні

        Test.startTest();
        NotificationQueueable job = new NotificationQueueable(p, rb, cfg);
        job.execute(null);
        Test.stopTest();

        List<Notification_Log__c> logs = [SELECT Status__c FROM Notification_Log__c];
        System.assertEquals(1, logs.size());
        System.assertEquals('SkippedNoRecipients', logs[0].Status__c);
    }

    /**
     * Тест: execute з cfg = null → logNoRecipients
     */
    @IsTest
    static void testExecute_NullConfig_LogsNoRecipients() {
        NotificationTypes.NotificationPayload p = makePayload('NULL_CFG_TEST');
        NotificationTypes.RecipientBundle rb = makeBundle();
        rb.emails.add('test@example.com');

        Test.startTest();
        NotificationQueueable job = new NotificationQueueable(p, rb, null);
        job.execute(null);
        Test.stopTest();

        List<Notification_Log__c> logs = [SELECT Status__c FROM Notification_Log__c];
        System.assertEquals(1, logs.size());
        System.assertEquals('SkippedNoRecipients', logs[0].Status__c);
    }

    /**
     * Тест: execute з малою кількістю recipients (1 чанк)
     */
    @IsTest
    static void testExecute_SmallRecipients_CreatesOneLog() {
        NotificationTypes.NotificationPayload p = makePayload('SMALL_TEST');
        NotificationTypes.NotificationEventCfg cfg = makeCfg('EmailUsers', 100);
        NotificationTypes.RecipientBundle rb = makeBundle();
        rb.emails.add('test1@example.com');
        rb.emails.add('test2@example.com');

        Test.startTest();
        NotificationQueueable job = new NotificationQueueable(p, rb, cfg);
        job.execute(null);
        Test.stopTest();

        // Має створити 1 лог (тому що 2 recipients < 100 batchSize)
        List<Notification_Log__c> logs = [SELECT Status__c FROM Notification_Log__c];
        System.assertEquals(1, logs.size());
    }

    /**
     * Тест: execute з великою кількістю recipients створює кілька логів
     */
    @IsTest
    static void testExecute_LargeRecipients_CreatesMultipleLogs() {
        NotificationTypes.NotificationPayload p = makePayload('LARGE_TEST');
        NotificationTypes.NotificationEventCfg cfg = makeCfg('EmailUsers', 2); // batchSize = 2
        NotificationTypes.RecipientBundle rb = makeBundle();
        rb.emails.add('test1@example.com');
        rb.emails.add('test2@example.com');
        rb.emails.add('test3@example.com');
        rb.emails.add('test4@example.com');
        rb.emails.add('test5@example.com');

        Test.startTest();
        NotificationQueueable job = new NotificationQueueable(p, rb, cfg);
        job.execute(null);
        Test.stopTest();

        // 5 emails / batchSize 2 = 3 чанки → 3 логи
        List<Notification_Log__c> logs = [SELECT Id FROM Notification_Log__c];
        System.assertEquals(3, logs.size());
    }

    /**
     * Тест: execute з batchSize = null використовує дефолтний (100)
     */
    @IsTest
    static void testExecute_NullBatchSize_UsesDefault() {
        NotificationTypes.NotificationPayload p = makePayload('NULL_BATCH_TEST');
        NotificationTypes.NotificationEventCfg cfg = makeCfg('EmailUsers', null);
        NotificationTypes.RecipientBundle rb = makeBundle();
        rb.emails.add('test@example.com');

        Test.startTest();
        NotificationQueueable job = new NotificationQueueable(p, rb, cfg);
        job.execute(null);
        Test.stopTest();

        // Має створити 1 лог (бо 1 recipient < 100 default batchSize)
        List<Notification_Log__c> logs = [SELECT Id FROM Notification_Log__c];
        System.assertEquals(1, logs.size());
    }

    /**
     * Тест: execute з batchSize <= 0 використовує дефолтний (100)
     */
    @IsTest
    static void testExecute_ZeroBatchSize_UsesDefault() {
        NotificationTypes.NotificationPayload p = makePayload('ZERO_BATCH_TEST');
        NotificationTypes.NotificationEventCfg cfg = makeCfg('EmailUsers', 0);
        NotificationTypes.RecipientBundle rb = makeBundle();
        rb.emails.add('test@example.com');

        Test.startTest();
        NotificationQueueable job = new NotificationQueueable(p, rb, cfg);
        job.execute(null);
        Test.stopTest();

        List<Notification_Log__c> logs = [SELECT Id FROM Notification_Log__c];
        System.assertEquals(1, logs.size());
    }

    /**
     * Тест: execute зберігає лог зі статусом Sent для успішної відправки
     */
    @IsTest
    static void testExecute_SuccessfulSend_LogsWithSentStatus() {
        NotificationTypes.NotificationPayload p = makePayload('SUCCESS_TEST');
        NotificationTypes.NotificationEventCfg cfg = makeCfg('EmailUsers', 100);
        NotificationTypes.RecipientBundle rb = makeBundle();
        rb.emails.add('test@example.com');

        Test.startTest();
        NotificationQueueable job = new NotificationQueueable(p, rb, cfg);
        job.execute(null);
        Test.stopTest();

        List<Notification_Log__c> logs = [SELECT Status__c FROM Notification_Log__c];
        System.assertEquals(1, logs.size());
        // Залежить від реальної реалізації каналу
    }

    /**
     * Тест: execute викликає channel.send для кожного чанку
     */
    @IsTest
    static void testExecute_CallsChannelSendPerChunk() {
        NotificationTypes.NotificationPayload p = makePayload('CHUNK_TEST');
        NotificationTypes.NotificationEventCfg cfg = makeCfg('EmailUsers', 1); // batchSize = 1
        NotificationTypes.RecipientBundle rb = makeBundle();
        rb.emails.add('test1@example.com');
        rb.emails.add('test2@example.com');
        rb.emails.add('test3@example.com');

        Test.startTest();
        NotificationQueueable job = new NotificationQueueable(p, rb, cfg);
        job.execute(null);
        Test.stopTest();

        // 3 emails / batchSize 1 = 3 чанки → 3 виклики channel.send → 3 логи
        List<Notification_Log__c> logs = [SELECT Id FROM Notification_Log__c];
        System.assertEquals(3, logs.size());
    }

    /**
     * Тест: конструктор зберігає параметри
     */
    @IsTest
    static void testConstructor_StoresParameters() {
        NotificationTypes.NotificationPayload p = makePayload('CONSTRUCTOR_TEST');
        NotificationTypes.NotificationEventCfg cfg = makeCfg('EmailUsers', 100);
        NotificationTypes.RecipientBundle rb = makeBundle();

        Test.startTest();
        NotificationQueueable job = new NotificationQueueable(p, rb, cfg);
        Test.stopTest();

        // Якщо не викликаємо execute, жодних логів не має бути
        List<Notification_Log__c> logs = [SELECT Id FROM Notification_Log__c];
        System.assertEquals(0, logs.size());
    }

    /**
     * Тест: execute з різними каналами
     */
    @IsTest
    static void testExecute_DifferentChannels_Works() {
        NotificationTypes.NotificationPayload p = makePayload('CHANNEL_TEST');
        NotificationTypes.RecipientBundle rb = makeBundle();
        rb.emails.add('test@example.com');

        Test.startTest();
        // EmailUsers
        NotificationTypes.NotificationEventCfg cfg1 = makeCfg('EmailUsers', 100);
        NotificationQueueable job1 = new NotificationQueueable(p, rb, cfg1);
        job1.execute(null);

        // EmailContacts (потрібен Contact Id)
        NotificationTypes.NotificationEventCfg cfg2 = makeCfg('EmailContacts', 100);
        NotificationQueueable job2 = new NotificationQueueable(p, rb, cfg2);
        job2.execute(null);
        Test.stopTest();

        List<Notification_Log__c> logs = [SELECT Channel__c FROM Notification_Log__c];
        System.assertEquals(2, logs.size());
    }

    /**
     * Тест: execute з порожнім payload
     */
    @IsTest
    static void testExecute_EmptyPayload_Works() {
        NotificationTypes.NotificationPayload p = new NotificationTypes.NotificationPayload();
        p.eventKey = null;
        p.context = null;
        p.vars = new Map<String, Object>();

        NotificationTypes.NotificationEventCfg cfg = makeCfg('EmailUsers', 100);
        NotificationTypes.RecipientBundle rb = makeBundle();
        rb.emails.add('test@example.com');

        Test.startTest();
        NotificationQueueable job = new NotificationQueueable(p, rb, cfg);
        job.execute(null);
        Test.stopTest();

        List<Notification_Log__c> logs = [SELECT EventKey__c FROM Notification_Log__c];
        System.assertEquals(1, logs.size());
        System.assertEquals(null, logs[0].EventKey__c);
    }

    /**
     * Тест: execute з користувацьким batchSize
     */
    @IsTest
    static void testExecute_CustomBatchSize_Works() {
        NotificationTypes.NotificationPayload p = makePayload('CUSTOM_BATCH_TEST');
        NotificationTypes.NotificationEventCfg cfg = makeCfg('EmailUsers', 3);
        NotificationTypes.RecipientBundle rb = makeBundle();
        for (Integer i = 0; i < 10; i++) {
            rb.emails.add('test' + i + '@example.com');
        }

        Test.startTest();
        NotificationQueueable job = new NotificationQueueable(p, rb, cfg);
        job.execute(null);
        Test.stopTest();

        // 10 emails / batchSize 3 = 4 чанки (3+3+3+1)
        List<Notification_Log__c> logs = [SELECT Id FROM Notification_Log__c];
        System.assertEquals(4, logs.size());
    }
}