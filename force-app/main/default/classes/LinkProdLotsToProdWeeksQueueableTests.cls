@IsTest
private class LinkProdLotsToProdWeeksQueueableTests {

    private static void makeWeek(Integer y, Integer m, Integer dFrom, Integer dTo) {
        ProdWeeksH__c w = new ProdWeeksH__c(
            Level__c    = 3,
            DateFrom__c = Date.newInstance(y, m, dFrom),
            DateTo__c   = Date.newInstance(y, m, dTo)
        );
        insert w;
    }

    @IsTest
    static void linkByDateRange_insertAndIdempotentUpdate() {
        // 1) Створюємо тижні (два суміжні)
        Date base = Date.today();
        Integer y = base.year();
        Integer m = base.month();

        makeWeek(y, m, 1, 7);
        makeWeek(y, m, 8, 15);

        // 2) Створюємо партії з датами у різних тижнях
        ProductionLot__c a = new ProductionLot__c(LotDate__c=Date.newInstance(y, m, 2));
        ProductionLot__c b = new ProductionLot__c(LotDate__c=Date.newInstance(y, m, 10));
        insert new List<ProductionLot__c>{ a, b };

        Test.startTest();
        // dryRun=false — реальне оновлення
        System.enqueueJob(new LinkProductionLotsToProdWeeksQueueable(null, Date.newInstance(y, m, 1), Date.newInstance(y, m, 20), false));
        Test.stopTest();

        // 3) Перевіряємо, що поля проставлені
        a = [SELECT Id, ProdWeek__c FROM ProductionLot__c WHERE Id=:a.Id];
        b = [SELECT Id, ProdWeek__c FROM ProductionLot__c WHERE Id=:b.Id];
        System.assertNotEquals(null, a.ProdWeek__c, 'Lot A must be linked to week');
        System.assertNotEquals(null, b.ProdWeek__c, 'Lot B must be linked to week');
        System.assertNotEquals(a.ProdWeek__c, b.ProdWeek__c, 'A and B should map to different weeks');

        // 4) Другий запуск — нічого не повинно змінитися (idempotent)
        Test.startTest();
        System.enqueueJob(new LinkProductionLotsToProdWeeksQueueable(new Set<Id>{a.Id, b.Id}, null, null, false));
        Test.stopTest();

        ProductionLot__c a2 = [SELECT Id, ProdWeek__c FROM ProductionLot__c WHERE Id=:a.Id];
        ProductionLot__c b2 = [SELECT Id, ProdWeek__c FROM ProductionLot__c WHERE Id=:b.Id];
        System.assertEquals(a.ProdWeek__c, a2.ProdWeek__c, 'Idempotent: A unchanged');
        System.assertEquals(b.ProdWeek__c, b2.ProdWeek__c, 'Idempotent: B unchanged');
    }

    @IsTest
    static void dryRunDoesNotWrite() {
        // Тиждень, який завідомо покриває today()
        Date t = Date.today();
        makeWeek(t.year(), t.month(), Math.max(1, t.day()-1), Math.min(t.day()+1, t.toStartOfMonth().addMonths(1).addDays(-1).day()));

        ProductionLot__c l = new ProductionLot__c(LotDate__c=t);
        insert l;

        Test.startTest();
        System.enqueueJob(new LinkProductionLotsToProdWeeksQueueable(new Set<Id>{l.Id}, null, null, true)); // dryRun=TRUE
        Test.stopTest();

        // Не повинно бути запису
        l = [SELECT Id, ProdWeek__c FROM ProductionLot__c WHERE Id=:l.Id];
        System.assertEquals(null, l.ProdWeek__c, 'Dry run must not modify data');
    }
}