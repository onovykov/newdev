@IsTest
private class OppDataErrorRecipientFallbackTest {

    @IsTest
    static void testResolve_UsesPermissionSetFallback() {

        // отримуємо PermissionSet
        PermissionSet ps = [
            SELECT Id
            FROM PermissionSet
            WHERE Name = 'ErrorNotification'
            LIMIT 1
        ];

        // створюємо користувача
        Profile p = [
            SELECT Id FROM Profile
            WHERE Name = 'Standard User'
            LIMIT 1
        ];

        User u = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@test.com',
            Username = 'testuser' + System.currentTimeMillis() + '@test.com',
            Alias = 'tuser',
            TimeZoneSidKey = 'Europe/Kiev',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id
        );

        insert u;

        // прив'язуємо PermissionSet
        insert new PermissionSetAssignment(
            AssigneeId = u.Id,
            PermissionSetId = ps.Id
        );

        // тестуємо
        IntegrationErrorContext ctx = new IntegrationErrorContext();
        ctx.salesRepEmail = null;
        ctx.bosEmail = null;

        Set<String> recipients =
            IntegrationErrorRecipientResolver.resolve(ctx);

        System.assert(!recipients.isEmpty(),
            'Fallback recipients should be resolved from PermissionSet');
    }
}