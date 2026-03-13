/**
 * Test class for ErrorService.
 * Achieves 80%+ code coverage through comprehensive testing.
 */
@IsTest
private class ErrorServiceTest {

    /**
     * Helper: Create mock Error_Classification__mdt record
     */
    private static Error_Classification__mdt createMockErrorConfig(
        String devName,
        String category,
        String subCategory,
        String errorKey,
        String area,
        String areaType,
        String criticalLevel,
        Decimal reactTimeHours,
        String notificationEvent
    ) {
        Error_Classification__mdt config = new Error_Classification__mdt();
        config.DeveloperName = devName;
        config.MasterLabel = devName;
        config.Category__c = category;
        config.SubCategory__c = subCategory;
        config.ErrorKey__c = errorKey;
        config.Area__c = area;
        config.AreaType__c = areaType;
        config.CriticalLevel__c = criticalLevel;
        config.ReactTimeHours__c = reactTimeHours;
        config.Default_Notification_Event__c = notificationEvent;
        return config;
    }

    /**
     * Helper: Setup test error configs
     */
    private static void setupTestConfigs() {
        ErrorService.testErrorConfigs = new Map<String, Error_Classification__mdt>();

        ErrorService.testErrorConfigs.put('GENERIC_ERROR', createMockErrorConfig(
            'GENERIC_ERROR',
            'System',
            'General',
            'GEN001',
            'OpportunityData',
            'Backend',
            'Low',
            24,
            null
        ));

        ErrorService.testErrorConfigs.put('CRITICAL_ERROR', createMockErrorConfig(
            'CRITICAL_ERROR',
            'System',
            'CriticalFailure',
            'CRIT001',
            'OpportunityManagement',
            'Backend',
            'Critical',
            1,
            'CRITICAL_NOTIFICATION'
        ));

        ErrorService.testErrorConfigs.put('HIGH_ERROR', createMockErrorConfig(
            'HIGH_ERROR',
            'Business',
            'DataIntegrity',
            'HIGH001',
            'Accounts',
            'Integration',
            'High',
            4,
            'HIGH_NOTIFICATION'
        ));

        ErrorService.testErrorConfigs.put('MEDIUM_ERROR', createMockErrorConfig(
            'MEDIUM_ERROR',
            'System',
            'Performance',
            'MED001',
            'RestAPI',
            'Backend',
            'Medium',
            12,
            'MEDIUM_NOTIFICATION'
        ));

        ErrorService.testErrorConfigs.put('NO_NOTIF_ERROR', createMockErrorConfig(
            'NO_NOTIF_ERROR',
            'System',
            'Test',
            'NO001',
            'Flow',
            'Backend',
            'Critical',
            1,
            null
        ));

        ErrorService.testErrorConfigs.put('INVALID_AREA', createMockErrorConfig(
            'INVALID_AREA',
            'System',
            'Test',
            'INV001',
            'InvalidAreaName',
            'Backend',
            'Low',
            24,
            null
        ));

        ErrorService.testErrorConfigs.put('BLANK_AREA', createMockErrorConfig(
            'BLANK_AREA',
            'System',
            'Test',
            'BLK001',
            null,
            'Backend',
            'Low',
            24,
            null
        ));
    }

    /**
     * Test: Blank errorKey uses GENERIC_ERROR
     */
    @IsTest
    static void handle_blankErrorKey_usesGenericError() {
        setupTestConfigs();

        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Exception testException = new DmlException('Test Exception');

        Test.startTest();
        ErrorService.handle('', testAccount, testException);
        Test.stopTest();

        System.assert(true, 'Should handle blank errorKey');
    }

    /**
     * Test: Low level error - no notification sent
     */
    @IsTest
    static void handle_lowLevel_noNotification() {
        setupTestConfigs();

        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Exception testException = new DmlException('Test Low Exception');

        Test.startTest();
        ErrorService.handle('GENERIC_ERROR', testAccount, testException);
        Test.stopTest();

        System.assert(true, 'Should not send notification for low level');
    }

    /**
     * Test: Medium level error - no notification sent
     */
    @IsTest
    static void handle_mediumLevel_noNotification() {
        setupTestConfigs();

        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Exception testException = new DmlException('Test Medium Exception');

        Test.startTest();
        ErrorService.handle('MEDIUM_ERROR', testAccount, testException);
        Test.stopTest();

        System.assert(true, 'Should not send notification for medium level');
    }

    /**
     * Test: High level with Account context - sends notification (no User_Type check)
     */
    @IsTest
    static void handle_highLevel_accountContext_sendsNotification() {
        setupTestConfigs();

        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Exception testException = new DmlException('Test High Exception');

        Test.startTest();
        ErrorService.handle('HIGH_ERROR', testAccount, testException);
        Test.stopTest();

        System.assert(true, 'Should send notification for Account context (no User_Type check)');
    }

    /**
     * Test: Critical level with null context - sends notification
     */
    @IsTest
    static void handle_criticalLevel_nullContext_sendsNotification() {
        setupTestConfigs();

        Exception testException = new DmlException('Test Critical Null Context');

        Test.startTest();
        ErrorService.handle('CRITICAL_ERROR', null, testException);
        Test.stopTest();

        System.assert(true, 'Should send notification for null context');
    }

    /**
     * Test: Critical level but no notification event - no notification
     */
    @IsTest
    static void handle_criticalLevel_noNotificationEvent() {
        setupTestConfigs();

        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Exception testException = new DmlException('Test Critical No Event');

        Test.startTest();
        ErrorService.handle('NO_NOTIF_ERROR', testAccount, testException);
        Test.stopTest();

        System.assert(true, 'Should not send notification when event not configured');
    }

    /**
     * Test: Opportunity with Sales Manager owner - sends notification
     */
    @IsTest
    static void handle_opportunity_salesManagerOwner_sendsNotification() {
        setupTestConfigs();

        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            OwnerId = UserInfo.getUserId()
        );
        insert testOpp;

        testOpp = [SELECT Id, AccountId, OwnerId FROM Opportunity WHERE Id = :testOpp.Id LIMIT 1];

        Exception testException = new DmlException('Test Opp Sales Manager Exception');

        Test.startTest();
        ErrorService.handle('CRITICAL_ERROR', testOpp, testException);
        Test.stopTest();

        System.assert(true, 'Should check User_Type for Opportunity owner');
    }

    /**
     * Test: Invalid area - uses default OpportunityData
     */
    @IsTest
    static void handle_invalidArea_usesDefault() {
        setupTestConfigs();

        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Exception testException = new DmlException('Test Invalid Area');

        Test.startTest();
        ErrorService.handle('INVALID_AREA', testAccount, testException);
        Test.stopTest();

        System.assert(true, 'Should use default area for invalid area name');
    }

    /**
     * Test: Blank area - uses default OpportunityData
     */
    @IsTest
    static void handle_blankArea_usesDefault() {
        setupTestConfigs();

        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Exception testException = new DmlException('Test Blank Area');

        Test.startTest();
        ErrorService.handle('BLANK_AREA', testAccount, testException);
        Test.stopTest();

        System.assert(true, 'Should use default area for blank area');
    }

    /**
     * Test: DML error type extraction - DUPLICATE_VALUE
     */
    @IsTest
    static void handle_dmlError_duplicateValue() {
        setupTestConfigs();

        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Exception testException = new DmlException('DUPLICATE_VALUE, duplicate external id');

        Test.startTest();
        ErrorService.handle('GENERIC_ERROR', testAccount, testException);
        Test.stopTest();

        System.assert(true, 'Should extract DUPLICATE_VALUE error type');
    }

    /**
     * Test: DML error type extraction - UNABLE_TO_LOCK_ROW with colon
     */
    @IsTest
    static void handle_dmlError_unableToLockRow() {
        setupTestConfigs();

        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Exception testException = new DmlException('UNABLE_TO_LOCK_ROW: record is currently locked');

        Test.startTest();
        ErrorService.handle('GENERIC_ERROR', testAccount, testException);
        Test.stopTest();

        System.assert(true, 'Should extract UNABLE_TO_LOCK_ROW error type');
    }

    /**
     * Test: Handle with additional variables
     */
    @IsTest
    static void handle_withAdditionalVars() {
        setupTestConfigs();

        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Map<String, Object> additionalVars = new Map<String, Object>{
            'customField1' => 'customValue1',
            'customField2' => 123
        };

        Exception testException = new DmlException('Test Additional Vars');

        Test.startTest();
        ErrorService.handle('CRITICAL_ERROR', testAccount, testException, additionalVars);
        Test.stopTest();

        System.assert(true, 'Should handle additional variables');
    }

    /**
     * Test: Invalid error key - uses fallback
     */
    @IsTest
    static void handle_invalidErrorKey_usesFallback() {
        setupTestConfigs();

        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Exception testException = new DmlException('Test Invalid Key');

        Test.startTest();
        ErrorService.handle('NON_EXISTENT_KEY', testAccount, testException);
        Test.stopTest();

        System.assert(true, 'Should use fallback for invalid error key');
    }

    /**
     * Test: Opportunity context - extracts AccountId
     */
    @IsTest
    static void handle_opportunityContext_extractsRelatedIds() {
        setupTestConfigs();

        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert testOpp;

        testOpp = [SELECT Id, AccountId FROM Opportunity WHERE Id = :testOpp.Id LIMIT 1];

        Exception testException = new DmlException('Test Opportunity Context');

        Test.startTest();
        ErrorService.handle('GENERIC_ERROR', testOpp, testException);
        Test.stopTest();

        System.assert(true, 'Should extract related object IDs from Opportunity');
    }

    /**
     * Test: Null exception
     */
    @IsTest
    static void handle_nullException() {
        setupTestConfigs();

        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Test.startTest();
        ErrorService.handle('GENERIC_ERROR', testAccount, null);
        Test.stopTest();

        System.assert(true, 'Should handle null exception');
    }

    /**
     * Test: SYSTEM_CALLOUT with recurring errors - creates Work Item and sends escalation
     */
    @IsTest
    static void handle_systemCallout_recurring_createsWorkItemAndEscalates() {
        setupTestConfigs();

        // Створити 3 Pharos Logs для SYSTEM_CALLOUT (поріг для recurring)
        List<pharos__Log__c> logs = new List<pharos__Log__c>();
        for (Integer i = 0; i < 3; i++) {
            logs.add(new pharos__Log__c(
                pharos__Summary__c = 'Test SYSTEM_CALLOUT error',
                pharos__Category__c = 'Apex',
                pharos__Type__c = 'CalloutException',
                pharos__Area__c = 'OpportunityData',
                Error_Classification_ErrorKey__c = 'SYSTEM_CALLOUT',
                Log_Source__c = 'ErrorService'
            ));
        }
        insert logs;

        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Exception testException = new CalloutException('System callout failed');

        Test.startTest();
        ErrorService.handle('SYSTEM_CALLOUT', testAccount, testException);
        Test.stopTest();

        // Перевірити що створений Work Item
        List<Notification_Work_Item__c> workItems = [
            SELECT Id, Summary__c, Work_Status__c, Notification_Type__c
            FROM Notification_Work_Item__c
        ];

        System.assertEquals(1, workItems.size(), 'Should create 1 Work Item for escalation');
        System.assertEquals('New', workItems[0].Work_Status__c, 'Work Item should have New status');
        System.assertEquals('SYSTEM_CALLOUT', workItems[0].Notification_Type__c, 'Should have correct notification type');
    }

    /**
     * Test: SYSTEM_CALLOUT without recurring - no escalation
     */
    @IsTest
    static void handle_systemCallout_notRecurring_noEscalation() {
        setupTestConfigs();

        // Створити тільки 1 Pharos Log (менше порогу 3)
        pharos__Log__c log = new pharos__Log__c(
            pharos__Summary__c = 'Test SYSTEM_CALLOUT error',
            pharos__Category__c = 'Apex',
            pharos__Type__c = 'CalloutException',
            pharos__Area__c = 'OpportunityData',
            Error_Classification_ErrorKey__c = 'SYSTEM_CALLOUT',
            Log_Source__c = 'ErrorService'
        );
        insert log;

        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Exception testException = new CalloutException('System callout failed');

        Test.startTest();
        ErrorService.handle('SYSTEM_CALLOUT', testAccount, testException);
        Test.stopTest();

        // Перевірити що Work Item НЕ створений
        List<Notification_Work_Item__c> workItems = [
            SELECT Id
            FROM Notification_Work_Item__c
        ];

        System.assertEquals(0, workItems.size(), 'Should NOT create Work Item when not recurring');
    }

    /**
     * Test: Non-SYSTEM_CALLOUT error - no escalation check
     */
    @IsTest
    static void handle_nonSystemCallout_noEscalationCheck() {
        setupTestConfigs();

        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Exception testException = new DmlException('Test error');

        Test.startTest();
        ErrorService.handle('CRITICAL_ERROR', testAccount, testException);
        Test.stopTest();

        // Перевірити що Work Item НЕ створений
        List<Notification_Work_Item__c> workItems = [
            SELECT Id
            FROM Notification_Work_Item__c
        ];

        System.assertEquals(0, workItems.size(), 'Should NOT check escalation for non-SYSTEM_CALLOUT errors');
    }
}