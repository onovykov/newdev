public with sharing class PARApprovalQueueable
    implements Queueable, Database.AllowsCallouts {

    private Id parId;
    private String resolution;
    private String comment;

    public PARApprovalQueueable(
        Id parId,
        String resolution,
        String comment
    ) {
        this.parId = parId;
        this.resolution = resolution;
        this.comment = comment;
    }

    public void execute(QueueableContext context) {

        PriceApprovalRequest__c par =
            [SELECT Id, ID_ERP__c, RetryCount__c
             FROM PriceApprovalRequest__c
             WHERE Id = :parId
             LIMIT 1];

        try {
            PARApprovalERPAdapter.ERPResponse response =
                PARApprovalERPAdapter.sendApproval(
                    par.ID_ERP__c,
                    resolution,
                    comment
                );

            if (response == null || response.Status == false) {
                markFailure(
                    par,
                    response == null
                        ? 'Null response'
                        : response.ErrorMessage
                );
                return;
            }

            // SUCCESS
            markComplete(par);

            // Stage update
            PARStageUpdateService.applyERPStage(
                par,
                response.PAMRequestInfo.Stage
            );

            // History write
            PARHistoryWriteService.addFromERPResponse(
                par.Id,
                response
            );

        } catch (Exception e) {
            markFailure(par, e.getMessage());
        }
    }

    private void markComplete(PriceApprovalRequest__c par) {

        par.ApprovalStatus__c = 'Complete';
        par.LastErrorMessage__c = null;
        par.LastAttemptDate__c = System.now();

        update par;
    }

    private void markFailure(
        PriceApprovalRequest__c par,
        String error
    ) {

        PARRetryPolicy__mdt policy =
            PARRetryPolicy__mdt.getInstance('Default');

        Integer maxRetries =
            Integer.valueOf(policy == null ? 3 : policy.MaxRetries__c);

        Integer retries =
            Integer.valueOf((par.RetryCount__c == null ? 0 : par.RetryCount__c) + 1);

        par.RetryCount__c = retries;
        par.LastErrorMessage__c = error;
        par.LastAttemptDate__c = System.now();

        if (retries >= maxRetries) {
            par.ApprovalStatus__c = 'Dead';
            PARDeadNotificationService.notify(par);
        } else {
            par.ApprovalStatus__c = 'Failure';
        }

        update par;
    }
}