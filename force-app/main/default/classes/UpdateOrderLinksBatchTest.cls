@isTest
private class UpdateOrderLinksBatchTest {
    @isTest
    static void testBatchExecution() {
        // Створення акаунта
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Створення продукту
        Product2 prod = new Product2(Name = 'Test Product', IsActive = true);
        insert prod;

        // Отримуємо стандартну прайс-книгу
        Id standardPricebookId = Test.getStandardPricebookId();

        // Створюємо активну стандартну ціну
        PricebookEntry standardEntry = new PricebookEntry(
                Pricebook2Id = standardPricebookId,
                Product2Id = prod.Id,
                UnitPrice = 100,
                IsActive = true
        );
        insert standardEntry;

        // Створення кастомної прайс-книги (опціонально)
        Pricebook2 customPb = new Pricebook2(Name = 'Custom PB', IsActive = true);
        insert customPb;

        PricebookEntry pbe = new PricebookEntry(
                Pricebook2Id = customPb.Id,
                Product2Id = prod.Id,
                UnitPrice = 100,
                IsActive = true
        );
        insert pbe;

        // Створення Order
        Order ord = new Order(
                Name = 'Test Order',
                ITENumber__c = '123456789',
                EffectiveDate = Date.today(),
                Status = 'Draft',
                AccountId = acc.Id,
                Pricebook2Id = customPb.Id
        );
        insert ord;

        // Створення OrderItem
        OrderItem item = new OrderItem(
                OrderId = ord.Id,
                Quantity = 1,
                UnitPrice = 100,
                ITENumber__c = '123456789001',
                PricebookEntryId = pbe.Id
        );
        insert item;

        // Створення SalesPlanFact__c
        SalesPlanFact__c spf = new SalesPlanFact__c(
                ITENumber__c = '123456789001'
        );
        insert spf;

        // Виконання батчу
        Test.startTest();
        Database.executeBatch(new UpdateOrderLinksBatch(), 1);
        Test.stopTest();

        // Перевірка
        SalesPlanFact__c result = [SELECT Order__c, OrderProduct__c FROM SalesPlanFact__c WHERE Id = :spf.Id];
        System.assertNotEquals(null, result.Order__c, 'Order__c має бути заповнене');
        System.assertNotEquals(null, result.OrderProduct__c, 'OrderProduct__c має бути заповнене');
    }
}