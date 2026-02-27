@IsTest
private class ExternalIdCacheTest {

    private static final String SETTINGS_DEV_NAME = 'local_OrderItemCache';
    private static final String OBJ = 'OrderItem';
    private static final String EXT_FIELD = 'ITENumber__c';

    @TestSetup
    static void setup() {
        // ---- Account
        Account acc = new Account(Name = 'T-Acc');
        insert acc;

        // ---- Product
        Product2 p = new Product2(Name = 'T-Prod', IsActive = true);
        insert p;

        // ---- Standard Pricebook + PBE
        Id stdPbId = Test.getStandardPricebookId();
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = stdPbId,
            Product2Id   = p.Id,
            UnitPrice    = 10,
            IsActive     = true
        );
        insert pbe;

        // ---- Order
        Order o = new Order(
            AccountId     = acc.Id,
            EffectiveDate = Date.today(),
            Status        = 'Draft',
            Pricebook2Id  = stdPbId
        );
        insert o;

        // ---- OrderItems with unique ITENumber__c
        List<OrderItem> items = new List<OrderItem>();
        items.add(new OrderItem(
            OrderId = o.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = 10,
            ITENumber__c = 'T-ITE-001'
        ));
        items.add(new OrderItem(
            OrderId = o.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 2,
            UnitPrice = 10,
            ITENumber__c = 'T-ITE-002'
        ));
        insert items;
    }

    @IsTest
    static void test_getOne_found() {
        ExternalIdCache cache =
            ExternalIdCache.forObject(OBJ, EXT_FIELD, SETTINGS_DEV_NAME);

        Id id1 = cache.getOne('T-ITE-001');
        System.assertNotEquals(null, id1, 'Expected existing OrderItem Id');
    }

    @IsTest
    static void test_getOne_notFound_negativeAllowed_returnsNull() {
        ExternalIdCache cache =
            ExternalIdCache.forObject(OBJ, EXT_FIELD, SETTINGS_DEV_NAME);

        Id idX = cache.getOne('T-ITE-DOES-NOT-EXIST');
        System.assertEquals(null, idX, 'Expected null for non-existing external id');
    }

    @IsTest
    static void test_getMany_mixed_found_and_notFound_negativeAllowed() {
        ExternalIdCache cache =
            ExternalIdCache.forObject(OBJ, EXT_FIELD, SETTINGS_DEV_NAME);

        Set<String> keys = new Set<String>{
            'T-ITE-001',
            'T-ITE-002',
            'T-ITE-404'
        };

        Map<String, Id> mapMany = cache.getMany(keys, true);

        System.assertEquals(true, mapMany.containsKey('T-ITE-001'), 'Must contain key 001');
        System.assertEquals(true, mapMany.containsKey('T-ITE-002'), 'Must contain key 002');
        System.assertEquals(true, mapMany.containsKey('T-ITE-404'), 'Must contain key 404 (negative cache)');

        System.assertNotEquals(null, mapMany.get('T-ITE-001'), '001 must resolve to Id');
        System.assertNotEquals(null, mapMany.get('T-ITE-002'), '002 must resolve to Id');
        System.assertEquals(null, mapMany.get('T-ITE-404'), '404 must resolve to null when negative cache enabled');
    }

    @IsTest
    static void test_getMany_notFound_negativeDisabled_doesNotContainMissing() {
        ExternalIdCache cache =
            ExternalIdCache.forObject(OBJ, EXT_FIELD, SETTINGS_DEV_NAME);

        Set<String> keys = new Set<String>{
            'T-ITE-001',
            'T-ITE-404'
        };

        Map<String, Id> mapCache = cache.getMany(keys, false);

        System.assertEquals(true, mapCache.containsKey('T-ITE-001'));
        System.assertEquals(false, mapCache.containsKey('T-ITE-404'),
            'When allowNegativeCache=false missing keys should not be present in map');
    }

    @IsTest
    static void test_invalidate_doesNotThrow() {
        ExternalIdCache cache =
            ExternalIdCache.forObject(OBJ, EXT_FIELD, SETTINGS_DEV_NAME);

        // We do NOT assert cache effects (Platform Cache may be unavailable in tests)
        // We only assert that invalidate is safe and never throws.
        Test.startTest();
        cache.invalidate('T-ITE-001');
        cache.invalidate('T-ITE-404');
        Test.stopTest();

        System.assert(true, 'invalidate should be safe');
    }

    @IsTest
    static void test_blank_inputs() {
        ExternalIdCache cache =
            ExternalIdCache.forObject(OBJ, EXT_FIELD, SETTINGS_DEV_NAME);

        System.assertEquals(null, cache.getOne(null));
        System.assertEquals(null, cache.getOne(''));

        Map<String, Id> empty1 = cache.getMany(null, true);
        Map<String, Id> empty2 = cache.getMany(new Set<String>(), true);

        System.assertEquals(0, empty1.size());
        System.assertEquals(0, empty2.size());
    }
}