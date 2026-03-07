@IsTest
private class AccTeamCanonicalMigrationAnalyzerTest {

    private static User createUser(String email) {

        Profile p = [
            SELECT Id
            FROM Profile
            WHERE UserType = 'Standard'
            LIMIT 1
        ];

        User u = new User(
            Alias = email.substring(0,5),
            Email = email,
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'Europe/Paris',
            Username = email + System.currentTimeMillis()
        );

        insert u;
        return u;
    }

    @IsTest
    static void test_analyze_all() {

        User owner = createUser('owner@test.com');
        User sales = createUser('sales@test.com');
        User bos   = createUser('bos@test.com');

        Account acc = new Account(
            Name = 'Analyzer Acc',
            OwnerId = owner.Id
        );
        insert acc;

        // Segmentation: sales (valid)
        insert new AccountSalesSegmentation__c(
            Account__c = acc.Id,
            Manager__c = sales.Id
        );

        // Segmentation: owner (should be skipped)
        insert new AccountSalesSegmentation__c(
            Account__c = acc.Id,
            Manager__c = owner.Id
        );

        // BOS
        insert new AccountBOS__c(
            Account__c = acc.Id,
            User__c = bos.Id
        );

        Test.startTest();

        AccountTeamCanonicalMigrationResult res =
            AccountTeamCanonicalMigrationAnalyzer.analyzeAll();

        Test.stopTest();

        // Dry-run → нічого не вставлено
        System.assertEquals(
            0,
            [SELECT COUNT() FROM AccountTeamMember WHERE AccountId = :acc.Id]
        );

        // Перевірка логіки
        System.assert(res.segmentationProcessed > 0);
        System.assert(res.bosProcessed > 0);
        System.assert(res.skippedOwner > 0);

        // Має бути 2 prepared inserts:
        // - sales (Edit)
        // - bos (Read)
        System.assertEquals(2, res.preparedInsert);

        // JSON не null
        String json = res.toPrettyString();
        System.assert(json.contains('segmentationProcessed'));
    }
}