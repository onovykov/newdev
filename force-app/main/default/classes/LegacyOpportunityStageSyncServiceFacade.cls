public virtual class LegacyOpportunityStageSyncServiceFacade {

    @TestVisible
    static LegacyOpportunityStageSyncServiceFacade overrideInstance;

    public static LegacyOpportunityStageSyncService.SyncResult send(Opportunity opp) {
        if (Test.isRunningTest() && overrideInstance != null) {
            return overrideInstance.doSend(opp);
        }
        return LegacyOpportunityStageSyncService.send(opp);
    }

    public virtual LegacyOpportunityStageSyncService.SyncResult doSend(Opportunity opp) {
        return LegacyOpportunityStageSyncService.send(opp);
    }
}