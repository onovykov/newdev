@IsTest
private class AsyncExecutorResultFinalCoverageTest {

    @IsTest
    static void coverAllFields() {
        AsyncExecutorResult r = new AsyncExecutorResult();

        r.mode = AsyncExecutionMode.BATCH;
        r.recordCount = 123;
        r.message = 'ok';
        r.asyncJobId = '707000000000000';
        r.executedAt = System.now();
        r.configName = 'CFG';

        System.assertEquals(123, r.recordCount);
    }
}