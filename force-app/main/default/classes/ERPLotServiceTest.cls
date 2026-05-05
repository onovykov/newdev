@IsTest
private class ERPLotServiceTest {

    @IsTest
    static void process_dryRun_shouldBuildLots() {
        ERPLotTestDataFactory.createBaseData();

        ERPLotService service = new ERPLotService();

        Test.startTest();
        ERPLotService.Result res = service.process(
            ERPLotTestDataFactory.buildMainParsedMessage(),
            true
        );
        Test.stopTest();

        System.assertNotEquals(null, res);
        System.assertEquals(3, res.lots.size());
        System.assertEquals(null, res.upsertResults);
    }

    @IsTest
    static void process_realRun_shouldUpsertLots() {
        ERPLotTestDataFactory.createBaseData();

        ERPLotService service = new ERPLotService();

        Test.startTest();
        ERPLotService.Result res = service.process(
            ERPLotTestDataFactory.buildMainParsedMessage(),
            false
        );
        Test.stopTest();

        System.assertEquals(3, res.lots.size());
        System.assertNotEquals(null, res.upsertResults);
        System.assertEquals(3, [SELECT COUNT() FROM Lot__c]);

        for (Lot__c l : [
            SELECT Id, ExtKey__c, ITENumber__c, /*Order__c,*/ OrderItem__c, ProdWeek__c, LotType__c
            FROM Lot__c
        ]) {
            System.assertNotEquals(null, l.ExtKey__c);
            // System.assertNotEquals(null, l.Order__c);
            System.assertNotEquals(null, l.OrderItem__c);
            System.assertNotEquals(null, l.ProdWeek__c);
        }
    }

    @IsTest
    static void process_shouldReturnEmptyForInvalidMessages() {
        ERPLotService service = new ERPLotService();

        System.assertEquals(0, service.process(null, true).lots.size());

        ERPMessageParser.ErpToSfMessage_OpportunityData parsed =
            new ERPMessageParser.ErpToSfMessage_OpportunityData();

        System.assertEquals(0, service.process(parsed, true).lots.size());

        parsed.data = new ERPMessageParser.OrderMessageData();
        System.assertEquals(0, service.process(parsed, true).lots.size());

        parsed.data.items = new List<ERPMessageParser.ERPObject_OrderItem>();
        System.assertEquals(0, service.process(parsed, true).lots.size());
    }

    @IsTest
    static void process_shouldSkipUnknownOrderItem() {
        ERPLotTestDataFactory.createBaseData();

        ERPMessageParser.ErpToSfMessage_OpportunityData parsed =
            ERPLotTestDataFactory.buildSingleItemMessage(
                'UNKNOWN-ITE',
                new List<ERPMessageParser.ERPObject_ProductLot>{
                    ERPLotTestDataFactory.buildLot('2024-07-25T00:00:00', '10', '0', '0')
                }
            );

        ERPLotService.Result res = new ERPLotService().process(parsed, true);

        System.assertEquals(0, res.lots.size());
    }
}