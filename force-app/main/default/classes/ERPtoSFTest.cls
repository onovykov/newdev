@IsTest
private class ERPtoSFTest {

    @IsTest
    static void testNewPipeline() {

        ERPtoSF.overrideUseOld = false;

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestBody = Blob.valueOf(
            '{"metadata":{"msgType":"CST","partNumber":1}}'
        );

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();

        ERPtoSF.postCST();

        Test.stopTest();

        System.assertNotEquals(null, res.statusCode);
    }

}