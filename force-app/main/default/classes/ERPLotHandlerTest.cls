@IsTest
private class ERPLotHandlerTest {

    @IsTest
    static void getLotList_shouldReturnDryRunLotsWithoutInsert() {
        ERPLotTestDataFactory.createBaseData();

        Test.startTest();
        List<Lot__c> lots = ERPLotHandler.getLotList(
            ERPLotTestDataFactory.buildMainParsedMessage()
        );
        Test.stopTest();

        System.assertEquals(3, lots.size(), 'Expected 3 aggregated lots');
        System.assertEquals(0, [SELECT COUNT() FROM Lot__c], 'Dry-run must not insert Lot__c');

        Map<String, Lot__c> byType = new Map<String, Lot__c>();
        for (Lot__c l : lots) {
            byType.put(l.LotType__c, l);
        }

        System.assert(byType.containsKey('Produced'));
        System.assert(byType.containsKey('Shipped'));
        System.assert(byType.containsKey('Delivered'));

        System.assertEquals(Decimal.valueOf('100.35'), byType.get('Produced').LotQty_t__c);
        System.assertEquals(Date.newInstance(2024, 7, 26), byType.get('Produced').LotDate__c);

        System.assertEquals(Decimal.valueOf('100.35'), byType.get('Shipped').LotQty_t__c);
        System.assertEquals(Date.newInstance(2024, 7, 26), byType.get('Shipped').LotDate__c);

        System.assertEquals(Decimal.valueOf('100.35'), byType.get('Delivered').LotQty_t__c);
        System.assertEquals(Date.newInstance(2024, 8, 6), byType.get('Delivered').LotDate__c);
    }

    @IsTest
    static void fillAggregateLots_shouldHandleNullParsed() {
        Test.startTest();
        ERPLotHandler.fillAggregateLots(null, true);
        Test.stopTest();

        System.assertEquals(0, ERPLotHandler.getLotList(null).size());
    }
}