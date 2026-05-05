@IsTest
private class ERPLotKeyUtilTest {

    @IsTest
    static void buildExtKey_shouldBuildExpectedKey() {
        ERPLotTestDataFactory.DataBundle b = ERPLotTestDataFactory.createBaseData();

        String key = ERPLotKeyUtil.buildExtKey(
            b.oi1.Id,
            b.julyWeek.Id,
            'Produced'
        );

        System.assertEquals(
            String.valueOf(b.oi1.Id) + '#' + String.valueOf(b.julyWeek.Id) + '#Produced',
            key
        );
    }

    @IsTest
    static void buildExtKey_shouldReturnNullForInvalidInput() {
        ERPLotTestDataFactory.DataBundle b = ERPLotTestDataFactory.createBaseData();

        System.assertEquals(null, ERPLotKeyUtil.buildExtKey(null, b.julyWeek.Id, 'Produced'));
        System.assertEquals(null, ERPLotKeyUtil.buildExtKey(b.oi1.Id, null, 'Produced'));
        System.assertEquals(null, ERPLotKeyUtil.buildExtKey(b.oi1.Id, b.julyWeek.Id, null));
        System.assertEquals(null, ERPLotKeyUtil.buildExtKey(b.oi1.Id, b.julyWeek.Id, ''));
    }

    @IsTest
    static void collectExtKeys_shouldCollectOnlyValidKeys() {
        ERPLotTestDataFactory.DataBundle b = ERPLotTestDataFactory.createBaseData();

        ERPLotAggregate validAgg = new ERPLotAggregate(
            ERPLotTestDataFactory.ITE_1,
            'Produced',
            10,
            Date.today(),
            b.julyWeek.Id
        );
        validAgg.extKey = ERPLotKeyUtil.buildExtKey(b.oi1.Id, b.julyWeek.Id, 'Produced');

        ERPLotAggregate invalidAgg = new ERPLotAggregate(
            ERPLotTestDataFactory.ITE_1,
            'Shipped',
            10,
            Date.today(),
            b.julyWeek.Id
        );
        invalidAgg.extKey = '';

        Set<String> keys =
            ERPLotKeyUtil.collectExtKeys(new List<ERPLotAggregate>{ validAgg, invalidAgg });

        System.assertEquals(1, keys.size());
        System.assert(keys.contains(validAgg.extKey));
        System.assertEquals(0, ERPLotKeyUtil.collectExtKeys(null).size());
    }
}