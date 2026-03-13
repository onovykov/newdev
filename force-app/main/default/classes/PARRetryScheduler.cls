public with sharing class PARRetryScheduler
    implements Schedulable {

    public void execute(SchedulableContext sc) {

        PARRetryPolicy__mdt policy =
            PARRetryPolicy__mdt.getInstance('Default');

        if (policy == null) {
            return;
        }

        Integer intervalSeconds =
            Integer.valueOf(policy.RetryIntervalMinutes__c) * 60;

        Datetime retryThreshold =
            System.now().addSeconds(-intervalSeconds);

        List<PriceApprovalRequest__c> failed =
            [SELECT Id,
                    RetryCount__c,
                    LastAttemptDate__c
             FROM PriceApprovalRequest__c
             WHERE ApprovalStatus__c = 'Failure'
             AND RetryCount__c < :policy.MaxRetries__c
             AND LastAttemptDate__c <= :retryThreshold];

        for (PriceApprovalRequest__c par : failed) {
            System.enqueueJob(
                new PARApprovalQueueable(
                    par.Id,
                    null,
                    null
                )
            );
        }
    }
}