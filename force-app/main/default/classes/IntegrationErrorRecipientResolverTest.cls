@IsTest
private class IntegrationErrorRecipientResolverTest {

    @IsTest
    static void testResolve_UsesJsonEmails() {

        IntegrationErrorContext ctx = new IntegrationErrorContext();
        ctx.salesRepEmail = 'valid@test.com';
        ctx.bosEmail = 'bos@test.com';

        Set<String> recipients =
            IntegrationErrorRecipientResolver.resolve(ctx);

        System.assertEquals(2, recipients.size());
        System.assert(recipients.contains('valid@test.com'));
        System.assert(recipients.contains('bos@test.com'));
    }

    @IsTest
    static void testResolve_InvalidEmails_UsesFallback() {

        IntegrationErrorContext ctx = new IntegrationErrorContext();
        ctx.salesRepEmail = 'bad_email';
        ctx.bosEmail = null;

        Set<String> recipients =
            IntegrationErrorRecipientResolver.resolve(ctx);

        System.assert(!recipients.isEmpty(),
            'Fallback recipients should be used');
    }
}