@IsTest
private class AccountTeamCanonicalMigrationServiceTest  {

    private static User createUser(String email) {
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];

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
    static void test_full_logic() {

        User owner = createUser('owner@test.com');
        User sales = createUser('sales@test.com');
        User bos = createUser('bos@test.com');

        Account acc = new Account(
            Name = 'Test Acc',
            OwnerId = owner.Id
        );
        insert acc;

        // Existing READ team member to test upgrade
        AccountTeamMember existing = new AccountTeamMember(
            AccountId = acc.Id,
            UserId = sales.Id,
            TeamMemberRole = 'BO Specialist',
            AccountAccessLevel = 'Read',
            OpportunityAccessLevel = 'Read',
            ContactAccessLevel = 'Read',
            CaseAccessLevel = 'None'
        );
        insert existing;

        AccountSalesSegmentation__c seg =
            new AccountSalesSegmentation__c(
                Account__c = acc.Id,
                Manager__c = sales.Id
            );

        AccountBOS__c bosRec =
            new AccountBOS__c(
                Account__c = acc.Id,
                User__c = bos.Id
            );

        insert seg;
        insert bosRec;

        AccountTeamCanonicalMigrationService.Config cfg =
            new AccountTeamCanonicalMigrationService.Config();
        cfg.isDryRun = false;

        Test.startTest();

        AccountTeamCanonicalMigrationResult res =
            AccountTeamCanonicalMigrationService.process(
                new List<AccountSalesSegmentation__c>{ seg },
                new List<AccountBOS__c>{ bosRec },
                cfg
            );

        Test.stopTest();

        System.assertEquals(1, res.upgraded); // sales upgraded
        System.assertEquals(1, res.inserted); // bos inserted

        List<AccountTeamMember> members =
            [SELECT UserId, AccountAccessLevel
             FROM AccountTeamMember
             WHERE AccountId = :acc.Id];

        System.assertEquals(2, members.size());

        for (AccountTeamMember m : members) {
            if (m.UserId == sales.Id) {
                System.assertEquals('Edit', m.AccountAccessLevel);
            }
        }
    }
}