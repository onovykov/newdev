@IsTest
private class OppDataErrorRecipient_NullCtx_Test {

    @IsTest
    static void testResolve_NullContext() {

        Set<String> recipients =
            IntegrationErrorRecipientResolver.resolve(null);

        System.assertNotEquals(null, recipients);
        System.assert(!recipients.isEmpty(),
            'Fallback should be used when ctx is null');
    }
}