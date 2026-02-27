@IsTest
private class CacheSettingsProviderTest {

    @IsTest
    static void test_load_returns_defaults_when_missing() {
        CacheSettingsProvider.CacheSettings cfg =
            CacheSettingsProvider.load('DOES_NOT_EXIST');

        System.assertNotEquals(null, cfg);
        System.assertNotEquals(null, cfg.cacheName);
        System.assertNotEquals(null, cfg.keyPrefix);
        System.assertNotEquals(null, cfg.shardLen);
        System.assertNotEquals(null, cfg.ttlSuccess);
        System.assertNotEquals(null, cfg.ttlNegative);
    }
}