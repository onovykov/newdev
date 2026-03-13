@IsTest
private class NotificationResolverTraceTest {

    @TestSetup
    static void setupTestData() {
        // Створюємо тестові дані
        Account acc1 = new Account(Name = 'Test Account 1');
        Account acc2 = new Account(Name = 'Test Account 2');
        insert new List<Account>{ acc1, acc2 };

        Opportunity opp1 = new Opportunity(
            Name = 'Test Opportunity 1',
            AccountId = acc1.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        Opportunity opp2 = new Opportunity(
            Name = 'Test Opportunity 2',
            AccountId = acc2.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(60)
        );
        insert new List<Opportunity>{ opp1, opp2 };
    }

    // =====================================================
    // ТЕСТИ ДЛЯ put() МЕТОДУ
    // =====================================================

    @IsTest
    static void testPut_ValidAccountContext() {
        // Arrange
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account 1' LIMIT 1];
        String trace = 'Account trace: resolved 5 users';

        // Act
        Test.startTest();
        NotificationResolverTrace.put(acc, trace);
        Test.stopTest();

        // Assert
        String retrieved = NotificationResolverTrace.get(acc);
        System.assertEquals(trace, retrieved, 'Trace should be stored and retrieved correctly');
    }

    @IsTest
    static void testPut_ValidOpportunityContext() {
        // Arrange
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity 1' LIMIT 1];
        String trace = 'Opportunity trace: OPP_OWNER +1 | ACCOUNT_OWNER +1';

        // Act
        Test.startTest();
        NotificationResolverTrace.put(opp, trace);
        Test.stopTest();

        // Assert
        String retrieved = NotificationResolverTrace.get(opp);
        System.assertEquals(trace, retrieved, 'Trace should be stored for Opportunity');
    }

    @IsTest
    static void testPut_NullContext() {
        // Arrange
        String trace = 'Some trace';

        // Act
        Test.startTest();
        NotificationResolverTrace.put(null, trace);
        Test.stopTest();

        // Assert - не повинно впасти
        System.assert(true, 'Should handle null context gracefully');
    }

    @IsTest
    static void testPut_ContextWithoutId() {
        // Arrange
        Account acc = new Account(Name = 'Not Inserted Account');
        String trace = 'Some trace';

        // Act
        Test.startTest();
        NotificationResolverTrace.put(acc, trace);
        Test.stopTest();

        // Assert - не повинно зберегти, бо немає Id
        String retrieved = NotificationResolverTrace.get(acc);
        System.assertEquals(null, retrieved, 'Should not store trace without Id');
    }

    @IsTest
    static void testPut_NullTrace() {
        // Arrange
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account 1' LIMIT 1];

        // Act
        Test.startTest();
        NotificationResolverTrace.put(acc, null);
        Test.stopTest();

        // Assert
        String retrieved = NotificationResolverTrace.get(acc);
        System.assertEquals(null, retrieved, 'Should not store null trace');
    }

    @IsTest
    static void testPut_BlankTrace() {
        // Arrange
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account 1' LIMIT 1];

        // Act
        Test.startTest();
        NotificationResolverTrace.put(acc, '');
        NotificationResolverTrace.put(acc, '   ');
        Test.stopTest();

        // Assert
        String retrieved = NotificationResolverTrace.get(acc);
        System.assertEquals(null, retrieved, 'Should not store blank trace');
    }

    @IsTest
    static void testPut_OverwriteExistingTrace() {
        // Arrange
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account 1' LIMIT 1];
        String trace1 = 'First trace';
        String trace2 = 'Second trace';

        // Act
        Test.startTest();
        NotificationResolverTrace.put(acc, trace1);
        String afterFirst = NotificationResolverTrace.get(acc);
        NotificationResolverTrace.put(acc, trace2);
        String afterSecond = NotificationResolverTrace.get(acc);
        Test.stopTest();

        // Assert
        System.assertEquals(trace1, afterFirst, 'First trace should be stored');
        System.assertEquals(trace2, afterSecond, 'Second trace should overwrite first');
    }

    @IsTest
    static void testPut_LongTrace() {
        // Arrange
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account 1' LIMIT 1];
        String longTrace = 'GROUP1: Users OPP_OWNER +1 | ' +
                          'GROUP2: Users ACCOUNT_OWNER +1 | ' +
                          'GROUP3: Users SYSADMINS +3 | ' +
                          'GROUP4: Contacts IT_ADMIN +5 | ' +
                          'GROUP5: Emails +10';

        // Act
        Test.startTest();
        NotificationResolverTrace.put(acc, longTrace);
        Test.stopTest();

        // Assert
        String retrieved = NotificationResolverTrace.get(acc);
        System.assertEquals(longTrace, retrieved, 'Should handle long trace strings');
    }

    @IsTest
    static void testPut_SpecialCharacters() {
        // Arrange
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account 1' LIMIT 1];
        String trace = 'Trace with special chars: | +5 | & < > " \' @ # $ %';

        // Act
        Test.startTest();
        NotificationResolverTrace.put(acc, trace);
        Test.stopTest();

        // Assert
        String retrieved = NotificationResolverTrace.get(acc);
        System.assertEquals(trace, retrieved, 'Should handle special characters');
    }

    // =====================================================
    // ТЕСТИ ДЛЯ get() МЕТОДУ
    // =====================================================

    @IsTest
    static void testGet_ExistingTrace() {
        // Arrange
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account 1' LIMIT 1];
        String trace = 'Existing trace';
        NotificationResolverTrace.put(acc, trace);

        // Act
        Test.startTest();
        String retrieved = NotificationResolverTrace.get(acc);
        Test.stopTest();

        // Assert
        System.assertEquals(trace, retrieved, 'Should retrieve existing trace');
    }

    @IsTest
    static void testGet_NonExistingTrace() {
        // Arrange
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account 1' LIMIT 1];

        // Act
        Test.startTest();
        String retrieved = NotificationResolverTrace.get(acc);
        Test.stopTest();

        // Assert
        System.assertEquals(null, retrieved, 'Should return null for non-existing trace');
    }

    @IsTest
    static void testGet_NullContext() {
        // Act
        Test.startTest();
        String retrieved = NotificationResolverTrace.get(null);
        Test.stopTest();

        // Assert
        System.assertEquals(null, retrieved, 'Should return null for null context');
    }

    @IsTest
    static void testGet_ContextWithoutId() {
        // Arrange
        Account acc = new Account(Name = 'Not Inserted Account');

        // Act
        Test.startTest();
        String retrieved = NotificationResolverTrace.get(acc);
        Test.stopTest();

        // Assert
        System.assertEquals(null, retrieved, 'Should return null for context without Id');
    }

    @IsTest
    static void testGet_AfterMultiplePuts() {
        // Arrange
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account 1' LIMIT 1];
        String finalTrace = 'Final trace';

        NotificationResolverTrace.put(acc, 'First');
        NotificationResolverTrace.put(acc, 'Second');
        NotificationResolverTrace.put(acc, finalTrace);

        // Act
        Test.startTest();
        String retrieved = NotificationResolverTrace.get(acc);
        Test.stopTest();

        // Assert
        System.assertEquals(finalTrace, retrieved, 'Should return last stored trace');
    }

    // =====================================================
    // INTEGRATION ТЕСТИ
    // =====================================================

    @IsTest
    static void testMultipleContexts_Independent() {
        // Arrange
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account 1' LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity 1' LIMIT 1];

        String accTrace = 'Account trace';
        String oppTrace = 'Opportunity trace';

        // Act
        Test.startTest();
        NotificationResolverTrace.put(acc, accTrace);
        NotificationResolverTrace.put(opp, oppTrace);

        String retrievedAcc = NotificationResolverTrace.get(acc);
        String retrievedOpp = NotificationResolverTrace.get(opp);
        Test.stopTest();

        // Assert
        System.assertEquals(accTrace, retrievedAcc, 'Account trace should be independent');
        System.assertEquals(oppTrace, retrievedOpp, 'Opportunity trace should be independent');
    }

    @IsTest
    static void testMultipleSameTypeContexts() {
        // Arrange
        List<Account> accounts = [SELECT Id FROM Account ORDER BY Name];
        String trace1 = 'Trace for account 1';
        String trace2 = 'Trace for account 2';

        // Act
        Test.startTest();
        NotificationResolverTrace.put(accounts[0], trace1);
        NotificationResolverTrace.put(accounts[1], trace2);

        String retrieved1 = NotificationResolverTrace.get(accounts[0]);
        String retrieved2 = NotificationResolverTrace.get(accounts[1]);
        Test.stopTest();

        // Assert
        System.assertEquals(trace1, retrieved1, 'First account trace should be correct');
        System.assertEquals(trace2, retrieved2, 'Second account trace should be correct');
    }

    @IsTest
    static void testPutAndGet_Workflow() {
        // Arrange
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account 1' LIMIT 1];

        // Act & Assert - симулюємо реальний workflow
        Test.startTest();

        // Спочатку нічого немає
        String initial = NotificationResolverTrace.get(acc);
        System.assertEquals(null, initial, 'Initially should be null');

        // Додаємо trace
        NotificationResolverTrace.put(acc, 'Processing started');
        String afterPut = NotificationResolverTrace.get(acc);
        System.assertEquals('Processing started', afterPut, 'Trace should be stored');

        // Оновлюємо trace
        NotificationResolverTrace.put(acc, 'Processing completed: 10 recipients');
        String afterUpdate = NotificationResolverTrace.get(acc);
        System.assertEquals('Processing completed: 10 recipients', afterUpdate, 'Trace should be updated');

        Test.stopTest();
    }

    @IsTest
    static void testMixedSObjectTypes() {
        // Arrange
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account 1' LIMIT 1];
        Opportunity opp1 = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity 1' LIMIT 1];
        Opportunity opp2 = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity 2' LIMIT 1];

        // Act
        Test.startTest();
        NotificationResolverTrace.put(acc, 'Account resolved: 5 users');
        NotificationResolverTrace.put(opp1, 'Opp1 resolved: 3 users');
        NotificationResolverTrace.put(opp2, 'Opp2 resolved: 7 users');

        String accTrace = NotificationResolverTrace.get(acc);
        String opp1Trace = NotificationResolverTrace.get(opp1);
        String opp2Trace = NotificationResolverTrace.get(opp2);
        Test.stopTest();

        // Assert
        System.assertEquals('Account resolved: 5 users', accTrace, 'Account trace should be correct');
        System.assertEquals('Opp1 resolved: 3 users', opp1Trace, 'Opp1 trace should be correct');
        System.assertEquals('Opp2 resolved: 7 users', opp2Trace, 'Opp2 trace should be correct');
    }

    @IsTest
    static void testReloadedContext_SameId() {
        // Arrange
        Account acc1 = [SELECT Id FROM Account WHERE Name = 'Test Account 1' LIMIT 1];
        String trace = 'Original trace';
        NotificationResolverTrace.put(acc1, trace);

        // Reload same account (simulates re-query)
        Account acc2 = [SELECT Id FROM Account WHERE Id = :acc1.Id];

        // Act
        Test.startTest();
        String retrieved = NotificationResolverTrace.get(acc2);
        Test.stopTest();

        // Assert
        System.assertEquals(trace, retrieved, 'Should retrieve trace using reloaded object with same Id');
    }

    @IsTest
    static void testBulkOperations() {
        // Arrange
        List<Opportunity> opps = [SELECT Id FROM Opportunity ORDER BY Name];

        // Act
        Test.startTest();
        for (Integer i = 0; i < opps.size(); i++) {
            NotificationResolverTrace.put(opps[i], 'Trace ' + i);
        }

        List<String> retrievedTraces = new List<String>();
        for (Opportunity opp : opps) {
            retrievedTraces.add(NotificationResolverTrace.get(opp));
        }
        Test.stopTest();

        // Assert
        for (Integer i = 0; i < retrievedTraces.size(); i++) {
            System.assertEquals('Trace ' + i, retrievedTraces[i], 'Trace ' + i + ' should be correct');
        }
    }

    // =====================================================
    // EDGE CASES
    // =====================================================

    @IsTest
    static void testPut_EmptyString() {
        // Arrange
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account 1' LIMIT 1];

        // Act
        Test.startTest();
        NotificationResolverTrace.put(acc, '');
        String retrieved = NotificationResolverTrace.get(acc);
        Test.stopTest();

        // Assert
        System.assertEquals(null, retrieved, 'Empty string should not be stored');
    }

    @IsTest
    static void testPut_WhitespaceOnly() {
        // Arrange
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account 1' LIMIT 1];

        // Act
        Test.startTest();
        NotificationResolverTrace.put(acc, '     ');
        String retrieved = NotificationResolverTrace.get(acc);
        Test.stopTest();

        // Assert
        System.assertEquals(null, retrieved, 'Whitespace-only string should not be stored');
    }

    @IsTest
    static void testPut_SingleCharacter() {
        // Arrange
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account 1' LIMIT 1];

        // Act
        Test.startTest();
        NotificationResolverTrace.put(acc, 'x');
        String retrieved = NotificationResolverTrace.get(acc);
        Test.stopTest();

        // Assert
        System.assertEquals('x', retrieved, 'Single character should be stored');
    }

    @IsTest
    static void testSequentialOperations() {
        // Arrange
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account 1' LIMIT 1];

        // Act & Assert
        Test.startTest();

        // Операція 1
        NotificationResolverTrace.put(acc, 'Step 1');
        System.assertEquals('Step 1', NotificationResolverTrace.get(acc), 'Step 1 should be stored');

        // Операція 2
        NotificationResolverTrace.put(acc, 'Step 2');
        System.assertEquals('Step 2', NotificationResolverTrace.get(acc), 'Step 2 should overwrite Step 1');

        // Операція 3
        NotificationResolverTrace.put(acc, 'Step 3');
        System.assertEquals('Step 3', NotificationResolverTrace.get(acc), 'Step 3 should overwrite Step 2');

        Test.stopTest();
    }

    @IsTest
    static void testCaseSensitivity() {
        // Arrange
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account 1' LIMIT 1];
        String lowerCase = 'lowercase trace';
        String upperCase = 'UPPERCASE TRACE';
        String mixedCase = 'MiXeD CaSe TrAcE';

        // Act
        Test.startTest();
        NotificationResolverTrace.put(acc, lowerCase);
        System.assertEquals(lowerCase, NotificationResolverTrace.get(acc), 'Lowercase should be preserved');

        NotificationResolverTrace.put(acc, upperCase);
        System.assertEquals(upperCase, NotificationResolverTrace.get(acc), 'Uppercase should be preserved');

        NotificationResolverTrace.put(acc, mixedCase);
        System.assertEquals(mixedCase, NotificationResolverTrace.get(acc), 'Mixed case should be preserved');
        Test.stopTest();
    }
}