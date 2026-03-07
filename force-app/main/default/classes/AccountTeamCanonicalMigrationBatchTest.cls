@IsTest
private class AccountTeamCanonicalMigrationBatchTest {

    @IsTest
    static void test_batch_dry_run() {
        // setup data

        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];

        User owner = new User(
            Alias = 'ownr',
            Email = 'owner@test2.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Owner',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'Europe/Paris',
            Username = 'owner2@test.com' + System.currentTimeMillis()
        );
        insert owner;

        User sales = new User(
            Alias = 'sales',
            Email = 'sales@test2.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Sales',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'Europe/Paris',
            Username = 'sales2@test.com' + System.currentTimeMillis()
        );
        insert sales;

        Account acc = new Account(
            Name = 'Batch Acc',
            OwnerId = owner.Id
        );
        insert acc;

        insert new AccountSalesSegmentation__c(
            Account__c = acc.Id,
            Manager__c = sales.Id
        );

        Test.startTest();
        Database.executeBatch(
            new AccountTeamCanonicalMigrationBatch(true),
            50
        );
        Test.stopTest();

        System.assertEquals(
            0,
            [SELECT COUNT() FROM AccountTeamMember WHERE AccountId = :acc.Id]
        );
    }

    @IsTest
    static void test_batch_real_run() {
        // setup data

        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];

        User owner = new User(
            Alias = 'ownr',
            Email = 'owner@test2.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Owner',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'Europe/Paris',
            Username = 'owner2@test.com' + System.currentTimeMillis()
        );
        insert owner;

        User sales = new User(
            Alias = 'sales',
            Email = 'sales@test2.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Sales',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'Europe/Paris',
            Username = 'sales2@test.com' + System.currentTimeMillis()
        );
        insert sales;

        Account acc = new Account(
            Name = 'Batch Acc',
            OwnerId = owner.Id
        );
        insert acc;

        insert new AccountSalesSegmentation__c(
            Account__c = acc.Id,
            Manager__c = sales.Id
        );
        
        Test.startTest();
        Database.executeBatch(
            new AccountTeamCanonicalMigrationBatch(false),
            50
        );
        Test.stopTest();

        System.assertEquals(
            1,
            [SELECT COUNT() FROM AccountTeamMember WHERE AccountId = :acc.Id]
        );
    }
}