@IsTest
private class OrderItemChildServiceTest {

    @TestSetup
    static void setup() {
        // Create test Account
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        // Create test Opportunity
        Opportunity testOpp = new Opportunity(
                Name = 'Test Opportunity',
                AccountId = testAccount.Id,
                StageName = 'Prospecting',
                CloseDate = Date.today().addDays(30)
        );
        insert testOpp;

        // Create test Product
        Product2 testProduct = new Product2(
                Name = 'Test Product',
                IsActive = true
        );
        insert testProduct;

        // Get Standard Pricebook
        Id pricebookId = Test.getStandardPricebookId();

        // Create PricebookEntry
        PricebookEntry testPbe = new PricebookEntry(
                Pricebook2Id = pricebookId,
                Product2Id = testProduct.Id,
                UnitPrice = 100,
                IsActive = true
        );
        insert testPbe;
    }

    @IsTest
    static void testSafeTrim_NullString() {
        String result = OrderItemChildService.safeTrim(null, 10);
        System.assertEquals(null, result, 'Should return null for null input');
    }

    @IsTest
    static void testSafeTrim_EmptyString() {
        String result = OrderItemChildService.safeTrim('', 10);
        System.assertEquals(null, result, 'Should return null for empty string');
    }

    @IsTest
    static void testSafeTrim_BlankString() {
        String result = OrderItemChildService.safeTrim('   ', 10);
        System.assertEquals(null, result, 'Should return null for blank string');
    }

    @IsTest
    static void testSafeTrim_StringShorterThanMax() {
        String result = OrderItemChildService.safeTrim('test', 10);
        System.assertEquals('test', result, 'Should return original string when shorter than max');
    }

    @IsTest
    static void testSafeTrim_StringLongerThanMax() {
        String result = OrderItemChildService.safeTrim('this is a long string', 10);
        System.assertEquals('this is a ', result, 'Should truncate string to max length');
    }

    @IsTest
    static void testFillChildRecords_NullOrderItems() {
        Test.startTest();
        OrderItemChildService.fillChildRecords(null, null, null, null);
        Test.stopTest();

        // Should not throw exception - verify no records created
        List<OrderItemGeneral__c> generals = [SELECT Id FROM OrderItemGeneral__c];
        System.assertEquals(0, generals.size(), 'No records should be created for null input');
    }

    @IsTest
    static void testFillChildRecords_EmptyOrderItems() {
        Test.startTest();
        OrderItemChildService.fillChildRecords(new List<OrderItem>(), null, null, null);
        Test.stopTest();

        // Should not throw exception - verify no records created
        List<OrderItemGeneral__c> generals = [SELECT Id FROM OrderItemGeneral__c];
        System.assertEquals(0, generals.size(), 'No records should be created for empty list');
    }

    @IsTest
    static void testFillChildRecords_TubesInsert() {
        // Get test data
        Opportunity opp = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        PricebookEntry pbe = [SELECT Id, Pricebook2Id FROM PricebookEntry WHERE Product2Id = :product.Id LIMIT 1];

        // Create Order with MarketSegment != '00006' (Tubes)
        Order testOrder = new Order(
                AccountId = opp.AccountId,
                OpportunityId = opp.Id,
                EffectiveDate = Date.today(),
                Status = 'Draft',
                Pricebook2Id = pbe.Pricebook2Id,
                MarketSegment__c = '00001'
        );
        insert testOrder;

        // Create OrderItem
        OrderItem testOI = new OrderItem(
                OrderId = testOrder.Id,
                Product2Id = product.Id,
                PricebookEntryId = pbe.Id,
                Quantity = 10,
                UnitPrice = 100,
                ITENumber__c = 'ITE-001'
        );
        insert testOI;

        Test.startTest();
        OrderItemChildService.fillChildRecords(
                new List<OrderItem>{testOI},
                new Map<Id, Order>{testOrder.Id => testOrder},
                new Map<Id, SpecVersion__c>(),
                new Map<Id, DrawingVersion__c>()
        );
        Test.stopTest();

        // Verify General record created
        List<OrderItemGeneral__c> generals = [
                SELECT Id, OrderProduct__c, Shop__c, Name, Product__c
                FROM OrderItemGeneral__c
                WHERE OrderProduct__c = :testOI.Id
        ];
        System.assertEquals(1, generals.size(), 'Should create one OrderItemGeneral__c');
        System.assertEquals(testOI.Id, generals[0].OrderProduct__c, 'Should link to OrderItem');
        System.assertEquals('ITE-001', generals[0].Name, 'Should set Name from ITENumber__c');
        System.assertEquals(product.Id, generals[0].Product__c, 'Should set Product__c');

        // Verify Pipes record created
        List<OrderItemProductInfoPipes__c> pipes = [
                SELECT Id, OrderProduct__c, Name
                FROM OrderItemProductInfoPipes__c
                WHERE OrderProduct__c = :testOI.Id
        ];
        System.assertEquals(1, pipes.size(), 'Should create one OrderItemProductInfoPipes__c');
        System.assertEquals(testOI.Id, pipes[0].OrderProduct__c, 'Should link to OrderItem');
        System.assertEquals('ITE-001', pipes[0].Name, 'Should set Name');

        // Verify no KLW record created
        List<OrderItemProductInfoKLW__c> klws = [
                SELECT Id FROM OrderItemProductInfoKLW__c WHERE OrderProduct__c = :testOI.Id
        ];
        System.assertEquals(0, klws.size(), 'Should not create OrderItemProductInfoKLW__c for tubes');
    }

    @IsTest
    static void testFillChildRecords_MultipleOrderItems() {
        // Get test data
        Opportunity opp = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
        Product2 product = [SELECT Id FROM Product2 LIMIT 1];
        PricebookEntry pbe = [SELECT Id, Pricebook2Id FROM PricebookEntry WHERE Product2Id = :product.Id LIMIT 1];

        // Create Orders
        Order tubesOrder = new Order(
                AccountId = opp.AccountId,
                OpportunityId = opp.Id,
                EffectiveDate = Date.today(),
                Status = 'Draft',
                Pricebook2Id = pbe.Pricebook2Id,
                MarketSegment__c = '00001'
        );
        Order klwOrder = new Order(
                AccountId = opp.AccountId,
                OpportunityId = opp.Id,
                EffectiveDate = Date.today(),
                Status = 'Draft',
                Pricebook2Id = pbe.Pricebook2Id,
                MarketSegment__c = '00006'
        );
        insert new List<Order>{tubesOrder, klwOrder};

        // Create OrderItems
        OrderItem tubesOI = new OrderItem(
                OrderId = tubesOrder.Id,
                Product2Id = product.Id,
                PricebookEntryId = pbe.Id,
                Quantity = 10,
                UnitPrice = 100,
                ITENumber__c = 'TUBE-001'
        );
        OrderItem klwOI = new OrderItem(
                OrderId = klwOrder.Id,
                Product2Id = product.Id,
                PricebookEntryId = pbe.Id,
                Quantity = 20,
                UnitPrice = 150,
                ITENumber__c = 'KLW-001',
                Stage__c = 'Confirmed'
        );
        insert new List<OrderItem>{tubesOI, klwOI};

        Test.startTest();
        OrderItemChildService.fillChildRecords(
                new List<OrderItem>{tubesOI, klwOI},
                new Map<Id, Order>{tubesOrder.Id => tubesOrder, klwOrder.Id => klwOrder},
                new Map<Id, SpecVersion__c>(),
                new Map<Id, DrawingVersion__c>()
        );
        Test.stopTest();

        // Verify 2 General records created
        List<OrderItemGeneral__c> generals = [SELECT Id FROM OrderItemGeneral__c];
        System.assertEquals(2, generals.size(), 'Should create two OrderItemGeneral__c records');

        // Verify 1 Pipes and 1 KLW record created
        List<OrderItemProductInfoPipes__c> pipes = [SELECT Id FROM OrderItemProductInfoPipes__c];
        System.assertEquals(1, pipes.size(), 'Should create one Pipes record');

        List<OrderItemProductInfoKLW__c> klws = [SELECT Id FROM OrderItemProductInfoKLW__c];
        System.assertEquals(1, klws.size(), 'Should create one KLW record');
    }
}