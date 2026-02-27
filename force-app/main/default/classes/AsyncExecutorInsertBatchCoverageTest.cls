@IsTest
private class AsyncExecutorInsertBatchCoverageTest {

    private static AsyncConfig cfgBatch() {
        AsyncConfig c = new AsyncConfig();
        c.syncLimit  = 1;
        c.queueLimit = 2;   // 3 records -> BATCH
        c.batchSize  = 200; // важливо: 1 chunk у тесті
        return c;
    }

    private static List<SObject> newAccountsAsSObjects(Integer n) {
        List<SObject> res = new List<SObject>();
        for (Integer i = 0; i < n; i++) {
            res.add(new Account(Name = 'T-' + i));
        }
        return res;
    }

    @IsTest
    static void coverInsertBatch() {
        AsyncExecutor.FORCE_SYNC_FOR_TESTS = false;

        Test.startTest();
        AsyncExecutorResult r =
            AsyncExecutor.insertSmart(
                newAccountsAsSObjects(3),
                cfgBatch(),
                false
            );
        Test.stopTest();

        System.assertEquals(AsyncExecutionMode.BATCH, r.mode);
    }
}