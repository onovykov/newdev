@IsTest
private class ProdWeekCacheTest {

    @IsTest
    static void getByDate_shouldFindMatchingWeek() {
        ProdWeekCache.reset();
        ERPLotTestDataFactory.DataBundle b = ERPLotTestDataFactory.createBaseData();

        Test.startTest();
        Id weekId = ProdWeekCache.getByDate(Date.newInstance(2024, 7, 25));
        Test.stopTest();

        System.assertEquals(b.julyWeek.Id, weekId);
    }

    @IsTest
    static void getByDate_shouldReturnNullForNullDate() {
        ProdWeekCache.reset();
        ERPLotTestDataFactory.createBaseData();

        System.assertEquals(null, ProdWeekCache.getByDate(null));
    }

    @IsTest
    static void getByDate_shouldReturnNullWhenNoWeekFound() {
        ProdWeekCache.reset();
        ERPLotTestDataFactory.createBaseData();

        System.assertEquals(null, ProdWeekCache.getByDate(Date.newInstance(2030, 1, 1)));
    }

    @IsTest
    static void getByDate_shouldReuseLoadedCache() {
        ProdWeekCache.reset();
        ERPLotTestDataFactory.DataBundle b = ERPLotTestDataFactory.createBaseData();

        Id first = ProdWeekCache.getByDate(Date.newInstance(2024, 7, 25));
        Id second = ProdWeekCache.getByDate(Date.newInstance(2024, 7, 26));

        System.assertEquals(b.julyWeek.Id, first);
        System.assertEquals(b.julyWeek.Id, second);
    }

    @IsTest
    static void getRecById_shouldReturnWeekRecForValidId() {
        ProdWeekCache.reset();
        ERPLotTestDataFactory.DataBundle b = ERPLotTestDataFactory.createBaseData();

        Test.startTest();
        ProdWeekCache.WeekRec rec = ProdWeekCache.getRecById(b.julyWeek.Id);
        Test.stopTest();

        System.assertNotEquals(null, rec);
        System.assertEquals(b.julyWeek.DateFrom__c, rec.DateFrom);
        System.assertEquals(b.julyWeek.DateTo__c, rec.DateTo);
        System.assertEquals(String.valueOf(b.julyWeek.Month__c), rec.Month);
        System.assertEquals(Integer.valueOf(b.julyWeek.Year__c), rec.Year);
        System.assertEquals(Integer.valueOf(b.julyWeek.WeekNum__c), rec.WeekNum);
    }

    @IsTest
    static void getRecById_shouldReturnNullForNullId() {
        ProdWeekCache.reset();
        ERPLotTestDataFactory.createBaseData();

        System.assertEquals(null, ProdWeekCache.getRecById(null));
    }

    @IsTest
    static void getRecById_shouldReturnNullWhenNoWeekFound() {
        ProdWeekCache.reset();
        ERPLotTestDataFactory.createBaseData();

        Id fakeId = Id.valueOf('a00000000000000AAA');

        System.assertEquals(null, ProdWeekCache.getRecById(fakeId));
    }

    @IsTest
    static void getRecByDate_shouldReturnSObjectForMatchingDate() {
        ProdWeekCache.reset();
        ERPLotTestDataFactory.DataBundle b = ERPLotTestDataFactory.createBaseData();

        Test.startTest();
        ProdWeeksH__c week = ProdWeekCache.getRecByDate(Date.newInstance(2024, 7, 25));
        Test.stopTest();

        System.assertNotEquals(null, week);
        System.assertEquals(b.julyWeek.Id, week.Id);
        System.assertEquals(b.julyWeek.DateFrom__c, week.DateFrom__c);
        System.assertEquals(b.julyWeek.DateTo__c, week.DateTo__c);
        System.assertEquals(b.julyWeek.Month__c, week.Month__c);
        System.assertEquals(b.julyWeek.Year__c, week.Year__c);
        System.assertEquals(b.julyWeek.WeekNum__c, week.WeekNum__c);
    }

    @IsTest
    static void getRecByDate_shouldReturnNullForNullDate() {
        ProdWeekCache.reset();
        ERPLotTestDataFactory.createBaseData();

        System.assertEquals(null, ProdWeekCache.getRecByDate(null));
    }

    @IsTest
    static void getRecByDate_shouldReturnNullWhenNoWeekFound() {
        ProdWeekCache.reset();
        ERPLotTestDataFactory.createBaseData();

        System.assertEquals(null, ProdWeekCache.getRecByDate(Date.newInstance(2030, 1, 1)));
    }
}