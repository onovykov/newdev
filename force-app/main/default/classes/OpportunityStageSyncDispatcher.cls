/*
    Один entrypoint із trigger layer.
    Збирає Set<Id>, не дає ставити дублікати в межах транзакції, enqueue-ить один Queueable.
*/
public with sharing class OpportunityStageSyncDispatcher {
    public static void dispatch(Set<Id> oppIds) {
        if (oppIds == null || oppIds.isEmpty()) {
            return;
        }

        if (OpportunityStageSyncContext.suppressTriggerDispatch) {
            return;
        }

        Set<Id> idsToQueue = new Set<Id>();
        for (Id oppId : oppIds) {
            if (oppId != null && !OpportunityStageSyncContext.queuedOpportunityIds.contains(oppId)) {
                idsToQueue.add(oppId);
            }
        }

        if (idsToQueue.isEmpty()) {
            return;
        }

        OpportunityStageSyncContext.queuedOpportunityIds.addAll(idsToQueue);
        System.enqueueJob(new OpportunityStageSyncJob(idsToQueue));
    }
}