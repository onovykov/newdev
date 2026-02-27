@IsTest
private class OrderItemCacheTest {

    @TestSetup
    static void setup() {
        Account acc = new Account(Name = 'T-Acc');
        insert acc;

        Product2 p = new Product2(Name = 'T-Prod', IsActive = true);
        insert p;

        Id stdPbId = Test.getStandardPricebookId();

        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = stdPbId,
            Product2Id   = p.Id,
            UnitPrice    = 10,
            IsActive     = true
        );
        insert pbe;

        Order o = new Order(
            AccountId     = acc.Id,
            EffectiveDate = Date.today(),
            Status        = 'Draft',
            Pricebook2Id  = stdPbId
        );
        insert o;

        insert new OrderItem(
            OrderId = o.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = 10,
            ITENumber__c = 'T-ITE-ORDERITEMCACHE-001'
        );
    }

    @IsTest
    static void test_getByIte_and_getByItes() {

        OrderItem oi = [
            SELECT Id, ITENumber__c
            FROM OrderItem
            WHERE ITENumber__c = 'T-ITE-ORDERITEMCACHE-001'
            LIMIT 1
        ];

        Id singleId = OrderItemCache.getByIte(oi.ITENumber__c);

        Map<String, Id> many =
            OrderItemCache.getByItes(new Set<String>{ oi.ITENumber__c });

        System.assertEquals(oi.Id, singleId);
        System.assertEquals(oi.Id, many.get(oi.ITENumber__c));
    }
}