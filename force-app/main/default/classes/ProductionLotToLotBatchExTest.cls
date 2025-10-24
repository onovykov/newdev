@isTest
private class ProductionLotToLotBatchExTest {

    @TestSetup
    static void makeData(){
        Account testAccount = new Account(Name = 'Test Account', MarketSegment__c = '00004');
        insert testAccount;

        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;

        Order testOrder = new Order(
            Name = 'Test Order',
            AccountId = testAccount.Id,
            Status = 'Draft',
            EffectiveDate = Date.today(),
            Pricebook2Id = standardPricebook.Id
        );
        insert testOrder;  
    }

    @isTest
    static void testBatchExecutionPositive() {
        Date lotDate = Date.today().addDays(-2);
        Date dateFrom = Date.today().addDays(-3);
        Order order = [SELECT Id FROM Order LIMIT 1];

        // ProductionLots з валідними кількостями і відповідною датою
        List<ProductionLot__c> testProductionLots = new List<ProductionLot__c>();
        for (Integer i = 0; i < 3; i++) {
            testProductionLots.add(new ProductionLot__c(
                ITE_Number__c = 'ITE-' + i,
                Order__c = order.Id,
                LotDate__c = lotDate,
                ProducedQuantity__c = 10,
                DispatchedQuantity__c = 5,
                ShippedQuantity__c = 2
            ));
        }
        insert testProductionLots;

        // Production Week
        ProdWeeksH__c testWeek = new ProdWeeksH__c(
            Name = 'WeekTest',
            DateFrom__c = Date.today().addDays(-10),
            DateTo__c = Date.today().addDays(10)
        );
        insert testWeek;

        Test.startTest();
        ProductionLotToLotBatchEx batch = new ProductionLotToLotBatchEx(dateFrom);
        Database.executeBatch(batch, 200);
        Test.stopTest();

        List<Lot__c> createdLots = [
            SELECT Id, ITENumber__c, LotType__c, LotQty_t__c, ProdWeek__c
            FROM Lot__c
        ];

        System.assertEquals(9, createdLots.size(), 'Повинно бути створено 9 Lot__c записів');

        for (Lot__c lot : createdLots) {
            System.assertNotEquals(null, lot.LotType__c);
            System.assertNotEquals(null, lot.LotQty_t__c);
            System.assertEquals(testWeek.Id, lot.ProdWeek__c);
        }
    }

    @isTest
    static void testBatchExecutionNoLotsCreated() {
        Date dateFrom = Date.today().addDays(-5);
        Order order = [SELECT Id FROM Order LIMIT 1];

        ProductionLot__c lotWithoutQuantities = new ProductionLot__c(
            ITE_Number__c = 'ITE-NULL',
            Order__c = Order.Id,
            LotDate__c = Date.today(),
            ProducedQuantity__c = null,
            DispatchedQuantity__c = null,
            ShippedQuantity__c = null
        );
        insert lotWithoutQuantities;

        Test.startTest();
        ProductionLotToLotBatchEx batch = new ProductionLotToLotBatchEx(dateFrom);
        Database.executeBatch(batch, 200);
        Test.stopTest();

        List<Lot__c> createdLots = [
            SELECT Id
            FROM Lot__c
        ];
        System.assertEquals(0, createdLots.size(), 'Жодного Lot__c не повинно бути створено');
    }

    @isTest
    static void testBatchSingleQuantity() {
        Date dateFrom = Date.today().addDays(-1);
        Order order = [SELECT Id FROM Order LIMIT 1];

        ProductionLot__c lotProducedOnly = new ProductionLot__c(
            ITE_Number__c = 'ITE-ONLY',
            LotDate__c = Date.today(),
            Order__c = order.Id,
            ProducedQuantity__c = 5,
            DispatchedQuantity__c = null,
            ShippedQuantity__c = null
        );
        insert lotProducedOnly;

        ProdWeeksH__c testWeek = new ProdWeeksH__c(
            Name = 'WeekTestOnly',
            DateFrom__c = Date.today().addDays(-1),
            DateTo__c = Date.today().addDays(1)
        );
        insert testWeek;

        Test.startTest();
        ProductionLotToLotBatchEx batch = new ProductionLotToLotBatchEx(dateFrom);
        Database.executeBatch(batch, 200);
        Test.stopTest();

        List<Lot__c> createdLots = [
            SELECT Id, LotType__c
            FROM Lot__c
        ];

        System.assertEquals(1, createdLots.size());
        System.assertEquals('Produced', createdLots[0].LotType__c);
    }

    @isTest
    static void testDateFilterExcluded() {
        Date dateFrom = Date.today().addDays(1); // майбутнє
        Order order = [SELECT Id FROM Order LIMIT 1];

        ProductionLot__c futureLot = new ProductionLot__c(
            ITE_Number__c = 'ITE-FUTURE',
            LotDate__c = Date.today(),
            Order__c = order.Id,
            ProducedQuantity__c = 10,
            DispatchedQuantity__c = 10,
            ShippedQuantity__c = 10
        );
        insert futureLot;

        Test.startTest();
        ProductionLotToLotBatchEx batch = new ProductionLotToLotBatchEx(dateFrom);
        Database.executeBatch(batch, 200);
        Test.stopTest();

        List<Lot__c> createdLots = [
            SELECT Id
            FROM Lot__c
        ];

        System.assertEquals(0, createdLots.size(), 'Запис повинен бути проігнорований через фільтр дати');
    }
}