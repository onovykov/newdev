@isTest
private class LinkProductionLotsToProdWeeksBatchTest {

    @isTest
    static void testBatchAssignsProdWeek() {
        // Створення тестового тижня
        Date today = Date.today();
        ProdWeeksH__c testWeek = new ProdWeeksH__c(
                DateFrom__c = today.addDays(-1),
                DateTo__c = today.addDays(1),
                Level__c = 3
        );
        insert testWeek;

        // Створення тестового акаунта
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        // Створення Order__c з правильним AccountId
        Order testOrder = new Order(
                Name = 'Test Order',
                Status = 'Draft',
                EffectiveDate = today,
                AccountId = testAccount.Id
        );
        insert testOrder;

        // Створення лоту з LotDate__c у межах тижня
        ProductionLot__c testLot = new ProductionLot__c(
                LotDate__c = today,
                Order__c = testOrder.Id
        );
        insert testLot;

        Test.startTest();
        Database.executeBatch(new LinkProductionLotsToProdWeeksBatch(), 200);
        Test.stopTest();

        // Перевірка
        ProductionLot__c updatedLot = [SELECT Id, ProdWeek__c FROM ProductionLot__c WHERE Id = :testLot.Id];
        System.assertEquals(testWeek.Id, updatedLot.ProdWeek__c, 'ProdWeek__c should be linked');
    }

    @isTest
    static void testBatchSkipsWhenNoMatchingWeek() {
        Date today = Date.today();

        // Створення тижня, який не підходить
        ProdWeeksH__c pastWeek = new ProdWeeksH__c(
                DateFrom__c = today.addDays(-10),
                DateTo__c = today.addDays(-8),
                Level__c = 3
        );
        insert pastWeek;

        // Створення тестового акаунта
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        // Створення Order__c з правильним AccountId
        Order testOrder = new Order(
                Name = 'Test Order',
                Status = 'Draft',
                EffectiveDate = today,
                AccountId = testAccount.Id
        );
        insert testOrder;

        // Лот, що не підпадає під жоден тиждень
        ProductionLot__c testLot = new ProductionLot__c(
                LotDate__c = today,
                Order__c = testOrder.Id
        );
        insert testLot;

        Test.startTest();
        Database.executeBatch(new LinkProductionLotsToProdWeeksBatch(), 200);
        Test.stopTest();

        ProductionLot__c updatedLot = [SELECT Id, ProdWeek__c FROM ProductionLot__c WHERE Id = :testLot.Id];
        System.assertEquals(null, updatedLot.ProdWeek__c, 'ProdWeek__c should remain null');
    }
}