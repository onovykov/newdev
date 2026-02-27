@IsTest
private class InvoiceOrderDebtRetryQueueable_Tests {

    // ─── MockQueueableContext ────────────────────────────────────────────────
    // QueueableContext is an interface; execute() never reads the job ID,
    // so returning null is safe.

    private class MockQueueableContext implements QueueableContext {
        public Id getJobId() { return null; }
    }

    // ─── Helpers ────────────────────────────────────────────────────────────

    private static Integer countCleaningBatchJobs() {
        return [
            SELECT COUNT() FROM AsyncApexJob
            WHERE JobType = 'BatchApex'
              AND ApexClass.Name = 'InvoiceOrderDebtCleaning'
        ];
    }

    // ─── PATH 1: batch NOT running → launch new batch ───────────────────────

    @IsTest
    static void testLaunchesBatchWhenNotRunning() {
        Test.startTest();
        System.enqueueJob(new InvoiceOrderDebtRetryQueueable(null, 'Q:NotRunning', 0, 1));
        Test.stopTest();

        System.assert(countCleaningBatchJobs() > 0,
            'Queueable should launch InvoiceOrderDebtCleaning batch when none is running');
    }

    @IsTest
    static void testLaunchesBatchWithNonNullSource() {
        List<ERPMessageParser.InvoiceOrderDebtMessageData> src =
            new List<ERPMessageParser.InvoiceOrderDebtMessageData>();

        Test.startTest();
        System.enqueueJob(new InvoiceOrderDebtRetryQueueable(src, 'Q:WithSource', 2, 5));
        Test.stopTest();

        System.assert(countCleaningBatchJobs() > 0,
            'Should launch batch even with a non-null source list');
    }

    @IsTest
    static void testLaunchesBatchWithHighRetryNumber() {
        Test.startTest();
        System.enqueueJob(new InvoiceOrderDebtRetryQueueable(null, 'Q:HighRetry', 5, 6));
        Test.stopTest();

        System.assert(countCleaningBatchJobs() > 0,
            'Should launch batch when no batch is running, regardless of retry counter value');
    }

    // ─── PATH 2 (real enqueue) — covers lines 38-43 ─────────────────────────

    @IsTest
    static void testSystemEnqueueJobCalled_whenBatchRunning() {
        // Strategy to avoid stack overflow:
        //   1. Seed a batch (it goes to 'Queued' status).
        //   2. Set allowEnqueueInTests = true.
        //   3. Call execute() DIRECTLY via MockQueueableContext — no System.enqueueJob overhead.
        //      This causes lines 38-43 (System.enqueueJob) to run and queue ONE chained job.
        //   4. Immediately reset allowEnqueueInTests = false — the chained job will
        //      run during Test.stopTest() and take the safe no-op/batch path, not recurse.

        Test.startTest();
        Database.executeBatch(new InvoiceOrderDebtCleaning(null, 'Seed:DirectExec', 0, 0), 200);
        // Batch is 'Queued' → execute() will see running = true.

        InvoiceOrderDebtRetryQueueable.allowEnqueueInTests = true;
        new InvoiceOrderDebtRetryQueueable(null, 'Q:DirectExec', 0, 1)
            .execute(new MockQueueableContext()); // lines 38-43 are covered here
        InvoiceOrderDebtRetryQueueable.allowEnqueueInTests = false;
        // Flag is off before Test.stopTest(), so the chained queueable
        // will not call System.enqueueJob again → no recursion.

        Test.stopTest();

        // System.enqueueJob in lines 38-43 created exactly one chained queueable job.
        Integer queueableCount = [
            SELECT COUNT() FROM AsyncApexJob WHERE JobType = 'Queueable'
        ];
        System.assert(queueableCount >= 1,
            'Lines 38-43 covered: System.enqueueJob must have created a chained retry queueable');
    }

    // ─── PATH 2: batch running, retry < retryMax → no-op in test context ───

    @IsTest
    static void testRunningWithRetryWouldEnqueue_butNoopInTests() {
        Test.startTest();
        Database.executeBatch(new InvoiceOrderDebtCleaning(null, 'Seed', 0, 0), 200);
        Integer jobsBeforeQueueable = countCleaningBatchJobs();

        System.enqueueJob(new InvoiceOrderDebtRetryQueueable(null, 'Q:Running', 0, 1));
        Test.stopTest();

        // Queueable detects the batch is running and takes the test no-op path.
        // It must NOT have launched an additional batch on its own.
        Integer jobsAfter = countCleaningBatchJobs();
        System.assert(jobsAfter >= 1,
            'At least the seeded batch job must exist');
        System.assertEquals(jobsBeforeQueueable, jobsAfter,
            'Queueable must NOT launch a second batch when one is already running (test no-op path)');
    }

    @IsTest
    static void testRunningWithHighRetryBelowMax_noopInTests() {
        Test.startTest();
        Database.executeBatch(new InvoiceOrderDebtCleaning(null, 'Seed:HighRetry', 0, 0), 200);
        Integer jobsBeforeQueueable = countCleaningBatchJobs();

        System.enqueueJob(new InvoiceOrderDebtRetryQueueable(null, 'Q:HighRetryRunning', 4, 5));
        Test.stopTest();

        Integer jobsAfter = countCleaningBatchJobs();
        System.assertEquals(jobsBeforeQueueable, jobsAfter,
            'No extra batch should be launched; test no-op path taken (retry=4, retryMax=5)');
    }

    // ─── PATH 3: batch running, retry >= retryMax → do nothing ─────────────

    @IsTest
    static void testNoReEnqueueWhenRetryLimitReached() {
        Test.startTest();
        Database.executeBatch(new InvoiceOrderDebtCleaning(null, 'Seed:Limit', 0, 0), 200);
        Integer jobsBeforeQueueable = countCleaningBatchJobs();

        System.enqueueJob(new InvoiceOrderDebtRetryQueueable(null, 'Q:Limit', 1, 1));
        Test.stopTest();

        Integer jobsAfter = countCleaningBatchJobs();
        System.assertEquals(jobsBeforeQueueable, jobsAfter,
            'Queueable must NOT launch any batch when retry limit is reached (retry=retryMax=1)');
    }

    @IsTest
    static void testNoReEnqueueWhenRetryMaxIsZero() {
        Test.startTest();
        Database.executeBatch(new InvoiceOrderDebtCleaning(null, 'Seed:ZeroMax', 0, 0), 200);
        Integer jobsBeforeQueueable = countCleaningBatchJobs();

        System.enqueueJob(new InvoiceOrderDebtRetryQueueable(null, 'Q:ZeroMax', 0, 0));
        Test.stopTest();

        Integer jobsAfter = countCleaningBatchJobs();
        System.assertEquals(jobsBeforeQueueable, jobsAfter,
            'With retryMax=0, limit is immediately reached; no extra batch should be launched');
    }

    @IsTest
    static void testNoReEnqueueWhenRetryExceedsMax() {
        Test.startTest();
        Database.executeBatch(new InvoiceOrderDebtCleaning(null, 'Seed:Exceeded', 0, 0), 200);
        Integer jobsBeforeQueueable = countCleaningBatchJobs();

        System.enqueueJob(new InvoiceOrderDebtRetryQueueable(null, 'Q:Exceeded', 5, 3));
        Test.stopTest();

        Integer jobsAfter = countCleaningBatchJobs();
        System.assertEquals(jobsBeforeQueueable, jobsAfter,
            'When retry (5) exceeds retryMax (3), no extra batch should be launched');
    }
}