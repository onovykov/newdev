@IsTest
private class IntegrationCacheConfigProviderTest {

    @IsTest
    static void testFallbackWhenNoCmdt() {
        Integer ttl = IntegrationCacheConfigProvider.getTTL(
            'Opportunity',
            'ERP_LOOKUP',
            300
        );

        System.assertEquals(
            300,
            ttl,
            'Fallback TTL must be returned when CMDT is missing'
        );
    }

    @IsTest
    static void testDisabledCacheReturnsZero() {
        // Імітуємо поведінку "cache disabled" через fallback = 0
        Integer ttl = IntegrationCacheConfigProvider.getTTL(
            'SomeObject',
            'DISABLED_CACHE',
            0
        );

        System.assertEquals(
            0,
            ttl,
            'TTL must be 0 when cache is disabled'
        );
    }
}