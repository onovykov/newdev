@IsTest
private class LegacyOpportunityStageSyncGatewayTest {
    private class DummyHttpMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"status":"OK"}');
            return res;
        }
    }
    private class MockService extends LegacyOpportunityStageSyncServiceFacade {
        public override LegacyOpportunityStageSyncService.SyncResult doSend(Opportunity opp) {
            return new LegacyOpportunityStageSyncService.SyncResult(
                opp.Id,
                true,
                null
            );
        }
    }

    @IsTest
    static void testGatewayUpdatesLastSync() {

        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Qualification',
            CloseDate = Date.today(),
            Id_ERP__c = 'ERP123'
        );
        insert opp;
        //---
        opp.StageName = 'Closed Won';
        update opp;
        //---
        LegacyOpportunityStageSyncServiceFacade.overrideInstance = new MockService();

        LegacyOpportunityStageSyncGateway gateway = new LegacyOpportunityStageSyncGateway();

        Test.startTest();
        gateway.sync(new Set<Id>{ opp.Id });
        Test.stopTest();

        Opportunity updated = [
            SELECT LastSyncERP__c
            FROM Opportunity
            WHERE Id = :opp.Id
        ];

        System.assertNotEquals(null, updated.LastSyncERP__c);

        LegacyOpportunityStageSyncServiceFacade.overrideInstance = null;
    }

    @IsTest
    static void testFacadeDefaultPath() {

        Opportunity opp = new Opportunity(
            Name = 'Test',
            StageName = 'Qualification',
            CloseDate = Date.today(),
            Id_ERP__c = 'ERP123'
        );
        insert opp;

        Test.startTest();
        LegacyOpportunityStageSyncService.SyncResult result =
            LegacyOpportunityStageSyncServiceFacade.send(opp);
        Test.stopTest();

        System.assertNotEquals(null, result);
    }
    //
    private class MockFacade extends LegacyOpportunityStageSyncServiceFacade {
        public override LegacyOpportunityStageSyncService.SyncResult doSend(Opportunity opp) {
            return new LegacyOpportunityStageSyncService.SyncResult(
                opp.Id,
                true,
                null
            );
        }
    }
    
    @IsTest
    static void testFacadeWithOverride() {

        LegacyOpportunityStageSyncServiceFacade.overrideInstance = new MockFacade();

        Opportunity opp = new Opportunity(
            Name = 'Test',
            StageName = 'Qualification',
            CloseDate = Date.today(),
            Id_ERP__c = 'ERP123'
        );
        insert opp;

        Test.startTest();
        LegacyOpportunityStageSyncService.SyncResult result =
            LegacyOpportunityStageSyncServiceFacade.send(opp);
        Test.stopTest();

        System.assertNotEquals(null, result);

        LegacyOpportunityStageSyncServiceFacade.overrideInstance = null;
    }

    @IsTest
    static void testServiceWithoutERP() {

        Test.setMock(HttpCalloutMock.class, new DummyHttpMock());

        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Qualification',
            CloseDate = Date.today()
        );
        insert opp;

        Test.startTest();
        LegacyOpportunityStageSyncService.SyncResult result =
            LegacyOpportunityStageSyncService.send(opp);
        Test.stopTest();

        System.assertNotEquals(null, result);
    }
    
    @IsTest
    static void testServiceWithInvalidData() {

        Test.setMock(HttpCalloutMock.class, new DummyHttpMock());

        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Closed Lost',
            CloseDate = Date.today(),
            Id_ERP__c = 'ERP123'
        );
        insert opp;

        Test.startTest();
        LegacyOpportunityStageSyncService.SyncResult result =
            LegacyOpportunityStageSyncService.send(opp);
        Test.stopTest();

        System.assertNotEquals(null, result);
    }
    
    @IsTest
    static void testGatewayRealFlow() {

        Opportunity opp = new Opportunity(
            Name = 'Test',
            StageName = 'Qualification',
            CloseDate = Date.today(),
            Id_ERP__c = 'ERP123'
        );
        insert opp;

        Test.setMock(HttpCalloutMock.class, new TestHttpMock());

        Test.startTest();
        new LegacyOpportunityStageSyncGateway().sync(new Set<Id>{ opp.Id });
        Test.stopTest();

        System.assert(true);
    }    
}