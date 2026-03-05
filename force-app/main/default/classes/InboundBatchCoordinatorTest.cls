@IsTest
private class InboundBatchCoordinatorTest {

    @IsTest
    static void testAcceptPart() {

        String payload =
        '{"metadata":{' +
        '"msgType":"CST",' +
        '"msgTimestamp":"2024-01-01T00:00:00Z",' +
        '"partNumber":1,' +
        '"totalParts":2' +
        '}}';

        Test.startTest();

        InboundBatchCoordinator.Result r =
            InboundBatchCoordinator.acceptPart(payload);

        Test.stopTest();

        System.assertEquals(202, r.httpStatus);

        List<ERP_InboundBatch__c> batches =
            [SELECT Id FROM ERP_InboundBatch__c];

        System.assertEquals(1, batches.size());
    }
}