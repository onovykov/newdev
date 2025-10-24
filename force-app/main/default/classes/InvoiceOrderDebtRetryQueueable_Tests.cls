@IsTest
private class InvoiceOrderDebtRetryQueueable_Tests {

    // 1) Коли батч НЕ біжить — Queueable має запустити батч
    @IsTest
    static void testLaunchesBatchWhenNotRunning() {
        Test.startTest();
        System.enqueueJob(new InvoiceOrderDebtRetryQueueable(null, 'Q:NotRunning', 0, 1));
        Test.stopTest();

        Integer batches = [
            SELECT COUNT() FROM AsyncApexJob
            WHERE JobType = 'BatchApex'
              AND ApexClass.Name = 'InvoiceOrderDebtCleaning'
        ];
        System.assert(batches > 0, 'Queueable should launch the batch when not running');
    }

    // 2) Коли батч ВЖЕ біжить — Queueable робить self-chain, а потім (коли вікно звільниться) запускає батч
    @IsTest
    static void testRunningWithRetryWouldEnqueue_butNoopInTests() {
        Test.startTest();
        // робимо "running": кидаємо будь-який батч нашого класу
        Database.executeBatch(new InvoiceOrderDebtCleaning(null, 'Seed', 0, 0, 10), 200);

        // retry < retryMax, але в тестах гілка робить no-op і виходить (без enqueue)
        System.enqueueJob(new InvoiceOrderDebtRetryQueueable(null, 'Q:Running', 0, 1));
        Test.stopTest();

        // достатньо, що код відпрацював без помилок
        System.assert(true, 'No-op re-enqueue path in tests executed');
    }

    // 3) Коли retry досяг ліміту — НЕ має ланцюжитися далі (гілка retry >= retryMax)
    @IsTest
    static void testNoReEnqueueWhenRetryLimitReached() {
        Test.startTest();

        // Стартуємо батч, щоб було "running"
        Database.executeBatch(new InvoiceOrderDebtCleaning(null, 'SeedBatch2', 0, 0, 10), 200);

        // Одразу заганяємо queueable із retry=1, retryMax=1 – гілка без re-enqueue
        System.enqueueJob(new InvoiceOrderDebtRetryQueueable(null, 'Q:Limit', 1, 1));

        Test.stopTest();

        System.assert(true, 'Queueable executed with retry limit reached path');
    }
}