@IsTest
private class OppDataErrorRecipient_EmptyEmails_Test {

    @IsTest
    static void testResolve_BothEmailsEmpty() {

        IntegrationErrorContext ctx = new IntegrationErrorContext();
        ctx.salesRepEmail = null;
        ctx.bosEmail = null;

        Set<String> recipients =
            IntegrationErrorRecipientResolver.resolve(ctx);

        System.assert(!recipients.isEmpty(),
            'Should fallback when both emails are empty');
    }

    @IsTest
    static void testResolve_OneValidOneInvalid() {

        IntegrationErrorContext ctx = new IntegrationErrorContext();
        ctx.salesRepEmail = 'valid@test.com';
        ctx.bosEmail = 'bad_email';

        Set<String> recipients =
            IntegrationErrorRecipientResolver.resolve(ctx);

        System.assertEquals(1, recipients.size());
    }    
}