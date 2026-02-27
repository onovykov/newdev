@IsTest
private class AsyncExecutorFinalCoverageTest {

    private static List<SObject> sobjs(Integer n) {
        List<SObject> res = new List<SObject>();
        res.addAll(TestDataFactory.createAccounts(n)); // createAccounts already inserts
        return res;
    }

    private static AsyncConfig cfgQueueable() {
        AsyncConfig c = new AsyncConfig();
        c.syncLimit  = 1;
        c.queueLimit = 2;   // 2 records -> QUEUEABLE
        c.batchSize  = 200; // doesn't matter here
        return c;
    }

    private static AsyncConfig cfgBatch() {
        AsyncConfig c = new AsyncConfig();
        c.syncLimit  = 1;
        c.queueLimit = 2;   // 3 records -> BATCH
        c.batchSize  = 200; // MUST be >= recordCount to get one execute() chunk in tests
        return c;
    }

    @IsTest
    static void coverQueueable() {
        AsyncExecutor.FORCE_SYNC_FOR_TESTS = false;

        Test.startTest();
        AsyncExecutorResult r =
            AsyncExecutor.updateSmart(sobjs(2), cfgQueueable());
        Test.stopTest();

        System.assertEquals(AsyncExecutionMode.QUEUEABLE, r.mode);
    }

    @IsTest
    static void coverBatch() {
        AsyncExecutor.FORCE_SYNC_FOR_TESTS = false;

        Test.startTest();
        AsyncExecutorResult r =
            AsyncExecutor.updateSmart(sobjs(3), cfgBatch());
        Test.stopTest();

        System.assertEquals(AsyncExecutionMode.BATCH, r.mode);
    }
}