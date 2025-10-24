public with sharing class InvoiceOrderDebtCleaning
    implements Database.Batchable<SObject>, Database.Stateful {

    private List<ERPMessageParser.InvoiceOrderDebtMessageData> source;
    private String origin = 'unknown';
    private Integer retry = 0, retryMax = 6, retryDelayMin = 10;

    // Лічильники для статистики
    Integer deletedOk = 0, alreadyDeleted = 0, otherErr = 0;

    // ЗВОРОТНО-СУМІСНИЙ КОНСТРУКТОР (старі виклики з одним аргументом)
    // DO NOT REMOVE: лишаємо для сумісності зі старим кодом
    public InvoiceOrderDebtCleaning(List<ERPMessageParser.InvoiceOrderDebtMessageData> src) {
        this(src, 'unknown', 0, 6, 10);
    }

    // Поточний з originLabel
    public InvoiceOrderDebtCleaning(
        List<ERPMessageParser.InvoiceOrderDebtMessageData> src,
        String originLabel
    ) {
        this(src, originLabel, 0, 6, 10);
    }

    // Базовий із усіма параметрами
    public InvoiceOrderDebtCleaning(
        List<ERPMessageParser.InvoiceOrderDebtMessageData> src,
        String originLabel,
        Integer retry,
        Integer retryMax,
        Integer retryDelayMin
    ) {
        this.source = src;
        this.origin = String.isBlank(originLabel) ? 'unknown' : originLabel;
        this.retry = (retry == null) ? 0 : retry;
        this.retryMax = (retryMax == null) ? 6 : retryMax;
        this.retryDelayMin = (retryDelayMin == null) ? 10 : retryDelayMin;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        // шукаємо інший активний job цього ж класу
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
            // План А: ретрі через Queueable
            if (retry < retryMax) {
                System.enqueueJob(
                    new InvoiceOrderDebtRetryQueueable(source, origin, retry + 1, retryMax)
                );
            }
            // культурний вихід (порожній QueryLocator)
            return Database.getQueryLocator([SELECT Id FROM InvoiceOrderDebt__c WHERE Id = null]);
        }

        Datetime dt = Datetime.now().addMinutes(-15);
        return Database.getQueryLocator([
            SELECT Id
            FROM InvoiceOrderDebt__c
            WHERE CreatedDate < :dt
        ]);
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        if (scope == null || scope.isEmpty()) return;

        // Partial delete
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

        // Шукаємо CronTrigger також у батьківському job (для scheduleBatch)
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

        System.debug(LoggingLevel.INFO,
            'InvoiceOrderDebtCleaning finish — origin=' + origin +
            ', jobId=' + j.Id +
            ', by=' + j.CreatedBy.Name +
            ', jobType=' + j.JobType +
            ', viaScheduler=' + (ct != null) +
            (ct != null ? ', nextFire=' + ct.NextFireTime : '') +
            '; stats: deleted=' + deletedOk +
            ', alreadyDeleted=' + alreadyDeleted +
            ', otherErrors=' + otherErr
        );

        if (source != null && !source.isEmpty()) {
            Database.executeBatch(new InvoiceOrderDebtBatch(source), 1000);
        }
    }
}