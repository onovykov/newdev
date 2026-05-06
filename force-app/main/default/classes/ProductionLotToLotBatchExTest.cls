@IsTest
private class ProductionLotToLotBatchExTest {

    private static final Date LOT_DATE = Date.newInstance(2026, 3, 3);
    private static final Date WEEK_FROM = Date.newInstance(2026, 3, 1);
    private static final Date WEEK_TO = Date.newInstance(2026, 3, 7);

    @TestSetup
    static void makeData() {
        Account acc = new Account(
            Name = 'Batch Test Account',
            MarketSegment__c = '00004'
        );
        insert acc;

        Product2 product = new Product2(
            Name = 'Batch Test Product',
            IsActive = true
        );
        insert product;

        Pricebook2 pb = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update pb;

        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = pb.Id,
            Product2Id = product.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;

        Order ord = new Order(
            Name = 'Batch Test Order',
            AccountId = acc.Id,
            Status = 'Draft',
            EffectiveDate = Date.today(),
            Pricebook2Id = pb.Id
        );
        insert ord;

        OrderItem oi = new OrderItem(
            OrderId = ord.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = 100,
            ITENumber__c = '26-TEST-001'
        );
        insert oi;

        insert new List<ProdWeeksH__c>{
            new ProdWeeksH__c(
                Name = 'WeekTest1',
                DateFrom__c = WEEK_FROM,
                DateTo__c = WEEK_TO
            ),
            new ProdWeeksH__c(
                Name = 'WeekFuture',
                DateFrom__c = Date.newInstance(2026, 6, 1),
                DateTo__c = Date.newInstance(2026, 6, 7)
            )
        };
    }

    @IsTest
    static void testBatchExecutionPositive() {
        OrderItem oi = [
            SELECT Id
            FROM OrderItem
            WHERE ITENumber__c = '26-TEST-001'
            LIMIT 1
        ];

        List<ProductionLot__c> sourceLots = new List<ProductionLot__c>();

        for (Integer i = 0; i < 3; i++) {
            sourceLots.add(new ProductionLot__c(
                OrderItem__c = oi.Id,
                LotDate__c = LOT_DATE,
                ProducedQuantity__c = 10,
                DispatchedQuantity__c = 5,
                ShippedQuantity__c = 2
            ));
        }

        insert sourceLots;

        Test.startTest();
        Database.executeBatch(new ProductionLotToLotBatchEx(WEEK_FROM), 200);
        Test.stopTest();

        List<Lot__c> createdLots = [
            SELECT Id, ExtKey__c, OrderItem__c, LotType__c, LotQty_t__c, ProdWeek__c
            FROM Lot__c
            WHERE OrderItem__c = :oi.Id
        ];

        System.assertEquals(
            3,
            createdLots.size(),
            'Upsert by ExtKey should leave 3 records: Produced, Shipped, Delivered'
        );

        Map<String, Lot__c> byType = new Map<String, Lot__c>();

        for (Lot__c l : createdLots) {
            byType.put(l.LotType__c, l);
            System.assertEquals(oi.Id, l.OrderItem__c);
            System.assertNotEquals(null, l.ExtKey__c);
            System.assertNotEquals(null, l.ProdWeek__c);
        }

        System.assertEquals(Decimal.valueOf('30'), byType.get('Produced').LotQty_t__c);
        System.assertEquals(Decimal.valueOf('15'), byType.get('Shipped').LotQty_t__c);
        System.assertEquals(Decimal.valueOf('6'), byType.get('Delivered').LotQty_t__c);
    }

    @IsTest
    static void testBatchExecutionNoLotsCreated() {
        OrderItem oi = [
            SELECT Id
            FROM OrderItem
            WHERE ITENumber__c = '26-TEST-001'
            LIMIT 1
        ];

        insert new ProductionLot__c(
            OrderItem__c = oi.Id,
            LotDate__c = LOT_DATE,
            ProducedQuantity__c = null,
            DispatchedQuantity__c = null,
            ShippedQuantity__c = null
        );

        Test.startTest();
        Database.executeBatch(new ProductionLotToLotBatchEx(WEEK_FROM), 200);
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM Lot__c]);
    }

    @IsTest
    static void testBatchSingleQuantity() {
        OrderItem oi = [
            SELECT Id
            FROM OrderItem
            WHERE ITENumber__c = '26-TEST-001'
            LIMIT 1
        ];

        insert new ProductionLot__c(
            OrderItem__c = oi.Id,
            LotDate__c = LOT_DATE,
            ProducedQuantity__c = 5,
            DispatchedQuantity__c = null,
            ShippedQuantity__c = null
        );

        Test.startTest();
        Database.executeBatch(new ProductionLotToLotBatchEx(WEEK_FROM), 200);
        Test.stopTest();

        List<Lot__c> createdLots = [
            SELECT Id, ExtKey__c, OrderItem__c, LotType__c, LotQty_t__c, ProdWeek__c
            FROM Lot__c
            WHERE OrderItem__c = :oi.Id
        ];

        System.assertEquals(1, createdLots.size());
        System.assertEquals('Produced', createdLots[0].LotType__c);
        System.assertEquals(Decimal.valueOf('5'), createdLots[0].LotQty_t__c);
        System.assertEquals(oi.Id, createdLots[0].OrderItem__c);
        System.assertNotEquals(null, createdLots[0].ExtKey__c);
        System.assertNotEquals(null, createdLots[0].ProdWeek__c);
    }

    @IsTest
    static void testDateFilterExcluded() {
        OrderItem oi = [
            SELECT Id
            FROM OrderItem
            WHERE ITENumber__c = '26-TEST-001'
            LIMIT 1
        ];

        insert new ProductionLot__c(
            OrderItem__c = oi.Id,
            LotDate__c = LOT_DATE,
            ProducedQuantity__c = 10,
            DispatchedQuantity__c = 10,
            ShippedQuantity__c = 10
        );

        Test.startTest();
        Database.executeBatch(new ProductionLotToLotBatchEx(LOT_DATE.addDays(1)), 200);
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM Lot__c]);
    }

    @IsTest
    static void testBatchSkipsWhenNoProdWeekFound() {
        OrderItem oi = [
            SELECT Id
            FROM OrderItem
            WHERE ITENumber__c = '26-TEST-001'
            LIMIT 1
        ];

        insert new ProductionLot__c(
            OrderItem__c = oi.Id,
            LotDate__c = Date.newInstance(2030, 1, 1),
            ProducedQuantity__c = 10
        );

        Test.startTest();
        Database.executeBatch(new ProductionLotToLotBatchEx(WEEK_FROM), 200);
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM Lot__c]);
    }
}