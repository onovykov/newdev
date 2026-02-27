@IsTest
private class AsyncExecutorInsDelAsyncCoverageTest {

    private static AsyncConfig cfgQ() {
        AsyncConfig c = new AsyncConfig();
        c.syncLimit  = 1;
        c.queueLimit = 2;
        c.batchSize  = 200;
        return c;
    }

    private static AsyncConfig cfgB() {
        AsyncConfig c = new AsyncConfig();
        c.syncLimit  = 1;
        c.queueLimit = 2;
        c.batchSize  = 200; // щоб був 1 chunk
        return c;
    }

    private static List<SObject> sobjs(Integer n) {
        List<SObject> s = new List<SObject>();
        s.addAll(TestDataFactory.createAccounts(n)); // якщо factory INSERT-ить — ок
        return s;
    }

    @IsTest
    static void coverInsertQueueable() {
        AsyncExecutor.FORCE_SYNC_FOR_TESTS = false;

        Test.startTest();
        AsyncExecutorResult r =
            AsyncExecutor.insertSmart(sobjs(2), cfgQ(), false);
        Test.stopTest();

        System.assertEquals(AsyncExecutionMode.QUEUEABLE, r.mode);
    }

    @IsTest
    static void coverDeleteBatch() {
        AsyncExecutor.FORCE_SYNC_FOR_TESTS = false;

        // delete needs persisted records; якщо factory вже insert-ить — ок
        List<SObject> three = sobjs(3);

        Test.startTest();
        AsyncExecutorResult r =
            AsyncExecutor.deleteSmart(three, cfgB(), false);
        Test.stopTest();

        System.assertEquals(AsyncExecutionMode.BATCH, r.mode);
    }
}