@isTest
public class FixOrderItemGeneralNameBatchTest {

    @isTest
    static void testBatchExecution() {
        // Create test data
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Order ord = new Order(
            AccountId = acc.Id,
            EffectiveDate = Date.today(),
            Status = 'Draft',
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert ord;

        Product2 prod = new Product2(Name = 'Test Product', IsActive = true);
        insert prod;

        PricebookEntry pbe = new PricebookEntry(
            Product2Id = prod.Id,
            Pricebook2Id = Test.getStandardPricebookId(),
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;

        OrderItem oi = new OrderItem(
            OrderId = ord.Id,
            Product2Id = prod.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 10,
            UnitPrice = 100,
            ITENumber__c = 'ITE-12345'
        );
        insert oi;

        // Create OrderItemGeneral__c with wrong Name (product name instead of ITE Number)
        OrderItemGeneral__c gen = new OrderItemGeneral__c(
            OrderProduct__c = oi.Id,
            Order__c = ord.Id,
            Product__c = prod.Id,
            Name = 'Wrong Product Name'
        );
        insert gen;

        // Verify initial state
        gen = [SELECT Id, Name FROM OrderItemGeneral__c WHERE Id = :gen.Id];
        System.assertEquals('Wrong Product Name', gen.Name, 'Initial name should be wrong');

        Test.startTest();
        // Execute batch
        FixOrderItemGeneralNameBatch batch = new FixOrderItemGeneralNameBatch();
        Database.executeBatch(batch, 200);
        Test.stopTest();

        // Verify the Name was updated to ITENumber__c
        gen = [SELECT Id, Name FROM OrderItemGeneral__c WHERE Id = :gen.Id];
        System.assertEquals('ITE-12345', gen.Name, 'Name should be updated to ITE Number');
    }

    @isTest
    static void testBatchWithMultipleRecords() {
        // Create test data
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Order ord = new Order(
            AccountId = acc.Id,
            EffectiveDate = Date.today(),
            Status = 'Draft',
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert ord;

        Product2 prod = new Product2(Name = 'Test Product', IsActive = true);
        insert prod;

        PricebookEntry pbe = new PricebookEntry(
            Product2Id = prod.Id,
            Pricebook2Id = Test.getStandardPricebookId(),
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;

        List<OrderItem> orderItems = new List<OrderItem>();
        for (Integer i = 0; i < 5; i++) {
            orderItems.add(new OrderItem(
                OrderId = ord.Id,
                Product2Id = prod.Id,
                PricebookEntryId = pbe.Id,
                Quantity = 10,
                UnitPrice = 100,
                ITENumber__c = 'ITE-' + i
            ));
        }
        insert orderItems;

        List<OrderItemGeneral__c> generals = new List<OrderItemGeneral__c>();
        for (OrderItem oi : orderItems) {
            generals.add(new OrderItemGeneral__c(
                OrderProduct__c = oi.Id,
                Order__c = ord.Id,
                Product__c = prod.Id,
                Name = 'Wrong Name ' + oi.Id
            ));
        }
        insert generals;

        Test.startTest();
        // Execute batch
        FixOrderItemGeneralNameBatch batch = new FixOrderItemGeneralNameBatch();
        Database.executeBatch(batch, 200);
        Test.stopTest();

        // Verify all records were updated
        List<OrderItemGeneral__c> updatedGenerals = [
            SELECT Id, Name, OrderProduct__r.ITENumber__c
            FROM OrderItemGeneral__c
            WHERE Id IN :generals
        ];

        for (OrderItemGeneral__c gen : updatedGenerals) {
            System.assertEquals(gen.OrderProduct__r.ITENumber__c, gen.Name,
                'Name should match ITENumber__c');
        }
    }
}