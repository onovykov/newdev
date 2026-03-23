/*
    Queueable Job
    Саме він тепер є async boundary.
    Callout іде звідси, а не через @future.
*/
public with sharing class OpportunityStageSyncJob implements Queueable, Database.AllowsCallouts {
    private final Set<Id> opportunityIds;

    public OpportunityStageSyncJob(Set<Id> opportunityIds) {
        this.opportunityIds = (opportunityIds == null)
            ? new Set<Id>()
            : opportunityIds.clone();
    }

    public void execute(QueueableContext context) {
        if (opportunityIds.isEmpty()) {
            return;
        }

        OpportunityStageSyncContext.suppressTriggerDispatch = true;
        try {
            IOpportunityStageSyncGateway gateway = OpportunityStageSyncGatewayFactory.create();
            gateway.sync(opportunityIds);
        } finally {
            OpportunityStageSyncContext.suppressTriggerDispatch = false;
        }
    }
}