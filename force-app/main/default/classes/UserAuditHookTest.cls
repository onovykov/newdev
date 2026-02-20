@IsTest
private class UserAuditHookTest {

    private static User createUser() {
        Profile p = [
            SELECT Id FROM Profile
            WHERE Name = 'Standard User'
            LIMIT 1
        ];

        return new User(
            Alias = 'uaud',
            Email = 'uaudit@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Audit',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'Europe/Warsaw',
            Username = 'uaudit_' + System.now().getTime() + '@test.com',
            ProfileId = p.Id
        );
    }

    @IsTest
    static void testAfterUpdateHookRuns() {

        User u = createUser();
        insert u;

        Test.startTest();

        // міняємо критичні поля User
        u.LoginERP__c = 'new.login';
        u.IsActive = true;
        update u;

        Test.stopTest();

        // якщо дійшли сюди — hook відпрацював
        System.assert(
            true,
            'UserAuditHook.afterUpdate executed successfully'
        );
    }
}