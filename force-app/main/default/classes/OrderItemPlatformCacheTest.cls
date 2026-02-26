@IsTest
public class OrderItemPlatformCacheTest {

    // ---------------------------
    // Test data
    // ---------------------------

    private static OrderItem createOrderItem(String ite) {

        // Account
        Account acc = new Account(Name = 'Test Acc ' + ite);
        insert acc;

        // Standard Pricebook
        Id stdPbId = Test.getStandardPricebookId();

        // Order (!!! з Pricebook2Id)
        Order ord = new Order(
            Name = 'Test Order ' + ite,
            AccountId = acc.Id,
            Status = 'Draft',
            EffectiveDate = Date.today(),
            Pricebook2Id = stdPbId
        );
        insert ord;

        // Product
        Product2 p = new Product2(
            Name = 'Test Product ' + ite,
            IsActive = true
        );
        insert p;

        // PricebookEntry
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = stdPbId,
            Product2Id   = p.Id,
            UnitPrice    = 100,
            IsActive     = true
        );
        insert pbe;

        // OrderItem
        OrderItem oi = new OrderItem(
            OrderId = ord.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = 100,
            ITENumber__c = ite
        );
        insert oi;

        return oi;
    }

    // ---------------------------
    // Tests
    // ---------------------------

    @IsTest
    static void test_getMany_basic() {

        OrderItemPlatformCache.invalidateAll();

        OrderItem oi1 = createOrderItem('25-TEST-001');
        OrderItem oi2 = createOrderItem('25-TEST-002');

        Set<String> keys = new Set<String>{
            '25-TEST-001',
            '25-TEST-002'
        };

        Map<String, OrderItem> result =
            OrderItemPlatformCache.getMany(keys);

        System.assertEquals(2, result.size());
        System.assertEquals(oi1.Id, result.get('25-TEST-001').Id);
        System.assertEquals(oi2.Id, result.get('25-TEST-002').Id);
    }

    @IsTest
    static void test_getMany_negativeCache() {

        OrderItemPlatformCache.invalidateAll();

        Set<String> keys = new Set<String>{ 'NOT-EXIST' };

        Map<String, OrderItem> result =
            OrderItemPlatformCache.getMany(keys);

        System.assertEquals(1, result.size());
        System.assertEquals(null, result.get('NOT-EXIST'));
    }

    @IsTest
    static void test_getOne() {

        OrderItemPlatformCache.invalidateAll();

        OrderItem oi = createOrderItem('25-TEST-003');

        OrderItem loaded =
            OrderItemPlatformCache.getOne('25-TEST-003');

        System.assertNotEquals(null, loaded);
        System.assertEquals(oi.Id, loaded.Id);

        System.assertEquals(null,
            OrderItemPlatformCache.getOne(null));
    }

    @IsTest
    static void test_invalidateByIte() {

        OrderItemPlatformCache.invalidateAll();

        OrderItem oi = createOrderItem('25-TEST-004');

        // перше читання — покладе в кеш
        OrderItemPlatformCache.getOne('25-TEST-004');

        // інвалідуємо конкретний ключ
        OrderItemPlatformCache.invalidateByIte(
            new Set<String>{ '25-TEST-004' }
        );

        // має знову нормально читатися
        OrderItem reloaded =
            OrderItemPlatformCache.getOne('25-TEST-004');

        System.assertEquals(oi.Id, reloaded.Id);
    }

    @IsTest
    static void test_invalidateAll() {

        OrderItemPlatformCache.invalidateAll();

        OrderItem oi = createOrderItem('25-TEST-005');

        OrderItemPlatformCache.getOne('25-TEST-005');

        OrderItemPlatformCache.invalidateAll();

        OrderItem reloaded =
            OrderItemPlatformCache.getOne('25-TEST-005');

        System.assertEquals(oi.Id, reloaded.Id);
    }
}