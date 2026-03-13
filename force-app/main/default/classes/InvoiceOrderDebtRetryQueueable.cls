global with sharing class InvoiceOrderDebtRetryQueueable implements Queueable {
    private List<ERPMessageParser.InvoiceOrderDebtMessageData> source;
    private String origin;
    private Integer retry;
    private Integer retryMax;

    public InvoiceOrderDebtRetryQueueable(
        List<ERPMessageParser.InvoiceOrderDebtMessageData> src,
        String originLabel,
        Integer retry,
        Integer retryMax
    ) {
        this.source = src;
        this.origin = String.isBlank(originLabel) ? 'unknown' : originLabel;
        this.retry = (retry == null) ? 0 : retry;
        this.retryMax = (retryMax == null) ? 6 : retryMax;
    }

    public void execute(QueueableContext qc) {
        // чи біжить зараз наш батч?
        Boolean running = ![
            SELECT Id FROM AsyncApexJob
            WHERE JobType = 'BatchApex'
              AND ApexClass.Name = 'InvoiceOrderDebtCleaning'
              AND Status IN ('Preparing','Queued','Holding','Processing')
            LIMIT 1
        ].isEmpty();

        if (!running) {
            // вільно — запускаємо батч прямо зараз
            Database.executeBatch(
                new InvoiceOrderDebtCleaning(source, origin + ' (retryQ ' + retry + ')', 0, 0, 10),
                1000
            );
            return;
        }

        // ще зайнято — якщо можемо, перезапускаємо себе (self-chain)
        if (retry < retryMax) {
            Integer nextRetry    = retry + 1;
            Integer nextRetryMax = retryMax;

            // У тестовому рантаймі: не ланцюжимося (інакше можна зловити Maximum stack depth)
            if (Test.isRunningTest()) {
                System.debug(LoggingLevel.INFO,
                    'TEST: would enqueue retry (retry=' + retry + ', retryMax=' + retryMax + ')');
                return; // <-- важливо: нічого не enqueue-имо в тестах
            }

            System.enqueueJob(new InvoiceOrderDebtRetryQueueable(
                source,
                origin,
                nextRetry,
                nextRetryMax
            ));
        }
    }
}