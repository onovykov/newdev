@IsTest
public class AsyncExecutorResultCoverageTest {

    @IsTest
    static void coverBehaviorMethods() {
        AsyncExecutorResult r = new AsyncExecutorResult();

        // empty
        System.assertEquals(true, r.isEmpty());

        // SYNC
        r.mode = AsyncExecutionMode.SYNC;
        r.recordCount = 1;
        System.assertEquals(false, r.isEmpty());
        System.assertEquals(false, r.isAsync());
        System.assertEquals(true, r.isSuccess());

        // QUEUEABLE
        r.mode = AsyncExecutionMode.QUEUEABLE;
        System.assertEquals(true, r.isAsync());

        // BATCH
        r.mode = AsyncExecutionMode.BATCH;
        System.assertEquals(true, r.isAsync());

        // NOOP
        r.mode = AsyncExecutionMode.NOOP;
        System.assertEquals(false, r.isSuccess());
    }

    @IsTest
    static void coverSerialization() {
        AsyncExecutorResult r = new AsyncExecutorResult();

        r.mode = AsyncExecutionMode.SYNC;
        r.recordCount = 5;
        r.message = 'ok';
        r.executedAt = System.now();
        r.asyncJobId = UserInfo.getUserId();
        r.configName = 'CFG';

        String s1 = r.toString();
        String s2 = r.toDebugString();

        System.assertNotEquals(null, s1);
        System.assertNotEquals(null, s2);
        System.assert(s2.contains('recordCount'));
    }
}