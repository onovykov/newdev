@IsTest
private class ERPLotBuilderTest {

    @IsTest
    static void buildAggregatesWithOrderItems_shouldAttachOrderDataAndExtKey() {
        ERPLotTestDataFactory.DataBundle b = ERPLotTestDataFactory.createBaseData();

        ERPLotAggregate agg = new ERPLotAggregate(
            ERPLotTestDataFactory.ITE_1,
            'Produced',
            10,
            Date.newInstance(2024, 7, 25),
            b.julyWeek.Id
        );

        Map<String, List<ERPLotAggregate>> byIte =
            new Map<String, List<ERPLotAggregate>>{
                ERPLotTestDataFactory.ITE_1 => new List<ERPLotAggregate>{ agg },
                'UNKNOWN' => new List<ERPLotAggregate>{
                    new ERPLotAggregate('UNKNOWN', 'Produced', 10, Date.today(), b.julyWeek.Id)
                }
            };

        Map<String, OrderItem> oiByIte =
            new Map<String, OrderItem>{
                ERPLotTestDataFactory.ITE_1 => b.oi1
            };

        List<ERPLotAggregate> result =
            new ERPLotBuilder().buildAggregatesWithOrderItems(byIte, oiByIte);

        System.assertEquals(1, result.size());
        System.assertEquals(b.oi1.Id, result[0].orderItemId);
        //System.assertEquals(b.ord.Id, result[0].orderId);
        System.assertEquals(
            String.valueOf(b.oi1.Id) + '#' + String.valueOf(b.julyWeek.Id) + '#Produced',
            result[0].extKey
        );
    }

    @IsTest
    static void buildLotsForUpsert_shouldBuildNewLots() {
        ERPLotTestDataFactory.DataBundle b = ERPLotTestDataFactory.createBaseData();

        ERPLotAggregate agg = new ERPLotAggregate(
            ERPLotTestDataFactory.ITE_1,
            'Produced',
            10,
            Date.newInstance(2024, 7, 25),
            b.julyWeek.Id
        );

        //agg.orderId = b.ord.Id;
        agg.orderItemId = b.oi1.Id;
        agg.extKey = ERPLotKeyUtil.buildExtKey(b.oi1.Id, b.julyWeek.Id, 'Produced');

        List<Lot__c> lots =
            new ERPLotBuilder().buildLotsForUpsert(
                new List<ERPLotAggregate>{ agg },
                new Map<String, Lot__c>()
            );

        System.assertEquals(1, lots.size());
        System.assertEquals(agg.extKey, lots[0].ExtKey__c);
        // System.assertEquals(ERPLotTestDataFactory.ITE_1, lots[0].ITENumber__c);
        // System.assertEquals(b.ord.Id, lots[0].Order__c);
        System.assertEquals(b.oi1.Id, lots[0].OrderItem__c);
        System.assertEquals(b.julyWeek.Id, lots[0].ProdWeek__c);
    }

    @IsTest
    static void buildLotsForUpsert_shouldUpdateExistingLots() {
        ERPLotTestDataFactory.DataBundle b = ERPLotTestDataFactory.createBaseData();

        String extKey = ERPLotKeyUtil.buildExtKey(b.oi1.Id, b.julyWeek.Id, 'Produced');

        Lot__c existing = new Lot__c(
            //Name = 'Old Name',
            ExtKey__c = extKey,
            //ITENumber__c = ERPLotTestDataFactory.ITE_1,
            // Order__c = b.ord.Id,
            OrderItem__c = b.oi1.Id,
            ProdWeek__c = b.julyWeek.Id,
            LotDate__c = Date.newInstance(2024, 7, 25),
            LotType__c = 'Produced',
            LotQty_t__c = 1
        );
        insert existing;

        ERPLotAggregate agg = new ERPLotAggregate(
            ERPLotTestDataFactory.ITE_1,
            'Produced',
            99,
            Date.newInstance(2024, 7, 26),
            b.julyWeek.Id
        );

        //agg.orderId = b.ord.Id;
        agg.orderItemId = b.oi1.Id;
        agg.extKey = extKey;

        List<Lot__c> lots =
            new ERPLotBuilder().buildLotsForUpsert(
                new List<ERPLotAggregate>{ agg },
                new Map<String, Lot__c>{ extKey => existing }
            );

        System.assertEquals(1, lots.size());
        System.assertEquals(existing.Id, lots[0].Id);
        System.assertEquals(Decimal.valueOf('99'), lots[0].LotQty_t__c);
        System.assertEquals(Date.newInstance(2024, 7, 26), lots[0].LotDate__c);
    }
}