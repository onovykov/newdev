@IsTest
private class ERPLotAggregationServiceTest {

    @IsTest
    static void aggregate_shouldMapAndAggregateLots() {
        ERPLotTestDataFactory.createBaseData();

        ERPLotAggregationService service = new ERPLotAggregationService();

        ERPLotAggregationService.AggregationResult res =
            service.aggregate(ERPLotTestDataFactory.buildMainParsedMessage());

        System.assertEquals(false, res.isEmpty());
        System.assertEquals(1, res.iteNumbers.size());
        System.assert(res.iteNumbers.contains(ERPLotTestDataFactory.ITE_1));
        System.assertEquals(3, res.aggregatesByIte.get(ERPLotTestDataFactory.ITE_1).size());

        Map<String, ERPLotAggregate> byType = new Map<String, ERPLotAggregate>();
        for (ERPLotAggregate a : res.aggregatesByIte.get(ERPLotTestDataFactory.ITE_1)) {
            byType.put(a.lotType, a);
        }

        System.assertEquals(Decimal.valueOf('100.35'), byType.get('Produced').lotQty);
        System.assertEquals(Decimal.valueOf('100.35'), byType.get('Shipped').lotQty);
        System.assertEquals(Decimal.valueOf('100.35'), byType.get('Delivered').lotQty);
    }

    @IsTest
    static void aggregate_shouldSkipBlankIte() {
        ERPLotTestDataFactory.createBaseData();

        ERPMessageParser.ErpToSfMessage_OpportunityData parsed =
            ERPLotTestDataFactory.buildSingleItemMessage(
                '',
                new List<ERPMessageParser.ERPObject_ProductLot>{
                    ERPLotTestDataFactory.buildLot('2024-07-25T00:00:00', '10', '0', '0')
                }
            );

        ERPLotAggregationService.AggregationResult res =
            new ERPLotAggregationService().aggregate(parsed);

        System.assertEquals(true, res.isEmpty());
    }

    @IsTest
    static void aggregate_shouldSkipZeroLots() {
        ERPLotTestDataFactory.createBaseData();

        ERPMessageParser.ErpToSfMessage_OpportunityData parsed =
            ERPLotTestDataFactory.buildSingleItemMessage(
                ERPLotTestDataFactory.ITE_1,
                new List<ERPMessageParser.ERPObject_ProductLot>{
                    ERPLotTestDataFactory.buildLot('2024-07-25T00:00:00', '0', '0', '0')
                }
            );

        ERPLotAggregationService.AggregationResult res =
            new ERPLotAggregationService().aggregate(parsed);

        System.assertEquals(true, res.isEmpty());
    }

    @IsTest
    static void aggregate_shouldSkipNullAndEmptyLots() {
        ERPMessageParser.ErpToSfMessage_OpportunityData parsed =
            new ERPMessageParser.ErpToSfMessage_OpportunityData();

        parsed.data = new ERPMessageParser.OrderMessageData();
        parsed.data.items = new List<ERPMessageParser.ERPObject_OrderItem>();

        parsed.data.items.add(null);

        ERPMessageParser.ERPObject_OrderItem itemWithNullLots =
            new ERPMessageParser.ERPObject_OrderItem();
        itemWithNullLots.iteNumber = ERPLotTestDataFactory.ITE_1;
        itemWithNullLots.lots = null;
        parsed.data.items.add(itemWithNullLots);

        ERPMessageParser.ERPObject_OrderItem itemWithEmptyLots =
            new ERPMessageParser.ERPObject_OrderItem();
        itemWithEmptyLots.iteNumber = ERPLotTestDataFactory.ITE_2;
        itemWithEmptyLots.lots = new List<ERPMessageParser.ERPObject_ProductLot>();
        parsed.data.items.add(itemWithEmptyLots);

        ERPLotAggregationService.AggregationResult res =
            new ERPLotAggregationService().aggregate(parsed);

        System.assertEquals(true, res.isEmpty());
    }
}
