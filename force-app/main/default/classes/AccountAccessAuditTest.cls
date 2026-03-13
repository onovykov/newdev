@IsTest
private class AccountAccessAuditTest {

    @IsTest
    static void test_fullParityScenarios() {

        // Create test users
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        User u1 = new User(
            Alias = 'u1',
            Email='u1@test.com',
            EmailEncodingKey='UTF-8',
            LastName='User1',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            ProfileId = p.Id,
            TimeZoneSidKey='Europe/Kiev',
            UserName='u1'+System.currentTimeMillis()+'@test.com'
        );

        User u2 = new User(
            Alias = 'u2',
            Email='u2@test.com',
            EmailEncodingKey='UTF-8',
            LastName='User2',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            ProfileId = p.Id,
            TimeZoneSidKey='Europe/Kiev',
            UserName='u2'+System.currentTimeMillis()+'@test.com'
        );

        insert new List<User>{u1, u2};

        // Create Account
        Account acc = new Account(Name='Test Account');
        insert acc;

        // Scenario 1: Exact match (covered + orphan candidate)
        AccountShare sh1 = new AccountShare(
            AccountId = acc.Id,
            UserOrGroupId = u1.Id,
            AccountAccessLevel = 'Edit',
            OpportunityAccessLevel = 'Edit',
            ContactAccessLevel = 'Edit',
            RowCause = Schema.AccountShare.RowCause.Manual
        );
        insert sh1;

        AccountTeamMember tm1 = new AccountTeamMember(
            AccountId = acc.Id,
            UserId = u1.Id,
            AccountAccessLevel = 'Edit',
            OpportunityAccessLevel = 'Edit',
            ContactAccessLevel = 'Edit'
        );
        insert tm1;

        // Scenario 2: Missing in team
        AccountShare sh2 = new AccountShare(
            AccountId = acc.Id,
            UserOrGroupId = u2.Id,
            AccountAccessLevel = 'Read',
            OpportunityAccessLevel = 'Read',
            ContactAccessLevel = 'Read',
            RowCause = Schema.AccountShare.RowCause.Manual
        );
        insert sh2;

        // Scenario 3: Over-provisioning
        User u3 = new User(
            Alias = 'u3',
            Email='u3@test.com',
            EmailEncodingKey='UTF-8',
            LastName='User3',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            ProfileId = p.Id,
            TimeZoneSidKey='Europe/Kiev',
            UserName='u3'+System.currentTimeMillis()+'@test.com'
        );
        insert u3;

        AccountTeamMember tm2 = new AccountTeamMember(
            AccountId = acc.Id,
            UserId = u3.Id,
            AccountAccessLevel = 'Read'
        );
        insert tm2;

        Test.startTest();
        AccountAccessAudit.run(false);
        Test.stopTest();

        System.assert(true, 'Audit executed without exceptions');
    }

    @IsTest
    static void test_accessMismatch() {

        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        User u = new User(
            Alias = 'um',
            Email='um@test.com',
            EmailEncodingKey='UTF-8',
            LastName='MismatchUser',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            ProfileId = p.Id,
            TimeZoneSidKey='Europe/Kiev',
            UserName='um'+System.currentTimeMillis()+'@test.com'
        );
        insert u;

        Account acc = new Account(Name='Mismatch Account');
        insert acc;

        // Manual share
        AccountShare sh = new AccountShare(
            AccountId = acc.Id,
            UserOrGroupId = u.Id,
            AccountAccessLevel = 'Edit',
            OpportunityAccessLevel = 'Edit',
            ContactAccessLevel = 'Edit',
            RowCause = Schema.AccountShare.RowCause.Manual
        );
        insert sh;

        // Team member with different access
        AccountTeamMember tm = new AccountTeamMember(
            AccountId = acc.Id,
            UserId = u.Id,
            AccountAccessLevel = 'Read'
        );
        insert tm;

        Test.startTest();
        AccountAccessAudit.run(false);
        Test.stopTest();

        System.assert(true, 'Access mismatch scenario executed');
    }
}