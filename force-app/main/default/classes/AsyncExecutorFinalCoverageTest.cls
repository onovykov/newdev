@IsTest
private class AsyncExecutorFinalCoverageTest {

    private static AsyncConfig cfg() {
        AsyncConfig c = new AsyncConfig();
        c.syncLimit  = 1;
        c.queueLimit = 2;
        c.batchSize  = 1;
        return c;
    }

    private static List<SObject> sobjs(Integer n) {
        List<SObject> s = new List<SObject>();
        s.addAll(TestDataFactory.createAccounts(n));
        return s;
    }

    @IsTest
    static void coverQueueableAndBatch() {

        AsyncExecutor.FORCE_SYNC_FOR_TESTS = false;

        insert sobjs(3);

        Test.startTest();
        AsyncExecutorResult q =
            AsyncExecutor.updateSmart(sobjs(2), cfg());
        AsyncExecutorResult b =
            AsyncExecutor.updateSmart(sobjs(3), cfg());
        Test.stopTest();

        System.assertEquals(AsyncExecutionMode.QUEUEABLE, q.mode);
        System.assertEquals(AsyncExecutionMode.BATCH, b.mode);
    }

    @IsTest
    static void coverOverloads() {
        Test.startTest();
        AsyncExecutorResult r =
            AsyncExecutor.updateSmart(sobjs(1));
        Test.stopTest();

        System.assertEquals(AsyncExecutionMode.SYNC, r.mode);
    }
}