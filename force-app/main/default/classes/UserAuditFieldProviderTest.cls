@IsTest
private class UserAuditFieldProviderTest {

    @IsTest
    static void testCacheIsUsedAndCleared() {

        // 1) перший виклик — завантаження з CMDT
        Set<String> fields1 =
            UserAuditFieldProvider.getEnabledFields();

        System.assert(
            !fields1.isEmpty(),
            'Enabled fields must be loaded from CMDT'
        );

        // 2) другий виклик — має піти з кешу
        Set<String> fields2 =
            UserAuditFieldProvider.getEnabledFields();

        System.assertEquals(
            fields1,
            fields2,
            'Second call must return cached fields'
        );

        // 3) очищаємо кеш (покриваємо clearCache)
        UserAuditFieldProvider.clearCache();

        // 4) повторний виклик після clearCache
        Set<String> fields3 =
            UserAuditFieldProvider.getEnabledFields();

        System.assertEquals(
            fields1,
            fields3,
            'Fields after cache clear must reload correctly'
        );
    }
}