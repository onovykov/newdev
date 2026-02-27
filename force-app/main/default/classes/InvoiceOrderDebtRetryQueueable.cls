global with sharing class InvoiceOrderDebtRetryQueueable implements Queueable {

    // Off by default. A single test sets this to true, calls execute() directly,
    // then immediately resets it to false so the chained queueable stays safe.
    @TestVisible
    private static Boolean allowEnqueueInTests = false;

    private final InvoiceOrderDebtJobConfig cfg;

    public InvoiceOrderDebtRetryQueueable(
        List<ERPMessageParser.InvoiceOrderDebtMessageData> src,
        String originLabel,
        Integer retry,
        Integer retryMax
    ) {
        this.cfg = new InvoiceOrderDebtJobConfig(src, originLabel, retry, retryMax);
    }

    public void execute(QueueableContext qc) {
        Boolean running = ![
            SELECT Id FROM AsyncApexJob
            WHERE JobType = 'BatchApex'
              AND ApexClass.Name = 'InvoiceOrderDebtCleaning'
              AND Status IN ('Preparing','Queued','Holding','Processing')
            LIMIT 1
        ].isEmpty();

        if (!running) {
            Database.executeBatch(
                new InvoiceOrderDebtCleaning(cfg.source, cfg.origin + ' (retryQ ' + cfg.retry + ')', 0, 0),
                1000
            );
            return;
        }

        if (cfg.retry < cfg.retryMax) {
            if (Test.isRunningTest() && !allowEnqueueInTests) {
                System.debug(LoggingLevel.INFO,
                    'TEST: would enqueue retry (retry=' + cfg.retry + ', retryMax=' + cfg.retryMax + ')');
                return;
            }

            System.enqueueJob(new InvoiceOrderDebtRetryQueueable(
                cfg.source,
                cfg.origin,
                cfg.retry + 1,
                cfg.retryMax
            ));
        }
    }
}