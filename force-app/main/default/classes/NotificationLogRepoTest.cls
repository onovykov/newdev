@IsTest
private class NotificationLogRepoTest {

    private static NotificationTypes.NotificationPayload makePayload(String eventKey, SObject ctx) {
        NotificationTypes.NotificationPayload p = new NotificationTypes.NotificationPayload();
        p.eventKey = eventKey;
        p.context = ctx;
        p.vars = new Map<String, Object>();
        return p;
    }

    private static NotificationTypes.NotificationEventCfg makeCfg(String eventKey, String channel) {
        NotificationTypes.NotificationEventCfg cfg = new NotificationTypes.NotificationEventCfg();
        cfg.eventKey = eventKey;
        cfg.channel = channel;
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

    private static NotificationTypes.ChannelResult makeResult(Boolean ok, Integer sentCount, String message) {
        NotificationTypes.ChannelResult res = new NotificationTypes.ChannelResult();
        res.ok = ok;
        res.sentCount = sentCount;
        res.message = message;
        return res;
    }

    /**
     * Тест: save з res == null → Status = 'Queued'
     */
    @IsTest
    static void testSave_NullResult_StatusQueued() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        NotificationTypes.NotificationPayload p = makePayload('TEST_EVENT', acc);
        NotificationTypes.NotificationEventCfg cfg = makeCfg('TEST_EVENT', 'EmailUsers');
        NotificationTypes.RecipientBundle rb = makeBundle();

        Test.startTest();
        NotificationLogRepo.save(p, cfg, rb, null);
        Test.stopTest();

        List<Notification_Log__c> logs = [SELECT Status__c, EventKey__c, Channel__c FROM Notification_Log__c];
        System.assertEquals(1, logs.size());
        System.assertEquals('Queued', logs[0].Status__c);
        System.assertEquals('TEST_EVENT', logs[0].EventKey__c);
        System.assertEquals('EmailUsers', logs[0].Channel__c);
    }

    /**
     * Тест: save з res.ok = true і sentCount > 0 → Status = 'Sent'
     */
    @IsTest
    static void testSave_OkWithSentCount_StatusSent() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        NotificationTypes.NotificationPayload p = makePayload('TEST_EVENT', acc);
        NotificationTypes.NotificationEventCfg cfg = makeCfg('TEST_EVENT', 'EmailUsers');
        NotificationTypes.RecipientBundle rb = makeBundle();
        rb.userIds.add(UserInfo.getUserId());

        NotificationTypes.ChannelResult res = makeResult(true, 1, 'Email sent successfully');

        Test.startTest();
        NotificationLogRepo.save(p, cfg, rb, res);
        Test.stopTest();

        List<Notification_Log__c> logs = [SELECT Status__c, ResolverTrace__c FROM Notification_Log__c];
        System.assertEquals(1, logs.size());
        System.assertEquals('Sent', logs[0].Status__c);
        System.assert(logs[0].ResolverTrace__c.contains('Channel: Email sent successfully'));
    }

    /**
     * Тест: save з res.ok = true і sentCount = 0 → Status = 'SkippedNoRecipients'
     */
    @IsTest
    static void testSave_OkWithZeroSent_StatusSkipped() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        NotificationTypes.NotificationPayload p = makePayload('TEST_EVENT', acc);
        NotificationTypes.NotificationEventCfg cfg = makeCfg('TEST_EVENT', 'EmailUsers');
        NotificationTypes.RecipientBundle rb = makeBundle();

        NotificationTypes.ChannelResult res = makeResult(true, 0, null);

        Test.startTest();
        NotificationLogRepo.save(p, cfg, rb, res);
        Test.stopTest();

        List<Notification_Log__c> logs = [SELECT Status__c FROM Notification_Log__c];
        System.assertEquals(1, logs.size());
        System.assertEquals('SkippedNoRecipients', logs[0].Status__c);
    }

    /**
     * Тест: save з res.ok = false і sentCount > 0 → Status = 'PartiallyFailed'
     */
    @IsTest
    static void testSave_FailedWithSomeSent_StatusPartiallyFailed() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        NotificationTypes.NotificationPayload p = makePayload('TEST_EVENT', acc);
        NotificationTypes.NotificationEventCfg cfg = makeCfg('TEST_EVENT', 'EmailUsers');
        NotificationTypes.RecipientBundle rb = makeBundle();
        rb.userIds.add(UserInfo.getUserId());

        NotificationTypes.ChannelResult res = makeResult(false, 1, 'Partially sent');

        Test.startTest();
        NotificationLogRepo.save(p, cfg, rb, res);
        Test.stopTest();

        List<Notification_Log__c> logs = [SELECT Status__c FROM Notification_Log__c];
        System.assertEquals(1, logs.size());
        System.assertEquals('PartiallyFailed', logs[0].Status__c);
    }

    /**
     * Тест: save з res.ok = false і sentCount = 0 → Status = 'Failed'
     */
    @IsTest
    static void testSave_FailedWithZeroSent_StatusFailed() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        NotificationTypes.NotificationPayload p = makePayload('TEST_EVENT', acc);
        NotificationTypes.NotificationEventCfg cfg = makeCfg('TEST_EVENT', 'EmailUsers');
        NotificationTypes.RecipientBundle rb = makeBundle();

        NotificationTypes.ChannelResult res = makeResult(false, 0, 'Send failed');

        Test.startTest();
        NotificationLogRepo.save(p, cfg, rb, res);
        Test.stopTest();

        List<Notification_Log__c> logs = [SELECT Status__c, ResolverTrace__c FROM Notification_Log__c];
        System.assertEquals(1, logs.size());
        System.assertEquals('Failed', logs[0].Status__c);
        System.assert(logs[0].ResolverTrace__c.contains('Channel: Send failed'));
    }

    /**
     * Тест: save з res.sentCount = null → розглядається як 0
     */
    @IsTest
    static void testSave_NullSentCount_TreatedAsZero() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        NotificationTypes.NotificationPayload p = makePayload('TEST_EVENT', acc);
        NotificationTypes.NotificationEventCfg cfg = makeCfg('TEST_EVENT', 'EmailUsers');
        NotificationTypes.RecipientBundle rb = makeBundle();

        NotificationTypes.ChannelResult res = makeResult(true, null, null);

        Test.startTest();
        NotificationLogRepo.save(p, cfg, rb, res);
        Test.stopTest();

        List<Notification_Log__c> logs = [SELECT Status__c FROM Notification_Log__c];
        System.assertEquals(1, logs.size());
        System.assertEquals('SkippedNoRecipients', logs[0].Status__c);
    }

    /**
     * Тест: logThrottled створює запис зі статусом 'Throttled'
     */
    @IsTest
    static void testLogThrottled_CreatesThrottledRecord() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        NotificationTypes.NotificationPayload p = makePayload('THROTTLE_TEST', acc);
        NotificationTypes.NotificationEventCfg cfg = makeCfg('THROTTLE_TEST', 'EmailUsers');
        NotificationTypes.RecipientBundle rb = makeBundle();

        Test.startTest();
        NotificationLogRepo.logThrottled(p, cfg, rb);
        Test.stopTest();

        List<Notification_Log__c> logs = [SELECT Status__c, EventKey__c FROM Notification_Log__c];
        System.assertEquals(1, logs.size());
        System.assertEquals('Throttled', logs[0].Status__c);
        System.assertEquals('THROTTLE_TEST', logs[0].EventKey__c);
    }

    /**
     * Тест: logNoRecipients створює запис зі статусом 'SkippedNoRecipients'
     */
    @IsTest
    static void testLogNoRecipients_CreatesSkippedRecord() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        NotificationTypes.NotificationPayload p = makePayload('NO_REC_TEST', acc);
        NotificationTypes.NotificationEventCfg cfg = makeCfg('NO_REC_TEST', 'EmailUsers');
        NotificationTypes.RecipientBundle rb = makeBundle();

        Test.startTest();
        NotificationLogRepo.logNoRecipients(p, cfg, rb);
        Test.stopTest();

        List<Notification_Log__c> logs = [SELECT Status__c, EventKey__c FROM Notification_Log__c];
        System.assertEquals(1, logs.size());
        System.assertEquals('SkippedNoRecipients', logs[0].Status__c);
        System.assertEquals('NO_REC_TEST', logs[0].EventKey__c);
    }

    /**
     * Тест: buildBase з context SObject заповнює ContextSObjectType і ContextRecordId
     */
    @IsTest
    static void testBuildBase_WithContextSObject_FillsContextFields() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        NotificationTypes.NotificationPayload p = makePayload('CONTEXT_TEST', acc);
        NotificationTypes.NotificationEventCfg cfg = makeCfg('CONTEXT_TEST', 'EmailUsers');
        NotificationTypes.RecipientBundle rb = makeBundle();

        Test.startTest();
        NotificationLogRepo.save(p, cfg, rb, null);
        Test.stopTest();

        List<Notification_Log__c> logs = [
            SELECT ContextSObjectType__c, ContextRecordId__c
            FROM Notification_Log__c
        ];
        System.assertEquals(1, logs.size());
        System.assertEquals('Account', logs[0].ContextSObjectType__c);
        System.assertEquals(acc.Id, logs[0].ContextRecordId__c);
    }

    /**
     * Тест: buildBase з payload = null
     */
    @IsTest
    static void testBuildBase_NullPayload_HandlesGracefully() {
        NotificationTypes.NotificationEventCfg cfg = makeCfg('NULL_TEST', 'EmailUsers');
        NotificationTypes.RecipientBundle rb = makeBundle();

        Test.startTest();
        NotificationLogRepo.save(null, cfg, rb, null);
        Test.stopTest();

        List<Notification_Log__c> logs = [SELECT EventKey__c, ContextSObjectType__c FROM Notification_Log__c];
        System.assertEquals(1, logs.size());
        System.assertEquals(null, logs[0].EventKey__c);
        System.assertEquals(null, logs[0].ContextSObjectType__c);
    }

    /**
     * Тест: buildBase з cfg = null
     */
    @IsTest
    static void testBuildBase_NullConfig_HandlesGracefully() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        NotificationTypes.NotificationPayload p = makePayload('CFG_NULL_TEST', acc);
        NotificationTypes.RecipientBundle rb = makeBundle();

        Test.startTest();
        NotificationLogRepo.save(p, null, rb, null);
        Test.stopTest();

        List<Notification_Log__c> logs = [SELECT Channel__c FROM Notification_Log__c];
        System.assertEquals(1, logs.size());
        System.assertEquals(null, logs[0].Channel__c);
    }

    /**
     * Тест: countRecipients з різними типами отримувачів
     */
    @IsTest
    static void testCountRecipients_AllTypes_CountsCorrectly() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        NotificationTypes.NotificationPayload p = makePayload('COUNT_TEST', acc);
        NotificationTypes.NotificationEventCfg cfg = makeCfg('COUNT_TEST', 'EmailUsers');
        NotificationTypes.RecipientBundle rb = makeBundle();
        rb.userIds.add(UserInfo.getUserId());
        rb.contactIds.add(acc.Id); // Використовуємо будь-який Id для тесту
        rb.emails.add('test1@example.com');
        rb.emails.add('test2@example.com');

        Test.startTest();
        NotificationLogRepo.save(p, cfg, rb, null);
        Test.stopTest();

        List<Notification_Log__c> logs = [SELECT RecipientsCount__c FROM Notification_Log__c];
        System.assertEquals(1, logs.size());
        System.assertEquals(4, logs[0].RecipientsCount__c);
    }

    /**
     * Тест: countRecipients з rb = null
     */
    @IsTest
    static void testCountRecipients_NullBundle_ReturnsZero() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        NotificationTypes.NotificationPayload p = makePayload('NULL_BUNDLE_TEST', acc);
        NotificationTypes.NotificationEventCfg cfg = makeCfg('NULL_BUNDLE_TEST', 'EmailUsers');

        Test.startTest();
        NotificationLogRepo.save(p, cfg, null, null);
        Test.stopTest();

        List<Notification_Log__c> logs = [SELECT RecipientsCount__c FROM Notification_Log__c];
        System.assertEquals(1, logs.size());
        System.assertEquals(0, logs[0].RecipientsCount__c);
    }

    /**
     * Тест: rb.resolverTrace додається до ResolverTrace__c
     */
    @IsTest
    static void testBuildBase_WithResolverTrace_FillsField() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        NotificationTypes.NotificationPayload p = makePayload('TRACE_TEST', acc);
        NotificationTypes.NotificationEventCfg cfg = makeCfg('TRACE_TEST', 'EmailUsers');
        NotificationTypes.RecipientBundle rb = makeBundle();
        rb.resolverTrace = 'Resolved from Group1, Group2';

        Test.startTest();
        NotificationLogRepo.save(p, cfg, rb, null);
        Test.stopTest();

        List<Notification_Log__c> logs = [SELECT ResolverTrace__c FROM Notification_Log__c];
        System.assertEquals(1, logs.size());
        System.assert(logs[0].ResolverTrace__c.contains('Resolved from Group1, Group2'));
    }

    /**
     * Тест: appendTrace додає message через |
     */
    @IsTest
    static void testAppendTrace_AddsMessageWithPipe() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        NotificationTypes.NotificationPayload p = makePayload('APPEND_TEST', acc);
        NotificationTypes.NotificationEventCfg cfg = makeCfg('APPEND_TEST', 'EmailUsers');
        NotificationTypes.RecipientBundle rb = makeBundle();
        rb.resolverTrace = 'Initial trace';

        NotificationTypes.ChannelResult res = makeResult(true, 1, 'Channel result');

        Test.startTest();
        NotificationLogRepo.save(p, cfg, rb, res);
        Test.stopTest();

        List<Notification_Log__c> logs = [SELECT ResolverTrace__c FROM Notification_Log__c];
        System.assertEquals(1, logs.size());
        System.assert(logs[0].ResolverTrace__c.contains('Initial trace'));
        System.assert(logs[0].ResolverTrace__c.contains('Channel: Channel result'));
        System.assert(logs[0].ResolverTrace__c.contains(' | '));
    }

    /**
     * Тест: res.message порожнє не додається до trace
     */
    @IsTest
    static void testAppendTrace_EmptyMessage_NotAdded() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        NotificationTypes.NotificationPayload p = makePayload('EMPTY_MSG_TEST', acc);
        NotificationTypes.NotificationEventCfg cfg = makeCfg('EMPTY_MSG_TEST', 'EmailUsers');
        NotificationTypes.RecipientBundle rb = makeBundle();
        rb.resolverTrace = 'Initial trace';

        NotificationTypes.ChannelResult res = makeResult(true, 1, '');

        Test.startTest();
        NotificationLogRepo.save(p, cfg, rb, res);
        Test.stopTest();

        List<Notification_Log__c> logs = [SELECT ResolverTrace__c FROM Notification_Log__c];
        System.assertEquals(1, logs.size());
        System.assertEquals('Initial trace', logs[0].ResolverTrace__c);
    }

    /**
     * Тест: context без Id не викликає помилку
     */
    @IsTest
    static void testBuildBase_ContextWithoutId_HandlesGracefully() {
        Account acc = new Account(Name = 'Test Account');
        // НЕ вставляємо, тому Id буде null

        NotificationTypes.NotificationPayload p = makePayload('NO_ID_TEST', acc);
        NotificationTypes.NotificationEventCfg cfg = makeCfg('NO_ID_TEST', 'EmailUsers');
        NotificationTypes.RecipientBundle rb = makeBundle();

        Test.startTest();
        NotificationLogRepo.save(p, cfg, rb, null);
        Test.stopTest();

        List<Notification_Log__c> logs = [SELECT ContextSObjectType__c, ContextRecordId__c FROM Notification_Log__c];
        System.assertEquals(1, logs.size());
        System.assertEquals('Account', logs[0].ContextSObjectType__c);
        System.assertEquals(null, logs[0].ContextRecordId__c);
    }

    /**
     * Тест: порожній RecipientBundle (всі Set порожні)
     */
    @IsTest
    static void testCountRecipients_EmptySets_ReturnsZero() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        NotificationTypes.NotificationPayload p = makePayload('EMPTY_SETS_TEST', acc);
        NotificationTypes.NotificationEventCfg cfg = makeCfg('EMPTY_SETS_TEST', 'EmailUsers');
        NotificationTypes.RecipientBundle rb = makeBundle();
        // Всі Set порожні

        Test.startTest();
        NotificationLogRepo.save(p, cfg, rb, null);
        Test.stopTest();

        List<Notification_Log__c> logs = [SELECT RecipientsCount__c FROM Notification_Log__c];
        System.assertEquals(1, logs.size());
        System.assertEquals(0, logs[0].RecipientsCount__c);
    }
}