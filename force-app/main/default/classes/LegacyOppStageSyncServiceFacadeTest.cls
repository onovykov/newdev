@IsTest
private class LegacyOppStageSyncServiceFacadeTest {

    private class MockFacade extends LegacyOpportunityStageSyncServiceFacade {
        public override LegacyOpportunityStageSyncService.SyncResult doSend(Opportunity opp) {
            return new LegacyOpportunityStageSyncService.SyncResult(opp.Id, true, null);
        }
    }

    @IsTest
    static void testOverride() {

        Opportunity opp = new Opportunity(
            Name='Test',
            StageName='Qualification',
            CloseDate=Date.today()
        );
        insert opp;

        LegacyOpportunityStageSyncServiceFacade.overrideInstance = new MockFacade();

        LegacyOpportunityStageSyncService.SyncResult res =
            LegacyOpportunityStageSyncServiceFacade.send(opp);

        System.assertEquals(true, res.success);

        LegacyOpportunityStageSyncServiceFacade.overrideInstance = null;
    }

    @IsTest
    static void testDefaultPath() {

        Opportunity opp = new Opportunity(
            Name='Test',
            StageName='Qualification',
            CloseDate=Date.today()
        );
        insert opp;

        LegacyOpportunityStageSyncService.SyncResult res =
            LegacyOpportunityStageSyncServiceFacade.send(opp);

        System.assertNotEquals(null, res);
    }

    @IsTest
    static void testFacadeWithoutOverride() {

        Opportunity opp = new Opportunity(
            Name='Test',
            StageName='Qualification',
            CloseDate=Date.today()
        );
        insert opp;

        LegacyOpportunityStageSyncService.SyncResult res =
            LegacyOpportunityStageSyncServiceFacade.send(opp);

        System.assertNotEquals(null, res);
    }    
}