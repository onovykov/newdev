public class OpportunityStageSyncContext {
    public static Boolean suppressTriggerDispatch = false;

    @TestVisible
    public static Boolean allowDispatchInTest = false;

    public static Set<Id> queuedOpportunityIds = new Set<Id>();

    public static void reset() {
        suppressTriggerDispatch = false;
        allowDispatchInTest = false;
        queuedOpportunityIds.clear();
    }
/*
    @TestVisible
    public static Boolean suppressTriggerDispatch = false;

    @TestVisible
    public static Set<Id> queuedOpportunityIds = new Set<Id>();

    @TestVisible
    public static void reset() {
        suppressTriggerDispatch = false;
        queuedOpportunityIds.clear();
    }
    */
}