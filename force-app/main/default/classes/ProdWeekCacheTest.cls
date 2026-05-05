@IsTest
private class ProdWeekCacheTest {

    @IsTest
    static void getByDate_shouldFindMatchingWeek() {
        ERPLotTestDataFactory.DataBundle b = ERPLotTestDataFactory.createBaseData();

        Test.startTest();
        Id weekId = ProdWeekCache.getByDate(Date.newInstance(2024, 7, 25));
        Test.stopTest();

        System.assertEquals(b.julyWeek.Id, weekId);
    }

    @IsTest
    static void getByDate_shouldReturnNullForNullDate() {
        ERPLotTestDataFactory.createBaseData();

        System.assertEquals(null, ProdWeekCache.getByDate(null));
    }

    @IsTest
    static void getByDate_shouldReturnNullWhenNoWeekFound() {
        ERPLotTestDataFactory.createBaseData();

        System.assertEquals(null, ProdWeekCache.getByDate(Date.newInstance(2030, 1, 1)));
    }

    @IsTest
    static void getByDate_shouldReuseLoadedCache() {
        ERPLotTestDataFactory.DataBundle b = ERPLotTestDataFactory.createBaseData();

        Id first = ProdWeekCache.getByDate(Date.newInstance(2024, 7, 25));
        Id second = ProdWeekCache.getByDate(Date.newInstance(2024, 7, 26));

        System.assertEquals(b.julyWeek.Id, first);
        System.assertEquals(b.julyWeek.Id, second);
    }
}