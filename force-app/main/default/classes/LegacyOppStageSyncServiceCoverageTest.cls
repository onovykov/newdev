@IsTest
private class LegacyOppStageSyncServiceCoverageTest {

    /**
     * Dummy HTTP mock — покриває будь-який callout
     */
    private class DummyHttpMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"status":"OK"}');
            return res;
        }
    }

    @IsTest
    static void testServiceExecution() {

        // Arrange
        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Qualification',
            CloseDate = Date.today(),
            Id_ERP__c = 'ERP123'
        );
        insert opp;

        // Підключаємо mock для callout
        Test.setMock(HttpCalloutMock.class, new DummyHttpMock());

        // Act
        Test.startTest();

        LegacyOpportunityStageSyncService.SyncResult result =
            LegacyOpportunityStageSyncService.send(opp);

        Test.stopTest();

        // Assert
        System.assertNotEquals(null, result, 'Result should not be null');
    }
}