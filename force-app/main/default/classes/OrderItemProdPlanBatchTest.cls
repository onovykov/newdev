@isTest
private class OrderItemProdPlanBatchTest {
    @testSetup
    static void setupTestData() {
        Account testAccount = new Account(Name = 'Test Account', MarketSegment__c = '00004');
        insert testAccount;

        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;

        Order testOrder = new Order(
            Name = 'Test Order', 
            Status = 'Draft', 
            EffectiveDate = Date.today(), 
            Pricebook2Id = standardPricebook.Id,
            AccountId = testAccount.Id
        );
        insert testOrder;

        Product2 testProduct = new Product2(Name = 'Test Product', IsActive = true);
        insert testProduct;

        PricebookEntry testPricebookEntry = new PricebookEntry(
            Product2Id = testProduct.Id,
            Pricebook2Id = standardPricebook.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert testPricebookEntry;
        
        OrderItem testItem = new OrderItem(
            OrderId = testOrder.Id,
            Quantity = 1,
            UnitPrice = 100,
            ITENumber__c = 'ITEM123',
            PricebookEntryId = testPricebookEntry.Id
        );
        insert testItem;
        
        ProdWeeksH__c testWeek = new ProdWeeksH__c(
            WeekNum__c = 1,
            Month__c = '3',
            Year__c = 2025
        );
        insert testWeek;
        
        OrderItemProdPlan__c testPlan = new OrderItemProdPlan__c(
            ITENumber__c = 'ITEM123',
            WeekNum__c = '1',
            Month__c = '3',
            Year__c = '2025'
        );

        OrderItemProdPlan__c testPlan2 = new OrderItemProdPlan__c(
            ITENumber__c = 'ITEM124',
            WeekNum__c = '1',
            Month__c = '3',
            Year__c = '2025'
        );
        insert new List<OrderItemProdPlan__c>{testPlan, testPlan2};
    }
    
    @isTest
    static void testBatchExecution() {
        Test.startTest();
        OrderItemProdPlanBatch batch = new OrderItemProdPlanBatch();
        Database.executeBatch(batch);
        Test.stopTest();
        
        OrderItemProdPlan__c updatedPlan = [SELECT Order__c, OrderItem__c, ProdWeek__c FROM OrderItemProdPlan__c WHERE ITENumber__c = 'ITEM123' LIMIT 1];
        System.assertNotEquals(null, updatedPlan.Order__c, 'Order should be assigned');
        System.assertNotEquals(null, updatedPlan.OrderItem__c, 'OrderItem should be assigned');
        System.assertNotEquals(null, updatedPlan.ProdWeek__c, 'ProdWeek should be assigned');

        
        OrderItemProdPlan__c updatedPlanWithoutOrder = [SELECT Order__c, OrderItem__c, ProdWeek__c FROM OrderItemProdPlan__c WHERE ITENumber__c = 'ITEM124' LIMIT 1];
        System.assertEquals(null, updatedPlanWithoutOrder.Order__c, 'Order should be null');
        System.assertNotEquals(null, updatedPlanWithoutOrder.ProdWeek__c, 'ProdWeek should be assigned');
    }
}