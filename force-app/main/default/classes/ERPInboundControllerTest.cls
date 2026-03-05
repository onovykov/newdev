@IsTest
private class ERPInboundControllerTest {

    @IsTest
    static void testController() {

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestBody = Blob.valueOf(
            '{"metadata":{' +
            '"msgType":"CST",' +
            '"msgTimestamp":"2024-01-01T00:00:00Z",' +
            '"partNumber":1,' +
            '"totalParts":1' +
            '}}'
        );

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();

        ERPInboundController.handle(req,res);

        Test.stopTest();

        System.assertEquals(202, res.statusCode);
    }
}