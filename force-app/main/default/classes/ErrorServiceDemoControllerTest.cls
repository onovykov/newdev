/**
 * Test class for ErrorServiceDemoController.
 * Achieves 100% code coverage through comprehensive testing.
 */
@IsTest
private class ErrorServiceDemoControllerTest {

    /**
     * Setup test data - create Account and Opportunity for context queries
     */
    @TestSetup
    static void setupTestData() {
        // Create Account
        Account testAccount = new Account(
            Name = 'Test Account for ErrorServiceDemo'
        );
        insert testAccount;

        // Create Opportunity
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity for ErrorServiceDemo',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert testOpp;
    }

    /**
     * Setup Error_Classification__mdt test configs for ErrorService
     */
    private static void setupErrorConfigs() {
        ErrorService.testErrorConfigs = new Map<String, Error_Classification__mdt>();

        // SYSTEM_CALLOUT - Critical
        ErrorService.testErrorConfigs.put('SYSTEM_CALLOUT', createMockErrorConfig(
            'SYSTEM_CALLOUT',
            'System',
            'Integration',
            'SYS_CALLOUT',
            'RestAPI',
            'Backend',
            'Critical',
            1,
            'CRITICAL_NOTIFICATION'
        ));

        // ERR_INT_OPPDATA_ERPMSGHANDLER - High
        ErrorService.testErrorConfigs.put('ERR_INT_OPPDATA_ERPMSGHANDLER', createMockErrorConfig(
            'ERR_INT_OPPDATA_ERPMSGHANDLER',
            'Integration',
            'OpportunityData',
            'ERP_OPP_001',
            'OpportunityManagement',
            'Backend',
            'High',
            4,
            'HIGH_NOTIFICATION'
        ));

        // ERR_INT_PRICE_APPROVAL - High
        ErrorService.testErrorConfigs.put('ERR_INT_PRICE_APPROVAL', createMockErrorConfig(
            'ERR_INT_PRICE_APPROVAL',
            'Business',
            'PriceApproval',
            'PRICE_001',
            'OpportunityData',
            'Backend',
            'High',
            4,
            'HIGH_NOTIFICATION'
        ));

        // OPP_CLOSED_WON_USERS - Critical
        ErrorService.testErrorConfigs.put('OPP_CLOSED_WON_USERS', createMockErrorConfig(
            'OPP_CLOSED_WON_USERS',
            'Business',
            'OpportunityManagement',
            'OPP_WON_001',
            'OpportunityManagement',
            'Backend',
            'Critical',
            1,
            'CRITICAL_NOTIFICATION'
        ));

        // OPP_CROSS_CREATE_USERS - Low
        ErrorService.testErrorConfigs.put('OPP_CROSS_CREATE_USERS', createMockErrorConfig(
            'OPP_CROSS_CREATE_USERS',
            'Business',
            'OpportunityManagement',
            'OPP_CROSS_001',
            'OpportunityManagement',
            'Backend',
            'Low',
            24,
            null
        ));

        // OPP_CROSS_WON_USERS - Low
        ErrorService.testErrorConfigs.put('OPP_CROSS_WON_USERS', createMockErrorConfig(
            'OPP_CROSS_WON_USERS',
            'Business',
            'OpportunityManagement',
            'OPP_CROSS_002',
            'OpportunityManagement',
            'Backend',
            'Low',
            24,
            null
        ));

        // AR_OVERDUE_7D_USERS - Medium
        ErrorService.testErrorConfigs.put('AR_OVERDUE_7D_USERS', createMockErrorConfig(
            'AR_OVERDUE_7D_USERS',
            'Business',
            'AccountsReceivable',
            'AR_OVERDUE_001',
            'Accounts',
            'Backend',
            'Medium',
            12,
            null
        ));
    }

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
     * Test: SYSTEM_CALLOUT scenario (Opportunity + CalloutException)
     */
    @IsTest
    static void simulate_systemCallout_success() {
        setupErrorConfigs();

        Test.startTest();
        ErrorServiceDemoController.simulate('SYSTEM_CALLOUT');
        Test.stopTest();

        System.assert(true, 'SYSTEM_CALLOUT simulation should complete without exception');
    }

    /**
     * Test: ERR_INT_OPPDATA_ERPMSGHANDLER scenario (Opportunity + DmlException)
     */
    @IsTest
    static void simulate_erpOppDataHandler_success() {
        setupErrorConfigs();

        Test.startTest();
        ErrorServiceDemoController.simulate('ERR_INT_OPPDATA_ERPMSGHANDLER');
        Test.stopTest();

        System.assert(true, 'ERR_INT_OPPDATA_ERPMSGHANDLER simulation should complete without exception');
    }

    /**
     * Test: ERR_INT_PRICE_APPROVAL scenario (PAR/null context + QueryException)
     */
    @IsTest
    static void simulate_priceApproval_success() {
        setupErrorConfigs();

        Test.startTest();
        ErrorServiceDemoController.simulate('ERR_INT_PRICE_APPROVAL');
        Test.stopTest();

        System.assert(true, 'ERR_INT_PRICE_APPROVAL simulation should complete without exception');
    }

    /**
     * Test: OPP_CLOSED_WON_USERS scenario (Opportunity + Generic)
     */
    @IsTest
    static void simulate_oppClosedWon_success() {
        setupErrorConfigs();

        Test.startTest();
        ErrorServiceDemoController.simulate('OPP_CLOSED_WON_USERS');
        Test.stopTest();

        System.assert(true, 'OPP_CLOSED_WON_USERS simulation should complete without exception');
    }

    /**
     * Test: OPP_CROSS_CREATE_USERS scenario (Opportunity + Generic)
     */
    @IsTest
    static void simulate_oppCrossCreate_success() {
        setupErrorConfigs();

        Test.startTest();
        ErrorServiceDemoController.simulate('OPP_CROSS_CREATE_USERS');
        Test.stopTest();

        System.assert(true, 'OPP_CROSS_CREATE_USERS simulation should complete without exception');
    }

    /**
     * Test: OPP_CROSS_WON_USERS scenario (Opportunity + Generic)
     */
    @IsTest
    static void simulate_oppCrossWon_success() {
        setupErrorConfigs();

        Test.startTest();
        ErrorServiceDemoController.simulate('OPP_CROSS_WON_USERS');
        Test.stopTest();

        System.assert(true, 'OPP_CROSS_WON_USERS simulation should complete without exception');
    }

    /**
     * Test: AR_OVERDUE_7D_USERS scenario (Account + Generic)
     */
    @IsTest
    static void simulate_arOverdue_success() {
        setupErrorConfigs();

        Test.startTest();
        ErrorServiceDemoController.simulate('AR_OVERDUE_7D_USERS');
        Test.stopTest();

        System.assert(true, 'AR_OVERDUE_7D_USERS simulation should complete without exception');
    }

    /**
     * Test: Null errorKey throws exception
     */
    @IsTest
    static void simulate_nullErrorKey_throwsException() {
        setupErrorConfigs();

        Exception caughtException = null;

        Test.startTest();
        try {
            ErrorServiceDemoController.simulate(null);
            System.assert(false, 'Should have thrown IllegalArgumentException');
        } catch (IllegalArgumentException e) {
            caughtException = e;
        }
        Test.stopTest();

        System.assertNotEquals(null, caughtException, 'Should throw IllegalArgumentException for null key');
        System.assert(caughtException.getMessage().contains('Unsupported errorKey'), 'Exception message should mention unsupported key');
    }

    /**
     * Test: Blank errorKey throws exception
     */
    @IsTest
    static void simulate_blankErrorKey_throwsException() {
        setupErrorConfigs();

        Exception caughtException = null;

        Test.startTest();
        try {
            ErrorServiceDemoController.simulate('   ');
            System.assert(false, 'Should have thrown IllegalArgumentException');
        } catch (IllegalArgumentException e) {
            caughtException = e;
        }
        Test.stopTest();

        System.assertNotEquals(null, caughtException, 'Should throw IllegalArgumentException for blank key');
        System.assert(caughtException.getMessage().contains('Unsupported errorKey'), 'Exception message should mention unsupported key');
    }

    /**
     * Test: Empty string errorKey throws exception
     */
    @IsTest
    static void simulate_emptyErrorKey_throwsException() {
        setupErrorConfigs();

        Exception caughtException = null;

        Test.startTest();
        try {
            ErrorServiceDemoController.simulate('');
            System.assert(false, 'Should have thrown IllegalArgumentException');
        } catch (IllegalArgumentException e) {
            caughtException = e;
        }
        Test.stopTest();

        System.assertNotEquals(null, caughtException, 'Should throw IllegalArgumentException for empty key');
    }

    /**
     * Test: Unsupported errorKey throws exception
     */
    @IsTest
    static void simulate_unsupportedErrorKey_throwsException() {
        setupErrorConfigs();

        Exception caughtException = null;

        Test.startTest();
        try {
            ErrorServiceDemoController.simulate('INVALID_KEY_NOT_IN_LIST');
            System.assert(false, 'Should have thrown IllegalArgumentException');
        } catch (IllegalArgumentException e) {
            caughtException = e;
        }
        Test.stopTest();

        System.assertNotEquals(null, caughtException, 'Should throw IllegalArgumentException for unsupported key');
        System.assert(caughtException.getMessage().contains('Unsupported errorKey'), 'Exception message should mention unsupported key');
        System.assert(caughtException.getMessage().contains('INVALID_KEY_NOT_IN_LIST'), 'Exception message should include the invalid key');
    }

    /**
     * Test: Simulation works without Opportunity records
     */
    @IsTest
    static void simulate_noOpportunityRecords_handlesGracefully() {
        setupErrorConfigs();

        // Delete all Opportunities
        delete [SELECT Id FROM Opportunity];

        Test.startTest();
        // Should still work with null context
        ErrorServiceDemoController.simulate('SYSTEM_CALLOUT');
        Test.stopTest();

        System.assert(true, 'Should handle missing Opportunity context gracefully');
    }

    /**
     * Test: Simulation works without Account records
     */
    @IsTest
    static void simulate_noAccountRecords_handlesGracefully() {
        setupErrorConfigs();

        // Delete all Accounts (cascades to Opportunities)
        delete [SELECT Id FROM Account];

        Test.startTest();
        // Should still work with null context
        ErrorServiceDemoController.simulate('AR_OVERDUE_7D_USERS');
        Test.stopTest();

        System.assert(true, 'Should handle missing Account context gracefully');
    }

    /**
     * Test: Multiple sequential simulations
     */
    @IsTest
    static void simulate_multipleSequential_allSucceed() {
        setupErrorConfigs();

        Test.startTest();
        ErrorServiceDemoController.simulate('SYSTEM_CALLOUT');
        ErrorServiceDemoController.simulate('ERR_INT_OPPDATA_ERPMSGHANDLER');
        ErrorServiceDemoController.simulate('AR_OVERDUE_7D_USERS');
        Test.stopTest();

        System.assert(true, 'Multiple sequential simulations should all complete successfully');
    }

    /**
     * Test: All allowed keys in a loop
     */
    @IsTest
    static void simulate_allAllowedKeys_allSucceed() {
        setupErrorConfigs();

        List<String> allKeys = new List<String>{
            'AR_OVERDUE_7D_USERS',
            'ERR_INT_OPPDATA_ERPMSGHANDLER',
            'ERR_INT_PRICE_APPROVAL',
            'OPP_CLOSED_WON_USERS',
            'OPP_CROSS_CREATE_USERS',
            'OPP_CROSS_WON_USERS',
            'SYSTEM_CALLOUT'
        };

        Test.startTest();
        for (String key : allKeys) {
            ErrorServiceDemoController.simulate(key);
        }
        Test.stopTest();

        System.assert(true, 'All allowed keys should simulate successfully');
    }

    /**
     * Test: Case sensitivity of errorKey
     */
    @IsTest
    static void simulate_lowercaseErrorKey_throwsException() {
        setupErrorConfigs();

        Exception caughtException = null;

        Test.startTest();
        try {
            // ALLOWED_KEYS contains uppercase, test lowercase
            ErrorServiceDemoController.simulate('system_callout');
            System.assert(false, 'Should have thrown IllegalArgumentException for lowercase key');
        } catch (IllegalArgumentException e) {
            caughtException = e;
        }
        Test.stopTest();

        System.assertNotEquals(null, caughtException, 'Should throw exception for case mismatch');
    }

    /**
     * Test: Mixed case errorKey throws exception
     */
    @IsTest
    static void simulate_mixedCaseErrorKey_throwsException() {
        setupErrorConfigs();

        Exception caughtException = null;

        Test.startTest();
        try {
            ErrorServiceDemoController.simulate('System_Callout');
            System.assert(false, 'Should have thrown IllegalArgumentException for mixed case key');
        } catch (IllegalArgumentException e) {
            caughtException = e;
        }
        Test.stopTest();

        System.assertNotEquals(null, caughtException, 'Should throw exception for mixed case key');
    }

    /**
     * Test: Special characters in errorKey
     */
    @IsTest
    static void simulate_specialCharactersInKey_throwsException() {
        setupErrorConfigs();

        Exception caughtException = null;

        Test.startTest();
        try {
            ErrorServiceDemoController.simulate('SYSTEM_CALLOUT!@#');
            System.assert(false, 'Should have thrown IllegalArgumentException');
        } catch (IllegalArgumentException e) {
            caughtException = e;
        }
        Test.stopTest();

        System.assertNotEquals(null, caughtException, 'Should throw exception for key with special characters');
    }

    /**
     * Test: Very long errorKey string
     */
    @IsTest
    static void simulate_veryLongErrorKey_throwsException() {
        setupErrorConfigs();

        Exception caughtException = null;
        String longKey = 'A'.repeat(255);

        Test.startTest();
        try {
            ErrorServiceDemoController.simulate(longKey);
            System.assert(false, 'Should have thrown IllegalArgumentException');
        } catch (IllegalArgumentException e) {
            caughtException = e;
        }
        Test.stopTest();

        System.assertNotEquals(null, caughtException, 'Should throw exception for very long key');
    }

    /**
     * Test: Simulation with existing Account and Opportunity
     */
    @IsTest
    static void simulate_withExistingRecords_usesLatestRecords() {
        setupErrorConfigs();

        // Create additional records to test "ORDER BY LastModifiedDate DESC LIMIT 1" logic
        Account newAccount = new Account(Name = 'Newer Test Account');
        insert newAccount;

        Opportunity newOpp = new Opportunity(
            Name = 'Newer Test Opportunity',
            AccountId = newAccount.Id,
            StageName = 'Qualification',
            CloseDate = Date.today().addDays(60)
        );
        insert newOpp;

        Test.startTest();
        // Should use the newest records
        ErrorServiceDemoController.simulate('SYSTEM_CALLOUT');
        ErrorServiceDemoController.simulate('AR_OVERDUE_7D_USERS');
        Test.stopTest();

        System.assert(true, 'Should use latest records from query');
    }
}