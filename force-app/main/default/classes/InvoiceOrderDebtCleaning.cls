public with sharing class InvoiceOrderDebtCleaning
    implements Database.Batchable<SObject>, Database.Stateful {

    private final InvoiceOrderDebtJobConfig cfg;

    private Integer deletedOk = 0, alreadyDeleted = 0, otherErr = 0;

    // DO NOT REMOVE: зворотна сумісність зі старим кодом
    public InvoiceOrderDebtCleaning(List<ERPMessageParser.InvoiceOrderDebtMessageData> src) {
        this(src, 'unknown', 0, 6);
    }

    public InvoiceOrderDebtCleaning(
        List<ERPMessageParser.InvoiceOrderDebtMessageData> src,
        String originLabel
    ) {
        this(src, originLabel, 0, 6);
    }

    public InvoiceOrderDebtCleaning(
        List<ERPMessageParser.InvoiceOrderDebtMessageData> src,
        String originLabel,
        Integer retry,
        Integer retryMax
    ) {
        this.cfg = new InvoiceOrderDebtJobConfig(src, originLabel, retry, retryMax);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        List<AsyncApexJob> others = [
            SELECT Id
            FROM AsyncApexJob
            WHERE JobType = 'BatchApex'
              AND ApexClass.Name = 'InvoiceOrderDebtCleaning'
              AND Status IN ('Preparing','Queued','Holding','Processing')
              AND Id != :bc.getJobId()
            LIMIT 1
        ];
        if (!others.isEmpty()) {
            if (cfg.retry < cfg.retryMax) {
                System.enqueueJob(
                    new InvoiceOrderDebtRetryQueueable(cfg.source, cfg.origin, cfg.retry + 1, cfg.retryMax)
                );
            }
            return Database.getQueryLocator([SELECT Id FROM InvoiceOrderDebt__c WHERE Id = NULL]);
        }

        Datetime dt = Datetime.now().addMinutes(-15);
        return Database.getQueryLocator([
            SELECT Id
            FROM InvoiceOrderDebt__c
            WHERE CreatedDate < :dt
        ]);
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        Database.DeleteResult[] results = Database.delete(scope, /* allOrNone */ false);

        for (Database.DeleteResult r : results) {
            if (r.isSuccess()) {
                deletedOk++; continue;
            }
            for (Database.Error e : r.getErrors()) {
                if (e.getStatusCode() == StatusCode.ENTITY_IS_DELETED) {
                    alreadyDeleted++;
                } else {
                    otherErr++;
                    System.debug(LoggingLevel.WARN,
                        'Delete error for Id=' + r.getId() + ': ' +
                        e.getStatusCode() + ' ' + e.getMessage());
                }
            }
        }
    }

    public void finish(Database.BatchableContext bc) {
        AsyncApexJob j = [
            SELECT Id, ApexClass.Name, Status, CreatedById, CreatedBy.Name,
                   ParentJobId, CronTriggerId, JobType, ExtendedStatus, CreatedDate
            FROM AsyncApexJob
            WHERE Id = :bc.getJobId()
            LIMIT 1
        ];

        CronTrigger ct;
        if (j.CronTriggerId != null) {
            ct = [
                SELECT Id, CronExpression, TimesTriggered, NextFireTime, State, OwnerId
                FROM CronTrigger
                WHERE Id = :j.CronTriggerId
                LIMIT 1
            ];
        } else if (j.ParentJobId != null) {
            AsyncApexJob parent = [
                SELECT Id, CronTriggerId
                FROM AsyncApexJob
                WHERE Id = :j.ParentJobId
                LIMIT 1
            ];
            if (parent.CronTriggerId != null) {
                ct = [
                    SELECT Id, CronExpression, TimesTriggered, NextFireTime, State, OwnerId
                    FROM CronTrigger
                    WHERE Id = :parent.CronTriggerId
                    LIMIT 1
                ];
            }
        }

        if (cfg.source != null && !cfg.source.isEmpty()) {
            Database.executeBatch(new InvoiceOrderDebtBatch(cfg.source), 1000);
        }
    }
}