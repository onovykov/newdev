@IsTest
private class ERPLotAccumulatorTest {

    @IsTest
    static void accumulator_shouldAggregateSumsAndMaxDates() {
        ERPLotTestDataFactory.createBaseData();

        ERPLotAccumulator acc =
            new ERPLotAccumulator(ERPLotTestDataFactory.ITE_1);

        acc.add(ERPLotTestDataFactory.buildLot('2024-07-25T00:00:00', '1.111', '2.222', '0'));
        acc.add(ERPLotTestDataFactory.buildLot('2024-07-26T00:00:00', '3.335', '4.444', '0'));
        acc.add(ERPLotTestDataFactory.buildLot('2024-08-06T00:00:00', '0', '0', '5.555'));

        List<ERPLotAggregate> aggregates = acc.toAggregates();

        System.assertEquals(3, aggregates.size());

        Map<String, ERPLotAggregate> byType = new Map<String, ERPLotAggregate>();
        for (ERPLotAggregate a : aggregates) {
            byType.put(a.lotType, a);
        }

        System.assertEquals(Decimal.valueOf('4.45'), byType.get('Produced').lotQty);
        System.assertEquals(Date.newInstance(2024, 7, 26), byType.get('Produced').lotDate);

        System.assertEquals(Decimal.valueOf('6.66'), byType.get('Shipped').lotQty);
        System.assertEquals(Date.newInstance(2024, 7, 26), byType.get('Shipped').lotDate);

        System.assertEquals(Decimal.valueOf('5.56'), byType.get('Delivered').lotQty);
        System.assertEquals(Date.newInstance(2024, 8, 6), byType.get('Delivered').lotDate);
    }

    @IsTest
    static void accumulator_shouldSkipInvalidDatesAndNullLots() {
        ERPLotTestDataFactory.createBaseData();

        ERPLotAccumulator acc =
            new ERPLotAccumulator(ERPLotTestDataFactory.ITE_1);

        acc.add(null);
        acc.add(ERPLotTestDataFactory.buildLot(null, '10', '10', '10'));
        acc.add(ERPLotTestDataFactory.buildLot('bad-date', '10', '10', '10'));

        System.assertEquals(0, acc.toAggregates().size());
    }

    @IsTest
    static void accumulator_shouldSkipWhenNoProdWeekFound() {
        ERPLotTestDataFactory.createBaseData();

        ERPLotAccumulator acc =
            new ERPLotAccumulator(ERPLotTestDataFactory.ITE_1);

        acc.add(ERPLotTestDataFactory.buildLot('2030-01-01T00:00:00', '10', '0', '0'));

        System.assertEquals(0, acc.toAggregates().size());
    }
}