@IsTest
private class LotRepositoryTest {

    @IsTest
    static void getByExtKeys_shouldReturnExistingLots() {
        ERPLotTestDataFactory.DataBundle b = ERPLotTestDataFactory.createBaseData();

        String extKey = ERPLotKeyUtil.buildExtKey(b.oi1.Id, b.julyWeek.Id, 'Produced');

        Lot__c lotRecord = new Lot__c(
            //Name = 'Repo Test Lot',
            ExtKey__c = extKey,
            //ITENumber__c = ERPLotTestDataFactory.ITE_1,
            // Order__c = b.ord.Id,
            OrderItem__c = b.oi1.Id,
            ProdWeek__c = b.julyWeek.Id,
            LotDate__c = Date.newInstance(2024, 7, 25),
            LotType__c = 'Produced',
            LotQty_t__c = 10
        );
        insert lotRecord;

        Map<String, Lot__c> found =
            new LotRepository().getByExtKeys(new Set<String>{ extKey });

        System.assertEquals(1, found.size());
        System.assertEquals(lotRecord.Id, found.get(extKey).Id);
    }

    @IsTest
    static void getByExtKeys_shouldHandleEmptyInput() {
        System.assertEquals(0, new LotRepository().getByExtKeys(null).size());
        System.assertEquals(0, new LotRepository().getByExtKeys(new Set<String>()).size());
    }

    @IsTest
    static void upsertByExtKey_shouldInsertAndUpdate() {
        ERPLotTestDataFactory.DataBundle b = ERPLotTestDataFactory.createBaseData();

        String extKey = ERPLotKeyUtil.buildExtKey(b.oi1.Id, b.julyWeek.Id, 'Produced');

        Lot__c lotRecord = new Lot__c(
            //Name = 'Upsert Lot',
            ExtKey__c = extKey,
            //ITENumber__c = ERPLotTestDataFactory.ITE_1,
            // Order__c = b.ord.Id,
            OrderItem__c = b.oi1.Id,
            ProdWeek__c = b.julyWeek.Id,
            LotDate__c = Date.newInstance(2024, 7, 25),
            LotType__c = 'Produced',
            LotQty_t__c = 10
        );

        Database.UpsertResult[] insertRes =
            new LotRepository().upsertByExtKey(new List<Lot__c>{ lotRecord });

        System.assertEquals(true, insertRes[0].isSuccess());
        System.assertEquals(1, [SELECT COUNT() FROM Lot__c WHERE ExtKey__c = :extKey]);

        Lot__c existing = [
            SELECT Id, ExtKey__c, LotQty_t__c
            FROM Lot__c
            WHERE ExtKey__c = :extKey
            LIMIT 1
        ];

        existing.LotQty_t__c = 25;

        Database.UpsertResult[] updateRes =
            new LotRepository().upsertByExtKey(new List<Lot__c>{ existing });

        System.assertEquals(true, updateRes[0].isSuccess());

        Lot__c updated = [
            SELECT LotQty_t__c
            FROM Lot__c
            WHERE ExtKey__c = :extKey
            LIMIT 1
        ];

        System.assertEquals(Decimal.valueOf('25'), updated.LotQty_t__c);
    }

    @IsTest
    static void upsertByExtKey_shouldHandleEmptyInput() {
        System.assertEquals(0, new LotRepository().upsertByExtKey(null).size());
        System.assertEquals(0, new LotRepository().upsertByExtKey(new List<Lot__c>()).size());
    }
}