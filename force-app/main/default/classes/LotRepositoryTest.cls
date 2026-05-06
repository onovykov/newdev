@IsTest
private class LotRepositoryTest {

    @IsTest
    static void getByExtKeys_shouldReturnLotsByExternalKey() {
        TestData data = createData();

        Set<String> extKeys = new Set<String>{
            data.producedLot.ExtKey__c,
            data.dispatchedLot.ExtKey__c
        };

        Test.startTest();
        Map<String, Lot__c> result = new LotRepository().getByExtKeys(extKeys);
        Test.stopTest();

        System.assertEquals(2, result.size());
        System.assertEquals(data.producedLot.Id, result.get(data.producedLot.ExtKey__c).Id);
        System.assertEquals(data.dispatchedLot.Id, result.get(data.dispatchedLot.ExtKey__c).Id);
    }

    @IsTest
    static void getByExtKeys_shouldReturnEmptyMapForNullOrEmptyInput() {
        LotRepository repo = new LotRepository();

        System.assertEquals(0, repo.getByExtKeys(null).size());
        System.assertEquals(0, repo.getByExtKeys(new Set<String>()).size());
    }

    @IsTest
    static void getLotsByIteNum_shouldReturnLotsForIteNumber() {
        TestData data = createData();

        Test.startTest();
        Map<String, Lot__c> result = new LotRepository().getLotsByIteNum(data.iteNumber);
        Test.stopTest();

        System.assertEquals(3, result.size());
        System.assert(result.containsKey(data.producedLot.ExtKey__c));
        System.assert(result.containsKey(data.dispatchedLot.ExtKey__c));
        System.assert(result.containsKey(data.shippedLot.ExtKey__c));
    }

    @IsTest
    static void getLotsByIteNum_shouldReturnEmptyMapForBlankInput() {
        LotRepository repo = new LotRepository();

        System.assertEquals(0, repo.getLotsByIteNum(null).size());
        System.assertEquals(0, repo.getLotsByIteNum('').size());
        System.assertEquals(0, repo.getLotsByIteNum('   ').size());
    }

    @IsTest
    static void getLotsByDates_shouldReturnLotsInsideDateRange() {
        TestData data = createData();

        Test.startTest();
        Map<String, Lot__c> result = new LotRepository().getLotsByDates(
            Date.newInstance(2024, 7, 1),
            Date.newInstance(2024, 7, 31)
        );
        Test.stopTest();

        System.assertEquals(2, result.size());
        System.assert(result.containsKey(data.producedLot.ExtKey__c));
        System.assert(result.containsKey(data.dispatchedLot.ExtKey__c));
        System.assert(!result.containsKey(data.shippedLot.ExtKey__c));
    }

    @IsTest
    static void getLotsByDates_shouldReturnEmptyMapForInvalidInput() {
        createData();

        LotRepository repo = new LotRepository();

        System.assertEquals(0, repo.getLotsByDates(null, Date.today()).size());
        System.assertEquals(0, repo.getLotsByDates(Date.today(), null).size());

        System.assertEquals(
            0,
            repo.getLotsByDates(
                Date.newInstance(2024, 8, 31),
                Date.newInstance(2024, 8, 1)
            ).size()
        );
    }

    @IsTest
    static void getLotsByYM_shouldReturnLotsForYearAndMonth() {
        TestData data = createData();

        Test.startTest();
        Map<String, Lot__c> result = new LotRepository().getLotsByYM(2024, 7);
        Test.stopTest();

        System.assertEquals(2, result.size());
        System.assert(result.containsKey(data.producedLot.ExtKey__c));
        System.assert(result.containsKey(data.dispatchedLot.ExtKey__c));
        System.assert(!result.containsKey(data.shippedLot.ExtKey__c));
    }

    @IsTest
    static void getLotsByYM_shouldReturnEmptyMapForInvalidInput() {
        createData();

        LotRepository repo = new LotRepository();

        System.assertEquals(0, repo.getLotsByYM(null, 7).size());
        System.assertEquals(0, repo.getLotsByYM(2024, null).size());
        System.assertEquals(0, repo.getLotsByYM(2024, 0).size());
        System.assertEquals(0, repo.getLotsByYM(2024, 13).size());
        System.assertEquals(0, repo.getLotsByYM(0, 7).size());
    }

    @IsTest
    static void getLotsByProdWeekId_shouldReturnLotsForProdWeek() {
        TestData data = createData();

        Test.startTest();
        Map<String, Lot__c> result = new LotRepository().getLotsByProdWeekId(data.julyWeek.Id);
        Test.stopTest();

        System.assertEquals(2, result.size());
        System.assert(result.containsKey(data.producedLot.ExtKey__c));
        System.assert(result.containsKey(data.dispatchedLot.ExtKey__c));
        System.assert(!result.containsKey(data.shippedLot.ExtKey__c));
    }

    @IsTest
    static void getLotsByProdWeekId_shouldReturnEmptyMapForNullInput() {
        LotRepository repo = new LotRepository();

        System.assertEquals(0, repo.getLotsByProdWeekId(null).size());
    }

    @IsTest
    static void upsertByExtKey_shouldInsertAndUpdateLots() {
        TestData data = createData();

        Lot__c newLot = new Lot__c(
            ExtKey__c = data.orderItem2.Id + '#' + data.julyWeek.Id + '#Produced',
            OrderItem__c = data.orderItem2.Id,
            ProdWeek__c = data.julyWeek.Id,
            LotDate__c = Date.newInstance(2024, 7, 27),
            //CDD__c = Date.newInstance(2024, 7, 27),
            LotQty_t__c = 10,
            LotType__c = 'Produced'
        );

        Lot__c updatedLot = new Lot__c(
            ExtKey__c = data.producedLot.ExtKey__c,
            LotQty_t__c = 99
        );

        Test.startTest();
        Database.UpsertResult[] results = new LotRepository().upsertByExtKey(
            new List<Lot__c>{ newLot, updatedLot }
        );
        Test.stopTest();

        System.assertEquals(2, results.size());
        System.assertEquals(true, results[0].isSuccess());
        System.assertEquals(true, results[1].isSuccess());

        Lot__c inserted = [
            SELECT Id, ExtKey__c, LotQty_t__c
            FROM Lot__c
            WHERE ExtKey__c = :newLot.ExtKey__c
            LIMIT 1
        ];

        Lot__c updated = [
            SELECT Id, ExtKey__c, LotQty_t__c
            FROM Lot__c
            WHERE ExtKey__c = :data.producedLot.ExtKey__c
            LIMIT 1
        ];

        System.assertEquals(10, inserted.LotQty_t__c);
        System.assertEquals(99, updated.LotQty_t__c);
    }

    @IsTest
    static void upsertByExtKey_shouldReturnEmptyResultsForNullOrEmptyInput() {
        LotRepository repo = new LotRepository();

        System.assertEquals(0, repo.upsertByExtKey(null).size());
        System.assertEquals(0, repo.upsertByExtKey(new List<Lot__c>()).size());
    }

    private class TestData {
        public OrderItem orderItem1;
        public OrderItem orderItem2;
        public ProdWeeksH__c julyWeek;
        public ProdWeeksH__c augustWeek;
        public String iteNumber;

        public Lot__c producedLot;
        public Lot__c dispatchedLot;
        public Lot__c shippedLot;
    }

    private static TestData createData() {
        ERPLotTestDataFactory.DataBundle b = ERPLotTestDataFactory.createBaseData();

        TestData data = new TestData();

        data.orderItem1 = b.oi1;
        data.orderItem2 = b.oi2;
        data.julyWeek = b.julyWeek;
        data.augustWeek = b.augustWeek;
        data.iteNumber = ERPLotTestDataFactory.ITE_1;

        data.producedLot = new Lot__c(
            ExtKey__c = data.orderItem1.Id + '#' + data.julyWeek.Id + '#Produced',
            OrderItem__c = data.orderItem1.Id,
            ProdWeek__c = data.julyWeek.Id,
            LotDate__c = Date.newInstance(2024, 7, 25),
            //CDD__c = Date.newInstance(2024, 7, 25),
            LotQty_t__c = 60.210,
            LotType__c = 'Produced'
        );

        data.dispatchedLot = new Lot__c(
            ExtKey__c = data.orderItem1.Id + '#' + data.julyWeek.Id + '#Shipped',
            OrderItem__c = data.orderItem1.Id,
            ProdWeek__c = data.julyWeek.Id,
            LotDate__c = Date.newInstance(2024, 7, 26),
            //CDD__c = Date.newInstance(2024, 7, 26),
            LotQty_t__c = 40.140,
            LotType__c = 'Shipped'
        );

        data.shippedLot = new Lot__c(
            ExtKey__c = data.orderItem1.Id + '#' + data.augustWeek.Id + '#Shipped',
            OrderItem__c = data.orderItem1.Id,
            ProdWeek__c = data.augustWeek.Id,
            LotDate__c = Date.newInstance(2024, 8, 5),
            //CDD__c = Date.newInstance(2024, 8, 5),
            LotQty_t__c = 40.140,
            LotType__c = 'Shipped'
        );

        insert new List<Lot__c>{
            data.producedLot,
            data.dispatchedLot,
            data.shippedLot
        };

        return data;
    }
}