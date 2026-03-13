/**
 * Test class for NotificationTypes.
 * Covers all inner classes: NotificationPayload, NotificationEventCfg, RecipientBundle, ChannelResult.
 */
@IsTest
private class NotificationTypesTest {

    // ========================================
    // NotificationPayload Tests
    // ========================================

    /**
     * Test NotificationPayload constructor with all parameters
     */
    @IsTest
    static void notificationPayload_constructorWithParams_setsAllFields() {
        // Arrange
        String eventKey = 'TEST_EVENT';
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Map<String, Object> vars = new Map<String, Object>{
            'key1' => 'value1',
            'key2' => 123
        };

        // Act
        Test.startTest();
        NotificationTypes.NotificationPayload payload =
            new NotificationTypes.NotificationPayload(eventKey, testAccount, vars);
        Test.stopTest();

        // Assert
        System.assertEquals('TEST_EVENT', payload.eventKey, 'eventKey має бути встановлений');
        System.assertEquals(testAccount.Id, payload.context.Id, 'context має бути встановлений');
        System.assertNotEquals(null, payload.vars, 'vars не має бути null');
        System.assertEquals(2, payload.vars.size(), 'vars має містити 2 елементи');
        System.assertEquals('value1', payload.vars.get('key1'), 'vars має містити правильні значення');
        System.assertEquals(123, payload.vars.get('key2'), 'vars має містити правильні значення');
    }

    /**
     * Test NotificationPayload constructor with null vars - should create empty Map
     */
    @IsTest
    static void notificationPayload_constructorWithNullVars_createsEmptyMap() {
        // Arrange
        String eventKey = 'TEST_EVENT';
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        // Act
        Test.startTest();
        NotificationTypes.NotificationPayload payload =
            new NotificationTypes.NotificationPayload(eventKey, testAccount, null);
        Test.stopTest();

        // Assert
        System.assertEquals('TEST_EVENT', payload.eventKey);
        System.assertEquals(testAccount.Id, payload.context.Id);
        System.assertNotEquals(null, payload.vars, 'vars має бути ініціалізований як empty Map');
        System.assertEquals(0, payload.vars.size(), 'vars має бути порожнім');
    }

    /**
     * Test NotificationPayload constructor with null context
     */
    @IsTest
    static void notificationPayload_constructorWithNullContext_allowsNull() {
        // Arrange
        String eventKey = 'TEST_EVENT';
        Map<String, Object> vars = new Map<String, Object>{ 'test' => 'value' };

        // Act
        Test.startTest();
        NotificationTypes.NotificationPayload payload =
            new NotificationTypes.NotificationPayload(eventKey, null, vars);
        Test.stopTest();

        // Assert
        System.assertEquals('TEST_EVENT', payload.eventKey);
        System.assertEquals(null, payload.context, 'context може бути null');
        System.assertEquals(1, payload.vars.size());
    }

    /**
     * Test NotificationPayload default constructor
     */
    @IsTest
    static void notificationPayload_defaultConstructor_createsEmptyObject() {
        // Act
        Test.startTest();
        NotificationTypes.NotificationPayload payload =
            new NotificationTypes.NotificationPayload();
        Test.stopTest();

        // Assert
        System.assertEquals(null, payload.eventKey, 'eventKey має бути null');
        System.assertEquals(null, payload.context, 'context має бути null');
        System.assertEquals(null, payload.vars, 'vars має бути null');
    }

    /**
     * Test NotificationPayload with empty vars Map
     */
    @IsTest
    static void notificationPayload_withEmptyVars_keepsEmptyMap() {
        // Arrange
        Map<String, Object> emptyVars = new Map<String, Object>();

        // Act
        Test.startTest();
        NotificationTypes.NotificationPayload payload =
            new NotificationTypes.NotificationPayload('EVENT', null, emptyVars);
        Test.stopTest();

        // Assert
        System.assertNotEquals(null, payload.vars, 'vars не має бути null');
        System.assertEquals(0, payload.vars.size(), 'vars має бути порожнім');
    }

    /**
     * Test NotificationPayload with complex vars
     */
    @IsTest
    static void notificationPayload_withComplexVars_storesAllTypes() {
        // Arrange
        Map<String, Object> complexVars = new Map<String, Object>{
            'stringVar' => 'test',
            'intVar' => 123,
            'boolVar' => true,
            'decimalVar' => 45.67,
            'dateVar' => Date.today(),
            'listVar' => new List<String>{ 'a', 'b' },
            'mapVar' => new Map<String, Object>{ 'nested' => 'value' },
            'nullVar' => null
        };

        // Act
        Test.startTest();
        NotificationTypes.NotificationPayload payload =
            new NotificationTypes.NotificationPayload('EVENT', null, complexVars);
        Test.stopTest();

        // Assert
        System.assertEquals(8, payload.vars.size(), 'Всі типи vars мають бути збережені');
        System.assertEquals('test', payload.vars.get('stringVar'));
        System.assertEquals(123, payload.vars.get('intVar'));
        System.assertEquals(true, payload.vars.get('boolVar'));
        System.assertEquals(null, payload.vars.get('nullVar'));
    }

    // ========================================
    // NotificationEventCfg Tests
    // ========================================

    /**
     * Test NotificationEventCfg initialization
     */
    @IsTest
    static void notificationEventCfg_initialization_initializesRecipientGroupKeys() {
        // Act
        Test.startTest();
        NotificationTypes.NotificationEventCfg cfg =
            new NotificationTypes.NotificationEventCfg();
        Test.stopTest();

        // Assert
        System.assertNotEquals(null, cfg.recipientGroupKeys, 'recipientGroupKeys має бути ініціалізований');
        System.assertEquals(0, cfg.recipientGroupKeys.size(), 'recipientGroupKeys має бути порожнім списком');
    }

    /**
     * Test NotificationEventCfg with all fields set
     */
    @IsTest
    static void notificationEventCfg_setAllFields_storesValues() {
        // Arrange
        NotificationTypes.NotificationEventCfg cfg =
            new NotificationTypes.NotificationEventCfg();

        // Act
        Test.startTest();
        cfg.eventKey = 'TEST_EVENT';
        cfg.active = true;
        cfg.channel = 'Email';
        cfg.recipientGroupKeys = new List<String>{ 'Group1', 'Group2' };
        cfg.templateApiName = 'TestTemplate';
        cfg.saveAsActivity = true;
        cfg.throttleMinutes = 30;
        cfg.batchSize = 100;
        Test.stopTest();

        // Assert
        System.assertEquals('TEST_EVENT', cfg.eventKey);
        System.assertEquals(true, cfg.active);
        System.assertEquals('Email', cfg.channel);
        System.assertEquals(2, cfg.recipientGroupKeys.size());
        System.assertEquals('Group1', cfg.recipientGroupKeys[0]);
        System.assertEquals('Group2', cfg.recipientGroupKeys[1]);
        System.assertEquals('TestTemplate', cfg.templateApiName);
        System.assertEquals(true, cfg.saveAsActivity);
        System.assertEquals(30, cfg.throttleMinutes);
        System.assertEquals(100, cfg.batchSize);
    }

    /**
     * Test NotificationEventCfg with null values
     */
    @IsTest
    static void notificationEventCfg_withNullValues_allowsNulls() {
        // Arrange
        NotificationTypes.NotificationEventCfg cfg =
            new NotificationTypes.NotificationEventCfg();

        // Act
        Test.startTest();
        cfg.eventKey = null;
        cfg.active = null;
        cfg.channel = null;
        cfg.templateApiName = null;
        cfg.saveAsActivity = null;
        cfg.throttleMinutes = null;
        cfg.batchSize = null;
        Test.stopTest();

        // Assert
        System.assertEquals(null, cfg.eventKey);
        System.assertEquals(null, cfg.active);
        System.assertEquals(null, cfg.channel);
        System.assertEquals(null, cfg.templateApiName);
        System.assertEquals(null, cfg.saveAsActivity);
        System.assertEquals(null, cfg.throttleMinutes);
        System.assertEquals(null, cfg.batchSize);
        System.assertNotEquals(null, cfg.recipientGroupKeys, 'recipientGroupKeys завжди ініціалізований');
    }

    // ========================================
    // RecipientBundle Tests
    // ========================================

    /**
     * Test RecipientBundle initialization
     */
    @IsTest
    static void recipientBundle_initialization_initializesAllSets() {
        // Act
        Test.startTest();
        NotificationTypes.RecipientBundle bundle =
            new NotificationTypes.RecipientBundle();
        Test.stopTest();

        // Assert
        System.assertNotEquals(null, bundle.userIds, 'userIds має бути ініціалізований');
        System.assertNotEquals(null, bundle.contactIds, 'contactIds має бути ініціалізований');
        System.assertNotEquals(null, bundle.emails, 'emails має бути ініціалізований');
        System.assertEquals(0, bundle.userIds.size(), 'userIds має бути порожнім');
        System.assertEquals(0, bundle.contactIds.size(), 'contactIds має бути порожнім');
        System.assertEquals(0, bundle.emails.size(), 'emails має бути порожнім');
    }

    /**
     * Test RecipientBundle.isEmpty() - all empty
     */
    @IsTest
    static void recipientBundle_isEmpty_allEmpty_returnsTrue() {
        // Arrange
        NotificationTypes.RecipientBundle bundle =
            new NotificationTypes.RecipientBundle();

        // Act
        Test.startTest();
        Boolean result = bundle.isEmpty();
        Test.stopTest();

        // Assert
        System.assertEquals(true, result, 'isEmpty має повертати true коли всі Set порожні');
    }

    /**
     * Test RecipientBundle.isEmpty() - has userIds
     */
    @IsTest
    static void recipientBundle_isEmpty_hasUserIds_returnsFalse() {
        // Arrange
        NotificationTypes.RecipientBundle bundle =
            new NotificationTypes.RecipientBundle();
        bundle.userIds.add(UserInfo.getUserId());

        // Act
        Test.startTest();
        Boolean result = bundle.isEmpty();
        Test.stopTest();

        // Assert
        System.assertEquals(false, result, 'isEmpty має повертати false коли є userIds');
    }

    /**
     * Test RecipientBundle.isEmpty() - has contactIds
     */
    @IsTest
    static void recipientBundle_isEmpty_hasContactIds_returnsFalse() {
        // Arrange
        NotificationTypes.RecipientBundle bundle =
            new NotificationTypes.RecipientBundle();
        bundle.contactIds.add('003000000000001AAA');

        // Act
        Test.startTest();
        Boolean result = bundle.isEmpty();
        Test.stopTest();

        // Assert
        System.assertEquals(false, result, 'isEmpty має повертати false коли є contactIds');
    }

    /**
     * Test RecipientBundle.isEmpty() - has emails
     */
    @IsTest
    static void recipientBundle_isEmpty_hasEmails_returnsFalse() {
        // Arrange
        NotificationTypes.RecipientBundle bundle =
            new NotificationTypes.RecipientBundle();
        bundle.emails.add('test@example.com');

        // Act
        Test.startTest();
        Boolean result = bundle.isEmpty();
        Test.stopTest();

        // Assert
        System.assertEquals(false, result, 'isEmpty має повертати false коли є emails');
    }

    /**
     * Test RecipientBundle.isEmpty() - has all types
     */
    @IsTest
    static void recipientBundle_isEmpty_hasAllTypes_returnsFalse() {
        // Arrange
        NotificationTypes.RecipientBundle bundle =
            new NotificationTypes.RecipientBundle();
        bundle.userIds.add(UserInfo.getUserId());
        bundle.contactIds.add('003000000000001AAA');
        bundle.emails.add('test@example.com');

        // Act
        Test.startTest();
        Boolean result = bundle.isEmpty();
        Test.stopTest();

        // Assert
        System.assertEquals(false, result, 'isEmpty має повертати false коли є всі типи');
    }

    /**
     * Test RecipientBundle.totalCount() - all empty
     */
    @IsTest
    static void recipientBundle_totalCount_allEmpty_returnsZero() {
        // Arrange
        NotificationTypes.RecipientBundle bundle =
            new NotificationTypes.RecipientBundle();

        // Act
        Test.startTest();
        Integer count = bundle.totalCount();
        Test.stopTest();

        // Assert
        System.assertEquals(0, count, 'totalCount має повертати 0 для порожнього bundle');
    }

    /**
     * Test RecipientBundle.totalCount() - only userIds
     */
    @IsTest
    static void recipientBundle_totalCount_onlyUserIds_returnsCorrectCount() {
        // Arrange
        NotificationTypes.RecipientBundle bundle =
            new NotificationTypes.RecipientBundle();
        bundle.userIds.add(UserInfo.getUserId());
        bundle.userIds.add('005000000000001AAA');

        // Act
        Test.startTest();
        Integer count = bundle.totalCount();
        Test.stopTest();

        // Assert
        System.assertEquals(2, count, 'totalCount має повертати кількість userIds');
    }

    /**
     * Test RecipientBundle.totalCount() - only contactIds
     */
    @IsTest
    static void recipientBundle_totalCount_onlyContactIds_returnsCorrectCount() {
        // Arrange
        NotificationTypes.RecipientBundle bundle =
            new NotificationTypes.RecipientBundle();
        bundle.contactIds.add('003000000000001AAA');
        bundle.contactIds.add('003000000000002AAA');
        bundle.contactIds.add('003000000000003AAA');

        // Act
        Test.startTest();
        Integer count = bundle.totalCount();
        Test.stopTest();

        // Assert
        System.assertEquals(3, count, 'totalCount має повертати кількість contactIds');
    }

    /**
     * Test RecipientBundle.totalCount() - only emails
     */
    @IsTest
    static void recipientBundle_totalCount_onlyEmails_returnsCorrectCount() {
        // Arrange
        NotificationTypes.RecipientBundle bundle =
            new NotificationTypes.RecipientBundle();
        bundle.emails.add('test1@example.com');
        bundle.emails.add('test2@example.com');
        bundle.emails.add('test3@example.com');
        bundle.emails.add('test4@example.com');

        // Act
        Test.startTest();
        Integer count = bundle.totalCount();
        Test.stopTest();

        // Assert
        System.assertEquals(4, count, 'totalCount має повертати кількість emails');
    }

    /**
     * Test RecipientBundle.totalCount() - mixed types
     */
    @IsTest
    static void recipientBundle_totalCount_mixedTypes_returnsSumOfAll() {
        // Arrange
        NotificationTypes.RecipientBundle bundle =
            new NotificationTypes.RecipientBundle();
        bundle.userIds.add(UserInfo.getUserId());
        bundle.userIds.add('005000000000001AAA');
        bundle.contactIds.add('003000000000001AAA');
        bundle.emails.add('test1@example.com');
        bundle.emails.add('test2@example.com');
        bundle.emails.add('test3@example.com');

        // Act
        Test.startTest();
        Integer count = bundle.totalCount();
        Test.stopTest();

        // Assert
        System.assertEquals(6, count, 'totalCount має повертати суму всіх типів: 2 + 1 + 3 = 6');
    }

    /**
     * Test RecipientBundle with resolverTrace
     */
    @IsTest
    static void recipientBundle_resolverTrace_storesValue() {
        // Arrange
        NotificationTypes.RecipientBundle bundle =
            new NotificationTypes.RecipientBundle();
        String trace = 'Resolved from AccountOwner > DefaultGroup';

        // Act
        Test.startTest();
        bundle.resolverTrace = trace;
        Test.stopTest();

        // Assert
        System.assertEquals(trace, bundle.resolverTrace, 'resolverTrace має зберігати значення');
    }

    /**
     * Test RecipientBundle - add duplicate values (Set behavior)
     */
    @IsTest
    static void recipientBundle_addDuplicates_setDeduplicates() {
        // Arrange
        NotificationTypes.RecipientBundle bundle =
            new NotificationTypes.RecipientBundle();

        // Act
        Test.startTest();
        bundle.userIds.add(UserInfo.getUserId());
        bundle.userIds.add(UserInfo.getUserId()); // duplicate
        bundle.emails.add('test@example.com');
        bundle.emails.add('test@example.com'); // duplicate
        bundle.emails.add('TEST@EXAMPLE.COM'); // різний регістр - не дублікат для Set
        Test.stopTest();

        // Assert
        System.assertEquals(1, bundle.userIds.size(), 'Set має дедуплікувати userIds');
        System.assertEquals(2, bundle.emails.size(), 'Set має дедуплікувати emails (case-sensitive)');
        System.assertEquals(3, bundle.totalCount(), 'totalCount має бути 1 + 2 = 3');
    }

    // ========================================
    // ChannelResult Tests
    // ========================================

    /**
     * Test ChannelResult initialization
     */
    @IsTest
    static void channelResult_initialization_createsEmptyObject() {
        // Act
        Test.startTest();
        NotificationTypes.ChannelResult result =
            new NotificationTypes.ChannelResult();
        Test.stopTest();

        // Assert
        System.assertEquals(null, result.ok, 'ok має бути null');
        System.assertEquals(null, result.message, 'message має бути null');
        System.assertEquals(null, result.sentCount, 'sentCount має бути null');
    }

    /**
     * Test ChannelResult with success values
     */
    @IsTest
    static void channelResult_successScenario_storesValues() {
        // Arrange
        NotificationTypes.ChannelResult result =
            new NotificationTypes.ChannelResult();

        // Act
        Test.startTest();
        result.ok = true;
        result.message = 'Successfully sent notifications';
        result.sentCount = 15;
        Test.stopTest();

        // Assert
        System.assertEquals(true, result.ok);
        System.assertEquals('Successfully sent notifications', result.message);
        System.assertEquals(15, result.sentCount);
    }

    /**
     * Test ChannelResult with failure values
     */
    @IsTest
    static void channelResult_failureScenario_storesValues() {
        // Arrange
        NotificationTypes.ChannelResult result =
            new NotificationTypes.ChannelResult();

        // Act
        Test.startTest();
        result.ok = false;
        result.message = 'Failed to send: Invalid email address';
        result.sentCount = 0;
        Test.stopTest();

        // Assert
        System.assertEquals(false, result.ok);
        System.assertEquals('Failed to send: Invalid email address', result.message);
        System.assertEquals(0, result.sentCount);
    }

    /**
     * Test ChannelResult with partial success
     */
    @IsTest
    static void channelResult_partialSuccess_storesValues() {
        // Arrange
        NotificationTypes.ChannelResult result =
            new NotificationTypes.ChannelResult();

        // Act
        Test.startTest();
        result.ok = true;
        result.message = 'Sent 3 out of 5 notifications';
        result.sentCount = 3;
        Test.stopTest();

        // Assert
        System.assertEquals(true, result.ok);
        System.assertEquals('Sent 3 out of 5 notifications', result.message);
        System.assertEquals(3, result.sentCount);
    }
}